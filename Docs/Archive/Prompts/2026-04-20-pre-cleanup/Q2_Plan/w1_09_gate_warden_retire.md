# W1-09 — Retire `gate_warden` content and references (D-046)

- mode: Fast Lane
- scope: any `ContentDefinitions/` definition naming `gate_warden`, any referencing test fixture, any `.gd` grep hit, `HANDOFF.md`/`DECISION_LOG.md` cross-references if present, and any asset under `Assets/` whose only purpose is `gate_warden`
- do not touch: any other enemy definition, any boss system, any stage/key/encounter outside the `gate_warden` surface, save schema shape
- validation budget: `py -3 Tools/validate_architecture_guards.py`; `py -3 Tools/validate_content.py`; `powershell -NoProfile -ExecutionPolicy Bypass -File Tools/run_godot_full_suite.ps1`
- doc policy: apply decision `D-046`. This is a content retirement, not a reservation.

## Task

1. Grep the repo for `gate_warden` (case-sensitive) and list every hit. The expected surfaces are content JSON, tests, potentially scene nodes, and docs.
2. For each hit:
   - If the hit is a content definition or a file whose sole purpose is the `gate_warden` surface, delete the file.
   - If the hit is a reference inside a larger file, remove the reference cleanly. Do not leave a `TODO` marker.
   - If the hit is in a test, update the test so that it no longer depends on the retired ID. If the test becomes trivial, delete the test.
3. If any asset under `Assets/` is used only by `gate_warden`, remove the asset and its `.import` / `.uid` siblings in the same patch.
4. After removal, grep again and confirm zero hits.

## Non-goals

- Do not archive the content into a reserved folder.
- Do not introduce a replacement boss.
- Do not change the boss pipeline itself (that is scope-creep and would be escalate-first).
- Do not touch `GDD.md` unless it currently names `gate_warden` — if it does, strike the sentence but do not rewrite the boss section.

## Report format

- full before-grep list and the disposition for each hit (removed / reference removed / test updated / asset removed)
- final grep showing zero remaining occurrences
- validator + content validator + full suite result
- explicitly: no save shape change, no new command/event family, no gameplay autoload change
