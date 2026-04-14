# SIMPLE RPG - Scatter Map Generation Design

## Status

- This file is a design/reference document for a future scatter-based map generator.
- Authority remains `Docs/MAP_CONTRACT.md` for map structure and `Docs/SOURCE_OF_TRUTH.md` for runtime ownership.
- This file does not authorize save-shape, flow-state, or gameplay-owner changes by itself.

## Continuation Gate

- touched owner layer: `workflow/docs + map generation design`
- authority doc: `Docs/MAP_CONTRACT.md`
- impact: `runtime truth could be affected by later implementation`; `save shape is not required to change by the safest baseline below`; `asset provenance is out of scope`
- minimum validation set: `design-only review against MAP_CONTRACT.md and current save/ownership rules before implementation`

## Certain Current Baseline

These points are current repo facts, not proposals:

- The map contract requires bounded node-graph exploration centered on a local start anchor.
- The player starts from a center anchor node.
- Movement is adjacency-based and revisit is allowed.
- Hidden nodes remain runtime-undiscovered rather than using dedicated fog cards.
- The graph should read as local neighborhoods, not horizontal layers.
- Prototype portrait readability currently targets roughly `14` total nodes including the center start.
- Opening exploration should usually expose at least one reward opportunity, one support opportunity, and one meaningful adjacency choice.
- Each stage currently guarantees exactly one `start`, one `key`, one `boss`, one `event`, one `reward`, one `side_mission`, two support opportunities, and six non-boss combat opportunities.
- The boss remains locked until the stage key is resolved.
- `MapRuntimeState` is the current runtime owner of realized graph truth, node state, current node, key/boss-gate truth, support revisit truth, side-mission state, and pending node context.
- Current exact save restore depends on realized graph payload, not on re-running generation from seed alone.
- Current runtime generation is scaffold-based and template-backed, not fully free-form scatter generation.

## Problem Statement

The current bounded exploration identity is correct, but the topology source is still scaffold-first:

- the stage shape is authored through fixed scaffold families first
- graph variety is narrower than the intended local-neighborhood fantasy
- controlled reconnection between leaf-like routes is constrained by scaffold shape
- outer-band key/boss pacing is currently achieved through scaffold slot rules rather than a graph-native scatter policy

The next generator should preserve the current bounded exploration identity while replacing scaffold-first topology with center-start controlled scatter generation.

## Design Goals

The future generator should:

- keep `start` at the center
- use controlled scatter placement instead of visibly ring-locked or slot-locked placement
- keep the graph connected at all times
- produce a readable mix of degree-`1`, degree-`2`, and degree-`3` nodes
- allow some leaf-like routes to reconnect to each other
- keep `key` and `boss` near the outer band
- preserve early reward/support/meaningful route exposure
- preserve portrait readability and bounded-exploration identity
- keep gameplay truth in `MapRuntimeState`
- avoid widening save scope unless forced by implementation evidence

## Non-Goals

This design does not aim to:

- turn the stage into free-roam exploration
- make all nodes visible at once
- move board layout truth into UI or scene code
- require saved presentation coordinates
- authorize immediate runtime rewrites by itself

## Generation Algorithm Options

## Option A - Spatial Sample -> Connect -> Repair

Summary:

- sample node positions in bounded scatter space around the center
- build a provisional neighbor graph from spatial proximity
- keep a spanning backbone
- add limited extra edges
- repair degree/readability failures afterward

Strengths:

- produces the most organic scatter feel
- naturally supports some cross-links and non-ring silhouettes
- adapts well to presentation-driven scatter layouts later

Risks:

- harder to guarantee early reward/support exposure without a strong repair phase
- harder to keep degree mix stable on a compact portrait board
- more likely to create crossings, over-dense pockets, or over-connected centers
- validity repair can become large and fragile

Recommendation:

- viable, but not the safest first implementation

## Option B - Center-Start Frontier Growth With Controlled Scatter

Summary:

- reserve the center `start`
- build a small set of first-hop structural branches from the start
- grow outward branch by branch using degree budgets and spatial envelopes
- allow only a small number of late reconnection edges
- assign node families after topology roles are known

Strengths:

- easiest to guarantee connectedness
- easiest to preserve early exposure rules
- easiest to control node degrees and outer-band pacing
- closest fit to the current bounded-exploration contract
- simpler to validate and repair deterministically

Risks:

- can look too orderly if spatial jitter is weak
- needs explicit anti-ring tuning so the result does not read as neat shells

Recommendation:

- safest recommended algorithm

## Option C - Pocket Modules With Scatter Stitching

Summary:

- generate a few mini-pockets or branch modules
- place them in scatter space around the start
- stitch them together with controlled connectors

Strengths:

- good readability
- strong control over local route identity
- easy to author special-purpose opening pockets

Risks:

- drifts back toward scaffold thinking
- can hide mechanic drift inside module content if not kept disciplined
- less future-proof if the project wants broader procedural variation

Recommendation:

- acceptable fallback if full scatter growth proves unstable, but weaker than Option B for the stated goal

## Safest Recommended Algorithm

Recommended choice:

- `Option B - Center-Start Frontier Growth With Controlled Scatter`

Reason:

- it preserves the current contract with the smallest risk surface
- it keeps connectedness and early exposure under direct control
- it can produce controlled scatter without requiring free-form geometric repair to carry the whole design

## Recommended Generator Model

This section is proposal, not current runtime fact.

### Phase 1 - Reserve Structural Roles

Reserve node-role targets before family fill:

- `center_start`
- `opening_reward_lane`
- `opening_support_lane`
- `opening_progress_lane`
- `mid_progress_lane`
- `late_prep_lane`
- `late_event_lane`
- `late_side_mission_lane`
- `outer_key_candidate`
- `outer_boss_candidate`
- remaining `combat_fill` / `detour_fill` roles

This keeps quota and pacing control without forcing the visible result into a scaffold grid.

### Phase 2 - Controlled Scatter Placement

Generate node positions in normalized portrait-safe board space:

- `start` at exact center
- other nodes use overlapping radial bands, not hard rings
- each branch gets a sector bias, but nodes may drift inside overlapping envelopes
- later nodes may drift farther and wider than early nodes

Suggested working envelopes:

- early band radius: `0.18 - 0.34`
- mid band radius: `0.30 - 0.56`
- outer band radius: `0.52 - 0.82`

Suggested working drift:

- early angular drift: modest
- late angular drift: wider
- branch sectors may overlap slightly so the graph does not read as perfect spokes

These are generation envelopes only. They should not become a visible ring promise.

### Phase 3 - Connected Frontier Growth

Grow the graph from the center:

1. Create `3` first-hop nodes from `start`.
2. Mark those first-hop nodes as the opening exposure set.
3. Expand outward from a frontier queue with branch budgets.
4. Every new node must attach to at least one already-connected parent.
5. Only add a second connection if the degree budget, readability checks, and reconnection budget allow it.
6. Add a small number of late cross-links between outer or late-mid nodes.

This produces a graph that is connected by construction rather than fixed by emergency repair at the end.

### Phase 4 - Degree Repair

After growth:

- demote over-connected nodes
- add one extra late cross-link if the graph is too tree-like
- repair accidental dead-end clustering
- ensure the boss/key pocket is not over-connected

### Phase 5 - Family Fill

Assign node families after the topology is validated:

- special structural roles first
- guarantee-floor families second
- remaining nodes filled by combat/default detour rules

This keeps topology generation and family quota logic separated but compatible.

## Node Count / Degree / Branch Density Recommendations

These are recommendations, not current contract facts unless explicitly marked above.

### Initial Safe Node Count

- keep the current `14` total node baseline for the first scatter implementation
- that means `1` center `start` plus `13` enterable non-start nodes
- do not widen to larger graphs before readability is proven

### Degree Targets

Recommended non-start degree mix for a `14`-node stage:

- `3-4` nodes at degree `1`
- `6-8` nodes at degree `2`
- `2-3` nodes at degree `3`

Recommended special cases:

- `start`: degree `3`
- `boss`: degree `1` or `2`
- `key`: degree `2` preferred

Hard guardrails:

- no node above degree `3` in the first implementation
- no isolated nodes
- no non-boss route that collapses into a pure straight checklist unless the branch mix still preserves meaningful choice elsewhere

### Branch Density

Recommended baseline:

- start from a connected `13`-edge backbone
- add `2-3` extra edges for controlled reconnection
- target total edges: `15-16`

This yields:

- mostly degree-`2` traversal
- some leaf routes
- some cross-links
- bounded readability on portrait

### Reconnection Budget

Recommended initial reconnection policy:

- `1-2` late cross-links total
- prefer late-mid or outer-band connections
- allow some leaf-to-leaf or near-leaf reconnections when readability survives
- avoid giving the opening neighborhood too many loops

## Connectedness / Validity Rules

These are proposed implementation validity checks.

### Hard Validity Rules

- the graph must be fully connected
- every node must be reachable from `start`
- `start` must not be a leaf
- `boss` must remain locked until `key` resolves
- `key` must be reachable before the boss unlocks
- after `key` resolves, at least one viable path to `boss` must remain
- hidden-information rules from `MAP_CONTRACT.md` must remain intact
- the graph must not create infinite farm loops

### Readability Rules

- the opening neighborhood should usually surface `2-4` meaningful outward choices
- the center pocket should not be visually saturated by too many cross-links
- outer-band detours must not create unreadable edge spaghetti on portrait
- a reconnection edge is invalid if it destroys local route readability

### Structural Distribution Rules

- there should be at least one leaf-like route
- there should usually be at least one reconnection route
- not all leaves should be isolated dead rewards; some may connect laterally
- not every branch should end in a leaf; at least one branch should support deeper progression flow

## Key / Boss Placement Rules

These are proposed placement rules.

### Placement Baseline

- both `key` and `boss` should live in the outer band or near-outer band
- neither should appear in the opening neighborhood
- the boss pocket should usually be farther from `start` than the key pocket

### Distance Targets

Recommended targets:

- `start -> key`: usually `3-5` moves
- `key -> boss`: usually `1-3` moves after key access is secured
- allow at least one plausible short prep detour after key before the boss push

### Separation Rules

- `key` and `boss` should not usually occupy the same immediate pocket
- they should usually sit on distinct outer-side pockets or on the same late branch with at least one meaningful decision point between them
- if the boss is degree `1`, ensure the approach still feels intentional rather than accidental

### Outer-Band Candidate Rule

Recommended candidate selection:

- choose key/boss only from nodes that land in the highest radius/depth bucket
- prefer candidates with late access and stable readability
- reject candidates whose placement would make the boss effectively an early click

## Early Exposure Preservation

This section is proposal driven by current contract requirements.

Opening exposure should be designed intentionally, not left to random family fill.

Recommended opening rule:

- `start` reveals exactly `3` first-hop branches in the first implementation

Recommended opening branch roles:

- one branch exposes an early `reward` opportunity
- one branch exposes an early support opportunity
- one branch exposes meaningful progression pressure, usually `combat`

Allowed variation:

- the meaningful progression branch may reveal `event` or `side_mission` later, but the opening shell should still read as a real route choice rather than three cosmetic detours

This keeps the current early-run exposure floor explicit.

## Node Family Quota Integration Approach

Certain baseline from `MAP_CONTRACT.md`:

- the stage currently guarantees one `event`, one `reward`, one `side_mission`, two support opportunities, one `key`, one `boss`, and six non-boss combat opportunities
- current support-family rotation is stage-scoped

Recommended integration approach:

### Step 1 - Topology Before Family Fill

Generate topology first, but mark structural role labels such as:

- `opening_support_lane`
- `opening_reward_lane`
- `late_support_lane`
- `late_event_lane`
- `late_side_mission_lane`
- `outer_key_candidate`
- `outer_boss_candidate`

### Step 2 - Fill Guaranteed Families Into Compatible Roles

Fill in this order:

1. `start`
2. `key`
3. `boss`
4. opening `reward`
5. opening support lane
6. late support lane
7. `event`
8. `side_mission`
9. remaining `combat`

### Step 3 - Apply Support Rotation

Safest baseline:

- preserve the current stage-scoped support rotation unless a later authority pass changes it

### Step 4 - Repair By Swapping Roles, Not Rebuilding The Graph

If quotas do not fit cleanly:

- swap compatible roles within the same depth/readability class first
- avoid regenerating the full topology unless the stage fails hard validity

This reduces generator volatility and keeps save-safe realized graph construction simpler.

## Save Shape Impact

## Certain Current Save Baseline

- current exact restore depends on realized graph payload rather than re-running map generation from seed alone
- current map runtime truth already includes stable node ids, node families, node states, and adjacency

## Safest Proposed Save Conclusion

- no save schema shape change should be required for the first scatter implementation if realized graph payload remains authoritative
- the generator may change how the realized graph is created, but load should still trust saved realized graph truth

## Save-Sensitive Watchpoints

Implementation should stop and escalate if it requires:

- new saved node coordinate fields
- saved presentation-only scatter metadata
- reliance on seed-only regeneration for exact restore
- incompatible reinterpretation of existing map identity fields without migration policy

## Escalation Trigger

For this design-doc task itself:

- no escalation trigger is required; this patch is design-only

For later implementation:

- yes, escalate first if the chosen approach changes save shape, changes map owner meaning, introduces a new flow state, introduces a new command/event family, or requires scene/UI ownership of gameplay truth

Specific watchpoints:

- changing the meaning or compatibility contract of `active_map_template_id`
- moving graph truth out of `MapRuntimeState`
- saving scatter coordinates as authoritative runtime state
- requiring load reconstruction by rerunning generation instead of trusting realized graph save data

## Acceptance Criteria

Implementation should only be accepted if all of the following are true:

- `start` is centered and the map still reads as one bounded local neighborhood
- the graph is connected
- the graph contains a readable mix of degree-`1`, degree-`2`, and degree-`3` nodes
- some late or outer routes may reconnect without destroying readability
- `key` and `boss` sit near the outer band and preserve `explore -> prepare -> key -> boss push`
- the opening shell still exposes reward/support/meaningful route choice
- the graph still feels bounded and portrait-readable rather than free-roam
- hidden nodes remain hidden until discovery
- `MapRuntimeState` remains the gameplay truth owner
- save/load remains exact from realized graph truth without requiring presentation-state save growth
- no mechanic drift is hidden inside family placement or presentation changes

## Assumptions And Open Questions

These are proposals or unresolved questions, not confirmed facts:

- `14` total nodes is likely still the safest first scatter target; wider graphs may be possible later, but are not yet justified
- a degree cap of `3` is likely enough for readable bounded exploration on portrait
- `3` opening branches are likely the best fit for current readability and early exposure rules
- a deterministic frontier-growth generator is likely safer than proximity-graph generation for this project's current validation surface
- if the project later wants stronger biome/profile variation, a profile-driven scatter parameter set may be enough without returning to scaffold templates
