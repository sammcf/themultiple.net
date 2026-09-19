#!/usr/bin/env bash
# Build the Markdown blog, validate all source, and assemble the Pages artifact.
set -euo pipefail

site_root=$(cd "$(dirname "$0")/.." && pwd)
cd "$site_root"

out=${1:-_site}
blog_build=$(mktemp -d "${TMPDIR:-/tmp}/themultiple-blog.XXXXXX")
trap 'rm -rf "$blog_build"' EXIT

if ! command -v bundle >/dev/null 2>&1; then
  echo "ERROR: blocked: Ruby/Bundler toolchain not reachable" >&2
  exit 1
fi

bash scripts/check-site.sh
bundle exec jekyll build --source blog-src --destination "$blog_build" --trace
bash scripts/assemble-site.sh "$out" "$blog_build"
