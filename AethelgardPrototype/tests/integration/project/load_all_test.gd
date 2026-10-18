extends SceneTree
## Loads every script and scene under res://scripts and res://scenes and fails
## (exit 1) if any of them doesn't load or a script can't be instantiated.
## Catches parse errors and broken ext_resource paths in seconds.

var _ok: int = 0
var _bad: Array[String] = []


func _initialize() -> void:
	_walk("res://scripts")
	_walk("res://scenes")
	print("LOADALL ok=%d bad=%d" % [_ok, _bad.size()])
	for path in _bad:
		print("LOADALL BAD " + path)
	quit(0 if _bad.is_empty() else 1)


func _walk(dir_path: String) -> void:
	var dir := DirAccess.open(dir_path)
	if dir == null:
		_bad.append(dir_path + " (cannot open)")
		return
	for sub in dir.get_directories():
		if not sub.begins_with("."):
			_walk(dir_path.path_join(sub))
	for file in dir.get_files():
		if file.ends_with(".gd") or file.ends_with(".tscn"):
			var path := dir_path.path_join(file)
			var res = ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_IGNORE)
			if res == null or (res is GDScript and not res.can_instantiate()):
				_bad.append(path)
			else:
				_ok += 1
