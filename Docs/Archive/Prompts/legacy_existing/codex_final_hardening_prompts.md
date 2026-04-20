This is the final repo hardening and truth-sync track.

Use this after the main overhaul queue and any optional audio / tuning / content expansion tracks are finished.

Primary goal:
- close the repo in a stable, truthful state
- remove stale references and quiet drift
- confirm docs, tests, validators, assets, and runtime truth all agree

Read first for every part:
- `AGENTS.md`
- `Docs/DOC_PRECEDENCE.md`
- `Docs/HANDOFF.md`
- `Docs/ARCHITECTURE.md`
- `Docs/SOURCE_OF_TRUTH.md`
- `Docs/TEST_STRATEGY.md`
- `Docs/TECH_BASELINE.md`
- `Docs/SAVE_SCHEMA.md`
- `Docs/ASSET_PIPELINE.md`
- `Docs/ASSET_LICENSE_POLICY.md`

Then read only the closest authority docs for the surfaces you touch.

Hard rules for the whole track:
- do not add new features or mechanics
- do not broaden architecture
- do not change save shape or save schema version unless a real existing mismatch forces escalation
- do not use this as a stealth refactor phase
- if the repo needs a real architecture rewrite rather than cleanup, stop and say `escalate first`

Global validation baseline:
- `py -3 Tools/validate_content.py`
- `py -3 Tools/validate_assets.py`
- `py -3 Tools/validate_architecture_guards.py`
- `powershell -NoProfile -ExecutionPolicy Bypass -File Tools/run_godot_full_suite.ps1`
- `powershell -NoProfile -ExecutionPolicy Bypass -File Tools/run_godot_smoke.ps1`

Recommended part order:
1. Part 1
2. Part 2
3. Part 3
4. Part 4

## Part 1 - Repo-Wide Hardening Audit (NO-CODE)

Goal:
- perform a final repo-wide audit before any cleanup patching
- identify truth drift across code, tests, docs, assets, and runtime wiring

Do not patch in this part.

Audit specifically:
- stale docs vs checked-out runtime truth
- stale tests vs checked-out runtime truth
- asset manifest/runtime/source drift
- save schema and content version truth
- old temporary file residue
- dead branches or thin wrappers left behind by the overhaul
- runner/helper/doc assumptions that are now stale

Report specifically:
1. doc drift
2. test drift
3. asset drift
4. stale file residue
5. remaining large-file or risk hotspots
6. whether Part 2 should run as-is or be adjusted

## Part 2 - Docs / Tests / Truth Sync Pass (LOW-MEDIUM RISK)

Goal:
- make repo truth explicit and consistent
- remove contradictions between current code and current docs/tests

Likely scope:
- `HANDOFF.md`
- closest authority docs where behavior meaning drifted
- test expectations that still assert stale labels/paths/flows
- validator comments or helper docs if they are stale

Hard rule:
- do not rewrite docs broadly
- update only what is necessary to restore truthful alignment

Validation after patching:
- global validation baseline

## Part 3 - Stale File / Asset / Cleanup Pass (LOW-MEDIUM RISK)

Goal:
- remove verified-dead files, stale helpers, and obsolete residues left by the overhaul

Hard rule:
- verify references before deletion
- do not treat workflow files like `codex_*.md` as cleanup targets
- do not delete archive/history material unless clearly requested and verified dead

Possible scope:
- stale root artifacts
- obsolete temp assets already replaced
- dead helper scripts or dead test helpers
- no-longer-used source masters after safe swaps

Validation after patching:
- global validation baseline

## Part 4 - Final End-to-End Audit + Release-Candidate Verdict (LOW RISK)

Goal:
- produce the final truthful repo verdict after all hardening
- say whether this prototype is ready for broader playtesting

Tasks:
1. Re-run the global validation baseline.
2. If appropriate, run the Windows playtest export:
   - `powershell -NoProfile -ExecutionPolicy Bypass -File Tools/export_windows_playtest.ps1`
3. Re-audit:
   - runtime truth
   - save/content version truth
   - asset provenance truth
   - docs/tests truth
4. End with a direct verdict:
   - stable for broader playtest
   - stable but still narrow
   - not yet ready

Final report format:
1. Executive Verdict
2. Baseline Validation
3. Repo-Wide Audit
4. Findings Before Patch
5. Applied Hardening Changes
6. Validation Results
7. Remaining Risks
8. Intentionally Untouched Areas
9. Escalation Items
10. Final Verdict

Before ending, give a 5-bullet handoff:
- what was hardened
- what stale residue was removed
- what stayed intentionally untouched
- what still needs later work
- whether the repo is ready for broader playtest or still needs another pass
