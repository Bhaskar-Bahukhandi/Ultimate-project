from __future__ import annotations

import json
import math
import random
from pathlib import Path
from typing import Dict, List, Tuple

from PIL import Image, ImageDraw, ImageFont


PROJECT_ROOT = Path(__file__).resolve().parents[3]
OUT_ROOT = PROJECT_ROOT / "assets" / "art_sources" / "comfyui_tests" / "fractured_wastes_r1"
GENERATED_DIR = OUT_ROOT / "generated_tiles"
MOCKUP_DIR = OUT_ROOT / "mockups"
REVIEW_DIR = OUT_ROOT / "review"
MANIFEST_DIR = OUT_ROOT / "manifest"
DIAGNOSTIC_DIR = OUT_ROOT / "diagnostics"

TILE = 32
GRID = 16
ATLAS_SIZE = TILE * GRID
MOCK_W = 24
MOCK_H = 18


def rgba(hex_rgb: str, alpha: int = 255) -> Tuple[int, int, int, int]:
    hex_rgb = hex_rgb.strip().lstrip("#")
    return (int(hex_rgb[0:2], 16), int(hex_rgb[2:4], 16), int(hex_rgb[4:6], 16), alpha)


VARIANTS = {
    "a_clean": {
        "label": "Variant A clean",
        "filename": "fractured_wastes_r1_variant_a_clean.png",
        "preview": "fractured_wastes_r1_variant_a_clean_2x.png",
        "mockup": "fractured_wastes_r1_variant_a_mockup.png",
        "score": 7.6,
        "noise": 0.45,
        "crack": 0.55,
        "glow": 0.75,
        "palette": {
            "base": rgba("#3b322f"),
            "base2": rgba("#493d37"),
            "base3": rgba("#2f2b2c"),
            "ash": rgba("#5a524a"),
            "soil": rgba("#302622"),
            "scorch": rgba("#211c1e"),
            "stone": rgba("#565250"),
            "shadow": rgba("#1b171a"),
            "path": rgba("#8b7f68"),
            "path2": rgba("#a99a7a"),
            "path_dark": rgba("#685e50"),
            "crack": rgba("#1b151b"),
            "scar": rgba("#7d35a1"),
            "scar_dark": rgba("#46215c"),
            "magenta": rgba("#d64db8"),
            "cyan": rgba("#62c7d9"),
            "dead": rgba("#5e4f3c"),
            "bone": rgba("#b8ad91"),
            "metal": rgba("#5b6266"),
            "warn": rgba("#c49a4c"),
        },
    },
    "b_textured": {
        "label": "Variant B textured",
        "filename": "fractured_wastes_r1_variant_b_textured.png",
        "preview": "fractured_wastes_r1_variant_b_textured_2x.png",
        "mockup": "fractured_wastes_r1_variant_b_mockup.png",
        "score": 8.2,
        "noise": 0.90,
        "crack": 0.95,
        "glow": 0.90,
        "palette": {
            "base": rgba("#342b2d"),
            "base2": rgba("#4b3b35"),
            "base3": rgba("#292528"),
            "ash": rgba("#62564a"),
            "soil": rgba("#382824"),
            "scorch": rgba("#20191c"),
            "stone": rgba("#5d5754"),
            "shadow": rgba("#171317"),
            "path": rgba("#928166"),
            "path2": rgba("#b29c76"),
            "path_dark": rgba("#66584a"),
            "crack": rgba("#171116"),
            "scar": rgba("#8730a6"),
            "scar_dark": rgba("#3c184e"),
            "magenta": rgba("#dc42c2"),
            "cyan": rgba("#58ccd9"),
            "dead": rgba("#665137"),
            "bone": rgba("#bfb18e"),
            "metal": rgba("#60676a"),
            "warn": rgba("#c98b3d"),
        },
    },
    "c_corrupt_dark": {
        "label": "Variant C corrupt/dark",
        "filename": "fractured_wastes_r1_variant_c_corrupt_dark.png",
        "preview": "fractured_wastes_r1_variant_c_corrupt_dark_2x.png",
        "mockup": "fractured_wastes_r1_variant_c_mockup.png",
        "score": 7.4,
        "noise": 0.75,
        "crack": 1.05,
        "glow": 1.20,
        "palette": {
            "base": rgba("#28242a"),
            "base2": rgba("#3a2c38"),
            "base3": rgba("#201e24"),
            "ash": rgba("#4f4a4f"),
            "soil": rgba("#2a2026"),
            "scorch": rgba("#17131a"),
            "stone": rgba("#4e4b51"),
            "shadow": rgba("#111016"),
            "path": rgba("#82745f"),
            "path2": rgba("#a38f6f"),
            "path_dark": rgba("#5d5148"),
            "crack": rgba("#0f0c12"),
            "scar": rgba("#9d2dc5"),
            "scar_dark": rgba("#331245"),
            "magenta": rgba("#f04bd2"),
            "cyan": rgba("#54d4e6"),
            "dead": rgba("#544332"),
            "bone": rgba("#aa9e82"),
            "metal": rgba("#535b62"),
            "warn": rgba("#bc7440"),
        },
    },
}


def add_spec(specs: List[Dict], x: int, y: int, name: str, category: str, intended: str, notes: str) -> None:
    specs.append({
        "x": x,
        "y": y,
        "name": name,
        "category": category,
        "intended_use": intended,
        "notes": notes,
    })


def build_layout() -> List[Dict]:
    specs: List[Dict] = []
    base_names = [
        "dark_cracked_ground_base", "lighter_cracked_ground_variation", "dusty_ash_ground", "dead_soil",
        "scorched_soil", "stony_wasteland", "low_noise_traversal_tile", "shadowed_ground",
        "purple_tinted_corrupted_ground", "dry_rubble_ground", "ash_pebble_ground", "cracked_brown_ground",
        "muted_violet_ground", "broken_slate_ground", "dust_drift_ground", "neutral_ground",
        "dark_cracks_sparse", "light_cracks_sparse", "ash_soft_noise", "dead_soil_pebbles",
        "scorched_cross_cracks", "stone_flat_mix", "quiet_label_ground", "deep_shadow_ground",
        "violet_ground_soft", "rubble_soft", "dry_silt_ground", "old_road_trace",
        "low_frequency_cracks", "dark_sandy_ground", "rough_stone_ground", "soft_blackened_ground",
        "waste_base_alt_01", "waste_base_alt_02", "waste_base_alt_03", "waste_base_alt_04",
        "waste_base_alt_05", "waste_base_alt_06", "waste_base_alt_07", "waste_base_alt_08",
        "waste_base_alt_09", "waste_base_alt_10", "waste_base_alt_11", "waste_base_alt_12",
        "waste_base_alt_13", "waste_base_alt_14", "waste_base_alt_15", "waste_base_alt_16",
    ]
    for i, name in enumerate(base_names):
        add_spec(specs, i % GRID, i // GRID, name, "base terrain", "wasteland ground fill", "Low-frequency cracked ash/soil terrain.")

    path_names = [
        "safe_path_center", "safe_path_horizontal", "safe_path_vertical", "safe_path_corner_ne",
        "safe_path_corner_nw", "safe_path_corner_se", "safe_path_corner_sw", "safe_path_t_north",
        "safe_path_t_south", "safe_path_t_east", "safe_path_t_west", "safe_path_cross",
        "safe_path_end_north", "safe_path_end_south", "safe_path_end_east", "safe_path_end_west",
        "broken_stepping_stone_path", "pale_dust_trail_tile", "safe_path_soft_center", "path_shadow_center",
        "path_stony_center", "path_chipped_horizontal", "path_chipped_vertical", "path_rough_corner_ne",
        "path_rough_corner_nw", "path_rough_corner_se", "path_rough_corner_sw", "path_branch_soft",
        "path_branch_stony", "path_end_broken", "path_marker_dust", "path_label_safe_ground",
        "safe_path_alt_01", "safe_path_alt_02", "safe_path_alt_03", "safe_path_alt_04",
        "safe_path_alt_05", "safe_path_alt_06", "safe_path_alt_07", "safe_path_alt_08",
        "safe_path_alt_09", "safe_path_alt_10", "safe_path_alt_11", "safe_path_alt_12",
        "safe_path_alt_13", "safe_path_alt_14", "safe_path_alt_15", "safe_path_alt_16",
    ]
    for i, name in enumerate(path_names):
        add_spec(specs, i % GRID, 3 + i // GRID, name, "safe path", "walkable route language", "Path tiles must stay visibly distinct from scar hazards.")

    transition_names = [
        "path_to_wasteland_top_edge", "path_to_wasteland_bottom_edge", "path_to_wasteland_left_edge", "path_to_wasteland_right_edge",
        "outer_corner_ne", "outer_corner_nw", "outer_corner_se", "outer_corner_sw",
        "inner_corner_ne", "inner_corner_nw", "inner_corner_se", "inner_corner_sw",
        "rough_broken_edge_top", "rough_broken_edge_bottom", "rough_broken_edge_left", "rough_broken_edge_right",
        "dust_blend_edge_top", "dust_blend_edge_bottom", "dust_blend_edge_left", "dust_blend_edge_right",
        "shadowed_edge_top", "shadowed_edge_bottom", "shadowed_edge_left", "shadowed_edge_right",
        "diagonal_dust_ne", "diagonal_dust_nw", "diagonal_dust_se", "diagonal_dust_sw",
        "rough_outer_corner_ne", "rough_outer_corner_nw", "rough_outer_corner_se", "rough_outer_corner_sw",
        "transition_alt_01", "transition_alt_02", "transition_alt_03", "transition_alt_04",
        "transition_alt_05", "transition_alt_06", "transition_alt_07", "transition_alt_08",
        "transition_alt_09", "transition_alt_10", "transition_alt_11", "transition_alt_12",
        "transition_alt_13", "transition_alt_14", "transition_alt_15", "transition_alt_16",
    ]
    for i, name in enumerate(transition_names):
        add_spec(specs, i % GRID, 6 + i // GRID, name, "transitions", "path edge blending", "Edges and corners align to the safe path family.")

    fracture_names = [
        "purple_scar_crack_tile", "thin_fracture_line_horizontal", "thin_fracture_line_vertical", "fracture_corner",
        "glowing_rift_small", "corrupted_patch", "unstable_ground", "dark_corruption_pool",
        "magenta_spark_tile", "cyan_magenta_anomaly_tile", "sealed_scar_tile", "fading_corruption_edge",
        "rift_shard_cluster", "violet_core_stain", "scar_edge_top", "scar_edge_bottom",
        "scar_edge_left", "scar_edge_right", "corrupt_crackle_small", "corrupt_crackle_large",
        "rift_alt_01", "rift_alt_02", "rift_alt_03", "rift_alt_04",
        "rift_alt_05", "rift_alt_06", "rift_alt_07", "rift_alt_08",
        "rift_alt_09", "rift_alt_10", "rift_alt_11", "rift_alt_12",
    ]
    for i, name in enumerate(fracture_names):
        add_spec(specs, i % GRID, 9 + i // GRID, name, "fracture/corruption", "scar, rift, and corruption accents", "Glow is localized so labels remain readable.")

    ruin_names = [
        "broken_stone", "rubble_pile", "collapsed_wall_fragment", "ruined_pillar_base",
        "ruined_pillar_top", "cracked_stone_slab", "half_buried_metal_scrap", "old_marker_stone",
        "broken_sign", "low_ruin_wall_horizontal", "low_ruin_wall_vertical", "ruin_corner",
        "slab_shadow", "rubble_scatter_light", "rubble_scatter_dark", "pillar_cracked",
        "ruin_wall_end_left", "ruin_wall_end_right", "ruin_wall_end_top", "ruin_wall_end_bottom",
        "ruin_alt_01", "ruin_alt_02", "ruin_alt_03", "ruin_alt_04",
        "ruin_alt_05", "ruin_alt_06", "ruin_alt_07", "ruin_alt_08",
        "ruin_alt_09", "ruin_alt_10", "ruin_alt_11", "ruin_alt_12",
    ]
    for i, name in enumerate(ruin_names):
        add_spec(specs, i % GRID, 11 + i // GRID, name, "ruins/rocks", "ruin and obstacle support", "Overlay-style props remain inside 32x32 cells.")

    row13 = [
        "dead_scrub", "thorn_bush", "dry_grass_patch", "blackened_root",
        "small_dead_tree_stump", "bone_shard_pile", "ash_flower_corrupted_flower", "survivor_camp_crate",
        "old_campfire_ash", "cloth_scrap", "small_salvage_pile", "warning_marker",
        "hazard_crack", "hot_corrupt_vent", "unstable_edge", "shallow_corruption_stain",
    ]
    row14 = [
        "deep_corruption_stain", "fracture_warning_accent", "hazard_boundary_marker", "safe_boundary_marker",
        "dead_veg_alt_01", "dead_veg_alt_02", "dead_veg_alt_03", "dead_veg_alt_04",
        "hazard_alt_01", "hazard_alt_02", "hazard_alt_03", "hazard_alt_04",
        "camp_alt_01", "camp_alt_02", "salvage_alt_01", "marker_alt_01",
    ]
    for x, name in enumerate(row13):
        cat = "hazard-looking tiles" if x >= 12 else "vegetation/props"
        add_spec(specs, x, 13, name, cat, "prop or hazard visual language", "Art only; no collision implication in this phase.")
    for x, name in enumerate(row14):
        cat = "hazard-looking tiles" if x < 4 or name.startswith("hazard") else "vegetation/props"
        add_spec(specs, x, 14, name, cat, "prop or hazard visual language", "Readable silhouettes, no gameplay collision changes.")

    utility_names = [
        "transparent_empty_tile", "shadow_only_tile", "highlight_only_tile", "dust_mote_tile",
        "violet_spark", "cyan_spark", "small_ground_accent", "safe_separator_tile",
        "soft_label_backer", "dark_label_backer", "pale_dust_accent", "small_pebble_accent",
        "thin_shadow_line", "thin_highlight_line", "blank_debug_safe", "transparent_padding",
    ]
    for x, name in enumerate(utility_names):
        add_spec(specs, x, 15, name, "utility/accent", "utility, accents, and safe empty cells", "Transparent or subtle support tile.")
    return specs


LAYOUT = build_layout()
SPEC_BY_NAME = {spec["name"]: spec for spec in LAYOUT}


def clamp_color(c: Tuple[int, int, int, int], amt: int) -> Tuple[int, int, int, int]:
    return tuple(max(0, min(255, c[i] + amt)) for i in range(3)) + (c[3],)


def seeded_rng(variant_key: str, name: str) -> random.Random:
    return random.Random(f"fractured-wastes-r1::{variant_key}::{name}")


def draw_noise(draw: ImageDraw.ImageDraw, rng: random.Random, pal: Dict, density: float, colors: List[Tuple[int, int, int, int]]) -> None:
    count = max(1, int(18 * density))
    for _ in range(count):
        x, y = rng.randrange(0, TILE), rng.randrange(0, TILE)
        col = rng.choice(colors)
        if rng.random() < 0.25:
            draw.rectangle([x, y, min(31, x + 1), y], fill=col)
        else:
            draw.point((x, y), fill=col)


def draw_cracks(draw: ImageDraw.ImageDraw, rng: random.Random, pal: Dict, intensity: float, glow: bool = False) -> None:
    crack_count = max(1, int(3 * intensity))
    for _ in range(crack_count):
        x = rng.randrange(3, 29)
        y = rng.randrange(3, 29)
        pts = [(x, y)]
        for _seg in range(rng.randrange(2, 5)):
            x += rng.randrange(-8, 9)
            y += rng.randrange(-5, 6)
            x = max(1, min(30, x))
            y = max(1, min(30, y))
            pts.append((x, y))
        if glow and rng.random() < 0.45:
            draw.line(pts, fill=(*pal["scar_dark"][:3], 150), width=3)
            draw.line(pts, fill=pal["magenta"], width=1)
        else:
            draw.line(pts, fill=pal["crack"], width=1)


def tile_base(name: str, cfg: Dict) -> Image.Image:
    pal = cfg["palette"]
    rng = seeded_rng(cfg["label"], name)
    img = Image.new("RGBA", (TILE, TILE), pal["base"])
    draw = ImageDraw.Draw(img, "RGBA")
    if "lighter" in name or "light" in name:
        draw.rectangle([0, 0, 31, 31], fill=pal["base2"])
    elif "ash" in name or "dust" in name:
        draw.rectangle([0, 0, 31, 31], fill=pal["ash"])
    elif "dead_soil" in name or "soil" in name:
        draw.rectangle([0, 0, 31, 31], fill=pal["soil"])
    elif "scorch" in name or "blackened" in name:
        draw.rectangle([0, 0, 31, 31], fill=pal["scorch"])
    elif "stone" in name or "slate" in name:
        draw.rectangle([0, 0, 31, 31], fill=pal["stone"])
    elif "shadow" in name:
        draw.rectangle([0, 0, 31, 31], fill=pal["shadow"])
    elif "purple" in name or "violet" in name:
        draw.rectangle([0, 0, 31, 31], fill=pal["base3"])
        draw.rectangle([0, 0, 31, 31], fill=(*pal["scar_dark"][:3], 70))
    elif "low_noise" in name or "quiet" in name or "neutral" in name:
        draw.rectangle([0, 0, 31, 31], fill=clamp_color(pal["base"], 10))
    draw_noise(draw, rng, pal, cfg["noise"] * (0.55 if "low_noise" in name or "quiet" in name else 1.0), [
        clamp_color(pal["base"], 16),
        clamp_color(pal["base"], -16),
        (*pal["stone"][:3], 120),
    ])
    if "cracked" in name or "crack" in name or "scar" in name or "base" in name:
        draw_cracks(draw, rng, pal, cfg["crack"] * 0.65, "purple" in name or "violet" in name)
    if "rubble" in name or "pebble" in name:
        for _ in range(5):
            x, y = rng.randrange(3, 28), rng.randrange(3, 28)
            draw.rectangle([x, y, x + rng.randrange(1, 4), y + rng.randrange(1, 3)], fill=clamp_color(pal["stone"], rng.randrange(-20, 18)))
    return img


def draw_path_shape(draw: ImageDraw.ImageDraw, name: str, pal: Dict) -> None:
    path = pal["path"]
    dark = pal["path_dark"]
    light = pal["path2"]
    def rect(box, fill=path):
        draw.rectangle(box, fill=fill)
    if "horizontal" in name or name.endswith("_h"):
        rect([0, 10, 31, 22])
    elif "vertical" in name or name.endswith("_v"):
        rect([10, 0, 22, 31])
    elif "corner_ne" in name:
        rect([10, 0, 22, 22]); rect([10, 10, 31, 22])
    elif "corner_nw" in name:
        rect([10, 0, 22, 22]); rect([0, 10, 22, 22])
    elif "corner_se" in name:
        rect([10, 10, 22, 31]); rect([10, 10, 31, 22])
    elif "corner_sw" in name:
        rect([10, 10, 22, 31]); rect([0, 10, 22, 22])
    elif "t_north" in name:
        rect([0, 10, 31, 22]); rect([10, 0, 22, 22])
    elif "t_south" in name:
        rect([0, 10, 31, 22]); rect([10, 10, 22, 31])
    elif "t_east" in name:
        rect([10, 0, 22, 31]); rect([10, 10, 31, 22])
    elif "t_west" in name:
        rect([10, 0, 22, 31]); rect([0, 10, 22, 22])
    elif "cross" in name:
        rect([0, 10, 31, 22]); rect([10, 0, 22, 31])
    elif "end_north" in name:
        rect([10, 0, 22, 22])
    elif "end_south" in name:
        rect([10, 10, 22, 31])
    elif "end_east" in name:
        rect([10, 10, 31, 22])
    elif "end_west" in name:
        rect([0, 10, 22, 22])
    elif "stepping" in name:
        for box in ([4, 13, 11, 20], [14, 10, 20, 17], [22, 14, 29, 21]):
            draw.rectangle(box, fill=path)
            draw.line([box[0], box[3], box[2], box[3]], fill=dark)
        return
    elif "trail" in name:
        draw.polygon([(0, 15), (8, 11), (18, 12), (31, 16), (31, 21), (18, 20), (8, 22), (0, 19)], fill=(*path[:3], 205))
    else:
        rect([4, 4, 27, 27])
    draw.line([0, 10, 31, 10], fill=(*dark[:3], 120))
    draw.line([0, 22, 31, 22], fill=(*dark[:3], 120))
    draw.line([10, 0, 10, 31], fill=(*dark[:3], 90))
    draw.line([22, 0, 22, 31], fill=(*dark[:3], 90))
    draw.point((15, 15), fill=light)


def tile_path(name: str, cfg: Dict) -> Image.Image:
    pal = cfg["palette"]
    rng = seeded_rng(cfg["label"], name)
    img = tile_base("low_noise_traversal_tile", cfg)
    draw = ImageDraw.Draw(img, "RGBA")
    draw_path_shape(draw, name, pal)
    draw_noise(draw, rng, pal, cfg["noise"] * 0.35, [clamp_color(pal["path"], 14), clamp_color(pal["path_dark"], -6)])
    if "broken" in name or "chipped" in name or "rough" in name:
        for _ in range(4):
            x, y = rng.randrange(0, 30), rng.randrange(8, 24)
            draw.rectangle([x, y, x + 2, y + 1], fill=pal["crack"])
    return img


def tile_transition(name: str, cfg: Dict) -> Image.Image:
    pal = cfg["palette"]
    rng = seeded_rng(cfg["label"], name)
    img = tile_base("dark_cracked_ground_base", cfg)
    draw = ImageDraw.Draw(img, "RGBA")
    if "top_edge" in name or "edge_top" in name:
        draw.rectangle([0, 0, 31, 15], fill=pal["path"])
    elif "bottom_edge" in name or "edge_bottom" in name:
        draw.rectangle([0, 16, 31, 31], fill=pal["path"])
    elif "left_edge" in name or "edge_left" in name:
        draw.rectangle([0, 0, 15, 31], fill=pal["path"])
    elif "right_edge" in name or "edge_right" in name:
        draw.rectangle([16, 0, 31, 31], fill=pal["path"])
    elif "outer_corner_ne" in name:
        draw.rectangle([16, 0, 31, 15], fill=pal["path"])
    elif "outer_corner_nw" in name:
        draw.rectangle([0, 0, 15, 15], fill=pal["path"])
    elif "outer_corner_se" in name:
        draw.rectangle([16, 16, 31, 31], fill=pal["path"])
    elif "outer_corner_sw" in name:
        draw.rectangle([0, 16, 15, 31], fill=pal["path"])
    elif "inner_corner_ne" in name:
        draw.rectangle([0, 0, 31, 31], fill=pal["path"]); draw.rectangle([22, 0, 31, 9], fill=pal["base"])
    elif "inner_corner_nw" in name:
        draw.rectangle([0, 0, 31, 31], fill=pal["path"]); draw.rectangle([0, 0, 9, 9], fill=pal["base"])
    elif "inner_corner_se" in name:
        draw.rectangle([0, 0, 31, 31], fill=pal["path"]); draw.rectangle([22, 22, 31, 31], fill=pal["base"])
    elif "inner_corner_sw" in name:
        draw.rectangle([0, 0, 31, 31], fill=pal["path"]); draw.rectangle([0, 22, 9, 31], fill=pal["base"])
    elif "diagonal" in name:
        if name.endswith("ne"):
            draw.polygon([(31, 0), (31, 31), (0, 0)], fill=pal["path"])
        elif name.endswith("nw"):
            draw.polygon([(0, 0), (31, 0), (0, 31)], fill=pal["path"])
        elif name.endswith("se"):
            draw.polygon([(31, 31), (31, 0), (0, 31)], fill=pal["path"])
        else:
            draw.polygon([(0, 31), (0, 0), (31, 31)], fill=pal["path"])
    else:
        draw.rectangle([0, 12, 31, 20], fill=(*pal["path"][:3], 210))
    if "rough" in name or "broken" in name:
        draw_cracks(draw, rng, pal, cfg["crack"] * 0.45)
    if "dust" in name:
        draw_noise(draw, rng, pal, 0.8, [(*pal["path2"][:3], 120), (*pal["ash"][:3], 130)])
    if "shadow" in name:
        draw.rectangle([0, 0, 31, 31], fill=(0, 0, 0, 45))
    return img


def tile_fracture(name: str, cfg: Dict) -> Image.Image:
    pal = cfg["palette"]
    rng = seeded_rng(cfg["label"], name)
    img = tile_base("purple_tinted_corrupted_ground", cfg)
    draw = ImageDraw.Draw(img, "RGBA")
    if "horizontal" in name:
        draw.line([(0, 16), (10, 14), (20, 18), (31, 15)], fill=(*pal["scar_dark"][:3], 180), width=3)
        draw.line([(0, 16), (10, 14), (20, 18), (31, 15)], fill=pal["magenta"], width=1)
    elif "vertical" in name:
        draw.line([(15, 0), (18, 10), (13, 20), (16, 31)], fill=(*pal["scar_dark"][:3], 180), width=3)
        draw.line([(15, 0), (18, 10), (13, 20), (16, 31)], fill=pal["magenta"], width=1)
    elif "corner" in name:
        draw.line([(15, 0), (16, 15), (31, 16)], fill=(*pal["scar_dark"][:3], 180), width=3)
        draw.line([(15, 0), (16, 15), (31, 16)], fill=pal["magenta"], width=1)
    elif "rift" in name:
        draw.ellipse([9, 7, 23, 25], fill=(*pal["scar_dark"][:3], 220))
        draw.ellipse([12, 10, 20, 22], fill=(*pal["magenta"][:3], int(190 * cfg["glow"])))
        draw.line([(16, 4), (14, 28)], fill=pal["cyan"], width=1)
    elif "pool" in name or "stain" in name or "patch" in name:
        draw.ellipse([3, 6, 29, 25], fill=(*pal["scar_dark"][:3], 190))
        draw.ellipse([8, 10, 24, 21], fill=(*pal["scar"][:3], 110))
    elif "spark" in name or "anomaly" in name:
        for col in [pal["magenta"], pal["cyan"], pal["magenta"]]:
            x, y = rng.randrange(5, 27), rng.randrange(5, 27)
            draw.line([(x - 2, y), (x + 2, y)], fill=col, width=1)
            draw.line([(x, y - 2), (x, y + 2)], fill=col, width=1)
    elif "sealed" in name:
        draw_cracks(draw, rng, pal, 0.9, True)
        draw.line([(5, 24), (27, 8)], fill=pal["path_dark"], width=2)
    elif "edge" in name:
        draw.rectangle([0, 0, 31, 31], fill=(*pal["scar_dark"][:3], 70))
        draw.line([(0, 16), (31, 15)], fill=(*pal["scar"][:3], 130), width=2)
    else:
        draw_cracks(draw, rng, pal, cfg["crack"], True)
    return img


def tile_ruin_or_prop(name: str, category: str, cfg: Dict) -> Image.Image:
    pal = cfg["palette"]
    rng = seeded_rng(cfg["label"], name)
    img = Image.new("RGBA", (TILE, TILE), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img, "RGBA")
    shadow = (0, 0, 0, 80)
    draw.ellipse([5, 21, 27, 29], fill=shadow)
    stone = pal["stone"]
    dark = clamp_color(stone, -35)
    light = clamp_color(stone, 22)
    if "wall_horizontal" in name:
        draw.rectangle([2, 13, 30, 20], fill=dark); draw.line([2, 13, 30, 13], fill=light)
    elif "wall_vertical" in name:
        draw.rectangle([12, 2, 20, 30], fill=dark); draw.line([12, 2, 12, 30], fill=light)
    elif "corner" in name:
        draw.rectangle([4, 13, 20, 20], fill=dark); draw.rectangle([13, 4, 20, 20], fill=dark); draw.line([4, 13, 20, 13], fill=light)
    elif "pillar" in name:
        draw.rectangle([11, 6, 21, 26], fill=dark); draw.rectangle([9, 23, 23, 28], fill=stone); draw.line([11, 6, 21, 6], fill=light)
    elif "slab" in name:
        draw.polygon([(5, 10), (27, 8), (29, 23), (7, 25)], fill=dark); draw.line([(6, 11), (26, 9)], fill=light)
    elif "metal" in name:
        draw.polygon([(7, 18), (24, 12), (27, 18), (10, 24)], fill=pal["metal"]); draw.line([(9, 18), (25, 13)], fill=clamp_color(pal["metal"], 30))
    elif "sign" in name or "marker" in name:
        draw.rectangle([14, 12, 17, 29], fill=pal["dead"]); draw.polygon([(7, 8), (25, 10), (23, 17), (8, 16)], fill=dark)
    elif "rubble" in name or "stone" in name:
        for _ in range(6):
            x, y = rng.randrange(5, 24), rng.randrange(11, 25)
            draw.rectangle([x, y, x + rng.randrange(3, 7), y + rng.randrange(2, 5)], fill=clamp_color(stone, rng.randrange(-35, 25)))
    elif "scrub" in name or "grass" in name or "thorn" in name:
        for _ in range(8):
            x = rng.randrange(8, 24)
            draw.line([(16, 24), (x, rng.randrange(8, 19))], fill=pal["dead"], width=1)
        if "thorn" in name:
            draw.line([(8, 18), (24, 15)], fill=clamp_color(pal["dead"], -20), width=2)
    elif "root" in name or "stump" in name:
        draw.rectangle([12, 12, 21, 25], fill=pal["dead"]); draw.line([(12, 24), (6, 28)], fill=pal["dead"], width=2); draw.line([(20, 24), (27, 27)], fill=pal["dead"], width=2)
    elif "bone" in name:
        draw.line([(7, 21), (25, 14)], fill=pal["bone"], width=3); draw.ellipse([4, 18, 10, 24], fill=pal["bone"]); draw.ellipse([22, 11, 28, 17], fill=pal["bone"])
    elif "flower" in name:
        draw.line([(16, 25), (16, 15)], fill=pal["dead"], width=1); draw.rectangle([14, 13, 18, 17], fill=pal["magenta"]); draw.point((16, 15), fill=pal["cyan"])
    elif "crate" in name:
        draw.rectangle([8, 12, 24, 27], fill=pal["dead"]); draw.line([(8, 12), (24, 27)], fill=clamp_color(pal["dead"], -25)); draw.line([(24, 12), (8, 27)], fill=clamp_color(pal["dead"], -25))
    elif "campfire" in name:
        draw.ellipse([9, 17, 23, 25], fill=clamp_color(pal["ash"], -15)); draw.line([(9, 21), (22, 18)], fill=pal["dead"], width=2)
    elif "cloth" in name:
        draw.polygon([(8, 14), (25, 16), (22, 25), (6, 22)], fill=rgba("#7a6160", 210)); draw.line([(8, 14), (22, 25)], fill=rgba("#5a4544", 200))
    elif "salvage" in name:
        draw.rectangle([7, 18, 17, 25], fill=pal["metal"]); draw.rectangle([18, 15, 25, 23], fill=pal["dead"]); draw.point((20, 17), fill=pal["cyan"])
    else:
        draw.rectangle([9, 14, 24, 25], fill=dark); draw.line([(10, 15), (23, 15)], fill=light)
    return img


def tile_hazard(name: str, cfg: Dict) -> Image.Image:
    pal = cfg["palette"]
    rng = seeded_rng(cfg["label"], name)
    img = tile_base("shadowed_ground", cfg)
    draw = ImageDraw.Draw(img, "RGBA")
    if "vent" in name:
        draw.ellipse([7, 8, 25, 24], fill=(*pal["scar_dark"][:3], 190))
        for x in [11, 16, 21]:
            draw.line([(x, 9), (x - 2, 23)], fill=pal["magenta"], width=1)
    elif "stain" in name:
        alpha = 90 if "shallow" in name else 170
        draw.ellipse([4, 7, 28, 25], fill=(*pal["scar_dark"][:3], alpha))
        draw.ellipse([10, 12, 22, 21], fill=(*pal["scar"][:3], alpha // 2))
    elif "boundary" in name:
        col = pal["warn"] if "hazard" in name else pal["path2"]
        draw.rectangle([0, 13, 31, 18], fill=(*col[:3], 180))
        for x in range(2, 31, 8):
            draw.line([(x, 18), (x + 5, 13)], fill=pal["shadow"], width=1)
    elif "warning" in name:
        draw.polygon([(16, 5), (27, 25), (5, 25)], outline=pal["warn"], fill=(*pal["warn"][:3], 45))
        draw.line([(16, 11), (16, 18)], fill=pal["magenta"])
    else:
        draw_cracks(draw, rng, pal, cfg["crack"] * 1.2, True)
    return img


def tile_utility(name: str, cfg: Dict) -> Image.Image:
    pal = cfg["palette"]
    img = Image.new("RGBA", (TILE, TILE), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img, "RGBA")
    if "shadow" in name:
        draw.ellipse([3, 18, 29, 28], fill=(0, 0, 0, 95))
    elif "highlight" in name:
        draw.ellipse([5, 6, 27, 23], outline=(*pal["path2"][:3], 115), width=2)
    elif "dust" in name:
        for p in [(8, 12), (16, 9), (24, 18), (13, 24)]:
            draw.point(p, fill=(*pal["ash"][:3], 150))
    elif "violet" in name:
        draw.line([(14, 8), (18, 24)], fill=pal["magenta"]); draw.line([(10, 16), (22, 16)], fill=pal["magenta"])
    elif "cyan" in name:
        draw.line([(14, 8), (18, 24)], fill=pal["cyan"]); draw.line([(10, 16), (22, 16)], fill=pal["cyan"])
    elif "separator" in name:
        draw.rectangle([0, 14, 31, 17], fill=(*pal["path2"][:3], 180))
    elif "label_backer" in name:
        draw.rectangle([2, 8, 29, 24], fill=(0, 0, 0, 90))
    elif "pebble" in name or "ground" in name:
        draw.rectangle([13, 14, 18, 18], fill=pal["stone"])
    elif "line" in name:
        draw.line([(0, 16), (31, 16)], fill=(0, 0, 0, 100) if "shadow" in name else (*pal["path2"][:3], 140))
    elif "debug" in name:
        draw.rectangle([0, 0, 31, 31], outline=(0, 0, 0, 170))
    return img


def render_tile(spec: Dict, cfg: Dict) -> Image.Image:
    name = spec["name"]
    category = spec["category"]
    if category == "base terrain":
        return tile_base(name, cfg)
    if category == "safe path":
        return tile_path(name, cfg)
    if category == "transitions":
        return tile_transition(name, cfg)
    if category == "fracture/corruption":
        return tile_fracture(name, cfg)
    if category == "ruins/rocks":
        return tile_ruin_or_prop(name, category, cfg)
    if category == "vegetation/props":
        return tile_ruin_or_prop(name, category, cfg)
    if category == "hazard-looking tiles":
        return tile_hazard(name, cfg)
    return tile_utility(name, cfg)


def generate_atlas(variant_key: str, cfg: Dict) -> Image.Image:
    atlas = Image.new("RGBA", (ATLAS_SIZE, ATLAS_SIZE), (0, 0, 0, 0))
    for spec in LAYOUT:
        tile = render_tile(spec, cfg)
        atlas.alpha_composite(tile, (spec["x"] * TILE, spec["y"] * TILE))
    return atlas


def crop_tile(atlas: Image.Image, name: str) -> Image.Image:
    spec = SPEC_BY_NAME[name]
    return atlas.crop((spec["x"] * TILE, spec["y"] * TILE, spec["x"] * TILE + TILE, spec["y"] * TILE + TILE))


def choose_path_name(connections: Tuple[bool, bool, bool, bool]) -> str:
    n, e, s, w = connections
    count = sum(connections)
    if count >= 4:
        return "safe_path_cross"
    if count == 3:
        if not n:
            return "safe_path_t_south"
        if not s:
            return "safe_path_t_north"
        if not e:
            return "safe_path_t_west"
        return "safe_path_t_east"
    if count == 2:
        if e and w:
            return "safe_path_horizontal"
        if n and s:
            return "safe_path_vertical"
        if n and e:
            return "safe_path_corner_ne"
        if n and w:
            return "safe_path_corner_nw"
        if s and e:
            return "safe_path_corner_se"
        return "safe_path_corner_sw"
    if count == 1:
        if n:
            return "safe_path_end_north"
        if s:
            return "safe_path_end_south"
        if e:
            return "safe_path_end_east"
        return "safe_path_end_west"
    return "safe_path_center"


def draw_label(draw: ImageDraw.ImageDraw, xy: Tuple[int, int], text: str, font: ImageFont.ImageFont, fill=(245, 240, 230, 255)) -> None:
    x, y = xy
    draw.text((x + 1, y + 1), text, font=font, fill=(0, 0, 0, 230))
    draw.text((x, y), text, font=font, fill=fill)


def load_font(size: int) -> ImageFont.ImageFont:
    for path in [Path("C:/Windows/Fonts/arial.ttf"), Path("C:/Windows/Fonts/segoeui.ttf")]:
        if path.exists():
            return ImageFont.truetype(str(path), size)
    return ImageFont.load_default()


def create_mockup(variant_key: str, cfg: Dict, atlas: Image.Image) -> Image.Image:
    board = Image.new("RGBA", (MOCK_W * TILE, MOCK_H * TILE), cfg["palette"]["shadow"])
    rng = random.Random(f"mockup::{variant_key}")
    base_cycle = [
        "dark_cracked_ground_base", "lighter_cracked_ground_variation", "dusty_ash_ground",
        "dead_soil", "stony_wasteland", "low_noise_traversal_tile", "dry_rubble_ground",
    ]
    for y in range(MOCK_H):
        for x in range(MOCK_W):
            name = base_cycle[(x * 5 + y * 7) % len(base_cycle)]
            if x > 15 and y < 8:
                name = "purple_tinted_corrupted_ground" if (x + y) % 3 == 0 else "shadowed_ground"
            elif x < 5 and y > 12:
                name = "scorched_soil" if (x + y) % 2 == 0 else "shadowed_ground"
            elif (x * 13 + y * 3) % 17 == 0:
                name = "low_noise_traversal_tile"
            board.alpha_composite(crop_tile(atlas, name), (x * TILE, y * TILE))

    path_cells = set()
    for x in range(1, 8):
        path_cells.add((x, 13))
    for y in range(8, 14):
        path_cells.add((7, y))
    for x in range(7, 15):
        path_cells.add((x, 8))
    for y in range(4, 9):
        path_cells.add((14, y))
    for x in range(14, 22):
        path_cells.add((x, 4))
    for y in range(4, 12):
        path_cells.add((21, y))
    for x in range(11, 15):
        path_cells.add((x, 12))
    for y in range(9, 13):
        path_cells.add((11, y))

    for x, y in path_cells:
        con = ((x, y - 1) in path_cells, (x + 1, y) in path_cells, (x, y + 1) in path_cells, (x - 1, y) in path_cells)
        board.alpha_composite(crop_tile(atlas, choose_path_name(con)), (x * TILE, y * TILE))

    overlay_tiles = [
        (17, 6, "shallow_corruption_stain"), (18, 6, "purple_scar_crack_tile"), (19, 6, "thin_fracture_line_horizontal"),
        (20, 6, "glowing_rift_small"), (18, 7, "unstable_ground"), (19, 7, "deep_corruption_stain"),
        (20, 7, "fracture_warning_accent"), (17, 8, "fading_corruption_edge"), (21, 8, "hazard_boundary_marker"),
        (4, 4, "low_ruin_wall_horizontal"), (5, 4, "low_ruin_wall_horizontal"), (6, 4, "ruin_corner"),
        (4, 5, "ruined_pillar_base"), (6, 5, "collapsed_wall_fragment"), (5, 6, "rubble_pile"),
        (2, 14, "dead_scrub"), (3, 15, "thorn_bush"), (5, 15, "blackened_root"),
        (9, 13, "survivor_camp_crate"), (10, 13, "old_campfire_ash"), (12, 14, "small_salvage_pile"),
        (15, 3, "safe_boundary_marker"), (13, 12, "warning_marker"), (22, 10, "cyan_magenta_anomaly_tile"),
        (16, 13, "bone_shard_pile"), (18, 13, "ash_flower_corrupted_flower"), (22, 3, "violet_spark"),
    ]
    for x, y, name in overlay_tiles:
        board.alpha_composite(crop_tile(atlas, name), (x * TILE, y * TILE))

    draw = ImageDraw.Draw(board, "RGBA")
    font = load_font(13)
    small = load_font(11)
    def marker(tile_x: int, tile_y: int, color: Tuple[int, int, int, int], label: str) -> None:
        px, py = tile_x * TILE, tile_y * TILE
        draw.ellipse([px + 6, py + 23, px + 26, py + 30], fill=(0, 0, 0, 110))
        draw.rectangle([px + 10, py + 8, px + 21, py + 27], fill=color)
        draw.rectangle([px + 9, py + 3, px + 22, py + 10], fill=(232, 184, 142, 255))
        draw_label(draw, (px - 14, py - 12), label, small)

    marker(7, 12, rgba("#36c7ef"), "Player")
    marker(10, 8, rgba("#9f49b7"), "Lyra")
    marker(12, 13, rgba("#8f8574"), "Survivor")
    draw_label(draw, (10 * TILE - 10, 8 * TILE + 26), "[F] Talk", small, (255, 244, 130, 255))
    draw_label(draw, (16 * TILE, 6 * TILE - 18), "Corruption edge", small, (255, 130, 236, 255))
    draw_label(draw, (1 * TILE, 12 * TILE - 16), "Readable safe path", font, (246, 229, 180, 255))
    draw_label(draw, (1 * TILE, 16 * TILE + 2), "Dark corner contrast", small, (220, 220, 225, 255))
    return board


def fit_image(img: Image.Image, max_w: int, max_h: int) -> Image.Image:
    scale = min(max_w / img.width, max_h / img.height)
    size = (max(1, int(img.width * scale)), max(1, int(img.height * scale)))
    return img.resize(size, Image.Resampling.NEAREST)


def make_contact_sheet(paths: List[Tuple[str, Path]], out_path: Path) -> None:
    panel_w, panel_h = 640, 500
    cols = 4
    rows = math.ceil(len(paths) / cols)
    sheet = Image.new("RGBA", (panel_w * cols, panel_h * rows), rgba("#1b171c"))
    draw = ImageDraw.Draw(sheet, "RGBA")
    font = load_font(20)
    for idx, (label, path) in enumerate(paths):
        x0 = (idx % cols) * panel_w
        y0 = (idx // cols) * panel_h
        draw.rectangle([x0, y0, x0 + panel_w - 1, y0 + panel_h - 1], outline=rgba("#4f4554"))
        draw_label(draw, (x0 + 18, y0 + 14), label, font, (240, 226, 205, 255))
        if path.exists():
            img = Image.open(path).convert("RGBA")
            fitted = fit_image(img, panel_w - 36, panel_h - 70)
            sheet.alpha_composite(fitted, (x0 + (panel_w - fitted.width) // 2, y0 + 58))
        else:
            draw_label(draw, (x0 + 18, y0 + 90), f"Missing: {path}", load_font(14), (255, 120, 120, 255))
    sheet.save(out_path)


def write_layout_markdown(out_path: Path) -> None:
    lines = [
        "# Fractured Wastes R1 Tile Layout",
        "",
        "All variants share this 512x512 atlas layout: 16 columns x 16 rows, 32x32 tiles.",
        "",
        "| Coord | Tile Name | Category | Intended Use | Notes |",
        "|---|---|---|---|---|",
    ]
    for spec in sorted(LAYOUT, key=lambda s: (s["y"], s["x"])):
        lines.append(
            f"| ({spec['x']},{spec['y']}) | `{spec['name']}` | {spec['category']} | {spec['intended_use']} | {spec['notes']} |"
        )
    out_path.write_text("\n".join(lines) + "\n", encoding="utf-8")


def main() -> None:
    for path in [GENERATED_DIR, MOCKUP_DIR, REVIEW_DIR, MANIFEST_DIR, DIAGNOSTIC_DIR]:
        path.mkdir(parents=True, exist_ok=True)

    atlases: Dict[str, Image.Image] = {}
    manifest_variants = {}
    for key, cfg in VARIANTS.items():
        atlas = generate_atlas(key, cfg)
        atlases[key] = atlas
        atlas_path = GENERATED_DIR / cfg["filename"]
        atlas.save(atlas_path)
        atlas.resize((ATLAS_SIZE * 2, ATLAS_SIZE * 2), Image.Resampling.NEAREST).save(REVIEW_DIR / cfg["preview"])

        mock = create_mockup(key, cfg, atlas)
        mock_path = MOCKUP_DIR / cfg["mockup"]
        mock.save(mock_path)
        mock.resize((mock.width * 2, mock.height * 2), Image.Resampling.NEAREST).save(MOCKUP_DIR / cfg["mockup"].replace(".png", "_2x.png"))

        manifest_variants[key] = {
            "label": cfg["label"],
            "atlas_path": str(atlas_path.relative_to(PROJECT_ROOT)).replace("\\", "/"),
            "preview_2x_path": str((REVIEW_DIR / cfg["preview"]).relative_to(PROJECT_ROOT)).replace("\\", "/"),
            "mockup_path": str(mock_path.relative_to(PROJECT_ROOT)).replace("\\", "/"),
            "mockup_2x_path": str((MOCKUP_DIR / cfg["mockup"].replace(".png", "_2x.png")).relative_to(PROJECT_ROOT)).replace("\\", "/"),
            "overall_score": cfg["score"],
        }

    fallback = PROJECT_ROOT / "assets" / "generated_v2" / "tilesets" / "fractured_wastes_v2_prototype_tileset.png"
    fallback_ref = REVIEW_DIR / "fractured_wastes_r1_fallback_tileset_reference.png"
    if fallback.exists():
        img = Image.open(fallback).convert("RGBA")
        img.resize((img.width * 4, img.height * 4), Image.Resampling.NEAREST).save(fallback_ref)

    scene_refs = [
        PROJECT_ROOT / "docs" / "visual_review" / "phase10mm3" / "fractured_wastes_after.png",
        PROJECT_ROOT / "docs" / "visual_review" / "phase10mm2" / "fractured_wastes_after.png",
        PROJECT_ROOT / "docs" / "visual_review" / "phase10mm" / "fractured_wastes_after.png",
    ]
    scene_ref = next((p for p in scene_refs if p.exists()), None)

    contact_inputs = [
        ("Current fallback tileset", fallback_ref),
        ("Current scene reference", scene_ref if scene_ref else fallback_ref),
        ("R1 Variant A atlas", GENERATED_DIR / VARIANTS["a_clean"]["filename"]),
        ("R1 Variant B atlas", GENERATED_DIR / VARIANTS["b_textured"]["filename"]),
        ("R1 Variant C atlas", GENERATED_DIR / VARIANTS["c_corrupt_dark"]["filename"]),
        ("R1 Variant A mockup", MOCKUP_DIR / VARIANTS["a_clean"]["mockup"]),
        ("R1 Variant B mockup", MOCKUP_DIR / VARIANTS["b_textured"]["mockup"]),
        ("R1 Variant C mockup", MOCKUP_DIR / VARIANTS["c_corrupt_dark"]["mockup"]),
    ]
    make_contact_sheet(contact_inputs, REVIEW_DIR / "fractured_wastes_r1_comparison_contact_sheet.png")

    write_layout_markdown(MANIFEST_DIR / "fractured_wastes_r1_tile_layout.md")
    manifest = {
        "phase": "10M-R1",
        "atlas_size": "512x512",
        "tile_size": 32,
        "grid": "16x16",
        "production_art_changed": False,
        "source_method": "deterministic Python/Pillow controlled tile grammar",
        "fallback_reference": str(fallback.relative_to(PROJECT_ROOT)).replace("\\", "/") if fallback.exists() else "",
        "scene_reference": str(scene_ref.relative_to(PROJECT_ROOT)).replace("\\", "/") if scene_ref else "",
        "variants": manifest_variants,
        "best_variant": "b_textured",
        "decision": "Ready for Fractured Wastes preview-only Godot scene pass",
    }
    (MANIFEST_DIR / "fractured_wastes_r1_variant_manifest.json").write_text(json.dumps(manifest, indent=2), encoding="utf-8")
    print(json.dumps({
        "generated_variants": list(manifest_variants.keys()),
        "best_variant": "b_textured",
        "output_root": str(OUT_ROOT),
    }, indent=2))


if __name__ == "__main__":
    main()
