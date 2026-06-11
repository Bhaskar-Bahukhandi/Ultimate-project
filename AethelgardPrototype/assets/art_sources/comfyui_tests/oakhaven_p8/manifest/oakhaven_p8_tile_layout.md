# Oakhaven P8 Tile Layout Map

Atlas: `assets/art_sources/comfyui_tests/oakhaven_p8/generated_tiles/oakhaven_p8_variant_*`. Tile size: 32x32. Grid: 16 columns x 16 rows.

All coordinates are atlas cell coordinates `(x,y)`, zero-based from the top-left. All three P8 variants share this exact grammar and layout. Unlisted cells are transparent empty cells.

| Tile Coordinate | Tile Name | Category | Intended Use | Notes |
| --- | --- | --- | --- | --- |
| (0,0) | `grass_base` | grass | base grass tile | Rows 0-2: grass terrain. |
| (1,0) | `grass_darker` | grass | darker grass variation | Rows 0-2: grass terrain. |
| (2,0) | `grass_lighter` | grass | lighter grass variation | Rows 0-2: grass terrain. |
| (3,0) | `grass_patchy` | grass | patchy grass | Rows 0-2: grass terrain. |
| (4,0) | `grass_sparse` | grass | sparse grass | Rows 0-2: grass terrain. |
| (5,0) | `grass_flower_speckled` | grass | flower-speckled grass | Rows 0-2: grass terrain. |
| (6,0) | `grass_worn` | grass | slightly worn grass | Rows 0-2: grass terrain. |
| (7,0) | `grass_shadowed` | grass | shadowed grass | Rows 0-2: grass terrain. |
| (8,0) | `grass_mossy` | grass | mossy grass | Rows 0-2: grass terrain. |
| (9,0) | `grass_leaf_scatter` | grass | leaf-scattered grass | Rows 0-2: grass terrain. |
| (10,0) | `grass_blue_flowers` | grass | blue flower grass | Rows 0-2: grass terrain. |
| (11,0) | `grass_pink_flowers` | grass | pink flower grass | Rows 0-2: grass terrain. |
| (12,0) | `grass_tiny_stones` | grass | tiny stone grass | Rows 0-2: grass terrain. |
| (13,0) | `grass_clover` | grass | clover grass | Rows 0-2: grass terrain. |
| (14,0) | `grass_faint_glitch_spark` | grass | tiny magical accent grass | Rows 0-2: grass terrain. |
| (15,0) | `grass_plain_backup` | grass | plain backup grass | Rows 0-2: grass terrain. |
| (0,1) | `grass_dense_blades` | grass | dense blade grass | Rows 0-2: grass terrain. |
| (1,1) | `grass_trampled` | grass | trampled grass | Rows 0-2: grass terrain. |
| (2,1) | `grass_forest_floor` | grass | forest floor grass | Rows 0-2: grass terrain. |
| (3,1) | `grass_dry_yellowed` | grass | dry yellowed grass | Rows 0-2: grass terrain. |
| (4,1) | `grass_soft_shadow` | grass | soft shadow grass | Rows 0-2: grass terrain. |
| (5,1) | `grass_village_lawn` | grass | village lawn fill | Rows 0-2: grass terrain. |
| (6,1) | `grass_herb_hint` | grass | herb hint grass | Rows 0-2: grass terrain. |
| (7,1) | `grass_low_noise` | grass | low-noise grass | Rows 0-2: grass terrain. |
| (0,3) | `dirt_center` | dirt path | dirt center | Rows 3-5: path grammar. |
| (1,3) | `dirt_variation` | dirt path | dirt variation | Rows 3-5: path grammar. |
| (2,3) | `path_worn_center` | dirt path | worn path center | Rows 3-5: path grammar. |
| (3,3) | `path_straight_horizontal` | dirt path | path straight horizontal | Rows 3-5: path grammar. |
| (4,3) | `path_straight_vertical` | dirt path | path straight vertical | Rows 3-5: path grammar. |
| (5,3) | `path_t_junction_up` | dirt path | path T-junction | Rows 3-5: path grammar. |
| (6,3) | `path_t_junction_down` | dirt path | path T-junction | Rows 3-5: path grammar. |
| (7,3) | `path_t_junction_left` | dirt path | path T-junction | Rows 3-5: path grammar. |
| (8,3) | `path_t_junction_right` | dirt path | path T-junction | Rows 3-5: path grammar. |
| (9,3) | `path_cross` | dirt path | path cross | Rows 3-5: path grammar. |
| (10,3) | `dirt_small_stone_embedded` | dirt path | small stone embedded dirt | Rows 3-5: path grammar. |
| (11,3) | `path_turn_ne` | dirt path | path turn | Rows 3-5: path grammar. |
| (12,3) | `path_turn_nw` | dirt path | path turn | Rows 3-5: path grammar. |
| (13,3) | `path_turn_se` | dirt path | path turn | Rows 3-5: path grammar. |
| (14,3) | `path_turn_sw` | dirt path | path turn | Rows 3-5: path grammar. |
| (15,3) | `path_end_left` | dirt path | path end | Rows 3-5: path grammar. |
| (0,4) | `path_end_right` | dirt path | path end | Rows 3-5: path grammar. |
| (1,4) | `path_end_top` | dirt path | path end | Rows 3-5: path grammar. |
| (2,4) | `path_end_bottom` | dirt path | path end | Rows 3-5: path grammar. |
| (3,4) | `dirt_pebble_1` | dirt path | pebble dirt | Rows 3-5: path grammar. |
| (4,4) | `dirt_pebble_2` | dirt path | pebble dirt alternate | Rows 3-5: path grammar. |
| (5,4) | `dirt_darker_mud` | dirt path | darker mud dirt | Rows 3-5: path grammar. |
| (6,4) | `dirt_dry_patch` | dirt path | dry dirt patch | Rows 3-5: path grammar. |
| (7,4) | `dirt_track_marks` | dirt path | track-mark dirt | Rows 3-5: path grammar. |
| (8,4) | `dirt_stepstone_center` | dirt path | stepping stone dirt | Rows 3-5: path grammar. |
| (9,4) | `path_narrow_horizontal` | dirt path | narrow horizontal path | Rows 3-5: path grammar. |
| (10,4) | `path_narrow_vertical` | dirt path | narrow vertical path | Rows 3-5: path grammar. |
| (11,4) | `path_shadow_left` | dirt path | path left shadow | Rows 3-5: path grammar. |
| (12,4) | `path_shadow_right` | dirt path | path right shadow | Rows 3-5: path grammar. |
| (13,4) | `dirt_low_noise` | dirt path | low-noise dirt | Rows 3-5: path grammar. |
| (0,6) | `transition_top_edge` | grass-to-dirt transitions | top edge | Rows 6-8: edge/corner grammar. |
| (1,6) | `transition_bottom_edge` | grass-to-dirt transitions | bottom edge | Rows 6-8: edge/corner grammar. |
| (2,6) | `transition_left_edge` | grass-to-dirt transitions | left edge | Rows 6-8: edge/corner grammar. |
| (3,6) | `transition_right_edge` | grass-to-dirt transitions | right edge | Rows 6-8: edge/corner grammar. |
| (4,6) | `transition_outer_tl` | grass-to-dirt transitions | outer corner | Rows 6-8: edge/corner grammar. |
| (5,6) | `transition_outer_tr` | grass-to-dirt transitions | outer corner | Rows 6-8: edge/corner grammar. |
| (6,6) | `transition_outer_bl` | grass-to-dirt transitions | outer corner | Rows 6-8: edge/corner grammar. |
| (7,6) | `transition_outer_br` | grass-to-dirt transitions | outer corner | Rows 6-8: edge/corner grammar. |
| (8,6) | `transition_inner_tl` | grass-to-dirt transitions | inner corner | Rows 6-8: edge/corner grammar. |
| (9,6) | `transition_inner_tr` | grass-to-dirt transitions | inner corner | Rows 6-8: edge/corner grammar. |
| (10,6) | `transition_inner_bl` | grass-to-dirt transitions | inner corner | Rows 6-8: edge/corner grammar. |
| (11,6) | `transition_inner_br` | grass-to-dirt transitions | inner corner | Rows 6-8: edge/corner grammar. |
| (12,6) | `transition_diagonal_down` | grass-to-dirt transitions | diagonal-ish rough edge | Rows 6-8: edge/corner grammar. |
| (13,6) | `transition_diagonal_up` | grass-to-dirt transitions | diagonal-ish rough edge | Rows 6-8: edge/corner grammar. |
| (14,6) | `transition_soft_broken_top` | grass-to-dirt transitions | soft broken edge | Rows 6-8: edge/corner grammar. |
| (15,6) | `transition_soft_broken_bottom` | grass-to-dirt transitions | soft broken edge | Rows 6-8: edge/corner grammar. |
| (0,7) | `transition_soft_broken_left` | grass-to-dirt transitions | soft broken edge | Rows 6-8: edge/corner grammar. |
| (1,7) | `transition_soft_broken_right` | grass-to-dirt transitions | soft broken edge | Rows 6-8: edge/corner grammar. |
| (2,7) | `transition_small_patch_dirt` | grass-to-dirt transitions | small dirt patch | Rows 6-8: edge/corner grammar. |
| (3,7) | `transition_small_patch_grass` | grass-to-dirt transitions | small grass patch | Rows 6-8: edge/corner grammar. |
| (4,7) | `transition_stony_edge_left` | grass-to-dirt transitions | stony edge | Rows 6-8: edge/corner grammar. |
| (5,7) | `transition_stony_edge_right` | grass-to-dirt transitions | stony edge | Rows 6-8: edge/corner grammar. |
| (6,7) | `transition_flowery_edge_top` | grass-to-dirt transitions | flowered edge | Rows 6-8: edge/corner grammar. |
| (7,7) | `transition_flowery_edge_bottom` | grass-to-dirt transitions | flowered edge | Rows 6-8: edge/corner grammar. |
| (8,7) | `transition_dark_edge_top` | grass-to-dirt transitions | dark edge | Rows 6-8: edge/corner grammar. |
| (9,7) | `transition_dark_edge_bottom` | grass-to-dirt transitions | dark edge | Rows 6-8: edge/corner grammar. |
| (10,7) | `transition_dark_edge_left` | grass-to-dirt transitions | dark edge | Rows 6-8: edge/corner grammar. |
| (11,7) | `transition_dark_edge_right` | grass-to-dirt transitions | dark edge | Rows 6-8: edge/corner grammar. |
| (0,9) | `fence_horizontal_middle` | fence/hedge | fence horizontal middle | Rows 9-10: boundary sprites. |
| (1,9) | `fence_vertical_middle` | fence/hedge | fence vertical middle | Rows 9-10: boundary sprites. |
| (2,9) | `fence_post` | fence/hedge | fence post | Rows 9-10: boundary sprites. |
| (3,9) | `fence_end_left` | fence/hedge | fence end left | Rows 9-10: boundary sprites. |
| (4,9) | `fence_end_right` | fence/hedge | fence end right | Rows 9-10: boundary sprites. |
| (5,9) | `fence_end_top` | fence/hedge | fence end top | Rows 9-10: boundary sprites. |
| (6,9) | `fence_end_bottom` | fence/hedge | fence end bottom | Rows 9-10: boundary sprites. |
| (7,9) | `hedge_block` | fence/hedge | hedge block | Rows 9-10: boundary sprites. |
| (8,9) | `hedge_horizontal` | fence/hedge | hedge horizontal | Rows 9-10: boundary sprites. |
| (9,9) | `hedge_vertical` | fence/hedge | hedge vertical | Rows 9-10: boundary sprites. |
| (10,9) | `hedge_corner_tl` | fence/hedge | hedge corner | Rows 9-10: boundary sprites. |
| (11,9) | `hedge_corner_tr` | fence/hedge | hedge corner | Rows 9-10: boundary sprites. |
| (12,9) | `hedge_corner_bl` | fence/hedge | hedge corner | Rows 9-10: boundary sprites. |
| (13,9) | `hedge_corner_br` | fence/hedge | hedge corner | Rows 9-10: boundary sprites. |
| (14,9) | `hedge_broken_opening` | fence/hedge | broken hedge/opening | Rows 9-10: boundary sprites. |
| (15,9) | `hedge_flower_block` | fence/hedge | hedge flower block | Rows 9-10: boundary sprites. |
| (0,10) | `fence_gate_left` | fence/hedge | fence gate left | Rows 9-10: boundary sprites. |
| (1,10) | `fence_gate_right` | fence/hedge | fence gate right | Rows 9-10: boundary sprites. |
| (2,10) | `fence_broken_board` | fence/hedge | broken fence | Rows 9-10: boundary sprites. |
| (3,10) | `fence_support_stake` | fence/hedge | fence support stake | Rows 9-10: boundary sprites. |
| (0,11) | `cottage_wall_base` | cottage/building support | cottage wall base | Rows 11-13: village building support. |
| (1,11) | `cottage_wall_variation` | cottage/building support | cottage wall variation | Rows 11-13: village building support. |
| (2,11) | `wooden_wall_tile` | cottage/building support | wooden wall tile | Rows 11-13: village building support. |
| (3,11) | `roof_edge_tile` | cottage/building support | roof edge tile | Rows 11-13: village building support. |
| (4,11) | `roof_corner_tile` | cottage/building support | roof corner tile | Rows 11-13: village building support. |
| (5,11) | `roof_center_tile` | cottage/building support | roof center tile | Rows 11-13: village building support. |
| (6,11) | `foundation_shadow` | cottage/building support | foundation shadow | Rows 11-13: village building support. |
| (7,11) | `doorway_base` | cottage/building support | doorway base | Rows 11-13: village building support. |
| (8,11) | `window_wall_detail` | cottage/building support | window/wall detail | Rows 11-13: village building support. |
| (9,11) | `small_wooden_trim` | cottage/building support | small wooden trim | Rows 11-13: village building support. |
| (10,11) | `roof_edge_left` | cottage/building support | roof edge left | Rows 11-13: village building support. |
| (11,11) | `roof_edge_right` | cottage/building support | roof edge right | Rows 11-13: village building support. |
| (12,11) | `roof_edge_top` | cottage/building support | roof edge top | Rows 11-13: village building support. |
| (13,11) | `roof_edge_bottom` | cottage/building support | roof edge bottom | Rows 11-13: village building support. |
| (14,11) | `wall_shadow_left` | cottage/building support | wall shadow left | Rows 11-13: village building support. |
| (15,11) | `wall_shadow_right` | cottage/building support | wall shadow right | Rows 11-13: village building support. |
| (0,12) | `wood_beam_horizontal` | cottage/building support | wood beam horizontal | Rows 11-13: village building support. |
| (1,12) | `wood_beam_vertical` | cottage/building support | wood beam vertical | Rows 11-13: village building support. |
| (2,12) | `wall_moss_base` | cottage/building support | mossy wall base | Rows 11-13: village building support. |
| (3,12) | `roof_moss_patch` | cottage/building support | mossy roof patch | Rows 11-13: village building support. |
| (4,12) | `cottage_step` | cottage/building support | cottage step | Rows 11-13: village building support. |
| (5,12) | `window_lit_detail` | cottage/building support | lit window detail | Rows 11-13: village building support. |
| (6,12) | `porch_plank` | cottage/building support | porch plank | Rows 11-13: village building support. |
| (7,12) | `wall_tiny_glitch_crack` | cottage/building support | tiny glitch crack | Rows 11-13: village building support. |
| (0,14) | `flower_patch` | props/utility | flower patch | Rows 14-15: decoration and utility. |
| (1,14) | `herb_patch` | props/utility | herb patch | Rows 14-15: decoration and utility. |
| (2,14) | `wooden_sign` | props/utility | wooden sign | Rows 14-15: decoration and utility. |
| (3,14) | `small_stone` | props/utility | small stone | Rows 14-15: decoration and utility. |
| (4,14) | `tree_stump` | props/utility | tree stump | Rows 14-15: decoration and utility. |
| (5,14) | `crate_barrel_simple` | props/utility | crate/barrel simple prop | Rows 14-15: decoration and utility. |
| (6,14) | `soft_shadow_blob` | props/utility | soft shadow blob | Rows 14-15: decoration and utility. |
| (7,14) | `glitch_flower_rune_accent` | props/utility | tiny cyan-magenta glitch flower/rune accent | Rows 14-15: decoration and utility. |
| (8,14) | `ground_leaf_scatter` | props/utility | ground leaf scatter | Rows 14-15: decoration and utility. |
| (9,14) | `village_marker_tile` | props/utility | village marker tile | Rows 14-15: decoration and utility. |
| (10,14) | `transparent_empty_tile` | props/utility | transparent empty tile | Rows 14-15: decoration and utility. |
| (11,14) | `debug_safe_separator` | props/utility | debug-safe separator | Rows 14-15: decoration and utility. |
| (12,14) | `shadow_only_tile` | props/utility | shadow-only tile | Rows 14-15: decoration and utility. |
| (13,14) | `highlight_only_accent_tile` | props/utility | highlight-only accent tile | Rows 14-15: decoration and utility. |
| (14,14) | `flower_patch_blue` | props/utility | blue flower patch | Rows 14-15: decoration and utility. |
| (15,14) | `tiny_mushroom_cluster` | props/utility | tiny mushroom cluster | Rows 14-15: decoration and utility. |
| (0,15) | `small_log` | props/utility | small log | Rows 14-15: decoration and utility. |
| (1,15) | `barrel_only` | props/utility | barrel only | Rows 14-15: decoration and utility. |
| (2,15) | `crate_only` | props/utility | crate only | Rows 14-15: decoration and utility. |
| (3,15) | `tiny_cyan_spark` | props/utility | tiny cyan spark | Rows 14-15: decoration and utility. |
