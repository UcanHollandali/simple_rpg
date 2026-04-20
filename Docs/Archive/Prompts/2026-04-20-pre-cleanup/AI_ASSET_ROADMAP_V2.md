# AI ASSET ROADMAP V2 - USER-SPECIFIC

Purpose: practical asset production roadmap tailored to the current user setup.
Audience: the user working this repo day-to-day, not a generic beginner.
Scope: map-facing visual assets first, then icon polish. Audio is out of scope here.

Active prompt runner for the current map pass: `Docs/Promts/MAP_MASTER_PROMPTS.md`.

This file is the only active asset roadmap for the current map pass.

> **Not a Codex prompt file.** This roadmap is human-in-the-loop work done locally in ComfyUI + Krita (or via Kenney). Do NOT paste this file into Codex as a prompt and do NOT queue it overnight. Use it BETWEEN `MAP_MASTER_PROMPTS.md` Prompt `6` (Codex stop) and Prompt `7` (Codex asset-hook wiring).

Authority order for conflicts:
1. `Docs/VISUAL_AUDIO_STYLE_GUIDE.md`
2. `Docs/ASSET_PIPELINE.md`
3. `Docs/ASSET_LICENSE_POLICY.md`
4. `Docs/MAP_COMPOSER_V2_ASSET_REQUIREMENTS.md`
5. this file

---

## 0. Quick Start

You do NOT need to read this whole file before the first batch.

If you want the shortest practical path, use only these sections first:
- `2. Tool Stack`
- `5. Repo-First Production Order`
- `6. Prompt Templates`
- `7. Daily Loop`
- `12. Success Criteria`
- `13.5 Reality Check`

Everything else is reference material.

Use this file only after map Prompts `1`, `2A`, `2B`, `3`, `4`, `5`, and `6` are clean.
When the first asset batch is ready, return to `Docs/Promts/MAP_MASTER_PROMPTS.md` and run Prompt `7`.

---

## 1. User Setup Snapshot (Certain)

- GPU: NVIDIA RTX `5080` (Blackwell, `16 GB` VRAM)
- OS: Windows
- Repo: `C:\Users\kemal\Documents\Codex\simple_rpg`
- AI coding agents available:
  - ChatGPT Pro `$100` / month with Codex CLI
  - Claude `$20` / month
- Known user constraint: Claude's lower tier is fine for planning and doc work, but large multi-file repo work should usually route through Codex.

This setup is strong enough to run local image diffusion comfortably. Cloud image services are optional, not required.

---

## 2. Tool Stack (Recommended For This User)

Research note (2026-04-18):
- ComfyUI official docs confirm local Windows install paths and portable builds.
- Acly's `krita-ai-diffusion` project confirms Krita can use ComfyUI as backend.
- Black Forest Labs / Hugging Face model cards confirm `FLUX.1 Schnell` is Apache-2.0 and `FLUX.1 Dev` is non-commercial.
- Kenney confirms asset packs are CC0 and commercial-safe.

### Primary image stack - local, free

- **ComfyUI Desktop or Portable** as the diffusion backend.
  - runs locally on Windows
  - supports FLUX, SDXL, and community workflows
  - recent ComfyUI builds added NVFP4 support for Blackwell GPUs; on the right CUDA 13 stack, RTX 50-series cards can see roughly a `2x` speedup on supported models
- **Krita** with the **Acly/krita-ai-diffusion** plugin.
  - the plugin uses ComfyUI as backend
  - generation, inpaint, masking, and cleanup stay in one place
  - this is better than splitting generation and cleanup across multiple half-overlapping tools
- **Codex CLI** for runtime wiring after assets are approved.
- **Claude** for doc edits, prompt drafting, and short research / planning passes. Do not rely on Claude for heavy repo-wide refactors.

### Models to try first on a `5080`

- `FLUX.1 Schnell`
  - first choice for this repo
  - fast iteration
  - Apache-2.0
  - commercial-safe baseline
- `SDXL`
  - fallback if FLUX prompt behavior or community workflow support becomes the bottleneck
  - strongest general ecosystem for ControlNet / LoRA experiments
- `FLUX.1 Dev`
  - only for prototype or concept exploration
  - non-commercial
  - must stay marked `replace_before_release=yes`
- `Illustrious XL`
  - only if later work shifts toward stylized 2D icon / bust variation
  - not the first pick for `Dark Forest Wayfinder`

Rule: pick one primary checkpoint and stay on it through the first approved batch. Do not checkpoint-hop during the first pass.

### Safe-first free asset pool (before AI)

Always check these first:
- **Kenney** - CC0, commercial-safe, no attribution required
- **Mixkit** - same safe-first pool named in `ASSET_LICENSE_POLICY.md`
- **Pixabay** - same safe-first pool

If Kenney has a `forest`, `roguelike`, or `top-down` pack that fits the repo silhouette logic after light recolor, use it first.

### Not recommended for runtime assets in this repo

- Midjourney
  - weaker provenance than local generation
  - no local workflow control
  - paid seat overhead for a job the 5080 can already handle
- ChatGPT / API image generation as the primary production lane
  - fine for isolated concept experiments
  - weaker than a locked local checkpoint for repeatable batch consistency
  - worse fit for this repo's provenance and iteration workflow
- Claude as image production
  - not the image lane here
- OpenGameArt / Freesound / Zapsplat
  - already blocked by repo license policy for temp production

---

## 3. Three Production Lanes (Pick The Lowest-Risk First)

When you need a new map asset family, evaluate lanes in this order:

### Lane A - Safe-first free library

- Search Kenney for a matching top-down 2D pack.
- If one fits `Dark Forest Wayfinder` after light recolor, use it.
- Manifest example:
  - `source_tool=kenney`
  - `source_origin=<exact pack URL>`
  - `license=CC0`
  - `ai_used=no`
  - `commercial_status=commercial_use_allowed`
  - `status=placeholder` or `candidate`

### Lane B - Local AI (FLUX / SDXL on ComfyUI + Krita)

- Use only when Lane A does not fit the style.
- Generate a small batch, keep very few winners, and clean them in Krita.
- Manifest for `FLUX.1 Dev` outputs:
  - `license=flux_dev_non_commercial`
  - `commercial_status=commercial_use_needs_review`
  - `replace_before_release=yes`
- Manifest for `FLUX.1 Schnell` outputs:
  - `license=apache_2_0`
  - `commercial_status=commercial_use_allowed`
  - still `replace_before_release=yes` until human-reviewed against the style guide

### Lane C - Repo-authored placeholder

- Use when neither Kenney nor local diffusion is giving a readable result.
- Hand-authored SVG or simple Krita paint is acceptable as a stable floor.
- Follow the `repo_authored_placeholder` manifest pattern from `ASSET_PIPELINE.md`.

Do not skip from Lane B straight into `Assets/` without human review.

---

## 4. What This Repo Already Has Live (Certain)

Before producing anything, remember these are already in the runtime-facing surface:

- board shell: `ui_map_board_backdrop.svg`
- walker frames (idle + 2 stride)
- 4 trail SVGs: `short_straight`, `gentle_curve`, `wider_curve`, `outward_reconnecting_arc`
- 2 clearing decals: `neutral`, `boss`
- 3 canopy clumps: `a`, `b`, `c`
- 3 node plates: `reachable`, `resolved`, `locked`
- map / equipment icons under `Assets/Icons/`

Missing in the live runtime surface:

- `ui_map_v2_ground_*` - ground / floor texture family
- `ui_map_v2_prop_*` - scatter props such as stones, roots, ferns, logs, mushrooms
- `ui_map_v2_landmark_*` - waystones, small shrines, guide-light anchors
- optional `ui_map_v2_foreground_*` - thin overlay leaves / branches that do not block hit targets

These are the production targets.

Current `Assets/UI/Map/` subfolders that already exist on disk: `Trails/`, `Clearings/`, `Canopy/`, `NodePlates/`, `Walker/`.
The missing subfolders (`Ground/`, `Props/`, `Landmarks/`) do NOT yet exist on disk; Prompt 7 in `MAP_MASTER_PROMPTS.md` is responsible for creating them during asset-hook wiring.

---

## 4.25 What You Are Actually Building

You are NOT painting one giant final map image.

You are building a modular map kit.

The game already owns:
- node placement
- graph connections
- path-family selection
- visibility rules

The art kit owns:
- board surface look
- trail surface look
- forest-edge / pocket dressing
- environmental density and atmosphere

Simple mental model:
- runtime decides structure
- composer decides placement
- assets decide the look

Hard rule:
- do not make one baked full-map image per seed

---

## 4.5 User Reference Image Alignment

The user's reference image should guide the first map-art pass in these ways:

- clear center-start anchor / camp / stump read
- readable road fan-out from the center
- dense forest-floor coverage so the board does not feel empty
- visible route landmarks near important outer pockets
- soft edge fog / depth pockets near the borders
- "this is a forest route board" feeling before the player reads the icons

Do NOT treat the image as a one-to-one copy target for:

- final palette brightness
- exact saturation level
- exact foliage paint style
- exact UI marker style

Repo constraint:

- the final result still needs to land inside `Dark Forest Wayfinder`
- use the image for composition density, route readability, and landmark placement
- do not let the board drift into bright-fantasy lushness unless the style guide changes

---

## 4.75 Naming-To-Asset Boundary

- The approved node-display names from `Docs/Promts/MAP_MASTER_PROMPTS.md` should guide map copy, future node-marker polish, and hero-landmark concept language.
- They do NOT authorize literal family-specific symbols inside reusable `ground`, `prop`, `landmark`, or `foreground` families.
- `C / C / C` is the locked naming direction for the current pass, so you do not need a separate approval loop before moving on.
- Ground and prop production can start as soon as the runtime hooks and topology pass are stable because those families stay generic.
- Landmark language should use the locked naming direction, but reusable landmark art should still avoid embedding literal gameplay truth.

---

## 5. Repo-First Production Order

| Priority | Family | Why now | First-pass target count |
|---|---|---|---:|
| 1 | `ground` | no live runtime family yet; board still leans on shell + tint | `2-3` |
| 1 | `prop` | density and forest-edge framing | `6-8` |
| 1 | `landmark` | route emphasis and wayfinder identity; concept after topology stabilizes under the locked naming direction | `3-4` |
| 2 | `canopy` | expand only if live clumps feel repetitive | `3-6` if needed |
| 2 | `clearing` | expand only if current pockets feel temporary | `1-3` if needed |
| 2 | `trail` | replace only if current trails still look prototype-like after map Prompt 6 | `1-4` if needed |
| 3 | `foreground` | polish only | `0-3` |
| later | `marker_body` | defer until a real runtime hook exists | `0` |

Do not widen scope until the Priority 1 families are live, reviewed, and manifest-tracked.

First-pass art goal:

- when `ground`, `prop`, and `landmark` land together, the board should already read closer to "center clearing with branching forest roads"
- `ground` and `prop` can start as soon as the hooks exist
- `landmark` concept language should follow the locked naming direction in `MAP_MASTER_PROMPTS.md`

---

## 5.25 Forest Fill Language

Your prop / filler pool should cover:
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
- clearing centers stay readable
- road centerlines stay readable
- filler gets denser outside pockets and trail edges

---

## 6. Prompt Templates (For FLUX / SDXL On A 5080)

Use these with the `krita-ai-diffusion` plugin or ComfyUI directly. Transparent background is important; if the result is opaque, clean the matte in Krita afterward.

### Ground prompt

```text
dark forest wayfinder, stylized forest floor base, worn mossy earth, damp soil, soft leaf litter, subtle moss stones, readable top-down 2D game asset, mobile-readable, silhouette-first texture breakup, flat shading, transparent background
```

### Prop prompt

```text
dark forest wayfinder, small forest prop cluster, roots moss stones ferns, top-down 2D game asset, stylized not realistic, readable silhouette, flat shading, transparent background
```

### Landmark prompt

```text
dark forest wayfinder, small route landmark, waystone or weathered shrine accent, top-down 2D game asset, stylized, readable silhouette, flat shading, subtle guide-light, transparent background
```

### Canopy replacement prompt (only if needed)

```text
dark forest wayfinder, clustered forest canopy mass, top-down silhouette, stylized not realistic, readable shape, 2D game asset, flat shading, transparent background
```

### Trail replacement prompt (only if needed; run map Prompt 6 first)

```text
dark forest wayfinder, stylized forest trail surface, worn dirt path, subtle moss and stone breakup, top-down 2D game asset, readable silhouette, mobile-readable, flat shading, transparent background
```

### Negative prompt (always)

```text
bright pastel, watercolor, photorealistic, anime, pixel art, neon fantasy, blurry silhouette, muddy green wash, heavy bloom, text, watermark, HUD, UI icon, character, creature
```

### Suggested baseline settings

- sampler: `Euler` or `dpmpp_2m`
- steps: `4-8` for `FLUX.1 Schnell`, `20-28` for `FLUX.1 Dev`, model-specific defaults for `SDXL`
- guidance:
  - FLUX: `3.5-4.5`
  - SDXL: follow checkpoint defaults first
- resolution:
  - `1024x1024` for ground / canopy
  - `768x768` for props and landmarks
  - downscale in Krita after cleanup

---

## 7. Daily Loop (Tight)

Use the same loop for every family:

1. Check the live runtime-facing assets first.
2. Pick exactly one target family for the day.
3. Try Lane A for `10` minutes. If nothing fits, go to Lane B.
4. Generate `4-8` variants. Keep `1-2`.
5. Clean the keepers in Krita.
6. Export the cleaned master first. Then place the runtime copy under `Assets/UI/Map/<Family>/` with the stable repo naming rule. If the runtime subfolder does not exist yet, create it manually or let Prompt 7 create it before the final copy.
7. Add or update the manifest row with truthful provenance.
8. Run `py -3 Tools/validate_assets.py`.
9. Hand the approved filename to Codex using the asset-hook prompt in `Docs/Promts/MAP_MASTER_PROMPTS.md` so the runtime hook is wired.
10. Stop.

Do not generate `50` options and drown in choices.

---

## 8. Manifest Templates For Common Cases

### FLUX.1 Dev (non-commercial) candidate

```text
asset_id,area,status,source_tool,source_origin,license,ai_used,commercial_status,master_path,runtime_path,replace_before_release,last_reviewed_at,notes
ui_map_v2_ground_forest_floor_a,map_ui,candidate,comfyui_flux_dev_local,internal_repo_ai_generated,flux_dev_non_commercial,yes,commercial_use_needs_review,SourceArt/Edited/Map/ui_map_v2_ground_forest_floor_a_master_v001.png,Assets/UI/Map/Ground/ui_map_v2_ground_forest_floor_a.png,yes,2026-04-18,FLUX.1 Dev local generation; replace before commercial release.
```

### FLUX.1 Schnell (Apache-2.0) candidate

```text
asset_id,area,status,source_tool,source_origin,license,ai_used,commercial_status,master_path,runtime_path,replace_before_release,last_reviewed_at,notes
ui_map_v2_prop_root_cluster_a,map_ui,candidate,comfyui_flux_schnell_local,internal_repo_ai_generated,apache_2_0,yes,commercial_use_allowed,SourceArt/Edited/Map/ui_map_v2_prop_root_cluster_a_master_v001.png,Assets/UI/Map/Props/ui_map_v2_prop_root_cluster_a.png,yes,2026-04-18,FLUX.1 Schnell local generation; review before release even though license is permissive.
```

### Kenney CC0 candidate

```text
asset_id,area,status,source_tool,source_origin,license,ai_used,commercial_status,master_path,runtime_path,replace_before_release,last_reviewed_at,notes
ui_map_v2_landmark_waystone_a,map_ui,candidate,kenney,https://kenney.nl/assets/<pack-slug>,CC0,no,commercial_use_allowed,SourceArt/Edited/Map/ui_map_v2_landmark_waystone_a_master_v001.png,Assets/UI/Map/Landmarks/ui_map_v2_landmark_waystone_a.png,no,2026-04-18,Kenney CC0 asset with light recolor toward Dark Forest Wayfinder palette.
```

`replace_before_release` rule:
- `yes` for every AI-assisted runtime asset until human release review signs off
- `no` is only reasonable for repo-authored or CC0-safe imports that already match the style and policy bar

---

## 9. LoRA - When (And Only When) To Start

Do NOT start LoRA in the first pass.

Revisit LoRA only if all of these are true:
- you already shipped `10+` approved assets in the same family
- those assets still feel stylistically inconsistent with a locked checkpoint and locked prompts
- you want to push the repo's own signature harder than stock FLUX / SDXL can hold

Typical LoRA path on a `5080`:
- gather `15-30` approved masters
- train a light LoRA
- switch the same ComfyUI workflow to that LoRA

Until then, one locked checkpoint plus one locked prompt template beats a half-trained LoRA.

---

## 10. Seven-Day User-Specific Plan

### Day 1

- install ComfyUI Desktop or Portable
- install `krita-ai-diffusion`
- pull `FLUX.1 Schnell` first
- run `2` smoke renders: one ground, one prop

### Day 2

- inspect `Assets/UI/Map/` and `AssetManifest/asset_manifest.csv` side by side
- try Kenney for forest / ruin / route-adjacent packs
- generate `2-4` more ground / prop variants if Kenney does not fit

### Day 3

- run the overnight map prompt from `Docs/Promts/MAP_MASTER_PROMPTS.md`
- keep the locked `C / C / C` naming direction
- clean best ground / prop candidates in Krita
- do NOT start serious landmark concept work yet if topology is still unstable

### Day 4

- export first approved ground + prop files
- add manifest rows
- run `py -3 Tools/validate_assets.py`
- hand approved filenames to Codex through the asset-hook prompt in `Docs/Promts/MAP_MASTER_PROMPTS.md` once hooks are ready

### Day 5

- start landmark concept pass using the locked naming language from `Docs/Promts/MAP_MASTER_PROMPTS.md`
- keep landmark silhouettes generic enough to stay reusable unless a separate node-marker hook exists

### Day 6

- optional canopy / clearing / trail replacement pass if the board still feels too prototype
- otherwise, try first foreground smoke tests

### Day 7

- full manifest review
- `py -3 Tools/validate_assets.py`
- portrait review capture with `Tools/run_portrait_review_capture.ps1`
- human readability check at portrait resolutions

---

## 11. When To Use Which Tool Or Agent

| Task | Best tool / agent | Why |
|---|---|---|
| multi-file map runtime refactor | Codex CLI | longer context, repo edits, terminal-native |
| doc edits, planning, prompt drafting | Claude | fast back-and-forth |
| image generation | ComfyUI + Krita | strongest local control and consistency |
| image cleanup | Krita + human | final asset judgment should stay human |
| one-off concept test | ChatGPT image or other cloud tool | only if you explicitly want a throwaway concept sample |

Rule: do not ask Claude to own big multi-file code passes in this repo when Codex is already available locally.

---

## 12. Success Criteria For The First Pass

The first polished pass is complete when:

- ground family is live on the board and visible under composer output
- at least `6` props render across the new topology without colliding with node overlays
- at least `3` landmarks render near outer pockets as route emphasis
- no AI-assisted runtime asset is in the manifest without the correct provenance fields
- `py -3 Tools/validate_assets.py` passes
- one portrait review capture shows the board reading as a forest pocket rather than temporary debug slots

Then and only then, consider canopy / trail replacement and optional foreground.

---

## 13. What Not To Do

- do not generate into `Assets/` directly; always go through `SourceArt/Generated/` -> `SourceArt/Edited/` -> `Assets/` plus manifest
- do not skip the manifest row even for placeholders
- do not paint assets that bake gameplay information into reusable environment layers
- do not use Midjourney for runtime assets in this repo
- do not rely on cloud AI image generation when a local 5080 workflow already solves the task
- do not run two code-touching prompts from `Docs/Promts/MAP_MASTER_PROMPTS.md` in parallel
- do not rename live path-family strings just because the art feel changes; names are gameplay contract, look is art contract

---

## 13.5 Reality Check

This roadmap can get the repo to:

- a board that reads much closer to the user's reference image in structure and density
- a center-start forest route board with modular environmental variation
- repeatable per-run visual variation without changing gameplay ownership

This roadmap does NOT guarantee in one pass:

- an exact screenshot match to the reference image
- final-release-quality painted environment art
- full parity with a hand-authored premium map illustration set

Expected outcome of a strong first pass:

- structural similarity: yes
- readability similarity: yes
- mood similarity: likely
- exact art fidelity: no, not without multiple art-review iterations
