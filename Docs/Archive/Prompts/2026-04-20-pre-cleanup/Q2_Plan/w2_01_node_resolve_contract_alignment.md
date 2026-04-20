# W2-01 — Align `NodeResolve` live fallback contract with docs (B-2, D-041)

- mode: Guarded Lane
- scope:
  - doc pass: `Docs/GAME_FLOW_STATE_MACHINE.md`, `Docs/MAP_CONTRACT.md`
  - code pass: `Game/Application/game_flow_manager.gd`, `Game/Application/run_session_coordinator.gd`, `scenes/map_explore.gd`, `scenes/node_resolve.gd`, `Game/Infrastructure/scene_router.gd`
- do not touch: save schema shape, flow-state families, command/event families, RunState compat accessors
- validation budget: `py -3 Tools/validate_architecture_guards.py`; `powershell -NoProfile -ExecutionPolicy Bypass -File Tools/run_godot_tests.ps1 test_flow_state.gd test_phase2_loop.gd`; `powershell -NoProfile -ExecutionPolicy Bypass -File Tools/run_godot_smoke.ps1`; `powershell -NoProfile -ExecutionPolicy Bypass -File Tools/run_godot_full_suite.ps1`
- doc policy: `D-041` is decided. Apply it — `NodeResolve` is an orchestrated transition shell only, no generic runtime fallback. The closest authority docs (`GAME_FLOW_STATE_MACHINE.md`, `MAP_CONTRACT.md`) must be updated in the same patch as the code narrowing.

## Current state (measured 2026-04-20)

- `scenes/node_resolve.gd` is 170 lines.
- `NodeResolve` is still referenced by `run_session_coordinator.gd`, `scene_router.gd`, `map_runtime_state.gd`, `transition_shell_presenter.gd`, tests, and four scene files.
- Audit finding `APP-F1`/`SCN-F7` flag a mismatch between the live fallback behavior and what the docs describe.

## Task

1. Read `Docs/GAME_FLOW_STATE_MACHINE.md` and `Docs/MAP_CONTRACT.md` passages that describe the map-to-interaction transition and `NodeResolve`.
2. In the same patch:
   - Narrow the code so that `NodeResolve` no longer acts as a generic fallback for unknown node kinds; an unknown kind must fail loudly through the existing flow-error path, not silently route through `NodeResolve`.
   - Update the doc passages so that `NodeResolve` is described as a transition shell only.
3. Keep the `NodeResolve` scene itself — the shell is real. Only the "generic fallback" interpretation is retired.
4. Do not change signal names or flow-state names. If a signal looks ambiguous, surface it and stop.

## Escalation checks

Do not continue if any of these is true:
- the change requires adding a new flow state → escalate first
- the change requires a new command or event family → escalate first
- the change requires a save-schema modification → escalate first

## Report format

- doc diff
- code diff
- targeted test result for `test_flow_state.gd` and `test_phase2_loop.gd`
- smoke result
- full-suite result
- explicitly: no save shape change, no flow-state addition, no new event family
