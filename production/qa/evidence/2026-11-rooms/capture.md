# Capture: 2026-10-25 22:01 (re-capture after the re-entry change, D10)

- **How:** real-renderer tour (`tests/run_screenshots.ps1 -Only ch1_breadcrumb_oakhaven,s08_elara_house,s08_shrine`), 1280x720, Godot_v4.6.3-stable_win64_console.exe, renderer forward_plus (live window, not --headless, not the dummy renderer)
- **Commit:** 5c94704 (the S08 implementation) + uncommitted changes under AethelgardPrototype/ (re-entry, D10)
- **Source run:** `AethelgardPrototype/run_artifacts/screenshots/20261025-220139` (git-ignored)
- **Files:** ch1_breadcrumb_oakhaven.png, s08_elara_house.png, s08_shrine.png, s08_shrine_altar.png, report.md; elara_house.png = copy of s08_elara_house.png, shrine.png = copy of s08_shrine.png (the story's names)
- **History:** captured 17:48 (the door still opened after the stew; the village shot showed the door prompt), re-captured 19:46 (door shut after the stew, no prompt), re-captured 22:01 (re-entry allowed again, D10: the village shot shows the door prompt, which is correct). Only the village shot differs in content between the three; the house and shrine shots are the same scenes.
- **Copied by hand, not with `-Evidence`:** the script names the folder `<current yyyy-MM>-<topic>`, and on 2026-10-25 no topic resolves to this story's `2026-11-rooms` folder. Tour exit code 0, 4 screenshots, 0 problems.
- **Viewed:** the village, house and shrine shots opened and checked by the orchestrator after the copy.
- **Art:** placeholder ColorRect rooms, not production art. ComfyUI used: No.
