#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=tools/lib/common.sh
source "$ROOT_DIR/tools/lib/common.sh"

ASSUME_YES=false
INSTALL_DEPS=false
RUN_UNIT_TESTS=false
CLEAN_OUTPUT=true
OUTPUT_DIR="$ROOT_DIR/.build/web"

print_help() {
  cat <<'USAGE'
Build the game for web distribution.

Usage:
  ./build.sh [options]

Options:
  --install             Run npm install before building.
  --run-unit-tests      Run unit tests before building.
  --no-clean            Keep existing output directory contents.
  --output <dir>        Output directory (default: .build/web).
  --yes                 Bypass interactive prompts.
  --help                Show this help text.

Examples:
  ./build.sh
  ./build.sh --install --run-unit-tests
  ./build.sh --output .build/local-web --yes
USAGE
}

while (($#)); do
  case "$1" in
    --install)
      INSTALL_DEPS=true
      shift
      ;;
    --run-unit-tests)
      RUN_UNIT_TESTS=true
      shift
      ;;
    --no-clean)
      CLEAN_OUTPUT=false
      shift
      ;;
    --output)
      [ "$#" -ge 2 ] || die "Missing value for --output."
      OUTPUT_DIR="$(resolve_path "$ROOT_DIR" "$2")"
      shift 2
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
require_command node
require_command npm
log_done "Node and npm are available."

if [ "$INSTALL_DEPS" = true ]; then
  log_step "Installing dependencies"
  npm install
  log_done "Dependencies installed."
elif [ ! -d "$ROOT_DIR/node_modules" ]; then
  die "Dependencies not found. Run './build.sh --install' or 'npm install'."
fi

if [ "$RUN_UNIT_TESTS" = true ]; then
  log_step "Running unit tests"
  npm run test:unit
  log_done "Unit tests passed."
fi

if [ "$CLEAN_OUTPUT" = true ] && [ -d "$OUTPUT_DIR" ]; then
  confirm_or_exit "Delete existing build output at '$OUTPUT_DIR'?" "$ASSUME_YES"
  log_step "Cleaning existing output"
  rm -rf "$OUTPUT_DIR"
  log_done "Output directory cleaned."
elif [ "$CLEAN_OUTPUT" != true ] && [ -d "$OUTPUT_DIR" ]; then
  confirm_or_exit "Build may overwrite existing files in '$OUTPUT_DIR'. Continue?" "$ASSUME_YES"
fi

log_step "Building web bundle"
mkdir -p "$OUTPUT_DIR"
npm run build:web -- --outDir "$OUTPUT_DIR"
log_done "Build completed: $OUTPUT_DIR"
