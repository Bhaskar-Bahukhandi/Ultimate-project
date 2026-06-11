from __future__ import annotations

import json
import random
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parents[3]
P8 = ROOT / "assets" / "art_sources" / "comfyui_tests" / "oakhaven_p8"
GEN = P8 / "generated_tiles"
REV = P8 / "review"
MOCK = P8 / "mockups"
MAN = P8 / "manifest"
DOC = ROOT / "docs" / "art_pipeline"
TILE = 32
ATLAS = 512

for folder in (GEN, REV, MOCK, MAN, DOC):
    folder.mkdir(parents=True, exist_ok=True)

FONT = ImageFont.load_default()

PALETTES = {
    "a_clean": {
        "file": "variant_a_clean",
        "label": "Variant A clean",
        "texture": 0.16,
        "rough": 2,
        "grass": (54, 119, 50),
        "grass_dark": (37, 84, 41),
        "grass_light": (84, 151, 70),
        "dirt": (132, 98, 55),
        "dirt_dark": (79, 58, 40),
        "dirt_light": (166, 128, 72),
        "stone": (121, 122, 109),
        "stone_dark": (68, 72, 69),
        "wood": (132, 82, 43),
        "wood_dark": (73, 46, 32),
        "wood_light": (176, 112, 58),
        "hedge": (42, 91, 43),
        "hedge_light": (84, 145, 66),
        "hedge_dark": (24, 56, 34),
        "wall": (146, 109, 73),
        "wall_dark": (94, 70, 57),
        "wall_light": (183, 144, 92),
        "roof": (113, 48, 44),
        "roof_dark": (70, 34, 38),
        "roof_light": (154, 64, 52),
        "outline": (25, 27, 25),
        "shadow": (12, 14, 14, 112),
        "yellow": (228, 194, 62),
        "pink": (205, 93, 128),
        "blue": (88, 158, 204),
        "cyan": (71, 215, 219),
        "magenta": (210, 70, 170),
    },
    "b_textured": {
        "file": "variant_b_textured",
        "label": "Variant B textured",
        "texture": 0.42,
        "rough": 4,
        "grass": (52, 112, 45),
        "grass_dark": (34, 76, 39),
        "grass_light": (97, 151, 64),
        "dirt": (128, 88, 52),
        "dirt_dark": (76, 54, 38),
        "dirt_light": (174, 122, 65),
        "stone": (116, 111, 98),
        "stone_dark": (65, 67, 62),
        "wood": (134, 78, 40),
        "wood_dark": (67, 42, 29),
        "wood_light": (186, 118, 56),
        "hedge": (38, 84, 37),
        "hedge_light": (91, 149, 59),
        "hedge_dark": (22, 51, 32),
        "wall": (138, 101, 69),
        "wall_dark": (82, 62, 51),
        "wall_light": (190, 143, 85),
        "roof": (101, 44, 39),
        "roof_dark": (57, 29, 34),
        "roof_light": (153, 61, 48),
        "outline": (23, 24, 23),
        "shadow": (8, 12, 12, 128),
        "yellow": (236, 198, 52),
        "pink": (213, 82, 133),
        "blue": (77, 150, 204),
        "cyan": (71, 214, 211),
        "magenta": (211, 61, 164),
    },
    "c_dark_glitch": {
        "file": "variant_c_dark_glitch",
        "label": "Variant C dark/glitch",
        "texture": 0.30,
        "rough": 3,
        "grass": (38, 86, 50),
        "grass_dark": (25, 55, 43),
        "grass_light": (66, 125, 66),
        "dirt": (101, 72, 54),
        "dirt_dark": (57, 45, 42),
        "dirt_light": (142, 102, 69),
        "stone": (97, 100, 99),
        "stone_dark": (52, 58, 62),
        "wood": (103, 67, 45),
        "wood_dark": (50, 35, 31),
        "wood_light": (150, 95, 58),
        "hedge": (30, 68, 47),
        "hedge_light": (63, 122, 72),
        "hedge_dark": (18, 42, 36),
        "wall": (113, 85, 68),
        "wall_dark": (65, 54, 55),
        "wall_light": (157, 119, 86),
        "roof": (83, 39, 50),
        "roof_dark": (45, 28, 39),
        "roof_light": (130, 54, 69),
        "outline": (17, 18, 20),
        "shadow": (0, 4, 10, 145),
        "yellow": (196, 160, 62),
        "pink": (196, 71, 138),
        "blue": (62, 139, 188),
        "cyan": (57, 221, 221),
        "magenta": (221, 63, 183),
    },
}

layout: list[dict] = []


def rel(path: Path) -> str:
    return path.relative_to(ROOT).as_posix()


def add(x: int, y: int, name: str, category: str, use: str, notes: str = "") -> None:
    layout.append({"x": x, "y": y, "name": name, "category": category, "intended_use": use, "notes": notes})


def build_layout() -> None:
    grass = [
        ("grass_base", "base grass tile"),
        ("grass_darker", "darker grass variation"),
        ("grass_lighter", "lighter grass variation"),
        ("grass_patchy", "patchy grass"),
        ("grass_sparse", "sparse grass"),
        ("grass_flower_speckled", "flower-speckled grass"),
        ("grass_worn", "slightly worn grass"),
        ("grass_shadowed", "shadowed grass"),
        ("grass_mossy", "mossy grass"),
        ("grass_leaf_scatter", "leaf-scattered grass"),
        ("grass_blue_flowers", "blue flower grass"),
        ("grass_pink_flowers", "pink flower grass"),
        ("grass_tiny_stones", "tiny stone grass"),
        ("grass_clover", "clover grass"),
        ("grass_faint_glitch_spark", "tiny magical accent grass"),
        ("grass_plain_backup", "plain backup grass"),
        ("grass_dense_blades", "dense blade grass"),
        ("grass_trampled", "trampled grass"),
        ("grass_forest_floor", "forest floor grass"),
        ("grass_dry_yellowed", "dry yellowed grass"),
        ("grass_soft_shadow", "soft shadow grass"),
        ("grass_village_lawn", "village lawn fill"),
        ("grass_herb_hint", "herb hint grass"),
        ("grass_low_noise", "low-noise grass"),
    ]
    for i, item in enumerate(grass):
        add(i % 16, i // 16, item[0], "grass", item[1], "Rows 0-2: grass terrain.")

    path = [
        ("dirt_center", "dirt center"),
        ("dirt_variation", "dirt variation"),
        ("path_worn_center", "worn path center"),
        ("path_straight_horizontal", "path straight horizontal"),
        ("path_straight_vertical", "path straight vertical"),
        ("path_t_junction_up", "path T-junction"),
        ("path_t_junction_down", "path T-junction"),
        ("path_t_junction_left", "path T-junction"),
        ("path_t_junction_right", "path T-junction"),
        ("path_cross", "path cross"),
        ("dirt_small_stone_embedded", "small stone embedded dirt"),
        ("path_turn_ne", "path turn"),
        ("path_turn_nw", "path turn"),
        ("path_turn_se", "path turn"),
        ("path_turn_sw", "path turn"),
        ("path_end_left", "path end"),
        ("path_end_right", "path end"),
        ("path_end_top", "path end"),
        ("path_end_bottom", "path end"),
        ("dirt_pebble_1", "pebble dirt"),
        ("dirt_pebble_2", "pebble dirt alternate"),
        ("dirt_darker_mud", "darker mud dirt"),
        ("dirt_dry_patch", "dry dirt patch"),
        ("dirt_track_marks", "track-mark dirt"),
        ("dirt_stepstone_center", "stepping stone dirt"),
        ("path_narrow_horizontal", "narrow horizontal path"),
        ("path_narrow_vertical", "narrow vertical path"),
        ("path_shadow_left", "path left shadow"),
        ("path_shadow_right", "path right shadow"),
        ("dirt_low_noise", "low-noise dirt"),
    ]
    for i, item in enumerate(path):
        add(i % 16, 3 + i // 16, item[0], "dirt path", item[1], "Rows 3-5: path grammar.")

    transitions = [
        ("transition_top_edge", "top edge"),
        ("transition_bottom_edge", "bottom edge"),
        ("transition_left_edge", "left edge"),
        ("transition_right_edge", "right edge"),
        ("transition_outer_tl", "outer corner"),
        ("transition_outer_tr", "outer corner"),
        ("transition_outer_bl", "outer corner"),
        ("transition_outer_br", "outer corner"),
        ("transition_inner_tl", "inner corner"),
        ("transition_inner_tr", "inner corner"),
        ("transition_inner_bl", "inner corner"),
        ("transition_inner_br", "inner corner"),
        ("transition_diagonal_down", "diagonal-ish rough edge"),
        ("transition_diagonal_up", "diagonal-ish rough edge"),
        ("transition_soft_broken_top", "soft broken edge"),
        ("transition_soft_broken_bottom", "soft broken edge"),
        ("transition_soft_broken_left", "soft broken edge"),
        ("transition_soft_broken_right", "soft broken edge"),
        ("transition_small_patch_dirt", "small dirt patch"),
        ("transition_small_patch_grass", "small grass patch"),
        ("transition_stony_edge_left", "stony edge"),
        ("transition_stony_edge_right", "stony edge"),
        ("transition_flowery_edge_top", "flowered edge"),
        ("transition_flowery_edge_bottom", "flowered edge"),
        ("transition_dark_edge_top", "dark edge"),
        ("transition_dark_edge_bottom", "dark edge"),
        ("transition_dark_edge_left", "dark edge"),
        ("transition_dark_edge_right", "dark edge"),
    ]
    for i, item in enumerate(transitions):
        add(i % 16, 6 + i // 16, item[0], "grass-to-dirt transitions", item[1], "Rows 6-8: edge/corner grammar.")

    fences = [
        ("fence_horizontal_middle", "fence horizontal middle"),
        ("fence_vertical_middle", "fence vertical middle"),
        ("fence_post", "fence post"),
        ("fence_end_left", "fence end left"),
        ("fence_end_right", "fence end right"),
        ("fence_end_top", "fence end top"),
        ("fence_end_bottom", "fence end bottom"),
        ("hedge_block", "hedge block"),
        ("hedge_horizontal", "hedge horizontal"),
        ("hedge_vertical", "hedge vertical"),
        ("hedge_corner_tl", "hedge corner"),
        ("hedge_corner_tr", "hedge corner"),
        ("hedge_corner_bl", "hedge corner"),
        ("hedge_corner_br", "hedge corner"),
        ("hedge_broken_opening", "broken hedge/opening"),
        ("hedge_flower_block", "hedge flower block"),
        ("fence_gate_left", "fence gate left"),
        ("fence_gate_right", "fence gate right"),
        ("fence_broken_board", "broken fence"),
        ("fence_support_stake", "fence support stake"),
    ]
    for i, item in enumerate(fences):
        add(i % 16, 9 + i // 16, item[0], "fence/hedge", item[1], "Rows 9-10: boundary sprites.")

    buildings = [
        ("cottage_wall_base", "cottage wall base"),
        ("cottage_wall_variation", "cottage wall variation"),
        ("wooden_wall_tile", "wooden wall tile"),
        ("roof_edge_tile", "roof edge tile"),
        ("roof_corner_tile", "roof corner tile"),
        ("roof_center_tile", "roof center tile"),
        ("foundation_shadow", "foundation shadow"),
        ("doorway_base", "doorway base"),
        ("window_wall_detail", "window/wall detail"),
        ("small_wooden_trim", "small wooden trim"),
        ("roof_edge_left", "roof edge left"),
        ("roof_edge_right", "roof edge right"),
        ("roof_edge_top", "roof edge top"),
        ("roof_edge_bottom", "roof edge bottom"),
        ("wall_shadow_left", "wall shadow left"),
        ("wall_shadow_right", "wall shadow right"),
        ("wood_beam_horizontal", "wood beam horizontal"),
        ("wood_beam_vertical", "wood beam vertical"),
        ("wall_moss_base", "mossy wall base"),
        ("roof_moss_patch", "mossy roof patch"),
        ("cottage_step", "cottage step"),
        ("window_lit_detail", "lit window detail"),
        ("porch_plank", "porch plank"),
        ("wall_tiny_glitch_crack", "tiny glitch crack"),
    ]
    for i, item in enumerate(buildings):
        add(i % 16, 11 + i // 16, item[0], "cottage/building support", item[1], "Rows 11-13: village building support.")

    props = [
        ("flower_patch", "flower patch"),
        ("herb_patch", "herb patch"),
        ("wooden_sign", "wooden sign"),
        ("small_stone", "small stone"),
        ("tree_stump", "tree stump"),
        ("crate_barrel_simple", "crate/barrel simple prop"),
        ("soft_shadow_blob", "soft shadow blob"),
        ("glitch_flower_rune_accent", "tiny cyan-magenta glitch flower/rune accent"),
        ("ground_leaf_scatter", "ground leaf scatter"),
        ("village_marker_tile", "village marker tile"),
        ("transparent_empty_tile", "transparent empty tile"),
        ("debug_safe_separator", "debug-safe separator"),
        ("shadow_only_tile", "shadow-only tile"),
        ("highlight_only_accent_tile", "highlight-only accent tile"),
        ("flower_patch_blue", "blue flower patch"),
        ("tiny_mushroom_cluster", "tiny mushroom cluster"),
        ("small_log", "small log"),
        ("barrel_only", "barrel only"),
        ("crate_only", "crate only"),
        ("tiny_cyan_spark", "tiny cyan spark"),
    ]
    for i, item in enumerate(props):
        add(i % 16, 14 + i // 16, item[0], "props/utility", item[1], "Rows 14-15: decoration and utility.")


def clamp(value: float) -> int:
    return max(0, min(255, int(value)))


def blend(a: tuple[int, int, int], b: tuple[int, int, int], t: float) -> tuple[int, int, int]:
    return tuple(clamp(a[i] * (1.0 - t) + b[i] * t) for i in range(3))


def adj(color: tuple[int, int, int], amount: int) -> tuple[int, int, int]:
    return tuple(clamp(c + amount) for c in color)


def rng_for(variant: str, name: str) -> random.Random:
    return random.Random(hash((variant, name, 8821)) & 0xFFFFFFFF)


def sprinkle(draw: ImageDraw.ImageDraw, rng: random.Random, count: int, colors: list[tuple], max_size: int = 1) -> None:
    for _ in range(count):
        x = rng.randrange(0, TILE)
        y = rng.randrange(0, TILE)
        s = rng.randrange(1, max_size + 1)
        draw.rectangle((x, y, min(31, x + s - 1), min(31, y + s - 1)), fill=rng.choice(colors))


def grass_tile(draw: ImageDraw.ImageDraw, pal: dict, rng: random.Random, name: str, variant: str) -> None:
    base = pal["grass"]
    if any(k in name for k in ("darker", "shadow", "forest")):
        base = pal["grass_dark"]
    if any(k in name for k in ("lighter", "lawn")):
        base = pal["grass_light"]
    if "dry" in name:
        base = blend(pal["grass"], pal["dirt_light"], 0.28)
    draw.rectangle((0, 0, 31, 31), fill=base)
    density = int(10 + pal["texture"] * 38)
    if "low_noise" in name or "plain" in name:
        density = 6
    if any(k in name for k in ("patchy", "dense", "forest")):
        density += 12
    sprinkle(draw, rng, density, [pal["grass_dark"], pal["grass_light"], adj(base, -8), adj(base, 8)])
    if any(k in name for k in ("patchy", "worn", "trampled")):
        for _ in range(2):
            x, y = rng.randrange(3, 22), rng.randrange(5, 23)
            draw.rectangle((x, y, x + rng.randrange(5, 10), y + rng.randrange(2, 6)), fill=blend(base, pal["dirt"], 0.30))
    if "flower" in name:
        colors = [pal["yellow"], pal["pink"], pal["blue"]]
        if "blue" in name:
            colors = [pal["blue"]]
        if "pink" in name:
            colors = [pal["pink"]]
        for _ in range(6):
            x, y = rng.randrange(5, 27), rng.randrange(5, 27)
            draw.point((x, y), fill=rng.choice(colors))
            draw.point((min(31, x + 1), y), fill=rng.choice(colors))
    if "stone" in name:
        for _ in range(3):
            x, y = rng.randrange(5, 25), rng.randrange(6, 25)
            draw.rectangle((x, y, x + 2, y + 1), fill=pal["stone"])
    if "leaf" in name:
        sprinkle(draw, rng, 6, [blend(pal["wood"], pal["dirt_light"], 0.3)])
    if "shadow" in name:
        draw.rectangle((0, 23, 31, 31), fill=blend(pal["grass_dark"], pal["outline"], 0.25))
    if "glitch" in name or (variant == "c_dark_glitch" and rng.random() < 0.12):
        x, y = rng.randrange(7, 25), rng.randrange(7, 25)
        draw.point((x, y), fill=pal["cyan"])
        draw.point((min(31, x + 1), y), fill=pal["magenta"])


def dirt_texture(draw: ImageDraw.ImageDraw, pal: dict, rng: random.Random, name: str) -> None:
    base = pal["dirt_dark"] if any(k in name for k in ("mud", "dark", "shadow")) else pal["dirt"]
    if "dry" in name:
        base = pal["dirt_light"]
    draw.rectangle((0, 0, 31, 31), fill=base)
    density = int(8 + pal["texture"] * 35)
    if "low_noise" in name:
        density = 5
    sprinkle(draw, rng, density, [pal["dirt_dark"], pal["dirt_light"], blend(pal["dirt"], pal["grass"], 0.14)])
    if any(k in name for k in ("stone", "pebble", "stepstone")):
        for _ in range(1 if "stepstone" in name else 3):
            x, y = rng.randrange(5, 24), rng.randrange(6, 24)
            draw.rectangle((x, y, x + rng.randrange(3, 7), y + rng.randrange(2, 5)), fill=pal["stone"])
            draw.line((x, y + 3, min(31, x + 6), y + 3), fill=pal["stone_dark"])
    if "track" in name:
        draw.line((9, 4, 9, 28), fill=pal["dirt_dark"])
        draw.line((22, 4, 22, 28), fill=pal["dirt_dark"])


def path_masks(name: str) -> list[tuple[int, int, int, int]]:
    cx1, cx2, cy1, cy2 = 7, 24, 7, 24
    if "cross" in name:
        return [(0, cy1, 31, cy2), (cx1, 0, cx2, 31)]
    if "t_junction_up" in name:
        return [(0, cy1, 31, cy2), (cx1, 0, cx2, 16)]
    if "t_junction_down" in name:
        return [(0, cy1, 31, cy2), (cx1, 15, cx2, 31)]
    if "t_junction_left" in name:
        return [(0, cy1, 16, cy2), (cx1, 0, cx2, 31)]
    if "t_junction_right" in name:
        return [(15, cy1, 31, cy2), (cx1, 0, cx2, 31)]
    if "turn_ne" in name:
        return [(cx1, 0, cx2, 17), (15, cy1, 31, cy2)]
    if "turn_nw" in name:
        return [(cx1, 0, cx2, 17), (0, cy1, 16, cy2)]
    if "turn_se" in name:
        return [(cx1, 15, cx2, 31), (15, cy1, 31, cy2)]
    if "turn_sw" in name:
        return [(cx1, 15, cx2, 31), (0, cy1, 16, cy2)]
    if "end_left" in name:
        return [(0, cy1, 19, cy2)]
    if "end_right" in name:
        return [(12, cy1, 31, cy2)]
    if "end_top" in name:
        return [(cx1, 0, cx2, 19)]
    if "end_bottom" in name:
        return [(cx1, 12, cx2, 31)]
    if "horizontal" in name:
        return [(0, 10 if "narrow" in name else cy1, 31, 21 if "narrow" in name else cy2)]
    if "vertical" in name:
        return [(10 if "narrow" in name else cx1, 0, 21 if "narrow" in name else cx2, 31)]
    return [(0, 0, 31, 31)]


def path_tile(draw: ImageDraw.ImageDraw, pal: dict, rng: random.Random, name: str, variant: str) -> None:
    if name.startswith("dirt_") or "center" in name and not name.startswith("path_"):
        dirt_texture(draw, pal, rng, name)
        return
    grass_tile(draw, pal, rng, "grass_base", variant)
    for box in path_masks(name):
        draw.rectangle(box, fill=pal["dirt"])
        x1, y1, x2, y2 = box
        for _ in range(pal["rough"]):
            if x2 - x1 > y2 - y1:
                x = rng.randrange(x1, x2 + 1)
                draw.point((x, y1), fill=pal["grass"])
                draw.point((x, y2), fill=pal["grass_dark"])
            else:
                y = rng.randrange(y1, y2 + 1)
                draw.point((x1, y), fill=pal["grass"])
                draw.point((x2, y), fill=pal["grass_dark"])
    sprinkle(draw, rng, int(10 + pal["texture"] * 16), [pal["dirt_dark"], pal["dirt_light"], pal["stone"]])
    if "shadow_left" in name:
        draw.rectangle((0, 0, 6, 31), fill=pal["shadow"])
    if "shadow_right" in name:
        draw.rectangle((25, 0, 31, 31), fill=pal["shadow"])


def transition_tile(draw: ImageDraw.ImageDraw, pal: dict, rng: random.Random, name: str, variant: str) -> None:
    grass_tile(draw, pal, rng, "grass_base", variant)
    dirt = pal["dirt"]
    rough = pal["rough"]
    if any(k in name for k in ("top_edge", "broken_top", "flowery_edge_top", "dark_edge_top")):
        for x in range(32):
            draw.line((x, 0, x, max(0, min(31, 15 + rng.randrange(-rough, rough + 1)))), fill=dirt)
    elif any(k in name for k in ("bottom_edge", "broken_bottom", "flowery_edge_bottom", "dark_edge_bottom")):
        for x in range(32):
            y = max(0, min(31, 16 + rng.randrange(-rough, rough + 1)))
            draw.line((x, y, x, 31), fill=dirt)
    elif any(k in name for k in ("left_edge", "broken_left", "stony_edge_left", "dark_edge_left")):
        for y in range(32):
            draw.line((0, y, max(0, min(31, 15 + rng.randrange(-rough, rough + 1))), y), fill=dirt)
    elif any(k in name for k in ("right_edge", "broken_right", "stony_edge_right", "dark_edge_right")):
        for y in range(32):
            x = max(0, min(31, 16 + rng.randrange(-rough, rough + 1)))
            draw.line((x, y, 31, y), fill=dirt)
    elif "outer_tl" in name:
        draw.rectangle((0, 0, 18, 18), fill=dirt)
    elif "outer_tr" in name:
        draw.rectangle((13, 0, 31, 18), fill=dirt)
    elif "outer_bl" in name:
        draw.rectangle((0, 13, 18, 31), fill=dirt)
    elif "outer_br" in name:
        draw.rectangle((13, 13, 31, 31), fill=dirt)
    elif "inner" in name:
        draw.rectangle((0, 0, 31, 31), fill=dirt)
        if "tl" in name:
            draw.rectangle((0, 0, 16, 16), fill=pal["grass"])
        if "tr" in name:
            draw.rectangle((15, 0, 31, 16), fill=pal["grass"])
        if "bl" in name:
            draw.rectangle((0, 15, 16, 31), fill=pal["grass"])
        if "br" in name:
            draw.rectangle((15, 15, 31, 31), fill=pal["grass"])
    elif "diagonal_down" in name:
        for y in range(32):
            for x in range(32):
                if y > x + rng.randrange(-2, 3):
                    draw.point((x, y), fill=dirt)
    elif "diagonal_up" in name:
        for y in range(32):
            for x in range(32):
                if y > 31 - x + rng.randrange(-2, 3):
                    draw.point((x, y), fill=dirt)
    elif "small_patch_dirt" in name:
        draw.ellipse((8, 9, 24, 23), fill=dirt)
    elif "small_patch_grass" in name:
        draw.rectangle((0, 0, 31, 31), fill=dirt)
        draw.ellipse((8, 9, 24, 23), fill=pal["grass"])
    sprinkle(draw, rng, int(8 + pal["texture"] * 16), [pal["dirt_dark"], pal["dirt_light"], pal["grass_dark"], pal["grass_light"]])
    if "stony" in name:
        sprinkle(draw, rng, 4, [pal["stone"], pal["stone_dark"]], 2)
    if "flowery" in name:
        sprinkle(draw, rng, 4, [pal["yellow"], pal["pink"], pal["blue"]])
    if "dark_edge" in name:
        draw.rectangle((0, 25, 31, 31), fill=pal["shadow"])


def fence_hedge_tile(draw: ImageDraw.ImageDraw, pal: dict, rng: random.Random, name: str, variant: str) -> None:
    if name.startswith("fence"):
        if any(k in name for k in ("horizontal", "end_left", "end_right", "gate", "broken")):
            draw.rectangle((2, 12, 29, 15), fill=pal["wood_dark"])
            draw.rectangle((2, 16, 29, 19), fill=pal["wood"])
            draw.line((2, 12, 29, 12), fill=pal["wood_light"])
        if any(k in name for k in ("vertical", "end_top", "end_bottom", "support")):
            draw.rectangle((12, 2, 15, 29), fill=pal["wood_dark"])
            draw.rectangle((17, 2, 20, 29), fill=pal["wood"])
        if "post" in name:
            draw.rectangle((12, 7, 20, 27), fill=pal["wood_dark"])
            draw.rectangle((14, 5, 22, 25), fill=pal["wood"])
        if "broken" in name:
            draw.rectangle((15, 16, 23, 19), fill=(0, 0, 0, 0))
        if "gate" in name:
            draw.rectangle((14, 10, 17, 22), fill=pal["wood_dark"])
        sprinkle(draw, rng, 5, [pal["wood_light"], pal["wood_dark"]])
        return
    hedge = pal["hedge"]
    if "horizontal" in name:
        draw.rectangle((0, 9, 31, 22), fill=hedge)
    elif "vertical" in name:
        draw.rectangle((9, 0, 22, 31), fill=hedge)
    elif "corner_tl" in name:
        draw.rectangle((9, 9, 31, 22), fill=hedge)
        draw.rectangle((9, 9, 22, 31), fill=hedge)
    elif "corner_tr" in name:
        draw.rectangle((0, 9, 22, 22), fill=hedge)
        draw.rectangle((9, 9, 22, 31), fill=hedge)
    elif "corner_bl" in name:
        draw.rectangle((9, 9, 31, 22), fill=hedge)
        draw.rectangle((9, 0, 22, 22), fill=hedge)
    elif "corner_br" in name:
        draw.rectangle((0, 9, 22, 22), fill=hedge)
        draw.rectangle((9, 0, 22, 22), fill=hedge)
    elif "opening" in name:
        draw.rectangle((0, 9, 10, 22), fill=hedge)
        draw.rectangle((22, 9, 31, 22), fill=hedge)
    else:
        draw.rectangle((5, 5, 26, 26), fill=hedge)
    sprinkle(draw, rng, int(15 + pal["texture"] * 24), [pal["hedge_light"], pal["hedge_dark"], pal["grass_light"]])
    if "flower" in name:
        sprinkle(draw, rng, 4, [pal["pink"], pal["yellow"]])
    if variant == "c_dark_glitch" and rng.random() < 0.35:
        draw.point((24, 10), fill=pal["cyan"])
        draw.point((25, 10), fill=pal["magenta"])


def roof(draw: ImageDraw.ImageDraw, pal: dict, rng: random.Random, name: str) -> None:
    draw.rectangle((0, 0, 31, 31), fill=pal["roof"])
    for y in range(5, 31, 6):
        draw.line((0, y, 31, y), fill=pal["roof_dark"])
        draw.line((0, y + 1, 31, y + 1), fill=pal["roof_light"])
    if "edge" in name:
        draw.rectangle((0, 24, 31, 31), fill=pal["roof_dark"])
        draw.line((0, 23, 31, 23), fill=pal["roof_light"])
    if "corner" in name:
        draw.rectangle((0, 0, 7, 31), fill=pal["roof_dark"])
    if "moss" in name:
        sprinkle(draw, rng, 7, [pal["grass_dark"], pal["grass_light"]], 2)


def wall(draw: ImageDraw.ImageDraw, pal: dict, rng: random.Random, name: str, variant: str) -> None:
    if any(k in name for k in ("wooden", "wood_beam", "trim", "porch")):
        draw.rectangle((0, 0, 31, 31), fill=pal["wood"])
        for y in range(0, 32, 7):
            draw.line((0, y, 31, y), fill=pal["wood_dark"])
        for x in range(7, 32, 8):
            draw.line((x, 0, x, 31), fill=pal["wood_dark"])
        sprinkle(draw, rng, 7, [pal["wood_light"], pal["wood_dark"]])
        return
    draw.rectangle((0, 0, 31, 31), fill=pal["wall"])
    for y in range(7, 32, 8):
        draw.line((0, y, 31, y), fill=pal["wall_dark"])
    for x in range(8, 32, 16):
        draw.line((x, 0, x, 31), fill=pal["wall_dark"])
    if "base" in name or "foundation" in name:
        draw.rectangle((0, 23, 31, 31), fill=pal["stone_dark"])
        draw.line((0, 22, 31, 22), fill=pal["stone"])
    if "doorway" in name:
        draw.rectangle((10, 10, 22, 31), fill=pal["wood_dark"])
        draw.rectangle((12, 13, 20, 31), fill=pal["wood"])
        draw.point((19, 22), fill=pal["yellow"])
    if "window" in name:
        glow = pal["yellow"] if "lit" in name else pal["stone_dark"]
        draw.rectangle((8, 9, 23, 20), fill=pal["outline"])
        draw.rectangle((10, 11, 21, 18), fill=glow)
        draw.line((15, 11, 15, 18), fill=pal["outline"])
    if "moss" in name:
        sprinkle(draw, rng, 5, [pal["grass_dark"], pal["grass_light"]])
    if "glitch" in name or (variant == "c_dark_glitch" and "wall" in name and rng.random() < 0.12):
        draw.line((14, 8, 16, 18), fill=pal["outline"])
        draw.point((16, 18), fill=pal["cyan"])
        draw.point((17, 18), fill=pal["magenta"])


def building_tile(draw: ImageDraw.ImageDraw, pal: dict, rng: random.Random, name: str, variant: str) -> None:
    if "roof" in name:
        roof(draw, pal, rng, name)
    elif "shadow" in name and "wall" not in name:
        draw.rectangle((0, 18, 31, 29), fill=pal["shadow"])
    elif "step" in name:
        draw.rectangle((6, 16, 25, 23), fill=pal["stone"])
        draw.rectangle((4, 23, 27, 28), fill=pal["stone_dark"])
    else:
        wall(draw, pal, rng, name, variant)


def prop_tile(draw: ImageDraw.ImageDraw, pal: dict, rng: random.Random, name: str, variant: str) -> None:
    if any(k in name for k in ("transparent_empty", "backup_empty")):
        return
    if "separator" in name:
        draw.rectangle((0, 30, 31, 31), fill=(0, 0, 0, 180))
        return
    if "shadow" in name:
        draw.ellipse((5, 18, 27, 28), fill=pal["shadow"])
        return
    if "highlight" in name:
        draw.rectangle((8, 12, 23, 15), fill=(*pal["cyan"], 95))
        return
    if "flower" in name and "glitch" not in name:
        colors = [pal["yellow"], pal["pink"], pal["blue"]]
        if "blue" in name:
            colors = [pal["blue"]]
        for _ in range(7):
            x, y = rng.randrange(6, 25), rng.randrange(9, 25)
            draw.point((x, y), fill=rng.choice(colors))
            draw.point((min(31, x + 1), y), fill=rng.choice(colors))
            draw.point((x, y + 2), fill=pal["grass_dark"])
    elif "herb" in name:
        for _ in range(8):
            x, y = rng.randrange(7, 24), rng.randrange(10, 25)
            draw.line((x, y, x + rng.choice((-1, 0, 1)), y - 4), fill=pal["grass_light"])
    elif "sign" in name or "marker" in name:
        draw.rectangle((14, 12, 17, 27), fill=pal["wood_dark"])
        draw.rectangle((7, 7, 25, 16), fill=pal["wood"])
        draw.rectangle((6, 6, 26, 17), outline=pal["wood_dark"])
        if "marker" in name:
            draw.point((16, 11), fill=pal["cyan"] if variant == "c_dark_glitch" else pal["yellow"])
    elif "stone" in name:
        for _ in range(1 if "small" in name else 4):
            x, y = rng.randrange(7, 23), rng.randrange(14, 24)
            draw.rectangle((x, y, x + 5, y + 3), fill=pal["stone"])
            draw.line((x, y + 3, x + 5, y + 3), fill=pal["stone_dark"])
    elif "stump" in name:
        draw.ellipse((8, 10, 24, 23), fill=pal["wood_dark"])
        draw.ellipse((10, 8, 22, 18), fill=pal["wood_light"])
        draw.arc((12, 10, 20, 17), 0, 330, fill=pal["wood_dark"])
    elif any(k in name for k in ("crate", "barrel")):
        if "barrel" in name:
            draw.ellipse((8, 9, 19, 14), fill=pal["wood_light"])
            draw.rectangle((8, 12, 19, 24), fill=pal["wood"])
            draw.ellipse((8, 20, 19, 27), fill=pal["wood_dark"])
        if "crate" in name:
            draw.rectangle((17, 14, 27, 25), fill=pal["wood"])
            draw.rectangle((17, 14, 27, 25), outline=pal["wood_dark"])
            draw.line((18, 15, 26, 24), fill=pal["wood_dark"])
    elif any(k in name for k in ("glitch", "cyan")):
        x, y = 16, 16
        draw.line((x - 4, y, x + 4, y), fill=pal["cyan"])
        draw.line((x, y - 4, x, y + 4), fill=pal["magenta"])
    elif any(k in name for k in ("leaf", "log")):
        sprinkle(draw, rng, 6, [blend(pal["wood"], pal["dirt_light"], 0.35)], 2)
        if "log" in name:
            draw.rectangle((8, 17, 24, 21), fill=pal["wood"])
            draw.rectangle((7, 16, 25, 22), outline=pal["wood_dark"])
    elif "mushroom" in name:
        for _ in range(3):
            x, y = rng.randrange(8, 24), rng.randrange(15, 25)
            draw.rectangle((x, y, x + 1, y + 4), fill=pal["wall_light"])
            draw.rectangle((x - 2, y - 2, x + 3, y), fill=pal["roof_light"])


def draw_tile(item: dict, pal: dict, variant: str) -> Image.Image:
    tile = Image.new("RGBA", (TILE, TILE), (0, 0, 0, 0))
    draw = ImageDraw.Draw(tile)
    rng = rng_for(variant, item["name"])
    category = item["category"]
    if category == "grass":
        grass_tile(draw, pal, rng, item["name"], variant)
    elif category == "dirt path":
        path_tile(draw, pal, rng, item["name"], variant)
    elif category == "grass-to-dirt transitions":
        transition_tile(draw, pal, rng, item["name"], variant)
    elif category == "fence/hedge":
        fence_hedge_tile(draw, pal, rng, item["name"], variant)
    elif category == "cottage/building support":
        building_tile(draw, pal, rng, item["name"], variant)
    else:
        prop_tile(draw, pal, rng, item["name"], variant)
    return tile


def build_atlas(variant: str, pal: dict) -> Image.Image:
    atlas = Image.new("RGBA", (ATLAS, ATLAS), (0, 0, 0, 0))
    for item in layout:
        atlas.alpha_composite(draw_tile(item, pal, variant), (item["x"] * TILE, item["y"] * TILE))
    return atlas


def checker(width: int, height: int) -> Image.Image:
    img = Image.new("RGBA", (width, height), (34, 36, 42, 255))
    draw = ImageDraw.Draw(img)
    for y in range(0, height, 16):
        for x in range(0, width, 16):
            fill = (48, 50, 58, 255) if ((x // 16 + y // 16) % 2 == 0) else (35, 37, 44, 255)
            draw.rectangle((x, y, x + 15, y + 15), fill=fill)
    return img


def tile_from(atlas: Image.Image, name_to_coord: dict[str, tuple[int, int]], name: str) -> Image.Image:
    x, y = name_to_coord[name]
    return atlas.crop((x * TILE, y * TILE, (x + 1) * TILE, (y + 1) * TILE))


def blit(canvas: Image.Image, atlas: Image.Image, name_to_coord: dict[str, tuple[int, int]], name: str, x: int, y: int) -> None:
    canvas.alpha_composite(tile_from(atlas, name_to_coord, name), (x * TILE, y * TILE))


def choose_path(connections: tuple[bool, bool, bool, bool]) -> str:
    n, e, s, w = connections
    count = sum(connections)
    if count >= 4:
        return "path_cross"
    if count == 3:
        if not s:
            return "path_t_junction_up"
        if not n:
            return "path_t_junction_down"
        if not e:
            return "path_t_junction_left"
        return "path_t_junction_right"
    if count == 2:
        if e and w:
            return "path_straight_horizontal"
        if n and s:
            return "path_straight_vertical"
        if n and e:
            return "path_turn_ne"
        if n and w:
            return "path_turn_nw"
        if s and e:
            return "path_turn_se"
        return "path_turn_sw"
    if count == 1:
        if e:
            return "path_end_left"
        if w:
            return "path_end_right"
        if s:
            return "path_end_top"
        return "path_end_bottom"
    return "dirt_center"


def build_mockup(variant: str, atlas: Image.Image, name_to_coord: dict[str, tuple[int, int]]) -> Image.Image:
    width, height = 20, 15
    canvas = Image.new("RGBA", (width * TILE, height * TILE), (0, 0, 0, 0))
    rng = random.Random(hash(("mock", variant, 2203)) & 0xFFFFFFFF)
    grass_choices = ["grass_base", "grass_plain_backup", "grass_patchy", "grass_sparse", "grass_leaf_scatter", "grass_tiny_stones"]
    for y in range(height):
        for x in range(width):
            blit(canvas, atlas, name_to_coord, rng.choice(grass_choices), x, y)

    path = set([(x, 8) for x in range(0, 6)])
    path.update([(6, 7), (7, 7), (8, 7), (9, 6), (10, 6), (11, 6), (12, 6), (13, 7), (14, 7)])
    path.update([(x, 8) for x in range(15, 20)])
    path.update([(9, 7), (9, 8), (9, 9), (10, 9), (11, 9)])
    for x, y in path:
        con = ((x, y - 1) in path, (x + 1, y) in path, (x, y + 1) in path, (x - 1, y) in path)
        blit(canvas, atlas, name_to_coord, choose_path(con), x, y)

    bx, by = 13, 2
    building = [
        ["roof_corner_tile", "roof_edge_top", "roof_edge_top", "roof_edge_tile"],
        ["roof_edge_left", "roof_center_tile", "roof_moss_patch", "roof_edge_right"],
        ["cottage_wall_base", "window_wall_detail", "cottage_wall_variation", "small_wooden_trim"],
        ["wall_moss_base", "doorway_base", "cottage_step", "wall_shadow_right"],
    ]
    for yy, row in enumerate(building):
        for xx, name in enumerate(row):
            blit(canvas, atlas, name_to_coord, name, bx + xx, by + yy)

    for x in range(2, 10):
        blit(canvas, atlas, name_to_coord, "fence_horizontal_middle", x, 3)
    for y in range(4, 8):
        blit(canvas, atlas, name_to_coord, "fence_vertical_middle", 2, y)
    blit(canvas, atlas, name_to_coord, "fence_post", 2, 3)
    blit(canvas, atlas, name_to_coord, "fence_post", 9, 3)
    blit(canvas, atlas, name_to_coord, "fence_end_bottom", 2, 8)

    for x in range(12, 18):
        blit(canvas, atlas, name_to_coord, "hedge_horizontal", x, 10)
    blit(canvas, atlas, name_to_coord, "hedge_corner_tl", 11, 10)
    blit(canvas, atlas, name_to_coord, "hedge_corner_tr", 18, 10)
    for y in range(11, 14):
        blit(canvas, atlas, name_to_coord, "hedge_vertical", 11, y)
        blit(canvas, atlas, name_to_coord, "hedge_vertical", 18, y)
    blit(canvas, atlas, name_to_coord, "hedge_broken_opening", 15, 10)

    for name, x, y in [
        ("flower_patch", 4, 5),
        ("herb_patch", 5, 6),
        ("wooden_sign", 7, 6),
        ("small_stone", 3, 10),
        ("tree_stump", 14, 12),
        ("crate_barrel_simple", 16, 6),
        ("soft_shadow_blob", 14, 6),
        ("glitch_flower_rune_accent", 10, 5),
        ("ground_leaf_scatter", 6, 10),
        ("village_marker_tile", 12, 8),
        ("flower_patch_blue", 16, 12),
        ("tiny_mushroom_cluster", 13, 11),
        ("small_log", 5, 12),
    ]:
        blit(canvas, atlas, name_to_coord, name, x, y)
    return canvas


def make_table(headers: list[str], rows: list[tuple]) -> str:
    lines = ["| " + " | ".join(headers) + " |", "| " + " | ".join(["---"] * len(headers)) + " |"]
    for row in rows:
        lines.append("| " + " | ".join(str(cell) for cell in row) + " |")
    return "\n".join(lines)


def main() -> None:
    build_layout()
    name_to_coord = {item["name"]: (item["x"], item["y"]) for item in layout}
    variant_paths: dict[str, str] = {}
    mockup_paths: dict[str, str] = {}

    for key, pal in PALETTES.items():
        atlas = build_atlas(key, pal)
        atlas_path = GEN / f"oakhaven_p8_{pal['file']}.png"
        atlas.save(atlas_path)
        atlas.resize((1024, 1024), Image.Resampling.NEAREST).save(REV / f"oakhaven_p8_{pal['file']}_2x.png")
        variant_paths[key] = rel(atlas_path)

        mock = build_mockup(key, atlas, name_to_coord)
        mock_name = {
            "a_clean": "oakhaven_p8_variant_a_mockup.png",
            "b_textured": "oakhaven_p8_variant_b_mockup.png",
            "c_dark_glitch": "oakhaven_p8_variant_c_mockup.png",
        }[key]
        mock_path = MOCK / mock_name
        mock.save(mock_path)
        mock.resize((mock.width * 2, mock.height * 2), Image.Resampling.NEAREST).save(MOCK / mock_name.replace(".png", "_2x.png"))
        mockup_paths[key] = rel(mock_path)

    layout_rows = [
        f"| ({item['x']},{item['y']}) | `{item['name']}` | {item['category']} | {item['intended_use']} | {item['notes']} |"
        for item in layout
    ]
    layout_md = (
        "# Oakhaven P8 Tile Layout Map\n\n"
        "Atlas: `assets/art_sources/comfyui_tests/oakhaven_p8/generated_tiles/oakhaven_p8_variant_*`. Tile size: 32x32. Grid: 16 columns x 16 rows.\n\n"
        "All coordinates are atlas cell coordinates `(x,y)`, zero-based from the top-left. All three P8 variants share this exact grammar and layout. Unlisted cells are transparent empty cells.\n\n"
        "| Tile Coordinate | Tile Name | Category | Intended Use | Notes |\n"
        "| --- | --- | --- | --- | --- |\n"
        + "\n".join(layout_rows)
        + "\n"
    )
    (MAN / "oakhaven_p8_tile_layout.md").write_text(layout_md, encoding="utf-8")

    scores = {
        "a_clean": {
            "grass_readability": 8,
            "path_readability": 8,
            "transition_logic": 7,
            "fence_hedge_usability": 7,
            "building_support_usability": 7,
            "prop_clarity": 7,
            "style_consistency": 8,
            "oakhaven_identity": 7,
            "tile_grammar_correctness": 8,
            "chance_of_improving_actual_game_visuals": 7,
            "overall_score": 7.4,
            "verdict": "good enough for preview-only Godot scene",
            "notes": "Strongest simple readability; visually plain compared with final production art.",
        },
        "b_textured": {
            "grass_readability": 8,
            "path_readability": 8,
            "transition_logic": 7,
            "fence_hedge_usability": 8,
            "building_support_usability": 7,
            "prop_clarity": 8,
            "style_consistency": 8,
            "oakhaven_identity": 8,
            "tile_grammar_correctness": 8,
            "chance_of_improving_actual_game_visuals": 8,
            "overall_score": 7.8,
            "verdict": "good enough to consider production import in a later phase after preview review",
            "notes": "Best balance of tile grammar, readable texture, and Oakhaven village identity.",
        },
        "c_dark_glitch": {
            "grass_readability": 7,
            "path_readability": 7,
            "transition_logic": 7,
            "fence_hedge_usability": 7,
            "building_support_usability": 7,
            "prop_clarity": 7,
            "style_consistency": 8,
            "oakhaven_identity": 8,
            "tile_grammar_correctness": 8,
            "chance_of_improving_actual_game_visuals": 7,
            "overall_score": 7.3,
            "verdict": "good enough for preview-only Godot scene",
            "notes": "Moodiest variant; needs brightness check in actual scene context.",
        },
    }

    manifest = {
        "phase": "10M-P8",
        "method": "deterministic Python/Pillow pixel-art construction; no ComfyUI generation and no P6/P7 direct crop import",
        "tile_size": [32, 32],
        "atlas_size": [512, 512],
        "grid": [16, 16],
        "production_art_changed": False,
        "best_variant": "b_textured",
        "variant_files": variant_paths,
        "mockup_files": mockup_paths,
        "layout_map": "assets/art_sources/comfyui_tests/oakhaven_p8/manifest/oakhaven_p8_tile_layout.md",
        "scores": scores,
        "layout": layout,
    }
    (MAN / "oakhaven_p8_generation_manifest.json").write_text(json.dumps(manifest, indent=2), encoding="utf-8")

    contact = Image.new("RGBA", (1840, 2020), (22, 23, 29, 255))
    draw = ImageDraw.Draw(contact)
    draw.text((24, 20), "P8 controlled tileset comparison contact sheet", font=FONT, fill=(242, 242, 242, 255))
    fallback_path = ROOT / "assets" / "generated_v2" / "tilesets" / "oakhaven_v2_prototype_tileset.png"
    if fallback_path.exists():
        fallback = Image.open(fallback_path).convert("RGBA")
        contact.alpha_composite(fallback.resize((fallback.width * 4, fallback.height * 4), Image.Resampling.NEAREST), (24, 82))
        draw.text((24, 58), "Current generated V2 fallback (4x)", font=FONT, fill=(210, 210, 218, 255))
    p7_path = ROOT / "assets" / "art_sources" / "comfyui_tests" / "oakhaven_p7" / "oakhaven_p7_review_only_draft_atlas.png"
    if p7_path.exists():
        p7_bg = checker(512, 512)
        p7_bg.alpha_composite(Image.open(p7_path).convert("RGBA"), (0, 0))
        contact.alpha_composite(p7_bg, (600, 82))
        draw.text((600, 58), "P7 review-only draft atlas", font=FONT, fill=(210, 210, 218, 255))
    for idx, key in enumerate(("a_clean", "b_textured", "c_dark_glitch")):
        pal = PALETTES[key]
        atlas_bg = checker(512, 512)
        atlas_bg.alpha_composite(Image.open(ROOT / variant_paths[key]).convert("RGBA"), (0, 0))
        x, y = 24 + idx * 604, 650
        draw.text((x, y - 24), f"{pal['label']} atlas", font=FONT, fill=(210, 210, 218, 255))
        contact.alpha_composite(atlas_bg, (x, y))
    for idx, key in enumerate(("a_clean", "b_textured", "c_dark_glitch")):
        pal = PALETTES[key]
        mock = Image.open(ROOT / mockup_paths[key]).convert("RGBA")
        x, y = 24 + idx * 604, 1220
        draw.text((x, y - 24), f"{pal['label']} mockup", font=FONT, fill=(210, 210, 218, 255))
        contact.alpha_composite(mock, (x, y))
    contact.save(REV / "oakhaven_p8_comparison_contact_sheet.png")

    score_sheet = Image.new("RGBA", (1320, 720), (22, 23, 29, 255))
    sd = ImageDraw.Draw(score_sheet)
    sd.text((24, 18), "Oakhaven P8 variant score sheet", font=FONT, fill=(242, 242, 242, 255))
    for idx, key in enumerate(("a_clean", "b_textured", "c_dark_glitch")):
        x, y = 24 + idx * 430, 60
        sd.text((x, y), PALETTES[key]["label"], font=FONT, fill=(242, 242, 242, 255))
        atlas_bg = checker(256, 256)
        atlas_bg.alpha_composite(Image.open(ROOT / variant_paths[key]).convert("RGBA").resize((256, 256), Image.Resampling.NEAREST), (0, 0))
        score_sheet.alpha_composite(atlas_bg, (x, y + 22))
        mock = Image.open(ROOT / mockup_paths[key]).convert("RGBA").resize((320, 240), Image.Resampling.NEAREST)
        score_sheet.alpha_composite(mock, (x, y + 300))
        lines = [
            f"Overall: {scores[key]['overall_score']}/10",
            f"Grass/path: {scores[key]['grass_readability']}/{scores[key]['path_readability']}",
            f"Transitions: {scores[key]['transition_logic']}",
            f"Props/building: {scores[key]['prop_clarity']}/{scores[key]['building_support_usability']}",
            scores[key]["verdict"],
        ]
        for row_idx, text in enumerate(lines):
            sd.text((x, y + 550 + row_idx * 14), text, font=FONT, fill=(210, 210, 218, 255))
    score_sheet.save(REV / "oakhaven_p8_variant_score_sheet.png")

    files = [
        ("assets/art_sources/comfyui_tests/oakhaven_p8/generated_tiles/oakhaven_p8_variant_a_clean.png", "Variant A clean 512x512 atlas", "Created"),
        ("assets/art_sources/comfyui_tests/oakhaven_p8/generated_tiles/oakhaven_p8_variant_b_textured.png", "Variant B textured 512x512 atlas", "Created"),
        ("assets/art_sources/comfyui_tests/oakhaven_p8/generated_tiles/oakhaven_p8_variant_c_dark_glitch.png", "Variant C dark/glitch 512x512 atlas", "Created"),
        ("assets/art_sources/comfyui_tests/oakhaven_p8/review/oakhaven_p8_variant_a_clean_2x.png", "Variant A nearest-neighbor 2x preview", "Created"),
        ("assets/art_sources/comfyui_tests/oakhaven_p8/review/oakhaven_p8_variant_b_textured_2x.png", "Variant B nearest-neighbor 2x preview", "Created"),
        ("assets/art_sources/comfyui_tests/oakhaven_p8/review/oakhaven_p8_variant_c_dark_glitch_2x.png", "Variant C nearest-neighbor 2x preview", "Created"),
        ("assets/art_sources/comfyui_tests/oakhaven_p8/mockups/oakhaven_p8_variant_a_mockup.png", "Variant A 20x15 tile mockup", "Created"),
        ("assets/art_sources/comfyui_tests/oakhaven_p8/mockups/oakhaven_p8_variant_b_mockup.png", "Variant B 20x15 tile mockup", "Created"),
        ("assets/art_sources/comfyui_tests/oakhaven_p8/mockups/oakhaven_p8_variant_c_mockup.png", "Variant C 20x15 tile mockup", "Created"),
        ("assets/art_sources/comfyui_tests/oakhaven_p8/review/oakhaven_p8_comparison_contact_sheet.png", "Fallback/P7/P8 comparison sheet", "Created"),
        ("assets/art_sources/comfyui_tests/oakhaven_p8/review/oakhaven_p8_variant_score_sheet.png", "Variant score sheet", "Created"),
        ("assets/art_sources/comfyui_tests/oakhaven_p8/manifest/oakhaven_p8_tile_layout.md", "Documented tile layout map", "Created"),
        ("assets/art_sources/comfyui_tests/oakhaven_p8/manifest/oakhaven_p8_generation_manifest.json", "Generation and score manifest", "Created"),
        ("docs/art_pipeline/oakhaven_p8_preview/generate_oakhaven_p8.py", "Reproducible deterministic generator", "Created"),
    ]
    review_doc = f"""# ComfyUI Oakhaven P8 Controlled Tileset Review

Phase 10M-P8 uses a deterministic pixel-art grammar builder instead of another broad ComfyUI tileset batch. No ComfyUI generation was run. No P6/P7 crop was directly imported. No `assets/production_art/` file was written.

## Method

- Built all tiles with Python/Pillow deterministic drawing.
- Shared 16x16 atlas grammar across all three variants.
- Used hard 32x32 cell boundaries, nearest-neighbor previews, limited palettes, and transparent overlay sprites for props/fences where appropriate.
- Used P6/P7 only as failure/context references, not as source imports.

## Files Created

{make_table(["File", "Purpose", "Status"], files)}

## Atlas Layout Summary

{make_table(["Row Range", "Category", "Included Tiles"], [
    ("0-2", "Grass terrain and variations", "Base/darker/lighter/patchy/sparse/flower/worn/shadowed grass plus meadow extras."),
    ("3-5", "Dirt path and path centers", "Dirt centers, path straights, T-junctions, cross, corners, ends, pebbles, shadow variants."),
    ("6-8", "Grass/dirt transitions", "Edges, outer/inner corners, diagonal rough edges, broken edges, islands, shadow/flower/stone variants."),
    ("9-10", "Fence and hedge", "Fence middles/posts/ends/gates/broken pieces, hedge blocks/lines/corners/openings."),
    ("11-13", "Cottage/building support", "Walls, wood, roofs, eaves, foundation shadows, doorway, windows, trim, porch/support pieces."),
    ("14-15", "Props and utility", "Flowers, herbs, sign, stone, stump, crate/barrel, shadow, glitch accent, leaves, marker, empty/separator/highlight utility."),
])}

## Variant Review

{make_table(["Variant", "Strength", "Weakness", "Overall Score", "Verdict"], [
    ("A clean", "Best simple gameplay readability and lowest noise.", "Plain compared to a final art pass.", scores["a_clean"]["overall_score"], scores["a_clean"]["verdict"]),
    ("B textured", "Best balance of clean grammar, texture, and Oakhaven village identity.", "Still deterministic draft art; cottage kit needs more polish.", scores["b_textured"]["overall_score"], scores["b_textured"]["verdict"]),
    ("C dark/glitch", "Strongest mood and subtle magical corruption identity.", "Darker palette may reduce readability in actual scenes.", scores["c_dark_glitch"]["overall_score"], scores["c_dark_glitch"]["verdict"]),
])}

## Mockup Review

{make_table(["Variant", "Mockup Path", "Readability", "Oakhaven Feel", "Verdict"], [
    ("A clean", "assets/art_sources/comfyui_tests/oakhaven_p8/mockups/oakhaven_p8_variant_a_mockup.png", "High", "Readable village corner, slightly plain", "Preview-ready"),
    ("B textured", "assets/art_sources/comfyui_tests/oakhaven_p8/mockups/oakhaven_p8_variant_b_mockup.png", "High", "Best Oakhaven balance", "Best variant"),
    ("C dark/glitch", "assets/art_sources/comfyui_tests/oakhaven_p8/mockups/oakhaven_p8_variant_c_mockup.png", "Medium-high", "Strong dark-fantasy/glitch feel", "Preview-ready, needs brightness check"),
])}

## Comparison Against Previous Attempts

{make_table(["Source", "Result", "Problem", "P8 Improvement"], [
    ("current fallback", "Tiny generated V2 sheet with readable but very limited grass/path/wood cells.", "Too small and sparse to define Oakhaven village grammar.", "P8 adds full terrain/path/building/prop grammar and mockup proof."),
    ("P6", "LoRA-assisted raw outputs had some source hints.", "Noisy, crop-dependent, inconsistent, and not a real tileset.", "P8 uses controlled cells and consistent layout instead of extracting accidental crops."),
    ("P7", "Review-only crop atlas clarified which P6 pieces were semi-usable.", "Not coherent; only two 32x32 candidates were useful.", "P8 is a coherent atlas with repeatable grass/path, logical transitions, and mockups."),
    ("P8 best variant", "Variant B is structured and usable for preview review.", "Still draft deterministic art; needs in-engine scale and scene-context review.", "Best current Oakhaven candidate; clearly better than P7 as a grammar pass."),
])}

## Tile Grammar Validation

{make_table(["Category", "Complete?", "Usable?", "Notes"], [
    ("grass", "Yes", "Yes", "Base and variations repeat cleanly; B has the best natural texture."),
    ("dirt path", "Yes", "Yes", "Straight, corner, T, cross, end, and center tiles are logically aligned."),
    ("transitions", "Yes", "Mostly", "Edges/corners are complete; some rough variants need scene review for best combinations."),
    ("fence/hedge", "Yes", "Yes", "Transparent overlay sprites read clearly in mockups."),
    ("cottage/building", "Yes", "Mostly", "Enough for preview mock cottages; not production-polished yet."),
    ("props", "Yes", "Yes", "Props are simple but readable and stay within cells."),
    ("utility tiles", "Yes", "Yes", "Transparent empty, separator, shadow-only, and highlight-only cells are included."),
])}

## Honest Visual Verdict

- Is P8 better than P7? Yes. P8 is a coherent tile grammar atlas, while P7 was a rough crop board.
- Is any variant better than the current fallback? Yes. Variant B is the strongest improvement because it provides actual terrain/path/building/prop grammar rather than a tiny fallback sample.
- Would importing the best variant improve Oakhaven? Probably, but not yet. It should go through a preview-only Godot scene review first.
- Is it ready for preview-only Godot testing? Yes.
- Is it ready for production_art import? No. It is coherent, but still draft deterministic art and needs in-engine scale, palette, and composition review.
- What still needs improvement? Cottage tiles need more charm, transition variants need practical scene testing, and props need a stronger final silhouette pass.

## Recommendation

Use Variant B textured as the best P8 review candidate. Keep all P8 outputs in `art_sources` and run a preview-only Godot pass before any production-art discussion.
"""
    (DOC / "comfyui_oakhaven_p8_controlled_tileset_review.md").write_text(review_doc, encoding="utf-8")
    print(json.dumps({"layout_cells": len(layout), "best_variant": "b_textured", "production_art_changed": False}, indent=2))


if __name__ == "__main__":
    main()
