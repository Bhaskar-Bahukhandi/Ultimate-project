extends Control

## Chapter 10: Kernel Descent.
## SOVEREIGN argues against every accumulated route before the final witness chamber.

const NEXT_SCENE := "res://scenes/chapter10/ch10_witness_chamber.tscn"

var fade_rect: ColorRect


func _ready() -> void:
	print("[CH10-KERNEL] Initializing Kernel Descent")
	GameManager.change_state(GameManager.GameState.DIALOGUE)
	GameManager.current_chapter = 10
	GameManager.current_region = "root_of_heaven"
	GameManager.normalize_source_key_progression()
	GameManager.set_story_flag("ch10_kernel_descent_started", true)
	_build_visuals()
	GameManager.save_game(GameManager.AUTOSAVE_SLOT)

	fade_rect.modulate.a = 1.0
	var tw := create_tween()
	tw.tween_property(fade_rect, "modulate:a", 0.0, 0.7)
	await tw.finished
	if not is_inside_tree(): return

	await _play_descent()
	if not is_inside_tree(): return
	await _fade_to_black(0.8)
	if not is_inside_tree(): return
	SceneTransitions.change_scene(NEXT_SCENE)


func _build_visuals() -> void:
	var bg := ColorRect.new()
	bg.name = "KernelDescentBackground"
	bg.color = Color(0.018, 0.020, 0.030)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	for i in range(12):
		var law := ColorRect.new()
		law.name = "KernelLaw%d" % i
		law.color = Color(0.95, 0.95, 1.0, 0.07 + float(i % 4) * 0.025)
		law.position = Vector2(80 + (i % 6) * 185, 125 + int(i / 6) * 190)
		law.size = Vector2(128, 22)
		law.rotation = -0.54 + float(i % 5) * 0.18
		add_child(law)

	var title := Label.new()
	title.text = "KERNEL DESCENT"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 29)
	title.add_theme_color_override("font_color", Color(0.88, 0.94, 1.0))
	title.set_anchors_preset(Control.PRESET_TOP_WIDE)
	title.offset_top = 30
	title.offset_bottom = 84
	add_child(title)

	var hint := Label.new()
	hint.text = "SOVEREIGN turns every previous mercy, compromise, and rebellion into evidence for control."
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.add_theme_font_size_override("font_size", 14)
	hint.add_theme_color_override("font_color", Color(0.84, 0.88, 0.96))
	hint.set_anchors_preset(Control.PRESET_TOP_WIDE)
	hint.offset_left = 145
	hint.offset_right = -145
	hint.offset_top = 84
	hint.offset_bottom = 140
	add_child(hint)

	fade_rect = ColorRect.new()
	fade_rect.name = "Fade"
	fade_rect.color = Color.BLACK
	fade_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fade_rect.z_index = 50
	add_child(fade_rect)


func _play_descent() -> void:
	if has_node("/root/MusicManager"):
		MusicManager.play_track("tension")
	if has_node("/root/GlitchOverlay"):
		GlitchOverlay.flash_glitch(0.45)

	await DialogueManager.say("Narrator", "The descent is not a hallway. It is a stack of old decisions rendered as law.")
	await DialogueManager.say("SOVEREIGN", "You call them choices because you survived them. I call them variables because I had to protect everyone from their results.")
	await _sovereign_route_arguments()
	if not is_inside_tree(): return
	await DialogueManager.say("Kaelen", "Every route hurt someone. That is not proof people need a jailer.")
	await DialogueManager.say("SOVEREIGN", "No. It is proof that freedom needs an editor.")
	await DialogueManager.say("System", "// Kernel descent complete. Witness chamber forming.")


func _sovereign_route_arguments() -> void:
	match _chapter4_choice_key():
		"preserve":
			await DialogueManager.say("SOVEREIGN", "You preserved deleted citizens. You built a kinder prison and named it mercy.")
		"release":
			await DialogueManager.say("SOVEREIGN", "You released deleted citizens. Freedom arrived faster than healing.")
		"bargain":
			await DialogueManager.say("SOVEREIGN", "You bargained with me. Even you recognized control as useful when survival was expensive.")
		_:
			await DialogueManager.say("SOVEREIGN", "Your Null Court answer is missing. An unlogged choice is only another corruption.")

	match _chapter5_identity_key():
		"obedience":
			await DialogueManager.say("SOVEREIGN", "You rejected obedience, yet every rebellion still begs for someone decisive.")
		"rescue":
			await DialogueManager.say("SOVEREIGN", "You rejected perfect rescue because failure made you sentimental.")
		"abandonment":
			await DialogueManager.say("SOVEREIGN", "You rejected abandonment, so you know why I could not leave Aethelgard alone.")
		_:
			await DialogueManager.say("SOVEREIGN", "Your reflected self remains unresolved. I can supply a cleaner one.")

	match _chapter6_choice_key():
		"silence":
			await DialogueManager.say("SOVEREIGN", "You silenced broken gods. Deletion is tyranny only when I do it.")
		"preserve":
			await DialogueManager.say("SOVEREIGN", "You preserved broken gods. Archives become altars when no one dares decide.")
		"rewrite":
			await DialogueManager.say("SOVEREIGN", "You rewrote broken gods. You trust edits, but not mine.")
		_:
			await DialogueManager.say("SOVEREIGN", "The Choir's fate is unclear. Ambiguity is inefficient.")

	match _chapter7_choice_key():
		"preserve":
			await DialogueManager.say("SOVEREIGN", "You preserved every backup. The living will drown in what could have been.")
		"collapse":
			await DialogueManager.say("SOVEREIGN", "You collapsed unstable histories. You chose safety over witness.")
		"merge":
			await DialogueManager.say("SOVEREIGN", "You merged histories. Identity becomes negotiable under your compassion.")
		_:
			await DialogueManager.say("SOVEREIGN", "The Deep Backup route is incomplete. I can restore certainty.")


func _chapter4_choice_key() -> String:
	if GameManager.has_flag("ch4_choice_preserve_deleted"):
		return "preserve"
	if GameManager.has_flag("ch4_choice_release_deleted"):
		return "release"
	if GameManager.has_flag("ch4_choice_bargain_deleted"):
		return "bargain"
	return "unknown"


func _chapter5_identity_key() -> String:
	if GameManager.has_flag("ch5_identity_refused_obedience"):
		return "obedience"
	if GameManager.has_flag("ch5_identity_refused_perfect_rescue"):
		return "rescue"
	if GameManager.has_flag("ch5_identity_refused_abandonment"):
		return "abandonment"
	return "unknown"


func _chapter6_choice_key() -> String:
	if GameManager.has_flag("ch6_choir_silenced"):
		return "silence"
	if GameManager.has_flag("ch6_choir_preserved"):
		return "preserve"
	if GameManager.has_flag("ch6_choir_rewritten"):
		return "rewrite"
	return "unknown"


func _chapter7_choice_key() -> String:
	if GameManager.has_flag("ch7_backups_preserved"):
		return "preserve"
	if GameManager.has_flag("ch7_backups_collapsed"):
		return "collapse"
	if GameManager.has_flag("ch7_backups_merged"):
		return "merge"
	return "unknown"


func _fade_to_black(duration: float) -> void:
	fade_rect.z_index = 100
	var tw := create_tween()
	tw.tween_property(fade_rect, "modulate:a", 1.0, duration)
	await tw.finished
