# Prompt 14 - Map Topology Contract Reset

Use this prompt pack only after Prompt 13 is closed green.
This pack intentionally rebuilds the active map queue before `Phase D - Playtest and Telemetry`.
This is a docs/contract pack. It does not implement runtime graph, camera, layout, or asset changes by itself.
Do not start Prompt 15-20 until Prompt 14 is closed green.

Checked-in filename note:
- this pack lives at `Docs/Archive/Prompts/2026-04-23-closed-green-prompt-packs/14_map_topology_contract_reset.md`
- checked-in filename and logical queue position now match Prompt `14`

Read first:
- `AGENTS.md`
- `Docs/DOC_PRECEDENCE.md`
- `Docs/HANDOFF.md`
- `Docs/ROADMAP.md`
- `Docs/MAP_CONTRACT.md`
- `Docs/SOURCE_OF_TRUTH.md`
- `Docs/MAP_TOPOLOGY_LOCAL_GRAPH_DESIGN.md`
- `Docs/MAP_COMPOSER_V2_DESIGN.md`
- `Docs/ASSET_PIPELINE.md`
- `Docs/ASSET_LICENSE_POLICY.md`

## Context Statement

Prompt 04, Prompt 05, and Prompt 13 all landed green on the current workspace, but the broader map lane is still blocked on one measured problem:

- topology/layout improvements did not retire the moving-board feel
- the current runtime still contains a live camera/focus chain (`_route_layout_offset`, `MapFocusHelper`, delayed route camera follow)
- that chain can make roads feel like they drift under the player instead of reading as a fixed world
- the map therefore needs a fuller reset than `topology only`

The new `14-20` wave treats this as one connected system:

- procedural grammar
- constrained family placement
- fixed board / no follow
- safe board placement and path generation
- walker motion on the board
- non-routing world fill
- asset/filler hookup
- final audit/patch

## Goal

Reopen the active queue with a new guarded map-overhaul wave that:

1. retires the old `14-18` queue shape
2. establishes the new target model (`template-driven procedural grammar + fixed board diorama`)
3. updates roadmap/handoff language so the repo no longer frames camera/focus drift as part of the desired end state
4. keeps authority boundaries explicit before any runtime patch begins

## Direction Statement

- topology/grammar first
- constrained family placement second
- fixed board / camera reset third
- layout/path/walker/world fill convergence fourth
- map-only asset/filler hookup fifth
- final review/audit/patch last
- save shape, flow state, and owner boundary stay guarded by default
- if a later prompt needs to cross those lines, it must stop and say `escalate first`

## New Queue Shape

Prompt 14 opens this family:

- Prompt 14: contract reset and queue reopen
- Prompt 15: runtime procedural grammar
- Prompt 16: family placement / pacing
- Prompt 17: fixed board / camera / playable rect reset
- Prompt 18: layout / path / walker / world fill convergence
- Prompt 19: prototype asset and filler hookup
- Prompt 20: final review / audit / patch

## Hard Guardrails

- No runtime code change in Prompt 14.
- No save/schema change.
- No flow-state change.
- No owner move.
- No asset approval/hookup.
- No `UiAssetPaths` change.
- No reopening of unrelated UI/combat lanes.
- Do not silently widen `Phase D`; either reopen the queue explicitly or keep it deferred.

## Validation

- markdown/internal link sanity for all touched docs
- queue/order sanity for Prompt `14-20`
- stale `14-18` wording removed from active queue surfaces
- `py -3 Tools/validate_architecture_guards.py`
- if only docs change, the Godot full suite is optional; report whether it was skipped

## Done Criteria

- `Docs/MAP_TOPOLOGY_LOCAL_GRAPH_DESIGN.md` describes the procedural-grammar direction and the `14-20` sequencing
- `Docs/MAP_COMPOSER_V2_DESIGN.md` describes current camera/focus drift as a baseline to retire, not as the target model
- `Docs/ROADMAP.md` records Prompt 14-20 as the active guarded map-overhaul wave
- `Docs/HANDOFF.md` reflects the reopened queue truthfully
- Prompt 17-20 filenames and roles are fixed in the queue surface

## Copy/Paste Parts

### Part A - Contract And Queue Reset

```text
Apply only Prompt 14 Part A.

Scope:
- Rebuild the active map queue as Prompt 14-20.
- Retire the old Prompt 17/18 role wording and any stale 14-18 queue language on active docs surfaces.
- Keep Prompt 14 docs-only.

Required outcomes:
- Prompt 15 = runtime procedural grammar
- Prompt 16 = family placement / pacing
- Prompt 17 = fixed board / camera / playable rect reset
- Prompt 18 = layout / path / walker / world fill convergence
- Prompt 19 = prototype asset and filler hookup
- Prompt 20 = final review / audit / patch

Do not:
- patch runtime code
- change save/flow contracts
- imply that the new queue already landed

Validation:
- markdown/internal link sanity
- validate_architecture_guards

Report:
- files changed
- explicit confirmation that Prompt 14 stayed docs-only
- exact stale queue wording retired
```

### Part B - Design Doc Reset

```text
Apply only Prompt 14 Part B.

Scope:
- Refresh Docs/MAP_TOPOLOGY_LOCAL_GRAPH_DESIGN.md and Docs/MAP_COMPOSER_V2_DESIGN.md for the new target model.
- Keep MAP_CONTRACT.md and SOURCE_OF_TRUTH.md as the authority docs.

Required design rules:
- template-driven procedural grammar, not free scatter
- fixed board diorama, not moving board follow
- character/walker moves on the board
- filler world is non-routing
- variation comes from grammar/placement/assets, not camera drift

Do not:
- widen authority wording
- move truth into UI in docs language
- claim save/flow/owner changes are required

Validation:
- markdown/internal link sanity
- validate_architecture_guards

Report:
- most important newly written design rules
- explicit confirmation that both design docs remain reference-only
```

### Part C - Queue Surface Sync

```text
Apply only Prompt 14 Part C.

Scope:
- Update Docs/ROADMAP.md, Docs/HANDOFF.md, and Docs/DOC_PRECEDENCE.md for the new 14-20 queue.
- Keep Phase D deferred behind Prompt 20.

Do not:
- change gameplay/runtime authority docs
- edit save/flow contracts
- remove asset approval gates

Validation:
- markdown/internal link sanity
- validate_architecture_guards

Report:
- files changed
- exact queue/open-state wording changed
- explicit confirmation that camera/focus drift is no longer described as the desired end state
```
