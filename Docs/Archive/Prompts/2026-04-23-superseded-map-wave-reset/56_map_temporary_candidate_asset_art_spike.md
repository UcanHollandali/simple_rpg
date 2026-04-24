# Prompt 56 - Temporary Candidate Asset And Art Spike

Use this prompt only after Prompt 58 is closed green.
This pack allows a temporary candidate asset spike for the map target after the structure is already reading correctly.

Checked-in filename note:
- this pack lives at `Docs/Promts/56_map_temporary_candidate_asset_art_spike.md`

Read first:
- `AGENTS.md`
- `Docs/DOC_PRECEDENCE.md`
- `Docs/ASSET_PIPELINE.md`
- `Docs/ASSET_LICENSE_POLICY.md`
- Prompt `43-58` outputs
- `AssetManifest/asset_manifest.csv`
- `Game/UI/ui_asset_paths.gd`
- map asset builder surfaces

Preflight:
- touched owner layer: `Assets + SourceArt + AssetManifest + Game/UI`
- authority doc: `Docs/ASSET_PIPELINE.md` and `Docs/ASSET_LICENSE_POLICY.md`
- impact: `runtime truth unchanged / save shape unchanged / asset-provenance may change truthfully`
- minimum validation set: `validate_assets + validate_architecture_guards + portrait capture + full suite checkpoint`

## Goal

Add only the temporary candidate landmark/path/terrain assets needed to push the new map structure closer to the intended art-like read.

## Required Outcomes

The asset spike follows this order:
1. candidate path-surface variants only after corridors and terrain masks already read correctly
2. candidate landmark socket/anchor art only after Prompt `53` landmark pockets are stable
3. candidate pocket-terrain accent art only after Prompt `54` masks and negative-space rules are stable
4. candidate negative-space clutter clusters last, only where structure already justifies them

Priority candidate classes:
- path-surface variants
- landmark plates, props, or small local identity kits
- pocket-terrain accent pieces that reinforce existing masks
- canopy, stone, ruin, shrub, signpost, or torch clusters in true negative space

Production preference:
- prefer reusable small kits and variants over bespoke one-off per-node art
- candidate art should improve many seeded layouts, not only one screenshot

Candidate/final lane split:
- Prompt `56` is candidate-only
- all landed art in this prompt remains explicitly provisional and `replace_before_release`
- final/release-safe asset production is outside this prompt unless a later explicit wave opens it

## Hard Guardrails

- Do not open asset work before structure is green.
- Do not frame candidate assets as release-safe.
- Do not hide structural failures behind candidate art.
- roads, landmarks, and terrain masks must already read without candidate art before this prompt opens.
- Do not skip straight to clutter/filler if path, landmark, and pocket-terrain classes are still unresolved.
- Do not let per-pocket asset placement read like a rigid checkerboard or centered-per-cell stamp pattern.

## Validation

- `py -3 Tools/validate_assets.py`
- `py -3 Tools/validate_architecture_guards.py`
- `powershell -NoProfile -ExecutionPolicy Bypass -File Tools/run_godot_scene_isolation.ps1 -ScenePath scenes/map_explore.tscn -QuitAfter 2`
- `powershell -NoProfile -ExecutionPolicy Bypass -File Tools/run_portrait_review_capture.ps1 -ScenePaths scenes/map_explore.tscn -ViewportSizes 1080x1920 -TimeoutSeconds 120`
- `powershell -NoProfile -ExecutionPolicy Bypass -File Tools/run_godot_full_suite.ps1`
- `git diff --check`

## Done Criteria

- candidate assets strengthen structure without faking it
- manifest and provenance stay truthful
- the board reads closer to the intended art-like target while remaining explicitly provisional
- the prompt only opens after structural readability is already green
- the landed art still reads like seeded variation over hidden structure rather than visible cell-centered placement

## Copy/Paste Parts

### Part A - Candidate Asset Need Audit

```text
Apply only Prompt 56 Part A.

Scope:
- Audit whether the map still needs a temporary candidate asset spike after the first integrated structural review.

Do not:
- generate or patch assets in Part A

Validation:
- validate_architecture_guards
- validate_assets
- portrait capture

Report:
- exact structural vs asset gaps
- exact candidate asset classes justified
- exact candidate asset order justified
- explicit no-go areas where asset work would be fake progress
```

### Part B - Candidate Asset Spike

```text
Apply only Prompt 56 Part B.

Scope:
- Land only the narrow candidate landmark/path/terrain assets and hookups justified by the Part A audit, in the same order documented above.

Do not:
- claim release-safe status
- widen into unrelated asset production

Validation:
- validate_assets
- validate_architecture_guards
- portrait capture
- full suite checkpoint
- git diff --check

Report:
- files changed
- exact candidate assets added or updated
- exact candidate classes landed first vs deferred
- exact provenance/manifest truth
- before/after screenshot paths
```

### Part C - Candidate Art Review

```text
Apply only Prompt 56 Part C.

Scope:
- Re-audit the checked-in board after the candidate asset spike.

Do not:
- patch runtime in Part C

Validation:
- validate_assets
- portrait capture

Report:
- findings first
- whether candidate art improved structure read
- whether any remaining failure is still structural rather than visual
- which landed art is still clearly candidate-only rather than final
```
