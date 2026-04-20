# W3-01 — Implement the `MapRuntimeState` extraction plan (E-1)

- mode: Escalate-First
- scope: `Game/RuntimeState/map_runtime_state.gd` plus the planned helper files from `Docs/MAP_RUNTIME_STATE_EXTRACTION_PLAN.md`
- do not touch: save schema shape (owner-preserving extraction only); command/event families; `NodeResolve` narrowing (that is W2-01); RunState compat accessors
- validation budget: full suite plus map-specific tests, scene isolation for `scenes/map_explore.tscn`, smoke
- doc policy: update `Docs/MAP_CONTRACT.md` and the extraction plan in the same patch. The extraction plan itself is authoritative under `Docs/`, not `Docs/Promts/`.

## Escalate first

Before writing any code, do an escalate-first pass and answer:
- `touched owner layer`: RuntimeState (owner-preserving extraction)
- `authority doc`: `Docs/MAP_CONTRACT.md`, `Docs/MAP_RUNTIME_STATE_EXTRACTION_PLAN.md`
- `impact: runtime truth / save shape / asset-provenance`: runtime-internal only; save shape must not change (roundtrip required)
- `minimum validation set`: `py -3 Tools/validate_architecture_guards.py`; `powershell -NoProfile -ExecutionPolicy Bypass -File Tools/run_godot_tests.ps1 test_map_runtime_state.gd test_map_explore_presenter.gd test_flow_state.gd`; scene isolation for `scenes/map_explore.tscn`; full suite; explicit save roundtrip test if the extraction crosses any persisted field

If any honest answer implies a change to flow, save shape, or source-of-truth ownership, stop and report it instead of continuing.

## Task

1. Read `Docs/MAP_RUNTIME_STATE_EXTRACTION_PLAN.md`. If W0-06 has not yet removed the duplicate under `Docs/Promts/`, stop and do W0-06 first.
2. Execute the extraction plan step by step. Each extracted module must keep the same owner — `MapRuntimeState` delegates to it, callers still go through `MapRuntimeState`.
3. Each step must leave the suite green before the next step starts. If a step cannot stay green, stop and surface the blocker.
4. After extraction, `map_runtime_state.gd` must drop below its current `HOTSPOT_FILE_LINE_LIMITS` cap (2397) with visible headroom. Update the cap to reflect the new baseline in the same patch.
5. Save roundtrip: dump, quit, reload. The reloaded map-runtime payload must equal the pre-dump payload field-for-field. Surface any diff.

## Non-goals

- Do not change any persisted field.
- Do not move ownership to a new autoload.
- Do not redesign the hamlet phase-split (that is `D-043` / `W1-05`).
- Do not introduce a new event family.

## Report format

- escalate-first statement (the four answers above) as the first section
- step-by-step extraction log with line counts after each step
- save roundtrip diff summary
- final line counts for `map_runtime_state.gd` and every new helper file
- validator cap updates
- full suite + scene isolation result
