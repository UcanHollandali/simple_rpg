# Prompt 01 - Current Truth Reset And Target Lock

Use this prompt first in the `01-18` map-system continuation wave.
This pack re-anchors continuation on current repo truth and on the intended small-world map feel, not on archived closeout claims.

Checked-in filename note:
- this pack lives at `Docs/Promts/01_current_truth_reset_and_target_lock.md`

Read first:
- `AGENTS.md`
- `Docs/DOC_PRECEDENCE.md`
- `Docs/HANDOFF.md`
- `Docs/ROADMAP.md`
- `Docs/MAP_CONTRACT.md`
- `Docs/MAP_COMPOSER_V2_DESIGN.md`
- `Docs/TEST_STRATEGY.md`

Archive handling:
- do not read archived prompt packs by default
- if old closeout wording is needed to explain a contradiction, open `Docs/Archive/Prompts/2026-04-23-superseded-map-wave-reset/` explicitly as historical evidence only
- archived prompt text is never authority and must not override current docs, current code, or current captures

Preflight:
- touched owner layer: `Docs/ + prompt-pack process surfaces only`
- authority doc: `Docs/DOC_PRECEDENCE.md` plus `Docs/MAP_CONTRACT.md`
- impact: `runtime truth unchanged / save shape unchanged / asset-provenance unchanged`
- minimum validation set: `validate_architecture_guards + docs/path truth check + git diff --check`

## Goal

Lock the current continuation target:
- fixed board, not a scrolling diagram
- portrait area used meaningfully
- seed-varied but always readable route networks
- center-local start identity with seed/profile-varied outward route emphasis
- north/south/east/west board directions readable without visible sector labels
- no fixed Slay-the-Spire-style upward ladder
- roads divide a small world, not just connect icon discs
- node identities read as places/pockets before icons
- hunger pressure is felt through route shape and exploration choices, without changing hunger rules
- asset dressing should become easy later, but candidate art stays closed in this wave

The user-provided forest-map image is a direction brief only. Do not copy, trace, crop, import, manifest, or treat it as proof.

## Required Outcomes

- active wave is relabeled as `Prompt 01-18`
- archived `43-62` stays historical and superseded
- current repo truth is separated from old optimistic closeouts
- candidate art is closed through this wave
- `HANDOFF`, `ROADMAP`, and `Docs/Promts/README.md` point to the `01-18` order
- later prompts must preserve: hidden sector grammar -> slot/anchor -> topology/adjacency -> corridors -> render-model core payload -> render-model masks/slots payload -> path-surface canvas/default lane -> walker/hunger feel -> landmark pockets -> terrain/filler -> scene shell -> asset sockets -> structural closeout gate -> candidate asset smoke -> cleanup -> final hygiene

## Global Stop Rules

- If screenshot/readback truth is structurally short, do not claim green.
- Candidate art is never structural proof in this wave.
- If save shape, flow state, or source-of-truth ownership would drift, stop and say `escalate first`.
- Default-lane switches require evidence from tests plus fresh screenshot/readback; test green alone is not enough.

## Hard Guardrails

- docs/process-only in this prompt
- no runtime, UI, save, flow, or asset changes
- no archived prompt claim becomes authority
- no candidate-art reopening
- no claim that current visuals already meet the target

## Validation

- `py -3 Tools/validate_architecture_guards.py`
- explicit docs/link/path/truth consistency check
- `git diff --check`

## Done Criteria

- `Docs/Promts/` contains the active `01-18` pack
- queue docs agree on order, scope, and candidate-art closure
- the handoff to the next prompt is explicitly recorded in `Docs/ROADMAP.md` and `Docs/Promts/README.md`

## Copy/Paste Parts

### Part A - Current Truth Audit

Apply only Prompt 01 Part A.

Scope:
- audit current repo truth, current captures, current prompt docs, and archived overclaim risks

Do not:
- patch code in Part A

Validation:
- `py -3 Tools/validate_architecture_guards.py`

Report:
- confirmed / inferred / unknown
- exact current map state
- exact archived claims that must not carry forward
- exact target-feel requirements now locked

### Part B - Queue And Target Sync

Apply only Prompt 01 Part B.

Scope:
- sync `HANDOFF`, `ROADMAP`, and `Docs/Promts/README.md`

Do not:
- widen into runtime/UI implementation

Validation:
- `py -3 Tools/validate_architecture_guards.py`
- docs/path truth check
- `git diff --check`

Report:
- files changed
- exact `01-18` queue landed
- exact candidate-art closure rule

### Part C - Recheck And Lock

Apply only Prompt 01 Part C.

Scope:
- recheck that active docs tell one story and the next prompt cursor is explicit

Do not:
- reopen archived queue semantics

Validation:
- Prompt 01 validation stack

Report:
- findings first
- whether the wave is locked
- exact next step at the time of this prompt's closeout
