# Dialogue format (`.dlg`)

All game dialogue is written in plain-text `.dlg` files under `dialogue/`. Edit them in any text
editor; VS Code is fine. The game reads them through `DialogueManager.run(file, node)`.

## The whole syntax

```
# A comment (whole line). Ignored by the game.

~ node_name
Speaker: What they say. [#ch1_elara_001]
Kaelen (Internal): Thoughts work the same way.
[if has_elara] Elara: Only shown if Elara is with you.
[if ch1_knight_spared and not ch2_seraphina_met] Kaelen: Conditions can combine with and / not.

? Kaelen: The question shown above the choices.
- I'll trust you. => trust [#ch1_elara_c1]
- I'm watching you. => cautious
- [if has_elara] Option only shown when the condition holds. => other
- Leave. => END

~ trust
set ch1_elara_trusted
Elara: Really?
do elara_smiles
=> after

~ cautious
set ch1_elara_cautious
set ch1_elara_trusted = false
=> after

~ after
Elara: Then let's go.
```

| Line starts with | Meaning |
|---|---|
| `~ name` | Starts a **node** (a beat you can jump to). Names: letters, digits, `_`, no spaces. |
| `Speaker: text` | A **line**. The speaker is everything before the first `: `. |
| `? Speaker: text` | The **prompt** shown with the choices that follow it. |
| `- text => node` | A **choice**. `=> END` ends the dialogue. |
| `set flag` / `set flag = false` | Writes a **story flag** (`flag = true` if no value). |
| `=> node` / `=> END` | **Jumps** to another node, or ends. Reaching the end of a node also ends. |
| `do event` | Hands control to the scene: a camera move, effect, animation. The scene decides what each event does. |
| `[if …]` | A **condition** in front of any line, choice, `set`, `=>` or `do`. Takes flags, `not flag`, `a and b`, and `has_elara`. |
| `[#id]` at the end | A **line ID**. Needed later for translations and voice-over; optional while drafting. |
| `\n` inside text | A line break inside one dialogue box. |
| `# …` | A comment. |

## Rules of thumb

- **One file per scene**, named like the scene: `dialogue/ch1/elara_meeting.dlg`.
- **Choices end in a jump.** Every option says where it goes.
- **Flags belong to the story.** Use the existing names (see `STORY_BIBLE.md` §5) or add new ones
  there first.
- **Don't put stage directions in spoken text** (`*smiles*`). Use `do smile` and let the scene show
  it, or describe it in a comment.
- The game **checks every file** in CI: unknown jump targets, choices without options, malformed
  lines and bad flag names all fail the build, with the file and line number.
- **Never write a key name.** Players rebind keys and use gamepads. Write the action in braces
  and the game shows the player's real button: `System: Press {interact} to open the gate.`
  shows "F" on keyboard, "A" on Xbox and "Cross" on PlayStation. Actions: `{interact}`,
  `{attack}`, `{jump}`, `{defend}`, `{sprint}`, `{spell}`, `{heal}`, `{root_access}`,
  `{data_vision}`, `{world_map}`, `{lore_journal}`, `{status_window}`, `{skip}`, `{move}`,
  `{move_lr}`, `{ui_accept}` and `{ui_cancel}`. Any other `{word}` is left as written.

## Where the old dialogue is

`dialogue/_extracted/` holds every line currently written inside the game's scripts (about 2,000),
one file per script, one node per function. It's **source material for your rewrite**: the game
doesn't load it, and its choices all point at `END`. When you rewrite a scene, write the new version
in `dialogue/<chapter>/` and the scene gets wired to it.
