# Prompt 19 - Map Prototype Asset And Filler Hookup

Use this prompt pack only after Prompt 18 is closed green.
This is the map-only asset/filler pack in the reopened `14-20` wave.
Do not widen into combat/menu/shared global polish.

Checked-in filename note:
- this pack lives at `Docs/Archive/Prompts/2026-04-23-closed-green-prompt-packs/19_map_prototype_asset_and_filler_hookup.md`
- checked-in filename and logical queue position now match Prompt `19`

Read first:
- `AGENTS.md`
- `Docs/DOC_PRECEDENCE.md`
- `Docs/HANDOFF.md`
- `Docs/ROADMAP.md`
- `Docs/MAP_TOPOLOGY_LOCAL_GRAPH_DESIGN.md`
- `Docs/MAP_VISUAL_OWNERSHIP_AUDIT.md`
- `Docs/MAP_COMPOSER_V2_DESIGN.md`
- `Docs/ASSET_PIPELINE.md`
- `Docs/ASSET_LICENSE_POLICY.md`
- `AssetManifest/asset_manifest.csv`
- `Docs/VISUAL_AUDIO_STYLE_GUIDE.md`

Primary write surface:
- map-only asset/runtime files under `Assets/UI/Map/` and `Assets/Icons/`
- matching source/master files under `SourceArt/Edited/` or `SourceArt/Generated/Map/`
- `AssetManifest/asset_manifest.csv`
- minimal map-only runtime hooks if required

## Goal

Ship a map-only prototype asset pass on top of the corrected topology/layout/walker/world-fill baseline so the board reads more intentionally without pretending any temporary asset is release-safe.

## Direction Statement

- asset work is after topology/layout/walker/world-fill
- map-only scope
- AI/prototype visuals are allowed in runtime only if:
  - human-reviewed
  - manifest-tracked
  - truthful about provenance
  - `candidate` / `placeholder` / `replace_before_release=yes`
- assets reinforce the landed structure; they do not rescue it

## Allowed Asset Surfaces

- node identity icons
- node plates
- trail surfaces
- board props
- forest/ruin/ground fillers
- walker / map readability accents

## Hard Guardrails

- No broader UI/combat/menu polish.
- No false release-safe framing.
- No untracked runtime asset.
- No asset promotion without truthful manifest row.
- No owner move.
- No graph-truth change.
- No save/flow change.

## Validation

- `py -3 Tools/validate_assets.py`
- `py -3 Tools/validate_architecture_guards.py`
- map runtime sanity / scene isolation if hooks changed
- portrait capture before/after polish
- explicit final closeout sync

## Done Criteria

- map-only assets are manifest-tracked
- readability improves on the board
- runtime hooks are safe
- every temporary/prototype asset stays truthfully marked as replace-before-release
- no asset is misframed as final/release-safe

## Copy/Paste Parts

### Part A - Map-Only Asset Audit

```text
Apply only Prompt 19 Part A.

Scope:
- Audit the landed Prompt 15-18 board and list the exact map-only asset gaps that still matter.
- Limit the audit to:
  - node identity icons
  - node plates
  - trail surfaces
  - board props
  - forest/ruin/ground fillers
  - walker / map readability accents
- Decide which existing runtime assets stay, which temporary assets can be improved in place, and which map-only runtime hooks still need art.

Do not:
- produce or hook assets in Part A
- widen outside the map surface

Validation:
- validate_assets
- validate_architecture_guards

Report:
- asset gap list
- stable asset_id/runtime_path reuse plan
- explicit map-only scope confirmation
```

### Part B - Asset And Filler Hookup

```text
Apply only Prompt 19 Part B.

Scope:
- Produce or improve map-only semantic assets / filler assets that materially improve board readability.
- Allowed source lanes:
  - repo-authored placeholders
  - repo-authored generated map assets
  - cleaned reviewed masters under the asset-pipeline rules
- Every runtime asset must have:
  - stable runtime filename
  - truthful manifest row in the same patch
  - candidate/placeholder status when still temporary
  - replace_before_release=yes when required by policy

Do not:
- widen into terrain mega-wave or broader UI polish
- invent a second runtime identity if an existing asset_id/runtime_path should be upgraded in place
- frame AI/prototype work as final

Validation:
- validate_assets
- validate_architecture_guards
- map scene isolation if runtime hooks changed
- portrait capture after hookup

Report:
- assets produced or upgraded
- manifest rows added/updated
- runtime paths touched
- explicit confirmation that all temporary/prototype assets stay replace-before-release where required
```

### Part C - Closeout Sync

```text
Apply only Prompt 19 Part C.

Scope:
- Update Docs/HANDOFF.md and Docs/ROADMAP.md after Parts A-B are green.
- Record:
  - what landed in the map-only asset/filler lane
  - what stayed explicitly temporary
  - what remains broader future asset work
  - readiness for Prompt 20 audit

Do not:
- declare prototype assets release-safe
- widen into unrelated phases

Validation:
- markdown/internal link sanity
- validate_assets
- validate_architecture_guards

Report:
- files changed
- final map-only asset state
- explicit note that temporary/prototype assets are not final/release-safe
```
