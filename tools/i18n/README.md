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
