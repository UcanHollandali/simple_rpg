# Prompt 24 - Enemy Pattern Pack A

Use this prompt pack only after Prompt 23 is closed green.
This is guarded combat/content work inside the current canonical enemy grammar.
It improves the questions enemies ask the player without opening advanced enemy-intent systems.

Checked-in filename note:
- this pack lives at `Docs/Archive/Prompts/2026-04-23-closed-green-prompt-packs/24_enemy_pattern_pack_a.md`
- checked-in filename and logical queue position now match Prompt `24`

Read first:
- `AGENTS.md`
- `Docs/DOC_PRECEDENCE.md`
- `Docs/HANDOFF.md`
- `Docs/ROADMAP.md`
- `Docs/COMBAT_RULE_CONTRACT.md`
- `Docs/CONTENT_ARCHITECTURE_SPEC.md`
- `Docs/TEST_STRATEGY.md`

## Continuation Gate

- touched owner layer: `ContentDefinitions/`, `Game/Application/` if required, docs, tests
- authority doc: `Docs/COMBAT_RULE_CONTRACT.md`, `Docs/CONTENT_ARCHITECTURE_SPEC.md`
- impact: runtime truth `yes`; save shape `no`; asset provenance `no`
- minimum validation set: `py -3 Tools/validate_content.py`, `py -3 Tools/validate_architecture_guards.py`, targeted combat/content tests, explicit full-suite checkpoint

## Context Statement

Current canonical enemy content already supports:

- sequential intent pools
- `deal_damage`
- narrow `apply_status` against the current player-status slice
- boss-only optional phase-local intent pools

That is enough to create more interesting enemy questions now:

- light pressure into heavy turn
- status pressure into punish window
- greed-punish loops
- boss spikes that force a timing answer

This pack should use that narrow truthful slice instead of pretending advanced grammar already exists.

## Goal

Rebuild a first enemy-pattern pack that makes combat decisions more meaningful through authored intent structure, not through fake complexity or unsupported effect families.

## Direction Statement

- enemies should ask clearer tactical questions, not just hit harder every turn
- use current grammar only
- prefer authored patterns over flat stat inflation
- keep telegraph readability truthful; if the revised pattern needs clearer copy or narrow presenter support, land that in the same pack
- target one first pack:
  - `4` normal enemies
  - `2` elites
  - `1` boss revision
- design for readable pattern identity:
  - light -> heavy
  - status pressure
  - greed punish
  - boss phase spike

## Primary Write Surface

- `ContentDefinitions/Enemies/`
- `ContentDefinitions/Statuses/` only if the current narrow player-status slice needs authored additions
- narrow combat-presentation or copy surfaces only if required to keep the new pattern read truthful
- `Docs/COMBAT_RULE_CONTRACT.md`
- `Docs/CONTENT_ARCHITECTURE_SPEC.md`
- targeted combat/content tests

## Risk Lane / Authority Docs

- lane: guarded content/runtime work inside the existing enemy grammar
- authority docs:
  - `Docs/COMBAT_RULE_CONTRACT.md`
  - `Docs/CONTENT_ARCHITECTURE_SPEC.md`
- if the desired pattern needs true multi-hit, weighted intent selection, enemy self-buff/self-guard, enemy-side status ownership, or a new effect family, stop and say `escalate first`

## Hard Guardrails

- No true multi-hit.
- No weighted intent selection.
- No enemy self-buff / self-guard / armor-up runtime.
- No enemy-side status ownership.
- No save/schema change.
- No flow-state change.
- No stage-count change.

## Out Of Scope / Escalation Triggers

Out of scope here:

- dedicated trainer content
- technique buttons
- hand-slot swap
- new node families
- boss-phase save persistence

If the pack needs:

- new `intent_pool` effect families
- generic trigger families
- enemy-side status ownership
- weighted intent routing

stop and say `escalate first`.

## Validation

- `py -3 Tools/validate_content.py`
- `py -3 Tools/validate_architecture_guards.py`
- `Tests/test_combat_spike.gd`
- `Tests/test_phase2_loop.gd`
- any new targeted content/combat tests added in the same patch
- explicit full-suite checkpoint

## Done Criteria

- the first enemy pack creates clearer tactical questions
- the pack stays inside current content grammar
- no advanced enemy-intent mechanics are smuggled in
- boss revision creates a readable spike pattern
- any required telegraph-copy or narrow UI reinforcement for the landed patterns ships with the pack
- combat/content docs match the landed pack truthfully

## Copy/Paste Parts

### Part A - Enemy Pattern Audit

```text
Apply only Prompt 24 Part A.

Scope:
- Audit the current live enemy set against the desired Pattern Pack A goals.
- Record:
  - which enemy definitions already ask a readable tactical question
  - which ones still feel like flat stat blocks
  - which current statuses are already useful for pressure patterns
  - what the current boss pattern fails to ask the player

Do not:
- patch content or code in Part A

Validation:
- validate_content
- validate_architecture_guards

Report:
- enemy-by-enemy tactical-read audit
- explicit separation between current-grammar possibilities and escalation-only asks
```

### Part B - Pattern Pack Implementation

```text
Apply only Prompt 24 Part B.

Scope:
- Author the first enemy pattern pack inside the current grammar.
- Target:
  - 4 normal enemy revisions/additions
  - 2 elite revisions/additions
  - 1 boss pattern revision
- Use only supported intent/effect families.
- If the new patterns need clearer telegraph copy or narrow presenter adjustments to stay readable, include those in the same patch.

Required pattern families:
- light -> heavy
- status pressure
- greed punish
- boss phase spike

Do not:
- add true multi-hit
- add weighted intent selection
- add enemy self-buff / self-guard / armor-up runtime
- widen into technique or hand-slot swap work

Validation:
- validate_content
- validate_architecture_guards
- targeted combat/content tests
- full suite checkpoint

Report:
- files changed
- enemy definitions touched
- short summary of the tactical question each revised enemy now asks
```

### Part C - Contract And Test Sync

```text
Apply only Prompt 24 Part C.

Scope:
- Update Docs/COMBAT_RULE_CONTRACT.md, Docs/CONTENT_ARCHITECTURE_SPEC.md, and the targeted tests only as needed to reflect the landed current-grammar enemy pack truthfully.
- Keep the docs narrow:
  - what now exists
  - what still remains escalation-only

Do not:
- overstate the grammar
- leave stale old enemy-pattern wording behind

Validation:
- validate_content
- validate_architecture_guards
- targeted combat/content tests
- full suite checkpoint

Report:
- files changed
- exact new locks added
- exact escalation-only items still deferred
```
