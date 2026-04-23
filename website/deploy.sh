#!/usr/bin/env bash
# One-command deploy to Cloudflare Pages.
#
# Rebuilds the site from the latest roll data, then pushes website/dist to
# the Cloudflare Pages project. Override the project name with CF_PROJECT.
#
# Requirements:
#   - uv installed (for the build)
#   - wrangler CLI installed and logged in (for the deploy)
#     npm install -g wrangler && wrangler login
#   - ghostscript (optional; compresses PDFs below Pages' 25 MiB limit)
#     brew install ghostscript

set -euo pipefail

PROJECT="${CF_PROJECT:-c-opus}"
REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"

echo "→ Rebuilding site..."
cd "$REPO_ROOT"
uv run python website/build.py

echo
echo "→ Checking Wrangler..."
if ! command -v wrangler >/dev/null 2>&1; then
    echo "  ! wrangler not found. Install with: npm install -g wrangler"
    echo "    Then authenticate: wrangler login"
    exit 1
fi

echo "→ Deploying to Cloudflare Pages project: $PROJECT"
wrangler pages deploy website/dist --project-name "$PROJECT"

echo
echo "Done. Check the URL printed above for the deployment."
