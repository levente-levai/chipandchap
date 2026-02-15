#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
# shellcheck source=tools/lib/common.sh
source "$ROOT_DIR/tools/lib/common.sh"

ASSUME_YES=false
OVERWRITE=false
SOURCE_PATH_DEFAULT="$ROOT_DIR/assets/working/art/chip.sprite-sheet.png"
if [ -f "$ROOT_DIR/assets/working/art/chip.sprite-sheet.2.png" ]; then
  SOURCE_PATH_DEFAULT="$ROOT_DIR/assets/working/art/chip.sprite-sheet.2.png"
fi
SOURCE_PATH="$SOURCE_PATH_DEFAULT"
OUTPUT_DIR="$ROOT_DIR/assets/processed/chip"
SHEET_NAME="chip.frames.png"
META_NAME="chip.frames.json"
CLEANED_NAME="chip.cleaned.png"
CELL_WIDTH=208
CELL_HEIGHT=240
IDLE_COUNT=2
RUN_COUNT=6
JUMP_COUNT=4

print_help() {
  cat <<'USAGE'
Extract and normalize Chip animation frames from a sprite sheet.

This workflow:
- Removes checkerboard background to true transparency.
- Removes long separator lines from the source sheet.
- Detects sprite components and extracts Idle/Run/Jump rows.
- Normalizes each frame onto a fixed-size transparent cell.
- Outputs a Phaser-friendly spritesheet and metadata JSON.

Usage:
  ./tools/workflow/extract-chip.sh [options]

Options:
  --source <file>         Input sprite sheet (default: assets/working/art/chip.sprite-sheet.2.png if present, otherwise chip.sprite-sheet.png).
  --output-dir <dir>      Output directory (default: assets/processed/chip).
  --sheet-name <file>     Output spritesheet filename (default: chip.frames.png).
  --meta-name <file>      Output metadata filename (default: chip.frames.json).
  --cleaned-name <file>   Output cleaned-source preview filename (default: chip.cleaned.png).
  --cell-width <px>       Cell width in pixels (default: 208).
  --cell-height <px>      Cell height in pixels (default: 240).
  --idle-count <n>        Idle frame count to export from top row (default: 2).
  --run-count <n>         Run frame count to export from middle row (default: 6).
  --jump-count <n>        Jump frame count to export from bottom row (default: 4).
  --overwrite             Allow replacing existing output files.
  --yes                   Bypass interactive confirmations.
  --help                  Show this help text.

Examples:
  ./tools/workflow/extract-chip.sh
  ./tools/workflow/extract-chip.sh --source assets/working/art/chip.sprite-sheet.2.png --overwrite
  ./tools/workflow/extract-chip.sh --cell-width 144 --cell-height 208 --overwrite --yes
USAGE
}

while (($#)); do
  case "$1" in
    --source)
      [ "$#" -ge 2 ] || die "Missing value for --source."
      SOURCE_PATH="$(resolve_path "$ROOT_DIR" "$2")"
      shift 2
      ;;
    --output-dir)
      [ "$#" -ge 2 ] || die "Missing value for --output-dir."
      OUTPUT_DIR="$(resolve_path "$ROOT_DIR" "$2")"
      shift 2
      ;;
    --sheet-name)
      [ "$#" -ge 2 ] || die "Missing value for --sheet-name."
      SHEET_NAME="$2"
      shift 2
      ;;
    --meta-name)
      [ "$#" -ge 2 ] || die "Missing value for --meta-name."
      META_NAME="$2"
      shift 2
      ;;
    --cleaned-name)
      [ "$#" -ge 2 ] || die "Missing value for --cleaned-name."
      CLEANED_NAME="$2"
      shift 2
      ;;
    --cell-width)
      [ "$#" -ge 2 ] || die "Missing value for --cell-width."
      CELL_WIDTH="$2"
      shift 2
      ;;
    --cell-height)
      [ "$#" -ge 2 ] || die "Missing value for --cell-height."
      CELL_HEIGHT="$2"
      shift 2
      ;;
    --idle-count)
      [ "$#" -ge 2 ] || die "Missing value for --idle-count."
      IDLE_COUNT="$2"
      shift 2
      ;;
    --run-count)
      [ "$#" -ge 2 ] || die "Missing value for --run-count."
      RUN_COUNT="$2"
      shift 2
      ;;
    --jump-count)
      [ "$#" -ge 2 ] || die "Missing value for --jump-count."
      JUMP_COUNT="$2"
      shift 2
      ;;
    --overwrite)
      OVERWRITE=true
      shift
      ;;
    --yes)
      ASSUME_YES=true
      shift
      ;;
    --help)
      print_help
      exit 0
      ;;
    *)
      die "Unknown option: $1. Use --help for usage."
      ;;
  esac
done

log_step "Checking prerequisites"
require_command python3
log_done "python3 is available."

log_step "Validating input"
[ -f "$SOURCE_PATH" ] || die "Source file '$SOURCE_PATH' does not exist."
log_done "Source file found: $SOURCE_PATH"

log_step "Preparing output paths"
mkdir -p "$OUTPUT_DIR"
SHEET_PATH="$OUTPUT_DIR/$SHEET_NAME"
META_PATH="$OUTPUT_DIR/$META_NAME"
CLEANED_PATH="$OUTPUT_DIR/$CLEANED_NAME"
log_info "Sheet output: $SHEET_PATH"
log_info "Metadata output: $META_PATH"
log_info "Cleaned preview output: $CLEANED_PATH"
log_done "Output directory is ready."

if [ -e "$SHEET_PATH" ] || [ -e "$META_PATH" ] || [ -e "$CLEANED_PATH" ]; then
  if [ "$OVERWRITE" != true ]; then
    die "Output file(s) already exist. Re-run with --overwrite to replace them."
  fi
  confirm_or_exit "Replace existing extraction outputs in '$OUTPUT_DIR'?" "$ASSUME_YES"
fi

log_step "Extracting normalized Chip frames"
python3 - "$SOURCE_PATH" "$SHEET_PATH" "$META_PATH" "$CLEANED_PATH" "$CELL_WIDTH" "$CELL_HEIGHT" "$IDLE_COUNT" "$RUN_COUNT" "$JUMP_COUNT" <<'PY'
import json
import sys
from collections import deque
from pathlib import Path

from PIL import Image

(
    source_path,
    sheet_path,
    meta_path,
    cleaned_path,
    cell_width,
    cell_height,
    idle_count,
    run_count,
    jump_count,
) = sys.argv[1:]

cell_width = int(cell_width)
cell_height = int(cell_height)
idle_count = int(idle_count)
run_count = int(run_count)
jump_count = int(jump_count)

img = Image.open(source_path).convert("RGBA")
width, height = img.size
pixels = img.load()


def grayscale_value(r, g, b):
    return (r + g + b) // 3


def is_probable_checker_pixel(r, g, b, a):
    if a == 0:
        return False
    if abs(r - g) > 8 or abs(g - b) > 8:
        return False

    gv = grayscale_value(r, g, b)
    return 55 <= gv <= 235


# Flood-fill from the borders so only background-connected checker pixels get removed.
visited = bytearray(width * height)
queue = deque()


def enqueue_if_checker(x, y):
    if x < 0 or y < 0 or x >= width or y >= height:
        return
    idx = y * width + x
    if visited[idx]:
        return
    visited[idx] = 1
    if is_probable_checker_pixel(*pixels[x, y]):
        queue.append((x, y))


for x in range(width):
    enqueue_if_checker(x, 0)
    enqueue_if_checker(x, height - 1)
for y in range(height):
    enqueue_if_checker(0, y)
    enqueue_if_checker(width - 1, y)

while queue:
    x, y = queue.popleft()
    r, g, b, _a = pixels[x, y]
    pixels[x, y] = (r, g, b, 0)

    enqueue_if_checker(x + 1, y)
    enqueue_if_checker(x - 1, y)
    enqueue_if_checker(x, y + 1)
    enqueue_if_checker(x, y - 1)


# Remove long near-black separator lines (e.g. generated guide lines).
rows_to_clear = []
y = 0
while y < height:
    coverage = 0
    for x in range(width):
        r, g, b, a = pixels[x, y]
        if a > 0 and r < 45 and g < 45 and b < 45:
            coverage += 1

    if coverage >= int(width * 0.80):
        y_start = y
        while y < height:
            coverage_inner = 0
            for x in range(width):
                r, g, b, a = pixels[x, y]
                if a > 0 and r < 45 and g < 45 and b < 45:
                    coverage_inner += 1
            if coverage_inner < int(width * 0.70):
                break
            y += 1
        y_end = y - 1
        if (y_end - y_start + 1) <= 5:
            rows_to_clear.append((y_start, y_end))
    y += 1

for y_start, y_end in rows_to_clear:
    for yy in range(y_start, y_end + 1):
        for x in range(width):
            r, g, b, a = pixels[x, yy]
            if a > 0 and r < 60 and g < 60 and b < 60:
                pixels[x, yy] = (r, g, b, 0)


# Connected component detection on non-transparent pixels.
visited = bytearray(width * height)
components = []

for y in range(height):
    for x in range(width):
        idx = y * width + x
        if visited[idx]:
            continue
        visited[idx] = 1
        if pixels[x, y][3] == 0:
            continue

        queue = deque([(x, y)])
        count = 0
        min_x = x
        min_y = y
        max_x = x
        max_y = y

        while queue:
            cx, cy = queue.popleft()
            count += 1
            if cx < min_x:
                min_x = cx
            if cy < min_y:
                min_y = cy
            if cx > max_x:
                max_x = cx
            if cy > max_y:
                max_y = cy

            for ny in (cy - 1, cy, cy + 1):
                if ny < 0 or ny >= height:
                    continue
                row_offset = ny * width
                for nx in (cx - 1, cx, cx + 1):
                    if nx < 0 or nx >= width:
                        continue
                    nidx = row_offset + nx
                    if visited[nidx]:
                        continue
                    visited[nidx] = 1
                    if pixels[nx, ny][3] > 0:
                        queue.append((nx, ny))

        # Ignore tiny artifacts.
        if count >= 1200:
            components.append(
                {
                    "count": count,
                    "min_x": min_x,
                    "min_y": min_y,
                    "max_x": max_x,
                    "max_y": max_y,
                    "center_y": (min_y + max_y) / 2,
                }
            )

if len(components) < (idle_count + run_count + jump_count):
    raise SystemExit(
        f"Extraction failed: detected only {len(components)} valid components. "
        f"Need at least {idle_count + run_count + jump_count}."
    )

components.sort(key=lambda c: c["center_y"])
rows = []
for comp in components:
    placed = False
    for row in rows:
        if abs(comp["center_y"] - row["mean_center_y"]) <= 95:
            row["items"].append(comp)
            row["mean_center_y"] = sum(i["center_y"] for i in row["items"]) / len(row["items"])
            placed = True
            break
    if not placed:
        rows.append({"mean_center_y": comp["center_y"], "items": [comp]})

rows.sort(key=lambda r: r["mean_center_y"])
if len(rows) < 3:
    raise SystemExit(f"Extraction failed: expected at least 3 animation rows, found {len(rows)}.")

selected_rows = rows[:3]
for row in selected_rows:
    row["items"].sort(key=lambda i: i["min_x"])

idle_frames = selected_rows[0]["items"][:idle_count]
run_frames = selected_rows[1]["items"][:run_count]
jump_frames = selected_rows[2]["items"][:jump_count]

if len(idle_frames) < idle_count:
    raise SystemExit(f"Extraction failed: idle row has {len(idle_frames)} frames, need {idle_count}.")
if len(run_frames) < run_count:
    raise SystemExit(f"Extraction failed: run row has {len(run_frames)} frames, need {run_count}.")
if len(jump_frames) < jump_count:
    raise SystemExit(f"Extraction failed: jump row has {len(jump_frames)} frames, need {jump_count}.")


def frame_to_cell(comp):
    x1 = comp["min_x"]
    y1 = comp["min_y"]
    x2 = comp["max_x"] + 1
    y2 = comp["max_y"] + 1

    sprite = img.crop((x1, y1, x2, y2))
    fw, fh = sprite.size
    if fw > cell_width or fh > cell_height:
        raise SystemExit(
            f"Extraction failed: frame {fw}x{fh} exceeds cell size {cell_width}x{cell_height}. "
            "Increase --cell-width/--cell-height."
        )

    cell = Image.new("RGBA", (cell_width, cell_height), (0, 0, 0, 0))
    baseline_y = cell_height - 6
    dest_x = (cell_width - fw) // 2
    dest_y = baseline_y - fh
    if dest_y < 0:
        dest_y = 0

    cell.alpha_composite(sprite, (dest_x, dest_y))
    return cell


idle_cells = [frame_to_cell(comp) for comp in idle_frames]
run_cells = [frame_to_cell(comp) for comp in run_frames]
jump_cells = [frame_to_cell(comp) for comp in jump_frames]

columns = max(idle_count, run_count, jump_count)
row_count = 3
sheet = Image.new("RGBA", (columns * cell_width, row_count * cell_height), (0, 0, 0, 0))


def paste_row(cells, row_idx):
    for col_idx, frame_image in enumerate(cells):
        sheet.alpha_composite(frame_image, (col_idx * cell_width, row_idx * cell_height))


paste_row(idle_cells, 0)
paste_row(run_cells, 1)
paste_row(jump_cells, 2)

# Save outputs.
Path(sheet_path).parent.mkdir(parents=True, exist_ok=True)
img.save(cleaned_path)
sheet.save(sheet_path)

animations = {
    "idle": [0 + i for i in range(idle_count)],
    "run": [columns + i for i in range(run_count)],
    "jump": [2 * columns + i for i in range(jump_count)],
}

metadata = {
    "source": str(Path(source_path).as_posix()),
    "frameWidth": cell_width,
    "frameHeight": cell_height,
    "columns": columns,
    "rows": row_count,
    "animations": animations,
    "notes": {
        "rowOrder": ["idle", "run", "jump"],
        "normalization": "centered horizontally with fixed baseline",
    },
}

with open(meta_path, "w", encoding="utf-8") as f:
    json.dump(metadata, f, indent=2)
    f.write("\n")

print(f"[PY] Source size: {width}x{height}")
print(f"[PY] Detected components: {len(components)}")
print(f"[PY] Rows used: idle={len(idle_frames)} run={len(run_frames)} jump={len(jump_frames)}")
print(f"[PY] Output sheet: {sheet_path}")
print(f"[PY] Output metadata: {meta_path}")
print(f"[PY] Cleaned preview: {cleaned_path}")
PY
log_done "Chip extraction completed successfully."
