# Prompt 32 - Combat Wave Checkpoint And Handoff

Use this prompt pack only after Prompt 24 and Prompt 25 are closed green and after Prompt 27 / Prompt 29 only if those packs actually landed.
If Prompt 33 is opened for a cross-mechanic combat UI audit, or Prompt 34 is opened for onboarding refresh, close those packs before running Prompt 32.
This is the first technical checkpoint and closeout gate inside the broader `21-36` combat/content wave.
New feature design is out of scope here.

Checked-in filename note:
- this pack lives at `Docs/Archive/Prompts/2026-04-23-closed-green-prompt-packs/32_combat_wave_checkpoint_and_handoff.md`
- checked-in filename and logical queue position now match Prompt `32`

Read first:
- `AGENTS.md`
- `Docs/DOC_PRECEDENCE.md`
- `Docs/HANDOFF.md`
- `Docs/ROADMAP.md`
- `Docs/COMBAT_RULE_CONTRACT.md`
- `Docs/SUPPORT_INTERACTION_CONTRACT.md`
- `Docs/MAP_CONTRACT.md`
- `Docs/SAVE_SCHEMA.md`
- `Docs/TEST_STRATEGY.md`

## Continuation Gate

- touched owner layer: review plus the narrowest touched surfaces required by findings
- authority doc: the closest authority docs for the actually-landed packs plus `Docs/HANDOFF.md` and `Docs/ROADMAP.md`
- impact: runtime truth `review only by default`; save shape `no by default`; asset provenance `no by default`
- minimum validation set: `py -3 Tools/validate_architecture_guards.py`, touched test slices, explicit full-suite checkpoint if runtime patches land

## Context Statement

Prompt 32 reviews the first combat/content wave as it actually landed, not as originally imagined.
At minimum this checkpoint should cover:

- Prompt 22 threat readability follow-up if landed
- Prompt 23 defend tempo/hunger pass
- Prompt 24 enemy pattern pack A
- Prompt 25 quest update surface

If later packs also landed, include them too:

- Prompt 27 technique runtime MVP
- Prompt 29 hand-slot swap runtime surface
- Prompt 33 combat mechanic UI audit if it landed
- Prompt 34 combat onboarding and hint refresh if it landed

Prompt 30 and Prompt 31 are escalation-only docs packs and should be reported as such, not treated as shipped gameplay.

## Goal

Audit the first combat/content wave together, land only narrow corrective patches if needed, and update handoff/queue surfaces truthfully.

## Direction Statement

- review findings first
- narrow corrective patch second, only if issues fit the already-opened lane
- final handoff sync last
- do not turn the checkpoint into a new implementation wave
- escalation-only items must stay clearly separated from shipped runtime features

## Risk Lane / Authority Docs

- lane: mixed review gate; default docs/review, guarded only if narrow runtime fixes are needed
- authority docs vary by landed packs:
  - `Docs/COMBAT_RULE_CONTRACT.md`
  - `Docs/SUPPORT_INTERACTION_CONTRACT.md`
  - `Docs/MAP_CONTRACT.md`
  - `Docs/SAVE_SCHEMA.md`
- if review findings require save-shape, flow-state, owner, or node-family changes, stop and say `escalate first`

## Hard Guardrails

- No new feature family.
- No queue widening hidden inside closeout.
- No save-schema widening unless the prompt stops with `escalate first`.
- No owner move hidden inside cleanup.
- No reframing of escalation-only docs packs as shipped runtime work.

## Out Of Scope / Escalation Triggers

Out of scope here:

- new technique design
- advanced enemy-intent implementation
- trainer-node implementation
- stage-count changes

If findings point to:

- save-shape change
- new flow state
- source-of-truth move
- node-family change

stop and say `escalate first` instead of patching through it.

## Validation

- `py -3 Tools/validate_architecture_guards.py`
- touched test slices
- `py -3 Tools/validate_content.py` if content definitions were touched in corrective work
- portrait or UI verification if visual fixes landed
- final explicit full-suite checkpoint if any runtime code changed

## Done Criteria

- the first combat/content wave has a truthful review record
- only narrow corrective patches land, if needed
- `Docs/HANDOFF.md` and `Docs/ROADMAP.md` reflect what actually shipped and what stayed deferred
- escalation-only items remain clearly marked
- any landed mechanic additions are reviewed together with their shipped UI surfaces
- if Prompt 33 landed, its findings are reflected instead of being silently folded into unrelated prompts
- if Prompt 34 landed, its onboarding changes are reflected instead of being silently folded into unrelated prompts

## Copy/Paste Parts

### Part A - Wave Review Findings

```text
Apply only Prompt 32 Part A.

Scope:
- Audit the first combat/content wave as one chain.
- Review all landed packs in this order:
  - threat readability follow-up
  - defend tempo/hunger pass
  - enemy pattern pack A
  - quest update surface
  - technique runtime MVP if it landed
  - hand-slot swap runtime surface if it landed
  - combat mechanic UI audit if it landed
  - combat onboarding and hint refresh if it landed

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
- explicit note whether any landed mechanic lacks an adequate UI surface
```

### Part B - Narrow Corrective Patch

```text
Apply only Prompt 32 Part B only if Part A found issues that fit the existing wave.

Scope:
- Land only the narrow corrective patches required by Part A findings.
- Keep fixes inside the already-opened 21-36 combat/content scope.

Do not:
- widen into a second large feature wave
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

### Part C - Final Handoff Sync

```text
Apply only Prompt 32 Part C.

Scope:
- Update Docs/HANDOFF.md and Docs/ROADMAP.md after Part A and any required Part B work are green.
- Record:
  - what shipped in the first technical tranche of the 21-36 wave
  - what remained deferred
  - which packs stayed docs-only escalation gates
  - what the next safest continuation is

Do not:
- claim escalation-only work shipped as runtime behavior
- hide remaining risks

Validation:
- markdown/internal link sanity
- validate_architecture_guards
- final full-suite checkpoint if runtime code changed earlier in the prompt

Report:
- files changed
- final closeout statement
- remaining risks or escalation notes
```
