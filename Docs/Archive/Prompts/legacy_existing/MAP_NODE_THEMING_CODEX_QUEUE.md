# MAP NODE THEMING CODEX QUEUE

Purpose: ordered Codex prompt chain to give every live node family a themed player-facing display name without moving gameplay truth.
Scope: presentation-layer display name mapping only. Runtime owner, save shape, flow transitions, and stable family ID strings stay untouched.

Master execution plan that sequences this file together with redesign, assets, and extraction: `Docs/Promts/MAP_OVERHAUL_EXECUTION_PLAN.md`.

This queue is a narrow companion to:
- `Docs/Promts/MAP_REDESIGN_CODEX_QUEUE.md` (topology / placement / composer redesign)
- `Docs/Promts/AI_ASSET_ROADMAP_V2.md` (asset production)

Authority order for conflicts:
1. `Docs/MAP_CONTRACT.md`
2. `Docs/CONTENT_ARCHITECTURE_SPEC.md`
3. `Docs/SOURCE_OF_TRUTH.md`
4. `Docs/VISUAL_AUDIO_STYLE_GUIDE.md`
5. this file

---

## 0. Current Repo Truth This Queue Starts From (Certain)

- Live runtime node families (`10` total): `start`, `combat`, `event`, `reward`, `hamlet`, `rest`, `merchant`, `blacksmith`, `key`, `boss`.
- One player-facing rename is already live: `event` -> `Trail Event`.
- `hamlet` has a stage-derived `hamlet_personality` read (`pilgrim` / `frontier` / `trade`) that does NOT widen the save payload.
- `side_mission` is a legacy alias only. It is NOT a separate live family.
- `Roadside Encounter` is a movement interruption. It is NOT a map node.
- `slot_type` values (`opening_support`, `late_primary`, `late_event`, `late_hamlet`) are placement slots, NOT node types.
- Current stage guarantee floor: `1` start, `6` combat, `1` event, `1` reward, `1` hamlet, `2` support, `1` key, `1` boss`.
- Current player-facing family-name maps are duplicated in `Game/UI/map_explore_presenter.gd` and `Game/UI/transition_shell_presenter.gd`.

---

## 0.5 Locked Direction For This Pass

- Code-side family IDs stay stable.
- Player-facing map labels should read like route-board places, objects, or encounters inside the world, not raw system buckets such as `reward` or `hamlet`.
- The naming pass exists to support the center-start forest-route redesign and later asset work.
- Reusable environment families (`ground`, `prop`, `landmark`, `foreground`) stay generic. Themed names may guide node markers, copy, and hero-landmark concepts, but they must NOT smuggle gameplay truth into reusable floor art.
- `event -> Trail Event` stays locked. It is already live and is the reference pattern this queue generalizes.

---

## 0.75 Current Table + Example Direction (Examples, Not Approved Yet)

The last column below is example language only. It is NOT final until the user approves a naming set.

| Code family | Live player-facing read today | Example thematic names |
|---|---|---|
| `start` | start / start-like map read | `Waymark`, `Trailhead`, `Traveller's Stone`, `Origin Cairn` |
| `combat` | combat | `Ambush`, `Trouble on the Path`, `Hunt`, `Skirmish` |
| `boss` | boss / boss gate | `Warden`, `Gatekeeper`, `Threshold Foe`, `Warden Gate` |
| `event` | `Trail Event` | keep as-is unless the user explicitly changes it |
| `reward` | reward | `Hidden Cache`, `Forgotten Stash`, `Traveller's Find`, `Cache` |
| `key` | key | `Warden's Sigil`, `Gate Sigil`, `Lockstone`, `Keystone` |
| `rest` | rest | `Campfire Hollow`, `Quiet Clearing`, `Pilgrim Fire` |
| `merchant` | merchant | `Pedlar's Post`, `Wandering Trader`, `Road Pedlar`, `Pedlar Camp` |
| `blacksmith` | blacksmith | `Forge Stop`, `Travelling Smith`, `Forge Camp` |
| `hamlet` | hamlet | `Waypost`, `Pilgrim's Rest`, `Frontier Waypost`, `Trader's Waypost` |

---

## Decision Gate Before Prompt 2

Prompt 2 must NOT lock final strings until the user approves answers to these three questions or explicitly accepts the recommended default.

### Q1 - Naming Tone

- A: short, iconic, closer to `Slay the Spire`
- B: heavier, diegetic, closer to `Darkest Dungeon`
- C: mixed

### Q2 - Stage Variance

- A: one display name for every family across all stages
- B: multiple stage-specific names across many families
- C: only `hamlet` varies by stage through the already-live `hamlet_personality` read

### Q3 - Surface Scope

- A: map board only
- B: map + transition + combat titles
- C: map + transition

Recommended default (explicitly a recommendation, not certain): `C / C / C`.

Why this default:
- mixed tone gives enough theme without bloating every label
- hamlet-only variance uses an already-live runtime read and avoids save risk
- map + transition gives visible payoff without forcing unnecessary combat-title churn

---

## Locked Constraints For Every Prompt

- Stable family ID strings (`combat`, `hamlet`, `rest`, etc.) do NOT change. They are save-critical and flow-critical.
- No save-schema change. No new flow state. No new autoload. No new command family.
- Display name mapping lives in the presentation layer (`Game/UI/`), not in `Game/RuntimeState/`, not in `Game/Application/`, not in `Game/Core/`, and not in save data.
- `hamlet_personality` is the only existing per-node variant hint. Do NOT add a second per-node save field just to support themed names.
- Render language stays `Dark Forest Wayfinder`. Themed names must fit that tone.
- Unknown family input must still fail soft by returning the raw input string.

## Stop And Escalate If

- any prompt proposes writing the themed name into save data
- any prompt proposes changing a stable family ID string in runtime code
- any prompt proposes changing flow routing based on the display name
- any prompt proposes a new `ContentDefinitions/` family just to host themed names
- any prompt proposes gameplay logic like `if display_name == ...`

---

## Read-First For Every Prompt

- `AGENTS.md`
- `Docs/DOC_PRECEDENCE.md`
- `Docs/HANDOFF.md`
- `Docs/MAP_CONTRACT.md`
- `Docs/SOURCE_OF_TRUTH.md`
- `Docs/CONTENT_ARCHITECTURE_SPEC.md`
- `Docs/VISUAL_AUDIO_STYLE_GUIDE.md`
- `Docs/SAVE_SCHEMA.md` only to confirm the themed name does NOT land there
- this file

---

## Queue Order

1. Audit + naming decision capture
2. Approved display-name helper
3. Map presenter wiring
4. Transition / combat / overlay wiring by approved scope
5. Hamlet personality variant pass
6. Tests + portrait review
7. Doc sync

---

## Prompt 1 - Audit + Naming Decision Capture

Task: read-only audit. Confirm every current player-facing surface where a node family name reaches the player, then summarize what still needs user approval.

Required audit output:
- exact list of player-facing surfaces rendering family names today
- list of places where `event` is already mapped to `Trail Event`
- list of places still rendering the raw family string directly to the player, if any
- short note on whether any existing UI already expects short labels versus longer diegetic labels
- one short asset-facing note explaining which themed names may influence later marker / hero-landmark concepts and which reusable environment families must stay generic
- a go / no-go note for Prompt 2
- a small Q1 / Q2 / Q3 decision block copied from this file into the PR description

Write scope:
- docs only, and only if an authority row is outdated against runtime truth
- no code changes

Validation:
- `py -3 Tools/validate_architecture_guards.py`
- doc consistency review

Deliverable:
- one audit PR
- the PR description must include Q1 / Q2 / Q3 plus the recommended default `C / C / C`

---

## Prompt 2 - Approved Display-Name Helper

Precondition:
- the user has either:
  - answered Q1 / Q2 / Q3 and approved a naming set, or
  - explicitly accepted the recommended default

Task: create a single presentation-layer helper that maps stable family IDs to approved themed display names.

Target behavior:
- one helper file under `Game/UI/`; proposed file: `Game/UI/map_node_display_names.gd`
- exposes a pure function roughly shaped like `display_name_for(family: String, context: Dictionary) -> String`
- `context` may carry `stage_index` and `hamlet_personality`; helper must NOT require them
- default / fallback return value is the raw family string so missing mapping fails soft
- `event` mapping keeps returning `Trail Event` unless the user explicitly approved a different label
- helper is stateless, pure, no autoload, no signals

Write scope:
- new file `Game/UI/map_node_display_names.gd`
- `Tests/test_map_node_display_names.gd` with:
  - every live family returns a non-empty string
  - unknown family returns the raw input
  - `event` returns the approved event label

Non-goals:
- no scene wiring yet
- no runtime file changes
- no content definition changes

Validation:
- new targeted test file passes
- `py -3 Tools/validate_architecture_guards.py`

---

## Prompt 3 - Map Presenter Wiring

Task: replace the map presenter's direct family-to-label usage with calls to the helper from Prompt 2.

Target behavior:
- map board labels, tooltips, focus-panel titles, current-anchor text, and node hint chips route through `map_node_display_names.gd`
- hit targets, marker positions, overlay anchors, and gameplay reads are unchanged
- resolved / locked state modifiers still stack on top of the themed name the same way they do today

Write scope:
- `Game/UI/map_explore_presenter.gd`
- `Game/UI/map_explore_scene_ui.gd` only if needed for string plumbing
- `Tests/test_map_explore_presenter.gd` if coverage already exists for this surface; otherwise add narrow coverage for the rename path
- do NOT change `scenes/map_explore.gd` structure

Validation:
- portrait review capture before / after
- targeted presenter tests

---

## Prompt 4 - Transition / Combat / Overlay Wiring

Task: apply themed names to every player-facing surface allowed by the approved Q3 scope.

If Q3 = A:
- skip this prompt entirely and go to Prompt 5

If Q3 = B:
- extend helper usage into:
  - `Game/UI/transition_shell_presenter.gd`
  - combat titles only if a raw family string currently leaks there
  - reward / support overlay headers only if they currently render the raw family

If Q3 = C:
- extend helper usage into:
  - `Game/UI/transition_shell_presenter.gd`
  - reward / support overlay headers only if they currently render the raw family
- do NOT retheme combat titles

Hard rule:
- the helper still returns strings only. No signals, no state, no owner move.

Validation:
- touched-surface tests
- full suite before closing this prompt

---

## Prompt 5 - Hamlet Personality Variant Pass

Task: use the existing `hamlet_personality` read to give hamlet a stage-flavored display name without widening save.

If Q2 = A:
- skip stage variance; keep one approved hamlet name

If Q2 = B:
- do NOT widen into multi-family stage variance until the user has approved a full variant table

If Q2 = C:
- implement hamlet-only stage variance through `hamlet_personality`

Target behavior:
- `display_name_for("hamlet", {"hamlet_personality": "pilgrim"})` returns the approved pilgrim variant
- missing personality falls back to the approved neutral hamlet name
- personality remains a derived read; no new save field is added

Write scope:
- `Game/UI/map_node_display_names.gd`
- `Tests/test_map_node_display_names.gd`

Validation:
- targeted test coverage for hamlet variants and fallbacks
- `py -3 Tools/validate_content.py`

---

## Prompt 6 - Tests + Portrait Review

Task: verify themed names render correctly across a full stage run at portrait resolutions and do not leak into save data.

Required checks:
- save / load a stage mid-run; load produces the same themed labels because save still holds family IDs, not names
- seed-sweep a stage and confirm every themed label appears on the expected family count
- portrait review capture on `1080x2400`, `1080x1920`, and `720x1280`
- confirm no gameplay test asserts against the old raw family string where the new themed string now appears
- confirm the approved longest names still read cleanly on portrait surfaces

Write scope:
- tests only
- no new production behavior

Validation:
- targeted tests
- full suite
- portrait capture via `Tools/run_portrait_review_capture.ps1`

---

## Prompt 7 - Doc Sync

Task: after the functional passes land, update docs so the display-name mapping is discoverable.

Required updates:
- `Docs/MAP_CONTRACT.md` - append a short "Player-Facing Display Names" subsection that lists the approved family -> display name map and notes that stable IDs did NOT change
- `Docs/HANDOFF.md` - add a short current-state line
- `Docs/DECISION_LOG.md` - add a row capturing the Q1 / Q2 / Q3 answers and the approved mapping stance

Non-goals:
- no new authority doc
- no change to the node-family list in `Docs/CONTENT_ARCHITECTURE_SPEC.md`
- no change to `Docs/SAVE_SCHEMA.md`

Validation:
- doc consistency review

---

## Overnight Rule

- Run Prompt 1 first.
- Prompt 2 should not start until the naming approval gate is satisfied.
- Prompts 3-5 should be reviewed one at a time, not batched.
- Prompts 6-7 close the pass.

---

## Interaction With Other Queues

- This queue is implementation-independent from `Docs/Promts/MAP_REDESIGN_CODEX_QUEUE.md`, but it is NOT art-independent from `Docs/Promts/AI_ASSET_ROADMAP_V2.md`.
- Prompt 1 from this queue should happen before serious landmark or node-marker concept work so the approval gate is visible early.
- Prompt 2 from this queue should land before serious landmark or node-marker concept work because the approved naming language defines later concept prompts.
- Ground and prop production can still proceed before this queue closes because those families stay generic.
- Do NOT merge this queue into the redesign queue. Keeping them separate protects the save-safe / presentation-only boundary.
- `Docs/Promts/MAP_RUNTIME_STATE_EXTRACTION_PLAN.md` is unrelated; extraction work happens after both queues close.
