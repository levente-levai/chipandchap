# AGENTS.md

## Purpose
This repository hosts a minimal Phaser 3 single-screen platformer and its supporting tooling.

## Repository Layout Rules
Keep concerns separated:
- `src/`: game/application source code only.
- `tools/`: workflow and utility scripts (asset prep, checks, helper tooling).
- `docs/`: project documentation.
- `assets/`: non-code assets (raw/processed art, audio, etc.).

Root-level scripts are reserved for core project operations:
- `build.sh`: project build entrypoint.
- `deploy.sh`: local deployment entrypoint.
- `dev.sh`: local development entrypoint.

Generated output must stay out of tracked source:
- Build artifacts: `.build/`
- Deployment artifacts: `.deployment/`

## Script Standards (Mandatory)
All repository scripts (`*.sh` in root or under `tools/`) must:
1. Support `--help` with:
   - Purpose
   - Typical usage
   - All flags/switches
   - Concrete examples
2. Support `--yes` (default off) to bypass all interactive confirmations.
3. Log progress in clear, explicit steps (start/completed/failure) so users can see what ran and what succeeded.
4. Emit actionable error messages that state:
   - What failed
   - Why it failed (if known)
   - How to fix or retry
5. Ask for permission before destructive actions that alter/delete non-temporary files.
6. Optionally provide finer-grained non-interactive switches (default off), e.g. `--force-clean`.

## Build and Deployment Expectations
- Build scripts write outputs under `.build/` only.
- Deployment scripts write outputs under `.deployment/` only.
- Local deployment is the first target; remote targets may be added later.

## Game Scope (Current Stage)
- Keep implementation minimal and maintainable.
- Prefer simple, explicit code over visual polish.
- Provide a single-screen platformer scene using placeholder graphics.
- Do not integrate concept art into runtime yet.
- Include unit and e2e tests for minimal functionality.
