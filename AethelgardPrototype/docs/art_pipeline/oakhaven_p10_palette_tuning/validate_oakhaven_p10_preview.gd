extends SceneTree

const CONTACT_OUT := "res://assets/art_sources/comfyui_tests/oakhaven_p10_palette_tuning/contact_sheets/oakhaven_p10_godot_preview_validation_contact_sheet.png"
const MANIFEST_OUT := "res://assets/art_sources/comfyui_tests/oakhaven_p10_palette_tuning/manifest/oakhaven_p10_godot_preview_validation.json"

const VARIANTS := {
	"morning": {
		"atlas": "res://assets/art_sources/comfyui_tests/oakhaven_p10_palette_tuning/tuned_atlases/oakhaven_p10_morning_tuned.png",
		"screenshot": "res://assets/art_sources/comfyui_tests/oakhaven_p10_palette_tuning/screenshots/oakhaven_p10_morning_preview.png"
	},
	"afternoon": {
		"atlas": "res://assets/art_sources/comfyui_tests/oakhaven_p10_palette_tuning/tuned_atlases/oakhaven_p10_afternoon_tuned.png",
		"screenshot": "res://assets/art_sources/comfyui_tests/oakhaven_p10_palette_tuning/screenshots/oakhaven_p10_afternoon_preview.png"
	},
	"night": {
		"atlas": "res://assets/art_sources/comfyui_tests/oakhaven_p10_palette_tuning/tuned_atlases/oakhaven_p10_night_tuned.png",
		"screenshot": "res://assets/art_sources/comfyui_tests/oakhaven_p10_palette_tuning/screenshots/oakhaven_p10_night_preview.png"
	}
}

func _init() -> void:
	var sheet := Image.create(2304, 576, false, Image.FORMAT_RGBA8)
	sheet.fill(Color(0.08, 0.085, 0.10, 1.0))
	var validation := {
		"phase": "10M-P10",
		"preview_only": true,
		"production_art_changed": false,
		"checks": {}
	}
	var x_offset := 0
	for key in ["morning", "afternoon", "night"]:
		var data: Dictionary = VARIANTS[key]
		var atlas := Image.load_from_file(ProjectSettings.globalize_path(data["atlas"]))
		var screenshot := Image.load_from_file(ProjectSettings.globalize_path(data["screenshot"]))
		if atlas == null or atlas.is_empty() or atlas.get_width() != 512 or atlas.get_height() != 512:
			push_error("P10 validation could not load 512x512 tuned atlas: %s" % data["atlas"])
			quit(1)
			return
		if screenshot == null or screenshot.is_empty() or screenshot.get_width() != 768 or screenshot.get_height() != 576:
			push_error("P10 validation could not load 768x576 screenshot: %s" % data["screenshot"])
			quit(1)
			return
		sheet.blit_rect(screenshot, Rect2i(0, 0, screenshot.get_width(), screenshot.get_height()), Vector2i(x_offset, 0))
		x_offset += screenshot.get_width()
		validation["checks"][key] = {
			"atlas": data["atlas"],
			"atlas_size": [atlas.get_width(), atlas.get_height()],
			"screenshot": data["screenshot"],
			"screenshot_size": [screenshot.get_width(), screenshot.get_height()]
		}

	var save_err := sheet.save_png(ProjectSettings.globalize_path(CONTACT_OUT))
	if save_err != OK:
		push_error("P10 validation could not save contact sheet: %s" % save_err)
		quit(1)
		return
	validation["contact_sheet"] = CONTACT_OUT
	var file := FileAccess.open(ProjectSettings.globalize_path(MANIFEST_OUT), FileAccess.WRITE)
	if file == null:
		push_error("P10 validation could not write manifest.")
		quit(1)
		return
	file.store_string(JSON.stringify(validation, "\t"))
	print("P10 Godot preview validation: PASS")
	quit(0)
