# SIMPLE RPG - Map Topology Local Graph Design

## Status

- This file is a reference design companion for one map-overhaul direction.
- Authority remains `Docs/MAP_CONTRACT.md` for map structure, `Docs/SOURCE_OF_TRUTH.md` for runtime ownership, and `Docs/SAVE_SCHEMA.md` / `Docs/GAME_FLOW_STATE_MACHINE.md` for save/flow boundaries.
- This file does not authorize save-shape, flow-state, or owner-boundary changes by itself.
- This file is not a queue surface.

## Continuation Gate

- touched owner layer: `workflow/docs + map topology design/reference`
- authority doc: `Docs/MAP_CONTRACT.md`
- impact: `runtime truth may change in later implementation prompts`; `save shape stays guarded by default`; `asset provenance remains gated by ASSET_PIPELINE.md and ASSET_LICENSE_POLICY.md`
- minimum validation set: `design review against MAP_CONTRACT.md, SOURCE_OF_TRUTH.md, MAP_COMPOSER_V2_DESIGN.md, and the current runtime/test baseline`

## Certain Current Baseline

These points describe the checked-in repo state, not a proposal:

- `MapRuntimeState` is the current runtime owner of stage-local node identity, adjacency, node state, current node, key/boss-gate truth, roadside quota state, support revisit state, hamlet side-quest state, and pending node context.
- The current runtime slice uses a bounded `14`-node controlled-scatter graph keyed by the `procedural_stage_*` profile ids.
- The current topology keeps the opening shell explicit: start exposes early combat, early reward, and early support under fixed stage quotas.
- Family placement already happens after topology; it is not UI-owned.
- `MapBoardComposerV2` and its helper chain derive board positions and route geometry from runtime truth; they do not own traversal truth.
- The board already keeps a frozen full-layout baseline at stage start; discovery changes the visible subset, not the graph signature.
- A live camera/focus chain still exists in code (`_route_layout_offset`, `MapFocusHelper`, delayed route camera follow progress). That is current baseline behavior to review/retire, not a rule that the new wave must preserve.
- Asset-facing map owners now exist for ground and filler (`MapBoardGroundBuilder`, `MapBoardFillerBuilder`), but they remain derived/non-routing and do not solve graph-truth problems by themselves.

## Problem Statement

The current stack already distinguishes runtime truth, layout, and visual-world layers, but the practical playtest problem is still broader than topology alone:

- free scatter plus later layout tuning can still read like a generated adjacency diagram instead of a discoverable world
- the live moving-board/focus-drift chain can make roads feel unstable even when the underlying graph is better
- asset polish is harder to land convincingly when structure, camera behavior, and world fill do not already agree
- hunger wants route commitment and travel-cost meaning; that pressure weakens when graph grammar and board presentation feel loose

This design direction treats map quality as one staged pipeline rather than as isolated topology or asset work.

## Design Goals

- Preserve `MAP_CONTRACT.md` bounded-exploration identity.
- Keep the player start anchored around a readable center-local origin / anchor zone.
- Shift the graph feel from `free scatter + later rescue` toward `template-driven procedural grammar`.
- Preserve the stage guarantee floor and current node-family set.
- Make route commitment more legible under hunger pressure.
- Keep layout a follower of graph truth, not the system that rescues bad graph truth.
- Keep assets/filler after structure; visuals should reinforce a coherent world, not compensate for topology drift.
- Produce variation through structure, placement, and semantic dressing, not through camera drift.

## Target Model Summary

- Use `template-driven procedural grammar` as the structural direction instead of `free scatter + later rescue`.
- Treat the board goal as a `fixed-board diorama`, not a moving-board follow presentation.
- Keep the player/walker moving on the board rather than translating the world under the route.
- Keep filler and world dressing derived/non-routing so traversal truth stays in the node/path graph.
- Source variation from grammar, placement, semantic asset bind, and filler dressing rather than from camera drift or follow compensation.

## Runtime Owner Boundary

### Current Owner Rule (Certain)

- `MapRuntimeState` remains the gameplay owner of graph truth.
- `RunSessionCoordinator` remains the movement-resolution / flow-routing owner.
- `MapBoardComposerV2` remains a derived presentation owner only.

### Future-Implementation Boundary Rule (Proposed)

- Future implementation that follows this design may redesign `MapRuntimeState` graph-generation rules.
- Future implementation that follows this design may redesign fixed-board placement rules in derived presentation owners.
- Future implementation that follows this design must not move map truth into UI, scenes, `RunState`, or `AppBootstrap`.
- Future implementation that follows this design must not widen save truth by default.
- If later implementation discovers that save/flow/owner boundaries must change, it must stop and say `escalate first` instead of silently widening scope.

## Proposed Map Pipeline

The target model is:

1. `topology grammar`
2. `family placement`
3. `fixed-board playable-rect placement`
4. `path generation`
5. `walker-on-board behavior`
6. `semantic asset bind`
7. `negative-space filler`
8. `final audit`

This is the intended sequencing if this design direction is resumed.

## Procedural Grammar Direction

### Name

`template-driven procedural grammar`

This is not:

- fully authored static map
- fully free random node scatter

It is controlled procedural generation:

- each run varies
- each run still speaks the same structural language

### Stage Blueprint Direction

The graph should begin from a blueprint/template choice before pixel placement exists.

Examples of the intended level of abstraction:

- `3 spoke + short pocket`
- `2 spoke + key flank`
- `3 spoke + support detour`

The exact template list remains implementation-tunable, but the generation model should pick a structural idea first instead of scattering nodes blindly and trying to recover order later.

### Abstract Graph Rule

After blueprint choice:

- build an abstract graph
- keep depth-band progression explicit
- prefer local forward edges
- keep reconnects limited
- reject long-span edge logic as a default behavior

`nearest in the whole graph` is not a good enough rule by itself.
The intended rule is `near + forward + degree-safe + readable`.

### Degree Rule

- Start should expose a small number of meaningful openings, not a dense starburst.
- Most non-start nodes should remain in the `1-2` degree range.
- `3`-way nodes may exist, but as exceptions that add route variety rather than becoming a default shape.
- High-degree graph hubs are outside the intended feel.

### Reconnect Rule

- Reconnect/merge is allowed, but it is a seasoning rule, not the default graph language.
- Reconnects should be short, local, and readable.
- The graph should not collapse into either:
  - a pure tree with no local correction
  - or a spaghetti mesh with too many cross-branch joins

## Family Assignment Direction

- Topology comes first.
- Family placement comes second.
- Family placement should be `constrained random`, not flat random.
- Early exposure floor remains mandatory:
  - early combat
  - early reward
  - early support
- `event` and `hamlet` should still feel like detours, not like random icon swaps.
- `key` and `boss` should still live in the late pressure region.

## Fixed-Board Placement Direction

- The target board model is a fixed board diorama.
- The camera should not follow the character as the desired end state.
- The player/walker should move on the board.
- Placement should happen inside a defined playable rect / generation envelope.
- The envelope must leave safe room for:
  - node radius
  - path width
  - walker footprint
  - overlay clearance

The goal is not `scatter freely, then clamp late`.
The goal is `generate inside safe bounds from the start`.

## Path And Walker Direction

- Path generation happens after topology/family/placement are coherent.
- Paths should be readable, local, and stable.
- Walker motion should reinforce the feeling of traversing a small world.
- Variation must not depend on moving the board or recentering the camera under the walker.

## Filler And Asset Direction

- Semantic assets come after structure.
- Negative-space filler comes last in structural terms, even if assets and filler may be implemented in separate prompt packs.
- Filler world is visual only:
  - ground
  - forest
  - ruin
  - canopy
  - clutter
- Filler must never become routing truth.

This is the core rule:

`filler world gives atmosphere; node/path graph remains traversal truth`

## Hunger And Route Pressure

The reopened direction exists partly because hunger makes route cost matter.

Desired player reads:

- `short safer route`
- `longer reward route`
- `support detour now or later`
- `push key now or stabilize first`

Undesired player reads:

- `every icon is globally reachable anyway`
- `the board shifts around me so the route itself does not feel grounded`

## Variation Sources

The target variability should come from:

- blueprint/template choice
- graph variation
- family placement variation
- safe placement jitter
- semantic asset variation
- filler variation

The target variability should not depend on:

- camera drift
- board follow
- world translation under the walker

## Save / Flow / Ownership Impact

### Baseline Conclusion (Proposed)

- Save-shape change is not required by the baseline direction.
- Flow-state change is not required by the baseline direction.
- Owner-boundary change is not required by the baseline direction.

### Explicit Escalation Triggers

Escalate before implementation if later implementation requires:

- widening save payload shape beyond the current realized graph contract
- storing presentation-led coordinates as runtime truth
- moving graph truth out of `MapRuntimeState`
- adding a new flow state just to support this design direction
- moving pending-node, key/gate, or traversal truth into UI/presentation surfaces

## Acceptance Direction

This direction should be considered successful when:

- the graph reads as a local route network centered on the start
- the board reads as a fixed discoverable world instead of a moving diagram
- hunger makes route commitment more legible
- family placement still meets the current stage guarantee floor
- layout no longer needs to rescue obviously bad graph choices
- assets/filler reinforce the world instead of compensating for route confusion

## Non-Goals

- This document does not approve broader free-roam graph generation.
- This document does not authorize save-shape changes.
- This document does not authorize flow-state changes.
- This document does not turn asset polish into gameplay truth.
- This document does not replace `MAP_CONTRACT.md`.

## Risks

- Over-correcting into a too-rigid tree could reduce replay texture and route flexibility.
- Under-correcting could keep the current spaghetti/over-connected feel.
- Family placement could regress if topology and placement are not revalidated together.
- Fixed-board placement could regress if playable-rect rules are vague.
- Asset polish could reopen scope if it starts before topology/layout/walker are actually green.
