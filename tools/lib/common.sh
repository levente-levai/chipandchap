#!/usr/bin/env bash

set -euo pipefail

log_info() {
  printf '[INFO] %s\n' "$*"
}

log_step() {
  printf '\n[STEP] %s\n' "$*"
}

log_done() {
  printf '[DONE] %s\n' "$*"
}

log_warn() {
  printf '[WARN] %s\n' "$*"
}

log_error() {
  printf '[ERROR] %s\n' "$*" >&2
}

die() {
  log_error "$1"
  exit "${2:-1}"
}

require_command() {
  local cmd="$1"

  if ! command -v "$cmd" >/dev/null 2>&1; then
    die "Missing required command: '$cmd'. Install it and run again."
  fi
}

resolve_path() {
  local base_dir="$1"
  local path_value="$2"

  if [[ "$path_value" = /* ]]; then
    printf '%s\n' "$path_value"
  else
    printf '%s/%s\n' "$base_dir" "$path_value"
  fi
}

confirm_or_exit() {
  local prompt="$1"
  local assume_yes="${2:-false}"

  if [ "$assume_yes" = true ]; then
    log_info "Auto-confirmed by --yes: $prompt"
    return
  fi

  read -r -p "$prompt [y/N]: " answer
  case "$answer" in
    y|Y|yes|YES)
      ;;
    *)
      die "Operation canceled by user."
      ;;
  esac
}
