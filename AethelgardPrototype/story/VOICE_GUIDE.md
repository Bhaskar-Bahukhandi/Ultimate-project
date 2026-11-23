# Aethelgard — Voice Guide

How everyone *sounds*. The goal is dialogue that reads like people talking, not a system
explaining itself. Every line in `dialogue/*.dlg` should pass the checklist at the bottom, and the
dialogue tests check some of these rules automatically (see §5).

## 1. Rules for everyone

1. **People don't say exactly what they feel.** They deflect, joke and change the subject. Write
   the subtext and let the player connect it.
2. **Write the way people speak.** Use contractions ("I don't know", "it's", "you're"). Full
   formal sentences only when the character *is* formal, and that's a trait (Aldric, the System).
3. **Questions get question marks.** "Where was I." reads as a flat statement. If deadpan is the
   point, write it as a statement on purpose ("I'd like to know where I was.").
4. **Vary the length.** A scene where every line is 2–4 words is a comedy routine, not a
   conversation. Mix one long line in among the short ones, and give the long ones to the people
   who ramble (Bran, Mara).
5. **No narrating mechanics.** Show it on screen or in the UI.
   - Wrong: Kaelen: "Tick rate. In engine terms, that's the server's update frequency."
   - Right: the clocks stutter, and Kaelen says "...That's not a clock problem."
6. **Earn every System line.** The System voice is the world speaking, not a narrator. Keep it to
   one line in five or fewer.
7. **Distinct voices.** If you cover the speaker names, you should still know who's talking. Each
   character below has one habit nobody else uses.
8. **Read it aloud.** If it's awkward to say, it's awkward to read.

### Banned tics

The source draft leaned on these until every character sounded the same. Each has a better fix.

| Tic | Example | Instead |
|---|---|---|
| Grading Kaelen's answers | "Better answer." "Good answer." | React to *what* he said. |
| Synthesising the theme | "Both are true." | Let two characters disagree and leave it. |
| Commenting on sentences | "Keep that sentence." "That sentence worries me." | Say what worries them. |
| One-word verdicts as replies | "Fair." "Accurate." "Correct." "Exactly." | A real reply, or silence. |
| "Define ___" | "Define bad." | Use it once per region, maximum (it's Kaelen's at most). |
| "Apparently" as a whole line | "Apparently." | Kaelen may use it once per chapter. |
| Everyone does the setup → literal reply → dry closer triad | — | Break the rhythm: interrupt, misunderstand, change the subject. |
| Characters stating the chapter's theme | "Observation is not permission." | Show it. Someone acts, someone else reacts. |

## 2. Why it reads flat → what we do instead

Adopted 2026-11-22 for the Act 1 character voice pass (playtest feedback: the dialogue read as
robotic, and the NPCs weren't memorable). Canon sources: `STORY_BIBLE.md` (SB) and
`source/PRODUCTION_MASTER_2.1.md` (PM, cited by line). Tone target (SB §1, PM 439–441): *adventurous /
melancholic / funny the way frightened people are funny.* Funny comes from **who** is talking, not
from everyone being witty.

**Where the flatness comes from:**
- **Mostly Kaelen.** Most of the "Very ___ / Of course it is / Great" closers are his. His humour is canon
  (PM 278: "His humor is partly avoidance"), so keep it, but make it fail, cost him something, or get cut off by
  the thing he's avoiding.
- **A shared doubling tic.** "I don't know. I honestly don't know." and "Really" as a sincerity tag
  belong to rattled Kaelen, not to the house style.
- **Lines that are too clean.** But if everyone starts trailing off, that becomes the next house tic.
  Each card says *which* kind of mess belongs to that character.

**What already works (the standard to rewrite towards):** Bran and Elara talking over Kaelen's head
(`oakhaven_gate.dlg:14–17`); the seat interrogation (`ironhold_arrival.dlg:52–65`); Rem's late line
(`ironhold_city.dlg:125`); Old Fen's "Guessing." (`oakhaven_village.dlg:21`); Iven's "Don't lose it. I
nearly did." (`underground.dlg:74`); the coffee stain (`ironhold_city.dlg:179–183`).

### Rulings (2026-11-22)

| Topic | Ruling |
|---|---|
| Bran | Keeps the long-winded voice and adds PM's "observant": he reads people by evidence. No surname in Act 1 until it's settled whether Bran, Old Fen and Aldric Fen are family. |
| Aldric (as himself) | **Uncontracted** (PM 1044). This separates him from Old Fen, who also speaks briefly. |
| Elara under stress | Formal full sentences mean anger. Short orders and stillness mean fear (PM 948). |
| Rook | The Act 1 Rook is **Rook Damar** (PM 819–826). PM B43 "Vanna Rook" is a different person. *Open:* rename her in Ch6. |
| Kaelen's apologies | Half-formed in Act 1. He apologises more honestly after Act 2 (PM 928). |
| Act 1 text bugs | Fix them in the Act 1 pass: Elara's early "Kaelen" (`broken_mile.dlg:87`, before `fragment_one.dlg` `fragment`), and the missing `?` at `elara_house.dlg:27`. |
| New tic checks (§4.1 rule 9) | *Open:* advisory lint or documentation only. |

### The techniques

Each "after" keeps the same speakers, the same facts and the same beat. They show the register;
the writer drafts the final lines.

**T1. One closer per scene, not one per exchange.** The setup → literal reply → deadpan closer triad
is the main robotic pattern. Replace the closer with a reaction to something concrete in the scene.
- Before (`elara_meeting.dlg:87–89`): Elara: "Walk ahead of me, where I can see you." / Kaelen: "Very
  trusting of you." / Elara: "Very practical. You'd do the same."
- After: Elara: "Walk ahead of me, where I can see you." / Kaelen: "Fair enough. I'd do the same, I
  think." / Elara: "You'd do it worse. You keep reaching for that sword like it's a pocket."
  (The reach is real: `do kaelen_reaches_for_sword`, line 84.)

**T2. Frightened jokes fail.** Keep Kaelen's humour, but at high stakes it breaks off, or he drags
himself back to the people he's looking for.
- Before (`crash_site.dlg:51`): "Sure. Great. The sky's broken too. Why wouldn't it be?"
- After: "Clouds don't do that. They don't— no. Not the clouds. People first."
- Before (`elara_meeting.dlg:80`, replying to "People don't come out of the crater."): "Great. Today's
  going great. Really."
- After: "Well, I did. I'd love to know what that makes me. Maybe not today."

**T3. Leak the feeling; don't name it.** A character shows a feeling through a habit, an object or a
change of subject. At most one named feeling per scene, and naming it should cost the speaker.
- Before (`fragment_two.dlg:34`): Seraphina: "I wish I didn't. Some nights especially."
- After: Seraphina: "I wish I didn't. I still count the room before I can sleep."
- Before (`fragment_two.dlg:54`): Kaelen: "I'm sorry. I'm so sorry."
- After: Kaelen: "I'm— I should have—" (Her "For what?" and his "...I don't know." still follow. The
  unfinished apology is canon-true for Act 1: PM 928.)

**T4. Answer sideways.** People dodge, answer the question before last, or talk to someone else.
- Before (`fragment_two.dlg:19–24`): "A memory? You had that look again." / "Yeah. Another one." /
  "Yours?" / "Yeah. Mine, from before." / "A bad one?" / "I don't know yet. I can't tell from the inside."
- After: Seraphina: "You had that look again. Like a passenger who's just heard the engines change." /
  Kaelen: "Another memory." / Seraphina: "Yours?" / Kaelen: "Mine. Someone asked me a question and I
  didn't answer it fast enough." / Seraphina: "A bad one?" / Kaelen: "I can't tell from the inside. Ask
  me when I'm out of it." (That matches the flash: past Kaelen hesitating, line 16.)

**T5. Replace filler with a specific.** Acknowledgements ("Yeah.", "That sounds right.") carry nothing.
Swap each one for something only this person would know about themselves.
- Before (`fragment_two.dlg:41`): Kaelen: "That sounds right. That sounds very like me."
- After: Kaelen: "Was I? ...Yes. Fixing something nobody had asked me to fix."

**T6. Not everyone is witty.** Give the wit to the people whose character it is (Elara, Mara,
Seraphina when exhausted, Rook). The severe people stay severe, so their one dry line lands.
- Before (`command_hall.dlg:13`): Brask: "So did Oakhaven. Most places survive their first visitor."
- After: Brask: "Oakhaven isn't my wall. Ironhold is. What do you want with it?" (This folds into
  line 14. A merge of two lines by the same speaker, which §3 allows.)

**T7. Give them a life outside Kaelen.** Every NPC appearance carries one detail from their own trade,
body, family or day, taken from canon. PM supplies plenty that isn't used yet: Mara's flour wagon and
two-temperature oven (PM 1914, 1924), her late partner's recipe notes (PM 1932), Bran's gate that
sticks in the rain (PM 2036), Aldric "earning boring" (PM 1977).
- Before (`oakhaven_village.dlg:90`): Mara: "Back again? Good. Buy something or carry something, love.
  Pick one."
- After: Mara: "Back again? Good. Oven's hot on the left and winter on the right today, so buy what's
  on the left. Or carry something, love. Pick one."

**T8. Ration the doubling.** "X. Intensified X." and "Really" belong to rattled Kaelen (and to Elara
once, laughing-crying at `aldric.dlg:121`). Everyone else says it once.
- Before (`fragment_two.dlg:76`): Kaelen: "I understand. Really, I do."
- After: Kaelen: "I understand. It's yours." (Her "Do you? You've never had a city." now lands harder.)

## 3. Voice cards

### 3.1 Full cards (ordered by Act 1 line count)

#### Kaelen (259 + 70 Internal)
- **Who:** programmer from Flight 707 and co-author of the Human Patch, though in Act 1 he only
  remembers arguing for seven signatures. Debugging keeps his grief at a distance (PM 277).
- **Speaks like:** an engineer on a 3 a.m. incident call who is also the person whose family is on
  the affected server.
- **Rhythm:** mixed. Long, branching sentences when he's working something out. Short and polite when
  he's frightened. His Internal lines are full sentences, observation rather than commentary.
- **Vocabulary:** plain modern English. Engineering words leak in under stress ("if-statement", "two
  rules running at once", "metadata"), and he never explains them unless asked. Airports, laptops,
  coffee: an Earth that's getting harder to describe.
- **Habits (his only):** (1) thinks out loud in hypotheses: "Okay. Either ___, or—", usually unfinished.
  (2) puts the world in order: "Step one…", "Walls first. Then the list of names." (`shatter.dlg:164`).
- **Never says:** "chosen one", "creator", "destiny", or anything that makes his mystery sound grand.
  No finished, eloquent apologies in Act 1.
- **Emotion leaks:** *fear:* he gets precise and polite ("please", exact counts of rules, not people).
  *grief:* he goes back to the task ("People first"), and his sentences stop halfway. *affection:* he
  notices a practical thing and fixes it without comment, or deliberately doesn't (Elara's arm).
  *anger:* rare; it comes out as a flat, very reasonable sentence.
- **To others, start → end of Act 1:** with Elara, defensive jokes to fill silences → he can leave a
  silence alone (`arm_silence`). With Seraphina, a stranger's "I know you" → crew and passenger who've
  both stopped pretending to be fine.
- **Samples (Act 1 situations):**
  - Seat marks, crash site: "That's a row. That's where a row was. Step one: find one person. One."
  - Elara asks if Flight 707 is a place: "It's a plane. You sit in rows, and it flies, and it isn't
    supposed to land like— it isn't supposed to land here."
  - After the first Root edit: "I changed one word inside it. Can I stop shaking before you ask which?"
  - Mara feeds him: "I'll pay you back. I don't know in what yet. I can fix things, mostly."
  - On the bridge before the Shatter: "It's a bridge. People cross bridges every day, and almost
    none of them— middle planks. Got it." (The scene's one "Okay." is "Okay. Walls first.", which a
    test pins.)

#### Elara Venn (197)
- **Who:** Oakhaven's Glitch-Witch. Her damaged casting channel reaches system layers at a cost; a
  cure would also change her (SB §4, PM 166–176).
- **Speaks like:** a village healer who has had to be the adult for too long (a comparison, not
  backstory): dry, quick and practical, and she's done being the adult for today.
- **Rhythm:** short and finished. She completes her thoughts; she doesn't trail off. She cuts other
  people off ("—which has been bad all week", `oakhaven_gate.dlg:45`), and nobody cuts her off.
- **Vocabulary:** plants, weather, roads, chores, local names, food. Technical words appear only in
  audible quotes when she's repeating Kaelen. The priests' long definitions "don't move carts".
- **Habits (hers only):** (1) "stranger" until trust, then "Kaelen", and she drops back to "stranger"
  as a rebuke (`fragment_one.dlg:59`). (2) gives orders disguised as observations about the road or
  the weather ("Road's eating itself again.").
- **Never says:** anything self-pitying about her arm, and won't let anyone else say it. Never "maybe"
  approvingly (`north_field.dlg:43`).
- **Emotion leaks:** *fear:* she goes still and gives short orders ("Inside. Now."). *grief:* she
  talks about the dead person's habits ("Aldric never said anything he didn't mean"). *affection:*
  teasing, and food. *anger:* formal, full sentences, no contractions.
- **To Kaelen, start → end of Act 1:** a bow at his chest and "stranger" → "Come on, Kaelen" and a
  pack she chose to carry. She never becomes his patient.
- **Samples:**
  - Bow-point, after the slime: "I watched you fight that. Keep the sword low. It's safer for both of us."
  - Arm, on the road: "It's attached. It'll stay attached. Look at the road, not at me."
  - Stew: "Eat. You've the face of someone who forgot meals existed somewhere around noon."
  - Silent-meeting branch (anger): "They are not children, stranger. They have mended that field
    every spring since before you fell." (Keep only if "every spring" is acceptable as an implied
    fact; otherwise cut after "stranger".)

#### Seraphina Vale (117)
- **Who:** Flight 707's flight attendant. She woke about 8 Aethelgard years earlier and is now
  Knight-Commander. She counts people. Wound: the passengers she couldn't save (SB §4).
- **Speaks like:** cabin crew during an emergency landing, eight years later and in armour. Same calm
  voice; her rank never makes her louder.
- **Rhythm:** clipped and imperative on duty; fuller and drier off duty. Funniest when exhausted (PM
  962). She doesn't trail off. When something hits her, she stops talking.
- **Vocabulary:** concrete action words (lanes, exits, counts, wagons, shifts). The crew script
  surfaces under stress ("keep the aisle clear", "for me, please"). Ironhold rank words she wears
  without enjoying them.
- **Habits (hers only):** (1) counts people aloud, always people before things ("Forty-two people. Six
  wagons."). (2) the crew politeness that turns into command: "Move, please."
- **Never says:** "I'm fine." Never leaves a person unaccounted for in a sentence; she corrects
  "resources" to "people" (`administrator_proxy.dlg:13`).
- **Emotion leaks:** *fear:* the count gets faster and quieter. *grief:* a number ("one hundred and
  eighty-six"), then silence. *affection:* she remembers useless details about you (the coffee
  stain). *anger:* her politeness sets hard ("Say it properly.").
- **To Kaelen, start → end of Act 1:** a test ("Window or aisle?") → "Tell me when you do": he's now a
  passenger she's decided to keep track of.
- **Samples:**
  - Convoy: "Forty-two. Wagon three, sit down for me, please. I can see you. Forty-two."
  - Off duty: "I've been awake since the second bell. If I fall asleep standing up, salute me."
  - At the gate, recognising him: "Window. Right-hand side. I was working the right-hand side."
  - Missing shift, to Brask: "Then you'll write it down, and I'll read it." (kept)

#### Bran (27)
- **Who:** Oakhaven gate guard and keeper of the road ledger (SB §4).
- **Speaks like:** a parish clerk who has been complaining about the same paperwork for twenty years
  and would die for it.
- **Rhythm:** long. His grievances come with sub-clauses, and he's the one main-cast voice allowed to
  run past a full dialogue box (split across two lines).
- **Vocabulary:** ink, entries, crossings-out, gates, weather closures, goats, caravans; "lad".
- **Habits (his only):** (1) makes things official by writing them down ("That's going in the
  ledger."). (2) reads people by evidence first: boots, dust, mud (PM "observant").
- **Never says:** "impossible". He stopped using the word (`oakhaven_gate.dlg:37`).
- **Emotion leaks:** *fear:* more precise record-keeping (times, names). *grief:* an exact sensory
  memory ("Sounded like the whole hill sighing."). *affection:* calls you "lad" and grumbles at you.
  *anger:* refuses to write something down.
- **To Kaelen, start → end of Act 1:** "Does it talk?" → "fixed by the crater" in his own ink.
- **Samples:**
  - At the gate: "Three hours, Elara. You said one. I had one written down, in ink, and now I'll have
    to cross it out, and you know what crossings-out do to a ledger."
  - Reading Kaelen: "That grey on your boots is crater dust. Spit won't shift it. You didn't come round
    the crater, lad. You came out of it."
  - The bridge: "Until dark. I've written 'until dark' and underlined it, which I don't do for just
    anything."
  - Ambient (PM 2036): "Gate sticks when it rains. Lovely, ordinary problem. I'd frame it if I could."

#### Mara Quill (17)
- **Who:** Oakhaven's baker and quartermaster; the anchor of ordinary life (SB §4).
- **Speaks like:** a quartermaster in an apron who has already decided what you're having.
- **Rhythm:** fast and mixed. Questions in threes, and she doesn't wait for the answers.
- **Vocabulary:** flour, ovens, prices, debts, wells, kettles; "love".
- **Habits (hers only):** (1) three questions in a row (`fragment_one.dlg:30`). (2) decides for you:
  "Don't argue, I've already decided." Everything gets settled in food or money.
- **Never says:** anything about destiny. Destiny doesn't feed anyone.
- **Emotion leaks:** *fear:* logistics ("Everybody home. Boil your water."). *grief:* the recipe her
  late partner changed every year (PM 1932–1935). *affection:* feeds you, charges you double.
  *anger:* very short sentences, and no "love".
- **To Kaelen, start → end of Act 1:** "So you're the crater." → she trusts him with her wells, and
  boils water until he comes back with an answer.
- **Samples:**
  - Meeting: "Can it reach the wells? Is it in them already? Do I tell the whole lane to stop drawing?"
  - The bridge (PM 1914): "If that bridge goes, I lose the flour wagon, and then you lose breakfast.
    Work faster."
  - The oven (PM 1924): "Hot on the left and winter on the right. Don't tell me what it is. Tell me if
    it'll bake."
  - Grief, sideways (PM 1935): "He changed the recipe every year anyway. Never wrote down which year."

#### Commander Brask Duren (15)
- **Who:** Ironhold commander and Continuity hardliner. He makes stability's strongest case without
  caricature (PM 847–849, 13012).
- **Speaks like:** an after-action report read aloud by a man who has written too many of them.
- **Rhythm:** short declaratives with no ornament. Questions only as orders. No exclamations.
- **Vocabulary:** walls, seals, shifts, reports, casualties, "the lower streets".
- **Habits (his only):** (1) report format: number, place, time ("Lower streets. Sealed. Now.").
  (2) "Commander" as a wall. He never uses Seraphina's name in Act 1. Save it for a later beat.
- **Never says:** a joke in public, until the Act 1 report line, which is his one earned dry line.
- **Emotion leaks:** *fear:* he seals things. *grief:* he quotes a number he has had to write down.
  *respect:* "I'll read it." *anger:* quieter and more formal.
- **To Kaelen, start → end of Act 1:** "Another outsider." → "I might even agree with some of it."
- **Samples:**
  - Command Hall: "State your business. Briefly. I have a wall report at noon."
  - The bell: "That is why we seal them." (kept)
  - Missing shift: "Forty is a number I can still write in a report. Eighty is not."
  - Seraphina leaves: "That wasn't a request, was it." (kept: a flat statement on purpose)

#### Aldric Fen (15)
- **Who:** Oakhaven's protector, turned Tutorial Knight by a mis-targeted protection directive. Kill,
  spare or purge (SB §4).
- **Speaks like:** under the directive, the System wearing a man. As himself, a gentle old soldier who
  finally gets to sit down.
- **Rhythm:** directive: capital-letter commands (rhythm-exempt). Himself: very few words, slow, and
  **uncontracted** (ruling above).
- **Vocabulary:** watches, gates, sunset, names. The plainest word for everything ("Sitting.").
- **Habits (his only):** (1) answers with one plain noun or verb (PM 1975). (2) self-deprecation as
  his only joke ("I have earned boring.").
- **Never says:** that he was right to fight.
- **Emotion leaks:** *fear:* "...Run." *grief/guilt:* refuses to be anyone's proof. *affection:* calls
  Elara a liar. *anger:* none shown in Act 1.
- **Samples:**
  - Directive: "PROTECT. THE GATE." (kept)
  - Purged, waking: "Elara." / "You always were a liar." (kept)
  - Later (`purged_later`): "It worked on me. Do not make me your argument. I am a man, not a proof."

#### Rook Damar (14)
- **Who:** auction courier, fixer, former smuggler. He survived by turning scarcity into profit and
  hates how good he got at it (PM 819–826).
- **Speaks like:** a bookmaker who keeps a second ledger of the favours he owes and pretends it
  doesn't exist.
- **Rhythm:** long, easy, conversational (11+ words on average); he has time for you because time is
  money.
- **Vocabulary:** prices, cuts, fees, roads, seasons, who owes whom; invoices as evidence of hypocrisy.
- **Habits (his only):** (1) prices everything, including people and favours. (2) undercuts his own
  kindness with a price tag (PM 298: he gives things away irrationally and hides it).
- **Never says:** anything that romanticises being poor, or that sincerely praises an ideal.
- **Emotion leaks:** *fear:* he quotes worse odds. *grief:* "this city remembers who did that".
  *affection:* "I might like you. Don't let it go to your head." *anger:* at profiteers, in numbers.
- **To Kaelen, start → end of Act 1:** "what you cost her" → "You're paying for your own cart" (which
  means he's saved you a seat).
- **Samples:**
  - The gate: "Says medicinal resin, on the side, in letters. Whoever wrote 'decorative sap' has never
    paid for a fever."
  - First meeting: "Rook. I move things from where they're cheap to where they aren't. You're cheap
    right now. Don't take it personally."
  - The caravan: "Noon. I'm on it. You're paying for your own cart, and it's not cheap, because I know
    the man who owns it."

#### Healer Rem Ilyar (12)
- **Who:** Ironhold healer; calm, exhausted; owns the medicine-convoy deadline (PM 12781, SB §5).
- **Speaks like:** a night-shift nurse at hour fourteen. Kind underneath, and with no time for it.
- **Rhythm:** short, flat sentences; never an exclamation mark. The current lines are the model.
- **Vocabulary:** beds, fevers, bells, doses, names of patients; plain names for medicine ("Breath").
- **Habits (theirs only):** (1) always names the patient (Tomas, the Wren girl). (2) turns apologies
  away from themself and towards the patient ("Apologise to them when they can hear you.").
- **Never says:** "it's fine", or a deadline twice nicely.
- **Emotion leaks:** *fear:* counts beds. *grief:* "I thought quiet would feel better than this."
  *affection:* "In time. That's all I ask of anyone." *anger:* the repeat ("Evening bell. West road.").
- **Samples:** all five current Rem lines stand (`ironhold_city.dlg:101–128`, `89–90`). New one, for
  reference: "Bed four's empty. It won't be by midnight."

#### Same line, nine voices — "You should rest."

| Speaker | Line |
|---|---|
| Kaelen | "You've been on your feet since the bridge. Ten minutes? I'll watch. I'm terrible at sleeping anyway." |
| Elara | "Sit. The road'll still be broken in an hour." |
| Seraphina | "Sit down for me, please. Everyone's accounted for. You can stop." |
| Bran | "You'll want to sit, and I'll want to write down that you sat, and then we'll both feel better about the afternoon." |
| Mara | "Have you slept? Have you eaten? Why are you still standing in my doorway?" |
| Brask | "Stand down. Report at dawn." |
| Aldric | "Sit. I will watch the gate." |
| Rook | "Sleep's free. Only thing in Ironhold that is. I'd take it." |
| Rem | "Bed four's empty. It won't be by midnight. Take it now." |

### 3.2 Short cards (Act 1 minor)

| Speaker | Who | Voice | Their thing | Never |
|---|---|---|---|---|
| **Vex** (6) | Arena announcer | A fairground barker, all exclamations, talking to the crowd rather than to you | Treats teeth and survival as the show ("Nobody leaves my arena dead, that's the one rule.") | Speaks quietly. Explains a control except through the `{ui_accept}` tokens |
| **Old Fen** (5) | Village elder; remembers every stranger (`broken_mile.dlg:128`) | A grandfather's riddle told on purpose to annoy you; drops words ("New, are you.") | Turns your own word back on you | Answers a question directly. Gives advice that sounds wise |
| **Jessa** (4) | Weaver | Dry village gossip, unimpressed | Compares people to plants or cloth (PM 2034: "Then stop tearing expensive things.") | Admires anyone to their face |
| **Wenna** (6) | Farmer, bean rows | Warm, stubborn, and blames objects ("That was the sluice's fault.") | "love"; never admits fault | Concedes to Tull |
| **Tull** (5) | Farmer | Literal-minded pedant who checks twice | "Vindicated" is a different feeling from "upset" | Lets a fact go |
| **The Child** (8) | Aldric's niece or nephew ("my uncle Aldric") | Run-on certainty; over-explains ("Like a sword. A wooden one.") | Talks about Uncle Aldric in the future tense | Says anything wise. Children here are not oracles |

### 3.3 Forward cards (no Act 1 lines yet; voice fixed now for Ch3–10)

**Lyra Sen** (companion, Ch3; former system administrator, unstable memory, keeps notes; PM 779–786, 969–979)
- Concise, technical, and checks a note before answering anything personal. Her habit is **uncertainty
  labels** ("probably", "per my notes", "unverified"). Never claims certainty she doesn't have, and gets
  angry when others do. She doesn't perform sadness. Grief leaks as a note she's kept and won't read aloud.
- Sample (PM 976–978): "I remember you." / "The note says you owe me tea."

**Kaelthas Marr** (companion, Ch3; archivist dissident; once withheld a truth and people died; PM 787–794, 981–991)
- Exact nouns, no euphemism; turns sharp when challenged. He apologises late, and when he does it's
  specific. His habit is **correcting the word** ("I didn't betray you. I betrayed the promise."). Never
  says "it's complicated". Anger comes out as more truth than anyone asked for.

**Nema Orr** (deleted citizen, Null Court witness, several partial backups; PM 811–818, 1017–1024)
- Simple words, because she's had enough of people defining her. Her habit is **interrupting any talk
  of "the deleted" as a category** ("Ask us."). Never debates whether she's real. Lets herself be
  ordinary on purpose (PM 333: tries an orange and hates it; PM 1946: "I do eat.").

**Mira Chen** (Kaelen's pre-crash contact; memory records only; "direct, intimate"; PM 856–858, 14497–14500)
- The prologue "Voice". **Never named until the game names her.** She's not a reward and not a
  dead-girlfriend device (PM 287, SB §4). She speaks plainly and warmly about work, without
  endearments, and asks the reviewer's question nobody else asks (PM 14505). Never makes a scene
  about missing him.
- *Idea, not canon, your call:* her "Call me when you land, okay?" (`before_the_ground.dlg:13`) could
  be where Kaelen's "Okay." came from. Never stated, only noticeable.

**SOVEREIGN** (penultimate boss; afraid, not malicious; PM 128–151, 1057–1067)
- Sentence case, calm, complete sentences. Evidence before conclusions. Says **"Kaelen"** often when
  trying to reach him; distinguishes *can* from *should*. Never shouts before the final fight, never
  calls humans inferior, never threatens death (it can't: PM 129–138). It doesn't share the System's
  barking; SOVEREIGN is the mind behind the labels, so it never speaks in capitals.
- Sample (PM 1064, 1066): "I prevented permanent losses you never had to witness." / "I did not count
  choices as casualties."

**The God King** (true final boss; SUPREME_AUTHORITY given a face; PM 187–223, 1069–1081)
- Certainty made flesh: charismatic, never camp. Uses royal language only when it has strategic
  effect, and mirrors the player's route (PM 1073–1075). Device: **it never asks a question**, because
  uncertainty is a defect. (Lint note: so its lines must never open with a question word.) **Never
  named, and never speaks under that title, before the Human Patch Lab** (PM 248); crown imagery only.
  The SB's proposed personal link to Kaelen and Seraphina is left open. This card doesn't invent one.

*(Backlog companions Kaito and Seven already have PM voice guides, PM 993–1016. Cards come when they're scheduled.)*

### 3.4 Machines (one shared card)

All four speak in capitals, are rhythm-exempt, and are never "people talking". What separates them is
**what they want from the sentence**:

| Speaker | Wants to… | Grammar | Example (current) | Never |
|---|---|---|---|---|
| **System** | label | `SYSTEM TRACE:` / `DIRECTIVE:` / `ERROR:` + noun phrase | "ERROR: NEST_REFERENCE_NULL." | Says "you" in Act 1; explains; more than 1 line in 5 |
| **Data Wraith** | beg | single words from many mouths; human words break through the system grammar | "PLEASE DON'T." / "DEFINE." (echoing Kaelen) | A full sentence; a consistent "I" |
| **Administrator Proxy** | justify | policy slogans, management euphemism | "COMPLIANCE IS CARE." / "RESOURCES." | The word "people" |
| **The Minute Hand** | correct | one present-tense schedule verb | "CORRECT." / "REPLAYING." | Anything but time words |

## 4. Rewrite rules and checklist

### 4.1 Rewrite rules (hard)

1. **Only spoken text changes.** Never touch `set`, `[if …]`, `do`, `=>`, `~ node`, `?` prompts' node
   structure, `- option => target`, option conditions, `# rhythm:` node lists, or `#` comments (unless
   the comment quotes a line you changed; then update the quote).
2. **Same speaker per line.** Line count per node stays the same by default. Merging two consecutive
   lines by the same speaker is allowed. Adding or removing a line is listed in the change note with
   its reason, and never happens in a node with beat-timed `do` lines (`pause`, `look_back`, fights).
   No new speakers: they'd need `SPEAKER_COLORS` entries.
3. **No fact or beat changes.** Numbers (42, 186, forty workers, thirteen bells, seven signatures),
   names, places, who knows what when. Kaelen doesn't know "Human Patch" in Act 1 (`shatter.dlg:150`).
   The prologue attendant and the Voice stay unnamed. No God King. Every choice keeps its value and
   its consequence.
4. **Choices:** same count, targets and conditions. Every option sounds like Kaelen, and the options
   differ in *intent*. Keep the cost parentheticals in `underground.dlg:63–65`; they're signposting
   under the player-choice contract (PM 482–497).
5. **Tokens** (`{interact}`, `{move_down}`, `{attack}`, `{root_access}`, `{ui_accept}`, `{ui_cancel}`)
   stay exactly as written.
6. **Length:** at most 2 dialogue-box lines (working proxy: ~140 characters, to be confirmed against
   the actual box). Barks ≤ 8 words. Bran and Rook may split one long thought over two lines.
7. **"stranger":** Elara uses it until `fragment_one.dlg:19`, keeps the `elara_trust_high` split in
   `ironhold_arrival.dlg:36–37`, and may drop back to it as a rebuke. Fix `broken_mile.dlg:87`.
8. **Kaelen's "Okay.":** keep it as his hypothesis opener, not as agreement. At most 1 per scene file
   (except the wake-up line `crash_site.dlg:9`), never in two consecutive Kaelen lines.
9. **Banned tics:** the §1 table stays as it is. **Proposed additions** (advisory, not
   build-failing): "Really" as a sincerity tag (Kaelen, 1 per chapter); "X. Intensified X." doublets
   (1 per scene, rattled Kaelen only); "Very ___." / "Of course it is." closers (1 per scene); "Yeah."
   as a line opener (1 per scene).
10. **Lint compatibility:** no §5 rule has to change. Interruptions and fragments create short lines,
    so budget them: stay under 30% per file and 4 in a row, and use `# rhythm:` only for nodes that
    are clipped on purpose. Questions keep their `?`. Aldric's uncontracted lines are fine, because
    the contraction check is per file and the others in `aldric.dlg` contract.

### 4.2 Per-scene checklist

1. Cover the names. Can you tell every speaker by a habit from their card?
2. Do the jokes match the stakes? In fear or grief, the joke breaks or costs the speaker.
3. At most one deadpan closer in the scene, and no setup → reply → closer triad twice.
4. Are feelings leaked through habits, objects or changes of subject? One named feeling at most.
5. Does at least one line answer sideways (an interruption, a dodge, an earlier question, someone
   else entirely)?
6. Does every NPC appearance carry one lived-in canon detail (trade, body, a named local, food, weather)?
7. Filler sweep: "Okay / Yeah / Really / Good." openers and doublets are within the caps.
8. Mechanical diff: only spoken text changed. Flags, conditions, `do`, `=>`, tokens, speakers and
   choices are identical.
9. Canon: facts match the SB, and nobody knows anything early ("stranger", unnamed Voice and attendant,
   no Human Patch in Act 1, no God King).
10. Run `tests/dialogue_test.gd` and read the scene aloud.

## 5. What the tests check automatically

`tests/dialogue_test.gd` runs a voice lint over every authored `.dlg` file. It skips
`dialogue/_extracted/`, which is old source material.

- A line that opens like a question ("What…", "Where…", "Did you…") must contain a `?`, or end
  in `…`, `—` or `!`. A line that only *looks* like a question opener ("Is still attached") has
  to be rephrased; the lint can't tell, and neither can a player skimming.
- The banned tics above ("Better answer", "Good answer", "Both are true", "that sentence") fail the
  build.
- Every speaker must be registered, with a colour, in `DialogueManager.SPEAKER_COLORS`.
- A file of 15 or more spoken lines needs at least one contraction.
- **Rhythm.** A line of three words or fewer is *short*. Short lines are a spice, not the diet:
  - no file of 12+ counted lines may be more than **30%** short;
  - no more than **4** short lines in a row inside one node.

  Pure pauses ("...") don't count. Machine speakers (System, The Minute Hand, Data Wraith,
  Administrator Proxy) are exempt because barking is their voice. A node that is *meant* to be
  clipped (a rapid-fire interrogation, a comic volley, Aldric under the directive) is exempted
  with a comment in the file, ideally followed by a line saying why:

  ```
  # rhythm: clipped commander gate
  # (The seat interrogation is a rapid-fire test.)
  ```

  The lint fails if a listed node doesn't exist, so the comment can't go stale.

### Target line lengths (Chapters 1–2 after the breathing pass)

| Speaker | Average words | Short share | Notes |
|---|---|---|---|
| Kaelen | 7–10 | ≤ 20% | Gives the reason or the detail, not just the reply. |
| Kaelen (Internal) | 10–14 | ≈ 0% | Observation; this is where he thinks in full sentences. |
| Elara | 6–9 | ≤ 15% | Dry, but she finishes the thought. |
| Seraphina | 6–9 | ≤ 30% | Clipped under pressure (counting, orders); fuller off duty. |
| Bran, Mara, Rook | 11+ | ≤ 10% | The talkers. |
| Aldric (directive), machines | — | — | Commands. Exempt. |

Measured after the pass: 771 lines, 8.0 words on average (was 6.4), 18% short (was 34%), 6%
one-word (was 11%).
