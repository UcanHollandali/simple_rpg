# Prompt 34 - Combat Onboarding And Hint Refresh

Use this prompt pack only after at least one mechanic-bearing combat pack has landed in the `21+` wave.
Typical trigger points:

- after Prompt `23` if Defend changed meaningfully
- after Prompt `27` if techniques landed
- after Prompt `29` if hand-slot swap landed

If Prompt `33` is opened for a cross-mechanic UI audit, prefer closing Prompt `33` before this pack so onboarding teaches the stabilized surface, not an intermediate layout.

This is a narrow onboarding / microcopy / hint-refresh pack.
It does not add new combat mechanics by itself.

Checked-in filename note:
- this pack lives at `Docs/Archive/Prompts/2026-04-23-closed-green-prompt-packs/34_combat_onboarding_and_hint_refresh.md`
- checked-in filename and logical queue position now match Prompt `34`

Read first:
- `AGENTS.md`
- `Docs/DOC_PRECEDENCE.md`
- `Docs/HANDOFF.md`
- `Docs/ROADMAP.md`
- `Docs/COMBAT_RULE_CONTRACT.md`
- `Docs/SAVE_SCHEMA.md`
- `Docs/TEST_STRATEGY.md`
- `Docs/UI_MICROCOPY_AUDIT.md`
- `Docs/Archive/Prompts/2026-04-23-closed-green-prompt-packs/10_5_first_run_hints.md`
- the exact landed mechanic prompt docs being taught, typically:
  - `Docs/Archive/Prompts/2026-04-23-closed-green-prompt-packs/23_defend_tempo_hunger_pass.md`
  - `Docs/Archive/Prompts/2026-04-23-closed-green-prompt-packs/27_technique_runtime_mvp.md`
  - `Docs/Archive/Prompts/2026-04-23-closed-green-prompt-packs/29_weapon_swap_runtime_surface.md`

## Continuation Gate

- touched owner layer: `Game/UI/`, `Game/Application/`, `scenes/`, docs
- authority doc: `Docs/COMBAT_RULE_CONTRACT.md`, `Docs/SAVE_SCHEMA.md`, `Docs/TEST_STRATEGY.md`
- impact: runtime truth `no` by default; save shape `no` by default; asset provenance `no`
- minimum validation set: `py -3 Tools/validate_architecture_guards.py`, targeted hint/UI tests, scene isolation if wiring changes

## Context Statement

Mechanics can be correct and visible yet still feel bad if the player is never taught:

- why Defend changed
- when to use a technique
- why a hand-slot swap affordance exists now
- what "ends turn" or "single use" means in practice

The repo already has:

- `FirstRunHintController`
- additive-optional `app_state.shown_first_run_hints`
- a prior hint strategy in Prompt `10.5`

Prompt 34 exists to refresh onboarding for newly-landed combat mechanics without creating a tutorial mode or a new save-system lane.

## Goal

Teach newly-landed combat mechanics through narrow first-run/contextual hints and microcopy refresh so the player understands the mechanic without pausing the game or opening a tutorial track.

## Direction Statement

- reuse the existing hint / onboarding surfaces where possible
- no tutorial mode
- no rotating tips system
- one mechanic truth per hint
- hints should be contextual, short, and non-blocking
- helper copy should explain cost / availability / consequence, not strategy-solve the turn

## Preferred Owner Surfaces

- `Game/UI/first_run_hint_controller.gd`
- `Game/UI/combat_copy_formatter.gd`
- `Game/UI/combat_presenter.gd`
- `Game/UI/combat_scene_ui.gd`
- `scenes/combat.gd` only for narrow composition hooks if unavoidable

## Risk Lane / Authority Docs

- default lane: low-risk fast lane if the pack stays in hint/copy/UI surfaces and reuses the existing additive hint continuity field
- authority docs:
  - `Docs/COMBAT_RULE_CONTRACT.md`
  - `Docs/SAVE_SCHEMA.md`
  - `Docs/TEST_STRATEGY.md`
- if the desired onboarding needs a new save field, a blocking tutorial flow, or a new mechanic state owner, stop and say `escalate first`

## Hard Guardrails

- No combat math change.
- No new action family.
- No tutorial mode.
- No new save field by default.
- No flow-state change.
- No hidden gameplay truth move into hint text.
- No recommendation system disguised as onboarding.

## Out Of Scope / Escalation Triggers

Out of scope here:

- technique redesign
- hand-slot swap rule redesign
- event/tutorial scene creation
- new persistent progression teaching systems

If the desired onboarding needs:

- a new save field
- a guided tutorial sequence
- a new flow state
- deeper gameplay explanation than current truth supports

stop and say `escalate first`.

## Validation

- `py -3 Tools/validate_architecture_guards.py`
- targeted hint/controller tests
- targeted combat/UI tests
- scene isolation if scene wiring changed
- portrait screenshots of the new hints or helper-copy states
- explicit full suite is optional if the pack stays hint/UI-only; report whether it was skipped

## Done Criteria

- newly-landed combat mechanics have truthful onboarding coverage
- hints/helper copy stay short and contextual
- no new save/schema lane is opened unless explicitly escalated
- no mechanic truth changed
- screenshots and tests can show that the onboarding actually appears

## Copy/Paste Parts

### Part A - Onboarding Gap Audit

```text
Apply only Prompt 34 Part A.

Scope:
- Audit the landed combat mechanics for missing onboarding.
- Focus on:
  - Defend cost / consequence if Prompt 23 landed
  - technique discovery / single-use or limited-use meaning if Prompt 27 landed
  - hand-slot swap discovery / ends-turn meaning if Prompt 29 landed

Do not:
- patch gameplay logic in Part A
- propose a tutorial mode instead of solving the actual onboarding gap

Validation:
- validate_architecture_guards
- readback only

Report:
- confirmed onboarding gaps
- explicit separation between copy-only gaps and hint-trigger gaps
- exact mechanic surfaces reviewed
```

### Part B - Hint And Microcopy Refresh

```text
Apply only Prompt 34 Part B only if Part A found real onboarding gaps.

Scope:
- Add or refresh narrow contextual hints and helper copy for the landed combat mechanics.
- Prefer:
  - existing FirstRunHintController
  - existing helper-copy surfaces
  - short non-blocking contextual hints

Do not:
- add a tutorial mode
- add a new save field by default
- change mechanic behavior
- write strategy-advice text that over-promises certainty

Validation:
- validate_architecture_guards
- targeted hint/UI tests
- scene isolation if wiring changed
- portrait screenshots of the hint/copy states

Report:
- files changed
- exact hints or helper-copy states added/refreshed
- screenshot paths
- explicit confirmation that gameplay truth did not change
```

### Part C - Onboarding Review

```text
Apply only Prompt 34 Part C.

Scope:
- Review the landed onboarding refresh.
- Verify:
  1. each new mechanic has at least one truthful onboarding surface
  2. hints are contextual and non-blocking
  3. helper copy explains cost/availability/consequence clearly
  4. the game still does not have a tutorial mode or rotating tips system
  5. no hint implies certainty that gameplay truth does not own

If a checkpoint fails:
- open only a narrow follow-up in the same hint/copy/UI owner scope

Validation:
- validate_architecture_guards if code changed
- targeted tests if code changed
- full suite optional only if Part C itself is docs/screenshots only

Report:
- screenshot paths
- pass/fail per checkpoint
- any remaining onboarding risk
```
