# Prompt 12.5 - Accessibility And Mobile Interaction Audit

Use this prompt pack only after Prompt 12 is closed green.
This is a future-queue pack. Do not start it while any earlier 06-12 pack (including 06.5, 10.5, 11.5) is still open.

This is the final UI overhaul pack. It is reference-only. It does not implement accessibility features by itself; it documents the gap and queues a narrowed implementation.

Read first:
- `AGENTS.md`
- `Docs/DOC_PRECEDENCE.md`
- `Docs/HANDOFF.md`
- `Docs/ROADMAP.md`
- `Docs/UI_INFORMATION_ARCHITECTURE_AUDIT.md`
- `Docs/UI_MICROCOPY_AUDIT.md`
- `Docs/SEMANTIC_ICON_READINESS_CHECKLIST.md`
- `Docs/VISUAL_AUDIO_STYLE_GUIDE.md`

## Goal

Audit the current UI against accessibility minimums and mobile-portrait interaction expectations, then produce a reference-only checklist with a prioritized, narrow implementation queue.

The output is a reference-only document at `Docs/UI_ACCESSIBILITY_AND_MOBILE_AUDIT.md`.

## Direction Statement

- Accessibility minimums covered: color contrast (text and meaningful icons), color-only signaling (must always have a non-color secondary cue), text scaling (player-controllable if practical), motion/flash (must not trigger photosensitive risk), and touch target spacing.
- Mobile interaction minimums covered: tap vs swipe vs drag conflict, long-press semantics, gesture overlap with the inventory drawer (Prompt 07), gesture overlap with the map board, accidental-tap zones, edge-of-screen safe area on portrait targets.
- This pack does not invent new gameplay logic, new gestures, or new visual treatment. It compares the current UI to a clear minimum and writes down the gap.
- Any implementation discovered here becomes follow-up candidate work only. No accessibility/mobile fix lands inside Prompt 12.5.

## Hard Guardrails

- No save schema change.
- No runtime ownership move.
- No combat math change.
- No item effect change.
- No event outcome change.
- No flow change.
- No new gesture added in this pack.
- No asset hookup or `UiAssetPaths` changes.
- No `temp_screen_theme.gd` rename.
- No code change in this pack; the audit is documentation only. Implementation work is queued as a follow-up, not landed here.

## Validation

- `py -3 Tools/validate_architecture_guards.py`
- markdown/internal link sanity for the new audit doc
- `py -3 Tools/validate_assets.py`

## Done Criteria

- `Docs/UI_ACCESSIBILITY_AND_MOBILE_AUDIT.md` exists and is clearly marked reference-only.
- Each accessibility minimum and each mobile interaction minimum is rated against the live UI.
- Each gap has a severity (`BLOCKER`, `HIGH`, `MEDIUM`, `LOW`) and a proposed narrow follow-up scope.
- A short prioritized queue of follow-up implementation passes is produced (numbered, each scoped to a single owner surface).
- No code, gameplay logic, save schema, or asset state changed.

## Copy/Paste Parts

### Part A - Accessibility Audit

```text
Apply only Prompt 12.5 Part A.

Scope:
- Audit the live UI against these accessibility minimums:
  1. text contrast: body text and important values readable on their actual backgrounds at portrait scale
  2. icon contrast: meaningful (non-decorative) icons readable on their actual backgrounds
  3. color-only signaling: any meaning carried by color alone (e.g., locked vs available, friendly vs hostile, low HP red) must have a second non-color cue (icon, label, shape)
  4. text scaling: whether the live theme allows a player-controllable text scale; if not, mark as gap
  5. motion / flash: any UI motion or flash that exceeds safe thresholds for photosensitive players (combat hit feedback, level-up cues, transitions, hint flashes)
  6. focus / selection visibility: when a target is selected (route node, choice card, button), is the selection state visible without color alone
  7. portrait safe-area: nothing critical sits inside the device safe-area cutouts at the standard portrait targets
- Create Docs/UI_ACCESSIBILITY_AND_MOBILE_AUDIT.md as a reference-only document.

For each minimum, capture:
- current state (PASS / WEAK / FAIL)
- evidence (which screen, which element)
- severity if not PASS (BLOCKER / HIGH / MEDIUM / LOW)
- proposed narrow follow-up scope (single owner surface)

Do not:
- implement any fix
- change gameplay logic
- redesign theme
- approve or hook assets

Validation:
- validate_architecture_guards
- markdown/internal link sanity on the new audit doc

Report:
- files created/changed
- gap counts per severity
- top 5 most impactful accessibility gaps
- explicit confirmation that no code changed
```

### Part B - Mobile Interaction Audit

```text
Apply only Prompt 12.5 Part B.

Scope:
- Extend Docs/UI_ACCESSIBILITY_AND_MOBILE_AUDIT.md with a Mobile Interaction section.
- Audit:
  1. tap vs swipe conflict on the inventory drawer (introduced by Prompt 07)
  2. tap vs drag conflict on inventory cards (drag-to-equip / drag-to-reorder paths)
  3. tap vs swipe / pan conflict on the map board (route selection vs board pan if pan exists)
  4. long-press semantics: are they used consistently or inconsistently
  5. accidental-tap zones near the bottom of the screen (thumb-natural area on portrait)
  6. edge-of-screen safe area on portrait targets
  7. touch target overlap (any two interactive elements with overlapping hitboxes)
  8. minimum touch target dimension on the live theme
  9. confirm-vs-destructive separation on portrait (e.g., Quit vs Continue placement)

For each item, capture:
- current state (PASS / WEAK / FAIL)
- severity if not PASS
- proposed narrow follow-up scope (single owner surface)

Do not:
- introduce new gestures
- redesign drawer interaction model already chosen by Prompt 07
- change input semantics
- add asset hookups

Validation:
- validate_architecture_guards
- markdown/internal link sanity on the audit doc

Report:
- files changed
- mobile-interaction gap counts per severity
- top 5 most impactful interaction gaps
- explicit confirmation that no input semantics changed
```

### Part C - Prioritized Follow-Up Queue And Closeout

```text
Apply only Prompt 12.5 Part C.

Scope:
- In Docs/UI_ACCESSIBILITY_AND_MOBILE_AUDIT.md, produce a final prioritized follow-up queue:
  - each entry must name a single owner surface
  - each entry must state the smallest possible scope that closes the gap
  - each entry must mark whether it requires a save change (should be NO for almost all)
- Update Docs/HANDOFF.md and Docs/ROADMAP.md so Prompt 12.5 is recorded and the UI overhaul wave is closed.
- The follow-up queue is recorded as candidate work, not as committed work.

Do not:
- bundle the follow-ups into a single big pack
- promote any follow-up to active without explicit approval
- declare accessibility complete; the audit only frames the gap
- silently implement any accessibility/mobile fix inside Prompt 12.5

Validation:
- markdown/internal link sanity
- validate_architecture_guards
- validate_assets

Report:
- files changed
- final follow-up queue summary
- explicit confirmation that the UI overhaul wave (06 through 12.5) is now documented as closed pending follow-ups
```
