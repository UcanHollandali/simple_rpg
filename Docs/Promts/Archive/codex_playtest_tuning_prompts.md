This is the post-core playtest and tuning track.

Use this after the main overhaul queue is stable.
If the separate audio track is part of the plan, prefer running audio first, then this track.

Primary goal:
- decide whether the game is actually fun, readable, and coherent in play
- tune pacing, readability, economy, and combat feel without widening architecture
- turn "it technically works" into "it is worth playtesting again"

Read first for every part:
- `AGENTS.md`
- `Docs/DOC_PRECEDENCE.md`
- `Docs/HANDOFF.md`
- `Docs/TEST_STRATEGY.md`
- `Docs/WINDOWS_PLAYTEST_BRIEF.md`
- `Docs/BALANCE_ANALYSIS.md`
- `Docs/COMBAT_RULE_CONTRACT.md`
- `Docs/MAP_CONTRACT.md`
- `Docs/REWARD_LEVELUP_CONTRACT.md`
- `Docs/SUPPORT_INTERACTION_CONTRACT.md`
- `Docs/GAME_FLOW_STATE_MACHINE.md`
- `Docs/SAVE_SCHEMA.md`

Hard rules for the whole track:
- do not add new mechanics just because balance feels off
- do not hide mechanic changes inside tuning
- do not change save shape or save schema version
- do not add new flow states
- do not do broad scene/core or owner-boundary rewrites
- if tuning clearly requires a new mechanic surface, stop and say `escalate first`

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
5. Part 5

## Part 1 - Playtest Audit + Tuning Backlog Lock (NO-CODE)

Goal:
- audit the current playable slice before tuning
- identify the biggest friction points in readability, pacing, and decision quality
- create a bounded tuning backlog instead of random tweaks

Do not patch in this part.

Tasks:
1. Re-audit the current playable flow from:
   - `MainMenu`
   - `RunSetup`
   - `MapExplore`
   - `Combat`
   - `Reward`
   - `LevelUp`
   - `SupportInteraction`
   - `StageTransition`
   - `RunEnd`
2. List the highest-value manual playtest checkpoints:
   - early map route choice clarity
   - first combat readability
   - reward/level-up comprehension
   - support-node usefulness
   - stage pacing
   - end-of-run clarity
3. Identify issues by category:
   - readability/UI
   - combat feel
   - economy/reward value
   - route/map pacing
   - run-level progression
   - repetition/fatigue
4. Separate:
   - tuning issue
   - bug
   - content shortage
   - architecture problem
5. Produce a ranked tuning backlog for Parts 2-4.

Report specifically:
1. top friction points
2. top boredom points
3. top confusion points
4. what is tuning-only vs not tuning-only
5. whether Part 2 should run as-is or be adjusted

## Part 2 - Readability + UX Tuning Pass (LOW-MEDIUM RISK)

Goal:
- improve how clearly the game communicates choices and outcomes
- tune UI-facing numbers, labels, hints, and presentation behavior without redesigning systems

Touched owner layer:
- mostly `Game/UI/`, `scenes/`, docs/tests if needed

Authority docs:
- `Docs/COMBAT_RULE_CONTRACT.md`
- `Docs/MAP_CONTRACT.md`
- `Docs/REWARD_LEVELUP_CONTRACT.md`
- `Docs/SUPPORT_INTERACTION_CONTRACT.md`

Impact:
- `runtime truth`: presentation-facing tuning only unless a contract-visible behavior is explicitly adjusted
- `save shape`: none
- `public surface`: user-facing labels/copy/hints may change

Possible scope:
- button copy clarity
- reward/level-up explanation clarity
- support-node explanation clarity
- tooltip or helper-text clarity
- route/state marker clarity
- low-risk pacing feedback such as reveal timing or panel wording

Do not:
- add new systems
- reopen major UI redesign work
- move gameplay truth into UI

Validation after patching:
- global validation baseline
- targeted scene isolation if touched:
  - `scenes/map_explore.tscn`
  - `scenes/combat.tscn`

## Part 3 - Combat / Economy / Progression Tuning Pass (MEDIUM RISK)

Goal:
- tune the numbers and cadence so the run feels more intentional and less flat
- improve decision quality without adding new mechanic surfaces

Likely tuning surface:
- combat tempo
- enemy threat readability vs actual danger
- reward offer quality and cadence
- merchant/blacksmith/rest value
- hunger pressure vs run pacing
- perk/reward progression feel
- stage difficulty curve

Hard rule:
- keep changes inside existing contracts
- if a change would require a new combat verb, new resource, new slot type, new content family, or save migration, stop and say `escalate first`

Before each non-trivial patch:
- state touched owner layer, authority doc, impact, minimum validation set

Validation after patching:
- global validation baseline
- `powershell -NoProfile -ExecutionPolicy Bypass -File Tools/run_godot_scene_isolation.ps1 -ScenePath scenes/combat.tscn`
- `powershell -NoProfile -ExecutionPolicy Bypass -File Tools/run_godot_scene_isolation.ps1 -ScenePath scenes/map_explore.tscn`

## Part 4 - Run Pacing + Repetition Tuning Pass (MEDIUM RISK)

Goal:
- reduce dead air, repetition, and route fatigue across a full run
- tune the feel of stage progression and variety without changing the core architecture

Likely scope:
- map route pacing and node density tuning that stays inside current contract
- encounter repetition tuning inside current content and selection surfaces
- support-node cadence tuning
- reward cadence tuning
- stage transition cadence

Do not:
- add a new route family
- add a new flow state
- expand content grammar here

Validation after patching:
- global validation baseline
- full run smoke if available through the current tests

## Part 5 - Final Playtest Verdict + Tuning Audit (LOW RISK)

Goal:
- close the tuning track with a truthful verdict
- say whether the build is ready for wider playtesting or still needs another pass

Tasks:
1. Re-audit the tuning backlog after Parts 2-4.
2. Confirm which issues were fixed, which remain, and which were misclassified.
3. Identify what still needs:
   - content expansion
   - hardening
   - mechanic redesign
4. If appropriate, run the Windows playtest export and say whether it succeeded:
   - `powershell -NoProfile -ExecutionPolicy Bypass -File Tools/export_windows_playtest.ps1`
5. End with a direct playtest verdict.

Final report format:
1. Executive Verdict
2. Baseline Validation
3. Playtest Audit
4. Findings Before Patch
5. Applied Tuning Changes
6. Validation Results
7. Remaining Fun / Clarity Risks
8. Issues That Need Content Expansion Instead
9. Issues That Need Hardening Instead
10. Escalation Items
11. Final Verdict

Before ending, give a 5-bullet handoff:
- what tuning improved most
- what stayed intentionally untouched
- what still feels weak in play
- exact files or tracks that should be next
- whether the next planned prompt should run as-is or be adjusted
