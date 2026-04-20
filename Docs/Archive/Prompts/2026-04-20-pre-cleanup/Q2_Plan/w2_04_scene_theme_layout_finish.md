# W2-04 — Finish scene theme/layout consolidation for the remaining 11 drifted scene functions (P-12)

- mode: Guarded Lane
- scope: `scenes/*.gd`, `Game/UI/scene_layout_helper.gd`, `Game/UI/temp_screen_theme.gd`, `Game/UI/scene_audio_players.gd`
- do not touch: `Game/RuntimeState/*`; save schema shape; command/event catalog entries
- validation budget: `py -3 Tools/validate_architecture_guards.py`; `powershell -NoProfile -ExecutionPolicy Bypass -File Tools/run_portrait_review_capture.ps1`; `powershell -NoProfile -ExecutionPolicy Bypass -File Tools/run_godot_scene_isolation.ps1 -ScenePath scenes/map_explore.tscn`; `powershell -NoProfile -ExecutionPolicy Bypass -File Tools/run_godot_scene_isolation.ps1 -ScenePath scenes/combat.tscn`; `powershell -NoProfile -ExecutionPolicy Bypass -File Tools/run_godot_full_suite.ps1`
- doc policy: if the consolidation changes the theme helper's public API, update the relevant note in `Docs/VISUAL_AUDIO_STYLE_GUIDE.md`. Otherwise no authority doc change.

## Task

1. Identify the 11 scene functions that still duplicate theme/layout/audio work (per audit findings `SCN-F3`, `UI-F4`, `UI-F5`).
2. Route each one through `scene_layout_helper.gd`, `temp_screen_theme.gd`, or `scene_audio_players.gd` — whichever already owns the corresponding responsibility. If none of the three is a clean owner for a specific function, stop and surface that case.
3. Keep visual output identical on portrait capture. Any pixel diff must be justified in the report; a surprise pixel diff is a fail.
4. Keep composition-only intent: scenes do not take gameplay truth ownership.

## Escalation checks

Stop and report if:
- a new UI autoload would be needed → escalate first
- a scene would need to own gameplay truth to be narrowed → escalate first

## Report format

- list of the 11 scene functions and the helper each now routes through
- portrait-capture summary: zero-diff / N-diff (with justification)
- scene isolation and full-suite result
- line count before/after for every touched file
