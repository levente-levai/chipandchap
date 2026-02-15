# Docker Workflow

This directory provides a reproducible build/deploy environment and a local nginx runtime.

## Files
- `docker/Dockerfile.builder`: Node-based reproducible build environment.
- `docker/compose.yml`: local builder + nginx services.
- `docker/Dockerfile.nginx`: optional immutable nginx image using `.deployment/site`.
- `docker/nginx.default.conf`: nginx server config.

## Typical Usage

1. Build and deploy artifacts in container:
```bash
docker compose -f docker/compose.yml run --rm builder
```

2. Serve host deployment output from nginx:
```bash
docker compose -f docker/compose.yml up web
```

3. Build and run immutable nginx image (optional):
```bash
docker compose -f docker/compose.yml --profile image up --build web-image
```

## Notes
- Builder writes to host `.build/` and `.deployment/` via bind mount.
- `web` serves `.deployment/site` as web root.
- `web-image` bakes `.deployment/site` into the image; run builder first.
