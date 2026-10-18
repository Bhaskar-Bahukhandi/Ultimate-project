"""Shared infrastructure + per-unit templates for the Y3-Y6 production expander.

Each template appends tasks to a Phase, one task per stream that the unit touches.
All text is built from unit IDs and roadmap structure; no plot is invented.
"""
import datetime as dt
import json
import re

TAGS = set(
    "code architecture cleanup tests systems combat animation cinematics story dialogue quests "
    "openworld npc economy items ui ux audio music vfx assets art tools performance accessibility "
    "localization save time difficulty fun release marketing legal team docs ai level business".split()
)
STREAMS = ["primary", "secondary", "art", "audio", "writing", "qa"]
TEAM = {"art", "audio", "writing", "qa"}

REG = {
    "R1": ("Oakhaven", "Act 1"),
    "R2": ("Ironhold", "Act 1"),
    "R3": ("Fractured Wastes", "Act 2"),
    "R4": ("Mirror City", "Act 2"),
    "R5": ("Cathedral Server", "Act 2"),
    "R6": ("Memory Ocean", "Act 3"),
    "R7": ("Saved Assembly", "Act 3"),
    "R8": ("Root of Heaven", "Act 4"),
}
DIFFS = ["Beginner", "Easy", "Medium", "Hard", "Hell"]
AXES = {
    "A1": "axis 1 (Authority: you / shared / none)",
    "A2": "axis 2 (Faction: Hearth Compact / Archive Covenant / Continuity League)",
    "A3": "axis 3 (The deleted: restore / release / choose)",
    "T": "a timing modifier (pace value + named timing flags, §12.4)",
    "H": "the hidden 4th axis value (secret Witness Protocol route)",
}


def low(s):
    return re.sub(r"[^a-z0-9]+", "_", s.lower()).strip("_")


def D(focus, steps, done):
    assert 3 <= len(steps) <= 6, (focus, len(steps))
    return {"focus": focus, "steps": list(steps), "done": done}


def count_weekdays(start, end, stream):
    """Stream-days in [start, end] inclusive."""
    n = 0
    d = start
    while d <= end:
        wd = d.weekday()  # Mon=0 .. Sun=6
        if stream == "secondary":
            n += 1
        elif stream == "primary":
            n += wd != 6
        else:
            n += wd < 5
        d += dt.timedelta(days=1)
    return n


class Phase:
    def __init__(self, pid, title, goal, exit_criteria, start, end, cap):
        self.pid = pid
        self.pl = pid.lower()
        self.title = title
        self.goal = goal
        self.exit_criteria = exit_criteria
        self.start = start
        self.end = end
        self.cap = cap
        self.tasks = []  # (seg, seq, stream, task, anchor)
        self.seg_names = []
        self.seg = 0
        self.seq = 0
        self.pools = {s: [] for s in STREAMS}
        self.words = 0.0
        self.word_scale = 1.0
        self.lean = False
        self.blocks = []

    def segment(self, name):
        if name in self.seg_names:
            self.seg = self.seg_names.index(name)
            return
        self.seg_names.append(name)
        self.seg = len(self.seg_names) - 1

    def ev(self, uid):
        return f"production/qa/evidence/{self.pl}/{uid}/"

    def add(self, stream, title, why, tags, days, edge, evidence, anchor=None, seg=None):
        assert stream in STREAMS
        for t in tags:
            assert t in TAGS, t
        assert days, title
        self.seq += 1
        task = {
            "stream": stream,
            "title": title,
            "why": why,
            "tags": list(tags),
            "days": days,
            "edge_cases": list(edge),
            "evidence": evidence,
        }
        self.tasks.append([self.seg if seg is None else seg, self.seq, stream, task, anchor])
        return task

    def pool(self, stream, gen, max_n, home=None):
        """Register a fill generator: gen(n) -> (title, why, tags, days, edge, evidence).
        home: segment name the pool belongs to (region polish), or None (floating)."""
        self.pools[stream].append((home, gen, max_n))

    def totals(self):
        t = {s: 0 for s in STREAMS}
        for _, _, s, task, _ in self.tasks:
            t[s] += len(task["days"])
        return t

    def fill(self):
        """Fill each stream block by block so regions end near the same date in every stream.
        blocks: [(end_date, [segment names], fill_segment)] in calendar order."""
        self.block_report = []
        for s in STREAMS:
            avail = count_weekdays(self.start, self.end, s)
            scale = self.cap[s] / avail
            pools = list(self.pools[s])
            used = [False] * len(pools)
            # raw content per block (before any fill), to keep room for later blocks
            raw = []
            prev_end = None
            for bend, segs, fseg in self.blocks:
                idx = {self.seg_names.index(x) for x in segs if x in self.seg_names}
                n = 0
                for seg, _, st, task, anchor in self.tasks:
                    if st != s:
                        continue
                    if (anchor is None and seg in idx) or (anchor is not None and anchor <= bend and (prev_end is None or anchor > prev_end)):
                        n += len(task["days"])
                raw.append(n)
                prev_end = bend
            cum_segs = set()
            for bi, (bend, segs, fseg) in enumerate(self.blocks):
                cum_segs |= {self.seg_names.index(x) for x in segs if x in self.seg_names}
                last = bi == len(self.blocks) - 1
                target = self.cap[s] if last else round(count_weekdays(self.start, bend, s) * scale)
                target = min(target, self.cap[s] - sum(raw[bi + 1:]))
                content = 0
                for seg, _, st, task, anchor in self.tasks:
                    if st != s:
                        continue
                    if (anchor is None and seg in cum_segs) or (anchor is not None and anchor <= bend):
                        content += len(task["days"])
                deficit = target - content
                self.block_report.append((s, bi, target, content))
                order = ([i for i in range(len(pools)) if not used[i] and pools[i][0] in segs]
                         + [i for i in range(len(pools)) if not used[i] and pools[i][0] is None]
                         + [i for i in range(len(pools)) if not used[i] and pools[i][0] is not None and pools[i][0] not in segs])
                for i in order:
                    if deficit <= 0:
                        break
                    home, gen, mx = pools[i]
                    n = min(mx, deficit)
                    title, why, tags, days, edge, evid = gen(n)
                    assert len(days) == n, (title, n, len(days))
                    self.add(s, title, why, tags, days, edge, evid, seg=self.seg_names.index(fseg))
                    used[i] = True
                    deficit -= n
                if last and deficit > 0:
                    raise SystemExit(f"{self.pid} {s}: fill pool exhausted, {deficit} days short")
            tot = self.totals()[s]
            if tot > self.cap[s] * 1.03:
                raise SystemExit(f"{self.pid} {s}: {tot} over capacity {self.cap[s]}")

    def ordered(self):
        out = {}
        for s in STREAMS:
            items = [x for x in self.tasks if x[2] == s]
            normal = sorted([x for x in items if x[4] is None], key=lambda x: (x[0], x[1]))
            anchored = sorted([x for x in items if x[4] is not None], key=lambda x: (x[4], x[1]))
            seq = list(normal)
            for a in anchored:
                target = count_weekdays(self.start, a[4] - dt.timedelta(days=1), s)
                cum = 0
                best, best_d = len(seq), None
                for idx in range(len(seq) + 1):
                    dist = abs(cum - target)
                    if best_d is None or dist < best_d:
                        best, best_d = idx, dist
                    if idx < len(seq):
                        cum += len(seq[idx][3]["days"])
                seq.insert(best, a)
            out[s] = [x[3] for x in seq]
        return out

    def finalize_words(self, text):
        def rep(m):
            v = int(m.group(1)) * self.word_scale
            return f"{int(round(v / 50.0) * 50):,}"
        return re.sub(r"@@W(\d+)@@", rep, text)

    def write(self, path):
        ordered = self.ordered()
        tasks = []
        n = 0
        for s in STREAMS:
            for t in ordered[s]:
                n += 1
                tt = {"id": f"{self.pid}-T{n:03d}"}
                tt.update(t)
                tasks.append(tt)
        doc = {
            "phase_id": self.pid,
            "phase_title": self.title,
            "goal": self.goal,
            "exit_criteria": self.exit_criteria,
            "tasks": tasks,
        }
        txt = json.dumps(doc, indent=1, ensure_ascii=False)
        self.words_emitted = sum(int(x) for x in re.findall(r"@@W(\d+)@@", txt))
        self.word_scale = getattr(self, "word_target", self.words_emitted) / max(1, self.words_emitted)
        txt = self.finalize_words(txt)
        with open(path, "w", encoding="utf-8") as f:
            f.write(txt)
        return doc


def W(ph, base):
    """Word-count token; scaled later so the year's writing lands on its word target."""
    ph.words += base
    return f"@@W{base}@@"


# --------------------------------------------------------------------------------------------
# Unit templates
# --------------------------------------------------------------------------------------------

def boss(ph, u):
    bid, reg = u["id"], u["reg"]
    rname, act = REG[reg]
    lab = f"{bid} ({u['name']})" if u.get("name") else bid
    il = low(bid)
    flags = u.get("flags") or "the defeat/choice flags assigned to it in the Y2 route table"
    ev = ph.ev(bid)
    why = f"P2/P6 + ROADMAP §7 {ph.pid}: {act} boss in {reg} {rname}; every boss has a Hell-only phase (§3, §12.1)"
    edge = [
        f"Pause via ContextStack during a {bid} phase transition, then resume",
        "Retry 5 times: HP, poise and phase counters identical at each fight start",
        "Lower difficulty mid-fight from the pause menu (allowed); raising it must be refused",
        "Load a checkpoint saved one second before the fight trigger",
        "Gamepad disconnect during a telegraph pauses the game and does not eat the parry input",
    ]
    pd = [
        D(f"{lab}: design doc and pattern sheet", [
            f"Run `/design-system` for `design/gdd/bosses/{il}.md` with all 8 sections: attack list, phase HP thresholds, poise, arena needs",
            f"Write each attack's readable cue (pose, sound, VFX) and its §12.1 telegraph scale: ×1.5 / ×1.25 / ×1.0 / ×0.85 / ×0.7",
            f"Sketch the {bid} Hell-only phase and the +variants that switch on at Medium and Hard",
            f"List the story outputs ({flags}) and confirm each id exists in FlagRegistry",
            "Run `/design-review` on the doc and log open questions under Edge Cases",
        ], f"`design/gdd/bosses/{il}.md` passes /design-review; the attack and phase table is frozen"),
        D(f"{lab}: frame data and BossDef", [
            f"Author one AttackSpec `.tres` per attack under `resources/combat/bosses/{il}/` (startup / active / recovery frames)",
            "Assign hitstop tiers and punish windows; parry windows stay owned by DifficultyProfile, never by stats (§12.8)",
            f"Fill BossDef and PhaseDef for {bid}: poise per phase, thresholds, stagger rules",
            f"Unit test `tests/unit/bosses/test_{il}_frame_data.gd`: every AttackSpec points at real animation frames",
        ], f"{bid} frame data loads and test_{il}_frame_data passes"),
        D(f"{lab}: phase 1 AI on the fixed tick", [
            f"Implement phase 1 states in `scripts/combat/bosses/{il}_ai.gd` on the fixed tick, with no `create_timer` or `await` timers",
            "Pick patterns by weighted choice from the seeded RNG so input replays stay deterministic",
            "Emit telegraph-start events to FeelService and the audio cue bus",
            f"Add a debug overlay for {bid}: state, next attack, poise",
        ], f"{bid} phase 1 runs end to end in its arena test scene"),
        D(f"{lab}: phase 2, variants and transition", [
            f"Add {bid} phase 2 states and the transition (invulnerable window, arena change if the doc asks)",
            "Gate the Medium/Hard +variant attacks on the active DifficultyProfile",
            "Assert stat invariants across the transition: HP, poise and buffs never reset",
            "Pause and unpause through ContextStack mid-transition; nothing is skipped",
        ], f"{bid} phases 1-2 and variants run on all 5 profiles with no stuck state"),
        D(f"{lab}: arena from terrain context", [
            f"Declare {bid}'s arena needs for arena generation: {rname} biome, terrain shape, hazards, camera bounds",
            "Add hazard nodes on the named physics layers plus the arena kill zone",
            "Verify the return to the same world position after victory, defeat and retry (P1)",
            "Profile arena build time against the under-1-second shatter-transition budget",
        ], f"{bid} arena builds from terrain context and returns the player to the same tile"),
        D(f"{lab}: Hell-only phase", [
            f"Implement the {bid} Hell-only phase: telegraph ×0.7, 2-frame parry windows (33 ms)",
            "Confirm the 4-frame input buffer and the latency calibration offset apply in this phase",
            f"Record a perfect-input replay of the Hell phase as `tests/fixtures/replays/{il}_hell.replay`",
            "Check loot: Hell adds cosmetics/titles only; nothing essential is Hell-exclusive",
        ], f"The {bid} Hell phase is beaten by the reference replay"),
        D(f"{lab}: difficulty data, rewards and story flags", [
            "Wire enemy damage ×0.6 / ×0.8 / ×1.0 / ×1.3 / ×2.0 and healing charges 5/4/3/2/1 through DifficultyProfile",
            "DDA gentle on Beginner, on for Easy, off from Medium up; assert it in a unit test",
            f"Grant {bid} rewards through RewardLedger `grant_once` and write {flags}",
            "Reload from the pre-fight checkpoint and win again: no double grant",
        ], f"{bid} rewards and flags grant exactly once on every profile"),
        D(f"{lab}: world integration and cinematic hooks", [
            f"Place the {bid} trigger in its {rname} chunk and connect CIN-{bid}-IN / CIN-{bid}-OUT timelines",
            "Confirm boss context clears on arrival, New Game and load (existing return-point rule)",
            "Allow cinematic skip only per the skip rule (admin bosses: after first defeat)",
            "Run `tests/run_phase0_tests.ps1` and the load_all scene check",
        ], f"{bid} plays from world trigger through outro in a debug build"),
        D(f"{lab}: replay and invariant tests", [
            f"Write `tests/integration/bosses/test_{il}_replay.gd`: the Hell replay wins; the same replay shifted one frame on a parry loses",
            "Add the 5-retry invariant test and a pause-during-transition test",
            "Run `/smoke-check`; capture one screenshot per phase",
            f"Save screenshots and the replay log to `{ev}`",
        ], f"{bid} replay and invariant tests are green in CI"),
    ]
    if ph.lean:
        pd[6] = D(f"{lab}: difficulty data, rewards, flags and world hook-up", [
            "Wire enemy damage ×0.6 / ×0.8 / ×1.0 / ×1.3 / ×2.0, healing charges 5/4/3/2/1 and DDA through DifficultyProfile",
            f"Grant {bid} rewards via RewardLedger `grant_once` and write {flags}",
            f"Place the {bid} trigger in its {rname} chunk; connect CIN-{bid}-IN / CIN-{bid}-OUT",
            "Reload from the pre-fight checkpoint: no double grant; boss context clears on load",
        ], f"{bid} rewards grant once and the fight runs from world trigger to outro")
        del pd[7]
    ph.add("primary", f"Build boss {lab}", why, ["combat", "ai", "difficulty", "code", "tests"], pd,
           edge, f"tests/integration/bosses/test_{il}_replay.gd, tests/unit/bosses/test_{il}_frame_data.gd, screenshots in {ev}")

    sd = [
        D(f"{lab}: approach level design and pacing", [
            f"Block out the approach to {bid} in the {rname} chunk: last checkpoint, sightline to the arena, one rest point",
            "Place an in-world warning before the trigger so the fight is never a surprise softlock",
            "Check telegraph readability against the arena background with the art lead",
            "Time the walk-back from checkpoint to boss; keep it short so retries stay fun",
        ], f"{bid} approach is blocked out and the checkpoint-to-boss time is logged"),
        D(f"{lab}: intro and outro cinematic direction", [
            f"Storyboard CIN-{bid}-IN and CIN-{bid}-OUT (6-10 shots each) in `design/cinematics/{il}.md`",
            "Write the camera timeline notes and hold lengths; mark the skip point",
            "Brief the art lead (keyframes), audio (stingers) and writer (scene lines) with the shot list",
            "Check the outro carries the outcome flags into the next scene",
        ], f"CIN-{bid}-IN/OUT shot lists handed to art, audio and writing"),
        D(f"{lab}: review team deliverables and sign off", [
            "Review sprites, animation and VFX against the art bible; file numbered notes",
            "Review the boss audio layer and telegraph SFX mix in the fight",
            "Play the fight on Medium and on Hell with the latest build",
            f"Sign off or return with notes in `production/reviews/{ph.pl}/{il}.md`",
        ], f"{bid} has a written sign-off or a dated return list"),
    ]
    if not ph.lean:
        sd.insert(2, D(f"{lab}: five-profile tuning sign-off", [
            f"Play {bid} on all 5 profiles with the difficulty tuning panel open",
            "Check pattern literacy still matters on Beginner (§12.1: forgive execution, not attention)",
            "Compare QA death logs with target ranges and adjust data, not code",
            "Record the tuned values in the boss doc's Tuning Knobs section",
        ], f"{bid} tuning values recorded for all 5 profiles"))
    ph.add("secondary", f"Direct boss {lab}: arena level, cinematics, sign-off",
           f"P2 + §7 {ph.pid} Definition of Done: real art and audio, tuned on 5 difficulties", ["level", "cinematics", "combat", "team"], sd,
           ["A telegraph is readable only by colour (fails colourblind modes)", "Cinematic skipped on first view breaks a flag write"],
           f"production/reviews/{ph.pl}/{il}.md and design/cinematics/{il}.md")

    ad = [
        D(f"{lab}: turnaround, palette and scale", [
            f"Draw the {bid} turnaround and palette per the art bible ({rname} palette family)",
            "Check silhouette readability at 1x game scale against the arena background",
            "Get art-direction approval before animating",
        ], f"{bid} turnaround approved"),
        D(f"{lab}: idle and locomotion", [
            f"Animate {bid} idle and locomotion clips in PAE",
            "Export through the PAE importer; confirm frame tags match AttackSpec names",
            "Check pixel snap and integer scaling in the arena test scene",
        ], f"{bid} idle and locomotion import cleanly"),
        D(f"{lab}: phase 1 attack clips", [
            f"Animate every phase 1 attack for {bid} with the telegraph pose held for the Medium frame count",
            "Mark active frames to match the AttackSpec `.tres` from the programmer",
            "Re-export and run the frame-data unit test",
        ], f"{bid} phase 1 attacks animated and frame-matched"),
        D(f"{lab}: phase 2 and variant clips", [
            f"Animate {bid} phase 2 attacks and the Medium/Hard variant attacks",
            "Animate the phase transition",
            "Re-run the frame-data unit test after export",
        ], f"{bid} phase 2 clips animated"),
        D(f"{lab}: Hell-phase visual layer", [
            f"Make the {bid} Hell-phase palette or overlay layer and its unique attack clips",
            "Keep telegraph poses distinct from phase 1 so pattern literacy still works",
            "Check contrast in the high-contrast accessibility mode",
        ], f"{bid} Hell-phase visuals in the build"),
        D(f"{lab}: stagger, hit and defeat", [
            f"Animate {bid} stagger, hit-react and defeat clips",
            "Add hit-flash frames for the FeelService flash",
            "Check the defeat clip hands off cleanly to CIN-" + bid + "-OUT",
        ], f"{bid} reaction clips imported"),
        D(f"{lab}: VFX for telegraphs and impacts", [
            f"Make telegraph flash, impact and projectile VFX for {bid} in the pooled particle set",
            "Keep VFX inside the per-frame particle budget",
            "Confirm every telegraph has a shape cue, not only a colour cue",
        ], f"{bid} VFX pooled and in budget"),
        D(f"{lab}: cinematic keyframes and arena dressing", [
            f"Draw keyframes for CIN-{bid}-IN and CIN-{bid}-OUT from the shot list",
            f"Dress the {bid} arena background layers for its terrain context",
            "Hand off to the director for review",
        ], f"{bid} keyframes and arena dressing delivered"),
    ]
    if ph.lean:
        ad[0] = D(f"{lab}: turnaround, palette, idle and locomotion", [
            f"Draw the {bid} turnaround and palette ({rname} palette family); get approval",
            f"Animate {bid} idle and locomotion in PAE",
            "Export through the PAE importer; frame tags match AttackSpec names",
        ], f"{bid} approved and base clips imported")
        del ad[1]
    ph.add("art", f"Animate and render boss {lab}", f"§7 DoD real art; P2 + P9 juice for {bid}", ["art", "animation", "vfx", "assets"], ad,
           ["Frame tags renamed in PAE break AttackSpec links", "Hell overlay unreadable on low-brightness displays"],
           f"Imported clips under assets/sprites/bosses/{il}/, screenshots in {ev}")

    ph.add("audio", f"Score and sound boss {lab}", f"P9 juice + adaptive music for {bid}", ["audio", "music", "combat"], [
        D(f"{lab}: adaptive boss layer", [
            f"Write the {bid} adaptive layer on its region's battle track: phase 1, phase 2 and Hell intensity stems",
            "Mark loop points and phase-transition stingers",
            "Bounce stems to `assets/audio/music/bosses/" + il + "/`",
        ], f"{bid} stems loop cleanly"),
        D(f"{lab}: telegraph and attack SFX", [
            f"Design one distinct audio telegraph per {bid} attack (an accessibility cue, not only flavour)",
            "Design swing, impact and projectile SFX",
            "Level-match against the SFX loudness target",
        ], f"{bid} telegraph SFX set delivered"),
        D(f"{lab}: stagger, defeat and Hell stinger", [
            f"Design {bid} stagger, defeat and Hell-phase entry stinger",
            "Create two variants of each high-frequency SFX to avoid repetition",
            "Name files to the SFX naming convention",
        ], f"{bid} reaction SFX delivered"),
        D(f"{lab}: integration and mix in the fight", [
            f"Hook {bid} stems and SFX into the fight with the audio bus layout",
            "Mix against player SFX; telegraphs must cut through on every difficulty",
            "Add the CIN-" + bid + "-IN/OUT sound pass",
        ], f"{bid} fight mix approved by the director"),
        D(f"{lab}: audio-cue accessibility review", [
            f"Play {bid} with music muted and with SFX muted: each telegraph must still have a visual or audio cue",
            "Check sound-cue captions/indicators fire for every telegraph",
            "Fix any cue that relies on stereo position only",
        ], f"{bid} passes the audio-cue accessibility check"),
    ], ["Telegraph SFX masked by the music on the Hell layer", "Stems drift out of sync after pause"],
        f"Audio files under assets/audio/ and a mix note in {ev}")

    ph.add("writing", f"Write boss scenes and barks for {lab}", f"P3 voice + §7 dialogue budget; VOICE_GUIDE.md", ["dialogue", "story", "localization"], [
        D(f"{lab}: intro and outro scenes", [
            f"Write CIN-{bid}-IN and CIN-{bid}-OUT lines in `dialogue/bosses/{il}.dlg` (~{W(ph, 500)} words)",
            f"Branch the outro on {flags}",
            "Read it against VOICE_GUIDE.md and the STORY_BIBLE cast table",
        ], f"{il}.dlg drafted and parses in the dialogue test"),
        D(f"{lab}: combat barks and localization keys", [
            f"Write {bid} phase-change, retry and Hell-phase barks (~{W(ph, 300)} words)",
            "Give every line a string key and a translator note for Simplified Chinese",
            "Run the dialogue test: after the scene `is_active == false`",
        ], f"{bid} barks keyed and extractable"),
    ], ["A retry line repeats on every retry (needs a rotation pool)", "A line refers to a flag the player may not have"],
        f"dialogue/bosses/{il}.dlg passing tests/dialogue_test.gd")

    qd = [
        D(f"{lab}: Beginner and Easy passes", [
            f"Write test cases for {bid} on Beginner and Easy in `production/qa/cases/{ph.pl}/{il}.md`",
            "Play 3 runs each; log deaths, cause and whether the telegraph was readable",
            "Check DDA engages on Beginner and Easy only",
        ], f"{bid} Beginner/Easy cases executed and logged"),
        D(f"{lab}: Medium and Hard passes", [
            f"Play {bid} 3 runs each on Medium and Hard; confirm +variants appear",
            "Run pause, gamepad-disconnect and checkpoint-reload cases",
            "File bugs with repro steps via `/bug-report`",
        ], f"{bid} Medium/Hard cases executed"),
        D(f"{lab}: Hell replay validation", [
            f"Run `tests/integration/bosses/test_{il}_replay.gd` on the release build",
            "Play the Hell phase manually with latency calibration at 0 and at +2 frames",
            f"Attach the fairness notes and screenshots to `{ev}`",
        ], f"{bid} Hell validated: perfect replay wins, one-frame-off loses"),
        D(f"{lab}: accessibility, assists and regression", [
            f"Play {bid} with colourblind modes, high contrast, 200% text and remapped controls",
            "Check the latency calibration and hold/toggle options inside the fight",
            "Re-run the region's earlier boss replays to catch shared-system regressions",
        ], f"{bid} accessibility and regression cases logged"),
    ]
    if ph.lean:
        qd[2]["steps"].append("Spot-check colourblind mode, 200% text and remapped controls in the Hell phase")
        del qd[3]
    ph.add("qa", f"Test boss {lab} on every difficulty", f"P6 + §7 DoD: tuned on all 5 difficulties; Hell replay-verified", ["tests", "difficulty", "combat"], qd,
           ["Latency calibration not applied after options change mid-fight", "Healing charges not restored on retry"],
           f"production/qa/cases/{ph.pl}/{il}.md and {ev}")


def enemy(ph, e):
    eid, reg, arch = e["id"], e["reg"], e["arch"]
    rname, act = REG[reg]
    il = low(eid)
    why = f"§3 50 enemy types; {ph.pid} share for {reg} {rname}"
    ph.add("primary", f"Build enemy type {eid} ({arch}, {reg})", why, ["combat", "ai", "code"], [
        D(f"{eid} ({arch}): EnemyDef and AttackSpecs", [
            f"Create `resources/combat/enemies/{il}.tres` (EnemyDef) and its AttackSpec set",
            "Set per-difficulty damage via DifficultyProfile, not per-enemy constants",
            f"Define its Root Access capability entry (what Kaelen may edit on {eid}, within PM limits)",
            "Choose overworld visibility rules: patrol path, aggro radius, shatter trigger",
        ], f"{eid} data resources load"),
        D(f"{eid}: AI, spawn and invariant tests", [
            f"Implement `scripts/combat/enemies/{il}_ai.gd` on the fixed tick",
            f"Spawn test in `tests/unit/enemies/test_{il}.gd`: spawns in every {rname} arena template",
            "Stat invariants across retries; no reward on despawn without kill",
            "Run the combat_fixes and load_all tests",
        ], f"{eid} spawn and invariant tests green"),
    ], [f"{eid} spawned at an arena edge clips into the kill zone", "Enemy pursuing across a chunk boundary during streaming"],
        f"tests/unit/enemies/test_{il}.gd")
    ead = [
        D(f"{eid}: overworld and side-scroll base", [
            f"Draw {eid}'s overworld sprite (visible in the world, P7a) and side-scroll idle/move",
            f"Match the {rname} palette family",
            "Import through PAE and check pixel snap",
        ], f"{eid} base sprites imported"),
        D(f"{eid}: attack clips", [
            f"Animate {eid} attacks with clear anticipation frames",
            "Tag active frames to the AttackSpec names",
            "Run the frame-data test after export",
        ], f"{eid} attacks frame-matched"),
        D(f"{eid}: reactions and elite palette", [
            f"Animate {eid} hit, stagger and death",
            "Make one palette variant for elite spawns",
            "Screenshot in an arena for review",
        ], f"{eid} reactions and variant delivered"),
    ]
    if ph.lean:
        ead[1] = D(f"{eid}: attack and reaction clips", [
            f"Animate {eid} attacks with clear anticipation frames; tag active frames to AttackSpec names",
            f"Animate {eid} hit, stagger and death, plus one elite palette variant",
            "Run the frame-data test after export; screenshot in an arena",
        ], f"{eid} attacks and reactions delivered")
        del ead[2]
    ph.add("art", f"Animate enemy type {eid} ({arch})", why, ["art", "animation", "assets"], ead, [f"{eid} silhouette confused with a friendly NPC in the overworld", "Death clip leaves a frame on screen after despawn"],
        f"assets/sprites/enemies/{il}/ plus {ph.ev(eid)}")
    ph.add("audio", f"Sound enemy type {eid}", why, ["audio", "combat"], [
        D(f"{eid}: SFX set", [
            f"Design {eid} idle, alert, attack telegraph, hit and death SFX (2 variants each)",
            "Match the audio telegraph to the anticipation frames",
            "Implement and level-check in the arena test scene",
        ], f"{eid} SFX in the build"),
    ], ["Alert SFX spam when several spawn at once (needs a voice limit)"], f"assets/audio/sfx/enemies/{il}/")
    ph.add("qa", f"Test enemy type {eid}", why, ["tests", "combat", "difficulty"], [
        D(f"{eid}: spawn, difficulty and Root Access cases", [
            f"Fight {eid} on Beginner, Medium and Hell; log time-to-kill and damage taken",
            f"Try every Root Access edit on {eid}; forbidden edits must be refused",
            "Check overworld contact always starts the shatter transition",
        ], f"{eid} cases logged in production/qa/cases/{ph.pl}/enemies.md"),
    ], [f"Two {eid} touching the player on the same frame start two fights"], f"production/qa/cases/{ph.pl}/enemies.md")


TIMING_P = {
    "window": ("window", "available only on days X-Y or during its event; closes with a signpost first"),
    "deadline": ("deadline", "complete within N in-game days, scaled by leniency ×1.5 / ×1.25 / ×1.0 / ×1.0 / ×0.85"),
    "order": ("order", "doing it before or after its paired quest changes its outcome"),
    "duration": ("duration", "finishing fast or slow changes the outcome flag"),
}


def quest(ph, q):
    qid, reg, kind = q["id"], q["reg"], q["kind"]
    rname, act = REG[reg]
    il = low(qid)
    timing = q.get("timing")
    feeds = q["feeds"]
    structure = q["structure"]
    ss = q.get("ss")
    secret = kind == "secret"
    label = f"{qid} ({'secret' if secret else 'side'}, {reg} {rname}, {structure}"
    label += f", {timing}" if timing else ""
    label += f", {ss}" if ss else ""
    label += ")"
    feed_txt = AXES.get(feeds, feeds)
    why = f"P5{' + P7f' if timing else ''} + §7 {ph.pid}: {act} {'secret' if secret else 'side'} quest feeding {feed_txt}"
    ev = ph.ev(qid)
    tags_p = ["quests", "code", "tests"] + (["time"] if timing else [])
    pdays = [
        D(f"{qid}: quest graph, flags and rewards", [
            f"Author `data/quests/{reg.lower()}/{il}.tres` in the quest editor: stages, objectives, fail states",
            f"Write its outputs through FlagRegistry ({feed_txt}); boot validation must find a writer for every read",
            "Grant rewards via RewardLedger `grant_once`; value checked against the economy rules",
            f"Add the bot path for {qid} to `tests/reachability_test.gd`",
        ], f"{qid} completes via the bot and passes boot validation"),
    ]
    if timing:
        nm, rule = TIMING_P[timing]
        pdays.append(D(f"{qid}: {nm} timing rule on the WorldClock", [
            f"Implement the {nm} rule for {qid}: {rule}",
            "Add the quest-log entry with its in-world reason and the signpost NPC line hook",
            f"Add {qid} to the bot's fast, slow and out-of-order timing profiles",
            f"Test with a seeded clock in `tests/integration/quests/test_{il}_timing.gd`",
        ], f"{qid} timing outcomes differ as designed under all 3 bot profiles"))
    if secret and feeds != "H":
        pdays[0]["steps"].append(f"Implement the hidden trigger ({q['trigger']}); no quest-log entry until found; secret-hunt bot profile reaches it")
    if secret and feeds == "H":
        pdays.append(D(f"{qid}: hidden trigger and discovery", [
            f"Implement {qid}'s hidden trigger ({q['trigger']}) with no quest-log entry until found",
            "Make it discoverable without a guide: one in-world hint placed by the level designer",
            ("Write the hidden 4th-axis value for the Witness Protocol route into the ending composer inputs"
             if feeds == "H" else "Record discovery in the storyline coverage viewer"),
            "Confirm the bot can reach it with the secret-hunt profile",
        ], f"{qid} is found by the secret-hunt bot profile"))
    ph.add("primary", f"Implement quest {label}", why, tags_p, pdays,
           [f"Save mid-{qid} then load into a newer build", "Abandon and re-accept", "Complete objective out of order"]
           + (["Sleep through the whole window/deadline in one rest", "Change difficulty while the timer runs"] if timing else []),
           f"tests/integration/quests/test_{il}.gd and the reachability bot log")
    sdays = [
        D(f"{qid}: placement, signposting and draft review", [
            f"Place the {qid} giver, objectives and any props in the {rname} chunk groups",
            ("Place the single in-world hint for the hidden trigger" if secret else "Add a map marker rule and one signpost NPC line"),
            "Review the writer's outline and draft against the route table",
            "Play it through on Medium and note pacing problems",
        ], f"{qid} placed and its draft reviewed with notes"),
    ]
    if not ph.lean:
        sdays.append(D(f"{qid}: integration playthrough and sign-off", [
            f"Play {qid} on a fresh save and on a late save with other {reg} quests done",
            "Check NPC reactions and reputation changes it causes are visible",
            ("Check the timing signpost appears before the limit" if timing else "Check the reward feels worth the detour (fun note)"),
            f"Sign off in `production/reviews/{ph.pl}/quests.md`",
        ], f"{qid} signed off"))
    ph.add("secondary", f"Place and review quest {qid}", why, ["level", "quests", "team"], sdays,
           ["Quest giver's schedule puts them off-map at night"], f"production/reviews/{ph.pl}/quests.md entry for {qid}")
    words = 1500 if secret else 1200
    wdays = [
        D(f"{qid}: outline from IDs and flags", [
            f"Outline {qid} beats from its structure ({structure}), what it feeds ({feed_txt}) and its flags; no new canon beyond STORY_BIBLE.md",
            "Set the word budget and list speakers",
            "Get the outline approved by the director",
        ], f"{qid} outline approved"),
        D(f"{qid}: dialogue draft", [
            f"Draft `dialogue/quests/{reg.lower()}/{il}.dlg` (~{W(ph, words)} words)",
            "Branch on the quest's outcome flags and companion presence",
            ("Write the in-world reason for the timing rule and the warning line" if timing else "Write the completion and refusal lines"),
            "Run the dialogue test to confirm it parses and closes",
        ], f"{il}.dlg drafted and green in the dialogue test"),
        D(f"{qid}: revision, journal text and string keys", [
            "Revise against VOICE_GUIDE.md and the director's notes",
            "Write the quest-log and journal entries",
            "Key every string for extraction and add translator notes",
        ], f"{qid} text final and extractable"),
    ]
    if ph.lean and not secret and not ss:
        wdays = [
            D(f"{qid}: outline and dialogue draft", [
                f"Outline {qid} from its structure ({structure}) and what it feeds ({feed_txt}); no new canon beyond STORY_BIBLE.md",
                f"Draft `dialogue/quests/{reg.lower()}/{il}.dlg` (~{W(ph, words)} words)",
                ("Write the in-world reason for the timing rule and the warning line" if timing else "Write completion and refusal lines"),
                "Run the dialogue test",
            ], f"{il}.dlg drafted and green in the dialogue test"),
            wdays[2],
        ]
        ph.words -= words  # the replaced 3-day draft token is not emitted
    ph.add("writing", f"Write quest {qid}", why, ["dialogue", "quests", "story", "localization"], wdays,
           ["A branch line assumes a companion who left the party"], f"dialogue/quests/{reg.lower()}/{il}.dlg")
    qdays = [
        D(f"{qid}: test cases and completion", [
            f"Write {qid} cases (main path, refusal, abandon, save/load mid-quest)",
            "Complete on Beginner and Hard; check rewards granted once",
            "Verify every string shows through the extraction pipeline",
        ], f"{qid} cases executed; bugs filed"),
        D(f"{qid}: automation and text pass", [
            f"Extend `tests/integration/quests/test_{il}.gd` with the manual cases that can be automated",
            "Pseudo-localized build: check every quest string fits its box",
            "Re-test after the writer's revision lands",
        ], f"{qid} automated checks green and text pass logged"),
    ]
    if timing:
        qdays.append(D(f"{qid}: timing-profile cases", [
            f"Run {qid} early, on time and late; check each outcome flag",
            "Rest through the limit; the signpost warning must appear first",
            "Repeat on Beginner (×1.5 leniency) and Hell (×0.85)",
        ], f"{qid} timing outcomes verified on 2 leniency profiles"))
    ph.add("qa", f"Test quest {qid}", why, ["tests", "quests"] + (["time"] if timing else []), qdays,
           ["Quest item sold to a merchant mid-quest", "Load a save made before the quest existed"],
           f"production/qa/cases/{ph.pl}/{il}.md and {ev}")


def side_storyline(ph, s):
    sid, regs, feeds, members = s["id"], s["regs"], s["feeds"], s["members"]
    il = low(sid)
    feed_txt = AXES[feeds]
    rtxt = "/".join(regs)
    mtxt = ", ".join(members)
    why = f"P5 + §3 12 side storylines; {sid} writes into {feed_txt}"
    note = s.get("note", "")
    ph.add("primary", f"Wire side storyline {sid} ({rtxt}) into {feeds}", why, ["quests", "story", "systems", "tests"], [
        D(f"{sid}: arc state and axis write", [
            f"Create the {sid} arc state in StoryGraph linking {mtxt}",
            f"Write its result into {feed_txt} through FlagRegistry (confirm the mapping against the Y2 route lock)",
            "Expose arc progress to the storyline coverage viewer",
            "Handle partial completion: what the composer reads if the arc is abandoned",
        ], f"{sid} arc state advances across its member quests"),
        D(f"{sid}: permutation tests", [
            f"Write `tests/integration/storylines/test_{il}.gd`: complete members in every legal order",
            "Assert the axis value the composer receives for each permutation",
            "Add the arc to the nightly bot run",
        ], f"{sid} permutation test green"),
    ], ["Member quest completed before the arc is known", "One member failed by timing"], f"tests/integration/storylines/test_{il}.gd")
    ph.add("secondary", f"Direct side storyline {sid}", why, ["story", "quests", "level", "team"], [
        D(f"{sid}: arc structure review", [
            f"Review the {sid} arc outline against the route table and {feed_txt}{note}",
            f"Check member quests {mtxt} are spaced through {rtxt} so the arc is discoverable",
            "Approve or return the outline with notes",
        ], f"{sid} outline approved"),
        D(f"{sid}: integration playthrough", [
            f"Play {sid} start to finish on a debug build",
            "Check the arc's effect is visible later (scene or NPC reaction)",
            "Log pacing notes and sign off",
        ], f"{sid} signed off in production/reviews/{ph.pl}/storylines.md"),
    ], ["Arc effect invisible to the player before the ending"], f"production/reviews/{ph.pl}/storylines.md")
    ph.add("writing", f"Write side storyline {sid} connective scenes", why, ["dialogue", "story", "quests"], [
        D(f"{sid}: arc bible page", [
            f"Write `story/side_storylines/{il}.md`: purpose, members {mtxt}, which axis value each outcome feeds",
            "No canon beyond STORY_BIBLE.md; mark anything new as proposed",
            "Get director approval",
        ], f"{sid} arc page approved"),
        D(f"{sid}: opening and bridge scenes", [
            f"Draft the {sid} opening and bridge scenes (~{W(ph, 1200)} words)",
            "Link each scene to the member quest that triggers it",
            "Run the dialogue test",
        ], f"{sid} opening and bridges parse"),
        D(f"{sid}: finale scene variants", [
            f"Draft the {sid} finale with one variant per axis outcome (~{W(ph, 1000)} words)",
            "Write the ending-composer slide line for each outcome",
            "Run the dialogue test",
        ], f"{sid} finale variants drafted"),
        D(f"{sid}: revision and string keys", [
            "Revise all scenes against VOICE_GUIDE.md",
            "Key strings; add translator notes",
            "Hand to QA",
        ], f"{sid} text final"),
    ], ["Finale references a member quest the player skipped"], f"story/side_storylines/{il}.md and dialogue files")
    ph.add("art", f"Key art and props for {sid}", why, ["art", "assets"], [
        D(f"{sid}: finale props and slide illustration", [
            f"Draw the props the {sid} finale needs and its ending-composer slide illustration",
            "Import and place with the director",
            "Screenshot for review",
        ], f"{sid} art delivered"),
    ], ["Slide illustration unreadable at 720p"], f"{ph.ev(sid)}")
    ph.add("audio", f"Motif for {sid}", why, ["audio", "music"], [
        D(f"{sid}: arc motif and finale stinger", [
            f"Write a short {sid} motif usable as a stinger and as a layer in its region track",
            "Bounce and implement on the finale trigger",
            "Mix check with dialogue",
        ], f"{sid} motif in the build"),
    ], ["Stinger collides with the quest-complete jingle"], "assets/audio/music/storylines/")
    ph.add("qa", f"Test side storyline {sid}", why, ["tests", "quests", "story"], [
        D(f"{sid}: arc-wide order cases", [
            f"Run {sid} members in 3 different orders; check the axis value each time",
            "Save at each bridge and load in a fresh session",
            "Check the coverage viewer shows the arc state",
        ], f"{sid} order cases pass"),
        D(f"{sid}: bot and timing cases", [
            f"Run the nightly bot on {sid} with fast and slow timing profiles",
            "Abandon the arc midway and confirm the composer default",
            f"Store logs in {ph.ev(sid)}",
        ], f"{sid} bot coverage logged"),
    ], ["Arc stuck if a member quest fails by deadline"], f"{ph.ev(sid)}")


def npc_b_batch(ph, b):
    bid, reg, ids = b["id"], b["reg"], b["ids"]
    rname, act = REG[reg]
    rng = f"{ids[0]}..{ids[-1]}"
    why = f"P4 + §12.3 Tier B (daily schedule, 5-10 memory facts, barks, mini-arc); {ph.pid} {reg}"
    roles = b["roles"]
    ph.add("primary", f"Implement Tier B NPCs {rng} ({reg} {rname})", why, ["npc", "systems", "time", "tests"], [
        D(f"{rng}: schedules, memory and barks data", [
            f"Author schedule resources for {rng} in the NPC schedule editor (calendar-aware: market days, festivals)",
            "Define 5-10 memory facts each and bark triggers to player state and time",
            f"Hook roles ({roles}) into the market as traders where flagged",
            "Off-screen NPCs advance only their schedule (simulation LOD)",
        ], f"{rng} schedules load and run for 7 in-game days"),
    ], ["NPC asleep when its quest needs it", "Merchant NPC killed or jailed by crime system"], f"tests/integration/npc/test_{low(bid)}.gd")
    ph.add("secondary", f"Place Tier B NPCs {rng}", why, ["npc", "level"], [
        D(f"{rng}: placement and schedule review", [
            f"Place {rng} in {rname} town and road chunks; check schedule paths are walkable",
            "Review barks for repetition across a full in-game day",
            "Approve mini-arc outlines from the writer",
        ], f"{rng} placed and reviewed"),
    ], ["Two schedules collide in a doorway"], f"production/reviews/{ph.pl}/npcs.md")
    ph.add("art", f"Sprites for Tier B NPCs {rng}", why, ["art", "animation", "npc"], [
        D(f"{rng}: 4-direction walk sets (first half)", [
            f"Draw 4-direction idle/walk sets for {ids[0]}..{ids[2]}",
            f"Fit the {rname} costume rules in the art bible",
            "Import and check in the schedule test scene",
        ], f"{ids[0]}..{ids[2]} sprites in"),
        D(f"{rng}: walk sets (second half) and portraits", [
            f"Draw 4-direction sets for {ids[3]}..{ids[-1]}",
            f"Draw dialogue portraits for all of {rng}",
            "Review with the director",
        ], f"{rng} sprites and portraits in"),
    ], ["Portrait palette mismatched with sprite palette"], f"assets/sprites/npc/{reg.lower()}/")
    ph.add("writing", f"Write Tier B NPCs {rng}", why, ["dialogue", "npc"], [
        D(f"{rng}: profiles and memory facts", [
            f"Write profile cards for {rng}: role, schedule beats, the 5-10 facts they remember",
            "Check against the STORY_BIBLE cast; nothing contradicts canon",
            "Get approval",
        ], f"{rng} profiles approved"),
        D(f"{rng}: barks to state and time", [
            f"Write barks for {rng}: time of day, weather/season, player reputation, crime witnessed (~{W(ph, 900)} words)",
            "Key strings",
            "Run the dialogue test",
        ], f"{rng} bark pools in"),
        D(f"{rng}: mini-arc lines", [
            f"Write the mini-arc or quest hook lines for {rng} (~{W(ph, 700)} words)",
            "Revise against VOICE_GUIDE.md",
            "Hand to QA",
        ], f"{rng} mini-arcs drafted"),
    ], ["Bark refers to a festival that the calendar moved"], f"dialogue/npc/{reg.lower()}/")
    ph.add("qa", f"Test Tier B NPCs {rng}", why, ["tests", "npc", "time"], [
        D(f"{rng}: 7-day schedule and memory cases", [
            f"Fast-forward 7 in-game days and check {rng} reach every schedule point",
            "Trigger 3 memory facts each and check the reaction",
            "Save/load mid-schedule and verify position",
        ], f"{rng} cases logged"),
    ], ["Schedule broken by a fast-travel arrival"], f"production/qa/cases/{ph.pl}/npcs.md")


def tier_a(ph, a):
    aid, reg, name = a["id"], a["reg"], a["name"]
    rname, act = REG[reg]
    lab = f"{aid} ({name})"
    il = low(aid)
    why = f"P4 + §12.3 Tier A: full calendar schedule, 20+ memory facts, contextual dialogue, arc + Story+"
    voice = a.get("voice_only", False)
    ph.add("primary", f"Tier A work: {lab}", why, ["npc", "systems", "story", "tests"], [
        D(f"{lab}: calendar schedule and memory", [
            f"Author {aid}'s full calendar-aware schedule (or presence rules, if voice-only)",
            "Define 20+ memory facts and the contextual dialogue selectors that read them",
            "Wire reactions to the act pace value and timing flags",
            "Off-screen LOD rules",
        ], f"{aid} memory facts readable in the debug inspector"),
        D(f"{lab}: arc state and tests", [
            f"Create {aid}'s arc state in StoryGraph with its Story+ hook",
            f"Test `tests/integration/npc/test_{il}.gd`: facts set by 3 earlier scenes change later lines",
            "Add to the bot's coverage report",
        ], f"{aid} arc test green"),
    ], ["Fact set twice from two routes", "Character absent on a festival day"], f"tests/integration/npc/test_{il}.gd")
    ph.add("secondary", f"Direct Tier A {lab}", why, ["npc", "story", "level"], [
        D(f"{lab}: arc review and staging", [
            f"Review {aid}'s arc outline against STORY_BIBLE.md",
            "Stage their key locations in the world",
            "Play their scenes in order",
        ], f"{aid} staged and reviewed"),
    ], ["Arc scene blocked by another NPC's schedule"], f"production/reviews/{ph.pl}/tier_a.md")
    ph.add("art", f"Tier A art: {lab}", why, ["art", "animation", "npc", "ui"] if voice else ["art", "animation", "npc"], [
        D(f"{lab}: {'voice presentation' if voice else 'sprite set'}", [
            (f"Design the text-box and glitch-overlay treatment for {name}; no sprite (identity stays uncertain until NG+)"
             if voice else f"Draw {name}'s 4-direction sprite set plus 3 schedule-specific clips"),
            "Match the art bible",
            "Import and review",
        ], f"{aid} visuals in"),
        D(f"{lab}: {'transition effects' if voice else 'portrait expressions'}", [
            ("Make the subtle desync effect used when the Voice speaks; keep it readable" if voice
             else f"Draw 6 portrait expressions for {name}"),
            "Check against accessibility (photosensitivity: no rapid flashing)",
            "Hand off",
        ], f"{aid} expressions/effects in"),
    ], ["Effect triggers photosensitivity warning threshold"], f"{ph.ev(aid)}")
    ph.add("writing", f"Write Tier A {lab}", why, ["dialogue", "story", "npc"], [
        D(f"{lab}: arc outline", [
            f"Outline {name}'s {ph.pid} arc beats from STORY_BIBLE.md; mark anything new as proposed",
            "List the 20+ memory facts with their source scenes",
            "Approval from director",
        ], f"{aid} outline approved"),
        D(f"{lab}: contextual dialogue (part 1)", [
            f"Write {name}'s contextual lines for facts 1-10 (~{W(ph, 1000)} words)",
            "Key strings",
            "Run the dialogue test",
        ], f"{aid} part 1 lines in"),
        D(f"{lab}: contextual dialogue (part 2)", [
            f"Write {name}'s lines for facts 11-20+ and pace/timing reactions (~{W(ph, 1000)} words)",
            "Revise against VOICE_GUIDE.md",
            "Run the dialogue test",
        ], f"{aid} part 2 lines in"),
        D(f"{lab}: arc scenes", [
            f"Write {name}'s {ph.pid} arc scenes (~{W(ph, 800)} words)",
            "Key strings and translator notes",
            "Hand to QA",
        ], f"{aid} arc scenes final"),
    ], ["Line references a fact from a route the player did not take"], f"dialogue/npc/tier_a/{il}.dlg")
    ph.add("qa", f"Test Tier A {lab}", why, ["tests", "npc"], [
        D(f"{lab}: memory and schedule cases", [
            f"Set 5 different fact combinations for {aid}; check each contextual line",
            "Check the schedule across a festival and a market day",
            "Save/load across a fact change",
        ], f"{aid} cases logged"),
    ], ["Contextual line picks the wrong fact priority"], f"production/qa/cases/{ph.pl}/tier_a.md")


def companion(ph, c):
    cid, name, reg = c["id"], c["name"], c["reg"]
    rname, act = REG[reg]
    lab = f"{cid} ({name})"
    il = low(cid)
    why = f"§3 8 companions; companion rule: two scenes contradicting their expected stance (STORY_BIBLE §4)"
    cp = [
        D(f"{lab}: follow and party state", [
            f"Implement {cid} overworld follow, party join/leave flags and fast-travel handling",
            "Relationship value with change log for the debug inspector",
            "Persist through SaveService; migration test for the new block",
            "Leave room for Y4 synergies (data-driven assist slot)",
        ], f"{cid} joins, follows and survives save/load"),
        D(f"{lab}: combat assist ability", [
            f"Implement {cid}'s assist as data (AttackSpec + cooldown); no companion command menu (bible rule)",
            "Respect DifficultyProfile damage scaling",
            "Hitstop/FeelService feedback on assist hits",
            "Unit test the cooldown on the fixed tick",
        ], f"{cid} assist triggers and respects cooldown"),
        D(f"{lab}: banter and camp triggers", [
            f"Wire {cid}'s banter triggers (location, flags, time, relationship bands)",
            "Camp scene selector reading relationship and act pace",
            "No-repeat rotation for banter",
            "Debug command to force each trigger",
        ], f"{cid} banter fires in 5 test locations"),
        D(f"{lab}: integration tests", [
            f"Test `tests/integration/companions/test_{il}.gd`: join, leave, rejoin, death-in-arena, save/load",
            "Run the chapter route tests with the companion present",
            f"Screenshots to {ph.ev(cid)}",
        ], f"{cid} integration test green"),
    ]
    if ph.lean:
        cp[0]["steps"][3] = f"Wire {cid}'s banter and camp triggers (location, flags, time, relationship band) with a no-repeat rotation"
        del cp[2]
    ph.add("primary", f"Companion systems for {lab}", why, ["npc", "combat", "systems", "tests"], cp, ["Companion leaves mid-quest that needs them", "Assist during boss invulnerable window"], f"tests/integration/companions/test_{il}.gd")
    ph.add("secondary", f"Direct companion {lab}", why, ["story", "npc", "team"], [
        D(f"{lab}: arc direction", [
            f"Review {name}'s {ph.pid} arc and the two contradiction scenes",
            "Place camp and banter locations",
            "Brief art and writing",
        ], f"{cid} arc direction written"),
        D(f"{lab}: integrated review", [
            f"Play a full region with {name} in the party",
            "Note banter frequency and assist feel",
            "Sign off or return notes",
        ], f"{cid} signed off"),
    ], ["Banter overlaps a cinematic"], f"production/reviews/{ph.pl}/companions.md")
    ph.add("art", f"Companion art for {lab}", why, ["art", "animation"], [
        D(f"{lab}: overworld 4-direction set", ["Draw idle/walk/run in 4 directions", "Follow-path offset frames", "Import and check"], f"{cid} overworld set in"),
        D(f"{lab}: side-scroll assist clips", [f"Animate {name}'s assist and entry/exit clips", "Tag frames to the assist AttackSpec", "Import"], f"{cid} assist clips in"),
        D(f"{lab}: portraits and expressions", [f"Draw 8 portrait expressions for {name}", "Check against the art bible", "Import"], f"{cid} portraits in"),
        D(f"{lab}: assist VFX and camp pose", [f"Make {name}'s assist VFX in the pooled set", "Draw camp idle pose", "Review"], f"{cid} VFX and camp pose in"),
    ], ["Assist VFX hides an enemy telegraph"], f"assets/sprites/companions/{il}/")
    ph.add("audio", f"Companion audio for {lab}", why, ["audio", "music"], [
        D(f"{lab}: motif and assist SFX", [f"Write {name}'s motif for camp and arc scenes", "Design assist SFX", "Implement and mix"], f"{cid} audio in"),
    ], ["Motif clashes with region track key"], "assets/audio/companions/")
    ph.add("writing", f"Write companion {lab}", why, ["dialogue", "story"], [
        D(f"{lab}: arc beats", [f"Outline {name}'s {ph.pid} beats from STORY_BIBLE.md", "Mark the two contradiction scenes", "Approval"], f"{cid} beats approved"),
        D(f"{lab}: contradiction scene 1", [f"Draft contradiction scene 1 (~{W(ph, 700)} words)", "Branch on relationship band", "Dialogue test"], f"{cid} scene 1 drafted"),
        D(f"{lab}: contradiction scene 2", [f"Draft contradiction scene 2 (~{W(ph, 700)} words)", "Branch on act pace", "Dialogue test"], f"{cid} scene 2 drafted"),
        D(f"{lab}: banter pool", [f"Write ~40 banter lines (~{W(ph, 900)} words)", "Tag triggers", "Key strings"], f"{cid} banter pool in"),
        D(f"{lab}: camp scenes", [f"Write camp scenes per relationship band (~{W(ph, 800)} words)", "Read against VOICE_GUIDE.md", "Dialogue test"], f"{cid} camp scenes in"),
        D(f"{lab}: revision and reactions", [f"Write {name}'s reactions to the region's main flags (~{W(ph, 500)} words)", "Revise all", "Hand to QA"], f"{cid} text final"),
    ], ["Banter refers to an event the player skipped"], f"dialogue/companions/{il}/")
    ph.add("qa", f"Test companion {lab}", why, ["tests", "npc"], [
        D(f"{lab}: party and save cases", [f"Join/leave/rejoin {cid}; save/load each state", "Fast travel with the companion", "Arena entry/exit"], f"{cid} party cases logged"),
        D(f"{lab}: banter and assist cases", [f"Trigger each banter tag once", "Assist on every difficulty", "Check no banter during cinematics"], f"{cid} banter/assist cases logged"),
    ], ["Companion stuck behind a door after fast travel"], f"production/qa/cases/{ph.pl}/companions.md")


def crowd(ph, c):
    cid, reg, n = c["id"], c["reg"], c["n"]
    rname, act = REG[reg]
    why = f"§12.3 Tier C (~200): simple schedule, reputation memory, barks; {ph.pid} {reg}"
    ph.add("primary", f"Tier C crowd {cid} ({n} NPCs, {reg})", why, ["npc", "performance", "openworld"], [
        D(f"{cid}: spawner, LOD and reputation", [
            f"Configure {n} Tier C NPCs in {rname} from body bases + overlays",
            "Cap active simulated NPCs per chunk; check the budget in the profiler",
            "Reputation-only memory; barks to reputation band",
            "Run the streaming hitch test (< 2 ms)",
        ], f"{cid} crowd within chunk budget"),
    ], ["Crowd blocks a quest NPC path"], f"{ph.ev(cid)} profiler capture")
    ph.add("art", f"Tier C bases and overlays {cid}", why, ["art", "assets", "npc"], [
        D(f"{cid}: body bases", [f"Draw {rname} crowd body bases (4-direction walk)", "Palette-swap sets", "Import"], f"{cid} bases in"),
        D(f"{cid}: overlays and variety check", ["Draw overlay layers (hats, tools, cloaks)", f"Generate {n} combinations and screenshot", "Remove clashing combos"], f"{cid} variety approved"),
    ], ["Overlay misaligned on one walk frame"], f"assets/sprites/crowd/{reg.lower()}/")
    ph.add("writing", f"Tier C barks {cid}", why, ["dialogue", "npc"], [
        D(f"{cid}: reputation bark pool", [f"Write {rname} crowd barks per reputation band (~{W(ph, 600)} words)", "Add time-of-day and crime-reaction variants", "Key strings"], f"{cid} barks in"),
    ], ["Bark contradicts current faction state"], f"dialogue/crowd/{reg.lower()}.dlg")
    ph.add("qa", f"Test crowd {cid}", why, ["tests", "npc", "performance"], [
        D(f"{cid}: density and reputation cases", ["Walk the town at noon and at night; record fps", "Change reputation band; check barks", "Commit a crime; check witness reactions"], f"{cid} cases logged"),
    ], ["Crowd re-spawns visibly on screen"], f"production/qa/cases/{ph.pl}/crowds.md")


def item_batch(ph, b, with_writing, with_qa):
    bid, cat, reg = b["id"], b["cat"], b["reg"]
    why = f"P7e + §3 ~450 items ({cat}); {ph.pid} batch for {reg}"
    ph.add("primary", f"Author items {bid} ({cat})", why, ["items", "economy", "tests"], [
        D(f"{bid}: ItemDB entries, affixes and recipes", [
            f"Add {bid} to ItemDB `.tres` with the item editor: rarity, affix table, slot, set id where relevant",
            "Add crafting recipes; crafted value ≤ 90% of inputs' market value unless upgraded by skill (§12.6)",
            "Sell price ≤ 40% of buy price; run the anti-exploit unit test",
            "Check weapon-class sprite or palette/overlay mapping (no paper-doll, §12.9)",
        ], f"{bid} loads and the anti-exploit test passes"),
    ], ["Affix stacking past cap", "Recipe loop that creates value"], "tests/unit/items/test_item_rules.gd")
    ph.add("art", f"Icons and visuals for {bid}", why, ["art", "items", "assets"], [
        D(f"{bid}: icons and equip visuals", [
            f"Draw 10 icons for {bid} ({cat})",
            "Make palette/overlay or weapon-class sprites where equippable",
            "Check icons at inventory scale and in high-contrast mode",
        ], f"{bid} icons imported"),
    ], ["Icon unreadable at 1x"], f"assets/icons/items/ ({bid})")
    if with_writing:
        ph.add("writing", f"Descriptions for {with_writing}", why, ["items", "dialogue", "localization"], [
            D(f"{with_writing}: descriptions", [
                f"Write names and descriptions for {with_writing} (~{W(ph, 600)} words)",
                "Keep lore in line with STORY_BIBLE §2 (magic is an interface, not 'just code')",
                "Key strings",
            ], f"{with_writing} text in"),
        ], ["Name collides with an existing item"], "data/items/strings")
    if with_qa:
        ph.add("qa", f"Test items {with_qa}", why, ["tests", "items", "economy"], [
            D(f"{with_qa}: craft, equip and price cases", [
                f"Craft, equip, salvage and sell every item in {with_qa}",
                "Check set bonuses and affix caps",
                "Run the headless economy sim for 100 days with the new items",
            ], f"{with_qa} cases pass"),
        ], ["Salvage returns more than input"], f"production/qa/cases/{ph.pl}/items.md")


def commodity_batch(ph, b):
    bid, cat = b["id"], b["cat"]
    why = f"P7b + §3 ~120 commodities ({cat})"
    ph.add("primary", f"Add commodities {bid} ({cat})", why, ["economy", "systems", "tests"], [
        D(f"{bid}: commodity data and price terms", [
            f"Add {bid} with base price, seasonality curve on the WorldClock calendar, demand weights",
            "Assign NPC trader roles (gatherers, merchants, collectors) that buy/sell them",
            "Add to sources/sinks tracking",
            "Run the 365-day headless economy sim in CI; inflation within bounds",
        ], f"{bid} in the market and the sim stays in bounds"),
    ], ["Seasonal price spike creates an arbitrage loop"], "economy sim CI log")
    ph.add("art", f"Commodity icons {bid}", why, ["art", "economy", "assets"], [
        D(f"{bid}: icons", [f"Draw icons for {bid}", "Check in the market UI", "Import"], f"{bid} icons in"),
    ], ["Two commodities share a near-identical icon"], "assets/icons/commodities/")


def auction_house(ph, a):
    aid, reg = a["id"], a["reg"]
    rname, act = REG[reg]
    il = low(aid)
    why = f"P7b + §12.6: one auction house per major city (4); {aid} in {reg} {rname}"
    apd = [
        D(f"{aid}: venue config and lot schedule", ["Configure lots on in-game time (start, end, extension rules)", f"Lot pool for {rname}: commodities, items, limited editions", "Fee as currency sink"], f"{aid} lots open and close on the clock"),
        D(f"{aid}: NPC bidders", ["Bidder budgets and preferences per city", "Anti-sniping cap via NPC behaviour (§12.6)", "Bidder memory of player wins"], f"{aid} NPC bidders bid in a 30-day sim"),
        D(f"{aid}: player bidding and listing", ["Player bid flow through ContextStack UI context", "Listing caps: 3 active lots, weekly cap", "Escrow and refund on outbid"], f"{aid} player bid/list works"),
        D(f"{aid}: save state", ["Serialize lots, bids and escrow in SaveService", "Migration test for the new block", "Load mid-auction and resume"], f"{aid} round-trips save/load"),
        D(f"{aid}: economy sim coverage", ["Add the auction to the headless economy sim", "Exploit probes: sniping, self-dealing via NPCs, fee avoidance", "Fix any loop found"], f"{aid} sim stays in bounds"),
        D(f"{aid}: tests", [f"`tests/integration/economy/test_{il}.gd`: listing caps, fee, refund", "Run `/balance-check` on fees", f"Evidence to {ph.ev(aid)}"], f"{aid} tests green"),
    ]
    if ph.lean:
        apd[3] = D(f"{aid}: save state and tests", ["Serialize lots, bids and escrow in SaveService with a migration test",
                                                    f"`tests/integration/economy/test_{il}.gd`: listing caps, fee, refund, load mid-auction",
                                                    "Run `/balance-check` on fees"], f"{aid} saves and tests green")
        del apd[5]
    ph.add("primary", f"Build auction house {aid} ({reg} {rname})", why, ["economy", "systems", "time", "save", "tests"], apd, ["Auction ends during a cutscene", "Player bids then sleeps past the end"], f"tests/integration/economy/test_{il}.gd")
    ph.add("secondary", f"Direct auction house {aid}", why, ["level", "economy", "ux"], [
        D(f"{aid}: venue level design", [f"Lay out the {aid} venue in {rname}", "Place the auctioneer and bidder crowd", "Signpost limited-edition lots"], f"{aid} venue blocked out"),
        D(f"{aid}: UX review", ["Run `/ux-review` on the bid and list screens", "Gamepad-only pass", "Return notes"], f"{aid} UX reviewed"),
        D(f"{aid}: sign-off", ["Play 3 auctions start to finish", "Check fee/sink numbers on the economy dashboard", "Sign off"], f"{aid} signed off"),
    ], ["Bid screen unreadable at 200% text scale"], f"production/reviews/{ph.pl}/{il}.md")
    ph.add("art", f"Auction house art {aid}", why, ["art", "ui", "assets"], [
        D(f"{aid}: venue tiles", ["Draw the venue interior tiles and props", "Import into the chunk", "Review"], f"{aid} venue art in"),
        D(f"{aid}: auctioneer sprite", ["Draw the auctioneer 4-direction set and gavel clip", "Portrait", "Import"], f"{aid} auctioneer in"),
        D(f"{aid}: UI panels", ["Draw lot cards, bid panel and timer widgets per the UI theme", "High-contrast variant", "Import"], f"{aid} UI art in"),
        D(f"{aid}: polish pass", ["Lighting and decals in the venue", "Crowd overlay variants", "Screenshots"], f"{aid} polished"),
    ], ["Timer widget too small on Steam Deck screen"], f"{ph.ev(aid)}")
    ph.add("audio", f"Auction house audio {aid}", why, ["audio"], [
        D(f"{aid}: SFX", ["Gavel, bid, outbid, win SFX", "UI ticks for the timer", "Implement"], f"{aid} SFX in"),
        D(f"{aid}: ambience", ["Venue ambience bed with crowd intensity driven by bidding", "Mix with the auction track", "Implement"], f"{aid} ambience in"),
    ], ["Outbid SFX missing when the menu is closed"], "assets/audio/auction/")
    ph.add("writing", f"Auction house text {aid}", why, ["dialogue", "economy"], [
        D(f"{aid}: auctioneer barks", [f"Write auctioneer barks (~{W(ph, 500)} words)", "Lot-call variants", "Key strings"], f"{aid} barks in"),
        D(f"{aid}: lot descriptions", [f"Write lot descriptions for the {rname} pool (~{W(ph, 500)} words)", "Signpost text for limited lots", "Key strings"], f"{aid} lot text in"),
    ], ["Lot text spoils a secret quest"], f"dialogue/economy/{il}.dlg")
    ph.add("qa", f"Test auction house {aid}", why, ["tests", "economy"], [
        D(f"{aid}: bidding and listing cases", ["Bid, outbid, win, lose", "Listing caps and weekly cap", "Fee charged once"], f"{aid} cases logged"),
        D(f"{aid}: exploit hunt", ["Try snipe at last tick", "Try listing a quest item", "Try sell-buy loops with shops"], f"{aid} exploit log written"),
        D(f"{aid}: save/time cases", ["Save during a live lot; load", "Rest through a lot end", "Fast travel away and back"], f"{aid} save/time cases logged"),
    ], ["Escrow lost on load"], f"production/qa/cases/{ph.pl}/{il}.md")


def minigame(ph, m, gambling=False):
    mid, reg, kind = m["id"], m["reg"], m["kind"]
    rname, act = REG[reg]
    il = low(mid)
    why = (f"P7c + §12.7 gambling: in-game currency only, visible house edge, daily table limits ({mid})" if gambling
           else f"P7c + §12.7 minigames: one-page design, reward table within economy rules, difficulty options ({mid})")
    tags = ["fun", "systems", "economy", "tests"]
    if gambling:
        pd = [
            D(f"{mid} ({kind}): rules and odds model", [f"Implement {kind} rules in `scripts/minigames/{il}.gd`", "House edge defined in data and shown in the UI", "Seeded RNG for tests"], f"{mid} playable with debug odds display"),
            D(f"{mid}: limits and currency rules", ["Daily table limits on the WorldClock", "In-game currency only; no paid randomness (A6)", "Region config flag so it can be disabled where restricted"], f"{mid} limits enforced"),
            D(f"{mid}: UI context and input", ["UI as a ContextStack context", "Keyboard and gamepad prompts via InputService", "Accessibility: no time pressure"], f"{mid} UI usable on gamepad"),
            D(f"{mid}: economy integration", ["Add to sources/sinks tracking", "Expected-value check over 100k simulated hands", "Economy sim 365 days"], f"{mid} EV equals the stated edge"),
            D(f"{mid}: tests", [f"`tests/unit/minigames/test_{il}.gd`: odds, limits, payouts", "Not required for story: assert no story flag reads it", f"Evidence to {ph.ev(mid)}"], f"{mid} tests green"),
        ]
    else:
        pd = [
            D(f"{mid} ({kind}): core loop", [f"Implement {kind} loop in `scripts/minigames/{il}.gd` on the fixed tick", "Difficulty options per §12.7", "Seeded RNG"], f"{mid} core loop playable"),
            D(f"{mid}: scoring and rewards", ["Reward table within the economy rules", "Grant via RewardLedger", "Optional, never needed for the story"], f"{mid} rewards granted"),
            D(f"{mid}: UI and input", ["ContextStack context", "InputService prompts", "Accessibility hold/toggle options"], f"{mid} UI usable"),
            D(f"{mid}: world integration", [f"Entry points in {rname}", "WorldClock availability rules", "Save state"], f"{mid} reachable in world"),
            D(f"{mid}: feel pass", ["FeelService hitstop/shake tuning", "Audio hooks", "Playtest 3 sessions"], f"{mid} fun notes logged"),
            D(f"{mid}: tests", [f"`tests/unit/minigames/test_{il}.gd`", "Reward cap test", f"Evidence to {ph.ev(mid)}"], f"{mid} tests green"),
        ]
    ph.add("primary", f"Build {'gambling game' if gambling else 'minigame'} {mid} ({kind})", why, tags, pd,
           ["Quit mid-round", "Currency at 0", "Pause during a timed input"], f"tests/unit/minigames/test_{il}.gd")
    sd = [
        D(f"{mid}: one-page design", [f"Write `design/gdd/minigames/{il}.md` (one page per §12.7)", "Reward table vs economy rules", "Difficulty options"], f"{mid} one-pager approved"),
        D(f"{mid}: placement and review", [f"Place {mid} in {rname}", "Run `/ux-review`", "Playtest and sign off"], f"{mid} signed off"),
    ]
    if not gambling:
        sd.insert(1, D(f"{mid}: fun review", ["Play 5 rounds at each difficulty", "Note what is boring", "Ask for one change"], f"{mid} fun notes filed"))
    ph.add("secondary", f"Direct {mid} ({kind})", why, ["fun", "ux", "level"], sd, ["Rules unclear without a tutorial"], f"design/gdd/minigames/{il}.md")
    ad = [
        D(f"{mid}: play-field art", [f"Draw the {kind} play field", "Pieces/cards/props", "Import"], f"{mid} field art in"),
        D(f"{mid}: UI widgets", ["Score, odds and limit widgets", "High-contrast variant", "Import"], f"{mid} UI art in"),
        D(f"{mid}: host/venue art", ["Host NPC or venue dressing", "Animation of key moments", "Review"], f"{mid} venue art in"),
    ]
    if not gambling:
        ad.append(D(f"{mid}: feedback VFX", ["Success/fail VFX", "Pooled particles", "Review"], f"{mid} VFX in"))
    ph.add("art", f"Art for {mid}", why, ["art", "ui"], ad, ["Odds text too small"], f"{ph.ev(mid)}")
    au = [D(f"{mid}: SFX set", [f"{kind} SFX set", "Win/lose stingers", "Implement"], f"{mid} SFX in")]
    if not gambling:
        au.append(D(f"{mid}: loop music", ["Short loop for the minigame", "Intensity layer", "Implement"], f"{mid} loop in"))
    ph.add("audio", f"Audio for {mid}", why, ["audio"], au, ["Stinger plays twice on fast input"], "assets/audio/minigames/")
    ph.add("writing", f"Text for {mid}", why, ["dialogue", "ux"], [
        D(f"{mid}: rules text and host lines", [f"Rules text and host lines (~{W(ph, 500)} words)", "Clear odds/edge wording" if gambling else "Tutorial prompts", "Key strings"], f"{mid} text in"),
    ], ["Rules text truncated in Chinese"], "dialogue/minigames/")
    ph.add("qa", f"Test {mid}", why, ["tests", "fun", "economy"], [
        D(f"{mid}: rules and reward cases", ["Every rule path", "Reward caps", "Save/quit mid-round"], f"{mid} cases logged"),
        D(f"{mid}: exploit and accessibility cases", ["Repeat-win exploit attempts", "Gamepad-only and text-scale 200%", "Daily limit reset at midnight" if gambling else "Difficulty options"], f"{mid} exploit cases logged"),
    ], ["Limit reset abused by save-scumming"], f"production/qa/cases/{ph.pl}/{il}.md")


def music_track(ph, m):
    mid, fn = m["id"], m["fn"]
    why = f"§3 ~45 tracks; P9 adaptive music; {ph.pid} {fn}"
    ph.add("audio", f"Compose {mid}: {fn}", why, ["music", "audio"], [
        D(f"{mid}: sketch", [f"Sketch {mid} ({fn}) themes against the audio direction brief", "Two 30-second options", "Send to the director"], f"{mid} sketch chosen"),
        D(f"{mid}: arrangement", [f"Arrange {mid} full length", "Mark loop points", "Plan adaptive layers"], f"{mid} arranged"),
        D(f"{mid}: adaptive stems", ["Write calm/tension/combat (or day/night) stems", "Check transitions at bar lines", "Bounce stems"], f"{mid} stems bounced"),
        D(f"{mid}: mix and master", ["Mix to the loudness target", "Master; check on headphones and TV", "Export final files"], f"{mid} mastered"),
        D(f"{mid}: implementation", ["Hook into the music manager's adaptive state", "Test transitions in game", "Log in the music register"], f"{mid} live in the build"),
        D(f"{mid}: instrument and orchestration pass", ["Replace placeholder instruments; record or render final parts", "Check the theme reads at low volume", "Re-bounce affected stems"], f"{mid} final instruments in"),
        D(f"{mid}: revision round", ["Apply the director's notes from the in-game review", "Re-check loop seams and transitions", "Update the register with final timings"], f"{mid} revision approved"),
    ], ["Stem desync after a long pause", "Loop click at the seam"], f"assets/audio/music/{low(mid)}/ + production/audio/music_register.md")
    ph.add("secondary", f"Direct and approve {mid}", why, ["music", "audio", "team"], [
        D(f"{mid}: brief and approval", [f"Write the brief for {mid} ({fn}): mood, instruments, adaptive states", "Review sketch and final mix", "Approve or return notes"], f"{mid} approved"),
    ], ["Track mood clashes with the scene"], "production/reviews/audio.md")


def sfx_batch(ph, s, review):
    sid, domain = s["id"], s["domain"]
    why = f"§3 ~900 SFX; P9 juice; {sid} ({domain}, 25 SFX)"
    ph.add("audio", f"Produce {sid}: {domain}", why, ["audio"], [
        D(f"{sid}: design and record", [f"List the 25 {domain} events for {sid}", "Record or synthesize source material", "First-pass design"], f"{sid} first pass done"),
        D(f"{sid}: variants and processing", ["2-3 variants for high-frequency events", "Process and normalize to the loudness target", "Name per convention"], f"{sid} processed"),
        D(f"{sid}: implementation", ["Hook events to the audio bus layout", "Voice limits and priorities", "In-game check"], f"{sid} live in build"),
        D(f"{sid}: edge-event pass", [f"Find {domain} events with no sound in rare states (stagger, pause, slow-time)", "Design the missing ones", "Slow-time pitch/time-stretch behaviour"], f"{sid} rare states covered"),
        D(f"{sid}: revision round", ["Apply review notes", "Loudness re-check across the batch", "Update the SFX register count toward ~900"], f"{sid} approved and counted"),
    ], ["Missing event hook found only in a rare state"], f"assets/audio/sfx/{low(sid)}/")
    if review:
        ph.add("secondary", f"Review SFX {review}", why, ["audio", "team"], [
            D(f"{review}: review", [f"Play through scenes using {review}", "Check mix balance vs music and dialogue", "Approve or note"], f"{review} reviewed"),
        ], ["SFX too loud on low-volume settings"], "production/reviews/audio.md")


def cinematic(ph, c, qa_group=None):
    cid, beat, reg = c["id"], c["beat"], c["reg"]
    rname, act = REG[reg]
    why = f"P9 + §7: cinematics for every act beat; {cid} {beat}"
    ph.add("secondary", f"Direct cinematic {cid}", why, ["cinematics", "story"], [
        D(f"{cid}: storyboard and timeline", [f"Storyboard {cid} ({beat}) in `design/cinematics/{low(cid)}.md`", "Lay the timeline in the cutscene tool", "Brief team"], f"{cid} timeline blocked"),
    ], ["Cinematic triggered twice"], f"design/cinematics/{low(cid)}.md")
    ph.add("art", f"Stage cinematic {cid}", why, ["cinematics", "art", "animation"], [
        D(f"{cid}: keyframes and staging", [f"Draw keyframes and any one-off clips for {cid}", "Stage in the timeline", "Review"], f"{cid} staged"),
    ], ["Character pops between shots"], f"{ph.ev(cid)}")
    ph.add("audio", f"Sound cinematic {cid}", why, ["cinematics", "audio"], [
        D(f"{cid}: score and sound pass", [f"Score cue and SFX pass for {cid}", "Duck under dialogue", "Implement"], f"{cid} audio in"),
    ], ["Audio continues after skip"], f"{ph.ev(cid)}")
    ph.add("writing", f"Script cinematic {cid}", why, ["cinematics", "dialogue"], [
        D(f"{cid}: scene script", [f"Write or adapt the {cid} scene (~{W(ph, 400)} words) from the outline and existing `dialogue/` files", "Branch on its flags", "Dialogue test"], f"{cid} script final"),
    ], ["Line refers to a flag not yet set"], "dialogue/cinematics/")
    if qa_group:
        ph.add("qa", f"Test cinematics {qa_group}", why, ["tests", "cinematics"], [
            D(f"{qa_group}: cinematic cases", [f"Play {qa_group} each with and without skip", "Check flags written, `is_active == false` after", "Pause mid-cinematic"], f"{qa_group} cases logged"),
        ], ["Skip during a flag-writing line"], f"production/qa/cases/{ph.pl}/cinematics.md")


def player_clip(ph, c):
    cid, nm, days = c["id"], c["name"], c["days"]
    why = f"§3 ~40 player clips + 4-direction set; P2 frame-data driven; {cid}"
    dd = [D(f"{cid} ({nm}): key poses and timing", [f"Key poses for Kaelen {nm} replacing the PAE slice version", "Match MoveData frame counts", "Approval"], f"{cid} poses approved")]
    if days >= 2:
        dd.append(D(f"{cid} ({nm}): in-betweens and import", ["In-betweens and smear frames", "Import; tag active frames", "Run the frame-data test"], f"{cid} imported"))
    else:
        dd[0]["steps"].append("Import and tag frames")
    ph.add("art", f"Animate player clip {cid}: {nm}", why, ["animation", "art"], dd, ["Frame tag drift breaks MoveData"], f"assets/sprites/kaelen/{low(cid)}/")


def region_package(ph, r):
    reg = r["reg"]
    rname, act = REG[reg]
    groups = r["groups"]
    pois = r["pois"]
    devs = r["devs"]
    wss = r["ws"]
    why = f"P7a + §12.5 open world; §7 vertical production of {reg} {rname}"
    # primary: dynamic events and waystations, streaming
    sbd = [
        D(f"{reg}: chunk streaming budget", [f"Profile streaming across all {len(groups)} {rname} chunk groups", "Hitch < 2 ms per chunk load", "Fix offenders (texture size, node count)"], f"{reg} streaming within budget"),
        D(f"{reg}: seams and traversal gates", [f"Validate authored seams to neighbouring regions", "Traversal unlocks gated by abilities, not invisible walls", "Run reachability test"], f"{reg} seams valid"),
    ]
    if ph.lean:
        sbd = [D(f"{reg}: streaming budget, seams and traversal gates", [f"Profile streaming across all {len(groups)} {rname} chunk groups; hitch < 2 ms per load",
                                                                         "Validate authored seams to neighbouring regions", "Traversal unlocks gated by abilities, not invisible walls; run reachability"],
                 f"{reg} streaming within budget and seams valid")]
    ph.add("primary", f"{reg} streaming budgets and chunk validation", why, ["openworld", "performance", "code"], sbd,
           ["Seam chunk unloads under the player"], f"{ph.ev(reg)} profiler captures")
    if ph.lean:
        chunks = [devs[i:i + 2] for i in range(0, len(devs), 2)]
        ph.add("primary", f"Dynamic events {devs[0]}..{devs[-1]} ({reg})", why + "; dynamic events tied to the clock", ["openworld", "time", "code"], [
            D(f"{'/'.join(c)}: event logic on the WorldClock", [f"Implement {' and '.join(c)} in `data/events/{reg.lower()}/`: trigger window, participants, outcomes",
                                                                "Signpost each before it closes", "Bot test: fires under fast and slow profiles"], f"{'/'.join(c)} fire on schedule")
            for c in chunks], ["Event fires during a boss fight"], f"tests/integration/openworld/test_{reg.lower()}_events.gd")
    else:
        for d in devs:
            ph.add("primary", f"Dynamic event {d} ({reg})", why + "; dynamic events tied to the clock", ["openworld", "time", "code"], [
                D(f"{d}: event logic on the WorldClock", [f"Implement {d} in `data/events/{reg.lower()}/{low(d)}.tres`: trigger window, participants, outcomes", "Signpost before it closes", "Bot test it fires under fast and slow profiles"], f"{d} fires on schedule"),
            ], ["Event fires during a boss fight"], f"tests/integration/openworld/test_{low(d)}.gd")
    ph.add("primary", f"{reg} waystations and fog of war", why, ["openworld", "code", "save"], [
        D(f"{reg}: waystations {wss[0]}..{wss[-1]}", [f"Register {', '.join(wss)} for fast travel", "Discovery saved; map fog of war cleared per chunk", "Fast travel keeps world state and the clock"], f"{reg} fast travel works"),
    ], ["Fast travel during a timed quest"], f"tests/integration/openworld/test_{reg.lower()}_waystations.gd")
    # secondary: level design per chunk group
    for i, g in enumerate(groups):
        ph.add("secondary", f"Level design {g} ({reg} {rname})", why, ["level", "openworld"], [
            D(f"{g}: layout and traversal", [f"Lay out {g} TileMapLayer chunks (~32×32 tiles each)", "Paths, sightlines, ability-gated shortcuts", "Collision pass on named layers"], f"{g} walkable"),
            D(f"{g}: encounters and dressing brief", [f"Place {g} enemy patrols and NPC paths", "Write the art dressing brief", "Playtest the group"], f"{g} encounter pass done"),
        ] + ([] if ph.lean else [
            D(f"{g}: integrate dressing and final collision", [f"Review the art lead's dressing of {g} in a live viewport", "Final collision and navigation pass after dressing",
                                                               "Re-run reachability; screenshot for evidence"], f"{g} integrated and evidenced"),
        ]), ["Player stuck on a tile corner"], f"{ph.ev(g)}")
    for i in range(0, len(pois), 2):
        p = pois[i:i + 2]
        ph.add("secondary", f"POIs {', '.join(p)} ({reg})", why, ["level", "openworld"], [
            D(f"{'/'.join(p)}: discovery design", [f"Place {' and '.join(p)}: landmark, reward (lore, cache or secret)", "Discovery feedback and map icon", "Playtest the find"], f"{'/'.join(p)} placed"),
        ], ["POI reward duplicates on reload"], f"{ph.ev(reg)}")
    ph.add("secondary", f"{reg} dynamic event staging and waystation placement", why, ["level", "openworld", "time"], [
        D(f"{reg}: dynamic event staging", [f"Stage {', '.join(devs)} in the world", "Signposts and NPC hints", "Play each once"], f"{reg} events staged"),
        D(f"{reg}: waystations", [f"Place {', '.join(wss)}", "Check travel time between them", "Sign off"], f"{reg} waystations placed"),
    ], ["Waystation inside an event area"], f"{ph.ev(reg)}")
    # art
    ph.add("art", f"{reg} {rname} environment kit", why, ["art", "assets", "openworld"], [
        D(f"{reg}: base tileset", [f"Final-quality {rname} base terrain tiles", "Autotile rules", "Import"], f"{reg} base tiles in"),
        D(f"{reg}: secondary tileset", ["Paths, water, cliffs", "Seam tiles to neighbours", "Import"], f"{reg} secondary tiles in"),
        D(f"{reg}: architecture set", [f"{rname} buildings and interiors kit", "Doors and interactables", "Import"], f"{reg} architecture in"),
        D(f"{reg}: props and decals", ["Prop set", "Decals for variety", "Import"], f"{reg} props in"),
        D(f"{reg}: side-scroll arena layers", ["Parallax layers per terrain context", "Hazard tiles", "Import"], f"{reg} arena layers in"),
        D(f"{reg}: lighting and day/night palette", ["Day/night palette ramps", "Light sprites", "Check in the clock test"], f"{reg} lighting in"),
    ], ["Tile seam visible at integer zoom 3", "Palette ramp wrong at dusk"], f"{ph.ev(reg)} screenshots")
    ph.add("art", f"{reg} {rname} chunk dressing", why, ["art", "assets", "level"],
        [D(f"{g}: dressing pass", [f"Dress {g} per the level designer's brief", "Check seams and repetition", "Screenshot"], f"{g} dressed") for g in groups],
        ["Tile seam visible at integer zoom 3", "Repeated prop clusters"], f"{ph.ev(reg)} screenshots")
    ph.add("art", f"{reg} {rname} POI landmarks", why, ["art", "assets", "openworld"],
        [D(f"POI landmarks {'/'.join(pois[i:i + 2])}", [f"Draw landmark art for {' and '.join(pois[i:i + 2])} readable from two chunks away", "Discovery highlight frames", "Import and screenshot"], f"{'/'.join(pois[i:i + 2])} landmarks in") for i in range(0, len(pois), 2)],
        ["Landmark unreadable at night", "Palette ramp wrong at dusk"], f"{ph.ev(reg)} screenshots")
    ph.add("audio", f"{reg} {rname} ambience", why, ["audio", "openworld"], [
        D(f"{reg}: day ambience beds", [f"{rname} day beds per biome", "Loop and level", "Implement on chunk enter"], f"{reg} day beds in"),
        D(f"{reg}: night and weather beds", ["Night variants", "Weather/season layers", "Implement"], f"{reg} night beds in"),
        D(f"{reg}: dynamic event and discovery stingers", [f"Stingers for {', '.join(devs)} and POI discovery", "Implement", "Mix check"], f"{reg} stingers in"),
        D(f"{reg}: interior beds", [f"Interior beds for {rname} buildings and dungeons", "Door/threshold crossfades", "Implement"], f"{reg} interiors in"),
        D(f"{reg}: seasonal layers", ["Four-season layers driven by the WorldClock calendar", "Festival/market-day crowd layer", "Implement and test with a time skip"], f"{reg} seasons in"),
    ], ["Ambience restarts audibly at chunk seams"], "assets/audio/ambience/")
    ph.add("writing", f"{reg} {rname} lore and signposting", why, ["dialogue", "openworld", "localization"], [
        D(f"{reg}: POI lore entries", [f"Lore entries for {', '.join(pois[:len(pois)//2])} (~{W(ph, 900)} words)", "Consistent with STORY_BIBLE §2-3", "Key strings"], f"{reg} lore part 1 in"),
        D(f"{reg}: POI lore entries (2)", [f"Lore for {', '.join(pois[len(pois)//2:])} (~{W(ph, 900)} words)", "Codex cross-links", "Key strings"], f"{reg} lore part 2 in"),
        D(f"{reg}: signposting and event text", [f"Warning and signpost lines for {', '.join(devs)} and timed quests (~{W(ph, 500)} words)", "Waystation names", "Key strings"], f"{reg} signposts in"),
    ], ["Lore contradicts the region table"], f"dialogue/lore/{reg.lower()}.dlg")


def region_dod(ph, reg, rel):
    rname, act = REG[reg]
    why = f"§7 Definition of Done for {reg} {rname} (vertical, shippable before the next region)"
    ph.add("primary", f"{reg} performance, accessibility and localization extraction", why, ["performance", "accessibility", "localization", "code"], [
        D(f"{reg}: performance pass", ["Run `/perf-profile` on the busiest chunk at noon on market day", "60 fps on min spec with NPC and market sim", "Fix top 3 costs"], f"{reg} meets 60 fps on min spec"),
        D(f"{reg}: accessibility pass", ["Text scale 200%, colourblind modes, remap, hold/toggle", "Subtitles on every line in the region", "Fix issues found"], f"{reg} accessibility checklist passes"),
        D(f"{reg}: string extraction", [f"Run `/localize` extraction on all {rname} content", "No hardcoded strings; CJK font coverage check", "Hand file to the localization pipeline"], f"{reg} strings extracted, 0 hardcoded"),
        D(f"{reg}: save migration for {rel}", [f"Add `SaveService.migrate` step for {rel}", f"Round-trip test `tests/unit/save/test_migration_{low(rel)}.gd` with fixtures from every earlier release", "CI must load every old fixture"], f"{rel} saves migrate 100%"),
    ], ["Old save made inside a region chunk that moved"], f"tests/unit/save/test_migration_{low(rel)}.gd")
    ph.add("secondary", f"{reg} Definition of Done review", why, ["release", "team", "docs"], [
        D(f"{reg}: DoD checklist", ["Real art and audio everywhere", "5 difficulties tuned (balance sheet)", "Strings extracted; bot coverage incl. time-skip; saves migrate; economy sim stable; no open critical/high"], f"{reg} DoD sheet filled"),
        D(f"{reg}: milestone review", ["Run `/milestone-review`", "Record cost per asset vs budget", "Decide go/hold for the next region"], f"{reg} go decision recorded"),
    ], ["A DoD item waived without a recorded reason"], f"production/milestones/{ph.pl}/{reg.lower()}_dod.md")
    ph.add("qa", f"{reg} Definition of Done test pass", why, ["tests", "release", "difficulty", "time"], [
        D(f"{reg}: bot coverage incl. time-skip", ["Run the bot with fast, slow and out-of-order profiles", "Time-skip paths (rest, wait)", "Coverage report"], f"{reg} bot coverage report"),
        D(f"{reg}: difficulty matrix", ["Every boss and 3 encounters on all 5 difficulties", "Fairness notes on Hard/Hell", "Log"], f"{reg} matrix logged"),
        D(f"{reg}: localization and accessibility check", ["Pseudo-loc build of the region", "Text overflow hunt", "Accessibility checklist"], f"{reg} loc/a11y logged"),
        D(f"{reg}: save and economy", [f"Load fixtures from every release into {rel}", "Run the economy sim 365 days", "Check sources/sinks dashboard"], f"{reg} saves and economy pass"),
        D(f"{reg}: bug triage and sign-off", ["Run `/bug-triage`", "Confirm 0 open critical/high", "Sign the DoD sheet"], f"{reg} DoD QA sign-off"),
    ], ["Bug reopened after sign-off"], f"production/qa/{ph.pl}/{reg.lower()}_dod_report.md")


def gen_pool(stream, title, why, tags, topics, final, edge, evidence):
    """Return a fill generator; topics = list of D() days; final = closing D()."""
    def g(n):
        if n == 1:
            days = [topics[0]]
        else:
            days = topics[: n - 1] + [final]
        return (title, why, tags, days, edge, evidence)
    return g, len(topics) + 1
