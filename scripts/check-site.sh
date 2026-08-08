#!/usr/bin/env bash
set -euo pipefail

site_root=$(cd "$(dirname "$0")/.." && pwd)
cd "$site_root"

required_files=(
  CNAME
  index.html
  404.html
  styles.css
  robots.txt
  sitemap.xml
  collage/index.html
  collage/guide/index.html
  collage/support/index.html
  collage/privacy/index.html
)

for file in "${required_files[@]}"; do
  if [[ ! -f "$file" ]]; then
    echo "ERROR: missing required file: $file" >&2
    exit 1
  fi
done

if [[ "$(tr -d '[:space:]' < CNAME)" != "themultiple.net" ]]; then
  echo "ERROR: CNAME must contain only themultiple.net" >&2
  exit 1
fi

while IFS= read -r file; do
  grep -q '<html lang="en">' "$file" || { echo "ERROR: $file has no English language declaration" >&2; exit 1; }
  grep -q '<meta name="viewport"' "$file" || { echo "ERROR: $file has no viewport metadata" >&2; exit 1; }
  grep -q '<title>' "$file" || { echo "ERROR: $file has no title" >&2; exit 1; }
  grep -q '<main' "$file" || { echo "ERROR: $file has no main landmark" >&2; exit 1; }
done < <(find . -name '*.html' -type f | sort)

if grep -RniE '<script|google-analytics|googletagmanager|facebook\.net' --include='*.html' .; then
  echo "ERROR: site must remain script-free and analytics-free" >&2
  exit 1
fi

grep -q 'sam@themultiple.net' collage/support/index.html
grep -q 'sam@themultiple.net' collage/privacy/index.html
grep -q 'href="collage/"' index.html
grep -q 'https://themultiple.net/collage/' collage/index.html
grep -q 'https://themultiple.net/collage/guide/' collage/guide/index.html
grep -q 'https://themultiple.net/collage/' sitemap.xml
grep -q 'https://themultiple.net/collage/guide/' sitemap.xml
grep -q 'https://themultiple.net/collage/support/' sitemap.xml
grep -q 'https://themultiple.net/collage/privacy/' sitemap.xml

echo "Static site checks passed."
