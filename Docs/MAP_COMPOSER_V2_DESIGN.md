# SIMPLE RPG - Map Composer V2 Design

## Status

- This file is a design/reference document for map presentation v2.
- This file is a reference presentation companion for the center-outward fixed-board map direction family.
- This file currently reflects the stronger fixed-board target:
  - road network first
  - landmark pockets second
  - full board usage
  - small-world traversal feel
  - candidate asset spike only after structure is green
- Authority remains `Docs/MAP_CONTRACT.md` for map structure and `Docs/SOURCE_OF_TRUTH.md` for runtime ownership.
- This file does not authorize save-shape, flow-state, or gameplay-owner changes by itself.
- This file is not a queue surface.

## Continuation Gate

- touched owner layer: `workflow/docs + map architecture design`
- authority doc: `Docs/MAP_CONTRACT.md`
- impact: `runtime truth could be affected if implementation leaks presentation state into runtime owners`; `save shape is not required by the baseline design below`; `asset provenance is out of scope here`
- minimum validation set: `design-only review against MAP_CONTRACT.md, SOURCE_OF_TRUTH.md, VISUAL_AUDIO_STYLE_GUIDE.md`

## Archived Visual Source Set (Certain)

The archived visual-rule sync used checked-in repo captures as the visual evidence set.
The earlier audit fallback was not needed because a checked-in reference set exists.
No extra user-provided reference images were used in the current chat beyond repo state.

Exact checked-in captures reviewed for this sync:

- `export/portrait_review/map_explore_1080x1920.png`
- `export/portrait_review/prompt42_full_board_footprint_20260423/after/seed11_late_1080x1920.png`
- `export/portrait_review/prompt42_full_board_footprint_20260423/after/seed29_late_1080x1920.png`
- `export/portrait_review/prompt42_full_board_footprint_20260423/after/seed41_late_1080x1920.png`
- `export/portrait_review/prompt20_board_path_hierarchy_20260423/after/map_explore_1080x1920.png`
- `export/portrait_review/prompt20_board_path_hierarchy_20260423/after/seed11_late_1080x1920.png`
- `export/portrait_review/prompt20_ground_filler_restraint_20260423/after/map_explore_1080x1920.png`
- `export/portrait_review/prompt40_final_reaudit_20260423/map_explore_1080x1920.png`

## Observed Current Baseline (Certain)

These points are based on the current repo state, not on proposal:

- `MapRuntimeState` currently owns stable node identity, node family, adjacency, node state, current node, pending node context, stage key state, boss-gate state, and support-node revisit state.
- `RunState` currently owns `run_seed` and named RNG stream cursors.
- Save validation currently requires `active_map_template_id` plus `map_realized_graph`.
- The realized graph currently stores `node_id`, `node_family`, `node_state`, and `adjacent_node_ids`.
- The current save payload does not store board coordinates, spline points, clearing masks, or decor placements.
- `MapBoardComposerV2` currently derives world positions, visible edge trails, forest shapes, and focus offset from runtime graph truth plus board seed.
- The current graph-stable board cache now preserves `world_positions`, frozen `layout_edges`, and `forest_shapes` when the realized graph signature stays unchanged.
- The current visible-node and visible-edge read is now filtered from that frozen full-layout cache instead of regenerating edge geometry from the currently visible subset.
- `MapRouteBinding` currently carries `_route_layout_offset` and uses `MapFocusHelper` plus `MapRouteMotionHelper.route_camera_follow_progress()` to translate the board during traversal.
- `scenes/map_explore.gd` still mirrors parts of that focus/recenter chain and keeps an emergency slot fallback path for missing composer positions.
- The current stage graph truth is controlled-scatter and compact, with one start anchor and bounded portrait readability.

## Problem Statement

The current board is graph-native, but the remaining presentation problem is not just polish:

- the board still has a live moving-board/focus-drift chain
- route travel can therefore read like the world slides under the walker
- playable bounds are improved heuristically, but the fixed-board envelope is not yet the explicit target contract
- world fill and asset layers are now structurally separated, but they still need a stable board model underneath them
- roads still do not reliably read before node discs, atmosphere, and overlay chrome
- node identity still reads too much like icon plates sitting on abstract clearings instead of landmark-owned pockets
- the lower half of the board too often collapses into beam/void/support mass instead of carrying meaningful route structure
- adjacent UI still risks framing the map as `board inside dashboard` instead of one small world with supporting UI

Map Composer V2 should keep the existing gameplay truth and stage contract while moving to a clearer target:

- fixed board
- fixed camera
- walker moving inside the board
- playable rect + safe margins
- world fill that follows structure instead of rescuing it

## Target Model Summary

- Presentation should serve a `fixed-board diorama`, not a moving-board follow chain.
- The walker should move on the board while the board and camera stay still by default.
- Layout/path/world-fill should follow runtime graph truth; they must not become a second gameplay map.
- Filler/decor metadata remains non-routing support around the traversal pocket.
- Visual variation should come from deterministic composition, placement, and asset/filler dressing rather than from camera drift.

## Design Goals

- Preserve `MAP_CONTRACT.md` bounded-exploration identity.
- Preserve portrait readability and the `2-4` meaningful outward-option target.
- Keep gameplay truth in `MapRuntimeState`, not in scenes or UI.
- Keep save-safe exact restore without introducing presentation-owned save truth for the baseline.
- Reveal should change visibility, not layout.
- Retire moving-board follow as the desired end state.
- Make road hierarchy the first-read structure.
- Make landmark pockets the primary node identity surface rather than icon discs alone.
- Use the full portrait board, including the lower half, as intentional structural space.
- Keep UI/overlay support from breaking the diorama illusion.
- Keep all node/path rendering inside a stable board envelope.
- Match `VISUAL_AUDIO_STYLE_GUIDE.md` `Dark Forest Wayfinder` direction: readable before atmospheric, stylized before realistic.

## Fixed-Board Visual System Rules

These rules translate the checked-in visual evidence into implementation-ready direction.
They are design rules for later prompts, not runtime-owner changes.

### 1. Road-First Readability

- Primary playable roads must read before node discs, atmosphere halos, and decorative filler.
- A player should be able to trace the currently meaningful branch structure without needing icon-family recognition first.
- History/reconnect lanes must remain visibly subordinate to active/decision-shaping roads through lower contrast, thinner presence, or calmer texture treatment.
- Road segments should begin and end at pocket / clearing edges, not visually at node-center icon discs.
- Roads must help carve pocket silhouettes; they must not feel like independent strokes laid across a separate abstract board.

### 2. Landmark Pocket Identity

- Each discovered node should own a local landmark pocket whose silhouette is larger and more memorable than the icon badge on top of it.
- The icon/plate layer should confirm node family and state; it should not be the primary identity carrier.
- Different high-value node families should be distinguishable by pocket character, anchor shape, local clearing behavior, or road arrival pattern before the icon is read closely.
- Roads should bend around or into pockets in ways that make the pocket feel authored by structure rather than stamped after the fact.

### 3. Full-Board Usage

- Composition should use the upper, middle, and lower board zones as intentional traversal space instead of clustering almost all semantic mass near one central island.
- Outer-frame nodes must feel connected by pocket-owning roads, not like isolated circles placed against empty backdrop.
- A layout is weak when the board footprint grows but the readable neighborhood still collapses into one overloaded central patch.
- Full-board usage does not mean filling every corner; it means that the occupied zones together read as one small world rather than one island floating in a frame.

### 4. Meaningful Negative Space

- Empty space should separate corridors and pockets on purpose; it should not read as leftover void.
- Negative space should make route choice legible by isolating branch groups and reducing visual collisions.
- Canopy, ground, and filler mass should recede around active roads and pocket clearings instead of flattening them into one continuous dark field.
- Large atmosphere shapes may support the composition, but they must not become the main semantic read.

### 5. Lower-Half Utilization

- The lower half of the board must participate in the neighborhood read, not act mainly as decorative spill, spotlight beam, or dead air.
- Across representative seeds, lower-half occupancy should carry either an active route continuation, a destination pocket, or a structural counterweight that keeps the board from top-loading.
- With the walker starting from a center-local pocket by default, the surrounding route read should not leave any cardinal side semantically vacant while the meaningful structure clusters in one direction.

### 6. UI Non-Interference

- HUD, side chips, and bottom inventory surfaces must behave like support rails around the world, not a second primary panel competing with it.
- Top and bottom UI create hard readability budgets; board composition should not rely on important pockets or tight road turns living directly underneath those slabs.
- Side overlays such as quest affordances must not obscure major roads, active destinations, or pocket silhouettes.
- The board should remain readable without always-on text labels on nodes; overlay chrome should support the illusion, not explain it away.

### 7. Structure Before Asset Lift

- Candidate assets may strengthen an already-correct structural read, but they must not be used to fake road hierarchy, pocket identity, or full-board usage.
- The rule target is procedural feel, not hand-authored pixel matching against one screenshot.
- If structure still reads as icon discs over abstract atmosphere, asset work is not yet the corrective lane.

## Hidden Sector Grammar Companion

- Authority for the hidden-sector grammar stays in `Docs/MAP_CONTRACT.md`.
- This section exists only to explain how that grammar should be interpreted by later layout/router work.
- The hidden sectors are not a visible `3x3` UI grid.
- The sectors should behave like irregular influence fields clipped by the playable rect, not like equal-sized rendered cells.
- `center_anchor` is the canonical opening-anchor sector in the unrotated grammar and the default start identity:
  - it should read as a center-local opening pocket, not an exact pixel-center stamp
  - the active orientation profile varies outward emphasis and route silhouette
  - lower-entry/upward exploration is not the default target
- Sector names are planning labels for implementation only:
  - not player text
  - not map-node family labels
  - not save payload by default

Implementation-facing interpretation:

- Each sector should expose a small local anchor budget, not one mandatory center point.
- Those local anchors should be asymmetrical within the sector so later placement can avoid visible centroid stacking.
- The later layout pass should pick from sector-local anchor candidates, then apply pocket-aware jitter and corridor-aware adjustment.
- A correct result should let the player feel one coherent small world without ever seeing the sector scaffold.
- A wrong result is easy to recognize:
  - nodes sit on invisible cell centers
  - left/right or upper/lower symmetry becomes obvious
  - the board reads like a checkerboard with icons on top

Corridor interpretation:

- canonical `north_center` is one major outward handoff sector, not the permanent primary spine.
- `mid_left` and `mid_right` are branch-body sectors, not decorative side gutters.
- canonical `south_*` sectors exist to support south-side route identity and counterweight structure, not to force a literal bottom row in every seed.
- Optional outer-late sectors are explicit pressure extensions for key/boss/final-prep staging only.
- Reconnects should stay local to neighboring sectors so the hidden grammar strengthens route identity instead of producing long-span rescue arcs.

Baseline harness relationship:

- The current pre-sector baseline tests that talk about `cardinal sectors` are only coarse footprint readbacks.
- They are useful before the hidden-sector implementation lands, but they are not the final sector contract.
- The structural metrics contract in `Docs/MAP_CONTRACT.md` now defines the later runtime/layout/router/pocket checks more directly.

## Runtime Owner Boundary

### Current Owner Rule (Certain)

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

### V2 Boundary Rule (Proposed)

- `Map Composer V2` should be a derived presentation surface, not a gameplay owner.
- Recommended ownership split:

| Artifact | Owner | Rule |
|---|---|---|
| graph truth | `MapRuntimeState` | unchanged |
| run seed | `RunState` | unchanged |
| layout signature / derived composition inputs | `Game/UI` presenter/composer layer | derived from authoritative state only |
| hover, selection, walker tween, animation state | `scenes/` / `Game/UI` | presentation only |
| authored presentation hints, if later needed | `ContentDefinitions` | definition input, not runtime truth |

- V2 must not add fields such as `node_screen_position`, `path_curve_points`, `clearing_mask`, or `decor_seed` to `MapRuntimeState` for the baseline design.
- V2 must not save presentation-only state as authoritative run truth for the baseline design.
- V2 must not consume `RunState` named RNG cursors during board recomposition, because UI refresh frequency would mutate gameplay RNG continuity.

## Graph Truth vs Presentation Split

### Truth Inputs (Certain + Kept)

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

### Presentation Outputs (Proposed)

The composer may derive:

- node center positions in board space
- depth-band / branch-group metadata
- spline control points for edges
- clearing masks
- pocket masks
- canopy fill masks
- decor placements
- overlay anchors
- hit-target anchors
- walker path samples

### Hard Separation Rule (Proposed)

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

## Current Baseline To Retire

These are current repo facts, not the desired end state:

- `_route_layout_offset` currently translates the board during traversal.
- `MapFocusHelper.desired_focus_offset()` currently computes a follow/recenter offset from world position plus visible-content context.
- `MapFocusHelper.clamp_focus_offset_to_visible_bounds()` currently keeps translated content inside the route frame.
- `MapRouteMotionHelper.route_camera_follow_progress()` currently delays camera follow during route movement.

The reopened wave may keep a narrow emergency fallback for exceptional cases, but the desired model is no longer `moving board with follow compensation`.

## Desired Board Model

- fixed board
- fixed camera
- walker moves on the board
- discovery changes visibility/readability, not board translation
- node/path/world-fill composition stays inside a defined playable rect

## Frozen Layout Rule

### Full Layout Snapshot (Current Baseline + Kept)

- For a stable realized-graph signature, the board should keep one frozen derived layout snapshot.
- The frozen snapshot currently includes:
  - all node world positions
  - full edge/path geometry (`layout_edges`)
  - forest-pocket shape output
- Clearing anchors and decor/filler anchors may remain derived presentation data, but they should follow the same rule: graph-stable layout artifacts do not get regenerated from the visible subset alone.

### Visibility Filter Rule (Proposed)

- Discovery should widen or narrow the visible subset only.
- `visible_nodes` should be filtered from the frozen node layout.
- `visible_edges` should be filtered from the frozen full edge geometry.
- Visibility changes must not generate new control points, new trail families, or new alternate path shapes for already-frozen graph edges.
- If implementation pressure requires saving layout payload or moving owner meaning, stop and escalate first instead of widening the baseline.

## Render Model Payload

Status after the closed map wave:

- `MapBoardComposerV2` emits a nested UI-only `render_model` payload with `schema_version = 1`.
- The payload is derived from existing composition truth; it does not add gameplay state, save state, flow state, asset provenance, assets, or canvas ownership.
- `render_model.path_surfaces` wraps currently visible corridor geometry with role, endpoint, width, cardinal, outward-route hint, and throat metadata.
- `render_model.junctions` wraps visible node junction/blend points for local choices and branch throats.
- `render_model.clearing_surfaces` wraps visible clearing discs and their road endpoint links.
- `render_model.canopy_masks` wraps canopy-source `forest_shapes` as road/clearing framing metadata with cardinal and outward-route relationship metadata.
- `render_model.landmark_slots` wraps visible node landmark footprints as asset-ready socket metadata with family, role, anchor point, rotation, scale, cardinal, and outward-route relationship fields.
- `render_model.decor_slots` wraps filler/decor source shapes as metadata-only socket anchors with route/clearing relation, cardinal side, outward-route hint, rotation, and scale fields.
- `MapBoardCanvas` uses `render_model.path_surfaces`, `render_model.junctions`, and `render_model.clearing_surfaces` as the default road/junction/clearing presentation lane when those fields are present.
- Legacy road strokes/decals and node-plate/decal candidate hooks are retired; `visible_edges` remains fallback data for continuity/motion, not a canvas default lane.
- The old visual wrapper blob/stamp layer is retired from default canvas drawing; `ground_shapes`, `filler_shapes`, `forest_shapes`, landmark pocket underlays, procedural landmark identity silhouettes, and prototype/candidate socket dressing remain metadata or explicit debug/prototype surfaces only.
- `ui_map_board_backdrop.svg` is a plain framed board shell; non-routing oval/blob atmosphere marks were removed from the runtime asset and source master.
- `MapRouteBinding` refreshes `render_model` after visible-edge continuity fallback so canvas reads the final presentation geometry.

Default render-model canvas draw order:

1. plain board background
2. `render_model.path_surfaces` as filled walkable surface polygons
3. render-model-derived road/pocket throat blends
4. `render_model.junctions` as local blend points
5. render-model path-surface highlight pass for selected/preview/current emphasis
6. `render_model.clearing_surfaces`
7. centered known-node icon overlays

This keeps roads above the plain board background, lets junctions blend route throats before clearings cap the endpoints, and keeps default node identity on clearings instead of letting large prototype footprint shapes dominate the board. Landmark pocket underlays, procedural landmark identity silhouettes, art-pilot candidate dressing, and socket-smoke placeholders are explicit debug/prototype surfaces only; they do not prove final art quality.

Legacy field status after the closed map wave:

| Legacy field | Status | Meaning after render-model canvas adoption |
|---|---|---|
| `layout_edges` | `fallback` | Frozen full-layout path geometry and continuity source; not a canvas default lane. |
| `visible_edges` | `fallback` | Legacy road geometry and motion/fallback source; not the default canvas road lane when render-model surfaces exist. |
| `ground_shapes` | `wrapper` | Metadata-only terrain-mask payload; no longer drawn by default canvas. |
| `filler_shapes` | `wrapper` | Metadata-only source for `render_model.decor_slots`; no runtime texture hook and no default canvas stamp layer. |
| `forest_shapes` | `wrapper` | Metadata-only source for `render_model.canopy_masks` / `render_model.decor_slots`; no runtime texture hook and no default canvas canopy/decor layer. |

## Playable Rect Rule

### Placement Principle (Proposed)

- The board should use a defined playable rect / generation envelope.
- The start should remain a readable center-local anchor inside that envelope by default.
- Node placement should happen inside safe bounds instead of relying on late follow/recenter rescue.

### Safe-Bounds Coverage (Proposed)

The playable rect must leave room for:

- node radius
- path stroke width
- walker sprite footprint
- overlay hit targets
- local clearing silhouettes

### Placement Steps (Proposed)

1. Define the playable board envelope.
2. Place the start anchor in the center-local safe opening zone.
3. Choose the active center-outward emphasis profile, then fit branches/pockets into the board envelope with deterministic jitter.
4. Resolve collisions inside local corridors before any broad displacement.
5. Reject placements that would require moving-board follow to stay readable.

## Path Generation Rule

### Path Model (Proposed)

- Every graph edge becomes a trail segment, not a straight UI line.
- The default trail geometry should use cubic Bezier segments sampled into a path polyline.
- Curve endpoints should begin at the edge of each node clearing, not at node-center icons.

### Path Acceptance Rule (Proposed)

- Paths must read as fixed routes on the board.
- Path continuity should survive discovery filtering.
- Path generation should not depend on camera drift or board follow.

## Walker Rule

### Walker Principle (Proposed)

- The walker should move through composed board space.
- The board should stay still while the walker advances.
- Motion polish should come from stride/tween/path sampling, not from moving the world under the walker.

## Clearing / Pocket Rule

### Clearing Principle (Proposed)

- The player should read an open ground pocket cut into the forest, not isolated icons floating over a board.
- Each visible node owns a local clearing.
- Visible trail segments connect those clearings into one readable exploration pocket.

### Hidden Node Rule (Proposed)

- `undiscovered` nodes do not cut readable clearings into the canopy.
- Their family and exact value must remain unreadable.
- A hidden node may only be implied by absent forest mass after discovery, never by a pre-reveal icon or named plate.

## Forest / Decor / Filler Rule

### Fill Principle (Proposed)

- Ground/forest/ruin/canopy wrapper payload is metadata around the graph pocket after the closed map wave.
- It should derive masks and future socket placement; it is not a visible default canvas layer.
- It is not a second gameplay map.
- Any future visible fill must improve local-neighborhood readability with screenshot evidence, not fight it.

### Non-Routing Rule (Proposed)

- filler metadata may seed future atmosphere/dressing sockets
- node/path graph remains routing truth

This rule also applies to any later asset hook:

- no decor placement may become traversal truth
- no filler mask may imply extra reachable space

## Node UI Overlay Rule

### Overlay Principle (Proposed)

- The node overlay is a UI layer on top of the composed board.
- It is not the board itself.

### Overlay Rules (Proposed)

- Overlays anchor to clearing centers, not arbitrary slot positions.
- Hit targets may remain larger than the visible icon plate.
- Family readability should come from icon + color + state treatment, not always-on text.
- Resolved nodes remain traversable where graph truth allows it, but the overlay should read as spent/muted.

## Migration Strategy

### Phase 0 - Current Baseline Audit

- Identify the live moving-board chain and the exact fallback surfaces that still depend on it.
- Keep `MapRuntimeState` as the only map gameplay owner.
- Keep save schema and flow state unchanged for the baseline.

### Phase 1 - Fixed Board Reset

- Retire moving-board follow as the desired default.
- Keep the walker lane, but ground it on a fixed board.
- Keep composition deterministic from existing truth only.

### Phase 2 - Playable Rect And Safe Bounds

- Make board-envelope rules explicit.
- Keep node/path placement inside safe margins.
- Prefer bounded generation/placement over late clamp-only rescue.

### Phase 3 - Layout / Path / Walker Convergence

- Tune placement and paths for fixed-board readability.
- Verify that hidden nodes remain hidden and that boss-lock readability still works.
- Keep walker motion local to the board.

### Phase 4 - World Fill Convergence

- Add or tune canopy fill, trail-edge breakup, and world-fill masks after structure is stable.
- Keep overlay clarity and hit target safety ahead of atmosphere.

### Phase 5 - Asset Hookup And Final Audit

- Hook map-only assets only after structure is green.
- End with a narrow audit/patch pass instead of silently widening the feature lane.

## Save / Flow / Ownership Impact

### Baseline Conclusion (Proposed, With Current-Evidence Support)

- Flow-state change is not required for Map Composer V2 baseline.
- Save-shape change is not required for Map Composer V2 baseline if composition remains deterministic from existing saved truth.
- Gameplay truth ownership change is not required for Map Composer V2 baseline if all composition output stays derived and presentation-only.

### Explicit Escalation Triggers

Escalate before implementation if any chosen implementation requires:

- storing board coordinates in save data
- storing spline/control-point payload in save data
- storing presentation-driven discovery or concealment state outside current node-state truth
- consuming gameplay RNG cursors to redraw the board
- moving map truth into `RunState`, `AppBootstrap`, the scene, or a presenter
- introducing a new flow state for map presentation

## Acceptance Criteria

- The board visually reads as a fixed forest pocket built from the realized graph.
- Roads read first as the player-facing structure of the neighborhood.
- Landmark pockets read second as the primary node-identity surface.
- The player-facing board still preserves the compact portrait neighborhood identity from `MAP_CONTRACT.md`.
- The occupied structure uses the portrait board intentionally, including the lower half, instead of collapsing into one top/mid island.
- `MapRuntimeState` remains the authoritative owner of graph truth.
- The scene and UI layers only consume derived composition output plus authoritative runtime truth.
- Hidden nodes remain hidden and unreadable until discovery.
- Locked boss access remains visibly locked without exposing forbidden deeper-node information.
- Resolved nodes remain visibly spent but traversable where the graph allows it.
- Save/load of the same run reproduces the same board composition without adding presentation fields to the save payload.
- World fill stays non-routing.
- Overlay hit targets remain mobile-readable and do not collapse below current practical tap safety.
- Map-adjacent UI supports the diorama read instead of reframing the scene as a dashboard with a decorative board inset.
- The board still surfaces current node, reachable options, key progress, and boss push readiness clearly.

## Risks

- Collision risk: compact portrait space may cause node overlays, trail bends, walker lanes, and decor to compete for the same space.
- Readability risk: a too-atmospheric canopy layer could reintroduce hidden-information confusion or make adjacency unclear.
- Save-drift risk: if implementation stores presentation state, it widens save scope unnecessarily.
- RNG risk: if board composition advances gameplay RNG streams, reward/combat determinism could drift.
- Hidden-info risk: poorly tuned path masks could leak undiscovered node topology.
- Input risk: organic shapes can make hit zones feel misaligned if the visible overlay and click target diverge too far.
- Asset-load risk: canopy/trail/decor families add production cost compared with the current mostly procedural shell.
- Performance risk: too many layered masks, props, or animated overlays may be expensive on mobile portrait targets.
