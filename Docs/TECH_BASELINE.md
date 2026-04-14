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
- On Windows, keep the current renderer baseline unless a test proves otherwise:
  - `rendering_device/driver.windows="d3d12"`
  - `renderer/rendering_method="mobile"`

## Godot Working Discipline

- Keep Godot closed while broad external patch sets are being applied.
- Do not run smoke or scene-isolation helpers while another Godot editor or headless process is already open.
- Prefer the repo-local safe launchers and runners so global editor state does not pollute this project.
- Treat `.godot/` and `_godot_profile/` as disposable cache/runtime state, not source of truth.
- If editor behavior becomes inconsistent:
  1. close all Godot processes
  2. retry with the repo-local safe launcher
  3. clear `.godot/` only if import/editor state still looks corrupted
  4. reset `_godot_profile/` only if the repo-local profile itself looks broken

## Validation Commands

- Windows content validator: `py -3 Tools/validate_content.py`
- macOS/Linux content validator: `python3 Tools/validate_content.py`
- Windows asset validator: `py -3 Tools/validate_assets.py`
- macOS/Linux asset validator: `python3 Tools/validate_assets.py`
- Windows architecture guard validator: `py -3 Tools/validate_architecture_guards.py`
- macOS/Linux architecture guard validator: `python3 Tools/validate_architecture_guards.py`
  - current guard scope: no new in-repo `dispatch()` callers, no new runtime-side `RunState` compatibility reads, no new test-side inventory compatibility reads, no new runtime-side `current_node_index` creep outside explicit compatibility files, and no new scene/UI direct gameplay-truth mutation creep
- Windows playtest export: `powershell -NoProfile -ExecutionPolicy Bypass -File Tools/export_windows_playtest.ps1`
- Windows local cache/build cleanup: `powershell -NoProfile -ExecutionPolicy Bypass -File Tools/clean_local_artifacts.ps1`
- Windows bounded regression runner (default bounded subset only): `Tools/run_godot_tests.ps1` or `Tools/run_godot_tests.cmd`
- Windows explicit full `Tests/test_*.gd` suite:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File Tools/run_godot_full_suite.ps1
```

- Windows smoke runner: `Tools/run_godot_smoke.ps1` or `Tools/run_godot_smoke.cmd`
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
- Windows playtest export additionally requires the matching Windows export template for the active Godot `4.6.x` editor binary
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

- `Docs/`: authoritative docs
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
- Prototype music policy: `library only`
- All runtime visual/audio assets must be tracked in `AssetManifest/asset_manifest.csv`
- Shipped product must not rely on live-generated AI
