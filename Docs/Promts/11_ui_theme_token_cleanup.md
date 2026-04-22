# Prompt 11 - UI Theme And Token Cleanup

Use this prompt pack only after Prompt 10 is closed green.
This is a future-queue pack. Do not start it while Prompt 04, Prompt 05, Prompt 06, Prompt 07, Prompt 08, Prompt 09, or Prompt 10 is still open.

Read first:
- `AGENTS.md`
- `Docs/DOC_PRECEDENCE.md`
- `Docs/HANDOFF.md`
- `Docs/ROADMAP.md`
- `Docs/TEST_STRATEGY.md`
- `Docs/VISUAL_AUDIO_STYLE_GUIDE.md`
- `Docs/UI_INFORMATION_ARCHITECTURE_AUDIT.md`
- `Docs/UI_MICROCOPY_AUDIT.md`

## Goal

Centralize shared UI color, spacing, typography, and component-state tokens after the hierarchy and readability wins are already landed.

## Direction Statement

- This is cleanup after functional UI wins, not before them.
- Shared UI owners should carry common token values.
- Local one-off constants that are now safe to centralize should be reduced.
- This pass must not smuggle gameplay or behavior changes behind cleanup wording.

## Preferred Owner Surfaces

- shared UI helper/theme owners already in use
- token extraction only where a stable shared owner is already appropriate

## Hard Guardrails

- No gameplay/UI behavior change disguised as cleanup.
- No save/schema change.
- No asset hookup change.
- No flow change.
- No ownership move.
- No new design system layer that bypasses existing shared UI owners without a strong reason.
- No file rename. In particular, `temp_screen_theme.gd` keeps its `temp_` prefix; renaming is treated as ownership move and is out of scope for this pack.

## Validation

- `py -3 Tools/validate_architecture_guards.py`
- targeted UI tests for touched shared helpers
- scene isolation for representative screens if needed
- full suite before closing implementation parts
- portrait screenshots plus short cleanup regression report

## Done Criteria

- Common token values are more centralized and less duplicated.
- Shared panel/button/card/text state logic is cleaner.
- No hierarchy/readability gains from Prompts 07-10 are lost.
- No gameplay behavior changed.

## Copy/Paste Parts

### Part A - Token Extraction

```text
Apply only Prompt 11 Part A.

Scope:
- Extract and normalize shared UI tokens for:
  - color
  - spacing
  - typography
  - panel/button/card state values
- Keep extraction inside existing shared UI helper/theme owners where possible.

Do not:
- redesign screens
- change gameplay logic
- widen into new asset work
- create a new owner layer if an existing shared UI owner can safely hold the token

Validation:
- validate_architecture_guards
- targeted shared-UI tests
- full suite before closing

Report:
- files changed
- before/after line counts
- token groups centralized
```

### Part B - Shared Component Cleanup

```text
Apply only Prompt 11 Part B.

Scope:
- Remove stale local constant duplication where the new shared tokens are now the clear owner.
- Keep cleanup behavior-preserving.

Do not:
- change hierarchy decisions already landed
- change readability guardrail intent
- widen into scene/core ownership changes

Validation:
- validate_architecture_guards
- targeted shared-UI tests
- full suite before closing

Report:
- files changed
- what duplication was removed
- explicit confirmation that behavior stayed the same
```

### Part C - Screenshot Regression Review

```text
Apply only Prompt 11 Part C.

Scope:
- Re-capture representative portrait screenshots for the touched UI screens.
- Verify that:
  1. hierarchy gains remain
  2. readability gains remain
  3. no panel/button/card state regressed visually

If a checkpoint fails:
- open a narrow follow-up cleanup correction in the same owner scope

Validation:
- validate_architecture_guards if any code changed
- targeted shared-UI tests if any code changed
- full suite before closing if any code changed

Report:
- captured files
- pass/fail per checkpoint
- any cleanup regressions found
```

### Part D - Closeout And Handoff Refresh

```text
Apply only Prompt 11 Part D.

Scope:
- Update Docs/HANDOFF.md and Docs/ROADMAP.md so Prompt 11 is recorded and Prompt 12 becomes next.
- Record that shared UI tokens were centralized after hierarchy/readability wins, not before them.

Validation:
- markdown/internal link sanity
- validate_architecture_guards

Report:
- files changed
- final cleanup summary
- any remaining open token debt
```
