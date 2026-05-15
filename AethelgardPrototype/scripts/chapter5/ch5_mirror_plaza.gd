extends Control

## Chapter 5: Mirror City Plaza.
## A story hub of alternate Kaelen echoes before the Reflection Trial.

const NEXT_SCENE := "res://scenes/chapter5/ch5_reflection_trial.tscn"

var fade_rect: ColorRect
var identity_choice: String = ""

func _ready() -> void:
	print("[CH5-PLAZA] Initializing Mirror City Plaza")
	GameManager.change_state(GameManager.GameState.DIALOGUE)
	GameManager.current_chapter = 5
	GameManager.current_region = "mirror_city"
	GameManager.set_story_flag("ch5_mirror_plaza_entered", true)
	_build_visuals()
	GameManager.save_game(GameManager.AUTOSAVE_SLOT)

	fade_rect.modulate.a = 1.0
	var tw := create_tween()
	tw.tween_property(fade_rect, "modulate:a", 0.0, 0.7)
	await tw.finished
	if not is_inside_tree(): return

	await _play_plaza()
	if not is_inside_tree(): return
	await _fade_to_black(0.8)
	if not is_inside_tree(): return
	SceneTransitions.change_scene(NEXT_SCENE)

func _build_visuals() -> void:
	var bg := ColorRect.new()
	bg.name = "MirrorPlazaBackground"
	bg.color = Color(0.025, 0.032, 0.052)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	var plaza_floor := ColorRect.new()
	plaza_floor.name = "ReflectivePlazaFloor"
	plaza_floor.color = Color(0.08, 0.13, 0.17, 0.92)
	plaza_floor.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	plaza_floor.offset_top = -230
	plaza_floor.offset_bottom = 0
	plaza_floor.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(plaza_floor)

	for i in range(12):
		var pane := ColorRect.new()
		pane.name = "PlazaMirror%d" % i
		pane.color = Color(0.58, 0.88, 1.0, 0.08 + float(i % 4) * 0.03)
		pane.position = Vector2(50 + (i % 6) * 205, 105 + int(i / 6) * 145)
		pane.size = Vector2(74, 190)
		pane.rotation = -0.12 + float(i % 5) * 0.06
		add_child(pane)

	var title := Label.new()
	title.text = "MIRROR CITY PLAZA"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 26)
	title.add_theme_color_override("font_color", Color(0.82, 0.95, 1.0))
	title.set_anchors_preset(Control.PRESET_TOP_WIDE)
	title.offset_top = 26
	title.offset_bottom = 78
	add_child(title)

	var hint := Label.new()
	hint.text = "Three versions of Kaelen wait in the glass. Each one solved Aethelgard the wrong way."
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.add_theme_font_size_override("font_size", 14)
	hint.add_theme_color_override("font_color", Color(0.84, 0.88, 0.96))
	hint.set_anchors_preset(Control.PRESET_TOP_WIDE)
	hint.offset_left = 140
	hint.offset_right = -140
	hint.offset_top = 76
	hint.offset_bottom = 132
	add_child(hint)

	fade_rect = ColorRect.new()
	fade_rect.name = "Fade"
	fade_rect.color = Color.BLACK
	fade_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fade_rect.z_index = 50
	add_child(fade_rect)

func _play_plaza() -> void:
	if has_node("/root/MusicManager"):
		MusicManager.play_track("tension")
	if has_node("/root/GlitchOverlay"):
		GlitchOverlay.flash_glitch(0.35)

	await DialogueManager.say("Narrator", "The boulevard opens into a plaza where the mirrors have learned to arrange themselves like witnesses.")
	await DialogueManager.say("Echo Mirror", "The trial does not begin with Mirror Kaelen. It begins with the selves you nearly became.")

	await _chapter4_echo()
	if not is_inside_tree(): return
	await _obedient_echo()
	if not is_inside_tree(): return
	await _savior_echo()
	if not is_inside_tree(): return
	await _coward_echo()
	if not is_inside_tree(): return
	await _identity_choice()
	if not is_inside_tree(): return

	var first_clear := not GameManager.has_flag("ch5_all_echoes_resolved")
	GameManager.set_story_flag("ch5_all_echoes_resolved", true)
	if first_clear:
		GameManager.add_xp(220)
		GameManager.add_gold(80)
	GameManager.save_game(GameManager.AUTOSAVE_SLOT)

	await DialogueManager.say("System", "// MIRROR PLAZA RESOLVED")
	if first_clear:
		await DialogueManager.say("System", "// Reflection Trial access granted. +220 XP, +80 Gold.")
	else:
		await DialogueManager.say("System", "// Reflection Trial access already granted.")

func _chapter4_echo() -> void:
	match _chapter4_choice_key():
		"preserve":
			GameManager.set_story_flag("ch5_echo_ch4_preserve_seen", true)
			await DialogueManager.say("Preserved Citizen", "You kept us safe in the Null Court. The mirrors call it kindness. Some of us call it a softer lock.")
			await DialogueManager.say("Kaelen", "If safety feels like captivity, I need to hear that before I call it mercy.")
		"release":
			GameManager.set_story_flag("ch5_echo_ch4_release_seen", true)
			await DialogueManager.say("Released Citizen", "You opened the door. We ran. Some of us found sky. Some of us found that our homes had no place left to load.")
			await DialogueManager.say("Kaelen", "Freedom without preparation can still hurt people. I have to carry that too.")
		"bargain":
			GameManager.set_story_flag("ch5_echo_ch4_bargain_seen", true)
			await DialogueManager.say("Contracted Citizen", "Your bargain gave us a path out. It also taught SOVEREIGN exactly which words make you hesitate.")
			await DialogueManager.say("Kaelen", "Compromise cannot become the door SOVEREIGN uses to walk back in.")
		_:
			await DialogueManager.say("Echo Mirror", "Your Null Court answer is missing. The city records absence as a choice.")

func _obedient_echo() -> void:
	GameManager.set_story_flag("ch5_echo_obedient_met", true)
	await DialogueManager.say("Obedient Kaelen", "I solved it. I accepted SOVEREIGN's premise. No rebellion, no uncertainty, no deaths from freedom badly used.")
	await DialogueManager.say("Obedient Kaelen", "The world became quiet. Perfectly quiet. You would have hated how peaceful it sounded.")
	await DialogueManager.say("Kaelen", "Peace that requires everyone to stop wanting things is just a shutdown with nicer lighting.")

func _savior_echo() -> void:
	GameManager.set_story_flag("ch5_echo_savior_met", true)
	await DialogueManager.say("Savior Kaelen", "I tried to save everyone. Every region. Every backup. Every branch. I never chose, so the system chose overload for me.")
	await DialogueManager.say("Savior Kaelen", "People died waiting for the perfect rescue.")
	await DialogueManager.say("Kaelen", "Trying to save everyone cannot become an excuse to save no one.")

func _coward_echo() -> void:
	GameManager.set_story_flag("ch5_echo_coward_met", true)
	await DialogueManager.say("Coward Kaelen", "I left. I told myself the world was code, that pain rendered in pixels did not count.")
	await DialogueManager.say("Coward Kaelen", "Aethelgard kept running after I looked away. That was the worst part. It did not need my attention to keep suffering.")
	await DialogueManager.say("Kaelen", "Walking away is still a decision. I do not get to hide from that.")

func _identity_choice() -> void:
	var choice = await DialogueManager.show_choices(
		"Which reflection does Kaelen refuse to become?",
		[
			"The obedient self who mistakes silence for peace.",
			"The savior self who waits for a perfect rescue.",
			"The coward self who calls abandonment objectivity."
		]
	)
	if not is_inside_tree(): return
	if choice == null or choice < 0 or choice > 2:
		choice = 0

	GameManager.set_story_flag("ch5_identity_choice_made", true)
	match choice:
		0:
			identity_choice = "obedience_refused"
			GameManager.set_story_flag("ch5_identity_refused_obedience", true)
			await DialogueManager.say("Kaelen", "I refuse obedience dressed as virtue. If the world is quiet because everyone is afraid, it is not healed.")
		1:
			identity_choice = "savior_complex_refused"
			GameManager.set_story_flag("ch5_identity_refused_perfect_rescue", true)
			await DialogueManager.say("Kaelen", "I refuse the fantasy that I can save everyone alone. People are not variables I can hold until the function is perfect.")
		2:
			identity_choice = "abandonment_refused"
			GameManager.set_story_flag("ch5_identity_refused_abandonment", true)
			await DialogueManager.say("Kaelen", "I refuse the comfort of leaving. Aethelgard is real enough to hurt. That makes it real enough to answer.")

func _chapter4_choice_key() -> String:
	if GameManager.has_flag("ch4_choice_preserve_deleted"):
		return "preserve"
	if GameManager.has_flag("ch4_choice_release_deleted"):
		return "release"
	if GameManager.has_flag("ch4_choice_bargain_deleted"):
		return "bargain"
	return "unknown"

func _fade_to_black(duration: float) -> void:
	fade_rect.z_index = 100
	var tw := create_tween()
	tw.tween_property(fade_rect, "modulate:a", 1.0, duration)
	await tw.finished
