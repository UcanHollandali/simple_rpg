# Prompt 22 - Combat Threat Readability Follow-Up

Use this prompt pack only after Prompt 21 is closed green.
This is a low-risk combat-UI follow-up pack.
Treat it as a visibility pass over existing truth, not as a combat-rule rewrite.

Checked-in filename note:
- this pack lives at `Docs/Archive/Prompts/2026-04-23-closed-green-prompt-packs/22_combat_threat_readability_followup.md`
- checked-in filename and logical queue position now match Prompt `22`

Read first:
- `AGENTS.md`
- `Docs/DOC_PRECEDENCE.md`
- `Docs/HANDOFF.md`
- `Docs/ROADMAP.md`
- `Docs/COMBAT_RULE_CONTRACT.md`
- `Docs/TEST_STRATEGY.md`
- `Docs/Archive/Prompts/2026-04-23-closed-green-prompt-packs/09_combat_hierarchy.md`

## Continuation Gate

- touched owner layer: `Game/UI/`, `scenes/`
- authority doc: `Docs/COMBAT_RULE_CONTRACT.md`
- impact: runtime truth `no`; save shape `no`; asset provenance `no` by default
- minimum validation set: `py -3 Tools/validate_architecture_guards.py`, targeted combat/UI tests, combat scene isolation if wiring changes

## Context Statement

The repo already has dedicated combat presentation helpers for:

- intent copy
- intent visual-model building
- enemy bust intent reinforcement

That means the next safe readability step is not new combat prediction logic.
It is clearer telegraphing of existing threat truth:

- heavier "big turn" emphasis
- cleaner intent copy
- low-durability warning clarity
- bust / frame / badge polish that reinforces, but does not replace, icon and text truth

## Goal

Make the player read the next threat faster so `Attack`, `Defend`, and later tactical surfaces feel more intentional without changing gameplay calculations.

## Direction Statement

- text and icon truth stay primary
- portrait / bust / FX only reinforce that truth
- heavy-turn telegraph should read distinctly from ordinary attack pressure
- low-durability warning should support future swap planning without inventing new legality
- no exact damage prediction should appear unless current runtime already owns it

## Preferred Owner Surfaces

- `Game/UI/combat_presenter.gd`
- `Game/UI/combat_copy_formatter.gd`
- `Game/UI/combat_intent_visual_model_builder.gd`
- `Game/UI/combat_enemy_intent_bust_visuals.gd`
- `Game/UI/combat_guard_badge.gd` if guard-readability treatment is involved
- `Game/UI/hunger_warning_toast.gd` if low-hunger readability treatment is involved
- `Game/UI/combat_scene_ui.gd`
- `scenes/combat.gd` only for narrow composition hooks if unavoidable

## Risk Lane / Authority Docs

- default lane: low-risk fast lane if the pack stays presentation-only
- authority doc: `Docs/COMBAT_RULE_CONTRACT.md`
- if the desired result needs new combat preview math, new intent families, or new rule ownership, stop and say `escalate first`

## Hard Guardrails

- No combat math change.
- No enemy intent selection change.
- No item legality change.
- No new top-level action.
- No save/schema change.
- No flow change.
- No asset-hookup requirement by default.
- Avoid large hotspot growth inside `scenes/combat.gd`.

## Out Of Scope / Escalation Triggers

Out of scope here:

- exact mitigation forecasts
- recommendation systems
- new enemy intent families
- technique buttons
- hand-slot swap

If a readability request depends on new gameplay calculation or new authored asset packs, stop and either:

- mark it `NEEDS_FUTURE_LOGIC_SUPPORT`, or
- open a later asset lane explicitly

## Validation

- `py -3 Tools/validate_architecture_guards.py`
- `Tests/test_combat_presenter.gd`
- `Tests/test_combat_safe_menu.gd`
- `Tools/run_godot_scene_isolation.ps1 -ScenePath scenes/combat.tscn` if scene wiring changed
- portrait screenshots before/after
- explicit full suite is optional if the pack stays UI-only; report whether it was skipped

## Done Criteria

- heavy threat turns read more clearly
- low-durability warning is more visible
- intent copy is clearer without overstating certainty
- bust/portrait reinforcement improves threat reading without replacing icon/text truth
- no combat rule or legality changes landed

## Copy/Paste Parts

### Part A - Threat Readability Audit

```text
Apply only Prompt 22 Part A.

Scope:
- Audit the current combat screen for threat readability gaps around:
  - normal attack vs heavier spike turns
  - low durability visibility
  - intent copy clarity
  - portrait/bust reinforcement

Do not:
- patch gameplay logic in Part A
- propose exact previews if the value is not current runtime truth

Validation:
- validate_architecture_guards
- readback only

Report:
- confirmed readability gaps
- explicit separation between confirmed issues and assumptions
- any item marked NEEDS_FUTURE_LOGIC_SUPPORT
```

### Part B - UI Follow-Up Pass

```text
Apply only Prompt 22 Part B.

Scope:
- Improve combat threat readability using existing truth only.
- Allowed moves:
  - clearer heavy-turn copy or badge treatment
  - clearer low-durability warning treatment
  - bust/frame/tint polish that reinforces existing intent families
  - hierarchy tuning in existing combat UI surfaces

Do not:
- add new combat calculations
- add new intent families
- add asset-pipeline-dependent work unless already approved and present
- widen into mechanic changes

Validation:
- validate_architecture_guards
- targeted combat presenter / UI tests
- combat scene isolation if wiring changed
- portrait screenshots before/after

Report:
- files changed
- before/after readability changes
- explicit confirmation that gameplay truth did not move
```

### Part C - Readability Checkpoint

```text
Apply only Prompt 22 Part C.

Scope:
- Review the landed Prompt 22 changes in portrait combat screenshots.
- Verify:
  1. heavy threat turns read differently from ordinary pressure
  2. low durability is easier to notice
  3. text/icon truth remains the primary source of intent meaning
  4. no new gameplay prediction implication slipped in

If a checkpoint fails:
- open only a narrow follow-up in the same UI owner scope

Validation:
- validate_architecture_guards if code changed
- targeted combat tests if code changed
- full suite optional if the pack stayed UI-only

Report:
- screenshot paths
- pass/fail per checkpoint
- any follow-up tuning still needed
```
