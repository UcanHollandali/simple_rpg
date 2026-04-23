# Prompt 36 - Combat Final Review Audit Patch Playtest Screenshot Review

Use this prompt pack only after Prompt 35 is closed green.
If Prompt 33 or Prompt 34 were reopened after Prompt 35, close them again before running Prompt 36 so this final gate reviews the actual intended end-of-wave surface.

This is the final integrated review/audit gate for the `21+` combat/content wave.
It combines:

- code/repo review
- narrow corrective patching
- final playtest readback
- final screenshot review

New feature work is out of scope here.

Checked-in filename note:
- this pack lives at `Docs/Archive/Prompts/2026-04-23-closed-green-prompt-packs/36_combat_final_review_audit_patch_playtest_screenshot_review.md`
- checked-in filename and logical queue position now match Prompt `36`

Read first:
- `AGENTS.md`
- `Docs/DOC_PRECEDENCE.md`
- `Docs/HANDOFF.md`
- `Docs/ROADMAP.md`
- `Docs/COMBAT_RULE_CONTRACT.md`
- `Docs/SUPPORT_INTERACTION_CONTRACT.md`
- `Docs/MAP_CONTRACT.md`
- `Docs/SAVE_SCHEMA.md`
- `Docs/CONTENT_BALANCE_TRACKER.md`
- `Docs/WINDOWS_PLAYTEST_BRIEF.md`
- `Docs/TEST_STRATEGY.md`
- the exact landed Prompt `21+` docs that were part of this wave

## Continuation Gate

- touched owner layer: review/docs by default; the narrowest touched runtime/content/UI surfaces required by findings if a corrective patch is needed
- authority doc: the closest authority docs for the actually-landed packs plus `Docs/HANDOFF.md` and `Docs/ROADMAP.md`
- impact: runtime truth `review only by default`; save shape `no by default`; asset provenance `no by default`
- minimum validation set: `py -3 Tools/validate_architecture_guards.py`, touched test slices, `py -3 Tools/validate_content.py` if content changed, portrait screenshot review, explicit full-suite checkpoint if runtime code changed

## Context Statement

Prompt 32 is the first technical checkpoint.
Prompt 35 is the post-wave balance/playtest checkpoint.
Prompt 36 exists to answer the final integration question:

- does the full combat/content wave read coherently as a shipped slice
- do rule changes, UI changes, onboarding changes, and balance notes agree with each other
- are there any narrow remaining contradictions worth patching now
- can the repo close this wave truthfully without hiding known issues

This is not a second feature wave.
It is the final integrated audit gate.

## Goal

Audit the full landed combat/content wave one last time, allow only narrow corrective patches, run a final playtest/screenshot review, and update closeout docs truthfully.

## Direction Statement

- findings first
- narrow corrective patch only if the issue fits the existing lane
- final screenshot review is required here, not optional
- final playtest readback is required here, even if Prompt 35 already ran
- handoff/roadmap sync last
- if findings imply a bigger continuation, record it explicitly instead of smuggling it into cleanup

## Risk Lane / Authority Docs

- lane: mixed final review gate; docs/review by default, guarded only if narrow fixes fit the existing contracts
- authority docs vary by landed packs:
  - `Docs/COMBAT_RULE_CONTRACT.md`
  - `Docs/SUPPORT_INTERACTION_CONTRACT.md`
  - `Docs/MAP_CONTRACT.md`
  - `Docs/SAVE_SCHEMA.md`
- reference-only support docs:
  - `Docs/CONTENT_BALANCE_TRACKER.md`
  - `Docs/WINDOWS_PLAYTEST_BRIEF.md`
- if findings require save-shape, flow-state, owner, node-family, or command-family changes, stop and say `escalate first`

## Hard Guardrails

- No new feature family.
- No queue widening hidden inside final cleanup.
- No save-schema widening unless the prompt stops with `escalate first`.
- No owner move hidden inside review cleanup.
- No reframing of deferred/escalation-only work as if it already shipped.
- No "final" claim unless the remaining issues are recorded truthfully.

## Out Of Scope / Escalation Triggers

Out of scope here:

- new technique design
- advanced enemy-intent implementation
- trainer-node implementation
- stage-count changes
- broader progression systems

If findings point to:

- save-shape change
- new flow state
- source-of-truth move
- node-family change
- new command family

stop and say `escalate first` instead of patching through it.

## Validation

- `py -3 Tools/validate_architecture_guards.py`
- touched test slices
- `py -3 Tools/validate_content.py` if content definitions changed
- final explicit full-suite checkpoint if any runtime code changed
- portrait screenshot review of the final combat/support/map-follow-up surfaces via `Tools/run_portrait_review_capture.ps1` when capture refresh is needed
- final manual playtest note summary
- optional Windows playtest export smoke via `Tools/export_windows_playtest.ps1` if packaged-build confidence is materially useful
- optional `--playtest-log` capture if a traced run is materially useful

## Done Criteria

- the full combat/content wave has one truthful final review record
- any remaining narrow contradictions are fixed or documented
- screenshots show the intended final surface clearly
- final playtest notes agree with the shipped behavior
- `Docs/HANDOFF.md` and `Docs/ROADMAP.md` reflect the actual closeout state
- deferred work stays explicit

## Copy/Paste Parts

### Part A - Final Integrated Review

```text
Apply only Prompt 36 Part A.

Scope:
- Audit the full landed 21+ combat/content wave as one integrated slice.
- Review in this order:
  - core combat rule changes
  - enemy/content changes
  - quest/update follow-up
  - technique delivery and combat use if landed
  - hand-slot swap if landed
  - mechanic UI follow-through
  - onboarding/hint refresh
  - balance/playtest doc sync

Do not:
- patch code in Part A
- start new feature design

Validation:
- validate_architecture_guards
- touched readbacks

Report:
- findings first, ordered by severity
- explicit separation between confirmed issues and assumptions
- explicit note whether any finding requires `escalate first`
- explicit note whether any shipped mechanic still lacks adequate presentation, onboarding, or balance follow-through
```

### Part B - Narrow Final Corrective Patch

```text
Apply only Prompt 36 Part B only if Part A found issues that fit the existing wave.

Scope:
- Land only the narrow corrective patches required by Part A findings.
- Keep fixes inside the already-opened 21+ combat/content scope.

Do not:
- widen into a second feature wave
- hide save/flow/owner changes inside cleanup
- reopen deferred escalation packs silently

Validation:
- touched test slices
- validate_architecture_guards
- validate_content if content changed
- final full-suite checkpoint if runtime code changed

Report:
- files changed
- which findings were fixed
- which findings remain and why
```

### Part C - Final Playtest And Screenshot Review

```text
Apply only Prompt 36 Part C.

Scope:
- Run one final integrated playtest readback and screenshot review over the landed combat/content slice.
- Capture final review evidence for:
  - combat action area
  - enemy threat readability
  - quest/update follow-up if relevant on the map
  - support-acquisition UI if techniques landed
  - hand-slot swap surface if it landed
  - onboarding/hint surfaces if they changed in this wave

Do not:
- invent new acceptance criteria beyond the shipped mechanics
- treat one good screenshot as proof that gameplay is balanced

Validation:
- portrait screenshots
- manual playtest note summary
- optional Windows playtest export smoke if useful
- optional `--playtest-log` capture if useful

Report:
- screenshot paths
- pass/fail per review checkpoint
- final playtest summary
- remaining feel/readability risks
```

### Part D - Final Closeout Sync

```text
Apply only Prompt 36 Part D.

Scope:
- Update Docs/HANDOFF.md and Docs/ROADMAP.md after Parts A-C and any required Part B work are green.
- Record:
  - what shipped in the full 21+ combat/content wave
  - what remained deferred
  - what stayed escalation-only
  - whether the wave is truly closed or only technically paused
  - the next safest continuation if more work remains

Do not:
- claim the wave is fully complete if known blockers remain
- hide escalation items

Validation:
- markdown/internal link sanity
- validate_architecture_guards
- final full-suite checkpoint if runtime code changed earlier in the prompt

Report:
- files changed
- final closeout statement
- remaining risks or escalation notes
```
