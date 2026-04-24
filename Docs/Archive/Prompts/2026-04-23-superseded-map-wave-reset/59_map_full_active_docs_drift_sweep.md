# Prompt 59 - Full Active Docs Drift Sweep

Use this prompt only after Prompt 56 is closed green.
This pack aligns the active docs with the shipped truth of the new map-system wave.

Checked-in filename note:
- this pack lives at `Docs/Promts/59_map_full_active_docs_drift_sweep.md`

Read first:
- `AGENTS.md`
- `Docs/DOC_PRECEDENCE.md`
- Prompt `43-58` outputs and the Prompt `56` outcome
- active docs under `Docs/`
- relevant root entry docs if they still point humans toward stale map truth

Preflight:
- touched owner layer: `active docs + root entry docs`
- authority doc: `Docs/DOC_PRECEDENCE.md`
- impact: `runtime truth unchanged / save shape unchanged / asset-provenance unchanged by default`
- minimum validation set: `internal doc consistency + validate_architecture_guards + git diff --check`

## Goal

Remove active-doc drift so future humans and agents do not continue using stale pre-wave map assumptions.

## Required Outcomes

- active `Docs/*` map direction stays aligned
- candidate asset lane is described truthfully
- structure-first asset-art order is described truthfully
- candidate-vs-final asset lane split is described truthfully
- validation expectations match the new wave
- playtest brief and ownership notes stay current
- archive remains non-authoritative

## Hard Guardrails

- Do not treat archive docs as authority.
- Do not open new docs unless unavoidable.
- Keep the active-doc set smaller and clearer, not noisier.

## Validation

- `py -3 Tools/validate_architecture_guards.py`
- `git diff --check`

## Done Criteria

- active docs no longer point continuations toward stale map assumptions
- map ownership, structure-first asset order, asset-candidate truth, and validation gates are consistent across active docs

## Copy/Paste Parts

### Part A - Drift Audit

```text
Apply only Prompt 59 Part A.

Scope:
- Audit active docs and relevant root entry docs for stale map-wave assumptions.

Do not:
- patch docs in Part A

Validation:
- validate_architecture_guards
- readback only

Report:
- exact doc drift found
- exact docs/functions of responsibility
- which drift is authority-level vs context-level
```

### Part B - Active Docs Sync

```text
Apply only Prompt 59 Part B.

Scope:
- Sync only the active docs and root entry docs justified by the Part A audit.

Do not:
- widen into archive cleanup
- add new docs unless clearly unavoidable

Validation:
- validate_architecture_guards
- git diff --check

Report:
- docs changed
- exact stale assumptions removed
- any remaining drift intentionally deferred
```

### Part C - Final Drift Readback

```text
Apply only Prompt 59 Part C.

Scope:
- Re-read the touched active docs and confirm they align with the new map-wave truth.

Do not:
- open another docs refactor

Validation:
- validate_architecture_guards

Report:
- confirmed / inferred / unknown
- remaining active-doc drift if any
- whether Prompt 60 can close the wave honestly
```
