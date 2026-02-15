#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
# shellcheck source=tools/lib/common.sh
source "$ROOT_DIR/tools/lib/common.sh"

ASSUME_YES=false
OVERWRITE=false
SOURCE_DIR="$ROOT_DIR/assets/concept/art"
TARGET_DIR="$ROOT_DIR/assets/working/art"

print_help() {
  cat <<'USAGE'
Prepare concept art files for a working asset directory.

Usage:
  ./tools/workflow/prepare-assets.sh [options]

Options:
  --source <dir>      Source concept art directory (default: assets/concept/art).
  --target <dir>      Destination working directory (default: assets/working/art).
  --overwrite         Overwrite files that already exist at destination.
  --yes               Bypass interactive prompts.
  --help              Show this help text.

Examples:
  ./tools/workflow/prepare-assets.sh
  ./tools/workflow/prepare-assets.sh --target assets/working/concepts
  ./tools/workflow/prepare-assets.sh --overwrite --yes
USAGE
}

while (($#)); do
  case "$1" in
    --source)
      [ "$#" -ge 2 ] || die "Missing value for --source."
      SOURCE_DIR="$(resolve_path "$ROOT_DIR" "$2")"
      shift 2
      ;;
    --target)
      [ "$#" -ge 2 ] || die "Missing value for --target."
      TARGET_DIR="$(resolve_path "$ROOT_DIR" "$2")"
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

log_step "Validating source directory"
if [ ! -d "$SOURCE_DIR" ]; then
  die "Source directory '$SOURCE_DIR' does not exist."
fi
log_done "Source exists."

log_step "Preparing destination directory"
mkdir -p "$TARGET_DIR"
log_done "Destination ready: $TARGET_DIR"

if [ "$OVERWRITE" = true ]; then
  confirm_or_exit "Overwrite existing files in '$TARGET_DIR' when needed?" "$ASSUME_YES"
fi

log_step "Copying concept art files"
COPIED=0
SKIPPED=0
shopt -s nullglob
for src_file in "$SOURCE_DIR"/*; do
  file_name="$(basename "$src_file")"
  dest_file="$TARGET_DIR/$file_name"

  if [ -e "$dest_file" ] && [ "$OVERWRITE" != true ]; then
    log_warn "Skipping existing file (use --overwrite to replace): $dest_file"
    SKIPPED=$((SKIPPED + 1))
    continue
  fi

  cp "$src_file" "$dest_file"
  COPIED=$((COPIED + 1))
done
shopt -u nullglob
log_done "Asset prep completed. Copied: $COPIED, Skipped: $SKIPPED"
