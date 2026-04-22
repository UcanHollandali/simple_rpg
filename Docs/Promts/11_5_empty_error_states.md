# Prompt 11.5 - Empty, Loading, And Error States

Use this prompt pack only after Prompt 11 is closed green and Prompt 06.5 is closed green.
This is a future-queue implementation pack. Do not start it while any earlier open 06-11 pack is still open.

Checked-in filename note:
- this pack lives at `Docs/Promts/11_5_empty_error_states.md`
- checked-in filename and logical queue position now match Prompt `11.5`

Read first:
- `AGENTS.md`
- `Docs/DOC_PRECEDENCE.md`
- `Docs/HANDOFF.md`
- `Docs/ROADMAP.md`
- `Docs/TEST_STRATEGY.md`
- `Docs/UI_INFORMATION_ARCHITECTURE_AUDIT.md`
- `Docs/UI_MICROCOPY_AUDIT.md`
- `Docs/VISUAL_AUDIO_STYLE_GUIDE.md`

Optional reference (only if a surface depends on the underlying contract):
- `Docs/MAP_CONTRACT.md`
- `Docs/COMBAT_RULE_CONTRACT.md`
- `Docs/SUPPORT_INTERACTION_CONTRACT.md`
- `Docs/REWARD_LEVELUP_CONTRACT.md`

## Goal

Implement the empty-state, loading/transition-state, and error/failure-state rewrite queue identified by Prompt 06.5 without changing gameplay truth, failure semantics, save shape, or flow ownership.

## Direction Statement

- This pack is presentation-only.
- Keep current failure behavior; improve clarity, hierarchy, and tone only.
- Prefer using existing presenter/UI owners instead of introducing new coordination layers.
- Reuse current runtime truth; do not invent new state.
- If a better message would need a new runtime reason code or new gameplay truth, stop and mark it `NEEDS_FUTURE_LOGIC_SUPPORT` instead of faking the copy.

## Hard Guardrails

- No save/schema change.
- No flow change.
- No combat math or item-effect change.
- No event outcome change.
- No map route logic change.
- No new command family or event family.
- No asset hookup or `UiAssetPaths` change.
- No localization framework change.
- No owner move; stay in existing presenter / scene presentation surfaces.
- Do not modify test baselines to hide readability regressions.

## Validation

- `py -3 Tools/validate_architecture_guards.py`
- targeted presenter / screen tests for touched surfaces
- scene isolation for touched screens when practical
- full suite before closing implementation parts

## Done Criteria

- Empty states read intentionally rather than as missing UI.
- Loading / transition states are clearer without changing the underlying transition behavior.
- Error / failure states are more actionable and less ambiguous without changing failure semantics.
- The pack stays presentation-only and preserves owner boundaries.

## Copy/Paste Parts

### Part A - Empty-State Pass

```text
Apply only Prompt 11.5 Part A.

Scope:
- Implement the empty-state rewrite set from Docs/UI_MICROCOPY_AUDIT.md.
- Focus on surfaces such as:
  - empty backpack / empty equipment-adjacent states
  - no usable consumable state
  - no relevant action/options state where the screen already exposes one
- Keep the change inside existing presenter / scene presentation owners.

Do not:
- add new behavior
- add fake placeholder data
- widen into error/failure semantics

Validation:
- validate_architecture_guards
- targeted UI/presenter tests
- full suite before closing

Report:
- files changed
- empty states improved
- any surface deferred because it needs future logic support
```

### Part B - Loading And Transition-State Pass

```text
Apply only Prompt 11.5 Part B.

Scope:
- Implement the loading / transition-state rewrite set from Docs/UI_MICROCOPY_AUDIT.md.
- Keep StageTransition, overlays, and screen-status text aligned with existing truth.
- Improve clarity only; no new loading state machine.

Do not:
- add new flow states
- change transition timing or routing
- invent progress percentages that do not exist

Validation:
- validate_architecture_guards
- targeted UI/presenter tests
- scene isolation if touched
- full suite before closing

Report:
- files changed
- transition/loading states improved
- any deferred gaps
```

### Part C - Error And Failure-State Pass

```text
Apply only Prompt 11.5 Part C.

Scope:
- Implement the error / failure-state rewrite set from Docs/UI_MICROCOPY_AUDIT.md.
- Clarify current failures such as unavailable actions, blocked choices, or narrow invalid-state messages where those reasons already exist.

Do not:
- change failure semantics
- add new retry behavior
- widen into gameplay logic or router/error-policy changes

Validation:
- validate_architecture_guards
- targeted UI/presenter tests
- full suite before closing

Report:
- files changed
- failure/error states improved
- explicit confirmation that semantics did not change
```

### Part D - Closeout And Handoff Refresh

```text
Apply only Prompt 11.5 Part D.

Scope:
- Update Docs/HANDOFF.md and Docs/ROADMAP.md so Prompt 11.5 is recorded and Prompt 12 becomes next.
- Record any surfaces still deferred because they need future logic support.

Validation:
- markdown/internal link sanity
- validate_architecture_guards

Report:
- files changed
- deferred copy gaps
- explicit confirmation that Prompt 11.5 stayed presentation-only
```
