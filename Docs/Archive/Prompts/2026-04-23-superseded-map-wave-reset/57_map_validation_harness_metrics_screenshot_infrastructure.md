# Prompt 57 - Map Validation Harness Metrics And Screenshot Infrastructure

Use this prompt only after Prompt 46 is closed green.
This baseline pack makes the new map-system wave measurable before runtime/system replacement begins.

Checked-in filename note:
- this pack lives at `Docs/Promts/57_map_validation_harness_metrics_screenshot_infrastructure.md`

Read first:
- `AGENTS.md`
- `Docs/DOC_PRECEDENCE.md`
- `Docs/TEST_STRATEGY.md`
- `Docs/WINDOWS_PLAYTEST_BRIEF.md`
- Prompt `43-46` outputs
- existing map tests under `Tests/`
- existing map test tools under `Tools/`

Preflight:
- touched owner layer: `Tests + Tools + docs`
- authority doc: `Docs/TEST_STRATEGY.md`
- impact: `runtime truth unchanged / save shape unchanged / asset-provenance unchanged by default`
- minimum validation set: `validate_architecture_guards + targeted harness/tests + full suite checkpoint`

## Goal

Add the baseline harness, screenshot infrastructure, and review expectations needed to evaluate the new map target before sector-specific implementation metrics exist.

## Required Outcomes

- baseline map generation smoke coverage where model-agnostic
- board canvas tests
- scene isolation expectations
- portrait seed sweep expectations
- screenshot artifact naming/path conventions
- baseline review helpers for:
  - lower-half occupancy readback
  - screenshot-path reporting
  - UI overlap failure capture
- explicit defer note that sector, pocket, and corridor-specific metrics are handled after Prompt `47`

## Hard Guardrails

- Do not hide subjective failure behind numbers alone.
- Do not add metrics that smuggle gameplay-truth ownership into tests/tools.
- Keep screenshot review as a required gate.
- Do not lock sector/pocket/corridor-specific metrics before the sector grammar contract exists.

## Validation

- `py -3 Tools/validate_architecture_guards.py`
- `powershell -NoProfile -ExecutionPolicy Bypass -File Tools/run_godot_tests.ps1 -Tests test_map_board_composer_v2.gd,test_map_board_canvas.gd -TimeoutSeconds 240`
- `powershell -NoProfile -ExecutionPolicy Bypass -File Tools/run_godot_scene_isolation.ps1 -ScenePath scenes/map_explore.tscn -QuitAfter 2`
- `powershell -NoProfile -ExecutionPolicy Bypass -File Tools/run_portrait_review_capture.ps1 -ScenePaths scenes/map_explore.tscn -ViewportSizes 1080x1920 -TimeoutSeconds 120`
- `powershell -NoProfile -ExecutionPolicy Bypass -File Tools/run_godot_full_suite.ps1`
- `git diff --check`

## Done Criteria

- the wave has explicit measurable gates
- screenshot review remains first-class
- implementation prompts start with baseline metrics instead of flying blind
- sector/pocket/corridor-specific metrics are explicitly deferred out of this baseline pack
- future continuation passes can identify regression vs true progress quickly

## Copy/Paste Parts

### Part A - Harness Gap Audit

```text
Apply only Prompt 57 Part A.

Scope:
- Audit current map validation, metrics, and screenshot infrastructure against the new wave target.

Do not:
- patch tests or tools in Part A

Validation:
- validate_architecture_guards
- read existing tests/tools only

Report:
- exact coverage gaps
- exact baseline metrics still missing
- exact structural metrics that must wait until after Prompt `47`
- exact places where screenshot review is still too subjective
```

### Part B - Harness And Metrics Implementation

```text
Apply only Prompt 57 Part B.

Scope:
- Implement the narrowest baseline tests, tools, and screenshot infrastructure needed before sector-specific metrics exist.

Do not:
- move gameplay truth into tools or tests
- widen into unrelated repo-wide harness cleanup
- invent sector/pocket/corridor metrics early

Validation:
- validate_architecture_guards
- targeted tests/tools
- scene isolation
- portrait capture
- full suite checkpoint
- git diff --check

Report:
- files changed
- exact baseline metrics and harnesses added
- exact review questions now locked by the repo
```

### Part C - Test Strategy Sync

```text
Apply only Prompt 57 Part C.

Scope:
- Sync touched validation docs after the harness and metrics patch.

Do not:
- widen into unrelated docs

Validation:
- validate_architecture_guards
- git diff --check

Report:
- docs changed
- exact validation expectations added
- any remaining sector/pocket/corridor metric gap deferred to Prompt `47.5`
```
