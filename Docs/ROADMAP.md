# SIMPLE RPG - Active Roadmap

Last updated: 2026-04-24 (Prompt 02 baseline complete as failure evidence; `Prompt 03` is next; archived `43-62` remains superseded historical evidence)

This is the single active roadmap and queue index for the repo.
It is a planning file, not an authority doc.
Authority still lives where `Docs/DOC_PRECEDENCE.md` says it lives.

## Measured Current State

- The repo is prototype-playable per `Docs/HANDOFF.md`.
- The current map codebase includes useful replacement-direction work from the archived wave:
  - runtime topology backbone
  - slot/anchor placement attempts
  - corridor/road hierarchy attempts
  - terrain/filler masking attempts
  - map-adjacent UI alignment
- The archived `43-62` wave is not the live queue.
  - it is stored under `Docs/Archive/Prompts/2026-04-23-superseded-map-wave-reset/`
  - it stays available as historical execution evidence only
  - its queue semantics and green/open claims are superseded
- The active continuation wave is now `Prompt 01-18`.
- Current cursor: `Prompt 01` is closed as a docs/process target-lock pass; `Prompt 02` is closed as a baseline failure-naming pass; `Prompt 03` is next. This does not claim the current map visuals are structurally green.
- Candidate art is not the default next step.
  - current repo candidate assets may be visible from the previous lane, but they are not structural proof
  - new candidate-art work stays closed through this wave
  - `Prompt 14` checks asset-socket readiness only
  - `Prompt 15` decides whether asset smoke and cleanup/hygiene are safe
  - `Prompt 16` may run a provisional candidate asset dressing smoke only if Prompt 15 allows it
  - `Prompt 18` chooses the next lane honestly
- Archived old Prompt `14-20` remains historically closed green as the older guarded fixed-board map-overhaul wave.
- Archived old Prompt `21-36` remains historically closed green as the combat/content reset and first executable combat slice.

## Active Prompt Queue

Execution order:

1. `Prompt 01` - current truth reset and target lock
   - fixed-board small-world target
   - current repo truth vs archived claims
   - candidate art closed
   - docs/process target lock only; no structural green claim
2. `Prompt 02` - baseline reproduction and failure naming
   - fresh capture/readback
   - dark blobs, stroke roads, icon plates, weak hunger/exploration feel
   - test green is not structural green
3. `Prompt 03` - hidden sector grammar contract recheck
   - invisible sector grammar
   - center-outward orientation/emphasis profiles and directional exploration
   - directional and branch identity
4. `Prompt 04` - runtime topology and hunger route shape
   - `MapRuntimeState` owner-preserving graph audit/fix
   - seed variation and local branch pockets
   - hunger pressure through route shape, not rule change
5. `Prompt 05` - slot anchor placement foundation
   - sector-local anchors
   - deterministic jitter
   - center-local start anchors, outward-emphasis variation, and portrait usage
6. `Prompt 06` - local adjacency and corridor routing
   - local sector adjacency read
   - corridor roles and same-corridor conflict
   - roads define route structure
7. `Prompt 07` - render model core payload
   - new nested `render_model.schema_version = 1`
   - `path_surfaces`, `junctions`, `clearing_surfaces`
   - legacy top-level field mapping table identified for wrapper/fallback/retired handling
8. `Prompt 08` - render model masks and slots payload
   - `canopy_masks`, `landmark_slots`, `decor_slots`
   - asset-readiness metadata without asset hookup
   - legacy `ground_shapes`, `filler_shapes`, and `forest_shapes` mapping remains explicit
9. `Prompt 09` - path surface canvas and default lane
   - canvas draws from `render_model`
   - roads as walkable terrain surfaces
   - default-lane switch only with screenshot/readback evidence
10. `Prompt 10` - walker traversal and exploration feel
   - walker follows the board route
   - path preview and motion agree
   - hunger feel stays visual/route-shaped
11. `Prompt 11` - landmark pockets as places
   - nodes read as places/pockets before icons
   - family-specific pocket/arrival grammar
   - key/boss/support distinctness
12. `Prompt 12` - terrain canopy negative space
   - terrain/filler/canopy follow structure
   - dark blob/filler rescue removed or made explicit fallback
   - empty space separates routes and pockets
13. `Prompt 13` - map scene shell and adjacent UI read
   - lower-board/lower-third pressure
   - map-adjacent UI does not damage board read
   - wrapper/fallback scene surfaces named before cleanup
14. `Prompt 14` - asset socket readiness gate
   - no assets added
   - sockets and metadata ready for later art
   - candidate art remains non-proof
15. `Prompt 15` - integrated structural closeout and cleanup gate
   - live + seeded screenshot review
   - exactly one default lane
   - non-default lanes labeled wrapper/fallback/retired
   - gate: run Prompt 16 asset smoke / skip asset smoke and run Prompt 17 cleanup / skip asset smoke and cleanup and go to Prompt 18 hygiene / stop for structural continuation
16. `Prompt 16` - candidate asset dressing smoke
   - no production art claim
   - minimal placeholder/candidate dressing to prove sockets carry assets
   - manifest-tracked provenance with `replace_before_release=yes` where required
17. `Prompt 17` - map legacy cleanup dead code retirement
   - retire only proven non-default map lanes
   - stale code/tests/docs cleanup with reference scans
   - no deletion without Prompt 15 evidence
18. `Prompt 18` - map final hygiene closeout
   - stale prompt/doc/reference scan
   - final validation and screenshot-grounded truth
   - next lane: structural continuation / asset candidate / production art / broader cleanup

## Active Wave Scope Lock

Final target:
- fixed board, not a scrolling diagram
- every seed feels like a different readable small world
- center-local start identity with seed/profile-varied outward route emphasis
- north/south/east/west branch identity, not a fixed upward ladder
- roads divide the world and create route pressure
- walker traverses the board, not a UI diagram
- nodes read as pockets/places before icons
- hunger pressure is felt through route shape and detours
- asset dressing is easy later because sockets exist

In scope:
- structural honesty reproduction
- hidden-sector contract recheck
- `MapRuntimeState` topology work only if owner-preserving and save-shape-neutral
- UI-only placement, corridor, path-surface, walker, landmark, terrain, and socket presentation work
- map scene shell and adjacent-UI read
- integrated structural closeout, optional asset smoke, cleanup tail, and final next-lane decision

Out of scope by default:
- save-schema or save-version changes
- flow-state additions
- pending-node ownership moves
- gameplay truth moving into UI
- new candidate art or art-pack work inside this wave
- reframing candidate art as final or release-safe
- restoring archived `43-62` as live queue

## Validation Checkpoints

- Every implementation prompt runs:
  - `py -3 Tools/validate_architecture_guards.py`
  - targeted map tests for the touched slice
  - `scenes/map_explore.tscn` isolation
  - portrait capture at `1080x1920`
  - `git diff --check`
- Full suite checkpoints:
  - `Prompt 04`
  - `Prompt 09`
  - `Prompt 12`
  - `Prompt 15`
  - `Prompt 16`
  - `Prompt 17`
  - `Prompt 18`
- Screenshot review must include:
  - fresh start frame
  - seeded mid/late `11`, `29`, `41`
  - at least two additional random seed sweeps or an explicit deferral reason

## Archived Summary

- `Prompt 43-62`: archived as superseded mid-wave history under `Docs/Archive/Prompts/2026-04-23-superseded-map-wave-reset/`
- Archived old `Prompt 14-20`: historical fixed-board map-overhaul wave
- Archived old `Prompt 21-36`: historical combat/content reset wave
- Archived old `Prompt 06-36`: broader closed-green prompt history remains archived under `Docs/Archive/Prompts/2026-04-23-closed-green-prompt-packs/`

## After This Wave

- Open later asset candidate work only if `Prompt 18` says the structure and sockets are ready.
- If `Prompt 18` chooses production art, use `Docs/Promts/Next/production_art_wave_stub.md` only as an inactive starting stub and rewrite it into a real active wave before implementation.
- Continue structural work if Prompt 15 or Prompt 18 finds the small-world read still short.
- Open broader balance/content or expansion work only after this map wave stops contradicting itself.
