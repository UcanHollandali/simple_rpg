# Prompt 08 - Event Modal Choice Cards

Use this prompt pack only after Prompt 07 is closed green.
This is a future-queue pack. Do not start it while Prompt 04, Prompt 05, Prompt 06, or Prompt 07 is still open.

Read first:
- `AGENTS.md`
- `Docs/DOC_PRECEDENCE.md`
- `Docs/HANDOFF.md`
- `Docs/ROADMAP.md`
- `Docs/TEST_STRATEGY.md`
- `Docs/UI_INFORMATION_ARCHITECTURE_AUDIT.md`
- `Docs/UI_MICROCOPY_AUDIT.md`

## Goal

Improve event-modal hierarchy so choices are easier to compare and the mechanical effect of each choice is easier to read, without changing event logic.

## Direction Statement

- Event modal dominant task: compare choices.
- Flavor text may remain, but mechanical effect must be easier to read.
- Choice cards should carry clear hierarchy:
  - label / title
  - short detail
  - cost / reward / availability using existing truth only
  - primary action button
- Back / leave remains visually secondary.

## Preferred Owner Surfaces

- `Game/UI/event_presenter.gd` (preferred)
- `scenes/event.gd` (composition-only hooks; avoid widening this scene)
- narrow shared presentation/theme helpers only if required

## Overlay Context

The event modal is rendered as an overlay above `MapExplore` and routed through `Game/UI/map_overlay_director.gd` plus the shared `OverlayFlowContract` / `MapOverlayContract` state surface. Keep the modal a pure overlay consumer:

- do not introduce a new overlay state or overlay name
- do not bypass the overlay director
- do not change the overlay open/close contract (presentation hierarchy only)

## Hard Guardrails

- No event outcome logic change.
- No new event grammar.
- No new runtime truth.
- No new prediction system.
- No save/schema change.
- No new overlay state or overlay-name expansion.
- No asset hookup or `UiAssetPaths` changes.
- No widening of `/root/AppBootstrap` lookup spread.

## Validation

- `py -3 Tools/validate_architecture_guards.py`
- targeted event/UI tests
- scene isolation if scene wiring changed
- full suite before closing implementation parts
- portrait screenshots plus short hierarchy report

## Done Criteria

- Event choices read as explicit choice cards rather than flat option rows.
- Existing truth for cost/reward/disabled reason is surfaced more clearly.
- Back/leave stays present but secondary.
- Portrait modal height/readability improves or at least does not regress.
- No event logic changes.

## Copy/Paste Parts

### Part A - Choice Card Hierarchy

```text
Apply only Prompt 08 Part A.

Scope:
- Improve event choice-card shell and hierarchy.
- Preferred file scope:
  - scenes/event.gd
  - Game/UI/event_presenter.gd
- Shared presentation/theme helper only if required.

Target behavior:
- clearer event tag/title/summary grouping
- clearer choice-card hierarchy
- action button visually tied to each choice card
- back/leave remains secondary

Do not:
- change event logic
- add new event state
- widen into map/combat/inventory work

Validation:
- validate_architecture_guards
- targeted event presenter / event scene tests
- event scene isolation if scene wiring changed
- full suite before closing
- portrait screenshots before/after plus short hierarchy report

Report:
- files changed
- before/after line counts
- screenshot paths
- explicit confirmation that event logic did not change
```

### Part B - Cost / Reward / Disabled Reason Visibility

```text
Apply only Prompt 08 Part B.

Scope:
- Surface event choice costs, rewards, disabled reasons, and short result feedback more clearly using existing truth only.
- If an exact desired value would require new gameplay calculation, mark it as NEEDS_FUTURE_LOGIC_SUPPORT and do not implement it.

Do not:
- add new prediction logic
- change event outcomes
- change item effects
- add asset hookups
- introduce a new disabled-reason source (existing disabled-reason routes for authored event templates must stay the truth path)

Validation:
- validate_architecture_guards
- targeted event presenter / event scene tests
- full suite before closing
- portrait screenshots before/after plus short hierarchy report

Report:
- files changed
- which fields became clearer
- anything marked NEEDS_FUTURE_LOGIC_SUPPORT
- explicit confirmation that the disabled-reason source for each authored event template still resolves the same way it did before this part
- screenshot paths
```

### Part C - Screenshot Review

```text
Apply only Prompt 08 Part C.

Scope:
- Capture portrait event screenshots after Parts A-B.
- Verify:
  1. title remains readable
  2. mechanical consequence of each choice is clearer
  3. costs and rewards are visually separated enough
  4. disabled reasons are visible when needed
  5. primary choice is visually dominant
  6. back/leave remains secondary
  7. modal height is acceptable on portrait targets

If a checkpoint fails:
- open a narrow follow-up tuning pass in the same owner scope

Validation:
- validate_architecture_guards if any code changed
- targeted event tests if any code changed
- full suite before closing if any code changed

Report:
- captured files
- pass/fail per checkpoint
- any follow-up tuning
```

### Part D - Closeout And Handoff Refresh

```text
Apply only Prompt 08 Part D.

Scope:
- Update Docs/HANDOFF.md and Docs/ROADMAP.md so Prompt 08 is recorded and Prompt 09 becomes next.
- Record event-modal hierarchy improvements without claiming new gameplay logic.

Validation:
- markdown/internal link sanity
- validate_architecture_guards

Report:
- files changed
- final event-modal hierarchy summary
- any remaining open readability risk
```
