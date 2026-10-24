# Screenshot tour — 2026-10-24 17:31:27

Godot 4.6.3-stable (official), renderer `forward_plus`, NVIDIA GeForce RTX 2050. Window (1280.0, 720.0).

Game state is reset before each scene, so scenes show their default (fresh-save) state.

**No layout problems found.**

Contact sheets: `contact_scenes.png`, `contact_dialogue.png`.

| Shot | Scene / source | Notes |
|---|---|---|
| `t11_combat_hud_strike2.png` | combat_arena.tscn | real combat_arena scene; tutorial slime, 100000 HP, not hostile; strikes through player._perform_combo_attack(); combo_step 2; chain label `STRIKE 2`; GameJuice counter `2 HIT` |
| `t11_combat_hud_after_hit.png` | combat_arena.tscn | player.take_damage(5) from the slime's position, then one frame; HP 100 -> 95; chain label `` |
