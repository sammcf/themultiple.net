#!/usr/bin/env bash
# Assemble the published site into _site/.
#
# The repository holds more than the site: the design system specimen, the
# harness that verifies the record strip, this script. None of that belongs on
# themultiple.net. So publishing works from a manifest — the list below is the
# site, and anything not on it is not served. New working material is unserved
# by default, which is the safe direction for a mistake to fall.
#
# The cost of a manifest is the opposite mistake: adding a page and forgetting
# to list it, which would 404 silently. The guards at the bottom catch that.
set -euo pipefail

site_root=$(cd "$(dirname "$0")/.." && pwd)
cd "$site_root"

out=${1:-_site}

fail() { echo "ERROR: $1" >&2; exit 1; }

# ---------------------------------------------------------------- the manifest

served=(
  index.html
  404.html
  styles.css
  favicon.svg
  robots.txt
  sitemap.xml
  CNAME
  .nojekyll
  fonts
  collage
  steward
  ficta
)

rm -rf "$out"
mkdir -p "$out"

for path in "${served[@]}"; do
  [[ -e "$path" ]] || fail "manifest lists $path, which does not exist"
  cp -R "$path" "$out/"
done

# ------------------------------------------------------------------ the guards

# Every page of the site must be served. A page added but not listed above would
# deploy as a hole in the site, so fail the build instead.
while IFS= read -r page; do
  rel=${page#./}
  [[ -f "$out/$rel" ]] || fail "page is not in the manifest: $rel"
done < <(find . -name '*.html' -type f \
           -not -path './.git/*' \
           -not -path './docs/*' \
           -not -path "./$out/*" | sort)

# And nothing that is not the site may reach the output. These are the specific
# things that live in this repository and must never be published.
for forbidden in docs scripts .github README.md .gitignore; do
  if [[ -e "$out/$forbidden" ]]; then fail "$forbidden must never be served"; fi
done

# Belt and braces: no shell, no markdown, no workflow YAML in the artifact.
while IFS= read -r stray; do
  fail "unservable file reached the artifact: ${stray#"$out/"}"
done < <(find "$out" -type f \( -name '*.sh' -o -name '*.md' -o -name '*.yml' \) | sort)

echo "Assembled $(find "$out" -type f | wc -l | tr -d ' ') files into $out/"
