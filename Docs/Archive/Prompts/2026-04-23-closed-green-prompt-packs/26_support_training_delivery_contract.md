# Prompt 26 - Support Training Delivery Contract

Use this prompt pack only after Prompt 24 and Prompt 25 are closed green.
This is an explicit `escalate first` docs/spec pack.
It does not implement techniques or create a new support-node family by itself.

Checked-in filename note:
- this pack lives at `Docs/Archive/Prompts/2026-04-23-closed-green-prompt-packs/26_support_training_delivery_contract.md`
- checked-in filename and logical queue position now match Prompt `26`

Read first:
- `AGENTS.md`
- `Docs/DOC_PRECEDENCE.md`
- `Docs/HANDOFF.md`
- `Docs/ROADMAP.md`
- `Docs/COMBAT_RULE_CONTRACT.md`
- `Docs/SUPPORT_INTERACTION_CONTRACT.md`
- `Docs/MAP_CONTRACT.md`
- `Docs/SAVE_SCHEMA.md`
- `Docs/GAME_FLOW_STATE_MACHINE.md`
- `Docs/CONTENT_ARCHITECTURE_SPEC.md`
- `Docs/TEST_STRATEGY.md`

## Continuation Gate

- touched owner layer: docs only in Prompt 26
- authority doc: `Docs/SUPPORT_INTERACTION_CONTRACT.md`, `Docs/COMBAT_RULE_CONTRACT.md`, `Docs/MAP_CONTRACT.md`, `Docs/SAVE_SCHEMA.md`
- impact: runtime truth `no` in Prompt 26 itself; save shape `no` in Prompt 26 itself; asset provenance `no`
- minimum validation set: markdown/internal link sanity, `py -3 Tools/validate_architecture_guards.py`

## Context Statement

The user-facing combat direction now wants limited-use tactical techniques and a training-style acquisition surface.
That is not routine content work.

In this repo, the risky parts are:

- adding a new combat command family
- choosing where training is delivered
- deciding whether technique ownership is runtime-only, save-backed, or visit-local
- deciding whether techniques are content-authored definitions, code-authored runtime entries, or a hybrid
- deciding which owner resolves technique effects during combat
- deciding what the player taps in combat and how training choices are shown in the support UI
- deciding whether `hamlet`, `blacksmith`, or another existing support surface should carry the first delivery

This prompt exists to make those decisions explicit before Prompt 27 touches runtime code.

## Goal

Write the explicit contract for how training/technique acquisition enters the game and how it is surfaced in UI, with a default bias toward an existing support surface instead of a brand-new node family.

## Direction Statement

- first delivery should prefer an existing support surface
- default candidate is `hamlet` unless the audit proves another existing support surface is materially better
- no dedicated `trainer` node family in this prompt
- no persistent top-level 2-slot skill bar by default
- techniques should stay constrained, tactical, and readable
- if combat-usable techniques exist, they must have an explicit tap target in the main combat action area; they must not hide in the log, tooltip, or inventory drawer
- training acquisition UI should stay lightweight: at most a small choice set plus `skip`, not a deep management screen
- save and flow impact must be stated directly, not implied

## Risk Lane / Authority Docs

- lane: high-risk escalate-first because this decision can imply a new combat command family, support behavior change, and save-sensitive continuity
- authority docs:
  - `Docs/SUPPORT_INTERACTION_CONTRACT.md`
  - `Docs/COMBAT_RULE_CONTRACT.md`
  - `Docs/MAP_CONTRACT.md`
  - `Docs/SAVE_SCHEMA.md`
  - `Docs/GAME_FLOW_STATE_MACHINE.md`
- if the desired shape needs a new node family, new flow state, or save-shape widening that is not explicitly written here, stop and say `escalate first`

## Hard Guardrails

- No runtime code change in Prompt 26.
- No save/schema change in Prompt 26.
- No new node family in Prompt 26.
- No technique implementation in Prompt 26.
- No hand-slot swap implementation in Prompt 26.
- Do not hide a new command family decision inside vague wording.

## Out Of Scope / Escalation Triggers

Out of scope here:

- technique runtime implementation
- persistent trainer node family
- stage-count increase
- advanced enemy-intent grammar

If the contract cannot stay clear without:

- new node family count
- new flow state
- new save schema shape
- new domain-event family

stop and record that explicitly instead of hand-waving it.

## Validation

- markdown/internal link sanity
- touched-doc consistency readback
- `py -3 Tools/validate_architecture_guards.py`

## Done Criteria

- the delivery surface is chosen explicitly
- acquisition timing and usage-limit policy are written explicitly
- technique definition surface and effect-resolution owner are written explicitly
- combat presentation surface and support-acquisition UI surface are written explicitly
- save/continuity policy is written explicitly
- Prompt 27 has a concrete implementation target instead of open design questions
- dedicated trainer-node work, if still desired, stays deferred behind Prompt 31

## Copy/Paste Parts

### Part A - Delivery Surface Audit

```text
Apply only Prompt 26 Part A.

Scope:
- Audit current support surfaces as candidates for first-pass training / technique delivery.
- Compare:
  - hamlet
  - blacksmith
  - merchant
  - rest
- Record which surface best fits:
  - thematic delivery
  - low UI complexity
  - existing save-safe support interaction behavior
  - low node-family risk

Do not:
- patch runtime code in Part A
- assume a dedicated trainer node is already justified

Validation:
- validate_architecture_guards
- readback only

Report:
- recommended delivery surface
- why the other candidates lost
- explicit note whether a dedicated trainer node is still unnecessary at this stage
```

### Part B - Contract Write-Up

```text
Apply only Prompt 26 Part B.

Scope:
- Write the explicit training/technique delivery contract for the first-pass implementation target.
- Lock:
  - delivery surface
  - acquisition timing
  - technique definition surface
  - technique effect-resolution owner
  - combat presentation surface
  - support-acquisition UI surface
  - whether the player keeps one or more techniques between combats
  - usage limit policy
  - whether continuity is runtime-only or save-backed
  - why persistent top-level skill-bar work is deferred

Default assumptions to preserve unless the audit disproves them:
- delivery through an existing support surface
- `hamlet` is the default first candidate
- limited-use techniques, not a persistent two-button skill bar

Do not:
- leave command-family ownership ambiguous
- imply a new node family
- imply a save-shape change without saying so directly

Validation:
- markdown/internal link sanity
- validate_architecture_guards

Report:
- exact contract decisions written
- exact open questions, if any remain
- explicit note whether Prompt 27 can now proceed without further product decisions
```

### Part C - Queue And Deferral Sync

```text
Apply only Prompt 26 Part C.

Scope:
- Sync the queue-facing docs so Prompt 27 has a clear implementation lane and Prompt 31 remains the deferred dedicated-trainer escalation pack.

Do not:
- overstate what Prompt 26 approved
- imply that the dedicated trainer node family is no longer needed forever if it was only deferred

Validation:
- markdown/internal link sanity
- validate_architecture_guards

Report:
- files changed
- exact queue wording updated
- explicit confirmation that Prompt 26 stayed docs-only
```
