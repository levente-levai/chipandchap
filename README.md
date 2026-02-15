# Chip&Chap

Chip&Chap is a minimal single-screen platformer built with Phaser 3.

## Current Scope
- One playable room scene (`TheRoom`).
- Placeholder graphics only (concept art is not integrated at runtime yet).
- Local-first build and deployment pipeline.

## Repository Structure
- `src/`: game source code.
- `tools/`: workflow tooling scripts.
- `docs/`: project documentation.
- `assets/concept/art/`: original concept art.
- `.build/`: generated build artifacts (gitignored).
- `.deployment/`: generated deployment output (gitignored).

## Quick Start
```bash
./dev.sh --install
```

## Build
```bash
./build.sh --install --run-unit-tests
```

## Local Deployment
```bash
./deploy.sh --build --serve
```

## Docker Build/Deploy
```bash
docker compose -f docker/compose.yml run --rm builder
docker compose -f docker/compose.yml up web
```

Optional immutable nginx image:
```bash
docker compose -f docker/compose.yml --profile image up --build web-image
```

## Tests
```bash
npm run test:unit
npm run test:e2e
```
