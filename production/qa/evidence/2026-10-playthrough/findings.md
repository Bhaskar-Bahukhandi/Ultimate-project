# Y1-P0-T14a findings: what the playthrough bot met (not fixed here)

Story AC-6: no file under `scripts/`, `scenes/` or `dialogue/` changed in T14a. Each finding names the scene, the symptom,
how to reproduce it and the bot's log line. None of them blocked the bot: it plays Chapter 3 → credits end to end.

## F-1 The ending never plays the credits screen; the credits screen still says "Version 1.0"

- **Scenes:** `scripts/chapter10/ch10_ending.gd`, `scripts/ui/credits_screen.gd`.
- **Symptom:** after the true ending the game shows a static "TRUE ENDING … Credits / Design, code, and story: Aethelgard
  Prototype Team …" panel (ch10_ending.gd:77) and returns to the main menu (:31). `CreditsScreen` (the scrolling credits)
  only opens from the main menu's Credits button (main_menu.gd:922). Its text also ends with "AETHELGARD: THE GLITCH
  SOVEREIGN / Version 1.0" — a real version string that T12 (one version, 0.1.0) did not catch.
- **Reproduce:** finish Chapter 10 (or run the bot): no scrolling credits; open Credits from the menu: "Version 1.0".
- **Bot log:** `AC-5 the ending returns to main_menu.tscn`, then `AC-5 CreditsScreen opens …` (opened by the bot).
- **Why not fixed:** the true ending is protected (AGENTS.md); a design call. The version line is a T12 follow-up.

## F-2 A hazard trial can write to a freed marker (a player can reach it, rarely; the bot avoids it)

- **Scene:** `scripts/combat/late_game_hazard_trial.gd` `_run_hazard` (:380-415) and `_run_safe_zone`.
- **Symptom:** `SCRIPT ERROR: Invalid assignment of property or key 'color' … on a base object of type 'previously freed'`
  (:412). Seen once, on the Sovereign trial, in the bot's first run (`bot_run1_hazard_script_error.log`).
- **Cause:** the markers are freed by `_clear_hazards()` from `_complete_trial()` and from `_on_player_died()` (:503-505).
  `_run_hazard`'s active-window loop checks `_retry_requested` only at the top of each pass, and `_wait_or_retry` stops
  early on `_transition_started` without `_run_hazard` checking it; so a marker freed during the last active tick, or
  during a telegraph/recovery wait cut short by `_transition_started`, is written to afterwards.
- **Reachable by a player?** Yes, rarely: dying on the very last active tick of a hazard frees the markers while the loop
  is about to exit (code review, engine specialist; inferred from the code, not reproduced). The bot's mid-attempt
  `_complete_trial()` (decision D2) reached it more easily.
- **Test-side work-around (named, AC-6):** the bot completes a trial only when no hazard marker exists
  (`_active_markers` empty) and sets `_retry_requested` first, so a hazard that starts afterwards takes its own stop
  branch. Not "what a player could do" — it is the cost of D2's shortcut, and it touches the test only.
- **Suggested robustness fix (for the register):** check `_retry_requested or _transition_started or not
  is_inside_tree()` after the active-window loop and after each `_wait_or_retry` in `_run_hazard` and `_run_safe_zone`.

## F-3 The Chapter 3 Data Stream minigame has no fail state (information)

- **Scene:** `scripts/chapter3/ch3_data_stream.gd` (lane-dodge in `_process`).
- **Symptom:** an idle player is carried to the end and finishes (the bot idles; about 12 s real at time scale 4, about
  48 s of game time), taking hits but never failing. Not a softlock; noted for design (is the minigame meant to be
  failable?).
- **Bot log:** `leg 03 data_stream.tscn 12.2 s real, 0 choice(s)`.

## F-4 Unregistered speakers seen on the route (known)

- 131 "Unknown speaker" warnings in one run (Mirror Kaelen ×16, Echo Mirror ×10, Oakhaven Survivor ×7, …): the TD-019
  baseline, now seen live on the Chapter 4–10 route. No new finding; listed so T15's playtester expects default-coloured
  names in Chapters 4–10.

## F-5 The Source Key count is rebuilt from chapter flags from Chapter 8 on (information)

- **Scene:** `scripts/game_manager.gd` `normalize_source_key_progression()` (:1256), called from every Chapter 8–10 story
  scene's `_ready`.
- **Symptom:** it sets `source_key_fragment_3..7` from the chapters' own `chN_fragment_N_collected` flags and recounts.
  So if a chapter's `collect_source_key(N)` call were lost, the end-of-game count would still read 7 (found by the
  code-review mutation (g): removing `collect_source_key(5)` left the final count at 7). Not a defect today (every grant
  fires); it means the end count alone cannot prove the grants. The bot therefore checks each `source_key_fragment_N`
  at the leg that grants it, before Chapter 8.

## Not found

- No softlock, no dead end, no stuck dialogue, no missing hand-off on the option-0 route; every hand-off had no active
  dialogue and an empty ContextStack; `ch3_ending`'s key-press wait accepts a real `ui_accept` event; the three hazard
  trials kept an idle player alive for at least 3 s of attempt 1 at their own time scale.
- Test-side shortcuts, named (AC-6): the Wastes region gate is used by calling the region's `_interact_story` (a player
  walks onto the gate and presses interact; reachability_test.gd proves it is touchable); choices are answered by
  calling `_on_choice_pressed(0)` once the buttons are focusable (after DialogueManager's 0.5 s grace, as a player
  could); the trial completion described in F-2.
