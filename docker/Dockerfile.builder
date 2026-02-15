FROM node:20-bookworm-slim

WORKDIR /workspace
ENV CI=true

# Default command mirrors the repository build/deploy flow.
CMD ["bash", "-lc", "npm ci && ./build.sh --yes --run-unit-tests && ./deploy.sh --yes"]
