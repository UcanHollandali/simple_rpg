# W1-02 — Extract the duplicated inventory display-name/family helper (P-03)

- mode: Fast Lane
- scope: `Game/UI/event_presenter.gd`, `Game/UI/reward_presenter.gd`, and a new thin helper under `Game/UI/` (for example `Game/UI/inventory_display_labels.gd`). Both presenters must consume the new helper.
- do not touch: gameplay truth; any `Game/RuntimeState/*`; any content schema; command/event catalog entries
- validation budget: `py -3 Tools/validate_architecture_guards.py`; `powershell -NoProfile -ExecutionPolicy Bypass -File Tools/run_godot_tests.ps1 test_event_node.gd test_reward_node.gd`; `powershell -NoProfile -ExecutionPolicy Bypass -File Tools/run_godot_full_suite.ps1`
- doc policy: UI helper extraction is an architecture-boundary concern only if the helper adopts gameplay truth. This one must not. No authority doc update needed.

## Task

1. Locate the duplicated display-name/family mapping in `event_presenter.gd` and `reward_presenter.gd`.
2. Introduce a new static helper file under `Game/UI/` that owns the mapping. Name it so that its role is obviously presentation-only (for example `inventory_display_labels.gd`).
3. Replace both callsites with the new helper call.
4. Keep the helper stateless: static functions or a stateless class, no autoload, no signals.
5. Do not change behavior. The helper must return exactly what the two callsites used to return.

## Non-goals

- Do not add the helper to any bootstrap autoload list.
- Do not reuse `RunState` or any runtime-state file inside the helper.
- Do not extend the mapping beyond what the two callsites already cover.

## Report format

- diff summary (new file + two replaced callsites)
- validator + targeted test + full suite result
- explicitly: no gameplay truth moved, no new autoload
