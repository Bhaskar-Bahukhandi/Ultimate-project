# Screenshot tour — 2026-10-25 22:02:27

Godot 4.6.3-stable (official), renderer `forward_plus`, NVIDIA GeForce RTX 2050. Window (1280.0, 720.0).

Game state is reset before each scene, so scenes show their default (fresh-save) state.

**No layout problems found.**

Contact sheets: `contact_scenes.png`, `contact_dialogue.png`.

| Shot | Scene / source | Notes |
|---|---|---|
| `ch1_breadcrumb_oakhaven.png` | oakhaven_village.tscn | real scene run; Chapter 1 step-6 breadcrumb; path: village arrival → ElaraHouseDoor handler → stew in elara_house.tscn → house Door handler → village; 5 choice(s) answered with option 1; objective `Spend the afternoon in Oakhaven. Meet the people here.`; ch1_stew_done set by the real stew (in the house): true; ch1_oakhaven_entered: true; arrow target cached: false; arrow text EMPTY |
| `s08_elara_house.png` | elara_house.tscn | preset ch1_stew_done (stew already eaten, so no stew dialogue); real elara_house.tscn, player at the scene's start spot; on screen: Elara, Table, Player, Door, Bandages, Herbs, Focuses, Cloak, Map; door open: true; state EXPLORATION |
| `s08_shrine.png` | shrine.tscn | preset: golden kill-route flags; real arena: fight started, its own _on_boss_defeated, choices answered with option 0; 2 choice(s) answered with option 1; ch1_knight_killed true; arrived from the arena via the shrine_fresh_arrival hand-off; arrival card `Under the old gate` shown, then faded (black alpha 0.00, text alpha 0.00); dressing shown: DressingKilled; fragment taken: false; altar active: true; dialogue box false |
| `s08_shrine_altar.png` | shrine.tscn | same arrival; player moved to (256.0, 150.0) on the runner (nothing interacted); fragment taken: false; dialogue box false |
