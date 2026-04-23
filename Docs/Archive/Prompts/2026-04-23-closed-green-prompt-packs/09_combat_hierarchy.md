# Prompt 09 - Combat Hierarchy

Use this prompt pack only after Prompt 08 is closed green.
This is a future-queue pack. Do not start it while Prompt 04, Prompt 05, Prompt 06, Prompt 07, or Prompt 08 is still open.

Read first:
- `AGENTS.md`
- `Docs/DOC_PRECEDENCE.md`
- `Docs/HANDOFF.md`
- `Docs/ROADMAP.md`
- `Docs/TEST_STRATEGY.md`
- `Docs/COMBAT_RULE_CONTRACT.md`
- `Docs/UI_INFORMATION_ARCHITECTURE_AUDIT.md`
- `Docs/UI_MICROCOPY_AUDIT.md`

## Goal

Improve combat action clarity and screen hierarchy so the player can read the enemy, understand current combat state, and choose an action faster.

## Direction Statement

- Combat dominant task: choose an action.
- Enemy intent should read clearly.
- Player combat state should be easier to scan.
- Attack / Defend / usable-item surfaces should be easier to distinguish.
- Combat log should stop competing with the action area when a compact/default-collapsed presentation is safer.
- This pack improves visibility of existing truth; it does not add new combat prediction systems.

## Preferred Owner Surfaces

- `Game/UI/combat_scene_ui.gd`
- `Game/UI/combat_presenter.gd`
- `Game/UI/run_status_presenter.gd`
- `Game/UI/combat_scene_shell.gd` (already live shell extraction; preferred for layout-budget tweaks)
- `Game/UI/combat_feedback_lane.gd` (already live; preferred owner for guard-delta and same-target feedback hierarchy)
- `Game/UI/action_hint_controller.gd` (already live; preferred owner for action-hint visual emphasis)

Avoid large `scenes/combat.gd` edits unless a small composition-only hook is unavoidable.

## Existing-Truth Rule

Do not add exact damage previews, exact mitigation forecasts, or recommendation systems unless the value already exists as reliable current runtime truth.

If an exact desired preview would require new gameplay calculation, mark it as:

`NEEDS_FUTURE_LOGIC_SUPPORT`

and do not implement it in this pack.

## Hard Guardrails

- No combat math change.
- No enemy intent logic change.
- No item effect change.
- No save/schema change.
- No new runtime truth owner.
- No flow change.
- No asset hookup or `UiAssetPaths` changes.
- No widening of `/root/AppBootstrap` lookup spread.

## Validation

- `py -3 Tools/validate_architecture_guards.py`
- targeted combat/UI tests
- combat scene isolation if scene wiring changed
- full suite before closing implementation parts
- portrait screenshots plus short hierarchy report

## Done Criteria

- Enemy intent is easier to see.
- Player combat state is easier to scan.
- Primary action area reads more clearly.
- Combat log becomes less visually dominant by default if safe.
- Existing combat truth remains unchanged.

## Copy/Paste Parts

### Part A - Enemy Intent And Action Hierarchy

```text
Apply only Prompt 09 Part A.

Scope:
- Improve combat hierarchy around:
  - enemy intent
  - player combat state
  - primary action area
- Preferred file scope:
  - Game/UI/combat_scene_ui.gd
  - Game/UI/combat_presenter.gd
  - Game/UI/run_status_presenter.gd

Use existing truth only.

Do not:
- change combat math
- add exact damage preview if it does not already exist as current runtime truth
- add recommendation systems
- widen into inventory drawer redesign beyond what is already landed in Prompt 07

Validation:
- validate_architecture_guards
- targeted combat presenter / combat UI tests
- combat scene isolation if scene wiring changed
- full suite before closing
- portrait screenshots before/after plus short hierarchy report

Report:
- files changed
- before/after line counts
- screenshot paths
- any values marked NEEDS_FUTURE_LOGIC_SUPPORT
```

### Part B - Consumable Quickbar And Compact Combat Log

```text
Apply only Prompt 09 Part B.

Scope:
- Improve consumable quickbar clarity.
- Reduce combat log visual dominance where safe.
- Keep player action area primary.
- Default-collapsed combat log is allowed only if the Prompt 06 audit's Combat Screen Findings explicitly recommended it. Otherwise keep the log expanded but visually de-emphasized.

Do not:
- change combat item legality
- change combat log truth
- delete useful combat history without a safe compact alternative

Validation:
- validate_architecture_guards
- targeted combat/UI tests
- combat scene isolation if scene wiring changed
- full suite before closing
- portrait screenshots before/after plus short hierarchy report

Report:
- files changed
- screenshot paths
- what became compact vs what remained expanded
- explicit confirmation that combat rules did not change
```

### Part C - Screenshot Review

```text
Apply only Prompt 09 Part C.

Scope:
- Capture portrait combat screenshots after Parts A-B.
- Verify:
  1. enemy intent is more visible
  2. player status is easier to scan
  3. Attack and Defend are clearer
  4. usable consumables are easier to notice
  5. combat log is no longer stealing primary attention
  6. no existing-truth surface became less readable
  7. guard delta readouts (signed gain / absorb / decay carryover) remain readable across consecutive turns
  8. dual-purpose `left_hand` slot remains distinguishable as `shield` vs `weapon` after the hierarchy pass
  9. same-target combat feedback still does not overwrite itself after the hierarchy pass

If a checkpoint fails:
- open a narrow follow-up tuning pass in the same owner scope

Validation:
- validate_architecture_guards if any code changed
- targeted combat tests if any code changed
- full suite before closing if any code changed

Report:
- captured files
- pass/fail per checkpoint
- any follow-up tuning
```

### Part D - Closeout And Handoff Refresh

```text
Apply only Prompt 09 Part D.

Scope:
- Update Docs/HANDOFF.md and Docs/ROADMAP.md so Prompt 09 is recorded and Prompt 10 becomes next.
- Record combat hierarchy improvements without claiming new combat prediction logic.

Validation:
- markdown/internal link sanity
- validate_architecture_guards

Report:
- files changed
- final combat hierarchy summary
- any remaining open readability risk
```
