# Prompt 33 - Combat Mechanic UI Audit

Use this prompt pack only after at least one mechanic-bearing combat pack has landed in the `21+` wave.
Typical trigger points:

- after Prompt `23` if Defend changed meaningfully
- after Prompt `27` if techniques landed
- after Prompt `29` if hand-slot swap landed

This is a narrow UI/readability audit and corrective pass.
It does not open new combat mechanics by itself.

Checked-in filename note:
- this pack lives at `Docs/Archive/Prompts/2026-04-23-closed-green-prompt-packs/33_combat_mechanic_ui_audit.md`
- checked-in filename and logical queue position now match Prompt `33`

Read first:
- `AGENTS.md`
- `Docs/DOC_PRECEDENCE.md`
- `Docs/HANDOFF.md`
- `Docs/ROADMAP.md`
- `Docs/COMBAT_RULE_CONTRACT.md`
- `Docs/TEST_STRATEGY.md`
- the exact landed mechanic prompt docs being audited, typically:
  - `Docs/Archive/Prompts/2026-04-23-closed-green-prompt-packs/23_defend_tempo_hunger_pass.md`
  - `Docs/Archive/Prompts/2026-04-23-closed-green-prompt-packs/27_technique_runtime_mvp.md`
  - `Docs/Archive/Prompts/2026-04-23-closed-green-prompt-packs/29_weapon_swap_runtime_surface.md`

## Continuation Gate

- touched owner layer: `Game/UI/`, `scenes/`, docs
- authority doc: `Docs/COMBAT_RULE_CONTRACT.md`, `Docs/TEST_STRATEGY.md`
- impact: runtime truth `no` by default; save shape `no`; asset provenance `no`
- minimum validation set: `py -3 Tools/validate_architecture_guards.py`, targeted combat/UI tests, combat scene isolation if wiring changes

## Context Statement

Combat mechanic packs can land correctly at the rule level and still feel weak if the player cannot read:

- what changed
- what is currently available
- what is unavailable and why
- what the turn-cost / usage-cost consequence is

Prompt 22 improves baseline threat readability, but that does not fully cover mechanic-specific affordances after Defend tuning, techniques, or hand-slot swap.

Prompt 33 exists as the optional cross-mechanic readability audit if the landed combat UI still feels fragmented after those mechanic passes.

## Goal

Audit and, if needed, narrowly improve the combat UI so shipped mechanics remain visible, tappable, and honest without adding new gameplay behavior.

## Direction Statement

- visibility of landed mechanics first
- no new mechanics
- no fake previews
- no sprawling action-bar growth
- reinforce the main combat decision area
- disabled/unavailable states should explain themselves visually

## Preferred Owner Surfaces

- `Game/UI/combat_scene_ui.gd`
- `Game/UI/combat_presenter.gd`
- `Game/UI/combat_copy_formatter.gd`
- `Game/UI/combat_feedback_lane.gd`
- `Game/UI/combat_guard_badge.gd` when the issue is guard visibility or guard-state presentation
- `Game/UI/hunger_warning_toast.gd` when the issue is hunger-warning visibility or threshold emphasis
- `scenes/combat.gd` only for narrow composition hooks if unavoidable

## Risk Lane / Authority Docs

- default lane: low-risk fast lane if the pass stays presentation-only
- authority doc: `Docs/COMBAT_RULE_CONTRACT.md`
- if the desired fix needs new combat math, new mechanic state, new save fields, or new action families, stop and say `escalate first`

## Hard Guardrails

- No combat math change.
- No new action family.
- No item legality change.
- No save/schema change.
- No flow-state change.
- No owner move.
- No mechanic redesign hidden inside "UI polish".

## Out Of Scope / Escalation Triggers

Out of scope here:

- technique design changes
- hand-slot swap rule changes
- enemy-intent grammar expansion
- inventory-owner redesign

If the desired improvement needs:

- new runtime mechanic state
- new command family
- new persistence
- broader combat-layout rewrite

stop and say `escalate first`.

## Validation

- `py -3 Tools/validate_architecture_guards.py`
- `Tests/test_combat_presenter.gd`
- `Tests/test_combat_safe_menu.gd`
- any new targeted combat/UI tests added in the same patch
- `Tools/run_godot_scene_isolation.ps1 -ScenePath scenes/combat.tscn` if scene wiring changed
- portrait screenshots before/after
- explicit full suite is optional if the pass stays UI-only; report whether it was skipped

## Done Criteria

- landed mechanics are easier to discover and understand
- action-area hierarchy stays compact
- unavailable states are legible
- no mechanic truth changed
- docs and screenshots can explain what improved

## Copy/Paste Parts

### Part A - Mechanic UI Audit

```text
Apply only Prompt 33 Part A.

Scope:
- Audit the current combat UI after the landed mechanic passes.
- Focus on:
  - Defend clarity if Prompt 23 landed
  - technique affordance / consumed-state / disabled-state clarity if Prompt 27 landed
  - hand-slot swap affordance / no-spare state / turn-cost clarity if Prompt 29 landed
  - whether the action area still reads as one coherent surface

Do not:
- patch gameplay logic in Part A
- propose new mechanics as a substitute for weak UI

Validation:
- validate_architecture_guards
- readback only

Report:
- confirmed UI/readability issues
- explicit separation between confirmed issues and assumptions
- exact screenshots or scene states reviewed
```

### Part B - Narrow Mechanic UI Patch

```text
Apply only Prompt 33 Part B only if Part A found presentation issues that fit the existing lane.

Scope:
- Land only narrow combat UI improvements needed to make the already-shipped mechanics readable.
- Allowed moves:
  - action-area layout tuning
  - clearer labels or helper copy
  - clearer disabled-state presentation
  - clearer cost / ends-turn messaging
  - compact feedback-lane or emphasis tuning

Do not:
- change mechanic behavior
- widen into inventory redesign
- turn the combat screen into a larger feature wave

Validation:
- validate_architecture_guards
- targeted combat/UI tests
- combat scene isolation if wiring changed
- screenshots before/after

Report:
- files changed
- exact UI problems fixed
- screenshot paths
- explicit confirmation that gameplay truth did not change
```

### Part C - Mechanic UI Review

```text
Apply only Prompt 33 Part C.

Scope:
- Review the landed mechanic UI follow-up.
- Verify:
  1. the action area still feels compact
  2. Defend, techniques, and swap each read as distinct decisions when present
  3. unavailable states explain themselves
  4. no mechanic appears hidden behind tooltip-only UI
  5. no fake prediction or recommendation implication slipped in

If a checkpoint fails:
- open only a narrow follow-up in the same combat UI owner scope

Validation:
- validate_architecture_guards if code changed
- targeted tests if code changed
- full suite optional only if Part C itself is docs/screenshots only

Report:
- screenshot paths
- pass/fail per checkpoint
- any remaining readability risk
```
