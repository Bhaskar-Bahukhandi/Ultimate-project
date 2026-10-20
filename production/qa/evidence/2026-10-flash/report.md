# Screenshot tour — 2026-10-20 17:15:26

Godot 4.6.3-stable (official), renderer `forward_plus`, NVIDIA GeForce RTX 2050. Window (1280.0, 720.0).

Game state is reset before each scene, so scenes show their default (fresh-save) state.

**No layout problems found.**

Contact sheets: `contact_scenes.png`, `contact_dialogue.png`.

| Shot | Scene / source | Notes |
|---|---|---|
| `ch3_archive_flash_before.png` | archive_depths.tscn | baseline: same scene, no flash yet |
| `ch3_archive_flash.png` | archive_depths.tscn | SceneTransitions.flash((0.2, 0.6, 1.0, 0.4), 0.8) called by the stop (scene call is inside the Source Key coroutine; routing proven by screen_flash_test F1); overlay colour (0.2, 0.6, 1.0, 0.4), modulate.a 0.800 just before the capture; mean RGB before (0.036, 0.046, 0.092) -> flash frame (0.070, 0.161, 0.281); shift toward the flash colour 0.224 (min 0.010) |
| `ch1_oakhaven_flash_before.png` | oakhaven_village.tscn | baseline: same scene, no flash yet |
| `ch1_oakhaven_flash.png` | oakhaven_village.tscn | real scene _on_dlg_event("fracture_spreads"); overlay colour (0.55, 0.0, 0.7, 0.35), modulate.a 0.800 just before the capture; mean RGB before (0.253, 0.386, 0.262) -> flash frame (0.296, 0.331, 0.326); shift toward the flash colour 0.095 (min 0.010) |
