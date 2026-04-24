# Prompt 43 - Full System Audit And Failure Naming

Use this prompt pack first in the new map continuation chat.
This is a findings-first audit pack.
It does not patch runtime code.

Checked-in filename note:
- this pack lives at `Docs/Promts/43_map_full_system_audit_failure_naming.md`
- Prompt `43-62` is the active map-system-replacement and cleanup wave on this snapshot

Read first:
- `AGENTS.md`
- `Docs/DOC_PRECEDENCE.md`
- `Docs/HANDOFF.md`
- `Docs/ROADMAP.md`
- `Docs/MAP_CONTRACT.md`
- `Docs/SOURCE_OF_TRUTH.md`
- `Docs/MAP_COMPOSER_V2_DESIGN.md`
- `Docs/MAP_VISUAL_OWNERSHIP_AUDIT.md`
- `Docs/TEST_STRATEGY.md`
- `Docs/WINDOWS_PLAYTEST_BRIEF.md`
- `Game/RuntimeState/map_runtime_state.gd`
- `Game/UI/map_board_composer_v2.gd`
- `Game/UI/map_board_layout_solver.gd`
- `Game/UI/map_board_canvas.gd`
- `Game/UI/map_route_binding.gd`
- `Game/UI/map_board_ground_builder.gd`
- `Game/UI/map_board_filler_builder.gd`
- `scenes/map_explore.gd`

Preflight:
- touched owner layer: `full map slice readback across RuntimeState + UI + scenes + tests + docs`
- authority doc: `Docs/MAP_CONTRACT.md` plus `Docs/SOURCE_OF_TRUTH.md`
- impact: `runtime truth unchanged / save shape unchanged / asset-provenance unchanged`
- minimum validation set: `validate_architecture_guards + map scene isolation + portrait capture + targeted map tests + full suite checkpoint`

## Goal

Audit the current checked-in map against the stronger final target:

- full portrait-board usage
- roads as first-read structure
- landmark-pocket node identity
- small-world traversal feel
- terrain/filler after structure
- map-adjacent UI that does not break the illusion

## Direction Statement

- findings first
- current repo truth only
- do not relabel visual failure as success
- separate confirmed issues from assumptions
- identify which subsystems can be preserved and which likely need replacement
- produce a legacy retire inventory:
  - what stays
  - what becomes wrapper/orchestrator only
  - what becomes fallback-only
  - what likely needs retirement later
- explicitly call out any `escalate first` boundary

## Hard Guardrails

- No code patch in Prompt `43`.
- No silent queue widening.
- No authority-doc rewrite in this prompt.
- Do not frame candidate assets as final.

## Required Validation

- `py -3 Tools/validate_architecture_guards.py`
- `powershell -NoProfile -ExecutionPolicy Bypass -File Tools/run_godot_tests.ps1 -Tests test_map_board_composer_v2.gd,test_map_board_canvas.gd -TimeoutSeconds 240`
- `powershell -NoProfile -ExecutionPolicy Bypass -File Tools/run_godot_scene_isolation.ps1 -ScenePath scenes/map_explore.tscn -QuitAfter 2`
- `powershell -NoProfile -ExecutionPolicy Bypass -File Tools/run_portrait_review_capture.ps1 -ScenePaths scenes/map_explore.tscn -ViewportSizes 1080x1920 -TimeoutSeconds 120`
- `powershell -NoProfile -ExecutionPolicy Bypass -File Tools/run_godot_full_suite.ps1`

## Done Criteria

- failure is named in subsystem terms, not vague feel terms
- preserved vs replaceable subsystems are explicit
- legacy retire inventory is explicit
- `escalate first` items are called out explicitly if any
- screenshot paths reviewed are listed

## Copy/Paste Parts

### Part A - Full Audit

```text
Apply only Prompt 43 Part A.

Scope:
- Audit the current full map slice against the stronger final target:
  - topology grammar
  - board footprint
  - lane overlap
  - landmark absence
  - terrain mask weakness
  - UI illusion breaks
  - asset lane weakness
  - doc drift

Do not:
- patch code
- rewrite docs
- open a new feature lane inside this prompt

Validation:
- validate_architecture_guards
- map scene isolation
- portrait capture
- targeted map tests
- full suite checkpoint

Report:
- findings first, ordered by severity
- explicit `Confirmed / Inferred / Unknown`
- exact screenshot paths reviewed
- preserved subsystems
- likely replacement subsystems
- legacy retire inventory:
  - what stays
  - what becomes wrapper/orchestrator
  - what becomes fallback-only
  - what likely needs retirement later
- explicit note whether any finding requires `escalate first`
```

### Part B - Replacement Readiness Note

```text
Apply only Prompt 43 Part B.

Scope:
- Convert Part A findings into a replacement-readiness note for Prompt 44-62.

Do not:
- patch runtime
- update authority docs here

Validation:
- readback only

Report:
- what can be preserved
- what likely needs subsystem replacement
- what should remain wrapper/orchestrator only
- what should remain fallback-only
- what later cleanup prompt should retire if the new system lands green
- which later prompts should carry the highest risk
```
