# Prompt 20 - Map Final Review Audit Patch

Use this prompt pack only after Prompt 19 is closed green.
This is the final review/audit gate for the reopened `14-20` wave.
New feature work is out of scope here.

Checked-in filename note:
- this pack lives at `Docs/Archive/Prompts/2026-04-23-closed-green-prompt-packs/20_map_final_review_audit_patch.md`
- checked-in filename and logical queue position now match Prompt `20`

Read first:
- `AGENTS.md`
- `Docs/DOC_PRECEDENCE.md`
- `Docs/HANDOFF.md`
- `Docs/ROADMAP.md`
- `Docs/MAP_CONTRACT.md`
- `Docs/MAP_TOPOLOGY_LOCAL_GRAPH_DESIGN.md`
- `Docs/MAP_COMPOSER_V2_DESIGN.md`
- `Docs/MAP_VISUAL_OWNERSHIP_AUDIT.md`
- `Docs/SOURCE_OF_TRUTH.md`
- `Docs/SAVE_SCHEMA.md`
- `Docs/GAME_FLOW_STATE_MACHINE.md`
- `Docs/TEST_STRATEGY.md`
- `Docs/ASSET_PIPELINE.md`
- `Docs/ASSET_LICENSE_POLICY.md`

Primary write surface:
- the narrowest touched surfaces required by review findings from Prompt 15-19
- `Docs/HANDOFF.md`
- `Docs/ROADMAP.md`

## Goal

Audit the full chain together:

- topology/grammar
- family placement
- fixed board / no follow
- layout/path/walker/world fill
- asset/filler hookup

Allow only narrow corrective patches that close measured findings without opening a new feature lane.

## Direction Statement

- review findings first
- then narrow corrective patch
- then final closeout sync
- no broader scope widening
- save/flow/owner boundary findings must be separated with `escalate first`

## Hard Guardrails

- No new feature family.
- No new flow state.
- No save-shape widening unless the pack stops with `escalate first`.
- No owner move hidden inside cleanup.
- No reopening of unrelated UI/combat lanes.

## Validation

- full review pass
- architecture guards
- touched test slices
- portrait verification if visual fixes land
- final explicit full-suite checkpoint

## Done Criteria

- the board reads as a fixed procedural world
- the walker moves on the board without follow drift
- topology/family/layout/assets no longer contradict each other
- remaining risks are documented truthfully
- Prompt 14-20 can close or stop with explicit escalation

## Copy/Paste Parts

### Part A - Review Findings

```text
Apply only Prompt 20 Part A.

Scope:
- Audit Prompt 15-19 as one chain.
- Review in this order:
  - topology/grammar
  - family placement
  - fixed-board camera behavior
  - layout/path/walker/world fill
  - asset/filler hookup

Do not:
- patch code in Part A
- start new feature design

Validation:
- architecture guards
- touched readbacks

Report:
- findings first, ordered by severity
- explicit separation between confirmed issues and assumptions
- explicit note whether any finding requires `escalate first`
```

### Part B - Narrow Corrective Patch

```text
Apply only Prompt 20 Part B only if Part A found issues that fit the existing lane.

Scope:
- Land only the narrow corrective patches required by Part A findings.
- Keep fixes inside the already-opened 14-20 map scope.

Do not:
- widen into new feature work
- turn a review pass into a second large implementation wave
- hide save/flow/owner changes inside cleanup

Validation:
- touched test slices
- architecture guards
- portrait verification if visual fixes landed
- final full-suite checkpoint

Report:
- files changed
- which findings were fixed
- which findings remain and why
```

### Part C - Final Closeout Sync

```text
Apply only Prompt 20 Part C.

Scope:
- Update Docs/HANDOFF.md and Docs/ROADMAP.md after Part A and any required Part B work are green.
- Record:
  - Prompt 14-20 closeout state
  - what landed
  - what remains deferred
  - any explicit escalation items

Do not:
- claim broader map work is complete if Part A/Part B left known blockers
- reopen later phases silently

Validation:
- markdown/internal link sanity
- architecture guards
- final full-suite checkpoint

Report:
- files changed
- final closeout statement
- remaining risks or escalation notes
```
