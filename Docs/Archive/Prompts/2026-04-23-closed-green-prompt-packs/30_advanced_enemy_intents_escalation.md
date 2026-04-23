# Prompt 30 - Advanced Enemy Intents Escalation

Use this prompt pack only after Prompt 24 is closed green and only if broader enemy-intent expansion is still desired.
This is an explicit `escalate first` docs/spec pack.
It does not implement advanced enemy intent runtime by itself.

Checked-in filename note:
- this pack lives at `Docs/Archive/Prompts/2026-04-23-closed-green-prompt-packs/30_advanced_enemy_intents_escalation.md`
- checked-in filename and logical queue position now match Prompt `30`

Read first:
- `AGENTS.md`
- `Docs/DOC_PRECEDENCE.md`
- `Docs/HANDOFF.md`
- `Docs/ROADMAP.md`
- `Docs/COMBAT_RULE_CONTRACT.md`
- `Docs/CONTENT_ARCHITECTURE_SPEC.md`
- `Docs/SAVE_SCHEMA.md`
- `Docs/GAME_FLOW_STATE_MACHINE.md`
- `Docs/TEST_STRATEGY.md`

## Continuation Gate

- touched owner layer: docs only in Prompt 30
- authority doc: `Docs/COMBAT_RULE_CONTRACT.md`, `Docs/CONTENT_ARCHITECTURE_SPEC.md`, `Docs/SAVE_SCHEMA.md`
- impact: runtime truth `no` in Prompt 30 itself; save shape `no` in Prompt 30 itself; asset provenance `no`
- minimum validation set: markdown/internal link sanity, `py -3 Tools/validate_architecture_guards.py`

## Context Statement

Prompt 24 deliberately stayed inside the current narrow enemy grammar.
If the repo later wants:

- true `setup/pass`
- true `multi-hit`
- enemy self-buff / self-guard / armor-up
- broader enemy-side status behavior

that is not a content-only continuation.
It is a new combat grammar and runtime-ownership discussion.

## Goal

Write the explicit spec for advanced enemy-intent expansion so later implementation does not smuggle unsupported mechanics through content changes.

## Direction Statement

- treat advanced enemy intents as a new rule surface, not as "just more content"
- define owner boundaries before implementation
- state UI telegraph needs explicitly
- state save/continuity policy explicitly if phase or intent state would need persistence
- keep this pack docs-only

## Risk Lane / Authority Docs

- lane: high-risk escalate-first
- authority docs:
  - `Docs/COMBAT_RULE_CONTRACT.md`
  - `Docs/CONTENT_ARCHITECTURE_SPEC.md`
  - `Docs/SAVE_SCHEMA.md`
  - `Docs/GAME_FLOW_STATE_MACHINE.md`
- if the desired expansion implies new save-safe combat persistence or broader target-routing semantics, say so directly instead of hiding it in content language

## Hard Guardrails

- No runtime code change in Prompt 30.
- No save/schema change in Prompt 30.
- No fake claim that advanced intents are already supported.
- Do not weaken the current grammar wording just to make future ideas sound easier.

## Out Of Scope / Escalation Triggers

Out of scope here:

- actual advanced-intent implementation
- trainer/technique work
- hand-slot swap
- stage-count expansion

If the spec cannot stay clear without:

- new save shape
- new combat save-safe state
- new flow state
- new domain-event family

record that explicitly as part of the spec.

## Validation

- markdown/internal link sanity
- touched-doc consistency readback
- `py -3 Tools/validate_architecture_guards.py`

## Done Criteria

- advanced intent families are defined explicitly
- the required runtime-owner changes are stated explicitly
- the content grammar impact is stated explicitly
- save/flow implications are stated explicitly
- later implementation has a real spec instead of vague ambition

## Copy/Paste Parts

### Part A - Expansion Audit

```text
Apply only Prompt 30 Part A.

Scope:
- Audit which desired advanced enemy behaviors are impossible under the current truthful grammar.
- Focus on:
  - true setup/pass
  - true multi-hit
  - enemy self-buff / self-guard / armor-up
  - broader enemy-side status behavior

Do not:
- patch runtime code in Part A
- pretend current content can already express these behaviors

Validation:
- validate_architecture_guards
- readback only

Report:
- exact current-grammar limits
- exact desired behaviors that cross those limits
```

### Part B - Advanced Intent Spec

```text
Apply only Prompt 30 Part B.

Scope:
- Write the explicit advanced-intent spec.
- Lock:
  - intended new intent families
  - intended owner surfaces
  - intended content-grammar expansion
  - intended UI telegraph requirements
  - intended save/flow implications

Do not:
- under-specify target routing, persistence, or phase behavior
- frame the work as content-only if it is not

Validation:
- markdown/internal link sanity
- validate_architecture_guards

Report:
- exact new rule surfaces proposed
- exact risks and prerequisites for later implementation
```

### Part C - Deferral Sync

```text
Apply only Prompt 30 Part C.

Scope:
- Sync the queue-facing docs so advanced enemy intents stay explicitly deferred until a later approved implementation wave opens.

Do not:
- imply that Prompt 24 already covered these mechanics
- imply that implementation can proceed without this spec

Validation:
- markdown/internal link sanity
- validate_architecture_guards

Report:
- files changed
- exact deferral wording added
- explicit confirmation that Prompt 30 stayed docs-only
```
