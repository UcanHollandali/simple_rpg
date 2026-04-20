# SIMPLE RPG - Decision Log

## Purpose

This file records accepted project-level decisions and points back to their owning docs.

Keep it short.
Do not repeat full design arguments here.

## Format Rule

- accepted decisions only
- one short record per decision
- authority docs hold the real rule detail
- if a decision is superseded, keep the old ID and mark it with the replacement

Do not use this file for:
- unaccepted design ideas
- speculative ideas
- temporary implementation notes
- session status
- routine refactors

## Accepted Decisions

| ID | Decision | Authority |
|---|---|---|
| `D-001` | The game is preparation-first, not reflex-first. | `GDD.md` |
| `D-002` | Combat is not the star; it is the visible decision layer of preparation. | `GDD.md`, `COMBAT_RULE_CONTRACT.md` |
| `D-003` | The game should feel hard but fair. | `GDD.md`, `COMBAT_RULE_CONTRACT.md` |
| `D-004` | The project uses Godot 4.6.2 stable with typed GDScript. | `TECH_BASELINE.md` |
| `D-005` | Canonical gameplay content lives as JSON under `ContentDefinitions/`. | `TECH_BASELINE.md`, `CONTENT_ARCHITECTURE_SPEC.md` |
| `D-006` | Definition data and runtime state must stay separate. | `ARCHITECTURE.md`, `SOURCE_OF_TRUTH.md`, `CONTENT_ARCHITECTURE_SPEC.md` |
| `D-007` | Gameplay truth does not live in UI or gameplay autoloads. | `ARCHITECTURE.md`, `SOURCE_OF_TRUTH.md`, `TECH_BASELINE.md` |
| `D-008` | Preferred runtime pattern: command -> application -> core -> state update -> domain events -> UI refresh. | `ARCHITECTURE.md` |
| `D-009` | Superseded by `D-036`. Earlier combat baseline used `Attack`, `Brace`, and `Use Item`. | `COMBAT_RULE_CONTRACT.md` |
| `D-010` | First enemy intent is visible before the first player decision. | `COMBAT_RULE_CONTRACT.md` |
| `D-011` | Save architecture is required early, but initial saves are safe-state only. | `TECH_BASELINE.md`, `SAVE_SCHEMA.md` |
| `D-012` | Target RNG model uses named deterministic streams: `map_rng`, `combat_rng`, `reward_rng`. | `TECH_BASELINE.md`, `SAVE_SCHEMA.md` |
| `D-013` | Most new items, armors, weapons, enemies, and statuses should be data-first additions. | `CONTENT_ARCHITECTURE_SPEC.md`, `ARCHITECTURE.md` |
| `D-014` | Experimental ideas stay outside authoritative spec docs. | `EXPERIMENT_BANK.md`, `DOC_PRECEDENCE.md` |
| `D-015` | `GdUnit4` is the primary long-term test framework direction. | `TECH_BASELINE.md`, `TEST_STRATEGY.md` |
| `D-016` | Superseded by `D-030`. Earlier inventory used fixed slot types with limited capacity. | `SOURCE_OF_TRUTH.md`, `GDD.md` |
| `D-017` | Superseded by `D-027`. Earlier hunger direction started at `0` and climbed upward under attrition. | `COMBAT_RULE_CONTRACT.md`, `GDD.md` |
| `D-018` | Superseded by `D-026`. Earlier map direction used a layered DAG with typed node resolution. | `MAP_CONTRACT.md`, `GAME_FLOW_STATE_MACHINE.md` |
| `D-019` | Superseded by `D-036`. Earlier combat used `Brace` as the temporary mitigation action. | `COMBAT_RULE_CONTRACT.md` |
| `D-020` | `SupportInteraction` uses `Rest`, `Merchant`, `Blacksmith`, and `Hamlet`; the main support economy stays on shared `gold`, while `hamlet` contract flow stays outside that spend lane. | `SUPPORT_INTERACTION_CONTRACT.md`, `GDD.md` |
| `D-021` | Rewards and level-ups remain separate follow-up flow states; reward generation is deterministic and content-backed through authored reward offer pools plus live `reward_rng`-driven seeded windows. | `REWARD_LEVELUP_CONTRACT.md`, `GAME_FLOW_STATE_MACHINE.md`, `CONTENT_ARCHITECTURE_SPEC.md` |
| `D-024` | Superseded by `D-037`. Earlier inventory-pressure wording assumed a shared carried-capacity model before the explicit equipment-slot plus backpack foundation landed. | `SOURCE_OF_TRUTH.md`, `GDD.md`, `REWARD_LEVELUP_CONTRACT.md` |
| `D-025` | The current runtime-backed status slice is a small combat-local player-status pool (`poison`, `bleed`, `weakened`); broader routing and generic status families remain deferred. | `COMBAT_RULE_CONTRACT.md`, `CONTENT_ARCHITECTURE_SPEC.md`, `SOURCE_OF_TRUTH.md` |
| `D-026` | The active map spine is a center-start bounded exploration graph with partial fog, adjacency traversal, revisit without repeat farm, movement hunger cost, and a single stage-local key plus boss gate per stage. | `GDD.md`, `MAP_CONTRACT.md` |
| `D-027` | Hunger is a `0-20` reserve that starts at `20`, drains toward `0` from movement and combat, restores through food/support recovery, and turns lethal only once it bottoms out. | `COMBAT_RULE_CONTRACT.md`, `MAP_CONTRACT.md`, `SUPPORT_INTERACTION_CONTRACT.md`, `GDD.md` |
| `D-028` | `Use Item` stays a core combat action, but live combat presentation now resolves the currently selected usable consumable slot from the `ITEM` lane instead of silently auto-picking the front usable stack. | `COMBAT_RULE_CONTRACT.md` |
| `D-029` | Superseded by `D-031`. Blacksmith is no longer repair-only; it remains a one-shot support stop but now resolves one of three services using shared inventory capacity. | `SUPPORT_INTERACTION_CONTRACT.md`, `SOURCE_OF_TRUTH.md` |
| `D-030` | Superseded by `D-037`. Earlier carried inventory used a shared-slot pool before the explicit equipment-slot plus backpack migration. | `SOURCE_OF_TRUTH.md`, `GDD.md`, `SAVE_SCHEMA.md` |
| `D-031` | Blacksmith targets carried weapon / armor slots directly: one visit may temper a chosen weapon for `+1` attack, reinforce a chosen armor for `+1` defense, or repair the active weapon; those upgrade tiers live as runtime slot `upgrade_level`, not stage-authored replacement gear. | `SUPPORT_INTERACTION_CONTRACT.md`, `COMBAT_RULE_CONTRACT.md`, `SOURCE_OF_TRUTH.md`, `SAVE_SCHEMA.md` |
| `D-032` | Superseded by `D-036` and `D-037`. Earlier combat allowed carried gear swapping from the shared inventory strip during combat. | `COMBAT_RULE_CONTRACT.md`, `SOURCE_OF_TRUTH.md`, `GDD.md` |
| `D-033` | Rest remains a safe node, but the live trade is now `+10 HP` for `-3 hunger`; it is no longer a free hunger refill. | `SUPPORT_INTERACTION_CONTRACT.md` |
| `D-034` | Superseded by `D-039`. Planned map `event` nodes now read as `Trail Event`, while `Roadside Encounter` is reserved for movement-triggered interruptions. | `GAME_FLOW_STATE_MACHINE.md`, `MAP_CONTRACT.md` |
| `D-035` | Superseded by `D-039`. Earlier side-mission work used a separate contract-node framing before the `hamlet` support-family settlement stop became canonical. | `MAP_CONTRACT.md`, `SUPPORT_INTERACTION_CONTRACT.md`, `COMBAT_RULE_CONTRACT.md`, `REWARD_LEVELUP_CONTRACT.md`, `SAVE_SCHEMA.md`, `CONTENT_ARCHITECTURE_SPEC.md` |
| `D-036` | Current combat foundation uses `Attack`, `Defend`, and `Use Item`; `Defend` creates temporary `Guard`, shields strengthen defend guard, offhand weapons act as dual-wield modifiers, and combat-time gear swapping is no longer canonical. | `COMBAT_RULE_CONTRACT.md`, `SOURCE_OF_TRUTH.md`, `GDD.md` |
| `D-037` | Current inventory foundation uses explicit `right_hand`, `left_hand`, `armor`, and `belt` equipment slots plus backpack-carried inventory; equipped gear no longer consumes backpack capacity. | `SOURCE_OF_TRUTH.md`, `SAVE_SCHEMA.md`, `GDD.md`, `CONTENT_ARCHITECTURE_SPEC.md` |
| `D-038` | Current progression keeps XP thresholds but level-up now grants `CharacterPerks` rather than inventory items; passive items remain backpack-carried bonuses and are not the progression owner. | `REWARD_LEVELUP_CONTRACT.md`, `SOURCE_OF_TRUTH.md`, `SAVE_SCHEMA.md`, `CONTENT_ARCHITECTURE_SPEC.md` |
| `D-039` | Current map/support taxonomy separates planned `Trail Event` nodes from movement-triggered `Roadside Encounter`s and uses `hamlet` as the support-family settlement stop that hosts side-quest flow. | `MAP_CONTRACT.md`, `GAME_FLOW_STATE_MACHINE.md`, `SUPPORT_INTERACTION_CONTRACT.md`, `SOURCE_OF_TRUTH.md` |
| `D-040` | Current `Guard` no longer clears completely at turn end; it decays by the configured rate and a small rounded remainder may carry into the next turn before new `Defend` guard is added. | `COMBAT_RULE_CONTRACT.md` |
| `D-041` | Canonical pending-node truth belongs to `MapRuntimeState`; the `app_state.pending_node_id` / `app_state.pending_node_type` lane is a compatibility save-orchestration mirror and must not grow into a second owner. | `SOURCE_OF_TRUTH.md`, `SAVE_SCHEMA.md` |
| `D-042` | The live `NodeResolve` generic fallback remains an explicit legacy-compat flow path until a dedicated flow audit approves a behavior-changing removal. | `GAME_FLOW_STATE_MACHINE.md`, `MAP_CONTRACT.md`, `HANDOFF.md` |
| `D-043` | Existing `/root/AppBootstrap` dependencies may shrink only through guarded cleanup that preserves owner meaning and live flow behavior; no new lookup spread or public-facade widening is allowed. | `ARCHITECTURE.md`, `SOURCE_OF_TRUTH.md`, `TECH_BASELINE.md` |
