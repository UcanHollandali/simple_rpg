# Prompt 10 - Font And Icon Readability Guardrails

Use this prompt pack only after Prompt 09 is closed green.
This is a future-queue pack. Do not start it while Prompt 04, Prompt 05, Prompt 06, Prompt 07, Prompt 08, or Prompt 09 is still open.

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

Add minimum font, icon, touch-target, and contrast guardrails so gameplay information remains readable on portrait targets.

This is not the full token/theme cleanup pass.

## Direction Statement

- Readability first.
- Decorative font usage stays limited to headings and accent surfaces.
- Gameplay values, effects, and dense informational surfaces should use readable text treatment.
- Icons must remain legible at runtime size.
- Touch/click targets should stay usable on portrait targets.

## Preferred Owner Surfaces

- `Game/UI/temp_screen_theme.gd`
- `Game/UI/scene_layout_helper.gd`
- `Game/UI/inventory_panel_layout.gd` (only for inventory-specific density / panel-height guardrails; do not move ownership)
- narrow shared UI helpers as needed

Do not rename `temp_screen_theme.gd`. The `temp_` prefix is intentional; the rename / re-owner decision is not in scope for this pack and is also not part of Prompt 11.

## Hard Guardrails

- No gameplay logic change.
- No save/schema change.
- No asset hookup change.
- No full theme/token refactor yet.
- No icon-family identity replacement; this pack sets guardrails, not a semantic icon wave.

## Validation

- `py -3 Tools/validate_architecture_guards.py`
- targeted UI tests for touched shared helpers
- scene isolation for touched screens if wiring changed
- full suite before closing implementation parts
- portrait screenshots plus a short readability report

## Done Criteria

- Minimum readability standards are explicit in code/presentation helpers.
- Hard-to-read font/icon/touch-target issues identified by Prompt 06 are reduced on affected surfaces.
- Decorative-font overuse is reduced where necessary.
- This pass does not expand into full theme/token centralization.

## Copy/Paste Parts

### Part A - Guardrail Implementation

```text
Apply only Prompt 10 Part A.

Scope:
- Add minimum readability guardrails for:
  - font sizes
  - icon sizes
  - touch target minimums
  - disabled text contrast
  - important value emphasis
  - decorative font usage limits
- Preferred file scope:
  - Game/UI/temp_screen_theme.gd
  - Game/UI/scene_layout_helper.gd
  - Game/UI/inventory_panel_layout.gd (inventory-specific guardrails only)
  - narrow shared UI helpers only as needed

Anchor decorative-font scope to the audit:
- the list of currently decorative font usages is the `Font And Icon Readability Findings` section in `Docs/UI_INFORMATION_ARCHITECTURE_AUDIT.md`
- do not introduce a new decorative-font surface in this pack
- do not rename `temp_screen_theme.gd`

Keep scope narrow:
- this is not the full token cleanup pass
- do not centralize every UI constant yet

Do not:
- change gameplay logic
- start semantic icon replacement
- widen into per-screen hierarchy changes already owned by Prompts 07-09 unless a narrow shared-helper adaptation is required

Validation:
- validate_architecture_guards
- targeted shared-UI tests
- relevant scene isolation if wiring changed
- full suite before closing
- portrait screenshots before/after plus short readability report

Report:
- files changed
- before/after line counts
- exact guardrails introduced
- screenshot paths
```

### Part B - Readability Review

```text
Apply only Prompt 10 Part B.

Scope:
- Review touched screens against readability checkpoints:
  1. smallest text no longer drops below the intended minimum
  2. icons remain readable at runtime size
  3. disabled text stays readable enough
  4. important gameplay values stand out appropriately
  5. decorative-font usage remains limited to headings/accent roles
  6. touch targets remain usable on portrait

If a checkpoint fails:
- open a narrow follow-up tuning pass in the same shared owner scope

Validation:
- validate_architecture_guards if any code changed
- targeted shared-UI tests if any code changed
- full suite before closing if any code changed

Report:
- captured files
- pass/fail per checkpoint
- any follow-up tuning
```

### Part C - Closeout And Handoff Refresh

```text
Apply only Prompt 10 Part C.

Scope:
- Update Docs/HANDOFF.md and Docs/ROADMAP.md so Prompt 10 is recorded and Prompt 11 becomes next.
- Record readability guardrails as shared-presentation rules, not gameplay rules.

Validation:
- markdown/internal link sanity
- validate_architecture_guards

Report:
- files changed
- final readability summary
- any remaining open readability risk
```
