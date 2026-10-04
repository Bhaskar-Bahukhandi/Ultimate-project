extends SceneTree
## Extracts the dialogue currently written inside GDScript into .dlg files under
## res://dialogue/_extracted/, mirroring res://scripts/. These files are SOURCE
## MATERIAL for the story rewrite: nothing in the game loads them. Each script
## function becomes a node; choice options point at END until rewritten.
##
## Run: tests/run_phase0_tests.ps1 -Script res://tools/extract_dialogue.gd
## (any headless run works; it only writes under res://dialogue/_extracted/).

const SRC_ROOT := "res://scripts"
const OUT_ROOT := "res://dialogue/_extracted"
const STR := "\"((?:[^\"\\\\]|\\\\.)*)\""  # a GDScript "string" literal (group 1 = contents)

var _say_re := RegEx.create_from_string("(?:DialogueManager\\.say|_show_dialogue)\\(\\s*" + STR + "\\s*,\\s*" + STR)
var _dict_re := RegEx.create_from_string("\"speaker\"\\s*:\\s*" + STR + "\\s*,\\s*\"text\"\\s*:\\s*" + STR)
var _choice_re := RegEx.create_from_string("(?s)show_choices\\(\\s*" + STR + "\\s*,\\s*\\[(.*?)\\]")
var _str_re := RegEx.create_from_string(STR)
var _func_re := RegEx.create_from_string("(?m)^func (\\w+)")

var _files := 0
var _lines := 0
var _choices := 0


func _initialize() -> void:
	_walk(SRC_ROOT)
	print("EXTRACT files=%d lines=%d choice_blocks=%d -> %s" % [_files, _lines, _choices, OUT_ROOT])
	quit(0)


func _walk(dir_path: String) -> void:
	var dir := DirAccess.open(dir_path)
	if dir == null:
		return
	for sub in dir.get_directories():
		_walk(dir_path.path_join(sub))
	for file in dir.get_files():
		if file.ends_with(".gd"):
			_extract(dir_path.path_join(file))


func _extract(script_path: String) -> void:
	var src := FileAccess.get_file_as_string(script_path)
	var items: Array = []  # [position, text_line_or_block]
	for m in _say_re.search_all(src):
		items.append([m.get_start(), "%s: %s" % [_unescape(m.get_string(1)), _unescape(m.get_string(2))]])
	for m in _dict_re.search_all(src):
		items.append([m.get_start(), "%s: %s" % [_unescape(m.get_string(1)), _unescape(m.get_string(2))]])
	for m in _choice_re.search_all(src):
		var block := "# TODO: point each option at the node for its outcome\n? Kaelen: %s" % _unescape(m.get_string(1))
		for opt in _str_re.search_all(m.get_string(2)):
			block += "\n- %s => END" % _unescape(opt.get_string(1))
		items.append([m.get_start(), block])
		_choices += 1
	if items.is_empty():
		return
	items.sort_custom(func(a, b): return a[0] < b[0])

	var funcs: Array = []  # [position, name]
	for m in _func_re.search_all(src):
		funcs.append([m.get_start(), m.get_string(1)])

	var out := "# Extracted from %s\n# Source material for the rewrite; not loaded by the game.\n# Format: story/DIALOGUE_FORMAT.md\n" % script_path
	var current_node := ""
	for item in items:
		var node := "file_scope"
		for f in funcs:
			if f[0] <= item[0]:
				node = f[1]
		if node != current_node:
			current_node = node
			out += "\n~ %s\n" % node
		out += item[1] + "\n"
		if not item[1].begins_with("#"):
			_lines += 1

	var rel := script_path.trim_prefix(SRC_ROOT + "/").get_basename() + ".dlg"
	var out_path := OUT_ROOT.path_join(rel)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out_path.get_base_dir()))
	var f := FileAccess.open(out_path, FileAccess.WRITE)
	f.store_string(out)
	f.close()
	_files += 1


## GDScript string escapes -> .dlg text (keeps \n as the .dlg line-break escape).
func _unescape(s: String) -> String:
	s = s.replace("\\\"", "\"").replace("\\t", " ")
	# \uXXXX -> the character (e.g. — em dash)
	var out := ""
	var i := 0
	while i < s.length():
		if s[i] == "\\" and i + 5 < s.length() and s[i + 1] == "u" and s.substr(i + 2, 4).is_valid_hex_number():
			out += char(s.substr(i + 2, 4).hex_to_int())
			i += 6
		else:
			out += s[i]
			i += 1
	return out.strip_edges()
