extends SceneTree

const OUTPUT_PATH := "res://assets/art_sources/comfyui_tests/late_hubs_t1_audit/diagnostics/late_hubs_t1_godot_validation.json"
const TEXTURES := [
    "res://assets/production_art/tilesets/oakhaven/oakhaven_afternoon_tileset.png",
    "res://assets/production_art/tilesets/ironhold/ironhold_tileset.png",
    "res://assets/production_art/tilesets/fractured_wastes/fractured_wastes_tileset.png",
    "res://assets/generated_v3/props/phase10mm_environment_prop_atlas.png",
    "res://assets/generated_v3/overlays/phase10mm_environment_decal_atlas.png",
    "res://assets/generated_v2/tilesets/forgotten_sectors_v2_prototype_tileset.png",
    "res://assets/generated_v2/tilesets/mirror_city_v2_prototype_tileset.png",
    "res://assets/generated_v2/tilesets/cathedral_server_v2_prototype_tileset.png",
    "res://assets/generated_v2/tilesets/memory_ocean_v2_prototype_tileset.png",
    "res://assets/generated_v2/tilesets/root_of_heaven_v2_prototype_tileset.png"
]
const SAFE_SCENES := [
    "res://scenes/regions/forgotten_sectors_revisit_hub.tscn",
    "res://scenes/regions/mirror_city_revisit_hub.tscn",
    "res://scenes/regions/cathedral_server_revisit_hub.tscn",
    "res://scenes/regions/memory_ocean_revisit_hub.tscn",
    "res://scenes/regions/root_of_heaven_prep_hub.tscn",
    "res://scenes/regions/saved_assembly_revisit_hub.tscn",
    "res://scenes/regions/human_patch_lab_revisit_hub.tscn"
]
const MAIN_MENU_CANDIDATES := [
    "res://scenes/main_menu.tscn",
    "res://scenes/ui/main_menu.tscn",
    "res://scenes/menus/main_menu.tscn",
    "res://scenes/MainMenu.tscn",
    "res://scenes/main/MainMenu.tscn"
]

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    var result := {
        "phase": "10M-T1",
        "project_boot": true,
        "textures": [],
        "main_menu": {"found": false, "path": "", "load_ok": false, "instantiate_ok": false},
        "late_hub_scene_loads": [],
        "chapter_story_scenes_skipped": true,
        "notes": [
            "This is a preview/read-only validation script.",
            "It does not change production_art, generated assets, scenes, scripts, saves, or gameplay state.",
            "Chapter story/trial scenes are not instantiated in this phase."
        ]
    }

    for path in TEXTURES:
        var exists := FileAccess.file_exists(path) or ResourceLoader.exists(path)
        var image_load_ok := false
        var dimensions := []
        if exists:
            var img := Image.new()
            var err := img.load(path)
            image_load_ok = err == OK
            if image_load_ok:
                dimensions = [img.get_width(), img.get_height()]
        result["textures"].append({"path": path, "exists": exists, "image_load_ok": image_load_ok, "dimensions": dimensions})

    for path in MAIN_MENU_CANDIDATES:
        if ResourceLoader.exists(path):
            result["main_menu"]["found"] = true
            result["main_menu"]["path"] = path
            var scene: PackedScene = load(path) as PackedScene
            result["main_menu"]["load_ok"] = scene != null
            if scene != null:
                var inst: Node = scene.instantiate()
                result["main_menu"]["instantiate_ok"] = inst != null
                if inst != null:
                    get_root().add_child(inst)
                    await process_frame
                    inst.queue_free()
            break

    for path in SAFE_SCENES:
        var entry := {"path": path, "exists": ResourceLoader.exists(path), "load_ok": false, "instantiate_ok": false, "player_found": false, "camera_found": false, "visual_node_found": false, "label_like_node_found": false}
        if entry["exists"]:
            var scene: PackedScene = load(path) as PackedScene
            entry["load_ok"] = scene != null
            if scene != null:
                var inst: Node = scene.instantiate()
                entry["instantiate_ok"] = inst != null
                if inst != null:
                    get_root().add_child(inst)
                    await process_frame
                    entry["player_found"] = _find_name(inst, "player")
                    entry["camera_found"] = _find_name(inst, "camera")
                    entry["visual_node_found"] = _find_name(inst, "visual") or _find_name(inst, "tile") or _find_name(inst, "background")
                    entry["label_like_node_found"] = _find_type_or_name(inst, "Label")
                    inst.queue_free()
                    await process_frame
        result["late_hub_scene_loads"].append(entry)

    var file := FileAccess.open(OUTPUT_PATH, FileAccess.WRITE)
    if file != null:
        file.store_string(JSON.stringify(result, "\t"))
        file.close()
    quit(0)

func _find_name(node: Node, needle: String) -> bool:
    if node.name.to_lower().contains(needle.to_lower()):
        return true
    for child in node.get_children():
        if _find_name(child, needle):
            return true
    return false

func _find_type_or_name(node: Node, needle: String) -> bool:
    if node.get_class().to_lower().contains(needle.to_lower()) or node.name.to_lower().contains(needle.to_lower()):
        return true
    for child in node.get_children():
        if _find_type_or_name(child, needle):
            return true
    return false
