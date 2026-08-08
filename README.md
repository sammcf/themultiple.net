# themultiple.net

Static project, support, and privacy pages for apps from The Multiple.

The bare domain is a minimal project index. Each app owns a stable directory
containing its landing page and public support/privacy surfaces.

## Published URLs

- `https://themultiple.net/collage/`
- `https://themultiple.net/collage/support/`
- `https://themultiple.net/collage/privacy/`

The site is deliberately plain HTML and CSS. It has no JavaScript, analytics,
cookies, third-party fonts, package manager, or build dependencies. GitHub Pages
publishes the committed files from `main` without transformation.

## Local preview

From the repository root:

```sh
ruby -run -e httpd . -p 8000
```

Then open `http://localhost:8000`.

Run the structural checks with:

```sh
bash scripts/check-site.sh
```

## Publishing

1. Review and commit content changes on a branch.
2. Open a pull request and wait for `Validate static site` to pass.
3. Merge to `main`; GitHub Pages publishes the exact committed files.
4. Verify the public support and privacy URLs after deployment.

The HTML in this repository is the authority for the published wording. The
Collage application repository keeps a release-time privacy-policy snapshot and
App Store metadata; update those references whenever the public policy changes.

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
