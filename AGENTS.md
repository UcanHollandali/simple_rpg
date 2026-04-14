# SIMPLE RPG - AI Agent Rules

This file is the repo-level operating contract for AI coding agents.

## Read First

Before changing code:
1. Read [Docs/DOC_PRECEDENCE.md](Docs/DOC_PRECEDENCE.md).
2. Read [Docs/HANDOFF.md](Docs/HANDOFF.md) for the current repo snapshot, blockers, and recommended next step.
3. Then read only the authority docs relevant to the task.

Use `Docs/HANDOFF.md` as current-state context only.
Use `Docs/DOC_PRECEDENCE.md` plus the closest authority doc for actual rules.

Task-specific docs:
- Combat work -> [Docs/COMBAT_RULE_CONTRACT.md](Docs/COMBAT_RULE_CONTRACT.md)
- Map work -> [Docs/MAP_CONTRACT.md](Docs/MAP_CONTRACT.md)
- Reward/progression work -> [Docs/REWARD_LEVELUP_CONTRACT.md](Docs/REWARD_LEVELUP_CONTRACT.md)
- Support/economy work -> [Docs/SUPPORT_INTERACTION_CONTRACT.md](Docs/SUPPORT_INTERACTION_CONTRACT.md)
- Save work -> [Docs/SAVE_SCHEMA.md](Docs/SAVE_SCHEMA.md)
- Flow work -> [Docs/GAME_FLOW_STATE_MACHINE.md](Docs/GAME_FLOW_STATE_MACHINE.md)
- Testing work -> [Docs/TEST_STRATEGY.md](Docs/TEST_STRATEGY.md)
- Visual/audio production work -> [Docs/ASSET_PIPELINE.md](Docs/ASSET_PIPELINE.md) and [Docs/ASSET_LICENSE_POLICY.md](Docs/ASSET_LICENSE_POLICY.md)

## Non-Negotiables

- Do not move gameplay truth into UI.
- Do not mix definition data with runtime state.
- Do not use display text as logic keys.
- Do not add gameplay autoloads for convenience.
- Do not treat `RunState` compatibility accessors as a permanent expansion surface.
- Do not hide mechanic changes inside content additions.
- Do not widen scope silently.

## Allowed Change Matrix

| Task type | Typical write scope | Required checks |
|---|---|---|
| Content-only | `ContentDefinitions/`, maybe `Docs/CONTENT_ARCHITECTURE_SPEC.md` | schema validation, ID/reference checks |
| UI-only | `Game/UI/`, `scenes/` | no gameplay truth drift |
| Core rule change | `Game/Core/`, related docs | rule tests, invariants |
| Flow change | `Game/Application/`, flow docs | transition tests |
| Save-sensitive | `Game/RuntimeState/`, `Game/Infrastructure/`, save docs | roundtrip plus invariant checks |
| Mechanic change | code plus authoritative docs plus decision log | docs updated before done |

## Risk Lanes

Use these lanes to decide whether a request can run in a fast path or needs the full guarded pass.

### Low-Risk Fast Lane

Use the fast lane only if all of these stay true:
- no save-schema shape or save-version change
- no flow-state addition or transition-contract change
- no source-of-truth ownership move
- no new command family or domain-event family
- no scene/core boundary rewrite
- no compatibility cleanup that would need migration or back-compat policy

Typical safe fast-lane work in this repo:
- `Game/UI/` presenter/helper extraction
- `scenes/` composition cleanup that does not take gameplay/save/flow truth ownership
- test cleanup that moves reads toward existing owners
- validator/tooling hardening
- doc cleanup that keeps the same authority meaning

Fast-lane validation baseline:
- changed-area validators/tests
- add smoke only if scene/autoload boot wiring changed
- explicit full suite only at a checkpoint or before claiming repo-wide cleanliness

### Medium-Risk Guarded Lane

Use the guarded lane when the change stays inside existing authority boundaries but can still break orchestration or continuation confidence.

Typical guarded-lane work in this repo:
- `Game/Application` orchestration changes that keep the same owners
- save/load orchestration changes that keep the same schema shape
- mechanic tuning inside an existing contract
- large-file extraction where ownership stays the same but fan-out risk is real

Guarded-lane requirements:
- update the closest authority doc in the same patch if behavior or interpretation changed
- run targeted tests for the touched slice
- run the explicit full suite before closing the pass
- run smoke when boot, autoload, or scene wiring changed

### High-Risk Escalate-First Lane

Do not treat these as fast cleanup:
- save-schema/version changes
- migration or compatibility-removal work
- `RunState.current_node_index` cleanup
- `armor_instance` / `belt_instance` cleanup
- new flow state
- new command family
- new domain event family
- source-of-truth ownership move
- gameplay autoload addition
- scene/core boundary changes

If a request crosses into this lane, stop and explicitly say `escalate first` before implementation.

## Repo-Specific Risk Map

Default low-risk areas:
- `Game/UI/`
- `Tools/`
- doc truth-alignment patches
- tests that move toward already-authoritative owners

Default medium-risk areas:
- `Game/Application/app_bootstrap.gd`
- `Game/Application/run_session_coordinator.gd`
- `Game/Application/save_runtime_bridge.gd`
- `Game/Application/combat_flow.gd`
- `scenes/map_explore.gd` when the change is more than pure presentation extraction

Default high-risk areas:
- `Game/RuntimeState/run_state.gd`
- `Game/RuntimeState/inventory_state.gd`
- `Game/RuntimeState/map_runtime_state.gd`
- `Game/Infrastructure/save_service.gd`
- `Game/Application/game_flow_manager.gd`
- `Docs/SAVE_SCHEMA.md`
- any patch that changes owner meaning rather than only improving wiring

Risk-map maintenance rules:
- these lanes are workflow heuristics, not gameplay or technical authority
- if a closest authority doc disagrees, the authority doc wins
- if uncertainty remains after inspection, choose the higher-risk lane, not the lower one
- if a patch makes this map stale, update or prune the stale entry in the same patch
- keep this map short; do not let file lists grow into stale cargo

## Escalation Triggers

Stop and surface the change if it affects:
- stable ID rename
- save schema shape
- new flow state
- new command family
- new domain event family
- source-of-truth ownership rule
- gameplay autoload need
- scene/core boundary change

## Content Patch Template

For content additions, reason using:
- `definition_id`
- `family`
- `tags`
- `reused grammar`
- `new mechanic required: yes/no`
- `validation required`

## Working Style

- Make small, local changes.
- Read only the docs relevant to the task.
- For new scene/UI/test work, prefer the real runtime owner or narrow application surface over adding new `RunState` compatibility-facade usage.
- Prefer the smallest safe patch.
- Validate the changed area.
- Report what changed, what did not, and what still needs checking.

## Continuation Gate

For any non-trivial human or AI continuation pass, state these before or alongside the implementation work:
- `touched owner layer`
- `authority doc`
- `impact: runtime truth / save shape / asset-provenance`
- `minimum validation set`

If the honest answer implies a change to flow, save shape, or source-of-truth ownership, stop and escalate before implementation instead of continuing as a narrow patch by default.

This gate is workflow-only.
It does not create a new gameplay or technical authority surface.

## Speed Mode Contract

If the user asks for `hiz modu` or an equivalent fast path:
- stay in the low-risk fast lane by default
- require the user to name the scope and what to ignore for now
- do not silently widen into guarded or high-risk work just because related debt is visible
- if the work turns out not to be low-risk after inspection, stop and say why

Useful user prompt fields:
- `mode`
- `scope`
- `do not touch`
- `validation budget`
- `doc policy`

## Success Condition

A change is successful when:
- the request is solved
- unrelated systems are not destabilized
- docs stay truthful
- future humans and agents can understand the change quickly
