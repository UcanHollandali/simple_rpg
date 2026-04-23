# SIMPLE RPG - Handoff

Last updated: 2026-04-23 (Prompt `36` is closed green; Prompt `21-36` combat/content wave is now closed for the current prototype scope)

This file is a current-state snapshot only.
It is not a rule contract. If it conflicts with an authority doc, the authority doc wins.
Use `Docs/ROADMAP.md` for the canonical prompt-wave order/open state; use this file to understand the current checked-in snapshot.

## Current State

- The repo is prototype-playable with the mobile-portrait main loop live across `MapExplore`, `Combat`, and the non-combat overlay family.
- The guarded Prompt `14-20` map-overhaul wave is now closed green on this workspace.
- Prompt `21-36` are now closed green on this workspace as the combat/content queue reset, the first executable combat slice, the technique MVP, the narrow hand-slot swap runtime pass, the advanced-enemy-intent escalation spec, the trainer-node necessity/deferral audit, the first technical checkpoint/handoff gate, the combat UI audit, the onboarding refresh, the post-wave balance checkpoint, and the final integrated review/audit/playtest/screenshot closeout.
- No further queued pack remains inside Prompt `21-36`; any new combat/content continuation now needs either a new approved wave or one of the explicit deferred/escalation lanes.
- The fully applied Prompt `06-36` pack set is now archived under `Docs/Archive/Prompts/2026-04-23-closed-green-prompt-packs/`; `Docs/Promts/` currently has no live execution pack.
- `Guarded` meant implementable with explicit boundary care during execution; it was not a blanket stop signal and it is no longer an open queue on this snapshot.
- Prompt `01-03`, Prompt `04-05`, Prompt `06-12.5`, and Prompt `13` remain closed green on this workspace.
- Runtime ownership remains stable; `Docs/SOURCE_OF_TRUTH.md` stays the authority table.
- Key live ownership reminders for this snapshot:
  - `MapRuntimeState` remains the graph and pending-node owner
  - `RunSessionCoordinator` remains the movement and pending-screen orchestration owner
  - `AppBootstrap` remains a facade over flow/run/save coordination
- Prompt `15` landed the runtime-topology reset inside `MapRuntimeState` only:
  - stage-local topology blueprint choice is explicit before board placement
  - runtime graph generation stays deterministic per seed
  - same-depth reconnects stay bounded/local instead of acting as long-span rescue edges
  - realized-graph save payload shape stayed unchanged
- Prompt `16` landed family placement / pacing inside `MapRuntimeState` only:
  - node-family assignment now runs after topology as topology-aware constrained placement
  - exact family quotas and the early combat/reward/support exposure floor stayed intact
  - key/boss remain late-pressure placements while support/event/hamlet stay route-decision reads
  - save shape, flow state, and owner meaning stayed unchanged
- Prompt `17` landed the fixed-board presentation reset in `Game/UI` / `scenes` only:
  - the desired default model is now fixed board + fixed camera + walker moving on the board
  - route-follow / recenter behavior is retired as the default traversal presentation
  - playable rect, node-center margins, and path-safe bounds are explicit in the board composer/layout helpers
  - graph truth, save shape, flow state, and owner meaning stayed unchanged
- Prompt `18` landed the fixed-board layout/path/walker/world-fill convergence in `Game/UI` / `scenes` only:
  - fixed-board portrait layout spread and reconnect/path readability were tightened without changing `MapRuntimeState` graph truth
  - walker motion now reads as board-local traversal rather than a token riding board translation
  - ground/filler/forest/canopy fill is derived after frozen node/path structure and remains non-routing
  - save shape, flow state, and owner meaning stayed unchanged
- Prompt `19` landed the map-only prototype asset/filler hookup under the existing asset-pipeline and manifest gates:
  - the map board/route surface now uses dedicated map-only `combat`, `key`, and `boss` semantic icons instead of generic shared fallback identities on those lanes
  - the existing filler owner now stamps narrow map-only ground / landmark / prop exports inside the checked-in composer/canvas chain
  - every newly landed runtime asset is manifest-tracked in the same patch
  - graph truth, save shape, flow state, and owner meaning stayed unchanged
- The asset lane is improved but still explicitly temporary:
  - the newly landed map-only icons and filler exports are `candidate` runtime assets with `replace_before_release=yes`
  - the current map asset lane is not final or release-safe and must not be framed that way
  - broader future asset work still remains outside this pack: release-safe replacement, larger terrain/prop variety, and any non-map UI/combat/global polish
- Prompt `20` closed the final audit / review / patch gate for the full Prompt `15-19` chain:
  - filler and world-fill clearance now account for textured/stamped draw footprint instead of only the smaller abstract placement footprint
  - the node-resolve shell now uses the dedicated map `combat`, `key`, and `boss` icon lane instead of the older generic shared fallback icons on that surface
  - save shape, flow state, and owner meaning stayed unchanged
- A narrow post-closeout map presentation cleanup then tightened the last two lingering read risks without reopening the map wave:
  - corridor-profile ground beds now stay narrower/lighter in late seeds instead of reading like a broad dark slab
  - history/reconnect roads now de-emphasize their stamped trail lane so outer-frame reads stay less decorative and more navigational
- A later re-audit cleanup then tightened the remaining late-route board read without reopening the map wave:
  - deterministic path-family assignment now surfaces a straighter lane again in curated opening/late-route seeds instead of collapsing almost entirely into wider curves
  - deterministic forest fallback now guarantees at least one canopy/decor stamp in sparse late-route pockets so the board no longer drops to a completely barren backdrop
- The live combat/content baseline from the closed Prompt `21-36` wave is intentionally narrow:
  - top-level combat actions remain `Attack`, `Defend`, and direct consumable use, with conditional `Technique` when one is equipped
  - current enemy content stays inside the narrow sequential-intent grammar
  - combat-time `SwapHand` is now narrow `right_hand` / `left_hand` only
  - `hamlet` remains the only current side-quest support surface
- The now-closed Prompt `21-36` wave was explicitly split during execution:
  - Prompt `22` and Prompt `25` landed as low-risk visibility passes
  - Prompt `23` and Prompt `24` landed as guarded runtime/content passes
- Runtime/UI work that actually shipped in that wave is explicit:
  - Prompt `27` landed the first-pass technique MVP on the existing `hamlet` support surface
  - Prompt `29` landed the narrow `SwapHand` lane for `right_hand` / `left_hand` only
  - Prompt `33-36` closed as the optional UI-follow-through, onboarding, playtest, and final audit packs
- Docs-only escalation gates from that wave stayed docs-only:
  - Prompt `26` defined the narrow technique lane before Prompt `27`
  - Prompt `28` defined the narrow swap lane before Prompt `29`
  - Prompt `30` and Prompt `31` stayed future escalation/spec gates
- The shipped technique and swap truths remain narrow:
  - first-pass technique delivery stays on the existing `hamlet` support surface with `once_per_combat` use and save-backed continuity
  - `SwapHand` stays limited to `right_hand` + `left_hand`; armor, belt, and backpack reorder remain locked in combat
  - no combat save-safe widening was approved for swap UI or broken-weapon follow-up state
- The first executable combat/content wave is intentionally narrow:
  - threat readability follow-up
  - defend rebalance with tempo/hunger cost
  - enemy pattern variety inside the current sequential-intent grammar
  - quest/update follow-up visibility where it stays presentation-only
- The first technical tranche that actually shipped runtime/UI work is now explicit:
  - Prompt `22` landed threat readability follow-through over existing combat truth
  - Prompt `23` landed the stronger `Defend` rule with the explicit `+1` extra hunger tradeoff
  - Prompt `24` landed Pattern Pack A inside the current enemy grammar
  - Prompt `25` landed the compact quest-update launcher, badge, and toast follow-up surface for `hamlet`
  - Prompt `27` landed the `hamlet`-first technique MVP with one equipped technique between combats and once-per-combat use
  - Prompt `29` landed the narrow turn-consuming `SwapHand` lane for `right_hand` / `left_hand` only
- Prompt `32` closed the first technical checkpoint with narrow corrective fixes only:
  - post-swap combat attack / technique / preview / repair truth now follows the actually equipped right-hand weapon
  - leaving an open `hamlet` training choice no longer persists that lesson as a future revisit offer
  - combat inventory card hints no longer imply that all equipment is globally locked when only hand-slot swap is legal
- Prompt `33` landed the cross-mechanic combat UI follow-through:
  - the combat action area now keeps shipped mechanic lanes visible and coherent even when a technique is not equipped
  - empty hand-slot states no longer read like generic mid-combat equipment management
- Prompt `34` landed the onboarding refresh:
  - `Defend`, `Technique`, and `SwapHand` now each have at least one truthful first-run/contextual hint surface
  - onboarding stayed inside the existing additive `shown_first_run_hints` save lane
- Prompt `35` landed the first post-wave balance checkpoint:
  - controlled playtest examples confirmed that `Defend` now buys real HP preservation at a visible hunger cost
  - Pattern Pack A enemies are producing readable spike turns and tactical questions in the current grammar
  - `Echo Strike` was the only narrow tuning target from the checkpoint and now primes a `x3` next attack instead of `x2`
- A narrow post-closeout combat follow-up then tightened the last two watchpoints without opening a new mechanic lane:
  - `Cleanse Pulse` now clears current afflictions and adds a small `2 guard` pulse
  - `SwapHand` candidate hints now explain proactive right-hand, shield, and offhand tradeoffs directly instead of generic equip copy
- The following items are still explicitly separated behind escalation-first review:
  - dedicated trainer node family
  - persistent top-level skill bar
  - true multi-hit
  - enemy self-buff / self-guard / armor-up runtime
  - stage-count increase
- Prompt `30` wrote the future advanced-enemy-intent spec only:
  - Prompt `24` did not already cover true setup/pass, true multi-hit, enemy self-state, or enemy-owned statuses
  - no advanced enemy-intent runtime is live on this snapshot
  - any later implementation still requires a later approved runtime wave on top of the Prompt `30` spec
- Broader equipment-swap ideas are still deferred:
  - armor swap
  - belt swap
  - backpack reorder during combat
  - broader offhand / shield redesign beyond the current rule contract
- Prompt `31` closed as a docs-only necessity audit:
  - the live `hamlet`-first delivery from Prompt `27` remains the current truth
  - the case for a dedicated `trainer` node family stayed weak on current implementation/test evidence
  - dedicated trainer-node work remains deferred as a future explicit expansion lane rather than an approved next implementation target
- The prompt packs that drove the closed UI/map/combat waves are now archived historical execution records; they do not override current repo truth or become a second authority surface.
- `NodeResolve` remains live as a legacy-compatible fallback. Generic fallback and legacy pending-node restore still exist and are not fast-lane removal work.
- Pending-node continuity is still compatibility-sensitive:
  - `RunSessionCoordinator` writes/restores the save-facing `app_state` pending-node mirror fields
  - `MapRuntimeState` remains the runtime owner that consumes and loads the effective pending-node context
- Save baseline remains:
  - `save_schema_version = 8`
  - `content_version = prototype_content_v7`
- `Tools/validate_architecture_guards.py` reports semantic boundary drift as `errors` and maintainability pressure (`hotspot` growth / active-doc ballast) as visible `warnings`.

## Last Verified Validation Checkpoint

- Passed latest explicit full suite: `powershell -NoProfile -ExecutionPolicy Bypass -File Tools/run_godot_full_suite.ps1`
- Passed latest targeted save/support slice: `powershell -NoProfile -ExecutionPolicy Bypass -File Tools/run_godot_tests.ps1 test_save_support_interaction.gd test_save_file_roundtrip.gd test_support_node_persistence.gd test_save_terminal_states.gd test_event_save_policy.gd test_save_first_run_hints.gd`
- Passed validators: `py -3 Tools/validate_content.py`, `py -3 Tools/validate_assets.py`, `py -3 Tools/validate_architecture_guards.py`
- Passed latest diff hygiene check: `git diff --check`

## Open Risks

- Prompt `21-36` is now closed green for the intended prototype slice; remaining items below are residual watch risks and explicit deferred lanes, not an open in-wave implementation blocker.
- Prompt `26`, `28`, `30`, and `31` stayed docs-only escalation packs; do not misread their specs as shipped gameplay.
- Advanced enemy-intent runtime remains deferred even though the future spec now exists.
- Dedicated trainer-node work remains deferred; the live technique delivery truth is still `hamlet`-first.
- Broader combat-time equipment swapping remains deferred:
  - armor swap
  - belt swap
  - backpack reorder during combat
  - broader offhand / shield redesign
- Manual Godot visual verification is still needed for map readability, overlay feel, and combat height-budget behavior on portrait targets.
- Manual listening/playtest is still needed for the current prototype music floor even though objective QC helpers exist.
- The newly landed map-only asset lane stays intentionally temporary: the current `candidate` icons / filler exports are not final or release-safe.
- Broader terrain expansion, larger prop/landmark sets, and non-map UI/combat/global polish remain deferred beyond this map-only pack.
- Narrow emergency presentation fallbacks still exist where composer world positions are missing; keep them isolated and do not let them become a moving-board default again.
- The new playable-rect and safe-bounds contract is explicit, but overlay clearance is still driven by checked-in presentation constants rather than live asset measurement.
- `NodeResolve` is still live legacy flow code. Do not remove or behavior-change it without a dedicated flow audit.
- Pending-node continuity still crosses save orchestration in `RunSessionCoordinator` and runtime ownership in `MapRuntimeState`. Do not move that boundary without an explicit save audit.
- Several hotspot owners remain large. Treat them as extraction-first slices, not as automatic redesign mandates:
  - `map_runtime_state.gd`
  - `combat.gd`
  - `map_explore.gd`
  - `map_route_binding.gd`
- The closed Prompt `14-20` wave did not require save-shape, flow-state, or owner-meaning escalation.
- Explicit escalation items still deferred: advanced enemy-intent runtime, dedicated trainer node family, broader combat equipment swap, persistent top-level skill bar, and stage-count increase.

## Next Step

1. Prompt `21-36` is closed for the intended prototype scope.
   Do not treat Prompt `36` as a pending implementation lane anymore.
2. If more combat/content work is desired, open a new approved wave or re-enter through an explicit deferred/escalation lane rather than widening this closed wave in place.
3. Keep the residual watch risks explicit in any follow-up:
   - the current prototype/candidate map assets are still not final or release-safe

## Locked Decisions

- Canonical pending-node owner: `MapRuntimeState`.
- `app_state.pending_node_id` / `app_state.pending_node_type` remain compatibility mirrors for save/restore orchestration; they are not a second owner.
- Prompt `15` kept runtime graph truth in `MapRuntimeState` and did not widen the realized-graph save payload shape.
- Prompt `17` established fixed board / fixed camera / walker-on-board as the desired map presentation model without moving traversal truth into UI.
- Prompt `19` kept map-only asset/runtime hookup inside the existing UI/composer chain and did not move gameplay truth, save shape, or flow ownership.
- Prompt `20` closed with narrow presentation-only corrective patches; it did not widen into a second implementation wave.
- The live `NodeResolve` generic fallback stays until an explicit flow audit approves behavior-changing removal.
- Existing `/root/AppBootstrap` usage may shrink only when owner meaning and live flow behavior stay unchanged.
- Map-only prototype asset hookup remains gated by `Docs/ASSET_PIPELINE.md`, `Docs/ASSET_LICENSE_POLICY.md`, and truthful manifest rows.
