extends Node

# AssetManager - Automatically detects and loads real assets when available
# Falls back to placeholder ColorRects if assets not found

# Asset paths configuration
const ASSET_PATHS = {
	"player": "res://assets/sprites/player/player.png",
	
	# ── Player Sprites (actual imported sprites) ──
	"player_before_ch1": "res://P before ch 1.png",
	"player_after_ch1": "res://P after ch 1.png",
	"player_top_down": "res://P top down.png",
	"player_sprite_sheet": "res://Character sprites.png",
	
	# ── Cutscene Characters (full body for animatic scenes) ──
	"char_kaelen": "res://assets/sprites/characters/kaelen.png",
	"char_elara": "res://assets/sprites/characters/elara.png",
	"char_mira": "res://assets/sprites/characters/mira.png",
	"char_tutorial_knight": "res://assets/sprites/characters/tutorial_knight.png",
	"char_elder": "res://assets/sprites/characters/elder.png",
	"char_farmer_jenkins": "res://assets/sprites/characters/farmer_jenkins.png",
	"char_seraphina": "res://assets/sprites/characters/seraphina.png",
	"char_nyx": "res://assets/sprites/characters/nyx.png",
	"char_pip": "res://assets/sprites/characters/pip.png",
	"char_gate_guard": "res://assets/sprites/characters/gate_guard.png",
	
	# ── Dialogue Portraits (small face icons for dialogue box) ──
	"portrait_kaelen": "res://assets/sprites/portraits/kaelen.png",
	"portrait_kaelen_internal": "res://assets/sprites/portraits/kaelen_internal.png",
	"portrait_elara": "res://assets/sprites/portraits/elara.png",
	"portrait_mira": "res://assets/sprites/portraits/mira.png",
	"portrait_system": "res://assets/sprites/portraits/system.png",
	"portrait_unknown": "res://assets/sprites/portraits/unknown.png",
	"portrait_tutorial_knight": "res://assets/sprites/portraits/tutorial_knight.png",
	"portrait_elder": "res://assets/sprites/portraits/elder.png",
	"portrait_seraphina": "res://assets/sprites/portraits/seraphina.png",
	"portrait_nyx": "res://assets/sprites/portraits/nyx.png",
	"portrait_gate_guard": "res://assets/sprites/portraits/gate_guard.png",
	
	# ── Scene Backgrounds (full-screen 1920x1080 / 1280x720 art) ──
	# Prologue
	"bg_plane_interior": "res://assets/backgrounds/prologue/bg_plane_interior_base.png",
	"bg_plane_glitch1": "res://assets/backgrounds/prologue/bg_plane_interior_glitch1.png",
	"bg_plane_glitch2": "res://assets/backgrounds/prologue/bg_plane_interior_glitch2.png",
	"bg_plane_glitch3": "res://assets/backgrounds/prologue/bg_plane_interior_glitch3.png",
	"bg_plane_glitch4": "res://assets/backgrounds/prologue/bg_plane_interior_glitch4.png",
	"bg_night_sky": "res://assets/backgrounds/prologue/bg_plane_window_sky.png",
	"bg_bsod": "res://assets/backgrounds/prologue/bg_bsod.png",
	"bg_boot_screen": "res://assets/backgrounds/prologue/bg_boot_screen.png",
	"bg_crash_sequence": "res://assets/backgrounds/prologue/bg_crash_sequence.png",
	# Chapter 1
	"bg_glitch_crater": "res://assets/backgrounds/chapter1/bg_crater_sky.png",
	"bg_forest_twilight": "res://assets/backgrounds/chapter1/bg_forest_twilight.png",
	"bg_oakhaven_sky": "res://assets/backgrounds/chapter1/bg_oakhaven_sky.png",
	"bg_oakhaven_buildings_far": "res://assets/backgrounds/chapter1/bg_oakhaven_buildings_far.png",
	"bg_oakhaven_buildings_near": "res://assets/backgrounds/chapter1/bg_oakhaven_buildings_near.png",
	"bg_oakhaven_ground": "res://assets/backgrounds/chapter1/bg_oakhaven_ground.png",
	"bg_tutorial_arena": "res://assets/backgrounds/chapter1/bg_arena_tutorial.png",
	"bg_shatter_bridge": "res://assets/backgrounds/chapter1/bg_shatter_bridge.png",
	# Chapter 2
	"bg_ironhold_sky": "res://assets/backgrounds/chapter2/bg_ironhold_sky.png",
	"bg_ironhold_industrial": "res://assets/backgrounds/chapter2/bg_ironhold_industrial.png",
	"bg_ironhold_market": "res://assets/backgrounds/chapter2/bg_ironhold_market.png",
	"bg_ironhold_arena": "res://assets/backgrounds/chapter2/bg_ironhold_arena.png",
	"bg_ironhold_clock_tower": "res://assets/backgrounds/chapter2/bg_ironhold_clock_tower.png",
	"bg_underground": "res://assets/backgrounds/chapter2/bg_underground.png",
	"bg_admin_boss_arena": "res://assets/backgrounds/chapter2/bg_admin_boss_arena.png",
	
	# Oakhaven enemies
	"slime_green": "res://assets/sprites/enemies/oakhaven/slime.png",
	"boar_corrupted": "res://assets/sprites/enemies/oakhaven/boar.png",
	"knight_tutorial": "res://assets/sprites/bosses/oakhaven/knight.png",
	
	# Ironhold enemies
	"arachnid_clockwork": "res://assets/sprites/enemies/ironhold/spider.png",
	"sentinel_steam": "res://assets/sprites/enemies/ironhold/turret.png",
	"gear_hulk": "res://assets/sprites/bosses/ironhold/hulk.png",
	
	# Necropolis enemies
	"bone_construct": "res://assets/sprites/enemies/necropolis/skeleton.png",
	"wraith": "res://assets/sprites/enemies/necropolis/wraith.png",
	"lich_lord": "res://assets/sprites/bosses/necropolis/lich.png",
	
	# Arena enemies (Chapter 2 wave combat)
	"corrupted_rat": "res://assets/sprites/enemies/oakhaven/corrupted_rat.png",
	"glitch_wolf": "res://assets/sprites/enemies/oakhaven/glitch_wolf.png",
	"corrupted_guard": "res://assets/sprites/enemies/ironhold/corrupted_guard.png",
	"data_sprite": "res://assets/sprites/enemies/ironhold/data_sprite.png",
	"clockwork_soldier": "res://assets/sprites/enemies/ironhold/clockwork_soldier.png",
	"shadow_wraith": "res://assets/sprites/enemies/necropolis/shadow_wraith.png",
	
	# Tilesets
	"tileset_oakhaven": "res://assets/tilesets/oakhaven/sprout_lands.png",
	"tileset_oakhaven_forest": "res://assets/tilesets/oakhaven/mystic_woods.png",
	"tileset_ironhold": "res://assets/tilesets/ironhold/steampunk.png",
	"tileset_necropolis": "res://assets/tilesets/necropolis/gothicvania.png",
	"tileset_celestia": "res://assets/tilesets/celestia/floating_islands.png",
	"tileset_deepblue": "res://assets/tilesets/deepblue/underwater.png",
	
	# Backgrounds
	"bg_celestia_sky": "res://assets/backgrounds/celestia/clouds.png",
	"bg_deepblue": "res://assets/backgrounds/deepblue/ocean.png",
	
	# UI
	"ui_frame": "res://assets/ui/frame.png",
	"ui_button": "res://assets/ui/button.png",
	
	# ── Kenney Enemy Sprites (from Mysprites) ──
	"kenney_slime_blue": "res://assets/sprites/mysprites_enemies/slimeBlue.png",
	"kenney_slime_green": "res://assets/sprites/mysprites_enemies/slimeGreen.png",
	"kenney_slime_purple": "res://assets/sprites/mysprites_enemies/slimePurple.png",
	"kenney_bat": "res://assets/sprites/mysprites_enemies/bat.png",
	"kenney_bat_fly": "res://assets/sprites/mysprites_enemies/bat_fly.png",
	"kenney_bat_hang": "res://assets/sprites/mysprites_enemies/bat_hang.png",
	"kenney_bat_hit": "res://assets/sprites/mysprites_enemies/bat_hit.png",
	"kenney_bat_dead": "res://assets/sprites/mysprites_enemies/bat_dead.png",
	"kenney_spider": "res://assets/sprites/mysprites_enemies/spider.png",
	"kenney_spider_walk1": "res://assets/sprites/mysprites_enemies/spider_walk1.png",
	"kenney_spider_walk2": "res://assets/sprites/mysprites_enemies/spider_walk2.png",
	"kenney_spider_hit": "res://assets/sprites/mysprites_enemies/spider_hit.png",
	"kenney_spider_dead": "res://assets/sprites/mysprites_enemies/spider_dead.png",
	"kenney_ghost": "res://assets/sprites/mysprites_enemies/ghost.png",
	"kenney_ghost_normal": "res://assets/sprites/mysprites_enemies/ghost_normal.png",
	"kenney_ghost_hit": "res://assets/sprites/mysprites_enemies/ghost_hit.png",
	"kenney_ghost_dead": "res://assets/sprites/mysprites_enemies/ghost_dead.png",
	"kenney_snake": "res://assets/sprites/mysprites_enemies/snakeSlime.png",
	"kenney_snake_walk": "res://assets/sprites/mysprites_enemies/snakeSlime_walk.png",
	"kenney_snake_hit": "res://assets/sprites/mysprites_enemies/snakeSlime_hit.png",
	"kenney_snake_dead": "res://assets/sprites/mysprites_enemies/snakeSlime_dead.png",
	"kenney_snake_lava": "res://assets/sprites/mysprites_enemies/snakeLava.png",
	"kenney_snake_lava_walk": "res://assets/sprites/mysprites_enemies/snakeLava_walk.png",
	"kenney_snake_lava_hit": "res://assets/sprites/mysprites_enemies/snakeLava_hit.png",
	"kenney_snake_lava_dead": "res://assets/sprites/mysprites_enemies/snakeLava_dead.png",
	"kenney_fly": "res://assets/sprites/mysprites_enemies/fly.png",
	"kenney_fly_fly": "res://assets/sprites/mysprites_enemies/fly_fly.png",
	"kenney_fly_hit": "res://assets/sprites/mysprites_enemies/fly_hit.png",
	"kenney_fly_dead": "res://assets/sprites/mysprites_enemies/fly_dead.png",
	"kenney_bee": "res://assets/sprites/mysprites_enemies/bee.png",
	"kenney_bee_fly": "res://assets/sprites/mysprites_enemies/bee_fly.png",
	"kenney_bee_hit": "res://assets/sprites/mysprites_enemies/bee_hit.png",
	"kenney_bee_dead": "res://assets/sprites/mysprites_enemies/bee_dead.png",
	"kenney_worm": "res://assets/sprites/mysprites_enemies/worm.png",
	"kenney_worm_walk": "res://assets/sprites/mysprites_enemies/worm_walk.png",
	"kenney_worm_hit": "res://assets/sprites/mysprites_enemies/worm_hit.png",
	"kenney_worm_dead": "res://assets/sprites/mysprites_enemies/worm_dead.png",
	"kenney_mouse": "res://assets/sprites/mysprites_enemies/mouse.png",
	"kenney_mouse_walk": "res://assets/sprites/mysprites_enemies/mouse_walk.png",
	"kenney_mouse_hit": "res://assets/sprites/mysprites_enemies/mouse_hit.png",
	"kenney_mouse_dead": "res://assets/sprites/mysprites_enemies/mouse_dead.png",
	"kenney_frog": "res://assets/sprites/mysprites_enemies/frog.png",
	"kenney_frog_leap": "res://assets/sprites/mysprites_enemies/frog_leap.png",
	"kenney_frog_hit": "res://assets/sprites/mysprites_enemies/frog_hit.png",
	"kenney_frog_dead": "res://assets/sprites/mysprites_enemies/frog_dead.png",
	"kenney_snail": "res://assets/sprites/mysprites_enemies/snail.png",
	"kenney_snail_walk": "res://assets/sprites/mysprites_enemies/snail_walk.png",
	"kenney_snail_hit": "res://assets/sprites/mysprites_enemies/snail_hit.png",
	"kenney_snail_shell": "res://assets/sprites/mysprites_enemies/snail_shell.png",
	"kenney_ladybug": "res://assets/sprites/mysprites_enemies/ladyBug.png",
	"kenney_ladybug_fly": "res://assets/sprites/mysprites_enemies/ladyBug_fly.png",
	"kenney_ladybug_walk": "res://assets/sprites/mysprites_enemies/ladyBug_walk.png",
	"kenney_ladybug_hit": "res://assets/sprites/mysprites_enemies/ladyBug_hit.png",
	"kenney_barnacle": "res://assets/sprites/mysprites_enemies/barnacle.png",
	"kenney_barnacle_bite": "res://assets/sprites/mysprites_enemies/barnacle_bite.png",
	"kenney_barnacle_hit": "res://assets/sprites/mysprites_enemies/barnacle_hit.png",
	"kenney_barnacle_dead": "res://assets/sprites/mysprites_enemies/barnacle_dead.png",
	"kenney_spinner": "res://assets/sprites/mysprites_enemies/spinner.png",
	"kenney_spinner_spin": "res://assets/sprites/mysprites_enemies/spinner_spin.png",
	"kenney_spinner_hit": "res://assets/sprites/mysprites_enemies/spinner_hit.png",
	"kenney_spinner_dead": "res://assets/sprites/mysprites_enemies/spinner_dead.png",
	
	# ── Kenney Character Sprites (alien platformer set) ──
	"kenney_char_blue": "res://assets/sprites/mysprites_characters/alienBlue_stand.png",
	"kenney_char_blue_walk1": "res://assets/sprites/mysprites_characters/alienBlue_walk1.png",
	"kenney_char_blue_walk2": "res://assets/sprites/mysprites_characters/alienBlue_walk2.png",
	"kenney_char_blue_jump": "res://assets/sprites/mysprites_characters/alienBlue_jump.png",
	"kenney_char_blue_duck": "res://assets/sprites/mysprites_characters/alienBlue_duck.png",
	"kenney_char_blue_hurt": "res://assets/sprites/mysprites_characters/alienBlue_hurt.png",
	"kenney_char_green": "res://assets/sprites/mysprites_characters/alienGreen_stand.png",
	"kenney_char_green_walk1": "res://assets/sprites/mysprites_characters/alienGreen_walk1.png",
	"kenney_char_green_walk2": "res://assets/sprites/mysprites_characters/alienGreen_walk2.png",
	"kenney_char_green_jump": "res://assets/sprites/mysprites_characters/alienGreen_jump.png",
	"kenney_char_green_duck": "res://assets/sprites/mysprites_characters/alienGreen_duck.png",
	"kenney_char_green_hurt": "res://assets/sprites/mysprites_characters/alienGreen_hurt.png",
	"kenney_char_beige": "res://assets/sprites/mysprites_characters/alienBeige_stand.png",
	"kenney_char_beige_walk1": "res://assets/sprites/mysprites_characters/alienBeige_walk1.png",
	"kenney_char_beige_walk2": "res://assets/sprites/mysprites_characters/alienBeige_walk2.png",
	"kenney_char_beige_jump": "res://assets/sprites/mysprites_characters/alienBeige_jump.png",
	"kenney_char_beige_duck": "res://assets/sprites/mysprites_characters/alienBeige_duck.png",
	"kenney_char_beige_hurt": "res://assets/sprites/mysprites_characters/alienBeige_hurt.png",
	"kenney_char_pink": "res://assets/sprites/mysprites_characters/alienPink_stand.png",
	"kenney_char_pink_walk1": "res://assets/sprites/mysprites_characters/alienPink_walk1.png",
	"kenney_char_pink_walk2": "res://assets/sprites/mysprites_characters/alienPink_walk2.png",
	"kenney_char_pink_jump": "res://assets/sprites/mysprites_characters/alienPink_jump.png",
	"kenney_char_pink_duck": "res://assets/sprites/mysprites_characters/alienPink_duck.png",
	"kenney_char_pink_hurt": "res://assets/sprites/mysprites_characters/alienPink_hurt.png",
	"kenney_char_yellow": "res://assets/sprites/mysprites_characters/alienYellow_stand.png",
	"kenney_char_yellow_walk1": "res://assets/sprites/mysprites_characters/alienYellow_walk1.png",
	"kenney_char_yellow_walk2": "res://assets/sprites/mysprites_characters/alienYellow_walk2.png",
	"kenney_char_yellow_jump": "res://assets/sprites/mysprites_characters/alienYellow_jump.png",
	"kenney_char_yellow_duck": "res://assets/sprites/mysprites_characters/alienYellow_duck.png",
	"kenney_char_yellow_hurt": "res://assets/sprites/mysprites_characters/alienYellow_hurt.png",
	
	# ── Kenney VFX Effects (transparent PNGs) ──
	"vfx_slash_01": "res://assets/sprites/mysprites_effects/slash_01.png",
	"vfx_slash_02": "res://assets/sprites/mysprites_effects/slash_02.png",
	"vfx_slash_03": "res://assets/sprites/mysprites_effects/slash_03.png",
	"vfx_slash_04": "res://assets/sprites/mysprites_effects/slash_04.png",
	"vfx_smoke_01": "res://assets/sprites/mysprites_effects/smoke_01.png",
	"vfx_smoke_02": "res://assets/sprites/mysprites_effects/smoke_02.png",
	"vfx_smoke_03": "res://assets/sprites/mysprites_effects/smoke_03.png",
	"vfx_smoke_04": "res://assets/sprites/mysprites_effects/smoke_04.png",
	"vfx_smoke_05": "res://assets/sprites/mysprites_effects/smoke_05.png",
	"vfx_smoke_06": "res://assets/sprites/mysprites_effects/smoke_06.png",
	"vfx_smoke_07": "res://assets/sprites/mysprites_effects/smoke_07.png",
	"vfx_smoke_08": "res://assets/sprites/mysprites_effects/smoke_08.png",
	"vfx_smoke_09": "res://assets/sprites/mysprites_effects/smoke_09.png",
	"vfx_smoke_10": "res://assets/sprites/mysprites_effects/smoke_10.png",
	"vfx_fire_01": "res://assets/sprites/mysprites_effects/fire_01.png",
	"vfx_fire_02": "res://assets/sprites/mysprites_effects/fire_02.png",
	"vfx_flame_01": "res://assets/sprites/mysprites_effects/flame_01.png",
	"vfx_flame_02": "res://assets/sprites/mysprites_effects/flame_02.png",
	"vfx_flame_03": "res://assets/sprites/mysprites_effects/flame_03.png",
	"vfx_flame_04": "res://assets/sprites/mysprites_effects/flame_04.png",
	"vfx_flame_05": "res://assets/sprites/mysprites_effects/flame_05.png",
	"vfx_flame_06": "res://assets/sprites/mysprites_effects/flame_06.png",
	"vfx_spark_01": "res://assets/sprites/mysprites_effects/spark_01.png",
	"vfx_spark_02": "res://assets/sprites/mysprites_effects/spark_02.png",
	"vfx_spark_03": "res://assets/sprites/mysprites_effects/spark_03.png",
	"vfx_spark_04": "res://assets/sprites/mysprites_effects/spark_04.png",
	"vfx_spark_05": "res://assets/sprites/mysprites_effects/spark_05.png",
	"vfx_spark_06": "res://assets/sprites/mysprites_effects/spark_06.png",
	"vfx_spark_07": "res://assets/sprites/mysprites_effects/spark_07.png",
	"vfx_star_01": "res://assets/sprites/mysprites_effects/star_01.png",
	"vfx_star_02": "res://assets/sprites/mysprites_effects/star_02.png",
	"vfx_star_03": "res://assets/sprites/mysprites_effects/star_03.png",
	"vfx_star_04": "res://assets/sprites/mysprites_effects/star_04.png",
	"vfx_star_05": "res://assets/sprites/mysprites_effects/star_05.png",
	"vfx_star_06": "res://assets/sprites/mysprites_effects/star_06.png",
	"vfx_star_07": "res://assets/sprites/mysprites_effects/star_07.png",
	"vfx_star_08": "res://assets/sprites/mysprites_effects/star_08.png",
	"vfx_star_09": "res://assets/sprites/mysprites_effects/star_09.png",
	"vfx_circle_01": "res://assets/sprites/mysprites_effects/circle_01.png",
	"vfx_circle_02": "res://assets/sprites/mysprites_effects/circle_02.png",
	"vfx_circle_03": "res://assets/sprites/mysprites_effects/circle_03.png",
	"vfx_circle_04": "res://assets/sprites/mysprites_effects/circle_04.png",
	"vfx_circle_05": "res://assets/sprites/mysprites_effects/circle_05.png",
	"vfx_magic_01": "res://assets/sprites/mysprites_effects/magic_01.png",
	"vfx_magic_02": "res://assets/sprites/mysprites_effects/magic_02.png",
	"vfx_magic_03": "res://assets/sprites/mysprites_effects/magic_03.png",
	"vfx_magic_04": "res://assets/sprites/mysprites_effects/magic_04.png",
	"vfx_magic_05": "res://assets/sprites/mysprites_effects/magic_05.png",
	"vfx_scorch_01": "res://assets/sprites/mysprites_effects/scorch_01.png",
	"vfx_scorch_02": "res://assets/sprites/mysprites_effects/scorch_02.png",
	"vfx_scorch_03": "res://assets/sprites/mysprites_effects/scorch_03.png",
	"vfx_light_01": "res://assets/sprites/mysprites_effects/light_01.png",
	"vfx_light_02": "res://assets/sprites/mysprites_effects/light_02.png",
	"vfx_light_03": "res://assets/sprites/mysprites_effects/light_03.png",
	"vfx_muzzle_01": "res://assets/sprites/mysprites_effects/muzzle_01.png",
	"vfx_muzzle_02": "res://assets/sprites/mysprites_effects/muzzle_02.png",
	"vfx_muzzle_03": "res://assets/sprites/mysprites_effects/muzzle_03.png",
	"vfx_muzzle_04": "res://assets/sprites/mysprites_effects/muzzle_04.png",
	"vfx_muzzle_05": "res://assets/sprites/mysprites_effects/muzzle_05.png",
	"vfx_twirl_01": "res://assets/sprites/mysprites_effects/twirl_01.png",
	"vfx_twirl_02": "res://assets/sprites/mysprites_effects/twirl_02.png",
	"vfx_twirl_03": "res://assets/sprites/mysprites_effects/twirl_03.png",
	"vfx_scratch_01": "res://assets/sprites/mysprites_effects/scratch_01.png",
	"vfx_flare_01": "res://assets/sprites/mysprites_effects/flare_01.png",
	"vfx_dirt_01": "res://assets/sprites/mysprites_effects/dirt_01.png",
	"vfx_dirt_02": "res://assets/sprites/mysprites_effects/dirt_02.png",
	"vfx_dirt_03": "res://assets/sprites/mysprites_effects/dirt_03.png",
	"vfx_trace_01": "res://assets/sprites/mysprites_effects/trace_01.png",
	"vfx_trace_02": "res://assets/sprites/mysprites_effects/trace_02.png",
	"vfx_trace_03": "res://assets/sprites/mysprites_effects/trace_03.png",
	"vfx_trace_04": "res://assets/sprites/mysprites_effects/trace_04.png",
	"vfx_trace_05": "res://assets/sprites/mysprites_effects/trace_05.png",
	"vfx_trace_06": "res://assets/sprites/mysprites_effects/trace_06.png",
	"vfx_trace_07": "res://assets/sprites/mysprites_effects/trace_07.png",
	"vfx_window_01": "res://assets/sprites/mysprites_effects/window_01.png",
	"vfx_window_02": "res://assets/sprites/mysprites_effects/window_02.png",
	"vfx_window_03": "res://assets/sprites/mysprites_effects/window_03.png",
	"vfx_window_04": "res://assets/sprites/mysprites_effects/window_04.png",
	"vfx_symbol_01": "res://assets/sprites/mysprites_effects/symbol_01.png",
	"vfx_symbol_02": "res://assets/sprites/mysprites_effects/symbol_02.png",
	
	# ── Kenney Items (collectibles, pickups) ──
	"item_coin_gold": "res://assets/sprites/mysprites_items/platformPack_item001.png",
	"item_coin_silver": "res://assets/sprites/mysprites_items/platformPack_item002.png",
	"item_coin_bronze": "res://assets/sprites/mysprites_items/platformPack_item003.png",
	"item_gem_blue": "res://assets/sprites/mysprites_items/platformPack_item004.png",
	"item_gem_green": "res://assets/sprites/mysprites_items/platformPack_item005.png",
	"item_gem_red": "res://assets/sprites/mysprites_items/platformPack_item006.png",
	"item_gem_yellow": "res://assets/sprites/mysprites_items/platformPack_item007.png",
	"item_star_gold": "res://assets/sprites/mysprites_items/platformPack_item008.png",
	"item_star_silver": "res://assets/sprites/mysprites_items/platformPack_item009.png",
	"item_star_bronze": "res://assets/sprites/mysprites_items/platformPack_item010.png",
	"item_heart": "res://assets/sprites/mysprites_items/platformPack_item011.png",
	"item_key": "res://assets/sprites/mysprites_items/platformPack_item012.png",
	"item_potion_red": "res://assets/sprites/mysprites_items/platformPack_item013.png",
	"item_potion_blue": "res://assets/sprites/mysprites_items/platformPack_item014.png",
	"item_potion_green": "res://assets/sprites/mysprites_items/platformPack_item015.png",
	"item_flag": "res://assets/sprites/mysprites_items/platformPack_item016.png",
	"item_mushroom": "res://assets/sprites/mysprites_items/platformPack_item017.png",
	"item_spring": "res://assets/sprites/mysprites_items/platformPack_item018.png",
	
	# ── Kenney UI Elements (RPG Pack) ──
	"ui_bar_blue_left": "res://assets/sprites/mysprites_ui/barBlue_horizontalLeft.png",
	"ui_bar_blue_mid": "res://assets/sprites/mysprites_ui/barBlue_horizontalMid.png",
	"ui_bar_blue_right": "res://assets/sprites/mysprites_ui/barBlue_horizontalRight.png",
	"ui_bar_green_left": "res://assets/sprites/mysprites_ui/barGreen_horizontalLeft.png",
	"ui_bar_green_mid": "res://assets/sprites/mysprites_ui/barGreen_horizontalMid.png",
	"ui_bar_green_right": "res://assets/sprites/mysprites_ui/barGreen_horizontalRight.png",
	"ui_bar_red_left": "res://assets/sprites/mysprites_ui/barRed_horizontalLeft.png",
	"ui_bar_red_mid": "res://assets/sprites/mysprites_ui/barRed_horizontalMid.png",
	"ui_bar_red_right": "res://assets/sprites/mysprites_ui/barRed_horizontalRight.png",
	"ui_bar_yellow_left": "res://assets/sprites/mysprites_ui/barYellow_horizontalLeft.png",
	"ui_bar_yellow_mid": "res://assets/sprites/mysprites_ui/barYellow_horizontalMid.png",
	"ui_bar_yellow_right": "res://assets/sprites/mysprites_ui/barYellow_horizontalRight.png",
	"ui_panel_blue": "res://assets/sprites/mysprites_ui/panelBlue.png",
	"ui_panel_brown": "res://assets/sprites/mysprites_ui/panelBrown.png",
	"ui_panel_beige": "res://assets/sprites/mysprites_ui/panelBeige.png",
	"ui_panel_inset_blue": "res://assets/sprites/mysprites_ui/panelInsetBlue.png",
	"ui_panel_inset_brown": "res://assets/sprites/mysprites_ui/panelInsetBrown.png",
	"ui_panel_inset_beige": "res://assets/sprites/mysprites_ui/panelInsetBeige.png",
	"ui_btn_blue": "res://assets/sprites/mysprites_ui/buttonLong_blue.png",
	"ui_btn_blue_pressed": "res://assets/sprites/mysprites_ui/buttonLong_blue_pressed.png",
	"ui_btn_brown": "res://assets/sprites/mysprites_ui/buttonLong_brown.png",
	"ui_btn_brown_pressed": "res://assets/sprites/mysprites_ui/buttonLong_brown_pressed.png",
	"ui_btn_grey": "res://assets/sprites/mysprites_ui/buttonLong_grey.png",
	"ui_btn_grey_pressed": "res://assets/sprites/mysprites_ui/buttonLong_grey_pressed.png",
	"ui_cursor_gauntlet": "res://assets/sprites/mysprites_ui/cursorGauntlet_blue.png",
	"ui_cursor_sword": "res://assets/sprites/mysprites_ui/cursorSword_gold.png",
	"ui_arrowBrown_right": "res://assets/sprites/mysprites_ui/arrowBrown_right.png",
	"ui_arrowBrown_left": "res://assets/sprites/mysprites_ui/arrowBrown_left.png",
	"ui_arrowBrown_up": "res://assets/sprites/mysprites_ui/arrowBrown_up.png",
	"ui_arrowBrown_down": "res://assets/sprites/mysprites_ui/arrowBrown_down.png",
	
	# ── Kenney Background Tiles (for procedural BG generation) ──
	"bg_tile_ground": "res://assets/sprites/mysprites_tiles/platformPack_tile001.png",
	"bg_tile_grass": "res://assets/sprites/mysprites_tiles/platformPack_tile004.png",
	"bg_tile_stone": "res://assets/sprites/mysprites_tiles/platformPack_tile013.png",
	"bg_tile_dirt": "res://assets/sprites/mysprites_tiles/platformPack_tile005.png",
	"bg_tile_wood": "res://assets/sprites/mysprites_tiles/platformPack_tile041.png",
	"bg_tile_brick": "res://assets/sprites/mysprites_tiles/platformPack_tile016.png",
	"bg_tile_metal": "res://assets/sprites/mysprites_tiles/platformPack_tile033.png",
	"bg_tile_ladder": "res://assets/sprites/mysprites_tiles/platformPack_tile057.png",
	"bg_tile_bridge": "res://assets/sprites/mysprites_tiles/platformPack_tile048.png",
	"bg_tile_spikes": "res://assets/sprites/mysprites_tiles/platformPack_tile044.png",
	"bg_tile_water_top": "res://assets/sprites/mysprites_tiles/platformPack_tile036.png",
	"bg_tile_water": "res://assets/sprites/mysprites_tiles/platformPack_tile037.png",
}

# Placeholder colors for missing assets
const PLACEHOLDER_COLORS = {
	"player": Color(0.3, 0.6, 1),
	# Cutscene characters
	"char_kaelen": Color(0.3, 0.6, 1.0),
	"char_elara": Color(0.8, 0.4, 1.0),
	"char_mira": Color(0.9, 0.6, 0.2),
	"char_tutorial_knight": Color(0.7, 0.3, 0.3),
	"char_elder": Color(0.7, 0.7, 0.8),
	"char_farmer_jenkins": Color(0.6, 0.8, 0.3),
	"char_seraphina": Color(0.95, 0.55, 0.55),
	"char_nyx": Color(0.6, 0.9, 0.8),
	"char_pip": Color(1.0, 0.85, 0.4),
	"char_gate_guard": Color(0.5, 0.5, 0.6),
	# Portraits
	"portrait_kaelen": Color(0.3, 0.6, 1.0),
	"portrait_kaelen_internal": Color(0.5, 0.65, 0.8),
	"portrait_elara": Color(0.8, 0.4, 1.0),
	"portrait_mira": Color(0.9, 0.6, 0.2),
	"portrait_system": Color(0.0, 1.0, 1.0),
	"portrait_unknown": Color(0.6, 0.0, 0.8),
	"portrait_tutorial_knight": Color(0.7, 0.3, 0.3),
	"portrait_elder": Color(0.7, 0.7, 0.8),
	"portrait_seraphina": Color(0.95, 0.55, 0.55),
	"portrait_nyx": Color(0.6, 0.9, 0.8),
	"portrait_gate_guard": Color(0.5, 0.5, 0.6),
	# Backgrounds
	"bg_plane_interior": Color(0.17, 0.30, 0.42),
	"bg_plane_glitch1": Color(0.17, 0.30, 0.42),
	"bg_plane_glitch2": Color(0.15, 0.25, 0.38),
	"bg_plane_glitch3": Color(0.12, 0.20, 0.32),
	"bg_plane_glitch4": Color(0.08, 0.12, 0.20),
	"bg_night_sky": Color(0.04, 0.04, 0.10),
	"bg_bsod": Color(0.0, 0.0, 0.667),
	"bg_boot_screen": Color(0.04, 0.04, 0.04),
	"bg_crash_sequence": Color(0.05, 0.05, 0.10),
	"bg_glitch_crater": Color(0.15, 0.08, 0.25),
	"bg_forest_twilight": Color(0.15, 0.10, 0.25),
	"bg_oakhaven_sky": Color(0.529, 0.808, 0.922),
	"bg_oakhaven_buildings_far": Color(0.502, 0.502, 0.502),
	"bg_oakhaven_buildings_near": Color(0.36, 0.25, 0.20),
	"bg_oakhaven_ground": Color(0.29, 0.545, 0.29),
	"bg_tutorial_arena": Color(0.227, 0.227, 0.227),
	"bg_shatter_bridge": Color(0.15, 0.08, 0.2),
	"bg_ironhold_sky": Color(1.0, 0.549, 0.259),
	"bg_ironhold_industrial": Color(0.44, 0.50, 0.565),
	"bg_ironhold_market": Color(0.722, 0.451, 0.20),
	"bg_ironhold_arena": Color(0.353, 0.353, 0.353),
	"bg_ironhold_clock_tower": Color(0.545, 0.271, 0.075),
	"bg_underground": Color(0.04, 0.03, 0.06),
	"bg_admin_boss_arena": Color(0.15, 0.02, 0.02),
	# Enemies
	"slime_green": Color(0.2, 0.8, 0.2),
	"boar_corrupted": Color(0.6, 0.3, 0.2),
	"knight_tutorial": Color(0.7, 0.7, 0.7),
	"arachnid_clockwork": Color(0.4, 0.3, 0.2),
	"sentinel_steam": Color(0.5, 0.4, 0.3),
	"gear_hulk": Color(0.6, 0.5, 0.4),
	"bone_construct": Color(0.9, 0.9, 0.8),
	"wraith": Color(0.3, 0.3, 0.5),
	"lich_lord": Color(0.5, 0.2, 0.5),
	# Arena enemies (Chapter 2)
	"corrupted_rat": Color(0.5, 0.3, 0.2),
	"glitch_wolf": Color(0.3, 0.4, 0.6),
	"corrupted_guard": Color(0.5, 0.5, 0.6),
	"data_sprite": Color(0.2, 0.8, 1.0),
	"clockwork_soldier": Color(0.7, 0.6, 0.3),
	"shadow_wraith": Color(0.4, 0.2, 0.6),
	# Kenney enemies
	"kenney_slime_blue": Color(0.2, 0.4, 0.9),
	"kenney_slime_green": Color(0.2, 0.8, 0.2),
	"kenney_slime_purple": Color(0.6, 0.2, 0.8),
	"kenney_bat": Color(0.4, 0.3, 0.5),
	"kenney_spider": Color(0.5, 0.3, 0.2),
	"kenney_ghost": Color(0.8, 0.8, 0.9),
	"kenney_snake": Color(0.3, 0.7, 0.3),
	"kenney_snake_lava": Color(0.9, 0.3, 0.1),
	"kenney_fly": Color(0.3, 0.3, 0.3),
	"kenney_bee": Color(0.9, 0.8, 0.1),
	"kenney_worm": Color(0.7, 0.5, 0.3),
	"kenney_mouse": Color(0.6, 0.5, 0.4),
	"kenney_frog": Color(0.2, 0.7, 0.3),
	"kenney_snail": Color(0.6, 0.5, 0.3),
	"kenney_ladybug": Color(0.9, 0.2, 0.2),
	"kenney_barnacle": Color(0.5, 0.4, 0.5),
	"kenney_spinner": Color(0.6, 0.6, 0.6),
	"default": Color(1, 0, 1) # Magenta for undefined
}

# Cache loaded assets
var loaded_assets = {}
var assets_available = {}

func _ready() -> void:
	print("AssetManager initialized - Scanning for asset availability...")
	_scan_availability()

func _scan_availability() -> void:
	## Quick availability check — no actual loading. Assets are loaded lazily on first use.
	for asset_name in ASSET_PATHS:
		var path = ASSET_PATHS[asset_name]
		assets_available[asset_name] = ResourceLoader.exists(path)

func scan_all_assets() -> void:
	## Full scan + load all assets (legacy call, now lazy-safe).
	_scan_availability()
	for asset_name in ASSET_PATHS:
		if assets_available[asset_name] and not loaded_assets.has(asset_name):
			var texture = load(ASSET_PATHS[asset_name])
			if texture:
				loaded_assets[asset_name] = texture

func get_sprite(asset_name: String) -> Texture2D:
	## Get a loaded texture asset — lazy-loads on first access.
	if loaded_assets.has(asset_name):
		return loaded_assets[asset_name]
	# Lazy load if available
	if assets_available.get(asset_name, false):
		var texture = load(ASSET_PATHS[asset_name])
		if texture:
			loaded_assets[asset_name] = texture
			return texture
	return null

func get_texture(asset_name: String) -> Texture2D:
	## Compatibility alias used by procedural background/story scenes.
	return get_sprite(asset_name)

func is_asset_available(asset_name: String) -> bool:
	## Check if a real asset is available
	return assets_available.get(asset_name, false)

func get_placeholder_color(asset_name: String) -> Color:
	## Get placeholder color for an asset
	return PLACEHOLDER_COLORS.get(asset_name, PLACEHOLDER_COLORS["default"])

func create_sprite_node(asset_name: String, size: Vector2 = Vector2(64, 64)) -> Node:
	## Create either a Sprite2D or ColorRect depending on asset availability
	if is_asset_available(asset_name):
		var sprite = Sprite2D.new()
		sprite.texture = get_sprite(asset_name)
		sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		sprite.name = asset_name + "_sprite"
		# Scale to fit requested size, preserving aspect ratio
		var tex_size = sprite.texture.get_size()
		if tex_size.x > 0 and tex_size.y > 0:
			var uniform = min(size.x / tex_size.x, size.y / tex_size.y)
			sprite.scale = Vector2(uniform, uniform)
		return sprite
	else:
		var rect = ColorRect.new()
		rect.size = size
		rect.position = -size / 2  # Center it
		rect.color = get_placeholder_color(asset_name)
		rect.name = asset_name + "_placeholder"
		return rect

func create_animated_sprite(asset_name: String, _frame_count: int = 1, size: Vector2 = Vector2(32, 32)) -> Node:
	## Create AnimatedSprite2D if asset available, otherwise ColorRect
	if is_asset_available(asset_name):
		var anim_sprite = AnimatedSprite2D.new()
		# Setup animation frames
		var sprite_frames = SpriteFrames.new()
		sprite_frames.add_animation("default")
		
		# If the asset is a sprite sheet, split it
		var texture = get_sprite(asset_name)
		sprite_frames.add_frame("default", texture)
		
		anim_sprite.sprite_frames = sprite_frames
		anim_sprite.play("default")
		anim_sprite.name = asset_name + "_animated"
		return anim_sprite
	else:
		# Fallback to simple ColorRect
		return create_sprite_node(asset_name, size)

func apply_to_node(node: Node, asset_name: String) -> void:
	## Apply real asset or placeholder to an existing node
	if node is Sprite2D:
		if is_asset_available(asset_name):
			node.texture = get_sprite(asset_name)
		else:
			# Convert to ColorRect
			var parent = node.get_parent()
			var rect = create_sprite_node(asset_name, Vector2(32, 32))
			rect.position = node.position
			parent.add_child(rect)
			node.queue_free()
	elif node is ColorRect:
		if is_asset_available(asset_name):
			# Upgrade to real sprite
			var parent = node.get_parent()
			var sprite = Sprite2D.new()
			sprite.texture = get_sprite(asset_name)
			sprite.position = node.position + node.size / 2
			sprite.name = node.name.replace("_placeholder", "_sprite")
			parent.add_child(sprite)
			node.queue_free()

func get_tileset(asset_name: String) -> Texture2D:
	## Get tileset texture
	return get_sprite(asset_name)

func print_asset_report() -> void:
	## Debug function to print asset availability
	print("\n=== ASSET AVAILABILITY REPORT ===")
	var available_count = 0
	var missing_count = 0
	
	for asset_name in ASSET_PATHS:
		var available = assets_available.get(asset_name, false)
		if available:
			print("✓ ", asset_name)
			available_count += 1
		else:
			print("○ ", asset_name, " (placeholder active)")
			missing_count += 1
	
	print("\nTotal: ", available_count, " available, ", missing_count, " using placeholders")
	print("=================================\n")

# Helper function for creating enemies
func create_enemy_sprite(enemy_type: String, hp: float, max_hp: float) -> Node2D:
	## Create complete enemy node with sprite and health bar
	var enemy_node = Node2D.new()
	enemy_node.name = enemy_type
	
	# Sprite — 96px for crisp 16x16 pixel art (6x scale)
	var sprite = create_sprite_node(enemy_type, Vector2(96, 96))
	enemy_node.add_child(sprite)
	
	# Health bar
	var health_bar = ProgressBar.new()
	health_bar.position = Vector2(-48, -60)
	health_bar.size = Vector2(96, 10)
	health_bar.value = (hp / maxf(max_hp, 1.0)) * 100.0
	health_bar.show_percentage = false
	enemy_node.add_child(health_bar)
	
	# Label
	var label = Label.new()
	label.position = Vector2(-50, -80)
	label.size = Vector2(100, 20)
	label.text = enemy_type.replace("_", " ").capitalize()
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	enemy_node.add_child(label)
	
	return enemy_node

# Helper for creating player sprite — prefers actual imported sprites
func create_player_sprite(context: String = "combat") -> Node:
	## Create player sprite based on context: 'combat', 'before_ch1', 'after_ch1', 'top_down'
	var sprite_key = "player"
	var is_side_scroll = true
	var target_h = 96.0
	match context:
		"before_ch1":
			sprite_key = "player_before_ch1"
		"after_ch1", "combat":
			sprite_key = "player_after_ch1"
		"top_down", "exploration":
			sprite_key = "player_top_down"
			is_side_scroll = false
			target_h = 64.0
	
	# Try the specific sprite first
	var tex = get_sprite(sprite_key)
	if tex:
		var sprite2d = Sprite2D.new()
		sprite2d.name = "Sprite"
		sprite2d.texture = tex
		sprite2d.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		# Player/Kaelen art faces LEFT -- flip so default facing is RIGHT
		sprite2d.flip_h = true
		sprite2d.set_meta("faces_left", true)
		var tex_size = tex.get_size()
		if tex_size.x > 0 and tex_size.y > 0:
			var uniform = target_h / max(tex_size.x, tex_size.y)
			sprite2d.scale = Vector2(uniform, uniform)
			if is_side_scroll:
				# Feet at origin: shift texture up by half its height
				sprite2d.offset = Vector2(0, -tex_size.y / 2.0)
		return sprite2d
	
	# Fallback to generic player or placeholder
	return create_sprite_node("player", Vector2(32, target_h))

func replace_player_sprite(player_node: Node, context: String = "combat") -> bool:
	## Replace a Player's ColorRect Sprite child with a real sprite if available.
	## Call this from any scene's _ready(). Returns true if sprite was replaced.
	## context: 'combat' / 'after_ch1' (side-scroll) or 'exploration' / 'top_down' (overhead)
	if not player_node or not player_node.has_node("Sprite"):
		return false
	
	var old_sprite = player_node.get_node("Sprite")
	var is_side_scroll = context in ["combat", "after_ch1", "before_ch1"]
	var target_h = 96.0 if is_side_scroll else 64.0
	
	# ── PRIORITY 1: Try animated sprite sheet ──
	var anim_sprite = try_build_animated_player(context)
	if anim_sprite:
		if is_side_scroll:
			anim_sprite.offset = Vector2(0, -target_h / 2.0)
		# Safely replace: remove old, add new at same index
		var _parent = old_sprite.get_parent()
		var _idx = old_sprite.get_index()
		_parent.remove_child(old_sprite)
		old_sprite.queue_free()
		_parent.add_child(anim_sprite)
		_parent.move_child(anim_sprite, _idx)
		print("✓ Player ANIMATED sprite loaded — %s" % context)
		# Notify animation controller if it exists
		if player_node.has_method("_get"):
			var ctrl = player_node.get("_anim_controller")
			if ctrl and ctrl.has_method("on_sprite_replaced"):
				ctrl.on_sprite_replaced()
		return true
	
	# ── PRIORITY 2: Try static sprite ──
	# Determine correct asset key
	var sprite_key = ""
	match context:
		"combat", "after_ch1":
			if is_asset_available("player_after_ch1"):
				sprite_key = "player_after_ch1"
			elif is_asset_available("player"):
				sprite_key = "player"
		"before_ch1":
			if is_asset_available("player_before_ch1"):
				sprite_key = "player_before_ch1"
			elif is_asset_available("player"):
				sprite_key = "player"
		"exploration", "top_down":
			if is_asset_available("player_top_down"):
				sprite_key = "player_top_down"
			elif is_asset_available("player"):
				sprite_key = "player"
	
	if sprite_key == "":
		return false  # No asset available, keep ColorRect placeholder
	
	var tex = get_sprite(sprite_key)
	if not tex:
		return false
	
	var tex_size = tex.get_size()
	if tex_size.x <= 0 or tex_size.y <= 0:
		return false
	
	# Build properly-scaled Sprite2D
	var new_sprite = Sprite2D.new()
	new_sprite.name = "Sprite"
	new_sprite.texture = tex
	new_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	
	# Uniform scale — fit within target size, preserve aspect ratio
	var uniform = target_h / max(tex_size.x, tex_size.y)
	new_sprite.scale = Vector2(uniform, uniform)
	# Player art faces LEFT -- flip so default facing is RIGHT
	new_sprite.flip_h = true
	new_sprite.set_meta("faces_left", true)
	
	if is_side_scroll:
		# Side-scroll: feet at origin — shift texture center up
		new_sprite.offset = Vector2(0, -tex_size.y / 2.0)
	# Top-down: centered on origin (default, offset = 0,0)
	
	# Safely replace the old ColorRect (remove + add at same index)
	var parent = old_sprite.get_parent()
	var idx = old_sprite.get_index()
	parent.remove_child(old_sprite)
	old_sprite.queue_free()
	parent.add_child(new_sprite)
	parent.move_child(new_sprite, idx)
	print("✓ Player sprite loaded (%s) — %s" % [sprite_key, context])
	return true

# =========================================================================
# PORTRAIT SYSTEM — For dialogue boxes
# =========================================================================

# ── Sprite sheet animation definitions ──
# Each entry: { "anim_name": { frames: int, row: int, speed: float, loop: bool } }
# Used when a sprite sheet has multiple rows of animation frames.
# Row 0 = top row, row 1 = second row, etc.
const PLAYER_COMBAT_ANIMS = {
	"idle":    { "frames": 4, "row": 0, "speed": 6.0,  "loop": true },
	"walk":    { "frames": 6, "row": 1, "speed": 10.0, "loop": true },
	"run":     { "frames": 6, "row": 1, "speed": 14.0, "loop": true },
	"jump":    { "frames": 2, "row": 2, "speed": 8.0,  "loop": false },
	"fall":    { "frames": 2, "row": 3, "speed": 8.0,  "loop": false },
	"attack":  { "frames": 4, "row": 4, "speed": 14.0, "loop": false },
	"hurt":    { "frames": 2, "row": 5, "speed": 8.0,  "loop": false },
	"die":     { "frames": 4, "row": 6, "speed": 6.0,  "loop": false },
}

const PLAYER_TOPDOWN_ANIMS = {
	"idle_down":  { "frames": 4, "row": 0, "speed": 6.0,  "loop": true },
	"idle_right": { "frames": 4, "row": 1, "speed": 6.0,  "loop": true },
	"idle_up":    { "frames": 4, "row": 2, "speed": 6.0,  "loop": true },
	"walk_down":  { "frames": 4, "row": 3, "speed": 8.0,  "loop": true },
	"walk_right": { "frames": 4, "row": 4, "speed": 8.0,  "loop": true },
	"walk_up":    { "frames": 4, "row": 5, "speed": 8.0,  "loop": true },
}

func build_animated_sprite_from_sheet(texture: Texture2D, anim_defs: Dictionary, frame_width: int, frame_height: int) -> AnimatedSprite2D:
	## Create an AnimatedSprite2D by slicing a sprite sheet into named animations.
	## texture: The full sprite sheet
	## anim_defs: Dictionary of { anim_name: { frames, row, speed, loop } }
	## frame_width/height: Size of each individual frame in the sheet
	var anim_sprite = AnimatedSprite2D.new()
	var sprite_frames = SpriteFrames.new()
	
	# Remove the default animation
	if sprite_frames.has_animation("default"):
		sprite_frames.remove_animation("default")
	
	var sheet_img = texture.get_image()
	if not sheet_img:
		push_warning("[AssetManager] Cannot get Image from texture for sheet slicing")
		return null
	
	for anim_name in anim_defs:
		var def = anim_defs[anim_name]
		var frame_count: int = def.get("frames", 4)
		var row: int = def.get("row", 0)
		var speed: float = def.get("speed", 8.0)
		var loops: bool = def.get("loop", true)
		
		sprite_frames.add_animation(anim_name)
		sprite_frames.set_animation_speed(anim_name, speed)
		sprite_frames.set_animation_loop(anim_name, loops)
		
		for f in range(frame_count):
			var region = Rect2i(f * frame_width, row * frame_height, frame_width, frame_height)
			# Clamp to texture bounds
			if region.position.x + region.size.x > sheet_img.get_width():
				break
			if region.position.y + region.size.y > sheet_img.get_height():
				break
			
			var frame_img = sheet_img.get_region(region)
			var frame_tex = ImageTexture.create_from_image(frame_img)
			sprite_frames.add_frame(anim_name, frame_tex)
	
	anim_sprite.sprite_frames = sprite_frames
	anim_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	anim_sprite.name = "Sprite"
	
	# Play idle by default
	if sprite_frames.has_animation("idle"):
		anim_sprite.play("idle")
	elif sprite_frames.has_animation("idle_down"):
		anim_sprite.play("idle_down")
	
	return anim_sprite

func try_build_animated_player(context: String) -> AnimatedSprite2D:
	## Try to build an AnimatedSprite2D for the player from sprite sheet.
	## Looks for: assets/sprites/player/player_combat_sheet.png or player_topdown_sheet.png
	## Returns null if no sheet found — caller should fall back to static sprite.
	var sheet_path = ""
	var anim_defs = {}
	var frame_w = 32
	var frame_h = 48
	
	if context in ["combat", "after_ch1", "before_ch1"]:
		sheet_path = "res://assets/sprites/player/player_combat_sheet.png"
		anim_defs = PLAYER_COMBAT_ANIMS
		frame_w = 32
		frame_h = 48
	else:
		sheet_path = "res://assets/sprites/player/player_topdown_sheet.png"
		anim_defs = PLAYER_TOPDOWN_ANIMS
		frame_w = 16
		frame_h = 24
	
	if not FileAccess.file_exists(sheet_path):
		return null
	
	var tex = load(sheet_path)
	if not tex:
		return null
	
	print("✓ Found animation sheet: %s" % sheet_path)
	return build_animated_sprite_from_sheet(tex, anim_defs, frame_w, frame_h)

# Speaker name to portrait asset key mapping
const PORTRAIT_MAP = {
	"Kaelen": "portrait_kaelen",
	"Kaelen (Internal)": "portrait_kaelen_internal",
	"Elara": "portrait_elara",
	"Elara (Glitch-Witch)": "portrait_elara",
	"Mira": "portrait_mira",
	"Mira (Flight Attendant)": "portrait_mira",
	"System": "portrait_system",
	"Data Vision": "portrait_system",
	"???": "portrait_unknown",
	"Tutorial Knight": "portrait_tutorial_knight",
	"Knight": "portrait_tutorial_knight",
	"Elder": "portrait_elder",
	"Seraphina": "portrait_seraphina",
	"Nyx": "portrait_nyx",
	"Gate Guard": "portrait_gate_guard",
	"Farmer Jenkins": "portrait_elder",        # reuse elder until dedicated art
	"Village Child": "portrait_unknown",
	"Village Guard": "portrait_gate_guard",     # reuse guard
	"Shopkeeper": "portrait_unknown",
	"Stewardess": "portrait_mira",             # Mira IS the stewardess
	"Blacksmith Torval": "portrait_gate_guard",
	"Pip": "portrait_nyx",                     # small companion — share Nyx style
	"Marcus": "portrait_unknown",
	"Vex": "portrait_unknown",
	"Crash": "portrait_unknown",
	"Null": "portrait_system",                 # system entity
	"CORRUPTED SENTINEL": "portrait_system",
	"Administrator Proxy": "portrait_system",
	"SOVEREIGN": "portrait_system",
	"Data Wraith": "portrait_system",
	"Clockwork Automaton": "portrait_system",
}

# Fallback: speaker → character sprite key (used if portrait not available)
const PORTRAIT_FALLBACK_TO_CHAR = {
	"Kaelen": "char_kaelen",
	"Kaelen (Internal)": "char_kaelen",
	"Elara": "char_elara",
	"Elara (Glitch-Witch)": "char_elara",
	"Mira": "char_mira",
	"Tutorial Knight": "char_tutorial_knight",
	"Knight": "char_tutorial_knight",
	"Elder": "char_elder",
	"Farmer Jenkins": "char_farmer_jenkins",
	"Seraphina": "char_seraphina",
	"Nyx": "char_nyx",
	"Pip": "char_pip",
	"Gate Guard": "char_gate_guard",
}

func get_portrait_key(speaker: String) -> String:
	## Get the portrait asset key for a speaker name
	if speaker in PORTRAIT_MAP:
		return PORTRAIT_MAP[speaker]
	# Fuzzy match — check if any key is contained in the speaker name
	for key in PORTRAIT_MAP:
		if key in speaker:
			return PORTRAIT_MAP[key]
	return "portrait_unknown"

func get_portrait_texture(speaker: String) -> Texture2D:
	## Get the best available portrait texture for a speaker.
	## Priority: portrait sprite → character sprite → null (use placeholder).
	# 1. Try dedicated portrait asset
	var portrait_key = get_portrait_key(speaker)
	if is_asset_available(portrait_key):
		return get_sprite(portrait_key)
	# 2. Fallback to character sprite (cropped as portrait)
	var char_key = PORTRAIT_FALLBACK_TO_CHAR.get(speaker, "")
	if char_key == "":
		# Fuzzy match
		for key in PORTRAIT_FALLBACK_TO_CHAR:
			if key in speaker:
				char_key = PORTRAIT_FALLBACK_TO_CHAR[key]
				break
	if char_key != "" and is_asset_available(char_key):
		return get_sprite(char_key)
	# 3. Try generic player sprite for Kaelen variants
	if "Kaelen" in speaker:
		for k in ["player_after_ch1", "player_before_ch1", "player"]:
			if is_asset_available(k):
				return get_sprite(k)
	return null

func create_portrait_node(speaker: String, size: Vector2 = Vector2(72, 72)) -> Node:
	## Create portrait TextureRect if asset exists, or ColorRect placeholder
	# Use smart fallback: portrait → character sprite → player sprite
	var tex = get_portrait_texture(speaker)
	
	if tex:
		var tex_rect = TextureRect.new()
		tex_rect.texture = tex
		tex_rect.custom_minimum_size = size
		tex_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		tex_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tex_rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		tex_rect.name = get_portrait_key(speaker) + "_portrait"
		return tex_rect
	else:
		var fallback_key = get_portrait_key(speaker)
		var rect = ColorRect.new()
		rect.custom_minimum_size = size
		rect.color = get_placeholder_color(fallback_key)
		rect.name = fallback_key + "_placeholder"
		# Add a letter initial inside
		var initial = Label.new()
		initial.text = speaker.substr(0, 1).to_upper() if speaker != "???" else "?"
		initial.add_theme_font_size_override("font_size", 28)
		initial.add_theme_color_override("font_color", Color(1, 1, 1, 0.7))
		initial.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		initial.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		initial.set_anchors_preset(Control.PRESET_FULL_RECT)
		initial.mouse_filter = Control.MOUSE_FILTER_IGNORE
		rect.add_child(initial)
		return rect

# =========================================================================
# CHARACTER SPRITE SYSTEM — For cutscene characters
# =========================================================================

# Character name to asset key mapping
const CHARACTER_MAP = {
	"Kaelen": "char_kaelen",
	"Elara": "char_elara",
	"Mira": "char_mira",
	"Tutorial Knight": "char_tutorial_knight",
	"Elder": "char_elder",
	"Farmer Jenkins": "char_farmer_jenkins",
	"Seraphina": "char_seraphina",
	"Nyx": "char_nyx",
	"Pip": "char_pip",
	"Gate Guard": "char_gate_guard",
}

## Mapping of character names to Kenney alien colors for fallback sprites.
## Used when no custom character art is available.
const CHARACTER_KENNEY_FALLBACK = {
	"Kaelen": "blue",
	"Kaelen (Internal)": "blue",
	"Elara": "pink",
	"Mira": "green",
	"Tutorial Knight": "yellow",
	"Elder": "beige",
	"Farmer Jenkins": "beige",
	"Seraphina": "pink",
	"Nyx": "yellow",
	"Pip": "green",
	"Gate Guard": "yellow",
	"Shopkeeper": "beige",
	"Merchant": "beige",
	"Villager": "green",
	"Blacksmith": "yellow",
	"Guard": "yellow",
	"Innkeeper": "beige",
	"Child": "green",
	"Scholar": "pink",
	"Administrator": "yellow",
}

func get_character_key(character_name: String) -> String:
	## Get the character asset key for a character name
	if character_name in CHARACTER_MAP:
		return CHARACTER_MAP[character_name]
	return "char_" + character_name.to_lower().replace(" ", "_")

func create_character_sprite(character_name: String, size: Vector2 = Vector2(128, 192)) -> Node2D:
	## Create cutscene character node — Sprite2D if asset exists, else labeled ColorRect
	var node = Node2D.new()
	node.name = character_name
	
	var asset_key = get_character_key(character_name)
	
	if is_asset_available(asset_key):
		var sprite = Sprite2D.new()
		sprite.texture = get_sprite(asset_key)
		sprite.name = "Sprite"
		sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		# Scale to fit target size, preserving pixel art crispness
		var tex_size = sprite.texture.get_size()
		if tex_size.x > 0 and tex_size.y > 0:
			var uniform = min(size.x / tex_size.x, size.y / tex_size.y)
			sprite.scale = Vector2(uniform, uniform)
		# Offset so character origin is at feet
		sprite.offset = Vector2(0, -sprite.texture.get_height() / 2.0)
		# Kaelen art faces LEFT -- flip so default facing is RIGHT
		if character_name == "Kaelen" or character_name == "Kaelen (Internal)":
			sprite.flip_h = true
			sprite.set_meta("faces_left", true)
		node.add_child(sprite)
	else:
		# Try Kenney alien character sprite as fallback
		var kenney_color := ""
		if character_name in CHARACTER_KENNEY_FALLBACK:
			kenney_color = CHARACTER_KENNEY_FALLBACK[character_name]
		elif character_name.hash() % 5 == 0:
			kenney_color = "blue"
		elif character_name.hash() % 5 == 1:
			kenney_color = "green"
		elif character_name.hash() % 5 == 2:
			kenney_color = "pink"
		elif character_name.hash() % 5 == 3:
			kenney_color = "yellow"
		else:
			kenney_color = "beige"
		
		var kenney_key = "kenney_char_" + kenney_color
		if is_asset_available(kenney_key):
			var sprite = Sprite2D.new()
			sprite.texture = get_sprite(kenney_key)
			sprite.name = "Sprite"
			sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			var tex_size = sprite.texture.get_size()
			if tex_size.x > 0 and tex_size.y > 0:
				var uniform = min(size.x / tex_size.x, size.y / tex_size.y)
				sprite.scale = Vector2(uniform, uniform)
			sprite.offset = Vector2(0, -sprite.texture.get_height() / 2.0)
			node.add_child(sprite)
			# Add character name label above Kenney sprite
			var label = Label.new()
			label.text = character_name
			label.position = Vector2(-size.x / 2, -size.y - 22)
			label.add_theme_font_size_override("font_size", 11)
			label.add_theme_color_override("font_color", Color(1, 1, 1, 0.85))
			label.mouse_filter = Control.MOUSE_FILTER_IGNORE
			node.add_child(label)
		else:
			# Final fallback: colored rect with name label
			var rect = ColorRect.new()
			rect.size = size
			rect.position = Vector2(-size.x / 2, -size.y)
			rect.color = get_placeholder_color(asset_key)
			rect.name = "Sprite"
			rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
			node.add_child(rect)
			
			var label = Label.new()
			label.text = character_name
			label.position = Vector2(-size.x / 2, -size.y - 20)
			label.add_theme_font_size_override("font_size", 11)
			label.add_theme_color_override("font_color", Color(1, 1, 1, 0.8))
			label.mouse_filter = Control.MOUSE_FILTER_IGNORE
			node.add_child(label)
	
	return node

# =========================================================================
# BACKGROUND SYSTEM — For scene environments
# =========================================================================

func create_background_node(bg_key: String, _size: Vector2 = Vector2(1280, 720)) -> Node:
	## Create background TextureRect if asset exists, else ColorRect placeholder
	if is_asset_available(bg_key):
		var tex_rect = TextureRect.new()
		tex_rect.texture = get_sprite(bg_key)
		tex_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
		tex_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		tex_rect.name = bg_key + "_bg"
		tex_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		return tex_rect
	else:
		var rect = ColorRect.new()
		rect.color = get_placeholder_color(bg_key)
		rect.set_anchors_preset(Control.PRESET_FULL_RECT)
		rect.name = bg_key + "_bg_placeholder"
		rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		return rect


# =========================================================================
# KENNEY ANIMATED ENEMY SPRITE SYSTEM
# =========================================================================

## Maps enemy class names to Kenney multi-frame animation sets.
## Each entry: { base_key, states: { state_name: asset_key } }
const KENNEY_ENEMY_ANIMS: Dictionary = {
	"Slime": {
		"base": "kenney_slime_green",
		"idle": "kenney_slime_green",
		"walk": "kenney_slime_green",  # slimes don't have walk
		"hit": "kenney_slime_green",
		"dead": "kenney_slime_green",
	},
	"CorruptedRat": {
		"base": "kenney_mouse",
		"idle": "kenney_mouse",
		"walk": "kenney_mouse_walk",
		"hit": "kenney_mouse_hit",
		"dead": "kenney_mouse_dead",
	},
	"GlitchWolf": {
		"base": "kenney_snake_lava",
		"idle": "kenney_snake_lava",
		"walk": "kenney_snake_lava_walk",
		"hit": "kenney_snake_lava_hit",
		"dead": "kenney_snake_lava_dead",
	},
	"CorruptedGuard": {
		"base": "kenney_spinner",
		"idle": "kenney_spinner",
		"walk": "kenney_spinner_spin",
		"hit": "kenney_spinner_hit",
		"dead": "kenney_spinner_dead",
	},
	"DataSprite": {
		"base": "kenney_bee",
		"idle": "kenney_bee",
		"walk": "kenney_bee_fly",
		"hit": "kenney_bee_hit",
		"dead": "kenney_bee_dead",
	},
	"ClockworkSoldier": {
		"base": "kenney_spider",
		"idle": "kenney_spider",
		"walk": "kenney_spider_walk1",
		"hit": "kenney_spider_hit",
		"dead": "kenney_spider_dead",
	},
	"ShadowWraith": {
		"base": "kenney_ghost",
		"idle": "kenney_ghost",
		"walk": "kenney_ghost_normal",
		"hit": "kenney_ghost_hit",
		"dead": "kenney_ghost_dead",
	},
	"AdministratorEnforcer": {
		"base": "kenney_snake",
		"idle": "kenney_snake",
		"walk": "kenney_snake_walk",
		"hit": "kenney_snake_hit",
		"dead": "kenney_snake_dead",
	},
	"AdministratorProxyBoss": {
		"base": "kenney_bat",
		"idle": "kenney_bat",
		"walk": "kenney_bat_fly",
		"hit": "kenney_bat_hit",
		"dead": "kenney_bat_dead",
	},
	"DataWraithBoss": {
		"base": "kenney_ghost",
		"idle": "kenney_ghost",
		"walk": "kenney_ghost_normal",
		"hit": "kenney_ghost_hit",
		"dead": "kenney_ghost_dead",
	},
	"TutorialKnightBoss": {
		"base": "kenney_snail",
		"idle": "kenney_snail",
		"walk": "kenney_snail_walk",
		"hit": "kenney_snail_hit",
		"dead": "kenney_snail_shell",
	},
	"ClockworkAutomatonBoss": {
		"base": "kenney_spider",
		"idle": "kenney_spider",
		"walk": "kenney_spider_walk1",
		"hit": "kenney_spider_hit",
		"dead": "kenney_spider_dead",
	},
}

func create_kenney_animated_enemy(class_name_str: String, target_size: float = 96.0) -> AnimatedSprite2D:
	## Build an AnimatedSprite2D for an enemy using Kenney individual PNGs.
	## Returns null if no Kenney data available for this class.
	if not KENNEY_ENEMY_ANIMS.has(class_name_str):
		return null
	
	var anim_data: Dictionary = KENNEY_ENEMY_ANIMS[class_name_str]
	var sprite_frames = SpriteFrames.new()
	var any_loaded: bool = false
	
	# Remove default animation
	if sprite_frames.has_animation("default"):
		sprite_frames.remove_animation("default")
	
	for state_name in anim_data:
		if state_name == "base":
			continue
		var asset_key: String = anim_data[state_name]
		var tex: Texture2D = get_sprite(asset_key)
		if not tex:
			continue
		
		sprite_frames.add_animation(state_name)
		sprite_frames.add_frame(state_name, tex)
		
		# Set animation properties
		var fps = 6.0
		var do_loop = (state_name in ["idle", "walk"])
		match state_name:
			"idle": fps = 4.0
			"walk": fps = 8.0
			"hit": fps = 10.0
			"dead": fps = 4.0
		sprite_frames.set_animation_speed(state_name, fps)
		sprite_frames.set_animation_loop(state_name, do_loop)
		any_loaded = true
	
	if not any_loaded:
		return null
	
	var anim_sprite = AnimatedSprite2D.new()
	anim_sprite.sprite_frames = sprite_frames
	anim_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	anim_sprite.name = "Sprite"
	
	# Scale to target size
	var base_key: String = anim_data.get("base", "")
	var base_tex: Texture2D = get_sprite(base_key)
	if base_tex:
		var tex_size = base_tex.get_size()
		if tex_size.x > 0 and tex_size.y > 0:
			var uniform = target_size / maxf(tex_size.x, tex_size.y)
			anim_sprite.scale = Vector2(uniform, uniform)
			anim_sprite.offset = Vector2(0.0, -tex_size.y / 2.0)
	
	if sprite_frames.has_animation("idle"):
		anim_sprite.play("idle")
	
	return anim_sprite

func play_enemy_anim(enemy_node: Node, anim_name: String) -> void:
	## Helper: play a Kenney animation on an enemy's sprite if it's AnimatedSprite2D.
	var sprite = enemy_node.get_node_or_null("Sprite")
	if sprite is AnimatedSprite2D and sprite.sprite_frames.has_animation(anim_name):
		sprite.play(anim_name)

# =========================================================================
# VFX SPRITE SYSTEM — Real VFX using Kenney particle pack
# =========================================================================

## Get a random VFX texture from a category
func get_random_vfx(category: String) -> Texture2D:
	var prefix = "vfx_" + category + "_"
	var available_keys: Array = []
	for key in loaded_assets:
		if key.begins_with(prefix):
			available_keys.append(key)
	if available_keys.is_empty():
		return null
	return loaded_assets[available_keys[randi() % available_keys.size()]]

## Create a VFX sprite node (e.g., for slash, smoke, magic effects)
func create_vfx_sprite(category: String, size: Vector2 = Vector2(64, 64), idx: int = -1) -> Sprite2D:
	var prefix = "vfx_" + category + "_"
	var available_keys: Array = []
	for key in loaded_assets:
		if key.begins_with(prefix):
			available_keys.append(key)
	
	if available_keys.is_empty():
		return null
	
	var key: String
	if idx >= 0 and idx < available_keys.size():
		key = available_keys[idx]
	else:
		key = available_keys[randi() % available_keys.size()]
	
	var sprite = Sprite2D.new()
	sprite.texture = loaded_assets[key]
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.name = "VFX_" + category
	
	var tex_size = sprite.texture.get_size()
	if tex_size.x > 0 and tex_size.y > 0:
		var uniform = min(size.x / tex_size.x, size.y / tex_size.y)
		sprite.scale = Vector2(uniform, uniform)
	
	return sprite

## Create an animated VFX sequence cycling through category textures
func create_vfx_animated(category: String, size: Vector2 = Vector2(64, 64), fps: float = 12.0, do_loop: bool = false) -> AnimatedSprite2D:
	var prefix = "vfx_" + category + "_"
	var textures: Array = []
	# Sort keys to ensure frame order
	var sorted_keys: Array = []
	for key in loaded_assets:
		if key.begins_with(prefix):
			sorted_keys.append(key)
	sorted_keys.sort()
	
	for key in sorted_keys:
		textures.append(loaded_assets[key])
	
	if textures.is_empty():
		return null
	
	var sprite_frames = SpriteFrames.new()
	if sprite_frames.has_animation("default"):
		sprite_frames.remove_animation("default")
	sprite_frames.add_animation("play")
	sprite_frames.set_animation_speed("play", fps)
	sprite_frames.set_animation_loop("play", do_loop)
	
	for tex in textures:
		sprite_frames.add_frame("play", tex)
	
	var anim_sprite = AnimatedSprite2D.new()
	anim_sprite.sprite_frames = sprite_frames
	anim_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	anim_sprite.name = "VFX_" + category
	
	# Scale to target
	var first_tex: Texture2D = textures[0]
	var tex_size = first_tex.get_size()
	if tex_size.x > 0 and tex_size.y > 0:
		var uniform = min(size.x / tex_size.x, size.y / tex_size.y)
		anim_sprite.scale = Vector2(uniform, uniform)
	
	return anim_sprite

## Create a one-shot VFX that auto-removes itself after playing
func spawn_oneshot_vfx(parent: Node, category: String, pos: Vector2, size: Vector2 = Vector2(48, 48), fps: float = 14.0) -> void:
	var vfx = create_vfx_animated(category, size, fps, false)
	if not vfx:
		return
	vfx.global_position = pos
	parent.add_child(vfx)
	vfx.play("play")
	vfx.animation_finished.connect(func(): vfx.queue_free())

# =========================================================================
# ITEM SPRITE HELPER
# =========================================================================

## Map game item IDs to Kenney item asset keys
const ITEM_SPRITE_MAP: Dictionary = {
	"health_potion": "item_potion_red",
	"mana_potion": "item_potion_blue",
	"stamina_potion": "item_potion_green",
	"gold_coin": "item_coin_gold",
	"silver_coin": "item_coin_silver",
	"bronze_coin": "item_coin_bronze",
	"source_key": "item_key",
	"gem_blue": "item_gem_blue",
	"gem_green": "item_gem_green",
	"gem_red": "item_gem_red",
	"gem_yellow": "item_gem_yellow",
	"star_gold": "item_star_gold",
	"star_silver": "item_star_silver",
	"heart": "item_heart",
	"mushroom": "item_mushroom",
	"flag": "item_flag",
}

func get_item_texture(item_id: String) -> Texture2D:
	## Get the Kenney sprite for a game item
	var asset_key: String = ITEM_SPRITE_MAP.get(item_id, "")
	if asset_key != "" and is_asset_available(asset_key):
		return get_sprite(asset_key)
	return null

func create_item_sprite(item_id: String, size: Vector2 = Vector2(32, 32)) -> Sprite2D:
	## Create an item pickup sprite
	var tex = get_item_texture(item_id)
	if not tex:
		return null
	var sprite = Sprite2D.new()
	sprite.texture = tex
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.name = "ItemSprite_" + item_id
	var tex_size = tex.get_size()
	if tex_size.x > 0 and tex_size.y > 0:
		var uniform = min(size.x / tex_size.x, size.y / tex_size.y)
		sprite.scale = Vector2(uniform, uniform)
	return sprite
