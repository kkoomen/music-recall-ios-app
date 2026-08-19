#!/usr/bin/env bash
#
# make-demo-strip.sh — combine three screenshots into one demo strip.
#
# Places demo1.png, demo2.png, demo3.png side by side on an off-white
# canvas with padding around the group, gaps between the images, and a
# soft black drop shadow (x=0, y=0) around each screenshot.
#
# Usage:
#   ./scripts/make-demo-strip.sh [demo1.png] [demo2.png] [demo3.png] [demo.png]
#
# Defaults: demo1.png demo2.png demo3.png -> demo.png (repo root).
#
# Tunables: BG (canvas color), PAD (outer padding), GAP (gap between
# images), SHADOW_OPACITY (percent), SHADOW_SIGMA (blur radius).

set -euo pipefail

BG="#F5F4EF"
PAD=120
GAP=60
SHADOW_OPACITY=35
SHADOW_SIGMA=40
# Transparent margin around each image giving the shadow room to render.
# Must comfortably exceed ~4x SHADOW_SIGMA.
SHADOW_BORDER=170

IMAGES=("${1:-demo1.png}" "${2:-demo2.png}" "${3:-demo3.png}")
OUT="${4:-demo.png}"

for img in "${IMAGES[@]}"; do
  if [[ ! -f "$img" ]]; then
    echo "error: missing input image: $img" >&2
    exit 1
  fi
done

W=$(magick identify -format "%w" "${IMAGES[0]}")
H=$(magick identify -format "%h" "${IMAGES[0]}")
for img in "${IMAGES[@]:1}"; do
  w=$(magick identify -format "%w" "$img")
  h=$(magick identify -format "%h" "$img")
  if [[ "$w" != "$W" || "$h" != "$H" ]]; then
    echo "error: $img is ${w}x${h}; expected ${W}x${H} like ${IMAGES[0]}" >&2
    exit 1
  fi
done

OUT_W=$((2 * PAD + 3 * W + 2 * GAP))
OUT_H=$((2 * PAD + H))

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

# Render each image with its drop shadow onto a transparent canvas of
# W+2B x H+2B (the shadow is generated from the image's alpha channel).
for i in 0 1 2; do
  magick "${IMAGES[$i]}" -bordercolor none -border "$SHADOW_BORDER" \
    \( +clone -background black -shadow "${SHADOW_OPACITY}x${SHADOW_SIGMA}+0+0" \) \
    +swap -background none -layers merge +repage \
    "$tmpdir/s$i.png"
done

# The shadowed canvas holds the screenshot plus SHADOW_BORDER of
# transparent margin; IM7's -shadow operator additionally pads the
# canvas by 2x SHADOW_SIGMA per side while rendering the blur, so the
# screenshot's top-left sits at SHADOW_BORDER + 2x SHADOW_SIGMA inside
# the canvas. Compositing at PAD - that inset places the screenshot
# exactly PAD px from the canvas edge on all four sides (the faintest
# shadow sliver past PAD is clipped). The gaps between screenshots stay
# GAP px wide.
SHADOW_INSET=$((SHADOW_BORDER + 2 * SHADOW_SIGMA))
OFFSET=$((PAD - SHADOW_INSET))

magick -size "${OUT_W}x${OUT_H}" "xc:${BG}" \
  \( "$tmpdir/s0.png" \) -geometry "+${OFFSET}+${OFFSET}" -composite \
  \( "$tmpdir/s1.png" \) -geometry "+$((OFFSET + W + GAP))+${OFFSET}" -composite \
  \( "$tmpdir/s2.png" \) -geometry "+$((OFFSET + 2 * (W + GAP)))+${OFFSET}" -composite \
  -depth 8 -strip \
  "$OUT"

echo "wrote $OUT (${OUT_W}x${OUT_H}) from ${IMAGES[0]}, ${IMAGES[1]}, ${IMAGES[2]}"
