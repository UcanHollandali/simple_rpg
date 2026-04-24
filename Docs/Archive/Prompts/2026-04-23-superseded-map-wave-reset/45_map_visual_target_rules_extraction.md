# Prompt 45 - Map Visual Target Rules Extraction

Use this prompt only after Prompt 44 is closed green.
This is a design-rules extraction pack, not a runtime implementation pack.

Checked-in filename note:
- this pack lives at `Docs/Promts/45_map_visual_target_rules_extraction.md`

Read first:
- `AGENTS.md`
- `Docs/DOC_PRECEDENCE.md`
- `Docs/MAP_CONTRACT.md`
- `Docs/MAP_COMPOSER_V2_DESIGN.md`
- `Docs/MAP_VISUAL_OWNERSHIP_AUDIT.md`
- Prompt `43` findings
- repo-internal portrait review captures under `export/portrait_review/` when they exist
- if no checked-in reference set exists, use Prompt `43` findings plus the screenshot paths reviewed there as the fallback source
- only if the current chat explicitly contains user-provided reference images beyond repo state, treat those as an additional non-authority input

Preflight:
- touched owner layer: `workflow/docs + reference design companions`
- authority doc: `Docs/MAP_CONTRACT.md`
- impact: `runtime truth unchanged / save shape unchanged / asset-provenance unchanged`
- minimum validation set: `markdown/internal link sanity + validate_architecture_guards`

## Goal

Translate the final target image(s) into explicit procedural system rules instead of vague mood language.

## Direction Statement

- extract structural rules, not vibes
- target the feel, not exact pixel fidelity
- roads and landmark pockets must become first-class system goals
- roads must define pockets, not just connect nodes
- UI and overlays are part of the illusion and must be included

## Hard Guardrails

- No runtime code in Prompt `45`.
- No asset approval in Prompt `45`.
- Do not turn reference images into a promise of hand-authored one-off polish.
- If no checked-in visual reference set exists, say so explicitly and fall back to Prompt `43` screenshot evidence instead of guessing.

## Validation

- markdown/internal link sanity
- `py -3 Tools/validate_architecture_guards.py`

## Done Criteria

- explicit rule list exists for later implementation prompts
- each rule is procedural/system-friendly
- vague visual language is replaced by measurable design intent
- the exact visual sources used are named explicitly

## Copy/Paste Parts

### Part A - Rule Extraction

```text
Apply only Prompt 45 Part A.

Scope:
- Extract the strongest design rules from the target visual direction.

Required rule types:
- road-first readability
- landmark pocket identity
- full-board usage
- meaningful negative space
- lower-half utilization
- UI non-interference

Do not:
- patch code
- promise final-release art fidelity

Validation:
- readback only

Report:
- `Confirmed / Inferred / Unknown`
- exact visual sources used:
  - checked-in repo captures if present
  - Prompt `43` screenshot evidence as fallback if not
  - current chat reference images only if they were explicitly provided
- the final rule list in implementation-ready wording
```

### Part B - Reference Doc Sync

```text
Apply only Prompt 45 Part B.

Scope:
- Update the non-authority map reference docs so they describe the stronger target truthfully:
  - `Docs/MAP_COMPOSER_V2_DESIGN.md`
  - `Docs/MAP_VISUAL_OWNERSHIP_AUDIT.md`

Do not:
- change save/flow/owner authority wording
- patch runtime

Validation:
- markdown/internal link sanity
- validate_architecture_guards

Report:
- files changed
- the most important extracted rules now documented
- explicit confirmation that these docs remain reference-only
```
