# SIMPLE RPG — Map Board 3-Pass Render + Prototype Asset Plan

## Purpose
This document defines the intended **map board rendering pipeline** for the current SIMPLE RPG prototype.

The goal is to make the map work in a clear production order:

1. **Generate nodes first**
2. **Draw paths from the realized graph**
3. **Fill the remaining space with presentation-only assets**

This is not a save-schema redesign and it is not a broad gameplay refactor.
It is a focused implementation plan for making the map feel like a **graph-native forest pocket** instead of a static painted background.

---

## Why this exists
Right now the project already has:
- a bounded center-start map contract
- controlled-scatter runtime graph generation
- a composer that derives board positions and edge trails from runtime truth
- a prototype map asset kit in progress

But the intended visual/technical pipeline needs to be made explicit and consistently implemented.

The desired runtime/presentation order is:
- **graph truth first**
- **trail composition second**
- **decor / filler / atmosphere last**

---

## Design Goal
The board should feel like:
- a **top-down mobile-readable exploration pocket**
- a **forest route map** carved into dense surrounding space
- a **procedural node graph** with readable trails
- a board where **nodes are primary gameplay anchors**, not painted into the background

The board should **not** feel like:
- a fixed lane map
- a concentric ring board
- a single hand-painted background that fights the random graph
- a UI slot layout pretending to be a map

---

## Hard Boundaries

### Runtime truth stays in runtime owners
- `MapRuntimeState` remains the owner of:
  - node identity
  - node family
  - adjacency
  - node state
  - current node
  - key / boss-gate truth
  - pending node context

### Presentation stays derived
- `MapBoardComposerV2` remains presentation-only
- scene/UI must not become layout truth owners
- no board coordinates, spline points, masks, or decor placements should become authoritative save truth unless absolutely unavoidable

### Save-safe rule
- do not redesign save schema unless implementation proves it is required
- prefer deterministic recomposition from current runtime truth + seed

---

## The 3-Pass Board Pipeline

## Pass 1 — Node Graph Pass
This pass is gameplay-authoritative.

### Responsibility
Produce only the realized map graph and node semantics.

### Output
- node ids
- node families
- node states
- adjacency
- current node
- discovered / hidden / locked state
- stage-local graph truth

### Non-goals
This pass should **not** decide:
- final visual world positions as authored truth
- spline path art
- forest filler placement
- canopy art
- decals
- background atmosphere

### Design intent
The map should first exist as a **real graph**, not as a painting.

---

## Pass 2 — Path / Clearing Composition Pass
This pass is presentation-only and derived from the realized graph.

### Responsibility
Turn the runtime graph into a readable board structure.

### Output
- node world positions
- edge/path geometry
- path family selection
- clearing anchors around nodes
- local board focus / framing data

### Rules
- node positions should derive from graph structure
- path geometry should connect realized adjacent nodes only
- clearings should feel intentionally carved out for node overlays
- no new gameplay truth should be invented here

### Desired result
After this pass, the player should already be able to read:
- where they are
- what routes branch out
- which pockets are near / far
- which node areas are visually reserved

Even if all decor is disabled, the board should still be understandable.

---

## Pass 3 — Environment Fill Pass
This pass is presentation-only atmosphere and filler.

### Responsibility
Fill the remaining empty board space after node and path readability is already established.

### Output
Deterministic or semi-deterministic placement of:
- canopy clumps
- bush clusters
- path-edge filler
- clearing decals
- ground clutter decals
- fog pockets
- small stone / ruin accents
- subtle board atmosphere layers

### Rules
- do not block node clearings
- do not overpaint or hide path readability
- do not leak hidden gameplay information
- do not turn decor placement into save-authoritative truth
- keep portrait readability first

### Desired result
The board should feel like:
- paths cut through a forest pocket
- the map is surrounded by world texture
- node areas are readable gameplay spaces
- the map no longer looks like bare geometry

---

## Rendering / Asset Philosophy
The system should **not** rely on generating one complete final background per run.
Instead it should use a modular kit:

- runtime graph decides structure
- composer decides positions/trails/clearings
- small reusable asset pieces decorate the rest

This keeps the random map system compatible with visuals.

---

## Prototype Asset Kit (Minimum Useful Set)

## A. Node Assets
Use a shared visual shell where possible.

### Recommended structure
- 1 shared node plate / shell
- 1 state rim family
- 1 icon/emblem per node type

### Current node families to support
- `start`
- `combat`
- `event` (player-facing: Trail Event)
- `reward`
- `hamlet`
- `rest`
- `merchant`
- `blacksmith`
- `key`
- `boss`

### Prototype target
Not final painted production art.
Readable, consistent, top-down, mobile-safe prototype art is enough.

---

## B. Path Assets
Paths should mostly be geometry + texture/decal, not unique painted route illustrations.

### Minimum useful set
- 1 dirt trail base texture
- 1 darker/worn trail variation
- 2–4 path-edge filler decals
- 1 subtle broken/relic trail overlay

### Important rule
Path visuals should reinforce the trail geometry, not replace it.

---

## C. Forest / Filler Assets
This is what prevents the board from looking empty.

### Minimum useful set
- 4–6 canopy clumps
- 3–4 path-edge vegetation fillers
- 3–4 ground clutter decals
- 2 clearing decals
- 2 fog/shadow patches
- 2 tiny ruin/stone accent stamps

### Important rule
These should be:
- top-down
- reusable
- transparent background assets
- low-composition filler pieces, not full scenes

---

## Art Direction Rules
Use the current project style direction:
- dark forest wayfinder
- readable before atmospheric
- stylized before realistic
- mobile-readable
- silhouette clarity first

Reject outputs that drift into:
- photorealistic rendering
- anime/chibi style
- pixel art
- watercolor softness
- inconsistent perspective/light direction
- giant scene compositions instead of reusable assets

---

## AI Asset Production Guidance
For AI-assisted asset generation, treat outputs as:
- isolated reusable assets
- transparent-background stamps
- top-down orthographic sprites/decals
- filler/decor pieces
- node shell + emblem variations

Do **not** ask the model for:
- one full final procedural map painting
- cinematic centered scenes
- fixed route illustrations that encode gameplay layout

Good asset prompt language:
- `single isolated asset`
- `strict top-down orthographic`
- `transparent background`
- `reusable filler stamp`
- `mobile-readable`
- `stylized fantasy forest`

Bad prompt language for this task:
- `beautiful full forest scene`
- `central composition`
- `radiating path illustration`
- `cinematic environment`

---

## Suggested Implementation Order

### Phase 1 — Audit and pipeline lock
- verify current separation between runtime graph truth and composer output
- document where path/clearings/decor are currently mixed
- identify old fallback logic that still behaves like a parallel layout system

### Phase 2 — Make Pass 1 explicit
- ensure runtime graph generation is the unquestioned first stage
- confirm composer consumes realized graph rather than reinterpreting map truth

### Phase 3 — Make Pass 2 explicit
- ensure composer builds positions + path geometry + clearings from graph truth
- keep this deterministic and save-safe

### Phase 4 — Prototype asset hookup
- add a small modular map kit
- bind node plates/icons, trail decals, canopy clumps, and clearing decals
- keep fallback behavior narrow and presentation-only

### Phase 5 — Tuning and cleanup
- prune dead/stale presentation leftovers caused by the new pipeline
- sync docs to checked-out truth
- validate readability on portrait aspect ratios

---

## Acceptance Criteria
The work is successful when:

### Structure
- the board is visibly built in node -> path -> decor order
- runtime graph truth stays in runtime owners
- no save-authoritative decor/layout drift is introduced

### Visual readability
- nodes read as gameplay anchors
- paths are readable without decor
- decor improves atmosphere without hurting route clarity
- clearings remain visible and usable for overlays
- the board reads as a forest pocket, not a bare graph or lane UI

### Asset practicality
- the prototype kit is modular and reusable
- the map can vary without needing a unique painted background each run
- node/path/filler assets are good enough for testing even if they are not final production art

### Safety
- deterministic recomposition remains possible
- hidden information is not leaked by decor/path placement
- emergency fallback logic, if still needed, is clearly secondary

---

## Questions Codex Should Answer Before Patching
1. Where are the current pass boundaries already clean, and where are they mixed?
2. Is `MapBoardComposerV2` already sufficient for pass 2, or does it still combine path + decor responsibilities too loosely?
3. What is the narrowest safe place to add asset fill placement?
4. Which current fallback branches can be retired safely, and which must remain emergency-only?
5. What is the minimum prototype asset kit required to make the map immediately feel better?

---

## Explicit Non-Goals
This document does **not** ask for:
- full free-form graph generation beyond the current bounded prototype direction
- final premium art production
- save-schema redesign by default
- broad gameplay rewrites outside the map board pipeline
- moving map truth into UI/scene code

---

## Short Summary
Desired board pipeline:

**Graph first -> trails second -> decor last**

If a patch violates that order, it is probably moving in the wrong direction.
