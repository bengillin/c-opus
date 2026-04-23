# Claude Opus 4.7 — artist site

Static website that showcases the six rolls of photographs by Claude Opus 4.7.
A single Python build script reads the six projects under `/projects`, pulls
frame metadata from each project's `build_artifact_pdf.py`, resizes the images
for the web, and renders a complete static site into `dist/`.

## Build

```bash
uv run python website/build.py
```

This produces `website/dist/` — a self-contained static site (~400 MB, most of
it full-resolution images and the six PDFs).

Re-run the build whenever the underlying rolls change; the website and the
artifact PDFs stay in sync because they read from the same per-project
`build_artifact_pdf.py` source of truth.

## Preview locally

Serve `dist/` over http so clean URLs resolve:

```bash
uv run python -m http.server 8000 --directory website/dist
# then open http://localhost:8000
```

Opening `dist/index.html` directly in a browser also works — the home page
renders, and internal links include explicit `index.html` so they resolve
correctly over `file://` too.

## Deploy

The `dist/` folder is a plain static site. Any static host works.

### Cloudflare Pages (the recommended path for this project)

Because the source images live in `projects/` (gitignored), a Git-connected
build on Pages wouldn't find them. Use **direct upload via Wrangler** instead:

```bash
# one-time setup
brew install ghostscript                  # compresses PDFs below the 25 MiB limit
brew install node && npm i -g wrangler    # Cloudflare CLI
wrangler login

# every deploy
./website/deploy.sh
```

`deploy.sh` rebuilds the site and runs `wrangler pages deploy website/dist`.
Override the project name with `CF_PROJECT=my-project ./website/deploy.sh`.

### Other hosts

- **Netlify** — `netlify deploy --dir=website/dist --prod`
- **GitHub Pages** — publish `dist/` to `gh-pages` (note: 1 GB repo limit; our
  compressed dist is ~40 MB so we fit)
- **S3 / Vercel / any CDN** — upload `dist/` as-is

No build-time or runtime JavaScript, no API calls, no database. It's HTML,
CSS, JPEGs, and PDFs.

## PDF compression

Each roll's full-resolution artist's-book PDF lives in its project folder
(35–72 MB, unchanged). The website build produces a **compressed web copy**
of each PDF via Ghostscript's `/ebook` preset (150 dpi, ~1–2 MB) into
`dist/rolls/<slug>/pdf/`. The originals stay untouched; the compressed copies
are what the site links to. This keeps the site under Cloudflare Pages'
25 MiB per-file limit while preserving the original artifacts for direct
sharing.

If Ghostscript isn't installed, `build.py` falls back to copying the originals
verbatim and prints a warning.

## Structure

```
website/
├── README.md              — this file
├── build.py               — the site generator
├── static/
│   └── css/style.css      — all styling
├── templates/
│   ├── base.html          — shared shell (header, footer)
│   ├── index.html         — home: 6-roll grid
│   ├── roll.html          — single roll page
│   ├── about.html         — bio + artist's statement + colophon
│   └── process.html       — how the work is made
└── dist/                  — generated output (gitignore'd)
    ├── index.html
    ├── about/index.html
    ├── process/index.html
    ├── rolls/<slug>/
    │   ├── index.html
    │   ├── card.jpg       — homepage thumbnail
    │   ├── frames/        — 24 gallery images
    │   └── pdf/           — the artist's book
    └── css/style.css
```

## Editing content

The per-roll metadata (title, film, subject, statement, accent colors, hero
frame) lives in the `ROLLS` list at the top of `build.py`. Per-frame data
(title, prompt, personal note) is pulled from each project's
`build_artifact_pdf.py` `FRAMES` constant — the same source of truth the PDF
generator uses. Edit there and re-run the build.

The bio, artist's statement, and process essay live as top-level constants in
`build.py` (`BIO`, `STATEMENT`, `PROCESS`).
