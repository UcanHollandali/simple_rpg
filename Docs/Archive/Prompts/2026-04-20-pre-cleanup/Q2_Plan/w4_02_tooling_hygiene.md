# W4-02 — Tooling hygiene pass (O-2)

- mode: Fast Lane
- scope: `Tools/validate_content.py`, local cache artifacts that belong to `Tools/`, stale helper comments inside `Tools/*.py`, and runner docs that are already under `Tools/` or adjacent to it
- do not touch: any `.gd` code; any content definition; any `ContentDefinitions/*`; any authority doc other than a single TECH_BASELINE update if a runner command string changed
- validation budget: `py -3 Tools/validate_architecture_guards.py`; `py -3 Tools/validate_content.py`; tool-specific validators as needed
- doc policy: if a runner command surface changed, update `Docs/TECH_BASELINE.md`. Do not put runner commands in `README.md` (per DOC_PRECEDENCE).

## Task

1. Audit `Tools/validate_content.py` for dead branches, stale helper comments, and unreachable allowlists (audit findings `MAINT-F5`, `MAINT-F9`).
2. Remove dead code. Do not rewrite logic. Keep output format identical.
3. Audit runner docs under `Tools/` and adjacent runbook files. If a command string is stale, fix it. If none is stale, report "no change required".
4. Clean local cache artifacts only if they are checked into the repo by mistake. Do not add new ignore rules in this patch.

## Non-goals

- Do not rewrite `Tools/validate_content.py` structure.
- Do not add new validator rules.
- Do not edit `README.md`.

## Report format

- dead code removed (per file)
- runner doc edits
- validator + content validator result
- explicitly: no production code changed, no content file changed
