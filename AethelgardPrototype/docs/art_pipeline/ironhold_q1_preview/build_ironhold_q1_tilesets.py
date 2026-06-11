from __future__ import annotations

import hashlib
import json
import math
import random
from dataclasses import dataclass
from pathlib import Path
from typing import Callable

from PIL import Image, ImageDraw, ImageFont


PROJECT_ROOT = Path(__file__).resolve().parents[3]
OUT_ROOT = PROJECT_ROOT / "assets" / "art_sources" / "comfyui_tests" / "ironhold_q1"
GENERATED_DIR = OUT_ROOT / "generated_tiles"
MOCKUP_DIR = OUT_ROOT / "mockups"
REVIEW_DIR = OUT_ROOT / "review"
MANIFEST_DIR = OUT_ROOT / "manifest"
DIAGNOSTIC_DIR = OUT_ROOT / "diagnostics"

CELL = 32
GRID = 16
ATLAS_SIZE = CELL * GRID
MOCKUP_W = 24
MOCKUP_H = 18


@dataclass(frozen=True)
class Variant:
    key: str
    label: str
    filename: str
    noise: int
    floor: tuple[int, int, int, int]
    floor_alt: tuple[int, int, int, int]
    floor_dark: tuple[int, int, int, int]
    stone: tuple[int, int, int, int]
    stone_dark: tuple[int, int, int, int]
    walkway: tuple[int, int, int, int]
    walkway_light: tuple[int, int, int, int]
    trim: tuple[int, int, int, int]
    bronze: tuple[int, int, int, int]
    bronze_dark: tuple[int, int, int, int]
    ember: tuple[int, int, int, int]
    ember_hot: tuple[int, int, int, int]
    soot: tuple[int, int, int, int]
    oil: tuple[int, int, int, int]
    cyan: tuple[int, int, int, int]
    magenta: tuple[int, int, int, int]
    shadow: tuple[int, int, int, int]
    highlight: tuple[int, int, int, int]


VARIANTS = [
    Variant(
        "a",
        "A clean",
        "ironhold_q1_variant_a_clean.png",
        3,
        (48, 50, 54, 255),
        (60, 63, 68, 255),
        (35, 36, 40, 255),
        (55, 50, 47, 255),
        (41, 38, 36, 255),
        (82, 72, 58, 255),
        (111, 93, 67, 255),
        (28, 29, 32, 255),
        (124, 86, 48, 255),
        (86, 57, 34, 255),
        (199, 97, 36, 255),
        (241, 156, 54, 255),
        (27, 26, 25, 255),
        (22, 24, 24, 210),
        (65, 190, 208, 255),
        (194, 78, 168, 255),
        (9, 9, 10, 160),
        (146, 144, 128, 255),
    ),
    Variant(
        "b",
        "B textured",
        "ironhold_q1_variant_b_textured.png",
        8,
        (46, 47, 52, 255),
        (67, 68, 73, 255),
        (31, 32, 36, 255),
        (62, 54, 49, 255),
        (42, 37, 34, 255),
        (88, 74, 54, 255),
        (128, 100, 63, 255),
        (25, 26, 29, 255),
        (143, 89, 42, 255),
        (92, 54, 29, 255),
        (218, 104, 31, 255),
        (255, 171, 52, 255),
        (24, 22, 21, 255),
        (16, 17, 17, 220),
        (55, 198, 215, 255),
        (207, 67, 162, 255),
        (7, 7, 8, 175),
        (164, 150, 122, 255),
    ),
    Variant(
        "c",
        "C ember/dark",
        "ironhold_q1_variant_c_ember_dark.png",
        5,
        (34, 36, 42, 255),
        (48, 50, 58, 255),
        (22, 23, 28, 255),
        (44, 39, 39, 255),
        (31, 28, 29, 255),
        (67, 55, 45, 255),
        (105, 78, 51, 255),
        (18, 19, 23, 255),
        (121, 70, 34, 255),
        (71, 42, 28, 255),
        (217, 83, 28, 255),
        (255, 137, 39, 255),
        (16, 15, 16, 255),
        (9, 11, 13, 225),
        (49, 178, 204, 255),
        (187, 62, 157, 255),
        (5, 5, 7, 190),
        (131, 116, 98, 255),
    ),
]


TileDrawFn = Callable[[ImageDraw.ImageDraw, Variant, random.Random, str], None]


def seed_for(variant: Variant, name: str) -> int:
    digest = hashlib.sha256(f"{variant.key}:{name}".encode("utf-8")).hexdigest()
    return int(digest[:12], 16)


def mix(a: tuple[int, int, int, int], b: tuple[int, int, int, int], t: float) -> tuple[int, int, int, int]:
    return tuple(int(a[i] * (1.0 - t) + b[i] * t) for i in range(4))


def add_noise(draw: ImageDraw.ImageDraw, variant: Variant, rng: random.Random, strength: int | None = None) -> None:
    count = variant.noise if strength is None else strength
    for _ in range(max(0, count)):
        x = rng.randrange(1, CELL - 2)
        y = rng.randrange(1, CELL - 2)
        base = variant.floor_alt if rng.random() > 0.45 else variant.floor_dark
        color = mix(base, variant.highlight, rng.random() * 0.15)
        draw.point((x, y), fill=color)
        if rng.random() > 0.72:
            draw.point((min(CELL - 2, x + 1), y), fill=color)


def base_floor(draw: ImageDraw.ImageDraw, variant: Variant, rng: random.Random, base: tuple[int, int, int, int] | None = None, quiet: bool = False) -> None:
    draw.rectangle((0, 0, 31, 31), fill=base or variant.floor)
    if not quiet:
        add_noise(draw, variant, rng)


def rivets(draw: ImageDraw.ImageDraw, color: tuple[int, int, int, int], points: list[tuple[int, int]]) -> None:
    for x, y in points:
        draw.rectangle((x, y, x + 2, y + 2), fill=color)
        draw.point((x + 1, y + 1), fill=(16, 16, 17, 255))


def draw_plate_lines(draw: ImageDraw.ImageDraw, variant: Variant, kind: str = "cross") -> None:
    dark = variant.trim
    light = mix(variant.floor_alt, variant.highlight, 0.2)
    if kind in ("cross", "vertical"):
        draw.line((15, 2, 15, 29), fill=dark)
        draw.line((16, 2, 16, 29), fill=light)
    if kind in ("cross", "horizontal"):
        draw.line((2, 15, 29, 15), fill=dark)
        draw.line((2, 16, 29, 16), fill=light)


def draw_floor(draw: ImageDraw.ImageDraw, variant: Variant, rng: random.Random, name: str) -> None:
    quiet = "low_noise" in name or "plain" in name
    base = variant.floor
    if "lighter" in name:
        base = variant.floor_alt
    elif "shadowed" in name:
        base = variant.floor_dark
    elif "stone" in name:
        base = mix(variant.stone, variant.floor, 0.25)
    elif "soot" in name:
        base = mix(variant.floor_dark, variant.soot, 0.45)
    base_floor(draw, variant, rng, base, quiet)
    if "riveted" in name or "rivets" in name:
        rivets(draw, variant.highlight, [(4, 4), (25, 4), (4, 25), (25, 25)])
        draw_plate_lines(draw, variant, "cross")
    elif "cracked" in name:
        draw.line((7, 2, 11, 10, 9, 18, 15, 30), fill=variant.trim, width=1)
        draw.line((11, 10, 19, 11), fill=variant.trim, width=1)
        draw.line((9, 18, 4, 22), fill=variant.trim, width=1)
    elif "hybrid" in name:
        for x in range(0, 32, 8):
            draw.rectangle((x, 16, x + 7, 31), fill=variant.stone if (x // 8) % 2 == 0 else variant.stone_dark)
        draw.line((0, 15, 31, 15), fill=variant.trim)
    elif "oil" in name:
        draw.ellipse((7, 9, 24, 22), fill=variant.oil)
        draw.point((12, 12), fill=mix(variant.oil, variant.cyan, 0.22))
    elif "worn" in name:
        draw.rectangle((6, 6, 25, 25), outline=mix(variant.floor_alt, variant.highlight, 0.18))
        draw.line((8, 23, 22, 23), fill=variant.trim)
    elif "square_plate" in name:
        draw.rectangle((4, 4, 27, 27), outline=variant.trim)
        rivets(draw, variant.highlight, [(6, 6), (23, 6), (6, 23), (23, 23)])
    elif "cross_braced" in name:
        draw.line((5, 5, 26, 26), fill=variant.trim)
        draw.line((26, 5, 5, 26), fill=variant.trim)
    elif "warm_dust" in name:
        draw.rectangle((0, 24, 31, 31), fill=mix(variant.floor, variant.bronze_dark, 0.35))


def draw_walk_connections(draw: ImageDraw.ImageDraw, variant: Variant, connections: set[str], warm: bool = False, stripes: bool = False) -> None:
    color = variant.walkway_light if warm else variant.walkway
    edge = variant.trim
    center = (10, 10, 21, 21)
    draw.rectangle(center, fill=color)
    if "N" in connections:
        draw.rectangle((10, 0, 21, 15), fill=color)
    if "S" in connections:
        draw.rectangle((10, 16, 21, 31), fill=color)
    if "W" in connections:
        draw.rectangle((0, 10, 15, 21), fill=color)
    if "E" in connections:
        draw.rectangle((16, 10, 31, 21), fill=color)
    draw.rectangle((9, 9, 22, 22), outline=edge)
    rivets(draw, mix(variant.highlight, color, 0.25), [(11, 11), (18, 11), (11, 18), (18, 18)])
    if stripes:
        for offset in range(-18, 40, 8):
            draw.line((offset, 31, offset + 22, 9), fill=variant.ember, width=2)


def draw_walkway(draw: ImageDraw.ImageDraw, variant: Variant, rng: random.Random, name: str) -> None:
    base_floor(draw, variant, rng, variant.floor_dark, "center" not in name)
    connection_map = {
        "main_walkway_center": {"N", "S", "E", "W"},
        "walkway_horizontal": {"E", "W"},
        "walkway_vertical": {"N", "S"},
        "walkway_corner_ne": {"N", "E"},
        "walkway_corner_nw": {"N", "W"},
        "walkway_corner_se": {"S", "E"},
        "walkway_corner_sw": {"S", "W"},
        "walkway_t_north": {"N", "E", "W"},
        "walkway_t_south": {"S", "E", "W"},
        "walkway_t_east": {"N", "S", "E"},
        "walkway_t_west": {"N", "S", "W"},
        "walkway_cross": {"N", "S", "E", "W"},
        "walkway_end_left": {"W"},
        "walkway_end_right": {"E"},
        "walkway_end_top": {"N"},
        "walkway_end_bottom": {"S"},
    }
    if name in connection_map:
        draw_walk_connections(draw, variant, connection_map[name], warm="warm" in name, stripes=False)
    elif "warning_stripe" in name:
        draw.rectangle((2, 8, 29, 23), fill=variant.walkway)
        draw.rectangle((2, 8, 29, 23), outline=variant.trim)
        for x in range(-8, 36, 8):
            draw.polygon([(x, 23), (x + 5, 23), (x + 17, 8), (x + 12, 8)], fill=variant.ember_hot)
    elif "warm_forge" in name:
        draw_walk_connections(draw, variant, {"E", "W"}, warm=True, stripes=False)
        draw.rectangle((3, 22, 28, 27), fill=mix(variant.ember, variant.walkway, 0.2))
    elif "riveted_walkway_horizontal" in name:
        draw.rectangle((0, 9, 31, 22), fill=variant.walkway)
        draw.rectangle((0, 8, 31, 9), fill=variant.trim)
        draw.rectangle((0, 22, 31, 23), fill=variant.trim)
        rivets(draw, variant.highlight, [(5, 12), (15, 12), (25, 12), (5, 18), (15, 18), (25, 18)])
    elif "riveted_walkway_vertical" in name:
        draw.rectangle((9, 0, 22, 31), fill=variant.walkway)
        draw.rectangle((8, 0, 9, 31), fill=variant.trim)
        draw.rectangle((22, 0, 23, 31), fill=variant.trim)
        rivets(draw, variant.highlight, [(12, 5), (18, 5), (12, 15), (18, 15), (12, 25), (18, 25)])
    elif "plaza" in name:
        draw.rectangle((3, 3, 28, 28), fill=variant.walkway)
        draw.rectangle((3, 3, 28, 28), outline=variant.trim)
        draw.line((3, 15, 28, 15), fill=mix(variant.walkway, variant.trim, 0.4))
    elif "sidewalk_horizontal" in name:
        draw.rectangle((0, 12, 31, 19), fill=mix(variant.walkway, variant.floor_alt, 0.25))
        draw.line((0, 11, 31, 11), fill=variant.trim)
        draw.line((0, 20, 31, 20), fill=variant.trim)
    elif "sidewalk_vertical" in name:
        draw.rectangle((12, 0, 19, 31), fill=mix(variant.walkway, variant.floor_alt, 0.25))
        draw.line((11, 0, 11, 31), fill=variant.trim)
        draw.line((20, 0, 20, 31), fill=variant.trim)
    elif "stair_step_west" in name or "stair_step_east" in name:
        for i in range(5):
            y = 6 + i * 4
            x1 = 4 + i if "east" in name else 4
            x2 = 28 if "east" in name else 28 - i
            draw.line((x1, y, x2, y), fill=variant.walkway_light, width=2)
    elif "gridded" in name:
        draw.rectangle((3, 3, 28, 28), fill=variant.walkway)
        for i in range(7, 29, 7):
            draw.line((3, i, 28, i), fill=variant.trim)
            draw.line((i, 3, i, 28), fill=variant.trim)
    elif "dark_walkway" in name:
        draw_walk_connections(draw, variant, {"N", "S", "E", "W"}, warm=False)
        draw.rectangle((0, 0, 31, 31), fill=(0, 0, 0, 35))
    elif "bronze_lane_horizontal" in name:
        draw.rectangle((0, 11, 31, 20), fill=variant.bronze)
        draw.line((0, 10, 31, 10), fill=variant.bronze_dark)
        draw.line((0, 21, 31, 21), fill=variant.bronze_dark)
    elif "bronze_lane_vertical" in name:
        draw.rectangle((11, 0, 20, 31), fill=variant.bronze)
        draw.line((10, 0, 10, 31), fill=variant.bronze_dark)
        draw.line((21, 0, 21, 31), fill=variant.bronze_dark)
    elif "lane_split_horizontal" in name:
        draw.rectangle((0, 9, 31, 22), fill=variant.walkway)
        draw.line((0, 15, 31, 15), fill=variant.bronze)
    elif "lane_split_vertical" in name:
        draw.rectangle((9, 0, 22, 31), fill=variant.walkway)
        draw.line((15, 0, 15, 31), fill=variant.bronze)
    else:
        draw_walk_connections(draw, variant, {"N", "S", "E", "W"}, warm=False)


def edge_parts(name: str) -> tuple[str, bool, bool]:
    # returns side/orientation, inner, shadow
    inner = "inner" in name
    shadow = "shadow" in name
    side = "top"
    for key in ["top", "bottom", "left", "right", "ne", "nw", "se", "sw"]:
        if key in name:
            side = key
            break
    return side, inner, shadow


def draw_transition(draw: ImageDraw.ImageDraw, variant: Variant, rng: random.Random, name: str) -> None:
    base_floor(draw, variant, rng, variant.floor, True)
    stone = variant.stone if "grunge" not in name else mix(variant.stone_dark, variant.soot, 0.3)
    side, inner, shadow = edge_parts(name)
    if side == "top":
        draw.rectangle((0, 0, 31, 13), fill=stone)
        edge_y = 13
        draw.line((0, edge_y, 31, edge_y), fill=variant.trim)
    elif side == "bottom":
        draw.rectangle((0, 18, 31, 31), fill=stone)
        draw.line((0, 18, 31, 18), fill=variant.trim)
    elif side == "left":
        draw.rectangle((0, 0, 13, 31), fill=stone)
        draw.line((13, 0, 13, 31), fill=variant.trim)
    elif side == "right":
        draw.rectangle((18, 0, 31, 31), fill=stone)
        draw.line((18, 0, 18, 31), fill=variant.trim)
    elif side in ("ne", "nw", "se", "sw"):
        box = {
            "ne": (16, 0, 31, 15),
            "nw": (0, 0, 15, 15),
            "se": (16, 16, 31, 31),
            "sw": (0, 16, 15, 31),
        }[side]
        if inner:
            draw.rectangle((0, 0, 31, 31), fill=stone)
            draw.rectangle(box, fill=variant.floor)
        else:
            draw.rectangle(box, fill=stone)
        draw.rectangle(box, outline=variant.trim)
    if "broken" in name or "grunge" in name:
        for _ in range(7 + variant.noise):
            x = rng.randrange(0, 32)
            y = rng.randrange(0, 32)
            draw.rectangle((x, y, min(31, x + rng.randrange(2, 5)), min(31, y + rng.randrange(1, 3))), fill=stone if rng.random() > 0.5 else variant.floor_dark)
    if shadow:
        draw.rectangle((0, 20, 31, 31), fill=(0, 0, 0, 55))


def draw_forge(draw: ImageDraw.ImageDraw, variant: Variant, rng: random.Random, name: str) -> None:
    base_floor(draw, variant, rng, variant.floor_dark, "glow" not in name)
    if "ember" in name:
        draw.rectangle((4, 4, 27, 27), fill=variant.soot)
        for _ in range(12):
            x = rng.randrange(6, 25)
            y = rng.randrange(8, 26)
            draw.point((x, y), fill=variant.ember_hot if rng.random() > 0.35 else variant.ember)
    elif "furnace_glow" in name:
        draw.rectangle((4, 6, 27, 26), fill=variant.trim)
        draw.rectangle((7, 10, 24, 24), fill=mix(variant.ember, variant.soot, 0.15))
        draw.rectangle((10, 14, 21, 23), fill=variant.ember_hot)
        draw.line((7, 9, 24, 9), fill=variant.bronze)
    elif "vent_glow" in name:
        draw.rectangle((2, 9, 29, 22), fill=variant.trim)
        for x in range(5, 28, 5):
            draw.line((x, 10, x, 21), fill=variant.ember)
        draw.rectangle((3, 23, 28, 25), fill=(0, 0, 0, 70))
    elif "hot_grate" in name or "cooled_grate" in name:
        glow = variant.ember if "hot" in name else variant.floor_alt
        draw.rectangle((3, 4, 28, 27), fill=variant.trim)
        draw.rectangle((5, 6, 26, 25), fill=mix(glow, variant.soot, 0.4))
        for x in range(8, 26, 5):
            draw.line((x, 6, x, 25), fill=variant.floor_dark)
        for y in range(10, 24, 5):
            draw.line((5, y, 26, y), fill=variant.floor_dark)
    elif "ash" in name:
        draw.ellipse((5, 9, 27, 24), fill=mix(variant.stone, variant.soot, 0.45))
        add_noise(draw, variant, rng, 10)
    elif "soot" in name:
        draw.ellipse((3, 5, 29, 28), fill=variant.soot)
    elif "bronze_heat_pipe" in name:
        draw.rectangle((0, 12, 31, 19), fill=variant.bronze)
        draw.rectangle((0, 14, 31, 16), fill=variant.ember)
        draw.rectangle((4, 9, 10, 22), fill=variant.bronze_dark)
        draw.rectangle((22, 9, 28, 22), fill=variant.bronze_dark)
    elif "warning_hot" in name:
        draw.rectangle((5, 5, 26, 26), outline=variant.ember_hot)
        for x in range(6, 27, 8):
            draw.line((x, 25, x + 12, 6), fill=variant.ember, width=2)
    elif "smoke_shadow" in name:
        draw.ellipse((4, 8, 26, 19), fill=(0, 0, 0, 70))
        draw.ellipse((9, 3, 30, 16), fill=(0, 0, 0, 45))
    else:
        draw.rectangle((8, 8, 24, 24), fill=variant.ember)


def draw_wall(draw: ImageDraw.ImageDraw, variant: Variant, rng: random.Random, name: str) -> None:
    base_floor(draw, variant, rng, variant.floor_dark, True)
    wall = mix(variant.floor_alt, variant.stone, 0.25)
    if "stone_wall" in name:
        wall = variant.stone
    if "metal_wall" in name or "industrial_wall" in name or "riveted_wall" in name:
        draw.rectangle((0, 6, 31, 31), fill=wall)
        draw.rectangle((0, 6, 31, 9), fill=variant.trim)
        draw.line((0, 22, 31, 22), fill=variant.trim)
        if "variation" in name or "panel" in name:
            draw.rectangle((5, 12, 26, 26), outline=variant.trim)
        if "riveted" in name:
            rivets(draw, variant.highlight, [(4, 9), (25, 9), (4, 25), (25, 25)])
    elif "bronze_trim" in name:
        draw.rectangle((0, 12, 31, 19), fill=variant.bronze)
        draw.line((0, 11, 31, 11), fill=variant.highlight)
        draw.line((0, 20, 31, 20), fill=variant.trim)
    elif "steel_beam_horizontal" in name:
        draw.rectangle((0, 12, 31, 20), fill=variant.floor_alt)
        draw.rectangle((0, 14, 31, 17), fill=variant.trim)
        rivets(draw, variant.highlight, [(4, 14), (15, 14), (26, 14)])
    elif "steel_beam_vertical" in name:
        draw.rectangle((12, 0, 20, 31), fill=variant.floor_alt)
        draw.rectangle((14, 0, 17, 31), fill=variant.trim)
        rivets(draw, variant.highlight, [(14, 4), (14, 15), (14, 26)])
    elif "pillar" in name:
        draw.rectangle((9, 3, 22, 30), fill=wall)
        draw.rectangle((7, 4, 24, 9), fill=variant.trim if "top" in name else variant.bronze_dark)
        draw.rectangle((6, 25, 25, 30), fill=variant.trim if "base" in name else variant.bronze_dark)
    elif "foundation_shadow" in name:
        draw.rectangle((0, 20, 31, 31), fill=(0, 0, 0, 95))
    elif "wall_crack" in name:
        draw.rectangle((0, 6, 31, 31), fill=wall)
        draw.line((15, 7, 13, 14, 18, 20, 16, 31), fill=variant.trim)
    elif "window_vent" in name:
        draw.rectangle((0, 6, 31, 31), fill=wall)
        draw.rectangle((7, 12, 24, 22), fill=variant.trim)
        for x in range(9, 24, 4):
            draw.line((x, 13, x, 21), fill=variant.ember)
    else:
        draw.rectangle((0, 8, 31, 31), fill=wall)


def draw_pipe(draw: ImageDraw.ImageDraw, variant: Variant, rng: random.Random, name: str) -> None:
    base_floor(draw, variant, rng, variant.floor_dark, True)
    pipe = variant.bronze if "pipe" in name else variant.floor_alt
    if "pipe_horizontal" in name:
        draw.rectangle((0, 12, 31, 19), fill=pipe)
        draw.line((0, 11, 31, 11), fill=variant.highlight)
        draw.line((0, 20, 31, 20), fill=variant.bronze_dark)
    elif "pipe_vertical" in name:
        draw.rectangle((12, 0, 19, 31), fill=pipe)
        draw.line((11, 0, 11, 31), fill=variant.highlight)
        draw.line((20, 0, 20, 31), fill=variant.bronze_dark)
    elif "pipe_corner" in name:
        draw.rectangle((12, 0, 19, 19), fill=pipe)
        draw.rectangle((12, 12, 31, 19), fill=pipe)
        draw.rectangle((10, 10, 21, 21), outline=variant.bronze_dark)
    elif "pipe_valve" in name:
        draw.rectangle((0, 13, 31, 18), fill=pipe)
        draw.ellipse((9, 7, 23, 21), outline=variant.highlight, width=2)
        draw.line((16, 6, 16, 22), fill=variant.ember)
        draw.line((8, 14, 24, 14), fill=variant.ember)
    elif "small_gear" in name:
        draw.ellipse((8, 8, 24, 24), outline=variant.highlight, width=2)
        draw.ellipse((13, 13, 19, 19), outline=variant.trim)
        for angle in range(0, 360, 45):
            x = 16 + int(math.cos(math.radians(angle)) * 10)
            y = 16 + int(math.sin(math.radians(angle)) * 10)
            draw.rectangle((x - 1, y - 1, x + 1, y + 1), fill=variant.highlight)
    elif "crate" in name:
        draw.rectangle((5, 7, 26, 27), fill=variant.bronze_dark)
        draw.rectangle((6, 8, 25, 26), outline=variant.bronze)
        draw.line((7, 9, 24, 25), fill=variant.trim)
        draw.line((24, 9, 7, 25), fill=variant.trim)
    elif "barrel" in name:
        draw.ellipse((8, 4, 24, 10), fill=variant.bronze)
        draw.rectangle((8, 7, 24, 25), fill=variant.bronze_dark)
        draw.ellipse((8, 21, 24, 29), fill=variant.bronze_dark)
        draw.line((8, 14, 24, 14), fill=variant.trim)
    elif "anvil" in name:
        draw.rectangle((8, 11, 24, 17), fill=variant.floor_alt)
        draw.polygon([(5, 12), (9, 10), (9, 18), (5, 16)], fill=variant.floor_alt)
        draw.rectangle((12, 18, 20, 25), fill=variant.trim)
    elif "workbench" in name:
        draw.rectangle((4, 11, 28, 18), fill=variant.bronze_dark)
        draw.rectangle((6, 18, 10, 28), fill=variant.trim)
        draw.rectangle((22, 18, 26, 28), fill=variant.trim)
        draw.line((8, 8, 17, 13), fill=variant.highlight)
    elif "coal" in name:
        for _ in range(14):
            x = rng.randrange(6, 25)
            y = rng.randrange(12, 27)
            draw.rectangle((x, y, x + 3, y + 2), fill=variant.soot)
    elif "scrap" in name:
        for _ in range(9):
            x = rng.randrange(5, 25)
            y = rng.randrange(8, 26)
            draw.rectangle((x, y, x + rng.randrange(3, 8), y + 2), fill=variant.floor_alt if rng.random() > 0.5 else variant.bronze)
    elif "tool_rack" in name:
        draw.rectangle((5, 7, 27, 10), fill=variant.bronze_dark)
        for x in [8, 14, 20, 25]:
            draw.line((x, 10, x - 2, 24), fill=variant.highlight)
    elif "machine_block" in name:
        draw.rectangle((5, 6, 27, 26), fill=variant.floor_alt)
        draw.rectangle((8, 10, 16, 18), fill=variant.trim)
        draw.point((20, 12), fill=variant.cyan)
        draw.point((22, 17), fill=variant.ember_hot)
    elif "control_box" in name:
        draw.rectangle((7, 6, 25, 26), fill=variant.trim)
        draw.rectangle((10, 9, 22, 14), fill=mix(variant.ember, variant.soot, 0.2))
        draw.point((12, 19), fill=variant.cyan)
        draw.point((18, 20), fill=variant.magenta)
    else:
        draw.rectangle((8, 8, 24, 24), fill=pipe)


def draw_boundary(draw: ImageDraw.ImageDraw, variant: Variant, rng: random.Random, name: str) -> None:
    base_floor(draw, variant, rng, variant.floor_dark, True)
    metal = variant.floor_alt
    if "railing_horizontal" in name:
        draw.line((0, 11, 31, 11), fill=metal, width=3)
        draw.line((0, 20, 31, 20), fill=metal, width=2)
        for x in range(3, 32, 8):
            draw.line((x, 9, x, 23), fill=variant.trim)
    elif "railing_vertical" in name:
        draw.line((11, 0, 11, 31), fill=metal, width=3)
        draw.line((20, 0, 20, 31), fill=metal, width=2)
        for y in range(3, 32, 8):
            draw.line((9, y, 23, y), fill=variant.trim)
    elif "railing_post" in name:
        draw.rectangle((11, 7, 21, 27), fill=metal)
        draw.rectangle((9, 5, 23, 11), fill=variant.trim)
    elif "railing_corner" in name:
        draw.line((11, 0, 11, 20), fill=metal, width=3)
        draw.line((11, 20, 31, 20), fill=metal, width=3)
        draw.rectangle((8, 17, 14, 23), fill=variant.trim)
    elif "chain_fence_horizontal" in name:
        for x in range(-4, 32, 8):
            draw.line((x, 12, x + 8, 20), fill=metal)
            draw.line((x, 20, x + 8, 12), fill=metal)
    elif "chain_fence_vertical" in name:
        for y in range(-4, 32, 8):
            draw.line((12, y, 20, y + 8), fill=metal)
            draw.line((20, y, 12, y + 8), fill=metal)
    elif "industrial_barrier" in name:
        draw.rectangle((2, 11, 30, 21), fill=variant.trim)
        for x in range(3, 30, 7):
            draw.line((x, 21, x + 8, 11), fill=variant.ember)
    elif "broken_barrier" in name:
        draw.rectangle((2, 12, 13, 20), fill=variant.trim)
        draw.rectangle((20, 11, 30, 19), fill=variant.trim)
        draw.line((13, 20, 21, 12), fill=variant.ember)
    elif "low_wall" in name:
        draw.rectangle((0, 16, 31, 27), fill=variant.stone)
        draw.rectangle((0, 15, 31, 18), fill=variant.floor_alt)
    elif "step_ramp" in name:
        for i in range(5):
            draw.rectangle((4 + i * 2, 7 + i * 4, 27, 9 + i * 4), fill=mix(variant.walkway, variant.highlight, 0.12))
    else:
        draw.rectangle((4, 12, 28, 20), fill=metal)


def draw_utility(draw: ImageDraw.ImageDraw, variant: Variant, rng: random.Random, name: str) -> None:
    if "transparent_empty" in name:
        draw.rectangle((0, 0, 31, 31), fill=(0, 0, 0, 0))
    elif "shadow_only" in name:
        draw.rectangle((0, 0, 31, 31), fill=(0, 0, 0, 0))
        draw.ellipse((4, 18, 28, 28), fill=(0, 0, 0, 95))
    elif "highlight_only" in name:
        draw.rectangle((0, 0, 31, 31), fill=(0, 0, 0, 0))
        draw.rectangle((4, 4, 27, 6), fill=(255, 220, 130, 80))
    elif "cyan_spark" in name:
        draw.rectangle((0, 0, 31, 31), fill=(0, 0, 0, 0))
        draw.point((16, 15), fill=variant.cyan)
        draw.line((16, 10, 16, 20), fill=variant.cyan)
        draw.line((11, 15, 21, 15), fill=variant.cyan)
    elif "magenta_glitch" in name:
        draw.rectangle((0, 0, 31, 31), fill=(0, 0, 0, 0))
        draw.line((8, 8, 12, 13, 10, 18, 17, 22, 14, 28), fill=variant.magenta)
    elif "steam_puff" in name:
        draw.rectangle((0, 0, 31, 31), fill=(0, 0, 0, 0))
        draw.ellipse((8, 14, 18, 24), fill=(185, 188, 184, 95))
        draw.ellipse((14, 8, 25, 20), fill=(205, 207, 200, 85))
    elif "dust_mote" in name:
        draw.rectangle((0, 0, 31, 31), fill=(0, 0, 0, 0))
        for _ in range(8):
            draw.point((rng.randrange(5, 27), rng.randrange(6, 27)), fill=(180, 140, 82, 120))
    elif "safe_separator" in name:
        draw.rectangle((0, 0, 31, 31), fill=(8, 8, 10, 120))
        draw.line((0, 31, 31, 0), fill=(90, 90, 96, 160))
    else:
        base_floor(draw, variant, rng, variant.floor_dark, True)


def make_layout() -> list[dict]:
    rows = [
        [
            ("dark_metal_floor_base", "industrial floor", "Default low-noise dark metal traversal tile."),
            ("lighter_metal_floor_variation", "industrial floor", "Lighter floor variation for plazas."),
            ("worn_metal_floor", "industrial floor", "Worn metal floor with a soft center plate."),
            ("riveted_metal_plate", "industrial floor", "Riveted plate tile."),
            ("cracked_metal_plate", "industrial floor", "Cracked metal plate detail."),
            ("stone_metal_hybrid_floor", "industrial floor", "Hybrid stone/metal threshold floor."),
            ("soot_stained_floor", "industrial floor", "Soot-stained forge-adjacent floor."),
            ("oil_stained_floor", "industrial floor", "Oil stain decal floor."),
            ("low_noise_floor", "industrial floor", "Quiet repeat tile for player/NPC backgrounds."),
            ("shadowed_floor", "industrial floor", "Darker floor for corners."),
            ("metal_floor_small_rivets", "industrial floor", "Subtle small-rivet variation."),
            ("warm_dust_floor", "industrial floor", "Warm dusty edge floor."),
            ("square_plate_floor", "industrial floor", "Square plate read, restrained contrast."),
            ("cross_braced_floor", "industrial floor", "Cross-braced floor detail."),
            ("plain_steel_floor", "industrial floor", "Plain steel repeat tile."),
            ("dark_stone_floor", "industrial floor", "Dark stone fallback floor."),
        ],
        [
            ("floor_repeat_01", "industrial floor", "Repeat-safe floor variation."),
            ("floor_repeat_02", "industrial floor", "Repeat-safe floor variation."),
            ("floor_repeat_03", "industrial floor", "Repeat-safe floor variation."),
            ("floor_repeat_04", "industrial floor", "Repeat-safe floor variation."),
            ("floor_repeat_05", "industrial floor", "Repeat-safe floor variation."),
            ("floor_repeat_06", "industrial floor", "Repeat-safe floor variation."),
            ("floor_repeat_07", "industrial floor", "Repeat-safe floor variation."),
            ("floor_repeat_08", "industrial floor", "Repeat-safe floor variation."),
            ("floor_repeat_09", "industrial floor", "Repeat-safe floor variation."),
            ("floor_repeat_10", "industrial floor", "Repeat-safe floor variation."),
            ("floor_repeat_11", "industrial floor", "Repeat-safe floor variation."),
            ("floor_repeat_12", "industrial floor", "Repeat-safe floor variation."),
            ("floor_repeat_13", "industrial floor", "Repeat-safe floor variation."),
            ("floor_repeat_14", "industrial floor", "Repeat-safe floor variation."),
            ("floor_repeat_15", "industrial floor", "Repeat-safe floor variation."),
            ("floor_repeat_16", "industrial floor", "Repeat-safe floor variation."),
        ],
        [
            ("floor_plaza_soft_01", "industrial floor", "Soft plaza tile."),
            ("floor_plaza_soft_02", "industrial floor", "Soft plaza tile."),
            ("floor_plaza_soft_03", "industrial floor", "Soft plaza tile."),
            ("floor_plaza_soft_04", "industrial floor", "Soft plaza tile."),
            ("floor_shadow_soft_01", "industrial floor", "Soft shadow floor."),
            ("floor_shadow_soft_02", "industrial floor", "Soft shadow floor."),
            ("floor_warm_soft_01", "industrial floor", "Warm floor for forge approach."),
            ("floor_warm_soft_02", "industrial floor", "Warm floor for forge approach."),
            ("floor_oil_soft_01", "industrial floor", "Subtle oil floor."),
            ("floor_soot_soft_01", "industrial floor", "Subtle soot floor."),
            ("floor_crack_soft_01", "industrial floor", "Subtle crack floor."),
            ("floor_rivet_soft_01", "industrial floor", "Subtle rivet floor."),
            ("floor_grid_soft_01", "industrial floor", "Quiet grid floor."),
            ("floor_grid_soft_02", "industrial floor", "Quiet grid floor."),
            ("floor_plain_dark_01", "industrial floor", "Plain dark floor."),
            ("floor_plain_dark_02", "industrial floor", "Plain dark floor."),
        ],
        [
            ("main_walkway_center", "walkway/road", "Central road hub tile."),
            ("walkway_horizontal", "walkway/road", "Horizontal walkway."),
            ("walkway_vertical", "walkway/road", "Vertical walkway."),
            ("walkway_corner_ne", "walkway/road", "Walkway corner north/east."),
            ("walkway_corner_nw", "walkway/road", "Walkway corner north/west."),
            ("walkway_corner_se", "walkway/road", "Walkway corner south/east."),
            ("walkway_corner_sw", "walkway/road", "Walkway corner south/west."),
            ("walkway_t_north", "walkway/road", "T-junction opening north."),
            ("walkway_t_south", "walkway/road", "T-junction opening south."),
            ("walkway_t_east", "walkway/road", "T-junction opening east."),
            ("walkway_t_west", "walkway/road", "T-junction opening west."),
            ("walkway_cross", "walkway/road", "Four-way walkway cross."),
            ("walkway_end_left", "walkway/road", "Left end cap."),
            ("walkway_end_right", "walkway/road", "Right end cap."),
            ("walkway_end_top", "walkway/road", "Top end cap."),
            ("walkway_end_bottom", "walkway/road", "Bottom end cap."),
        ],
        [
            ("embedded_warning_stripe_tile", "walkway/road", "Warning stripe tile."),
            ("warm_forge_lit_walkway_tile", "walkway/road", "Forge-lit walkway."),
            ("riveted_walkway_horizontal", "walkway/road", "Riveted horizontal walkway."),
            ("riveted_walkway_vertical", "walkway/road", "Riveted vertical walkway."),
            ("wide_plaza_plate", "walkway/road", "Wide plaza plate."),
            ("narrow_sidewalk_horizontal", "walkway/road", "Narrow horizontal sidewalk."),
            ("narrow_sidewalk_vertical", "walkway/road", "Narrow vertical sidewalk."),
            ("stair_step_west", "walkway/road", "Step/ramp west-facing study."),
            ("stair_step_east", "walkway/road", "Step/ramp east-facing study."),
            ("gridded_road_plate", "walkway/road", "Gridded road plate."),
            ("dark_walkway_center", "walkway/road", "Darkened walkway center."),
            ("clean_walkway_cap", "walkway/road", "Clean walkway cap."),
            ("bronze_lane_horizontal", "walkway/road", "Bronze lane horizontal."),
            ("bronze_lane_vertical", "walkway/road", "Bronze lane vertical."),
            ("lane_split_horizontal", "walkway/road", "Horizontal split lane."),
            ("lane_split_vertical", "walkway/road", "Vertical split lane."),
        ],
        [
            ("walkway_plaza_repeat_01", "walkway/road", "Plaza repeat tile."),
            ("walkway_plaza_repeat_02", "walkway/road", "Plaza repeat tile."),
            ("walkway_plaza_repeat_03", "walkway/road", "Plaza repeat tile."),
            ("walkway_plaza_repeat_04", "walkway/road", "Plaza repeat tile."),
            ("walkway_warning_end_left", "walkway/road", "Warning end left."),
            ("walkway_warning_end_right", "walkway/road", "Warning end right."),
            ("walkway_warning_end_top", "walkway/road", "Warning end top."),
            ("walkway_warning_end_bottom", "walkway/road", "Warning end bottom."),
            ("walkway_warm_corner_ne", "walkway/road", "Warm corner north/east."),
            ("walkway_warm_corner_nw", "walkway/road", "Warm corner north/west."),
            ("walkway_warm_corner_se", "walkway/road", "Warm corner south/east."),
            ("walkway_warm_corner_sw", "walkway/road", "Warm corner south/west."),
            ("walkway_shadow_horizontal", "walkway/road", "Shadowed horizontal walkway."),
            ("walkway_shadow_vertical", "walkway/road", "Shadowed vertical walkway."),
            ("walkway_clean_corner_ne", "walkway/road", "Clean corner north/east."),
            ("walkway_clean_corner_sw", "walkway/road", "Clean corner south/west."),
        ],
        [
            ("metal_to_stone_top_edge", "transitions", "Metal-to-stone top edge."),
            ("metal_to_stone_bottom_edge", "transitions", "Metal-to-stone bottom edge."),
            ("metal_to_stone_left_edge", "transitions", "Metal-to-stone left edge."),
            ("metal_to_stone_right_edge", "transitions", "Metal-to-stone right edge."),
            ("outer_corner_ne", "transitions", "Outer corner north/east."),
            ("outer_corner_nw", "transitions", "Outer corner north/west."),
            ("outer_corner_se", "transitions", "Outer corner south/east."),
            ("outer_corner_sw", "transitions", "Outer corner south/west."),
            ("inner_corner_ne", "transitions", "Inner corner north/east."),
            ("inner_corner_nw", "transitions", "Inner corner north/west."),
            ("inner_corner_se", "transitions", "Inner corner south/east."),
            ("inner_corner_sw", "transitions", "Inner corner south/west."),
            ("broken_edge_top", "transitions", "Broken top edge."),
            ("broken_edge_bottom", "transitions", "Broken bottom edge."),
            ("broken_edge_left", "transitions", "Broken left edge."),
            ("broken_edge_right", "transitions", "Broken right edge."),
        ],
        [
            ("shadow_edge_top", "transitions", "Shadow top edge."),
            ("shadow_edge_bottom", "transitions", "Shadow bottom edge."),
            ("shadow_edge_left", "transitions", "Shadow left edge."),
            ("shadow_edge_right", "transitions", "Shadow right edge."),
            ("grunge_edge_top", "transitions", "Grunge top edge."),
            ("grunge_edge_bottom", "transitions", "Grunge bottom edge."),
            ("grunge_edge_left", "transitions", "Grunge left edge."),
            ("grunge_edge_right", "transitions", "Grunge right edge."),
            ("broken_outer_ne", "transitions", "Broken outer corner north/east."),
            ("broken_outer_nw", "transitions", "Broken outer corner north/west."),
            ("broken_outer_se", "transitions", "Broken outer corner south/east."),
            ("broken_outer_sw", "transitions", "Broken outer corner south/west."),
            ("shadow_inner_ne", "transitions", "Shadow inner corner north/east."),
            ("shadow_inner_nw", "transitions", "Shadow inner corner north/west."),
            ("shadow_inner_se", "transitions", "Shadow inner corner south/east."),
            ("shadow_inner_sw", "transitions", "Shadow inner corner south/west."),
        ],
        [
            ("grunge_outer_ne", "transitions", "Grunge outer corner north/east."),
            ("grunge_outer_nw", "transitions", "Grunge outer corner north/west."),
            ("grunge_outer_se", "transitions", "Grunge outer corner south/east."),
            ("grunge_outer_sw", "transitions", "Grunge outer corner south/west."),
            ("stone_to_metal_soft_top", "transitions", "Soft top transition."),
            ("stone_to_metal_soft_bottom", "transitions", "Soft bottom transition."),
            ("stone_to_metal_soft_left", "transitions", "Soft left transition."),
            ("stone_to_metal_soft_right", "transitions", "Soft right transition."),
            ("oil_edge_top", "transitions", "Oil-stained top edge."),
            ("oil_edge_bottom", "transitions", "Oil-stained bottom edge."),
            ("soot_edge_left", "transitions", "Soot left edge."),
            ("soot_edge_right", "transitions", "Soot right edge."),
            ("road_to_floor_top", "transitions", "Road to floor top."),
            ("road_to_floor_bottom", "transitions", "Road to floor bottom."),
            ("road_to_floor_left", "transitions", "Road to floor left."),
            ("road_to_floor_right", "transitions", "Road to floor right."),
        ],
        [
            ("forge_ember_tile", "forge/furnace", "Ember floor tile."),
            ("furnace_glow_tile", "forge/furnace", "Furnace glow tile."),
            ("vent_glow_tile", "forge/furnace", "Vent glow tile."),
            ("hot_grate_tile", "forge/furnace", "Hot grate tile."),
            ("cooled_grate_tile", "forge/furnace", "Cooled grate tile."),
            ("ash_patch_tile", "forge/furnace", "Ash patch."),
            ("soot_patch_tile", "forge/furnace", "Soot patch."),
            ("bronze_heat_pipe_tile", "forge/furnace", "Bronze heat pipe."),
            ("warning_hot_floor_accent", "forge/furnace", "Warning-hot accent."),
            ("smoke_shadow_tile", "forge/furnace", "Smoke shadow decal."),
            ("forge_brick_floor", "forge/furnace", "Forge brick floor."),
            ("glowing_coal_slot", "forge/furnace", "Glowing coal slot."),
            ("warm_floor_pool", "forge/furnace", "Warm light floor pool."),
            ("thin_heat_crack", "forge/furnace", "Thin heat crack."),
            ("ember_scatter_floor", "forge/furnace", "Ember scatter."),
            ("quiet_cool_forge_floor", "forge/furnace", "Quiet cooled forge floor."),
        ],
        [
            ("forge_side_wall", "forge/furnace", "Forge side wall."),
            ("furnace_mouth_left", "forge/furnace", "Furnace mouth left."),
            ("furnace_mouth_right", "forge/furnace", "Furnace mouth right."),
            ("vent_horizontal_warm", "forge/furnace", "Warm horizontal vent."),
            ("vent_vertical_warm", "forge/furnace", "Warm vertical vent."),
            ("smoke_shadow_soft_01", "forge/furnace", "Soft smoke shadow."),
            ("smoke_shadow_soft_02", "forge/furnace", "Soft smoke shadow."),
            ("ash_floor_soft_01", "forge/furnace", "Soft ash floor."),
            ("ash_floor_soft_02", "forge/furnace", "Soft ash floor."),
            ("ember_floor_soft_01", "forge/furnace", "Soft ember floor."),
            ("ember_floor_soft_02", "forge/furnace", "Soft ember floor."),
            ("forge_warning_corner_ne", "forge/furnace", "Warning corner north/east."),
            ("forge_warning_corner_nw", "forge/furnace", "Warning corner north/west."),
            ("forge_warning_corner_se", "forge/furnace", "Warning corner south/east."),
            ("forge_warning_corner_sw", "forge/furnace", "Warning corner south/west."),
            ("cooling_floor_tile", "forge/furnace", "Cooling floor tile."),
        ],
        [
            ("metal_wall_base", "walls/architecture", "Metal wall base."),
            ("metal_wall_variation", "walls/architecture", "Metal wall variation."),
            ("stone_wall_base", "walls/architecture", "Stone wall base."),
            ("industrial_wall_panel", "walls/architecture", "Industrial wall panel."),
            ("riveted_wall_panel", "walls/architecture", "Riveted wall panel."),
            ("bronze_trim_tile", "walls/architecture", "Bronze trim."),
            ("steel_beam_horizontal", "walls/architecture", "Horizontal steel beam."),
            ("steel_beam_vertical", "walls/architecture", "Vertical steel beam."),
            ("pillar_base", "walls/architecture", "Pillar base."),
            ("pillar_top", "walls/architecture", "Pillar top."),
            ("foundation_shadow", "walls/architecture", "Foundation shadow."),
            ("wall_crack_detail", "walls/architecture", "Wall crack detail."),
            ("small_window_vent_detail", "walls/architecture", "Small window/vent detail."),
            ("arched_plate_wall", "walls/architecture", "Arched plate support."),
            ("dark_wall_recess", "walls/architecture", "Dark wall recess."),
            ("warm_wall_sill", "walls/architecture", "Warm wall sill."),
        ],
        [
            ("wall_repeat_01", "walls/architecture", "Wall repeat tile."),
            ("wall_repeat_02", "walls/architecture", "Wall repeat tile."),
            ("wall_repeat_03", "walls/architecture", "Wall repeat tile."),
            ("wall_repeat_04", "walls/architecture", "Wall repeat tile."),
            ("wall_trim_horizontal", "walls/architecture", "Horizontal wall trim."),
            ("wall_trim_vertical", "walls/architecture", "Vertical wall trim."),
            ("wall_corner_ne", "walls/architecture", "Wall corner north/east."),
            ("wall_corner_nw", "walls/architecture", "Wall corner north/west."),
            ("wall_corner_se", "walls/architecture", "Wall corner south/east."),
            ("wall_corner_sw", "walls/architecture", "Wall corner south/west."),
            ("wall_shadow_left", "walls/architecture", "Wall shadow left."),
            ("wall_shadow_right", "walls/architecture", "Wall shadow right."),
            ("wall_shadow_bottom", "walls/architecture", "Wall shadow bottom."),
            ("wall_glow_vent", "walls/architecture", "Wall glow vent."),
            ("wall_cold_vent", "walls/architecture", "Wall cold vent."),
            ("wall_low_noise_fill", "walls/architecture", "Low-noise wall fill."),
        ],
        [
            ("pipe_horizontal", "pipes/machinery", "Horizontal pipe."),
            ("pipe_vertical", "pipes/machinery", "Vertical pipe."),
            ("pipe_corner", "pipes/machinery", "Pipe corner."),
            ("pipe_valve", "pipes/machinery", "Pipe valve."),
            ("small_gear", "pipes/machinery", "Small gear prop."),
            ("crate", "pipes/machinery", "Crate prop."),
            ("barrel", "pipes/machinery", "Barrel prop."),
            ("anvil", "pipes/machinery", "Anvil prop."),
            ("workbench_tile", "pipes/machinery", "Workbench tile."),
            ("coal_pile", "pipes/machinery", "Coal pile."),
            ("metal_scrap_pile", "pipes/machinery", "Metal scrap pile."),
            ("tool_rack", "pipes/machinery", "Tool rack."),
            ("small_machine_block", "pipes/machinery", "Small machine block."),
            ("furnace_control_box", "pipes/machinery", "Furnace control box."),
            ("pipe_shadow_underlay", "pipes/machinery", "Pipe shadow underlay."),
            ("machine_shadow_underlay", "pipes/machinery", "Machine shadow underlay."),
        ],
        [
            ("railing_horizontal", "boundaries/obstacles", "Horizontal railing."),
            ("railing_vertical", "boundaries/obstacles", "Vertical railing."),
            ("railing_post", "boundaries/obstacles", "Railing post."),
            ("railing_corner", "boundaries/obstacles", "Railing corner."),
            ("chain_fence_horizontal", "boundaries/obstacles", "Horizontal chain fence."),
            ("chain_fence_vertical", "boundaries/obstacles", "Vertical chain fence."),
            ("industrial_barrier", "boundaries/obstacles", "Industrial barrier."),
            ("broken_barrier", "boundaries/obstacles", "Broken barrier."),
            ("low_wall_segment", "boundaries/obstacles", "Low wall segment."),
            ("step_ramp_tile", "boundaries/obstacles", "Step/ramp tile."),
            ("boundary_shadow", "boundaries/obstacles", "Boundary shadow."),
            ("railing_end_left", "boundaries/obstacles", "Railing end left."),
            ("railing_end_right", "boundaries/obstacles", "Railing end right."),
            ("railing_end_top", "boundaries/obstacles", "Railing end top."),
            ("railing_end_bottom", "boundaries/obstacles", "Railing end bottom."),
            ("warning_barrier_corner", "boundaries/obstacles", "Warning barrier corner."),
        ],
        [
            ("transparent_empty_tile", "utility/accent", "Transparent empty tile."),
            ("shadow_only_tile", "utility/accent", "Shadow-only tile."),
            ("highlight_only_tile", "utility/accent", "Highlight-only tile."),
            ("tiny_cyan_spark_accent", "utility/accent", "Tiny cyan spark accent."),
            ("tiny_magenta_glitch_crack", "utility/accent", "Tiny magenta glitch crack."),
            ("small_steam_puff", "utility/accent", "Small steam puff."),
            ("dust_mote_tile", "utility/accent", "Dust mote tile."),
            ("safe_separator_tile", "utility/accent", "Safe separator tile."),
            ("empty_dark_floor", "utility/accent", "Dark empty utility tile."),
            ("empty_warm_floor", "utility/accent", "Warm empty utility tile."),
            ("empty_cold_floor", "utility/accent", "Cold empty utility tile."),
            ("single_rivet_marker", "utility/accent", "Single rivet marker."),
            ("small_bronze_spark", "utility/accent", "Small bronze spark."),
            ("tiny_oil_drop", "utility/accent", "Tiny oil drop."),
            ("soft_square_shadow", "utility/accent", "Soft square shadow."),
            ("atlas_safe_fill", "utility/accent", "Safe fill tile."),
        ],
    ]
    layout = []
    for row, entries in enumerate(rows):
        for col, (name, category, notes) in enumerate(entries):
            layout.append(
                {
                    "x": col,
                    "y": row,
                    "name": name,
                    "category": category,
                    "intended_use": notes,
                    "notes": "32x32 cell; stays inside tile bounds.",
                }
            )
    return layout


LAYOUT = make_layout()
NAME_TO_COORD = {entry["name"]: (entry["x"], entry["y"]) for entry in LAYOUT}


def draw_tile(name: str, variant: Variant) -> Image.Image:
    img = Image.new("RGBA", (CELL, CELL), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    rng = random.Random(seed_for(variant, name))
    if "floor" in name or "plate" in name or name.startswith("dark_metal") or name.startswith("lighter") or name.startswith("worn") or name.startswith("riveted_metal") or name.startswith("cracked") or name.startswith("stone_metal") or name.startswith("soot") or name.startswith("oil") or name.startswith("low_noise") or name.startswith("shadowed") or name.startswith("plain"):
        draw_floor(draw, variant, rng, name)
    elif "walkway" in name or "lane" in name or "road" in name or "stair" in name or "sidewalk" in name or "plaza" in name:
        draw_walkway(draw, variant, rng, name)
    elif "edge" in name or "corner" in name or "transition" in name or name.startswith("metal_to_stone") or name.startswith("stone_to_metal"):
        draw_transition(draw, variant, rng, name)
    elif "forge" in name or "furnace" in name or "vent" in name or "grate" in name or "ash" in name or "soot_patch" in name or "ember" in name or "smoke" in name or "warning_hot" in name or "heat" in name or "cooling" in name:
        draw_forge(draw, variant, rng, name)
    elif "wall" in name or "beam" in name or "pillar" in name or "foundation" in name or "window" in name or "trim" in name or "recess" in name or "sill" in name:
        draw_wall(draw, variant, rng, name)
    elif "pipe" in name or "gear" in name or "crate" in name or "barrel" in name or "anvil" in name or "workbench" in name or "coal" in name or "scrap" in name or "tool" in name or "machine" in name or "control_box" in name:
        draw_pipe(draw, variant, rng, name)
    elif "railing" in name or "fence" in name or "barrier" in name or "low_wall" in name or "step_ramp" in name or "boundary" in name:
        draw_boundary(draw, variant, rng, name)
    else:
        draw_utility(draw, variant, rng, name)
    return img


def build_atlas(variant: Variant) -> Image.Image:
    atlas = Image.new("RGBA", (ATLAS_SIZE, ATLAS_SIZE), (0, 0, 0, 0))
    for entry in LAYOUT:
        tile = draw_tile(entry["name"], variant)
        atlas.alpha_composite(tile, (entry["x"] * CELL, entry["y"] * CELL))
    return atlas


def tile_from(atlas: Image.Image, name: str) -> Image.Image:
    x, y = NAME_TO_COORD[name]
    return atlas.crop((x * CELL, y * CELL, x * CELL + CELL, y * CELL + CELL))


def paste_tile(canvas: Image.Image, atlas: Image.Image, name: str, x: int, y: int) -> None:
    canvas.alpha_composite(tile_from(atlas, name), (x * CELL, y * CELL))


def build_mockup(variant: Variant, atlas: Image.Image) -> Image.Image:
    rng = random.Random(seed_for(variant, "mockup"))
    canvas = Image.new("RGBA", (MOCKUP_W * CELL, MOCKUP_H * CELL), (0, 0, 0, 255))
    floor_choices = [
        "low_noise_floor",
        "dark_metal_floor_base",
        "floor_repeat_01",
        "floor_repeat_03",
        "floor_plaza_soft_01",
        "floor_plain_dark_01",
    ]
    for y in range(MOCKUP_H):
        for x in range(MOCKUP_W):
            choice = floor_choices[(x * 3 + y * 5 + rng.randrange(4)) % len(floor_choices)]
            if x > 16 and y > 11:
                choice = "floor_warm_soft_01" if (x + y) % 3 else "soot_stained_floor"
            if x < 5 and y > 12:
                choice = "shadowed_floor"
            paste_tile(canvas, atlas, choice, x, y)

    # Central walkway network.
    for x in range(2, 22):
        paste_tile(canvas, atlas, "walkway_horizontal", x, 8)
    for y in range(3, 16):
        paste_tile(canvas, atlas, "walkway_vertical", 11, y)
    paste_tile(canvas, atlas, "walkway_cross", 11, 8)
    paste_tile(canvas, atlas, "walkway_t_east", 11, 5)
    for x in range(11, 19):
        paste_tile(canvas, atlas, "warm_forge_lit_walkway_tile" if x > 15 else "walkway_horizontal", x, 5)
    paste_tile(canvas, atlas, "walkway_corner_se", 19, 5)
    for y in range(6, 12):
        paste_tile(canvas, atlas, "walkway_vertical", 19, y)
    paste_tile(canvas, atlas, "walkway_t_south", 6, 8)
    for y in range(9, 13):
        paste_tile(canvas, atlas, "narrow_sidewalk_vertical", 6, y)

    # Top wall strip and architecture support.
    for x in range(MOCKUP_W):
        name = "metal_wall_base" if x % 4 else "riveted_wall_panel"
        paste_tile(canvas, atlas, name, x, 0)
        paste_tile(canvas, atlas, "foundation_shadow", x, 1)
    for x in [2, 8, 14, 20]:
        paste_tile(canvas, atlas, "pillar_base", x, 1)

    # Forge/furnace corner.
    for x in range(17, 23):
        paste_tile(canvas, atlas, "hot_grate_tile" if x % 2 else "cooled_grate_tile", x, 13)
    for x in range(18, 23):
        paste_tile(canvas, atlas, "forge_ember_tile" if x % 2 else "ash_patch_tile", x, 14)
    paste_tile(canvas, atlas, "furnace_glow_tile", 21, 12)
    paste_tile(canvas, atlas, "furnace_control_box", 20, 12)
    paste_tile(canvas, atlas, "bronze_heat_pipe_tile", 18, 12)
    paste_tile(canvas, atlas, "smoke_shadow_tile", 22, 11)

    # Pipe runs.
    for x in range(3, 10):
        paste_tile(canvas, atlas, "pipe_horizontal", x, 3)
    paste_tile(canvas, atlas, "pipe_corner", 10, 3)
    for y in range(4, 7):
        paste_tile(canvas, atlas, "pipe_vertical", 10, y)
    paste_tile(canvas, atlas, "pipe_valve", 7, 3)

    # Props and obstacle language.
    for x, y, name in [
        (4, 10, "crate"),
        (5, 10, "barrel"),
        (16, 9, "anvil"),
        (17, 9, "workbench_tile"),
        (15, 12, "coal_pile"),
        (14, 13, "metal_scrap_pile"),
        (3, 14, "small_machine_block"),
        (4, 14, "tool_rack"),
    ]:
        paste_tile(canvas, atlas, name, x, y)

    for x in range(13, 23):
        paste_tile(canvas, atlas, "railing_horizontal", x, 16)
    for y in range(11, 16):
        paste_tile(canvas, atlas, "railing_vertical", 13, y)
    paste_tile(canvas, atlas, "railing_corner", 13, 16)
    paste_tile(canvas, atlas, "industrial_barrier", 8, 12)
    paste_tile(canvas, atlas, "broken_barrier", 9, 12)
    paste_tile(canvas, atlas, "step_ramp_tile", 7, 8)

    # Small accents.
    paste_tile(canvas, atlas, "tiny_cyan_spark_accent", 18, 6)
    paste_tile(canvas, atlas, "tiny_magenta_glitch_crack", 5, 4)
    paste_tile(canvas, atlas, "small_steam_puff", 21, 11)
    paste_tile(canvas, atlas, "dust_mote_tile", 2, 15)

    # Player/NPC scale markers.
    draw = ImageDraw.Draw(canvas)
    draw.rectangle((11 * CELL + 11, 9 * CELL + 4, 11 * CELL + 20, 9 * CELL + 28), fill=(32, 192, 232, 255))
    draw.rectangle((11 * CELL + 10, 9 * CELL + 2, 11 * CELL + 21, 9 * CELL + 10), fill=(238, 188, 142, 255))
    draw.rectangle((9 * CELL + 12, 7 * CELL + 6, 9 * CELL + 20, 7 * CELL + 27), fill=(180, 126, 78, 255))
    draw.rectangle((15 * CELL + 12, 7 * CELL + 6, 15 * CELL + 20, 7 * CELL + 27), fill=(126, 152, 165, 255))
    draw.rectangle((4 * CELL + 12, 12 * CELL + 6, 4 * CELL + 20, 12 * CELL + 27), fill=(148, 138, 116, 255))

    return canvas


def save_2x(image: Image.Image, path: Path) -> None:
    image.resize((image.width * 2, image.height * 2), Image.Resampling.NEAREST).save(path)


def markdown_layout(path: Path) -> None:
    lines = [
        "# Ironhold Q1 Tile Layout",
        "",
        "Atlas: 512x512 PNG, 16 columns x 16 rows, 32x32 tiles.",
        "",
        "| Tile Coordinate | Tile Name | Category | Intended Use | Notes |",
        "| --- | --- | --- | --- | --- |",
    ]
    for entry in LAYOUT:
        lines.append(
            f"| ({entry['x']},{entry['y']}) | `{entry['name']}` | {entry['category']} | {entry['intended_use']} | {entry['notes']} |"
        )
    path.write_text("\n".join(lines) + "\n", encoding="utf-8")


def label(draw: ImageDraw.ImageDraw, xy: tuple[int, int], text: str) -> None:
    try:
        font = ImageFont.truetype("arial.ttf", 18)
    except OSError:
        font = ImageFont.load_default()
    x, y = xy
    draw.text((x + 1, y + 1), text, fill=(0, 0, 0, 255), font=font)
    draw.text((x, y), text, fill=(235, 228, 210, 255), font=font)


def fit_image(path: Path, size: tuple[int, int], pixel: bool = False) -> Image.Image:
    img = Image.open(path).convert("RGBA")
    img.thumbnail(size, Image.Resampling.NEAREST if pixel else Image.Resampling.LANCZOS)
    out = Image.new("RGBA", size, (18, 18, 20, 255))
    out.alpha_composite(img, ((size[0] - img.width) // 2, (size[1] - img.height) // 2))
    return out


def build_comparison_sheet(outputs: dict[str, dict[str, Path]]) -> None:
    sheet = Image.new("RGBA", (1600, 1800), (14, 15, 17, 255))
    draw = ImageDraw.Draw(sheet)
    baseline = PROJECT_ROOT / "docs" / "art_pipeline" / "current_visual_baseline" / "ironhold_m3_baseline.png"
    visual_review = PROJECT_ROOT / "docs" / "visual_review" / "phase10mm3" / "ironhold_after.png"
    fallback_tileset = PROJECT_ROOT / "assets" / "generated_v2" / "tilesets" / "ironhold_v2_prototype_tileset.png"

    label(draw, (24, 18), "Current Ironhold scene reference")
    sheet.alpha_composite(fit_image(baseline if baseline.exists() else visual_review, (760, 430)), (24, 48))
    label(draw, (820, 18), "Generated V2 fallback tileset")
    sheet.alpha_composite(fit_image(fallback_tileset, (512, 256), pixel=True), (820, 52))

    x_positions = [24, 548, 1072]
    y = 520
    for index, variant in enumerate(VARIANTS):
        x = x_positions[index]
        label(draw, (x, y), f"{variant.label} atlas")
        sheet.alpha_composite(fit_image(outputs[variant.key]["atlas"], (448, 448), pixel=True), (x, y + 30))
    y = 1040
    for index, variant in enumerate(VARIANTS):
        x = x_positions[index]
        label(draw, (x, y), f"{variant.label} mockup")
        sheet.alpha_composite(fit_image(outputs[variant.key]["mockup"], (448, 336), pixel=True), (x, y + 30))
    label(draw, (24, 1450), "Q1 comparison note")
    note = (
        "Q1 replaces the fallback's tiny 128x64 noisy metal panel family with a documented 512x512 grammar: "
        "quiet floors, readable walkways, transitions, forge heat, walls, pipes, props, and boundaries. "
        "This is review-only and not imported into production_art."
    )
    try:
        font = ImageFont.truetype("arial.ttf", 18)
    except OSError:
        font = ImageFont.load_default()
    words = note.split()
    line = ""
    yy = 1484
    for word in words:
        test = f"{line} {word}".strip()
        if draw.textlength(test, font=font) > 1500:
            draw.text((24, yy), line, fill=(222, 216, 202, 255), font=font)
            yy += 26
            line = word
        else:
            line = test
    if line:
        draw.text((24, yy), line, fill=(222, 216, 202, 255), font=font)
    sheet.save(REVIEW_DIR / "ironhold_q1_comparison_contact_sheet.png")


def write_manifest(outputs: dict[str, dict[str, Path]]) -> None:
    data = {
        "phase": "10M-Q1",
        "atlas_size": "512x512",
        "tile_size": "32x32",
        "grid": "16x16",
        "production_art_changed": False,
        "variants": [
            {
                "variant": variant.label,
                "atlas_path": str(outputs[variant.key]["atlas"].relative_to(PROJECT_ROOT)).replace("\\", "/"),
                "preview_2x_path": str(outputs[variant.key]["preview_2x"].relative_to(PROJECT_ROOT)).replace("\\", "/"),
                "mockup_path": str(outputs[variant.key]["mockup"].relative_to(PROJECT_ROOT)).replace("\\", "/"),
                "mockup_2x_path": str(outputs[variant.key]["mockup_2x"].relative_to(PROJECT_ROOT)).replace("\\", "/"),
                "noise_level": variant.noise,
            }
            for variant in VARIANTS
        ],
        "comparison_contact_sheet": "assets/art_sources/comfyui_tests/ironhold_q1/review/ironhold_q1_comparison_contact_sheet.png",
        "layout_map": "assets/art_sources/comfyui_tests/ironhold_q1/manifest/ironhold_q1_tile_layout.md",
    }
    (MANIFEST_DIR / "ironhold_q1_generation_manifest.json").write_text(json.dumps(data, indent=2), encoding="utf-8")


def main() -> None:
    for directory in [GENERATED_DIR, MOCKUP_DIR, REVIEW_DIR, MANIFEST_DIR, DIAGNOSTIC_DIR]:
        directory.mkdir(parents=True, exist_ok=True)
    markdown_layout(MANIFEST_DIR / "ironhold_q1_tile_layout.md")

    outputs: dict[str, dict[str, Path]] = {}
    for variant in VARIANTS:
        atlas = build_atlas(variant)
        atlas_path = GENERATED_DIR / variant.filename
        atlas.save(atlas_path)
        preview_2x_path = REVIEW_DIR / variant.filename.replace(".png", "_2x.png")
        save_2x(atlas, preview_2x_path)

        mockup = build_mockup(variant, atlas)
        mockup_name = variant.filename.replace("generated_tiles/", "").replace(".png", "_mockup.png")
        mockup_name = mockup_name.replace("ironhold_q1_variant_", "ironhold_q1_variant_")
        mockup_path = MOCKUP_DIR / mockup_name
        mockup.save(mockup_path)
        mockup_2x_path = MOCKUP_DIR / mockup_name.replace(".png", "_2x.png")
        save_2x(mockup, mockup_2x_path)
        outputs[variant.key] = {
            "atlas": atlas_path,
            "preview_2x": preview_2x_path,
            "mockup": mockup_path,
            "mockup_2x": mockup_2x_path,
        }

    # Rename mockups to the exact requested names.
    requested_names = {
        "a": "ironhold_q1_variant_a_mockup.png",
        "b": "ironhold_q1_variant_b_mockup.png",
        "c": "ironhold_q1_variant_c_mockup.png",
    }
    for key, requested in requested_names.items():
        current = outputs[key]["mockup"]
        target = MOCKUP_DIR / requested
        if current != target:
            current.replace(target)
            outputs[key]["mockup"] = target
        current_2x = outputs[key]["mockup_2x"]
        target_2x = MOCKUP_DIR / requested.replace(".png", "_2x.png")
        if current_2x != target_2x:
            current_2x.replace(target_2x)
            outputs[key]["mockup_2x"] = target_2x

    build_comparison_sheet(outputs)
    write_manifest(outputs)
    print("Ironhold Q1 controlled tileset generation complete.")


if __name__ == "__main__":
    main()
