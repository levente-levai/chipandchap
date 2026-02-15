# Development

## Prerequisites
- Node.js 20+
- npm 10+

## Main Commands
- `./dev.sh --install` to install dependencies and start the local dev server.
- `./build.sh --install --run-unit-tests` to run unit tests and build to `.build/web`.
- `./deploy.sh --build --serve` to deploy to `.deployment/site` and serve locally.
- `docker compose -f docker/compose.yml run --rm builder` to build/deploy in a reproducible container.
- `docker compose -f docker/compose.yml up web` to serve `.deployment/site` with nginx.
- `./tools/workflow/extract-chip.sh --source assets/working/art/chip.sprite-sheet.2.png --overwrite --yes` to preprocess and normalize Chip animation frames.

## Tests
- Unit tests: `npm run test:unit`
- E2E tests: `npm run test:e2e`
