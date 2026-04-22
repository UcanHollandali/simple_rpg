# Prompt 06.5 - UI Microcopy Audit

Use this prompt pack only after Prompt 06 is closed green.
This is a future-queue pack. Do not start it while Prompt 06 or any earlier open UI-overhaul pack is still open.

Checked-in filename note:
- this pack lives at `Docs/Promts/06_5_microcopy_audit.md`
- checked-in filename and logical queue position now match Prompt `06.5`

Read first:
- `AGENTS.md`
- `Docs/DOC_PRECEDENCE.md`
- `Docs/HANDOFF.md`
- `Docs/ROADMAP.md`
- `Docs/UI_INFORMATION_ARCHITECTURE_AUDIT.md`
- `Docs/VISUAL_AUDIO_STYLE_GUIDE.md`

Optional reference (only if a wording problem depends on the underlying rule surface):
- `Docs/MAP_CONTRACT.md`
- `Docs/COMBAT_RULE_CONTRACT.md`
- `Docs/SUPPORT_INTERACTION_CONTRACT.md`
- `Docs/REWARD_LEVELUP_CONTRACT.md`

## Goal

Audit the current player-facing microcopy so later UI presentation passes improve clarity, disabled-reason readability, and tone consistency without inventing new gameplay truth.

The output is a reference-only planning document at `Docs/UI_MICROCOPY_AUDIT.md`.

This is not a gameplay rewrite.
This is not a localization system pass.
This is not a code patch.

## Direction Statement

- Reuse existing runtime truth; do not invent new explanation text for gameplay states that the game does not currently expose reliably.
- Prefer short, actionable wording over flavor-first wording when the player is making an immediate decision.
- Disabled choices should say why they are unavailable when that reason already exists as current truth.
- Empty, loading, and error text should feel intentional, but Prompt 06.5 only audits and queues the work.
- If a better line would need new gameplay logic or a new derived state, mark it `NEEDS_FUTURE_LOGIC_SUPPORT`.

## Hard Guardrails

- No code change in this pack.
- No save/schema change.
- No combat math, route logic, event outcome, reward logic, or support logic change.
- No new runtime owner.
- No asset approval, generation, import, move, rename, or hookup.
- No `UiAssetPaths` change.
- No failure semantics change; only wording audit and follow-up planning.

## Validation

- `py -3 Tools/validate_architecture_guards.py`
- markdown/internal link sanity for any touched docs

If only docs are changed, the full Godot suite is optional. Report whether it was skipped.

## Done Criteria

- `Docs/UI_MICROCOPY_AUDIT.md` exists and is clearly marked reference-only.
- The audit inventories the major player-facing text surfaces and classifies wording problems by type.
- The audit assigns follow-up work to the later UI wave without changing gameplay or flow.
- The audit clearly separates:
  - clear and keep
  - unclear but fixable with wording only
  - missing disabled reason
  - too long / too noisy
  - tone mismatch
  - duplicate phrasing
  - needs future logic support

## Copy/Paste Parts

### Part A - Microcopy Audit Document

```text
Apply only Prompt 06.5 Part A.

Scope:
- Audit current player-facing text across:
  - map route / node surfaces
  - event modal titles, body text, choice labels, and disabled reasons
  - combat action labels, hints, guard feedback labels, and status readouts
  - inventory / equipment labels, slot names, usability text, and discard / overflow messaging
  - stage transition / run-end summary text
  - warnings, toasts, and empty/error strings if visible
- Create Docs/UI_MICROCOPY_AUDIT.md as a reference-only planning document.

Required audit sections:
1. Status
2. Scope And Current Direction
3. Tone Baseline
4. Surface Inventory
5. Disabled-Reason Audit
6. Empty / Loading / Error Surface Inventory
7. High-Impact Rewrite Candidates
8. `NEEDS_FUTURE_LOGIC_SUPPORT` Cases
9. Prompt 07-11.5 Handoff Plan
10. Non-Goals

Do not:
- rewrite code
- change live strings in this pack
- invent new gameplay explanation text that needs unavailable runtime truth

Validation:
- validate_architecture_guards
- markdown/internal link sanity on the new audit doc

Report:
- files created/changed
- top microcopy problem categories
- top disabled-reason gaps
- explicit confirmation that no code changed
```

### Part B - Closeout And Handoff Refresh

```text
Apply only Prompt 06.5 Part B.

Scope:
- Update Docs/HANDOFF.md and Docs/ROADMAP.md so Prompt 06.5 is recorded.
- Make the recommended rewrite hand-offs explicit:
  - Prompt 07-09: screen-specific hierarchy copy touchpoints only where needed
  - Prompt 10: readability guardrails only
  - Prompt 11.5: the main empty / loading / error / failure-state rewrite lane

Do not:
- implement the rewrites
- change gameplay logic
- declare any asset lane unblocked

Validation:
- markdown/internal link sanity
- validate_architecture_guards

Report:
- files changed
- main rewrite queues handed off
- explicit confirmation that Prompt 06.5 stayed docs-only
```
