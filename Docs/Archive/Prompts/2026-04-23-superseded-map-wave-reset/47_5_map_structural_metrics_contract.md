# Prompt 47.5 - Map Structural Metrics Contract

Use this prompt only after Prompt 47 is closed green.
This pack defines the sector, pocket, and corridor-specific metrics only after the sector grammar contract exists.

Checked-in filename note:
- this pack lives at `Docs/Promts/47_5_map_structural_metrics_contract.md`

Read first:
- `AGENTS.md`
- `Docs/DOC_PRECEDENCE.md`
- `Docs/MAP_CONTRACT.md`
- `Docs/TEST_STRATEGY.md`
- Prompt `43-47` outputs
- Prompt `57` baseline harness outputs

Preflight:
- touched owner layer: `Tests + Tools + docs`
- authority doc: `Docs/MAP_CONTRACT.md` plus `Docs/TEST_STRATEGY.md`
- impact: `runtime truth unchanged / save shape unchanged / asset-provenance unchanged by default`
- minimum validation set: `validate_architecture_guards + git diff --check`

## Goal

Lock the sector, pocket, and corridor-specific metrics after the sector grammar exists, so later implementation prompts can add them without inventing placeholder structure.

## Required Outcomes

- sector occupancy metrics
- sector diversity count
- vertical spread / top-heavy pressure metrics
- start-anchor placement and first-choice readability metrics
- visible symmetry / uniformity rejection metrics
- landmark pocket validation goals
- landmark clearing integrity goals
- icon-secondary readability checks
- route overlap and same-corridor conflict metrics
- outward lane count expectations
- support detour readability metrics
- key/boss late-pressure lane separation expectations
- seed-variance checks so different seeds do not collapse into one repeated occupancy silhouette

## Hard Guardrails

- Do not patch runtime in Prompt `47.5`.
- Do not invent metrics that conflict with the sector grammar contract.
- Do not turn metrics into a substitute for screenshot review.

## Validation

- `py -3 Tools/validate_architecture_guards.py`
- `git diff --check`

## Done Criteria

- structural metrics are defined after the sector grammar, not before
- later implementation prompts know which metrics they must satisfy
- baseline harness and structural metrics no longer conflict

## Copy/Paste Parts

### Part A - Structural Metrics Spec

```text
Apply only Prompt 47.5 Part A.

Scope:
- Define the sector, pocket, and corridor-specific metrics that follow from Prompt 47.

Do not:
- patch runtime code
- write placeholder tests that guess at future structure

Validation:
- validate_architecture_guards

Report:
- exact structural metrics chosen
- exact relationship between baseline Prompt 57 checks and these later metrics
- any metric that still appears too unstable and should wait for implementation readback
```

### Part B - Metrics/Test Strategy Sync

```text
Apply only Prompt 47.5 Part B.

Scope:
- Sync only the closest docs or test-strategy notes needed so later prompts can add the structural metrics safely.

Do not:
- widen into runtime implementation

Validation:
- validate_architecture_guards
- git diff --check

Report:
- files changed
- exact structural metrics wording landed
- exact later prompts expected to implement or consume these metrics
```
