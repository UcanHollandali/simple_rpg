# Prompt 28 - Hand-Slot Swap Contract

Use this prompt pack only after Prompt 27 is closed green.
This is an explicit `escalate first` docs/spec pack for combat-time hand-slot swap.
It does not implement the swap action by itself.

Checked-in filename note:
- this pack lives at `Docs/Archive/Prompts/2026-04-23-closed-green-prompt-packs/28_weapon_swap_contract.md`
- checked-in filename and logical queue position now match Prompt `28`

Read first:
- `AGENTS.md`
- `Docs/DOC_PRECEDENCE.md`
- `Docs/HANDOFF.md`
- `Docs/ROADMAP.md`
- `Docs/COMBAT_RULE_CONTRACT.md`
- `Docs/SAVE_SCHEMA.md`
- `Docs/GAME_FLOW_STATE_MACHINE.md`
- `Docs/TEST_STRATEGY.md`

## Continuation Gate

- touched owner layer: docs only in Prompt 28
- authority doc: `Docs/COMBAT_RULE_CONTRACT.md`, `Docs/SAVE_SCHEMA.md`, `Docs/GAME_FLOW_STATE_MACHINE.md`
- impact: runtime truth `no` in Prompt 28 itself; save shape `no` in Prompt 28 itself; asset provenance `no`
- minimum validation set: markdown/internal link sanity, `py -3 Tools/validate_architecture_guards.py`

## Context Statement

Combat-time hand-slot swap is not a cosmetic tweak in this repo.
It can affect:

- the top-level combat action surface
- durability failure behavior
- shield / dual-wield combat expectations
- legality messaging in combat UI
- inventory-owner interaction boundaries

Prompt 28 exists so Prompt 29 does not guess about any of that.

## Goal

Write the narrow hand-slot swap contract explicitly, with a default bias toward `right_hand` weapon change plus `left_hand` shield/offhand change that consumes the turn and keeps all other gear lanes locked.

## Direction Statement

- default first-pass shape:
  - `right_hand` and `left_hand`
  - exactly one hand-slot swap action per turn
  - consumes the turn
  - armor stays locked
  - belt stays locked
  - reorder stays locked
- `right_hand` swap candidates should come only from carried backpack weapon entries that are valid for `right_hand`
- `left_hand` swap candidates should come only from carried backpack shields or offhand-capable weapons that are valid for `left_hand`
- no swap affordance should appear for a slot when no eligible spare item exists for that slot
- the combat UI should use a narrow dedicated swap surface, not a full backpack manager
- the attack that breaks a weapon should still resolve first
- the broken state should matter on the following turn
- shield and dual-wield consequences should stay inside the current rule contract, not trigger a second combat-stance redesign in this pass
- combat UI must speak this rule plainly

## Risk Lane / Authority Docs

- lane: high-risk escalate-first because this can imply a new combat command family and inventory-owner touchpoints
- authority docs:
  - `Docs/COMBAT_RULE_CONTRACT.md`
  - `Docs/SAVE_SCHEMA.md`
  - `Docs/GAME_FLOW_STATE_MACHINE.md`
- if the contract would require armor/belt swap, reorder changes, multi-slot-in-one-action swap, or a save-safe combat-state change, stop and say `escalate first`

## Hard Guardrails

- No runtime code change in Prompt 28.
- No armor/belt swap.
- No reorder support.
- No multi-slot swap in one action.
- No save/schema change in Prompt 28.
- Do not hide command-family implications behind vague "interaction" wording.

## Out Of Scope / Escalation Triggers

Out of scope here:

- runtime implementation
- armor/belt swap
- broader shield/offhand rebalance beyond current rules
- trainer/technique work

If the contract cannot stay narrow without:

- broader inventory-owner rewrite
- new flow state
- combat save support
- broader offhand / shield legality expansion beyond the approved first-pass shape

stop and record that explicitly instead of proceeding.

## Validation

- markdown/internal link sanity
- touched-doc consistency readback
- `py -3 Tools/validate_architecture_guards.py`

## Done Criteria

- the swap action shape is explicit
- broken-weapon timing is explicit
- candidate-source, slot-coverage, and UI-surface rules are explicit
- UI wording expectations are explicit
- Prompt 29 has a concrete implementation target
- broader equipment-swap ideas remain deferred

## Copy/Paste Parts

### Part A - Current Loop Audit

```text
Apply only Prompt 28 Part A.

Scope:
- Audit the current combat loop around:
  - broken weapon fallback behavior
  - current locked equipment messaging
  - current shield / dual-wield combat implications
  - current inventory-owner touchpoints needed for a narrow swap

Do not:
- patch runtime code in Part A
- assume armor or belt swap is already justified

Validation:
- validate_architecture_guards
- readback only

Report:
- confirmed current broken-weapon flow
- confirmed current UI/legality surfaces
- exact reasons the default should stay hand-slot only (`right_hand` + `left_hand`, no armor/belt)
```

### Part B - Hand-Slot Swap Contract Write-Up

```text
Apply only Prompt 28 Part B.

Scope:
- Write the explicit first-pass combat hand-slot swap contract.
- Default contract:
  - right_hand and left_hand
  - exactly one hand-slot swap action per turn
  - full-turn cost
  - right_hand candidates only from carried backpack weapons valid for right_hand
  - left_hand candidates only from carried backpack shields or offhand-capable weapons valid for left_hand
  - no swap affordance for a slot when no eligible spare item exists for that slot
  - dedicated narrow combat swap surface, not a full backpack manager
  - attack that causes break still resolves
  - broken state matters on the next turn
  - no armor / belt / reorder opening
  - the narrow swap surface must stay visually tied to the main combat action area or equipment strip, not hidden behind a second modal

Do not:
- leave legality ambiguous
- imply broader swap support
- imply combat save support unless you are explicitly escalating it

Validation:
- markdown/internal link sanity
- validate_architecture_guards

Report:
- exact contract decisions written
- exact open questions, if any remain
- explicit confirmation that Prompt 29 can now proceed without new product decisions
```

### Part C - Queue Sync

```text
Apply only Prompt 28 Part C.

Scope:
- Sync the queue-facing docs so Prompt 29 has a clear narrow target and broader equipment-swap work remains deferred.

Do not:
- overstate what Prompt 28 approved
- imply that armor/belt or broader offhand/shield expansion is coming automatically next

Validation:
- markdown/internal link sanity
- validate_architecture_guards

Report:
- files changed
- exact queue wording updated
- explicit confirmation that Prompt 28 stayed docs-only
```
