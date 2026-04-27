#!/bin/bash
docker run --rm node:20-alpine sh -c "npm install -g opencode-ai && ls -l /usr/local/lib/node_modules/opencode-ai/bin/ && /usr/local/lib/node_modules/opencode-ai/bin/.opencode --version" || echo "Alpine failed"
docker run --rm node:20-slim sh -c "npm install -g opencode-ai && /usr/local/lib/node_modules/opencode-ai/bin/.opencode --version" || echo "Slim failed"
