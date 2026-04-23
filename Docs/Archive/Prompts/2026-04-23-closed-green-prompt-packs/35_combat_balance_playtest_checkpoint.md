# Prompt 35 - Combat Balance Playtest Checkpoint

Use this prompt pack only after Prompt 32 is closed green.
If Prompt 33 or Prompt 34 are opened after technical closeout, close them before running Prompt 35 so the playtest reads the actual intended combat surface.

This is the post-wave manual playtest and narrow balance-check gate for the `21+` combat/content work.
Prompt 36 remains the final integrated review/audit closeout after this checkpoint.
It may end as docs/playtest notes only, or as a narrow guarded tuning patch if the findings fit the existing authority boundaries.

Checked-in filename note:
- this pack lives at `Docs/Archive/Prompts/2026-04-23-closed-green-prompt-packs/35_combat_balance_playtest_checkpoint.md`
- checked-in filename and logical queue position now match Prompt `35`

Read first:
- `AGENTS.md`
- `Docs/DOC_PRECEDENCE.md`
- `Docs/HANDOFF.md`
- `Docs/ROADMAP.md`
- `Docs/COMBAT_RULE_CONTRACT.md`
- `Docs/SUPPORT_INTERACTION_CONTRACT.md`
- `Docs/CONTENT_BALANCE_TRACKER.md`
- `Docs/WINDOWS_PLAYTEST_BRIEF.md`
- `Docs/TEST_STRATEGY.md`
- the exact landed mechanic prompt docs being evaluated

## Continuation Gate

- touched owner layer: review/docs by default; the narrowest combat/content surfaces required by findings if a tuning patch is needed
- authority doc: `Docs/COMBAT_RULE_CONTRACT.md`, `Docs/SUPPORT_INTERACTION_CONTRACT.md`, `Docs/TEST_STRATEGY.md`
- impact: runtime truth `review only by default`; save shape `no by default`; asset provenance `no`
- minimum validation set: `py -3 Tools/validate_architecture_guards.py`, touched test slices if tuning lands, explicit full-suite checkpoint if runtime code changes

## Context Statement

Prompt 32 closes the technical wave honestly.
Prompt 35 answers a different question:

- does the changed combat actually feel better in live runs
- is Defend now too weak, too strong, or finally useful
- do revised enemies create decisions instead of noise
- do techniques earn their space if they landed
- does hand-slot swap produce a real choice if it landed

The repo already has:

- a balance snapshot doc
- a Windows playtest brief
- optional developer telemetry capture via `--playtest-log`
- portrait screenshot capture via `Tools/run_portrait_review_capture.ps1`
- Windows playtest export smoke via `Tools/export_windows_playtest.ps1`

Prompt 35 uses those surfaces instead of improvising a second playtest system.

## Goal

Run a truthful post-wave combat playtest checkpoint, capture findings, and land only narrow balance tuning that fits the current authority boundaries.

## Direction Statement

- feel and fairness first
- no broad feature expansion
- use live runs, not theory only
- update balance-tracker docs truthfully
- if the findings need bigger design changes, record them as deferrals or escalations instead of sneaking them into tuning

## Risk Lane / Authority Docs

- lane: mixed review gate; docs/review by default, guarded only if narrow tuning fits the existing contract
- authority docs:
  - `Docs/COMBAT_RULE_CONTRACT.md`
  - `Docs/SUPPORT_INTERACTION_CONTRACT.md`
  - `Docs/TEST_STRATEGY.md`
- reference-only support docs for this checkpoint:
  - `Docs/CONTENT_BALANCE_TRACKER.md`
  - `Docs/WINDOWS_PLAYTEST_BRIEF.md`
- if the findings require save-shape, flow-state, node-family, or command-family changes, stop and say `escalate first`

## Hard Guardrails

- No new feature family.
- No queue widening hidden inside balance tuning.
- No save-schema widening unless the prompt stops with `escalate first`.
- No owner move hidden inside tuning.
- No framing of subjective feel as if it were confirmed rule truth without evidence.

## Out Of Scope / Escalation Triggers

Out of scope here:

- dedicated trainer node implementation
- advanced enemy-intent implementation
- stage-count changes
- new progression systems

If findings point to:

- new command family
- new flow state
- save-shape change
- node-family change
- source-of-truth move

stop and say `escalate first` instead of tuning through it.

## Validation

- `py -3 Tools/validate_architecture_guards.py`
- touched test slices if tuning lands
- `py -3 Tools/validate_content.py` if content definitions changed
- explicit full-suite checkpoint if runtime code changed
- manual playtest note summary
- optional portrait screenshot capture if visual regressions or readability disputes are part of the findings
- optional Windows playtest export smoke if a packaged-build sanity check is materially useful
- optional `--playtest-log` capture if a traced run is materially useful

## Done Criteria

- combat playtest findings are written down clearly
- `Docs/CONTENT_BALANCE_TRACKER.md` reflects the new live baseline truthfully
- `Docs/WINDOWS_PLAYTEST_BRIEF.md` is refreshed if player focus points changed materially
- only narrow tuning lands, if needed
- bigger issues remain explicit deferred work, not hidden tuning

## Copy/Paste Parts

### Part A - Playtest Findings

```text
Apply only Prompt 35 Part A.

Scope:
- Run a manual combat-focused playtest checkpoint over the landed 21+ combat/content work.
- Evaluate:
  - Defend usefulness and cost
  - enemy pattern readability and decision pressure
  - technique value if Prompt 27 landed
  - hand-slot swap value if Prompt 29 landed
  - whether the combined loop is more strategic and less dull

Do not:
- patch code in Part A
- turn first impressions into rule claims without examples

Validation:
- validate_architecture_guards
- readback plus manual playtest note summary
- optional portrait screenshot capture if readability is disputed
- optional Windows playtest export smoke if build-level confidence is needed
- optional `--playtest-log` capture if useful

Report:
- findings first, ordered by severity
- explicit separation between confirmed issues and assumptions
- exact run situations that produced the findings
```

### Part B - Narrow Balance Tuning

```text
Apply only Prompt 35 Part B only if Part A found issues that fit the existing authority lane.

Scope:
- Land only narrow combat/content tuning required by the playtest findings.
- Allowed examples:
  - Defend numbers inside the already-approved rule shape
  - enemy authored numbers/pattern pacing inside current grammar
  - technique usage numbers inside the already-approved technique contract
  - swap-turn messaging or cost clarity if that is purely tuning and not a rule rewrite

Do not:
- open new mechanics
- change save/flow ownership
- turn a playtest checkpoint into a second feature wave

Validation:
- validate_architecture_guards
- validate_content if definitions changed
- touched test slices
- full suite checkpoint if runtime code changed

Report:
- files changed
- exact findings fixed
- exact findings deferred and why
```

### Part C - Balance And Playtest Sync

```text
Apply only Prompt 35 Part C.

Scope:
- Update:
  - Docs/CONTENT_BALANCE_TRACKER.md
  - Docs/WINDOWS_PLAYTEST_BRIEF.md if player feedback focus changed materially
  - Docs/HANDOFF.md and Docs/ROADMAP.md only if the next continuation recommendation changed
- Record:
  - what the current live combat baseline now is
  - what still feels risky
  - what the next safest continuation should be

Do not:
- write speculative future mechanics as if they already landed
- hide unresolved balance concerns

Validation:
- markdown/internal link sanity
- validate_architecture_guards
- full suite checkpoint if runtime code changed earlier in the prompt

Report:
- files changed
- final balance/playtest checkpoint summary
- remaining risks or next-step recommendations
```
