# Prompt 12 - Semantic Icon Readiness

Use this prompt pack only after Prompt 11.5 is closed green and Prompt 04 Part D is already landed.
This is a future-queue reference pack. Do not start it while any earlier open 06-11.5 pack is still open.

Checked-in filename note:
- this pack lives at `Docs/Archive/Prompts/2026-04-23-closed-green-prompt-packs/12_semantic_icon_readiness.md`
- checked-in filename and logical queue position now match Prompt `12`

Read first:
- `AGENTS.md`
- `Docs/DOC_PRECEDENCE.md`
- `Docs/HANDOFF.md`
- `Docs/ROADMAP.md`
- `Docs/ASSET_WAVE_SEMANTIC_SCOPE.md`
- `Docs/ASSET_PIPELINE.md`
- `Docs/ASSET_LICENSE_POLICY.md`
- `Docs/VISUAL_AUDIO_STYLE_GUIDE.md`

Optional reference:
- `Docs/UI_MICROCOPY_AUDIT.md`
- `Docs/UI_INFORMATION_ARCHITECTURE_AUDIT.md`

## Goal

Produce a reference-only runtime-readiness / asset-contract checkpoint at `Docs/SEMANTIC_ICON_READINESS_CHECKLIST.md` for the semantic icon wave defined by Prompt 04 Part D.

This pack does not generate art.
This pack does not approve art.
This pack does not hook art into runtime.

## Direction Statement

- The semantic icon wave remains separate from terrain-transition art.
- Runtime adoption stays blocked until approved filenames, truthful manifest rows, and provenance/licensing gates are satisfied.
- The checklist should make replacement value explicit:
  - what the current fallback is
  - what runtime filename would replace it
  - whether `UiAssetPaths` would need to change
  - whether the current repo already ships a generic fallback
- The output is a readiness/checkpoint document, not an implementation plan that silently widens runtime scope.

## Hard Guardrails

- No asset generation.
- No asset approval.
- No asset move/rename/import/convert/hookup.
- No `UiAssetPaths` change.
- No save/schema change.
- No gameplay or flow change.
- No authority override of `Docs/ASSET_PIPELINE.md` or `Docs/ASSET_LICENSE_POLICY.md`.
- No claim that Prompt 12 unblocks the asset wave by itself.

## Validation

- `py -3 Tools/validate_architecture_guards.py`
- `py -3 Tools/validate_assets.py`
- markdown/internal link sanity for any touched docs

## Done Criteria

- `Docs/SEMANTIC_ICON_READINESS_CHECKLIST.md` exists and is clearly marked reference-only.
- Tier 1 map-semantic icon targets are explicitly checked:
  - `icon_map_combat`
  - `icon_map_key`
  - `icon_map_boss`
- The checklist records current fallback, expected runtime filename, `UiAssetPaths` impact, and approval/provenance gate for each target family.
- The pack does not generate, approve, or hook any asset.

## Copy/Paste Parts

### Part A - Runtime Icon Contract Audit

```text
Apply only Prompt 12 Part A.

Scope:
- Create Docs/SEMANTIC_ICON_READINESS_CHECKLIST.md as a reference-only checkpoint document.
- Audit Tier 1, Tier 2, and Tier 3 readiness from Docs/ASSET_WAVE_SEMANTIC_SCOPE.md.

Required checklist columns per surface/family:
- target surface
- expected runtime filename pattern
- current repo fallback
- current runtime owner/path surface
- UiAssetPaths change required: yes/no
- manifest row required: yes
- provenance/license review required: yes
- human visual review required: yes
- ready now / blocked / partial
- blocking reason

Do not:
- generate or edit assets
- repoint runtime paths
- treat file presence as approval

Validation:
- validate_architecture_guards
- validate_assets
- markdown/internal link sanity on the new checklist doc

Report:
- files created/changed
- ready vs blocked counts
- top blockers
- explicit confirmation that no asset changed state
```

### Part B - Readiness Closeout

```text
Apply only Prompt 12 Part B.

Scope:
- Finish the checklist with a short closeout summary:
  - what can move first once approvals exist
  - what stays blocked
  - what should not be attempted in the semantic wave
- Cross-check the checklist wording against Docs/ASSET_WAVE_SEMANTIC_SCOPE.md.

Do not:
- collapse blocked and ready states into one bucket
- overclaim readiness
- treat optional prop work as mandatory terrain work

Validation:
- validate_architecture_guards
- validate_assets
- markdown/internal link sanity

Report:
- files changed
- closeout summary
- explicit blocked items that still need approval/provenance/runtime-path work
```

### Part C - Handoff And Roadmap Refresh

```text
Apply only Prompt 12 Part C.

Scope:
- Update Docs/HANDOFF.md and Docs/ROADMAP.md so Prompt 12 is recorded and Prompt 12.5 becomes next.
- Record that Prompt 12 is a readiness checkpoint only and does not unblock asset hookup by itself.

Validation:
- markdown/internal link sanity
- validate_architecture_guards
- validate_assets

Report:
- files changed
- final readiness state
- explicit confirmation that no asset was generated, approved, or hooked
```
