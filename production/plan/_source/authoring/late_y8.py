"""Y8: 1.0 launch (~2034-02-15), live support, console port production (2033-10-01 -> 2034-09-30)."""
from late_common import *
from late_y8_extra import add_extra

CAPS = {"primary": 313, "secondary": 365, "art": 261, "audio": 261, "writing": 261, "qa": 261}
RC_BUCKETS = [(f"RC-{k:02d}", SYSTEMS[(k - 1) % 15], REGIONS[(k - 1) % 8][0]) for k in range(1, 31)]
WAR = ["L-2", "L-1", "L-day", "L+1", "L+2", "L+3", "L+4", "L+5", "L+6", "L+7", "L+8", "L+9"]
HOTFIX = ["1.0.1", "1.0.2", "1.0.3"]
PATCHES = ["1.0 RC2", "1.0 RC3", "1.0 RC4 (gold candidate)", "1.0.4", "1.1.0", "1.2.0", "1.3.0", "1.4.0", "1.5.0"]
CRASH = [f"CR-{k:02d}" for k in range(1, 21)]


def build():
    ph = Phase("Y8", "1.0 Launch, live support and console port production",
               "Aethelgard 1.0 is live on PC (~2034-02-15) with a working war room, hotfix lane and patch cadence; every save since EA loads in CI; console platforms A and B are port-complete with the chosen partner and C is under way; the launch + 6-month review is done.",
               ["1.0 shipped on PC in EN + zh-Hans on the planned date or a recorded slip ADR",
                "Hotfix lane proven: 3 hotfixes shipped each within the severity SLA in the hotfix runbook",
                "Save-compatibility CI loads 100% of fixtures from every EA, Beta and 1.x release",
                "Crash-free sessions >= 99.5% (Gate 4 bar) measured by month 3 after launch",
                "Console platforms A and B pass the internal pre-cert checklist in all 10 categories (check current platform requirements)",
                "Expansion 1 pre-production greenlit with epics and stories for X1-R9 and X1-R10",
                "Launch + 6-month review written and decisions recorded as ADRs"],
               CAPS)

    # ============================== PRIMARY ==============================
    ph.spec("primary", "Y8 kickoff: launch timeline and RC follow-ups", "ROADMAP §9 Y8; Gate 7 output", ["release", "team"], [
        ("Y8 kickoff: launch timeline", ["Turn Gate 7 ADR follow-ups into stories", "Lay out the backward plan from ~2034-02-15: gold build, store review lead time (check current store rules), press",
                                         "Run `/sprint-plan` for sprint 1", "Publish `production/milestones/launch_plan.md`"], "Launch timeline published"),
        ("Y8 kickoff: risk review for launch", ["Update the risk register for launch (crash, save, exploit, server-free ops)", "Assign owners for each launch risk",
                                                "Define severity SLA for hotfixes", "Record in `production/milestones/launch_risks.md`"], "Launch risks owned")],
        ["Store review lead time longer than planned"], "production/milestones/launch_plan.md", where="head")

    ph.spec("primary", "Long-term save compatibility guaranteed in CI", "ROADMAP §9 Y8: long-term save compatibility in CI; R4", ["save", "tests", "tools"], [
        ("Save compat: policy", ["Write ADR 'Save compatibility guarantee': every save from EA onward loads forever, or fails loudly with a backup",
                                 "Define forward-compat behaviour: an older build refuses a newer save with a clear message", "Define fixture retention: keep forever, never regenerate",
                                 "Link the ADR from `docs/save/schema_history.md`"], "ADR merged"),
        ("Save compat: fixture library harvest", ["Harvest per-act, per-difficulty saves from every tagged build since EA into `tests/fixtures/saves/<build>/`",
                                                  "Generate missing ones by replaying bot routes on the old build tags", "Record index with schema version and content summary", "Store LFS checksums"], "Fixture library complete"),
        ("Save compat: CI matrix job", ["Add CI job `save-compat` loading every fixture into HEAD headless", "Assert StoryGraph flags, WorldClock, RewardLedger, market positions and Story+ state survive",
                                        "Fail on any silent change of player inventory value", "Publish summary to the CI page"], "save-compat job green"),
        ("Save compat: forward-compat and corruption tests", ["Test HEAD save loaded in the previous release: refusal message, no crash", "Test truncated, zeroed and partially written files",
                                                              "Test saves from opt-in player submissions", "Write `tests/integration/save/test_forward_compat.gd`"], "Forward-compat tests green"),
        ("Save compat: cloud save conflicts", ["Test store cloud-save conflict prompts with two machines", "Ensure newest-wins never discards Story+ progress silently",
                                               "Document the player-facing conflict UI", "Add manual test case for QA"], "Cloud conflict handling verified"),
        ("Save compat: release gate", ["Make `save-compat` a required check for `release/*` branches", "Add the job to the hotfix runbook", "Dry-run on RC2", "Record in `docs/save/schema_history.md`"],
         "Release branches cannot merge without save-compat")],
        ["Save made during a hotfix rollback", "Save from an EA build with a removed item", "Save at the exact moment of a WorldClock month rollover"],
        "CI job save-compat + tests/integration/save/test_forward_compat.gd")

    ph.fam("primary", "Release-candidate burn-down", "Gate 7 follow-up: zero critical, high under threshold", ["code", "tests", "cleanup"], RC_BUCKETS,
           lambda u: f"RC burn-down {u[0]}: {u[1]} in {u[2]} {RNAME[u[2]]}",
           lambda u: [f"Pull open RC-blocking `{u[1]}` issues in {u[2]} via `/bug-triage`", "Reproduce with `scripts/core/debug_test_mode.gd`; save repro under `tests/fixtures/saves/bugs/`",
                      f"Fix with a regression test under `tests/unit/{SYS_SLUG[u[1]]}/`", "Run the affected matrix cells and the save-compat job"],
           lambda u: f"{u[0]}: {u[1]} blockers in {u[2]} closed",
           ["Fix that changes a frame window (needs replay re-verification)"], "Closed issues with regression tests", chunk=6)

    ph.spec("primary", "Launch build pipeline", "§9 launch; release discipline", ["release", "tools"], [
        ("Pipeline: reproducible build", ["Make `tools/export_windows.ps1` take a version string and embed it in the title screen and crash logs", "Pin the editor and templates by checksum",
                                          "Build twice and diff outputs", "Document in `docs/release/build.md`"], "Two builds byte-identical except timestamp"),
        ("Pipeline: depots and branches", ["Configure store depots and branches per current store tooling (check current docs)", "Script upload with credentials kept out of the repo (environment only)",
                                           "Set default, beta and rollback branches", "Dry-run upload to a private branch"], "Private branch receives the build"),
        ("Pipeline: symbols and crash triage", ["Archive symbols per build under `production/releases/<version>/`", "Map crash logs to versions automatically", "Group crashes by signature", "Test with a forced crash on RC"], "Crash signatures grouped by version"),
        ("Pipeline: Deck and Linux path", ["Verify the same pipeline produces the build tested on Deck", "Check Proton-specific crash capture", "Record compatibility notes", "Re-run Deck checklist on RC"], "Deck build from pipeline verified"),
        ("Pipeline: launch dry run", ["Full dry run: tag, build, test, upload to private branch, smoke", "Time each step", "Fix slow steps", "Write the launch-day command sheet"], "Launch command sheet tested")],
        ["Upload fails mid-way on launch day", "Credentials expired"], "docs/release/build.md + launch command sheet")

    ph.spec("primary", "Hotfix process and war-room tooling", "§9 Y8: war room, hotfix process", ["release", "tools", "tests"], [
        ("Hotfix runbook", ["Write `docs/release/hotfix_runbook.md`: severity levels, SLA, branch from release tag, minimal suite", "Define rollback via the store's branch switching (check current tooling)",
                            "Define who approves a hotfix (user)", "Rehearse with a fake critical bug"], "Runbook rehearsed"),
        ("Hotfix minimal suite", ["Select a 20-minute CI subset: boot, load_all, save-compat, phase0, hell-replay sample, matrix smoke 10 cells", "Wire it as `hotfix-suite`",
                                  "Time it", "Document"], "hotfix-suite under 20 minutes"),
        ("War-room dashboard", ["Build `production/warroom/dashboard.md` generator: crash rate, top signatures, review sentiment notes, support tickets", "Refresh hourly on launch days",
                                "Set alert thresholds", "Test on RC telemetry"], "Dashboard renders from real data"),
        ("War-room intake", ["Set one intake for community bugs with required fields (version, save, steps)", "Auto-tag by system", "Link to triage", "Test with 10 sample reports"], "Intake routing works"),
        ("Hotfix dry run", ["Inject a fake critical in RC3 branch", "Run the whole hotfix flow to a private branch", "Measure time to fix-live", "Improve the slowest step"], "Fake hotfix live within SLA")],
        ["Hotfix needed while another is in review", "Rollback with saves made on the bad version"], "docs/release/hotfix_runbook.md")

    ph.spec("primary", "Pre-launch verification on the gold candidate", "Gate 7 criteria re-verified on gold", ["tests", "release", "performance", "ai"], [
        ("Gold: Hell replays", ["Re-run all 24 Hell replays on gold", "Re-run mutants for B22-B24", "Compare checksums with Beta", "Record"], "24/24 replays green on gold"),
        ("Gold: matrix", ["Run the full 405-cell matrix on gold", "Triage any red cell immediately", "Record dashboard snapshot", "Archive"], "Matrix green on gold"),
        ("Gold: performance", ["Re-run the 8 region perf routes on min spec", "Re-run Deck preset", "Compare with Beta numbers", "Record"], "Perf budgets met on gold"),
        ("Gold: localization", ["Boot in zh-Hans and run the screenshot tour", "Check fallback font and overflow test", "Check credits and notices", "Record"], "zh-Hans gold verified"),
        ("Gold: wider hardware", ["Run on the 8 QA hardware configs via QA", "Check crash logs", "Fix driver-specific issues if any", "Record"], "Hardware matrix clean"),
        ("Gold: PC platform features", ["Verify achievements unlock once each and are reachable", "Verify cloud saves and controller configs", "Verify overlay and screenshots", "Record"], "Platform features verified")],
        ["Driver update between gold and launch"], "production/releases/1.0.0/verification.md")

    ph.spec("primary", "Console porting partner: selection package", "§9: licensed Godot porting partner (console templates are not public)", ["business", "architecture", "docs"], [
        ("Partner criteria", ["Write criteria: Godot 4.x console experience, platforms covered, cert support, pricing model, code ownership", "List candidate partners from public directories (names kept in the private business file, not the repo)",
                              "Prepare questions about engine version support and our 4.6 pin", "Store in `production/business/console_partner_criteria.md`"], "Criteria written"),
        ("Technical audit pack", ["Assemble architecture overview, autoload list, GDExtension use (if any), shader list, memory budget", "Note platform-sensitive systems: SaveService, InputService, file paths, threads",
                                  "Prepare a build the partner can compile", "Strip secrets"], "Audit pack ready"),
        ("Partner evaluation calls", ["Run calls with shortlisted partners (user leads)", "Score against criteria", "Ask for a small paid test port if offered", "Record scores"], "Scores recorded"),
        ("Partner decision input", ["Summarise trade-offs and costs", "Recommend one partner with reasons", "User decides; record ADR 'Console porting partner'", "Notify partner (user sends)"], "Partner ADR recorded"),
        ("Contract technical annex", ["Draft the technical annex: deliverables per platform, cert support, bug SLAs, source access", "Hand to the lawyer with the business terms", "List acceptance tests per milestone", "Store draft"], "Annex drafted for legal review")],
        ["Partner supports our Godot version on only some platforms"], "production/business/console_partner_criteria.md + ADR")

    ph.spec("primary", "PlatformService abstraction", "Console readiness: one owner per platform concern (R7)", ["architecture", "code", "tests"], [
        ("PlatformService ADR", ["Write ADR: `scripts/core/platform_service.gd` owns user, saves location, achievements, entitlements, glyphs, suspend events", "List current direct uses of platform APIs in `scripts/`",
                                 "Define a PC backend and a stub backend for tests", "Define how the partner implements console backends"], "ADR merged"),
        ("PlatformService: saves and user", ["Route SaveService file access through PlatformService", "Handle user change events (console requirement) on PC as no-op", "Unit tests with the stub backend", "No save schema change"], "Saves via PlatformService"),
        ("PlatformService: achievements and entitlements", ["Route achievement unlocks through PlatformService", "Add entitlement query for future DLC (Expansion 1)", "Unit tests", "Document"], "Achievements via service"),
        ("PlatformService: input glyphs", ["Move glyph selection to PlatformService with per-platform glyph sets", "Keep InputService the only input owner", "Test PC keyboard, two gamepad types", "Document"], "Glyphs via service"),
        ("PlatformService: suspend/resume and focus", ["Emit suspend/resume signals; ContextStack pauses on suspend", "Persist an autosave on suspend if safe", "Test alt-tab on PC as proxy", "Document"], "Suspend handled through ContextStack"),
        ("PlatformService: storage-full and errors", ["Handle storage-full on save with a clear message and retry", "Never delete the previous save before the new one is written", "Test with a filled disk image", "Document"], "Storage-full handled"),
        ("PlatformService: lint", ["Add lint: no platform API calls outside platform_service.gd", "Fix violations", "Add to CI", "Update docs"], "Lint green"),
        ("PlatformService: partner hand-off", ["Write `docs/platform/backend_contract.md` for the partner", "Include test suite they must pass", "Review with partner", "Record questions"], "Contract handed to partner")],
        ["Suspend during save write", "User signs out mid-dialogue"], "scripts/core/platform_service.gd + docs/platform/backend_contract.md")

    ph.anchor(ph.spec("primary", "Day-one build 1.0.0", "§9 launch", ["release", "tests"], [
        ("1.0.0 build", ["Cut `release/1.0.0` from the gold tag", "Run every CI job including save-compat and hotfix-suite", "Upload to the default branch staged for release time", "Archive symbols"], "1.0.0 staged"),
        ("1.0.0 release switch", ["Follow the launch-day command sheet", "Verify the live build hash", "Smoke test from a clean install", "Announce to war room"], "1.0.0 live and verified")],
        ["Launch-time clock zone confusion"], "production/releases/1.0.0/"), 0.352)

    ph.fam("primary", "Launch war room", "§9 Y8: launch war room", ["release", "tests"], WAR,
           lambda w: f"War room {w}: engineering watch",
           lambda w: [f"Refresh the war-room dashboard ({w}) every 2 hours; log crash rate and top 5 signatures",
                      "Triage new reports through the intake; decide hotfix vs next patch per the runbook",
                      "Fix the top crash signature with a test if one is new",
                      f"Write the {w} log entry in `production/warroom/{w}.md`; stop at the planned end time (burnout rule)"],
           lambda w: f"{w} log written; no critical issue untriaged",
           ["Crash only on a GPU driver version", "Save corruption report (all hands)"], "production/warroom/")

    ph.fam("primary", "Launch hotfixes", "§9 Y8 hotfix process", ["release", "code", "tests"], HOTFIX,
           lambda h: f"Hotfix {h}",
           lambda h: [f"Branch `hotfix/{h}` from the live tag; apply only the approved fixes", "Run `hotfix-suite` and save-compat", "Ship to beta branch, verify, then default",
                      f"Write `production/releases/{h}.md` with time-to-live"],
           lambda h: f"{h} live within SLA",
           ["Hotfix colliding with a store sale event"], "production/releases/")

    ph.fam("primary", "Post-launch crash signatures", "Crash-free >= 99.5% (Gate 4 bar kept)", ["code", "performance", "tests"], CRASH,
           lambda c: f"Crash signature bucket {c}",
           lambda c: [f"Take the #{c[3:]} ranked crash signature from the dashboard", "Reproduce with the crash log and player save if provided",
                      "Fix root cause; add a test or a soak case", "Verify crash count drops in the next build"],
           lambda c: f"{c} fixed or explained with a ticket",
           ["Crash in a third-party addon"], "production/warroom/crash_trends.md", chunk=5)

    ph.fam("primary", "Player-requested quality-of-life features", "Live support; P9 juice; UX", ["ux", "ui", "code"], QOL,
           lambda q: f"{q}: implement the approved QoL change",
           lambda q: [f"Read the {q} spec from the secondary stream (quick-design)", "Implement behind a setting where it changes behaviour", "Add a test", "Capture before/after in `production/qa/evidence/y8/qol/`"],
           lambda q: f"{q} merged with evidence",
           ["QoL change that would alter difficulty (reject)"], "production/qa/evidence/y8/qol/")

    for pid, pname in PLATFORMS[:2]:
        rows = [(f"{pid} bring-up with the chosen partner", [f"Hand the partner the tagged build and backend contract for {pname}", "Agree build cadence and bug tracker access",
                                                            "Get first boot on devkit (partner runs)", f"Record blockers in `production/console/{pid}/bringup.md`"], f"{pid} boots to title"),
                (f"{pid} renderer and shader check", [f"Run the screenshot tour on {pname} via the partner", "Diff screenshots against PC", "Fix shader differences in our code; partner fixes backend",
                                                     "Record"], f"{pid} tour matches PC"),
                (f"{pid} PlatformService backend review", [f"Review the partner's {pname} backend against `docs/platform/backend_contract.md`", "Run the contract test suite", "Fix our side issues", "Record"], f"{pid} backend passes contract tests"),
                (f"{pid} input and glyphs", [f"Map InputService actions to {pname} controller", "Install {0} glyph set from art".format(pid), "Test remapping screen SC04", "Record"], f"{pid} input complete"),
                (f"{pid} saves and user model", [f"Verify saves on {pname} storage via PlatformService", "Test user switching and sign-out", "Test storage full", "Run save-compat fixtures on device"], f"{pid} saves verified"),
                (f"{pid} suspend/resume", [f"Test suspend in combat, dialogue, save and streaming on {pname}", "Ensure ContextStack pause and WorldClock freeze", "Fix issues", "Record"], f"{pid} suspend safe"),
                (f"{pid} memory budget", [f"Profile memory on {pname} in R4 and R8", "Set texture/audio streaming budgets per platform", "Reduce peaks", "Record"], f"{pid} under memory budget")]
        rows += [(f"{pid} performance in {r} {rn}", [f"Run the {r} perf route on {pname}", "Record frame time and streaming hitches", "Fix top hotspot", f"Record `production/console/{pid}/perf_{r}.md`"], f"{pid} {r} meets target")
                 for r, rn, _ in REGIONS]
        rows += [(f"{pid} achievements/trophies mapping", [f"Map the PC achievement list to {pname}'s system (check current requirements on counts and art)", "Implement via PlatformService", "Test unlocks", "Record"], f"{pid} achievements mapped"),
                 (f"{pid} Hell determinism on device", [f"Run Hell replays B01-B24 on {pname}", "Compare checksums with PC", "Investigate any divergence", "Record"], f"{pid} replays deterministic"),
                 (f"{pid} localization on device", [f"Boot {pname} in zh-Hans", "Check font rendering and overflow", "Check platform-language detection", "Record"], f"{pid} zh-Hans ok"),
                 (f"{pid} accessibility on device", [f"Check AX01-AX12 settings on {pname}", "Check platform-level accessibility settings interplay", "Fix", "Record"], f"{pid} a11y ok")]
        rows += [(f"{pid} pre-cert {cc}: {cn}", [f"Read the current {pname} requirements for {cn} (check current platform requirements)", f"Test our build against {cc}", "Fix failures or escalate to partner", f"Record `production/console/{pid}/{cc}.md`"], f"{pid} {cc} pass")
                 for cc, cn in CERT_CATS]
        rows += [(f"{pid} DLC entitlement prep", [f"Prototype Expansion 1 entitlement check on {pname} via PlatformService", "Test owned/not owned", "Document", "Record"], f"{pid} DLC path proven"),
                 (f"{pid} milestone acceptance", ["Run the acceptance tests from the contract annex", "Write acceptance report", "User signs off milestone", "Archive build"], f"{pid} milestone accepted")]
        ph.add("main", "primary", f"Console port production: {pname}", "§9 Y8: console ports with a licensed Godot porting partner; cert prep",
               ["release", "performance", "code"], [D(f, s, d) for f, s, d in rows[:14]], ["Devkit firmware update mid-port", "Platform rejects save size"], f"production/console/{pid}/")
        ph.add("main", "primary", f"Console certification prep: {pname}", "§9 Y8: certification prep (check current platform requirements)",
               ["release", "tests", "legal"], [D(f, s, d) for f, s, d in rows[14:]], ["Requirement changed during the port"], f"production/console/{pid}/CC01..CC10.md")
    pid, pname = PLATFORMS[2]
    ph.spec("primary", f"Console port start: {pname}", "§9 Y8 console port production", ["release", "code"], [
        (f"{pid} bring-up with the chosen partner", [f"Hand the partner the build for {pname}", "Agree cadence", "First boot on devkit", "Record blockers"], f"{pid} boots"),
        (f"{pid} renderer check", ["Run screenshot tour via partner", "Diff with PC", "Fix shaders", "Record"], f"{pid} tour ok"),
        (f"{pid} backend contract tests", ["Run contract suite on the partner's backend", "Fix our side", "Record", "Plan remaining work"], f"{pid} contract tests run"),
        (f"{pid} input and glyphs", [f"Map actions for {pname}", "Install glyphs", "Test SC04", "Record"], f"{pid} input done"),
        (f"{pid} saves", ["Verify saves and user model", "Storage full", "Save-compat fixtures on device", "Record"], f"{pid} saves ok"),
        (f"{pid} memory first pass", ["Profile R4 and R8", "Set budgets", "Record peaks", "Plan reductions"], f"{pid} memory plan"),
        (f"{pid} performance first pass R1-R4", ["Run R1-R4 routes", "Record hotspots", "Fix the worst", "Record"], f"{pid} R1-R4 measured"),
        (f"{pid} performance first pass R5-R8", ["Run R5-R8 routes", "Record hotspots", "Fix the worst", "Record"], f"{pid} R5-R8 measured"),
        (f"{pid} Hell determinism", ["Run 24 Hell replays", "Compare checksums", "Investigate divergence", "Record"], f"{pid} replays checked"),
        (f"{pid} Y9 plan", ["List remaining port and cert work", "Estimate with partner", "Add to Y9 plan", "Record"], f"{pid} Y9 plan written")],
        ["Platform C has lower memory than A/B"], f"production/console/{pid}/")

    ph.spec("primary", "Expansion 1 technical pre-production", "§9 Y9 Expansion 1 (2 cut kingdoms) - tech ready before content", ["architecture", "openworld", "systems"], [
        ("X1 DLC packaging ADR", ["Write ADR: expansion content as a resource pack loaded via `ProjectSettings.load_resource_pack` gated by PlatformService entitlement", "Define what lives in base vs DLC (code in base, content in pack)",
                                  "Define save behaviour when DLC is missing (keep data, block entry)", "Review with partner for consoles"], "DLC ADR merged"),
        ("X1 world seams", ["Plan where X1-R9 Human Patch Lab and X1-R10 Forgotten Sectors attach to the streamed world", "Reserve chunk coordinates and seam chunks", "Check streaming budget with 12 more chunk sets",
                            "Record in `docs/expansion1/world_seams.md`"], "Seams planned"),
        ("X1 StoryGraph extension", ["Design how X1-ST1..ST3 attach to existing axes additively (§12.2: no multiplicative storylines)", "Reserve flag namespaces `x1_*` in FlagRegistry", "Plan ending composer slide hooks", "Record"], "Story hooks designed"),
        ("X1 market extension", ["Plan X1-CM-01..16 in the market sim and ItemDB", "Plan X1-EV-01..08 on WorldClock", "Plan sim regression for all 27 storylines + X1", "Record"], "Market plan written"),
        ("X1 save migration plan", ["Plan migration adding X1 blocks to saves (needs explicit approval for schema change)", "Plan fixtures for pre-X1 saves", "Plan DLC-missing behaviour tests", "Record"], "Migration plan ready for approval"),
        ("X1 tools readiness", ["Check region builder, chunk importer and quest tools handle the new IDs", "Fix tool gaps", "Run the controlled grammar builder preview for X1-R9", "Record"], "Tools ready"),
        ("X1 performance budget", ["Set per-chunk budgets for X1 based on R1-R8 data", "Define NPC caps per chunk", "Add CI perf placeholders", "Record"], "Budgets set"),
        ("X1 test plan", ["Run `/qa-plan` for Expansion 1", "Extend the QA matrix with X1 storylines", "Plan Hell replays for X1-B25..B28", "Record"], "X1 test plan written"),
        ("X1 epics", ["Run `/create-epics` for X1 tech", "Run `/create-stories` for the first epic", "Estimate with `/estimate`", "Record"], "X1 tech epics exist"),
        ("X1 tech greenlight", ["Review tech readiness with the team", "Record go/adjust ADR", "Update Y9 plan", "Archive"], "X1 tech greenlit")],
        ["Player owns DLC on one platform only"], "docs/expansion1/ + ADRs")

    every_year(ph, "Y8", "the 1.0 launch gate", PATCHES, triage_n=13)

    ph.spec("primary", "Launch + 6-month review: engineering data", "§4 timeline: Y8 ends with the launch + 6-month review", ["release", "docs", "business"], [
        ("Review data: stability and saves", ["Pull crash-free rate per month since launch", "Pull save-compat history and any player-reported save losses", "Pull hotfix time-to-live per incident", "Write data section"], "Stability data written"),
        ("Review data: performance and economy", ["Pull perf telemetry by hardware tier", "Pull economy telemetry vs sim", "List open exploits and turnaround", "Write data section"], "Perf/economy data written"),
        ("Review data: engineering retrospective", ["Run `/retrospective` for launch engineering", "List what to keep/change for console launches", "Record ADRs for changes", "Archive"], "Engineering retro recorded")],
        ["Telemetry gap during an outage"], "production/milestones/launch_plus_6.md", where="tail")

    ph.set_filler("primary", Filler(
        lambda i: D(f"Live fix LF-{i + 1:03d}: {SYSTEMS[i % 15]} in {REGIONS[(i // 15) % 8][0]}",
                    [f"Take the oldest open `{SYSTEMS[i % 15]}` bug in {REGIONS[(i // 15) % 8][0]} from the live tracker", "Reproduce from the player's save and steps",
                     f"Fix with a test under `tests/unit/{SYS_SLUG[SYSTEMS[i % 15]]}/`", "Queue for the next patch; reply to the reporter via secondary"],
                    f"LF-{i + 1:03d} fixed and queued"),
        lambda n: f"Live fixes block {n:02d}", "Live support", ["code", "tests"], ["Fix conflicts with a console branch"], "Closed issues", "primary"), 5)

    # ============================== SECONDARY ==============================
    ph.spec("secondary", "Y8 kickoff: launch production plan", "§9 Y8", ["team", "release"], [
        ("Launch production plan", ["Map department deliverables to launch dates", "Set war-room shift plan with rest days (burnout rule)", "Agree communication owners", "Publish `production/milestones/launch_team.md`"], "Team plan published"),
        ("Launch decision calendar", ["List decisions needed before launch: price, date confirmation, regions", "Set decision dates", "Prepare inputs", "Record"], "Decision calendar set")],
        ["Team member sick during launch week"], "production/milestones/launch_team.md", where="head")
    ph.fam("secondary", "Launch checklist per department", "§9 launch (/launch-checklist)", ["release", "team"],
           ["code", "content", "store", "marketing", "community", "infrastructure", "legal"],
           lambda d: f"`/launch-checklist`: {d} department",
           lambda d: [f"Run `/launch-checklist` section '{d}'", "Mark each item pass/fail with evidence links", "Assign owners for fails", f"Record in `production/milestones/launch_checklist_{d}.md`"],
           lambda d: f"{d} checklist complete or fails owned", ["Item owned by someone on leave"], "production/milestones/launch_checklist_*.md")
    ph.spec("secondary", "Store, price and ratings for 1.0", "§9 launch; business", ["business", "release", "legal"], [
        ("Price research", ["List comparable titles' launch prices (public store data, check current)", "Consider EA price history and promises to EA buyers", "Prepare options for the user", "Record"], "Price options ready"),
        ("Price and regional pricing decision", ["User decides the price", "Apply regional pricing using the store's current recommendations (check current)", "Record ADR", "Stage on store"], "Price set"),
        ("Release date announcement", ["Confirm the date with engineering readiness", "Prepare announcement with writing", "Schedule", "Publish"], "Date announced"),
        ("Store page 1.0 final", ["Update description, screenshots, trailer, content descriptors", "Check zh-Hans page", "Submit for store review if required (check current)", "Record"], "Store page approved"),
        ("Ratings delta check", ["Compare 1.0 content with the rated Beta content", "Update questionnaires if content changed", "Record certificates", "Update store age gates"], "Ratings current for 1.0"),
        ("EA to 1.0 transition comms", ["Explain to EA owners what changes at 1.0", "State save guarantee", "Schedule post", "Publish"], "EA comms published")],
        ["Regional pricing below the store floor"], "production/business/price_adr.md")
    ph.fam("secondary", "Launch marketing beats", "§8/§9 launch marketing", ["marketing"],
           ["L-90", "L-60", "L-45", "L-30", "L-21", "L-14", "L-7", "L-3", "L-1"],
           lambda b: f"Marketing beat {b}",
           lambda b: [f"Execute the {b} items from `production/marketing/launch_plan.md`", "Post assets in EN and zh-Hans", "Track wishlist/follower changes", f"Log in `production/marketing/beats/{b}.md`"],
           lambda b: f"{b} beat done and logged", ["Press embargo broken"], "production/marketing/beats/")
    ph.spec("secondary", "Press, creators and community launch prep", "§9 launch", ["marketing", "release"], [
        ("Press preview build", ["Prepare a press build branch with embargo notes", "Check current key distribution rules", "Send keys (user sends)", "Track coverage"], "Press keys sent"),
        ("Creator programme", ["Select creators by audience fit", "Send kits and keys (user sends)", "Set spoiler guidance", "Track"], "Creator keys sent"),
        ("Launch trailer approval", ["Review final trailer cut with audio", "Check ratings compliance of footage", "Approve", "Schedule"], "Trailer approved"),
        ("Launch trailer release", ["Publish trailer", "Update store", "Post in communities", "Track"], "Trailer live"),
        ("Community launch FAQ", ["Write FAQ: saves, difficulty, timing, missables, zh-Hans", "Write known issues list", "Set support channels", "Publish"], "FAQ live"),
        ("War-room comms plan", ["Pre-write status message templates", "Set posting cadence", "Define escalation", "Rehearse"], "Comms plan rehearsed")],
        ["Creator spoils an ending"], "production/marketing/")
    ph.spec("secondary", "Console partner business management", "§9 Y8 console ports (chosen partner)", ["business", "legal", "team"], [
        ("Partner contract review", ["Review business terms and technical annex with a lawyer (user engages)", "Check IP ownership and source access clauses", "List changes", "Record"], "Contract comments ready"),
        ("Partner contract signature", ["Agree final terms (user)", "Sign (user)", "Store contract privately (not in repo)", "Record milestones"], "Contract signed"),
        ("Platform developer programmes", ["Check current requirements to join each platform's developer programme (check current rules)", "Prepare company documents (user)", "Apply or confirm partner covers it", "Record"], "Programme status recorded"),
        ("Partner kickoff", ["Kickoff with partner: scope, cadence, bug flow", "Share docs", "Set first milestone", "Record"], "Kickoff done")],
        ["Partner delay threatens Y9 console launches"], "production/business/console_partner.md")
    ph.add_series("secondary", [Phase.T("secondary", f"Console partner milestone review M{m}", "§9 Y8 console ports (chosen partner)", ["business", "release"],
                                        [D(f"Partner milestone review M{m}", [f"Review partner milestone M{m} deliverables", "Check acceptance tests from the contract annex",
                                                                             "Approve payment or list fixes (user decides)", f"Record in `production/business/console_partner.md` (M{m})"], f"M{m} reviewed")],
                                        ["Milestone accepted with open cert risks"], "production/business/console_partner.md") for m in range(1, 8)])
    ph.anchor(ph.fam("secondary", "Launch war room: community", "§9 war room", ["release", "marketing"], WAR[2:],
           lambda w: f"Community war room {w}",
           lambda w: [f"Post the {w} status update", "Read top community threads and reviews; tag issues to intake", "Answer common questions with the FAQ", f"Log sentiment in `production/warroom/community_{w}.md`"],
           lambda w: f"{w} community log written", ["Review bombing over a misunderstanding"], "production/warroom/"), 0.375)
    ph.fam("secondary", "Post-launch marketing beats", "§9 launch", ["marketing"], ["L+1", "L+3", "L+7 (week-one)", "L+14", "L+30"],
           lambda b: f"Post-launch beat {b}",
           lambda b: [f"Execute the {b} beat (thanks post, stats, roadmap teaser)", "Share player highlights with permission", "Track sales/review trend", "Log"],
           lambda b: f"{b} beat logged", ["Negative press cycle"], "production/marketing/beats/")
    ph.fam("secondary", "Boss difficulty review from launch telemetry", "P6: bosses hard on every difficulty, fair on all", ["difficulty", "combat"], BOSSES,
           lambda b: f"Live difficulty review {b['bid']} {b['bname']}",
           lambda b: [f"Read {b['bid']} attempts/deaths per difficulty from telemetry", "Compare with Beta targets", "Propose data-only tuning if outside band (never frame windows)", f"Record `production/live/difficulty/{b['bid']}.md`"],
           lambda b: f"{b['bid']} reviewed", ["Telemetry skewed by speedrunners"], "production/live/difficulty/", chunk=6)
    ph.fam("secondary", "Live feedback synthesis per region and system", "Live support; fun factor", ["fun", "ux"],
           [f"{r} {n}" for r, n, _ in REGIONS] + SYSTEMS,
           lambda x: f"Feedback synthesis: {x}",
           lambda x: [f"Collect reviews, forum and support items mentioning {x}", "Run `/playtest-report` style grouping", "Separate bugs, design issues, praise", f"Record actions in `production/live/feedback/{x.split()[0].replace('/', '_')}.md`"],
           lambda x: f"{x} feedback synthesised", ["Feedback in zh-Hans only"], "production/live/feedback/", chunk=6)
    ph.fam("secondary", "QoL designs", "Live support UX", ["ux", "systems"], QOL,
           lambda q: f"{q} quick design",
           lambda q: [f"Write `/quick-design` for {q} from the top feedback items", "Check it never changes difficulty or timing windows", "Define test and evidence", "Hand to primary"],
           lambda q: f"{q} spec ready", ["QoL request that breaks a pillar"], "design/quick/")
    ph.fam("secondary", "Post-launch limited-edition calendar", "P7b limited editions on the calendar", ["economy", "items"], LE_POST,
           lambda le: f"Limited-edition release {le} design",
           lambda le: [f"Define {le}: slot, rarity, stock, place and time (in-game calendar), auction or shop", "Check economy rules and signposting in advance", "Request art/writing", f"Record `design/live/{le}.md`"],
           lambda le: f"{le} designed", ["Missable item with no advance signpost (not allowed)"], "design/live/")
    ph.fam("secondary", "Economy telemetry review", "§8 telemetry; exploit turnaround <= 1 patch", ["economy"], [f"month {m}" for m in range(1, 9)],
           lambda m: f"Economy review post-launch {m}",
           lambda m: [f"Compare live money supply and prices ({m}) with the sim", "Check exploit alerts", "Decide data changes for next patch", "Record"],
           lambda m: f"Economy {m} reviewed", ["Exploit spread through a video"], "production/live/econ/")
    xrows = [("X1 world bible: Human Patch Lab", ["Read the cut-kingdom material in `design_archive/` for Human Patch Lab", "Extract canon only; mark gaps as open questions", "Write structure: districts, factions present, ties to axes", "Store `design/expansion1/k1_world.md`"], "K1 bible draft"),
             ("X1 world bible: Forgotten Sectors", ["Read cut-kingdom material for Forgotten Sectors", "Extract canon; mark gaps", "Write structure", "Store `design/expansion1/k2_world.md`"], "K2 bible draft"),
             ("X1 scope and budget", ["Set X1 content budget: 12 chunk sets, 4 bosses, 6 enemies, 20 side quests, 6 TQs, 4 secrets, 16 commodities, 8 events, 12 Tier B NPCs, 8 item sets", "Cost from measured Y3-Y6 speed", "Cut list", "Record"], "Budget set"),
             ("X1 narrative director review", ["Check X1 plans against STORY_BIBLE and the Null Court thesis", "Ensure no retcon of the 27 storylines", "List open canon questions for the user", "Record"], "Canon review done")]
    xrows += [(f"Storyline design {st} (day {k})", [f"{'Define how ' + st + ' attaches to the axes (additive)' if k == 1 else 'Define scenes changed, ending hook and Story+ state for ' + st}", "Check against §12.2 rules",
                                                    "Use IDs, not invented plot, where canon is open", f"Record `design/expansion1/{st}.md`"], f"{st} design day {k} done") for st in X1_ST for k in (1, 2, 3)]
    xrows += [(f"Side quest outline {q} ({rg})", [f"Outline {q}: giver, objective, axis or timing hook", "Assign timing type if time-sensitive", "Estimate cost", f"Record `design/expansion1/quests/{q}.md`"], f"{q} outlined") for q, rg in X1_SQ]
    xrows += [(f"Time-sensitive quest {q} ({t})", [f"Define {q}'s {t} rule and leniency per difficulty", "Define the signpost", "Define Story+ reflection", "Record"], f"{q} defined") for q, t in X1_TQ]
    xrows += [(f"Secret quests {X1_SC[0]}-{X1_SC[1]}", ["Define hidden triggers", "Define hints", "Define reward", "Record"], "Secrets 1-2 defined"),
              (f"Secret quests {X1_SC[2]}-{X1_SC[3]}", ["Define hidden triggers", "Define hints", "Define reward", "Record"], "Secrets 3-4 defined")]
    xrows += [(f"Market goods {X1_CM[k]}-{X1_CM[k + 3]}", ["Define base price, seasonality and NPC agents", "Check arbitrage rules", "Check the sim", "Record"], f"{X1_CM[k]}-{X1_CM[k + 3]} defined") for k in range(0, 16, 4)]
    xrows += [(f"World events {X1_EV[k]}-{X1_EV[k + 1]}", ["Define calendar timing and conditions", "Define NPC and market effects", "Define signposting", "Record"], f"{X1_EV[k]}-{X1_EV[k + 1]} defined") for k in range(0, 8, 2)]
    xrows += [(f"Boss design {b} ({rg})", [f"Define {b} pattern list and Hell-only phase concept", "Define arena context", "Define per-difficulty variants", "Record"], f"{b} designed") for b, rg in X1_BOSSES]
    xrows += [("Enemy designs X1-E51..E53", ["Define roles and tells", "Define frame-data targets", "Define drops", "Record"], "E51-E53 designed"),
              ("Enemy designs X1-E54..E56", ["Define roles and tells", "Define frame-data targets", "Define drops", "Record"], "E54-E56 designed")]
    xrows += [(f"Tier B NPCs {X1_NB[k]}-{X1_NB[k + 3]}", ["Define role, schedule, memory facts", "Define market role if merchant", "Define mini-arc", "Record"], f"{X1_NB[k]}-{X1_NB[k + 3]} defined") for k in range(0, 12, 4)]
    xrows += [(f"Item sets {X1_IS[k]}-{X1_IS[k + 1]}", ["Define set bonuses and affixes", "Check balance with `/balance-check`", "Define crafting tree hooks", "Record"], f"{X1_IS[k]}-{X1_IS[k + 1]} defined") for k in range(0, 8, 2)]
    xrows += [(f"Level block-out plan {cs} ({n})", [f"Sketch {cs} layout: POIs, traversal gates, waystation", "Mark encounter spaces and terrain contexts", "Check chunk budget", "Record"], f"{cs} planned") for cs, _, n in X1_CS]
    xrows += [("X1 epics and stories", ["Run `/create-epics` for X1 content", "Run `/create-stories` for the first two epics", "Run `/estimate`", "Record"], "X1 epics exist"),
              ("X1 greenlight", ["Review budget vs capacity", "User decides go/re-scope", "Record ADR", "Update Y9 plan"], "X1 greenlit")]
    ph.spec("secondary", "Expansion 1 pre-production (part 1)", "§9 Y9 Expansion 1: 2 cut kingdoms, new storylines, goods, events", ["story", "quests", "level", "economy"], xrows[:30],
            ["Cut-kingdom material contradicts current canon"], "design/expansion1/")
    ph.spec("secondary", "Expansion 1 pre-production (part 2)", "§9 Y9 Expansion 1", ["quests", "level", "economy", "items"], xrows[30:],
            ["Budget exceeds capacity"], "design/expansion1/")
    ph.fam("secondary", "Console store pages and ratings", "§9 console ports", ["release", "legal", "marketing"],
           [(p, n, t) for p, n in PLATFORMS for t in ("rating", "store page", "marketing plan")],
           lambda u: f"{u[0]} {u[2]}",
           lambda u: [f"Prepare {u[1]} {u[2]} (check current platform requirements)", "Reuse PC material where allowed", "Get partner/platform feedback", f"Record `production/console/{u[0]}/{u[2].replace(' ', '_')}.md`"],
           lambda u: f"{u[0]} {u[2]} ready", ["Rating differs from PC"], "production/console/")
    ph.fam("secondary", "Business and team reviews", "Risk: funding, burnout, key person", ["business", "team"],
           [f"month {m:02d}" for m in range(1, 13)],
           lambda m: f"Y8 {m}: business and team review",
           lambda m: [f"Review sales, refunds and costs for {m} (business)", "Update runway forecast", "Check team load and energy", f"Record `production/business/y8_{m.replace(' ', '_')}.md`"],
           lambda m: f"Y8 {m} review recorded", ["Revenue below forecast"], "production/business/")
    ph.spec("secondary", "Community programme and dev updates", "Live-ops: community", ["marketing", "team"], [
        (f"Dev update post #{k}", [f"Draft dev update #{k} with writing (roadmap, fixes, console progress)", "Avoid dates not yet committed", "Publish EN + zh-Hans", "Collect replies"], f"Dev update #{k} published") for k in range(1, 9)] + [
        ("Community moderation policy", ["Write moderation rules", "Set escalation", "Publish", "Brief helpers"], "Policy live"),
        ("Creator programme v2", ["Review creator results", "Update kit", "Plan console creators", "Record"], "Programme updated")],
        ["Harassment incident"], "production/community/")
    ph.spec("secondary", "Launch retrospective and runway plan", "Operating rhythm", ["team", "business"], [
        ("Launch retrospective", ["Run `/retrospective` for the launch", "Collect team input", "List changes for console launches", "Record"], "Retro recorded"),
        ("Runway plan after launch", ["Forecast revenue scenarios from launch data", "Decide Y9 staffing (user)", "Record", "Share with team"], "Runway plan recorded")],
        ["Team contract end dates"], "production/business/")
    ph.spec("secondary", "Launch + 6-month review", "§4: Y8 ends with the launch + 6-month review", ["release", "business", "docs"], [
        ("6-month review: player data", ["Collect sales, reviews, retention, completion by act and difficulty", "Collect storyline distribution", "Collect support themes", "Write player section"], "Player section written"),
        ("6-month review: product decisions", ["Compare against Gate 4 bars", "Decide priorities for Y9", "Record ADRs", "Write decision section"], "Decisions recorded"),
        ("6-month review: publish", ["Share internal review with team", "Publish a player-facing summary", "Archive", "Update roadmap"], "Review published")],
        ["Conflicting metrics"], "production/milestones/launch_plus_6.md", where="tail")
    ph.set_filler("secondary", Filler(
        lambda i: D(f"Player support follow-up PS-{i + 1:03d}: {REGIONS[i % 8][0]} {SYSTEMS[(i // 8) % 15]}",
                    [f"Review support tickets tagged {REGIONS[i % 8][0]} / {SYSTEMS[(i // 8) % 15]}", "Answer with workarounds; link to fixes", "Update FAQ if needed", "Tag recurring items for triage"],
                    f"PS-{i + 1:03d} tickets answered"),
        lambda n: f"Player support follow-up block {n:02d}", "Live support", ["release", "ux"], ["Ticket requiring a save edit (never edit; give guidance)"], "production/community/support/", "secondary"), 5)

    # ============================== ART ==============================
    ph.spec("art", "Launch art deliverables", "§9 launch marketing", ["marketing", "art"], [
        ("Launch trailer art finishing 1", ["Clean captured shots for the trailer", "Title cards final", "Check rating compliance", "Deliver"], "Trailer art set 1"),
        ("Launch trailer art finishing 2", ["End card and logo animation", "zh-Hans variant", "Deliver", "Archive"], "Trailer art set 2"),
        ("Launch trailer art finishing 3", ["Fix notes from review", "Export masters", "Deliver", "Archive"], "Trailer art final"),
        ("Launch key art final adjustments", ["Update key art with 1.0 logo", "Export all sizes (check current specs)", "Deliver", "Archive"], "Key art final"),
        ("Launch capsule refresh", ["Refresh capsules for launch", "Check current specs", "Deliver", "Archive"], "Capsules final"),
        ("Launch social set A", ["Countdown images", "EN + zh-Hans", "Deliver", "Archive"], "Social A"),
        ("Launch social set B", ["Launch-day images", "EN + zh-Hans", "Deliver", "Archive"], "Social B"),
        ("Launch social set C", ["Week-one thanks images", "EN + zh-Hans", "Deliver", "Archive"], "Social C"),
        ("Achievement icon audit", ["Check all PC achievement icons", "Fix missing/unclear", "Deliver", "Archive"], "Icons complete"),
        ("Credits art update", ["Add new contributors", "Check layout", "Deliver", "Archive"], "Credits art updated")],
        ["Spoiler in key art"], "production/marketing/assets/")
    ph.fam("art", "Console UI adaptation", "Console ports", ["ui", "art"], [(p, n, t) for p, n in PLATFORMS for t in ("glyph set", "TV safe area and UI scale", "store art", "achievement/trophy icons")],
           lambda u: f"{u[0]} {u[2]}",
           lambda u: [f"Produce {u[1]} {u[2]} per current platform requirements (check current)", "Check readability at 1080p and 4K TV distance", "Import with fallbacks", f"Capture `production/qa/evidence/y8/console/{u[0]}_{u[2].split()[0]}.png`"],
           lambda u: f"{u[0]} {u[2]} delivered", ["Platform requires specific icon sizes"], "production/qa/evidence/y8/console/", chunk=6)
    ph.fam("art", "Console memory: art budgets per region", "Console ports performance", ["art", "performance"], [(r, n, k) for r, n, _ in REGIONS for k in (1, 2)],
           lambda u: f"Console texture budget {u[0]} {u[1]} pass {u[2]}",
           lambda u: [f"{'List largest textures/atlases' if u[2] == 1 else 'Apply reductions and re-pack atlases'} in {u[0]}", "Keep visual parity at 1x", "Re-import; fallbacks intact", "Record memory delta"],
           lambda u: f"{u[0]} pass {u[2]} done", ["Atlas shared across regions"], "production/console/art_memory.md", chunk=8)
    ph.fam("art", "Post-launch art polish from feedback", "Live support", ["art", "assets"], [(r, n, k) for r, n, _ in REGIONS for k in ("readability", "visual bugs")],
           lambda u: f"Post-launch art {u[0]} {u[2]}",
           lambda u: [f"Read player feedback on {u[0]} {u[2]}", "Fix specific visible issues only (baselines protected)", "Capture before/after", "Close tickets"],
           lambda u: f"{u[0]} {u[2]} fixed", ["Fix requested on accepted baseline (escalate)"], "production/qa/evidence/y8/art/", chunk=8)
    ph.fam("art", "Ending slide art check per storyline", "P3/P8", ["art", "story", "cinematics"], STORYLINES,
           lambda s: f"Ending slide art {s['sid']}",
           lambda s: [f"Review composed ending slides for {s['sid']}", "Fix composition seams between modular slides", "Check text space for zh-Hans", "Capture"],
           lambda s: f"{s['sid']} slides clean", ["Slide variant missing for a companion state"], "production/qa/evidence/y8/endings/", chunk=9)
    ph.fam("art", "Post-launch limited-edition item art", "P7b", ["items", "art"], [(le, k) for le in LE_POST for k in ("icon", "world/weapon sprite")],
           lambda u: f"{u[0]} {u[1]}",
           lambda u: [f"Produce {u[0]} {u[1]} per design", "Check rarity readability", "Import with fallback", "Capture"],
           lambda u: f"{u[0]} {u[1]} delivered", ["Weapon sprite misaligned in one direction"], "assets/items/live/", chunk=8)
    xr = [("X1 art bible extension", ["Run `/art-bible` to extend the bible for Human Patch Lab and Forgotten Sectors", "Define palettes and motifs from canon only", "Get user approval", "Store"], "Bible extension approved"),
          ("X1 asset specs", ["Run `/asset-spec` for X1 tiles, props, enemies, bosses, NPCs, items", "Estimate counts", "Mark ComfyUI vs PAE vs hand per truth gate", "Store"], "Specs ready")]
    xr += [(f"X1 concept: {n} {t}", [f"Concept {t} for {n} per bible", "Review with user", "Iterate once", "Store under `assets/art_sources/expansion1/`"], f"{n} {t} concept approved")
           for _, n in X1_REG for t in ("tiles", "props", "landmarks", "palette night/day")]
    xr += [(f"X1 boss concept {b}", [f"Concept {b} silhouette and tells", "Review", "Iterate", "Store"], f"{b} concept approved") for b, _ in X1_BOSSES]
    xr += [(f"X1 enemy concepts {X1_ENEMIES[k][0]}-{X1_ENEMIES[k + 1][0]}", ["Concept silhouettes", "Review", "Iterate", "Store"], "Enemy concepts approved") for k in range(0, 6, 2)]
    xr += [(f"X1 NPC concepts {X1_NB[k]}-{X1_NB[k + 3]}", ["Concept sprites", "Review", "Iterate", "Store"], "NPC concepts approved") for k in range(0, 12, 4)]
    xr += [("X1 PAE palette validation", ["Validate new palettes in the PAE pipeline", "Check overlay layers", "Record", "Store"], "Palettes validated"),
           ("X1-R9 controlled grammar builder preview", ["Run the controlled builder for X1-R9 (preview-only, per AGENTS.md)", "Validate in Godot preview", "Record verdict", "No production import"], "R9 preview validated"),
           ("X1-R10 controlled grammar builder preview", ["Run the controlled builder for X1-R10 (preview-only)", "Validate in Godot preview", "Record verdict", "No production import"], "R10 preview validated")]
    xr += [(f"X1 tileset first pass {cs}", [f"Produce first-pass tiles for {cs}", "Validate seams", "Preview only", "Record"], f"{cs} first pass") for cs, _, _ in X1_CS]
    ph.spec("art", "Expansion 1 art pre-production (part 1)", "§9 Y9 Expansion 1", ["art", "assets"], xr[:20], ["Concept contradicts canon"], "assets/art_sources/expansion1/")
    ph.spec("art", "Expansion 1 art pre-production (part 2)", "§9 Y9 Expansion 1", ["art", "assets"], xr[20:], ["Preview tiles fail seam check"], "assets/art_sources/expansion1/")
    ph.fam("art", "Monthly social assets", "Live-ops marketing", ["marketing", "art"], [f"month {m:02d}" for m in range(1, 13)],
           lambda m: f"Y8 social set {m}", lambda m: [f"Produce the {m} social set", "Non-spoiler content", "EN + zh-Hans", "Approve"], lambda m: f"Y8 {m} set approved",
           ["Debug UI in capture"], "production/marketing/assets/social/")
    ph.set_filler("art", Filler(
        lambda i: D(f"Live art fix AF-{i + 1:03d}: {REGIONS[i % 8][0]} {['tiles', 'props', 'NPC sprites', 'enemy sprites', 'UI art', 'VFX', 'icons', 'portraits'][(i // 8) % 8]}",
                    [f"Pull reported art issues: {REGIONS[i % 8][0]} {['tiles', 'props', 'NPC sprites', 'enemy sprites', 'UI art', 'VFX', 'icons', 'portraits'][(i // 8) % 8]}", "Fix top 4 (baselines protected)", "Import and fallback check", "Close tickets"],
                    f"AF-{i + 1:03d} closed"),
        lambda n: f"Live art fixes block {n:02d}", "Live support", ["art", "assets", "vfx"], ["Fix needs collision change (not allowed)"], "production/qa/evidence/y8/art/", "art"), 5)

    # ============================== AUDIO ==============================
    ph.spec("audio", "Launch audio lock", "§9 launch", ["audio", "release"], [
        ("Launch trailer final mix", ["Mix final trailer", "Loudness for video platforms (check current)", "Deliver stems", "Archive"], "Trailer mix final"),
        ("Launch mix lock 1", ["Final loudness sweep R1-R4", "Fix outliers", "Lock", "Record"], "R1-R4 locked"),
        ("Launch mix lock 2", ["Final loudness sweep R5-R8 and Story+", "Fix outliers", "Lock", "Record"], "R5-R8 locked"),
        ("Launch audio regression", ["Play 2 h with focus on audio bugs", "Fix criticals", "Lock", "Record"], "Audio regression clean")],
        ["Late change after lock"], "production/qa/y8/audio/")
    ph.fam("audio", "Console audio per platform and region", "Console ports", ["audio", "performance"], [(p, n, r) for p, n in PLATFORMS for r, _, _ in REGIONS],
           lambda u: f"{u[0]} audio in {u[2]} {RNAME[u[2]]}",
           lambda u: [f"Check {u[1]} audio formats and streaming banks for {u[2]} (check current platform guidance)", "Measure audio memory", "Check loudness on TV speakers", "Record"],
           lambda u: f"{u[0]} {u[2]} audio ok", ["Audio stall on streaming"], "production/console/audio.md", chunk=8)
    ph.fam("audio", "Console haptics", "P9", ["audio", "ux"], [(p, n, k) for p, n in PLATFORMS for k in (1, 2)],
           lambda u: f"{u[0]} haptics pass {u[2]}",
           lambda u: [f"{'Map haptic patterns' if u[2] == 1 else 'Tune intensities'} for {u[1]} controllers", "Respect AX12 settings", "Test", "Record"],
           lambda u: f"{u[0]} haptics pass {u[2]} done", ["Controller without rumble"], "production/console/haptics.md")
    ph.fam("audio", "Repetition fatigue: music variation per region", "Long playtime (100+ h)", ["music", "audio"], [(r, n, k) for r, n, _ in REGIONS for k in ("day", "night")],
           lambda u: f"Music variation {u[0]} {u[2]}",
           lambda u: [f"Add or rotate variation layers for {u[0]} {u[2]} exploration music", "Check loop seams", "Check adaptive transitions", "Record"],
           lambda u: f"{u[0]} {u[2]} variation added", ["Variation clashes with festival music"], "assets/audio/music/", chunk=8)
    ph.fam("audio", "SFX variation expansion", "Long playtime fatigue", ["audio"], SFXB,
           lambda sb: f"SFX variation expansion {sb}",
           lambda sb: [f"Find the most-triggered SFX in {sb} from telemetry", "Add 2-3 variations each", "Check bus levels", "Record"],
           lambda sb: f"{sb} variations added", ["Variation louder than original"], "production/qa/y8/audio/", chunk=6)
    ph.fam("audio", "Boss tell feedback tuning", "P6 fairness", ["audio", "combat"], [BOSSES[i:i + 2] for i in range(0, 24, 2)],
           lambda g: f"Tell audio feedback {g[0]['bid']}-{g[1]['bid']}",
           lambda g: [f"Read fairness feedback for {g[0]['bid']} and {g[1]['bid']}", "Adjust tell cue clarity", "Check Hell phase", "Record"],
           lambda g: f"{g[0]['bid']}/{g[1]['bid']} tuned", ["Cue masking by music"], "production/qa/y8/audio/", chunk=6)
    ph.fam("audio", "Soundtrack album mastering", "Business: soundtrack release (check rights)", ["music", "business"], [MUSIC[i:i + 3] for i in range(0, 45, 3)],
           lambda g: f"OST master {g[0]}-{g[-1]}",
           lambda g: [f"Create album edits of {', '.join(g)}", "Master for streaming (check current loudness guidance)", "Write track metadata", "Archive"],
           lambda g: f"{g[0]}-{g[-1]} album masters done", ["Licensed sample in a track (check rights)"], "production/ost/", chunk=5)
    ph.fam("audio", "Post-launch limited-edition stingers", "P7b", ["audio"], LE_POST,
           lambda le: f"{le} audio", lambda le: [f"Create acquisition stinger/SFX for {le}", "Mix", "Integrate", "Record"], lambda le: f"{le} audio done", ["Stinger during combat"], "assets/audio/live/")
    xa = [("X1 audio direction", ["Write audio direction for Human Patch Lab and Forgotten Sectors from the bible", "Define instrument palettes", "User approval", "Store"], "Direction approved"),
          ("X1 ambience concepts K1", ["Sketch Human Patch Lab ambience layers", "Review", "Iterate", "Store"], "K1 ambience concept"),
          ("X1 ambience concepts K2", ["Sketch Forgotten Sectors ambience layers", "Review", "Iterate", "Store"], "K2 ambience concept"),
          ("X1 SFX lists", ["List SFX per X1 asset class", "Estimate counts per batch X1-SB-01..04", "Mark reuse", "Store"], "SFX lists ready")]
    xa += [(f"X1 music sketch {mt} (day {k})", [f"{'Write motif and harmony' if k == 1 else ('Arrange adaptive layers' if k == 2 else 'Review and revise')} for {mt}", "Check against direction", "Export sketch", "Store"], f"{mt} sketch day {k}") for mt in X1_MT for k in (1, 2, 3)]
    xa += [(f"X1 boss theme sketch {b}", [f"Sketch {b} theme with Hell-phase variant", "Review", "Iterate", "Store"], f"{b} theme sketched") for b, _ in X1_BOSSES]
    ph.spec("audio", "Expansion 1 audio pre-production", "§9 Y9 Expansion 1", ["audio", "music"], xa, ["Theme too close to an existing track"], "assets/audio/expansion1/")
    ph.set_filler("audio", Filler(
        lambda i: D(f"Live audio fix AUF-{i + 1:03d}: {REGIONS[i % 8][0]} {['ambience', 'footsteps', 'combat SFX', 'UI sounds', 'music transitions', 'barks', 'world events', 'cutscene audio'][(i // 8) % 8]}",
                    [f"Pull reported issues: {REGIONS[i % 8][0]} {['ambience', 'footsteps', 'combat SFX', 'UI sounds', 'music transitions', 'barks', 'world events', 'cutscene audio'][(i // 8) % 8]}", "Fix top 4", "Re-test", "Close"],
                    f"AUF-{i + 1:03d} closed"),
        lambda n: f"Live audio fixes block {n:02d}", "Live support", ["audio"], ["Issue only on one output device"], "production/qa/y8/audio/", "audio"), 5)

    # ============================== WRITING ==============================
    ph.spec("writing", "Launch copy", "§9 launch", ["marketing", "release"], [
        ("Press release final", ["Finalise release text with date and price", "zh-Hans version", "Approve", "Archive"], "Press release final"),
        ("Launch FAQ and known issues", ["Write FAQ", "Write known issues", "zh-Hans", "Publish via secondary"], "FAQ ready"),
        ("Store copy final", ["Final store copy", "zh-Hans", "Approve", "Archive"], "Store copy final"),
        ("EA transition note", ["Write EA-to-1.0 note", "zh-Hans", "Approve", "Archive"], "EA note final"),
        ("Launch day posts", ["Write launch-day posts", "zh-Hans", "Approve", "Schedule"], "Posts scheduled"),
        ("Week-one thanks post", ["Write thanks post with stats placeholders", "zh-Hans", "Approve", "Schedule"], "Thanks post ready"),
        ("Credits final", ["Final credits text", "Check names", "Approve", "Deliver"], "Credits final"),
        ("Support macros", ["Write support response templates for top 10 issues", "zh-Hans", "Approve", "Deliver"], "Macros ready")],
        ["Price change after copy approval"], "production/marketing/copy/")
    ph.fam("writing", "Patch notes and zh-Hans deltas", "Live-ops cadence", ["localization", "release"], PATCHES + HOTFIX,
           lambda p: f"Notes and loc delta for {p}",
           lambda p: [f"Draft EN notes for {p} in player language", f"Translate the {p} string delta into zh-Hans", "Check glossary", "Hand to secondary"],
           lambda p: f"{p} notes + delta ready", ["String changed after freeze"], "production/community/", chunk=6)
    ph.fam("writing", "Dev update copy", "Community", ["marketing", "docs"], [f"#{k}" for k in range(1, 13)],
           lambda k: f"Dev update copy {k}", lambda k: [f"Draft dev update {k}", "Fact-check with the team", "zh-Hans", "Hand to secondary"], lambda k: f"Dev update {k} ready",
           ["Promise of a date not committed"], "production/community/")
    ph.fam("writing", "Story+ and ending text fixes from players", "P3/P8 live quality", ["story", "dialogue"], STORYLINES,
           lambda s: f"Live text fixes {s['sid']}",
           lambda s: [f"Read player reports for {s['sid']} endings/Story+", "Fix continuity and typo issues", "Update zh-Hans", "Commit"],
           lambda s: f"{s['sid']} fixes committed", ["Fix changes a choice's meaning"], "string tables", chunk=9)
    ph.fam("writing", "Limited-edition lore", "P7b", ["items", "story"], LE_POST,
           lambda le: f"{le} lore text", lambda le: [f"Write {le} name, description and signpost notice", "Check canon", "zh-Hans", "Commit"], lambda le: f"{le} text done",
           ["Name clash with an existing item"], "string tables")
    ph.fam("writing", "Console terminology compliance", "Console cert (check current platform requirements)", ["localization", "release"], [(p, n, k) for p, n in PLATFORMS for k in ("EN", "zh-Hans", "achievement text")],
           lambda u: f"{u[0]} terminology {u[2]}",
           lambda u: [f"Check {u[1]} required terms for {u[2]} (check current requirements)", "Replace PC terms (e.g. button names) via platform string tables", "Verify in build", "Record"],
           lambda u: f"{u[0]} {u[2]} compliant", ["Term differs between platforms"], "production/console/")
    wx = [("X1 narrative structure", ["Extend world bible structure for both kingdoms (canon only)", "List open canon questions for the user", "Define voice notes", "Store"], "Structure ready"),
          ("X1 zh-Hans glossary extension", ["Add X1 terms", "Decide translation approach", "Store", "Brief translator"], "Glossary extended"),
          ("X1 dialogue budget", ["Estimate words per quest/scene", "Compare with measured writer speed", "Cut list", "Store"], "Budget set")]
    wx += [(f"Storyline outline {st} (day {k})", [f"{'Beat outline' if k == 1 else ('Scene list X1 scenes 1-4' if k == 2 else 'Ending/Story+ hooks')} for {st}", "Use IDs where canon is open", "Check voice guide", "Store"], f"{st} outline day {k}") for st in X1_ST for k in (1, 2, 3)]
    wx += [(f"Quest outline text {q}", [f"Write {q} objective lines and key dialogue beats", "Mark timing hooks", "Check canon", "Store"], f"{q} outline text") for q, _ in X1_SQ]
    wx += [(f"TQ signpost plan {q}", [f"Write signpost plan for {q}", "Write warning line drafts", "Story+ line draft", "Store"], f"{q} plan") for q, _ in X1_TQ]
    wx += [(f"Secret quest hints {s}", [f"Write hint trail for {s}", "Check fairness", "Store", "Flag for review"], f"{s} hints") for s in X1_SC]
    wx += [(f"NPC profile {nb}", [f"Write {nb} profile: role, voice, memory facts", "Check schedule hooks", "Store", "Flag barks needed"], f"{nb} profile") for nb in X1_NB]
    wx += [(f"Item set text {s}", [f"Write names/descriptions for {s}", "Check affixes", "Store", "zh-Hans note"], f"{s} text") for s in X1_IS]
    wx += [(f"Main scene draft {st}-SCN{k}", [f"Draft {st} scene {k}", "Check voice guide", "Review with user", "Store"], f"{st}-SCN{k} drafted") for st in X1_ST for k in range(1, 5)]
    wx += [(f"Barks draft {nb}", [f"Draft barks for {nb} keyed to time and player state", "Check repetition", "Store", "zh-Hans note"], f"{nb} barks") for nb in X1_NB]
    wx += [(f"Codex entries X1 batch {k}", ["Draft codex entries", "Check canon", "Store", "zh-Hans note"], f"Codex batch {k}") for k in range(1, 9)]
    ph.spec("writing", "Expansion 1 narrative pre-production (part 1)", "§9 Y9 Expansion 1", ["story", "quests", "dialogue"], wx[:30], ["Open canon question blocks a quest"], "design/expansion1/")
    ph.spec("writing", "Expansion 1 narrative pre-production (part 2)", "§9 Y9 Expansion 1", ["story", "npc", "dialogue"], wx[30:60], ["Bark references unreleased content"], "design/expansion1/")
    ph.spec("writing", "Expansion 1 narrative pre-production (part 3)", "§9 Y9 Expansion 1", ["story", "dialogue"], wx[60:], ["Codex spoils X1 storyline"], "design/expansion1/")
    ph.set_filler("writing", Filler(
        lambda i: D(f"Live text fix WF-{i + 1:03d}: {REGIONS[i % 8][0]} {['typos', 'overflow', 'continuity', 'tone', 'missing keys', 'barks', 'item text', 'quest log'][(i // 8) % 8]}",
                    [f"Pull player-reported text issues: {REGIONS[i % 8][0]} {['typos', 'overflow', 'continuity', 'tone', 'missing keys', 'barks', 'item text', 'quest log'][(i // 8) % 8]}", "Fix EN and zh-Hans", "Verify in game", "Close"],
                    f"WF-{i + 1:03d} closed"),
        lambda n: f"Live text fixes block {n:02d}", "Live support", ["dialogue", "localization"], ["Fix in a line referenced by achievements"], "string tables", "writing"), 5)

    # ============================== QA ==============================
    ph.fam("qa", "RC and gold verification", "Gate 7 follow-up", ["tests", "release"],
           [(rc, k) for rc in ("RC2", "RC3", "RC4 gold") for k in ("critical path", "regression suite")] + [("gold", f"matrix sign-off part {k}") for k in range(1, 6)] +
           [("store build", "launch smoke"), ("store build", "clean install + cloud save")] + [("saves", f"EA/Beta save load check {k}") for k in range(1, 4)],
           lambda u: f"{u[0]}: {u[1]}",
           lambda u: [f"Run {u[1]} on {u[0]}", "Log blockers immediately to the war-room intake", "Attach saves and video", f"Record `production/qa/y8/{u[0].replace(' ', '_')}.md`"],
           lambda u: f"{u[0]} {u[1]} signed off", ["Build mismatch between store and CI"], "production/qa/y8/", chunk=6)
    ph.fam("qa", "Hardware compatibility expansion", "Launch on wide PC hardware", ["tests", "performance"],
           ["GPU vendor C", "older 4-core CPU", "8 GB RAM machine", "HDD install", "multi-monitor", "laptop on battery", "Deck docked to TV", "non-English Windows locale"],
           lambda hw: f"Compatibility: {hw}", lambda hw: [f"Play 1 hour on {hw}", "Check crashes, perf, input", "Log", "Attach logs"], lambda hw: f"{hw} logged", ["Locale path with non-ASCII user name"], "production/qa/y8/hardware/")
    ph.anchor(ph.fam("qa", "War room repro", "§9 war room", ["tests", "release"], [w for w in WAR[2:] if w not in ("L+5", "L+6")],
           lambda w: f"War-room repro {w}", lambda w: [f"Reproduce the top new reports of {w}", "Attach repro saves", "Verify fixes on beta branch", "Log"], lambda w: f"{w} repro log done",
           ["Report from pirated build"], "production/warroom/qa/"), 0.36)
    ph.fam("qa", "Hotfix and patch verification", "Live-ops cadence", ["tests", "release"], [(p, k) for p in HOTFIX + PATCHES[3:] for k in ("fix verification", "regression")],
           lambda u: f"{u[0]} {u[1]}", lambda u: [f"Run {u[1]} for {u[0]}", "Check save-compat on device fixtures", "Spot-check zh-Hans", "Sign off or block"],
           lambda u: f"{u[0]} {u[1]} done", ["Patch changes difficulty data"], "production/qa/y8/patches/", chunk=6)
    ph.fam("qa", "Console pre-cert testing", "§9 cert prep (check current platform requirements)", ["tests", "release"], [(p, n, cc, cn) for p, n in PLATFORMS[:2] for cc, cn in CERT_CATS] + [(PLATFORMS[2][0], PLATFORMS[2][1], cc, cn) for cc, cn in CERT_CATS[:5]],
           lambda u: f"{u[0]} pre-cert test {u[2]}",
           lambda u: [f"Execute {u[2]} ({u[3]}) cases on {u[1]}", "Use the current requirement list (check current platform requirements)", "Log failures with video", f"Record `production/console/{u[0]}/qa_{u[2]}.md`"],
           lambda u: f"{u[0]} {u[2]} tested", ["Requirement interpretation unclear (ask partner)"], "production/console/", chunk=5)
    ph.fam("qa", "Console gameplay runs", "Console ports", ["tests", "performance"], [(p, n, r) for p, n in PLATFORMS[:2] for r, _, _ in REGIONS] + [(p, n, f"Act {a}") for p, n in PLATFORMS[:2] for a in range(1, 5)],
           lambda u: f"{u[0]} run: {u[2]}", lambda u: [f"Play {u[2]} on {u[1]}", "Log perf, crashes, input issues", "Check suspend/resume once", "Record"],
           lambda u: f"{u[0]} {u[2]} run logged", ["Devkit thermal issues"], "production/console/qa/", chunk=8)
    ph.fam("qa", "Console accessibility and localization", "Console ports", ["accessibility", "localization", "tests"],
           [(p, n, f"screens {SCREENS[k][0]}-{SCREENS[k + 2][0]}") for p, n in PLATFORMS[:1] for k in range(0, 24, 3)] + [(p, n, f"zh-Hans pass {k}") for p, n in PLATFORMS[:2] for k in (1, 2)],
           lambda u: f"{u[0]} {u[2]}", lambda u: [f"Test {u[2]} on {u[1]}", "Check text scale and glyphs", "Log", "Screenshot evidence"],
           lambda u: f"{u[0]} {u[2]} logged", ["TV distance legibility"], "production/qa/evidence/y8/console/", chunk=8)
    ph.fam("qa", "Live regression: Hell replays and endings", "P6 + P3 stay true after patches", ["tests", "difficulty", "story"],
           [("Hell replays", p) for p in PATCHES[3:]] + [("ending", s["sid"]) for s in STORYLINES],
           lambda u: f"Live check {u[0]} {u[1]}", lambda u: [f"Verify {u[0]} {u[1]} on the current live build", "Compare with gold results", "Log differences", "File regressions"],
           lambda u: f"{u[0]} {u[1]} verified", ["Patch changes a timing flag"], "production/qa/y8/live/", chunk=9)
    ph.fam("qa", "Expansion 1 early tests", "§9 Y9 Expansion 1", ["tests", "openworld"], ["test plan"] + [cs for cs, _, _ in X1_CS[:6]],
           lambda u: f"X1 early test: {u}", lambda u: ["Write the X1 test plan with `/qa-plan`", "Define matrix extension", "Define replay plan", "Store"] if u == "test plan" else [f"Grey-box walk of {u}", "Check streaming seams and traversal gates", "Log", "Record"],
           lambda u: f"X1 {u} done", ["Grey-box collision placeholder"], "production/qa/y8/x1/", chunk=7)
    ph.set_filler("qa", Filler(
        lambda i: D(f"Community bug repro CB-{i + 1:03d}: {REGIONS[i % 8][0]} x {SYSTEMS[(i // 8) % 15]}",
                    [f"Reproduce community reports for {SYSTEMS[(i // 8) % 15]} in {REGIONS[i % 8][0]}", "Add repro steps and saves to the issue", "Mark cannot-reproduce with what was tried", "Update triage"],
                    f"CB-{i + 1:03d} reports processed"),
        lambda n: f"Community bug repro block {n:02d}", "Live support", ["tests"], ["Report from modded install"], "Issue tracker", "qa"), 5)
    add_extra(ph)
    return ph


if __name__ == "__main__":
    print(build().counts())
