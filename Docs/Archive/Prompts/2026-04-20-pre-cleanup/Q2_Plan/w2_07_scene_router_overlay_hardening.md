# W2-07 — Harden `SceneRouter` overlay contract (P-15)

- mode: Guarded Lane
- scope: `Game/Infrastructure/scene_router.gd`, any scene method that opens an overlay through a scene-specific string, `Docs/GAME_FLOW_STATE_MACHINE.md` only if the overlay contract is currently described there
- do not touch: `Game/RuntimeState/*`; save shape; flow-state families; command/event families
- validation budget: `py -3 Tools/validate_architecture_guards.py`; `powershell -NoProfile -ExecutionPolicy Bypass -File Tools/run_godot_tests.ps1 test_flow_state.gd test_phase2_loop.gd`; `powershell -NoProfile -ExecutionPolicy Bypass -File Tools/run_godot_smoke.ps1`; `powershell -NoProfile -ExecutionPolicy Bypass -File Tools/run_godot_full_suite.ps1`
- doc policy: if the overlay contract is described in an authority doc, update it in the same patch. Otherwise no authority doc change.

## Task

1. Replace scene-specific string choreography in `scene_router.gd` overlay openers with a typed enum / const set that lives in `scene_router.gd` itself.
2. Every scene call site must be updated to the typed path. Leave no string-based overlay key behind inside `scenes/`.
3. Do not rename overlays — the typed names must mirror the current string names 1:1.
4. Do not introduce a new command/event family. If the hardening would need one, stop and escalate.

## Escalation checks

Stop and report if:
- the hardening would introduce a new flow state → escalate first
- the hardening would introduce a new event family → escalate first

## Report format

- typed-enum / const declaration in final form
- list of scene callsites updated
- flow/phase2 test result
- smoke + full suite result
