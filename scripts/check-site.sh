#!/usr/bin/env bash
# Structural checks for themultiple.net.
#
# Uses ripgrep throughout, never the platform grep: BSD and GNU grep diverge
# silently on -P and on escapes like \s, so a check that "passes" on macOS can
# be a check that never ran. rg behaves identically everywhere.
set -euo pipefail

site_root=$(cd "$(dirname "$0")/.." && pwd)
cd "$site_root"

if ! command -v rg >/dev/null 2>&1; then
  echo "ERROR: ripgrep (rg) is required. Install it with 'brew install ripgrep' or 'apt-get install ripgrep'." >&2
  exit 1
fi

fail() { echo "ERROR: $1" >&2; exit 1; }

# --------------------------------------------------------------- required files

required_files=(
  CNAME
  .pages.yml
  Gemfile
  Gemfile.lock
  index.html
  404.html
  styles.css
  favicon.svg
  robots.txt
  sitemap.xml
  fonts/bricolage-grotesque-variable.woff2
  fonts/inter-variable.woff2
  fonts/ibm-plex-mono-400.woff2
  fonts/ibm-plex-mono-500.woff2
  collage/index.html
  collage/guide/index.html
  collage/support/index.html
  collage/privacy/index.html
  steward/index.html
  ficta/index.html
  blog-src/_config.yml
  blog-src/_layouts/default.html
  blog-src/_layouts/post.html
  blog-src/blog/index.html
  scripts/build-site.sh
)

for file in "${required_files[@]}"; do
  [[ -f "$file" ]] || fail "missing required file: $file"
done

[[ "$(tr -d '[:space:]' < CNAME)" == "themultiple.net" ]] \
  || fail "CNAME must contain only themultiple.net"

# ------------------------------------------------------------------ every page

# docs/ is working material — the design system specimen, which carries its own
# stylesheet and quotes the brand rule verbatim, and the strip harness. It is in
# the repository but never published (see scripts/assemble-site.sh), so it is
# checked out of the page rules below. Keep pages of the site out of docs/.
pages=()
while IFS= read -r file; do
  pages+=("$file")
# _site/ is this same site already assembled; checking it would double every
# result and mis-see _site/404.html as a page that has lost its canonical URL.
done < <(find . -name '*.html' -type f \
           -not -path './.git/*' \
           -not -path './blog-src/*' \
           -not -path './docs/*' \
           -not -path './_blog-build/*' \
           -not -path './vendor/*' \
           -not -path './_site/*' | sort)

for file in "${pages[@]}"; do
  rg -qF '<html lang="en">' "$file"     || fail "$file has no English language declaration"
  rg -qF '<meta name="viewport"' "$file" || fail "$file has no viewport metadata"
  rg -qF '<title>' "$file"               || fail "$file has no title"
  rg -qF '<main' "$file"                 || fail "$file has no main landmark"
  rg -qF '/styles.css' "$file"           || fail "$file does not load the stylesheet"
  rg -qF '/favicon.svg' "$file"          || fail "$file does not load the favicon"
  rg -qF 'skip-link' "$file"             || fail "$file has no skip link"
done

# --------------------------------------------------------------- blog source

rg -qF 'path: blog-src/_posts' .pages.yml || fail "Pages CMS does not target the Jekyll posts"
rg -qF 'input: blog-src/blog/media' .pages.yml || fail "Pages CMS media is outside the blog source"
rg -qF 'output: /blog/media' .pages.yml || fail "Pages CMS media has the wrong public path"
rg -qF 'permalink: /blog/' blog-src/_config.yml || fail "blog permalinks are not under /blog/"
rg -qF 'path: blog/feed.xml' blog-src/_config.yml || fail "blog feed is not under /blog/"

# The blog is intentionally public but undiscoverable from the project index
# until its visual system is ready.
if rg -nF 'href="/blog/' index.html; then
  fail "the front page must not link to the blog yet"
fi

# Every page except 404 is canonical and belongs in the sitemap.
for file in "${pages[@]}"; do
  [[ "$file" == "./404.html" ]] && continue
  rg -qF 'rel="canonical"' "$file" || fail "$file has no canonical URL"
done

# ------------------------------------------------------------------- the brand

# The article is always lowercase. This is the one brand rule a machine can hold.
# docs/ is exempt because that is where the rule is written down, capital and all.
if rg -nF 'The Multiple' --glob '*.html' --glob '*.css' --glob '*.xml' --glob '!docs/**' --glob '!vendor/**' .; then
  fail "the article is always lowercase: write 'the Multiple', never 'The Multiple'"
fi

# ----------------------------------------------------------- no script, no CDN

# docs/ is exempt: the strip harness is JavaScript by nature, being a measuring
# instrument. It is never published — scripts/assemble-site.sh is what enforces
# that, and this ban covers everything that is.
if rg -ni -e '<script' -e 'google-analytics' -e 'googletagmanager' -e 'facebook\.net' \
     --glob '*.html' --glob '!docs/**' --glob '!vendor/**' .; then
  fail "site must remain script-free and analytics-free"
fi

# Fonts and styles are served from this origin. Nothing is fetched from anyone else.
if rg -ni -e 'fonts\.googleapis\.com' -e 'fonts\.gstatic\.com' -e 'cdn\.' -e 'unpkg\.com' -e 'jsdelivr' \
     --glob '*.html' --glob '*.css' --glob '!docs/**' --glob '!vendor/**' .; then
  fail "site must not reference a third-party CDN or font host"
fi

# ------------------------------------------------------------------- the links

rg -qF 'href="/collage/"' index.html || fail "index does not link to Collage"
rg -qF 'href="/steward/"' index.html || fail "index does not link to Steward"
rg -qF 'href="/ficta/"'   index.html || fail "index does not link to Ficta"

rg -qF 'sam@themultiple.net' collage/support/index.html || fail "support page has no contact address"
rg -qF 'sam@themultiple.net' collage/privacy/index.html || fail "privacy page has no contact address"

for url in \
  'https://themultiple.net/' \
  'https://themultiple.net/collage/' \
  'https://themultiple.net/collage/guide/' \
  'https://themultiple.net/collage/support/' \
  'https://themultiple.net/collage/privacy/' \
  'https://themultiple.net/steward/' \
  'https://themultiple.net/ficta/'
do
  rg -qF "<loc>$url</loc>" sitemap.xml || fail "sitemap is missing $url"
done

# -------------------------------------------------------------- the stylesheet

# The record strip is the signature; losing it silently would be a regression.
rg -qF '.record' styles.css                        || fail "styles.css has no record strip"
rg -qF 'prefers-color-scheme: light' styles.css    || fail "styles.css has no derived light mode"
rg -qF 'prefers-reduced-motion' styles.css         || fail "styles.css does not respect reduced motion"

for face in bricolage-grotesque-variable inter-variable ibm-plex-mono-400 ibm-plex-mono-500; do
  rg -qF "/fonts/$face.woff2" styles.css || fail "styles.css does not load $face"
done

echo "Static site checks passed. ${#pages[@]} pages."
