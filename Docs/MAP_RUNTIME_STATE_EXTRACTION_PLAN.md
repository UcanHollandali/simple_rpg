# MAP_RUNTIME_STATE Extraction Plan

Escalate-first lane.

This file is planning-only.
Do not treat it as implementation authorization.
`Game/RuntimeState/map_runtime_state.gd` is the current stage-truth owner. Any extraction that changes owner meaning, save truth, pending-node truth, or graph-truth write boundaries must escalate first before code changes.

## Current Measurement

Measured against the current repo snapshot, not the stale prompt numbers:

- file: `Game/RuntimeState/map_runtime_state.gd`
- current line count: `2395`
- current function count: `147`
- reference SHA256 at planning time: `D6089EB1ECC73CD9C9516C830819986C817B7BB5D7CA73265F469B15C47C2FE1`

## Reading Rule

This plan separates:

- pure or mostly-pure helper logic that can be extracted while keeping `MapRuntimeState` as owner
- mutation helpers that likely still belong under the owner even if some normalization utilities move out
- blocks that should not move without an explicit ownership decision

`ownership impact` meanings:

- `none`: safe helper extraction candidate; owner stays `MapRuntimeState`
- `ambiguous`: probably extractable as helper logic, but only if the write/read boundary stays explicit
- `yes`: extraction risks changing owner meaning or save/runtime authority

## Function Blocks

### 1. Public Read Surface and Basic Queries

Representative functions:

- `has_node`
- `get_node_count`
- `get_current_node_family`
- `get_stage_key_node_id`
- `get_boss_node_id`
- `get_active_template_id`
- `get_node_family`
- `get_node_state`
- `get_adjacent_node_ids`
- `get_discovered_adjacent_node_ids`
- `get_frontier_fog_count`
- `get_discovered_node_count`
- `get_resolved_node_count`
- `is_stage_key_resolved`
- `is_boss_gate_unlocked`
- `is_node_discovered`
- `is_node_locked`
- `is_node_resolved`
- `is_support_node`
- `is_hamlet_node`
- `is_side_mission_node`
- `get_hamlet_personality`

Ownership impact: `none`

Why:

- These are mostly read-only projections over owner state.
- They can stay as thin owner methods even if some low-level query helpers move out.

Estimated helper file:

- `Game/RuntimeState/map_runtime_queries.gd`

### 2. Movement Gating and Traversal Entry

Representative functions:

- `can_move_to_node`
- `node_requires_resolution`
- `move_to_node`
- `find_adjacent_node_id`
- `build_adjacent_node_snapshots`
- `build_node_snapshots`
- `_build_node_snapshot`
- `_reveal_adjacent_nodes`

Ownership impact: `ambiguous`

Why:

- Read-heavy parts are extractable.
- Actual move validity and reveal mutation still touch canonical stage truth.
- Safe extraction would split pure snapshot/projection math from owner writes, not move traversal ownership.

Estimated helper file:

- `Game/RuntimeState/map_runtime_traversal_view.gd`

### 3. Pending Context

Representative functions:

- `has_pending_node`
- `clear_pending_node`
- `set_pending_node`
- `consume_pending_node_data`

Ownership impact: `yes`

Why:

- This is direct owner truth for pending-node continuity.
- It is tightly coupled to flow resume, roadside continuation, and save/load.

Estimated helper file:

- none recommended unless only a tiny codec/normalizer helper is extracted

### 4. Stage Key and Boss Gate

Representative functions:

- `resolve_stage_key`
- `_sync_boss_gate_state`

Ownership impact: `yes`

Why:

- These functions mutate canonical stage progression truth.
- Extracting behavior would risk moving stage-truth ownership away from `MapRuntimeState`.

Estimated helper file:

- none recommended

### 5. Roadside Quota and Route-Interruption State

Representative functions:

- `can_trigger_roadside_encounter`
- `consume_roadside_encounter_slot`
- `get_roadside_encounters_this_stage`

Ownership impact: `ambiguous`

Why:

- Counter reads and validation can be helperized.
- Quota mutation still belongs to the owner.

Estimated helper file:

- `Game/RuntimeState/map_roadside_policy.gd`

### 6. Support Revisit Runtime State

Representative functions:

- `get_support_node_runtime_state`
- `save_support_node_runtime_state`
- `_is_support_node_family`
- `_normalize_support_node_state`

Ownership impact: `ambiguous`

Why:

- Normalization and validation helpers can move.
- The dictionary itself remains owner-backed runtime truth keyed by stable node id.

Estimated helper file:

- `Game/RuntimeState/map_support_node_state_codec.gd`

### 7. Hamlet / Side-Quest Runtime State

Representative functions:

- `get_side_mission_node_runtime_state`
- `get_side_quest_node_runtime_state`
- `save_side_mission_node_runtime_state`
- `save_side_quest_node_runtime_state`
- `list_eligible_side_mission_target_node_ids`
- `list_eligible_side_quest_target_node_ids`
- `get_side_mission_target_enemy_definition_id`
- `get_side_quest_target_enemy_definition_id`
- `mark_side_mission_target_completed`
- `mark_side_quest_target_completed`
- `build_side_mission_highlight_snapshot`
- `build_side_quest_highlight_snapshot`
- `get_active_side_quest_by_target_node_id`
- `_build_default_side_quest_node_state`
- `_normalize_side_mission_node_state`
- `_normalize_side_quest_node_state`
- `_side_quest_reward_inventory_family_is_supported`
- `_normalize_side_quest_mission_type`
- `_side_quest_target_family_is_valid`

Ownership impact: `ambiguous`

Why:

- This is still owner truth, but much of the mission-state shaping and validation is normalization logic.
- A helper extraction is viable if save/runtime write ownership stays in `MapRuntimeState`.

Estimated helper file:

- `Game/RuntimeState/map_side_quest_state_codec.gd`

### 8. Persistence and Legacy Load

Representative functions:

- `to_save_dict`
- `load_from_save_dict`
- `_build_legacy_fixed_graph`
- `_load_graph_template_nodes`
- `_resolve_scaffold_id_for_stage`
- `_resolve_legacy_template_id_for_stage`
- `_extract_template_node_array`

Ownership impact: `yes`

Why:

- This is direct save truth assembly and hydration for the stage owner.
- Legacy schema handling is especially sensitive.
- Extraction can happen only as narrow helper utilities, not as a new persistence owner.

Estimated helper file:

- `Game/RuntimeState/map_runtime_graph_codec.gd` already exists as the natural narrow landing area for future codec-only helper work

### 9. Node State Mutation Internals

Representative functions:

- `_find_node_graph_index`
- `_get_node_data`
- `_find_first_node_id_by_family`
- `_set_node_state`
- `_is_valid_node_state`

Ownership impact: `yes`

Why:

- These are direct internals for canonical node truth.
- They should remain close to the owner unless only tiny pure validators move out.

Estimated helper file:

- none recommended

### 10. Reset and Seed Plumbing

Representative functions:

- `reset_for_new_run`
- `reset_for_next_stage`
- `_reset_runtime_state`
- `_resolve_generation_seed`
- `_normalize_generation_seed`

Ownership impact: `yes`

Why:

- These are owner lifecycle boundaries for stage truth.
- They coordinate graph rebuild and state reset.

Estimated helper file:

- none recommended

### 11. Graph Build Entry and Scaffold Fallback

Representative functions:

- `_build_scaffold_graph`
- `_build_scatter_graph_fallback`
- `_validate_scatter_runtime_graph_min_floor`

Ownership impact: `ambiguous`

Why:

- The pure graph-construction logic is a strong extraction candidate.
- The final act of adopting the graph should remain inside `MapRuntimeState`.

Estimated helper file:

- `Game/RuntimeState/map_scatter_graph_builder.gd`

### 12. Controlled-Scatter Topology Builder

Representative functions:

- `_build_controlled_scatter_topology`
- `_build_controlled_scatter_frontier_tree`
- `_frontier_branch_target_lengths`
- `_frontier_branch_growth_order`
- `_frontier_branch_priority_order`
- `_rotate_packed_int32_array`
- `_apply_controlled_scatter_reconnects`
- `_scatter_reconnect_plans`
- `_pick_controlled_reconnect_edge`
- `_preferred_reconnect_candidates`
- `_controlled_scatter_role_targets_are_valid`
- `_build_scatter_path_length`
- `_count_scatter_same_depth_reconnects`
- `_count_scatter_extra_edges`
- `_has_scatter_edge`
- `_add_scatter_edge`
- `_get_scatter_degree`
- `_build_scatter_depth_map`
- `_shuffle_int_array`

Ownership impact: `none`

Why:

- This is the cleanest extraction candidate in the whole file.
- The majority is pure topology math over adjacency dictionaries and seeds.
- `MapRuntimeState` can stay the owner that calls into a builder.

Estimated helper file:

- `Game/RuntimeState/map_scatter_topology_builder.gd`

### 13. Controlled-Scatter Role Reservation

Representative functions:

- `_reserve_controlled_scatter_role_targets`
- `_reserve_event_slot_node_id`
- `_branch_role_node_id`
- `_validate_controlled_scatter_topology`

Ownership impact: `none`

Why:

- These are still graph-analysis helpers, not stage-truth adoption points.
- They are natural companions to topology generation.

Estimated helper file:

- `Game/RuntimeState/map_scatter_role_reservation.gd`

### 14. Family Assignment and Structural Analysis

Representative functions:

- `_build_controlled_scatter_family_assignments`
- `_build_scatter_structural_family_analysis`
- `_sorted_scatter_node_ids`
- `_build_scatter_parent_map`
- `_build_scatter_branch_root_map`
- `_build_scatter_children_count_map`
- `_build_scatter_same_depth_reconnect_node_set`
- `_build_scatter_branch_summaries`
- `_build_scatter_placement_seed`
- `_build_scatter_topology_signature`
- `_build_unassigned_scatter_node_ids`
- `_filter_unassigned_node_ids`
- `_filter_nodes_by_branch_root`
- `_filter_nodes_by_min_path_length`
- `_filter_nodes_adjacent_to_target`
- `_filter_leaf_like_scatter_nodes`
- `_filter_connector_friendly_scatter_nodes`
- `_filter_nodes_away_from_role_branches`
- `_pick_best_scatter_role_candidate`
- `_score_scatter_role_candidate`
- `_frontier_score_for_scatter_node`
- `_connector_score_for_scatter_node`
- `_progress_corridor_score_for_scatter_node`
- `_optional_detour_score_for_scatter_node`
- `_is_leaf_like_scatter_node`
- `_target_proximity_score`
- `_role_tiebreak_value`
- `_hash_scatter_seed_string`
- `_filter_nodes_by_depth_and_max`
- `_resolve_stage_support_layout`

Ownership impact: `none`

Why:

- This is mostly pure analysis and scoring.
- It is the second-best extraction zone after topology building.

Estimated helper file:

- `Game/RuntimeState/map_scatter_family_assignment.gd`

### 15. Graph Payload and Adjacency Rebuild Helpers

Representative functions:

- `_build_adjacency_lookup_from_graph`
- `_build_family_budget_slot_reservations_from_graph`
- `_rebuild_family_budget_slot_reservations_from_graph`
- `_build_scatter_graph_payload`
- `_validate_scatter_runtime_graph`
- `_is_graph_connected_scatter`

Ownership impact: `ambiguous`

Why:

- Codec/validation parts are pure and extractable.
- Rebuild/adopt steps still serve owner truth directly.

Estimated helper file:

- `Game/RuntimeState/map_runtime_graph_helpers.gd`

### 16. Family Budget Snapshot

Representative functions:

- `build_family_budget_slot_snapshot`
- `_build_family_budget_slot_reservations_from_graph`
- `_rebuild_family_budget_slot_reservations_from_graph`

Ownership impact: `ambiguous`

Why:

- Mostly derived from graph state.
- Could move as a narrow helper, but it is close to owner-managed graph adoption.

Estimated helper file:

- `Game/RuntimeState/map_family_budget_snapshot.gd`

## Safe Extraction Order

From safest to riskiest:

1. `map_scatter_topology_builder.gd`
   - pure controlled-scatter topology and reconnect math
   - ownership impact: `none`
2. `map_scatter_role_reservation.gd`
   - role target reservation and topology validity helpers
   - ownership impact: `none`
3. `map_scatter_family_assignment.gd`
   - structural analysis and family scoring
   - ownership impact: `none`
4. `map_runtime_graph_helpers.gd`
   - adjacency rebuild, graph payload assembly, validation helpers
   - ownership impact: `ambiguous`
5. `map_runtime_queries.gd`
   - read-only query helpers and snapshot shaping
   - ownership impact: `none`
6. `map_runtime_traversal_view.gd`
   - snapshot/read-side traversal presentation helpers
   - ownership impact: `ambiguous`
7. `map_support_node_state_codec.gd`
   - support-node normalization helpers
   - ownership impact: `ambiguous`
8. `map_side_quest_state_codec.gd`
   - side-quest normalization and validation helpers
   - ownership impact: `ambiguous`
9. `map_roadside_policy.gd`
   - roadside quota read/validation helpers only
   - ownership impact: `ambiguous`
10. Persistence helper widening under existing codec surfaces
    - only narrow codec extraction, no owner move
    - ownership impact: `yes` if widened carelessly
11. Pending context, stage key, boss gate, reset lifecycle
    - not recommended without explicit escalation
    - ownership impact: `yes`

## Recommended First Pass

If implementation starts later, the smallest safe first pass is:

1. extract controlled-scatter topology math
2. extract controlled-scatter role reservation
3. extract family-assignment scoring/analysis

That sequence should remove a large amount of pure helper code without changing:

- stage truth ownership
- save payload shape
- pending-node ownership
- key/boss-gate ownership
- side-quest runtime ownership

## Explicit Non-Recommendations

Do not start with:

- `load_from_save_dict`
- `to_save_dict`
- pending-node helpers
- key/boss-gate mutation
- `reset_for_new_run` / `reset_for_next_stage`

Those are the areas most likely to blur owner boundaries and create hidden save/flow drift.
