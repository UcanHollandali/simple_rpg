# Semantic Icon Readiness Checklist

## Status

- Reference-only checkpoint for Prompt 12.
- This document does not approve assets, does not hook assets into runtime, and does not change `UiAssetPaths`.
- File presence is not approval.
- Runtime adoption remains blocked until manifest, provenance/license review, and human visual review all pass per `Docs/ASSET_PIPELINE.md` and `Docs/ASSET_LICENSE_POLICY.md`.

## Status Key

- `READY_NOW`: the current runtime contract already supports an in-place replacement at a stable filename; normal manifest/provenance/human-review gates still apply.
- `PARTIAL`: some runtime support already exists, but broader family adoption still needs additional runtime selection/path work or wider file coverage.
- `BLOCKED`: the expected semantic surface is not runtime-ready yet because the target file, manifest row, or runtime path surface is missing.

## Tier 1 - Node Identity Icon Completion

| target surface | expected runtime filename pattern | current repo fallback | current runtime owner/path surface | UiAssetPaths change required: yes/no | manifest row required: yes | provenance/license review required: yes | human visual review required: yes | ready now / blocked / partial | blocking reason |
|---|---|---|---|---|---|---|---|---|---|
| combat node identity icon | `Assets/Icons/icon_map_combat.svg` | `Assets/Icons/icon_attack.svg` via `UiAssetPaths.ATTACK_ICON_TEXTURE_PATH` | `Game/UI/map_explore_presenter.gd`, `Game/UI/map_board_composer_v2.gd`, `Game/UI/transition_shell_presenter.gd`, `Game/UI/ui_asset_paths.gd` | yes | yes | yes | yes | `BLOCKED` | Target runtime file is missing, no manifest row exists, and current map combat identity is still owned by the generic combat attack path. |
| key node identity icon | `Assets/Icons/icon_map_key.svg` | `Assets/Icons/icon_confirm.svg` via `UiAssetPaths.KEY_ICON_TEXTURE_PATH` | `Game/UI/map_explore_presenter.gd`, `Game/UI/map_board_composer_v2.gd`, `Game/UI/transition_shell_presenter.gd`, `Game/UI/ui_asset_paths.gd` | yes | yes | yes | yes | `BLOCKED` | Target runtime file is missing, no manifest row exists, and the live key node still resolves through the generic confirm path. |
| boss node identity icon | `Assets/Icons/icon_map_boss.svg` | `Assets/Icons/icon_enemy_intent_heavy.svg` via `UiAssetPaths.BOSS_ICON_TEXTURE_PATH` | `Game/UI/map_explore_presenter.gd`, `Game/UI/map_board_composer_v2.gd`, `Game/UI/transition_shell_presenter.gd`, `Game/UI/ui_asset_paths.gd` | yes | yes | yes | yes | `BLOCKED` | Target runtime file is missing, no manifest row exists, and the live boss node still resolves through the combat heavy-intent path. |

## Tier 2 - Optional Node Props And Landmark Emphasis

| target surface | expected runtime filename pattern | current repo fallback | current runtime owner/path surface | UiAssetPaths change required: yes/no | manifest row required: yes | provenance/license review required: yes | human visual review required: yes | ready now / blocked / partial | blocking reason |
|---|---|---|---|---|---|---|---|---|---|
| rest camp prop | `Assets/UI/Map/Props/ui_map_prop_rest_camp.svg` | procedural clearing plus `Assets/Icons/icon_map_rest.svg` | No dedicated prop owner; map node identity currently resolves through `Game/UI/map_explore_presenter.gd`, `Game/UI/map_board_composer_v2.gd`, and `Game/UI/ui_asset_paths.gd` | yes | yes | yes | yes | `BLOCKED` | Target prop file is missing, no manifest row exists, and there is no current shared runtime prop path owner for this family. |
| merchant stall prop | `Assets/UI/Map/Props/ui_map_prop_merchant_stall.svg` | procedural clearing plus `Assets/Icons/icon_map_merchant.svg` | No dedicated prop owner; map node identity currently resolves through `Game/UI/map_explore_presenter.gd`, `Game/UI/map_board_composer_v2.gd`, and `Game/UI/ui_asset_paths.gd` | yes | yes | yes | yes | `BLOCKED` | Target prop file is missing, no manifest row exists, and there is no current shared runtime prop path owner for this family. |
| blacksmith anvil prop | `Assets/UI/Map/Props/ui_map_prop_blacksmith_anvil.svg` | procedural clearing plus `Assets/Icons/icon_map_blacksmith.svg` | No dedicated prop owner; map node identity currently resolves through `Game/UI/map_explore_presenter.gd`, `Game/UI/map_board_composer_v2.gd`, and `Game/UI/ui_asset_paths.gd` | yes | yes | yes | yes | `BLOCKED` | Target prop file is missing, no manifest row exists, and there is no current shared runtime prop path owner for this family. |
| boss gate marker or sword altar prop | `Assets/UI/Map/Landmarks/ui_map_landmark_boss_gate.svg` or `Assets/UI/Map/Landmarks/ui_map_landmark_sword_altar.svg` | boss icon plus procedural pocket | No dedicated landmark owner; boss nodes currently resolve through generic icon ownership in `Game/UI/map_explore_presenter.gd`, `Game/UI/map_board_composer_v2.gd`, and `Game/UI/ui_asset_paths.gd` | yes | yes | yes | yes | `BLOCKED` | Both target landmark files are missing, no manifest rows exist, and there is no current shared runtime landmark path owner. |
| optional key shrine prop | `Assets/UI/Map/Landmarks/ui_map_landmark_key_shrine.svg` | key icon plus procedural pocket | No dedicated landmark owner; key nodes currently resolve through generic icon ownership in `Game/UI/map_explore_presenter.gd`, `Game/UI/map_board_composer_v2.gd`, and `Game/UI/ui_asset_paths.gd` | yes | yes | yes | yes | `BLOCKED` | Target landmark file is missing, no manifest row exists, and there is no current shared runtime landmark path owner. |
| optional start lantern shrine prop | `Assets/UI/Map/Landmarks/ui_map_landmark_start_lantern_shrine.svg` | `Assets/Icons/icon_map_start.svg` plus procedural center pocket | No dedicated landmark owner; start nodes currently resolve through `Game/UI/map_explore_presenter.gd`, `Game/UI/map_board_composer_v2.gd`, and `Game/UI/ui_asset_paths.gd` | yes | yes | yes | yes | `BLOCKED` | Target landmark file is missing, no manifest row exists, and there is no current shared runtime landmark path owner. |
| optional event question box prop | `Assets/UI/Map/Props/ui_map_prop_event_question_box.svg` | `Assets/Icons/icon_map_trail_event.svg` plus procedural pocket | No dedicated prop owner; event nodes currently resolve through `Game/UI/map_explore_presenter.gd`, `Game/UI/map_board_composer_v2.gd`, and `Game/UI/ui_asset_paths.gd` | yes | yes | yes | yes | `BLOCKED` | Target prop file is missing, no manifest row exists, and there is no current shared runtime prop path owner for this family. |
| optional reward chest prop | `Assets/UI/Map/Props/ui_map_prop_reward_chest.svg` | `Assets/Icons/icon_reward.svg` plus procedural pocket | No dedicated prop owner; reward nodes currently resolve through `Game/UI/map_explore_presenter.gd`, `Game/UI/map_board_composer_v2.gd`, and `Game/UI/ui_asset_paths.gd` | yes | yes | yes | yes | `BLOCKED` | Target prop file is missing, no manifest row exists, and there is no current shared runtime prop path owner for this family. |

## Tier 3 - Item And Character Extensions

| target surface | expected runtime filename pattern | current repo fallback | current runtime owner/path surface | UiAssetPaths change required: yes/no | manifest row required: yes | provenance/license review required: yes | human visual review required: yes | ready now / blocked / partial | blocking reason |
|---|---|---|---|---|---|---|---|---|---|
| weapons, shields, armor, belts | `Assets/Icons/icon_weapon_<theme>.svg`, `Assets/Icons/icon_shield_<theme>.svg`, `Assets/Icons/icon_armor_<theme>.svg`, `Assets/Icons/icon_belt_<theme>.svg` | generic family fallbacks already ship as `Assets/Icons/icon_weapon.svg`, `Assets/Icons/icon_shield.svg`, `Assets/Icons/icon_armor.svg`, `Assets/Icons/icon_belt.svg` | `Game/UI/inventory_presenter.gd` and `Game/UI/ui_asset_paths.gd` | no for in-place replacement of the current generic family slots | yes | yes | yes | `PARTIAL` | Generic runtime slots and manifest-backed fallbacks already exist, but no themed `<theme>` runtime files or manifest rows exist and multiple semantic variants would need selector logic or new path constants. |
| consumables, passives, quest items | `Assets/Icons/icon_consumable_<theme>.svg`, `Assets/Icons/icon_passive_<theme>.svg`, `Assets/Icons/icon_quest_item_<theme>.svg` | generic family fallbacks already ship as `Assets/Icons/icon_consumable.svg`, `Assets/Icons/icon_passive.svg`, `Assets/Icons/icon_quest_item.svg` | `Game/UI/inventory_presenter.gd` and `Game/UI/ui_asset_paths.gd` | no for in-place replacement of the current generic family slots | yes | yes | yes | `PARTIAL` | Generic runtime slots and manifest-backed fallbacks already exist, but no themed `<theme>` runtime files or manifest rows exist and multiple semantic variants would need selector logic or new path constants. |
| shield attachments | `Assets/Icons/icon_shield_attachment_<theme>.svg` | generic family fallback already ships as `Assets/Icons/icon_shield_attachment.svg` | `Game/UI/inventory_presenter.gd` and `Game/UI/ui_asset_paths.gd` | no for in-place replacement of the current generic family slot | yes | yes | yes | `PARTIAL` | The generic runtime slot and manifest-backed fallback already exist, but no themed `<theme>` runtime files or manifest rows exist and multiple semantic variants would need selector logic or new path constants. |
| enemy busts | `Assets/Enemies/enemy_<definition_id>_bust.png` | runtime already resolves stable bust paths plus specific fallback mappings where a definition is missing | `Game/UI/combat_presenter.gd` and `Game/UI/ui_asset_paths.gd` via `build_enemy_bust_texture_path(...)` | no | yes | yes | yes | `READY_NOW` | No contract blocker for in-place `enemy_<definition_id>_bust.png` adoption; each new bust still needs its own manifest row, provenance review, and human visual review. |
| enemy tokens | `Assets/Enemies/enemy_<definition_id>_token.png` | partial runtime support through stable token path building; current repo ships only a small token subset | `Game/UI/combat_presenter.gd` and `Game/UI/ui_asset_paths.gd` via `build_enemy_token_texture_path(...)` | no if the stable pattern is followed | yes | yes | yes | `PARTIAL` | The path builder exists and some manifest-backed token files already ship, but family coverage is incomplete and there is no broad fallback table for missing token art. |
| player bust | `Assets/Characters/player_bust.png` | current runtime already ships `Assets/Characters/player_bust.png` | `Game/UI/combat_presenter.gd` and `Game/UI/ui_asset_paths.gd` via `PLAYER_BUST_TEXTURE_PATH` | no | yes | yes | yes | `READY_NOW` | No contract blocker for in-place replacement of `player_bust.png`; normal manifest/provenance/human-review gates still apply to any new art revision. |
| NPC portraits | `Assets/Characters/npc_<definition_id>_portrait.png` | no current generic runtime NPC portrait fallback is exposed | No current shared runtime NPC portrait owner/path surface | yes | yes | yes | yes | `BLOCKED` | No shared runtime owner exists, no target runtime files are present, and no manifest rows exist for the expected portrait pattern. |
| walker frame extensions | `Assets/UI/Map/Walker/ui_map_walker_<state>.svg` | current runtime already ships `ui_map_walker_idle.svg`, `ui_map_walker_walk_a.svg`, `ui_map_walker_walk_b.svg` | `Game/UI/map_route_binding.gd` preloads the live walker frames; `Game/UI/ui_asset_paths.gd` also records the current three path constants | no for in-place replacement of the current three files | yes | yes | yes | `PARTIAL` | The current three walker files are present and manifest-backed, but true frame extensions to new `<state>` names would require runtime selection expansion beyond the current idle/walk-a/walk-b contract. |

## Totals

- `READY_NOW`: 2
- `PARTIAL`: 5
- `BLOCKED`: 12

## Top Blockers

1. Tier 1 semantic targets do not exist at their expected runtime filenames and have no manifest rows.
2. Tier 2 prop and landmark families have neither runtime files nor a current shared path owner.
3. NPC portrait runtime ownership is still absent, so even correctly named portrait files would remain blocked without a new runtime surface.
4. Tier 3 themed icon families currently stop at generic fallback slots; broader semantic variants would need additional selector/path work.

## Closeout Summary

- Cross-check against `Docs/ASSET_WAVE_SEMANTIC_SCOPE.md`: this checklist keeps the same three-bucket wave shape:
  - Tier 1 = first mandatory semantic identity replacements
  - Tier 2 = optional prop/landmark polish
  - Tier 3 = later item/character extensions
- What can move first once approvals exist:
  - Tier 1 map-semantic icon replacements for `icon_map_combat`, `icon_map_key`, and `icon_map_boss`
  - Tier 3 in-place art refreshes on already stable runtime contracts such as `player_bust.png` and additional `enemy_<definition_id>_bust.png` files
- What stays blocked:
  - every Tier 1 row until the target runtime file exists, the manifest row exists, provenance/license review is complete, human visual review is complete, and the required runtime-path hookup is explicitly landed
  - all Tier 2 props/landmarks until a real runtime path owner exists; these remain optional and are not terrain blockers
  - NPC portraits until a shared runtime portrait surface exists
  - broader Tier 3 themed icon families until runtime selection/path work exists beyond the current generic fallback slots
- What should not be attempted in the semantic wave:
  - treating Tier 2 optional props as mandatory terrain work
  - reopening baked board art, terrain-transition art, or code-owned trail/clearing/canopy surfaces
  - treating file presence as approval
  - claiming Prompt 12 alone unblocks runtime adoption

## Non-Goals

- This checklist does not approve any asset already present in the repo.
- This checklist does not change `UiAssetPaths`.
- This checklist does not unblock the semantic icon wave by itself.
