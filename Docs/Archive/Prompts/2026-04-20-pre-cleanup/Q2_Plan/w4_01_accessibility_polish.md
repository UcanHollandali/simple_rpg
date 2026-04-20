# W4-01 — Accessibility polish pass for compact UI (O-1)

- mode: Fast Lane (quality pass, evidence-gated)
- scope: `Game/UI/inventory_card_factory.gd`, `Game/UI/run_status_strip.gd`, `Game/UI/safe_menu_overlay.gd`
- do not touch: `Game/RuntimeState/*`; save shape; content definitions
- validation budget: portrait captures; targeted scene isolation for `scenes/map_explore.tscn` and `scenes/combat.tscn`; `powershell -NoProfile -ExecutionPolicy Bypass -File Tools/run_godot_full_suite.ps1` if behavior was touched
- doc policy: if the pass raises an accessibility floor, update `Docs/VISUAL_AUDIO_STYLE_GUIDE.md` in the same patch. Otherwise no authority doc change.

## Task

1. Run a pass over the three files for accessibility floors (min font size, min tap target, contrast). Audit findings `UI-F6`, `UI-F7` flag the current state.
2. Only make changes backed by portrait-capture evidence. If the current state already meets the floor, report "no change required" and stop for that file.
3. If a change is proposed, keep it visually minimal — this is a polish pass, not a redesign.

## Non-goals

- Do not move theme rhythm constants (that is `W2-06`).
- Do not introduce a new style helper.
- Do not change strings.

## Report format

- per-file: "no change required" or list of changed floors
- portrait capture evidence summary
- full-suite result only if behavior was touched
