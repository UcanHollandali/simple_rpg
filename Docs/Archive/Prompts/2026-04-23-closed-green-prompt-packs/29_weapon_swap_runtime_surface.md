# Prompt 29 - Hand-Slot Swap Runtime Surface

Use this prompt pack only after Prompt 28 is closed green.
This is guarded combat/runtime/UI work that depends on Prompt 28 being decision-complete.
Do not start this pack if Prompt 28 left legality, turn-cost, or break-timing wording ambiguous.

Checked-in filename note:
- this pack lives at `Docs/Archive/Prompts/2026-04-23-closed-green-prompt-packs/29_weapon_swap_runtime_surface.md`
- checked-in filename and logical queue position now match Prompt `29`

Read first:
- `AGENTS.md`
- `Docs/DOC_PRECEDENCE.md`
- `Docs/HANDOFF.md`
- `Docs/ROADMAP.md`
- `Docs/COMBAT_RULE_CONTRACT.md`
- `Docs/SAVE_SCHEMA.md`
- `Docs/TEST_STRATEGY.md`
- `Docs/Archive/Prompts/2026-04-23-closed-green-prompt-packs/28_weapon_swap_contract.md`

## Continuation Gate

- touched owner layer: `Game/Application/`, `Game/UI/`, `scenes/`, and the narrowest authoritative inventory owner surfaces required by Prompt 28
- authority doc: the exact contract written by Prompt 28 plus `Docs/COMBAT_RULE_CONTRACT.md` and `Docs/SAVE_SCHEMA.md`
- impact: runtime truth `yes`; save shape `default no`; asset provenance `no`
- minimum validation set: `py -3 Tools/validate_architecture_guards.py`, targeted combat/inventory tests, combat scene isolation if wiring changes, explicit full-suite checkpoint

## Context Statement

Prompt 29 is not freeform "make equipment usable in combat."
It is the narrow implementation of the exact first-pass hand-slot swap contract approved in Prompt 28.

Default target shape:

- `right_hand` and `left_hand`
- exactly one hand-slot swap action per turn
- consumes the turn
- no armor / belt / reorder changes
- `right_hand` candidates come only from carried backpack weapons valid for `right_hand`
- `left_hand` candidates come only from carried backpack shields or offhand-capable weapons valid for `left_hand`
- no swap affordance appears for a slot when no eligible spare item exists for that slot
- the swap surface is a narrow dedicated combat lane, not a full backpack manager
- broken weapon attack still resolves before the next-turn swap decision appears

The UI must stop pretending equipment is globally locked if one narrow swap surface is now truly legal.

## Goal

Implement the narrow combat-time hand-slot swap loop and present it honestly in the combat UI without widening into broader equipment-management work.

## Direction Statement

- implement only the narrow swap rule approved in Prompt 28
- keep `Quick Use` separate from hand-slot swap
- replace fake "locked equipment" messaging with truthful narrow legality messaging
- keep broader equipment lanes closed
- prefer the narrowest inventory-owner integration over new compatibility helpers
- keep swap candidates limited to eligible carried hand-slot items only
- keep the swap affordance visually close to the combat action area / equipment strip so it reads as a battle decision, not as buried inventory management

## Primary Write Surface

- `Game/Application/combat_flow.gd`
- `Game/UI/combat_presenter.gd`
- `Game/UI/combat_scene_ui.gd`
- `Game/UI/inventory_presenter.gd`
- `scenes/combat.gd`
- the narrowest authoritative inventory owner surface required to apply a hand-slot swap
- `Docs/COMBAT_RULE_CONTRACT.md`

## Risk Lane / Authority Docs

- lane: guarded runtime/UI work after an explicit escalate-first spec
- authority docs:
  - Prompt 28's approved contract
  - `Docs/COMBAT_RULE_CONTRACT.md`
  - `Docs/SAVE_SCHEMA.md`
- if implementation pressure now implies armor/belt swap, multi-slot-in-one-action swap, reorder support, or save-safe combat-state expansion, stop and say `escalate first`

## Hard Guardrails

- No armor or belt swap.
- No reorder support.
- No multi-slot swap in one action.
- No free swap.
- No silent save-shape widening.
- No new `RunState` compatibility accessor.

## Out Of Scope / Escalation Triggers

Out of scope here:

- broader shield/offhand rebalancing beyond current rules
- inventory drawer redesign outside the narrow combat-swap need
- trainer/technique work
- advanced enemy-intent work

If the approved swap shape cannot land without:

- broader inventory-owner redesign
- new flow state
- combat save support
- wider combat action-bar redesign

stop and say `escalate first`.

## Validation

- `py -3 Tools/validate_architecture_guards.py`
- `Tests/test_combat_safe_menu.gd`
- `Tests/test_phase2_loop.gd`
- any new targeted combat / inventory legality tests added in the same patch
- `Tools/run_godot_scene_isolation.ps1 -ScenePath scenes/combat.tscn` if scene wiring changed
- portrait screenshots of the combat action area / swap surface after the UI lands
- explicit full-suite checkpoint

## Done Criteria

- hand-slot swap works exactly as Prompt 28 specified
- broken-weapon timing is truthful
- the combat UI presents swap legality clearly
- the combat UI does not turn into a full backpack manager
- the swap affordance is visible per slot when eligible and absent when no spare eligible item exists for that slot
- broader equipment lanes remain locked
- docs and tests match the landed behavior truthfully

## Copy/Paste Parts

### Part A - Contract Readback Audit

```text
Apply only Prompt 29 Part A.

Scope:
- Re-read the exact hand-slot swap contract approved by Prompt 28 before patching code.
- Confirm:
  - right_hand / left_hand slot coverage
  - one-slot-per-turn rule
  - turn-cost rule
  - candidate-source rule
  - no-spare-item behavior per slot
  - broken-weapon timing
  - disallowed gear lanes

Do not:
- patch code in Part A
- fill gaps with guesswork if Prompt 28 left ambiguity

Validation:
- validate_architecture_guards
- readback only

Report:
- exact implementation target
- any ambiguity that still blocks safe implementation
```

### Part B - Runtime And UI Implementation

```text
Apply only Prompt 29 Part B.

Scope:
- Implement the narrow combat-time hand-slot swap rule approved by Prompt 28.
- Update the combat UI so the player sees:
  - what can be swapped
  - that the swap ends the turn
  - that armor/belt remain locked
  - that no swap option exists for a slot when no eligible spare item exists for that slot

Do not:
- widen into armor/belt support
- turn the combat equipment panel into a full inventory manager
- add save-shape changes

Validation:
- validate_architecture_guards
- targeted combat / inventory tests
- combat scene isolation if wiring changed
- capture portrait screenshots of the swap surface
- full suite checkpoint

Report:
- files changed
- exact surfaces that now present swap legality
- screenshot paths
- explicit confirmation that the pack stayed inside Prompt 28's contract
```

### Part C - Contract And Test Sync

```text
Apply only Prompt 29 Part C.

Scope:
- Update Docs/COMBAT_RULE_CONTRACT.md and the targeted tests to match the landed swap behavior.
- Refresh any combat UI wording that would otherwise still claim equipment is fully locked.

Do not:
- leave stale locked-equipment wording behind
- imply broader equipment swap support than what actually shipped

Validation:
- validate_architecture_guards
- targeted tests
- full suite checkpoint

Report:
- files changed
- old locks retired
- new locks added
- pass/fail summary
```

### Part D - Swap UI Review

```text
Apply only Prompt 29 Part D.

Scope:
- Review the landed combat-time hand-slot swap UI.
- Verify:
  1. the swap affordance is easy to find when eligible
  2. the swap affordance is absent per slot when no eligible spare item exists for that slot
  3. the player can tell the swap ends the turn
  4. the UI makes it clear that only hand slots can change and armor / belt remain locked
  5. the UI makes it clear that one swap action changes only one slot
  6. the surface does not read like a full inventory manager

If a checkpoint fails:
- open only a narrow follow-up in the same combat/inventory UI owner scope

Validation:
- validate_architecture_guards if code changed
- targeted tests if code changed
- full suite optional only if Part D itself is docs/screenshots only

Report:
- screenshot paths
- pass/fail per checkpoint
- any follow-up tuning still needed
```
