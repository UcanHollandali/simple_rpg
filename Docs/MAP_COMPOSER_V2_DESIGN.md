# SIMPLE RPG - Map Composer V2 Design

## Status

- This file is a design/reference document for map presentation v2.
- Authority remains `Docs/MAP_CONTRACT.md` for map structure and `Docs/SOURCE_OF_TRUTH.md` for runtime ownership.
- This file does not authorize save-shape, flow-state, or gameplay-owner changes by itself.

## Continuation Gate

- touched owner layer: `workflow/docs + map architecture design`
- authority doc: `Docs/MAP_CONTRACT.md`
- impact: `runtime truth could be affected if implementation leaks presentation state into runtime owners`; `save shape is not required by the baseline design below`; `asset provenance is out of scope here`
- minimum validation set: `design-only review against MAP_CONTRACT.md, SOURCE_OF_TRUTH.md, VISUAL_AUDIO_STYLE_GUIDE.md`

## Observed Current Baseline (Certain)

These points are based on the current repo state, not on proposal:

- `MapRuntimeState` currently owns stable node identity, node family, adjacency, node state, current node, pending node context, stage key state, boss-gate state, and support-node revisit state.
- `RunState` currently owns `run_seed` and named RNG stream cursors.
- Save validation currently requires `active_map_template_id` plus `map_realized_graph`.
- The realized graph currently stores `node_id`, `node_family`, `node_state`, and `adjacent_node_ids`.
- The current save payload does not store board coordinates, spline points, clearing masks, or decor placements.
- `scenes/map_explore.gd` currently renders only the adjacent reachable shell through six fixed slot positions plus a current-node marker.
- The current board roads are straight `Line2D` segments between the current marker and each visible adjacent marker.
- The current stage graph truth is scaffold-based and compact, with one start anchor and bounded portrait readability.
- Dedicated fog cards are currently suspended by contract; undiscovered nodes remain runtime-hidden instead.

## Problem Statement

The current board is readable, but it is visibly slot-driven:

- node placement is tied to a small fixed slot set instead of the actual graph shape
- path presentation is a straight line overlay instead of an authored-looking trail
- the board reads as UI chrome over a backdrop, not as a local forest pocket
- graph identity is stronger in runtime truth than in player-facing composition

Map Composer V2 should keep the existing gameplay truth and stage contract, but replace the board presentation with:

- graph-driven node placement
- path-mask-driven trail composition
- local clearing pockets around visible nodes
- canopy/decor fill around the playable pocket
- UI overlays anchored on top of the composed board rather than standing in for the board

## Design Goals

- Preserve `MAP_CONTRACT.md` bounded-exploration identity.
- Preserve portrait readability and the `2-3` meaningful outward-option target.
- Keep gameplay truth in `MapRuntimeState`, not in scenes or UI.
- Keep save-safe exact restore without introducing presentation-owned save truth for the baseline.
- Let `corridor`, `openfield`, and `loop` scaffolds feel different in presentation without changing their runtime guarantee floor.
- Match `VISUAL_AUDIO_STYLE_GUIDE.md` "Dark Forest Wayfinder" direction: readable before atmospheric, stylized before realistic.

## Runtime Owner Boundary

## Current Owner Rule (Certain)

- `MapRuntimeState` remains the authoritative owner of:
  - node ids
  - node families
  - adjacency
  - node states
  - current node
  - key/boss-gate state
  - pending node context
- `RunState` remains the authoritative owner of:
  - `run_seed`
  - named RNG stream cursors
- `RunSessionCoordinator` remains the movement-resolution and flow-routing owner.

## V2 Boundary Rule (Proposed)

- `Map Composer V2` should be a derived presentation surface, not a gameplay owner.
- Recommended ownership split:

| Artifact | Owner | Rule |
|---|---|---|
| graph truth | `MapRuntimeState` | unchanged |
| run seed | `RunState` | unchanged |
| layout signature / derived composition inputs | `Game/UI` presenter/composer layer | derived from authoritative state only |
| hover, selection, camera offset, walker tween, animation state | `scenes/` / `Game/UI` | presentation only |
| authored presentation hints, if later needed | `ContentDefinitions` | definition input, not runtime truth |

- V2 must not add fields such as `node_screen_position`, `path_curve_points`, `clearing_mask`, or `decor_seed` to `MapRuntimeState` for the baseline design.
- V2 must not save presentation-only state as authoritative run truth for the baseline design.
- V2 must not consume `RunState` named RNG cursors during board recomposition, because UI refresh frequency would mutate gameplay RNG continuity.

## Graph Truth vs Presentation Split

## Truth Inputs (Certain + Kept)

The composer should only read:

- `stage_index`
- `run_seed`
- `active_map_template_id`
- realized node list
- `node_id`
- `node_family`
- `node_state`
- `adjacent_node_ids`
- `current_node_id`
- `stage_key_resolved`

## Presentation Outputs (Proposed)

The composer may derive:

- node center positions in board space
- ring index / branch sector assignment
- spline control points for edges
- clearing masks
- pocket masks
- canopy fill masks
- decor placements
- overlay anchors
- hit-target anchors
- local board camera/focus offset

## Hard Separation Rule (Proposed)

- Graph truth answers `what exists` and `what is reachable`.
- Presentation answers `where it is drawn` and `how it is surfaced`.
- No gameplay logic may depend on:
  - overlay labels
  - icon texture paths
  - node plate visuals
  - road curve shape
  - canopy/decor presence

## Determinism Rule (Proposed)

- Composition must be deterministic from already-owned truth.
- Recommended board seed input:
  - `run_seed`
  - `stage_index`
  - `active_map_template_id`
  - a stable sorted realized-graph signature
- Recommended implementation approach:
  - hash the inputs into one read-only board seed
  - derive sub-seeds for `layout`, `path`, `clearing`, and `decor`
  - do not advance gameplay RNG streams while composing the board

This preserves save/load visual stability without changing save shape.

## Node Placement Rule

## Placement Principle (Proposed)

- The graph should be laid out from a center-start anchor, then read as radial/local neighborhoods rather than horizontal rows.
- The absolute composition should stay start-rooted.
- Camera/focus drift may follow the current node, but the underlying node positions should remain stable for the stage.

## Placement Steps (Proposed)

1. Treat node `0` / `start` as the stage origin in normalized board space.
2. Compute each node's ring depth from the start node using shortest-path distance.
3. Assign each node to an angular sector based on its first-hop ancestry from the start node.
4. For reconnection nodes, place them between the sectors of their contributing branches, then clamp to avoid line crossings.
5. Apply deterministic jitter inside each node's sector/ring envelope.
6. Resolve collisions by reducing jitter first, then nudging within-sector before allowing cross-sector drift.

## Ring Baseline (Proposed)

This is a proposed composition baseline, not a map-rule contract:

- ring `0`: `start`
- ring `1`: opening neighborhood
- ring `2`: mid-route pocket
- ring `3`: late-route pocket
- ring `4`: boss gate if the graph pushes it outward cleanly

## Controlled Random Rule (Proposed)

- Jitter should be deterministic, not session-random.
- Jitter should preserve:
  - minimum node-to-node spacing
  - portrait-safe outer margins
  - overlay hit target clearance
  - path readability
- Jitter amplitude should shrink on dense rings and near the boss pocket.

## Placement Readability Guardrail (Proposed)

- The visible pocket should still read as one local neighborhood.
- At normal portrait zoom, the player should usually judge `2-3` outward choices, not all unresolved nodes at once.
- Node overlays must not overlap each other or sit on top of the current-node walker lane.

## Path Generation Rule

## Path Model (Proposed)

- Every graph edge becomes a trail segment, not a straight UI line.
- The default trail geometry should use cubic Bezier segments sampled into a path polyline.
- Curve endpoints should begin at the edge of each node clearing, not at node-center icons.

## Bezier Rule (Proposed)

- Control points should be derived from:
  - start-to-end direction
  - ring tangent bias
  - sector bias
  - deterministic curvature sign for sibling/reconnection edges
- Control-point distance should scale from edge length, then clamp to avoid over-bending on short edges.
- Reconnection edges should bias outward first, then return inward, so the path reads as a trail detour rather than a UI chord.

## Visibility Rule (Proposed)

- `discovered` and `resolved` nodes may reveal their connecting trail inside the visible pocket.
- `locked` boss approaches may show the visible locked approach if the boss node is already discovered.
- `undiscovered` deeper edges must stay hidden under canopy / non-readable fill.
- V2 must not reintroduce dedicated fog cards or readable hidden-node labels.

## Trail Rendering Layers (Proposed)

- trail base / soil mask
- inner guide highlight
- optional resolved/locked tint treatment
- optional light debris decal pass on open sections only

## Clearing / Pocket Rule

## Clearing Principle (Proposed)

- The player should read an open ground pocket cut into the forest, not isolated icons floating over a board.
- Each visible node owns a local clearing.
- Visible trail segments connect those clearings into one readable exploration pocket.

## Clearing Size Rule (Proposed)

- `start`: largest standard clearing
- `boss`: large clearing with stronger rim silhouette
- `reward`, `rest`, `merchant`, `blacksmith`, `key`: medium-large clearing
- `combat`, `event`: medium clearing
- `resolved` nodes keep the clearing but lose most of the visual emphasis

## Pocket Union Rule (Proposed)

- The player-facing pocket is the union of:
  - current node clearing
  - discovered adjacent node clearings
  - any discovered non-adjacent clearing that still falls inside the focus window
  - the visible trail masks connecting them

## Hidden Node Rule (Proposed)

- `undiscovered` nodes do not cut readable clearings into the canopy.
- Their family and exact value must remain unreadable.
- A hidden node may only be implied by absent forest mass after discovery, never by a pre-reveal icon or named plate.

## Forest / Decor Fill Rule

## Fill Principle (Proposed)

- Forest fill is an atmosphere layer around the graph pocket.
- It is not a second gameplay map.
- It must improve local-neighborhood readability, not fight it.

## Fill Layers (Proposed)

- far forest floor tone under the pocket
- canopy fill mass around undiscovered space
- midground forest props near pocket borders
- thin foreground branch/leaf accents only where they do not block overlays

## Decor Placement Rule (Proposed)

- Decor placement should use deterministic sub-seeds from the board seed.
- Decor must respect exclusion zones around:
  - node overlays
  - hit targets
  - current-node walker lane
  - trail centerlines
  - top-right key/read panels
- Decor density should vary by scaffold identity:
  - `corridor`: denser edge canopy, stronger tunnel feel, straighter visual guidance
  - `openfield`: wider negative space, broader clearings, lighter canopy compression
  - `loop`: more circular root/log framing, more visible reconnecting negative space

## Style Rule (Proposed)

- Use the `Dark Forest Wayfinder` palette and silhouette logic from `VISUAL_AUDIO_STYLE_GUIDE.md`.
- The board should feel like a way through forest mass, not a clean tactical diagram.
- Readability still wins over atmosphere.

## Node UI Overlay Rule

## Overlay Principle (Proposed)

- The node overlay is a UI layer on top of the composed board.
- It is not the board itself.

## Overlay Contents (Proposed)

- family icon
- state indicator
- selection/highlight ring
- hit target
- optional short label chip on focus/hover only

## Overlay Rules (Proposed)

- Overlays anchor to clearing centers, not arbitrary slot positions.
- Hit targets may remain larger than the visible icon plate.
- Family readability should come from icon + color + state treatment, not always-on text.
- Resolved nodes remain traversable where graph truth allows it, but the overlay should read as spent/muted.

## Asset Families

See `Docs/MAP_COMPOSER_V2_ASSET_REQUIREMENTS.md` for the production-facing asset breakdown.

## Migration Strategy

## Phase 0 - Freeze Truth Boundary

- Keep `MapRuntimeState` as the only map gameplay owner.
- Keep save schema and flow state unchanged for the baseline.
- Add an explicit rule that board composition must be derived from saved truth, not saved separately.

## Phase 1 - Introduce Read-Only Composer

- Build a `Map Composer V2` read-only composition pass that accepts graph truth and outputs a board composition object.
- Keep the current scene interaction model and current button-driven movement commands.
- Use deterministic seed derivation from existing truth only.

## Phase 2 - Replace Slot Placement

- Replace the six fixed route-slot positions with composer-driven overlay anchors.
- Keep current family icons and hit targets for parity first.
- Preserve current current-node marker and walker behavior until composition parity is proven.

## Phase 3 - Replace Straight Roads With Trail Masks

- Swap straight `Line2D` roads for spline-derived trail paths.
- Introduce clearings and pocket union logic.
- Verify that hidden nodes remain hidden and that boss-lock readability still works.

## Phase 4 - Add Canopy / Decor Fill

- Add canopy fill, trail-edge breakup, and forest props.
- Tune per-scaffold presentation profiles for `corridor`, `openfield`, and `loop`.
- Keep overlay clarity and hit target safety ahead of atmosphere.

## Phase 5 - Retire Slot Scaffolding

- Remove the fixed slot constants and slot-first route layout once parity and fallback confidence are complete.
- Keep a temporary fallback path only until v2 acceptance criteria are met.

## Save / Flow / Ownership Impact

## Baseline Conclusion (Proposed, With Current-Evidence Support)

- Flow-state change is not required for Map Composer V2 baseline.
- Save-shape change is not required for Map Composer V2 baseline if composition remains deterministic from existing saved truth.
- Gameplay truth ownership change is not required for Map Composer V2 baseline if all composition output stays derived and presentation-only.

## Explicit Escalation Triggers

Escalate before implementation if any chosen implementation requires:

- storing board coordinates in save data
- storing spline/control-point payload in save data
- storing presentation-driven discovery or concealment state outside current node-state truth
- consuming gameplay RNG cursors to redraw the board
- moving map truth into `RunState`, `AppBootstrap`, the scene, or a presenter
- introducing a new flow state for map presentation

## Acceptance Criteria

- The board visually reads as a forest pocket built from the realized graph, not from six fixed slots.
- The player-facing board still preserves the compact portrait neighborhood identity from `MAP_CONTRACT.md`.
- `MapRuntimeState` remains the authoritative owner of graph truth.
- The scene and UI layers only consume derived composition output plus authoritative runtime truth.
- Hidden nodes remain hidden and unreadable until discovery.
- Locked boss access remains visibly locked without exposing forbidden deeper-node information.
- Resolved nodes remain visibly spent but traversable where the graph allows it.
- Save/load of the same run reproduces the same board composition without adding presentation fields to the save payload.
- `corridor`, `openfield`, and `loop` feel visually distinct through composition and decor, not through hidden mechanic drift.
- Overlay hit targets remain mobile-readable and do not collapse below current practical tap safety.
- The board still surfaces current node, reachable options, key progress, and boss push readiness clearly.

## Risks

- Collision risk: compact portrait space may cause node overlays, trail bends, and decor to compete for the same space.
- Readability risk: a too-atmospheric canopy layer could reintroduce hidden-information confusion or make adjacency unclear.
- Save-drift risk: if implementation stores presentation state, it widens save scope unnecessarily.
- RNG risk: if board composition advances gameplay RNG streams, reward/combat determinism could drift.
- Hidden-info risk: poorly tuned path masks could leak undiscovered node topology.
- Input risk: organic shapes can make hit zones feel misaligned if the visible overlay and click target diverge too far.
- Asset-load risk: canopy/trail/decor families add production cost compared with the current mostly procedural shell.
- Performance risk: too many layered masks, props, or animated overlays may be expensive on mobile portrait targets.
- Test-surface risk: deterministic visual composition needs stable assertions around layout rules, not brittle pixel-exact tests.
- Migration risk: if slot scaffolding is removed before parity, movement/readability regressions could be harder to isolate.

## Assumptions And Open Questions

These are design assumptions, not confirmed repo facts:

- A deterministic hashed board seed will be sufficient; no extra saved layout seed should be needed.
- Existing graph sizes can be represented cleanly with start-rooted radial placement plus a modest camera/focus drift.
- Current icon family can remain the overlay identity layer while new environmental assets carry most of the visual upgrade.
- A future optional `MapPresentationTemplates` content family could exist if art-directed placement hints become necessary, but it is not required for the baseline design.
