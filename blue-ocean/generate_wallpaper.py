#!/usr/bin/env python3
"""Draw a reproducible, calm ocean wallpaper with Pillow."""

from __future__ import annotations

import math
import random
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter


WIDTH, HEIGHT = 1920, 1080
OUT = Path(__file__).resolve().parent / "wallpaper" / "blue-ocean.png"


def mix(a: tuple[int, int, int], b: tuple[int, int, int], t: float) -> tuple[int, int, int]:
    return tuple(round(x * (1 - t) + y * t) for x, y in zip(a, b))


def wave(x: float, level: float, size: float, phase: float) -> float:
    return level + math.sin(x * 0.0042 + phase) * size + math.sin(x * 0.0093 + phase * 1.9) * size * 0.25


def main() -> None:
    image = Image.new("RGB", (WIDTH, HEIGHT))
    draw = ImageDraw.Draw(image)
    for y in range(HEIGHT):
        t = y / HEIGHT
        if t < 0.58:
            color = mix((5, 19, 34), (11, 43, 64), t / 0.58)
        else:
            color = mix((11, 43, 64), (4, 28, 47), (t - 0.58) / 0.42)
        draw.line((0, y, WIDTH, y), fill=color)

    glow = Image.new("RGBA", (WIDTH, HEIGHT), (0, 0, 0, 0))
    gd = ImageDraw.Draw(glow)
    gd.ellipse((730, 220, 1780, 1080), fill=(38, 158, 195, 43))
    gd.ellipse((190, 550, 1150, 1290), fill=(28, 122, 168, 30))
    glow = glow.filter(ImageFilter.GaussianBlur(135))
    image = Image.alpha_composite(image.convert("RGBA"), glow)

    sea = Image.new("RGBA", (WIDTH, HEIGHT), (0, 0, 0, 0))
    sd = ImageDraw.Draw(sea)
    layers = [
        (685, 36, 0.3, (15, 74, 101, 115)),
        (745, 41, 1.6, (13, 69, 99, 155)),
        (830, 38, 2.5, (8, 55, 83, 185)),
        (920, 30, 3.5, (6, 44, 70, 222)),
    ]
    for level, size, phase, fill in layers:
        points = [(x, round(wave(x, level, size, phase))) for x in range(-8, WIDTH + 10, 5)]
        sd.polygon(points + [(WIDTH, HEIGHT), (0, HEIGHT)], fill=fill)
        sd.line(points, fill=(99, 200, 221, 22), width=2)

    rng = random.Random(17)
    for index in range(27):
        level = 686 + index * 14
        phase = 0.2 + index * 0.20
        size = 32 - index * 0.38
        points = [(x, round(wave(x, level, size, phase))) for x in range(-8, WIDTH + 10, 6)]
        alpha = max(9, 47 - index)
        sd.line(points, fill=(99, 202, 226, alpha), width=2 if index % 5 == 0 else 1)
    for _ in range(115):
        x = rng.randrange(50, WIDTH - 50)
        y = rng.randrange(630, HEIGHT - 60)
        if rng.random() < 0.65:
            sd.line((x, y, x + rng.randrange(8, 36), y), fill=(118, 209, 225, rng.randrange(8, 32)), width=1)

    image = Image.alpha_composite(image, sea).convert("RGB")
    OUT.parent.mkdir(parents=True, exist_ok=True)
    image.save(OUT, optimize=True)
    print(OUT)


if __name__ == "__main__":
    main()
