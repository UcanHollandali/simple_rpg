# Architecture Hardening Audit - 2026-04-18

Status: report-only  
Method: static analysis plus grep/rg only  
Code changes: none  
Authority:
- `Docs/ARCHITECTURE.md`
- `Docs/SOURCE_OF_TRUTH.md`
- `Docs/COMBAT_RULE_CONTRACT.md`
- `Docs/MAP_CONTRACT.md`
- `Tools/validate_architecture_guards.py`

## Scope

Audited areas:
- `Game/Core/`
- `Game/Application/`
- `Game/RuntimeState/`
- `Game/Infrastructure/`
- `Game/UI/`
- `scenes/`
- `project.godot`
- `Docs/ARCHITECTURE.md`
- `Docs/SOURCE_OF_TRUTH.md`
- `Docs/COMBAT_RULE_CONTRACT.md`
- `Docs/MAP_CONTRACT.md`
- `Docs/COMMAND_EVENT_CATALOG.md`
- `Tools/validate_architecture_guards.py`

Supporting detailed audits already present:
- `Docs/Audit/2026-04-18-runtimestate-audit.md`
- `Docs/Audit/2026-04-18-application-audit.md`
- `Docs/Audit/2026-04-18-scene-audit.md`
- `Docs/Audit/2026-04-18-ui-audit.md`

Limitations:
- This pass is static-analysis only.
- No runtime instrumentation or profiler output was used.
- Explicit `preload(...)` cycles were checked; implicit `class_name` cycles remain a weaker grep-based check and are therefore reported separately as `Unclear` unless directly proven.

## Executive Summary

Confirmed critical layer violations:
- None found in this pass.

Confirmed major issues:
- `AppBootstrap` remains a broad autoload facade and is still reached directly by many scenes via `/root/AppBootstrap`, which keeps ownership technically intact but weakens layer discipline.
- `InventoryState` contains cache-updating getters (`consumable_slots`, `passive_slots`) that mutate internal state during property reads. This is intentional but breaks a strict "getter is idempotent and side-effect free" assumption.
- `Tools/validate_architecture_guards.py` covers several important repo-specific rules, but it does not guard some architecture risks now visible in the codebase: explicit/implicit cycle detection, getter side effects, autoload breadth, command/event catalog drift, and magic-number duplication/heuristics.

Confirmed non-problems:
- `Game/Core/` currently has no direct `scenes/` or `Game/UI/` references.
- No explicit `preload(...)` cycle was found in `.gd` files.
- `Game/Infrastructure/` is still primarily routing, persistence, content IO, and playtest logging; it is not currently a hidden gameplay-truth owner.
- The autoload list is minimal: only `AppBootstrap` and `SceneRouter` are registered in `project.godot`.

Likely or ambiguous structural risks:
- `SceneRouter` is architecturally allowed, but it is coupled to scene-specific overlay method names and file paths. This is composition/routing, not gameplay ownership, but it is still a brittle boundary hotspot.
- `Docs/COMMAND_EVENT_CATALOG.md` appears to lag the implemented Application surface. `turn_phase_resolved` and `BossPhaseChanged` exist in code but are not listed in the catalog.

## Findings

### F1 - No confirmed Core -> UI/scene layer violation, and Infrastructure still behaves like adapters/IO

- Severity: Confirmed non-problem
- Confidence: Confirmed
- AGENTS risk lane estimate if changed later:
  - validator/doc hardening: low-risk fast lane
  - ownership move: high-risk escalate-first lane

Evidence:
- `Game/Core/combat_resolver.gd` has no direct `Game/UI`, `scenes`, `SceneTree`, `Control`, `Label`, or `Button` references by grep.
- `Game/Infrastructure/content_loader.gd:8-26` is pure content IO.
- `Game/Infrastructure/save_service.gd:45-124` is snapshot build/read/write/validation.
- `Game/Infrastructure/save_service_legacy_loader.gd:25-151` is legacy schema validation/compat logic.
- `Game/Infrastructure/playtest_logger.gd:11-48` is instrumentation/file append only.

Interpretation:
- This is aligned with `Docs/ARCHITECTURE.md`: Core remains presentation-free, and Infrastructure remains persistence/routing/adapter-heavy rather than becoming a gameplay-truth owner.

### F2 - `AppBootstrap` remains a broad gameplay-facing facade and scenes still depend on it directly

- Severity: Major
- Confidence: Confirmed
- AGENTS risk lane estimate for cleanup: medium-risk guarded lane

Evidence:
- `project.godot:18-21` autoloads only:
  - `AppBootstrap`
  - `SceneRouter`
- `Game/Application/app_bootstrap.gd:49-104` exposes direct getters and gameplay-facing helpers such as:
  - `get_flow_manager()`
  - `get_run_state()`
  - `get_map_runtime_state()`
  - `get_reward_state()`
  - `get_level_up_state()`
  - `get_event_state()`
  - `get_support_interaction_state()`
  - `build_combat_setup_data()`
  - `save_game()`
  - `load_game()`
  - `restore_from_snapshot()`
- `Game/Application/app_bootstrap.gd:277-334` binds and re-binds `RunSessionCoordinator` and `SaveRuntimeBridge`, then keeps a private `_request_transition(...)` wrapper.
- Direct scene access to `/root/AppBootstrap` is still present in:
  - `scenes/combat.gd:583`
  - `scenes/event.gd:66`
  - `scenes/level_up.gd:55`
  - `scenes/main.gd:44`
  - `scenes/main_menu.gd:41`
  - `scenes/map_explore.gd:492`
  - `scenes/node_resolve.gd:37`
  - `scenes/reward.gd:70`
  - `scenes/run_end.gd:46`
  - `scenes/stage_transition.gd:45`
  - `scenes/support_interaction.gd:63`

Interpretation:
- This is not a confirmed owner violation because `AppBootstrap` is the sanctioned autoload facade.
- It is still an architecture-hardening risk because scenes can continue to grow dependency reach through a single global object instead of narrower Application-level surfaces.

Recommendation:
- Do not widen `AppBootstrap` further.
- Any future cleanup should reduce direct scene dependence on raw getters before adding more convenience methods.

### F3 - `InventoryState` cache getters have hidden write-side effects

- Severity: Major
- Confidence: Confirmed
- AGENTS risk lane estimate for cleanup: high-risk escalate-first lane

Evidence:
- `Game/RuntimeState/inventory_state.gd:118-123`
  - `consumable_slots` getter recomputes `_consumable_slots_cache`
  - updates `_consumable_cache_version`
- `Game/RuntimeState/inventory_state.gd:127-130`
  - `passive_slots` getter recomputes `_passive_slots_cache`
  - updates `_passive_cache_version`

Why this is a layer/architecture concern:
- `Docs/SOURCE_OF_TRUTH.md` correctly places inventory truth in `InventoryState`.
- But the getter surface is no longer observational-only; property reads can mutate internal cache/version state.
- This is still legal inside the owner, but it breaks the simpler architectural assumption that reads are idempotent and state changes happen only through explicit mutator methods.

Impact:
- Not a gameplay-truth leak.
- Still a hidden side-effect surface that can surprise future maintainers and makes pure-read auditing harder.

Recommendation:
- Keep behavior for now if performance benefit matters.
- If hardened later, document these getters as cached views or convert them into explicit accessor methods with caching semantics made visible.

### F4 - `SceneRouter` is not a gameplay owner, but it is tightly coupled to scene-specific choreography

- Severity: Minor
- Confidence: Confirmed
- AGENTS risk lane estimate for cleanup: low-risk fast lane if only refactor, medium-risk guarded lane if scene contract changes

Evidence:
- `Game/Infrastructure/scene_router.gd:8-28` hard-codes overlay state lists and scene method names:
  - `open_event_overlay`
  - `open_support_overlay`
  - `open_reward_overlay`
  - `open_level_up_overlay`
  - matching `close_*` methods
- `Game/Infrastructure/scene_router.gd:30-40` hard-codes state -> scene file paths.
- `Game/Infrastructure/scene_router.gd:125-148` contains MapExplore-specific overlay choreography and method-name dispatch.

Interpretation:
- `Docs/ARCHITECTURE.md` allows scene routing in Infrastructure, so this is not a violation.
- The brittle part is not ownership; it is scene-composition coupling through string method names and path constants.

Impact:
- Refactors in `scenes/map_explore.gd` or overlay method names can break routing without a type-safe contract.
- `validate_architecture_guards.py` currently guards presentation node-name coupling in `Application/Infrastructure`, but not this method-name routing surface.

### F5 - Command/event architecture is mostly centralized, but catalog drift remains

- Severity: Major
- Confidence: Confirmed
- AGENTS risk lane estimate for fixing:
  - doc-only catalog correction: low-risk fast lane
  - producer/consumer redesign: medium-risk guarded lane

Evidence:
- `Game/Application/game_flow_manager.gd:43-67` is the central flow transition point via `request_transition(...)`.
- Deprecated free-form `dispatch(...)` path is gone; the validator now checks for any repo-wide `dispatch(` usage.
- `Game/Application/combat_flow.gd:7-9` defines:
  - `domain_event_emitted`
  - `combat_ended_signal`
  - `turn_phase_resolved`
- `Game/Application/combat_flow.gd:563` emits `BossPhaseChanged`.
- `Docs/COMMAND_EVENT_CATALOG.md` contains `CombatStarted` and `EnemyIntentRevealed`, but grep shows no entries for:
  - `turn_phase_resolved`
  - `BossPhaseChanged`

Interpretation:
- Command dispatch is no longer diffuse in the older `dispatch()` sense.
- The remaining issue is documentation drift around event naming, not double-emission architecture breakage.

### F6 - `validate_architecture_guards.py` covers key repo-specific rules, but not several architecture smells now visible

- Severity: Major
- Confidence: Confirmed
- AGENTS risk lane estimate for guard additions: low-risk fast lane

Confirmed covered rules:
- repo-wide `dispatch(` ban
- `RunState` compatibility accessor spread outside allowed lanes
- test-side `RunState` inventory compat reads
- scene/UI direct writes to `RunState` scalar truth
- scene/UI direct calls into specific `MapRuntimeState` mutators
- combat active-slot bridge spread
- stale `RunSummaryCard` workaround spread
- `Application/Infrastructure` presentation-node string coupling
- hotspot file line-count ceilings
- public surface ceilings for `AppBootstrap` and `RunSessionCoordinator`

Confirmed uncovered or only partially covered:
- explicit and implicit dependency cycles
- getter side effects / non-idempotent property reads
- autoload breadth and direct scene reliance on `/root/AppBootstrap`
- command/event catalog drift
- Infrastructure method-name choreography coupling in `SceneRouter`
- magic-number duplication and unnamed heuristic constants
- duplicate helper/function families that are structurally architectural, not just stylistic

Interpretation:
- The validator is strong on repo-specific regressions already seen in this codebase.
- It is not yet a full architecture linter; several hardening targets are still human-audit-only.

### F7 - Most boundary constants are owner-centralized; one unnamed map heuristic remains a real hotspot

- Severity: Minor
- Confidence: Confirmed
- AGENTS risk lane estimate for cleanup:
  - same-owner naming cleanup: low-risk fast lane
  - owner move/content move: medium-risk guarded lane or higher

Confirmed single-owner or acceptable reused constants:
- `Game/Core/combat_resolver.gd:13`
  - `GUARD_DECAY_RATE: float = 0.75`
  - also documented in `Docs/COMBAT_RULE_CONTRACT.md:152`
- `Game/RuntimeState/map_runtime_state.gd:23`
  - `SCATTER_NODE_COUNT: int = 14`
- `Game/RuntimeState/map_runtime_state.gd:24`
  - `SCATTER_START_BRANCH_COUNT: int = 3`
- `Game/RuntimeState/map_runtime_state.gd:70`
  - `MAX_ROADSIDE_ENCOUNTERS_PER_STAGE: int = 3`
- `Game/RuntimeState/inventory_state.gd:40`
  - `BASE_BACKPACK_CAPACITY: int = 5`
- `Game/RuntimeState/run_state.gd:10`
  - `DEFAULT_HUNGER: int = 20`

Interpretation:
- These are mostly not duplication bugs; they are owner-backed constants reused across layers by reference.
- The notable smell is an unnamed heuristic penalty:
  - `Game/RuntimeState/map_runtime_state.gd:1961` -> `score -= 0.75`

Why this matters:
- Unlike the named owner constants above, this `0.75` is a naked topology heuristic inside the scatter scorer.
- It is not obvious from the symbol what it tunes or whether it should align with any other reconnect/placement heuristic.

Recommendation:
- Keep owner-local placement heuristics in `MapRuntimeState`, but promote this penalty to a named same-owner constant if the scatter system is tuned again.

### F8 - Circular dependency check is clean for explicit preloads, but implicit `class_name` cycle risk remains unproven

- Severity: Confirmed non-problem for explicit preload cycles; Unclear for implicit cycles
- Confidence: Mixed
- AGENTS risk lane estimate if tooling is added: low-risk fast lane

Confirmed:
- No explicit `.gd -> preload("...gd") -> ...` cycle was found in the current repo graph.

Unclear:
- This pass did not fully model implicit cycles created only through `class_name` resolution and runtime construction patterns.

Interpretation:
- There is no confirmed cycle bug.
- The remaining gap is tool coverage, not a proven architecture failure.

## Magic Number Hotspot List

Values worth tracking, even where they are currently legitimate owner constants:

- `0.75`
  - `Game/Core/combat_resolver.gd:13`
  - meaning: guard decay rate
  - recommended home: keep in Core or promote to a combat config surface only if combat tuning policy changes
- `14`
  - `Game/RuntimeState/map_runtime_state.gd:23`
  - meaning: scatter node count
  - recommended home: keep in `MapRuntimeState` unless map topology becomes content-driven
- `3`
  - `Game/RuntimeState/map_runtime_state.gd:24`
  - meaning: scatter start branch count
  - recommended home: keep in `MapRuntimeState`
- `3`
  - `Game/RuntimeState/map_runtime_state.gd:70`
  - meaning: roadside encounter cap
  - recommended home: keep in `MapRuntimeState`; already mirrored by `Docs/MAP_CONTRACT.md`
- `5`
  - `Game/RuntimeState/inventory_state.gd:40`
  - meaning: base backpack capacity
  - recommended home: keep in `InventoryState`
- `20`
  - `Game/RuntimeState/run_state.gd:10`
  - meaning: default hunger cap
  - recommended home: keep in `RunState`
- `0.75`
  - `Game/RuntimeState/map_runtime_state.gd:1961`
  - meaning: unnamed reconnect-node score penalty
  - recommended home: named same-owner constant inside `MapRuntimeState`

## Recommendations

1. Do not widen `AppBootstrap` further.
   - If scenes need more access, prefer narrowing scene calls rather than adding more autoload convenience.

2. Treat `InventoryState` cache getters as a documented exception, not an invisible pattern.
   - If left as-is, note the side effect in owner-facing documentation or comments.

3. Extend `validate_architecture_guards.py` for architecture-hardening gaps that are now recurring:
   - getter side effects
   - autoload breadth / direct scene reach
   - command/event catalog drift
   - scene-router method-name coupling
   - optional preload-cycle detection

4. Keep current owner-backed constants where they already live, but name local heuristics.
   - especially the scatter score penalty in `MapRuntimeState`.

5. Correct `Docs/COMMAND_EVENT_CATALOG.md` in a doc-only fast lane.
   - `turn_phase_resolved`
   - `BossPhaseChanged`

## Validation

Executed:
- `py -3 Tools/validate_architecture_guards.py`

Result:
- PASS
