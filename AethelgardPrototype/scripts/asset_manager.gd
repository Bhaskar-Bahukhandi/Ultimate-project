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
var _missing_production_art_warned := {}
var _oakhaven_force_generated_fallback := false
var _ironhold_force_generated_fallback := false
var _fractured_wastes_force_generated_fallback := false
var _mirror_city_force_generated_fallback := false

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

const PLAYER_COMBAT_V2_SHEET = "res://assets/generated_v2/sprites/player/kaelen_combat_v2_alpha_sheet.png"
const PLAYER_COMBAT_PRODUCTION_SHEET = "res://assets/production_art/characters/player/kaelen_combat_alpha_sheet.png"
const PLAYER_COMBAT_V2_ANIMS = {
	"idle":          { "frames": 4, "row": 0,  "speed": 6.0,  "loop": true },
	"run":           { "frames": 4, "row": 1,  "speed": 10.0, "loop": true },
	"slash_1":       { "frames": 4, "row": 2,  "speed": 12.5, "loop": false },
	"slash_2":       { "frames": 4, "row": 3,  "speed": 11.4, "loop": false },
	"slash_3":       { "frames": 4, "row": 4,  "speed": 8.5,  "loop": false },
	"charged_slash": { "frames": 4, "row": 5,  "speed": 6.5,  "loop": false },
	"upslash":       { "frames": 4, "row": 6,  "speed": 12.1, "loop": false },
	"downslash":     { "frames": 4, "row": 7,  "speed": 18.0, "loop": false },
	"dash":          { "frames": 4, "row": 8,  "speed": 22.0, "loop": false },
	"cast":          { "frames": 4, "row": 9,  "speed": 10.0, "loop": false },
	"hurt":          { "frames": 4, "row": 10, "speed": 8.0,  "loop": false },
	"death":         { "frames": 4, "row": 11, "speed": 6.0,  "loop": false },
}

const PLAYER_TOPDOWN_ANIMS = {
	"idle_down":  { "frames": 4, "row": 0, "speed": 6.0,  "loop": true },
	"idle_right": { "frames": 4, "row": 1, "speed": 6.0,  "loop": true },
	"idle_up":    { "frames": 4, "row": 2, "speed": 6.0,  "loop": true },
	"walk_down":  { "frames": 4, "row": 3, "speed": 8.0,  "loop": true },
	"walk_right": { "frames": 4, "row": 4, "speed": 8.0,  "loop": true },
	"walk_up":    { "frames": 4, "row": 5, "speed": 8.0,  "loop": true },
}

const PLAYER_TOPDOWN_V2_SHEET = "res://assets/generated_v2/sprites/player/kaelen_topdown_v2_alpha_sheet.png"
const PLAYER_TOPDOWN_PRODUCTION_SHEET = "res://assets/production_art/characters/player/kaelen_topdown_alpha_sheet.png"
const PLAYER_TOPDOWN_V2_ANIMS = {
	# The V2 sheet uses front/back row names; the animation controller already
	# consumes down/up directional names for top-down movement.
	"idle_down":  { "frames": 4, "row": 0, "speed": 4.0, "loop": true },
	"walk_down":  { "frames": 4, "row": 1, "speed": 8.0, "loop": true },
	"idle_up":    { "frames": 4, "row": 2, "speed": 4.0, "loop": true },
	"walk_up":    { "frames": 4, "row": 3, "speed": 8.0, "loop": true },
	"idle_left":  { "frames": 4, "row": 4, "speed": 4.0, "loop": true },
	"walk_left":  { "frames": 4, "row": 5, "speed": 8.0, "loop": true },
	"idle_right": { "frames": 4, "row": 6, "speed": 4.0, "loop": true },
	"walk_right": { "frames": 4, "row": 7, "speed": 8.0, "loop": true },
}

const TUTORIAL_KNIGHT_V2_SHEET = "res://assets/generated_v2/sprites/bosses/tutorial_knight_v2_alpha_sheet.png"
const TUTORIAL_KNIGHT_PRODUCTION_SHEET = "res://assets/production_art/characters/bosses/tutorial_knight_alpha_sheet.png"
const TUTORIAL_KNIGHT_V2_ANIMS = {
	"idle":           { "frames": 4, "row": 0, "speed": 6.0, "loop": true },
	"slash":          { "frames": 4, "row": 1, "speed": 7.0, "loop": false },
	"charge":         { "frames": 4, "row": 2, "speed": 6.0, "loop": false },
	"low_sweep":      { "frames": 4, "row": 3, "speed": 5.0, "loop": false },
	"shield_bash":    { "frames": 4, "row": 4, "speed": 6.0, "loop": false },
	"teleport_slash": { "frames": 4, "row": 5, "speed": 6.0, "loop": false },
	"corrupt_rift":   { "frames": 4, "row": 6, "speed": 5.0, "loop": false },
	"shockwave":      { "frames": 4, "row": 7, "speed": 4.0, "loop": false },
	"phase_change":   { "frames": 4, "row": 8, "speed": 6.0, "loop": false },
	"defeat":         { "frames": 4, "row": 9, "speed": 5.0, "loop": false },
}

const ENEMY_V2_ANIMS = {
	"idle":   { "frames": 4, "row": 0, "speed": 5.0,  "loop": true },
	"move":   { "frames": 4, "row": 1, "speed": 8.0,  "loop": true },
	"attack": { "frames": 4, "row": 2, "speed": 10.0, "loop": false },
	"hurt":   { "frames": 4, "row": 3, "speed": 9.0,  "loop": false },
	"death":  { "frames": 4, "row": 4, "speed": 8.0,  "loop": false },
}

const ENEMY_V2_SHEETS = {
	"Slime": "res://assets/generated_v2/sprites/enemies/fracture_slime_v2_alpha_sheet.png",
	"PhaseSpider": "res://assets/generated_v2/sprites/enemies/clock_mite_v2_alpha_sheet.png",
	"DataSprite": "res://assets/generated_v2/sprites/enemies/memory_wisp_v2_alpha_sheet.png",
}
const ENEMY_PRODUCTION_SHEETS = {
	"Slime": "res://assets/production_art/characters/enemies/fracture_slime_alpha_sheet.png",
	"PhaseSpider": "res://assets/production_art/characters/enemies/clock_mite_alpha_sheet.png",
	"DataSprite": "res://assets/production_art/characters/enemies/memory_wisp_alpha_sheet.png",
}

const NPC_V2_ANIMS = {
	"idle": { "frames": 4, "row": 0, "speed": 4.0, "loop": true },
	"talk": { "frames": 4, "row": 1, "speed": 7.0, "loop": true },
	"walk": { "frames": 4, "row": 2, "speed": 8.0, "loop": true },
}

const NPC_V2_SHEETS = {
	"Elara": "res://assets/generated_v2/sprites/npcs/elara_v2_alpha_sheet.png",
	"Seraphina": "res://assets/generated_v2/sprites/npcs/seraphina_v2_alpha_sheet.png",
	"Lyra": "res://assets/generated_v2/sprites/npcs/lyra_v2_alpha_sheet.png",
	"Null Clerk": "res://assets/generated_v2/sprites/npcs/null_clerk_v2_alpha_sheet.png",
	"Assembly Runner": "res://assets/generated_v2/sprites/npcs/assembly_runner_v2_alpha_sheet.png",
}
const NPC_PRODUCTION_SHEETS = {
	"Elara": "res://assets/production_art/characters/npcs/elara_alpha_sheet.png",
	"Seraphina": "res://assets/production_art/characters/npcs/seraphina_alpha_sheet.png",
	"Lyra": "res://assets/production_art/characters/npcs/lyra_alpha_sheet.png",
	"Null Clerk": "res://assets/production_art/characters/npcs/null_clerk_alpha_sheet.png",
	"Assembly Runner": "res://assets/production_art/characters/npcs/assembly_runner_alpha_sheet.png",
}

const V2_PROTOTYPE_TILESETS = {
	"oakhaven": "res://assets/generated_v2/tilesets/oakhaven_v2_prototype_tileset.png",
	"ironhold": "res://assets/generated_v2/tilesets/ironhold_v2_prototype_tileset.png",
	"fractured_wastes": "res://assets/generated_v2/tilesets/fractured_wastes_v2_prototype_tileset.png",
	"forgotten_sectors": "res://assets/generated_v2/tilesets/forgotten_sectors_v2_prototype_tileset.png",
	"mirror_city": "res://assets/generated_v2/tilesets/mirror_city_v2_prototype_tileset.png",
	"cathedral_server": "res://assets/generated_v2/tilesets/cathedral_server_v2_prototype_tileset.png",
	"memory_ocean": "res://assets/generated_v2/tilesets/memory_ocean_v2_prototype_tileset.png",
	"root_of_heaven": "res://assets/generated_v2/tilesets/root_of_heaven_v2_prototype_tileset.png",
}
const PRODUCTION_VISUAL_TILESETS = {
	"oakhaven": "res://assets/production_art/tilesets/oakhaven/oakhaven_afternoon_tileset.png",
	"ironhold": "res://assets/production_art/tilesets/ironhold/ironhold_tileset.png",
	"fractured_wastes": "res://assets/production_art/tilesets/fractured_wastes/fractured_wastes_tileset.png",
	"forgotten_sectors": "res://assets/production_art/tilesets/forgotten_sectors_tileset.png",
	"mirror_city": "res://assets/production_art/tilesets/mirror_city/mirror_city_tileset.png",
	"cathedral_server": "res://assets/production_art/tilesets/cathedral_server_tileset.png",
	"memory_ocean": "res://assets/production_art/tilesets/memory_ocean_tileset.png",
	"saved_assembly": "res://assets/production_art/tilesets/saved_assembly_tileset.png",
	"human_patch_lab": "res://assets/production_art/tilesets/human_patch_lab_tileset.png",
	"root_of_heaven": "res://assets/production_art/tilesets/root_of_heaven_tileset.png",
}
const IRONHOLD_PRODUCTION_TILESET = "res://assets/production_art/tilesets/ironhold/ironhold_tileset.png"
const FRACTURED_WASTES_PRODUCTION_TILESET = "res://assets/production_art/tilesets/fractured_wastes/fractured_wastes_tileset.png"
const OAKHAVEN_PRODUCTION_TIME_OF_DAY_ENABLED = true
const OAKHAVEN_DEFAULT_TIME_STATE = "afternoon"
const OAKHAVEN_PRODUCTION_TIME_TILESETS = {
	"morning": "res://assets/production_art/tilesets/oakhaven/oakhaven_morning_tileset.png",
	"afternoon": "res://assets/production_art/tilesets/oakhaven/oakhaven_afternoon_tileset.png",
	"night": "res://assets/production_art/tilesets/oakhaven/oakhaven_night_tileset.png",
}
const V2_PROTOTYPE_TILE_SIZE = Vector2i(32, 32)

const V3_ENVIRONMENT_PROP_ATLAS = "res://assets/generated_v3/props/phase10mm_environment_prop_atlas.png"
const V3_ENVIRONMENT_DECAL_ATLAS = "res://assets/generated_v3/overlays/phase10mm_environment_decal_atlas.png"
const PRODUCTION_ENVIRONMENT_PROP_ATLAS = "res://assets/production_art/props/environment_prop_atlas.png"
const PRODUCTION_ENVIRONMENT_DECAL_ATLAS = "res://assets/production_art/backgrounds/environment_decal_atlas.png"
const V3_ENVIRONMENT_PROP_REGIONS = {
	"oakhaven_roof": Rect2i(32, 22, 248, 190),
	"oakhaven_hedge_corner": Rect2i(760, 52, 390, 176),
	"oakhaven_flowers": Rect2i(30, 264, 418, 82),
	"oakhaven_herb_sign": Rect2i(478, 238, 128, 126),
	"ironhold_pipes": Rect2i(616, 238, 544, 170),
	"ironhold_forge": Rect2i(1320, 226, 164, 194),
	"crates": Rect2i(40, 434, 540, 144),
	"archive_shelves": Rect2i(620, 370, 356, 218),
	"dossier_stack": Rect2i(988, 440, 94, 128),
	"null_seal": Rect2i(1092, 432, 156, 176),
	"mirror_plinth": Rect2i(1280, 430, 202, 192),
	"server_console": Rect2i(36, 612, 376, 194),
	"firewall_panel": Rect2i(430, 612, 358, 194),
	"tide_buoy": Rect2i(824, 610, 120, 182),
	"salvage_shelf": Rect2i(974, 610, 290, 198),
	"ocean_cache": Rect2i(1268, 610, 236, 198),
	"lab_console": Rect2i(34, 818, 248, 178),
	"memory_tank": Rect2i(292, 814, 170, 186),
	"root_circuit_rail": Rect2i(628, 816, 844, 190),
}
const V3_ENVIRONMENT_DECAL_REGIONS = {
	"oakhaven_path": Rect2i(18, 10, 630, 198),
	"oakhaven_stones": Rect2i(22, 228, 650, 128),
	"ironhold_road": Rect2i(676, 16, 820, 224),
	"fracture_field": Rect2i(18, 360, 500, 294),
	"shard_spill": Rect2i(270, 350, 246, 298),
	"archive_seals": Rect2i(520, 362, 382, 292),
	"mirror_ripples": Rect2i(900, 246, 602, 280),
	"cathedral_circuit": Rect2i(900, 510, 600, 240),
	"memory_tide": Rect2i(14, 674, 476, 326),
	"root_veins": Rect2i(492, 680, 406, 320),
	"arena_border": Rect2i(898, 754, 620, 252),
}

func build_animated_sprite_from_sheet(texture: Texture2D, anim_defs: Dictionary, frame_width: int, frame_height: int) -> AnimatedSprite2D:
	## Create an AnimatedSprite2D by slicing a sprite sheet into named animations.
	## texture: The full sprite sheet
	## anim_defs: Dictionary of { anim_name: { frames, row, speed, loop } }
	## frame_width/height: Size of each individual frame in the sheet
	var sheet_img = texture.get_image()
	if not sheet_img:
		push_warning("[AssetManager] Cannot get Image from texture for sheet slicing")
		return null

	var anim_sprite = AnimatedSprite2D.new()
	var sprite_frames = SpriteFrames.new()

	# Remove the default animation
	if sprite_frames.has_animation("default"):
		sprite_frames.remove_animation("default")

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
		var combat_sheet_slot = _resolve_visual_texture_slot(PLAYER_COMBAT_PRODUCTION_SHEET, PLAYER_COMBAT_V2_SHEET, "Kaelen combat sheet")
		var combat_sheet_path: String = combat_sheet_slot.get("path", PLAYER_COMBAT_V2_SHEET)
		if _visual_path_exists(combat_sheet_path):
			var v2_tex = combat_sheet_slot.get("texture") as Texture2D
			if v2_tex:
				print("✓ Found combat animation sheet: %s" % combat_sheet_path)
				return build_animated_sprite_from_sheet(v2_tex, PLAYER_COMBAT_V2_ANIMS, 64, 64)
			push_warning("[AssetManager] V2 combat player sheet failed to load; using existing player fallback.")
		else:
			push_warning("[AssetManager] V2 combat player sheet missing; using existing player fallback.")
		sheet_path = "res://assets/sprites/player/player_combat_sheet.png"
		anim_defs = PLAYER_COMBAT_ANIMS
		frame_w = 32
		frame_h = 48
	else:
		var topdown_sheet_slot = _resolve_visual_texture_slot(PLAYER_TOPDOWN_PRODUCTION_SHEET, PLAYER_TOPDOWN_V2_SHEET, "Kaelen top-down sheet")
		var topdown_sheet_path: String = topdown_sheet_slot.get("path", PLAYER_TOPDOWN_V2_SHEET)
		if _visual_path_exists(topdown_sheet_path):
			var v2_tex = topdown_sheet_slot.get("texture") as Texture2D
			if v2_tex:
				print("✓ Found top-down animation sheet: %s" % topdown_sheet_path)
				return build_animated_sprite_from_sheet(v2_tex, PLAYER_TOPDOWN_V2_ANIMS, 32, 32)
			push_warning("[AssetManager] V2 top-down player sheet failed to load; using existing player fallback.")
		else:
			push_warning("[AssetManager] V2 top-down player sheet missing; using existing player fallback.")
		sheet_path = "res://assets/sprites/player/player_topdown_sheet.png"
		anim_defs = PLAYER_TOPDOWN_ANIMS
		frame_w = 16
		frame_h = 24
	
	# ResourceLoader, not FileAccess: exported builds have no source .png files.
	if not ResourceLoader.exists(sheet_path):
		return null

	var tex = load(sheet_path)
	if not tex:
		return null
	
	print("✓ Found animation sheet: %s" % sheet_path)
	return build_animated_sprite_from_sheet(tex, anim_defs, frame_w, frame_h)

func try_build_animated_tutorial_knight() -> AnimatedSprite2D:
	## Prefer the V2 Tutorial Knight sheet for the Chapter 1 boss only.
	var sheet_slot = _resolve_visual_texture_slot(TUTORIAL_KNIGHT_PRODUCTION_SHEET, TUTORIAL_KNIGHT_V2_SHEET, "Tutorial Knight sheet")
	var sheet_path: String = sheet_slot.get("path", TUTORIAL_KNIGHT_V2_SHEET)
	var texture = sheet_slot.get("texture") as Texture2D
	if not texture:
		push_warning("[AssetManager] Tutorial Knight sheet failed to load; using existing boss fallback.")
		return null
	print("Found Tutorial Knight animation sheet: %s" % sheet_path)
	var anim_sprite = build_animated_sprite_from_sheet(texture, TUTORIAL_KNIGHT_V2_ANIMS, 96, 96)
	if anim_sprite:
		anim_sprite.set_meta("tutorial_knight_v2_visual", true)
	return anim_sprite

func try_build_v2_enemy(class_name_str: String, target_size: float = 72.0) -> AnimatedSprite2D:
	if not ENEMY_V2_SHEETS.has(class_name_str):
		return null
	var sheet_slot = _resolve_visual_texture_slot(
		ENEMY_PRODUCTION_SHEETS.get(class_name_str, ""),
		ENEMY_V2_SHEETS[class_name_str],
		"%s enemy sheet" % class_name_str
	)
	var sheet_path: String = sheet_slot.get("path", ENEMY_V2_SHEETS[class_name_str])
	var texture = sheet_slot.get("texture") as Texture2D
	if not texture:
		push_warning("[AssetManager] Enemy sheet failed to load for %s; using existing enemy fallback." % class_name_str)
		return null
	var anim_sprite = build_animated_sprite_from_sheet(texture, ENEMY_V2_ANIMS, 48, 48)
	if not anim_sprite:
		return null
	var uniform = target_size / 48.0 if target_size > 0.0 else 1.0
	anim_sprite.scale = Vector2(uniform, uniform)
	anim_sprite.offset = Vector2(0.0, -24.0)
	anim_sprite.set_meta("enemy_v2_visual", true)
	anim_sprite.set_meta("enemy_v2_sheet", sheet_path)
	return anim_sprite

func try_build_v2_npc(npc_name: String, target_size: float = 32.0) -> AnimatedSprite2D:
	if not NPC_V2_SHEETS.has(npc_name):
		return null
	var sheet_slot = _resolve_visual_texture_slot(
		NPC_PRODUCTION_SHEETS.get(npc_name, ""),
		NPC_V2_SHEETS[npc_name],
		"%s NPC sheet" % npc_name
	)
	var sheet_path: String = sheet_slot.get("path", NPC_V2_SHEETS[npc_name])
	var texture = sheet_slot.get("texture") as Texture2D
	if not texture:
		push_warning("[AssetManager] NPC sheet failed to load for %s; using existing NPC fallback." % npc_name)
		return null
	var anim_sprite = build_animated_sprite_from_sheet(texture, NPC_V2_ANIMS, 32, 32)
	if not anim_sprite:
		return null
	var uniform = target_size / 32.0 if target_size > 0.0 else 1.0
	anim_sprite.scale = Vector2(uniform, uniform)
	anim_sprite.offset = Vector2(0.0, -16.0)
	anim_sprite.set_meta("npc_v2_visual", true)
	anim_sprite.set_meta("npc_v2_sheet", sheet_path)
	return anim_sprite

func create_topdown_npc_visual(npc_name: String, fallback_color: Color, fallback_size: Vector2 = Vector2(16, 22), target_size: float = 32.0) -> CanvasItem:
	var anim_sprite = try_build_v2_npc(npc_name, target_size)
	if anim_sprite:
		return anim_sprite
	var rect = ColorRect.new()
	rect.name = "Sprite"
	rect.color = fallback_color
	rect.size = fallback_size
	rect.position = Vector2(-fallback_size.x / 2.0, -fallback_size.y)
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return rect

func play_v2_npc_anim(npc_node: Node, anim_name: String) -> void:
	if not npc_node:
		return
	var sprite = npc_node.get_node_or_null("Sprite")
	if sprite is AnimatedSprite2D and sprite.get_meta("npc_v2_visual", false):
		if sprite.sprite_frames and sprite.sprite_frames.has_animation(anim_name):
			if sprite.animation != anim_name:
				sprite.play(anim_name)

func _resolve_visual_texture_slot(production_path: String, fallback_path: String, slot_label: String) -> Dictionary:
	if _visual_path_exists(production_path):
		var production_texture = _load_visual_texture_path(production_path)
		if production_texture:
			return {"texture": production_texture, "path": production_path, "production": true}
		push_warning("[AssetManager] Production art failed to load for %s at %s; using generated fallback %s." % [slot_label, production_path, fallback_path])
	else:
		_warn_missing_production_art(production_path, fallback_path, slot_label)
	return {"texture": _load_visual_texture_path(fallback_path), "path": fallback_path, "production": false}

func _visual_path_exists(path: String) -> bool:
	return not path.is_empty() and (FileAccess.file_exists(path) or ResourceLoader.exists(path))

func _load_visual_texture_path(path: String) -> Texture2D:
	if not _visual_path_exists(path):
		return null
	var texture: Texture2D = null
	if ResourceLoader.exists(path):
		texture = load(path) as Texture2D
	if texture:
		return texture
	var image = Image.load_from_file(ProjectSettings.globalize_path(path))
	if image and not image.is_empty():
		return ImageTexture.create_from_image(image)
	return null

func _warn_missing_production_art(production_path: String, fallback_path: String, slot_label: String) -> void:
	if _missing_production_art_warned.has(production_path):
		return
	_missing_production_art_warned[production_path] = true
	push_warning("[AssetManager] Production art slot missing for %s at %s; using generated fallback %s." % [slot_label, production_path, fallback_path])

func get_oakhaven_tileset(time_state: String = OAKHAVEN_DEFAULT_TIME_STATE) -> Texture2D:
	var slot = get_oakhaven_tileset_slot(time_state)
	return slot.get("texture") as Texture2D

func set_oakhaven_force_generated_fallback(enabled: bool) -> void:
	_oakhaven_force_generated_fallback = enabled

func is_oakhaven_force_generated_fallback() -> bool:
	return _oakhaven_force_generated_fallback

func get_oakhaven_tileset_slot(time_state: String = OAKHAVEN_DEFAULT_TIME_STATE) -> Dictionary:
	var requested_time_state := str(time_state).strip_edges().to_lower()
	if requested_time_state.is_empty():
		requested_time_state = OAKHAVEN_DEFAULT_TIME_STATE
	var resolved_time_state := _normalize_oakhaven_time_state(requested_time_state)
	var invalid_time_state := requested_time_state != resolved_time_state
	var fallback_path: String = V2_PROTOTYPE_TILESETS.get("oakhaven", "")
	if _oakhaven_force_generated_fallback:
		return _oakhaven_generated_fallback_slot(fallback_path, requested_time_state, resolved_time_state, "runtime fallback override enabled")
	if not OAKHAVEN_PRODUCTION_TIME_OF_DAY_ENABLED:
		return _oakhaven_generated_fallback_slot(fallback_path, requested_time_state, resolved_time_state, "production time-of-day loading disabled")

	var production_path: String = OAKHAVEN_PRODUCTION_TIME_TILESETS.get(resolved_time_state, "")
	var production_texture = _try_load_oakhaven_production_variant(production_path, requested_time_state, resolved_time_state)
	if production_texture:
		if invalid_time_state:
			_warn_invalid_oakhaven_time_state(requested_time_state, resolved_time_state)
		return {
			"texture": production_texture,
			"path": production_path,
			"production": true,
			"requested_time_state": requested_time_state,
			"time_state": resolved_time_state,
			"fallback_used": invalid_time_state,
			"fallback_reason": "invalid time state normalized to default" if invalid_time_state else "",
		}

	if resolved_time_state != OAKHAVEN_DEFAULT_TIME_STATE:
		var default_path: String = OAKHAVEN_PRODUCTION_TIME_TILESETS.get(OAKHAVEN_DEFAULT_TIME_STATE, "")
		var default_texture = _try_load_oakhaven_production_variant(default_path, requested_time_state, OAKHAVEN_DEFAULT_TIME_STATE)
		if default_texture:
			_warn_oakhaven_variant_fallback(production_path, default_path, requested_time_state, OAKHAVEN_DEFAULT_TIME_STATE)
			return {
				"texture": default_texture,
				"path": default_path,
				"production": true,
				"requested_time_state": requested_time_state,
				"time_state": OAKHAVEN_DEFAULT_TIME_STATE,
				"fallback_used": true,
				"fallback_reason": "requested production variant missing or invalid",
			}

	return _oakhaven_generated_fallback_slot(fallback_path, requested_time_state, resolved_time_state, "production variant missing or invalid")

func _normalize_oakhaven_time_state(time_state: String) -> String:
	if OAKHAVEN_PRODUCTION_TIME_TILESETS.has(time_state):
		return time_state
	return OAKHAVEN_DEFAULT_TIME_STATE

func _try_load_oakhaven_production_variant(production_path: String, requested_time_state: String, resolved_time_state: String) -> Texture2D:
	if production_path.is_empty():
		return null
	if not _visual_path_exists(production_path):
		_warn_missing_oakhaven_variant(production_path, requested_time_state, resolved_time_state)
		return null
	var texture = _load_visual_texture_path(production_path)
	if texture:
		return texture
	push_warning("[AssetManager] Oakhaven %s production tileset failed to load at %s; requested=%s." % [resolved_time_state, production_path, requested_time_state])
	return null

func _oakhaven_generated_fallback_slot(fallback_path: String, requested_time_state: String, resolved_time_state: String, reason: String) -> Dictionary:
	push_warning("[AssetManager] Oakhaven production tileset fallback: %s; requested=%s resolved=%s generated=%s." % [reason, requested_time_state, resolved_time_state, fallback_path])
	return {
		"texture": _load_visual_texture_path(fallback_path),
		"path": fallback_path,
		"production": false,
		"requested_time_state": requested_time_state,
		"time_state": resolved_time_state,
		"fallback_used": true,
		"fallback_reason": reason,
	}

func _warn_missing_oakhaven_variant(production_path: String, requested_time_state: String, resolved_time_state: String) -> void:
	var warning_key := "oakhaven:%s:%s" % [resolved_time_state, production_path]
	if _missing_production_art_warned.has(warning_key):
		return
	_missing_production_art_warned[warning_key] = true
	push_warning("[AssetManager] Oakhaven %s production tileset missing at %s; requested=%s." % [resolved_time_state, production_path, requested_time_state])

func _warn_oakhaven_variant_fallback(missing_path: String, fallback_path: String, requested_time_state: String, fallback_time_state: String) -> void:
	var warning_key := "oakhaven_variant_fallback:%s:%s" % [requested_time_state, missing_path]
	if _missing_production_art_warned.has(warning_key):
		return
	_missing_production_art_warned[warning_key] = true
	push_warning("[AssetManager] Oakhaven requested production variant %s unavailable at %s; using %s production tileset %s." % [requested_time_state, missing_path, fallback_time_state, fallback_path])

func _warn_invalid_oakhaven_time_state(requested_time_state: String, fallback_time_state: String) -> void:
	var warning_key := "oakhaven_invalid_time_state:%s" % requested_time_state
	if _missing_production_art_warned.has(warning_key):
		return
	_missing_production_art_warned[warning_key] = true
	push_warning("[AssetManager] Invalid Oakhaven time state %s; using %s production tileset." % [requested_time_state, fallback_time_state])

func get_ironhold_tileset() -> Texture2D:
	var slot = get_ironhold_tileset_slot()
	return slot.get("texture") as Texture2D

func set_ironhold_force_generated_fallback(enabled: bool) -> void:
	_ironhold_force_generated_fallback = enabled

func is_ironhold_force_generated_fallback() -> bool:
	return _ironhold_force_generated_fallback

func get_ironhold_tileset_slot() -> Dictionary:
	var fallback_path: String = V2_PROTOTYPE_TILESETS.get("ironhold", "")
	var production_path: String = PRODUCTION_VISUAL_TILESETS.get("ironhold", IRONHOLD_PRODUCTION_TILESET)
	if _ironhold_force_generated_fallback:
		return _ironhold_generated_fallback_slot(fallback_path, "runtime fallback override enabled")

	var production_texture = _try_load_ironhold_production_tileset(production_path)
	if production_texture:
		return {
			"texture": production_texture,
			"path": production_path,
			"production": true,
			"region_id": "ironhold",
			"fallback_used": false,
			"fallback_reason": "",
		}

	return _ironhold_generated_fallback_slot(fallback_path, "production tileset missing or invalid")

func _try_load_ironhold_production_tileset(production_path: String) -> Texture2D:
	var fallback_path: String = V2_PROTOTYPE_TILESETS.get("ironhold", "")
	if production_path.is_empty():
		_warn_missing_production_art(production_path, fallback_path, "ironhold production tileset")
		return null
	if not _visual_path_exists(production_path):
		_warn_missing_production_art(production_path, fallback_path, "ironhold production tileset")
		return null
	var texture = _load_visual_texture_path(production_path)
	if texture:
		return texture
	push_warning("[AssetManager] Ironhold production tileset failed to load at %s; using generated fallback %s." % [production_path, fallback_path])
	return null

func _ironhold_generated_fallback_slot(fallback_path: String, reason: String) -> Dictionary:
	push_warning("[AssetManager] Ironhold production tileset fallback: %s; generated=%s." % [reason, fallback_path])
	return {
		"texture": _load_visual_texture_path(fallback_path),
		"path": fallback_path,
		"production": false,
		"region_id": "ironhold",
		"fallback_used": true,
		"fallback_reason": reason,
	}

func get_fractured_wastes_tileset() -> Texture2D:
	var slot = get_fractured_wastes_tileset_slot()
	return slot.get("texture") as Texture2D

func set_fractured_wastes_force_generated_fallback(enabled: bool) -> void:
	_fractured_wastes_force_generated_fallback = enabled

func is_fractured_wastes_force_generated_fallback() -> bool:
	return _fractured_wastes_force_generated_fallback

func get_fractured_wastes_tileset_slot() -> Dictionary:
	var fallback_path: String = V2_PROTOTYPE_TILESETS.get("fractured_wastes", "")
	var production_path: String = PRODUCTION_VISUAL_TILESETS.get("fractured_wastes", FRACTURED_WASTES_PRODUCTION_TILESET)
	if _fractured_wastes_force_generated_fallback:
		return _fractured_wastes_generated_fallback_slot(fallback_path, "runtime fallback override enabled")

	var production_texture = _try_load_fractured_wastes_production_tileset(production_path)
	if production_texture:
		return {
			"texture": production_texture,
			"path": production_path,
			"production": true,
			"region_id": "fractured_wastes",
			"fallback_used": false,
			"fallback_reason": "",
		}

	return _fractured_wastes_generated_fallback_slot(fallback_path, "production tileset missing or invalid")

func _try_load_fractured_wastes_production_tileset(production_path: String) -> Texture2D:
	var fallback_path: String = V2_PROTOTYPE_TILESETS.get("fractured_wastes", "")
	if production_path.is_empty():
		_warn_missing_production_art(production_path, fallback_path, "Fractured Wastes production tileset")
		return null
	if not _visual_path_exists(production_path):
		_warn_missing_production_art(production_path, fallback_path, "Fractured Wastes production tileset")
		return null
	var texture = _load_visual_texture_path(production_path)
	if texture:
		return texture
	push_warning("[AssetManager] Fractured Wastes production tileset failed to load at %s; using generated fallback %s." % [production_path, fallback_path])
	return null

func _fractured_wastes_generated_fallback_slot(fallback_path: String, reason: String) -> Dictionary:
	push_warning("[AssetManager] Fractured Wastes production tileset fallback: %s; generated=%s." % [reason, fallback_path])
	return {
		"texture": _load_visual_texture_path(fallback_path),
		"path": fallback_path,
		"production": false,
		"region_id": "fractured_wastes",
		"fallback_used": true,
		"fallback_reason": reason,
	}


func get_mirror_city_tileset() -> Texture2D:
	var slot = get_mirror_city_tileset_slot()
	return slot.get("texture") as Texture2D

func set_mirror_city_force_generated_fallback(enabled: bool) -> void:
	_mirror_city_force_generated_fallback = enabled

func is_mirror_city_force_generated_fallback() -> bool:
	return _mirror_city_force_generated_fallback

func get_mirror_city_tileset_slot(production_path_override: String = "") -> Dictionary:
	var fallback_path: String = V2_PROTOTYPE_TILESETS.get("mirror_city", "")
	var production_path: String = production_path_override
	if production_path.is_empty():
		production_path = PRODUCTION_VISUAL_TILESETS.get("mirror_city", "")
	if _mirror_city_force_generated_fallback:
		return _mirror_city_generated_fallback_slot(fallback_path, "runtime fallback override enabled")

	var tileset_slot = _resolve_visual_texture_slot(production_path, fallback_path, "Mirror City production tileset")
	var texture = tileset_slot.get("texture") as Texture2D
	if texture and bool(tileset_slot.get("production", false)):
		return {
			"texture": texture,
			"path": tileset_slot.get("path", production_path),
			"production": true,
			"region_id": "mirror_city",
			"fallback_used": false,
			"fallback_reason": "",
		}
	return _mirror_city_generated_fallback_slot(fallback_path, "production tileset missing or invalid")

func _mirror_city_generated_fallback_slot(fallback_path: String, reason: String) -> Dictionary:
	push_warning("[AssetManager] Mirror City production tileset fallback: %s; generated=%s." % [reason, fallback_path])
	return {
		"texture": _load_visual_texture_path(fallback_path),
		"path": fallback_path,
		"production": false,
		"region_id": "mirror_city",
		"fallback_used": true,
		"fallback_reason": reason,
	}

func try_create_v2_visual_tile_layer(tileset_id: String, area_size: Vector2, layer_name: String, layer_z_index: int, tile_choices: Array = [], time_state: String = OAKHAVEN_DEFAULT_TIME_STATE) -> TileMapLayer:
	## Build a visual-only prototype tile layer; existing environment collisions stay authoritative.
	var tileset_slot = _try_resolve_v2_prototype_tileset_slot(tileset_id, time_state)
	var texture = tileset_slot.get("texture") as Texture2D
	if not texture:
		return null

	var atlas_source = TileSetAtlasSource.new()
	atlas_source.texture = texture
	atlas_source.texture_region_size = V2_PROTOTYPE_TILE_SIZE
	var atlas_size = Vector2i(
		int(texture.get_width() / V2_PROTOTYPE_TILE_SIZE.x),
		int(texture.get_height() / V2_PROTOTYPE_TILE_SIZE.y)
	)
	if atlas_size.x <= 0 or atlas_size.y <= 0:
		push_warning("[AssetManager] V2 tileset geometry is invalid for %s; using existing environment fallback." % tileset_id)
		return null
	for atlas_y in range(atlas_size.y):
		for atlas_x in range(atlas_size.x):
			atlas_source.create_tile(Vector2i(atlas_x, atlas_y))

	var tile_set = TileSet.new()
	tile_set.tile_size = V2_PROTOTYPE_TILE_SIZE
	var source_id = tile_set.add_source(atlas_source)
	var visual_layer = TileMapLayer.new()
	visual_layer.name = layer_name
	visual_layer.tile_set = tile_set
	visual_layer.z_index = layer_z_index
	visual_layer.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	visual_layer.set_meta("v2_visual_tileset", tileset_id)
	visual_layer.set_meta("visual_only", true)
	visual_layer.set_meta("visual_tileset_path", tileset_slot.get("path", ""))
	visual_layer.set_meta("visual_tileset_production", bool(tileset_slot.get("production", false)))
	if tileset_id == "oakhaven":
		visual_layer.set_meta("oakhaven_time_state", tileset_slot.get("time_state", OAKHAVEN_DEFAULT_TIME_STATE))
		visual_layer.set_meta("oakhaven_requested_time_state", tileset_slot.get("requested_time_state", time_state))

	var fill_choices: Array[Vector2i] = []
	for tile_choice in tile_choices:
		if tile_choice is Vector2i and _atlas_has_tile(atlas_size, tile_choice):
			fill_choices.append(tile_choice)
	if fill_choices.is_empty():
		for atlas_y in range(atlas_size.y):
			for atlas_x in range(atlas_size.x):
				fill_choices.append(Vector2i(atlas_x, atlas_y))

	var cell_columns = int(ceil(area_size.x / float(V2_PROTOTYPE_TILE_SIZE.x)))
	var cell_rows = int(ceil(area_size.y / float(V2_PROTOTYPE_TILE_SIZE.y)))
	for cell_y in range(cell_rows):
		for cell_x in range(cell_columns):
			var choice_index = posmod(cell_x * 17 + cell_y * 31 + cell_x * cell_y * 3, fill_choices.size())
			visual_layer.set_cell(Vector2i(cell_x, cell_y), source_id, fill_choices[choice_index])
	return visual_layer

func try_create_v2_control_tileset_background(tileset_id: String, background_name: String, time_state: String = OAKHAVEN_DEFAULT_TIME_STATE) -> TextureRect:
	## Repeat a prototype tileset sheet as a non-interactive Control background.
	var tileset_slot = _try_resolve_v2_prototype_tileset_slot(tileset_id, time_state)
	var texture = tileset_slot.get("texture") as Texture2D
	if not texture:
		return null
	var background = TextureRect.new()
	background.name = background_name
	background.texture = texture
	background.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	background.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	background.stretch_mode = TextureRect.STRETCH_TILE
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	background.set_meta("v2_visual_tileset", tileset_id)
	background.set_meta("visual_only", true)
	background.set_meta("visual_tileset_path", tileset_slot.get("path", ""))
	background.set_meta("visual_tileset_production", bool(tileset_slot.get("production", false)))
	if tileset_id == "oakhaven":
		background.set_meta("oakhaven_time_state", tileset_slot.get("time_state", OAKHAVEN_DEFAULT_TIME_STATE))
		background.set_meta("oakhaven_requested_time_state", tileset_slot.get("requested_time_state", time_state))
	return background

func add_v3_environment_prop(parent: Node, prop_id: String, pos: Vector2, target_size: Vector2, node_name: String, layer_z_index: int, tint: Color = Color.WHITE) -> Sprite2D:
	var prop = try_create_v3_environment_prop(prop_id, target_size, node_name, layer_z_index)
	if not prop or not parent:
		return null
	prop.position = pos
	prop.modulate = tint
	parent.add_child(prop)
	return prop

func add_v3_environment_decal(parent: Node, decal_id: String, pos: Vector2, target_size: Vector2, node_name: String, layer_z_index: int, tint: Color = Color.WHITE) -> Sprite2D:
	var decal = try_create_v3_environment_decal(decal_id, target_size, node_name, layer_z_index)
	if not decal or not parent:
		return null
	decal.position = pos
	decal.modulate = tint
	parent.add_child(decal)
	return decal

func try_create_v3_environment_prop(prop_id: String, target_size: Vector2, node_name: String, layer_z_index: int) -> Sprite2D:
	var atlas_slot = _resolve_visual_texture_slot(PRODUCTION_ENVIRONMENT_PROP_ATLAS, V3_ENVIRONMENT_PROP_ATLAS, "environment prop atlas")
	return _try_create_v3_atlas_visual(
		atlas_slot.get("path", V3_ENVIRONMENT_PROP_ATLAS),
		V3_ENVIRONMENT_PROP_REGIONS,
		prop_id,
		target_size,
		node_name,
		layer_z_index
	)

func try_create_v3_environment_decal(decal_id: String, target_size: Vector2, node_name: String, layer_z_index: int) -> Sprite2D:
	var atlas_slot = _resolve_visual_texture_slot(PRODUCTION_ENVIRONMENT_DECAL_ATLAS, V3_ENVIRONMENT_DECAL_ATLAS, "environment decal atlas")
	return _try_create_v3_atlas_visual(
		atlas_slot.get("path", V3_ENVIRONMENT_DECAL_ATLAS),
		V3_ENVIRONMENT_DECAL_REGIONS,
		decal_id,
		target_size,
		node_name,
		layer_z_index
	)

func _try_create_v3_atlas_visual(atlas_path: String, regions: Dictionary, visual_id: String, target_size: Vector2, node_name: String, layer_z_index: int) -> Sprite2D:
	if not regions.has(visual_id):
		push_warning("[AssetManager] Unknown V3 environment visual: %s" % visual_id)
		return null
	# Not FileAccess.file_exists alone: an exported build has only the imported
	# texture, not the source .png, so that check is always false there.
	if not _visual_path_exists(atlas_path):
		push_warning("[AssetManager] V3 environment atlas missing: %s" % atlas_path)
		return null
	var atlas_cache_key = "phase10mm_atlas:%s" % atlas_path
	var atlas_texture = loaded_assets.get(atlas_cache_key) as Texture2D
	if not atlas_texture:
		if ResourceLoader.exists(atlas_path):
			atlas_texture = load(atlas_path) as Texture2D
		if not atlas_texture:
			var atlas_image = Image.load_from_file(ProjectSettings.globalize_path(atlas_path))
			if atlas_image and not atlas_image.is_empty():
				atlas_texture = ImageTexture.create_from_image(atlas_image)
		if atlas_texture:
			loaded_assets[atlas_cache_key] = atlas_texture
	if not atlas_texture:
		push_warning("[AssetManager] V3 environment atlas failed to load: %s" % atlas_path)
		return null

	var region: Rect2i = regions[visual_id]
	var cropped_texture = AtlasTexture.new()
	cropped_texture.atlas = atlas_texture
	cropped_texture.region = Rect2(region.position, region.size)

	var sprite = Sprite2D.new()
	sprite.name = node_name
	sprite.texture = cropped_texture
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.z_index = layer_z_index
	if target_size.x > 0.0 and target_size.y > 0.0:
		sprite.scale = Vector2(target_size.x / float(region.size.x), target_size.y / float(region.size.y))
	sprite.set_meta("phase10mm_v3_environment_visual", true)
	sprite.set_meta("phase10mm_v3_visual_id", visual_id)
	return sprite

func _try_resolve_v2_prototype_tileset_slot(tileset_id: String, time_state: String = OAKHAVEN_DEFAULT_TIME_STATE) -> Dictionary:
	if not V2_PROTOTYPE_TILESETS.has(tileset_id) and not PRODUCTION_VISUAL_TILESETS.has(tileset_id):
		push_warning("[AssetManager] Unknown V2 tileset %s; using existing environment fallback." % tileset_id)
		return {}
	if tileset_id == "oakhaven":
		return get_oakhaven_tileset_slot(time_state)
	if tileset_id == "ironhold":
		return get_ironhold_tileset_slot()
	if tileset_id == "fractured_wastes":
		return get_fractured_wastes_tileset_slot()
	if tileset_id == "mirror_city":
		return get_mirror_city_tileset_slot()
	var generated_path: String = V2_PROTOTYPE_TILESETS.get(tileset_id, "")
	var production_path: String = PRODUCTION_VISUAL_TILESETS.get(tileset_id, "")
	var tileset_slot = _resolve_visual_texture_slot(production_path, generated_path, "%s visual tileset" % tileset_id)
	var tileset_path: String = tileset_slot.get("path", generated_path)
	var texture = tileset_slot.get("texture") as Texture2D
	if not texture:
		push_warning("[AssetManager] Visual tileset failed to load for %s at %s; using existing environment fallback." % [tileset_id, tileset_path])
	return tileset_slot

func _try_load_v2_prototype_tileset(tileset_id: String, time_state: String = OAKHAVEN_DEFAULT_TIME_STATE) -> Texture2D:
	var tileset_slot = _try_resolve_v2_prototype_tileset_slot(tileset_id, time_state)
	var texture = tileset_slot.get("texture") as Texture2D
	return texture

func _atlas_has_tile(atlas_size: Vector2i, atlas_coords: Vector2i) -> bool:
	return atlas_coords.x >= 0 and atlas_coords.y >= 0 and atlas_coords.x < atlas_size.x and atlas_coords.y < atlas_size.y

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

## Sorted VFX asset keys for a category. Assets are lazy-loaded, so this reads
## ASSET_PATHS: loaded_assets only holds textures something already requested.
func _vfx_keys(category: String) -> Array:
	var prefix = "vfx_" + category + "_"
	var keys: Array = []
	for key in ASSET_PATHS:
		if key.begins_with(prefix) and is_asset_available(key):
			keys.append(key)
	keys.sort()
	return keys

## Get a random VFX texture from a category
func get_random_vfx(category: String) -> Texture2D:
	var available_keys = _vfx_keys(category)
	if available_keys.is_empty():
		return null
	return get_sprite(available_keys[randi() % available_keys.size()])

## Create a VFX sprite node (e.g., for slash, smoke, magic effects)
func create_vfx_sprite(category: String, size: Vector2 = Vector2(64, 64), idx: int = -1) -> Sprite2D:
	var available_keys = _vfx_keys(category)

	if available_keys.is_empty():
		return null

	var key: String
	if idx >= 0 and idx < available_keys.size():
		key = available_keys[idx]
	else:
		key = available_keys[randi() % available_keys.size()]

	var tex = get_sprite(key)
	if not tex:
		return null
	var sprite = Sprite2D.new()
	sprite.texture = tex
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.name = "VFX_" + category
	
	var tex_size = sprite.texture.get_size()
	if tex_size.x > 0 and tex_size.y > 0:
		var uniform = min(size.x / tex_size.x, size.y / tex_size.y)
		sprite.scale = Vector2(uniform, uniform)
	
	return sprite

## Create an animated VFX sequence cycling through category textures
func create_vfx_animated(category: String, size: Vector2 = Vector2(64, 64), fps: float = 12.0, do_loop: bool = false) -> AnimatedSprite2D:
	var textures: Array = []
	# Keys come back sorted, which keeps frame order
	for key in _vfx_keys(category):
		var tex = get_sprite(key)
		if tex:
			textures.append(tex)
	
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
	# Add first: global_position set outside the tree ignores the parent's transform.
	parent.add_child(vfx)
	vfx.global_position = pos
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
