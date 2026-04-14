# SIMPLE RPG - Asset License Policy

## Purpose

This file defines how free, AI-assisted, and prototype-only assets are handled without losing track of release risk.

## Core Rule

Prototype speed is allowed.
Provenance amnesia is not.

Every asset that crosses into runtime must have:
- a source
- a license or usage note
- an AI usage note
- a commercial status note
- a replacement note when needed

## Source Trust Levels

Allowed safe-first pool:
- `Kenney`
- `Mixkit`
- `Pixabay`

Do not use for temporary production passes:
- `Zapsplat`
- `OpenGameArt`
- `Freesound`

Do not treat as release-safe by default:
- free-plan AI music tools
- AI art with no source trail
- unattributed or unclear asset packs

Temporary production rule:
- temporary passes open a stable runtime floor; they do not declare a final asset
- visual temp work should prefer repo-authored placeholders before any external source
- audio temp work should prefer the safe-first free pool before any repo-authored generated temp cue or loop
- do not leave the safe-first pool for temporary sourcing
- do not use unclear-license or unclear-provenance sources
- keep `asset_id` stable and keep `runtime_path` stable
- later upgrades must swap in place and update only truthful provenance fields
- temporary assets must not be presented as final assets

## AI-Assisted Asset Rule

AI may help with:
- concept exploration
- placeholder visuals
- variation passes
- moodboard generation
- temporary bust or token ideation
- background exploration

AI must not become the source of truth for:
- the UI component system
- the icon system
- the logo
- store or capsule art
- final marketing visuals
- release-facing key art

Live-generated AI is not allowed in the shipped game.

## Runtime Approval Boundary

Human review is required before a file becomes a runtime asset.

Minimum approval questions:
1. Is the source trail clear enough to explain later?
2. Is the license/commercial status truthful?
3. Is the asset visually aligned with the style guide?
4. Is `replace_before_release` truthful for this asset?

If any answer is "no" or "not sure", the asset must not be promoted as `approved_for_prototype`.

## Prototype Vs Release

Prototype-acceptable:
- clear, tracked placeholders
- AI-assisted placeholders
- temporary library music
- simple repo-authored generated temp audio loops or cues with truthful manifest provenance
- reviewed free-library assets with truthful manifest notes

For temporary free-library use in the current prototype floor, stay inside:
- `Kenney`
- `Mixkit`
- `Pixabay`

If a free source is used, record the exact source link and truthful license in the manifest/review notes.

Still blocked from release by default:
- anything with `replace_before_release=yes`
- anything with `commercial_use_not_allowed`
- anything with unclear source or unclear attribution
- AI-generated assets used in public-facing critical roles

`approved_for_prototype` means approved for the current playable slice.
It does not mean legal, aesthetic, or commercial approval for ship.

## Manifest Truth Requirements

The following fields must stay truthful:
- `source_origin`
- `license`
- `ai_used`
- `commercial_status`
- `replace_before_release`

Current validator enforcement:
- `ai_used` and `replace_before_release` must use yes/no or true/false
- `commercial_status` must use the controlled enum
- header-only manifests are invalid
- runtime assets under `Assets/` must be tracked
- `placeholder`, `candidate`, and `replace_before_release` runtime assets must use `replace_before_release=yes`
- `commercial_use_not_allowed` assets must use `replace_before_release=yes`

## Release Audit Requirement

Before any commercial release discussion:
- review all manifest entries
- filter by `replace_before_release`
- filter by `commercial_use_needs_review` and `commercial_use_not_allowed`
- review every AI-assisted asset
- check that critical final-facing surfaces stayed under human control

`Tools/validate_assets.py` provides the minimum automated audit floor.
It is not a substitute for human release review.
