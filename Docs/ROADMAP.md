# SIMPLE RPG - Active Roadmap

Last updated: 2026-04-25 (hunger/exploration UX pilot landed; next lane is live-socket production asset brief)

This is the active short-horizon roadmap for the repo.
It is a planning file, not an authority doc.
Authority still lives where `Docs/DOC_PRECEDENCE.md` says it lives.

## Measured Current State

- The repo is prototype-playable per `Docs/HANDOFF.md`.
- There is no active prompt-wave queue.
- The closed map `Prompt 01-18` wave is archived under `Docs/Archive/Prompts/2026-04-24-map-wave-01-18-closed/`.
  - It is historical execution evidence only.
  - It is not active queue truth.
  - It must not be used as a fallback authority when active docs answer the question.
- Closed map/UI audit and checklist snapshots are archived under `Docs/Archive/Audits/2026-04-24-closed-reference-audits/`.
  - They are not part of the default working set.
  - They do not route future agents by default.
- The stale map-runtime extraction planning snapshot is archived under `Docs/Archive/Plans/2026-04-24-stale-reference-plans/`.
  - Future extraction work should remeasure current code before planning.
- Retired map art scope/requirements/brief/audit references are archived under `Docs/Archive/Plans/2026-04-24-retired-map-art-reference/`.
  - They are historical reference only and do not route future agents by default.
- The archived `43-62` wave remains superseded history under `Docs/Archive/Prompts/2026-04-23-superseded-map-wave-reset/`.
- The current fixed-board map replacement is closed as prototype structural/presentation evidence, not final art or release-ready visual proof.
- Exactly one default map presentation lane remains:
  - `render_model.path_surfaces`
  - `render_model.junctions`
  - `render_model.clearing_surfaces`
- Non-default map lanes are labeled:
  - `visible_edges` and `layout_edges`: fallback data
  - `ground_shapes`, `filler_shapes`, and `forest_shapes`: wrapper metadata for masks/socket derivation only
  - old draw-only trail/decal/node-plate candidate lane: retired
  - old canopy/filler/ground wrapper asset hook: retired
  - socket-smoke placeholder assets: provisional placeholder evidence only
- The visual wrapper blob/stamp lane is retired from the default board read.
  - `MapBoardCanvas` no longer draws atmosphere circles/arcs or wrapper `ground_shapes`, `filler_shapes`, and `forest_shapes` as visible board layers.
  - `ui_map_board_backdrop.svg` no longer carries non-routing oval/blob atmosphere marks in front of the board field.
  - landmark pocket underlays and procedural landmark identity silhouettes are explicit prototype/debug surfaces only, not normal/default board render.
- Candidate art is not the default next step.
  - Existing socket-smoke placeholder assets are not structural proof.
- Broader cleanup audit preserved one unambiguous default presentation lane and found no evidence-backed active code/asset deletion beyond stale current-state doc cleanup.
  - `visible_edges`, `layout_edges`, `ground_shapes`, `filler_shapes`, and `forest_shapes` remain live fallback/wrapper/prototype metadata as labeled above.
  - Socket-smoke placeholder assets remain provisional until a later art pilot replaces or narrows them with manifest-backed assets.
- The first production-art pilot has landed as candidate socket dressing, not final map art:
  - path-surface brush: `ui_map_art_pilot_path_brush`
  - landmark pilots: `ui_map_art_pilot_boss_landmark`, `ui_map_art_pilot_key_landmark`, `ui_map_art_pilot_rest_landmark`, `ui_map_art_pilot_merchant_landmark`
  - decor/filler stamp: `ui_map_art_pilot_decor_stamp`
  - all remain manifest-tracked candidates with `replace_before_release=yes`
  - art-pilot candidates and socket-smoke placeholders remain manifest-tracked but are hidden from normal/default board render unless explicit prototype/debug canvas flags are enabled
- Source-only candidate SVGs and superseded v1 path/decor masters were removed after selected art-pilot candidates were promoted into manifest-backed source masters and runtime exports.
- Retired `ui_map_v2_*` source-only map art under old ground/landmark/prop lanes was removed; active runtime map assets remain manifest-backed.
- The map canvas now has a narrow road/pocket throat blend pass derived from `render_model` path/clearing links.
  - it is presentation-only and does not change runtime topology or ownership
- Archived old prompt `14-20` remains historically closed as the older guarded fixed-board map-overhaul wave.
- Archived old prompt `21-36` remains historically closed as the combat/content reset and first executable combat slice.

## Closed Lane - Broader Cleanup

Result:
- active prompt/audit/stale-plan routing stayed archived and out of default agent routing
- retired `ui_map_v2_*` draw-lane paths were not found in live runtime/test code
- wrapper/fallback/provisional surfaces still have live tests or derivation roles and were not removed

Safe cleanup applied:
- stale current-state wording in `Docs/HANDOFF.md` and this roadmap

Still out of scope without a dedicated lane:
- save-schema or save-version changes
- flow-state additions
- pending-node ownership moves
- gameplay truth moving into UI
- production art claims
- using candidate art as structural proof
- restoring archived prompt packs as active queue truth

## Closed Lane - Production Art Pilot

Result:
- real repo-authored candidate SVG assets can ride the socket system through `render_model` metadata behind an explicit prototype/debug flag
- boss/key/rest/merchant landmark sockets can resolve to family-specific art-pilot assets when prototype socket dressing is enabled
- path-surface and decor sockets can resolve to pilot art assets when prototype socket dressing is enabled
- unsupported landmark families skip placeholder dressing in normal/default board render instead of inventing broader art coverage

Still true:
- these assets are not final art
- these assets are not structural proof
- blacksmith, hamlet, combat, event, reward, canopy, and broader filler families are not production-art covered by this pilot

## Closed Lane - Hunger / Exploration UX Pilot

Goal:
- make route choice, hunger pressure, support detours, and branch commitment easier to read without changing gameplay ownership

Result:
- route hover/selection affordance already read through marker focus and road emphasis
- hunger-cost visibility was weak because route button text is intentionally hidden and the prior top HUD line only showed open/seen/cleared counts
- support-detour readability existed through icons/pockets, but the visible HUD did not name the prep/support opportunity
- key/boss push commitment existed in hidden/bottom context and route-state chips, but it was not consistently present in the visible top HUD
- candidate art remains hidden in normal/default render and was not used to solve route pressure

Applied:
- visible map HUD now foregrounds next-move hunger cost, route count, prep/support detour state, and key/boss commitment
- the richer route overview model remains presenter-derived from runtime owners
- no save-shape, flow-state, source-of-truth ownership, production-art expansion, or default asset-lane change

Validation:
- targeted map presenter/canvas tests
- asset and architecture validators
- map scene isolation
- portrait review capture
- portrait image diff
- explicit full Godot suite
- `git diff --check`

## Next Lane - Production Asset Brief From Live Socket Metadata

Goal:
- generate a fresh production art brief from current live socket metadata instead of archived brief/audit drafts

Include:
- path brush sockets
- boss/key/rest/merchant landmark sockets
- missing combat/event/reward/blacksmith/hamlet landmark families
- canopy, filler, and decor family sizing/placement needs

Rules:
- do not enable candidate or production art in normal/default board render inside the brief step
- do not restore archived map art briefs as active routing docs
- use current manifest state and live render-model/socket metadata
- keep default render promotion as a later separate decision with provenance, screenshot review, and pixel diff

## Archived Summary

- `Prompt 01-18`: closed map-system wave archived under `Docs/Archive/Prompts/2026-04-24-map-wave-01-18-closed/`
- closed map/UI audit and checklist snapshots: archived under `Docs/Archive/Audits/2026-04-24-closed-reference-audits/`
- stale map-runtime extraction planning snapshot: archived under `Docs/Archive/Plans/2026-04-24-stale-reference-plans/`
- `Prompt 43-62`: superseded mid-wave history archived under `Docs/Archive/Prompts/2026-04-23-superseded-map-wave-reset/`
- old `Prompt 14-20`: historical fixed-board map-overhaul wave
- old `Prompt 21-36`: historical combat/content reset wave
- old `Prompt 06-36`: broader closed-green prompt history archived under `Docs/Archive/Prompts/2026-04-23-closed-green-prompt-packs/`
- retired map art scope/requirements/brief/audit references: archived under `Docs/Archive/Plans/2026-04-24-retired-map-art-reference/`

## After Production Asset Brief

- If the brief is accepted, choose the next lane explicitly from:
  - 5-8 asset candidate generation
  - a small manifest-backed default-render pilot for 2-3 approved assets
  - additional map structural cleanup
  - broader balance/content work
- Do not open a new prompt queue until `ROADMAP.md` names it directly.
- Do not infer the next lane from archived prompt packs, archived audit snapshots, or archived stale plans.
