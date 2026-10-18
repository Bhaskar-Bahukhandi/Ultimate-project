ROUTES = [
 ("Prologue to Oakhaven arrival", ["Play from New Game through the Flight 707 cinematic and the crash sequence (scripts/prologue/) to the ch1_opening_crash_site_hook and ch1_path_to_oakhaven", "Stop at the Oakhaven village entrance; note time-to-control and every skip used"]),
 ("Oakhaven village, Elara and the tutorial knight", ["Play ch1_oakhaven_village, the Elara meeting and the ch1_tutorial_knight fight", "Talk to every NPC in Oakhaven once and use the shop before leaving"]),
 ("Broken Mile and the glitch crater", ["Play the Broken Mile path through ch1_glitch_crater including every shatter-transition fight", "Return to Oakhaven by foot afterwards and check world position after each fight"]),
 ("Chapter 1 end to end", ["Play Chapter 1 from a fresh save to the Chapter 2 hand-off without debug shortcuts", "Record total time, deaths, and every moment of confusion"]),
 ("Ironhold gate, city and arena district", ["Play ch2_ironhold_gate, ch2_ironhold_city and ch2_arena_district from the Chapter 2 start save", "Fight every arena wave available and visit every merchant"]),
 ("Clock Tower to Fragment Two", ["Play ch2_clock_tower, the Underground and the Administrator Proxy fight (ch2_administrator_boss) through ch2_chapter_end", "Check the Source Key fragment count and story flags after Fragment Two"]),
 ("Chapter 2 end to end", ["Play Chapter 2 from its start save, including the Seraphina choice, to the chapter end", "Play the Seraphina choice the opposite way on a second save and diff the flags"]),
 ("Act 1 in one sitting", ["Play prologue through Fragment Two on one save in one session", "Save and quit at three points, reload each, and continue"]),
 ("Market, auction and gambling loop", ["In the most developed city hub, buy, sell, list one auction lot, bid on one lot and play the gambling table to its daily limit (use the shop_system flow if market v1 is not yet built)", "Log gold before and after each step"]),
 ("Minigame circuit", ["Play every minigame built so far three times each (if none exist yet, play the arena district waves as the stand-in)", "Record reward per run and any economy-rule breach"]),
 ("Time-sensitive quests, fast profile", ["Start every active time-sensitive quest and complete them as fast as possible (if none exist yet, use the bridge deadline / chapter timers)", "Check the quest log timing text and in-world warnings for each"]),
 ("Time-sensitive quests, slow profile", ["Start the time-sensitive quests, then rest and wander so each one reaches its deadline or window close", "Check that every miss was signposted before it happened"]),
 ("World map and fast-travel tour", ["Open WorldMapUI and fast travel to every discovered destination in turn (free-travel rules unchanged)", "At each stop, walk 60 s and trigger one fight"]),
 ("Newest region critical path", ["Play the critical path of the newest region or chunk built this month from its entry seam to its last objective", "Walk its full perimeter looking for collision holes and seams"]),
 ("Boss rush of every built boss", ["Load each boss's pre-fight save (Administrator Proxy and any newer bosses) and fight each until a win or 5 deaths", "Log deaths with cause per attempt"]),
]

DIFFS = ["Beginner", "Easy", "Medium", "Hard", "Hell"]

FOCI = [
 ("regression hunting", "Re-test every bug closed in the last two weeks along the route; reopen any that reproduce"),
 ("performance", "Run with the FPS/frame-time monitor visible; log every hitch over 2 ms and every scene change time; run /perf-profile on the worst spot"),
 ("save and load", "Save at every allowed point, quit to the main menu, reload and compare flags, gold, position and clock against notes"),
 ("controller only", "Unplug the keyboard and mouse; play with a pad including all menus; log any action unreachable or any wrong glyph"),
 ("accessibility settings maxed", "Set text to max, reduced flashing and shake on, and a colour-blind simulation; log every barrier"),
 ("audio mix", "Play with headphones; log any masked warning sound, clipped SFX, repeated loop or music transition glitch"),
 ("new-player eyes", "Read every line and tutorial; do not use knowledge of the build; log every point of confusion with a timestamp"),
 ("sequence breaking", "Skip every skippable thing and try to reach objectives out of order; log soft-locks and missing flag guards"),
 ("economy tracking", "Log every gold gain and spend with its source; compute net gold per 10 minutes and flag any loop"),
 ("time pressure", "Log the in-game clock at each step and every deadline/warning seen; flag any unsignposted closure"),
 ("visual consistency", "Take a screenshot at each area; compare against the art bible and accepted baselines; log mismatches and fallback art"),
 ("difficulty fairness", "Log every death with the attack that caused it and whether it felt fair; tally fair vs unfair"),
]


def integration_days():
    out = []
    for i in range(60):
        r = i % 15
        k = i // 15
        rname, rsteps = ROUTES[r]
        diff = DIFFS[(r + k) % 5]
        fname, fstep = FOCI[(r + 3 * k) % 12]
        steps = [
            "Pull main, then build the exe: powershell -File AethelgardPrototype/tools/export_windows.ps1 -Tour; keep the tour log and screenshots in production/qa/evidence/<YYYY-MM-DD>-weekly/; any tour failure becomes today's first bug",
            "Run every suite: powershell -File AethelgardPrototype/tests/run_all_tests.ps1 (no -Quick), including reachability_test.gd, plus the gdUnit4 run (GdUnitCmdTool.gd -a res://tests) once installed; record pass/fail per suite",
            f"Set difficulty to {diff}. " + rsteps[0],
            rsteps[1],
            f"Focus - {fname}: {fstep}",
            "Run /playtest-report on today's notes and save it to production/qa/playtest-<YYYY-MM-DD>.md",
            "Run /bug-triage on new and open bugs, then /sprint-status for the week's burndown and risks",
            "Fix the top 2-3 bugs (S1/S2 first), each with a regression test; re-run the affected suite and re-export if the build changed",
        ]
        out.append({
            "focus": f"{rname} on {diff}, focus: {fname}",
            "steps": steps,
            "done": f"Exe built and toured, all suites recorded, '{rname}' played end to end on {diff} with {fname} notes, playtest report and triage saved, top bugs fixed or scheduled.",
        })
    return out


BUFFER = {
 "polish": (["fun", "vfx"], [
  ("Juice pass on {area}", "List every player action in {area} and check it has visual, audio and rumble feedback; add the missing ones"),
  ("Hit-feedback tuning in {area}", "Record 10 hits in {area} at 25% speed; align sparks, sound and hitstop to the impact frame"),
  ("Readability pass on {area}", "Screenshot {area} at 1x; mark every interactable or enemy that blends into the background and fix contrast"),
  ("UI tidy-up for {area}", "Align, pad and size every UI element shown in {area} to the theme; remove hardcoded colours"),
  ("Transition polish in {area}", "Time every fade and scene change in {area}; cut any over 0.5 s without a reason"),
  ("Ambient life pass on {area}", "Add or tune idle animations, ambient loops and small props so {area} does not feel static"),
  ("Pixel cleanup in {area}", "Find stray pixels, mixels and inconsistent outlines in sprites used in {area}; fix the worst five"),
  ("Camera polish in {area}", "Check camera limits, look-ahead and shake in {area}; fix any reveal of off-map space"),
  ("Text polish in {area}", "Read every string shown in {area} aloud; fix typos, voice drift and overlong lines"),
  ("Audio polish in {area}", "Balance every SFX and loop in {area} against the music; add variation to repeated sounds"),
  ("Menu feel in {area}", "Tune cursor speed, sounds and focus memory for menus reachable from {area}"),
  ("Death and retry polish for {area}", "Measure retry time in {area}; reduce it toward under 5 s"),
  ("Reward presentation in {area}", "Make pickups and chest openings in {area} scale with rarity"),
  ("Lighting and palette pass on {area}", "Check day and night palettes in {area} for readability and mood"),
  ("Glitch effect tuning in {area}", "Check every GlitchOverlay use in {area} for meaning and readability; reduce noise"),
 ]),
 "bugbash": (["tests", "fun"], [
  ("Bug bash: collision in {area}", "Walk every wall and edge of {area} pressing into corners; log snags and escapes (fixes to collision need approval)"),
  ("Bug bash: interactions in {area}", "Use every interactable in {area} twice, then again after a save/load"),
  ("Bug bash: transitions in {area}", "Enter and leave {area} through every exit, including during fights and dialogue"),
  ("Bug bash: pause and menus in {area}", "Open pause, map, status and shop in every state possible in {area}; check ContextStack recovers"),
  ("Bug bash: input spam in {area}", "Mash every button during dialogue, transitions and fights in {area}"),
  ("Bug bash: save edge cases in {area}", "Save at odd moments in {area} (mid-dialogue, just after a pickup) and reload"),
  ("Bug bash: controller in {area}", "Play {area} with a pad, hot-swapping to keyboard twice"),
  ("Bug bash: low framerate in {area}", "Cap FPS to 30 and play {area}; check timing-dependent logic"),
  ("Bug bash: high refresh in {area}", "Run {area} at 144 Hz and check animation, physics and timers"),
  ("Bug bash: window and resolution in {area}", "Resize, fullscreen toggle and alt-tab during {area}"),
  ("Bug bash: time of day in {area}", "Advance the WorldClock through a full day in {area} and watch schedules and lighting"),
  ("Bug bash: difficulty switch in {area}", "Lower difficulty mid-play in {area} and check every system follows"),
  ("Bug bash: companion in {area}", "Play {area} with each available companion; log pathing and dialogue issues"),
  ("Bug bash: sequence breaks in {area}", "Try reaching {area}'s objectives out of order"),
  ("Bug bash: log review for {area}", "Play {area} with the debugger output open; turn every warning and error into a bug"),
 ]),
 "techdebt": (["code", "cleanup"], [
  ("Static typing sweep of {area}", "Add types to every untyped var, param and return in scripts for {area}"),
  ("Magic numbers to data in {area}", "Move gameplay values in {area}'s scripts into .tres or exported vars with source comments"),
  ("Signal hygiene in {area}", "Convert string connects to Callables and add disconnects for long-lived emitters in {area}"),
  ("Coroutine safety in {area}", "Guard every await in {area} with an instance-validity check"),
  ("Pause safety in {area}", "Check every timer and tween in {area} respects pause (create_timer(t, false), bound tweens)"),
  ("Service routing in {area}", "Replace direct Input, paused and time_scale use in {area} with InputService and ContextStack"),
  ("Duplication removal in {area}", "Find copy-pasted blocks in {area}'s scripts and extract one helper with a test"),
  ("Long function split in {area}", "Split the longest function in {area} into named helpers, keeping tests green"),
  ("Node path cleanup in {area}", "Replace long get_node paths in {area} with typed @onready vars or unique names"),
  ("Dead code removal in {area}", "Remove unreachable and commented-out code in {area} after a reference grep"),
  ("Error handling in {area}", "Add push_error with context to every silent failure path in {area}"),
  ("Resource mutation audit in {area}", "Find shared Resources mutated at runtime in {area}; duplicate before mutating"),
  ("Enum conversion in {area}", "Replace string states in {area} with enums"),
  ("Warnings to zero in {area}", "Enable GDScript warnings for {area}'s scripts in a scratch copy and fix every warning"),
  ("Dependency untangling in {area}", "List autoloads used by {area}; inject the ones a test needs to fake"),
 ]),
 "docs": (["docs"], [
  ("System doc for {area}", "Write or update a one-page doc for {area}: purpose, data, entry points, known issues"),
  ("Doc comments for {area}", "Add ## doc comments to every public function in {area}'s scripts"),
  ("ADR backfill for {area}", "Find a decision in {area} made without an ADR and write it with /architecture-decision"),
  ("GDD refresh for {area}", "Compare {area}'s GDD with the build; update rules, edge cases and acceptance criteria"),
  ("Onboarding notes for {area}", "Write how a new team member would run, test and change {area}"),
  ("Diagram for {area}", "Draw the flow of {area} (states, signals, scenes) and link it from the doc index"),
  ("Known-issues list for {area}", "Collect open bugs and limitations of {area} into its doc"),
  ("Test doc for {area}", "List which tests cover {area} and which behaviours are untested"),
  ("CHANGELOG catch-up for {area}", "Add missing CHANGELOG entries for {area} from git log"),
  ("Glossary check for {area}", "Make sure terms used in {area} match the bible and glossary"),
  ("Data dictionary for {area}", "Document every .tres field {area} reads, its unit and range"),
  ("Playtest notes digest for {area}", "Summarise the last playtest notes about {area} into actions"),
  ("Evidence index for {area}", "Index screenshots and logs in production/qa/evidence/ that prove {area}'s features"),
  ("Tuning knobs list for {area}", "List every tuning value for {area} with current value and rationale"),
  ("Edge-case catalogue for {area}", "Write the edge cases for {area} as a checklist QA can run"),
 ]),
 "tests": (["tests"], [
  ("Unit tests for {area}'s formulas", "Extract one formula from {area} to a pure function and cover it with boundary tests"),
  ("Integration test for {area}", "Write a headless test that drives {area}'s main flow and asserts outcomes"),
  ("Regression tests for {area}", "Write a test for each fixed bug in {area} that lacks one"),
  ("Pause tests for {area}", "Test that {area} timers and tweens stop under a ContextStack pause"),
  ("Save round-trip test for {area}", "Save state touched by {area}, reload, and assert equality"),
  ("Reachability coverage for {area}", "Add {area}'s scenes to reachability_test.gd"),
  ("Determinism test for {area}", "Run {area}'s logic twice with the same seed and assert identical results"),
  ("Input test for {area}", "Simulate the input sequences {area} needs through InputService in a test"),
  ("Free-during-await test for {area}", "Free {area}'s node mid-coroutine in a test and assert no errors"),
  ("Data validation test for {area}", "Load every .tres used by {area} and validate ranges"),
  ("Screenshot evidence for {area}", "Add {area} to the screenshot tour and retain the images as evidence"),
  ("Flakiness check for {area}", "Run {area}'s tests 10 times and log variance"),
  ("Test readability for {area}", "Rename {area}'s tests to describe behaviour and add failure messages"),
  ("gdUnit4 migration for {area}", "Port {area}'s legacy test checks to gdUnit4 keeping the old ones until green"),
  ("Bot route for {area}", "Write a bot script that completes {area} headlessly"),
 ]),
 "performance": (["performance"], [
  ("Profile {area}", "Profile {area} for 60 s and list the top 5 costs"),
  ("Hitch hunt in {area}", "Log every frame over 16.6 ms in {area} with what happened"),
  ("Draw call review of {area}", "Check draw calls in {area} and fix batching breakers"),
  ("Allocation review of {area}", "Remove per-frame allocations in {area}'s scripts"),
  ("Idle processing in {area}", "Disable _process on nodes in {area} that have nothing to do"),
  ("Physics cost in {area}", "Reduce active bodies and monitoring areas in {area}"),
  ("Load time of {area}", "Measure and reduce the scene load time of {area}"),
  ("Memory over time in {area}", "Watch memory over 20 minutes in {area}; find growth"),
  ("Texture budget of {area}", "Check texture sizes and import settings used by {area}"),
  ("Audio cost of {area}", "Count simultaneous voices in {area} and cap them"),
  ("Particle budget in {area}", "Cap particle counts in {area}'s effects"),
  ("NPC sim cost in {area}", "Measure NPC update cost in {area} and apply LOD"),
  ("Shader cost in {area}", "Profile shaders active in {area} at full screen"),
  ("Pooling in {area}", "Pool frequently spawned objects in {area}"),
  ("Perf regression test for {area}", "Add a budget test for {area}'s load or frame time"),
 ]),
 "accessibility": (["accessibility", "ux"], [
  ("Remap coverage for {area}", "Check every action in {area} respects remapping"),
  ("Text size check in {area}", "Play {area} at max text size and fix overlaps"),
  ("Colour-only cues in {area}", "Find cues in {area} that rely on colour alone and add shape or sound"),
  ("Flash and shake audit of {area}", "Check {area} against reduced flash and shake settings"),
  ("Captions for {area}", "Add captions or visual cues for critical sounds in {area}"),
  ("Pad navigation of {area}", "Make every menu in {area} fully pad-navigable"),
  ("Hold-to-toggle in {area}", "Offer toggles for hold inputs used in {area}"),
  ("Signposting in {area}", "Check every missable in {area} is signposted"),
  ("Onboarding clarity in {area}", "Check {area} teaches its mechanic before testing it"),
  ("Contrast check in {area}", "Measure text contrast in {area}'s UI"),
  ("Cognitive load in {area}", "Count simultaneous HUD items in {area} and reduce"),
  ("Return-player recap for {area}", "Make {area}'s quest/log text understandable after a break"),
  ("Timing assist in {area}", "Check {area}'s timed elements work with leniency settings"),
  ("Error prevention in {area}", "Add confirmation or undo to destructive actions in {area}"),
  ("Accessibility evidence for {area}", "Screenshot {area} with accessibility options on and retain the images"),
 ]),
 "content": (["story", "localization"], [
  ("Canon check of {area}", "Check names, terms and facts in {area} against STORY_BIBLE"),
  ("Voice check of {area}", "Check {area}'s lines against VOICE_GUIDE per speaker"),
  ("String extraction for {area}", "Wrap {area}'s player-facing strings in tr() or .dlg"),
  ("Translator context for {area}", "Add context notes to {area}'s strings"),
  ("Text expansion test for {area}", "Fake +30% text length in {area} and fix clipping"),
  ("Barks variety in {area}", "Add variants to repeated barks in {area}"),
  ("Lore entries for {area}", "Check {area}'s lore entries are filed and linked"),
  ("Quest log copy for {area}", "Rewrite {area}'s quest log entries for clarity"),
  ("Item descriptions for {area}", "Review descriptions of items found in {area}"),
  ("Flag audit of {area}", "List flags {area} sets and reads; check each is declared"),
  ("Timing signposts in {area}", "Check in-world warnings for {area}'s time-sensitive content"),
  ("Consistency of {area} with Story+", "List what Story+ must show about {area}"),
  ("Dialogue flow review of {area}", "Cut redundant lines in {area}'s longest scene"),
  ("Hardcoded strings in {area}", "Grep {area}'s scripts for user-facing literals"),
  ("Pseudo-locale run of {area}", "Run {area} with a pseudo-locale and log untranslated strings"),
 ]),
}

TAILS = {
 "polish": ["Capture before/after screenshots of {area} into production/qa/evidence/<YYYY-MM-DD>-polish/", "Play {area} for 10 minutes to confirm nothing regressed; run tests/run_all_tests.ps1 -Quick"],
 "bugbash": ["File each finding with /bug-report including repro steps and severity", "Fix the top S1/S2 from {area} today with a regression test; schedule the rest"],
 "techdebt": ["Run the full suite before and after the change in {area}; no behaviour change allowed", "Record the item in the debt register as closed with the commit hash"],
 "docs": ["Link the updated doc for {area} from the docs index", "Ask for approval before writing the file, then commit as docs:"],
 "tests": ["Run the new tests for {area} three times to confirm determinism", "Add the suite to run_all_tests.ps1 and ci.yml if it is a new file"],
 "performance": ["Record before/after numbers for {area} in the perf log", "Run /perf-profile again on {area} to confirm the gain"],
 "accessibility": ["Retest {area} with the setting on and off", "Log remaining barriers in {area} as issues tagged accessibility"],
 "content": ["Run dialogue_test and load_all_test after edits in {area}", "List any canon question for {area} for the narrative review instead of inventing canon"],
}


def buffer_tasks():
    out = []
    for cat, (tags, items) in BUFFER.items():
        for title, step in items:
            out.append({"title": title, "steps": [step] + TAILS[cat], "tags": tags})
    return out
