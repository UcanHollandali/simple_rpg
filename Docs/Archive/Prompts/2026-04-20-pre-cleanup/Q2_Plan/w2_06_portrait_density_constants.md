# W2-06 — Centralize portrait density constants, theme rhythm, and accessibility floors (P-14)

- mode: Guarded Lane
- scope: `Game/UI/combat_scene_ui.gd`, `Game/UI/map_explore_scene_ui.gd`, `Game/UI/safe_menu_overlay.gd`, `Game/UI/temp_screen_theme.gd`, `Game/UI/inventory_card_factory.gd`, `Game/UI/run_status_strip.gd`; optional single new helper under `Game/UI/` to own the constants if no existing file is a natural owner
- do not touch: `Game/RuntimeState/*`; save shape; content definitions; `ASSET_PIPELINE.md`
- validation budget: `py -3 Tools/validate_architecture_guards.py`; portrait captures; `powershell -NoProfile -ExecutionPolicy Bypass -File Tools/run_godot_scene_isolation.ps1 -ScenePath scenes/map_explore.tscn`; `powershell -NoProfile -ExecutionPolicy Bypass -File Tools/run_godot_scene_isolation.ps1 -ScenePath scenes/combat.tscn`; `powershell -NoProfile -ExecutionPolicy Bypass -File Tools/run_godot_full_suite.ps1`
- doc policy: if a new constants owner is created, add a single paragraph to `Docs/VISUAL_AUDIO_STYLE_GUIDE.md` naming the owner and its topic. Otherwise no authority doc change.

## Task

1. List every duplicated portrait density / theme rhythm / accessibility floor literal across the six files (audit findings `UI-F4..UI-F7`).
2. Route each literal through a single named constant in the chosen owner file.
3. Do not change the visible value of any literal. A visual diff must be justified in the report.
4. Accessibility floors (min font size, min tap target) must keep their current guarantees — do not tighten them in this patch.

## Escalation checks

Stop and report if:
- a new UI autoload would be needed → escalate first
- a constant would need to flip from UI to runtime ownership → escalate first

## Report format

- constants list with source/target ownership
- per-file diff summary
- portrait-capture diff summary
- full-suite result
- line count before/after for all six files; optional new owner file line count
