# Source text catalog tools

These command-line tools extract an assembly text catalog, compare catalogs, and reconstruct an unchanged source tree. They do not translate text, provide fonts, or enable new character encodings in the game. Python 3.9 or newer is required; no third-party Python packages are needed. Building reconstructed game sources requires the dependencies in the repository installation guide.

## Extract a catalog

Run from the repository root. Keep outputs outside the source tree being inspected.

```bash
python3 tools/i18n/catalog.py extract --source . --out ../source-catalog
```

For a source archive without Git metadata, optionally supply --source-commit with its full 40-character commit SHA. This records a declared origin; it does not verify that an archive matches that commit. The generated source-files.json and tree digest identify the files actually inspected.

Outputs:

- catalog.jsonl: original source spans, hashes, label-based IDs, parsed commands, display text, tokens, consumer hints and diagnostics.
- source-files.json and summary.json: input inventory, hashes and coverage totals.
- coverage.json and diagnostics.jsonl: file coverage and statements requiring review.
- translation-migration.json: optional ID/hash mapping when --translations points to a directory of JSON records with id and source_sha256. No records are rewritten.

## Compare source versions

```bash
python3 tools/i18n/catalog.py diff ../catalog-old/catalog.jsonl ../catalog-new/catalog.jsonl --out ../catalog-diff.json
```

The report lists added, removed and changed IDs. Equal-hash additions and removals are possible moves or renames requiring manual review. Repeated strings remain distinct. IDs use path, label and block ordinal, not line numbers; inserting a block under an existing label can change later ordinals. Preserve catalogs and review differences before migrating translations.

## Reconstruct original source

Use an unchanged source snapshot and its matching catalog. The destination must be a new directory outside that source tree.

```bash
python3 tools/i18n/roundtrip.py --source . --catalog ../source-catalog/catalog.jsonl --out ../reconstructed-source --report ../roundtrip-report.json
```

The default original mode requires complete catalog coverage and unchanged commands. It verifies IDs, labels, spans, source hashes, command positions and overlaps. Each recognized block is rebuilt from catalog commands while preserving source formatting and comments; other source and asset files provide the build environment. The report records consumed commands and replacement hashes.

An explicit --mode literal-edit experiment permits quoted literal changes only in unambiguous map/common text. Keep source_text and its hash unchanged as provenance; edit commands[].args. Control order and dynamic-token signatures must remain unchanged. --allow-partial disables the complete-catalog check for a deliberate subset. These options are not a general translation importer.

## Limitations

The parser recognizes selected RGBDS text macros, literal tables and far-text references. It does not evaluate conditional assembly or expand macros, infer complete runtime consumers, extract lettering from images, or support arbitrary assembly transformations. Conditions and uncertain boundaries are retained for review. Consumer supported=false and auto_admit=false mean discovery has not approved that record for runtime translation.

Source spans and hashes preserve exact UTF-8 text, including internal blank lines and comments; display_text is a separate interpretation. Neither tool modifies the inspected source tree. Do not treat catalog text or command arguments from untrusted sources as safe to assemble without review.

## Export profile-selected messages

```bash
python3 tools/i18n/messages.py --source . --profile normal --out ../messages --old-catalog ../source-catalog/catalog.jsonl --old-diagnostics ../source-catalog/diagnostics.jsonl
```

Profiles select documented normal, faithful or debug build conditions; unknown conditions remain review items. Use translation-ready.jsonl and its ordered translation_segments/translation_view, not display_text alone: dynamic RAM values, controls and symbolic format arguments must remain visible to translators. Original source spans and selected source segments retain their locations and hashes. Shared-label tails include explicit continuation references.

The full messages file also retains runtime-code handoffs, references and macro templates separately. Readiness means the message is suitable as translation input, not that every runtime consumer can accept a translation. Diagnostic dispositions explain old records individually; inactive build alternatives are retained in conditions.jsonl.

## Inventory non-ASM resources

```bash
python3 tools/i18n/resources.py --source . --out ../resources
```

Resources are not automatically extracted text. The report separates visually confirmed lettering, candidates, nontext data and assets requiring manual review, with hashes and assembly references. No OCR or automatic image replacement is performed.

## Multilingual CSV worksheet

Message export now also writes `translations.csv` (UTF-8 with BOM for Excel).
The default language columns are `translation_zh-Hans` and `translation_zh-Hant`.
Use `messages.py --languages zh-Hans zh-Hant ja ...` to choose other language tags.
CSV quoting preserves commas, quotes and embedded newlines. Keep the ID, source
hash, profile, location and original columns unchanged. Existing worksheets are
never overwritten by export.

Export a worksheet from existing message JSONL without extracting again:

```bash
python3 tools/i18n/worksheet.py export --messages ../messages/translation-ready.jsonl --languages zh-Hans zh-Hant ja --out ../translations.csv
```

Select the exact language column for the next toolchain stage:

```bash
python3 tools/i18n/worksheet.py select --messages ../messages/translation-ready.jsonl --csv ../translations.csv --language zh-Hans --out ../selected-zh-Hans.jsonl
```

Selection rejects missing language columns, empty translations, duplicate/unknown
IDs, missing records and changed source metadata. Explicit `--fallback original`
uses the original text for blank cells; it never reads another language's column.
The selected JSONL contains `language`, `translation` and `selection_status`
alongside original message metadata. This is draft selection, not ROM insertion:
placeholder, encoding and layout admission remain the runtime importer's responsibility.
Use the unified package workflow below for image replacements.

## Unified text and image package

```bash
python3 tools/i18n/images.py package --source . --messages ../messages/translation-ready.jsonl --out ../localization --languages zh-Hans zh-Hant
python3 tools/i18n/worksheet.py select --messages ../localization/messages.jsonl --resources ../localization/resources.jsonl --csv ../localization/translations.csv --language zh-Hans --fallback original --out ../selected.jsonl
python3 tools/i18n/images.py apply --source . --selected ../selected.jsonl --out ../localized-source
```

The single CSV includes `resource_kind` (`text` or `image`) and `review_status`.
For text rows, each language column contains translated text. For image rows,
it contains a replacement PNG path relative to the CSV directory, for example
`replacements/zh-Hans/gfx/title/logo.png`. Originals are copied into
`originals/gfx/...` for viewing and editing; `original` points there.
Blank image cells always preserve the original asset, including when text
selection uses the default strict mode. PNGs awaiting visual review are included
as such; inclusion does not claim they contain text.

Apply validates source/replacement hashes and requires identical dimensions,
PNG color format, palette and transparency. It writes a new source directory
only after validation; the inspected source stays unchanged. Edit copied originals
without changing their palette or export settings. Noninterlaced PNGs are supported.
Use a clean source tree and build the result with the repository's normal build
process. Apply only replaces PNG source assets: it does not insert text translations,
perform OCR, regenerate tilemaps, import raw tile binaries, or guarantee that edited
art fits runtime tile budgets. Review and game-build verification remain necessary.
The complete resource inventory retains non-PNG assets separately.

## Static browser editor

Open `tools/i18n/editor.html` directly in a browser with directory write support.
No server or network is required. Open the resource folder once; saves write the
CSV and replacement PNGs directly to it. There is no export/import mode. The folder
handle is remembered locally for refresh, with its identifier and name in the URL.
The browser may require a click to renew access. Save drafts before closing.

The original/translation table loads additional rows while scrolling. Tags filter
by resource type, language-specific translation status, image text-review state
and custom categories. Multiple tags match their intersection. Metadata appears
in a separate drawer. Click images to zoom; image replacement remains optional.
Tags and review decisions are shared across languages and do not change build
fallback behavior. Image-to-ROM compilation and visual equivalence are unverified.

## Start translating this repository

The root `translations.csv` is the versioned translation worksheet: 12,539 text
records and 3,180 PNG resources. Open `tools/i18n/editor.html`, then choose the
repository root folder. Original images are read from the existing `gfx/` tree;
no duplicate originals are committed. Commit the CSV and any new replacement PNGs
together. Do not commit generated ROMs, temporary packages or backups.

The interface language selector supports Simplified Chinese and English independently
of the translation language. UI messages are centralized in the embedded `UI_EN`
dictionary so the page stays standalone and works without fetching dependencies.
Tags use stable stored values; changing interface language does not rewrite them.

To validate selected repository translations, regenerate message/resource JSONL
outside the source tree, and pass `worksheet.py select --repository-paths` along
with those files and the root CSV. Source updates require explicit worksheet
migration; do not overwrite a worksheet containing translator edits.
