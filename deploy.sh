#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=tools/lib/common.sh
source "$ROOT_DIR/tools/lib/common.sh"

ASSUME_YES=false
RUN_BUILD=false
CLEAN_TARGET=true
SERVE=false
PORT="8080"
SOURCE_DIR="$ROOT_DIR/.build/web"
TARGET_DIR="$ROOT_DIR/.deployment/site"

print_help() {
  cat <<'USAGE'
Deploy built game assets into a local deployment directory.

Usage:
  ./deploy.sh [options]

Options:
  --build             Run build.sh before deployment.
  --source <dir>      Build source directory (default: .build/web).
  --target <dir>      Deployment directory (default: .deployment/site).
  --no-clean          Keep existing target contents.
  --serve             Start a local HTTP server after deployment.
  --port <port>       Port for --serve (default: 8080).
  --yes               Bypass interactive prompts.
  --help              Show this help text.

Examples:
  ./deploy.sh --build
  ./deploy.sh --source .build/web --target .deployment/site --yes
  ./deploy.sh --build --serve --port 9000
USAGE
}

while (($#)); do
  case "$1" in
    --build)
      RUN_BUILD=true
      shift
      ;;
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
    --no-clean)
      CLEAN_TARGET=false
      shift
      ;;
    --serve)
      SERVE=true
      shift
      ;;
    --port)
      [ "$#" -ge 2 ] || die "Missing value for --port."
      PORT="$2"
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
require_command cp
require_command find
require_command wc
log_done "System utilities are available."

if [ "$RUN_BUILD" = true ]; then
  log_step "Running build step before deployment"
  if [ "$ASSUME_YES" = true ]; then
    "$ROOT_DIR/build.sh" --yes
  else
    "$ROOT_DIR/build.sh"
  fi
  log_done "Build step completed."
fi

if [ ! -d "$SOURCE_DIR" ]; then
  die "Build source not found at '$SOURCE_DIR'. Run './build.sh' first or pass --build."
fi

if [ "$CLEAN_TARGET" = true ] && [ -d "$TARGET_DIR" ]; then
  confirm_or_exit "Delete existing deployment output at '$TARGET_DIR'?" "$ASSUME_YES"
  log_step "Cleaning existing deployment directory"
  rm -rf "$TARGET_DIR"
  log_done "Deployment directory cleaned."
elif [ "$CLEAN_TARGET" != true ] && [ -d "$TARGET_DIR" ]; then
  confirm_or_exit "Deployment may overwrite existing files in '$TARGET_DIR'. Continue?" "$ASSUME_YES"
fi

log_step "Copying build output to deployment directory"
mkdir -p "$TARGET_DIR"
cp -R "$SOURCE_DIR"/. "$TARGET_DIR"/
FILE_COUNT="$(find "$TARGET_DIR" -type f | wc -l | tr -d ' ')"
log_done "Deployment completed: $TARGET_DIR ($FILE_COUNT files)."

if [ "$SERVE" = true ]; then
  log_step "Starting local deployment server"
  require_command python3
  log_info "Serving '$TARGET_DIR' on http://127.0.0.1:$PORT"
  python3 -m http.server "$PORT" --directory "$TARGET_DIR"
fi
