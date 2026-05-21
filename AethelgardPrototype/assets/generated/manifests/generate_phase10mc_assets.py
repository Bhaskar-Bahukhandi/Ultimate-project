from __future__ import annotations

import json
import math
from dataclasses import dataclass
from pathlib import Path
from typing import Callable, Iterable

from PIL import Image, ImageDraw


ROOT = Path(__file__).resolve().parents[3]
GENERATED = ROOT / "assets" / "generated"
MANIFEST_DIR = GENERATED / "manifests"
PREVIEW_DIR = MANIFEST_DIR / "previews"


RGBA = tuple[int, int, int, int]
FramePainter = Callable[[Image.Image, int, int, int, int], None]


@dataclass
class AssetRecord:
    path: str
    kind: str
    width: int
    height: int
    frame_size: tuple[int, int]
    rows: list[dict[str, object]]
    intended_godot_type: str
    integration_priority: str
    alpha_required: bool
    notes: str
    tile_size: tuple[int, int] | None = None
    tiles: list[str] | None = None


ASSETS: list[AssetRecord] = []


INK: RGBA = (17, 17, 28, 255)
SHADOW: RGBA = (21, 25, 38, 140)
CLEAR: RGBA = (0, 0, 0, 0)
SKIN: RGBA = (217, 166, 121, 255)
HAIR: RGBA = (48, 36, 58, 255)
KAELEN_COAT: RGBA = (37, 84, 126, 255)
KAELEN_TRIM: RGBA = (87, 210, 214, 255)
ROOT_GLOW: RGBA = (191, 255, 238, 255)
STEEL: RGBA = (138, 154, 177, 255)
STEEL_LIGHT: RGBA = (215, 226, 239, 255)
KNIGHT_PLUME: RGBA = (201, 57, 78, 255)
KNIGHT_GLOW: RGBA = (244, 151, 110, 255)
GLITCH: RGBA = (219, 73, 239, 255)
GREEN: RGBA = (96, 219, 106, 255)
GOLD: RGBA = (244, 201, 82, 255)
TEAL: RGBA = (49, 193, 183, 255)
BLUE: RGBA = (75, 137, 235, 255)
RED: RGBA = (215, 70, 84, 255)
WHITE: RGBA = (244, 246, 241, 255)


def rel(path: Path) -> str:
    return path.relative_to(ROOT).as_posix()


def make_dirs() -> None:
    for directory in [
        GENERATED / "sprites" / "player",
        GENERATED / "sprites" / "npcs",
        GENERATED / "sprites" / "enemies",
        GENERATED / "sprites" / "bosses",
        GENERATED / "icons",
        GENERATED / "vfx",
        GENERATED / "tilesets",
        MANIFEST_DIR,
        PREVIEW_DIR,
    ]:
        directory.mkdir(parents=True, exist_ok=True)


def add_record(
    path: Path,
    kind: str,
    image: Image.Image,
    frame_size: tuple[int, int],
    rows: list[dict[str, object]],
    intended_godot_type: str,
    priority: str,
    alpha_required: bool,
    notes: str,
    tile_size: tuple[int, int] | None = None,
    tiles: list[str] | None = None,
) -> None:
    ASSETS.append(
        AssetRecord(
            path=rel(path),
            kind=kind,
            width=image.width,
            height=image.height,
            frame_size=frame_size,
            rows=rows,
            intended_godot_type=intended_godot_type,
            integration_priority=priority,
            alpha_required=alpha_required,
            notes=notes,
            tile_size=tile_size,
            tiles=tiles,
        )
    )


def save_sheet(
    path: Path,
    frame_size: tuple[int, int],
    rows: list[dict[str, object]],
    painter: FramePainter,
    kind: str,
    intended_type: str,
    priority: str,
    notes: str,
    alpha_required: bool = True,
) -> Image.Image:
    columns = max(int(row["frames"]) for row in rows)
    fw, fh = frame_size
    image = Image.new("RGBA", (columns * fw, len(rows) * fh), CLEAR)
    for row_index, row in enumerate(rows):
        for frame_index in range(int(row["frames"])):
            painter(image, row_index, frame_index, frame_index * fw, row_index * fh)
    path.parent.mkdir(parents=True, exist_ok=True)
    image.save(path)
    add_record(path, kind, image, frame_size, rows, intended_type, priority, alpha_required, notes)
    return image


def draw_outline_rect(draw: ImageDraw.ImageDraw, box: tuple[int, int, int, int], fill: RGBA, outline: RGBA = INK) -> None:
    draw.rectangle(box, fill=outline)
    x0, y0, x1, y1 = box
    if x1 - x0 > 2 and y1 - y0 > 2:
        draw.rectangle((x0 + 1, y0 + 1, x1 - 1, y1 - 1), fill=fill)


def draw_shadow(draw: ImageDraw.ImageDraw, cx: int, y: int, rx: int, ry: int) -> None:
    draw.ellipse((cx - rx, y - ry, cx + rx, y + ry), fill=SHADOW)


def draw_kaelen_topdown(image: Image.Image, row: int, frame: int, ox: int, oy: int) -> None:
    draw = ImageDraw.Draw(image)
    cx = ox + 16
    bob = 1 if frame % 2 else 0
    step = [-1, 0, 1, 0][frame % 4]
    direction = row // 2
    action = row % 2
    draw_shadow(draw, cx, oy + 27, 8, 2)
    draw_outline_rect(draw, (cx - 5, oy + 12 + bob, cx + 5, oy + 23 + bob), KAELEN_COAT)
    if direction == 0:
        draw_outline_rect(draw, (cx - 5, oy + 5 + bob, cx + 5, oy + 14 + bob), HAIR)
        draw.rectangle((cx - 3, oy + 10 + bob, cx + 3, oy + 15 + bob), fill=SKIN)
    elif direction == 1:
        draw.rectangle((cx - 4, oy + 5 + bob, cx + 4, oy + 13 + bob), fill=HAIR)
        draw_outline_rect(draw, (cx - 5, oy + 5 + bob, cx + 5, oy + 15 + bob), HAIR)
        draw.rectangle((cx - 5, oy + 15 + bob, cx + 5, oy + 16 + bob), fill=KAELEN_TRIM)
    elif direction == 2:
        draw_outline_rect(draw, (cx - 6, oy + 6 + bob, cx + 4, oy + 15 + bob), SKIN)
        draw.rectangle((cx - 6, oy + 6 + bob, cx - 1, oy + 10 + bob), fill=HAIR)
    else:
        draw_outline_rect(draw, (cx - 4, oy + 6 + bob, cx + 6, oy + 15 + bob), SKIN)
        draw.rectangle((cx + 1, oy + 6 + bob, cx + 6, oy + 10 + bob), fill=HAIR)
    if action == 1:
        draw.rectangle((cx - 5 - step, oy + 23 + bob, cx - 1 - step, oy + 28), fill=INK)
        draw.rectangle((cx + 1 + step, oy + 23 + bob, cx + 5 + step, oy + 28), fill=INK)
        draw.rectangle((cx - 4 - step, oy + 23 + bob, cx - 2 - step, oy + 27), fill=KAELEN_TRIM)
        draw.rectangle((cx + 2 + step, oy + 23 + bob, cx + 4 + step, oy + 27), fill=KAELEN_TRIM)
    else:
        draw.rectangle((cx - 5, oy + 23 + bob, cx - 2, oy + 28), fill=INK)
        draw.rectangle((cx + 2, oy + 23 + bob, cx + 5, oy + 28), fill=INK)
    draw.line((cx, oy + 14 + bob, cx, oy + 23 + bob), fill=ROOT_GLOW, width=1)
    if action == 1 and frame in (1, 2):
        draw.rectangle((cx + 7, oy + 16 + bob, cx + 9, oy + 19 + bob), fill=ROOT_GLOW)


def combat_pose(row_name: str, frame: int) -> dict[str, int]:
    if row_name == "run":
        return {"bob": frame % 2, "lean": 1, "step": [-2, -1, 1, 2][frame % 4], "sword": 0}
    if row_name.startswith("slash"):
        return {"bob": 0, "lean": 0, "step": 0, "sword": [-11, -4, 6, 13][frame % 4]}
    if row_name == "dash":
        return {"bob": 1, "lean": 4, "step": 2, "sword": 5}
    if row_name == "hurt":
        return {"bob": 1, "lean": -2, "step": 0, "sword": -4}
    if row_name == "death":
        return {"bob": min(4, frame), "lean": frame * 2, "step": 0, "sword": -8}
    if row_name == "cast":
        return {"bob": 0, "lean": 0, "step": 0, "sword": 3}
    if row_name == "upslash":
        return {"bob": 0, "lean": 0, "step": 0, "sword": frame * 3}
    if row_name == "downslash":
        return {"bob": 0, "lean": 0, "step": 0, "sword": 8 - frame * 3}
    return {"bob": 1 if frame == 1 else 0, "lean": 0, "step": 0, "sword": 0}


def draw_kaelen_combat_factory(rows: list[dict[str, object]]) -> FramePainter:
    def painter(image: Image.Image, row: int, frame: int, ox: int, oy: int) -> None:
        name = str(rows[row]["animation"])
        pose = combat_pose(name, frame)
        draw = ImageDraw.Draw(image)
        cx = ox + 28 + pose["lean"]
        feet = oy + 54 - pose["bob"]
        draw_shadow(draw, ox + 30, oy + 57, 15, 3)
        if name == "death":
            fall = frame * 3
            draw_outline_rect(draw, (cx - 12, feet - 16 + fall, cx + 12, feet - 8 + fall), KAELEN_COAT)
            draw_outline_rect(draw, (cx + 8, feet - 20 + fall, cx + 18, feet - 9 + fall), SKIN)
            return
        draw.rectangle((cx - 6 - pose["step"], feet - 13, cx - 2 - pose["step"], feet), fill=INK)
        draw.rectangle((cx + 3 + pose["step"], feet - 13, cx + 7 + pose["step"], feet), fill=INK)
        draw_outline_rect(draw, (cx - 9, feet - 34, cx + 9, feet - 13), KAELEN_COAT)
        draw.rectangle((cx - 9, feet - 22, cx + 9, feet - 19), fill=KAELEN_TRIM)
        draw_outline_rect(draw, (cx - 8, feet - 47, cx + 6, feet - 34), SKIN)
        draw.rectangle((cx - 9, feet - 49, cx + 5, feet - 42), fill=HAIR)
        draw.rectangle((cx + 3, feet - 44, cx + 8, feet - 40), fill=SKIN)
        draw.line((cx - 8, feet - 31, cx - 15, feet - 20), fill=INK, width=4)
        draw.line((cx - 8, feet - 31, cx - 15, feet - 20), fill=KAELEN_TRIM, width=2)
        sword_base = (cx + 8, feet - 29)
        sword_tip = (cx + 26, feet - 34 - pose["sword"])
        if name == "upslash":
            sword_tip = (cx + 13, feet - 56 - pose["sword"])
        if name == "downslash":
            sword_tip = (cx + 18, feet - 2 + pose["sword"])
        draw.line((cx + 7, feet - 31, sword_base[0], sword_base[1]), fill=INK, width=4)
        draw.line((sword_base[0], sword_base[1], sword_tip[0], sword_tip[1]), fill=INK, width=5)
        draw.line((sword_base[0], sword_base[1], sword_tip[0], sword_tip[1]), fill=STEEL_LIGHT, width=2)
        if "slash" in name and frame in (1, 2):
            draw.arc((cx + 5, feet - 57, cx + 49, feet - 3), -75, 65, fill=ROOT_GLOW, width=3)
        if name == "dash":
            for trail in range(3):
                draw.rectangle((ox + 5 + trail * 5, feet - 32 + trail, ox + 16 + trail * 4, feet - 25 + trail), fill=(87, 210, 214, 120 - trail * 30))
        if name == "cast":
            radius = 3 + frame * 2
            draw.ellipse((cx - 22 - radius, feet - 33 - radius, cx - 22 + radius, feet - 33 + radius), outline=ROOT_GLOW, width=2)
        if name == "hurt":
            draw.line((cx - 13, feet - 42, cx + 17, feet - 16), fill=RED, width=2)

    return painter


def draw_knight_factory(rows: list[dict[str, object]]) -> FramePainter:
    def painter(image: Image.Image, row: int, frame: int, ox: int, oy: int) -> None:
        animation = str(rows[row]["animation"])
        draw = ImageDraw.Draw(image)
        cx = ox + 31
        feet = oy + 56
        pulse = frame % 2
        lunge = frame * 2 if animation in {"charge", "shield_bash"} else 0
        if animation == "teleport_slash":
            for ghost in range(3 - min(frame, 2)):
                draw.rectangle((ox + 8 + ghost * 5, oy + 18, ox + 17 + ghost * 5, oy + 46), fill=(219, 73, 239, 55))
        draw_shadow(draw, cx, oy + 59, 18, 3)
        if animation == "defeat":
            sink = frame * 3
            draw_outline_rect(draw, (cx - 19, feet - 15 + sink, cx + 12, feet - 4 + sink), STEEL)
            draw.polygon([(cx + 12, feet - 14 + sink), (cx + 25, feet - 7 + sink), (cx + 13, feet - 3 + sink)], fill=KNIGHT_PLUME)
            return
        draw.rectangle((cx - 12 + lunge, feet - 13, cx - 5 + lunge, feet), fill=INK)
        draw.rectangle((cx + 5 + lunge, feet - 13, cx + 12 + lunge, feet), fill=INK)
        draw_outline_rect(draw, (cx - 18 + lunge, feet - 39, cx + 15 + lunge, feet - 12), STEEL)
        draw.rectangle((cx - 15 + lunge, feet - 33, cx + 12 + lunge, feet - 30), fill=KNIGHT_GLOW)
        draw_outline_rect(draw, (cx - 13 + lunge, feet - 55 + pulse, cx + 9 + lunge, feet - 38 + pulse), STEEL_LIGHT)
        draw.rectangle((cx - 10 + lunge, feet - 49 + pulse, cx + 6 + lunge, feet - 47 + pulse), fill=INK)
        draw.rectangle((cx - 3 + lunge, feet - 61 + pulse, cx + 12 + lunge, feet - 56 + pulse), fill=KNIGHT_PLUME)
        shield_x = cx - 27 + lunge
        if animation == "shield_bash":
            shield_x -= frame
        draw.polygon(
            [(shield_x, feet - 37), (shield_x + 12, feet - 43), (shield_x + 18, feet - 24), (shield_x + 6, feet - 12)],
            fill=INK,
        )
        draw.polygon(
            [(shield_x + 2, feet - 36), (shield_x + 11, feet - 40), (shield_x + 15, feet - 25), (shield_x + 7, feet - 16)],
            fill=STEEL,
        )
        sword_tip = (cx + 31 + lunge, feet - 35)
        if animation == "low_sweep":
            sword_tip = (cx + 38 + lunge, feet - 13 + frame)
        elif animation == "shockwave":
            sword_tip = (cx + 24 + lunge, feet - 2)
        elif animation in {"slash", "teleport_slash"}:
            sword_tip = (cx + 34 + lunge, feet - 48 + frame * 10)
        draw.line((cx + 13 + lunge, feet - 31, sword_tip[0], sword_tip[1]), fill=INK, width=6)
        draw.line((cx + 13 + lunge, feet - 31, sword_tip[0], sword_tip[1]), fill=STEEL_LIGHT, width=2)
        if animation in {"slash", "teleport_slash", "low_sweep"} and frame in (1, 2):
            draw.arc((cx + 6 + lunge, feet - 57, cx + 58 + lunge, feet - 4), -78, 70, fill=KNIGHT_GLOW, width=3)
        if animation == "corrupt_rift":
            draw.rectangle((ox + 10 + frame * 2, feet - 5, ox + 54 - frame * 2, feet - 2), fill=GLITCH)
            draw.line((ox + 18, feet - 4, ox + 24, feet - 20 - frame * 2), fill=GLITCH, width=2)
        if animation == "phase_change":
            draw.rectangle((cx - 20, feet - 58, cx + 18, feet - 10), outline=(244, 151, 110, 120 + frame * 25), width=2)
    return painter


def enemy_painter(kind: str, primary: RGBA, secondary: RGBA, rows: list[dict[str, object]]) -> FramePainter:
    def painter(image: Image.Image, row: int, frame: int, ox: int, oy: int) -> None:
        animation = str(rows[row]["animation"])
        draw = ImageDraw.Draw(image)
        cx = ox + 24
        feet = oy + 42
        bob = frame % 2
        draw_shadow(draw, cx, oy + 45, 12, 2)
        if kind == "fracture_slime":
            stretch = 2 if animation == "attack" and frame >= 1 else 0
            draw.polygon(
                [(cx - 16, feet), (cx - 13, feet - 18 + bob), (cx - 3, feet - 28 - bob), (cx + 9 + stretch, feet - 23), (cx + 16 + stretch, feet)],
                fill=INK,
            )
            draw.polygon(
                [(cx - 13, feet - 2), (cx - 9, feet - 17 + bob), (cx - 2, feet - 23 - bob), (cx + 9 + stretch, feet - 18), (cx + 13 + stretch, feet - 2)],
                fill=primary,
            )
            draw.rectangle((cx - 5, feet - 17, cx + 0, feet - 13), fill=secondary)
            draw.rectangle((cx + 4, feet - 16, cx + 8, feet - 12), fill=secondary)
        elif kind == "clock_mite":
            step = [-2, 0, 2, 0][frame % 4]
            draw_outline_rect(draw, (cx - 14, feet - 25 + bob, cx + 12, feet - 8 + bob), primary)
            draw.rectangle((cx - 7, feet - 19 + bob, cx + 6, feet - 15 + bob), fill=secondary)
            for leg in (-11, -3, 5, 13):
                draw.line((cx + leg // 2, feet - 8, cx + leg + step, feet), fill=INK, width=2)
            if animation == "attack":
                draw.line((cx + 11, feet - 19, cx + 24 + frame * 2, feet - 12), fill=secondary, width=3)
        else:
            wave = int(math.sin(frame / 4 * math.pi) * 3)
            draw.polygon([(cx - 12, feet - 1), (cx - 15, feet - 25), (cx, feet - 37 - bob), (cx + 15, feet - 25), (cx + 12, feet - 1)], fill=INK)
            draw.polygon([(cx - 9, feet - 4), (cx - 10, feet - 23), (cx, feet - 32 - bob), (cx + 10, feet - 23), (cx + 9, feet - 4)], fill=primary)
            draw.rectangle((cx - 6, feet - 22, cx - 2, feet - 17), fill=secondary)
            draw.rectangle((cx + 2, feet - 22, cx + 6, feet - 17), fill=secondary)
            draw.line((cx - 9, feet - 7, cx - 19, feet - 1 + wave), fill=primary, width=2)
            draw.line((cx + 9, feet - 7, cx + 19, feet - 1 - wave), fill=primary, width=2)
            if animation == "attack":
                draw.arc((cx - 30, feet - 40, cx + 30, feet + 9), 210, 328, fill=secondary, width=3)
        if animation == "hurt":
            draw.line((ox + 9, oy + 9, ox + 39, oy + 39), fill=WHITE, width=2)
        if animation == "death":
            draw.rectangle((ox + 12, feet - frame * 2, ox + 36, feet - frame), fill=(secondary[0], secondary[1], secondary[2], max(50, 220 - frame * 35)))
    return painter


def npc_painter(name: str, primary: RGBA, accent: RGBA, hair: RGBA, rows: list[dict[str, object]]) -> FramePainter:
    prop_offset = {"elara": -7, "seraphina": 7, "lyra": -3, "null_clerk": 4, "assembly_runner": -5}[name]
    def painter(image: Image.Image, row: int, frame: int, ox: int, oy: int) -> None:
        animation = str(rows[row]["animation"])
        draw = ImageDraw.Draw(image)
        cx = ox + 16
        bob = frame % 2 if animation == "walk" else 0
        step = [-1, 1, 0, 1][frame % 4] if animation == "walk" else 0
        draw_shadow(draw, cx, oy + 29, 7, 2)
        draw.rectangle((cx - 4 - step, oy + 21 + bob, cx - 1 - step, oy + 28), fill=INK)
        draw.rectangle((cx + 2 + step, oy + 21 + bob, cx + 5 + step, oy + 28), fill=INK)
        draw_outline_rect(draw, (cx - 7, oy + 11 + bob, cx + 7, oy + 22 + bob), primary)
        draw_outline_rect(draw, (cx - 5, oy + 4 + bob, cx + 5, oy + 13 + bob), SKIN)
        draw.rectangle((cx - 6, oy + 3 + bob, cx + 6, oy + 7 + bob), fill=hair)
        draw.rectangle((cx - 5, oy + 16 + bob, cx + 5, oy + 17 + bob), fill=accent)
        if animation == "talk":
            draw.rectangle((cx + prop_offset, oy + 13 + bob, cx + prop_offset + 2, oy + 16 + bob), fill=accent)
            draw.rectangle((cx + 8, oy + 7 + frame, cx + 10, oy + 8 + frame), fill=WHITE)
        if name == "null_clerk":
            draw.rectangle((cx - 9, oy + 10 + bob, cx - 7, oy + 25 + bob), fill=ROOT_GLOW)
        if name == "assembly_runner":
            draw.rectangle((cx + 7, oy + 12 + bob, cx + 10, oy + 19 + bob), fill=GOLD)
    return painter


def tile_sheet(theme: str, palette: list[RGBA], tiles: list[str], path: Path) -> Image.Image:
    tile_size = 32
    cols = 4
    rows = math.ceil(len(tiles) / cols)
    image = Image.new("RGBA", (cols * tile_size, rows * tile_size), palette[0])
    draw = ImageDraw.Draw(image)
    for index, tile in enumerate(tiles):
        x = (index % cols) * tile_size
        y = (index // cols) * tile_size
        draw.rectangle((x, y, x + 31, y + 31), fill=palette[index % len(palette)])
        draw.rectangle((x, y, x + 31, y + 31), outline=INK)
        if tile in {"grass", "moss", "path"}:
            for stripe in range(4):
                draw.line((x + 5 + stripe * 6, y + 22 - stripe, x + 7 + stripe * 6, y + 16 - stripe), fill=palette[-1], width=2)
        elif "wall" in tile or tile in {"brick", "server"}:
            for yy in (y + 8, y + 17, y + 25):
                draw.line((x + 2, yy, x + 29, yy), fill=palette[-1], width=1)
            for xx in (x + 9, x + 21):
                draw.line((xx, y + 3, xx, y + 28), fill=palette[-1], width=1)
        elif tile in {"water", "tide", "memory"}:
            for yy in (y + 9, y + 18, y + 25):
                draw.arc((x + 4, yy - 5, x + 18, yy + 3), 0, 180, fill=palette[-1], width=2)
                draw.arc((x + 15, yy - 2, x + 29, yy + 6), 180, 360, fill=palette[-1], width=2)
        elif tile in {"rune", "mirror", "root", "glitch"}:
            draw.polygon([(x + 16, y + 4), (x + 27, y + 16), (x + 16, y + 27), (x + 5, y + 16)], outline=palette[-1])
            draw.line((x + 16, y + 7, x + 16, y + 25), fill=palette[-1], width=2)
        elif tile in {"crate", "console", "altar", "sign"}:
            draw_outline_rect(draw, (x + 6, y + 7, x + 25, y + 25), palette[-2], INK)
            draw.line((x + 8, y + 10, x + 23, y + 22), fill=palette[-1], width=2)
        else:
            for dot in range(10):
                px = x + 4 + ((dot * 7 + index * 3) % 24)
                py = y + 5 + ((dot * 11 + index) % 22)
                draw.point((px, py), fill=palette[-1])
    image.save(path)
    rows_manifest = [{"animation": "tiles", "frames": len(tiles), "tiles": tiles}]
    add_record(path, "tileset", image, (tile_size, tile_size), rows_manifest, "TileSetAtlasSource", "P2", False, f"{theme} prototype atlas.", (tile_size, tile_size), tiles)
    return image


def draw_icon(draw: ImageDraw.ImageDraw, ox: int, oy: int, index: int, style: str) -> None:
    draw.rectangle((ox + 2, oy + 2, ox + 29, oy + 29), outline=(255, 255, 255, 38))
    if style == "item":
        color = [RED, BLUE, GREEN, GOLD, TEAL, GLITCH, ROOT_GLOW, STEEL_LIGHT][index % 8]
        choice = index % 8
        if choice == 0:
            draw_outline_rect(draw, (ox + 11, oy + 6, ox + 21, oy + 24), color)
            draw.rectangle((ox + 13, oy + 3, ox + 19, oy + 7), fill=GOLD)
        elif choice == 1:
            draw.polygon([(ox + 16, oy + 4), (ox + 25, oy + 15), (ox + 17, oy + 27), (ox + 7, oy + 18)], fill=INK)
            draw.polygon([(ox + 16, oy + 7), (ox + 22, oy + 15), (ox + 16, oy + 24), (ox + 10, oy + 18)], fill=color)
        elif choice == 2:
            draw.polygon([(ox + 15, oy + 4), (ox + 24, oy + 10), (ox + 22, oy + 22), (ox + 15, oy + 28), (ox + 7, oy + 22), (ox + 7, oy + 10)], fill=color, outline=INK)
        elif choice == 3:
            draw.line((ox + 7, oy + 24, ox + 25, oy + 6), fill=INK, width=5)
            draw.line((ox + 8, oy + 23, ox + 24, oy + 7), fill=color, width=2)
        elif choice == 4:
            draw.arc((ox + 5, oy + 5, ox + 27, oy + 27), 40, 320, fill=color, width=4)
        elif choice == 5:
            draw.rectangle((ox + 7, oy + 8, ox + 25, oy + 24), fill=INK)
            draw.rectangle((ox + 9, oy + 10, ox + 23, oy + 22), fill=color)
            draw.line((ox + 12, oy + 13, ox + 20, oy + 13), fill=WHITE, width=1)
        elif choice == 6:
            draw.ellipse((ox + 7, oy + 7, ox + 25, oy + 25), fill=color, outline=INK)
            draw.arc((ox + 10, oy + 10, ox + 22, oy + 22), 200, 340, fill=INK, width=2)
        else:
            draw.polygon([(ox + 16, oy + 3), (ox + 27, oy + 16), (ox + 16, oy + 29), (ox + 5, oy + 16)], fill=color, outline=INK)
    else:
        color = [ROOT_GLOW, WHITE, GOLD, BLUE, TEAL, RED, GREEN, GLITCH][index % 8]
        choice = index % 8
        if choice == 0:
            draw.polygon([(ox + 16, oy + 4), (ox + 27, oy + 16), (ox + 16, oy + 28), (ox + 5, oy + 16)], outline=color)
        elif choice == 1:
            draw.rectangle((ox + 7, oy + 11, ox + 25, oy + 21), outline=color, width=2)
            draw.rectangle((ox + 11, oy + 7, ox + 21, oy + 25), outline=color, width=2)
        elif choice == 2:
            draw.line((ox + 7, oy + 16, ox + 25, oy + 16), fill=color, width=3)
            draw.polygon([(ox + 22, oy + 10), (ox + 29, oy + 16), (ox + 22, oy + 22)], fill=color)
        elif choice == 3:
            draw.rectangle((ox + 7, oy + 7, ox + 25, oy + 25), outline=color, width=2)
            draw.line((ox + 11, oy + 11, ox + 21, oy + 21), fill=color, width=2)
        elif choice == 4:
            draw.arc((ox + 5, oy + 5, ox + 27, oy + 27), 35, 325, fill=color, width=3)
        elif choice == 5:
            draw.polygon([(ox + 16, oy + 5), (ox + 25, oy + 25), (ox + 7, oy + 25)], outline=color)
        elif choice == 6:
            draw.rectangle((ox + 9, oy + 6, ox + 23, oy + 26), outline=color, width=2)
            draw.line((ox + 12, oy + 11, ox + 20, oy + 11), fill=color, width=2)
            draw.line((ox + 12, oy + 16, ox + 20, oy + 16), fill=color, width=2)
        else:
            draw.arc((ox + 7, oy + 7, ox + 25, oy + 25), 0, 360, fill=color, width=2)
            draw.line((ox + 16, oy + 5, ox + 16, oy + 27), fill=color, width=2)


def icon_sheet(path: Path, style: str, label: str) -> Image.Image:
    size = 32
    cols = 4
    rows = 4
    image = Image.new("RGBA", (cols * size, rows * size), CLEAR)
    draw = ImageDraw.Draw(image)
    for index in range(cols * rows):
        draw_icon(draw, (index % cols) * size, (index // cols) * size, index, style)
    image.save(path)
    row_manifest = [{"animation": f"{label}_row_{row}", "frames": cols} for row in range(rows)]
    add_record(path, "icon_sheet", image, (size, size), row_manifest, "AtlasTexture/Sprite2D", "P2", True, f"Original {label} pixel icons.")
    return image


def vfx_painter(effect: str, color: RGBA, rows: list[dict[str, object]]) -> FramePainter:
    def painter(image: Image.Image, row: int, frame: int, ox: int, oy: int) -> None:
        draw = ImageDraw.Draw(image)
        alpha = 255 - frame * 30
        cx = ox + 32
        cy = oy + 32
        fx = (color[0], color[1], color[2], max(70, alpha))
        if effect == "slash":
            draw.arc((ox + 7 - frame, oy + 8, ox + 58 + frame, oy + 58), -80 + frame * 6, 58 + frame * 7, fill=fx, width=3 + frame // 2)
            draw.arc((ox + 12, oy + 13, ox + 52, oy + 52), -72, 52, fill=WHITE, width=1)
        elif effect == "parry":
            radius = 7 + frame * 4
            draw.polygon([(cx, cy - radius), (cx + radius, cy), (cx, cy + radius), (cx - radius, cy)], outline=fx)
            draw.line((cx - radius, cy, cx + radius, cy), fill=WHITE, width=2)
        elif effect == "dash":
            for trail in range(4):
                x0 = ox + 6 + trail * 8 + frame * 2
                draw.rectangle((x0, cy - 7 + trail, x0 + 18 - trail * 2, cy + 5 + trail), fill=(color[0], color[1], color[2], max(35, alpha - trail * 42)))
        elif effect == "heal":
            radius = 5 + frame * 3
            draw.ellipse((cx - radius, cy - radius, cx + radius, cy + radius), outline=fx, width=2)
            draw.line((cx, cy - 13, cx, cy + 13), fill=WHITE, width=3)
            draw.line((cx - 13, cy, cx + 13, cy), fill=WHITE, width=3)
        else:
            for shard in range(7):
                angle = shard * math.pi * 2 / 7 + frame * 0.18
                x = cx + int(math.cos(angle) * (8 + frame * 3))
                y = cy + int(math.sin(angle) * (8 + frame * 2))
                draw.rectangle((x - 2, y - 5, x + 2, y + 5), fill=fx)
            draw.line((ox + 10 + frame * 2, oy + 52 - frame * 3, ox + 54 - frame, oy + 12 + frame), fill=fx, width=2)
    return painter


def contact_sheet(paths: Iterable[Path], output: Path, thumb: tuple[int, int], cols: int) -> None:
    images = [Image.open(path).convert("RGBA") for path in paths]
    tw, th = thumb
    rows = math.ceil(len(images) / cols)
    sheet = Image.new("RGBA", (cols * tw, rows * th), (15, 18, 28, 255))
    for index, image in enumerate(images):
        preview = image.copy()
        preview.thumbnail((tw - 12, th - 12), Image.Resampling.NEAREST)
        x = (index % cols) * tw + (tw - preview.width) // 2
        y = (index // cols) * th + (th - preview.height) // 2
        checker = Image.new("RGBA", preview.size, (28, 32, 46, 255))
        cdraw = ImageDraw.Draw(checker)
        for yy in range(0, preview.height, 8):
            for xx in range(0, preview.width, 8):
                if (xx // 8 + yy // 8) % 2:
                    cdraw.rectangle((xx, yy, xx + 7, yy + 7), fill=(40, 47, 66, 255))
        checker.alpha_composite(preview)
        sheet.alpha_composite(checker, (x, y))
    output.parent.mkdir(parents=True, exist_ok=True)
    sheet.save(output)


def write_manifest() -> None:
    manifest_path = MANIFEST_DIR / "phase10mc_asset_manifest.json"
    payload = {
        "phase": "10M-C",
        "generator": rel(Path(__file__)),
        "style": "original alpha-quality procedural pixel art",
        "assets": [record.__dict__ for record in ASSETS],
    }
    manifest_path.write_text(json.dumps(payload, indent=2), encoding="utf-8")

    md_path = MANIFEST_DIR / "phase10mc_asset_manifest.md"
    lines = [
        "# Phase 10M-C Procedural Asset Manifest",
        "",
        "All files are generated into `assets/generated/` and are not wired into gameplay scenes yet.",
        "",
        "| Path | Frame Size | Animation Rows | Frame Counts | Intended Godot Type | Priority |",
        "| --- | --- | --- | --- | --- | --- |",
    ]
    for record in ASSETS:
        animation_rows = ", ".join(str(row["animation"]) for row in record.rows)
        frame_counts = ", ".join(str(row["frames"]) for row in record.rows)
        lines.append(
            f"| `{record.path}` | `{record.frame_size[0]}x{record.frame_size[1]}` | {animation_rows} | {frame_counts} | {record.intended_godot_type} | {record.integration_priority} |"
        )
    md_path.write_text("\n".join(lines) + "\n", encoding="utf-8")


def validate_assets() -> None:
    errors: list[str] = []
    for record in ASSETS:
        path = ROOT / record.path
        if not path.exists() or path.stat().st_size == 0:
            errors.append(f"missing or zero-byte: {record.path}")
            continue
        with Image.open(path) as image:
            if image.size != (record.width, record.height):
                errors.append(f"dimension mismatch: {record.path}")
            if image.width % record.frame_size[0] or image.height % record.frame_size[1]:
                errors.append(f"frame grid mismatch: {record.path}")
            if record.alpha_required and "A" not in image.getbands():
                errors.append(f"alpha missing: {record.path}")
            if record.alpha_required and image.getchannel("A").getextrema()[0] > 0:
                errors.append(f"transparent pixels missing: {record.path}")
    validation_path = MANIFEST_DIR / "phase10mc_validation.json"
    validation_path.write_text(
        json.dumps(
            {
                "asset_count": len(ASSETS),
                "errors": errors,
                "status": "pass" if not errors else "fail",
            },
            indent=2,
        ),
        encoding="utf-8",
    )
    if errors:
        raise SystemExit("\n".join(errors))
    print(f"PHASE10MC_IMAGE_VALIDATION PASS assets={len(ASSETS)}")


def main() -> None:
    make_dirs()

    topdown_rows = [
        {"animation": "idle_front", "frames": 4},
        {"animation": "walk_front", "frames": 4},
        {"animation": "idle_back", "frames": 4},
        {"animation": "walk_back", "frames": 4},
        {"animation": "idle_left", "frames": 4},
        {"animation": "walk_left", "frames": 4},
        {"animation": "idle_right", "frames": 4},
        {"animation": "walk_right", "frames": 4},
    ]
    combat_rows = [
        {"animation": "idle", "frames": 4},
        {"animation": "run", "frames": 4},
        {"animation": "slash_1", "frames": 4},
        {"animation": "slash_2", "frames": 4},
        {"animation": "slash_3", "frames": 4},
        {"animation": "charged_slash", "frames": 4},
        {"animation": "upslash", "frames": 4},
        {"animation": "downslash", "frames": 4},
        {"animation": "dash", "frames": 4},
        {"animation": "cast", "frames": 4},
        {"animation": "hurt", "frames": 4},
        {"animation": "death", "frames": 4},
    ]
    knight_rows = [
        {"animation": "idle", "frames": 4},
        {"animation": "slash", "frames": 4},
        {"animation": "charge", "frames": 4},
        {"animation": "low_sweep", "frames": 4},
        {"animation": "shield_bash", "frames": 4},
        {"animation": "teleport_slash", "frames": 4},
        {"animation": "corrupt_rift", "frames": 4},
        {"animation": "shockwave", "frames": 4},
        {"animation": "phase_change", "frames": 4},
        {"animation": "defeat", "frames": 4},
    ]
    enemy_rows = [
        {"animation": "idle", "frames": 4},
        {"animation": "move", "frames": 4},
        {"animation": "attack", "frames": 4},
        {"animation": "hurt", "frames": 4},
        {"animation": "death", "frames": 4},
    ]
    npc_rows = [
        {"animation": "idle", "frames": 4},
        {"animation": "talk", "frames": 4},
        {"animation": "walk", "frames": 4},
    ]

    player_top = save_sheet(
        GENERATED / "sprites" / "player" / "kaelen_topdown_alpha_sheet.png",
        (32, 32),
        topdown_rows,
        draw_kaelen_topdown,
        "sprite_sheet",
        "AnimatedSprite2D/SpriteFrames",
        "P0",
        "Four-direction top-down Kaelen sheet.",
    )
    player_combat = save_sheet(
        GENERATED / "sprites" / "player" / "kaelen_combat_alpha_sheet.png",
        (64, 64),
        combat_rows,
        draw_kaelen_combat_factory(combat_rows),
        "sprite_sheet",
        "AnimatedSprite2D/SpriteFrames",
        "P0",
        "Side-view combat Kaelen sheet with placeholder attack timing rows.",
    )
    knight = save_sheet(
        GENERATED / "sprites" / "bosses" / "tutorial_knight_alpha_sheet.png",
        (64, 64),
        knight_rows,
        draw_knight_factory(knight_rows),
        "sprite_sheet",
        "AnimatedSprite2D/SpriteFrames",
        "P1",
        "Tutorial Knight boss sheet matching current pattern vocabulary.",
    )

    enemy_images = []
    enemy_specs = [
        ("fracture_slime", (98, 114, 225, 255), ROOT_GLOW),
        ("clock_mite", (128, 91, 54, 255), GOLD),
        ("memory_wisp", (59, 93, 145, 255), GLITCH),
    ]
    for name, primary, accent in enemy_specs:
        enemy_images.append(
            save_sheet(
                GENERATED / "sprites" / "enemies" / f"{name}_alpha_sheet.png",
                (48, 48),
                enemy_rows,
                enemy_painter(name, primary, accent, enemy_rows),
                "sprite_sheet",
                "AnimatedSprite2D/SpriteFrames",
                "P2",
                f"Generic {name.replace('_', ' ')} enemy sheet.",
            )
        )

    npc_images = []
    npc_specs = [
        ("elara", (83, 42, 111, 255), ROOT_GLOW, (210, 191, 231, 255)),
        ("seraphina", (61, 83, 124, 255), GOLD, (231, 208, 129, 255)),
        ("lyra", (37, 110, 94, 255), TEAL, (174, 231, 213, 255)),
        ("null_clerk", (60, 65, 84, 255), GLITCH, (196, 204, 224, 255)),
        ("assembly_runner", (118, 66, 42, 255), GREEN, (72, 53, 42, 255)),
    ]
    for name, primary, accent, hair in npc_specs:
        npc_images.append(
            save_sheet(
                GENERATED / "sprites" / "npcs" / f"{name}_alpha_sheet.png",
                (32, 32),
                npc_rows,
                npc_painter(name, primary, accent, hair, npc_rows),
                "sprite_sheet",
                "AnimatedSprite2D/SpriteFrames",
                "P2",
                f"NPC {name.replace('_', ' ')} idle/talk/walk sheet.",
            )
        )

    item_icons = icon_sheet(GENERATED / "icons" / "item_icons_alpha_sheet.png", "item", "item")
    ui_icons = icon_sheet(GENERATED / "icons" / "ui_icons_alpha_sheet.png", "ui", "ui")

    vfx_rows = [{"animation": "frames", "frames": 6}]
    vfx_images = []
    for name, color in [
        ("slash", ROOT_GLOW),
        ("parry", GOLD),
        ("dash", TEAL),
        ("heal", GREEN),
        ("corruption", GLITCH),
    ]:
        vfx_images.append(
            save_sheet(
                GENERATED / "vfx" / f"{name}_alpha_strip.png",
                (64, 64),
                vfx_rows,
                vfx_painter(name, color, vfx_rows),
                "vfx_strip",
                "AnimatedSprite2D/GPUParticles2D texture",
                "P2",
                f"{name} transparent VFX strip.",
            )
        )

    tile_sets = {
        "oakhaven": ([(34, 70, 46, 255), (63, 112, 65, 255), (134, 112, 75, 255), (189, 180, 115, 255)], ["grass", "path", "moss", "wood", "roof", "sign", "hedge", "flower"]),
        "ironhold": ([(46, 49, 58, 255), (82, 90, 104, 255), (132, 94, 54, 255), (216, 175, 81, 255)], ["brick", "metal", "rail", "vent", "crate", "forge", "pipe", "grate"]),
        "fractured_wastes": ([(46, 31, 60, 255), (92, 53, 109, 255), (145, 102, 72, 255), (235, 107, 221, 255)], ["dust", "crack", "shard", "glitch", "rune", "ridge", "pit", "obelisk"]),
        "forgotten_sectors": ([(31, 37, 53, 255), (63, 71, 87, 255), (118, 126, 146, 255), (191, 255, 238, 255)], ["null_floor", "wall", "dossier", "memory", "seal", "bench", "rune", "void"]),
        "mirror_city": ([(28, 48, 71, 255), (66, 105, 131, 255), (120, 194, 204, 255), (239, 250, 248, 255)], ["glass", "mirror", "plaza", "reflection", "frame", "fountain", "arch", "rune"]),
        "cathedral_server": ([(32, 31, 52, 255), (68, 59, 92, 255), (111, 145, 175, 255), (244, 201, 82, 255)], ["server", "aisle", "console", "altar", "firewall", "choir", "wire", "rune"]),
        "memory_ocean": ([(20, 42, 75, 255), (36, 91, 140, 255), (95, 184, 198, 255), (219, 242, 250, 255)], ["water", "tide", "memory", "island", "salvage", "foam", "log", "rune"]),
        "root_of_heaven": ([(23, 24, 38, 255), (68, 44, 90, 255), (130, 225, 211, 255), (251, 247, 218, 255)], ["root", "kernel", "wall", "circuit", "witness", "portal", "throne", "glitch"]),
    }
    tile_images = []
    for name, (palette, tiles) in tile_sets.items():
        tile_images.append(tile_sheet(name.replace("_", " ").title(), palette, tiles, GENERATED / "tilesets" / f"{name}_prototype_tileset.png"))

    contact_sheet(
        [
            GENERATED / "sprites" / "player" / "kaelen_topdown_alpha_sheet.png",
            GENERATED / "sprites" / "player" / "kaelen_combat_alpha_sheet.png",
            GENERATED / "sprites" / "bosses" / "tutorial_knight_alpha_sheet.png",
            *[GENERATED / "sprites" / "enemies" / f"{name}_alpha_sheet.png" for name, _, _ in enemy_specs],
            *[GENERATED / "sprites" / "npcs" / f"{name}_alpha_sheet.png" for name, *_ in npc_specs],
        ],
        PREVIEW_DIR / "phase10mc_sprite_contact_sheet.png",
        (256, 192),
        3,
    )
    contact_sheet(
        [
            GENERATED / "icons" / "item_icons_alpha_sheet.png",
            GENERATED / "icons" / "ui_icons_alpha_sheet.png",
            *[GENERATED / "vfx" / f"{name}_alpha_strip.png" for name in ["slash", "parry", "dash", "heal", "corruption"]],
            *[GENERATED / "tilesets" / f"{name}_prototype_tileset.png" for name in tile_sets],
        ],
        PREVIEW_DIR / "phase10mc_fx_tiles_contact_sheet.png",
        (224, 160),
        4,
    )

    write_manifest()
    validate_assets()
    print(f"PHASE10MC_GENERATION PASS assets={len(ASSETS)} previews=2")


if __name__ == "__main__":
    main()
