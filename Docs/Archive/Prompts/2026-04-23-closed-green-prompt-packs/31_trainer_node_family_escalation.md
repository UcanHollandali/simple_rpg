# Prompt 31 - Trainer Node Family Escalation

Use this prompt pack only after Prompt 27 is closed green, or after Prompt 26 only if Prompt 26 already proved that the existing-support-surface delivery model cannot safely reach implementation.
This is an explicit `escalate first` docs/spec pack.
It does not add a new node family by itself.

Checked-in filename note:
- this pack lives at `Docs/Archive/Prompts/2026-04-23-closed-green-prompt-packs/31_trainer_node_family_escalation.md`
- checked-in filename and logical queue position now match Prompt `31`

Read first:
- `AGENTS.md`
- `Docs/DOC_PRECEDENCE.md`
- `Docs/HANDOFF.md`
- `Docs/ROADMAP.md`
- `Docs/MAP_CONTRACT.md`
- `Docs/SUPPORT_INTERACTION_CONTRACT.md`
- `Docs/COMBAT_RULE_CONTRACT.md`
- `Docs/SAVE_SCHEMA.md`
- `Docs/GAME_FLOW_STATE_MACHINE.md`
- `Docs/CONTENT_ARCHITECTURE_SPEC.md`
- `Docs/TEST_STRATEGY.md`

## Continuation Gate

- touched owner layer: docs only in Prompt 31
- authority doc: `Docs/MAP_CONTRACT.md`, `Docs/SUPPORT_INTERACTION_CONTRACT.md`, `Docs/COMBAT_RULE_CONTRACT.md`, `Docs/SAVE_SCHEMA.md`
- impact: runtime truth `no` in Prompt 31 itself; save shape `no` in Prompt 31 itself; asset provenance `no`
- minimum validation set: markdown/internal link sanity, `py -3 Tools/validate_architecture_guards.py`

## Context Statement

Prompt 26 deliberately prefers first-pass technique delivery through an existing support surface.
If that later proves insufficient, a dedicated `trainer` node family is not a small follow-up.
It can affect:

- node-family counts and pacing
- stage-local pathing and detours
- support vs map-family identity
- save payload for node-local state
- combat-side acquisition expectations

Prompt 31 exists so that expansion, if ever needed, is specified cleanly instead of slipping in as "just another node."

## Goal

Write the explicit spec for a dedicated `trainer` node family only if the existing-support delivery model is no longer enough.

## Direction Statement

- start from "why existing support delivery failed"
- keep stage-count and route-shape stability unless a separate future prompt proves otherwise
- define whether `trainer` is a support-family replacement, addition, or subtype
- define save/node-state expectations explicitly
- keep this pack docs-only

## Risk Lane / Authority Docs

- lane: high-risk escalate-first
- authority docs:
  - `Docs/MAP_CONTRACT.md`
  - `Docs/SUPPORT_INTERACTION_CONTRACT.md`
  - `Docs/COMBAT_RULE_CONTRACT.md`
  - `Docs/SAVE_SCHEMA.md`
  - `Docs/GAME_FLOW_STATE_MACHINE.md`
- if the spec implies stage-count growth, new flow states, or save-shape widening, state that directly instead of implying it away

## Hard Guardrails

- No runtime code change in Prompt 31.
- No node-family addition in Prompt 31.
- No save/schema change in Prompt 31.
- No stage-count change in Prompt 31.
- Do not rewrite current `hamlet` truth just to make `trainer` sound necessary.

## Out Of Scope / Escalation Triggers

Out of scope here:

- actual trainer-node implementation
- stage-count increase
- advanced enemy intents
- hand-slot swap

If the spec cannot stay clear without:

- new node-family quotas
- save-shape change
- new flow state
- map-runtime owner changes

record that explicitly as part of the spec.

## Validation

- markdown/internal link sanity
- touched-doc consistency readback
- `py -3 Tools/validate_architecture_guards.py`

## Done Criteria

- the case for or against a dedicated trainer node is explicit
- node-family implications are explicit
- save/runtime implications are explicit
- the fallback path remains "keep using existing support delivery" if the case is weak
- later implementation has a real spec instead of vague expansion pressure

## Copy/Paste Parts

### Part A - Necessity Audit

```text
Apply only Prompt 31 Part A.

Scope:
- Audit whether the existing support-surface delivery model from Prompt 26 is still insufficient after real implementation/playtest evidence from Prompt 27, or from a documented Prompt 26 proof that implementation cannot safely proceed.
- Record:
  - what current delivery does well
  - what it fails to provide
  - whether those failures truly require a new node family

Do not:
- patch runtime code in Part A
- start from the assumption that a trainer node must exist

Validation:
- validate_architecture_guards
- readback only

Report:
- explicit case for or against a dedicated trainer node
- strongest evidence on both sides
```

### Part B - Trainer Family Spec

```text
Apply only Prompt 31 Part B.

Scope:
- Only if Part A justified it, write the explicit trainer-node-family spec.
- Lock:
  - node-family identity
  - relationship to existing support families
  - map/pacing implications
  - node-local state needs
  - save/runtime implications

Do not:
- leave node-family quotas or placement implications vague
- imply stage-count growth unless you are explicitly escalating it

Validation:
- markdown/internal link sanity
- validate_architecture_guards

Report:
- exact new node-family proposal
- exact prerequisites for any future implementation wave
```

### Part C - Deferral Or Adoption Sync

```text
Apply only Prompt 31 Part C.

Scope:
- Sync the queue-facing docs with the outcome:
  - keep trainer deferred if the case stayed weak, or
  - record the dedicated trainer spec as a future explicit expansion lane if the case was justified

Do not:
- imply that Prompt 31 implemented anything
- remove the existing-support delivery path from history if it still remains the current truth

Validation:
- markdown/internal link sanity
- validate_architecture_guards

Report:
- files changed
- exact deferral or future-lane wording added
- explicit confirmation that Prompt 31 stayed docs-only
```
