# MAP REDESIGN CODEX QUEUE

Purpose: Ordered Codex prompt list for the current map-redesign pass the user asked for.
Scope: center-start scatter topology refinement + cardinal-start opening feel + varied road geometry + deterministic re-roll per run + asset hook completion. Runtime owner, save shape, and flow stay untouched.
Audience: someone driving Codex (local CLI or cloud) prompt-by-prompt.

This queue is a focused, user-driven companion to `Docs/Promts/CODEX_MAP_PATCH_QUEUE.md`.
If this file and `Docs/Promts/CODEX_MAP_PATCH_QUEUE.md` disagree, `MAP_CONTRACT.md` + `SOURCE_OF_TRUTH.md` win, then `Docs/Promts/CODEX_MAP_PATCH_QUEUE.md`, then this file.

Master execution plan that sequences this file together with theming, assets and extraction: `Docs/Promts/MAP_OVERHAUL_EXECUTION_PLAN.md`.

Related independent queues:
- `Docs/Promts/MAP_NODE_THEMING_CODEX_QUEUE.md` — themed player-facing display names for node families; presentation-only, can run in parallel or in either order.
- `Docs/Promts/MAP_RUNTIME_STATE_EXTRACTION_PLAN.md` — technical refactor of `map_runtime_state.gd`; MUST run AFTER this redesign queue closes, otherwise block line numbers drift.

---

## 0. Current Repo Truth This Queue Starts From

Before writing new prompts, the following is already true in the checked-out repo. Do NOT ask Codex to build these from scratch:

- `MapRuntimeState` already generates a `14`-node controlled-scatter graph with a center `start` and `3` opening branches (combat/support/reward).
- Topology generation (`_build_controlled_scatter_frontier_tree`) and family placement (`_build_controlled_scatter_family_assignments`) are already separated.
- Reconnect edges between outer branches are already implemented (`_apply_controlled_scatter_reconnects`) — `1-2` reconnects per stage.
- Degree floor is already enforced: most nodes degree `2`, some leaves degree `1`, a few degree `3`, start can be `4`.
- Seeded per-run variation is already in (branch priority rotation, reconnect plan rotation).
- `MapBoardComposerV2` already derives world positions, visible edge trails, forest shapes from runtime truth plus a board seed, without advancing gameplay RNG.
- Four path families already exist and render: `short_straight`, `gentle_curve`, `wider_curve`, `outward_reconnecting_arc`.
- Live map-facing assets already exist: trail textures, clearing decals, canopy clumps, node plates, walker, board shell, map-family icons.

What the user is asking that is NOT already live:
- a stronger 4-direction opening feel around center (currently 3 branches)
- stronger visual feel that the graph changes meaningfully each run
- stronger visible differentiation between road families (straight / gentle curve / wider curve / reconnecting arc)
- missing asset families: `ground`, `prop`, `landmark`, optional `foreground`

That is the actual scope of this pass.

---

## 0.5 Locked User Direction For This Pass

These points are treated as the current user ask for the redesign pass:

- The player starts from the center anchor.
- The board should read as a scattered forest graph, not concentric rings and not flat left-to-right lanes.
- The opening shell should feel like a center camp / stump / waymark with routes pushing outward around it.
- Preferred opening feel: `4` cardinal-ish directions (`up`, `down`, `left`, `right`) if the `14`-node envelope can still preserve readability and the current guarantee floor.
- Safe fallback if the full `4`-branch version becomes too shallow or too noisy: `3` main branches plus `1` short spur / detour branch near the center.
- Total node-family counts stay under the current contract unless explicitly escalated.
- Degree mix should still feel map-like:
  - some leaf / dead-end pockets
  - many `2`-way traversal nodes
  - some `3`-way connectors
  - center start may be `3-4` degree
- Outer nodes should not feel isolated; limited reconnects between late pockets should help the graph read as a map.
- Road families should stay inside the current `4`-family set and become visibly distinct.
- The reference image is a composition/readability target, not a palette-copy target. Keep `Dark Forest Wayfinder` as the final render language unless the authority docs are changed.

Recommended implementation stance:

- do NOT restart the map system from zero
- treat this as a controlled-scatter v1.5 pass over the live runtime owner
- prefer topology + placement + composer tuning over a blank-slate generator rewrite
- prefer `3 main + 1 short spur` over forced `4` equal-depth branches if the latter weakens key/boss pacing inside `14` nodes

---

## Locked Constraints For Every Prompt

- `MapRuntimeState` is the map gameplay owner. Do not move truth to UI or `AppBootstrap`.
- No save-schema change. No new flow state. No new autoload. No scene/core boundary rewrite.
- Render language stays `Dark Forest Wayfinder`. Brighter reference maps may inform composition only.
- `14`-node center-start bounded-exploration contract stays intact.
- Portrait readability guardrail (`2-4` outward options visible at once) stays intact.
- The user wants a stronger center-start shell, but not at the cost of collapsing route readability or key/boss viability.
- Key reachability and post-key boss viability stay intact.
- Extraction-first on `map_runtime_state.gd`, `map_board_composer_v2.gd`, `scenes/map_explore.gd`.
- Every prompt runs the working loop from `Docs/Promts/CODEX_MAP_PATCH_QUEUE.md`: audit → narrow patch → review → report.

## Stop And Escalate If

- save shape change is required
- source-of-truth ownership would move
- `MAP_CONTRACT.md` meaning would change outside the current bounded-exploration contract
- portrait `14`-node envelope cannot hold a 4-direction opening

---

## Read-First For Every Prompt

- `AGENTS.md`
- `Docs/DOC_PRECEDENCE.md`
- `Docs/HANDOFF.md`
- `Docs/MAP_CONTRACT.md`
- `Docs/SOURCE_OF_TRUTH.md`
- `Docs/MAP_COMPOSER_V2_DESIGN.md`
- `Docs/Promts/CODEX_MAP_PATCH_QUEUE.md`
- `Docs/VISUAL_AUDIO_STYLE_GUIDE.md`
- `Docs/ASSET_PIPELINE.md` + `Docs/ASSET_LICENSE_POLICY.md` only if the prompt also imports runtime asset files

---

## Queue Order

1. Baseline Audit + Cardinal-Start Feasibility
2. Topology Refactor: Cardinal-Start Opening + Stronger Scatter
3. Reconnect Tuning: Cross-Branch Late Arcs
4. Placement Tuning Against New Topology
5. Composer Path-Family Differentiation
6. Asset Hook Completion: Ground / Prop / Landmark
7. Per-Run Visual Variation Verification
8. Residue Cleanup

---

## Prompt 1 — Baseline Audit + Cardinal-Start Feasibility

Task: Read-only audit. Confirm exact current state. Decide whether a `4`-direction cardinal-start opening can fit the `14`-node envelope without breaking `MAP_CONTRACT.md` or save shape.

Deliverable:
- a short audit note that states:
  - current branch count from start
  - current degree distribution at start and across the graph
  - current reconnect count + which branch pairs
  - current path family distribution actually emitted by the composer
- an explicit go/no-go for Prompt 2
- if `14` nodes cannot support a full `4`-branch opening without collapsing leaf/two-way counts, say so and propose either `3+1` (three main branches + one short detour branch) OR explicit escalation to widen node count
- say explicitly whether the reference image should guide:
  - topology feel
  - composer layout feel
  - asset mood only
  - or all three

Write scope:
- docs only (`Docs/DECISION_LOG.md` if D-041 is still missing, plus truth-alignment updates if repo code disagrees with a doc)
- no code changes

Validation:
- `py -3 Tools/validate_architecture_guards.py`
- doc consistency review

---

## Prompt 2 — Topology Refactor: Cardinal-Start Opening + Stronger Scatter

Task: Refactor the frontier-growth topology to produce a stronger cardinal-start opening feel around the center while preserving the current controlled-scatter contract.

Target behavior:
- center start remains node `0`
- opening branches: prefer `4` (`up` / `down` / `left` / `right` feel in presentation space) if Prompt 1 greenlit it; otherwise `3` main + `1` short detour
- per-branch target length varies slightly per seed while keeping total `14` nodes
- degree floor: most nodes degree `2`, at least `SCATTER_MIN_LEAF_COUNT` leaves, a few degree `3`, start degree in `3-4`
- outer reconnects limited and placed at late depth
- no ring-shaped placement artifacts; position assignments stay the composer's job
- key/boss lane must still read as a late push, not as an immediate center-adjacent branch

Implementation guidance:
- refactor `_build_controlled_scatter_frontier_tree`, `_frontier_branch_target_lengths`, `_frontier_branch_priority_order` (and add a 4-branch variant behind the same SCATTER constants if feasible)
- do not touch composer code in this prompt
- extraction-first: if new helpers are needed, put them under `Game/RuntimeState/` and preload from `map_runtime_state.gd`
- preserve `_validate_controlled_scatter_topology` checks; update thresholds only with test coverage
- if a full `4`-branch version harms branch depth or role placement, lock the runtime on `3 main + 1 short detour` instead of forcing symmetry

Write scope:
- `Game/RuntimeState/map_runtime_state.gd`
- new helper files under `Game/RuntimeState/` if needed
- `Tests/test_map_runtime_state.gd`
- `Docs/MAP_CONTRACT.md` only if the topology contract meaning genuinely shifts

Validation:
- targeted map runtime tests
- `100`-seed sweep: connectivity, degree floor, no isolated nodes, opening branch count, key reachability, post-key boss viability
- explicit full suite before closing

---

## Prompt 3 — Reconnect Tuning: Cross-Branch Late Arcs

Task: Tune reconnect logic so outer (leaf-adjacent) nodes can form `1-2` cross-branch arcs each run, giving the "outer ring feels connected" read the user described without collapsing readability.

Target behavior:
- reconnects prefer late-depth nodes, not mid-depth
- at least one reconnect per stage goes across non-adjacent branches (not the immediate neighbor pair)
- reconnect candidate picking still deterministic under current seed logic
- `SCATTER_MAX_RECONNECT_EDGE_COUNT` stays at `2`; do NOT widen it without escalation

Write scope:
- `_apply_controlled_scatter_reconnects`, `_scatter_reconnect_plans`, `_pick_controlled_reconnect_edge`
- related tests

Validation:
- seed sweep: reconnect count per stage, cross-branch distribution, depth distribution
- full suite before closing

---

## Prompt 4 — Placement Tuning Against New Topology

Task: Update family placement so guarantee-floor roles still land correctly on the refactored cardinal-start topology.

Preserve:
- stage guarantee floor from `MAP_CONTRACT.md` (1 start, 6 combat, 1 event, 1 reward, 1 hamlet, 2 support, 1 key, 1 boss)
- `event` and `hamlet` remain dedicated runtime-backed roles
- `start` center, `boss` outer, `key` late-depth without collapsing into immediate boss click
- center-near branches should still expose an early combat route, an early reward route, and an early support route, even if the visual opening shell widens

Write scope:
- `_build_controlled_scatter_family_assignments` + scoring helpers
- related tests

Validation:
- seed sweep for family counts and invariants
- full suite

---

## Prompt 5 — Composer Path-Family Differentiation

Task: Make the four existing path families (`short_straight`, `gentle_curve`, `wider_curve`, `outward_reconnecting_arc`) render visibly distinct on the current board, without renaming them and without introducing presentation-owned save truth.

Target behavior:
- `short_straight`: minimal bend, small subtle natural break-up
- `gentle_curve`: one shallow control point offset
- `wider_curve`: deeper control point offset, reads as a curved road
- `outward_reconnecting_arc`: pushes outward first, then returns inward (detour read, not chord)
- reconnect edges should prefer `outward_reconnecting_arc` when both endpoints sit at late depth
- center-start opening roads should not all read the same; the player should be able to read at a glance whether a route exits straight, bends softly, or takes a wider detour
- per-edge family is derived from graph metadata + board seed, NOT from saved state

Write scope:
- `Game/UI/map_board_composer_v2.gd`
- helpers under `Game/UI/` if needed
- `Tests/test_map_board_composer_v2.gd`
- `scenes/map_explore.gd` only if wiring genuinely needs adjustment

Non-goals:
- no new path family names
- no asset import in this prompt

Validation:
- composer determinism tests
- scene isolation for `scenes/map_explore.tscn`
- portrait review capture before/after

---

## Prompt 6 — Asset Hook Completion: Ground / Prop / Landmark

Task: Open runtime consumption hooks for the still-missing asset families so the user's local-generated assets can drop in by filename.

Priority order:
1. `ui_map_v2_ground_*`
2. `ui_map_v2_prop_*`
3. `ui_map_v2_landmark_*`
4. optional `ui_map_v2_foreground_*`

Target behavior:
- deterministic family pick from presentation seed (never from gameplay RNG)
- missing files fail softly (warning + fallback to current procedural tone), not broken scene
- manifest row is required if any real asset file is added; if only the hook is added with no file, say so in the PR
- the board should be ready for a "center camp + forest routes + outer landmarks" art pass after this prompt closes

Write scope:
- composer + backdrop + canvas wiring
- lookup helpers under `Game/UI/` if needed
- `AssetManifest/asset_manifest.csv` only if runtime files are added in the same patch

Validation:
- composer tests
- scene isolation for `scenes/map_explore.tscn`
- `py -3 Tools/validate_assets.py` only if runtime assets are added in the same patch

---

## Prompt 7 — Per-Run Visual Variation Verification

Task: Add debug/visual verification that three consecutive runs on the same stage with different run seeds produce visibly distinct boards (different branch lengths, different reconnect pair, different family roster at opening).

Deliverable:
- a debug overlay OR a headless test that renders seed-by-seed topology signatures
- a short note listing which inputs contribute to per-run variation and which are locked

Write scope:
- tests
- optional debug overlay (if already present, extend; do not add a new autoload)

Validation:
- `100`-seed sweep
- portrait review capture if overlay changed

---

## Prompt 8 — Residue Cleanup

Task: Remove dead topology/placement/composer helpers that Prompts 2–5 made obsolete, but keep any compatibility path that is still used by save restore or tests.

Compat guard:
- prove a path is unused before removing (grep + tests)
- if unsure, keep it with a short comment explaining why

Write scope:
- same files touched by Prompts 2–5
- related tests only if assumptions changed

Validation:
- architecture guards
- targeted map tests
- scene isolation for `scenes/map_explore.tscn`
- full suite at the final checkpoint

---

## Overnight Rule

- Run Prompt 1 first. If it reports an escalation blocker, stop.
- Prompts 2–4 are runtime; Prompts 5–6 are presentation; Prompts 7–8 are verification/cleanup.
- Do not merge presentation assumptions that depend on asset files that do not exist yet.
- Keep Godot closed while broad external patches are being applied.
- Treat the user's reference image as a composition target and moodboard, not as permission to drift out of the locked repo style guide.

---

## Executing Each Prompt With Codex

If you are using Codex locally via the ChatGPT Pro $100 plan:
- open a terminal in the repo root
- feed one prompt from this file at a time
- start each session by telling Codex to read the Read-First block above, then the specific Prompt block
- ask Codex to summarize the plan before it writes files
- review the diff in its own commit before moving to the next prompt

If you are using another agent (Claude, Copilot agent mode), the same rule applies:
- one prompt per session
- human review of the diff before proceeding

Do not run two prompts of this queue in parallel.
