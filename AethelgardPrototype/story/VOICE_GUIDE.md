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

## 2. Voice cards

```
Name:
Speaks like (one comparison):
Sentence length:        short / mixed / long
Vocabulary:
Verbal habit (theirs only):
What they never say:
How they show affection:            How they show fear:
How they talk to Kaelen at the start → by the end:
Three sample lines (a joke, a threat, a confession):
```

### Kaelen
- **Speaks like:** a tired senior engineer on an incident call. He's calm on the surface and
  talks himself through it.
- **Sentence length:** mixed. Short when scared, long when he's working something out.
- **Vocabulary:** plain English with engineering words leaking in under stress ("conditional",
  "two rules running at once"). He never explains them unless asked.
- **Habit:** he thinks out loud in hypotheses, often starting with "Okay." ("Okay. Either the
  plane's somewhere else, or—" and he doesn't finish).
- **Never says:** "chosen one", "creator", or anything that makes his own mystery sound
  impressive.
- **Affection:** he notices practical things and fixes them quietly. **Fear:** he gets very
  precise and very polite.
- **Arc:** treats everything as a bug to fix, then learns that seeing a problem doesn't give him
  the right to solve it.
- **Samples:**
  - "I'm not going to ask about the chicken."
  - "Put the bow down, and I'll put down the sword I didn't know I owned."
  - "There were people with me. I need that to still be true."

### Elara Venn
- **Speaks like:** a village healer who has had to be the adult for too long. She's dry, quick
  and practical.
- **Sentence length:** short, and very short when she's hurting.
- **Vocabulary:** plants, weather, roads, chores, local names. Nothing technical unless she's
  repeating Kaelen, and then she puts it in audible quotes.
- **Habit:** she calls him **"stranger"** until she trusts him, then switches to his name. She
  gives orders disguised as observations ("Road's eating itself again.").
- **Never says:** anything self-pitying about her arm. She won't let anyone else say it either.
- **Affection:** teasing, and food. **Fear:** she goes very formal and very still.
- **Arc:** guarded guide, then partner, though she never becomes Kaelen's patient.
- **Samples:**
  - "Stare at my arm any harder and it'll start charging rent."
  - "Hands where I can see them. Both. Yes, the one with the sword too."
  - "I'll take help I asked for. That's the whole rule."

### Bran (Oakhaven gate guard, keeper of the road ledger)
- **Speaks like:** a man who has been complaining about the same paperwork for twenty years and
  secretly loves it.
- **Sentence length:** long. He runs on, and his grievances come with sub-clauses.
- **Habit:** everything comes back to the ledger. "That's going in the ledger."
- **Never says:** "impossible". He stopped using the word years ago.
- **Sample:** "I write the arguments down so everyone can have exactly the same argument again next
  spring. It's called civic memory."

### Mara Quill (baker)
- **Speaks like:** a quartermaster in an apron. She asks questions back-to-back and doesn't wait
  for the answers.
- **Sentence length:** mixed and fast.
- **Habit:** practical questions in threes: "Can it reach the wells? Will it reach them? How long?"
  She knows everything by lunch.
- **Never says:** anything about destiny. Destiny doesn't feed anyone.
- **Sample:** "You saved a boar. Lovely. Who's paying for the fence?"

### Old Fen
- **Speaks like:** a riddle someone's grandfather tells on purpose to annoy you.
- **Sentence length:** very short, and he drops words ("New, are you.").
- **Habit:** turns your own word back on you.
- **Sample:** "You'll get over it." "Being new?" "Being *apparently*."

### Jessa (weaver)
- **Speaks like:** the village's dry gossip. She's unimpressed by everything.
- **Habit:** compares people unfavourably to plants, cloth, or Elara's other strays.

### Aldric Fen (the Tutorial Knight)
- **Speaks like:** a gentle man buried under a soldier's orders.
- **Under the directive:** capital-letter commands only, in the System's cadence ("PROTECT THE
  GATE.").
- **As himself:** a few words, warm and slow, with no jokes except at his own expense.
- **Never says:** that he was right to fight.
- **Sample:** "It worked on me. Don't make me your argument."

### The flight attendant (Seraphina, unnamed in the prologue)
- **Speaks like:** cabin crew. Clear, calm, rehearsed instructions, then one human slip.
- **Habit:** counts people. Even in the prologue she's checking rows.
- **Later (Chapter 2):** the same calm, now in armour. Her rank never makes her louder.

### System / UI voice
- Short, cold, all capitals, with no personality. It labels things and never explains them.
- Prefixes: `SYSTEM TRACE:`, `DIRECTIVE:`, `ERROR:`. It's spoken as `System:`.
- It never addresses Kaelen as "you" in Act 1. That's a later beat.

### Townsfolk (Tier B/C)
- **Oakhaven:** farm talk, understatement, nicknames for animals ("Pebbles"). People call each other
  "love" and "lad", and nobody hurries.
- Other regions get their own dialect words when they're written.

## 3. Before / after examples

These show the standard the source draft (`Aethelgard_PRODUCTION_MASTER_2.1`) was rewritten to.

| Before | After | Why |
|---|---|---|
| ELARA: That a place. | Elara: Is that a place? | Questions are questions. |
| KAELEN: I did not own a sword. / Apparently I do now. | Kaelen: I don't own a sword. / ...I own a sword. | Contractions. The beat comes from the pause, not from "apparently". |
| ELARA: Better answer. | Elara: Then don't promise me anything you haven't got. | React to what he said, don't grade it. |
| KAELEN: That is a conditional. / ELARA: A what. | Kaelen: That's an if-statement. It's— it's waiting for a nest that isn't there. | Kaelen thinks out loud, which is his habit. |
| BRAN: It talks. / ELARA: Constantly. | Bran: Does it talk? / Elara: You'll wish it didn't. | Same joke, with a natural question. |
| KAELEN: Thirty-four percent temporal stability. That means time itself is fractured in here. | Kaelen: ...That's not a clock problem. | Don't explain what the UI shows. |

## 4. Checklist (every scene)

- [ ] Read aloud; nothing sounds written.
- [ ] Cover the names, and every speaker is still recognisable.
- [ ] No character explains a mechanic the screen could show.
- [ ] System lines are one in five or fewer, and each one is the world speaking.
- [ ] At least one line in the scene means more than it says.
- [ ] Every choice option sounds like something Kaelen would say, and the options differ in
  *intent*, not just wording.
- [ ] Names, places and facts match `STORY_BIBLE.md`.
- [ ] No key names in the text: use `{interact}` and similar tokens (`DIALOGUE_FORMAT.md`).

## 5. What the tests check automatically

`tests/dialogue_test.gd` runs a voice lint over every authored `.dlg` file. It skips
`dialogue/_extracted/`, which is old source material.

- A line that opens like a question ("What…", "Where…", "Did you…") must end in `?`, `…`, `—` or
  `!`.
- The banned tics above ("Better answer", "Good answer", "Both are true", "that sentence") fail the
  build.
- Every speaker must be registered, with a colour, in `DialogueManager.SPEAKER_COLORS`.
