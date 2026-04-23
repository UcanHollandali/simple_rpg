# Prompt 15 - Map Runtime Procedural Grammar

Use this prompt pack only after Prompt 14 is closed green.
This is the first implementation pack in the reopened `14-20` wave.
Treat this as guarded/high-risk runtime work.
If save shape, flow state, or owner meaning must move, stop and say `escalate first`.

Checked-in filename note:
- this pack lives at `Docs/Archive/Prompts/2026-04-23-closed-green-prompt-packs/15_map_runtime_local_graph.md`
- checked-in filename and logical queue position now match Prompt `15`

Read first:
- `AGENTS.md`
- `Docs/DOC_PRECEDENCE.md`
- `Docs/HANDOFF.md`
- `Docs/ROADMAP.md`
- `Docs/MAP_CONTRACT.md`
- `Docs/MAP_TOPOLOGY_LOCAL_GRAPH_DESIGN.md`
- `Docs/SOURCE_OF_TRUTH.md`
- `Docs/SAVE_SCHEMA.md`
- `Docs/TEST_STRATEGY.md`

Primary write surface:
- `Game/RuntimeState/map_runtime_state.gd`
- `Tests/test_map_runtime_state.gd`

Read-only context:
- `Game/RuntimeState/map_scatter_graph_tools.gd`
- `Game/RuntimeState/map_runtime_graph_codec.gd`
- `Game/RuntimeState/map_runtime_local_state_helper.gd`
- `Game/Application/run_session_coordinator.gd`
- map-related tests that verify progression/flow continuity

## Goal

Redesign runtime graph truth from `free scatter that later needs layout rescue` toward `template-driven procedural grammar` while preserving the stage guarantee floor and the current realized-graph save payload shape.

## Direction Statement

- `MapRuntimeState` stays the graph-truth owner
- save payload shape stays unchanged by default
- the current stage guarantee floor stays intact
- graph generation should be:
  - blueprint/template-driven
  - local and bounded
  - readable on a fixed portrait board
  - deterministic per seed
- topology changes must land before family placement, camera reset, or layout/world-fill convergence

## Grammar Requirements

- select a stage blueprint before real board coordinates exist
- build an abstract graph from that blueprint
- keep degree caps and limited reconnects explicit
- reject long-span edge logic as a default behavior
- preserve controlled variation through:
  - blueprint choice
  - local graph variation
  - placement-ready jitter metadata if needed
- do not offload randomness quality to later camera/layout tricks

## Hard Guardrails

- No save-schema shape change unless the pack explicitly stops with `escalate first`.
- No flow-state change.
- No owner move into UI/scenes.
- No asset work.
- No `UiAssetPaths` change.
- No silent widening into family placement or layout rescue logic.
- Do not widen this topology pack into support/side-quest local-state helper redesign unless a verified blocker forces escalation.

## Validation

- topology invariants
- deterministic seed sweep
- `Tests/test_map_runtime_state.gd`
- `py -3 Tools/validate_architecture_guards.py`
- explicit full-suite checkpoint before closeout

## Done Criteria

- graph remains connected
- blueprint/template choice is explicit in the generation model
- node count / branch envelope / degree cap stay valid
- long-span edge behavior is explicitly constrained
- start remains a readable center-local anchor
- stage guarantee floor remains intact
- save shape remains unchanged, or the pack stops with `escalate first`

## Copy/Paste Parts

### Part A - Runtime Baseline Audit

```text
Apply only Prompt 15 Part A.

Scope:
- Re-audit the checked-out runtime topology truth before patching.
- Record:
  - current generation stages
  - current branch/spur shape
  - current reconnect expectations
  - current degree envelope
  - current invariant/test locks
- Restate the continuation gate:
  - touched owner layer
  - authority docs
  - impact: runtime truth / save shape / asset-provenance
  - minimum validation set

Do not:
- patch code in Part A
- weaken tests

Validation:
- validate_architecture_guards

Report:
- exact invariants currently locked by code/tests
- explicit note whether this pack can proceed without `escalate first`
```

### Part B - Procedural Grammar Redesign

```text
Apply only Prompt 15 Part B.

Scope:
- Redesign Game/RuntimeState/map_runtime_state.gd topology generation toward:
  - template-driven procedural grammar
  - abstract graph before board placement
  - rooted local graph
  - depth-band progression
  - mostly local forward edges
  - degree cap
  - limited merge/reconnect
  - no extreme cross-map edge spans
- Preserve:
  - stage profile ids
  - total node count
  - realized-graph save payload shape
  - stage guarantee floor
  - current owner meaning

Do not:
- move graph truth out of MapRuntimeState
- add new save fields
- change flow states
- widen into family placement logic except the minimum needed to keep topology output consumable

Validation:
- targeted topology assertions
- deterministic seed sweep
- validate_architecture_guards
- full suite checkpoint

Report:
- files changed
- old vs new topology model in one short paragraph
- explicit confirmation that save shape stayed unchanged
```

### Part C - Test Lock Refresh

```text
Apply only Prompt 15 Part C.

Scope:
- Update Tests/test_map_runtime_state.gd so it locks the new procedural-grammar invariants without overfitting to stale scatter details.
- Keep or replace old expectations consciously; do not just delete them.
- Add assertions for:
  - connectedness
  - deterministic seed repeat
  - degree cap
  - long-span edge rejection intent
  - readable opening shell
  - blueprint/template sanity

Do not:
- weaken the stage guarantee floor
- remove tests without replacing the covered behavior

Validation:
- targeted map runtime tests
- validate_architecture_guards
- explicit full-suite checkpoint

Report:
- which old test locks were retired
- which new invariants replaced them
- explicit pass/fail summary
```

### Part D - Closeout Sync

```text
Apply only Prompt 15 Part D.

Scope:
- Update Docs/HANDOFF.md and Docs/ROADMAP.md with the landed runtime-topology truth only if Parts A-C are green.
- Keep docs truthful about what changed and what is still deferred to Prompt 16-20.

Do not:
- claim family placement, fixed-board reset, layout convergence, or asset hookup is done
- touch asset wording beyond keeping Prompt 19 last and Prompt 20 as the audit gate

Validation:
- markdown/internal link sanity
- validate_architecture_guards

Report:
- files changed
- remaining risks before Prompt 16
```
