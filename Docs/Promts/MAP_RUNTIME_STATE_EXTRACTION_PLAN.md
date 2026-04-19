# MAP_RUNTIME_STATE Extraction Plan

`escalate-first lane`

> **Note (2026-04-18):** This file is a **technical refactor plan**. It does NOT change map design — it only splits `map_runtime_state.gd` into smaller helper files. For the active map pass workflow use `Docs/Promts/MAP_MASTER_PROMPTS.md`.
>
> This extraction plan must run AFTER the map redesign pass in `MAP_MASTER_PROMPTS.md` closes (especially Prompts 3–6). If extraction runs first, redesign patches become fragile. If redesign runs first, the line numbers in the block tables below shift and must be re-measured before starting any extraction.
>
> Order: `Docs/Promts/MAP_MASTER_PROMPTS.md` Prompts 1A → 8 → then this extraction plan.
>
> **Line-number freshness warning:** The line and function counts below (`2397`, `146`) were measured on 2026-04-18, BEFORE the redesign pass. After Prompts 3–5 run, these numbers WILL change. Re-run a measurement pass (`wc -l` on `map_runtime_state.gd` and a `grep -c '^func '`) before starting any extraction wave, and update this file with the new block line ranges if they drifted by more than ~50 lines.

`MapRuntimeState` stage truth owner'ıdır. Bu dosya için güvenli varsayılan davranış, owner meaning'i taşımamak ve extraction'ı yalnızca helper/pure-algorithm yönünde düşünmektir. Bu rapor ölçüm ve sınıflandırma amaçlıdır. Bu pass'te hiçbir `.gd` dosyası değiştirilmedi.

## File Facts

- Source file: [C:\Users\kemal\Documents\Codex\simple_rpg\Game\RuntimeState\map_runtime_state.gd](C:\Users\kemal\Documents\Codex\simple_rpg\Game\RuntimeState\map_runtime_state.gd)
- Current line count: `2397`
- Current function count: `146`
- Authority doc: [C:\Users\kemal\Documents\Codex\simple_rpg\Docs\MAP_CONTRACT.md](C:\Users\kemal\Documents\Codex\simple_rpg\Docs\MAP_CONTRACT.md)
- Existing related extraction already in repo: [C:\Users\kemal\Documents\Codex\simple_rpg\Game\RuntimeState\map_runtime_graph_codec.gd](C:\Users\kemal\Documents\Codex\simple_rpg\Game\RuntimeState\map_runtime_graph_codec.gd)

## Reading Rule

`ownership impact` labels mean:

- `none`: aynı owner altında stateless/helper extraction mümkün; truth owner değişmek zorunda değil
- `ambiguous`: extraction mümkün ama helper sınırı kolayca pseudo-owner'a dönüşebilir; imza ve write direction dikkat ister
- `yes`: extraction çoğu durumda owner meaning'i böler veya yeni truth owner hissi yaratır; explicit escalation olmadan önerilmez

## Owner-Sensitive Runtime Blocks

| Block | Approx lines | Representative funcs | Ownership impact | Estimated file name | Notes |
|---|---:|---|---|---|---|
| Public authority façade | `132-546` | `has_node`, `get_node_state`, `move_to_node`, `mark_node_resolved`, `build_node_snapshots`, `save_support_node_runtime_state` | `yes` | `keep in map_runtime_state.gd` | Bu yüzey doğrudan map truth API'si. Toplu taşıma owner drift yaratır. |
| Node state + traversal mutation | `279-318`, `455-467`, `687-728` | `node_requires_resolution`, `move_to_node`, `mark_node_resolved`, `reveal_node`, `_reveal_adjacent_nodes`, `_set_node_state` | `ambiguous` | `map_runtime_traversal_mutator.gd` | Teknik olarak helper'a ayrılabilir, ama `_node_graph`, `current_node_id`, discovery ve resolve sırası owner'a çok bağlı. |
| Pending context | `318-335` | `has_pending_node`, `clear_pending_node`, `set_pending_node`, `consume_pending_node_data` | `ambiguous` | `map_pending_context.gd` | Küçük blok; extraction mümkün ama fayda düşük. Yanlış yapılırsa ikinci owner hissi yaratır. |
| Stage key | `217-221`, `305-310` | `is_stage_key_resolved`, `resolve_stage_key` | `ambiguous` | `map_gate_state.gd` | Key çözümü boss gate ve discovery akışına bağlı. Ayrı helper yalnızca method bundle olarak mantıklı. |
| Boss gate | `221`, `882-895` | `is_boss_gate_unlocked`, `_sync_boss_gate_state` | `ambiguous` | `map_boss_gate_state.gd` | Gate görünürlüğü node-state truth ile iç içe. Saf helper extraction mümkün, owner move olmamalı. |
| Support revisit runtime state | `378-413`, `741-754` | `get_support_node_runtime_state`, `save_support_node_runtime_state`, `_normalize_support_node_state` | `ambiguous` | `map_support_revisit_state.gd` | Truth hâlâ `MapRuntimeState` içinde kalmalı. Normalize/save helper ayrımı yapılabilir. |
| Hamlet side-quest runtime state | `389-542`, `757-879` | `get_side_mission_node_runtime_state`, `save_side_mission_node_runtime_state`, `list_eligible_side_mission_target_node_ids`, `mark_side_mission_target_completed`, `_normalize_side_quest_node_state` | `yes` | `map_hamlet_side_quest_runtime.gd` | En riskli bloklardan biri. Hamlet request truth, target seçimi, payout grammar ve completion akışı aynı yerde. Owner split tehlikesi yüksek. |
| Roadside quota | `264-275`, save/load touchpoints at `553`, `587` | `can_trigger_roadside_encounter`, `consume_roadside_encounter_slot`, `get_roadside_encounters_this_stage` | `ambiguous` | `map_roadside_quota.gd` | Tek sayaç küçük görünüyor ama traversal pacing ve save continuity ile bağlı. Extraction değeri düşük. |
| Persistence orchestration | `546-628` | `to_save_dict`, `load_from_save_dict` | `ambiguous` | `map_runtime_persistence_codec.gd` | Ayrı codec/helper mümkün; fakat stage truth restore sırası, legacy fallback ve live graph restore aynı yerde. |

## Lower-Risk Algorithm / Helper Blocks

| Block | Approx lines | Representative funcs | Ownership impact | Estimated file name | Notes |
|---|---:|---|---|---|---|
| Legacy fixed-graph compatibility | `629-664` | `_build_legacy_fixed_graph`, `_load_graph_template_nodes`, `_resolve_scaffold_id_for_stage`, `_resolve_legacy_template_id_for_stage`, `_extract_template_node_array` | `none` | `map_graph_legacy_loader.gd` | En güvenli extraction adaylarından biri. Legacy template load + scaffold id resolution saf helper olabilir. |
| Snapshot/read-model builders | `344-378`, `676-684` | `build_adjacent_node_snapshots`, `build_node_snapshots`, `build_realized_graph_snapshots`, `_build_node_snapshot` | `none` | `map_runtime_snapshot_builder.gd` | Read-only shape üretimi. Owner write yönü yok. |
| Reset/seed utilities | `908-926` | `_reset_runtime_state`, `_resolve_generation_seed`, `_normalize_generation_seed` | `ambiguous` | `map_generation_context.gd` | Ayrılabilir, fakat owner alanlarının ilk kurulum sırası kritik. |
| Graph build dispatch + fallback gate | `933-970` | `_build_scaffold_graph`, `_build_scatter_graph_fallback`, `_validate_scatter_runtime_graph_min_floor` | `ambiguous` | `map_graph_builder.gd` | Builder olarak ayrılabilir; ancak `_family_budget_slot_reservations` yan etkisi owner orchestration'da kalmalı. |
| Controlled-scatter topology + frontier growth | `1074-1350` | `_build_controlled_scatter_topology`, `_build_controlled_scatter_frontier_tree`, `_frontier_branch_target_lengths`, `_frontier_branch_growth_order`, `_apply_controlled_scatter_reconnects` | `none` | `map_scatter_topology_builder.gd` | En güçlü extraction adayı. Büyük ölçüde saf algoritma ve seed-driven topology üretimi. |
| Role reservation + topology validity | `1298-1388`, `2043-2095` | `_reserve_controlled_scatter_role_targets`, `_reserve_event_slot_node_id`, `_validate_controlled_scatter_topology`, `_controlled_scatter_role_targets_are_valid` | `none` | `map_scatter_role_planner.gd` | Graph üstünde structural reservation/guard logic. Owner write'i yok, girdiler/çıktılar açık. |
| Family assignment + structural analysis | `1389-2033` | `_build_controlled_scatter_family_assignments`, `_build_scatter_structural_family_analysis`, `_build_scatter_parent_map`, `_build_scatter_branch_summaries`, `_pick_best_scatter_role_candidate`, scoring funcs | `none` | `map_scatter_family_assigner.gd` | Dosyanın en büyük ve en güvenli pure-analysis bloğu. |
| Graph payload, reservations, validation, path/depth utils | `2096-2392` | `_build_scatter_path_length`, `_count_scatter_same_depth_reconnects`, `_build_adjacency_lookup_from_graph`, `_build_family_budget_slot_reservations_from_graph`, `_build_scatter_graph_payload`, `_validate_scatter_runtime_graph`, `_is_graph_connected_scatter`, `_build_scatter_depth_map` | `none` | `map_scatter_graph_validator.gd` | Builder/validator/helper olarak ayrılmaya çok uygun. |

## Safe Portability Order

En az owner değişikliği gerektirenden en fazlaya:

1. `map_scatter_topology_builder.gd`
   - `_build_controlled_scatter_topology`
   - frontier-growth, reconnect, rotation, branch-order helpers
2. `map_scatter_family_assigner.gd`
   - structural analysis
   - scoring/tiebreak helpers
   - family assignment picks
3. `map_scatter_role_planner.gd`
   - role reservation
   - role-target validity checks
4. `map_scatter_graph_validator.gd`
   - path length, connectivity, depth map
   - payload build and graph validation
   - family-budget-slot reservation derivation
5. `map_graph_legacy_loader.gd`
   - legacy fixed-template reconstruction
   - stage scaffold/template id selection
6. `map_runtime_snapshot_builder.gd`
   - node/adjacency snapshot read models
7. `map_runtime_persistence_codec.gd`
   - only if kept as codec/helper under `MapRuntimeState`
   - load/save orchestration should stay initiated by owner
8. `map_support_revisit_state.gd`
   - normalize/get/save helpers only
   - dictionary ownership should stay on `MapRuntimeState`
9. `map_gate_state.gd`
   - key/gate helper extraction only
   - state fields must remain owner-local
10. `map_runtime_traversal_mutator.gd`
    - highest-risk helper-only extraction before owner split
    - should not become a second stateful runtime owner
11. `map_pending_context.gd`
    - technically movable, but payoff is low and semantic coupling is high
12. `map_hamlet_side_quest_runtime.gd`
    - do last, only with explicit escalation and contract review

## Recommended First Wave

If this file is ever extracted under explicit approval, the safest first wave is:

1. `map_scatter_topology_builder.gd`
2. `map_scatter_family_assigner.gd`
3. `map_scatter_role_planner.gd`
4. `map_scatter_graph_validator.gd`
5. `map_graph_legacy_loader.gd`

Expected result:

- large line-count drop
- no save-shape change
- no public owner change
- `MapRuntimeState` remains orchestration + truth owner while pure graph math leaves the file

## Explicit Do-Not-Start Zones Without Escalation

- `load_from_save_dict` / `to_save_dict` semantics
- public truth-mutating API movement as a set
- hamlet side-quest runtime truth
- support revisit truth ownership
- stage key / boss gate ownership split
- pending node truth split

## Suggested Guarded Follow-Up Order

1. extract pure scatter topology
2. extract pure scatter family placement
3. extract scatter validation/payload helpers
4. re-measure file size and hot paths
5. only then reconsider persistence/support/hamlet blocks with a new explicit risk review
