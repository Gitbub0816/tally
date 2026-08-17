#!/usr/bin/env python3
"""Generate Tally liveries against the source models' real UV atlases.

Usage:
  python3 scripts/generate_aircraft_liveries.py \
    --b737-texture /path/to/b737_TEX.png \
    --b787-fuselage /path/to/image_0.jpg \
    --b787-tail /path/to/image_1.jpg \
    --output ios/Tally/Resources/AircraftLiveries
"""

from __future__ import annotations

import argparse
import math
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw


def recolor_masked(source: Image.Image, mask: np.ndarray, color: tuple[int, int, int]) -> Image.Image:
    pixels = np.asarray(source.convert("RGB"), dtype=np.float32)
    luminance = pixels.mean(axis=2)
    reference = float(np.median(luminance[mask]))
    shading = np.clip(luminance / max(reference, 1.0), 0.62, 1.34)
    result = pixels.copy()
    for channel, value in enumerate(color):
        result[..., channel][mask] = np.clip(value * shading[mask], 0, 255)
    return Image.fromarray(result.astype(np.uint8), "RGB")


def star(draw: ImageDraw.ImageDraw, center: tuple[float, float], radius: float, fill: str) -> None:
    points: list[tuple[float, float]] = []
    for index in range(10):
        angle = index * math.pi / 5 - math.pi / 2
        point_radius = radius if index % 2 == 0 else radius * 0.43
        points.append((center[0] + math.cos(angle) * point_radius, center[1] + math.sin(angle) * point_radius))
    draw.polygon(points, fill=fill)


def masked_graphics(base: Image.Image, fuselage_mask: np.ndarray, painter) -> Image.Image:
    graphics = Image.new("RGBA", base.size, (0, 0, 0, 0))
    painter(ImageDraw.Draw(graphics))
    alpha = np.asarray(graphics.getchannel("A"), dtype=np.uint8).copy()
    alpha[~fuselage_mask] = 0
    graphics.putalpha(Image.fromarray(alpha, "L"))
    return Image.alpha_composite(base.convert("RGBA"), graphics).convert("RGB")


def generate_737(source_path: Path, output: Path) -> None:
    source = Image.open(source_path).convert("RGB")
    pixels = np.asarray(source)
    green = (
        (pixels[..., 1] > pixels[..., 0] + 12)
        & (pixels[..., 1] > pixels[..., 2] + 7)
        & (pixels[..., 0] < 95)
        & (pixels[..., 1] < 125)
    )
    # The second mirrored fuselage island contains a large unpainted white
    # section. Include that island explicitly without touching the wing/engine
    # islands elsewhere in the atlas.
    yy, xx = np.indices(green.shape)
    lower_fuselage = (xx < 640) & (yy >= 430) & (yy < 842)
    neutral_light = (pixels.max(axis=2) - pixels.min(axis=2) < 38) & (pixels.mean(axis=2) > 150)
    fuselage = green | (lower_fuselage & neutral_light)

    tennessee = recolor_masked(source, fuselage, (200, 16, 46))

    def paint_tennessee(draw: ImageDraw.ImageDraw) -> None:
        navy = "#0C2340"
        draw.ellipse((145, 118, 535, 354), fill=navy)
        star(draw, (260, 235), 30, "white")
        star(draw, (345, 190), 30, "white")
        star(draw, (425, 270), 30, "white")
        draw.ellipse((35, 512, 405, 748), fill=navy)
        star(draw, (140, 630), 28, "white")
        star(draw, (220, 585), 28, "white")
        star(draw, (300, 665), 28, "white")

    tennessee = masked_graphics(tennessee, fuselage, paint_tennessee)
    tennessee.save(output / "boeing_737_tennessee_one.png", optimize=True)

    canyon = recolor_masked(source, fuselage, (40, 96, 164))

    def paint_canyon(draw: ImageDraw.ImageDraw) -> None:
        red, gold = "#C83C34", "#E5B941"
        draw.line(((0, 382), (680, 420)), fill=red, width=54)
        draw.line(((0, 360), (680, 398)), fill=gold, width=12)
        draw.line(((0, 790), (635, 828)), fill=red, width=54)
        draw.line(((0, 768), (635, 806)), fill=gold, width=12)

    canyon = masked_graphics(canyon, fuselage, paint_canyon)
    canyon.save(output / "boeing_737_classic_canyon_blue.png", optimize=True)


def generate_787(fuselage_path: Path, tail_path: Path, output: Path) -> None:
    source = Image.open(fuselage_path).convert("RGB")
    pixels = np.asarray(source, dtype=np.int16)
    result = pixels.copy()

    # Preserve baked doors, windows, panel lines, and shading while turning the
    # original neutral skin into Silver Eagle's aluminum tone.
    channel_span = pixels.max(axis=2) - pixels.min(axis=2)
    neutral_skin = (channel_span < 18) & (pixels.mean(axis=2) > 145)
    luminance = pixels.mean(axis=2)
    silver = np.clip(188 + (luminance - 205) * 0.42, 158, 218)
    for channel, offset in enumerate((4, 7, 10)):
        result[..., channel][neutral_skin] = np.clip(silver[neutral_skin] + offset, 0, 255)

    # Recolor the source atlas' blue artwork so every painted pixel follows the
    # fuselage UVs instead of being composited in front of the SceneKit view.
    blue = (
        (pixels[..., 2] > pixels[..., 0] + 24)
        & (pixels[..., 2] > pixels[..., 1] + 8)
        & (pixels[..., 2] > 70)
    )
    result[..., 0][blue] = 37
    result[..., 1][blue] = 60
    result[..., 2][blue] = 115
    fuselage = Image.fromarray(result.astype(np.uint8), "RGB")
    draw = ImageDraw.Draw(fuselage)
    red = "#C9373D"
    navy = "#253C73"

    # Remove the source-model branding from the four mirrored fuselage islands.
    # These boxes sit between the door/window detail rather than over it.
    silver_fill = (194, 199, 204)
    for box in ((205, 735, 465, 798), (1080, 730, 1390, 792), (205, 1432, 470, 1495), (1080, 1436, 1390, 1498)):
        draw.rectangle(box, fill=silver_fill)

    # The two long strips are the left and right fuselage islands in image_0.
    # Lines follow the existing unwrap immediately beneath the window rows.
    draw.line(((18, 805), (410, 875), (910, 870)), fill=navy, width=18)
    draw.line(((18, 828), (410, 898), (910, 893)), fill=red, width=11)
    draw.line(((1128, 870), (1590, 868), (1900, 800)), fill=navy, width=18)
    draw.line(((1128, 893), (1590, 891), (1900, 823)), fill=red, width=11)
    draw.line(((18, 1480), (420, 1415), (910, 1425)), fill=navy, width=18)
    draw.line(((18, 1503), (420, 1438), (910, 1448)), fill=red, width=11)
    draw.line(((1128, 1425), (1590, 1428), (1900, 1490)), fill=navy, width=18)
    draw.line(((1128, 1448), (1590, 1451), (1900, 1513)), fill=red, width=11)
    fuselage.save(output / "boeing_787_silver_eagle_fuselage.png", optimize=True)

    tail = Image.open(tail_path).convert("RGB")
    draw_tail = ImageDraw.Draw(tail)
    # Cover both mirrored fin islands completely so none of the source 787
    # lettering survives on the shipped livery.
    left_fin = ((57, 10), (332, 38), (265, 97), (190, 258), (0, 258), (0, 188))
    right_fin = ((311, 218), (423, 137), (512, 120), (512, 420), (390, 512), (312, 400), (232, 327))
    draw_tail.polygon(left_fin, fill=navy)
    draw_tail.polygon(right_fin, fill=navy)
    draw_tail.polygon(((82, 35), (126, 39), (248, 242), (212, 251)), fill="#B9BEC4")
    draw_tail.polygon(((116, 38), (150, 42), (265, 226), (235, 244)), fill=red)
    draw_tail.polygon(((447, 154), (476, 146), (356, 418), (327, 390)), fill="#B9BEC4")
    draw_tail.polygon(((470, 148), (494, 140), (375, 438), (352, 416)), fill=red)
    tail.save(output / "boeing_787_silver_eagle_tail.png", optimize=True)


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--b737-texture", type=Path, required=True)
    parser.add_argument("--b787-fuselage", type=Path, required=True)
    parser.add_argument("--b787-tail", type=Path, required=True)
    parser.add_argument("--output", type=Path, required=True)
    arguments = parser.parse_args()
    arguments.output.mkdir(parents=True, exist_ok=True)
    generate_737(arguments.b737_texture, arguments.output)
    generate_787(arguments.b787_fuselage, arguments.b787_tail, arguments.output)


if __name__ == "__main__":
    main()
