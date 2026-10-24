extends SceneTree
## InputService.bind_text() must prune entries whose node was freed (Y1-P0-T10, AC-3/AC-4).
## Before the fix only a device switch or a rebind pruned them, so a keyboard-only
## session grew _bound_texts with every UI rebuild. Runs against the live autoload,
## which may already hold other bindings: each case measures base_live (entries with a
## live node) when it starts, frees what it created and never clears the list.
## Run: tests/run_phase0_tests.ps1 -Script res://tests/unit/input/input_bound_texts_prune_test.gd

const BULK := 1000

var _passes := 0
var _failures: Array[String] = []


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	await process_frame
	await process_frame
	if not OS.get_user_data_dir().contains("aeth_phase0_test"):
		push_error("Refusing to run: user data dir is not isolated. Use tests/run_phase0_tests.ps1.")
		quit(2)
		return
	test_refresh_with_freed_nodes_returns_to_base_live()
	test_bind_after_freed_nodes_prunes_without_refresh()
	test_rebind_same_node_keeps_one_entry_with_new_template()
	await test_queue_freed_node_is_pruned_by_next_bind()
	test_rebind_after_freed_entry_keeps_live_entries_after_it()
	print("")
	print("BOUNDTEXTS RESULT: %d passed, %d failed" % [_passes, _failures.size()])
	for f in _failures:
		print("  FAIL: " + f)
	quit(0 if _failures.is_empty() else 1)


func _check(cond: bool, name: String) -> void:
	if cond:
		_passes += 1
		print("  PASS: " + name)
	else:
		_failures.append(name)
		print("  FAIL: " + name)


func _svc() -> Node: return get_root().get_node("InputService")


## Entries whose node is still alive (the list can also hold dead ones from earlier code).
func _base_live() -> int:
	var n := 0
	for entry in _svc()._bound_texts:
		if entry["ref"].get_ref() != null:
			n += 1
	return n


func _dead_entries() -> int:
	var n := 0
	for entry in _svc()._bound_texts:
		if entry["ref"].get_ref() == null:
			n += 1
	return n


## The entries bound to `node` (any property).
func _entries_for(node: Object) -> Array:
	return _svc()._bound_texts.filter(func(e: Dictionary) -> bool: return e["ref"].get_ref() == node)


func _bind_and_free_bulk(svc: Node) -> void:
	var labels: Array[Label] = []
	for i in BULK:
		var l := Label.new()
		svc.bind_text(l, "bulk %d" % i)
		labels.append(l)
	for l in labels:
		l.free()


func test_refresh_with_freed_nodes_returns_to_base_live() -> void:
	print("[refresh drops freed nodes]")
	var svc := _svc()
	var base_live := _base_live()
	_bind_and_free_bulk(svc)
	svc._refresh_bound_texts()
	_check(svc._bound_texts.size() == base_live,
		"after refresh the list is back to base_live (%d of %d)" % [svc._bound_texts.size(), base_live])
	_check(_dead_entries() == 0, "no entry has a null ref after refresh")


func test_bind_after_freed_nodes_prunes_without_refresh() -> void:
	print("[bind prunes without refresh]")
	var svc := _svc()
	var base_live := _base_live()
	_bind_and_free_bulk(svc)
	var fresh := Label.new()
	svc.bind_text(fresh, "fresh")
	_check(svc._bound_texts.size() == base_live + 1,
		"1,000 freed labels then one bind leaves base_live + 1 (%d, base_live %d)" % [svc._bound_texts.size(), base_live])
	_check(_dead_entries() == 0, "no dead entry survives the bind")
	fresh.free()


func test_rebind_same_node_keeps_one_entry_with_new_template() -> void:
	print("[rebind same node + property]")
	var svc := _svc()
	var base_live := _base_live()
	var first := "Press {interact}"
	var second := "Hold {interact}"
	var l := Label.new()
	svc.bind_text(l, first)
	svc.bind_text(l, second)
	var mine := _entries_for(l)
	_check(mine.size() == 1, "one entry for L after two binds (%d)" % mine.size())
	_check(mine.size() == 1 and mine[0]["template"] == second, "L's entry holds the second template")
	_check(l.text == svc.fmt(second), "L.text is fmt(second)")
	_check(svc._bound_texts.size() == base_live + 1, "size is base_live + 1 (%d, base_live %d)" % [svc._bound_texts.size(), base_live])
	l.free()


func test_queue_freed_node_is_pruned_by_next_bind() -> void:
	print("[queue_free then next bind]")
	var svc := _svc()
	var base_live := _base_live()
	var l := Label.new()
	svc.bind_text(l, "queued")
	var l_ref: WeakRef = _entries_for(l)[0]["ref"]
	l.queue_free()
	_check(l_ref.get_ref() != null and _entries_for(l).size() == 1,
		"same frame: L's ref is still non-null and its entry still listed")
	await process_frame
	_check(l_ref.get_ref() == null, "next frame: L's ref is null")
	# Re-measure after the frame: another autoload may have bound or freed a label meanwhile.
	base_live = _base_live()
	var m := Label.new()
	svc.bind_text(m, "after")
	var dead_for_l: Array = svc._bound_texts.filter(func(e: Dictionary) -> bool: return e["ref"] == l_ref)
	_check(dead_for_l.is_empty(), "binding M dropped L's entry")
	_check(svc._bound_texts.size() == base_live + 1, "size is base_live + 1 (%d, base_live %d)" % [svc._bound_texts.size(), base_live])
	m.free()


func test_rebind_after_freed_entry_keeps_live_entries_after_it() -> void:
	print("[prune keeps live entries after a duplicate]")
	var svc := _svc()
	var base_live := _base_live()
	var a := Label.new()
	var d := Label.new()
	var b := Label.new()
	svc.bind_text(a, "a1")
	svc.bind_text(d, "d1")
	svc.bind_text(b, "b1")
	d.free()
	svc.bind_text(a, "a2")
	var b_entries := _entries_for(b)
	var a_entries := _entries_for(a)
	_check(_dead_entries() == 0, "D's entry was pruned")
	_check(b_entries.size() == 1 and b_entries[0]["ref"].get_ref() == b, "B (listed after A) is still present and live")
	_check(a_entries.size() == 1 and a_entries[0]["template"] == "a2", "A's template is updated, still one entry")
	_check(svc._bound_texts.size() == base_live + 2, "size is base_live + 2 (%d, base_live %d)" % [svc._bound_texts.size(), base_live])
	a.free()
	b.free()
