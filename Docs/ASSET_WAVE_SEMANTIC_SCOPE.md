# SIMPLE RPG - Semantic Asset Wave Scope

## Status

- This file is reference-only.
- This file is a production/reference companion to `Docs/ASSET_BACKLOG.md`.
- Authority remains `Docs/VISUAL_AUDIO_STYLE_GUIDE.md` for style direction and `Docs/ASSET_PIPELINE.md` plus `Docs/ASSET_LICENSE_POLICY.md` for approval, provenance, and runtime-boundary rules.
- This file does not approve assets, does not hook assets into runtime, and does not reopen terrain-transition or baked-board art lanes.

## Purpose

Scope the next AI-assisted asset wave to semantic single-object surfaces only so future asset work strengthens map identity without turning terrain art into a runtime dependency.

## Composition Reference

Pinned visual target for future semantic asset generation:

- warm lit earthen paths radiate from a center start anchor
- a small lantern or shrine-like prop marks the center start node
- semantic node identity is carried by prop-style icons rather than flat UI glyphs
- reward reads as a chest
- key reads as a key chest or keyed reliquary
- boss reads as a sword altar or gate marker
- start reads as a lantern shrine
- event reads as a question-mark box or mystery prop
- rest reads as a small camp
- merchant reads as a stall
- blacksmith reads as an anvil or forge prop
- hamlet reads as a settlement marker
- combat reads as a compact combat token or skirmish marker
- dense forest canopy frames the playable pocket without overtaking node and route readability
- procedural decor such as rocks, stumps, lanterns, and small bushes can scatter along path edges and canopy gaps
- contrast must stay mobile portrait-readable on a small screen
- the target is not a baked full-stage illustration, not a single authored board image, and not a terrain-transition pipeline

This visual language is reached through the existing architecture, not through a one-shot background painting:

- seed-driven controlled-scatter produces a different topology per run
- procedural code draws roads, clearings, atmosphere, canopy massing, and decor variation
- semantic single-object art carries node identity and optional prop decoration

## Tier 1 - Node Identity Icon Completion

Priority goal: replace the current generic fallbacks used by map-facing combat, key, and boss nodes with dedicated map-semantic identity icons.

| Surface | Expected runtime filename pattern | Current repo fallback | UiAssetPaths impact | Approval gate |
|---|---|---|---|---|
| combat node identity icon | `Assets/Icons/icon_map_combat.svg` | falls back to `Assets/Icons/icon_attack.svg` through `UiAssetPaths.ATTACK_ICON_TEXTURE_PATH` in map presenters | yes; a dedicated map-combat hookup needs a `UiAssetPaths` update or equivalent map-presenter path swap so combat UI keeps its own attack icon contract | manifest row plus truthful provenance/license fields per `Docs/ASSET_PIPELINE.md` and `Docs/ASSET_LICENSE_POLICY.md`; human style/readability review against `Docs/VISUAL_AUDIO_STYLE_GUIDE.md` |
| key node identity icon | `Assets/Icons/icon_map_key.svg` | falls back to `Assets/Icons/icon_confirm.svg` through `UiAssetPaths.KEY_ICON_TEXTURE_PATH` and current key-marker usage | yes; current key map identity is path-owned by generic confirm art | manifest row plus truthful provenance/license fields per `Docs/ASSET_PIPELINE.md` and `Docs/ASSET_LICENSE_POLICY.md`; human style/readability review against `Docs/VISUAL_AUDIO_STYLE_GUIDE.md` |
| boss node identity icon | `Assets/Icons/icon_map_boss.svg` | falls back to `Assets/Icons/icon_enemy_intent_heavy.svg` through `UiAssetPaths.BOSS_ICON_TEXTURE_PATH` | yes; a dedicated boss map identity requires a path-level hookup change | manifest row plus truthful provenance/license fields per `Docs/ASSET_PIPELINE.md` and `Docs/ASSET_LICENSE_POLICY.md`; human style/readability review against `Docs/VISUAL_AUDIO_STYLE_GUIDE.md` |

Notes:

- start, rest, merchant, blacksmith, and hamlet already ship map-facing icons; Tier 1 is only for the three live weak fallbacks above
- these are semantic identity replacements, not terrain art

## Tier 2 - Optional Node Props And Landmark Emphasis

Priority goal: add optional prop-style landmark surfaces that can deepen map identity after the procedural renderer is already readable on its own.

| Surface | Expected runtime filename pattern | Current repo fallback | UiAssetPaths impact | Approval gate |
|---|---|---|---|---|
| rest camp prop | `Assets/UI/Map/Props/ui_map_prop_rest_camp.svg` | no dedicated runtime prop; current fallback is procedural clearing plus `icon_map_rest` | yes if promoted into shared runtime path ownership; no current `UiAssetPaths` slot exists for this prop family | manifest row plus truthful provenance/license fields per `Docs/ASSET_PIPELINE.md` and `Docs/ASSET_LICENSE_POLICY.md`; human style/readability review against `Docs/VISUAL_AUDIO_STYLE_GUIDE.md` |
| merchant stall prop | `Assets/UI/Map/Props/ui_map_prop_merchant_stall.svg` | no dedicated runtime prop; current fallback is procedural clearing plus `icon_map_merchant` | yes if promoted into shared runtime path ownership; no current `UiAssetPaths` slot exists for this prop family | manifest row plus truthful provenance/license fields per `Docs/ASSET_PIPELINE.md` and `Docs/ASSET_LICENSE_POLICY.md`; human style/readability review against `Docs/VISUAL_AUDIO_STYLE_GUIDE.md` |
| blacksmith anvil prop | `Assets/UI/Map/Props/ui_map_prop_blacksmith_anvil.svg` | no dedicated runtime prop; current fallback is procedural clearing plus `icon_map_blacksmith` | yes if promoted into shared runtime path ownership; no current `UiAssetPaths` slot exists for this prop family | manifest row plus truthful provenance/license fields per `Docs/ASSET_PIPELINE.md` and `Docs/ASSET_LICENSE_POLICY.md`; human style/readability review against `Docs/VISUAL_AUDIO_STYLE_GUIDE.md` |
| boss gate marker or sword altar prop | `Assets/UI/Map/Landmarks/ui_map_landmark_boss_gate.svg` or `Assets/UI/Map/Landmarks/ui_map_landmark_sword_altar.svg` | no dedicated runtime prop; current fallback is boss icon plus procedural pocket | yes if adopted; there is no current shared path owner for map landmark props | manifest row plus truthful provenance/license fields per `Docs/ASSET_PIPELINE.md` and `Docs/ASSET_LICENSE_POLICY.md`; human style/readability review against `Docs/VISUAL_AUDIO_STYLE_GUIDE.md` |
| optional key shrine prop | `Assets/UI/Map/Landmarks/ui_map_landmark_key_shrine.svg` | no dedicated runtime prop; current fallback is key icon plus procedural pocket | yes if adopted; there is no current shared path owner for map landmark props | manifest row plus truthful provenance/license fields per `Docs/ASSET_PIPELINE.md` and `Docs/ASSET_LICENSE_POLICY.md`; human style/readability review against `Docs/VISUAL_AUDIO_STYLE_GUIDE.md` |
| optional start lantern shrine prop | `Assets/UI/Map/Landmarks/ui_map_landmark_start_lantern_shrine.svg` | no dedicated runtime prop; current fallback is `Assets/Icons/icon_map_start.svg` plus the procedural center pocket | yes if adopted; there is no current shared path owner for map landmark props | manifest row plus truthful provenance/license fields per `Docs/ASSET_PIPELINE.md` and `Docs/ASSET_LICENSE_POLICY.md`; human style/readability review against `Docs/VISUAL_AUDIO_STYLE_GUIDE.md` |
| optional event question box prop | `Assets/UI/Map/Props/ui_map_prop_event_question_box.svg` | no dedicated runtime prop; current fallback is `Assets/Icons/icon_map_trail_event.svg` plus procedural pocket | yes if promoted into shared runtime path ownership; no current `UiAssetPaths` slot exists for this prop family | manifest row plus truthful provenance/license fields per `Docs/ASSET_PIPELINE.md` and `Docs/ASSET_LICENSE_POLICY.md`; human style/readability review against `Docs/VISUAL_AUDIO_STYLE_GUIDE.md` |
| optional reward chest prop | `Assets/UI/Map/Props/ui_map_prop_reward_chest.svg` | no dedicated runtime prop; current fallback is `Assets/Icons/icon_reward.svg` plus procedural pocket | yes if promoted into shared runtime path ownership; no current `UiAssetPaths` slot exists for this prop family | manifest row plus truthful provenance/license fields per `Docs/ASSET_PIPELINE.md` and `Docs/ASSET_LICENSE_POLICY.md`; human style/readability review against `Docs/VISUAL_AUDIO_STYLE_GUIDE.md` |

Notes:

- Tier 2 remains optional polish
- Tier 2 does not reopen trail, clearing, filler, canopy, junction, or transition art as required runtime blockers

## Tier 3 - Item And Character Extensions

Priority goal: later passes can deepen semantic identity outside the core map-node lane without changing the code-first terrain direction.

| Surface family | Expected runtime filename pattern | Current repo fallback | UiAssetPaths impact | Approval gate |
|---|---|---|---|---|
| weapons, shields, armor, belts | `Assets/Icons/icon_weapon_<theme>.svg`, `Assets/Icons/icon_shield_<theme>.svg`, `Assets/Icons/icon_armor_<theme>.svg`, `Assets/Icons/icon_belt_<theme>.svg` | generic family fallbacks already ship as `icon_weapon.svg`, `icon_shield.svg`, `icon_armor.svg`, `icon_belt.svg` | no for in-place replacement of the current generic family slots; yes only if runtime starts selecting multiple per-family variants through new path constants or selector logic | manifest row plus truthful provenance/license fields per `Docs/ASSET_PIPELINE.md` and `Docs/ASSET_LICENSE_POLICY.md`; human style/readability review against `Docs/VISUAL_AUDIO_STYLE_GUIDE.md` |
| consumables, passives, quest items | `Assets/Icons/icon_consumable_<theme>.svg`, `Assets/Icons/icon_passive_<theme>.svg`, `Assets/Icons/icon_quest_item_<theme>.svg` | generic family fallbacks already ship as `icon_consumable.svg`, `icon_passive.svg`, `icon_quest_item.svg` | no for in-place replacement of the current generic family slots; yes only if runtime starts selecting multiple themed variants | manifest row plus truthful provenance/license fields per `Docs/ASSET_PIPELINE.md` and `Docs/ASSET_LICENSE_POLICY.md`; human style/readability review against `Docs/VISUAL_AUDIO_STYLE_GUIDE.md` |
| shield attachments | `Assets/Icons/icon_shield_attachment_<theme>.svg` | generic family fallback already ships as `icon_shield_attachment.svg` | no for in-place replacement of the current generic family slot; yes only if runtime starts selecting multiple variants | manifest row plus truthful provenance/license fields per `Docs/ASSET_PIPELINE.md` and `Docs/ASSET_LICENSE_POLICY.md`; human style/readability review against `Docs/VISUAL_AUDIO_STYLE_GUIDE.md` |
| enemy busts | `Assets/Enemies/enemy_<definition_id>_bust.png` | current runtime already uses `UiAssetPaths.build_enemy_bust_texture_path(...)` plus specific bust fallback mappings where a definition is missing | no if the stable `enemy_<definition_id>_bust.png` pattern is followed | manifest row plus truthful provenance/license fields per `Docs/ASSET_PIPELINE.md` and `Docs/ASSET_LICENSE_POLICY.md`; human style/readability review against `Docs/VISUAL_AUDIO_STYLE_GUIDE.md` |
| enemy tokens | `Assets/Enemies/enemy_<definition_id>_token.png` | partial runtime support exists through `UiAssetPaths.build_enemy_token_texture_path(...)`; no broad generic fallback table is currently populated | no if the stable `enemy_<definition_id>_token.png` pattern is followed; yes only if a new fallback family or alternate naming contract is introduced | manifest row plus truthful provenance/license fields per `Docs/ASSET_PIPELINE.md` and `Docs/ASSET_LICENSE_POLICY.md`; human style/readability review against `Docs/VISUAL_AUDIO_STYLE_GUIDE.md` |
| player bust | `Assets/Characters/player_bust.png` | current runtime already ships `player_bust.png` through `UiAssetPaths.PLAYER_BUST_TEXTURE_PATH` | no for in-place replacement of the same stable filename | manifest row plus truthful provenance/license fields per `Docs/ASSET_PIPELINE.md` and `Docs/ASSET_LICENSE_POLICY.md`; human style/readability review against `Docs/VISUAL_AUDIO_STYLE_GUIDE.md` |
| NPC portraits | `Assets/Characters/npc_<definition_id>_portrait.png` | no current generic runtime NPC portrait fallback is exposed | yes if NPC portraits become a runtime surface; there is no current shared NPC portrait path owner | manifest row plus truthful provenance/license fields per `Docs/ASSET_PIPELINE.md` and `Docs/ASSET_LICENSE_POLICY.md`; human style/readability review against `Docs/VISUAL_AUDIO_STYLE_GUIDE.md` |
| walker frame extensions | `Assets/UI/Map/Walker/ui_map_walker_<state>.svg` | current runtime already ships `ui_map_walker_idle.svg`, `ui_map_walker_walk_a.svg`, `ui_map_walker_walk_b.svg` | no for in-place replacement of the current three files; yes if new named frames or states are added to runtime selection | manifest row plus truthful provenance/license fields per `Docs/ASSET_PIPELINE.md` and `Docs/ASSET_LICENSE_POLICY.md`; human style/readability review against `Docs/VISUAL_AUDIO_STYLE_GUIDE.md` |

Notes:

- Tier 3 is explicitly later-pass scope
- Tier 3 does not justify widening map terrain art scope

## Non-Goals

This plan does not cover:

- baked full-stage terrain art
- single authored board images
- ground art, trail strip art, clearing underlay art, filler art, junction art, or transition art as required runtime surfaces
- any art whose correctness depends on neighboring art blending
- any change that would make procedural roads, clearings, atmosphere, canopy massing, or decor variation stop being code-owned
- any automatic approval, import, rename, move, or hookup of existing `SourceArt/Generated/` files

## References

- `Docs/ASSET_BACKLOG.md` remains the planning queue companion for what to build next
- `Docs/VISUAL_AUDIO_STYLE_GUIDE.md` remains the authority for the `Dark Forest Wayfinder` look, icon readability, palette behavior, and small-screen contrast
- `Docs/ASSET_PIPELINE.md` remains the authority for runtime filenames, promotion stages, and manifest requirements
- `Docs/ASSET_LICENSE_POLICY.md` remains the authority for provenance, AI usage notes, and commercial/replacement truth
