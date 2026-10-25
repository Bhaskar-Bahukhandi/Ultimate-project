# Capture: 2026-10-25 19:46 (re-capture after the code review)

- **How:** real-renderer tour (`tests/run_screenshots.ps1 -Only ch1_breadcrumb_oakhaven,s08_elara_house,s08_shrine`), 1280x720, Godot_v4.6.3-stable_win64_console.exe, renderer forward_plus (live window, not --headless, not the dummy renderer)
- **Commit:** c677cf6 (HEAD; T14a's commits on top of the S08 story commit 38219e3) + uncommitted S08 changes under AethelgardPrototype/ (after the /code-review fixes)
- **Source run:** `AethelgardPrototype/run_artifacts/screenshots/20261025-194651` (git-ignored)
- **Files:** ch1_breadcrumb_oakhaven.png, s08_elara_house.png, s08_shrine.png, s08_shrine_altar.png, report.md; elara_house.png = copy of s08_elara_house.png, shrine.png = copy of s08_shrine.png (the story's names)
- **Why re-captured:** the first capture (17:48) was taken before the village door was shut after the stew; its `ch1_breadcrumb_oakhaven.png` showed "[F] Interact" over the door, i.e. the bug. The re-capture shows no prompt there, matching the fixed code and the new rooms-suite check "back at the shut door, the player targets nothing". In the house the prompt on the door is correct (leaving is allowed after the stew).
- **Copied by hand, not with `-Evidence`:** the script names the folder `<current yyyy-MM>-<topic>`, and on 2026-10-25 no topic resolves to this story's `2026-11-rooms` folder. The copy step is otherwise the same (PNGs other than contact sheets, plus report.md). Tour exit code 0, 4 screenshots, 0 problems.
- **Viewed:** all four PNGs opened and checked by the orchestrator after the copy.
- **Art:** placeholder ColorRect rooms, not production art. ComfyUI used: No.
