# SIMPLE RPG - Asset Pipeline

## Purpose

This file defines the source-of-truth chain, folder ownership, naming rules, promotion stages, and runtime approval boundary for visual and audio assets.

## Source Of Truth Chain

- production asset request truth: `Docs/ProductionAssetBriefs/map_asset_external_request_pack.md` plus the closest production authority docs
- visual and audio source/master files: `SourceArt/`
- runtime-ready exports: `Assets/`
- provenance and release tracking: `AssetManifest/asset_manifest.csv`

Never treat a runtime export as the master file.
`SourceArt/` and `AssetManifest/` must stay outside Godot's runtime import surface.

## Folder Ownership

- `SourceArt/Generated/`: AI-generated or externally generated source material
- `SourceArt/Edited/`: cleaned, normalized, or human-edited source files
- `Assets/UI/`: exported runtime UI assets
- `Assets/Icons/`: exported runtime icons
- `Assets/Characters/`: runtime character art
- `Assets/Enemies/`: runtime enemy art and tokens
- `Assets/Backgrounds/`: runtime backgrounds and overlays
- `Assets/Animation/`: runtime VFX sprites and animation sheets
- `Assets/Audio/SFX/`: runtime sound effects
- `Assets/Audio/Music/`: runtime music files
- `Assets/Marketing/`: non-runtime promo assets
- `AssetManifest/`: provenance and replacement tracking

## Naming Rules

- all files use `lower_snake_case`
- runtime export names stay stable once imported into `Assets/`
- source masters may carry version suffixes
- category and role should be obvious from the name

Examples:
- `icon_attack.svg`
- `enemy_bone_raider_bust.png`
- `enemy_bone_raider_token.png`
- `sfx_ui_confirm_01.ogg`
- `music_ui_hub_loop_proto_01.ogg`

## Promotion Model

There are two separate concepts:

1. source-stage labels used by humans in the production workflow
2. manifest `status` values used for runtime-tracked assets

### Source-Stage Labels

These are process stages only. They are not manifest `status` values.

- `reference_only`: inspiration, snippets, or rough pulls; never imported to runtime
- `candidate_source`: plausible source material still under review or cleanup
- `approved_master`: the reviewed source/master file that future runtime exports should come from

### Manifest Status Values

These are the only allowed `status` values for runtime-tracked assets:
- `placeholder`
- `candidate`
- `approved_for_prototype`
- `replace_before_release`

Meaning:
- `placeholder`: temporary runtime readability aid; must use `replace_before_release=yes`
- `candidate`: runtime testing/export candidate; must use `replace_before_release=yes`
- `approved_for_prototype`: approved for the current playable slice
- `replace_before_release`: allowed in prototype/runtime, explicitly blocked from commercial ship without replacement

`approved_for_prototype` does not mean "final for release."

## Runtime Approval Boundary

A file may cross from `SourceArt/` into `Assets/` only after all of these are true:

1. it has a stable runtime filename
2. the source/master path is known and reviewable
3. a manifest row exists or is added in the same patch
4. `source_origin`, `license`, `ai_used`, `commercial_status`, and `replace_before_release` are truthful
5. the asset passes a human readability/style check against the style guide

Do not promote directly from:
- raw AI output
- raw asset-library dumps
- unedited design-tool scratch exports

The minimum safe path is:

`reference_only -> candidate_source -> approved_master -> runtime export + manifest row`

## Temporary Sourcing Order

Temporary production passes exist to open a stable runtime floor, not to declare a final asset.

Visual temp sourcing order:
1. produce a repo-authored placeholder first
2. if that is not sufficient, use only a safe-first free source

Audio temp sourcing order:
1. use only a safe-first free source first
2. if nothing suitable exists, produce a very simple repo-authored generated temp cue or loop

Allowed safe-first free source pool:
- `Kenney`
- `Mixkit`
- `Pixabay`

Do not use broader review-needed pools such as:
- `OpenGameArt`
- `Freesound`
- `Zapsplat`

Do not use unclear-license or unclear-provenance assets for runtime temp passes.

## Current Map Wave Structure-First Rule

For the active map-system replacement wave, the art and asset sequence stays:

1. topology / placement
2. corridors / pocket masks
3. landmark sockets / anchors
4. candidate art spike

Guardrails for that sequence:

- do not use candidate assets to claim that road hierarchy, landmark pockets, or full-board usage are already solved
- candidate map assets stay truthful `candidate` or other non-final manifest states until explicitly promoted through the normal review path
- candidate map assets must still use truthful provenance plus `replace_before_release=yes` when required by their manifest status
- if structure is not reading correctly yet, the next fix lane is still structural rather than an asset-polish pass

## Map Socket Production Lane

For reviewed map socket production assets:

- the only active AI-facing map production handoff is `Docs/ProductionAssetBriefs/map_asset_external_request_pack.md`
- source masters go under `SourceArt/Edited/Map/Production/`
- runtime exports go under `Assets/UI/Map/Production/`
- manifest rows must be added or updated in `AssetManifest/asset_manifest.csv` in the same patch as the runtime export
- the current external map production request uses PNG-primary production targets; existing `ArtPilot` and `SocketSmoke` SVG assets remain fallback/review lanes
- `Game/UI/ui_asset_paths.gd` resolves socket art in this order: `Production` -> `ArtPilot` -> `SocketSmoke`
- `MapBoardCanvas` still draws socket art only when explicit prototype socket dressing is enabled
- adding a file under `Assets/UI/Map/Production/` does not approve normal/default map render promotion by itself

## Manifest Minimum Contract

Required columns:
- `asset_id`
- `area`
- `status`
- `source_tool`
- `source_origin`
- `license`
- `ai_used`
- `commercial_status`
- `master_path`
- `runtime_path`
- `replace_before_release`
- `last_reviewed_at`
- `notes`

Required non-empty fields:
- `asset_id`
- `area`
- `status`
- `source_origin`
- `license`
- `ai_used`
- `commercial_status`
- `replace_before_release`

Current validator rules:
- `asset_manifest.csv` must contain at least one real manifest entry
- `commercial_status` must use one of:
  - `commercial_use_allowed`
  - `commercial_use_needs_review`
  - `commercial_use_not_allowed`
- `runtime_path`, when present, must point inside `Assets/` and the file must exist
- runtime paths must be unique
- runtime assets under `Assets/` must be manifest-tracked
- `placeholder`, `candidate`, and `replace_before_release` runtime assets must use `replace_before_release=yes`
- `commercial_use_not_allowed` assets must use `replace_before_release=yes`
- `.gitattributes` must keep `*.svg` text-reviewable

Validator commands:
- Windows: `py -3 Tools/validate_assets.py`
- macOS/Linux: `python3 Tools/validate_assets.py`

## Manifest Default Provenance For Temp Assets

If the temp asset is repo-authored placeholder art:
- `source_tool=repo_authored_placeholder`
- `source_origin=internal_repo_temp_placeholder`
- `license=project_owned`
- `ai_used=no`
- `commercial_status=commercial_use_allowed`
- `status=placeholder`
- `replace_before_release=yes`

If the temp asset comes from the safe-first free source pool:
- keep `source_tool` truthful to the real source/export path
- keep `source_origin` truthful to the exact real source
- keep `license` truthful to the exact real source
- `ai_used=no`
- keep `commercial_status` truthful to the exact source license state
- `status=placeholder`
- `replace_before_release=yes`

If the temp asset is a repo-authored generated audio cue or loop:
- `source_tool=repo_authored_generated_temp`
- `source_origin=internal_repo_temp_generated`
- `license=project_owned`
- `ai_used=no`
- `commercial_status=commercial_use_allowed`
- `status=placeholder`
- `replace_before_release=yes`

Swap rule for later upgrades:
- keep `asset_id` stable
- keep `runtime_path` stable
- swap in place when a better asset replaces the temp floor
- update only the source/master/runtime files and truthful manifest provenance fields
- do not create a second runtime identity just because the source improved

## Export And Import Rules

- only exported runtime assets go into `Assets/`
- `SourceArt/` must stay blocked from Godot import via `.gdignore`
- `AssetManifest/` must stay blocked from Godot import via `.gdignore`
- do not drop design-tool masters, PSDs, Krita files, or AI raw outputs into runtime folders
- do not import broad dumps into Godot without naming and manifest review

## Export Format Standards

### Icons

- format: `SVG` preferred, `PNG` acceptable
- standard sizes: `128x128` master, `64x64` runtime-safe read
- background: transparent

### Character And Enemy Busts

- format: `PNG`
- size: `512x768`
- background: transparent

### Character And Enemy Tokens

- format: `PNG`
- size: `128x128`
- must remain readable at `64x64`

### Backgrounds

- format: `PNG` or `JPEG` when file size matters
- base resolution: `1080x1920`
- separate `far`, `mid`, and `overlay` layers when practical

### UI Exports

- `SVG` for vector assets, `PNG` for raster assets
- component and export naming should match runtime names in `lower_snake_case`

### SFX

- format: `OGG Vorbis`
- sample rate: `44100 Hz`
- mono by default
- short, readable, and reusable first

### Music

- format: `OGG Vorbis`
- sample rate: `44100 Hz`
- stereo
- prototype music should prefer the safe-first free source pool
- if no suitable free temp loop exists, a very simple repo-authored generated temp loop is allowed
- keep manifest provenance truthful in either case

## Daily Workflow

1. define the asset request
2. collect or generate candidates in `SourceArt/`
3. clean up the chosen source into an approved master
4. add or update the manifest row before runtime import
5. export runtime-ready files
6. import into Godot only after review

## Review Artifact Discipline

- default local search should stay on active source/master lanes
- do not leave review preview sheets in `SourceArt/Edited/`; keep only reviewed masters there
- if a future task needs temporary review dumps, keep them in ignored `export/` output and promote only through the normal approved-master plus manifest workflow

## Placeholder And Release Discipline

- placeholders are allowed
- placeholders must be manifest-tracked
- placeholders must not silently become release assets
- every runtime asset should be explainable by:
  - style guide
  - manifest row
  - readable source/master path

Before any commercial release discussion:
- filter manifest entries by `replace_before_release`
- filter by non-commercial or review-needed commercial status
- review all AI-assisted assets
