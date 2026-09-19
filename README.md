# themultiple.net

Static project, support, and privacy pages for software from the Multiple.

The bare domain is the project index. Each project owns a stable directory
containing its landing page and any public surfaces it needs.

## Published URLs

- `https://themultiple.net/`
- `https://themultiple.net/collage/`
- `https://themultiple.net/collage/guide/`
- `https://themultiple.net/collage/support/`
- `https://themultiple.net/collage/privacy/`
- `https://themultiple.net/steward/`
- `https://themultiple.net/ficta/`
- `https://themultiple.net/blog/` (public, but intentionally unlinked from the project index)

The project pages are hand-written HTML and CSS; the blog is generated from
Markdown by Jekyll during deployment. The published site has no JavaScript,
analytics, cookies, or third-party request. GitHub Pages serves the allowlisted
artifact assembled by the Actions workflow on `main`.

## The design system

Edition 01. One stylesheet, `styles.css`, organised in fourteen numbered
sections from faces and tokens down to motion.

`docs/design-system.html` is the specimen the stylesheet was built from: every
token, face, and component rendered against itself, with the reasoning beside
each one. Open it directly in a browser — it is self-contained apart from the
fonts, which it loads from `/fonts/`. It is in the repository but not on the
site: `scripts/assemble-site.sh` publishes from a manifest, and `docs/` is not
on it. `docs/_pulse-test.html` is the harness that verifies the record strip,
and is unserved for the same reason. The short version:

**The plane.** Dark is canonical; light is derived from the same token names
under `prefers-color-scheme`. The neutrals carry a slight cool bias. Depth
comes from one hairline and one tone step — no shadows, no gradient washes,
no large radii.

**Ink.** The index carries no colour of its own. Each project owns one spot
ink, declared as a pair: a fill value, and the shifted value that clears
4.5:1 as text on its own ground. Adding a fourth project costs one hex pair,
not a redesign. Scope it with a class on `<body>`: `app-collage`,
`app-steward`, `app-ficta`.

**Type.** Bricolage Grotesque for display, Inter for body, IBM Plex Mono for
labels, status, and the record strip. All three are open licence, latin
subset, and served from `/fonts/` — 140 KB for the whole system. Never link
a font CDN; the check script fails the build if you do.

**The record strip.** The signature. All three products are an ordered chain
that closes, so one component carries each product's real sequence. It is an
`<ol>` because the order is information. Two registered `@property` numbers
drive it, with no JavaScript: `--t` draws it on scroll via a view timeline,
and `--pulse` travels it every six seconds on an ordinary clock, swelling each
node in turn and colouring the hairline behind it. Where view timelines are
unsupported it renders fully drawn and still pulses; reduced motion parks both
at rest. Below 38rem it rotates to vertical and the pulse travels down it.

**Material.** Each project has a texture behind its identity block, drawn as
a CSS mask so it tints from `--mat` in both themes: an alpha checkerboard for
Collage, ledger rules for Steward, and a staff with editorial accidentals
above it for Ficta.

**The menu.** The same three projects on every page, in the same order, so the
header never rearranges itself under you. A project's own pages — Collage's
guide, support, and privacy — hang below it as a second row that is present
only while you are inside that project, and absent everywhere else. Two states,
and they are different claims: the page you are on is underlined in full spot
ink, the project you are inside but not on is underlined at forty percent.

**The page template.** Masthead, identity, record, facts, then whatever that
project actually has — install, refusals, build log — and the impression
footer. Blocks render only when they are true. A page with nothing to install
has no install block, and nothing is invented to fill the gap.

## The name

Always **the Multiple**, with a lowercase article, including at the start of
a sentence and in a `<title>`. `scripts/check-site.sh` fails on `The
Multiple` in any HTML, CSS, or XML file.

The wordmark sets `the` in IBM Plex Mono and `Multiple` in Bricolage: mono is
the metadata face everywhere else on the site, and an article is metadata
about a noun. The monogram — a capital sigma entangled with a lowercase phi —
lives in `favicon.svg` and in the impression footer. It is drawn as SVG paths
rather than set as text, because the shipped fonts are latin subset and carry
no Greek.

## Blog publishing

Blog posts are Markdown files under `blog-src/_posts/`. Pages CMS reads
`.pages.yml` and presents a mobile-friendly form for the title, date, kind,
tags, body, and images. Saving there commits directly to `main`; that push runs
the same Pages workflow as any other site change.

Jekyll is a build-time dependency only. It renders the isolated `blog-src/`
tree into `/blog/`, including the index, dated post URLs, and Atom feed. The
normal manifest assembly then admits only that generated directory. Layouts,
Markdown source, `.pages.yml`, and Ruby dependency files never enter the Pages
artifact.

The blog is deliberately absent from the front page and project navigation for
now. `scripts/check-site.sh` holds that boundary until the blog's visual and
browsing treatment is ready.

## Local preview

Install Ruby and Bundler, then from the repository root:

```sh
bundle install
bash scripts/build-site.sh _site
ruby -run -e httpd _site -p 8000
```

Then open `http://localhost:8000`. Serve `_site`, not the repository root — the
blog exists only after Jekyll has rendered it, and stylesheet, font, and page
links are all absolute.

Run the structural checks with:

```sh
bash scripts/check-site.sh
```

The structural script requires [ripgrep](https://github.com/BurntSushi/ripgrep) and uses
it in place of the platform `grep`, whose BSD and GNU builds diverge silently
on some patterns — a check that quietly matches nothing looks exactly like a
check that passes.

## Publishing

1. Review and commit content changes on a branch.
2. Open a pull request and wait for `Validate static site` to pass.
3. Merge to `main`; GitHub Pages publishes the exact committed files.
4. Verify the public support and privacy URLs after deployment.

The HTML in this repository is the authority for the published wording. The
Collage application repository keeps a release-time privacy-policy snapshot
and App Store metadata; update those references whenever the public policy
changes.

## Fonts

| File | Family | Licence |
| --- | --- | --- |
| `fonts/bricolage-grotesque-variable.woff2` | Bricolage Grotesque | SIL OFL 1.1 |
| `fonts/inter-variable.woff2` | Inter | SIL OFL 1.1 |
| `fonts/ibm-plex-mono-400.woff2` | IBM Plex Mono | SIL OFL 1.1 |
| `fonts/ibm-plex-mono-500.woff2` | IBM Plex Mono | SIL OFL 1.1 |

All four are latin subsets. If a page ever needs Greek or extended Latin,
add a subset rather than reaching for a hosted stylesheet.

## Custom-domain DNS

The GitHub Pages custom domain is `themultiple.net`. At the authoritative DNS
provider, preserve all existing MX and TXT records and add these apex A records:

```text
185.199.108.153
185.199.109.153
185.199.110.153
185.199.111.153
```

Also add a `www` CNAME pointing to `sammcf.github.io`. GitHub will redirect
between the apex and `www` variants once both are configured. Complete GitHub's
account-level domain verification TXT record before or during DNS setup, then
enable HTTPS in the repository's Pages settings after the certificate is ready.

DNS changes can take up to 24 hours. Do not remove or replace the existing
Google Workspace MX, SPF, or other mail-related records.
