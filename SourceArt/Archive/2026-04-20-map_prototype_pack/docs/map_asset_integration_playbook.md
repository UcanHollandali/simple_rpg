# Map Asset Integration Playbook for Codex

## Purpose
This file explains **how the map assets should be used in the current repo**.
It is not an art-style brainstorm and it is not a broad architecture redesign.
It is a practical implementation playbook for integrating the current and upcoming map assets into the live `simple_rpg` map board.

Use this together with:
- `Docs/MAP_CONTRACT.md`
- `Docs/MAP_COMPOSER_V2_DESIGN.md`
- `Docs/HANDOFF.md`
- `AssetManifest/asset_manifest.csv`

---

## Current repo truth to preserve

### Runtime / ownership boundaries
- `MapRuntimeState` owns **graph truth**:
  - node ids
  - node families
  - adjacency
  - node state
  - current node
  - pending node context
  - key / boss-gate / support revisit truth
- `RunSessionCoordinator` owns movement resolution and roadside interruption continuation.
- `MapBoardComposerV2` is **derived presentation only**.
- Scene/UI layers must **consume** composition output, not become the source of map truth.

### Important rule
**Do not solve map visuals by drawing one giant full-board background per run.**
The correct approach is:
1. runtime graph
2. derived node positions + trails + clearings
3. presentation-only asset placement

---

## Current live map-asset baseline
These are already conceptually/live integrated in the repo and should be treated as the baseline, not thrown away casually:

### Existing board-facing prototypes
- canopy clumps
- clearing decals
- node state plates
- trail family decals
- dedicated `Trail Event` icon
- refreshed side-mission / hamlet icon lane
- refreshed node icon family for some node types

### Current path-family vocabulary
Preserve this unless there is a very strong reason to change it:
- `short_straight`
- `gentle_curve`
- `wider_curve`
- `outward_reconnecting_arc`

### Current runtime-backed node families
- `start`
- `combat`
- `event`
- `reward`
- `hamlet`
- `rest`
- `merchant`
- `blacksmith`
- `key`
- `boss`

Player-facing notes:
- `event` is shown as `Trail Event`
- `hamlet` is the support-family settlement stop

---

## The intended map visual pipeline

### Pass 1 — Graph truth
Owned by runtime.
No art decisions here.
Only:
- node identities
- families
- discovered/resolved/locked state
- adjacency
- current node
- reachable nodes

### Pass 2 — Board composition
Owned by `MapBoardComposerV2`.
This pass derives:
- world positions for visible/relevant nodes
- trail geometry/path family per edge
- clearing pocket selection
- decor placement anchors / masks

### Pass 3 — Asset rendering / placement
Owned by presentation.
This pass uses assets to render:
- node shells / node icons
- state plates
- trail decals
- clearing decals
- canopy clumps
- filler / clutter / fog / ruin patches

**Presentation state must not be written back into runtime truth.**

---

## What kinds of assets we should use

### A. Node assets
These are the main route-reading assets.

#### Correct construction model
Do **not** paint 10 totally unrelated node illustrations.
Instead:
- create **1 shared node shell**
- create **node-specific center props / symbols**
- combine them consistently

#### Shared shell idea
One common reusable base:
- top-down orthographic
- mossy stone shell / plate / pedestal
- same silhouette family
- same lighting
- same brush language
- transparent background
- readable on mobile

#### Node-specific center variants
1. `start` → lantern / waypoint flame
2. `combat` → threat marker / crossed blades / small hostile camp symbol
3. `event` / `Trail Event` → shrine / rune stone / curiosity marker
4. `reward` → supply cache / chest / rations bundle
5. `hamlet` → warm hut / settlement sign
6. `rest` → campfire + bedroll
7. `merchant` → bags / small trade stall / crate stack
8. `blacksmith` → anvil / ember glow / forge tools
9. `key` → relic key on holder
10. `boss` → cursed gate / altar / skull brazier

#### State overlays
These should stay separate from the center identity when possible:
- reachable
- resolved
- locked
- special/progression emphasis

That lets one node type reuse the same identity while changing board state cleanly.

---

### B. Trail / path assets
These are not a single big road image.
They are reusable pieces tied to path families and edge rendering.

Use small transparent assets for:
- straight trail decal
- gentle-curve trail decal
- wider-curve trail decal
- reconnect arc trail decal
- path-edge filler A
- path-edge filler B
- junction decal
- breakup decal
- relic-wear overlay

Important:
- trails must support composed edge geometry
- trail assets should not encode map truth
- path art must follow the already-derived path, not replace it

---

### C. Clearing / ground assets
Use small ground assets to make node pockets intentional.

Needed types:
- neutral clearing decal
- special clearing decal (key/boss/reward emphasis)
- subtle ground clutter A
- subtle ground clutter B
- ruin-stone patch

These should sit **under** node plates and trail ends, not override them.

---

### D. Forest fill assets
These are what make the board feel like a real forest pocket instead of a bare graph.

Needed types:
- small canopy clump
- medium canopy clump
- large canopy clump
- path-edge vegetation filler
- soft fog patch
- soft shadow pocket
- minor ruin/boulder filler

These are decorative and spacing-aware.
They must not block clearings or make routes unreadable.

---

## Practical layering model
Use the board in this general stack order:

1. board/backdrop shell
2. trail decals / trail family art
3. clearing decals
4. forest fill / canopy / clutter / fog
5. node state plates
6. node shell / node center prop or icon
7. marker/highlight/current/reachable emphasis

If the current scene already expects a slightly different draw order, adapt carefully, but keep this visual priority:
- route readability first
- node readability second
- atmosphere third

---

## What Codex should implement

### Codex should NOT
- move map truth into the scene
- save board layout as new authoritative runtime truth
- replace procedural composition with a single static painted map
- make asset filenames into gameplay logic keys
- widen scope into broad UI rewrite unless required

### Codex SHOULD
- treat assets as presentation-only hooks
- keep runtime graph and board composition boundaries intact
- bind assets by family/state/path-family/decor-role
- preserve deterministic composition from runtime truth + seed
- keep fallback behavior narrow and clearly non-authoritative
- update `AssetManifest` for every new runtime-facing asset
- place source masters in `SourceArt/Generated/Map/` or the nearest correct source folder
- place runtime assets under the existing `Assets/UI/Map/...` or `Assets/Icons/...` structure

---

## Recommended implementation order

### Step 1 — audit current hooks
Codex should first identify:
- where node icons are currently selected
- where state plates are applied
- where trail family art is selected
- where clearing/canopy hooks already exist
- what still uses procedural fallback only

### Step 2 — stabilize the shared node shell approach
Implement or prepare a shell-first node rendering model:
- common shell
- center identity per family
- state overlay separate where possible

### Step 3 — fill missing node families
Highest priority missing/weak families to complete cleanly:
- `key`
- `boss`
- `combat`
- any currently weak support family surface

### Step 4 — strengthen trail support
Use the existing path-family lane and make sure each path family has:
- a usable decal
- edge-filler support
- repetition-break support

### Step 5 — strengthen forest pocket fill
Use canopy/filler/clutter/fog to make the map read as a forest pocket without harming route clarity.

### Step 6 — validate board readability
After each wave:
- portrait readability check
- current/reachable state readability check
- hidden info leak check
- no scene-level ownership drift

---

## Concrete asset waves

### Wave 1 — must-have node base
1. neutral shared node shell
2. start center variant
3. combat center variant
4. trail event center variant
5. reward center variant
6. hamlet center variant
7. rest center variant
8. merchant center variant
9. blacksmith center variant
10. key center variant
11. boss center variant

### Wave 2 — state readability
12. reachable plate/overlay
13. resolved plate/overlay
14. locked plate/overlay
15. special/progression plate/overlay

### Wave 3 — trail support
16. straight trail
17. gentle curve trail
18. wider curve trail
19. reconnect arc trail
20. edge filler A
21. edge filler B
22. junction decal
23. breakup decal
24. relic-wear overlay

### Wave 4 — clearing and environment support
25. neutral clearing decal
26. special clearing decal
27. ground clutter A
28. ground clutter B
29. ruin stones patch
30. canopy small
31. canopy medium
32. canopy large
33. fog patch
34. shadow pocket

---

## Asset naming and storage rules

### Source masters
Store masters in:
- `SourceArt/Generated/Map/` for generated temporary sources
- `SourceArt/Edited/...` if manually refined versions are created later

### Runtime assets
Use the existing runtime-facing structure where possible:
- `Assets/UI/Map/NodePlates/`
- `Assets/UI/Map/Trails/`
- `Assets/UI/Map/Clearings/`
- `Assets/UI/Map/Canopy/`
- `Assets/Icons/`

### Manifest
Every new asset must get a row in `AssetManifest/asset_manifest.csv`.
Track at minimum:
- asset id
- area
- status
- source tool/origin
- license / ownership
- AI used yes/no
- commercial status
- master path
- runtime path
- replace-before-release
- notes

---

## How to bind the assets in code

### Node family binding
Map node family → visual identity layer.
Keep this in presentation code, not runtime truth.

Suggested conceptual model:
- family selects center variant or icon
- node state selects overlay/plate
- family + state combine into final displayed node surface

### Trail family binding
Map composed edge trail family → trail asset selection.

Suggested conceptual model:
- composed edge already knows family label
- that label chooses the trail art asset
- edge filler/breakup overlays are optional deterministic presentation sugar

### Clearing binding
Node family / importance / state → clearing decal choice.

Suggested conceptual model:
- regular nodes use neutral clearing
- boss/key/special nodes can use special clearing
- do not make every node use the dramatic special version

### Forest fill binding
Use composer-derived decor anchors / masks / spacing rules.

Suggested conceptual model:
- canopy clusters go to board perimeter and non-route pockets
- clutter/fog go to low-information empty spaces
- do not cover node pockets or route decision zones

---

## Acceptance criteria
Codex should consider this successful only if:

### Visual / functional
- board still reads clearly in portrait
- routes remain readable
- node families remain readable
- current/reachable/resolved/locked states remain readable
- key/boss are visually distinct enough
- board feels more like a forest pocket, not a bare graph

### Technical
- runtime truth ownership did not move
- save shape did not expand just for art/layout state
- composed board remains deterministic from current truth
- fallback logic remains narrow and non-authoritative
- asset paths are valid
- `AssetManifest` is updated

### Scope control
- no broad architecture rewrite
- no broad scene ownership rewrite
- no giant static background solution pretending to be procedural

---

## What to ask Codex to do first
Use this exact intent:

1. Audit the current map asset hooks.
2. Identify which asset lanes are already live vs still fallback-only.
3. Integrate the shared node shell + node family center-variant model without moving runtime truth.
4. Fill the highest-priority missing node families.
5. Strengthen trail + clearing + canopy hooks.
6. Update the manifest and run changed-area validation.

---

## Final note
The goal is **not** “paint a full map”.
The goal is to make the current procedural graph-backed map board feel intentional by using a reusable asset kit.

Short version:
- graph first
- trails second
- forest fill third
- assets are modular
- presentation stays derived
