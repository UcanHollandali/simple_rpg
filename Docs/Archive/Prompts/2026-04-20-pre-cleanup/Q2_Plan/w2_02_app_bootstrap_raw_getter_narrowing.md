# W2-02 — Narrow scene dependence on `AppBootstrap` raw getters (P-10)

- mode: Guarded Lane
- scope: `Game/Application/app_bootstrap.gd`, `scenes/*.gd` that read raw runtime references from `AppBootstrap`
- do not touch: `Game/RuntimeState/*`; save schema shape; any flow-state family; any command/event family
- validation budget: `py -3 Tools/validate_architecture_guards.py`; `powershell -NoProfile -ExecutionPolicy Bypass -File Tools/run_godot_smoke.ps1`; `powershell -NoProfile -ExecutionPolicy Bypass -File Tools/run_godot_full_suite.ps1`
- doc policy: if this narrowing changes how `AGENTS.md` Risk Map reads for `app_bootstrap.gd`, update `AGENTS.md` in the same patch. Otherwise no authority doc update needed.

## Task

1. Grep scenes for `AppBootstrap.` raw getter use. For each hit:
   - Confirm the scene is pulling a runtime owner (e.g. `RunState`, `InventoryState`, `MapRuntimeState`) rather than an application surface.
   - Replace the scene's read with a call against the existing narrow application surface (`RunSessionCoordinator`, `GameFlowManager`, etc.) — whichever already owns that read path.
2. `AppBootstrap` must not gain new convenience getters. If a scene cannot be narrowed without a new getter, stop and report — do not add the getter. This is AGENTS.md non-negotiable ("do not add new `AppBootstrap` convenience gameplay methods without explicit escalation").
3. Keep composition-only intent: the scene layer must not adopt runtime truth ownership.

## Escalation checks

Stop and report if:
- a new `AppBootstrap` method would be needed → escalate first
- a new `RunState` compat accessor would be needed → escalate first (frozen per `D-042`)
- a narrowing would require a source-of-truth ownership move → escalate first

## Report format

- list of scene edits
- list of narrowed reads: before path / after path
- confirmation: `AppBootstrap` net-added method count is zero
- validator + smoke + full suite result
