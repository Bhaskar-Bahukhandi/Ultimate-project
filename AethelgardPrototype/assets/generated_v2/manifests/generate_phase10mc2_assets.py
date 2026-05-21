from __future__ import annotations

import json
import math
import random
from dataclasses import asdict, dataclass
from pathlib import Path
from typing import Callable, Iterable

from PIL import Image, ImageDraw, ImageFont


ROOT = Path(__file__).resolve().parents[3]
V1 = ROOT / "assets" / "generated"
V2 = ROOT / "assets" / "generated_v2"
MANIFESTS = V2 / "manifests"
PREVIEWS = MANIFESTS / "previews"

RGBA = tuple[int, int, int, int]
Painter = Callable[[Image.Image, int, int, int, int], None]


@dataclass
class Record:
    path: str
    kind: str
    dimensions: tuple[int, int]
    frame_size: tuple[int, int]
    animation_rows: list[dict[str, object]]
    intended_godot_type: str
    integration_priority: str
    improvement_notes_over_v1: str
    alpha_required: bool
    tile_size: tuple[int, int] | None = None
    tiles: list[str] | None = None


ASSETS: list[Record] = []


CLEAR: RGBA = (0, 0, 0, 0)
INK: RGBA = (8, 10, 18, 255)
INK_SOFT: RGBA = (20, 24, 39, 255)
VOID: RGBA = (13, 17, 31, 255)
SHADOW: RGBA = (7, 12, 22, 150)
SKIN_DARK: RGBA = (110, 68, 63, 255)
SKIN: RGBA = (203, 145, 109, 255)
SKIN_LIT: RGBA = (242, 187, 138, 255)
HAIR: RGBA = (31, 24, 43, 255)
HAIR_LIT: RGBA = (76, 60, 92, 255)
COAT_DARK: RGBA = (17, 42, 70, 255)
COAT: RGBA = (31, 82, 129, 255)
COAT_LIT: RGBA = (57, 133, 177, 255)
CYAN: RGBA = (86, 245, 238, 255)
CYAN_FADE: RGBA = (86, 245, 238, 135)
MAGENTA: RGBA = (239, 73, 235, 255)
MAGENTA_FADE: RGBA = (239, 73, 235, 135)
GOLD: RGBA = (246, 198, 82, 255)
EMBER: RGBA = (238, 108, 63, 255)
RED: RGBA = (205, 54, 74, 255)
MOSS: RGBA = (68, 152, 92, 255)
GREEN_GLOW: RGBA = (114, 239, 141, 255)
STEEL_DARK: RGBA = (54, 67, 93, 255)
STEEL: RGBA = (124, 151, 181, 255)
STEEL_LIT: RGBA = (219, 235, 244, 255)
WHITE: RGBA = (247, 246, 231, 255)
GLASS: RGBA = (151, 233, 242, 255)


def rel(path: Path) -> str:
    return path.relative_to(ROOT).as_posix()


def ensure_dirs() -> None:
    for folder in [
        V2 / "sprites" / "player",
        V2 / "sprites" / "npcs",
        V2 / "sprites" / "enemies",
        V2 / "sprites" / "bosses",
        V2 / "icons",
        V2 / "vfx",
        V2 / "tilesets",
        MANIFESTS,
        PREVIEWS,
    ]:
        folder.mkdir(parents=True, exist_ok=True)


def rect(draw: ImageDraw.ImageDraw, box: tuple[int, int, int, int], color: RGBA) -> None:
    x0, y0, x1, y1 = box
    draw.rectangle((min(x0, x1), min(y0, y1), max(x0, x1), max(y0, y1)), fill=color)


def poly(draw: ImageDraw.ImageDraw, points: list[tuple[int, int]], fill: RGBA, outline: RGBA | None = None) -> None:
    draw.polygon(points, fill=fill)
    if outline is not None:
        draw.line(points + [points[0]], fill=outline, width=1)


def rim(draw: ImageDraw.ImageDraw, points: list[tuple[int, int]], color: RGBA, width: int = 1) -> None:
    draw.line(points, fill=color, width=width)


def outlined_poly(draw: ImageDraw.ImageDraw, outer: list[tuple[int, int]], inner: list[tuple[int, int]], fill: RGBA, highlight: list[tuple[int, int]] | None = None, highlight_color: RGBA = WHITE) -> None:
    poly(draw, outer, INK)
    poly(draw, inner, fill)
    if highlight:
        rim(draw, highlight, highlight_color)


def outlined_rect(draw: ImageDraw.ImageDraw, box: tuple[int, int, int, int], fill: RGBA, inner_hi: RGBA | None = None) -> None:
    x0, y0, x1, y1 = box
    rect(draw, box, INK)
    if x1 - x0 >= 3 and y1 - y0 >= 3:
        rect(draw, (x0 + 1, y0 + 1, x1 - 1, y1 - 1), fill)
    if inner_hi is not None:
        rim(draw, [(x0 + 2, y0 + 2), (x1 - 2, y0 + 2)], inner_hi)


def shadow(draw: ImageDraw.ImageDraw, x: int, y: int, rx: int, ry: int) -> None:
    draw.ellipse((x - rx, y - ry, x + rx, y + ry), fill=SHADOW)


def tint(color: RGBA, factor: float, alpha: int | None = None) -> RGBA:
    return (
        max(0, min(255, int(color[0] * factor))),
        max(0, min(255, int(color[1] * factor))),
        max(0, min(255, int(color[2] * factor))),
        color[3] if alpha is None else alpha,
    )


def record(path: Path, kind: str, image: Image.Image, frame_size: tuple[int, int], rows: list[dict[str, object]], godot_type: str, priority: str, note: str, alpha: bool, tile_size: tuple[int, int] | None = None, tiles: list[str] | None = None) -> None:
    ASSETS.append(
        Record(
            path=rel(path),
            kind=kind,
            dimensions=image.size,
            frame_size=frame_size,
            animation_rows=rows,
            intended_godot_type=godot_type,
            integration_priority=priority,
            improvement_notes_over_v1=note,
            alpha_required=alpha,
            tile_size=tile_size,
            tiles=tiles,
        )
    )


def save_sheet(path: Path, frame_size: tuple[int, int], rows: list[dict[str, object]], painter: Painter, kind: str, godot_type: str, priority: str, note: str, alpha: bool = True) -> Image.Image:
    fw, fh = frame_size
    cols = max(int(row["frames"]) for row in rows)
    image = Image.new("RGBA", (cols * fw, len(rows) * fh), CLEAR)
    for row_index, row in enumerate(rows):
        for frame_index in range(int(row["frames"])):
            painter(image, row_index, frame_index, frame_index * fw, row_index * fh)
    path.parent.mkdir(parents=True, exist_ok=True)
    image.save(path)
    record(path, kind, image, frame_size, rows, godot_type, priority, note, alpha)
    return image


def glitch_ticks(draw: ImageDraw.ImageDraw, x: int, y: int, seed: int, width: int, height: int, color: RGBA = MAGENTA) -> None:
    rng = random.Random(seed)
    for _ in range(4):
        px = x + rng.randrange(max(1, width))
        py = y + rng.randrange(max(1, height))
        rect(draw, (px, py, px + rng.randrange(1, 4), py + 1), color)


def kaelen_topdown(rows: list[dict[str, object]]) -> Painter:
    def paint(image: Image.Image, row: int, frame: int, ox: int, oy: int) -> None:
        draw = ImageDraw.Draw(image)
        direction = row // 2
        moving = row % 2 == 1
        cx = ox + 16
        bob = 1 if frame in (1, 2) else 0
        stride = [-2, -1, 2, 1][frame % 4] if moving else [0, 1, 0, -1][frame % 4]
        shadow(draw, cx, oy + 29, 10, 2)
        if direction in (0, 1):
            outer_coat = [(cx - 8, oy + 13 + bob), (cx - 11, oy + 25 + bob), (cx - 6, oy + 30), (cx, oy + 27), (cx + 6, oy + 30), (cx + 11, oy + 25 + bob), (cx + 8, oy + 13 + bob)]
            inner_coat = [(cx - 6, oy + 14 + bob), (cx - 8, oy + 24 + bob), (cx - 4, oy + 27), (cx, oy + 25), (cx + 4, oy + 27), (cx + 8, oy + 24 + bob), (cx + 6, oy + 14 + bob)]
            outlined_poly(draw, outer_coat, inner_coat, COAT, [(cx - 5, oy + 15 + bob), (cx, oy + 13 + bob), (cx + 4, oy + 15 + bob)], COAT_LIT)
            rect(draw, (cx - 7 - stride, oy + 23 + bob, cx - 3 - stride, oy + 30), INK)
            rect(draw, (cx + 3 + stride, oy + 23 + bob, cx + 7 + stride, oy + 30), INK)
            rect(draw, (cx - 6 - stride, oy + 24 + bob, cx - 4 - stride, oy + 28), CYAN)
            rect(draw, (cx + 4 + stride, oy + 24 + bob, cx + 6 + stride, oy + 28), CYAN)
            if direction == 0:
                outlined_poly(draw, [(cx - 7, oy + 5 + bob), (cx - 5, oy + 1 + bob), (cx + 4, oy + 1 + bob), (cx + 8, oy + 6 + bob), (cx + 6, oy + 14 + bob), (cx - 6, oy + 14 + bob)], [(cx - 5, oy + 6 + bob), (cx - 3, oy + 3 + bob), (cx + 3, oy + 3 + bob), (cx + 6, oy + 7 + bob), (cx + 4, oy + 13 + bob), (cx - 4, oy + 13 + bob)], SKIN, [(cx - 4, oy + 4 + bob), (cx + 3, oy + 4 + bob)], SKIN_LIT)
                poly(draw, [(cx - 7, oy + 5 + bob), (cx - 3, oy + 0 + bob), (cx + 4, oy + 1 + bob), (cx + 7, oy + 7 + bob), (cx + 1, oy + 5 + bob), (cx - 4, oy + 7 + bob)], HAIR)
                rect(draw, (cx - 2, oy + 15 + bob, cx + 2, oy + 24 + bob), CYAN)
                rect(draw, (cx + 9, oy + 12 + bob, cx + 11, oy + 25 + bob), STEEL_LIT)
            else:
                outlined_poly(draw, [(cx - 8, oy + 4 + bob), (cx - 4, oy + 0 + bob), (cx + 5, oy + 1 + bob), (cx + 8, oy + 7 + bob), (cx + 5, oy + 15 + bob), (cx - 6, oy + 14 + bob)], [(cx - 5, oy + 5 + bob), (cx - 3, oy + 2 + bob), (cx + 4, oy + 3 + bob), (cx + 5, oy + 8 + bob), (cx + 3, oy + 13 + bob), (cx - 4, oy + 12 + bob)], HAIR, [(cx - 4, oy + 3 + bob), (cx + 4, oy + 4 + bob)], HAIR_LIT)
                rect(draw, (cx - 6, oy + 15 + bob, cx + 6, oy + 17 + bob), CYAN)
                rect(draw, (cx - 11, oy + 12 + bob, cx - 9, oy + 25 + bob), STEEL_LIT)
        else:
            face_right = direction == 3
            sign = 1 if face_right else -1
            coat_outer = [(cx - 5 * sign, oy + 13 + bob), (cx - 9 * sign, oy + 25 + bob), (cx - 2 * sign, oy + 30), (cx + 7 * sign, oy + 27), (cx + 8 * sign, oy + 14 + bob)]
            coat_inner = [(cx - 3 * sign, oy + 14 + bob), (cx - 6 * sign, oy + 24 + bob), (cx - 1 * sign, oy + 27), (cx + 5 * sign, oy + 25 + bob), (cx + 6 * sign, oy + 15 + bob)]
            outlined_poly(draw, coat_outer, coat_inner, COAT, [(cx - 2 * sign, oy + 15 + bob), (cx + 5 * sign, oy + 15 + bob)], COAT_LIT)
            rect(draw, (cx - 5 * sign - stride, oy + 23 + bob, cx - 1 * sign - stride, oy + 30), INK)
            rect(draw, (cx + 3 * sign + stride, oy + 22 + bob, cx + 7 * sign + stride, oy + 29), INK)
            head_outer = [(cx - 6 * sign, oy + 4 + bob), (cx + 0 * sign, oy + 1 + bob), (cx + 7 * sign, oy + 5 + bob), (cx + 6 * sign, oy + 14 + bob), (cx - 5 * sign, oy + 14 + bob)]
            head_inner = [(cx - 4 * sign, oy + 5 + bob), (cx + 0 * sign, oy + 3 + bob), (cx + 5 * sign, oy + 6 + bob), (cx + 4 * sign, oy + 13 + bob), (cx - 3 * sign, oy + 12 + bob)]
            outlined_poly(draw, head_outer, head_inner, SKIN, [(cx - 2 * sign, oy + 4 + bob), (cx + 3 * sign, oy + 5 + bob)], SKIN_LIT)
            poly(draw, [(cx - 6 * sign, oy + 4 + bob), (cx - 1 * sign, oy + 0 + bob), (cx + 5 * sign, oy + 4 + bob), (cx + 2 * sign, oy + 7 + bob), (cx - 5 * sign, oy + 7 + bob)], HAIR)
            rect(draw, (cx + 7 * sign, oy + 12 + bob, cx + 10 * sign, oy + 25 + bob), STEEL_LIT)
            rect(draw, (cx - 1 * sign, oy + 15 + bob, cx + 1 * sign, oy + 24 + bob), CYAN)
        glitch_ticks(draw, ox + 3, oy + 4, row * 17 + frame, 25, 22, MAGENTA_FADE)
    return paint


def sword(draw: ImageDraw.ImageDraw, hilt: tuple[int, int], tip: tuple[int, int], glow: RGBA = CYAN, width: int = 5) -> None:
    draw.line((hilt[0], hilt[1], tip[0], tip[1]), fill=INK, width=width + 2)
    draw.line((hilt[0], hilt[1], tip[0], tip[1]), fill=STEEL_LIT, width=max(2, width - 2))
    draw.line((hilt[0], hilt[1], tip[0], tip[1]), fill=glow, width=1)
    draw.line((hilt[0] - 4, hilt[1] - 2, hilt[0] + 4, hilt[1] + 2), fill=GOLD, width=2)


def kaelen_combat(rows: list[dict[str, object]]) -> Painter:
    def paint(image: Image.Image, row: int, frame: int, ox: int, oy: int) -> None:
        draw = ImageDraw.Draw(image)
        name = str(rows[row]["animation"])
        cx = ox + 28
        ground = oy + 59
        run_step = [-5, -2, 4, 2][frame % 4] if name == "run" else 0
        bob = 2 if name == "run" and frame in (1, 2) else (1 if name == "idle" and frame in (1, 2) else 0)
        lean = {"dash": 8, "hurt": -4, "slash_1": frame * 2, "slash_2": frame, "slash_3": frame * 3, "charged_slash": -4 + frame * 3}.get(name, 0)
        if name == "death":
            shadow(draw, ox + 33, ground + 1, 22, 4)
            fall = min(12, frame * 4)
            outlined_poly(draw, [(ox + 12, oy + 44 + fall), (ox + 40, oy + 40 + fall), (ox + 53, oy + 50 + fall), (ox + 46, oy + 58 + fall), (ox + 15, oy + 56 + fall)], [(ox + 15, oy + 46 + fall), (ox + 39, oy + 43 + fall), (ox + 48, oy + 50 + fall), (ox + 43, oy + 55 + fall), (ox + 18, oy + 53 + fall)], COAT)
            outlined_poly(draw, [(ox + 43, oy + 34 + fall), (ox + 58, oy + 39 + fall), (ox + 56, oy + 51 + fall), (ox + 43, oy + 48 + fall)], [(ox + 46, oy + 37 + fall), (ox + 55, oy + 40 + fall), (ox + 53, oy + 47 + fall), (ox + 45, oy + 45 + fall)], SKIN)
            sword(draw, (ox + 14, oy + 48 + fall), (ox + 4, oy + 61), MAGENTA, 3)
            return
        shadow(draw, ox + 33, ground + 1, 18 if name != "dash" else 25, 3)
        body_x = cx + lean
        back_leg = [(body_x - 10 - run_step, ground - 21), (body_x - 15 - run_step, ground - 3), (body_x - 7 - run_step, ground), (body_x - 4, ground - 19)]
        front_leg = [(body_x + 4 + run_step, ground - 20), (body_x + 8 + run_step, ground - 1), (body_x + 16 + run_step, ground - 2), (body_x + 10, ground - 22)]
        outlined_poly(draw, back_leg, [(body_x - 9 - run_step, ground - 18), (body_x - 12 - run_step, ground - 4), (body_x - 8 - run_step, ground - 3), (body_x - 5, ground - 18)], STEEL_DARK, [(body_x - 10 - run_step, ground - 6), (body_x - 7 - run_step, ground - 4)], CYAN)
        outlined_poly(draw, front_leg, [(body_x + 5 + run_step, ground - 18), (body_x + 10 + run_step, ground - 4), (body_x + 14 + run_step, ground - 4), (body_x + 9, ground - 19)], STEEL_DARK, [(body_x + 8 + run_step, ground - 5), (body_x + 14 + run_step, ground - 5)], CYAN)
        coat_outer = [(body_x - 16, ground - 45 + bob), (body_x + 5, ground - 50 + bob), (body_x + 18, ground - 37 + bob), (body_x + 12, ground - 18), (body_x - 7, ground - 15), (body_x - 21, ground - 24)]
        coat_inner = [(body_x - 13, ground - 43 + bob), (body_x + 4, ground - 46 + bob), (body_x + 14, ground - 36 + bob), (body_x + 9, ground - 20), (body_x - 6, ground - 18), (body_x - 17, ground - 25)]
        outlined_poly(draw, coat_outer, coat_inner, COAT, [(body_x - 11, ground - 42 + bob), (body_x + 3, ground - 45 + bob), (body_x + 12, ground - 35 + bob)], COAT_LIT)
        rect(draw, (body_x - 3, ground - 45 + bob, body_x + 1, ground - 20), CYAN)
        poly(draw, [(body_x - 21, ground - 31), (body_x - 31, ground - 16 + frame % 2), (body_x - 16, ground - 20)], tint(COAT_DARK, 0.8), INK)
        head_outer = [(body_x - 10, ground - 60 + bob), (body_x + 4, ground - 63 + bob), (body_x + 17, ground - 55 + bob), (body_x + 14, ground - 41 + bob), (body_x - 7, ground - 43 + bob)]
        head_inner = [(body_x - 7, ground - 57 + bob), (body_x + 3, ground - 60 + bob), (body_x + 14, ground - 53 + bob), (body_x + 11, ground - 44 + bob), (body_x - 5, ground - 46 + bob)]
        outlined_poly(draw, head_outer, head_inner, SKIN, [(body_x - 5, ground - 58 + bob), (body_x + 6, ground - 58 + bob)], SKIN_LIT)
        poly(draw, [(body_x - 10, ground - 59 + bob), (body_x + 1, ground - 64 + bob), (body_x + 15, ground - 57 + bob), (body_x + 6, ground - 52 + bob), (body_x - 8, ground - 53 + bob)], HAIR)
        rim(draw, [(body_x - 4, ground - 60 + bob), (body_x + 4, ground - 62 + bob), (body_x + 12, ground - 56 + bob)], HAIR_LIT)
        shoulder = (body_x + 12, ground - 40 + bob)
        hilt = (body_x + 18, ground - 35 + bob)
        tip = (body_x + 46, ground - 42 + bob)
        if name == "slash_1":
            tip = [(body_x + 33, ground - 60), (body_x + 49, ground - 49), (body_x + 53, ground - 26), (body_x + 39, ground - 13)][frame]
        elif name == "slash_2":
            tip = [(body_x + 48, ground - 20), (body_x + 49, ground - 35), (body_x + 42, ground - 56), (body_x + 28, ground - 62)][frame]
        elif name == "slash_3":
            tip = [(body_x + 17, ground - 62), (body_x + 39, ground - 58), (body_x + 56, ground - 32), (body_x + 50, ground - 8)][frame]
        elif name == "charged_slash":
            tip = [(body_x - 3, ground - 57), (body_x + 21, ground - 66), (body_x + 60, ground - 40), (body_x + 54, ground - 10)][frame]
        elif name == "upslash":
            tip = [(body_x + 39, ground - 28), (body_x + 47, ground - 54), (body_x + 31, ground - 70), (body_x + 21, ground - 61)][frame]
        elif name == "downslash":
            tip = [(body_x + 36, ground - 64), (body_x + 52, ground - 40), (body_x + 39, ground - 3), (body_x + 20, ground - 8)][frame]
        elif name == "dash":
            tip = (body_x + 44, ground - 30)
            for trail in range(4):
                poly(draw, [(ox + 3 + trail * 7, ground - 44 + trail), (ox + 24 + trail * 6, ground - 39 + trail), (ox + 16 + trail * 6, ground - 26 + trail)], (CYAN[0], CYAN[1], CYAN[2], 110 - trail * 20))
        elif name == "cast":
            tip = (body_x + 36, ground - 48)
            radius = 5 + frame * 3
            draw.ellipse((body_x - 37 - radius, ground - 38 - radius, body_x - 37 + radius, ground - 38 + radius), outline=CYAN, width=2)
            draw.polygon([(body_x - 37, ground - 47 - frame), (body_x - 29 + frame, ground - 38), (body_x - 37, ground - 29 + frame), (body_x - 45 - frame, ground - 38)], outline=WHITE)
        elif name == "hurt":
            tip = (body_x + 26, ground - 49)
            rim(draw, [(body_x - 18, ground - 57), (body_x + 21, ground - 23)], RED, 3)
        draw.line((shoulder[0], shoulder[1], hilt[0], hilt[1]), fill=INK, width=6)
        draw.line((shoulder[0], shoulder[1], hilt[0], hilt[1]), fill=COAT_LIT, width=3)
        sword(draw, hilt, tip, CYAN if name != "charged_slash" else GOLD, 5)
        if "slash" in name and frame in (1, 2):
            arc_box = (body_x + 4, ground - 70, body_x + 68, ground - 2)
            draw.arc(arc_box, -84 + frame * 5, 74 + frame * 12, fill=CYAN, width=4)
            draw.arc((arc_box[0] + 4, arc_box[1] + 4, arc_box[2] - 4, arc_box[3] - 4), -80, 66, fill=WHITE, width=1)
        glitch_ticks(draw, ox + 4, oy + 6, row * 31 + frame, 54, 44, MAGENTA_FADE)
    return paint


def knight(rows: list[dict[str, object]]) -> Painter:
    def paint(image: Image.Image, row: int, frame: int, ox: int, oy: int) -> None:
        draw = ImageDraw.Draw(image)
        name = str(rows[row]["animation"])
        cx = ox + 39
        ground = oy + 92
        phase = row in (5, 6, 8)
        shift = frame * 3 if name in {"charge", "shield_bash"} else 0
        if name == "defeat":
            shadow(draw, ox + 34, ground, 25, 4)
            fall = frame * 4
            outlined_poly(draw, [(ox + 7, oy + 41 + fall), (ox + 48, oy + 36 + fall), (ox + 61, oy + 50 + fall), (ox + 51, oy + 59 + fall), (ox + 12, oy + 56 + fall)], [(ox + 12, oy + 43 + fall), (ox + 46, oy + 40 + fall), (ox + 56, oy + 50 + fall), (ox + 48, oy + 55 + fall), (ox + 15, oy + 52 + fall)], STEEL)
            poly(draw, [(ox + 48, oy + 31 + fall), (ox + 62, oy + 34 + fall), (ox + 59, oy + 49 + fall)], RED, INK)
            return
        shadow(draw, cx + shift, ground + 1, 25, 4)
        if name == "teleport_slash":
            for ghost in range(3):
                alpha = 55 + ghost * 18
                poly(draw, [(ox + 4 + ghost * 7, oy + 16), (ox + 16 + ghost * 7, oy + 5), (ox + 28 + ghost * 7, oy + 22), (ox + 24 + ghost * 7, oy + 51), (ox + 8 + ghost * 7, oy + 46)], (MAGENTA[0], MAGENTA[1], MAGENTA[2], alpha))
        leg_l = [(cx - 18 + shift, ground - 27), (cx - 24 + shift, ground - 2), (cx - 12 + shift, ground), (cx - 7 + shift, ground - 24)]
        leg_r = [(cx + 6 + shift, ground - 26), (cx + 10 + shift, ground), (cx + 23 + shift, ground - 2), (cx + 16 + shift, ground - 28)]
        outlined_poly(draw, leg_l, [(cx - 16 + shift, ground - 25), (cx - 20 + shift, ground - 5), (cx - 13 + shift, ground - 3), (cx - 9 + shift, ground - 22)], STEEL_DARK, [(cx - 18 + shift, ground - 8), (cx - 12 + shift, ground - 6)], STEEL_LIT)
        outlined_poly(draw, leg_r, [(cx + 8 + shift, ground - 23), (cx + 12 + shift, ground - 4), (cx + 20 + shift, ground - 5), (cx + 14 + shift, ground - 25)], STEEL_DARK, [(cx + 12 + shift, ground - 7), (cx + 19 + shift, ground - 8)], STEEL_LIT)
        torso_outer = [(cx - 25 + shift, ground - 50), (cx - 7 + shift, ground - 61), (cx + 20 + shift, ground - 54), (cx + 28 + shift, ground - 34), (cx + 18 + shift, ground - 20), (cx - 18 + shift, ground - 20), (cx - 30 + shift, ground - 34)]
        torso_inner = [(cx - 21 + shift, ground - 48), (cx - 6 + shift, ground - 57), (cx + 17 + shift, ground - 51), (cx + 23 + shift, ground - 34), (cx + 15 + shift, ground - 24), (cx - 15 + shift, ground - 24), (cx - 25 + shift, ground - 35)]
        outlined_poly(draw, torso_outer, torso_inner, STEEL, [(cx - 18 + shift, ground - 48), (cx - 4 + shift, ground - 55), (cx + 15 + shift, ground - 49)], STEEL_LIT)
        rect(draw, (cx - 17 + shift, ground - 39, cx + 18 + shift, ground - 35), tint(KNIGHT_GLOW := EMBER, 0.9))
        helm_outer = [(cx - 18 + shift, ground - 78), (cx + 0 + shift, ground - 86), (cx + 19 + shift, ground - 75), (cx + 15 + shift, ground - 55), (cx - 14 + shift, ground - 57)]
        helm_inner = [(cx - 14 + shift, ground - 75), (cx + 0 + shift, ground - 81), (cx + 15 + shift, ground - 72), (cx + 11 + shift, ground - 59), (cx - 11 + shift, ground - 61)]
        outlined_poly(draw, helm_outer, helm_inner, STEEL_LIT, [(cx - 11 + shift, ground - 73), (cx + shift, ground - 78), (cx + 12 + shift, ground - 70)], WHITE)
        rect(draw, (cx - 11 + shift, ground - 69, cx + 11 + shift, ground - 66), INK)
        rect(draw, (cx - 6 + shift, ground - 69, cx + 7 + shift, ground - 67), EMBER)
        poly(draw, [(cx - 2 + shift, ground - 86), (cx + 18 + shift, ground - 92), (cx + 25 + shift, ground - 84), (cx + 8 + shift, ground - 78)], RED, INK)
        shield_left = cx - 37 + shift - (frame * 2 if name == "shield_bash" else 0)
        shield_outer = [(shield_left, ground - 54), (shield_left + 25, ground - 61), (shield_left + 35, ground - 35), (shield_left + 18, ground - 9), (shield_left - 5, ground - 25)]
        shield_inner = [(shield_left + 4, ground - 51), (shield_left + 23, ground - 56), (shield_left + 30, ground - 35), (shield_left + 16, ground - 14), (shield_left, ground - 26)]
        outlined_poly(draw, shield_outer, shield_inner, STEEL_DARK, [(shield_left + 9, ground - 49), (shield_left + 22, ground - 52), (shield_left + 26, ground - 36)], CYAN)
        rect(draw, (shield_left + 13, ground - 45, shield_left + 18, ground - 22), EMBER)
        hilt = (cx + 23 + shift, ground - 43)
        tip = (cx + 52 + shift, ground - 51)
        if name == "slash":
            tip = [(cx + 39, ground - 80), (cx + 60, ground - 63), (cx + 61, ground - 28), (cx + 42, ground - 7)][frame]
        elif name == "low_sweep":
            tip = [(cx + 47, ground - 35), (cx + 63, ground - 19), (cx + 68, ground - 9), (cx + 45, ground - 5)][frame]
        elif name == "shield_bash":
            tip = (cx + 44 + shift, ground - 50)
        elif name == "shockwave":
            tip = [(cx + 42, ground - 60), (cx + 52, ground - 25), (cx + 38, ground + 1), (cx + 29, ground - 16)][frame]
        elif name == "corrupt_rift":
            tip = (cx + 40, ground - 44)
            for crack in range(4):
                x = ox + 7 + crack * 13 + frame * 2
                rim(draw, [(x, ground - 4), (x + 5, ground - 18 - crack), (x + 9, ground - 3)], MAGENTA, 2)
        elif name == "teleport_slash":
            tip = [(cx + 33, ground - 78), (cx + 61, ground - 48), (cx + 58, ground - 11), (cx + 37, ground - 5)][frame]
        sword(draw, hilt, tip, GOLD if not phase else MAGENTA, 6)
        if name in {"slash", "teleport_slash", "low_sweep"} and frame in (1, 2):
            draw.arc((cx + 1 + shift, ground - 86, cx + 80 + shift, ground + 5), -82, 72, fill=GOLD if not phase else MAGENTA, width=5)
            draw.arc((cx + 6 + shift, ground - 81, cx + 74 + shift, ground - 1), -78, 66, fill=WHITE, width=1)
        if name == "phase_change":
            draw.ellipse((cx - 35, ground - 90, cx + 45, ground + 0), outline=MAGENTA, width=3)
            draw.line((cx - 29, ground - 47, cx + 37, ground - 47), fill=CYAN, width=2)
        glitch_ticks(draw, ox + 4, oy + 4, 700 + row * 43 + frame, 55, 50, MAGENTA_FADE if phase else CYAN_FADE)
    return paint


def enemy(rows: list[dict[str, object]], kind: str) -> Painter:
    def paint(image: Image.Image, row: int, frame: int, ox: int, oy: int) -> None:
        draw = ImageDraw.Draw(image)
        name = str(rows[row]["animation"])
        cx, ground = ox + 24, oy + 45
        shadow(draw, cx, ground + 1, 14, 3)
        if kind == "fracture_slime":
            lunge = 6 if name == "attack" and frame >= 1 else 0
            outer = [(cx - 19, ground), (cx - 17, ground - 16), (cx - 9, ground - 31 - frame % 2), (cx - 1, ground - 24), (cx + 8 + lunge, ground - 36), (cx + 19 + lunge, ground - 16), (cx + 18 + lunge, ground)]
            inner = [(cx - 15, ground - 2), (cx - 13, ground - 15), (cx - 7, ground - 25), (cx, ground - 19), (cx + 7 + lunge, ground - 30), (cx + 15 + lunge, ground - 14), (cx + 14 + lunge, ground - 2)]
            outlined_poly(draw, outer, inner, (54, 81, 196, 255), [(cx - 11, ground - 14), (cx - 6, ground - 23), (cx + 5 + lunge, ground - 27)], CYAN)
            poly(draw, [(cx - 6, ground - 30), (cx - 2, ground - 39), (cx + 2, ground - 27)], MAGENTA, INK)
            rect(draw, (cx - 9, ground - 18, cx - 3, ground - 13), WHITE)
            rect(draw, (cx + 5 + lunge, ground - 20, cx + 10 + lunge, ground - 15), WHITE)
            rect(draw, (cx - 7, ground - 17, cx - 5, ground - 14), INK)
            rect(draw, (cx + 7 + lunge, ground - 19, cx + 9 + lunge, ground - 16), INK)
        elif kind == "clock_mite":
            stride = [-4, -1, 4, 1][frame % 4] if name == "move" else 0
            for leg, sign in [(-16, -1), (-7, 1), (7, -1), (16, 1)]:
                rim(draw, [(cx + leg // 2, ground - 12), (cx + leg + stride, ground - 1 - sign * frame % 2)], INK, 3)
                rim(draw, [(cx + leg // 2, ground - 13), (cx + leg + stride, ground - 3 - sign * frame % 2)], GOLD, 1)
            outer = [(cx - 18, ground - 29), (cx + 2, ground - 38), (cx + 20, ground - 27), (cx + 16, ground - 10), (cx - 15, ground - 10)]
            inner = [(cx - 14, ground - 27), (cx + 1, ground - 33), (cx + 16, ground - 25), (cx + 13, ground - 13), (cx - 12, ground - 13)]
            outlined_poly(draw, outer, inner, (92, 60, 42, 255), [(cx - 10, ground - 27), (cx + 3, ground - 31), (cx + 13, ground - 25)], GOLD)
            draw.ellipse((cx - 7, ground - 27, cx + 8, ground - 13), outline=STEEL_LIT, width=2)
            rim(draw, [(cx, ground - 25), (cx + 5, ground - 19), (cx, ground - 15)], CYAN, 1)
            if name == "attack":
                pincer = cx + 22 + frame * 2
                poly(draw, [(cx + 15, ground - 24), (pincer, ground - 35), (pincer - 2, ground - 23)], GOLD, INK)
                poly(draw, [(cx + 14, ground - 18), (pincer, ground - 7), (pincer - 4, ground - 20)], GOLD, INK)
        else:
            drift = int(math.sin(frame * 1.2) * 3)
            outer = [(cx, ground - 43 + drift), (cx + 18, ground - 31), (cx + 16, ground - 9), (cx + 5, ground - 2), (cx - 1, ground - 11), (cx - 8, ground - 2), (cx - 18, ground - 12), (cx - 17, ground - 31)]
            inner = [(cx, ground - 38 + drift), (cx + 14, ground - 29), (cx + 12, ground - 12), (cx + 4, ground - 7), (cx, ground - 16), (cx - 7, ground - 7), (cx - 13, ground - 14), (cx - 13, ground - 29)]
            outlined_poly(draw, outer, inner, (40, 76, 129, 255), [(cx - 10, ground - 29), (cx, ground - 35 + drift), (cx + 11, ground - 28)], GLASS)
            rect(draw, (cx - 8, ground - 25, cx - 3, ground - 19), MAGENTA)
            rect(draw, (cx + 3, ground - 25, cx + 8, ground - 19), CYAN)
            if name == "attack":
                draw.arc((ox + 0, oy + 2, ox + 47, oy + 47), 215, 332, fill=MAGENTA, width=4)
                draw.arc((ox + 5, oy + 7, ox + 42, oy + 42), 220, 325, fill=WHITE, width=1)
        if name == "hurt":
            rim(draw, [(ox + 8, oy + 6), (ox + 40, oy + 42)], WHITE, 2)
            rim(draw, [(ox + 36, oy + 7), (ox + 13, oy + 39)], RED, 2)
        elif name == "death":
            for shard in range(5):
                x = ox + 8 + shard * 7 + frame
                y = ground - 15 + (shard % 2) * 5 + frame * 2
                poly(draw, [(x, y - 5), (x + 4, y), (x, y + 5), (x - 3, y)], (CYAN[0], CYAN[1], CYAN[2], max(55, 210 - frame * 35)))
        glitch_ticks(draw, ox + 5, oy + 5, 1100 + row * 19 + frame, 36, 34, MAGENTA_FADE)
    return paint


def npc(rows: list[dict[str, object]], kind: str, palette: tuple[RGBA, RGBA, RGBA]) -> Painter:
    cloth, accent, hair = palette
    def paint(image: Image.Image, row: int, frame: int, ox: int, oy: int) -> None:
        draw = ImageDraw.Draw(image)
        name = str(rows[row]["animation"])
        cx, ground = ox + 16, oy + 30
        bob = frame % 2 if name == "walk" else (1 if name == "talk" and frame in (1, 2) else 0)
        stride = [-2, 1, 2, -1][frame % 4] if name == "walk" else 0
        shadow(draw, cx, ground, 10, 2)
        if kind == "elara":
            outlined_poly(draw, [(cx - 9, oy + 9 + bob), (cx, oy + 2 + bob), (cx + 10, oy + 10 + bob), (cx + 12, oy + 29), (cx - 12, oy + 29)], [(cx - 7, oy + 11 + bob), (cx, oy + 5 + bob), (cx + 8, oy + 11 + bob), (cx + 8, oy + 27), (cx - 9, oy + 27)], cloth, [(cx - 5, oy + 12), (cx + 5, oy + 9)], accent)
            poly(draw, [(cx - 7, oy + 9 + bob), (cx, oy + 2 + bob), (cx + 7, oy + 9 + bob), (cx + 4, oy + 15 + bob), (cx - 4, oy + 15 + bob)], hair, INK)
            rect(draw, (cx - 3, oy + 10 + bob, cx + 3, oy + 16 + bob), SKIN)
            rim(draw, [(cx - 12, oy + 13), (cx - 15, oy + 28)], accent, 2)
            if name == "talk":
                draw.ellipse((cx - 18, oy + 5 + frame, cx - 11, oy + 12 + frame), outline=CYAN, width=1)
        elif kind == "seraphina":
            outlined_poly(draw, [(cx - 10, oy + 12 + bob), (cx - 7, oy + 5 + bob), (cx + 6, oy + 4 + bob), (cx + 11, oy + 13 + bob), (cx + 8, oy + 29), (cx - 8, oy + 29)], [(cx - 7, oy + 13 + bob), (cx - 5, oy + 7 + bob), (cx + 5, oy + 6 + bob), (cx + 8, oy + 14 + bob), (cx + 6, oy + 27), (cx - 6, oy + 27)], cloth, [(cx - 5, oy + 8), (cx + 5, oy + 7)], STEEL_LIT)
            outlined_poly(draw, [(cx - 6, oy + 2 + bob), (cx + 5, oy + 2 + bob), (cx + 8, oy + 12 + bob), (cx - 6, oy + 13 + bob)], [(cx - 4, oy + 4 + bob), (cx + 4, oy + 4 + bob), (cx + 5, oy + 11 + bob), (cx - 4, oy + 11 + bob)], SKIN, [(cx - 3, oy + 4 + bob), (cx + 3, oy + 4 + bob)], SKIN_LIT)
            poly(draw, [(cx - 7, oy + 2 + bob), (cx + 4, oy + 1 + bob), (cx + 8, oy + 6 + bob), (cx + 1, oy + 5 + bob)], hair, INK)
            outlined_rect(draw, (cx + 7, oy + 14, cx + 13, oy + 22), accent, GOLD)
        elif kind == "lyra":
            outlined_poly(draw, [(cx - 11, oy + 14 + bob), (cx - 4, oy + 6 + bob), (cx + 8, oy + 8 + bob), (cx + 12, oy + 19 + bob), (cx + 5, oy + 29), (cx - 8, oy + 27)], [(cx - 8, oy + 14 + bob), (cx - 3, oy + 8 + bob), (cx + 6, oy + 10 + bob), (cx + 9, oy + 19 + bob), (cx + 4, oy + 26), (cx - 6, oy + 25)], cloth, [(cx - 6, oy + 14), (cx + 6, oy + 12)], accent)
            outlined_poly(draw, [(cx - 5, oy + 2 + bob), (cx + 5, oy + 3 + bob), (cx + 7, oy + 12 + bob), (cx - 6, oy + 12 + bob)], [(cx - 3, oy + 4 + bob), (cx + 4, oy + 5 + bob), (cx + 4, oy + 11 + bob), (cx - 4, oy + 10 + bob)], SKIN)
            poly(draw, [(cx - 6, oy + 3 + bob), (cx + 5, oy + 2 + bob), (cx + 10, oy + 8 + bob), (cx + 7, oy + 15 + bob)], hair, INK)
            rim(draw, [(cx - 10, oy + 16), (cx + 12, oy + 8)], accent, 2)
        elif kind == "null_clerk":
            outlined_poly(draw, [(cx - 9, oy + 6 + bob), (cx + 8, oy + 6 + bob), (cx + 13, oy + 29), (cx - 13, oy + 29)], [(cx - 6, oy + 9 + bob), (cx + 6, oy + 9 + bob), (cx + 9, oy + 27), (cx - 9, oy + 27)], cloth, [(cx - 4, oy + 10), (cx + 4, oy + 10)], accent)
            draw.rectangle((cx - 5, oy + 2 + bob, cx + 5, oy + 10 + bob), fill=VOID, outline=accent)
            draw.arc((cx - 11, oy - 2, cx + 11, oy + 19), 205, 335, fill=CYAN, width=1)
            rim(draw, [(cx - 10, oy + 13), (cx - 10, oy + 27)], accent, 2)
        else:
            outlined_poly(draw, [(cx - 11, oy + 11 + bob), (cx - 4, oy + 5 + bob), (cx + 7, oy + 6 + bob), (cx + 12, oy + 16 + bob), (cx + 6, oy + 29), (cx - 9, oy + 27)], [(cx - 8, oy + 12 + bob), (cx - 3, oy + 7 + bob), (cx + 5, oy + 8 + bob), (cx + 9, oy + 16 + bob), (cx + 5, oy + 26), (cx - 6, oy + 25)], cloth, [(cx - 7, oy + 13), (cx + 6, oy + 12)], accent)
            outlined_poly(draw, [(cx - 5, oy + 2 + bob), (cx + 5, oy + 3 + bob), (cx + 7, oy + 12 + bob), (cx - 6, oy + 11 + bob)], [(cx - 3, oy + 4 + bob), (cx + 4, oy + 5 + bob), (cx + 4, oy + 10 + bob), (cx - 4, oy + 10 + bob)], SKIN)
            poly(draw, [(cx - 6, oy + 3 + bob), (cx + 4, oy + 2 + bob), (cx + 7, oy + 7 + bob), (cx - 3, oy + 7 + bob)], hair, INK)
            outlined_rect(draw, (cx - 15, oy + 13, cx - 9, oy + 23), accent, GOLD)
        rect(draw, (cx - 7 - stride, ground - 6, cx - 3 - stride, ground), INK)
        rect(draw, (cx + 3 + stride, ground - 6, cx + 7 + stride, ground), INK)
        if name == "talk":
            rim(draw, [(cx + 9, oy + 9 + frame), (cx + 13, oy + 7 + frame)], WHITE, 1)
            rim(draw, [(cx + 11, oy + 14 + frame), (cx + 15, oy + 13 + frame)], accent, 1)
        glitch_ticks(draw, ox + 2, oy + 3, 1500 + row * 17 + frame + len(kind), 27, 22, MAGENTA_FADE)
    return paint


def icon_art(draw: ImageDraw.ImageDraw, ox: int, oy: int, index: int, ui: bool) -> None:
    bg = (16, 21, 37, 220)
    draw.rounded_rectangle((ox + 2, oy + 2, ox + 29, oy + 29), radius=4, fill=bg, outline=(73, 94, 128, 255))
    draw.line((ox + 5, oy + 5, ox + 25, oy + 5), fill=(130, 161, 199, 180), width=1)
    if not ui:
        variant = index % 8
        if variant == 0:
            outlined_poly(draw, [(ox + 12, oy + 4), (ox + 20, oy + 4), (ox + 23, oy + 11), (ox + 21, oy + 25), (ox + 11, oy + 25), (ox + 9, oy + 11)], [(ox + 13, oy + 7), (ox + 19, oy + 7), (ox + 20, oy + 12), (ox + 19, oy + 22), (ox + 13, oy + 22), (ox + 12, oy + 12)], RED, [(ox + 13, oy + 8), (ox + 19, oy + 8)], WHITE)
            rect(draw, (ox + 13, oy + 2, ox + 19, oy + 5), GOLD)
        elif variant == 1:
            outlined_poly(draw, [(ox + 16, oy + 3), (ox + 27, oy + 15), (ox + 18, oy + 29), (ox + 5, oy + 18)], [(ox + 16, oy + 7), (ox + 23, oy + 15), (ox + 17, oy + 25), (ox + 9, oy + 18)], CYAN, [(ox + 15, oy + 8), (ox + 21, oy + 15)], WHITE)
        elif variant == 2:
            outlined_poly(draw, [(ox + 16, oy + 3), (ox + 25, oy + 10), (ox + 23, oy + 23), (ox + 16, oy + 29), (ox + 7, oy + 22), (ox + 7, oy + 10)], [(ox + 16, oy + 7), (ox + 22, oy + 12), (ox + 20, oy + 21), (ox + 16, oy + 25), (ox + 10, oy + 20), (ox + 10, oy + 12)], GREEN_GLOW, [(ox + 12, oy + 11), (ox + 20, oy + 10)], WHITE)
        elif variant == 3:
            sword(draw, (ox + 9, oy + 23), (ox + 25, oy + 5), CYAN, 3)
        elif variant == 4:
            draw.arc((ox + 5, oy + 5, ox + 27, oy + 27), 32, 330, fill=CYAN, width=4)
            draw.arc((ox + 8, oy + 8, ox + 24, oy + 24), 42, 320, fill=WHITE, width=1)
        elif variant == 5:
            outlined_rect(draw, (ox + 7, oy + 8, ox + 25, oy + 24), MAGENTA, WHITE)
            rim(draw, [(ox + 11, oy + 13), (ox + 21, oy + 13)], INK, 2)
        elif variant == 6:
            draw.ellipse((ox + 6, oy + 6, ox + 26, oy + 26), fill=INK)
            draw.ellipse((ox + 8, oy + 8, ox + 24, oy + 24), fill=GOLD)
            draw.arc((ox + 11, oy + 11, ox + 21, oy + 21), 200, 350, fill=INK, width=2)
        else:
            outlined_poly(draw, [(ox + 16, oy + 3), (ox + 27, oy + 16), (ox + 16, oy + 29), (ox + 5, oy + 16)], [(ox + 16, oy + 7), (ox + 23, oy + 16), (ox + 16, oy + 25), (ox + 9, oy + 16)], GLASS, [(ox + 16, oy + 8), (ox + 21, oy + 15)], WHITE)
    else:
        variant = index % 8
        color = [CYAN, WHITE, GOLD, GLASS, GREEN_GLOW, RED, STEEL_LIT, MAGENTA][variant]
        if variant == 0:
            outlined_poly(draw, [(ox + 16, oy + 4), (ox + 27, oy + 16), (ox + 16, oy + 28), (ox + 5, oy + 16)], [(ox + 16, oy + 8), (ox + 23, oy + 16), (ox + 16, oy + 24), (ox + 9, oy + 16)], tint(color, 0.85), [(ox + 16, oy + 8), (ox + 22, oy + 15)], color)
        elif variant == 1:
            draw.rounded_rectangle((ox + 7, oy + 7, ox + 25, oy + 25), radius=2, outline=color, width=2)
            draw.rectangle((ox + 12, oy + 4, ox + 20, oy + 28), outline=color, width=2)
        elif variant == 2:
            rim(draw, [(ox + 5, oy + 16), (ox + 24, oy + 16)], color, 4)
            poly(draw, [(ox + 21, oy + 8), (ox + 30, oy + 16), (ox + 21, oy + 24)], color)
        elif variant == 3:
            outlined_rect(draw, (ox + 7, oy + 7, ox + 25, oy + 25), tint(color, 0.6), color)
            rim(draw, [(ox + 10, oy + 10), (ox + 22, oy + 22)], WHITE, 1)
        elif variant == 4:
            draw.arc((ox + 4, oy + 5, ox + 28, oy + 28), 35, 328, fill=color, width=4)
            draw.arc((ox + 9, oy + 10, ox + 23, oy + 23), 40, 320, fill=WHITE, width=1)
        elif variant == 5:
            outlined_poly(draw, [(ox + 16, oy + 5), (ox + 27, oy + 26), (ox + 5, oy + 26)], [(ox + 16, oy + 10), (ox + 23, oy + 23), (ox + 9, oy + 23)], tint(color, 0.72), [(ox + 16, oy + 11), (ox + 16, oy + 18)], WHITE)
        elif variant == 6:
            outlined_rect(draw, (ox + 9, oy + 5, ox + 23, oy + 27), tint(color, 0.65), color)
            for y in (11, 16, 21):
                rim(draw, [(ox + 12, oy + y), (ox + 20, oy + y)], WHITE, 1)
        else:
            draw.ellipse((ox + 6, oy + 6, ox + 26, oy + 26), outline=color, width=2)
            rim(draw, [(ox + 16, oy + 4), (ox + 16, oy + 28)], color, 3)
            rim(draw, [(ox + 9, oy + 16), (ox + 23, oy + 16)], WHITE, 1)


def icon_sheet(path: Path, ui: bool) -> Image.Image:
    size, cols, rows = 32, 4, 4
    image = Image.new("RGBA", (size * cols, size * rows), CLEAR)
    draw = ImageDraw.Draw(image)
    for index in range(cols * rows):
        icon_art(draw, (index % cols) * size, (index // cols) * size, index, ui)
    image.save(path)
    row_defs = [{"animation": f"{'ui' if ui else 'item'}_row_{row}", "frames": cols} for row in range(rows)]
    record(path, "icon_sheet", image, (size, size), row_defs, "AtlasTexture/Sprite2D", "P2", "V2 adds framed depth, internal highlights, and less glyph-flat icon silhouettes.", True)
    return image


def vfx(effect: str, rows: list[dict[str, object]]) -> Painter:
    palette = {"slash": CYAN, "parry": GOLD, "dash": GLASS, "heal": GREEN_GLOW, "corruption": MAGENTA}
    def paint(image: Image.Image, row: int, frame: int, ox: int, oy: int) -> None:
        draw = ImageDraw.Draw(image)
        color = palette[effect]
        alpha = max(40, 250 - frame * 33)
        glow = (color[0], color[1], color[2], alpha)
        cx, cy = ox + 32, oy + 32
        if effect == "slash":
            draw.arc((ox + 3 - frame, oy + 3, ox + 62 + frame, oy + 63), -92 + frame * 5, 58 + frame * 10, fill=glow, width=5)
            draw.arc((ox + 10, oy + 9, ox + 57, oy + 58), -88, 50 + frame * 8, fill=WHITE, width=2)
            for spark in range(3):
                rim(draw, [(ox + 42 + spark * 4, oy + 13 + frame * 2), (ox + 49 + spark * 5, oy + 8 + spark)], glow, 2)
        elif effect == "parry":
            radius = 8 + frame * 4
            outlined_poly(draw, [(cx, cy - radius), (cx + radius, cy), (cx, cy + radius), (cx - radius, cy)], [(cx, cy - max(3, radius - 4)), (cx + max(3, radius - 4), cy), (cx, cy + max(3, radius - 4)), (cx - max(3, radius - 4), cy)], (GOLD[0], GOLD[1], GOLD[2], max(50, alpha - 30)), [(cx - radius, cy), (cx + radius, cy)], WHITE)
            for spark in range(4):
                angle = spark * math.pi / 2 + frame * 0.18
                rim(draw, [(cx + int(math.cos(angle) * radius), cy + int(math.sin(angle) * radius)), (cx + int(math.cos(angle) * (radius + 8)), cy + int(math.sin(angle) * (radius + 8)))], glow, 2)
        elif effect == "dash":
            for band in range(5):
                x0 = ox + 2 + band * 8 + frame * 3
                poly(draw, [(x0, cy - 15 + band), (x0 + 26 - band * 2, cy - 9 + band), (x0 + 18 - band * 2, cy + 11 + band), (x0 - 4, cy + 4 + band)], (color[0], color[1], color[2], max(25, alpha - band * 34)))
                rim(draw, [(x0 + 2, cy - 12 + band), (x0 + 20 - band * 2, cy - 7 + band)], WHITE if band == 0 else glow, 1)
        elif effect == "heal":
            radius = 7 + frame * 4
            draw.ellipse((cx - radius, cy - radius, cx + radius, cy + radius), outline=glow, width=4)
            draw.arc((cx - radius + 5, cy - radius + 5, cx + radius - 5, cy + radius - 5), 30, 330, fill=WHITE, width=1)
            rim(draw, [(cx, cy - 17), (cx, cy + 17)], WHITE, 4)
            rim(draw, [(cx - 17, cy), (cx + 17, cy)], WHITE, 4)
            for mote in range(3):
                rect(draw, (cx - 18 + mote * 14, cy - 20 + frame + mote * 3, cx - 16 + mote * 14, cy - 18 + frame + mote * 3), glow)
        else:
            for shard in range(8):
                angle = shard * math.pi * 2 / 8 + frame * 0.22
                x = cx + int(math.cos(angle) * (10 + frame * 4))
                y = cy + int(math.sin(angle) * (7 + frame * 3))
                poly(draw, [(x, y - 8), (x + 4, y), (x, y + 8), (x - 3, y)], glow)
            rim(draw, [(ox + 7 + frame * 2, oy + 55 - frame * 4), (ox + 23, oy + 36), (ox + 34, oy + 44), (ox + 55 - frame, oy + 9 + frame)], glow, 3)
            glitch_ticks(draw, ox + 7, oy + 8, 1900 + frame, 50, 45, WHITE)
    return paint


def tile_noise(draw: ImageDraw.ImageDraw, x: int, y: int, seed: int, colors: list[RGBA], count: int = 13) -> None:
    rng = random.Random(seed)
    for _ in range(count):
        px = x + rng.randrange(3, 29)
        py = y + rng.randrange(3, 29)
        color = colors[rng.randrange(len(colors))]
        if rng.random() > 0.55:
            rect(draw, (px, py, px + rng.randrange(1, 3), py + rng.randrange(1, 2)), color)
        else:
            draw.point((px, py), fill=color)


def tileset(name: str, specs: list[tuple[str, RGBA, list[RGBA]]], path: Path) -> Image.Image:
    tile = 32
    cols = 4
    rows = math.ceil(len(specs) / cols)
    image = Image.new("RGBA", (cols * tile, rows * tile), (15, 18, 29, 255))
    draw = ImageDraw.Draw(image)
    tiles: list[str] = []
    for index, (label, base, texture) in enumerate(specs):
        x = index % cols * tile
        y = index // cols * tile
        tiles.append(label)
        rect(draw, (x, y, x + 31, y + 31), INK)
        rect(draw, (x + 1, y + 1, x + 30, y + 30), base)
        rim(draw, [(x + 2, y + 2), (x + 29, y + 2)], tint(base, 1.28), 1)
        tile_noise(draw, x, y, 2300 + index * 43 + len(name), texture, 14)
        if label in {"grass", "hedge", "flower"}:
            for tuft in range(4):
                px = x + 5 + tuft * 6
                rim(draw, [(px, y + 25 - tuft % 2), (px + 2, y + 17 - tuft), (px + 4, y + 24)], texture[-1], 2)
            if label == "flower":
                rect(draw, (x + 11, y + 11, x + 14, y + 14), GOLD)
                rect(draw, (x + 20, y + 19, x + 23, y + 22), CYAN)
        elif label in {"path", "dust", "null_floor", "plaza", "aisle", "kernel", "circuit"}:
            for crack in range(3):
                rim(draw, [(x + 4 + crack * 8, y + 28 - crack * 4), (x + 12 + crack * 5, y + 16 + crack), (x + 18 + crack * 4, y + 14 - crack)], texture[-1], 1)
        elif label in {"brick", "wall", "archive_wall", "server_floor", "root_wall"}:
            for yy in (y + 9, y + 18, y + 26):
                rim(draw, [(x + 3, yy), (x + 28, yy)], texture[-1], 1)
            for xx in (x + 9, x + 20):
                rim(draw, [(xx, y + 4), (xx, y + 27)], texture[-2], 1)
        elif label in {"forge", "pipe", "rail", "vent"}:
            outlined_rect(draw, (x + 5, y + 8, x + 26, y + 24), texture[-2], tint(texture[-1], 1.1))
            rim(draw, [(x + 7, y + 16), (x + 24, y + 16)], EMBER if label == "forge" else STEEL_LIT, 2)
        elif label in {"shard", "glitch_rune", "seal", "mirror", "reflection", "firewall", "rune", "portal", "witness"}:
            outlined_poly(draw, [(x + 16, y + 4), (x + 27, y + 16), (x + 16, y + 28), (x + 5, y + 16)], [(x + 16, y + 8), (x + 23, y + 16), (x + 16, y + 24), (x + 9, y + 16)], texture[-2], [(x + 16, y + 8), (x + 21, y + 14)], texture[-1])
        elif label in {"water", "tide", "foam"}:
            for wave in range(3):
                yy = y + 9 + wave * 8
                draw.arc((x + 3, yy - 4, x + 19, yy + 5), 0, 180, fill=texture[-1], width=2)
                draw.arc((x + 14, yy - 1, x + 29, yy + 7), 180, 360, fill=tint(texture[-1], 0.92), width=2)
        elif label in {"wood", "roof", "sign", "crate", "console", "altar", "dossier", "salvage", "throne"}:
            outlined_rect(draw, (x + 5, y + 6, x + 26, y + 25), texture[-2], texture[-1])
            rim(draw, [(x + 8, y + 10), (x + 23, y + 21)], texture[-1], 2)
            rim(draw, [(x + 8, y + 21), (x + 23, y + 10)], tint(texture[-1], 0.75), 1)
        elif label in {"pit", "void"}:
            draw.ellipse((x + 4, y + 7, x + 28, y + 27), fill=VOID, outline=texture[-1])
            draw.arc((x + 7, y + 10, x + 25, y + 24), 210, 340, fill=MAGENTA, width=2)
        elif label in {"fountain", "island", "log", "root"}:
            draw.ellipse((x + 5, y + 7, x + 27, y + 25), fill=texture[-2], outline=INK)
            draw.arc((x + 8, y + 10, x + 24, y + 22), 20, 345, fill=texture[-1], width=2)
        rim(draw, [(x + 1, y + 30), (x + 30, y + 30)], tint(base, 0.62), 1)
    image.save(path)
    rows_def = [{"animation": "tiles", "frames": len(specs), "tiles": tiles}]
    record(path, "tileset", image, (tile, tile), rows_def, "TileSetAtlasSource", "P2", "V2 tile motifs add texture, edge wear, and region-specific symbols over V1 palette blocks.", False, (tile, tile), tiles)
    return image


def checker_thumb(path: Path, size: tuple[int, int]) -> Image.Image:
    image = Image.open(path).convert("RGBA")
    image.thumbnail(size, Image.Resampling.NEAREST)
    bg = Image.new("RGBA", image.size, (17, 21, 35, 255))
    draw = ImageDraw.Draw(bg)
    for y in range(0, bg.height, 8):
        for x in range(0, bg.width, 8):
            if (x // 8 + y // 8) % 2:
                rect(draw, (x, y, x + 7, y + 7), (29, 36, 54, 255))
    bg.alpha_composite(image)
    return bg


def contact(paths: Iterable[Path], output: Path, cell: tuple[int, int], cols: int, labels: bool = False) -> None:
    paths = list(paths)
    rows = math.ceil(len(paths) / cols)
    font = ImageFont.load_default()
    canvas = Image.new("RGBA", (cell[0] * cols, cell[1] * rows), (10, 14, 27, 255))
    draw = ImageDraw.Draw(canvas)
    for index, path in enumerate(paths):
        thumb_height = cell[1] - 22 if labels else cell[1] - 10
        thumb = checker_thumb(path, (cell[0] - 12, thumb_height))
        left = index % cols * cell[0]
        top = index // cols * cell[1]
        x = left + (cell[0] - thumb.width) // 2
        y = top + 5
        canvas.alpha_composite(thumb, (x, y))
        if labels:
            draw.text((left + 6, top + cell[1] - 15), path.stem.replace("_v2", "")[:24], fill=WHITE, font=font)
    output.parent.mkdir(parents=True, exist_ok=True)
    canvas.save(output)


def compare_pairs(pairs: list[tuple[str, Path, Path]], output: Path) -> None:
    font = ImageFont.load_default()
    cell_w, cell_h = 248, 180
    canvas = Image.new("RGBA", (cell_w * 2, cell_h * len(pairs)), (10, 14, 27, 255))
    draw = ImageDraw.Draw(canvas)
    for row, (label, v1_path, v2_path) in enumerate(pairs):
        top = row * cell_h
        draw.text((8, top + 6), f"V1 {label}", fill=(195, 211, 237, 255), font=font)
        draw.text((cell_w + 8, top + 6), f"V2 {label}", fill=CYAN, font=font)
        for column, path in enumerate((v1_path, v2_path)):
            thumb = checker_thumb(path, (cell_w - 18, cell_h - 32))
            x = column * cell_w + (cell_w - thumb.width) // 2
            y = top + 24 + (cell_h - 32 - thumb.height) // 2
            canvas.alpha_composite(thumb, (x, y))
        draw.line((cell_w, top, cell_w, top + cell_h), fill=(50, 67, 96, 255), width=1)
        draw.line((0, top + cell_h - 1, cell_w * 2, top + cell_h - 1), fill=(50, 67, 96, 255), width=1)
    canvas.save(output)


def write_manifests() -> None:
    data = {"phase": "10M-C2", "generator": rel(Path(__file__)), "assets": [asdict(asset) for asset in ASSETS]}
    (MANIFESTS / "phase10mc2_asset_manifest.json").write_text(json.dumps(data, indent=2), encoding="utf-8")
    rows = [
        "# Phase 10M-C2 V2 Asset Manifest",
        "",
        "The V2 files stay isolated under `assets/generated_v2/` and keep V1 row compatibility for later integration.",
        "",
        "| File | Dimensions | Frame Size | Animation Rows | Frames Per Row | Godot Type | Priority | Improvement Over V1 |",
        "| --- | --- | --- | --- | --- | --- | --- | --- |",
    ]
    for asset in ASSETS:
        row_names = ", ".join(str(row["animation"]) for row in asset.animation_rows)
        frames = ", ".join(str(row["frames"]) for row in asset.animation_rows)
        rows.append(
            f"| `{asset.path}` | `{asset.dimensions[0]}x{asset.dimensions[1]}` | `{asset.frame_size[0]}x{asset.frame_size[1]}` | {row_names} | {frames} | {asset.intended_godot_type} | {asset.integration_priority} | {asset.improvement_notes_over_v1} |"
        )
    (MANIFESTS / "phase10mc2_asset_manifest.md").write_text("\n".join(rows) + "\n", encoding="utf-8")


def validate() -> None:
    errors: list[str] = []
    for asset in ASSETS:
        path = ROOT / asset.path
        if not path.exists() or path.stat().st_size == 0:
            errors.append(f"missing_or_zero:{asset.path}")
            continue
        with Image.open(path) as image:
            if image.size != asset.dimensions:
                errors.append(f"dimension:{asset.path}")
            if image.width % asset.frame_size[0] or image.height % asset.frame_size[1]:
                errors.append(f"grid:{asset.path}")
            if asset.alpha_required:
                if "A" not in image.getbands():
                    errors.append(f"alpha:{asset.path}")
                elif image.getchannel("A").getextrema()[0] > 0:
                    errors.append(f"transparency:{asset.path}")
    preview_names = [
        "phase10mc2_sprite_contact_sheet.png",
        "phase10mc2_npc_enemy_contact_sheet.png",
        "phase10mc2_fx_tiles_contact_sheet.png",
        "phase10mc2_v1_vs_v2_comparison.png",
    ]
    missing_previews = [name for name in preview_names if not (PREVIEWS / name).exists()]
    errors.extend(f"preview:{name}" for name in missing_previews)
    payload = {
        "asset_count": len(ASSETS),
        "preview_count": len(preview_names) - len(missing_previews),
        "errors": errors,
        "status": "pass" if not errors else "fail",
    }
    (MANIFESTS / "phase10mc2_validation.json").write_text(json.dumps(payload, indent=2), encoding="utf-8")
    if errors:
        raise SystemExit("\n".join(errors))
    print(f"PHASE10MC2_VALIDATION PASS assets={len(ASSETS)} previews={len(preview_names)}")


def main() -> None:
    ensure_dirs()
    top_rows = [
        {"animation": "idle_front", "frames": 4},
        {"animation": "walk_front", "frames": 4},
        {"animation": "idle_back", "frames": 4},
        {"animation": "walk_back", "frames": 4},
        {"animation": "idle_left", "frames": 4},
        {"animation": "walk_left", "frames": 4},
        {"animation": "idle_right", "frames": 4},
        {"animation": "walk_right", "frames": 4},
    ]
    combat_rows = [{"animation": name, "frames": 4} for name in ["idle", "run", "slash_1", "slash_2", "slash_3", "charged_slash", "upslash", "downslash", "dash", "cast", "hurt", "death"]]
    knight_rows = [{"animation": name, "frames": 4} for name in ["idle", "slash", "charge", "low_sweep", "shield_bash", "teleport_slash", "corrupt_rift", "shockwave", "phase_change", "defeat"]]
    enemy_rows = [{"animation": name, "frames": 4} for name in ["idle", "move", "attack", "hurt", "death"]]
    npc_rows = [{"animation": name, "frames": 4} for name in ["idle", "talk", "walk"]]
    vfx_rows = [{"animation": "frames", "frames": 6}]

    save_sheet(V2 / "sprites" / "player" / "kaelen_topdown_v2_alpha_sheet.png", (32, 32), top_rows, kaelen_topdown(top_rows), "sprite_sheet", "AnimatedSprite2D/SpriteFrames", "P0", "Larger body occupancy, split coat, direction-specific head shape, sword/rim accents.", True)
    save_sheet(V2 / "sprites" / "player" / "kaelen_combat_v2_alpha_sheet.png", (64, 64), combat_rows, kaelen_combat(combat_rows), "sprite_sheet", "AnimatedSprite2D/SpriteFrames", "P0", "Dynamic sword silhouettes, anticipation/follow-through poses, cape and rim lighting.", True)
    save_sheet(V2 / "sprites" / "bosses" / "tutorial_knight_v2_alpha_sheet.png", (96, 96), knight_rows, knight(knight_rows), "sprite_sheet", "AnimatedSprite2D/SpriteFrames", "P1", "Allowed 96x96 frame gives broader armor mass, full shield/sword patterns, and corruption escalation shapes room to read.", True)

    for name in ["fracture_slime", "clock_mite", "memory_wisp"]:
        save_sheet(V2 / "sprites" / "enemies" / f"{name}_v2_alpha_sheet.png", (48, 48), enemy_rows, enemy(enemy_rows, name), "sprite_sheet", "AnimatedSprite2D/SpriteFrames", "P2", "Distinct body silhouette and more separated attack/hurt/death poses.", True)

    npc_palettes = {
        "elara": ((73, 38, 111, 255), CYAN, (192, 167, 230, 255)),
        "seraphina": ((43, 67, 112, 255), GOLD, (232, 196, 110, 255)),
        "lyra": ((28, 110, 87, 255), GREEN_GLOW, (93, 47, 58, 255)),
        "null_clerk": ((49, 54, 76, 255), MAGENTA, STEEL_LIT),
        "assembly_runner": ((115, 66, 42, 255), GOLD, (50, 38, 33, 255)),
    }
    for name, palette in npc_palettes.items():
        save_sheet(V2 / "sprites" / "npcs" / f"{name}_v2_alpha_sheet.png", (32, 32), npc_rows, npc(npc_rows, name, palette), "sprite_sheet", "AnimatedSprite2D/SpriteFrames", "P2", "Costume silhouette, prop language, and visible talk motion exceed V1 recolor read.", True)

    icon_sheet(V2 / "icons" / "item_icons_v2_alpha_sheet.png", False)
    icon_sheet(V2 / "icons" / "ui_icons_v2_alpha_sheet.png", True)

    for name in ["slash", "parry", "dash", "heal", "corruption"]:
        save_sheet(V2 / "vfx" / f"{name}_v2_alpha_strip.png", (64, 64), vfx_rows, vfx(name, vfx_rows), "vfx_strip", "AnimatedSprite2D/GPUParticles2D texture", "P2", "Sharper active-frame silhouette, richer sparks/trails, and stronger glow hierarchy.", True)

    tile_specs: dict[str, list[tuple[str, RGBA, list[RGBA]]]] = {
        "oakhaven": [
            ("grass", (33, 82, 49, 255), [(24, 61, 38, 255), (70, 136, 79, 255), (158, 201, 100, 255)]),
            ("path", (115, 88, 58, 255), [(82, 59, 40, 255), (148, 112, 74, 255), (194, 154, 92, 255)]),
            ("wood", (95, 61, 38, 255), [(66, 43, 29, 255), (138, 90, 49, 255), GOLD]),
            ("roof", (77, 46, 43, 255), [(52, 34, 36, 255), (124, 72, 61, 255), (185, 112, 71, 255)]),
            ("hedge", (25, 66, 42, 255), [(19, 49, 34, 255), (58, 126, 72, 255), GREEN_GLOW]),
            ("flower", (39, 91, 49, 255), [(25, 67, 38, 255), (95, 175, 98, 255), CYAN]),
            ("sign", (106, 68, 37, 255), [(76, 47, 27, 255), (155, 99, 50, 255), GOLD]),
            ("moss", (45, 98, 57, 255), [(30, 73, 45, 255), (86, 151, 83, 255), (171, 213, 120, 255)]),
        ],
        "ironhold": [
            ("brick", (49, 55, 71, 255), [(34, 39, 54, 255), (88, 98, 123, 255), STEEL_LIT]),
            ("metal", (57, 64, 79, 255), [(35, 42, 57, 255), STEEL, CYAN]),
            ("forge", (79, 52, 42, 255), [(45, 35, 37, 255), EMBER, GOLD]),
            ("pipe", (57, 61, 69, 255), [(39, 43, 52, 255), (113, 101, 74, 255), STEEL_LIT]),
            ("rail", (48, 53, 66, 255), [(35, 39, 48, 255), STEEL, GOLD]),
            ("crate", (91, 63, 43, 255), [(62, 44, 33, 255), (149, 99, 57, 255), GOLD]),
            ("vent", (47, 54, 65, 255), [(30, 36, 48, 255), (92, 105, 125, 255), CYAN]),
            ("brick", (61, 49, 56, 255), [(40, 35, 45, 255), (116, 89, 77, 255), EMBER]),
        ],
        "fractured_wastes": [
            ("dust", (86, 59, 68, 255), [(56, 39, 53, 255), (134, 86, 74, 255), MAGENTA]),
            ("path", (101, 68, 62, 255), [(60, 45, 54, 255), (157, 105, 79, 255), EMBER]),
            ("shard", (62, 42, 79, 255), [(38, 27, 58, 255), MAGENTA, CYAN]),
            ("glitch_rune", (71, 39, 90, 255), [(43, 28, 59, 255), MAGENTA, WHITE]),
            ("rune", (80, 47, 95, 255), [(44, 30, 62, 255), CYAN, MAGENTA]),
            ("ridge", (114, 78, 63, 255), [(74, 52, 51, 255), (170, 111, 73, 255), GOLD]),
            ("pit", (46, 29, 53, 255), [(24, 18, 37, 255), MAGENTA, CYAN]),
            ("dust", (91, 65, 70, 255), [(58, 42, 54, 255), (145, 94, 75, 255), WHITE]),
        ],
        "forgotten_sectors": [
            ("null_floor", (44, 52, 71, 255), [(29, 36, 55, 255), (85, 95, 119, 255), CYAN]),
            ("archive_wall", (53, 59, 79, 255), [(33, 40, 59, 255), STEEL, CYAN]),
            ("dossier", (69, 65, 69, 255), [(46, 47, 57, 255), (188, 176, 143, 255), GOLD]),
            ("seal", (38, 48, 68, 255), [(24, 33, 51, 255), CYAN, WHITE]),
            ("memory", (44, 72, 86, 255), [(29, 49, 64, 255), GLASS, CYAN]),
            ("void", (20, 25, 39, 255), [(13, 18, 31, 255), MAGENTA, CYAN]),
            ("console", (47, 55, 73, 255), [(29, 38, 55, 255), STEEL, CYAN]),
            ("rune", (36, 43, 63, 255), [(24, 31, 49, 255), MAGENTA, WHITE]),
        ],
        "mirror_city": [
            ("glass", (43, 83, 109, 255), [(29, 57, 79, 255), GLASS, WHITE]),
            ("mirror", (48, 93, 120, 255), [(29, 59, 80, 255), CYAN, WHITE]),
            ("plaza", (74, 109, 130, 255), [(49, 76, 98, 255), (131, 185, 201, 255), WHITE]),
            ("fountain", (36, 90, 119, 255), [(26, 63, 87, 255), GLASS, CYAN]),
            ("arch", (58, 95, 119, 255), [(35, 65, 88, 255), GLASS, WHITE]),
            ("reflection", (37, 75, 104, 255), [(25, 52, 76, 255), CYAN, MAGENTA]),
            ("mirror", (54, 104, 127, 255), [(30, 63, 85, 255), GLASS, CYAN]),
            ("rune", (42, 80, 112, 255), [(28, 55, 80, 255), CYAN, WHITE]),
        ],
        "cathedral_server": [
            ("server_floor", (45, 45, 73, 255), [(30, 31, 53, 255), (86, 92, 126, 255), GOLD]),
            ("aisle", (61, 56, 84, 255), [(39, 37, 61, 255), (111, 116, 151, 255), CYAN]),
            ("console", (52, 55, 77, 255), [(31, 35, 54, 255), STEEL, CYAN]),
            ("altar", (74, 61, 78, 255), [(43, 39, 59, 255), GOLD, WHITE]),
            ("firewall", (69, 43, 74, 255), [(39, 31, 58, 255), MAGENTA, GOLD]),
            ("choir", (45, 52, 81, 255), [(30, 35, 57, 255), CYAN, GOLD]),
            ("wire", (39, 44, 66, 255), [(25, 30, 49, 255), STEEL, MAGENTA]),
            ("rune", (53, 45, 77, 255), [(32, 29, 53, 255), GOLD, WHITE]),
        ],
        "memory_ocean": [
            ("water", (23, 64, 109, 255), [(15, 45, 79, 255), (53, 138, 178, 255), GLASS]),
            ("tide", (29, 84, 132, 255), [(16, 53, 91, 255), GLASS, WHITE]),
            ("foam", (41, 112, 151, 255), [(23, 72, 112, 255), GLASS, WHITE]),
            ("island", (75, 89, 92, 255), [(46, 59, 66, 255), MOSS, GOLD]),
            ("salvage", (66, 81, 94, 255), [(43, 56, 70, 255), STEEL, CYAN]),
            ("log", (91, 73, 59, 255), [(56, 48, 44, 255), GOLD, GLASS]),
            ("memory", (35, 83, 121, 255), [(19, 51, 83, 255), CYAN, MAGENTA]),
            ("rune", (31, 74, 112, 255), [(18, 47, 78, 255), GLASS, WHITE]),
        ],
        "root_of_heaven": [
            ("root", (62, 43, 80, 255), [(35, 29, 57, 255), MAGENTA, CYAN]),
            ("kernel", (54, 59, 91, 255), [(30, 36, 63, 255), CYAN, WHITE]),
            ("circuit", (47, 53, 83, 255), [(28, 33, 58, 255), GLASS, CYAN]),
            ("root_wall", (55, 45, 73, 255), [(31, 29, 53, 255), MAGENTA, STEEL_LIT]),
            ("witness", (48, 49, 79, 255), [(29, 31, 56, 255), GOLD, CYAN]),
            ("portal", (39, 49, 80, 255), [(24, 31, 59, 255), CYAN, WHITE]),
            ("throne", (66, 52, 83, 255), [(38, 34, 62, 255), GOLD, WHITE]),
            ("glitch_rune", (54, 39, 81, 255), [(32, 27, 58, 255), MAGENTA, CYAN]),
        ],
    }
    for name, specs in tile_specs.items():
        tileset(name, specs, V2 / "tilesets" / f"{name}_v2_prototype_tileset.png")

    player_paths = [
        V2 / "sprites" / "player" / "kaelen_topdown_v2_alpha_sheet.png",
        V2 / "sprites" / "player" / "kaelen_combat_v2_alpha_sheet.png",
        V2 / "sprites" / "bosses" / "tutorial_knight_v2_alpha_sheet.png",
    ]
    npc_enemy_paths = [
        *(V2 / "sprites" / "enemies" / f"{name}_v2_alpha_sheet.png" for name in ["fracture_slime", "clock_mite", "memory_wisp"]),
        *(V2 / "sprites" / "npcs" / f"{name}_v2_alpha_sheet.png" for name in npc_palettes),
    ]
    fx_tile_paths = [
        V2 / "icons" / "item_icons_v2_alpha_sheet.png",
        V2 / "icons" / "ui_icons_v2_alpha_sheet.png",
        *(V2 / "vfx" / f"{name}_v2_alpha_strip.png" for name in ["slash", "parry", "dash", "heal", "corruption"]),
        *(V2 / "tilesets" / f"{name}_v2_prototype_tileset.png" for name in tile_specs),
    ]
    contact(player_paths, PREVIEWS / "phase10mc2_sprite_contact_sheet.png", (300, 260), 2, True)
    contact(npc_enemy_paths, PREVIEWS / "phase10mc2_npc_enemy_contact_sheet.png", (220, 170), 3, True)
    contact(fx_tile_paths, PREVIEWS / "phase10mc2_fx_tiles_contact_sheet.png", (212, 160), 4, True)
    compare_pairs(
        [
            ("Kaelen Topdown", V1 / "sprites" / "player" / "kaelen_topdown_alpha_sheet.png", player_paths[0]),
            ("Kaelen Combat", V1 / "sprites" / "player" / "kaelen_combat_alpha_sheet.png", player_paths[1]),
            ("Tutorial Knight", V1 / "sprites" / "bosses" / "tutorial_knight_alpha_sheet.png", player_paths[2]),
            ("NPC Elara", V1 / "sprites" / "npcs" / "elara_alpha_sheet.png", V2 / "sprites" / "npcs" / "elara_v2_alpha_sheet.png"),
            ("Memory Wisp", V1 / "sprites" / "enemies" / "memory_wisp_alpha_sheet.png", V2 / "sprites" / "enemies" / "memory_wisp_v2_alpha_sheet.png"),
            ("Oakhaven Tiles", V1 / "tilesets" / "oakhaven_prototype_tileset.png", V2 / "tilesets" / "oakhaven_v2_prototype_tileset.png"),
            ("Slash VFX", V1 / "vfx" / "slash_alpha_strip.png", V2 / "vfx" / "slash_v2_alpha_strip.png"),
        ],
        PREVIEWS / "phase10mc2_v1_vs_v2_comparison.png",
    )
    write_manifests()
    validate()
    print(f"PHASE10MC2_GENERATION PASS assets={len(ASSETS)}")


if __name__ == "__main__":
    main()
