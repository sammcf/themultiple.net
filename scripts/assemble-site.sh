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
blog_build=${2:-}

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

# Jekyll builds in isolation. Admit only its generated /blog/ tree, never its
# layouts, Markdown source, configuration, or dependency files.
if [[ -n "$blog_build" ]]; then
  [[ -d "$blog_build/blog" ]] || fail "generated blog is missing: $blog_build/blog"
  [[ -f "$blog_build/blog/index.html" ]] || fail "generated blog has no index"
  [[ -f "$blog_build/blog/feed.xml" ]] || fail "generated blog has no Atom feed"

  while IFS= read -r generated; do
    [[ "${generated#"$blog_build"/}" == blog ]] \
      || fail "Jekyll generated an unexpected top-level path: ${generated#"$blog_build"/}"
  done < <(find "$blog_build" -mindepth 1 -maxdepth 1 -print | sort)

  cp -R "$blog_build/blog" "$out/"
fi

# ------------------------------------------------------------------ the guards

# Every page of the site must be served. A page added but not listed above would
# deploy as a hole in the site, so fail the build instead.
while IFS= read -r page; do
  rel=${page#./}
  [[ -f "$out/$rel" ]] || fail "page is not in the manifest: $rel"
done < <(find . -name '*.html' -type f \
           -not -path './.git/*' \
           -not -path './blog-src/*' \
           -not -path './docs/*' \
           -not -path './_blog-build/*' \
           -not -path "./$out/*" | sort)

# And nothing that is not the site may reach the output. These are the specific
# things that live in this repository and must never be published.
for forbidden in blog-src docs scripts .github .pages.yml Gemfile Gemfile.lock README.md .gitignore; do
  if [[ -e "$out/$forbidden" ]]; then fail "$forbidden must never be served"; fi
done

# Belt and braces: no shell, no markdown, no workflow YAML in the artifact.
while IFS= read -r stray; do
  fail "unservable file reached the artifact: ${stray#"$out/"}"
done < <(find "$out" -type f \( -name '*.sh' -o -name '*.md' -o -name '*.yml' \) | sort)

# Validate Jekyll's output rather than trusting that valid source necessarily
# produced a valid public page. Raw HTML in Markdown must not weaken the site's
# no-script and no-third-party-request promises.
if [[ -d "$out/blog" ]]; then
  while IFS= read -r page; do
    rg -qF '<html lang="en">' "$page" || fail "$page has no English language declaration"
    rg -qF 'rel="canonical"' "$page" || fail "$page has no canonical URL"
    rg -qF '<main' "$page" || fail "$page has no main landmark"
    rg -qF '/styles.css' "$page" || fail "$page does not load the stylesheet"
    rg -qF '/favicon.svg' "$page" || fail "$page does not load the favicon"
    rg -qF 'skip-link' "$page" || fail "$page has no skip link"
  done < <(find "$out/blog" -name '*.html' -type f | sort)

  if rg -ni '<script' "$out/blog"; then
    fail "generated blog must remain script-free"
  fi
  if rg -niP "<(?:audio|iframe|img|source|video)\\b[^>]+\\b(?:poster|src)=['\\\"][[:space:]]*https?://" "$out/blog"; then
    fail "generated blog must not load third-party media"
  fi
fi

echo "Assembled $(find "$out" -type f | wc -l | tr -d ' ') files into $out/"
