# SIMPLE RPG - Map Contract

## Purpose

This file defines the minimum map topology, traversal, and viability contract for prototype and early implementation work.

## Map Spine

- Each stage uses a bounded node graph centered on local exploration.
- The default map identity starts the player from one center-local opening anchor.
- The opening anchor may jitter inside a safe center-local pocket, but the active target is not an edge-entry ladder.
- Routes should open toward readable north/south/east/west board directions so the player feels they are exploring outward from a small-world center.
- Stage visibility uses partial undiscovered information; the player explores from local revealed information rather than full-route certainty.
- Board presentation may pre-compose a full derived stage layout at stage start, but discovery should only change visibility/readability, not graph truth or traversal semantics.
- Dedicated fog presentation on the board is currently suspended; hidden nodes stay runtime-undiscovered without separate fog cards or fog labels.
- Movement is adjacency-based between neighboring reachable nodes.
- Revisit is allowed inside a stage.
- Movement consumes hunger.
- The map must not create infinite farm loops.

## Derived Presentation Boundary

- Board composition, road rendering, pocket/clearing masks, overlay anchors, and walker path presentation remain derived readability layers over the runtime graph.
- Those presentation layers may evolve or be replaced side-by-side during implementation work, but they do not become a second gameplay map.
- During such replacement work, old and new presentation lanes may coexist temporarily as presentation surfaces only; this does not transfer node, adjacency, discovery, current-node, pending-node, or key/boss truth out of the current runtime owners.
- Discovery may change what becomes readable on the board, but it must not change graph truth, traversal semantics, or save ownership just because the board surface changes.
- If a presentation implementation would require new save fields, a new flow state, a pending-node owner move, or behavior-changing removal of a live compatibility fallback, stop and `escalate first`.

## Node Families

Current runtime-backed prototype node families:
- `start`
- `combat`
- `event`
- `reward`
- `hamlet`
- `rest`
- `merchant`
- `blacksmith`
- `key`
- `boss`
- The technical `event` family is currently rendered to the player as `Trail Event` on map route surfaces.
- `hamlet` is the support-family settlement stop. The side-quest system hangs off that node family rather than living as a second separate map-node family.

## Topology Baseline

- Each stage owns exactly one bounded cluster/radial exploration graph.
- The graph should read as local neighborhoods around the center start rather than as horizontal layers.
- Branching, reconnection, and short reversals are allowed as long as adjacency stays readable on a portrait screen.
- This model is bounded exploration, not full free-roam.
- Exact ring counts, spoke counts, edge layouts, and reveal percentages remain deferred.
- Overall graph density should still stay inside the compact portrait readability target.

## Hidden Sector Grammar Contract

- This section defines the replacement target for board partition grammar.
- It does not claim that the current runtime already implements hidden sectors.
- Sectors are hidden implementation partitions inside the portrait playable rect.
- Sectors are not player-facing labels, not save payload by default, and not a second ownership layer.
- `center_anchor` is the canonical opening-anchor sector name for the unrotated grammar.
  - normal runs should start in a center-local pocket, not at an edge-entry band
  - center-local does not mean the exact screen midpoint or a visibly fixed pixel position
  - outward direction emphasis may vary by deterministic profile, but the start does not move to a Slay-the-Spire-style edge by default
- Sector occupancy should usually stay sparse:
  - default expectation: `0-2` nodes in a sector
  - one justified dense pocket may rise to `3` only when route role or late-pressure staging clearly needs it
- Slot/anchor budget means the number of local anchor candidates the later layout system may expose inside that sector.
- Node placement must consume sector-local anchor candidates with jitter, offset, and asymmetry.
- Node placement must not silently collapse to sector centroids.
- Corridors may connect only allowed neighboring sectors, except for the optional outer-late extension rule below.
- Visible checkerboard, visible cell-centering, or obvious mirrored symmetry is contract failure, not acceptable randomness.

### Orientation Profile Contract

- The map must not collapse into a fixed Slay-the-Spire-style upward ladder.
- The default supported profile family is `center_outward`: opening anchor center-local, with multiple outward route directions.
- Each run or stage profile may choose a deterministic `orientation_profile_id` from the run seed to vary outward emphasis, silhouette, and risk/support placement.
- Required center-outward emphasis variants:
  - `center_outward_balanced`: no single cardinal direction owns the whole route read
  - `center_outward_north_weighted`: north-side route pressure is stronger but south/east/west still contribute
  - `center_outward_south_weighted`: south-side route pressure is stronger but north/east/west still contribute
  - `center_outward_west_weighted`: west-side route pressure is stronger but north/south/east still contribute
  - `center_outward_east_weighted`: east-side route pressure is stronger but north/south/west still contribute
- Edge-entry profiles are not the default identity. If a later stage profile intentionally starts from an edge, it must say so explicitly and must not be reported as the general map target.
- The chosen profile must keep screen north/south/east/west readable through route layout, branch labels in developer data, or review metadata, without showing sector labels to the player.
- Direction variation must preserve bounded exploration, local adjacency, key/boss viability, and the `2-4` first-choice readability target.
- If UI needs layout metadata, `orientation_profile_id` / outward-emphasis reads must remain read-only non-save metadata and must not become UI-owned gameplay truth.

Baseline hidden sectors:

| Sector | Allowed neighboring sectors | Min/max occupancy | Optional empty chance | Slot/anchor budget | Role bias | Corridor exits |
|---|---|---:|---:|---:|---|---|
| `center_anchor` | `north_west`, `north_center`, `north_east`, `mid_left`, `mid_right`, `south_center` | `1-2` | `0%` | `3` | center start pocket, readable first `2-4` north/south/east/west choices, one local opening-value stop allowed, never default key/boss | primary `north_center` / `mid_left` / `mid_right` / `south_center`; optional diagonal handoffs through `north_west` / `north_east` |
| `north_west` | `center_anchor`, `north_center`, `mid_left`, optional `outer_late_west` | `0-2` | `25%` | `2` | upper-left flank pocket, event/reward/support detour, local reconnect only | primary `north_center` or `mid_left`; optional `outer_late_west` |
| `north_center` | `center_anchor`, `north_west`, `north_east`, `mid_left`, `mid_right` | `1-2` | `5%` | `2` | north outward continuation, early combat/readability handoff, route split staging | primary `north_west` / `north_east`; secondary `mid_left` / `mid_right` |
| `north_east` | `center_anchor`, `north_center`, `mid_right`, optional `outer_late_east` | `0-2` | `25%` | `2` | upper-right flank pocket, reward/support/event detour, local reconnect only | primary `north_center` or `mid_right`; optional `outer_late_east` |
| `mid_left` | `center_anchor`, `north_west`, `north_center`, `south_west`, `south_center` | `0-2` | `15%` | `2` | left branch body, opening-side choice, reward/support pocket, landmark counterweight | primary `north_west` / `south_west`; secondary `south_center` |
| `mid_right` | `center_anchor`, `north_east`, `north_center`, `south_east`, `south_center` | `0-2` | `15%` | `2` | right branch body, opening-side choice, reward/support pocket, landmark counterweight | primary `north_east` / `south_east`; secondary `south_center` |
| `south_west` | `mid_left`, `south_center` | `0-2` | `35%` | `2` | lower-left structural counterweight, short prep/support detour, not default key/boss | primary `mid_left`; secondary `south_center` |
| `south_center` | `center_anchor`, `mid_left`, `mid_right`, `south_west`, `south_east` | `0-1` | `45%` | `1` | lower-center counterweight, support detour, or local reconnect staging, not mandatory | primary `center_anchor`; secondary `south_west` / `south_east` |
| `south_east` | `mid_right`, `south_center` | `0-2` | `35%` | `2` | lower-right structural counterweight, short prep/support detour, not default key/boss | primary `mid_right`; secondary `south_center` |

Allowed later extension:

| Sector | Allowed neighboring sectors | Min/max occupancy | Optional empty chance | Slot/anchor budget | Role bias | Corridor exits |
|---|---|---:|---:|---:|---|---|
| `outer_late_west` | `north_west`, `mid_left` | `0-1` | `55%` | `1` | explicit late-pressure extension for key/boss/final-prep staging only | return through `north_west` or `mid_left` |
| `outer_late_east` | `north_east`, `mid_right` | `0-1` | `55%` | `1` | explicit late-pressure extension for key/boss/final-prep staging only | return through `north_east` or `mid_right` |

Hidden-sector grammar rules:

- `center_anchor` never goes empty.
- Canonical `north_center` should usually remain occupied because it carries one major outward handoff; an empty canonical `north_center` must be an explicit stage-shape exception, not the default.
- At least one of `mid_left` or `mid_right` should usually participate in the opening readable-choice shell.
- Canonical `south_*` sectors exist to create back-side/counterweight structure after orientation mapping; the numeric enforcement now lives in the structural-metrics contract below.
- Optional outer-late sectors are late-pressure tools only:
  - they must not become opening pockets
  - they must not become general overflow bins for ordinary branch clutter
- Key/boss pressure should favor outward sectors (`north_*`, `mid_*`, `south_*`, or optional outer-late sectors) rather than collapsing back into `center_anchor`.
- Local reconnects may only bridge neighboring sectors or return through an already allowed sector chain.
- Direct cross-board jumps such as `north_west -> south_east` or `south_west -> north_east` are contract failure unless a later explicit contract update changes the grammar and says `escalate first`.

## Structural Metrics Contract

- This section defines the structural metrics contract for later map implementation work.
- These metrics are layered on top of the hidden-sector grammar above; they do not replace it.
- They do not claim that the current checked-in runtime already satisfies them.
- Structural metrics do not replace screenshot review. If captures still read wrong, a metrics-only pass is not green.

### Sector Occupancy And Spread Metrics

- `occupied_baseline_sector_count`
  - normal seeds should occupy `6-8` baseline sectors
  - `5` occupied baseline sectors is allowed only as an explicit stage-shape exception when one justified dense pocket or one optional outer-late sector still preserves opening readability and lower-half structure
  - fewer than `5` occupied baseline sectors is structural failure
- `dense_pocket_cap`
  - at most one sector may rise to `3` occupied nodes
  - no sector may exceed its stated occupancy cap
- `north_outward_presence`
  - canonical `north_center` should remain occupied in normal seeds because it is one readable cardinal outward handoff
  - an empty canonical `north_center` is an explicit stage-shape exception, not a default outcome
- `opening_lateral_presence`
  - at least one of `mid_left` or `mid_right` must participate in the opening readable-choice shell
- `back_or_counterweight_sector_presence`
  - representative default seeds should usually occupy at least one canonical `south_*` sector after orientation mapping
  - a fully back-side-empty layout counts as one-direction pressure failure unless a documented stage-shape exception still preserves visible counterweight structure
- `single_direction_pressure`
  - node count across any one cardinal direction cluster should not dominate `center_anchor + the other cardinal clusters` by more than `2`
- `one_direction_ladder_failure`
  - any layout whose occupied sectors collapse to `center_anchor + one cardinal direction only` is structural failure

### Start Anchor And Opening Choice Metrics

- `start_anchor_zone`
  - the realized opening pocket should be center-local by default, not a lower/upper/left/right edge-entry band
  - center-local placement may jitter by seed inside safe bounds so repeated runs do not look stamped
  - any edge-entry start is a stage-specific exception and must be called out as such
  - the opening pocket must preserve safe margins, first-choice readability, and room for north/south/east/west route identity
- `opening_outward_choice_count`
  - the opening pocket should expose `2-4` readable outward choices
- `opening_cardinal_read`
  - at least two opening choices should claim distinct cardinal route reads by the first pocket throat
  - representative sweeps should show north, south, east, and west routes as meaningful at least once unless a stage profile explicitly narrows direction use
- `opening_lateral_read`
  - at least one opening choice should hand off through `mid_left` or `mid_right`
- `opening_choice_separation`
  - if `3+` opening choices are visible, at least two of them must claim distinct corridor silhouettes by the first turn or first pocket throat
  - choices that keep sharing the same departure lane beyond that point count as same-corridor conflict

### Symmetry And Uniformity Rejection

- `bilateral_mirror_failure`
  - a layout fails if all three left/right sector pairs (`north_west` / `north_east`, `mid_left` / `mid_right`, `south_west` / `south_east`) resolve to matching occupancies and mirrored opening exits in the same seed
- `uniform_occupancy_failure`
  - a layout fails if `5+` occupied baseline sectors all resolve to one-node pockets with no dense / empty contrast
- `checkerboard_rejection`
  - evenly spaced centroid-like placement or obvious visible grid cadence is structural failure even if occupancy counts technically pass

### Landmark Pocket And Clearing Metrics

- `pocket_owner_coverage`
  - every discovered non-start destination must belong to one local pocket owner
- `special_pocket_distinctness`
  - `key`, `boss`, `reward`, and support-family destinations must each read as a distinct pocket or arrival pattern before icon read
  - `combat` and `event` pockets may reuse families, but they still need a local pocket owner rather than floating icon discs
- `pocket_merge_limit`
  - adjacent actionable destinations may not collapse into one ambiguous pocket mass unless a corridor throat or clearing split keeps them distinguishable
- `clearing_integrity`
  - each actionable pocket must preserve one local arrival clearing plus one landmark silhouette gap
  - roads may enter and exit through pocket throats, but they must not cut through the interaction clearing
  - canopy and filler mass must recede from the pocket core rather than occluding it
- `icon_secondary_read`
  - icons are confirmation surfaces only
  - screenshot review should still leave `key`, `boss`, `reward`, and support-family identity understandable when icons are mentally suppressed
  - later automated checks may validate pocket ownership metadata, but screenshot review remains the authority for this read

### Corridor And Lane Metrics

- `outward_lane_count`
  - `center_anchor` should usually expose `2-4` outward choices
  - canonical `north_center`, `mid_left`, and `mid_right` should usually expose `2-3` readable outward lanes when they act as decision pockets
  - `outer_late_*` sectors should behave as pressure terminals or short return pockets, not fresh wide-fanout hubs
- `same_corridor_conflict`
  - two actionable outward choices fail if they share the same visible departure lane for more than one short corridor segment (`one junction-to-junction step`) before separating
  - clearly secondary reconnect/history lanes do not count as primary outward choices
- `route_overlap_limit`
  - active corridors should not stack so tightly that one pocket exit reads like one undecidable bundle of lines
- `support_detour_readability`
  - at least one support-family opportunity should live on a short readable detour off the opening shell or one outward route
  - a support detour should not require passing the boss gate or collapse into the same corridor as the mandatory boss push
- `risk_safety_route_contrast`
  - branch risk/safety must read from route structure, node-family pressure, detour depth, reconnect cost, support/prep placement, and key/boss staging rather than from player-facing sector labels or hardcoded `safe` / `risky` route text
  - representative review should be able to name at least one pressure-oriented route and one prep/support-oriented route when the stage profile and reveal state expose enough choices
  - this contrast is presentation and topology readability only; it does not add a new gameplay owner, save field, node family, or route-state truth source
- `late_pressure_separation`
  - `key` and `boss` must not share `center_anchor`, the same pocket, or the same immediate arrival read
  - boss pressure should remain outward and late, typically in a cardinal/outside pressure sector rather than the opening center
  - after key resolution, the map should still preserve at least one additional step or one readable final-prep detour before boss commitment by default

### Seed Variance Metrics

- `representative_seed_sweep_floor`
  - structural review should use a representative seed sweep, not one cherry-picked screenshot
  - working floor: at least `5` seeds per active stage profile, or an explicitly named equivalent curated set if a later prompt justifies it
- `occupancy_silhouette_variance`
  - occupied-sector silhouettes should produce at least `3` distinct patterns inside each representative sweep
  - no single occupied-sector silhouette should dominate more than `50%` of the reviewed seeds for the same stage profile
- `opening_pattern_dominance_rejection`
  - the exact same cardinal opening-choice pattern should not dominate more than `50%` of the representative sweep by default
- `lower_half_participation_variance`
  - representative sweeps should include more than one way of using the board area around and beyond the center-local opening pocket
  - repeated one-direction/top-loaded silhouettes are failure even when individual seeds remain technically valid
- `orientation_profile_variance`
  - representative sweeps should include more than one center-outward emphasis profile unless a stage profile explicitly locks one for a documented reason
  - the same outward emphasis profile should not dominate more than `60%` of a general representative sweep by default
  - if a narrow stage profile intentionally locks one emphasis, the report must say so and must not describe the whole map system as direction-varied

## Portrait Readability Guardrail

- Prototype stage graphs should stay compact enough to read as one local neighborhood on a mobile portrait screen.
- A practical working target is usually around `12-13` enterable non-start nodes per stage, or `14` total nodes counting the center start.
- From one explored pocket, the player should usually be judging at most `2-4` outward exploration options at once.
- Exact authored layouts may vary as long as they preserve readability, guarantee floor, and bounded-exploration identity.

## Node State Semantics

- `undiscovered`
  - hidden from the player-facing board
  - node family and value are not yet readable
- `discovered`
  - revealed and readable
  - not yet resolved
- `resolved`
  - the node's primary content has already been consumed
  - revisit may still pass through the node, but it does not regenerate its primary reward or encounter by default
- `locked`
  - visible but not currently enterable
  - the boss gate is the mandatory prototype example of this state

## Traversal Rules

- From the current node, the player may move only to adjacent reachable nodes.
- Traversal may move across discovered space in any graph-supported direction.
- Revisit is allowed for positioning, scouting, and route correction.
- Every movement step pays hunger cost.
- Current runtime-backed movement cost is `1` hunger per step.
- If a movement step leaves hunger at `0`, that step also deals `1` HP starvation damage and may end the run immediately.
- Revisit does not reopen resolved value, respawn combat, or create repeat-farm loops.
- Exact reveal-radius remains deferred, but the current per-move hunger-cost baseline is no longer deferred.

## Generation Baseline

- Prototype map generation should target bounded profile-driven sector-aware backbone graphs first.
- Full free-graph generation is still deferred.
- The current runtime-backed slice now uses stage-profile-driven sector-aware backbone generation keyed by the `procedural_stage_*` ids inside the locked compact portrait envelope.
- Fresh runs may now vary the realized sector-aware backbone blueprint and role placement within that stage-profile floor by consuming the active run seed.
- That seeded variation must preserve the same stage guarantee floor, bounded compact envelope, and center-start readability contract rather than widening into free-form graph generation.
- Current runtime backbone truth uses a two-step runtime model:
  - first build the bounded connected sector-aware backbone with a deliberate center-local start anchor, `3` mainline opening choices, one local counterweight opening pocket, and `1-2` local same-depth reconnects
  - then assign node families onto that graph through a separate structural role-scoring placement step
- Current runtime backbone truth keeps the opening readable shell explicit: start reveals an early combat route, an early reward route, and an early support route under fixed stage quotas across a denser `14`-node stage graph.
- Current controlled family placement also keeps one support branch explicit:
  - one opening support node is adjacent to start
  - one late support node stays directly adjacent on that opening support branch
- Current event placement is narrow and controlled:
  - each stage graph owns exactly `1` dedicated late-route detour event role
  - that role always resolves to the runtime-backed `event` node family
  - it is additive to the existing combat/reward/support/key/boss floor, not a replacement for it
- Current hamlet placement is also narrow and controlled:
  - each stage graph owns exactly `1` dedicated optional-detour hamlet role
  - that role always resolves to the runtime-backed `hamlet` node family
  - that hamlet node may later host side-quest targeting and return flow, but it is additive to the existing combat/reward/support/key/boss floor rather than replacing them
- Current key/boss placement is also controlled:
  - they are biased to the outer region
  - they are placed on late-pressure outer pockets or flanks rather than collapsing back into the opening shell
  - they must not collapse into an immediate adjacent boss click once the key is secured

## Stage Guarantee Floor

- Guarantee rules apply at the stage-level graph-space level.
- They do not mean every local route is equally safe, equally generous, or equally short.
- Current procedural v1 realizes exactly:
  - `1` `start`
  - `6` non-boss `combat` opportunities
  - `1` `event` opportunity
  - `1` `reward` opportunity
  - `1` `hamlet` opportunity
  - `2` support opportunities
  - `1` `key` node
  - `1` `boss` node
- Every stage must still contain at least:
  - `1` `event` opportunity
  - `1` `reward` opportunity
  - `1` support opportunity
  - `1` prep valve in the pre-boss portion of the stage
  - `1` `key` node
- `support opportunity` means `rest`, `merchant`, or `blacksmith`.
- `hamlet` is a support-family settlement detour, but in the current floor it is still a separate optional contract stop rather than a substitute for the main support-economy slice.
- `prep valve` means `rest` or `blacksmith`.
- Current procedural v1 support-family rotation is stage-scoped:
  - stage `1`: opening `rest`, late `merchant`
  - stage `2`: opening `merchant`, late `blacksmith`
  - stage `3`: opening `rest`, late `blacksmith`
- Across the full `3`-stage run, both `merchant` and `blacksmith` must appear at least once.

## Early-Run Exposure Floor

- Opening exploration around the center start should usually let a novice player discover at least one reward opportunity, one support opportunity, and one meaningful adjacency choice before an early collapse.
- This is an exposure floor, not a promise of equal payout or equal safety on every line.

## Stage Decision Pattern

- Inside a stage, the player's primary decisions should usually be:
  - reveal more space or cash in current local value
  - take a support detour now or save it for later
  - consume a one-shot node now or leave it for a later pass
  - reposition through resolved space to reach a newly relevant branch
  - secure the stage key now or delay it while improving readiness
  - push the boss gate after the key or spend a short final prep detour first
- The stage should not collapse into full-route certainty or into a pure checklist march from key to boss.

## Key/Boss Viability

- Each stage contains exactly one stage-local `key` and one boss gate.
- The boss gate remains locked until the stage key is resolved.
- The stage key must be reachable from the center-start graph without requiring the boss gate to already be open.
- After the key is resolved, at least one viable path to the boss encounter must remain reachable.
- Intended pacing is `explore -> prepare -> secure key -> make a short final boss push`.
- Exact key-to-boss distance remains tuning, but the key should not collapse the stage into an immediate boss click by default.
- The boss gate may be represented as a locked boss node read or as a separate gated access read; the contract requires the lock behavior, not one specific scene implementation.

## Current Runtime Owner

- `MapRuntimeState` now exists as the current implemented owner of:
  - stable stage-local node identity
  - runtime node-state truth over the current bounded sector-aware backbone slice
  - current node position
  - node discovery / resolved / locked state
  - stage-local key resolution
  - boss-gate locked / unlocked state
  - roadside encounter quota (`roadside_encounters_this_stage`) and deterministic roadside routing draw state
  - support-node local revisit state keyed by stable node id
  - hamlet-local side-quest state keyed by stable node id
  - pending node resolution context
- The current stage-profile ids are:
  - `ContentDefinitions/MapTemplates/procedural_stage_corridor_v1.json`
  - `ContentDefinitions/MapTemplates/procedural_stage_openfield_v1.json`
  - `ContentDefinitions/MapTemplates/procedural_stage_loop_v1.json`
- Those ids remain the active runtime/save profile identifiers for stage `1-3`.
- Runtime graph construction no longer depends on authored scaffold node adjacency from those files.
- Legacy fixed templates `fixed_stage_cluster.json` and `fixed_stage_detour.json` remain only for backward-compatible load reconstruction of schema-1 saves.
- `RunSessionCoordinator` routes node entry and node resolution through that state.
- The current implemented slice now owns adjacency movement, local undiscovered-node reveal, stage-local key/gate truth, support-node revisit persistence, resolved traversal, sector-aware backbone graph construction, and separate role-based family assignment across that bounded graph set.
- The current role fill places `event` nodes through one dedicated late-route event role; it does not disguise events as reward or support nodes.
- The current role fill also places `hamlet` nodes through one dedicated late-route settlement role.
- Boss-clear stage progression currently routes through `RunSessionCoordinator` plus `RunState`, not through UI.
- The current implemented slice now owns bounded sector-aware backbone generation, but not broader free-form graph generation.
- Save-safe exact restore now depends on the realized graph payload, not on re-running scaffold fill from seed alone.
- Current runtime node snapshots may expose a derived `hamlet_personality` read for `hamlet` nodes.
  - this read is stage-derived selection/presentation context, not extra saved graph payload
- Target authority direction is fuller exploration graph state in `MapRuntimeState`; current implementation is still a bounded sector-aware backbone foundation rather than the complete long-term graph-generation slice.

## Current Runtime-Backed Node Resolution

- Current live traversal now resolves active node families directly from `MapExplore`.
- Current direct-routing truth:
  - `combat` -> `Combat`
  - `boss` -> `Combat`
  - `event` -> `Event`
  - `reward` -> `Reward`
  - `rest` -> `SupportInteraction`
  - `merchant` -> `SupportInteraction`
  - `blacksmith` -> `SupportInteraction`
  - `hamlet` -> `SupportInteraction`
  - `key` resolves in place on `MapExplore` while updating stage-key and boss-gate truth
- `NodeResolve` remains implemented as a legacy transition shell.
- current runtime-backed node families no longer use it on their normal direct-entry path
- generic pending-node fallback and legacy-compatible pending-node restore can still route into it
- behavior-changing removal of that live fallback still requires a dedicated flow audit; guarded cleanup should only document or isolate it, not retire it opportunistically
- Planned `event` nodes and movement-triggered roadside encounters are distinct:
  - the planned map-node family remains `event` and routes directly into `Event`
  - travel-triggered roadside encounters are transient movement interruptions and do not occupy or consume a map-node slot
  - `Roadside Encounter` is now reserved for the movement-triggered interruption only
- Side-step movement can also route to `Event` when the roadside RNG stream rolls a hit:
  - source context is `roadside_encounter`
  - attempt happens after the move is chosen and its hunger cost is paid, but before destination arrival commits
  - only unresolved `discovered` combat/reward-style travel targets are eligible
  - current roadside tune allows up to `3` movement interruptions per stage through `MapRuntimeState.MAX_ROADSIDE_ENCOUNTERS_PER_STAGE`
  - roadside-tagged `EventTemplates` may optionally gate themselves behind `rules.trigger_condition` using current route-state stats such as hunger, HP percent, or gold
  - start, planned `event`, key, boss, hamlet, and direct support-family destinations stay untouched
  - an accepted side-quest marked combat target also stays untouched so that route opens `Combat` directly
  - while the roadside interruption is open, the player has not yet arrived on the destination node
  - a successful roadside interruption does not mark the destination resolved or consume its primary content
  - after the roadside interruption resolves, destination flow resumes through its own family routing
  - quota is enforced by `MapRuntimeState.can_trigger_roadside_encounter`
- `start` is a map anchor node, not a reward or combat result node.
- Re-entering a resolved node may still support traversal, but must not create fresh primary payout or encounter value by default.
- Resolved event-node revisits must stay traversable without reopening `Event` or minting a second primary outcome.
- Resolved support-node revisits must stay traversable without reopening `SupportInteraction`.
- Resolved hamlet nodes are the one current exception:
  - after a side quest is accepted or completed, revisiting that node may reopen `SupportInteraction`
  - after the side quest is claimed, revisiting that node must fall back to pure traversal

## Current Map Inventory Strip

- `MapExplore` shows the carried inventory strip directly from `InventoryState`.
- Current map-side card interactions are:
  - click carried `weapon`, `armor`, or `belt` to equip or unequip it immediately
  - click carried `consumable` to use it immediately if it changes HP or hunger
  - drag carried cards to reorder backpack slot order
- clicking a carried replacement weapon / shield / armor / belt still swaps directly with the equipped lane even when the backpack is already full
- if unequipping an equipped non-belt item would need a backpack slot and the backpack is already full, map runtime now opens the same discard-or-keep prompt style instead of silently evicting older carried loot
- Those interactions mutate the canonical inventory owner; they are not separate map-local UI truth.

## Boss Rule

- Every stage ends with a single boss encounter guarded by one boss gate.
- Clearing the boss encounter ends the stage; this pass does not require a separate exit node.
