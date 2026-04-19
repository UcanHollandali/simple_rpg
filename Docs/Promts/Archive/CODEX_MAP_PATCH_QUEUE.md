# CODEX MAP PATCH QUEUE

Purpose: incremental Codex queue for current-repo map continuation.
Scope: map topology tuning, placement tuning, composer readability extension, remaining map-asset hook completion, and validation.
This queue is ordered. Do not start the next prompt until the previous one is completed or blocked with an explicit escalation note.

## Current Baseline This Queue Assumes
- The repo already has live controlled-scatter runtime generation in `MapRuntimeState`.
- The repo already separates topology generation from post-topology family assignment.
- The repo already has composer-driven derived map presentation through `MapBoardComposerV2`.
- The repo already has partial map-kit hookup in runtime:
  - trail textures
  - clearing decals
  - canopy clumps
  - node plates
  - dedicated `Trail Event` icon support
  - dedicated hamlet / side-mission icon support
- The current topology target remains `14` total nodes with a center-start stage graph.

## Locked Direction
- Keep `Dark Forest Wayfinder` as the render language.
- Use brighter forest-map references for composition, road readability, environmental density, and marker-body ideas only.
- Target outcome: stronger road feel, stronger local-neighborhood readability, and denser procedural forest dressing without changing map truth ownership.
- Do not treat this as asset-only work. Runtime generation, presentation tuning, and asset integration still have to line up.

## Read First For Every Prompt
- `AGENTS.md`
- `Docs/DOC_PRECEDENCE.md`
- `Docs/HANDOFF.md`
- `Docs/MAP_CONTRACT.md`
- `Docs/SOURCE_OF_TRUTH.md`
- `Docs/TEST_STRATEGY.md`
- `Docs/MAP_COMPOSER_V2_DESIGN.md`
- `Docs/MAP_COMPOSER_V2_ASSET_REQUIREMENTS.md`
- `Docs/TECH_BASELINE.md`
- `Docs/ASSET_PIPELINE.md` and `Docs/ASSET_LICENSE_POLICY.md` for Prompt 5 if runtime assets are added in the same patch

## Hard Constraints
- `MapRuntimeState` remains the gameplay owner of map truth.
- Do not move map truth into UI, scene scripts, or `AppBootstrap`.
- Do not change save schema or save version unless explicitly blocked and escalated first.
- Do not write presentation-only fields such as screen positions, bezier points, clearing masks, decor seeds, or asset-family picks into runtime or save truth.
- Do not consume gameplay RNG cursors for board recomposition.
- Graph logic and path-render geometry must stay separate.
- Extraction-first is mandatory before widening hotspot files.
- `Game/RuntimeState/map_runtime_state.gd` work is guarded/high-risk by default.
- `Game/UI/map_board_composer_v2.gd` and `scenes/map_explore.gd` should also be treated as extraction-first hotspots.
- Keep Godot closed while broad external patches are being applied.

## Not This Queue
- No save-schema changes.
- No new flow state.
- No source-of-truth ownership move.
- No gameplay autoload addition.
- No scene/core boundary rewrite.
- No asset generation inside runtime prompts.

## Required Working Loop For Every Prompt
Every prompt in this queue should follow the same internal loop:
1. audit the touched slice before changing code
2. patch only the narrow write scope for that prompt
3. review the changed files for regressions, stale assumptions, and leftover fallback coupling
4. report what remains intentionally deferred

Do not skip the review step.
Do not leave dead helper code, stale comments, or fallback residue behind if it became obsolete because of the patch.
If residue cannot be removed safely inside the current prompt, call it out explicitly so the final cleanup pass can remove it.

## Stop And Escalate If
- a save shape or save-version change is required
- source-of-truth ownership would change
- a new flow state is needed
- a new gameplay autoload is needed
- the implementation would change `MAP_CONTRACT.md` meaning outside the current bounded-exploration contract
- the implementation would cross the current scene/core boundary instead of staying inside existing owners
- portrait readability cannot be reconciled with the intended opening shell or current `14`-node compact envelope

## Queue Order
1. Baseline Audit / Truth Alignment
2. Topology Refactor Under Existing Contract
3. Placement Tuning Under Existing Post-Topology Lane
4. Composer Readability Extension
5. Remaining Asset Hook Completion
6. Validation / Debug Expansion
7. Residue Cleanup With Compat Guard

---

## Prompt 1 - Baseline Audit / Truth Alignment

Task:
Audit the current map runtime and presentation stack, confirm the continuation lane, and align docs only where the active repo truth actually disagrees with them.

Requirements:
- Inspect the current generator, family-placement lane, composer, backdrop builder, map scene integration, and tests.
- State clearly whether continuation can proceed without save-shape or ownership changes.
- Treat this as a current-state audit, not a preflight for a blank-slate rewrite.
- If the visual-direction clarification is still missing from `Docs/DECISION_LOG.md`, add:
  - `D-041`: `Current visual direction keeps Dark Forest Wayfinder as the locked render language; brighter forest-map references may guide composition, path readability, and environmental density, but do not override the style guide palette or render rules.`
- If the intended continuation target changes `MAP_CONTRACT.md` meaning, update that authority doc in the same patch.
- Produce a short implementation note in the PR description:
  - what is already live
  - biggest mismatch with the target map feel
  - intended write scope for Prompt 2

Write scope:
- `Docs/DECISION_LOG.md` only if the clarification row is genuinely missing
- doc updates only if truth alignment is required
- no broad runtime rewrite yet

Validation:
- `py -3 Tools/validate_architecture_guards.py`
- doc consistency review against `MAP_CONTRACT.md`, `SOURCE_OF_TRUTH.md`, and `HANDOFF.md`

Deliverable:
- one narrow PR
- explicit go/no-go note for Prompt 2
- explicit residue list for later cleanup if any stale fallback, compatibility glue, or dead-path suspicion is discovered

---

## Prompt 2 - Topology Refactor Under Existing Contract

Task:
Refactor the current frontier-growth controlled-scatter topology toward a stronger constrained-scatter, neighbor-aware graph while preserving the live contract and current save-safe runtime model.

Current repo truth to preserve:
- `14` total nodes
- center-start graph
- current `3`-branch opening shell as the live baseline unless Prompt 1 explicitly justifies a contract-aligned change
- compact portrait-readable envelope
- deterministic seed variation inside stage-profile floor
- key reachability and post-key boss viability
- current stage-profile ids and current save shape
- topology first, family placement later

Target behavior:
- center start
- stronger four-direction opening feel around the center
- scattered node positions, not rings or flat lanes
- minimum spacing and portrait-safe margins
- connectivity guaranteed
- most nodes degree `2`, some degree `1`, fewer degree `3`, center may be degree `4`
- outer reconnects allowed but limited
- no spaghetti graph

Implementation guidance:
- Treat this as a refactor of the existing topology lane, not a blank replacement of the whole map system.
- Preserve existing role-placement inputs and save-safe graph payload shape unless authority docs are updated in the same patch.
- Prefer helper extraction under `Game/RuntimeState/` before widening `map_runtime_state.gd`.
- Keep the topology output compatible with current placement and current composer/test assumptions unless those follow-up prompts explicitly update them.

Write scope:
- `Game/RuntimeState/map_runtime_state.gd`
- extraction helpers under `Game/RuntimeState/` if needed
- `Tests/test_map_runtime_state.gd`
- closest authority docs only if behavior meaning changes

Non-goals:
- no asset work
- no path art work
- no UI overhaul
- no save-schema or owner change

Validation:
- `py -3 Tools/validate_architecture_guards.py`
- targeted map runtime tests
- seed-sweep coverage for connectivity, degree floor, no isolated nodes, key reachability, and post-key boss viability
- explicit full suite before closing the pass because the runtime owner is a guarded/high-risk hotspot

Deliverable:
- one PR
- summary must state exact topology rules now implemented
- summary must list preserved invariants and any intentionally deferred old topology residue

---

## Prompt 3 - Placement Tuning Under Existing Post-Topology Lane

Task:
Tune and clean up the current post-topology family-placement lane so it remains deterministic, easier to reason about, and better matched to the refined topology.

Current repo truth to preserve:
- the repo already has separate post-topology family placement
- current stage guarantee floor still comes from `MAP_CONTRACT.md`
- `event` and `hamlet` remain dedicated runtime-backed roles, not disguised replacements for reward or support nodes

Target behavior:
- `start` remains center
- `boss` remains outer/frontier biased
- `key` remains late-depth without collapsing into immediate boss click
- optional and detour-feeling content prefers leaf or branch-detour candidates
- `combat` remains majority filler
- critical placement failures reroll or reassign instead of silently shipping invalid graphs

Implementation guidance:
- Do not re-introduce "separate topology from placement" as if that split does not already exist.
- Focus on scoring, quota tuning, clearer helper boundaries, and deterministic placement behavior against the refined topology.
- Move toward config-driven quotas only if it stays save-safe and authority-aligned.

Write scope:
- map runtime placement logic
- map template or config helpers only if needed
- tests covering quotas and placement invariants

Validation:
- targeted runtime tests
- seed sweeps for family counts, opening exposure floor, and placement invariants
- explicit full suite before closing the pass

Deliverable:
- one PR
- summary must separate topology rules from placement rules
- summary must list any stale placement helpers or compatibility bridges still present after the patch

---

## Prompt 4 - Composer Readability Extension

Task:
Extend the existing composer and backdrop foundation so the graph reads more clearly as roads and pockets without changing runtime truth ownership.

Current repo truth to preserve:
- composer-driven derived board positions
- visible edge paths
- clearing decals
- canopy / forest fill
- node plates and icon-overlay stack
- current live path-family labels:
  - `short_straight`
  - `gentle_curve`
  - `wider_curve`
  - `outward_reconnecting_arc`

Target behavior:
- stronger road read
- clearer local pockets
- better corridor/clearing/forest-fill separation
- node UI remains above the board, not baked into it
- missing art still fails softly through fallback instead of broken scenes

Implementation guidance:
- Treat this as an extension of the current composer foundation, not a second-generation architecture reset.
- Keep current path-family names stable unless tests, code, and docs are all updated together for a strong reason.
- Do not hardcode asset paths that do not exist.
- Do not introduce presentation-owned save truth.
- Prefer extraction helpers under `Game/UI/` before widening `map_board_composer_v2.gd`.

Write scope:
- `Game/UI/map_board_composer_v2.gd`
- `Game/UI/map_board_backdrop_builder.gd`
- extraction helpers under `Game/UI/` if needed
- `Tests/test_map_board_composer_v2.gd`
- `scenes/map_explore.gd` only if presentation wiring genuinely needs adjustment

Non-goals:
- no final-art requirement yet
- no full map-scene rewrite
- no path-family churn just for naming aesthetics

Validation:
- composer determinism
- visible edge readability
- visible node spacing
- no hidden-info leak through board composition
- scene isolation for `scenes/map_explore.tscn` if scene wiring changed
- portrait review capture if layout or board readability changed

Deliverable:
- one PR
- summary must explain runtime truth vs derived presentation output
- summary must list any deferred path/layout residue or fallback coupling

---

## Prompt 5 - Remaining Asset Hook Completion

Task:
Prepare the codebase to consume the remaining map-kit families that are still thin or missing from the live runtime-facing surface.

Current live runtime-facing map kit to preserve:
- trail textures
- clearing decals
- canopy clumps
- node plates
- board shell
- walker assets
- dedicated `Trail Event` icon
- dedicated hamlet / side-mission icon support

Priority order for this prompt:
1. `ui_map_v2_ground_*`
2. `ui_map_v2_prop_*`
3. `ui_map_v2_landmark_*`
4. optional `ui_map_v2_foreground_*`

Deferred by default:
- marker-body work, unless the prompt explicitly adds a real runtime hook surface for it

Target behavior:
- deterministic asset-family selection from presentation seed inputs
- new family hooks sit on top of the existing composer metadata instead of bypassing it
- missing assets fail softly with warnings and fallback, not broken scenes

Write scope:
- composer, backdrop, canvas, and map-scene integration
- asset lookup helpers if needed
- no asset generation
- no icon-system rewrite

Validation:
- targeted composer tests
- scene isolation for `scenes/map_explore.tscn`
- portrait-safe review capture if render or layout changed
- `py -3 Tools/validate_assets.py` only if runtime assets are added in the same patch

Deliverable:
- one PR
- summary must list which asset hooks are now live
- summary must list which families still rely on fallback
- summary must name every remaining fallback path still active after the patch

---

## Prompt 6 - Validation / Debug Expansion

Task:
Add the debug and review tooling needed to trust the incremental overhaul.

Required debug visibility:
- node id
- node family
- degree
- depth or distance from center
- path family
- topology signature or seed

Required validation:
- `100`-seed sweep for connectivity and family invariants
- portrait readability checks inside current target resolutions
- screenshot or review-helper updates only where directly relevant

Write scope:
- tests
- optional debug overlay or test scene
- tooling updates only where directly relevant

Validation:
- `py -3 Tools/validate_architecture_guards.py`
- targeted Godot test lists first
- use broader suites only if touched scope justifies it

Deliverable:
- one PR
- final summary must say:
  - what changed
  - what did not change
  - what still depends on incoming art assets
  - what stale code or compatibility residue still remains for the final cleanup pass

---

## Prompt 7 - Residue Cleanup With Compat Guard

Task:
After the functional passes land, do a final targeted cleanup pass so the map stack ends cleanly without stripping still-needed compatibility bridges.

Focus:
- remove stale topology helpers no longer used by the refined generator
- remove dead layout or presentation helpers replaced by the current foundation
- remove comments, constants, and compatibility glue that now describe old behavior
- trim emergency fallback paths only where safe and where authority docs allow them to remain optional rather than primary

Compat guard:
- if a fallback or compatibility path looks removable, prove it first through tests and the closest authority doc
- if that proof is missing, keep it and add a short comment explaining why it still exists

Requirements:
- start with a read-only audit of the touched map/runtime/UI files
- identify dead code, unreachable helpers, stale constants, unused imports or preloads, obsolete comments, and old fallback branches
- patch only what can be removed safely without changing intended behavior
- prefer smaller cleanup patches over one destructive sweep

Write scope:
- map runtime files touched by Prompts 2-3
- UI/composer/map scene files touched by Prompts 4-5
- related tests only if cleanup changes test assumptions

Non-goals:
- no new feature work
- no asset generation
- no save or flow changes

Validation:
- `py -3 Tools/validate_architecture_guards.py`
- targeted map tests
- scene isolation for `scenes/map_explore.tscn` if scene scripts changed
- explicit full suite at the final cleanup checkpoint

Deliverable:
- one cleanup-focused PR
- summary must say:
  - which old code paths were removed
  - which fallback or compatibility paths remain and why
  - whether the map stack now reflects the current architecture cleanly

## Overnight Rule
- Run Prompt 1 first.
- If Prompt 1 reports an escalation blocker, stop the queue.
- If Prompt 2 lands, Prompts 3-7 may follow in order.
- Do not merge presentation assumptions that depend on asset files that do not exist yet.
