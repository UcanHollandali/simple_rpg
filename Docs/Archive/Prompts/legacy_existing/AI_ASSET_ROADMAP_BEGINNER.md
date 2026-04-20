# AI ASSET ROADMAP BEGINNER

> **Note (2026-04-18):** For the active user setup on this repo (RTX `5080`, ChatGPT Pro `$100` with Codex, Claude `$20`), the day-to-day production roadmap is `Docs/Promts/AI_ASSET_ROADMAP_V2.md`.
>
> This beginner file is kept as:
> - a generic reference for when the setup assumption changes
> - the source of the naming rules and daily-loop discipline that V2 still inherits
>
> If V2 and this file disagree, V2 wins for day-to-day work.

Purpose: practical beginner guide for producing map-facing visual assets for `simple_rpg`.
Audience: someone who wants the smallest safe manual workload while still matching the live repo surface.
Scope: map-facing visual assets only. This guide does not replace the technical Codex queue.

Use this together with:
- `Docs/Promts/AI_ASSET_ROADMAP_V2.md` (user-specific roadmap; takes precedence for day-to-day production)
- `Docs/Promts/MAP_REDESIGN_CODEX_QUEUE.md` (user-driven Codex queue for the current map redesign pass)
- `Docs/Promts/CODEX_MAP_PATCH_QUEUE.md`
- `Docs/ASSET_PIPELINE.md`
- `Docs/ASSET_LICENSE_POLICY.md`
- `Docs/MAP_COMPOSER_V2_ASSET_REQUIREMENTS.md`
- `Docs/VISUAL_AUDIO_STYLE_GUIDE.md`

---

## 1. What This Repo Already Has Live

Before producing any new art, start from the actual runtime surface.

The current repo already has live runtime-facing map assets for:
- board shell:
  - `Assets/UI/Map/ui_map_board_backdrop.svg`
- walker:
  - `Assets/UI/Map/Walker/ui_map_walker_idle.svg`
  - `Assets/UI/Map/Walker/ui_map_walker_walk_a.svg`
  - `Assets/UI/Map/Walker/ui_map_walker_walk_b.svg`
- trails:
  - `Assets/UI/Map/Trails/ui_map_v2_trail_short_straight.svg`
  - `Assets/UI/Map/Trails/ui_map_v2_trail_gentle_curve.svg`
  - `Assets/UI/Map/Trails/ui_map_v2_trail_wider_curve.svg`
  - `Assets/UI/Map/Trails/ui_map_v2_trail_outward_reconnecting_arc.svg`
- clearings:
  - `Assets/UI/Map/Clearings/ui_map_v2_clearing_decal_neutral.svg`
  - `Assets/UI/Map/Clearings/ui_map_v2_clearing_decal_boss.svg`
- canopy:
  - `Assets/UI/Map/Canopy/ui_map_v2_canopy_clump_a.svg`
  - `Assets/UI/Map/Canopy/ui_map_v2_canopy_clump_b.svg`
  - `Assets/UI/Map/Canopy/ui_map_v2_canopy_clump_c.svg`
- node plates:
  - `Assets/UI/Map/NodePlates/ui_map_v2_node_plate_reachable.svg`
  - `Assets/UI/Map/NodePlates/ui_map_v2_node_plate_resolved.svg`
  - `Assets/UI/Map/NodePlates/ui_map_v2_node_plate_locked.svg`
- map-facing icons:
  - `Assets/Icons/icon_map_trail_event.svg`
  - `Assets/Icons/icon_map_side_mission.svg`
  - plus the current start/rest/merchant/blacksmith/combat/reward family icons already in use

This matters because your first job is not to invent a new taxonomy.
Your first job is to improve the live map surface without fighting the current hook layout.

---

## 2. What Is Thin, Missing, Or Still Waiting

### Live now, but still temporary or thin
- trail textures
- clearing decals
- canopy clumps
- node plates

These already exist and already render in runtime, but they are still prototype-quality candidates.

### Target families that are still missing or incomplete
- `ui_map_v2_ground_*`
- `ui_map_v2_prop_*`
- `ui_map_v2_landmark_*`
- optional later: `ui_map_v2_foreground_*`

These are the highest-confidence first-pass production targets for this repo right now.

### Wait by default
- marker bodies as a new runtime family

Reason:
- the repo already has a live node-plate plus icon-overlay stack
- the queue does not treat marker bodies as a current first-class hook yet
- marker-body production is lower-confidence than ground, props, and landmarks until the runtime hook is explicit

---

## 3. What You Are Actually Building

You are **not** painting one giant final map image.

You are building a **modular map kit**.

The game already owns:
- node placement
- graph connections
- path family selection
- visibility rules

The art kit owns:
- what the board surface looks like
- what the road textures look like
- what shapes the forest edges
- what makes the board stop looking temporary

Simple mental model:
- runtime decides structure
- composer decides placement
- assets decide the look

---

## 4. What We Are Not Doing

Do not do these:
- do not make one full baked map image per seed
- do not start with LoRA training
- do not redesign the whole icon system with AI
- do not replace working path-family names just because other names sound prettier
- do not import raw AI outputs directly into `Assets/`
- do not skip the manifest

Reason:
- the repo already expects a modular composer-driven board
- the style guide is locked to `Dark Forest Wayfinder`
- raw AI output without cleanup creates consistency and provenance problems

---

## 5. Visual Direction

Locked render language:
- `Dark Forest Wayfinder`

That means:
- dark and misty, not muddy
- stylized, not realistic
- readable before atmospheric
- silhouette first
- mobile-readable

You may borrow these ideas from brighter reference maps:
- stronger road feel
- richer foliage density
- clearer pocket edges
- more satisfying environmental dressing

You may not borrow these as final style:
- bright pastel color language
- watercolor softness
- overly lush painterly blur
- realistic 3D-looking terrain

The point is not to copy a brighter reference image.
The point is to import its readability and density into the locked repo style.

---

## 6. Recommended Tool Stack

Minimum recommended stack:
- local image generation: `ComfyUI`
- cleanup/editing: `Krita`
- code integration and wiring: `Codex`

Optional outside AI:
- any external image model can be used for idea generation and variant exploration
- but every selected result still needs cleanup, naming, and manifest tracking before runtime use

Simple rule:
- use outside AI to get options
- use local tools to refine and standardize
- use Codex to connect finished assets to the game

---

## 7. Best First Setup

If you want the smallest-effort path:

1. Install `ComfyUI`.
2. Install `Krita`.
3. Do **not** train LoRA yet.
4. Use one stylized base model or checkpoint consistently for the first pass.
5. Open the current live map assets in `Assets/UI/Map/` and the matching manifest rows first.
6. Generate a small smoke set only for the families that are still thin or missing.
7. Let Codex handle hook wiring and validation after you have approved winners.

Why no LoRA yet:
- you said you do not know LoRA yet
- the project does not need it for the first pass
- the fastest win is a clean reusable kit, not a custom model workflow

Only think about LoRA later if:
- your first `20-30` assets are good but inconsistent
- you want a stronger project-specific signature
- your base model keeps drifting away from the same style

---

## 8. Production Order For This Repo

This is the repo-first order.
Do not start from a generic art backlog.
Start from the live runtime gap.

| Priority | Family | Why now | Suggested first-pass count |
|---|---|---|---:|
| 1 | ground | still missing as a true runtime family; the board still leans on shell plus tint fallback | `2-3` |
| 1 | prop | high value for forest density and edge framing | `6-8` |
| 1 | landmark | high value for route emphasis and stronger wayfinder identity | `3-4` |
| 2 | canopy | only expand or replace if the live candidate floor feels too repetitive | `3-6` if needed |
| 2 | clearing | only expand or replace if current pockets feel too temporary | `1-3` if needed |
| 2 | trail | only replace or expand if current trail set feels too prototype-like | `1-4` if needed |
| 3 | foreground | optional polish only after the base board reads well | `0-3` |
| later | marker body | defer until a real runtime hook exists | `0` for now |

This is enough to build a believable first polished board without widening scope too early.

---

## 9. Road Surface Language

The repo already uses four live path families:
- `short_straight`
- `gentle_curve`
- `wider_curve`
- `outward_reconnecting_arc`

Those are stable runtime semantics right now.
Do not rename them as part of the art pass.

What can change:
- the texture look
- the surface breakup
- the edge character
- the wear pattern

What should not change:
- gameplay meaning
- path-family wiring
- deterministic family selection logic

Simple rule:
- gameplay graph stays the same
- visual road family changes the flavor

---

## 10. Forest Fill Language

Forest fill should make empty space feel alive without hiding gameplay.

Your prop and filler pool should cover:
- small stones
- mossy rocks
- ferns
- low shrubs
- flowers
- mushrooms
- roots
- broken logs
- tiny ruin fragments

Your landmark pool should cover:
- waystones
- shrine-like route accents
- low ruin markers
- guide-light anchors

Your canopy pool should cover:
- large canopy clusters
- medium canopy masses
- narrow edge-framing canopy shapes

Simple placement idea:
- clearing center stays readable
- road centerline stays readable
- filler gets denser outside pockets and trail edges

---

## 11. Node Presence: What To Improve First

If you want nodes to feel less like floating prototype markers, use this order:

1. improve node plates first
2. improve clearing context second
3. improve landmark accents third
4. introduce a separate marker-body family only after the runtime hook is explicit

Reason:
- node plates are already part of the live runtime-facing surface
- marker bodies are still a speculative extension

If you want a higher-confidence visual upgrade today, replacing the node-plate art is safer than inventing a new marker-body lane.

---

## 12. Folder Workflow

Always use this chain:

1. `SourceArt/Generated/`
2. `SourceArt/Edited/`
3. `Assets/`
4. `AssetManifest/asset_manifest.csv`

Repo-aligned working folders:
- generated source:
  - `SourceArt/Generated/Map/`
- cleaned source:
  - `SourceArt/Edited/Map/`
- runtime exports under:
  - `Assets/UI/Map/Trails/`
  - `Assets/UI/Map/Clearings/`
  - `Assets/UI/Map/Canopy/`
  - `Assets/UI/Map/NodePlates/`
  - future:
    - `Assets/UI/Map/Ground/`
    - `Assets/UI/Map/Props/`
    - `Assets/UI/Map/Landmarks/`
    - optional `Assets/UI/Map/Foreground/`

Never do this:
- generate into `Assets/`
- edit the runtime file as if it were the master
- forget where a selected asset came from

---

## 13. Naming Rules For This Repo

### If you are replacing a live family
Keep the exact live semantic name and swap in place.

Examples:
- `ui_map_v2_trail_short_straight.svg`
- `ui_map_v2_trail_gentle_curve.svg`
- `ui_map_v2_clearing_decal_neutral.svg`
- `ui_map_v2_canopy_clump_a.svg`
- `ui_map_v2_node_plate_locked.svg`

### If you are creating a not-yet-hooked family
Use one consistent semantic naming pattern, not generic numbered throwaways.

Recommended examples:
- `ui_map_v2_ground_forest_floor_a.png`
- `ui_map_v2_ground_forest_floor_b.png`
- `ui_map_v2_prop_root_cluster_a.png`
- `ui_map_v2_prop_ruin_scatter_a.png`
- `ui_map_v2_landmark_waystone_a.png`
- `ui_map_v2_landmark_shrine_a.png`
- `ui_map_v2_foreground_branch_frame_a.png`

Why this is better than `*_01.png`:
- the name already tells you what the asset is
- Codex can wire it more safely later
- future replacements stay understandable without opening the file

---

## 14. The Daily Loop

Use this exact loop for every family:

1. Check the live runtime-facing assets first.
2. Choose one target family for the day.
3. Generate `4-8` variants.
4. Keep the best `1-2` only.
5. Clean those in Krita.
6. Export the chosen runtime file with a stable name.
7. Add or update the manifest row.
8. Stop.

This is important:
- do not generate `50` options and drown in choices
- do not try to perfect every family at once
- do not produce speculative families before the live gaps are covered

---

## 15. Suggested 7-Day Repo-First Plan

### Day 1
- inspect `Assets/UI/Map/` and `AssetManifest/asset_manifest.csv`
- review the live map board in captures or runtime if available
- decide whether canopy, clearing, or trail assets are "good enough for now"
- generate:
  - `2` ground smoke tests
  - `2` prop smoke tests

### Day 2
- choose the best ground direction
- generate:
  - `2` more ground
  - `2-4` prop variants
- clean the best ground winner

### Day 3
- clean the best prop winners
- export the first approved ground and prop files
- add manifest rows

### Day 4
- generate:
  - `2-3` landmark variants
  - `1-2` additional prop variants if the set still feels thin

### Day 5
- clean and export landmark winners
- add manifest rows
- only if the board still feels weak, start a replacement pass for canopy, clearings, or trails

### Day 6
- optional replacement pass:
  - `1-2` canopy variants
  - `1-2` clearing variants
  - `1-2` trail variants
- or optional first foreground test if the base board already reads well

### Day 7
- export all approved winners
- add final manifest rows
- hand the approved asset list to Codex for runtime hookup or in-place swaps

This is enough for the first polished pass.

---

## 16. Prompt Templates

Use short, repeatable prompts.
Do not over-describe.

### Ground prompt

```text
dark forest wayfinder, stylized forest floor base, worn mossy earth, readable top-down 2D game asset, mobile-readable, silhouette-first texture breakup, transparent background
```

### Prop prompt

```text
dark forest wayfinder, small forest prop cluster, roots moss stones ferns, top-down 2D game asset, stylized not realistic, readable silhouette, transparent background
```

### Landmark prompt

```text
dark forest wayfinder, small route landmark, waystone or shrine accent, top-down 2D game asset, stylized, readable silhouette, transparent background
```

### Canopy replacement prompt

```text
dark forest wayfinder, clustered forest canopy mass, top-down silhouette, stylized not realistic, readable shape, 2D game asset, transparent background
```

### Trail replacement prompt

```text
dark forest wayfinder, stylized forest trail surface, worn dirt path, subtle moss and stone breakup, top-down 2D game asset, readable silhouette, mobile-readable, transparent background
```

### Negative prompt

```text
bright pastel, watercolor, photorealistic, anime, pixel art, neon fantasy, blurry silhouette, muddy green wash, heavy bloom, text, watermark
```

---

## 17. How To Judge A Result Fast

Ask only these questions:

1. Does it look like it belongs to the same game as the current approved assets?
2. Is the silhouette readable when small?
3. Is it too bright for the current game?
4. Is it too painterly or soft?
5. Does it solve a live runtime gap instead of creating a new speculative lane?

If the answer fails on any one of these, reject it and move on.

Do not spend `40` minutes trying to rescue a weak result.

---

## 18. Krita Cleanup Checklist

For every selected image:
- cut the background cleanly
- fix broken edges
- reduce noisy detail
- push colors back toward the locked palette
- keep the silhouette strong
- make sure the asset still reads when zoomed out

You do not need perfect illustration polish.
You need:
- clean shape
- stable palette
- reusable runtime asset

---

## 19. Manifest Example That Matches This Repo

Every runtime asset needs a manifest row.

Use the real repo columns and truthful values.
Example:

```text
asset_id,area,status,source_tool,source_origin,license,ai_used,commercial_status,master_path,runtime_path,replace_before_release,last_reviewed_at,notes
ui_map_v2_ground_forest_floor_a,map_ui,candidate,repo_authored_generated_temp,internal_repo_temp_generated,project_owned,yes,commercial_use_allowed,SourceArt/Edited/Map/ui_map_v2_ground_forest_floor_a_master_v001.png,Assets/UI/Map/Ground/ui_map_v2_ground_forest_floor_a.png,yes,2026-04-18,First-pass forest floor base for the map board; not wired into runtime yet and replace before release.
```

Rules:
- if you used an external source, replace `source_tool`, `source_origin`, `license`, and `commercial_status` with the exact truthful values
- if you are unsure about the license, do not promote it
- if it is still a prototype candidate, keep `replace_before_release=yes`
- be truthful, not optimistic

---

## 20. When To Use Codex

Use Codex for:
- wiring new asset families into the composer
- deterministic family-selection logic
- warnings and fallback behavior
- debug overlays
- validation and tests
- scene integration
- in-place replacement of live asset paths without breaking the runtime hook layout

Do not use Codex as your taste engine.

You should decide:
- which asset looks better
- which one matches the game
- which one is too bright or too noisy

Simple division:
- you choose the art
- Codex connects the system

---

## 21. When To Use Outside AI

Outside AI is good for:
- quick idea exploration
- "show me several forest-floor reads"
- "show me several route landmark shapes"
- "give me prop clusters I can refine locally"

Outside AI is bad as a final step.

Before anything reaches runtime:
- clean it
- rename it
- export it properly
- track it in the manifest

---

## 22. LoRA: Why You Are Not Starting With It

LoRA is a lightweight way to teach a model a more project-specific style.

You are not starting with it because:
- it adds setup cost
- it adds debugging cost
- you do not need it for the first polished pass

You only revisit LoRA later if:
- your first asset batch is promising but inconsistent
- your chosen base model keeps drifting
- you already have a strong internal mini-library of approved assets

For now:
- use one main model or checkpoint
- stay consistent
- finish the first missing families

That is the fastest path.

---

## 23. Common Mistakes

- making assets too detailed
- making assets too bright
- producing speculative families before the live runtime gap is covered
- generating too many options and choosing nothing
- skipping cleanup
- forgetting the manifest
- changing the style every night
- renaming live runtime surfaces unnecessarily

The goal is not "beautiful art in isolation".
The goal is "assets that improve the live map board without fighting the current runtime hook layout".

---

## 24. What Success Looks Like

If this guide works, the result will feel like this:
- roads look like roads, not debug lines
- node areas feel like readable pockets
- the board has forest density without losing clarity
- the live candidate floor is replaced where it is weak
- missing families such as ground, props, and landmarks finally exist
- each run still feels visually varied, but still from the same game

That is enough for the first polished pass.

---

## 25. Your Next Actions

Do these in order:

1. Open `Assets/UI/Map/` and `AssetManifest/asset_manifest.csv`.
2. Decide whether the current trail, clearing, canopy, and node-plate candidates are "good enough for now" or need replacement.
3. Start with:
   - `ground`
   - `prop`
   - `landmark`
4. Generate your first smoke assets for those families.
5. Pick only the best winners.
6. Clean them in Krita.
7. Export them with stable repo-aligned names.
8. Add truthful manifest rows.
9. Give the approved filenames to Codex for hookup or in-place swaps.

When that is done, move to the next family.

Do not overthink the first week.
Finish a small, repo-aligned, usable kit first.
