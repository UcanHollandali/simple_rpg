# SIMPLE RPG - Technical Baseline

## Purpose

This file locks the technical foundation that should not stay ambiguous.

## Locked Baseline

- Engine: `Godot 4 stable`
- Scripting language: `typed GDScript`
- Canonical gameplay content format: `JSON`
- Canonical content path: `ContentDefinitions/<family>/<stable_id>.json`
- One definition per file
- Stable IDs use `lower_snake_case`

## Godot Policy

- Godot scenes are for presentation and composition.
- Core gameplay rule logic does not live in scene scripts.
- Signals may coordinate UI and presentation.
- Core gameplay contracts must not be hidden inside signal chains.
- On Windows, keep the project on the Godot 4.6 default driver baseline unless a test proves otherwise:
  - `rendering_device/driver.windows="d3d12"`
  - `renderer/rendering_method="mobile"`

## Godot Working Discipline

- Keep Godot closed while large external patch sets are being applied.
- Reopen Godot only after the patch round is finished and ready for validation.
- Prefer VS Code for code and doc editing.
- Use Godot mainly for:
  - scene composition
  - node wiring
  - visual checks
  - short GUI smoke runs
- Do not treat the live-open editor as a safe place for broad concurrent file mutations.
- If Godot starts behaving inconsistently after external edits, reset by:
  - closing all Godot processes
  - reopening the project
  - clearing `.godot/` cache only when needed

## Godot Cache Rule

- `.godot/` is disposable cache, not source of truth.
- Do not commit `.godot/` as project logic.
- Clear `.godot/` only when launch/import/editor state looks corrupted.
- Clear it only while Godot is fully closed.
- Use `Tools/clear_godot_cache.ps1` as the preferred cleanup path.
- On Windows, prefer the `.cmd` wrappers if PowerShell execution policy blocks `.ps1` directly.

## Godot Validation Policy

- Prefer editor-mode parse/open checks over Windows headless script runs when headless proves unstable.
- GUI smoke validation is acceptable for scene wiring and launch sanity checks.
- Pure rule validation should stay outside scene-dependent editor workflows whenever possible.
- Use `Tools/run_godot_smoke.ps1` for quick editor or scene smoke checks.
- Use `Tools/run_godot_scene_isolation.ps1` to test the minimal isolation scene.
- On Windows, prefer `Tools/run_godot_smoke.cmd` and `Tools/run_godot_scene_isolation.cmd` for simpler local execution.

## Renderer Fallback Strategy

Default intent:
- keep the project on the normal project settings first

Fallback order on Windows when crash suspicion is renderer-related:
1. default profile
2. `d3d12_mobile`
3. `vulkan_mobile`
4. `compatibility`

Compatibility is the last fallback because it changes renderer capability more aggressively.

## Autoload Policy

Allowed autoloads:
- `AppBootstrap`
- `SceneRouter`
- `SaveService`
- `ConfigService`

Disallowed as autoload owners:
- combat truth
- inventory truth
- enemy truth
- reward truth

## Save Baseline

- The architecture is save-ready from the start.
- First supported save-safe states:
  - `MapExplore`
  - `Reward`
  - `LevelUp`
  - `SupportInteraction`
  - `StageTransition`
  - `RunEnd`
- First unsupported save states:
  - `Boot`
  - `RunSetup`
  - `NodeResolve`
  - `Combat`

## RNG Baseline

Use named deterministic streams:
- `map_rng`
- `combat_rng`
- `reward_rng`

Persist active RNG stream state in save data.

## Content Baseline

JSON definitions must contain:
- `schema_version`
- `definition_id`
- `family`
- `tags`
- `display`
- `rules`

Display text is never a logic key.
Tags are controlled vocabulary, not arbitrary free-form chaos.

## Testing Baseline

- Core rules should be testable headlessly where possible.
- Godot CLI/headless smoke tests are allowed for integration checks.
- Determinism, save roundtrip, and ownership invariants are first-class concerns.

## Repo Layout

- root: entrypoint and agent memory files
- `Docs/`: authoritative docs
- `Game/`: code by layer
- `Scenes/`: Godot presentation/composition
- `ContentDefinitions/`: canonical content data
- `Tests/`: automated checks
- `Tools/`: validators and internal helpers
