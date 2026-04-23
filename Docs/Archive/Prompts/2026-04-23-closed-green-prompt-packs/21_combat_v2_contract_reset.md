# Prompt 21 - Combat V2 Contract Reset

Use this prompt pack only after Prompt 20 is closed green and the repo is ready to reopen post-map combat/content work.
This is a future-queue docs/contract pack for the `21-36` combat/content wave.
It does not implement combat math, techniques, hand-slot swap, or new support-node behavior by itself.
Do not start Prompt 22-36 until Prompt 21 is closed green.

Checked-in filename note:
- this pack lives at `Docs/Archive/Prompts/2026-04-23-closed-green-prompt-packs/21_combat_v2_contract_reset.md`
- checked-in filename and logical queue position now match Prompt `21`

Read first:
- `AGENTS.md`
- `Docs/DOC_PRECEDENCE.md`
- `Docs/HANDOFF.md`
- `Docs/ROADMAP.md`
- `Docs/SOURCE_OF_TRUTH.md`
- `Docs/COMBAT_RULE_CONTRACT.md`
- `Docs/CONTENT_ARCHITECTURE_SPEC.md`
- `Docs/MAP_CONTRACT.md`
- `Docs/SUPPORT_INTERACTION_CONTRACT.md`
- `Docs/SAVE_SCHEMA.md`
- `Docs/GAME_FLOW_STATE_MACHINE.md`
- `Docs/TEST_STRATEGY.md`

## Continuation Gate

- touched owner layer: docs only in Prompt 21
- authority doc: `Docs/COMBAT_RULE_CONTRACT.md`, `Docs/SUPPORT_INTERACTION_CONTRACT.md`, `Docs/MAP_CONTRACT.md`, `Docs/SAVE_SCHEMA.md`
- impact: runtime truth `no`; save shape `no`; asset provenance `no`
- minimum validation set: markdown/internal link sanity, queue-order sanity, `py -3 Tools/validate_architecture_guards.py`

## Context Statement

Prompt `14-20` is the closed-green guarded fixed-board map wave.
The repo's live combat identity is still intentionally minimal:

- top-level combat actions remain `Attack`, `Defend`, and direct consumable use
- current enemy content stays inside the narrow sequential-intent grammar
- combat-time gear swap is still locked
- `hamlet` remains the only current side-quest support surface

This makes the next broader combat/content wave possible, but only if the queue reopens explicitly and keeps risk boundaries visible.

## Goal

Reopen the future queue as Prompt `21-36` so the repo can improve combat agency, threat readability, defend tradeoffs, enemy pattern variety, quest follow-up surfaces, mechanic UI follow-through, onboarding refresh, and later high-risk technique / hand-slot swap decisions without silently widening authority boundaries.

## Direction Statement

- threat readability first
- defend tradeoff second
- current-grammar enemy variety third
- quest/update visibility in parallel where safe
- mechanic/runtime prompts must ship with their truthful UI follow-through in the same lane; no invisible mechanic additions
- technique delivery only after explicit escalation-first contract review
- hand-slot swap only after explicit escalation-first contract review
- advanced enemy-intent grammar and dedicated trainer node family stay separate escalation gates
- save shape, flow state, owner meaning, and node-family count stay guarded by default

## Executable Scope Split

Allowed in the first executable wave:

- threat readability follow-up
- defend rebalance with tempo/hunger cost
- enemy pattern variety inside the current sequential-intent grammar
- quest/update follow-up visibility where it stays presentation-only

Deferred behind explicit escalation-first packs:

- dedicated trainer node family
- persistent top-level skill bar
- true multi-hit
- enemy self-buff / self-guard / armor-up runtime
- stage-count increase

## New Queue Shape

Prompt 21 opens this family:

- Prompt 21: combat v2 contract reset (`docs-only` queue-reset gate)
- Prompt 22: combat threat readability follow-up (`low-risk visibility` if presentation-only)
- Prompt 23: defend tempo / hunger pass (`guarded runtime/content`)
- Prompt 24: enemy pattern pack A (`guarded runtime/content`)
- Prompt 25: quest update surface (`low-risk visibility` if presentation-only)
- Prompt 26: support training delivery contract (`escalate first` docs/spec)
- Prompt 27: technique runtime MVP (`guarded runtime/content`)
- Prompt 28: hand-slot swap contract (`escalate first` docs/spec)
- Prompt 29: hand-slot swap runtime surface (`guarded runtime/content`)
- Prompt 30: advanced enemy intents escalation (`escalate first` docs/spec)
- Prompt 31: trainer node family escalation (`escalate first` docs/spec)
- Prompt 32: combat wave checkpoint and handoff (`checkpoint / handoff`)
- Prompt 33: combat mechanic UI audit (`optional low-risk UI audit`)
- Prompt 34: combat onboarding and hint refresh (`optional onboarding refresh`)
- Prompt 35: combat balance playtest checkpoint (`post-wave playtest/balance gate`)
- Prompt 36: combat final review audit patch playtest screenshot review (`final integrated audit gate`)

## Risk Lane / Authority Docs

- Prompt 21 itself is docs-only.
- Prompt 22 and Prompt 25 are low-risk visibility passes if they stay presentation-only.
- Prompt 23, Prompt 24, Prompt 27, and Prompt 29 are guarded runtime/content passes.
- Prompt 26, Prompt 28, Prompt 30, and Prompt 31 are explicit `escalate first` contract/spec packs.
- The first executable wave stays inside the current combat/support/map authority baseline:
  - threat readability, defend-tempo tuning, current-grammar enemy variety, and quest/update visibility are in-bounds
  - advanced enemy-intent grammar is not implied as already supported by current content docs
  - technique runtime follow-through must ship with truthful UI readability in the same lane, but Prompt 21 does not assign technique ownership to UI
- The following items remain explicitly deferred behind escalation-first packs instead of being hidden inside runtime prompts:
  - dedicated trainer node family
  - persistent top-level skill bar
  - true multi-hit
  - enemy self-buff / self-guard / armor-up runtime
  - stage-count increase
- Prompt 33 is an optional low-risk cross-mechanic UI audit pack after mechanic-bearing runtime work lands.
- Prompt 34 is an optional onboarding/hint-refresh pack after mechanic-bearing runtime work lands.
- Prompt 35 is the post-wave manual playtest and narrow balance-check gate.
- Prompt 36 is the final integrated review/audit/patch/playtest/screenshot-review gate.
- Authority remains:
  - `Docs/COMBAT_RULE_CONTRACT.md` for combat identity and current loop rules
  - `Docs/CONTENT_ARCHITECTURE_SPEC.md` for current canonical enemy/status content grammar
  - `Docs/SUPPORT_INTERACTION_CONTRACT.md` for support-surface rules and `hamlet`
  - `Docs/MAP_CONTRACT.md` for node-family and stage-shape truth
  - `Docs/SAVE_SCHEMA.md` and `Docs/GAME_FLOW_STATE_MACHINE.md` for continuation-sensitive changes

## Hard Guardrails

- No runtime code change in Prompt 21.
- No save/schema change.
- No flow-state change.
- No owner move.
- No new node family in Prompt 21.
- No combat verb or command-family addition in Prompt 21.
- Do not frame Prompt 21 as if Prompt 22-36 already landed.
- Do not reopen the map `14-20` wave or rewrite its queue.

## Out Of Scope / Escalation Triggers

Out of scope in Prompt 21:

- technique implementation
- hand-slot swap implementation
- new trainer node family
- stage-count increase
- true multi-hit
- enemy self-buff / self-guard / armor-up runtime

If queue planning would require any of these immediately:

- save-shape widening
- new flow state
- new command family
- new domain event family
- node-family count change
- source-of-truth ownership move

stop and say `escalate first`.

## Validation

- markdown/internal link sanity for touched docs
- prompt-order sanity for `21-36`
- stale wording that still frames broader combat/content work as unqueued future drift should be removed from touched queue surfaces
- `py -3 Tools/validate_architecture_guards.py`
- if only docs change, the Godot full suite is optional; report whether it was skipped

## Done Criteria

- Prompt `21-36` exists as a coherent future queue
- scope is explicitly split between low-risk, guarded, and escalation-first packs
- current map `14-20` wave is not silently replaced
- active docs surfaces can describe this wave truthfully once it is later opened
- high-risk items are separated instead of hidden inside runtime prompts
- runtime prompts explicitly include required UI follow-through instead of assuming another later pass will rescue readability
- an optional post-landing cross-mechanic UI audit exists if the combined combat surface still needs cleanup after multiple mechanic packs
- an optional onboarding-refresh pack exists so new mechanics are taught without inventing a tutorial mode
- a post-wave playtest/balance checkpoint exists so feel problems are not mistaken for implementation completeness
- a final integrated review gate exists so technical closeout, UI follow-through, onboarding, playtest, and screenshots can agree before the wave is called done

## Copy/Paste Parts

### Part A - Contract And Queue Reset

```text
Apply only Prompt 21 Part A.

Scope:
- Rebuild the future combat/content queue as Prompt 21-36.
- Keep Prompt 21 docs-only.
- Define which prompts are:
  - low-risk visibility
  - guarded runtime/content
  - escalate-first docs/spec

Required outcomes:
- Prompt 22 = combat threat readability follow-up
- Prompt 23 = defend tempo / hunger pass
- Prompt 24 = enemy pattern pack A
- Prompt 25 = quest update surface
- Prompt 26 = support training delivery contract
- Prompt 27 = technique runtime MVP
- Prompt 28 = hand-slot swap contract
- Prompt 29 = hand-slot swap runtime surface
- Prompt 30 = advanced enemy intents escalation
- Prompt 31 = trainer node family escalation
- Prompt 32 = combat wave checkpoint and handoff
- Prompt 33 = combat mechanic UI audit
- Prompt 34 = combat onboarding and hint refresh
- Prompt 35 = combat balance playtest checkpoint
- Prompt 36 = combat final review audit patch playtest screenshot review

Do not:
- patch runtime code
- change save/flow contracts
- claim the new wave is already active on the roadmap unless Prompt 21 explicitly updates queue surfaces

Validation:
- markdown/internal link sanity
- validate_architecture_guards

Report:
- files changed
- explicit confirmation that Prompt 21 stayed docs-only
- exact queue wording added or retired
```

### Part B - Authority And Scope Reset

```text
Apply only Prompt 21 Part B.

Scope:
- Refresh the queue-facing docs language so the upcoming combat/content wave stays aligned with current authority docs.
- Make the following split explicit:
  - allowed in the first executable wave
  - deferred behind escalation-first packs

Required scope split:
- allowed first wave:
  - threat readability follow-up
  - defend rebalance with tempo/hunger cost
  - enemy pattern variety inside current grammar
  - quest/update follow-up visibility
- deferred behind explicit escalation:
  - dedicated trainer node family
  - persistent top-level skill bar
  - true multi-hit
  - enemy self-buff / self-guard / armor up
  - stage-count increase

Do not:
- widen authority wording
- imply that content docs already support advanced enemy grammar
- move technique ownership into UI language

Validation:
- markdown/internal link sanity
- validate_architecture_guards

Report:
- most important queue rules written
- explicit confirmation that high-risk items stayed separated
```

### Part C - Queue Surface Sync

```text
Apply only Prompt 21 Part C.

Scope:
- Update the narrowest queue surfaces required to record the future Prompt 21-36 wave truthfully.
- Keep the closed Prompt 14-20 map wave recorded intact; do not reopen or rewrite that queue while syncing the new combat/content wave.

Do not:
- rewrite active map ownership docs
- claim Prompt 21 is already in execution if Prompt 20 is not yet closed green
- remove the existing Phase D-F roadmap language without replacing it truthfully

Validation:
- markdown/internal link sanity
- validate_architecture_guards

Report:
- files changed
- exact queue/open-state wording changed
- explicit confirmation that Prompt 14-20 remained the active wave unless intentionally reopened
```
