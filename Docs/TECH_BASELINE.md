# SIMPLE RPG - Technical Baseline

## Purpose

This file locks the technical baseline that should not stay ambiguous.

## Locked Baseline

- Engine: `Godot 4.6.2 stable`
- Scripting language: `typed GDScript`
- Canonical gameplay content format: `JSON`
- Canonical content path: `ContentDefinitions/<family>/<stable_id>.json`
- One definition per file
- Stable IDs use `lower_snake_case`
- Primary development platform: `Windows`
- Secondary development platform: `macOS (Apple Silicon)`

## Godot Runtime Rules

- Godot scenes are for presentation and composition.
- Core gameplay rule logic does not live in scene scripts.
- Signals may coordinate UI and presentation, but must not hide critical gameplay contracts.
- UI design reference remains `1080x1920` portrait. Desktop development preview should use a smaller windowed size or a safe fitted window, not force a full `1080x1920` window on every display.
- On Windows, keep the current renderer baseline unless a test proves otherwise:
  - `rendering_device/driver.windows="d3d12"`
  - `renderer/rendering_method="mobile"`

## Godot Working Discipline

- Keep Godot closed while broad external patch sets are being applied.
- Do not run smoke or scene-isolation helpers while another Godot editor or headless process is already open.
- Prefer the repo-local safe launchers and runners so global editor state does not pollute this project.
- Current Windows smoke helper may reap stale repo-local Godot helper processes after a bounded shutdown wait; it is not permission to keep an external editor open while running repo helpers.
- Treat `.godot/` and `_godot_profile/` as disposable cache/runtime state, not source of truth.
- If editor behavior becomes inconsistent:
  1. close all Godot processes
  2. retry with the repo-local safe launcher
  3. clear `.godot/` only if import/editor state still looks corrupted
  4. reset `_godot_profile/` only if the repo-local profile itself looks broken

## Validation Commands

- Windows environment check: `powershell -NoProfile -ExecutionPolicy Bypass -File Tools/check_environment.ps1`
  - use before Godot-heavy work or when a helper fails unexpectedly
  - `-FailOnRunningGodot` upgrades detected Godot/editor/helper processes from warnings to failures for automation
- Windows AI working check: `powershell -NoProfile -ExecutionPolicy Bypass -File Tools/run_ai_check.ps1`
  - default lane runs environment check, content/assets/architecture validators, bounded Godot tests, and `git diff --check`
  - before checking the environment, it reaps stale repo-local `_godot_profile` Godot helper processes; unrelated/external Godot processes still fail the preflight
  - validator Python calls prefer `py -3` when available and fall back to `python` for CI/runner portability
  - `-Tests test_name.gd,other_test.gd` runs a targeted Godot test list
  - `-MapReview` runs the map-targeted test pair, `scenes/map_explore.tscn` isolation, and a `1080x1920` map portrait capture
  - `-FullSuite` runs the explicit full `Tests/test_*.gd` lane instead of the bounded/targeted runner
- Optional Windows GDScript static check: `powershell -NoProfile -ExecutionPolicy Bypass -File Tools/run_gdscript_static_check.ps1`
  - uses GDQuest `gdscript-formatter` when available on `PATH` or at `../Tools/gdscript-formatter/gdscript-formatter.exe`
  - default scope is changed `.gd` files only; use `-All` only when explicitly auditing repo-wide style debt
  - default action is linter-only with noisy existing style-debt rules disabled; pass `-DisabledRules @()` only for an explicit strict style audit
  - add `-FormatCheck` for non-mutating formatter checks
  - formatting writes require explicit `-Format` plus `-Files` or `-All`; do not auto-format broad gameplay work by default
- Windows portrait image-diff regression: `powershell -NoProfile -ExecutionPolicy Bypass -File Tools/run_portrait_image_diff.ps1 -Capture`
  - captures the standard portrait review set, compares stable images against `Tests/VisualBaselines/portrait_review/`, and writes report/diff artifacts under ignored `export/portrait_image_diff/`
  - use `-UpdateBaselines` only after the visual change is intentional and reviewed
- GitHub Actions validation: `.github/workflows/validate.yml`
  - runs on Windows with Godot `4.6.2` and Python
  - current CI gate runs environment diagnostics, content/assets/architecture validators, bounded Godot tests, portrait image diff, and `git diff --check`
  - this is the current PR/push safety lane; local targeted/full/map checks still apply when a task needs more evidence
- Windows content validator: `py -3 Tools/validate_content.py`
- macOS/Linux content validator: `python3 Tools/validate_content.py`
- Windows asset validator: `py -3 Tools/validate_assets.py`
- macOS/Linux asset validator: `python3 Tools/validate_assets.py`
- Windows architecture guard validator: `py -3 Tools/validate_architecture_guards.py`
- macOS/Linux architecture guard validator: `python3 Tools/validate_architecture_guards.py`
  - semantic hard-fail guards cover boundary drift such as owner/truth/coupling regressions, compatibility creep, facade/public-surface widening, live contract drift, and catalog or legacy-surface regressions
  - ergonomic warnings cover hotspot file growth and active workflow-doc ballast; those are repo maintainability signals, not gameplay authority
- Windows playtest export: `powershell -NoProfile -ExecutionPolicy Bypass -File Tools/export_windows_playtest.ps1`
- playtest session JSONL capture is opt-in via `--playtest-log`; do not treat generic debug/editor/test runs as playtest telemetry by default
- explicit playtest telemetry sessions append a `session_start` header and stable `session_id` so one JSONL file can contain multiple separable sessions without pretending to be one run
- Windows portrait screenshot review capture: `powershell -NoProfile -ExecutionPolicy Bypass -File Tools/run_portrait_review_capture.ps1`
- Windows local cache/build cleanup: `powershell -NoProfile -ExecutionPolicy Bypass -File Tools/clean_local_artifacts.ps1`
- Windows bounded regression runner (default bounded subset only): `Tools/run_godot_tests.ps1` or `Tools/run_godot_tests.cmd`
- Windows explicit full `Tests/test_*.gd` suite:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File Tools/run_godot_full_suite.ps1
```

- Windows smoke runner: `Tools/run_godot_smoke.ps1` or `Tools/run_godot_smoke.cmd`
  - smoke parse lanes should ignore both `.godot/` and `_godot_profile/` because neither cache tree is repo source of truth
- Windows scene isolation runner: `Tools/run_godot_scene_isolation.ps1` or `Tools/run_godot_scene_isolation.cmd`
  - example: `powershell -NoProfile -ExecutionPolicy Bypass -File Tools/run_godot_scene_isolation.ps1 -ScenePath scenes/map_explore.tscn`
- macOS smoke runner: `Tools/run_godot_smoke.sh`
- macOS scene isolation runner: `Tools/run_godot_scene_isolation.sh`

## Content Baseline

JSON definitions must contain:
- `schema_version`
- `definition_id`
- `family`
- `tags`
- `display`
- `rules`

Display text is never a logic key.
Tags are controlled vocabulary, not arbitrary free-form input.

## GDScript File And Class Convention

- File names use `lower_snake_case.gd`
- Class names use `PascalCase`
- `class_name` is required for non-scene scripts unless the script is an autoload singleton script
- File name should match class name in snake_case form
- One primary class per file
- Inner classes are allowed only for small helper types
- Scene-attached scripts may omit `class_name` if they are not referenced externally
- Autoload scripts should not declare a `class_name` that matches the autoload singleton name; current Godot `4.6.2` treats that as a compile error

Layer-oriented suffixes are encouraged:
- `_resolver.gd` for Core resolvers
- `_command.gd` for Application commands
- `_state.gd` for RuntimeState models
- `_service.gd` for Infrastructure services
- `_presenter.gd` for UI presenters

## Testing Baseline

- Core rules should be testable headlessly where possible.
- The active runnable test surface is the `Tests/` folder of `SceneTree` scripts.
- Current implemented runner shape is:
  - `godot --headless --script res://Tests/<test_name>.gd`
- `Tools/run_godot_tests.*` runs a bounded subset by default when called without an explicit test list; that default lane is not the full `Tests/test_*.gd` union.
- Determinism, save roundtrip, and ownership invariants are first-class concerns.
- `GdUnit4` remains the preferred long-term direction, but it is not the current runnable baseline.

## Tool Prerequisites

- Python `3.8+` for validator scripts
- A Godot `4.6.x` editor binary available on `PATH`, via `GODOT` / `GODOT_BIN` / `GODOT_EXECUTABLE`, or discoverable by helper scripts
- `Tools/check_environment.ps1` is the current Windows preflight for confirming the local Godot/Python/Git/GitHub CLI surface and whether Godot processes are already running
- Optional GDQuest `gdscript-formatter` can live outside the repo under `../Tools/gdscript-formatter/gdscript-formatter.exe`; it is a helper, not an authority source
- Optional local Godot documentation clones under `../References/` are external helper references only; they are not repo authority and must not be committed into this project
- Windows playtest export additionally requires the matching Windows export template for the active Godot `4.6.x` editor binary
  - current export helper first checks local template lanes and then attempts the official `4.6.2` export-template archive download automatically when local templates are missing
  - fully offline machines still need a local template copy
- `GdUnit4` is not required for the current runnable test suite

## Cross-Platform Rules

- Line endings are normalized to LF via `.gitattributes`
- `.editorconfig` is the formatting baseline
- `.gitignore` covers OS-specific junk on both Windows and macOS
- `.godot/` must never be committed
- `SVG` assets remain text-reviewable in Git
- After cloning on a new machine:
  1. install Godot `4.6.2 stable`
  2. open the project and allow reimport
  3. keep the regenerated `.godot/` local only

## Repo Layout

- `Docs/`: mixed authority and reference docs; use `Docs/DOC_PRECEDENCE.md` for topic routing instead of treating the whole folder as a single authority surface
- `Game/`: code by layer
- `scenes/`: Godot presentation/composition
- `ContentDefinitions/`: canonical content data
- `Tests/`: automated checks
- `Tools/`: validators and helper scripts
- `SourceArt/`: source/master visual and audio files
- `Assets/`: runtime-facing exported assets
- `AssetManifest/`: provenance and release-replacement tracking

## Production Technical Locks

- UI source of truth: `Figma`
- Character and enemy prototype format: `bust + token`
- Prototype music policy: `safe-first free library music first; if no acceptable safe-first prototype replacement is available, repo-authored generated temp loops are allowed with truthful manifest provenance`
- All runtime visual/audio assets must be tracked in `AssetManifest/asset_manifest.csv`
- Shipped product must not rely on live-generated AI
