#!/usr/bin/env python3
"""Generate legacy Android launcher PNGs from the simplified insect mark."""

from __future__ import annotations

from pathlib import Path

from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[1]
RES = ROOT / "android/app/src/main/res"
BACKGROUND = "#984061"
FOREGROUND = "#FFFFFF"
VIEWPORT = 108
SUPERSAMPLING = 4
ICON_SIZES = {
    "mipmap-mdpi/ic_launcher.png": 48,
    "mipmap-hdpi/ic_launcher.png": 72,
    "mipmap-xhdpi/ic_launcher.png": 96,
    "mipmap-xxhdpi/ic_launcher.png": 144,
    "mipmap-xxxhdpi/ic_launcher.png": 192,
}
APP_ICON_ASSET = ROOT / "assets/images/app_icon.png"
APP_ICON_SIZE = 512


def scaled(value: float, factor: float) -> int:
    return round(value * factor)


def draw_rounded_line(
    draw: ImageDraw.ImageDraw,
    points: list[tuple[float, float]],
    *,
    factor: float,
    width: float,
) -> None:
    coordinates = [(scaled(x, factor), scaled(y, factor)) for x, y in points]
    line_width = scaled(width, factor)
    radius = line_width // 2
    draw.line(coordinates, fill=FOREGROUND, width=line_width, joint="curve")
    for x, y in (coordinates[0], coordinates[-1]):
        draw.ellipse(
            (x - radius, y - radius, x + radius, y + radius),
            fill=FOREGROUND,
        )


def render_icon(size: int) -> Image.Image:
    render_size = size * SUPERSAMPLING
    factor = render_size / VIEWPORT
    image = Image.new("RGB", (render_size, render_size), BACKGROUND)
    draw = ImageDraw.Draw(image)

    draw_rounded_line(
        draw,
        [(50, 38), (47, 30), (39, 23)],
        factor=factor,
        width=4,
    )
    draw_rounded_line(
        draw,
        [(58, 38), (61, 30), (69, 23)],
        factor=factor,
        width=4,
    )

    draw.ellipse(
        tuple(scaled(value, factor) for value in (22, 33, 53, 69)),
        fill=FOREGROUND,
    )
    draw.ellipse(
        tuple(scaled(value, factor) for value in (55, 33, 86, 69)),
        fill=FOREGROUND,
    )
    draw.rounded_rectangle(
        tuple(scaled(value, factor) for value in (43, 37, 65, 84)),
        radius=scaled(11, factor),
        fill=FOREGROUND,
    )
    draw.ellipse(
        tuple(scaled(value, factor) for value in (44, 30, 64, 50)),
        fill=FOREGROUND,
    )

    return image.resize((size, size), Image.Resampling.LANCZOS)


def main() -> None:
    for relative_path, size in ICON_SIZES.items():
        output = RES / relative_path
        render_icon(size).save(output, format="PNG", optimize=True)
        print(f"Generated {output.relative_to(ROOT)} ({size}x{size})")

    APP_ICON_ASSET.parent.mkdir(parents=True, exist_ok=True)
    render_icon(APP_ICON_SIZE).save(APP_ICON_ASSET, format="PNG", optimize=True)
    print(
        f"Generated {APP_ICON_ASSET.relative_to(ROOT)} "
        f"({APP_ICON_SIZE}x{APP_ICON_SIZE})"
    )


if __name__ == "__main__":
    main()
