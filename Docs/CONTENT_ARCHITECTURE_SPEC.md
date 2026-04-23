# SIMPLE RPG - Content Architecture Specification

## Purpose

This file defines the canonical format and current truth boundaries for gameplay content.

## Core Principle

Most new content should be added by new data, not new special-case code.

## Status Note

- This spec distinguishes between `supported now` and `reserved later`.
- `Supported now` means the current prototype runtime, validator, and canonical content all agree.
- `Reserved later` means the field or pattern may remain part of the target architecture, but current runtime should not be treated as if it supports it.

## Content Growth Discipline

- Most future growth should come from new content data inside the current grammar.
- Adding new `Weapons`, `Shields`, `Armors`, `Belts`, `Consumables`, `PassiveItems`, `ShieldAttachments`, `CharacterPerks`, `Rewards`, `EventTemplates`, and `Enemies` inside the current grammar should be relatively easy.
- The current starter run loadout and current merchant stock slices are now content-backed through narrow dedicated families, not hardcoded runtime tables.
- Broader support-table growth still is not a generic runtime surface; widening it requires explicit implementation work.
- Adding a new resource axis, slot type, combat verb, currency, node family, trigger matrix, or progression track is not routine content work and requires explicit contract review.

## Canonical Format

- Canonical gameplay content lives in `JSON`
- Path: `ContentDefinitions/<family>/<stable_id>.json`
- One definition per file
- One stable ID per file

## Supported Families

- `Weapons`
- `Shields`
- `Armors`
- `Belts`
- `Consumables`
- `PassiveItems`
- `QuestItems`
- `ShieldAttachments`
- `CharacterPerks`
- `Enemies`
- `Statuses`
- `Effects`
- `Rewards`
- `RouteConditions`
- `EventTemplates`
- `RunLoadouts`
- `MerchantStocks`
- `MapTemplates`
- `SideMissions`

Supported family does not mean full runtime support already exists for that family.
Families currently without authored content: Effects, RouteConditions.
`EventTemplates` is now a narrow runtime-backed canonical family:
- the current prototype places runtime-backed `event` map nodes through the procedural map v1 scaffolds
- the current runtime resolves `EventTemplates` into the dedicated `Event` flow only
- the current event surface stays fixed at 2 authored choices and the exact v1 outcome list documented below

## Required Top-Level Fields

- `schema_version`
- `definition_id`
- `family`
- `tags`
- `display`
- `rules`

## Family-Specific Required Fields

### Ordered Runtime Families

The current prototype has two runtime surfaces where authored definition order is gameplay-relevant:
- normal combat enemy rotation
- level-up perk offer windows

`authoring_order` rules:
- top-level integer field
- required for every `Enemies` definition
- required for every `CharacterPerks` definition
- must not be added to other families as stray ordering metadata
- must be a positive integer
- must be unique within its family
- purpose:
  - locks deterministic authored order without depending on file-name sort
  - `Enemies.authoring_order` remains the canonical base order for stage-tagged minor-enemy pools even when live combat setup applies a deterministic run-seeded stage offset before node-index mapping
  - is not a display sort hint or UI label

### RunLoadouts

The current prototype uses one authored starter run loadout for new-run inventory setup.

`RunLoadouts` rules:
- supported explicit equipment keys:
  - `rules.right_hand_definition_id`
  - optional `rules.left_hand_definition_id`
  - optional `rules.armor_definition_id`
  - optional `rules.belt_definition_id`
- at least one explicit equipment key must be present
- equipment keys reference their canonical family:
  - `right_hand_definition_id` -> `Weapons/`
  - `left_hand_definition_id` -> `Weapons/` or `Shields/`
  - `armor_definition_id` -> `Armors/`
  - `belt_definition_id` -> `Belts/`
- `rules.backpack_items`
  - required array
  - each entry requires:
    - `inventory_family`
    - `definition_id`
  - `inventory_family` currently supports:
    - `weapon`
    - `shield`
    - `armor`
    - `belt`
    - `consumable`
    - `passive`
    - `quest_item`
    - `shield_attachment`
  - consumable entries also require positive integer `current_stack`
- current status:
  - runtime-backed for explicit starter equipment plus starter backpack contents
  - equipment slots are no longer inferred from a shared-bag baseline

### MerchantStocks

The current prototype uses deterministic stage-local authored merchant stock definitions for merchant-node offer generation.

`MerchantStocks` rules:
- `rules.stock`
  - required non-empty array
  - array order is the current runtime offer order
  - each entry requires:
    - `offer_id`
    - `definition_id`
    - `effect_type`
    - `cost_gold`
- current supported `effect_type` values:
  - `buy_consumable`
    - requires positive integer `amount`
    - `definition_id` references `Consumables/`
  - `buy_weapon`
    - does not use `amount`
    - `definition_id` references `Weapons/`
  - `buy_shield`
    - does not use `amount`
    - `definition_id` references `Shields/`
  - `buy_armor`
    - does not use `amount`
    - `definition_id` references `Armors/`
  - `buy_belt`
    - does not use `amount`
    - `definition_id` references `Belts/`
  - `buy_passive_item`
    - does not use `amount`
    - `definition_id` references `PassiveItems/`
- current status:
  - runtime-backed only for the merchant-node stock slice
  - current runtime chooses one authored stock from the current stage-local pool using deterministic run-seeded selection over `RunState.stage_index` plus source node id
  - labels remain derived from referenced item definitions
  - current live stage-local stock pools currently include:
    - stage `1`: `basic_merchant_stock`, `stage_1_merchant_stock_roadpack`, `stage_1_merchant_stock_scout`
    - stage `2`: `stage_2_merchant_stock`, `stage_2_merchant_stock_kit`, `stage_2_merchant_stock_forgegear`
    - stage `3`: `stage_3_merchant_stock`, `stage_3_merchant_stock_bulwark`, `stage_3_merchant_stock_convoy`
  - generic weighted shop generation or broader support-table routing remains deferred

### EventTemplates

The current prototype uses authored event templates for the dedicated `Event` flow.

`EventTemplates` rules:
- tags must carry exactly one source-role discriminator:
  - `event` for planned map-node templates
  - `roadside` for movement-triggered interruption templates
- optional `rules.trigger_condition`
  - current runtime-backed use is roadside-only eligibility filtering for roadside-tagged templates
  - planned map-event templates must not use `trigger_condition` as dead metadata
  - current supported stat names:
    - `hunger`
    - `hp_percent`
    - `gold`
  - current supported operators stay inside the existing condition grammar
- `rules.choices`
  - required array with exactly `2` entries
  - each entry requires:
    - `choice_id`
    - `label`
    - `summary`
    - `effect_type`
- current supported `effect_type` values:
  - `grant_gold`
    - requires positive integer `amount`
  - `grant_xp`
    - requires positive integer `amount`
  - `grant_item`
    - requires:
      - `inventory_family`
      - `definition_id`
    - current supported `inventory_family` values:
      - `consumable`
      - `weapon`
      - `shield`
      - `armor`
      - `belt`
      - `passive`
      - `shield_attachment`
    - consumable item grants may also include positive integer `amount`
  - `heal`
    - requires positive integer `amount`
  - `modify_hunger`
    - requires non-zero integer `amount`
  - `repair_weapon`
    - does not use `amount`
  - `damage_player`
    - requires positive integer `amount`
  - current status:
  - runtime-backed only for the dedicated `Event` flow slice
- current runtime uses that same flow for both planned map `event` nodes and movement-triggered roadside interruptions, distinguished by `EventState.source_context`
- current roadside selection may filter the roadside-tagged pool by optional `rules.trigger_condition` before deterministic seeded template selection
- template selection is currently deterministic run-seeded context selection over the filtered stable-id pool, while `selection_seed = 1` keeps the old stage-offset lane for compatibility-style tests/tools
- current repo still keeps `10` live `zz_*` `EventTemplates` stable IDs; treat them as intentional stable identifiers until an explicit approved stable-ID cleanup lands
- do not rename those `zz_*` IDs as routine filename cleanup
- item-grant event choices do not silently evict older backpack loot; when the chosen item would need a new slot, runtime opens a discard-or-leave prompt against the current backpack
- no generic multi-effect event matrix, weighted event table, or authored event-graph routing exists in the current truthful slice

### MapTemplates

The current prototype uses authored map-template files as stage-profile identifiers plus compatibility/reference data for stage-local exploration.

`MapTemplates` rules:
- `rules.nodes`
  - still supported in canonical content for legacy fixed templates and reference/profile data
  - current live runtime no longer treats authored `rules.nodes[*].adjacent_node_ids` as the active new-run graph source
  - each entry requires:
    - `node_id`
    - `adjacent_node_ids`
    - and either:
      - `node_family`
      - `slot_type`
- current supported `node_family` values:
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
- current supported `slot_type` values:
  - `opening_support`
  - `late_primary`
  - `late_event`
  - `late_hamlet`
- current status:
  - active runtime stage profiles are `procedural_stage_corridor_v1`, `procedural_stage_openfield_v1`, and `procedural_stage_loop_v1`
    - those checked-in files carry the `active_runtime_profile` tag
  - checked-in `procedural_stage_cluster_v1` and `procedural_stage_detour_v1` remain reference-only scaffold definitions; they are not active runtime/save profile ids
    - those checked-in files carry the `reference_only_scaffold` tag
  - `MapRuntimeState` still owns node discovery, resolution, locking, current position, and support-node revisit state
  - new-run graph topology is now generated inside `MapRuntimeState` through controlled scatter plus post-topology family placement, not by reading authored scaffold adjacency directly
  - current content files still carry the narrow scaffold/reference grammar and legacy fixed-template data, but exact realized graph restore now lives in save data
  - exact realized graph restore now lives in save data
  - legacy fixed templates remain in `MapTemplates/` only for backward-compatible schema-1 load reconstruction
    - those checked-in files carry the `legacy_load_compat` tag

### SideMissions

The current prototype uses authored side-quest definitions for hamlet contract-board detours and marked-objective requests.

`SideMissions` rules:
- `rules.mission_type`
  - required non-empty string
  - current supported values:
    - `hunt_marked_enemy`
    - `deliver_supplies`
    - `rescue_missing_scout`
    - `bring_proof`
- `rules.quest_item_definition_id`
  - required non-empty `QuestItems` definition for `deliver_supplies`
  - optional supported hook for `bring_proof`
- `rules.target_families`
  - optional non-empty array
  - current supported values:
    - `combat`
    - `event`
    - `reward`
    - `rest`
    - `merchant`
    - `blacksmith`
- required non-empty text fields:
  - `briefing_text`
  - `accept_label`
  - `accepted_text`
  - `reminder_label`
  - `completed_text`
  - `claimed_text`
  - `claimed_label`
- `rules.reward_pool`
  - required array with at least `2` entries
  - each entry requires:
    - `offer_id`
    - `effect_type`
  - current supported `effect_type` values:
    - `grant_gold`
      - requires positive integer `amount`
    - `grant_item`
      - requires:
        - `inventory_family`
        - `definition_id`
      - current supported `inventory_family` values:
        - `weapon`
        - `shield`
        - `armor`
        - `belt`
        - `passive`
        - `shield_attachment`
        - `consumable`
      - consumable item grants may also include positive integer `amount`
- current status:
  - runtime-backed only for the dedicated hamlet side-quest slice
  - current runtime chooses one authored request definition from the current stage-local pool using deterministic run-seeded selection over `RunState.stage_index` plus source node id
  - current runtime picks exactly `1` valid target node when the request is accepted
  - `hunt_marked_enemy` also picks exactly `1` enemy definition
  - current runtime presents exactly `2` reward offers from the authored reward pool when the contract is completed
  - current authored content now covers all four mission hooks with multiple stage-local request definitions
  - generic multi-step quest chains, multiple objectives, and non-gear contract rewards remain deferred

### Techniques (Live Prompt 27 Family)

- First-pass technique definitions now live as an authored content family under `ContentDefinitions/Techniques/*.json`.
- The current live definition set is:
  - `cleanse_pulse` using `remove_statuses` plus an authored small `guard_gain`
  - `sundering_strike` using `attack_ignore_armor`
  - `blood_draw` using `attack_lifesteal`
  - `echo_strike` using `prime_next_attack`
- Technique definitions must keep the normal stable-id rules:
  - file-name / `definition_id` match
  - separate `display` vs `rules`
  - no gameplay truth in presentation-only fields
- First-pass technique authoring stays narrow:
  - single-target combat use only
  - limited-use tactical effects only
  - no true multi-hit packets
  - no hand-slot swap dependency
  - no enemy-side status ownership
- Hamlet training delivery points at these stable technique definition ids with a narrow `2`-offer-plus-`skip` surface; it does not require a broader generic weighted training-pool family.
- Still deferred:
  - `stun`
  - dedicated trainer content families behind Prompt `31`
  - broader multi-technique loadout/buildcraft families

### Enemies

Enemy definitions require the standard top-level fields plus:
- `design_intent_question`

`design_intent_question` rules:
- top-level string field
- required for every `Enemies` definition
- human-readable design sentence
- purpose:
  - states what combat question the enemy is asking the player
  - exists for design review discipline, not for runtime resolution

Optional reserved enemy metadata:
- `encounter_tier`

`encounter_tier` rules:
- top-level string field if present
- allowed values:
  - `minor`
  - `elite`
- current status:
  - reserved metadata only
  - current prototype runtime ignores it for combat exit flow
  - current prototype stage-rotation selection still depends on stage tags plus authored order, not on a broader elite encounter lane
  - current prototype flow contract remains `Combat victory -> Reward`

## Naming Rules

- `definition_id` uses `lower_snake_case`
- display name is separate from stable ID
- logic never depends on display text

## Display vs Rules

`display` may contain:
- name
- short description
- icon key
- presentation labels

`rules` may contain:
- stats
- behaviors
- family-specific helper blocks

## Supported-Now Matrix

| Area | Supported now | Reserved later / not truthful yet |
|---|---|---|
| top-level schema | required top-level fields, family/path match, stable ID/file-name match, non-empty `display.name` | richer schema families and reference graphs |
| event content surface | `EventTemplates.rules.choices` with exactly 2 authored choices, deterministic stage-scoped template rotation, dedicated `Event` flow resolution, and the narrow event outcome list `grant_gold` / `grant_xp` / `grant_item` / `heal` / `modify_hunger` / `repair_weapon` / `damage_player` | weighted event pools, generic multi-effect events, authored event graph routing, or broader effect matrices |
| enemy metadata | `design_intent_question`, optional `encounter_tier` enum check | `encounter_tier`-driven flow behavior |
| enemy intent selection | first intent on setup, then sequential advance by index; boss-only optional `rules.boss_phases[*].intent_pool` with turn-end threshold swaps | weighted or authored-random intent selection |
| enemy `intent_pool` effects | `deal_damage`, narrow `apply_status` for combat-local player-status definitions using current DoT and supported stat-modifier keys | broader non-damage intent effects, buff/heal/status resolution beyond the current small player-status slice |
| behavior triggers in canonical runtime-backed content | `passive` on enemy, passive-item, armor, and shield-attachment definitions | generic trigger families such as `on_turn_start`, `on_turn_end`, `on_damage_taken`, `on_use`, `on_equip`, `on_break` |
| behavior effects in canonical runtime-backed content | `modify_stat` on passive enemy, passive-item, armor, and shield-attachment behaviors | `heal`, `apply_status`, `remove_status`, `reduce_durability`, `restore_durability`, generic multi-family effect routing |
| deterministic authored ordering | top-level `authoring_order` on `Enemies` and `CharacterPerks` for the current deterministic rotation/window surfaces | file-name sort or any implicit directory order affecting gameplay |
| run-start loadout | explicit `RunLoadouts.rules.<equipment slot>` entries plus `backpack_items` for the current starter baseline | broader authored perk start packages or a generic run-setup system |
| merchant stock | narrow `MerchantStocks.rules.stock` array with authored stage-indexed `buy_consumable` / `buy_weapon` / `buy_shield` / `buy_armor` / `buy_belt` / `buy_passive_item` entries | seeded shop generation, generic support-table families, or richer merchant effect types |
| map template topology | narrow `MapTemplates.rules.nodes` grammar retained for legacy fixed templates plus profile/reference data, while active bounded procedural generation now lives in `MapRuntimeState` and exact graph restore lives in save payload | broader authored graph libraries, free-form graph generation, or generic runtime-authored event-node placement |
| condition support | direct source/target dictionary comparisons with `always`, `eq`, `neq`, `gt`, `gte`, `lt`, `lte`, `has_tag`, `not_has_tag` | nested path lookups, global queries, broad computed-stat library |
| target semantics | authoring field may be present as `self` or `enemy` for current rule-block shape; first status slice implicitly targets the player from enemy intent | generic runtime target dispatch, `equipped_weapon`, arbitrary target routing |
| `random_roll_percent` | internal placeholder value injected as `100` by current combat flow | authored proc-chance contract, real RNG-driven combat authoring |
| `weight` | not supported for current canonical content | weighted intent selection |
| `use_effect` helper | `Consumables.rules.use_effect` with `trigger = on_use`, `target = self`, and `effects[*].type = heal` or `modify_hunger` for the current self-food slice | broader consumable effect families, multi-target use rules |
| status definitions | `Statuses.rules.stats.duration_turns`, `max_stacks`, plus either `damage_per_turn` or narrow `stat_modifiers` keys `attack_power_bonus` / `incoming_damage_flat_reduction` / `durability_cost_flat_reduction` / `skip_player_action` for the current combat-local player-status pool | generic status behavior blocks, broader modifier families, enemy-side status ownership, status-driven routing |
| boss phase authoring | boss-only optional `Enemies.rules.boss_phases[*]` with ordered threshold swaps and phase-local intent pools | phase-persistent save state, generic enemy phase graphs, or non-boss phase routing |
| reward generation from content | deterministic seeded reward generation through `Rewards.rules.offer_pool`, `present_count`, and `selection_mode = seeded_reward_rng` using the current reward effect types (`heal` / `repair_weapon` / `grant_xp` / `grant_gold` / `grant_item`) plus run-level `reward_rng` continuity, narrow `stage_min` / `stage_max` gating, and optional combat-victory `preferred_enemy_tags_any` tone bias | richer eligibility graphs and broader generic reward-pool routing |

## Current Runtime-Backed Combat Slice

Current canonical combat-backed content should stay inside this narrow slice:

- `Enemies.rules.intent_pool[*].effects[*]`
  - current supported effect types:
    - `deal_damage`
    - `apply_status` with `params.definition_id` pointing to a canonical `Statuses/` definition that matches the current combat-local player-status slice
- `Enemies.rules.boss_phases[*]`
  - current supported fields:
    - `phase_id`
    - `display_name`
    - optional `enter_at_or_below_percent` on later phases
    - `intent_pool`
  - current runtime truth:
    - phase `0` is active at combat start
    - later phases switch only during next-intent preparation at turn end
    - switching to a new phase resets intent rotation to that phase's first intent
- `Enemies.rules.behaviors[*]`
  - current supported trigger: `passive`
  - current supported effect type: `modify_stat`
  - current supported condition shape:
    - omit `condition`, or use `{"op": "always"}`
    - direct stat comparison object with supported operators
- `PassiveItems.rules.behaviors[*]`
  - current supported trigger: `passive`
  - current supported target: `self`
  - current supported effect type: `modify_stat`
  - current supported condition shape:
    - omit `condition`, or use `{"op": "always"}`
- `CharacterPerks.rules.perk_family`
  - current supported values:
    - `offense`
    - `defense`
    - `survival`
    - `economy_route`
- `CharacterPerks.rules.behaviors[*]`
  - current supported trigger: `passive`
  - current supported target: `self`
  - current supported effect type: `modify_stat`
  - current supported condition shape:
    - omit `condition`, or use `{"op": "always"}`
- `Armors.rules.behaviors[*]`
  - current supported trigger: `passive`
  - current supported target: `self`
  - current supported effect type: `modify_stat`
  - current supported condition shape:
    - omit `condition`, or use `{"op": "always"}`
- `Belts.rules.backpack_capacity_bonus`
  - required positive integer
  - current runtime truth:
    - belts are backpack-utility equipment, not a combat-stat behavior surface
- `ShieldAttachments.rules`
  - current supported fields:
    - `attachment_target = shield`
    - `max_per_shield = 1`
    - `behaviors[*]` using the same passive self-target `modify_stat` slice as armor/passive content
  - current runtime truth:
    - detached attachments are backpack items
    - attached attachments live as `attachment_definition_id` on shield slot state
    - only shields support attachments in V1
- `Weapons.rules.slot_compatibility`
  - current supported keys:
    - `right_hand`
    - `left_hand`
    - `offhand_capable`
  - current runtime truth:
    - all live weapons must stay right-hand compatible
    - `left_hand` / `offhand_capable` enable live offhand-weapon equip compatibility
    - offhand weapons feed the current dual-wield modifier surface, not a second independent attack engine
- `Weapons.rules.stats.durability_profile`
  - current supported values:
    - `sturdy`
    - `standard`
    - `fragile`
    - `heavy`
  - current runtime truth:
    - this field multiplies `durability_cost_per_attack`
    - the current live multipliers are `0.5x / 1x / 1.5x / 2x`
    - profile scaling stays inside the narrow durability-cost calculation; it does not add a new combat verb or effect family
- weapon and enemy `rules.stats`
  - current runtime reads basic numeric combat stats from this block
- `Consumables.rules.use_effect`
  - current supported trigger: `on_use`
  - current supported target: `self`
  - current supported effect types:
    - `heal`
    - `modify_hunger`
    - `repair_weapon`
  - current supported condition shape:
    - omit `condition`, or use `{"op": "always"}`
- `Statuses.rules.stats`
  - current supported keys:
    - `duration_turns`
    - `max_stacks`
    - `damage_per_turn`
    - `stat_modifiers.attack_power_bonus`
    - `stat_modifiers.incoming_damage_flat_reduction`
    - `stat_modifiers.durability_cost_flat_reduction`
    - `stat_modifiers.skip_player_action`
  - current canonical runtime-backed status definitions:
    - `poison`
    - `bleed`
    - `weakened`
    - `fortified`
    - `enraged`
    - `stunned`
    - `corroded`
- `Rewards.rules.offers`
  - current supported deterministic pool fields:
    - `selection_mode = seeded_reward_rng`
    - `present_count`
    - `offer_pool`
  - current supported offer fields inside `offers` / `offer_pool`:
    - `offer_id`
    - `label`
    - `effect_type`
    - `amount` for numeric reward effects and consumable item grants
    - `inventory_family` for item grants
    - `definition_id` for item grants
    - optional `stage_min` / `stage_max`
    - optional `preferred_enemy_tags_any`
  - current supported reward effect types:
    - `heal`
    - `repair_weapon`
    - `grant_xp`
    - `grant_gold`
    - `grant_item`
  - current canonical runtime-backed reward definitions:
    - `combat_victory`
    - `reward_node`
- `EventTemplates.rules.choices`
  - current supported fields:
    - `choice_id`
    - `label`
    - `summary`
    - `effect_type`
    - `amount` for numeric event outcomes and consumable item grants
    - `inventory_family` for item grants
    - `definition_id` for item grants
  - current supported event effect types:
    - `grant_gold`
    - `grant_xp`
    - `grant_item`
    - `heal`
    - `modify_hunger`
    - `repair_weapon`
    - `damage_player`
  - current canonical runtime-backed event definitions:
    - `forest_shrine_echo`
    - `ghost_lantern_bargain`
    - `moss_waystone_tithe`
    - `trickster_stump_feast`
    - `wrenched_supply_cart`

## Condition and State Lookup Truth

- Current resolver only reads direct keys from the provided `source_state` and `target_state` dictionaries.
- It does not support:
  - nested paths
  - object traversal
  - global lookups
  - generic computed stat registries
- Current authored content should therefore avoid pretending that rich query syntax already exists.

`random_roll_percent` note:
- the current combat flow injects `random_roll_percent = 100` into `player_state`
- this is an implementation placeholder, not a stable authoring contract
- current canonical content should not rely on authored proc-chance behavior yet

## Intent Selection Truth

- `intent_pool` defines possible intents.
- Current runtime:
  - takes the first intent on combat setup
  - rotates enemy definitions by explicit top-level `authoring_order`, not by file-name sort
  - advances by sequential index each turn
- Current Pack A enemy patterns stay inside that slice:
  - `light -> heavy`
  - `status pressure -> punish`
  - `greed / resource punish`
  - boss-only phase spike through `rules.boss_phases[*].intent_pool`
- Current readable examples include `mossback_ram`, `skeletal_hound`, `dusk_pikeman`, `ashen_sapper`, `chain_trapper`, `grave_chanter`, and `tollhouse_captain`.
- `weight` is intentionally not part of the current truthful content surface.

## Build Engine Scope

- The current intended build engine is intentionally narrow.
- Current carried inventory capacity stays intentionally small:
  - base backpack: `5`
  - equipped belt bonus comes from authored `Belts.rules.backpack_capacity_bonus`
- Level-up character perks do not consume backpack space.
- Current level-up perk offer generation reads `CharacterPerks.authoring_order` for deterministic authored windows.
- Passive items remain backpack-carried bonuses and are not the canonical progression track.
- Build identity should mostly come from equipment direction, `1-2` perk synergies, passive backpack support, and consumable/resource planning.
- Intended synergies should stay small and linear.
- Build variety should come from strong content combinations inside the current grammar, not from expanding that grammar.

## Reserved / Deferred Patterns

These remain part of target architecture direction, but not current runtime truth:

- weighted intent selection via `weight`
- true multi-hit or chained hit packets
- authored chance procs via `random_roll_percent`
- consumable `use_effect` resolution beyond self-target `heal` + `modify_hunger`
- generic status-tick or routing runtime beyond the current small player-status pool
- enemy self-buff / self-guard / armor-up runtime
- enemy-side status ownership
- generic target routing
- generic trigger/effect matrix across all families
- weighted reward generation through `Rewards`
- weighted or tag-driven event template selection
- generic multi-effect event resolution beyond the current 2-choice / 1-outcome-per-choice slice

## Advanced Enemy Intent Expansion Target (Prompt 30, Not Live Yet)

This section records the approved content-grammar target for later advanced enemy-intent work.
It is not current live content truth yet.

- Advanced enemy intents require a grammar expansion under `Enemies.rules.intent_pool[*]`; they are not a content-only extension of the current Pack A slice.
- Intended new top-level per-intent metadata for advanced entries:
  - `intent_family`
    - allowed advanced values:
      - `setup_pass`
      - `multi_hit`
      - `self_state`
      - `enemy_status`
  - `telegraph_family`
    - explicit player-facing telegraph bucket for presenter/UI treatment
  - optional `telegraph_tags`
    - narrow authored tags that describe the threat read without moving gameplay truth into UI
- Intended advanced effect-family expansion for `Enemies.rules.intent_pool[*].effects[*]`:
  - `prepare_followup`
    - target: `enemy_self`
    - required params:
      - `prepared_intent_id`
      - `expires_after_turns`
  - `deal_damage_packets`
    - target: `player`
    - required params:
      - `packets`
    - each packet is an authored ordered hit entry, not a weighted branch
  - `gain_enemy_guard`
    - target: `enemy_self`
    - required params:
      - `amount`
  - `modify_enemy_stat`
    - target: `enemy_self`
    - required params:
      - `stat_key`
      - `amount`
      - `duration_turns`
    - intended first-pass keys:
      - `attack_power_bonus`
      - `incoming_damage_flat_reduction`
  - `apply_enemy_status`
    - target: `enemy_self`
    - required params:
      - `definition_id`
  - `remove_enemy_status`
    - target: `enemy_self`
    - required params:
      - `definition_id`
- Intended routing stays narrow even after this expansion:
  - supported targets remain only `player` and `enemy_self`
  - no ally routing
  - no random target selection
  - no route-wide or party-wide targeting
- Intended enemy-side status expansion is explicit:
  - later implementation should use a dedicated authored family under `ContentDefinitions/EnemyStatuses/`
  - do not silently overload the current player-owned `Statuses/` slice and pretend both owners already share one canonical family
- Intended multi-hit scope stays narrow:
  - ordered packets only
  - no weighted packet routing
  - no packet-level random target dispatch
  - no hidden extra-hit math outside authored packets
- Intended setup/pass scope stays narrow:
  - at most `1` prepared follow-up payload may be armed on the enemy at a time
  - preparation and follow-up expiry must be explicit in authored data
  - preparing a follow-up is not the same as opening generic trigger routing
- Intended self-state scope stays narrow:
  - enemy guard / armor-up / temporary attack-up are the first explicit self-state targets
  - this does not approve generic enemy heal, cleanse, or summon behavior
- Intended enemy-status scope stays narrow:
  - enemy-owned statuses are still deterministic authored state, not generic proc-web authoring
  - introducing enemy-owned statuses does not approve generic status-to-status routing or weighted behavior graphs

## Design-Rejected Growth Directions

- exponential combo scaling
- broad trigger web expansion
- second build-family explosion
- solving content problems by opening a new generic mechanic surface

## Example Reference

Runtime-aligned examples:
- `ContentDefinitions/Weapons/iron_sword.json`
- `ContentDefinitions/Enemies/bone_raider.json`
- `ContentDefinitions/Enemies/barbed_hunter.json`
- `ContentDefinitions/Enemies/drain_adept.json`
- `ContentDefinitions/Enemies/venom_scavenger.json`
- `ContentDefinitions/Consumables/minor_heal_potion.json`
- `ContentDefinitions/Consumables/wild_berries.json`
- `ContentDefinitions/Consumables/traveler_bread.json`
- `ContentDefinitions/Consumables/cured_meat.json`
- `ContentDefinitions/RunLoadouts/starter_loadout.json`
- `ContentDefinitions/MerchantStocks/basic_merchant_stock.json`
- `ContentDefinitions/MerchantStocks/stage_1_merchant_stock_roadpack.json`
- `ContentDefinitions/MerchantStocks/stage_1_merchant_stock_scout.json`
- `ContentDefinitions/MerchantStocks/stage_2_merchant_stock.json`
- `ContentDefinitions/MerchantStocks/stage_2_merchant_stock_kit.json`
- `ContentDefinitions/MerchantStocks/stage_2_merchant_stock_forgegear.json`
- `ContentDefinitions/MerchantStocks/stage_3_merchant_stock.json`
- `ContentDefinitions/MerchantStocks/stage_3_merchant_stock_bulwark.json`
- `ContentDefinitions/MerchantStocks/stage_3_merchant_stock_convoy.json`
- `ContentDefinitions/MapTemplates/procedural_stage_corridor_v1.json`
- `ContentDefinitions/MapTemplates/procedural_stage_openfield_v1.json`
- `ContentDefinitions/MapTemplates/procedural_stage_loop_v1.json`
- `ContentDefinitions/MapTemplates/fixed_stage_cluster.json` (legacy load compatibility)
- `ContentDefinitions/MapTemplates/fixed_stage_detour.json` (legacy load compatibility)
- `ContentDefinitions/Statuses/poison.json`
- `ContentDefinitions/Statuses/bleed.json`
- `ContentDefinitions/Statuses/weakened.json`
- `ContentDefinitions/Rewards/combat_victory.json`
- `ContentDefinitions/Rewards/reward_node.json`
- `ContentDefinitions/EventTemplates/forest_shrine_echo.json`
- `ContentDefinitions/EventTemplates/ghost_lantern_bargain.json`
- `ContentDefinitions/EventTemplates/moss_waystone_tithe.json`
- `ContentDefinitions/EventTemplates/trickster_stump_feast.json`
- `ContentDefinitions/EventTemplates/zz_ash_tree_ledger.json`
- `ContentDefinitions/EventTemplates/zz_dry_well_cache.json`
- `ContentDefinitions/EventTemplates/zz_watch_post_embers.json`
- `ContentDefinitions/EventTemplates/zz_barrow_crows.json`
- `ContentDefinitions/EventTemplates/zz_split_axle_verge.json`
- `ContentDefinitions/EventTemplates/zz_sunken_toll_fire.json`

Reference-only forward examples:
- none currently

Reference-only forward examples may show reserved-later schema direction.
They are not evidence that the current runtime already supports those patterns.

## Definition vs Instance

Definitions do not contain:
- current HP
- current durability
- current forge tier or `upgrade_level`
- active stacks
- current intent
- current owner slot

Those belong to runtime state.

## Tag Policy

- tags are controlled vocabulary
- tags are not a substitute for real mechanics
- tags should stay finite and reviewable
- current validator does not yet enforce a full tag vocabulary list

## Validation Expectations

Current validator actively checks:
- duplicate ID
- family/path mismatch
- stable ID/file-name mismatch
- stray `authoring_order` outside the ordered runtime families
- required top-level fields
- `display.name`
- enemy `design_intent_question`
- optional `encounter_tier` enum
- reserved current-content fields such as `weight`
- current enemy rule-block shape for the prototype combat slice
- current narrow `apply_status(<dot_status_id>)` intent-effect shape
- current consumable `use_effect` shape for the prototype self-target heal/hunger slice
- current passive-item and character-perk rule-block shape for the prototype progression slice
- current explicit `RunLoadouts.rules.<equipment slot>` plus `backpack_items` shape for starter inventory setup
- current `MerchantStocks.rules.stock` shape for fixed merchant-node offer generation
- current `EventTemplates.rules.choices` shape for the dedicated event-node slice plus roadside-only `trigger_condition`
- current `EventTemplates` source-role tag split between planned `event` templates and `roadside` interruption templates
- current `SideMissions.rules.reward_pool` shape for hamlet contract payouts
- current `MapTemplates.rules.nodes` and slot metadata shape for stage-profile/reference data plus legacy fixed-template compatibility, including the dedicated `late_event` slot
- current `MapTemplates` role-tag split between `active_runtime_profile`, `reference_only_scaffold`, and `legacy_load_compat`
- current `Statuses.rules.stats` shape for the combat-local mixed DoT/debuff pool
- current `Rewards.rules.offer_pool` / `present_count` / `selection_mode` shape for deterministic reward generation, including narrow `stage_min` / `stage_max` gating and `preferred_enemy_tags_any` arrays

Current validator does not yet fully validate:
- global tag vocabulary
- broad cross-family content references
- full generic trigger/effect/target support across all families
- reward/content-generation graphs
