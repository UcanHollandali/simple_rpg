# SIMPLE RPG - Experiment Bank

## Purpose

This file stores speculative ideas that are worth testing but not worth locking yet.

It is intentionally non-authoritative.
Anything here stays optional until it is promoted into an owning doc and recorded in `DECISION_LOG.md`.

## Keep Here Only If

- the idea is useful but not validated
- the idea could change scope if accepted too early
- the idea is better tested in prototype than argued in docs

Do not use this file for:
- accepted project rules
- routine TODOs
- implementation chores
- long-form design essays

## Active Experiment Buckets

### Combat Variants

- additional status families
- alternate `Defend` / `Guard` payoffs
- niche enemy behaviors
- boss threshold behavior beyond the baseline

### Item and Weapon Space

- extra weapon families beyond the first compact set
- more exotic consumables
- more specialized passive identities

### Progression Space

- additional build families
- run-start kit choices
- meta progression variants

### Build Identity Hypotheses

- `Iron Wall`: durable, defend-first, low-risk build; succeeds only if shield/guard play stays distinct without slowing the game too much.
- `Glass Edge`: aggressive, tempo-first build; succeeds only if intent reading creates real payoff instead of pure stat racing.
- `Scavenger`: consumable-centered build; succeeds only if local hold-vs-use and consumable slot decisions remain stronger than simple hoarding.
- `Scrap Keeper`: durability-economy build; succeeds only if repair and long-route planning become meaningful without turning into bookkeeping.

These stay experiments, not archetype commitments.
If two hypotheses collapse into the same play pattern, cut one instead of protecting all four.

### Difficulty and Scaling Hypotheses

- starting HP around `60` is a reasonable prototype baseline
- early normal enemies likely need low damage and low intent complexity
- bosses should differ more through readable pacing than raw stat inflation
- difficulty should come from route pressure, resource use, and intent reading, not hidden spikes
- if players cannot explain why they lost, the current numbers are wrong even if win rate looks acceptable

### Map and Node Space

- richer event families
- more route condition types
- later-stage systemic twists

## Prototype Validation Questions

Use these questions to decide whether to cut, keep, or simplify systems.
If a question fails, reduce surrounding system load before adding more mechanics.

### Hunger

Question:
- is hunger creating real decisions or just passive tax?

Pass signal:
- hunger changes route, item, or combat timing often enough to be noticed

Fail reaction:
- simplify it hard, retune aggressively, or merge it into another pressure system

### Slot Contention

Question:
- do passive replacement and consumable discard choices feel real instead of automatic?

Pass signal:
- reward/drop decisions produce visible pause and tradeoff

Fail reaction:
- suspect passive variety, slot counts, or over-similar item effects before adding more systems

### Reward Cadence

Question:
- does reward presentation preserve mobile portrait tempo?

Pass signal:
- rewards are visible and earned without turning every win into friction

Fail reaction:
- reduce reward presentation overhead before expanding reward complexity

### Archetype Readability

Question:
- are build identities actually distinct, or are they just stat-tuned variants?

Pass signal:
- each build direction can be described in one clean sentence

Fail reaction:
- merge or cut overlapping build directions

### Decision Density

Question:
- is the run producing real decisions, or mostly maintenance and UI handling?

Pass signal:
- meaningful decisions at least match maintenance actions

Fail reaction:
- cut or automate the heaviest maintenance system first

## Promotion Rule

An idea leaves this file only when:
1. it proves useful in testing or implementation
2. it fits the locked project scope
3. its owning doc is updated
4. the decision is recorded if it becomes project-level
