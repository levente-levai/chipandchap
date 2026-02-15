#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=tools/lib/common.sh
source "$ROOT_DIR/tools/lib/common.sh"

ASSUME_YES=false
INSTALL_DEPS=false
HOST="127.0.0.1"
PORT="5173"

print_help() {
  cat <<'USAGE'
Start the local development server.

Usage:
  ./dev.sh [options]

Options:
  --install        Run npm install before starting.
  --host <host>    Host interface for the dev server (default: 127.0.0.1).
  --port <port>    Port for the dev server (default: 5173).
  --yes            Bypass interactive prompts (kept for interface consistency).
  --help           Show this help text.

Examples:
  ./dev.sh
  ./dev.sh --install
  ./dev.sh --host 0.0.0.0 --port 5174
USAGE
}

while (($#)); do
  case "$1" in
    --install)
      INSTALL_DEPS=true
      shift
      ;;
    --host)
      [ "$#" -ge 2 ] || die "Missing value for --host."
      HOST="$2"
      shift 2
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
require_command node
require_command npm
log_done "Node and npm are available."

if [ "$INSTALL_DEPS" = true ]; then
  log_step "Installing dependencies"
  npm install
  log_done "Dependencies installed."
elif [ ! -d "$ROOT_DIR/node_modules" ]; then
  die "Dependencies not found. Run './dev.sh --install' or 'npm install'."
fi

log_step "Starting development server"
log_info "Host: $HOST"
log_info "Port: $PORT"
log_info "Bypass prompts: $ASSUME_YES"
npm run dev -- --host "$HOST" --port "$PORT"
