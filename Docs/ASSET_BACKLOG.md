# SIMPLE RPG - Asset Backlog

## Purpose

This file keeps the first-pass, later, and deferred visual/audio backlog for the playable slice.

This is a planning file, not a source-of-truth contract.
Use it to decide what to build next, not to redefine style, licensing, or runtime ownership.

## First Pass Must-Haves

Prototype simplification rule:
- stop at the smallest set that supports a readable playable slice

### UI Screens

- `main_menu`
- `map_explore`
- `combat`
- `reward`
- `level_up`
- `support_interaction`

### Reusable UI Floor

- `panel_base`
- `button`
- `badge`
- `resource_bar`
- `item_slot`
- `choice_card`
- `node_state_marker`
- `key_marker`
- `boss_gate_marker`

### Icons

Target size:
- `15-20` total icons

Minimum set:
- `attack`
- `defend`
- `use_item`
- `weapon`
- `armor`
- `consumable`
- `reward`
- `hp`
- `hunger`
- `durability`
- `enemy_intent_attack`
- `enemy_intent_heavy`
- `confirm`
- `cancel`
- `node_marker`

### Characters And Enemies

- `1` player bust
- `2` enemy busts
- `1` boss placeholder bust
- one token for each of the above

### Background And Map Shell

- `main_menu_background`
- `map_background`
- `combat_background`
- `reward_overlay`
- `fog_overlay`
- `cluster_map_shell`

### Feedback And Motion

- `button_bounce`
- `hit_flash`
- `intent_reveal`
- `panel_open`
- `panel_close`
- `small_screen_shake`

### SFX Floor

- `ui_click`
- `ui_confirm`
- `ui_cancel`
- `combat_hit_light`
- `defend`
- `item_use`
- `reward_pickup`
- `node_select`

### Music Floor

- `map_loop`
- `combat_loop`

## Soon After First Pass

- `inventory_equipment_overlay`
- second biome variation
- additional enemy variants
- support-specific flavor visuals
- reward and level-up polish pass

## Deferred

- logo
- store icon or capsule art
- trailer assets
- promotional images
- full soundtrack
- advanced animation polish
- marketing kit

## Component Build Order

1. global components
2. combat shell
3. map shell
4. reward and level-up cards
5. support shell
6. inventory overlay only if the playable slice proves it is needed

## Audio Event Floor

### UI

- primary button press -> `ui_confirm`
- secondary or cancel action -> `ui_cancel`
- hover or focus move -> `ui_click` or lighter variant
- panel open/close -> `panel_open` / `panel_close`

### Map

- node selected -> `node_select`
- route confirmed -> `ui_confirm` or `node_select` variation

### Combat

- attack resolved -> `combat_hit_light`
- defend resolved -> `defend`
- item used -> `item_use`
- intent reveal -> short `intent_reveal` cue if needed

### Reward And Progression

- reward claimed -> `reward_pickup`
- level-up reveal -> short sting
- run end -> reward or fail cue depending on outcome

## Two Week Focus

Days 1-4:
- repo UI component floor
- combat, map, reward, and support shells

Days 5-8:
- icon sourcing and cleanup
- player/enemy bust first pass
- tokens

Days 9-12:
- one biome background family
- SFX base set
- two temporary music loops

Days 13-14:
- Godot import
- manifest review
- readability validation
