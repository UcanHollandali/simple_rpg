# Prompt 27 - Technique Runtime MVP

Use this prompt pack only after Prompt 26 is closed green.
This is guarded runtime/content work that depends on Prompt 26 being decision-complete.
Do not start this pack if Prompt 26 left command-family, delivery, or continuity ownership ambiguous.

Checked-in filename note:
- this pack lives at `Docs/Archive/Prompts/2026-04-23-closed-green-prompt-packs/27_technique_runtime_mvp.md`
- checked-in filename and logical queue position now match Prompt `27`

Read first:
- `AGENTS.md`
- `Docs/DOC_PRECEDENCE.md`
- `Docs/HANDOFF.md`
- `Docs/ROADMAP.md`
- `Docs/COMBAT_RULE_CONTRACT.md`
- `Docs/SUPPORT_INTERACTION_CONTRACT.md`
- `Docs/SAVE_SCHEMA.md`
- `Docs/GAME_FLOW_STATE_MACHINE.md`
- `Docs/CONTENT_ARCHITECTURE_SPEC.md`
- `Docs/TEST_STRATEGY.md`
- `Docs/Archive/Prompts/2026-04-23-closed-green-prompt-packs/26_support_training_delivery_contract.md`

## Continuation Gate

- touched owner layer: `Game/Application/`, `Game/Core/`, `Game/UI/`, `scenes/`, content, docs
- authority doc: the exact contract written by Prompt 26 plus `Docs/COMBAT_RULE_CONTRACT.md`, `Docs/SUPPORT_INTERACTION_CONTRACT.md`, and `Docs/SAVE_SCHEMA.md`
- impact: runtime truth `yes`; save shape `default no unless Prompt 26 explicitly approved additive continuity`; asset provenance `no`
- minimum validation set: `py -3 Tools/validate_architecture_guards.py`, `py -3 Tools/validate_content.py` if content definitions change, targeted combat/support tests, explicit full-suite checkpoint

## Context Statement

Prompt 27 is not freeform feature exploration.
It is the narrow implementation of the exact technique shape approved in Prompt 26.

Default target shape:

- limited-use techniques
- tactical, intent-answering behavior
- no persistent top-level two-button skill bar
- no dedicated trainer node family
- technique definition and effect-resolution ownership exactly as Prompt 26 approved it
- explicit support-acquisition UI with a small choice set and visible `skip` path
- explicit combat action-area affordance for each available technique the player can currently use

The first candidate technique set should remain narrow:

- `cleanse/remove effect`
- `ignore armor`
- `lifesteal`
- `next turn double attack`

`stun` is not default in this MVP unless Prompt 26 approved it explicitly.

## Goal

Ship the first playable technique system inside the contract approved by Prompt 26, while keeping combat readable and keeping the repo out of a card-battle or open-ended action-bar expansion.

## Direction Statement

- implement only the minimum technique lane approved by Prompt 26
- keep top-level combat surface compact
- techniques should answer specific threat patterns, not become generic damage spam
- acquisition should use the approved support surface only
- persistence should follow the explicit continuity policy from Prompt 26
- if a technique is usable in combat, the player must see a clear tap target, remaining-use state, and disabled/unavailable state in the combat action area
- do not bury technique use behind long-press, tooltip-only UI, combat log entries, or the generic inventory lane

## Primary Write Surface

- `Game/Application/combat_flow.gd`
- `Game/Core/combat_resolver.gd` only if the approved technique effects truly need it
- `Game/UI/combat_presenter.gd`
- `Game/UI/combat_scene_ui.gd`
- `Game/UI/support_interaction_presenter.gd`
- `scenes/combat.gd`
- `scenes/support_interaction.gd`
- the exact authored content surface approved by Prompt 26
- `Docs/COMBAT_RULE_CONTRACT.md`
- `Docs/SUPPORT_INTERACTION_CONTRACT.md`
- `Docs/SAVE_SCHEMA.md` only if Prompt 26 explicitly approved additive continuity

## Risk Lane / Authority Docs

- lane: guarded runtime/content work after an explicit escalate-first spec
- authority docs:
  - Prompt 26's approved contract
  - `Docs/COMBAT_RULE_CONTRACT.md`
  - `Docs/SUPPORT_INTERACTION_CONTRACT.md`
  - `Docs/CONTENT_ARCHITECTURE_SPEC.md` if Prompt 26 approved content-authored technique definitions
  - `Docs/SAVE_SCHEMA.md`
- if implementation pressure now implies a new flow state, save-shape widening beyond the approved contract, or a persistent top-level skill bar, stop and say `escalate first`

## Hard Guardrails

- No dedicated trainer node family.
- No persistent top-level two-button skill bar unless Prompt 26 explicitly approved it.
- No `stun` by default unless Prompt 26 explicitly approved it.
- No hand-slot swap work in this pack.
- No stage-count change.
- No silent save-shape widening.

## Out Of Scope / Escalation Triggers

Out of scope here:

- advanced enemy intents
- dedicated trainer node family
- left/right-hand swap
- broader buildcraft systems

If the approved technique shape cannot land without:

- a new flow state
- a new node family
- non-additive save migration
- broader combat owner rewrites

stop and say `escalate first`.

## Validation

- `py -3 Tools/validate_architecture_guards.py`
- `py -3 Tools/validate_content.py` if content definitions changed
- `Tests/test_support_interaction.gd`
- `Tests/test_support_node_persistence.gd`
- `Tests/test_combat_spike.gd`
- `Tests/test_combat_safe_menu.gd`
- `Tests/test_phase2_loop.gd`
- portrait screenshots of the support-acquisition surface and combat action area after the technique UI lands
- explicit full-suite checkpoint

## Done Criteria

- techniques work according to Prompt 26's contract
- acquisition works through the approved support surface
- technique definition and effect-resolution ownership stay inside the approved lane
- combat UI stays readable
- support UI clearly shows technique choices and `skip`
- combat UI clearly shows technique tap targets, availability, and remaining-use state
- no persistent trainer node or top-level action-bar sprawl appears
- docs and tests describe the landed behavior truthfully

## Copy/Paste Parts

### Part A - Contract Readback Audit

```text
Apply only Prompt 27 Part A.

Scope:
- Re-read the exact contract approved by Prompt 26 before patching code.
- Confirm:
  - delivery surface
  - technique definition surface
  - technique effect-resolution owner
  - usage-limit policy
  - persistence policy
  - approved technique list
  - deferred technique list

Do not:
- patch code in Part A
- fill gaps with guesswork if Prompt 26 left ambiguity

Validation:
- validate_architecture_guards
- readback only

Report:
- exact implementation target
- any ambiguity that still blocks safe implementation
```

### Part B - Technique MVP Implementation

```text
Apply only Prompt 27 Part B.

Scope:
- Implement the minimum technique runtime approved by Prompt 26.
- Keep the first technique list narrow and tactical.
- Respect the approved acquisition and persistence rules exactly.
- Ship the required support-acquisition UI and combat action-area UI in the same patch.

Do not:
- invent a broader skill-bar system
- add a dedicated trainer node family
- add stun unless it was explicitly approved
- hide technique use inside generic inventory or tooltip-only UI
- widen into hand-slot swap or advanced enemy-intent work

Validation:
- validate_architecture_guards
- validate_content if definitions changed
- targeted combat/support tests
- capture portrait screenshots of the support-acquisition UI and combat action area
- full suite checkpoint

Report:
- files changed
- technique list shipped
- screenshot paths
- explicit confirmation that the pack stayed inside Prompt 26's contract
```

### Part C - Contract And Test Sync

```text
Apply only Prompt 27 Part C.

Scope:
- Update the closest docs and tests to match the landed technique MVP.
- At minimum, refresh:
  - combat rule wording
  - support delivery wording
  - content architecture wording if Prompt 26 approved content-authored technique definitions
  - save wording only if Prompt 26 explicitly approved additive continuity

Do not:
- leave vague wording about command-family ownership
- overstate the system as a broader skill-build layer

Validation:
- validate_architecture_guards
- validate_content if definitions changed
- targeted tests
- full suite checkpoint

Report:
- files changed
- new test locks added
- any intentionally deferred technique ideas
```

### Part D - Technique UI Review

```text
Apply only Prompt 27 Part D.

Scope:
- Review the landed technique UI in both support acquisition and combat.
- Verify:
  1. the player can discover technique acquisition without a hidden submenu
  2. the player can see a clear `skip` option when offered techniques
  3. combat-usable techniques appear as clear tap targets in the action area
  4. remaining-use or consumed-state feedback is visible
  5. unavailable techniques do not read like broken buttons
  6. the combat surface did not turn into a sprawling action bar

If a checkpoint fails:
- open only a narrow follow-up in the same support/combat UI owner scope

Validation:
- validate_architecture_guards if code changed
- targeted tests if code changed
- full suite optional only if Part D itself is docs/screenshots only

Report:
- screenshot paths
- pass/fail per checkpoint
- any follow-up tuning still needed
```
