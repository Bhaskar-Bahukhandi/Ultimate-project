# Edge cases per tag: one per line.
RAW = {
"code": """
A node is freed while a coroutine is awaiting on it (await resumes on a dead instance)
A signal is emitted during the receiver's _exit_tree
Two autoloads call each other in _ready before both are initialised
A Callable bound to a freed object is called from a deferred call
Integer overflow in a counter that accumulates over 10 in-game years (gold, play time)
Float equality comparison on a timer value that never hits exactly 0.0
A typed Array receives a null element from a Resource load
A Dictionary key is a StringName in one place and a String in another
Script reloads in the editor while a @tool script holds state
A function called with a default arg that mutates a shared Array default
A match on an enum receives a value added later with no branch
Division by zero when a max-HP or max-stack value is 0 in data
Negative delta passed after a time_scale change to 0
Recursive signal: handler emits the same signal again
Deep recursion in a tree walk over a large scene (stack overflow)
String formatting with % when the value contains a % character
A path with spaces ('Ultimate project') passed to an external tool unquoted
A Resource is modified at runtime and the change leaks to every instance sharing it
An exported NodePath is empty because the scene was re-parented
An @onready var is used in _init before the node enters the tree
A static var keeps state between test runs in the same process
call_deferred queued twice for the same reset in one frame
Unicode (Simplified Chinese) characters in a string length or substr calculation
A for loop erases elements from the Array it is iterating
Node renamed in the scene breaks a get_node string path at runtime only
An enum value saved as int is reordered in a later version
Godot warns 'Attempt to call function on a null instance' only in release export
Process order between parent and child differs from the assumption
Floating point drift in a position after thousands of frames of small moves
OS-specific path separators in a path built with string concatenation
""",
"architecture": """
A new system needs data owned by GameManager before the owning service exists
Two services both believe they own the current scene transition
A service is used in a test without the scene tree (no autoloads)
Circular dependency appears between SaveService and StoryGraph
WorldClock is advanced by both rest and a cutscene in the same frame
ContextStack has a context pushed by a node that is then freed without popping
An autoload depends on a scene node that is not loaded in the main menu
The event order of quest completion and flag set differs between runs
A save from an older build references a system that no longer exists
A plugin or tool script writes into res:// at runtime
Two regions loaded at once during a seam both register the same NPC
A UI screen reads state directly from a gameplay node instead of a service
A cross-cutting feature (accessibility setting) needs to reach every system
An ADR decision is contradicted by code merged later
Removing an autoload breaks a scene that references it by name in a script string
A data Resource schema changes while hundreds of .tres files use the old fields
The streaming system unloads a chunk that holds an active quest object
A system emits on a global signal bus with no listener and the feature silently fails
A system requires a fixed tick but runs inside _process on one code path
A service holds a reference to a scene node across a scene change
Test seams require changing a public API used by 20 call sites
Two paths into the same arena (random encounter vs scripted) diverge in setup
Ending composer receives an axis value combination marked invalid
Story+ loads world state built for a storyline that was cut
Pause state and time_scale state disagree after a crash in a transition
Replay system records input but a system reads Input directly
A new difficulty knob is read in one place but not in the replay validator
A save migration needs data that only exists in a loaded scene
DebugTestMode hooks remain wired into a release build path
Feature flags for cut content leave dead branches in the composer
""",
"cleanup": """
Deleting a script leaves its .uid and breaks a scene that loads it by uid
Removing an 'unused' asset that is loaded by a string built at runtime
Deleting a scene referenced only from a .dlg command
Removing an input action still referenced by a saved remap file
Archiving docs that a test fixture reads
Renaming a folder breaks res:// paths in .tres files not opened in the editor
Removing an autoload still referenced by name in a test
Deleting tmpclaude files while a Claude session is using its cwd file
Deleting 'nul' fails due to Windows reserved-name handling
Pruning run_artifacts deletes evidence not yet copied to production/qa/evidence
Git LFS migration rewrites history on a branch others have
Removing generated_v2 when a fallback path in AssetManager points to it
Deleting a branch with unmerged commits
Removing an unused shader that is referenced inside a .tres material
Converting CRLF to LF corrupts a binary file wrongly marked as text
A cleanup commit mixes in a gameplay change and hides it in the diff
Deleting an empty folder that a tool expects to exist (scripts/validation)
Removing print statements that a test greps for in logs
A .gdignore placed in a folder that contains a needed resource
Export filter excludes a folder that a release scene loads
Removing dead code that is actually called via call() with a string
Removing an achievement ID that existing saves reference
Archiving a story doc that the dialogue extractor reads
Cleaning user:// deletes the user's real save on the dev machine
Removing a font still used in a Theme override
Deleting a sample .dlg used in dialogue_test
Removing a debug scene used by the screenshot tour
Squashing commits that are referenced by CHANGELOG hashes
Pruning a stash that contains the only copy of an experiment
Clearing .godot cache while the editor is still open
""",
"tests": """
A test passes alone but fails when run after another suite (shared autoload state)
A test depends on real time and fails on a slow CI machine
A test writes to user:// and the next run reads stale data
A route test passes because an earlier step silently skipped
Headless mode returns a different viewport size than the real game
A test awaits a signal that never fires and hangs CI
The test runner exits 0 when the script fails to parse
Two tests use the same save slot name in parallel runs
A screenshot test fails due to font hinting differences between machines
A random seed is set in the test but the system uses a global RNG
A test asserts on a print() string that changed wording
A test fixture is out of date with the current .dlg format
A test covers the happy path only and misses the cancel path
CI uses a different Godot patch version than local
A test passes because the assertion helper never fails
The test counts nodes and breaks when a decorative node is added
A long route test exceeds the CI timeout
A test leaks orphan nodes that slow later tests
Locale differences change number formatting in an assertion
Testing pause: timers in tests use process_always=true by accident
A quest bot finishes a quest via a debug shortcut real players cannot use
Floating point comparison in an assertion without a tolerance
A test relies on file order from DirAccess listing
gdUnit4 and legacy runners both run the same test twice
A test passes on an empty data set (no items loaded) vacuously
A test mocks a service but the real code calls the autoload directly
Reachability test misses scenes added outside the scanned folder
Test for Hell input replay passes at 60 fps but the tick drifts at 59.94 Hz
A regression test is written after the fix and never seen failing
Test names do not describe behaviour, so a failure message is unreadable
""",
"systems": """
Two modifiers on the same stat apply in a different order and give different results
A stat goes negative after a debuff stack
A cap applies before a percentage bonus instead of after
A training-based stat grows while the player is AFK in a loop
Respec at 0 gold or with equipped stat-requirement items
A companion synergy triggers twice when both companions are swapped in the same frame
Reputation hits the max and a further gain overflows or wraps
A crime is witnessed by an NPC who is despawned by simulation LOD
A difficulty change mid-run recalculates healing charges above the new max
Lowering difficulty during a boss fight changes telegraphs mid-attack
The ending composer receives two timing flags that contradict each other
Flag set on a branch the player later loses access to (Act 3 branch lock)
A stat buff expires during a pause or cutscene
An item grants a stat that affects parry windows (must not)
NG+ carries over a stat bonus that breaks early balance
A system reads a DifficultyProfile value that is missing in a new profile
Two systems react to the same world event and double-reward
Simulation LOD switches mid-schedule step and the NPC teleports
A timed buff and WorldClock rest interact (resting skips buff duration)
Level-up while the stat window is open shows stale values
Haggling stat at max plus best reputation breaks the 40% sell rule
Gambling luck stat exceeds its cap via items
Status effect applied to an enemy that is dying
Two status effects with the same ID from different sources
Faction reputation affects a merchant who belongs to two factions
XP gain from killing an enemy during a cutscene
A system needs the WorldClock while the clock is frozen by a menu
A storyline axis value is set by a side quest after the act locked it
Companion leaves the party with equipped unique items
Data-driven config file missing a key on load (defaults vs crash)
""",
"combat": """
Parry input lands on the exact frame the enemy hitbox deactivates
Player and enemy hit each other on the same frame (trade)
Hitstop overlaps with a ContextStack pause request
Dodge i-frames end inside a lingering hitbox
Two enemies hit the player in the same frame; damage applied once or twice
Player dies during hitstop from a parry
Pogo on an enemy that dies from the pogo hit
Attack cancel window input buffered across a stagger
Enemy knocked into a wall corner and stuck
Boss phase transition triggers while the player is in a Root Access slow-time
Root Access activated with exactly the required resource
Healing charge used on the frame the player takes lethal damage
Player lands a hit during the arena's victory transition
Last enemy dies from a DoT while the player is dead
Random encounter starts while a dialogue is opening
Arena generated from terrain with no flat ground (cliff edge)
Return from arena places the player inside an obstacle
Enemy attack telegraph shorter than 1 frame on Hell x0.7 multiplier
Combat starts with zero healing charges after a previous fight
Projectile hits during a scene transition fade
Enemy spawned off-screen inside a hazard
Controller disconnects mid-combo
Input buffer holds a jump across a death and respawn
Boss Hell-only phase triggers when difficulty was lowered mid-fight
Player at 1 HP takes a 0-damage hit (should not die, should feedback)
Multi-hit attack where the parry blocks only the first hit
Enemy stagger state receives another stagger
Aerial attack on the frame the player touches ground
Damage numbers or effects spawned after the enemy node is freed
Flee or escape from a fight that should not allow escape (boss)
""",
"animation": """
Animation interrupted on the impact frame; does the hit still apply
A clip transitions to itself and restarts every frame
Facing flips during an attack animation
Animation speed scaled by time_scale vs not (Root Access)
Idle animation desynchronised between identical NPCs looks robotic
A missing animation name falls back silently to a T-pose frame
Animation finished signal not emitted when the clip loops
Sprite frame offsets differ between clips causing a 1-pixel jump
Animation plays while the node is hidden then shows mid-clip
Death animation plays twice when killed by two hits in one frame
Walk cycle plays at 0 velocity due to a rounding threshold
Diagonal movement uses the wrong of 4 direction sets
Animation call during pause keeps playing or freezes unexpectedly
Hit flash shader resets mid-animation
Clip with variable frame durations misaligns with frame data
Portrait expression swap happens before the text line appears
Animation-driven root motion moves the character through a wall
Attack animation shorter than the hitbox active window
Cutscene animation cancelled by skip leaves the sprite in a mid pose
Long idle variant triggers during dialogue
Two AnimationPlayers fight over the same property
Animation tree parameter set before the tree is active
Sprite sheet updated with a different frame count than the SpriteFrames resource
Animation playback speed differs between 60 Hz and 144 Hz monitors
Looping ambient animation pops at the loop seam
Weapon sprite swap mismatched with the attack frame
Enemy animation for a state that the AI skips (never seen)
Palette swap applied to an animation frame that uses an off-palette colour
Spawn animation interrupted by an immediate attack
Animations continue for enemies culled off-screen (wasted cost)
""",
"cinematics": """
Player skips a cutscene on its first frame; required flags still set
Cutscene starts while the player is mid-air or in combat
Cutscene camera targets a node that was freed
Dialogue inside a cutscene waits for input but input is blocked by the cutscene context
Cutscene triggered twice by re-entering the trigger area
Save attempted during a cutscene
Controller disconnect during a cutscene
Letterbox bars persist after the cutscene ends
Music and cutscene audio both play after a skip
Cutscene runs at a different aspect ratio and reveals off-map areas
Cutscene ends while a ContextStack pause is active from the pause menu
Alt-tab during a cutscene with timing-based sequences
Cutscene depends on an NPC who is elsewhere because of their schedule
Player position after the cutscene overlaps an NPC collision
Cutscene variant missing for a timing flag combination
Skipping a cutscene skips a tutorial message
Cutscene speed-up option desyncs audio
Cutscene camera limits differ from the gameplay camera and snap back
Cutscene at 144 Hz plays faster or slower than at 60 Hz
Text in cutscene subtitles overflows in Simplified Chinese
Cutscene triggered while a quest deadline expires that same in-game minute
Cutscene expects a companion who left the party
Fade to black never fades back after an error
Cutscene during low HP leaves a low-HP warning sound looping
Glitch effect in cutscene with reduced-flash setting on
Cutscene plays after a load from a save made right before it
WorldClock advances during a cutscene unexpectedly
Story+ cutscene references an ending the player did not get
Cutscene's first frame shows the previous scene for one frame
Player can open the pause menu mid-cutscene and change difficulty
""",
"story": """
Player reaches a story scene with a flag combination not authored
Player skips an optional scene that a later scene references
Main-story deadline fails without the required signposted warning
Player completes Act 1 events out of the expected order
A companion who should comment on an event has left the party
A Tier A NPC needed for a scene died due to a timing flag
Two timing flags alter the same scene in conflicting ways
Player sees a reveal before the setup scene because of open-world order
Fragment Two acquired in an unexpected way (sequence break)
Source Key fragment count shown wrong after a load
A choice with no visible consequence is perceived as a bug
An ending is reached with an axis value that should be impossible
Story+ state contradicts the ending slide shown
NG+ replays a scene that assumes first-time knowledge
Player declines a main-story prompt repeatedly
Player returns to Oakhaven after Act 2 and NPCs still talk as Act 1
Seraphina choice made, then a reload with a different choice; flags leak
Story text references a region the player has not discovered yet
Lowering difficulty changes deadline leniency after a deadline already passed
A secret quest flag (Witness Protocol path) set by accident
The Voice (Mira) is named in text before the reveal
SOVEREIGN appears in an encounter before its introduction scene
God King foreshadowing removed by a cut leaves a dangling line
Player sequence-breaks into a region gated by story only
Chapter end triggered twice
A cut kingdom (Human Patch Lab, Forgotten Sectors) still referenced in dialogue
Ending composer chooses a sequence with no audio track
Player completes all side storylines before the main axis choice
A storyline counted as reached in the tracker but not in the composer
Player abandons the main story for 100+ in-game days
""",
"dialogue": """
Dialogue started while another dialogue is active
Line longer than the text box at the largest text size
A choice option with an empty text after a failed flag lookup
.dlg file with a missing label for a jump
Dialogue references a speaker with no portrait
Player mashes confirm and skips a choice
Dialogue opened while the player is being attacked
Bark triggers on an NPC that is mid-dialogue
A line with a variable placeholder that is null
Dialogue ends on a choice with no follow-up
Two NPCs bark at the same time and overlap
Dialogue choice timeout in a timed conversation with pause opened
Simplified Chinese line breaks mid-word in a wrong place
Name of a character changed in the bible but old name in old .dlg
Dialogue history/log missing lines after a skip
Dialogue that sets a flag twice when re-read
Portrait expression tag misspelled
Dialogue camera focus on an off-screen speaker
A line meant for a specific companion plays with a different one
Dialogue triggered during a scene transition fade
Repeat-talk to an NPC loops the same first-meeting line
Dialogue choices exceed the visible list (scrolling)
Dialogue with rich text tags that break the typewriter effect
Dialogue speed setting at maximum skips a voice blip sync
NPC dialogue depends on time of day at exactly the hour boundary
Dialogue triggered by a flag set in the same frame
Dialogue with a missing translation key in Chinese builds
Player saves and loads mid-conversation
Dialogue input buffered from combat confirms the first choice
Very short line (one word) shows a frame of empty box
""",
"quests": """
Quest completed before it was started (item already in inventory)
Quest giver dies or leaves before the quest is turned in
Deadline quest expires during a cutscene
Two quests require the same unique item
Quest marker points to an NPC in an unloaded chunk
Order-type quest done in both orders across save reloads
Window-type quest starts while the player is in another region
Duration quest with time spent paused or in menus
Quest reward given twice on fast double input
Quest log shows a deadline in the wrong calendar month (28-day month)
Abandoning a quest that sets an axis flag midway
Quest objective inside an area that is locked later by story
Side storyline step completed out of order
Quest item sold to a merchant
Quest item stored in a container the quest does not check
Quest requires a minigame the player finds too hard
Quest enemy killed by a companion or hazard rather than the player
Escort NPC falls into a hazard or gets stuck
Quest updated while the quest log UI is open
Quest that depends on a market event that did not occur
Secret quest trigger condition met during NG+
Quest that should fail when another succeeds, both completed via save scumming
Time-sensitive quest on Beginner vs Hell leniency mismatch
Quest started on the day a festival ends
Quest available only at night accepted at 23:59 in-game
Fetch quest item dropped in an unreachable location
Quest rewards an item when inventory is full
Quest chain step requires talking to an NPC whose schedule never overlaps the player
Quest tracker counts quests from cut content
Quest completed during a combat transition
""",
"openworld": """
Player crosses a chunk boundary during a combat transition
Two chunks load in the same frame causing a streaming hitch above 2 ms
Player fast travels to a waystation in an unloaded region seam
NPC walks from a loaded chunk into an unloaded one
Player reaches a map edge with no collision
Traversal ability used to skip a story gate
POI discovered while in a cutscene
Fog of war reveal after loading an old save
World event scheduled in a chunk that is unloaded
Player stands exactly on a seam between two region tilesets
Weather or time change while inside an arena
Player returns to a cleared area and enemies respawn unexpectedly
Waystation used while being chased by an enemy
Map marker on a POI that has been removed by story change
Player falls into a gap where no chunk exists
Tile collision mismatch at chunk edges
Enemies visible in the world spawn on top of the player after a load
Player teleports via fast travel during a deadline quest
Discovering a secret area out of the intended order
Map zoomed out shows unexplored regions' names
Loading a save where the player stands in an obstacle placed by a later patch
Player walks into a region designed for much higher level enemies
Seam between R1 and R2 shows mismatched lighting
World map icons overlap at high density
Region streaming while a dialogue is open
Fast travel with a companion whose schedule says elsewhere
Waystation discovered but unreachable later due to story change
Day/night transition in a chunk loading at the same frame
Player AFK in the open world for hours (clock and NPC sim)
Exploration reward collected twice after chunk reload
""",
"npc": """
NPC schedule puts them in a location blocked by the player
NPC needed for a quest is asleep at night
NPC witnesses a crime while off-screen in LOD
NPC memory of an event survives a load from a save before the event
Two NPCs path into the same doorway and block each other
NPC barks the same line repeatedly within a minute
Merchant NPC closed during a market day
NPC reacting to the player during a cutscene
Tier B NPC dies and a quest still references them
NPC teleports when switching simulation LOD
NPC pushed into a wall by the player
NPC schedule step skipped when the clock jumps on rest
NPC follows the player into a combat transition
NPC with festival behaviour on a day the festival is cancelled by a timing flag
NPC remembers a fact about a companion who is not present
Crowd density above budget in a town during a festival
NPC idle animation mid-dialogue
NPC reputation reaction differs between barks and dialogue
NPC sells an item the player already owns as a unique
NPC walks off-screen while the player talks to them
NPC enters a building that is not loaded
Auctioneer NPC absent on an auction day
Gambling host NPC available when the table is closed
NPC schedule edge at midnight (day rollover)
NPC fate changed by a timing flag but still shown alive in Story+
Many NPCs reacting to one event simultaneously cause a frame spike
NPC path blocked by a dropped item or prop
NPC names displayed for unnamed Tier C NPCs inconsistently
NPC says a line about weather when it is not raining
NPC hostile after a crime but the player is in a protected area
""",
"economy": """
Sell price exceeds 40% of buy price via a reputation stack
Crafted item value exceeds 90% of inputs without skill upgrade
Buy-sell loop between two merchants with different seasonal prices
Auction sniping in the final in-game minute
Player lists the max lots and cancels repeatedly to dodge fees
Limited edition stock bought out by NPC agents before the player arrives
Gambling daily limit reset by changing system time (should use WorldClock)
Gold value at the integer maximum
Market price driven to zero by repeated selling
Market price spiking without bound due to demand
Inflation over a 1000-day headless sim beyond bounds
NPC trader with negative budget
Player bids on their own lot
Auction ends while the player is in combat
Auction lot with no bids
Price noise rounding to a negative value
Season change mid-transaction
Player sells a quest item for profit
Salvage producing more value than the item cost
Shop restock frequency exploited by resting
Haggling stat at maximum with reputation at maximum
Commodity with zero base price in data
Player buys an item with exactly their total gold
Transaction interrupted by a crash (gold deducted, item not given)
Gambling with the minimum bet at the house edge over 10,000 rounds
Arena betting on a fight whose outcome is already known by the player via reload
Limited edition missed; signposting existed but player was in another region
Currency sinks too strong on Beginner economies
Market telemetry event fired twice per transaction
Price display rounding differs from actual charge
""",
"items": """
Inventory full when picking up a quest item
Stack limit reached mid-pickup of a stack
Equipping an item that requires a stat above the current value after a debuff
Unique item duplicated via drop-and-reload
Limited-edition numbered artifact numbering after NG+
Item with an affix rolled out of its tier range
Set bonus active with one item unequipped mid-fight
Item tooltip comparison when no item equipped in that slot
Item removed from data in a patch but present in a save
Consumable used during pause
Crafting with an item that is equipped
Salvaging the last weapon the player has
Item with zero durability or value
Item description missing translation
Item icon missing (fallback icon)
Weapon class change mid-combo (sprite swap)
Palette-swap armour on a sprite with off-palette pixels
Loot table with all weights zero
Drop spawns inside a wall
Item picked up during a transition is lost
Item granted by a quest while the player already has the unique
Sorting inventory with mixed rarities and equal names
Selling equipped items
Item with an affix that affects parry window (forbidden)
Rare loot on Hell difficulty dropping on lower difficulties after a change
Hell cosmetic or title earned, then difficulty lowered
Gift item to a companion who leaves the party
Two items with the same ID in the ItemDB
Item stats displayed differently in shop and inventory
Stack splitting into a slot that is occupied
""",
"ui": """
Text size at maximum causes overlapping labels in the status window
HUD visible during a cutscene
Two menus open at once (pause over shop)
Menu opened during a transition fade
Focus lost after closing a popup on controller
Resolution change while a menu is open
Ultra-wide aspect ratio stretches the HUD
Number formatting for very large gold values
Tooltip off-screen at the screen edge
Quest log with 100+ entries performance and scroll
Controller and mouse used at the same time on a menu
Button glyph shows keyboard key while using a pad
World map opened during combat
Mouse cursor visible during gameplay on pad
Notifications stacking (level up + quest + item at once)
UI scale with Simplified Chinese font metrics
Pause screen opened during dialogue
Settings changed and cancelled; values revert correctly
Health bar at 0 but player alive (rounding)
Long item names truncated without ellipsis
Shop UI when the merchant has zero stock
Auction UI timer when the in-game clock is paused
Level-up UI with no points to spend
Dialogue box with a portrait missing
Menu navigation wraps unexpectedly
Screen shake moving UI elements
Glitch overlay drawn over UI text
Credits screen skipped then re-opened
Map fog with no regions discovered (new save)
Achievement popup during a boss Hell phase
""",
"ux": """
New player never discovers the parry because the tutorial was skipped
Player does not know the game autosaved
Player loses progress believing Continue loads the latest save
Player misses that a quest has a deadline
Player cannot tell why an interaction prompt does not appear
Player does not understand the shatter transition means combat
Player confuses discovered and visited waystations
Player sells an item they need later with no warning
Player stuck with no idea of the next objective after a long break
Player cannot find the setting to reduce glitch effects
Player lowers difficulty accidentally and cannot raise it back
Player thinks the game froze during a long load with no indicator
Player cannot tell which companion is speaking
Player gets the same tip repeatedly
Player cannot see where to sell commodities
Player interprets a house-edge disclosure as a bug
Player does not notice an NPC reacting to their past action
Player tries to remap a key already in use
Player exits the game during a save write
Player clicks through a confirmation dialog by habit
Player expects pad vibration toggles separately for menus
Player unable to tell whether a door is locked or decorative
Player struggles to read the clock or calendar
Player cannot find where a limited edition will be sold
Player fails a minigame repeatedly with no hint
Player in Hell cannot tell latency from their own timing
Player cannot compare items quickly
Player does not see a warning before a missable closes
Player cannot tell how close they are to a storyline outcome (intended mystery vs confusion)
Player returns after a month and does not remember controls
""",
"audio": """
Two identical SFX play on the same frame and phase (comb filtering)
Voice count exceeds the limit in a big fight
Music bus muted but a stinger still plays at full volume
Audio continues during pause when it should stop
Audio stops during pause when it should continue (UI, pause music)
Dialogue ducking does not release after a skipped line
Positional bark heard from an unloaded chunk
Audio device unplugged mid-game
Very high volume on first launch before the settings are read
SFX play during a muted cutscene
Hitstop stretching an SFX that should not stretch
Root Access slow-time pitch-shifts all audio including UI
Footstep surface wrong at a tileset seam
Ambience loop audible click at the loop point
Missing SFX file falls back silently
Audio settings not saved after a crash
Mono output setting with positional audio
Many rapid UI moves cause a buzzing SFX
Death sound plays twice
Audio of a freed node cut off abruptly
Combat warning sound masked by music in loud tracks
Low-HP loop never stops after healing
Audio in background window (alt-tab) behaviour
Sample rate mismatch causes pitch shift on some devices
Arena music and world music overlap after return
SFX for an enemy that is off-screen but attacking
Volume slider at 0 still plays faint sound
Audio latency on wireless headsets for rhythm minigame
Gambling win sound too exciting relative to restraint guidelines
Festival music not stopping after the festival day ends
""",
"music": """
Transition to combat music mid-phrase sounds abrupt
Combat ends during a music transition
Region seam crossing toggles music back and forth
Music track loop point drifts over long play
Boss Hell phase music change while the player dies
Two music requests in the same frame
Music for a timing-flag variant scene missing
Night variant music starts before visual night
Music volume zero but adaptive layers still computed every frame
Music resumes from the start after every pause
Silence-intended scene overridden by region music
Festival rhythm game music desync with input timing
Track tempo change breaks layer sync
Music during a cutscene skip restarts region theme twice
Story+ music reflecting the wrong ending
Menu music continues into gameplay
Music change during dialogue ducking
Long session: same track repeats for 30+ minutes
Music for a region not yet composed (placeholder fallback)
Music crossfade on a low-end machine stutters during loading
Stinger overlaps with a level-up jingle
Music on game over loops too long
Music licensing metadata missing for a track
Arena music generated per biome mismatches the region
Leitmotif used for a character before introduction
Music stems missing one layer in export
Music in Chinese build references English-language lyrics (if any)
Battle music starting for a fight that ends instantly
Rest/wait advancing time changes the track abruptly
Music in the courier minigame vs deadline tension music both active
""",
"vfx": """
Particles continue after the emitter node is freed
Screen shake during a menu
Hit spark spawned on an enemy that died this frame
Glitch overlay intensity stacking from multiple sources
VFX with reduced-flash setting still flashing
Particles at 144 Hz emit more than at 60 Hz
Slow-time affecting particles inconsistently
VFX drawn over UI layers
VFX pooling returning an emitter mid-emission
Shader compile stutter on first use of an effect
Very many VFX in a big fight causing frame drops
Shatter transition VFX on a low-end GPU
VFX colour invisible against a specific biome background
Afterimage trails on fast dash leaving ghost sprites after stop
Camera zoom changes making VFX pixel-misaligned
VFX for parry not distinct from normal hit
Light2D effects on a scene with CanvasModulate night
VFX missing for an enemy type (fallback)
Death dissolve VFX on a boss with multiple sprites
VFX during cutscenes using gameplay layers
Weather particles crossing chunk boundaries
VFX timing at hitstop (frozen or running)
Fullscreen VFX at ultra-wide resolution leaving edges
VFX alpha sorting with Y-sort in top-down
Glitch VFX colour accessible for colour-blind players
VFX emitted while the game is paused
Effect libraries loading all textures at boot
Screen shake disabled setting still shakes camera in cutscenes
VFX in Simplified Chinese UI overlays text
VFX scale mismatch between top-down and side-scroll views
""",
"assets": """
Production art missing; fallback must load
Fallback asset differs in size, breaking collision alignment
Texture imported with filtering on (blurry pixel art)
Texture with mipmaps on for pixel art
Asset path case mismatch works on Windows but fails on export
Asset in art_sources accidentally referenced by a scene
Large PNG not in LFS committed
Sprite sheet frame size changed but SpriteFrames not updated
Asset renamed and .import still points to old name
Two assets with the same name in different folders confused
Generated asset without provenance entry
Asset licence incompatible with commercial release
Atlas exceeds max texture size on a target platform
Audio asset imported with loop off
Font missing CJK glyphs
Asset updated outside Godot without reimport
Asset with transparent fringe halo on dark backgrounds
Palette of a new asset outside the art bible palette
Asset referenced only via a string built at runtime
Asset deleted from production_art while a rollback needs it
PAE export metadata out of sync with PNG
Asset accepted baseline overwritten by a candidate
Animation sheet with uneven frame spacing
Asset size budget exceeded for a region
Import preset differs between similar assets
Asset with embedded text needing localisation
Asset loaded synchronously causing a hitch
Asset compression artefacts on gradients
Missing asset for a cut region still referenced
Asset with wrong pivot causing offset in game
""",
"art": """
Sprite readable at 2x but not at 1x
Character silhouette blends into the background tile colour
Light direction inconsistent between NPC and environment
Palette swap creates low-contrast armour
Region tiles repeat visibly in large areas
Night palette makes enemies invisible
UI art style mismatches world art
Glitch art reads as an actual rendering bug to players
Portrait style inconsistent between characters
Enemy sprite too similar to an NPC sprite
Boss sprite too large for the arena camera
Shadows inconsistent between top-down and side-scroll views
Pixel density mismatch (mixels) between assets
Colour-blind players cannot distinguish enemy variants
Background parallax layers too contrasted vs gameplay layer
Art for a season variant missing
Interactable not visually distinct from decor
Art bible rule violated by a deterministic placeholder accidentally shipped
Text-in-image art not localisable
Overexposed colours on HDR displays
Animation frames with stray pixels visible at speed
Character colour coding conflicts with UI colour meaning
Fog of war art obscures discovered areas
Weather art reduces contrast below readability
Same rock asset used everywhere in a region
Art for a timing-flag variant scene missing
Weapon sprites not readable during fast attacks
Hell cosmetics not visible enough to feel rewarding
Story+ world state art variant inconsistent with the ending
Art claimed as ComfyUI without evidence (truth gate)
""",
"tools": """
Export script run from a path with spaces
Export script run without Godot templates installed
-Tour run on a machine without a display
Dialogue extractor on a malformed .dlg file
Tool writes output into res:// and triggers reimport
Tool run on a dirty git tree mixes outputs with code changes
Asset audit tool counts .import files as assets
Editor plugin crashes the editor on load
@tool script runs in the editor and modifies scene data
Headless sim tool takes longer than CI timeout
Test runner picks up an old Godot version on PATH
Tool depends on Python not installed on a new machine
PowerShell execution policy blocks the script
Tool output not deterministic between runs
Tool fails silently with exit code 0
Screenshot tour takes screenshots before the scene renders
Export preset renamed and the script cannot find it
Tool deletes files without confirmation
Bot tool uses debug shortcuts unavailable to players
Tool assumes Windows-only paths
Long-running tool not interruptible
Tool log too large to read
Tool versions differ between team members after Gate 3
Asset pipeline tool overwrites accepted baselines
Economy sim tool uses a different formula than the game
Localization extraction misses strings in .tscn files
Tool requires a network resource and fails offline
Tool writes to user:// of the real player profile
Batch tool processes 10k files and runs out of memory
Tool output format changed and downstream scripts break
""",
"performance": """
Streaming hitch over 2 ms when two chunks load together
Frame spike when 50+ NPCs update schedules on the hour
Particles count explosion in a large fight
Shader compilation stutter on first use
Memory growth over a 4-hour session
Garbage spikes from per-frame Array allocations
Save of a large world state taking over 1 s
Load time for a region over the budget on HDD
High CPU in menus due to background world processing
Physics bodies left active off-screen
Many Area2D overlaps in a crowded town
Big auction lot list rebuild every frame
Pathfinding many NPCs at once
Text rendering of large Chinese fonts
Audio voices exceeding budget
Off-screen enemy AI ticking at full rate
Performance at 144 Hz with fixed 60 Hz combat tick
Integrated GPU with GlitchOverlay at full screen
Window resize causes texture reallocation hitch
Debug prints flooding stdout in release
Hitstop and time_scale changes stalling timers
Map UI with thousands of fog tiles
Economy sim per in-game day cost growth over 10 years of data
Long-running save file size growth
Many signals connected to a global bus firing every frame
Animation trees on many NPCs
Lighting with many Light2D nodes at night
Exported build slower than editor due to missing optimisation flags
Background loading thread contention
Console port target performance unknown (check platform specs)
""",
"accessibility": """
Remapping two actions to the same key
Remapping confirm so menus become unusable
Text size max breaks dialogue layout
Colour-blind filter applied but telegraph uses colour only
Reduced motion disables a gameplay-critical cue
Subtitles missing for a cutscene line
Captions for SFX overlapping dialogue subtitles
Hold-to-interact without a toggle option
One-handed play impossible due to a required chord
Screen reader cannot read a custom-drawn control
Flashing glitch exceeding safe frequency
Audio cue only (off-screen attack) with no visual
Timing assist for deadlines conflicts with Hell mode rules
Controller-only navigation stuck in a mouse-only widget
Font legibility at small sizes for dyslexic players
High contrast mode missing in minigames
Rhythm minigame requires precise audio timing (latency)
Quick-time inputs with no option to extend
Settings menu not reachable before the first cutscene
Accessibility settings reset after an update
Camera shake setting ignored in cutscenes
Low-vision players cannot read map icons
Motion sickness from parallax and shake combined
Text speed too fast with no adjustment
Hell mode precision requirements and latency calibration missing
Simplified Chinese text at small size unreadable
Mono audio missing for one-ear hearing
Gambling disclosures not readable at max text size
Tutorial prompts disappear before being read
Language of UI and screen reader output mismatch
""",
"localization": """
String too long in Chinese breaks a button
Missing translation key shows the raw key
Concatenated strings with wrong word order in Chinese
Plural forms for counts of items
Dates in the 28-day calendar formatted per locale
Numbers with thousand separators for gold
Font fallback for CJK missing a glyph
Line breaking rules for Chinese in autowrap labels
Text in images untranslated
Dialogue speaker names translated inconsistently
Glossary terms (Source Key, Root Access) translated differently
Placeholder variables reordered in translation
Rich text tags broken by translators
String freeze violated after translation
Locale switch at runtime not updating open UI
Fonts licence for CJK not cleared for commercial use
Text expansion in German-style languages (if added later)
Sorting inventory alphabetically in Chinese
Input glyph names localised
Puns and idioms untranslatable
Cultural review of gambling content in the Chinese market (check current rules)
Voice and tone lost in translation for humour lines
Translator context missing for short UI strings
Pseudo-locale reveals hardcoded strings
Save files storing localised strings instead of IDs
Achievements names on store platforms localisation
Store page localisation mismatch with in-game text
Chinese punctuation width in fixed-size boxes
Typewriter effect speed for CJK vs Latin
LQA build missing debug overlay for string IDs
""",
"save": """
Crash during save write leaves a partial file
Save from an older version loaded after a schema change
Save during a transition or cutscene
Save made in combat or during hitstop
Disk full during save
Save folder in OneDrive sync conflict
Two saves with the same slot written in quick succession
Save including WorldClock, market and auction state round trip
Load a save where a referenced item was removed
Load a save from a different difficulty profile
Save file manually edited with invalid JSON
Autosave triggered while a menu is open
Save with a quest in an intermediate state
Save made in a chunk that no longer exists after a patch
Save file size growth over 100+ hours
Load a save made in NG+ in a non-NG+ build
Save during a dialogue choice
Loading a save while another load is in progress
Save slot deleted while it is loaded
Cloud sync on a store platform overwriting a newer local save (check platform behaviour)
Save created by a debug build loaded in release
Timestamps on saves in a different time zone
Save migration chain v1 to v5 skipping intermediate versions
Corrupt backup and main save both
Save containing NPC memory facts for despawned NPCs
Save storing Engine.time_scale or paused state accidentally
Save with an auction lot active mid-bid
Save with a limited edition reservation
Load from main menu after returning from a game (stale autoload state)
Save from Early Access loaded in 1.0
""",
"time": """
Deadline expires while the player is in a menu (clock paused or not)
Rest advances time past a window quest's opening and closing
Clock at day rollover during a schedule step
28-day month rollover in a deadline countdown
Season change during a market transaction
WorldClock paused by ContextStack but a timer still advances
Order quest A and B completed in the same in-game minute
Duration quest started before a long rest
Time-of-day based dialogue at the boundary minute
Festival day starts while the player is in an arena
Timing flag set early in Act 1 and checked in Act 4
Pace value computed with a load from an earlier save
Deadline leniency multiplier applied twice
Lowering difficulty extends a deadline already counting
Clock drift between real time and in-game time over long sessions
Fast travel time cost vs walking time cost mismatch
Bot timing profile (fast, slow, out-of-order) hits an unhandled state
Limited edition release day missed by one minute
Main-story deadline with signposted warning skipped by rest
Clock tick rate tuned while saves exist
Auction ending at the exact second a save is made
NPC schedules after a 100-day jump
Night-only enemy present when time is changed by a cutscene
Clock not advancing during long dialogue (intended?)
Timing modifiers changing ending slides with missing variants
Story+ showing timing changes for flags never set
In-game calendar year rollover
Player AFK for 24 real hours
Time-sensitive quest started on Beginner and difficulty lowered from Medium mid-quest
Clock determinism under different frame rates
""",
"difficulty": """
Lowering difficulty during a boss fight
Attempting to raise difficulty (must be blocked)
Hell-only phase reached after lowering to Hard
Healing charges above the new max after lowering
DDA on Easy making a boss trivial
Parry window frames on Beginner overlapping enemy follow-ups
Telegraph multiplier causing overlapping attacks on Hell
Enemy damage x2.0 one-shotting the player at low level
Deadline leniency differences between difficulties in the same save
Loot table differences when difficulty changes mid-run
Hell cosmetics granted then difficulty lowered
NG+ difficulty selection rules
Difficulty shown inconsistently across UI screens
Accessibility assists conflicting with Hell
Input buffer frames identical across difficulties (should be)
Latency calibration affecting Hell fairness
Replay-verified fairness: one frame off must lose
Difficulty profile missing a key in data
Difficulty-specific achievements after a change
Beginner players stuck on pattern literacy
Medium players experiencing the first Hard spike
Boss variant patterns on Medium vs base
Difficulty selection on the first screen without explanation
Changing difficulty during a timed quest
Difficulty in Story+ after the ending
Speedrun timer category per difficulty
Difficulty affecting economy rewards unintendedly
Elite enemies scaling on Hell beyond readability
Companion damage scaling with difficulty
Difficulty survey responses showing deaths as unfair
""",
"fun": """
Optimal strategy is boring (players optimise the fun away)
Grinding is the best way to progress
Players skip a minigame because rewards are better elsewhere
Gambling becomes the best income source
A quest type repeats too often in a row
The open world feels empty between POIs
Players feel punished for exploring (deadline missed)
Boss is fun once but tedious on retry (long walk back)
Combat on Beginner feels trivial and boring
Players never use Root Access
Too many currencies or commodities to care about
Market so stable it is uninteresting
Auction always won by the player
Companion banter repeats
Players feel the time pressure prevents exploration
Story+ feels like a checklist
NG+ adds nothing new in the first hour
Players do not notice their choices mattered
Minigame difficulty curve too steep
Reward pacing stalls in mid-Act 2
Players stop playing at the same spot (drop-off)
Crafting feels like menu work
Hell mode only fun for a tiny audience
Too much reading before fun begins
Enemy variety too low in a region
Levelling feels meaningless
Secret quests too obscure to find without a guide
Players feel lost and quit
Combat transitions too frequent in a region
Limited editions cause FOMO rather than fun
""",
"release": """
Build version number not bumped
Export missing a resource excluded by filter
Release build includes debug features
Crash on first launch on a clean machine
Missing VC runtime or GPU driver issues on Windows
Build signed or not per store requirements (check current rules)
Store depot uploaded with the wrong build
Patch breaks saves from the previous version
Hotfix branch diverges from main
Release notes missing a change
Rollback plan untested
Achievements not registered on the store backend
Crash reporting not enabled or not consented
Build size exceeding store or platform limits (check current rules)
Localization missing in the release build
Antivirus false positive on the exe
Build launches in the wrong resolution or monitor
Steam Deck or handheld compatibility not tested (check current programmes)
Release candidate fails smoke-check at the last minute
Wrong rating information on the store page
Pre-release build leaked
Early Access to 1.0 save compatibility
Patch notes promising something not in the build
Console certification requirements not met (check current platform rules)
Region-specific gambling restrictions not applied in the build config
Update deployed on a weekend with no support capacity
Release day bug with no hotfix path
Demo build includes content beyond the demo scope
Demo save carrying into the full game
Build reproducibility (same commit, different output)
""",
"marketing": """
Trailer shows features not in the build
Screenshots from debug builds with overlays
Store page capsule text unreadable at small size
Announcement timing clashing with a major release (check calendar)
Devlog cadence unsustainable alongside 7-day work weeks
Community expectations set beyond the scope
Negative reception to gambling features
Press kit missing key facts
Social posts spoilering story reveals
Demo too long or too short to hook
Wishlists not tracked
Influencer copies with no embargo terms
Marketing claims about ComfyUI or AI art without evidence (truth gate)
Store tags misrepresent the game
Trailer music licensing not cleared
Localization of store page incomplete for Chinese
Festival or event submission deadlines missed (check current dates)
Marketing builds diverging from main
Community questions about release date with no answer
Discord moderation load for a solo dev
Fake key requests
Embargo broken
Store page AI disclosure inconsistent with the game
Marketing screenshot of a region before art acceptance
Over-promising Story+ or NG+ content
Review copies distributed without tracking
Patch notes tone inconsistent with brand
Early Access page lacking clear 'what is coming' list
Leaked build screenshots
Marketing time eating into production with no budget
""",
"legal": """
Third-party asset licence not commercial
Font licence restricts embedding
Music contract missing stems or ownership terms
Title trademark conflict (check current registers)
AI disclosure requirements on stores (check current rules)
Simulated gambling triggering higher age ratings (check current rules)
Regional gambling restrictions (check current rules per region)
Privacy law for telemetry (consent, data retention)
EULA missing or outdated
Contractor IP assignment missing
Open-source licence obligations for Godot and plugins (MIT notice)
gdUnit4 or other plugin licence attribution
Credits missing contributors
Using a name similar to an existing game or character
Fan content and modding policy unclear
Refund policy expectations per store
Age rating questionnaire answers inconsistent with content
Loot box rules (none paid, but verify wording)
Export of user data on request (privacy)
Crash report data containing personal information
Contract with collaborator without a termination clause
Royalty or revenue share terms with team members
Tax obligations from store revenue (check with an accountant)
Trademark use in marketing (platform logos)
Licence of AI tools used in pipeline
Copyright of generated assets (check current law)
Accessibility legal requirements in some markets (check current rules)
Store terms changes after release
Publisher or funding contract obligations
Code from tutorials or forums with unclear licences
""",
"team": """
New team member cannot run the build on day one
Onboarding doc out of date
Two people edit the same scene and merge conflicts
Contractor unavailable in a critical week
Communication time zones mismatch
Review bottleneck on the solo lead
Key-person risk: only one person knows a system
Team member burnout
Disagreement on art direction escalates
Unclear ownership of a system
Asset delivered in the wrong format
Writer produces text not matching VOICE_GUIDE
Composer stems not matching the adaptive system
QA reports without reproduction steps
Team member leaves mid-milestone
Access to repo and tools revoked or not granted
Licences for tools per seat
Payment delays affecting trust
Credits disagreements
Feedback culture too harsh or too soft
Meetings eating production time
Task estimates from new members unreliable
Team not following Conventional Commits
Different editor versions across machines
Shared storage of large binaries
Team members' contributions not backed up
Unclear decision rights at gates
Contractor needs story spoilers under NDA
Team using different save files for testing
Lead unavailable due to illness
""",
"docs": """
Doc describes a system as it was before a refactor
ADR missing for a major change
GDD missing acceptance criteria
README commands fail
CHANGELOG missing entries
Doc paths point to src/ instead of AethelgardPrototype/
Duplicate docs in design_archive and docs with conflicting content
Onboarding doc assumes knowledge not written down
Doc for a cut feature still presented as current
Story bible contradicts VOICE_GUIDE
Docs written in a format agents misread
Docs containing secrets or personal data
Doc too long to be read in practice
Missing diagrams for complex flows
Docs not linked from an index
Doc dates missing
Test evidence docs referencing deleted screenshots
API doc comments diverging from behaviour
Roadmap status not updated after a gate
Decision log missing the reasoning
Glossary terms inconsistent across docs
Docs claim production readiness without evidence
Docs for tools missing usage examples
Engine reference docs outdated after a Godot upgrade
Art pipeline docs not matching the truth gate rules
Docs for save schema missing a version
Session-state file stale after a crash
Doc translation needs for the team
Docs split across too many folders to find
Docs referencing a branch that was deleted
""",
"ai": """
Enemy AI stuck on terrain in a generated arena
Enemy AI attacking during its own hit stun
Two enemies choosing the same attack slot (token system)
AI perception through walls
AI chasing the player across a combat boundary
Boss AI phase selection when HP crosses two thresholds in one hit
AI pattern repeats predictably beyond intended learnability
AI cheese: player finds a spot the AI cannot reach
AI reacting to a player who is invisible in a cutscene
NPC schedule AI deadlock in a doorway
AI target selection when companions are present
AI on Hell using variants that overlap unfairly
AI timers using real time instead of game time
AI disabled by pause but resumes with stale state
AI pathfinding on a chunk that unloads
AI for NPC traders making irrational trades that crash prices
Auction bidder AI exceeding its budget
Gambling host AI behaviour fairness (no cheating beyond house edge)
AI difficulty adaptation (DDA) oscillating
Flying enemy AI leaving the arena bounds
Ranged AI shooting from off-screen
AI not reacting to Root Access slow-time
AI ignoring hazards
AI spawning behind the player with no telegraph
Companion AI blocking the player in narrow places
Companion AI standing in boss AOE
Quest bot AI (testing) stuck on a dialogue choice
AI behaviour differing between 60 Hz and 144 Hz
AI state not saved for persistent enemies
AI debug visuals visible in release
""",
"level": """
Player can leave the playable area through a corner
Checkpoint placed before a long unskippable section
Secret area reachable only by a physics glitch
Level geometry hides an enemy telegraph
Collision mismatch with visuals (snagging)
Door that looks open but is blocked
Arena platform unreachable without a specific ability
Long backtrack after a dead end
Landmark not visible from the expected angle
One-way drop that soft-locks the player
Interactable placed behind foreground decor
Lighting making a path invisible at night
Spawn point inside an NPC
Enemy placement creating an unavoidable hit on entry
Level built for one direction played in reverse
Hazard placement unfair on Hell
Path width too narrow for companions
Repeat geometry causing disorientation
Region seam with a walkable gap
Waystation placed where enemies patrol
Treasure visible but intended for later, unreachable now with no hint
Area with no music or ambience trigger
Level overlaps with a loaded chunk's collision
Elevation change unclear in top-down view
Player stuck after a scripted collapse
Quest objective placed in an area later locked
Environmental storytelling missed because off the main path
Level performance budget exceeded by decor
Platforming section on keyboard vs pad difficulty difference
Shortcut unlock not obvious from the far side
""",
"business": """
Funding runway shorter than the next gate
Revenue from Early Access lower than planned
Price point misjudged relative to comparable games (check current market)
Store fees and taxes not modelled
Currency conversion for Chinese market pricing (check current rules)
Refund rate spike after a bad patch
Team costs exceeding plan after Gate 3
Contract renegotiation mid-production
Insurance or business registration requirements (check current rules)
Publisher offer with restrictive terms
Console port cost underestimated
Expansion pricing and value perception
Sales events timing (check current store calendars)
Bundle and discount strategy affecting perceived value
Dependence on one storefront
Wishlist conversion lower than assumed (no invented numbers; measure)
Marketing spend without measurement
Burnout reducing productivity and extending runway needs
Exchange rate changes affecting contractor costs
Legal costs for ratings and trademarks
Scope cuts needed after Gate 3 funding gap
Selling merchandise or soundtrack licensing questions
Revenue share obligations with team
Sequel decision without data
Live support costs after 1.0
Platform holder requirements adding cost (check current rules)
Delayed payment from storefronts (check current terms)
Grant or fund application deadlines (check current dates)
Accounting records incomplete at tax time
Smaller-game fallback triggered at Gate 3
""",
}


def build():
    out = {}
    for tag, block in RAW.items():
        items = [l.strip() for l in block.strip().splitlines() if l.strip()]
        out[tag] = items
    return out
