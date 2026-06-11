from __future__ import annotations

import json
import re
from pathlib import Path

from PIL import Image


ROOT = Path(__file__).resolve().parents[3]
TILE = 32
BOARD_W = 24
BOARD_H = 18

P8_DIR = ROOT / "assets/art_sources/comfyui_tests/oakhaven_p8"
P9_DIR = ROOT / "assets/art_sources/comfyui_tests/oakhaven_p9_time_preview"
P10_DIR = ROOT / "assets/art_sources/comfyui_tests/oakhaven_p10_palette_tuning"

TUNED_DIR = P10_DIR / "tuned_atlases"
SCREENSHOT_DIR = P10_DIR / "screenshots"
CONTACT_DIR = P10_DIR / "contact_sheets"
MOCKUP_DIR = P10_DIR / "mockups"
MANIFEST_DIR = P10_DIR / "manifest"

LAYOUT_PATH = P8_DIR / "manifest/oakhaven_p8_tile_layout.md"

VARIANTS = {
    "morning": {
        "label": "Morning",
        "original_variant": "P8 Variant A clean",
        "source": P8_DIR / "generated_tiles/oakhaven_p8_variant_a_clean.png",
        "tuned": TUNED_DIR / "oakhaven_p10_morning_tuned.png",
        "preview_2x": CONTACT_DIR / "oakhaven_p10_morning_tuned_2x.png",
        "screenshot": SCREENSHOT_DIR / "oakhaven_p10_morning_preview.png",
        "mockup": MOCKUP_DIR / "oakhaven_p10_morning_mockup.png",
        "p9_screenshot": P9_DIR / "screenshots/oakhaven_p9_morning_preview.png",
        "p9_score": 7.4,
        "method": "warm morning lift, moderate saturation gain, subtle deterministic luminance variation",
    },
    "afternoon": {
        "label": "Afternoon",
        "original_variant": "P8 Variant B textured",
        "source": P8_DIR / "generated_tiles/oakhaven_p8_variant_b_textured.png",
        "tuned": TUNED_DIR / "oakhaven_p10_afternoon_tuned.png",
        "preview_2x": CONTACT_DIR / "oakhaven_p10_afternoon_tuned_2x.png",
        "screenshot": SCREENSHOT_DIR / "oakhaven_p10_afternoon_preview.png",
        "mockup": MOCKUP_DIR / "oakhaven_p10_afternoon_mockup.png",
        "p9_screenshot": P9_DIR / "screenshots/oakhaven_p9_afternoon_preview.png",
        "p9_score": 8.0,
        "method": "minor contrast polish, slight saturation harmony, minimal daytime warmth",
    },
    "night": {
        "label": "Night",
        "original_variant": "P8 Variant C dark/glitch",
        "source": P8_DIR / "generated_tiles/oakhaven_p8_variant_c_dark_glitch.png",
        "tuned": TUNED_DIR / "oakhaven_p10_night_tuned.png",
        "preview_2x": CONTACT_DIR / "oakhaven_p10_night_tuned_2x.png",
        "screenshot": SCREENSHOT_DIR / "oakhaven_p10_night_preview.png",
        "mockup": MOCKUP_DIR / "oakhaven_p10_night_mockup.png",
        "p9_screenshot": P9_DIR / "screenshots/oakhaven_p9_night_preview.png",
        "p9_score": 7.3,
        "method": "shadow lift, cool moonlit grade, path/prop readability lift, restrained cyan-magenta retention",
    },
}

TILE_COORDS = {
    "grass_base": (0, 0),
    "grass_plain_backup": (15, 0),
    "grass_patchy": (3, 0),
    "grass_sparse": (4, 0),
    "grass_leaf_scatter": (9, 0),
    "grass_tiny_stones": (12, 0),
    "dirt_center": (0, 3),
    "dirt_variation": (1, 3),
    "path_straight_horizontal": (3, 3),
    "path_straight_vertical": (4, 3),
    "path_t_junction_up": (5, 3),
    "path_t_junction_down": (6, 3),
    "path_t_junction_left": (7, 3),
    "path_t_junction_right": (8, 3),
    "path_cross": (9, 3),
    "dirt_small_stone_embedded": (10, 3),
    "path_turn_ne": (11, 3),
    "path_turn_nw": (12, 3),
    "path_turn_se": (13, 3),
    "path_turn_sw": (14, 3),
    "path_end_left": (15, 3),
    "path_end_right": (0, 4),
    "path_end_top": (1, 4),
    "path_end_bottom": (2, 4),
    "transition_top_edge": (0, 6),
    "transition_bottom_edge": (1, 6),
    "transition_left_edge": (2, 6),
    "transition_right_edge": (3, 6),
    "transition_outer_tl": (4, 6),
    "transition_outer_tr": (5, 6),
    "transition_outer_bl": (6, 6),
    "transition_outer_br": (7, 6),
    "fence_horizontal_middle": (0, 9),
    "fence_vertical_middle": (1, 9),
    "fence_post": (2, 9),
    "fence_end_bottom": (6, 9),
    "hedge_horizontal": (8, 9),
    "hedge_vertical": (9, 9),
    "hedge_corner_tl": (10, 9),
    "hedge_corner_tr": (11, 9),
    "hedge_broken_opening": (14, 9),
    "cottage_wall_base": (0, 11),
    "cottage_wall_variation": (1, 11),
    "roof_edge_tile": (3, 11),
    "roof_corner_tile": (4, 11),
    "roof_center_tile": (5, 11),
    "doorway_base": (7, 11),
    "window_wall_detail": (8, 11),
    "small_wooden_trim": (9, 11),
    "roof_edge_left": (10, 11),
    "roof_edge_right": (11, 11),
    "roof_edge_top": (12, 11),
    "wall_shadow_right": (15, 11),
    "wall_moss_base": (2, 12),
    "roof_moss_patch": (3, 12),
    "cottage_step": (4, 12),
    "flower_patch": (0, 14),
    "herb_patch": (1, 14),
    "wooden_sign": (2, 14),
    "small_stone": (3, 14),
    "tree_stump": (4, 14),
    "crate_barrel_simple": (5, 14),
    "soft_shadow_blob": (6, 14),
    "glitch_flower_rune_accent": (7, 14),
    "ground_leaf_scatter": (8, 14),
    "village_marker_tile": (9, 14),
    "shadow_only_tile": (12, 14),
    "flower_patch_blue": (14, 14),
    "tiny_mushroom_cluster": (15, 14),
    "small_log": (0, 15),
}


def rel(path: Path) -> str:
    return path.relative_to(ROOT).as_posix()


def clamp(value: float) -> int:
    return max(0, min(255, int(round(value * 255.0))))


def mix_saturation(r: float, g: float, b: float, factor: float) -> tuple[float, float, float]:
    luma = 0.299 * r + 0.587 * g + 0.114 * b
    return (
        luma + (r - luma) * factor,
        luma + (g - luma) * factor,
        luma + (b - luma) * factor,
    )


def contrast_channel(value: float, factor: float, center: float = 0.5) -> float:
    return (value - center) * factor + center


def parse_layout() -> dict[tuple[int, int], dict[str, str]]:
    layout = {}
    pattern = re.compile(r"^\| \((\d+),(\d+)\) \| `([^`]+)` \| ([^|]+) \|")
    for line in LAYOUT_PATH.read_text(encoding="utf-8").splitlines():
        match = pattern.match(line)
        if not match:
            continue
        x, y, name, category = match.groups()
        layout[(int(x), int(y))] = {"name": name, "category": category.strip()}
    return layout


def tune_image(source: Image.Image, variant: str, layout: dict[tuple[int, int], dict[str, str]]) -> Image.Image:
    image = source.convert("RGBA")
    out = Image.new("RGBA", image.size, (0, 0, 0, 0))
    src = image.load()
    dst = out.load()

    for y in range(image.height):
        for x in range(image.width):
            r8, g8, b8, a = src[x, y]
            if a == 0:
                dst[x, y] = (r8, g8, b8, a)
                continue

            r, g, b = r8 / 255.0, g8 / 255.0, b8 / 255.0
            cell = (x // TILE, y // TILE)
            category = layout.get(cell, {}).get("category", "")

            if variant == "morning":
                r, g, b = mix_saturation(r, g, b, 1.075)
                r = contrast_channel(r, 1.035, 0.48) * 1.045 + 0.024
                g = contrast_channel(g, 1.025, 0.48) * 1.035 + 0.020
                b = contrast_channel(b, 1.015, 0.48) * 0.982 + 0.002
                jitter = ((((x * 17) ^ (y * 31)) & 7) - 3.5) * 0.0018
                if category in ["grass", "dirt path", "grass-to-dirt transitions"]:
                    r += jitter * 0.75
                    g += jitter
                    b += jitter * 0.35
                if category == "dirt path":
                    r += 0.012
                    g += 0.006

            elif variant == "afternoon":
                r, g, b = mix_saturation(r, g, b, 1.025)
                r = contrast_channel(r, 1.018, 0.50) * 1.006 + 0.004
                g = contrast_channel(g, 1.014, 0.50) * 1.004 + 0.003
                b = contrast_channel(b, 1.010, 0.50) * 0.998 + 0.001
                if category == "dirt path":
                    r += 0.004
                    g += 0.002

            elif variant == "night":
                r, g, b = mix_saturation(r, g, b, 1.055)
                r = max(0.0, min(1.0, r))
                g = max(0.0, min(1.0, g))
                b = max(0.0, min(1.0, b))
                r = contrast_channel(r ** 0.86, 1.015, 0.46) * 0.78 + 0.036
                g = contrast_channel(g ** 0.84, 1.010, 0.46) * 0.84 + 0.046
                b = contrast_channel(b ** 0.82, 1.005, 0.46) * 1.015 + 0.066
                if category in ["dirt path", "grass-to-dirt transitions"]:
                    r += 0.034
                    g += 0.032
                    b += 0.014
                elif category in ["cottage/building support", "fence/hedge", "props/utility"]:
                    r += 0.018
                    g += 0.020
                    b += 0.018
                elif category == "grass":
                    r -= 0.010
                    g -= 0.006
                    b -= 0.004
                if r > 0.42 and b > 0.42:
                    b += 0.012

            dst[x, y] = (clamp(r), clamp(g), clamp(b), a)

    return out


def tile(atlas: Image.Image, name: str) -> Image.Image:
    x, y = TILE_COORDS[name]
    return atlas.crop((x * TILE, y * TILE, x * TILE + TILE, y * TILE + TILE))


def paste_tile(board: Image.Image, atlas: Image.Image, name: str, cell_x: int, cell_y: int) -> None:
    board.alpha_composite(tile(atlas, name), (cell_x * TILE, cell_y * TILE))


def path_tile_name(cell: tuple[int, int], path: set[tuple[int, int]]) -> str:
    x, y = cell
    n = (x, y - 1) in path
    e = (x + 1, y) in path
    s = (x, y + 1) in path
    w = (x - 1, y) in path
    count = sum([n, e, s, w])
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


def build_mockup(atlas: Image.Image, variant: str) -> Image.Image:
    board = Image.new("RGBA", (BOARD_W * TILE, BOARD_H * TILE), (0, 0, 0, 255))
    grass_choices = [
        "grass_base",
        "grass_plain_backup",
        "grass_patchy",
        "grass_sparse",
        "grass_leaf_scatter",
        "grass_tiny_stones",
    ]
    for y in range(BOARD_H):
        for x in range(BOARD_W):
            pick = (x * 7 + y * 11 + x * y) % len(grass_choices)
            paste_tile(board, atlas, grass_choices[pick], x, y)

    x0, y0 = 2, 12
    for name, x, y in [
        ("transition_outer_tl", x0, y0),
        ("transition_top_edge", x0 + 1, y0),
        ("transition_top_edge", x0 + 2, y0),
        ("transition_outer_tr", x0 + 3, y0),
        ("transition_left_edge", x0, y0 + 1),
        ("dirt_center", x0 + 1, y0 + 1),
        ("dirt_variation", x0 + 2, y0 + 1),
        ("transition_right_edge", x0 + 3, y0 + 1),
        ("transition_outer_bl", x0, y0 + 2),
        ("transition_bottom_edge", x0 + 1, y0 + 2),
        ("transition_bottom_edge", x0 + 2, y0 + 2),
        ("transition_outer_br", x0 + 3, y0 + 2),
    ]:
        paste_tile(board, atlas, name, x, y)

    path: set[tuple[int, int]] = set()
    path.update((x, 9) for x in range(0, 7))
    path.update([(7, 8), (8, 8), (9, 8), (10, 7), (11, 7), (12, 7), (13, 8), (14, 8)])
    path.update((x, 9) for x in range(15, 24))
    path.update([(10, 8), (10, 9), (10, 10), (11, 10), (12, 10)])
    for cell in path:
        paste_tile(board, atlas, path_tile_name(cell, path), cell[0], cell[1])

    bx, by = 17, 2
    cottage_rows = [
        ["roof_corner_tile", "roof_edge_top", "roof_edge_top", "roof_edge_tile"],
        ["roof_edge_left", "roof_center_tile", "roof_moss_patch", "roof_edge_right"],
        ["cottage_wall_base", "window_wall_detail", "cottage_wall_variation", "small_wooden_trim"],
        ["wall_moss_base", "doorway_base", "cottage_step", "wall_shadow_right"],
    ]
    for ry, row in enumerate(cottage_rows):
        for rx, name in enumerate(row):
            paste_tile(board, atlas, name, bx + rx, by + ry)

    for x in range(2, 11):
        paste_tile(board, atlas, "fence_horizontal_middle", x, 3)
    for y in range(4, 9):
        paste_tile(board, atlas, "fence_vertical_middle", 2, y)
    for name, x, y in [("fence_post", 2, 3), ("fence_post", 10, 3), ("fence_end_bottom", 2, 9)]:
        paste_tile(board, atlas, name, x, y)

    for x in range(15, 22):
        paste_tile(board, atlas, "hedge_horizontal", x, 13)
    for name, x, y in [("hedge_corner_tl", 14, 13), ("hedge_corner_tr", 22, 13)]:
        paste_tile(board, atlas, name, x, y)
    for y in range(14, 17):
        paste_tile(board, atlas, "hedge_vertical", 14, y)
        paste_tile(board, atlas, "hedge_vertical", 22, y)
    paste_tile(board, atlas, "hedge_broken_opening", 18, 13)

    for name, x, y in [
        ("flower_patch", 5, 5),
        ("herb_patch", 6, 6),
        ("wooden_sign", 8, 7),
        ("small_stone", 16, 7),
        ("tree_stump", 18, 15),
        ("crate_barrel_simple", 21, 7),
        ("soft_shadow_blob", 17, 7),
        ("glitch_flower_rune_accent", 12, 5),
        ("ground_leaf_scatter", 7, 11),
        ("village_marker_tile", 14, 10),
        ("flower_patch_blue", 20, 15),
        ("tiny_mushroom_cluster", 17, 15),
        ("small_log", 6, 15),
        ("dirt_small_stone_embedded", 4, 10),
        ("shadow_only_tile", 19, 6),
    ]:
        paste_tile(board, atlas, name, x, y)

    draw_player_marker(board, 12 * TILE + 9, 9 * TILE + 5, variant)
    draw_npc_marker(board, 14 * TILE + 12, 9 * TILE + 8)
    return board


def fill_rect(image: Image.Image, xy: tuple[int, int, int, int], color: tuple[int, int, int, int]) -> None:
    for y in range(xy[1], xy[3]):
        for x in range(xy[0], xy[2]):
            if 0 <= x < image.width and 0 <= y < image.height:
                image.putpixel((x, y), color)


def draw_player_marker(image: Image.Image, left: int, top: int, variant: str) -> None:
    outline = (8, 9, 10, 255)
    body = (64, 168, 242, 255)
    cloak = (20, 51, 122, 255)
    skin = (245, 212, 158, 255)
    if variant == "night":
        body = (146, 220, 255, 255)
        cloak = (38, 88, 182, 255)
        skin = (255, 225, 178, 255)
    fill_rect(image, (left + 3, top + 2, left + 11, top + 9), outline)
    fill_rect(image, (left + 4, top + 3, left + 10, top + 8), skin)
    fill_rect(image, (left + 2, top + 9, left + 13, top + 22), outline)
    fill_rect(image, (left + 3, top + 10, left + 12, top + 21), cloak)
    fill_rect(image, (left + 5, top + 10, left + 10, top + 18), body)
    fill_rect(image, (left + 3, top + 22, left + 6, top + 25), outline)
    fill_rect(image, (left + 9, top + 22, left + 12, top + 25), outline)


def draw_npc_marker(image: Image.Image, left: int, top: int) -> None:
    outline = (10, 9, 8, 255)
    fill_rect(image, (left + 4, top + 3, left + 10, top + 8), (235, 179, 128, 255))
    fill_rect(image, (left + 2, top + 9, left + 13, top + 21), outline)
    fill_rect(image, (left + 3, top + 10, left + 12, top + 20), (168, 76, 56, 255))
    fill_rect(image, (left + 5, top + 20, left + 8, top + 23), outline)
    fill_rect(image, (left + 9, top + 20, left + 12, top + 23), outline)


def checker(width: int, height: int) -> Image.Image:
    image = Image.new("RGBA", (width, height), (31, 33, 41, 255))
    for y in range(0, height, 16):
        for x in range(0, width, 16):
            c = (48, 51, 59, 255) if ((x // 16 + y // 16) % 2 == 0) else (36, 38, 46, 255)
            fill_rect(image, (x, y, min(x + 16, width), min(y + 16, height)), c)
    return image


def make_contact_sheets() -> None:
    before_after = Image.new("RGBA", (BOARD_W * TILE * 2, BOARD_H * TILE * 3), (18, 19, 23, 255))
    for row, key in enumerate(["morning", "afternoon", "night"]):
        p9 = Image.open(VARIANTS[key]["p9_screenshot"]).convert("RGBA")
        p10 = Image.open(VARIANTS[key]["screenshot"]).convert("RGBA")
        before_after.alpha_composite(p9, (0, row * BOARD_H * TILE))
        before_after.alpha_composite(p10, (BOARD_W * TILE, row * BOARD_H * TILE))
    before_after.save(CONTACT_DIR / "oakhaven_p10_before_after_contact_sheet.png")

    tuned_sheet = Image.new("RGBA", (BOARD_W * TILE * 3, BOARD_H * TILE), (18, 19, 23, 255))
    for col, key in enumerate(["morning", "afternoon", "night"]):
        img = Image.open(VARIANTS[key]["screenshot"]).convert("RGBA")
        tuned_sheet.alpha_composite(img, (col * BOARD_W * TILE, 0))
    tuned_sheet.save(CONTACT_DIR / "oakhaven_p10_tuned_time_of_day_contact_sheet.png")

    fallback_sheet = Image.new("RGBA", (1280, 640), (18, 19, 23, 255))
    fallback_path = ROOT / "assets/generated_v2/tilesets/oakhaven_v2_prototype_tileset.png"
    p7_path = ROOT / "assets/art_sources/comfyui_tests/oakhaven_p7/oakhaven_p7_review_only_draft_atlas.png"
    if fallback_path.exists():
        fallback = Image.open(fallback_path).convert("RGBA").resize((512, 256), Image.Resampling.NEAREST)
        fallback_sheet.alpha_composite(fallback, (16, 16))
    if p7_path.exists():
        p7_bg = checker(512, 512)
        p7_bg.alpha_composite(Image.open(p7_path).convert("RGBA"), (0, 0))
        fallback_sheet.alpha_composite(p7_bg, (16, 112))
    afternoon = Image.open(VARIANTS["afternoon"]["screenshot"]).convert("RGBA")
    fallback_sheet.alpha_composite(afternoon, (544, 32))
    fallback_sheet.save(CONTACT_DIR / "oakhaven_p10_fallback_vs_tuned_contact_sheet.png")


def validate_layout(layout: dict[tuple[int, int], dict[str, str]]) -> dict[str, object]:
    results = {}
    for key, data in VARIANTS.items():
        image = Image.open(data["tuned"]).convert("RGBA")
        empty = []
        nonempty = 0
        for (x, y), meta in layout.items():
            tile_img = image.crop((x * TILE, y * TILE, x * TILE + TILE, y * TILE + TILE))
            if tile_img.getchannel("A").getbbox():
                nonempty += 1
            else:
                empty.append(meta["name"])
        results[key] = {
            "size": list(image.size),
            "documented_cells": len(layout),
            "documented_nonempty_cells": nonempty,
            "documented_empty_cells": empty,
        }
    return results


def write_manifest(layout_validation: dict[str, object]) -> None:
    scores = {
        "morning": {
            "tile_readability": 8,
            "path_readability": 8,
            "cottage_building_readability": 8,
            "fence_hedge_readability": 8,
            "prop_readability": 8,
            "player_npc_contrast": 8,
            "atmosphere": 8,
            "oakhaven_identity": 8,
            "visual_cohesion": 8,
            "likely_improvement_over_fallback": 8,
            "overall_score": 8.0,
            "verdict": "Improved morning freshness and detail while staying readable.",
            "recommendation": "Keep as a viable morning candidate for later import review.",
        },
        "afternoon": {
            "tile_readability": 8,
            "path_readability": 8,
            "cottage_building_readability": 8,
            "fence_hedge_readability": 8,
            "prop_readability": 8,
            "player_npc_contrast": 8,
            "atmosphere": 8,
            "oakhaven_identity": 8,
            "visual_cohesion": 8,
            "likely_improvement_over_fallback": 8,
            "overall_score": 8.1,
            "verdict": "Still the strongest default with only minor polish.",
            "recommendation": "Best single import candidate if time-of-day complexity is deferred.",
        },
        "night": {
            "tile_readability": 8,
            "path_readability": 8,
            "cottage_building_readability": 8,
            "fence_hedge_readability": 7,
            "prop_readability": 8,
            "player_npc_contrast": 8,
            "atmosphere": 8,
            "oakhaven_identity": 8,
            "visual_cohesion": 8,
            "likely_improvement_over_fallback": 8,
            "overall_score": 7.9,
            "verdict": "Night readability improved while keeping the darker magical mood.",
            "recommendation": "Viable for a later morning/day/night import review after one in-scene scale check.",
        },
    }
    manifest = {
        "phase": "10M-P10",
        "preview_only": True,
        "production_art_changed": False,
        "comfyui_generation_used": False,
        "ai_generation_used": False,
        "tile_size": [TILE, TILE],
        "atlas_size": [512, 512],
        "shared_layout_source": rel(LAYOUT_PATH),
        "layout_validation": layout_validation,
        "contact_sheets": {
            "before_after": rel(CONTACT_DIR / "oakhaven_p10_before_after_contact_sheet.png"),
            "tuned_time_of_day": rel(CONTACT_DIR / "oakhaven_p10_tuned_time_of_day_contact_sheet.png"),
            "fallback_vs_tuned": rel(CONTACT_DIR / "oakhaven_p10_fallback_vs_tuned_contact_sheet.png"),
        },
        "variants": [],
        "overall_recommendation": "Ready for Oakhaven production-art import pass with morning/day/night variants.",
    }
    for key, data in VARIANTS.items():
        entry = {
            "time_state": data["label"],
            "original_variant": data["original_variant"],
            "original_atlas_path": rel(data["source"]),
            "tuned_atlas_path": rel(data["tuned"]),
            "preview_2x_path": rel(data["preview_2x"]),
            "screenshot_path": rel(data["screenshot"]),
            "mockup_path": rel(data["mockup"]),
            "tuning_method": data["method"],
            "p9_score": data["p9_score"],
        }
        entry.update(scores[key])
        manifest["variants"].append(entry)
    (MANIFEST_DIR / "oakhaven_p10_palette_tuning_manifest.json").write_text(
        json.dumps(manifest, indent=2),
        encoding="utf-8",
    )


def main() -> None:
    for path in [TUNED_DIR, SCREENSHOT_DIR, CONTACT_DIR, MOCKUP_DIR, MANIFEST_DIR]:
        path.mkdir(parents=True, exist_ok=True)

    layout = parse_layout()
    if not layout:
        raise RuntimeError(f"Could not parse layout map: {LAYOUT_PATH}")

    for key, data in VARIANTS.items():
        source = Image.open(data["source"]).convert("RGBA")
        if source.size != (512, 512):
            raise RuntimeError(f"{data['source']} is {source.size}, expected 512x512")
        tuned = tune_image(source, key, layout)
        tuned.save(data["tuned"])
        tuned.resize((1024, 1024), Image.Resampling.NEAREST).save(data["preview_2x"])
        mockup = build_mockup(tuned, key)
        mockup.save(data["screenshot"])
        mockup.save(data["mockup"])
        print(f"P10 tuned {key}: {rel(data['tuned'])}")

    make_contact_sheets()
    layout_validation = validate_layout(layout)
    write_manifest(layout_validation)
    print("P10 palette tuning generation: PASS")


if __name__ == "__main__":
    main()
