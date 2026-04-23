# Prompt 16 - Map Family Assignment And Pacing

Use this prompt pack only after Prompt 15 is closed green.
This pack redesigns family placement after topology/grammar, not before it.
Treat this as guarded medium-risk gameplay/runtime work.

Checked-in filename note:
- this pack lives at `Docs/Archive/Prompts/2026-04-23-closed-green-prompt-packs/16_map_family_assignment_pacing.md`
- checked-in filename and logical queue position now match Prompt `16`

Read first:
- `AGENTS.md`
- `Docs/DOC_PRECEDENCE.md`
- `Docs/HANDOFF.md`
- `Docs/ROADMAP.md`
- `Docs/MAP_CONTRACT.md`
- `Docs/MAP_TOPOLOGY_LOCAL_GRAPH_DESIGN.md`
- `Docs/SOURCE_OF_TRUTH.md`
- `Docs/TEST_STRATEGY.md`
- `Game/RuntimeState/map_runtime_state.gd`
- `Game/RuntimeState/map_runtime_local_state_helper.gd`

Primary write surface:
- `Game/RuntimeState/map_runtime_state.gd`
- `Tests/test_map_runtime_state.gd`

## Goal

Place node families after topology through constrained-random role assignment so pacing is readable, quotas stay exact, and the final fixed-board layout has meaningful route choices to render.

## Direction Statement

- topology/grammar first, family placement second
- no flat random placement
- early combat/reward/support floor stays mandatory
- late key/boss floor stays mandatory
- event/hamlet/support should feel like route decisions, not arbitrary icon swaps
- family placement must stay compatible with the later fixed-board/playable-rect pass

## Placement Requirements

- preserve exact family quotas
- keep `event` and `hamlet` as real detours
- keep support opportunity pacing intentional
- bias key/boss into the late pressure region
- keep variation constrained and readable rather than purely shuffled

## Hard Guardrails

- No save shape change.
- No flow-state change.
- No owner move.
- No fixed-board/layout rescue work in this pack.
- No asset work.
- No weakening of family quotas or stage floor.
- Do not widen family-placement work into support/side-quest local-state helper redesign.

## Validation

- placement determinism
- family counts exact
- key-boss separation
- detour/support readability assertions
- `Tests/test_map_runtime_state.gd`
- explicit full-suite checkpoint

## Done Criteria

- family quotas stay exact
- early exposure floor remains true
- key and boss pacing remain late/readable
- support/rest lane produces a real route decision
- no full-random drift remains in placement logic

## Copy/Paste Parts

### Part A - Placement Baseline Audit

```text
Apply only Prompt 16 Part A.

Scope:
- Re-audit current family placement after Prompt 15.
- Record:
  - family quotas
  - early exposure floor
  - current role-scoring helpers
  - current pacing risks

Do not:
- patch code in Part A

Validation:
- validate_architecture_guards

Report:
- what is topology-driven now
- what still reads too sequential or too random
```

### Part B - Constrained Random Placement

```text
Apply only Prompt 16 Part B.

Scope:
- Redesign family assignment in Game/RuntimeState/map_runtime_state.gd so placement is topology-aware and constrained-random.
- Preserve:
  - exact family quotas
  - early combat + reward + support exposure
  - late key + boss
  - event and hamlet detour identity
  - compatibility with a fixed-board playable-rect layout target

Do not:
- flatten placement into pure depth order
- reintroduce flat random placement
- widen into camera/layout work
- change save or flow behavior

Validation:
- placement determinism
- family-count assertions
- detour/key/boss/support assertions
- full suite checkpoint

Report:
- files changed
- old vs new placement model in one short paragraph
- explicit confirmation that quotas stayed exact
```

### Part C - Test Refresh

```text
Apply only Prompt 16 Part C.

Scope:
- Update Tests/test_map_runtime_state.gd for the landed family-placement model.
- Lock:
  - exact family counts
  - early exposure floor
  - key/boss separation
  - event/hamlet detour sanity
  - support/rest route-decision intent

Do not:
- weaken coverage
- remove a behavior assertion without replacing it

Validation:
- targeted map runtime tests
- validate_architecture_guards
- explicit full-suite checkpoint

Report:
- old test locks retired
- new locks added
- pass/fail summary
```

### Part D - Closeout Sync

```text
Apply only Prompt 16 Part D.

Scope:
- Update Docs/HANDOFF.md and Docs/ROADMAP.md only after Parts A-C are green.
- Record that topology grammar landed in Prompt 15 and family placement/pacing landed in Prompt 16.
- Keep Prompt 17-20 clearly open.

Validation:
- markdown/internal link sanity
- validate_architecture_guards

Report:
- files changed
- remaining risks before Prompt 17
```
