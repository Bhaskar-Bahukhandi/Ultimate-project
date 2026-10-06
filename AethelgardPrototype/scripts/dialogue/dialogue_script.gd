extends RefCounted
## Parser for Aethelgard dialogue files (.dlg). Writer-facing syntax:
## story/DIALOGUE_FORMAT.md. Pure data — no scene or autoload access — so it
## can be tested on its own. DialogueManager.run() plays the result.
##
##   ~ node_name                     start a node
##   Speaker: text [#id]              a line
##   ? Speaker: prompt [#id]          the prompt for the choices that follow
##   - option text => node [#id]      a choice (=> END to finish)
##   set flag  /  set flag = false    write a story flag
##   => node  /  => END               jump
##   do event_name                    hand control to the scene (camera, fx…)
##   [if a and not b] <any step>      condition (flags, or has_elara)
##   # comment

const END := "END"

var path: String = ""
var nodes: Dictionary = {}          # node name -> Array[Dictionary] of steps
var node_order: Array[String] = []
var errors: Array[String] = []

static var _cache: Dictionary = {}

## Parse a file (cached per path). Check `errors` before playing it.
static func load_file(file_path: String, use_cache: bool = true) -> RefCounted:
	if use_cache and _cache.has(file_path):
		return _cache[file_path]
	var script = load("res://scripts/dialogue/dialogue_script.gd").new()
	script.path = file_path
	if not FileAccess.file_exists(file_path):
		script.errors.append("%s: file not found" % file_path)
	else:
		script.parse(FileAccess.get_file_as_string(file_path))
	if use_cache:
		_cache[file_path] = script
	return script


static func clear_cache() -> void:
	_cache.clear()


func parse(source: String) -> void:
	nodes.clear()
	node_order.clear()
	errors.clear()
	var current := ""
	var pending_prompt: Variant = null
	var line_no := 0
	for raw in source.split("\n"):
		line_no += 1
		var line := raw.strip_edges()
		if line.is_empty() or line.begins_with("#"):
			continue
		# Node header
		if line.begins_with("~"):
			current = line.substr(1).strip_edges()
			if current.is_empty() or current.contains(" "):
				_error(line_no, "node names can't be empty or contain spaces: '%s'" % line)
				current = ""
				continue
			if nodes.has(current):
				_error(line_no, "duplicate node '%s'" % current)
			nodes[current] = []
			node_order.append(current)
			pending_prompt = null
			continue
		if current.is_empty():
			_error(line_no, "text before the first '~ node' line")
			continue
		var step := _parse_step(line, line_no)
		if step.is_empty():
			continue
		var node_steps: Array = nodes[current]
		var open_block: bool = not node_steps.is_empty() and node_steps.back()["type"] == "choice" \
				and not node_steps.back().get("closed", false)
		# A "? prompt" starts a new choice block (closing any open one).
		if step["type"] == "prompt":
			if open_block:
				node_steps.back()["closed"] = true
			pending_prompt = step
			continue
		if step["type"] == "option":
			if not open_block:
				node_steps.append({"type": "choice", "prompt": pending_prompt, "options": [], "line": line_no, "cond": []})
				pending_prompt = null
			node_steps.back()["options"].append(step)
			continue
		# Any other step closes an open choice block.
		if open_block:
			node_steps.back()["closed"] = true
		if pending_prompt != null:
			_error(int(pending_prompt["line"]), "'?' prompt must be followed by '- option' lines")
			pending_prompt = null
		node_steps.append(step)
	_validate()


func _parse_step(line: String, line_no: int) -> Dictionary:
	var cond: Array = []
	if line.begins_with("[if "):
		var close := line.find("]")
		if close == -1:
			_error(line_no, "unclosed [if ...]")
			return {}
		cond = _parse_condition(line.substr(4, close - 4), line_no)
		line = line.substr(close + 1).strip_edges()
	var id := ""
	var id_match := RegEx.create_from_string("\\[#([A-Za-z0-9_.-]+)\\]\\s*$").search(line)
	if id_match:
		id = id_match.get_string(1)
		line = line.substr(0, id_match.get_start()).strip_edges()

	if line.begins_with("=>"):
		return {"type": "jump", "target": line.substr(2).strip_edges(), "cond": cond, "line": line_no}
	if line.begins_with("set "):
		var body := line.substr(4).strip_edges()
		var value := true
		if body.contains("="):
			var parts := body.split("=", true, 1)   # keep empty parts: "set flag =" must report, not index past the end
			body = parts[0].strip_edges()
			var v := parts[1].strip_edges().to_lower()
			if v not in ["true", "false"]:
				_error(line_no, "set value must be true or false")
			value = v == "true"
		if body.is_empty() or body.contains(" "):
			_error(line_no, "bad flag name in 'set'")
			return {}
		return {"type": "set", "flag": body, "value": value, "cond": cond, "line": line_no}
	if line.begins_with("do "):
		return {"type": "do", "event": line.substr(3).strip_edges(), "cond": cond, "line": line_no}
	if line.begins_with("- "):
		var body := line.substr(2).strip_edges()
		# Options take their condition after the dash: "- [if flag] text => node"
		if body.begins_with("[if "):
			var close := body.find("]")
			if close == -1:
				_error(line_no, "unclosed [if ...]")
				return {}
			cond.append_array(_parse_condition(body.substr(4, close - 4), line_no))
			body = body.substr(close + 1).strip_edges()
		var arrow := body.rfind("=>")
		if arrow == -1:
			_error(line_no, "choice option needs '=> node' (or '=> END')")
			return {}
		return {"type": "option", "text": body.substr(0, arrow).strip_edges().replace("\\n", "\n"),
			"target": body.substr(arrow + 2).strip_edges(), "id": id, "cond": cond, "line": line_no}
	var is_prompt := line.begins_with("? ")
	if is_prompt:
		line = line.substr(2).strip_edges()
	var colon := line.find(": ")
	if colon <= 0:
		_error(line_no, "expected 'Speaker: text' — got '%s'" % line)
		return {}
	return {"type": "prompt" if is_prompt else "line", "speaker": line.substr(0, colon).strip_edges(),
		"text": line.substr(colon + 2).strip_edges().replace("\\n", "\n"), "id": id, "cond": cond, "line": line_no}


## "a and not b" -> [{"flag": "a", "negate": false}, {"flag": "b", "negate": true}]
func _parse_condition(text: String, line_no: int) -> Array:
	var out: Array = []
	for part in text.split(" and "):
		var term := part.strip_edges()
		var negate := term.begins_with("not ")
		if negate:
			term = term.substr(4).strip_edges()
		if term.is_empty() or term.contains(" "):
			_error(line_no, "bad condition '%s' (use: flag, not flag, a and b)" % text)
			continue
		out.append({"flag": term, "negate": negate})
	return out


func _validate() -> void:
	for node_name in node_order:
		for step in nodes[node_name]:
			var targets: Array = []
			if step["type"] == "jump":
				targets.append(step["target"])
			elif step["type"] == "choice":
				if step["options"].is_empty():
					_error(int(step["line"]), "choice block with no options")
				for opt in step["options"]:
					targets.append(opt["target"])
			for t in targets:
				if t != END and not nodes.has(t):
					_error(int(step["line"]), "jump to unknown node '%s'" % t)


func _error(line_no: int, message: String) -> void:
	errors.append("%s:%d: %s" % [path if not path.is_empty() else "<source>", line_no, message])


## Lines and options that have no [#id] yet (they need one before localization).
func missing_ids() -> Array[String]:
	var out: Array[String] = []
	for node_name in node_order:
		for step in nodes[node_name]:
			if step["type"] == "line" and step["id"].is_empty():
				out.append("%s:%d" % [path, step["line"]])
			elif step["type"] == "choice":
				if step["prompt"] != null and step["prompt"]["id"].is_empty():
					out.append("%s:%d" % [path, step["prompt"]["line"]])
				for opt in step["options"]:
					if opt["id"].is_empty():
						out.append("%s:%d" % [path, opt["line"]])
	return out
