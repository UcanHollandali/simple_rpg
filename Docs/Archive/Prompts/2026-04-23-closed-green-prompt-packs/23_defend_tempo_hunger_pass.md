# Prompt 23 - Defend Tempo Hunger Pass

Use this prompt pack only after Prompt 21 is closed green.
This is guarded combat-rule work inside the existing combat identity.
It does not open techniques, hand-slot swap, or advanced enemy grammar.

Checked-in filename note:
- this pack lives at `Docs/Archive/Prompts/2026-04-23-closed-green-prompt-packs/23_defend_tempo_hunger_pass.md`
- checked-in filename and logical queue position now match Prompt `23`

Read first:
- `AGENTS.md`
- `Docs/DOC_PRECEDENCE.md`
- `Docs/HANDOFF.md`
- `Docs/ROADMAP.md`
- `Docs/COMBAT_RULE_CONTRACT.md`
- `Docs/TEST_STRATEGY.md`

## Continuation Gate

- touched owner layer: `Game/Core/`, `Game/Application/`, `Game/UI/`, docs
- authority doc: `Docs/COMBAT_RULE_CONTRACT.md`
- impact: runtime truth `yes`; save shape `no`; asset provenance `no`
- minimum validation set: `py -3 Tools/validate_architecture_guards.py`, targeted combat tests, explicit full-suite checkpoint

## Context Statement

Current combat already exposes `Defend`, but the next safe improvement is not a new combat verb.
It is making `Defend` a real decision:

- stronger immediate safety than a routine attack turn
- explicit attrition/tempo cost
- readable copy so the player understands the tradeoff

The first pass should stay conservative and readable.
Do not jump straight to a punishing `+2` or `+3` hunger tax as the default assumption.

## Goal

Rebalance `Defend` so it becomes a meaningful safe-play choice with a visible tempo/hunger tradeoff inside the current combat loop.

## Direction Statement

- keep `Attack` and `Defend` as the core action pair
- make `Defend` more protective than it is today
- make that protection carry an explicit attrition cost
- prefer a first-pass `+1` extra hunger cost over harsher defaults unless playtest evidence says otherwise
- keep the rule easy to explain in combat copy and log messaging

## Primary Write Surface

- `Game/Core/combat_resolver.gd`
- `Game/Application/combat_flow.gd`
- `Game/UI/combat_presenter.gd`
- `Game/UI/combat_copy_formatter.gd`
- `Game/UI/combat_guard_badge.gd` if guard-state presentation changes
- `Game/UI/hunger_warning_toast.gd` if hunger-cost feedback or threshold emphasis changes
- `Docs/COMBAT_RULE_CONTRACT.md`
- targeted combat tests

## Risk Lane / Authority Docs

- lane: guarded medium-risk mechanic tuning inside the existing combat contract
- authority doc: `Docs/COMBAT_RULE_CONTRACT.md`
- if the change needs a new top-level action, new save-safe combat state, or a new flow state, stop and say `escalate first`

## Hard Guardrails

- No new combat action family.
- No technique slot or trainer delivery.
- No enemy-intent grammar expansion in this pack.
- No save/schema change.
- No flow-state change.
- No owner move.
- No silent copy-only change that hides a rule shift without updating the contract doc.

## Out Of Scope / Escalation Triggers

Out of scope here:

- hand-slot swap
- stage-count changes
- trainer node family
- combat-time gear legality changes
- new status ownership rules

If the desired tuning requires:

- a new combat verb
- combat save support
- new enemy intent effects
- inventory owner changes

stop and say `escalate first`.

## Validation

- `py -3 Tools/validate_architecture_guards.py`
- `Tests/test_combat_spike.gd`
- `Tests/test_combat_safe_menu.gd`
- `Tests/test_phase2_loop.gd`
- any new targeted defend- or hunger-specific tests added in the same patch
- `Tools/run_godot_scene_isolation.ps1 -ScenePath scenes/combat.tscn` if combat scene wiring changes
- explicit full-suite checkpoint

## Done Criteria

- `Defend` is stronger and more legible
- `Defend` carries an explicit tempo/hunger tradeoff
- combat copy and feedback surfaces explain the new tradeoff truthfully
- no new action family or save/flow behavior lands
- `Docs/COMBAT_RULE_CONTRACT.md` matches the shipped rule

## Copy/Paste Parts

### Part A - Defend Baseline Audit

```text
Apply only Prompt 23 Part A.

Scope:
- Audit the current Defend rule and its current combat copy.
- Record:
  - current guard behavior
  - current hunger interaction
  - current UI/copy surfaces that describe Defend
  - where the current rule fails to produce a real decision

Do not:
- patch code in Part A

Validation:
- validate_architecture_guards
- readback only

Report:
- confirmed current Defend rule
- confirmed copy gaps
- explicit separation between facts and assumptions
```

### Part B - Defend Rule Tune

```text
Apply only Prompt 23 Part B.

Scope:
- Rebalance Defend inside the existing combat loop.
- Required direction:
  - stronger immediate protection
  - explicit attrition/tempo cost
  - first-pass default should prefer +1 extra hunger cost unless evidence supports harsher tuning

Do not:
- add a new action
- widen into technique or hand-slot swap work
- hide a mechanic change inside copy-only edits
- touch save shape or flow state

Validation:
- validate_architecture_guards
- targeted combat tests
- full suite checkpoint

Report:
- files changed
- old vs new Defend rule in one short paragraph
- explicit confirmation that no new combat action family was added
```

### Part C - Contract And Test Sync

```text
Apply only Prompt 23 Part C.

Scope:
- Update Docs/COMBAT_RULE_CONTRACT.md and the targeted combat tests to match the landed Defend rule.
- Lock:
  - stronger Defend protection
  - explicit hunger/tempo tradeoff
  - no broader combat-loop expansion

Do not:
- weaken coverage
- leave stale old-rule wording behind

Validation:
- validate_architecture_guards
- targeted combat tests
- full suite checkpoint

Report:
- files changed
- old test locks retired
- new test locks added
- pass/fail summary
```
