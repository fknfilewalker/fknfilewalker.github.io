#!/usr/bin/env bash
# Render a video that pans right -> left through a wide image while zooming in
# and drifting toward the top of the image. Uses zoompan, which scales every
# frame to one fixed output size, so all frames are guaranteed to have
# identical dimensions.
#
# Usage: ./make_scroll_video.sh [input.jpg] [duration_s] [fps] [out_size] [zoom_factor] [pan_frac]
#   out_size: either a width (height = full image height), e.g. "1920",
#             or an explicit WxH, e.g. "400x400"
set -euo pipefail

INPUT="${1:-swr_lod_msaa0_filter_ao2.jpg}"
DURATION="${2:-10}"
FPS="${3:-60}"
OUT_SIZE="${4:-1920}"
ZOOM="${5:-2}"         # zoom the slow ramp would reach after DURATION seconds
PAN_FRAC="${6:-0.5}"   # fraction of DURATION for the pan to reach the left
                       # edge — the video STOPS there, so the actual clip
                       # length is DURATION * PAN_FRAC seconds

IFS=, read -r IMG_W IMG_H < <(ffprobe -v error -select_streams v:0 \
  -show_entries stream=width,height -of "csv=p=0" "$INPUT")

if [[ "$OUT_SIZE" == *x* ]]; then
  OUT_W="${OUT_SIZE%x*}"; OUT_H="${OUT_SIZE#*x}"
else
  OUT_W="$OUT_SIZE"; OUT_H=$(( IMG_H / 2 * 2 ))  # even for yuv420p
fi

# zoompan's viewport always has the input's aspect ratio, so pad the image
# vertically until input aspect == output aspect; then no frame is distorted.
PAD_H=$(( IMG_W * OUT_H / OUT_W ))
PAD_H=$(( PAD_H < IMG_H ? IMG_H : PAD_H )); PAD_H=$(( (PAD_H + 1) / 2 * 2 ))
PAD_TOP=$(( (PAD_H - IMG_H) / 2 ))               # image centered in padding

# Z0: zoom at which the viewport height equals the image height (start: full
# image visible top-to-bottom). Z1: Z0 * ZOOM at the end.
Z0=$(awk -v p="$PAD_H" -v h="$IMG_H" 'BEGIN{printf "%.6f", p/h}')
Z1=$(awk -v z="$Z0" -v f="$ZOOM" 'BEGIN{printf "%.6f", z*f}')

FRAMES=$(( DURATION * FPS ))          # nominal zoom timeline (sets zoom speed)
LAST=$(( FRAMES - 1 ))
PAN_LAST=$(awk -v l="$LAST" -v f="$PAN_FRAC" 'BEGIN{printf "%d", l*f}')
OUT_FRAMES=$(( PAN_LAST + 1 ))        # video ends when the left edge is hit

OUTPUT="${INPUT%.*}_scroll.mp4"

# Per output frame (on = 0..PAN_LAST):
#   z: slow ramp paced against the FULL nominal duration (LAST); since the
#      video stops at PAN_LAST, only part of the ramp is seen
#   x: (iw - iw/zoom) -> 0 by frame PAN_LAST (fast pan); the video ends
#      exactly when the left edge is reached
#   y: pinned to the top of the real image content; as the viewport shrinks
#      its bottom edge rises, so the view drifts upward
ffmpeg -y -i "$INPUT" \
  -vf "pad=w=iw:h=${PAD_H}:x=0:y=${PAD_TOP},zoompan=\
z='${Z0}+(${Z1}-${Z0})*on/${LAST}':\
x='(iw-iw/zoom)*(1-on/${PAN_LAST})':\
y='${PAD_TOP}':\
d=${OUT_FRAMES}:s=${OUT_W}x${OUT_H}:fps=${FPS}" \
  -c:v libx264 -pix_fmt yuv420p -crf 18 -movflags +faststart "$OUTPUT"

CLIP_S=$(awk -v d="$DURATION" -v f="$PAN_FRAC" 'BEGIN{printf "%.1f", d*f}')
echo "Wrote $OUTPUT (${OUT_W}x${OUT_H}, ${CLIP_S}s @ ${FPS}fps)"
