# Prompt 44 - Map Wave Contract Confirmation And Scope Lock

Use this prompt only after Prompt 43 is closed green.
The `43-62` wave is already open on this snapshot.
Prompt `44` confirms and tightens the implementation contract; it does not reopen the queue a second time.

Checked-in filename note:
- this pack lives at `Docs/Promts/44_map_wave_contract_confirmation_scope_lock.md`

Read first:
- `AGENTS.md`
- `Docs/DOC_PRECEDENCE.md`
- `Docs/HANDOFF.md`
- `Docs/ROADMAP.md`
- `Docs/MAP_CONTRACT.md`
- `Docs/SOURCE_OF_TRUTH.md`
- `Docs/Promts/43_map_full_system_audit_failure_naming.md`

Preflight:
- touched owner layer: `workflow/docs + queue/scope surfaces`
- authority doc: `Docs/MAP_CONTRACT.md`
- impact: `runtime truth unchanged / save shape unchanged / asset-provenance unchanged`
- minimum validation set: `markdown/internal link sanity + validate_architecture_guards`

## Goal

Lock the new map wave so implementation prompts do not drift into vague "readability polish."

The explicit target is:

- road network first
- landmark pockets second
- full board usage
- small-world traversal feel
- candidate asset spike only after structure is green

## Direction Statement

- scope lock first
- docs-only in this prompt
- preserve historical closure of Prompt `14-20`
- keep `43-62` as a new continuation wave
- make in-scope / out-of-scope explicit
- make execution order explicit even where the prompt numbering is intentionally non-numeric
- if a later pack must be inserted without renumbering the whole wave, use interstitial numbering such as `43.5`, `44.5`, or `50.5`
- freeze the spec after Prompt `47.5` unless a real blocker is discovered
- after that freeze point, new design-rule ideas do not enter the wave silently; they need an explicit interstitial prompt justified by blocker evidence
- lock side-by-side replacement:
  - new sector/layout/router lane first
  - old presentation chain may survive as wrapper/orchestrator/fallback temporarily
  - default switch only after screenshot + tests + integrated review are green
  - Prompt `58` owns the green-switch decision
  - Prompt `60` verifies final default-lane truth before cleanup prompts open

## Hard Guardrails

- No runtime patch in Prompt `44`.
- No save/flow/owner change.
- Do not reopen old prompt waves in place.
- Do not treat in-place nudging of the old scatter chain as the default replacement strategy.

## Validation

- markdown/internal link sanity
- `py -3 Tools/validate_architecture_guards.py`

## Done Criteria

- scope drift is reduced before runtime work starts
- active queue surfaces describe the same target
- out-of-scope items are explicit
- side-by-side replacement and non-numeric execution order are explicit

## Copy/Paste Parts

### Part A - Scope Lock Review

```text
Apply only Prompt 44 Part A.

Scope:
- Review Prompt 43 findings and lock the exact implementation scope and execution order for Prompt 45-62.

Required outcomes:
- strong final target is stated explicitly
- preserved boundaries are stated explicitly
- out-of-scope items are stated explicitly
- side-by-side replacement contract is stated explicitly
- spec-freeze point is stated explicitly
- Prompt 57 baseline harness is placed before implementation prompts
- Prompt 56 candidate art is placed after the first integrated structural review

Do not:
- patch runtime
- widen into authority-doc rewrites outside the touched queue/context surfaces

Validation:
- validate_architecture_guards

Report:
- final in-scope list
- final out-of-scope list
- exact side-by-side replacement rule
- exact execution order
- exact items that stay behind `escalate first`
```

### Part B - Queue And Context Sync

```text
Apply only Prompt 44 Part B.

Scope:
- Narrow docs-only sync on:
  - `Docs/ROADMAP.md`
  - `Docs/HANDOFF.md`
  - `Docs/Promts/README.md`
if Prompt 43 exposed wording drift.

Do not:
- rewrite authority docs in this part
- patch runtime

Validation:
- markdown/internal link sanity
- validate_architecture_guards

Report:
- files changed
- exact scope/queue wording updated
- explicit confirmation that Prompt 14-20 stayed historical and closed
```
