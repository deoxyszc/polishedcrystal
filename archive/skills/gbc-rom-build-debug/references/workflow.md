# Tested workflow (2026-09-16)

## Versions and environment
Polished source: /Users/zhaoc/source/polishedcrystal at f22d31a52cbbf1387d27ba63f5bf2fa959955d37 (master, version string 3.2.3; not necessarily release tag). Chinese wrapper: /Users/zhaoc/source/pokecrystal_cn_build at 868552150200b3086d64d1ec49959afd04b92da3; source submodule dab54f14d49c578eec05e4c67ee8b7d5fb916e11; RGBDS submodule 08f3e360c9525b65291db9cee66fc5eb6e4a45e4 (v0.7.0).

Installed Homebrew RGBDS 1.0.3, coreutils 9.12, bison 3.8.2, pkgconf 3.0.7, libpng 1.6.58; Python venv with openpyxl 3.1.5. SameBoy 1.0.3 installed at /Users/zhaoc/Documents/Codex/Applications/SameBoy.app.

```bash
HOMEBREW_NO_AUTO_UPDATE=1 brew install rgbds coreutils bison pkgconf libpng
HOMEBREW_NO_AUTO_UPDATE=1 brew install --cask --appdir=/Users/zhaoc/Documents/Codex/Applications sameboy
python3 -m venv work/venv
work/venv/bin/pip install openpyxl
```

The /Applications install failed when Homebrew attempted sudo; appdir under Documents/Codex succeeded. Homebrew auto-update attempted protected .git writes; disabling auto-update per invocation avoids unrelated updates. No global shell profile edits are needed.

## Chinese build
Build pinned RGBDS locally:

```bash
cd /Users/zhaoc/source/pokecrystal_cn_build/rgbds
env PATH=/opt/homebrew/opt/bison/bin:/opt/homebrew/bin:/usr/bin:/bin make -j4
```

Use a fresh staging directory to avoid modifying translated source or double-applying the credits patch:

```bash
mkdir -p /Users/zhaoc/Documents/Codex/2026-09-16/ban/work/cn-build
rsync -a --exclude=.git --exclude=rgbds /Users/zhaoc/source/pokecrystal_cn_build/ /Users/zhaoc/Documents/Codex/2026-09-16/ban/work/cn-build/
cd /Users/zhaoc/Documents/Codex/2026-09-16/ban/work/cn-build
env PATH=/Users/zhaoc/source/pokecrystal_cn_build/rgbds:/Users/zhaoc/Documents/Codex/2026-09-16/ban/work/venv/bin:/opt/homebrew/opt/coreutils/libexec/gnubin:/opt/homebrew/bin:/usr/bin:/bin bash -c 'source env-setup && pmc_isys && pmc_init && pmc_itext && pmc_build'
```

Use Bash explicitly. pmc_isys changes staged source; pmc_init copies source to build; pmc_itext imports main dialogue and patches credits; pmc_build compiles. README incorrectly calls the last step pmc_itext in one sentence. Successful outputs in work/cn-build/build: pokecrystal11.gbc and pokecrystal11_debug.gbc, both with matching .sym/.map. Original repository stayed clean.

## Polished build

```bash
cd /Users/zhaoc/source/polishedcrystal
make -j4
# Preserve normal ROM, .sym, .map before switching if needed.
make clean
make debug -j4
```

Normal built successfully: polishedcrystal-3.2.3.gbc, 29,975/2,097,152 bytes free (1.43%). Normal SHA256: 469d08907d0ef474d174d87d84d25e108b86ca481131b41fa291bd8aae97c29b.

Important observed failure: make debug immediately after normal reused objects and produced identical ROM hashes. Clean debug rebuild succeeded, reporting 29,867 bytes free (1.42%). Objects do not encode flags in filenames. Keep variants in separate staging trees or clean when switching. Debug output is polishedcrystal-debug-3.2.3.gbc, with .sym/.map. Apple clang emitted unsupported GCC warning-option warnings; compilation still passed. tools/parsemap.h.pch is an untracked generated artifact.

## SameBoy tests and debugging
File > Open (Cmd+O), then Cmd+Shift+G in file picker to enter a ROM path. Observe path field before typing. SameBoy auto-loaded sibling .sym files and displayed named registers/backtraces for both normal builds.

Verified default controls: A=x, B=z, Start=Return, Select=Backspace, arrows=direction, Space=Turbo, Tab=Rewind. UI snapshots may lag; focus the game window explicitly after closing console. A key invocation alone is not evidence of game input.

Develop > Developer Mode; Develop > Show Console; Ctrl+C interrupts. Verify console title matches ROM.

```text
break PlaceString
continue
```

Chinese build breakpoint hit at 00:111b, with DE pointing into _AreYouABoyOrAreYouAGirlText and backtrace through NewGame, InitGender and TextCommand_FAR. Registers and symbolic stack were visible. delete without arguments cleared test breakpoints; Continue resumed display. Polished accepted break _PlaceString at 00:0ea7; its halt showed MainMenuJoypadLoop and MenuJoypadLoop, but a text breakpoint hit was not verified.

Other documented commands (not all exercised): registers, backtrace, examine/16 de, disassemble/16, step, next, finish, reset reload. Develop exposes Show Memory and Show VRAM Viewer; their detailed workflows remain untested. Official command reference: https://sameboy.github.io/debugger/ .

Smoke-test scope: Chinese normal ROM reached Chinese title, main menu, New Game, readable gender question and boy/girl selection; text breakpoint hit confirmed. Console reported PPU odd-mode fallback and APU odd-mode untested warnings, without preventing observed startup. Polished normal ROM reached intro, title and main menu through Start input, with symbolic debugging verified. Debug variants were built but not separately playtested. No claim of battle, save/load, link or full-game correctness.
