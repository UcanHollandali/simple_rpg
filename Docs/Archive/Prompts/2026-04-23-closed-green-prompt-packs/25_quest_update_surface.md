# Prompt 25 - Quest Update Surface

Use this prompt pack only after Prompt 21 is closed green.
This is a low-risk map/UI follow-up pack over existing quest truth.
It does not create a new quest grammar or change contract resolution rules.

Checked-in filename note:
- this pack lives at `Docs/Archive/Prompts/2026-04-23-closed-green-prompt-packs/25_quest_update_surface.md`
- checked-in filename and logical queue position now match Prompt `25`

Read first:
- `AGENTS.md`
- `Docs/DOC_PRECEDENCE.md`
- `Docs/HANDOFF.md`
- `Docs/ROADMAP.md`
- `Docs/MAP_CONTRACT.md`
- `Docs/SUPPORT_INTERACTION_CONTRACT.md`
- `Docs/SAVE_SCHEMA.md`
- `Docs/TEST_STRATEGY.md`

## Continuation Gate

- touched owner layer: `Game/UI/`, `scenes/`
- authority doc: `Docs/SUPPORT_INTERACTION_CONTRACT.md`, `Docs/MAP_CONTRACT.md`, `Docs/SAVE_SCHEMA.md`
- impact: runtime truth `no` by default; save shape `no`; asset provenance `no`
- minimum validation set: `py -3 Tools/validate_architecture_guards.py`, targeted map/UI tests, map scene isolation if wiring changes

## Context Statement

The repo already has a live quest-log surface for the current `hamlet` side-mission slice.
The next safe improvement is not a new quest system.
It is making updates easier to notice and easier to act on:

- badge / unread signal
- compact corner launcher
- ready-to-turn-in state
- small quest-update toast
- light known-target hinting without GPS-style auto-routing

The source of truth remains the existing `hamlet` request state.

## Goal

Improve quest follow-up visibility so accepted and completed `hamlet` requests are easier to notice and route around without changing quest ownership or quest resolution rules.

## Direction Statement

- reuse current `hamlet` request truth
- keep the map surface lightweight
- the quest entrypoint should stay a compact corner launcher that expands into a drawer/panel when tapped
- show updates without flooding the player
- support "return to hamlet" clarity
- avoid auto-pathing or over-explaining hidden targets
- any badge / unread treatment must be derived from current quest truth plus session-local UI state only, not from new persisted unread state

## Preferred Owner Surfaces

- `Game/UI/map_quest_log_model_builder.gd`
- `Game/UI/map_quest_log_panel.gd`
- `Game/UI/map_explore_presenter.gd`
- `Game/UI/map_explore_scene_ui.gd`
- `scenes/map_explore.gd` only for narrow composition hooks if unavoidable

## Risk Lane / Authority Docs

- default lane: low-risk fast lane if the pack stays presentation-only
- authority docs:
  - `Docs/SUPPORT_INTERACTION_CONTRACT.md`
  - `Docs/MAP_CONTRACT.md`
  - `Docs/SAVE_SCHEMA.md`
- if the desired result needs new quest-state persistence, a new quest grammar, or node-target auto-routing truth, stop and say `escalate first`

## Hard Guardrails

- No new quest grammar.
- No new node family.
- No save/schema change.
- No flow-state change.
- No always-open large quest panel by default.
- No auto-pathing or forced route line.
- No hidden gameplay truth move into UI.
- No persisted unread/update ledger.

## Out Of Scope / Escalation Triggers

Out of scope here:

- completed-history archive beyond current truthful runtime support
- new quest categories
- quest failure/expiration systems
- support-node behavior change

If the requested feature needs:

- new persisted quest fields
- persisted unread/update state
- non-`hamlet` quest ownership
- explicit route guidance truth
- cross-scene toast ownership outside the current map/UI lane

stop and say `escalate first`.

## Validation

- `py -3 Tools/validate_architecture_guards.py`
- `Tests/test_map_explore_presenter.gd`
- `Tests/test_map_quest_log_ui.gd`
- `Tools/run_godot_scene_isolation.ps1 -ScenePath scenes/map_explore.tscn` if scene wiring changed
- explicit full suite is optional if the pack stays UI-only; report whether it was skipped

## Done Criteria

- the quest launcher stays compact and expands into a readable drawer/panel on demand
- quest updates are easier to notice
- ready-to-turn-in state is clearly visible
- known-target hinting, if present, stays light and non-spoilery
- no new quest persistence or resolution logic lands
- the map surface stays readable

## Copy/Paste Parts

### Part A - Quest Update Audit

```text
Apply only Prompt 25 Part A.

Scope:
- Audit the current quest-log and map follow-up surfaces for:
  - accepted state visibility
  - completed / ready-to-turn-in visibility
  - update discoverability
  - target clarity on the map

Do not:
- patch quest logic in Part A
- invent missing quest truth

Validation:
- validate_architecture_guards
- readback only

Report:
- confirmed visibility gaps
- explicit separation between existing runtime truth and desired future truth
```

### Part B - Update Surface Pass

```text
Apply only Prompt 25 Part B.

Scope:
- Improve quest follow-up visibility using existing truth only.
- Allowed moves:
  - compact launcher that expands/collapses the quest log drawer/panel
  - quest badge / unread signal
  - ready-to-turn-in chip
  - small quest-update toast
  - light known-target hinting when the target is already known truthfully

Do not:
- add auto-pathing
- add new quest grammar
- add save fields
- add persisted unread/update state
- widen into support-interaction rule changes

Validation:
- validate_architecture_guards
- targeted map/UI tests
- map scene isolation if wiring changed

Report:
- files changed
- exact update surfaces added or refined
- explicit confirmation that gameplay truth ownership did not move
```

### Part C - Quest Visibility Checkpoint

```text
Apply only Prompt 25 Part C.

Scope:
- Review the landed quest follow-up surfaces in the map screen.
- Verify:
  1. the compact launcher expands/collapses the quest surface clearly
  2. accepted quest state is easier to notice
  3. ready-to-turn-in state is easier to notice
  4. any known-target hint stays light and non-GPS-like
  5. no fake completed-history surface appears without real truth behind it

If a checkpoint fails:
- open only a narrow follow-up in the same map/UI owner scope

Validation:
- validate_architecture_guards if code changed
- targeted map/UI tests if code changed
- full suite optional if the pack stayed UI-only

Report:
- screenshot or UI check summary
- pass/fail per checkpoint
- any follow-up tuning still needed
```
