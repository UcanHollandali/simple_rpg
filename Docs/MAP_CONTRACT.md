# SIMPLE RPG - Map Contract

## Purpose

This file defines the minimum map topology, traversal, and viability contract for prototype and early implementation work.

## Map Spine

- Each stage uses a bounded node graph centered on local exploration.
- The player starts from a center anchor node.
- Stage visibility uses partial undiscovered information; the player explores from local revealed information rather than full-route certainty.
- Board presentation may pre-compose a full derived stage layout at stage start, but discovery should only change visibility/readability, not graph truth or traversal semantics.
- Dedicated fog presentation on the board is currently suspended; hidden nodes stay runtime-undiscovered without separate fog cards or fog labels.
- Movement is adjacency-based between neighboring reachable nodes.
- Revisit is allowed inside a stage.
- Movement consumes hunger.
- The map must not create infinite farm loops.

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

- Prototype map generation should target bounded profile-driven controlled-scatter graphs first.
- Full free-graph generation is still deferred.
- The current runtime-backed slice now uses stage-profile-driven controlled scatter generation keyed by the `procedural_stage_*` ids inside the locked compact portrait envelope.
- Fresh runs may now vary the realized controlled-scatter topology and role placement within that stage-profile floor by consuming the active run seed.
- That seeded variation must preserve the same stage guarantee floor, bounded compact envelope, and center-start readability contract rather than widening into free-form graph generation.
- Current controlled-scatter v1 truth uses a two-step runtime model:
  - first build the bounded connected center-start frontier-growth scatter graph with controlled late reconnect
  - then assign node families onto that graph through a separate structural role-scoring placement step
- Current controlled-scatter v1 truth keeps the opening readable shell explicit: start reveals an early combat route, an early reward route, and an early support route under fixed stage quotas across a denser `14`-node stage graph.
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
  - they are placed on the same late route line or flank
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
  - runtime node-state truth over the current controlled-scatter procedural slice
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
- The current implemented slice now owns adjacency movement, local undiscovered-node reveal, stage-local key/gate truth, support-node revisit persistence, resolved traversal, controlled-scatter graph construction, and separate role-based family assignment across that bounded graph set.
- The current controlled-scatter role fill places `event` nodes through one dedicated late-route event role; it does not disguise events as reward or support nodes.
- The current controlled-scatter role fill also places `hamlet` nodes through one dedicated late-route settlement role.
- Boss-clear stage progression currently routes through `RunSessionCoordinator` plus `RunState`, not through UI.
- The current implemented slice now owns controlled-scatter v1 generation, but not broader free-form graph generation.
- Save-safe exact restore now depends on the realized graph payload, not on re-running scaffold fill from seed alone.
- Current runtime node snapshots may expose a derived `hamlet_personality` read for `hamlet` nodes.
  - this read is stage-derived selection/presentation context, not extra saved graph payload
- Target authority direction is fuller exploration graph state in `MapRuntimeState`; current implementation is still a bounded controlled-scatter foundation rather than the complete long-term graph-generation slice.

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
