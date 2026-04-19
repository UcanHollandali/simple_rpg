This is the post-core content breadth track.

Use this after the main overhaul queue is stable.
Prefer running the playtest/tuning track first so content additions answer real gaps instead of guesses.

Primary goal:
- add more authored variety without widening the underlying grammar unnecessarily
- make the game feel less thin through data-first content expansion
- expand encounters, rewards, gear, enemies, and authored slices inside the current contracts

Read first for every part:
- `AGENTS.md`
- `Docs/DOC_PRECEDENCE.md`
- `Docs/HANDOFF.md`
- `Docs/CONTENT_ARCHITECTURE_SPEC.md`
- `Docs/COMBAT_RULE_CONTRACT.md`
- `Docs/MAP_CONTRACT.md`
- `Docs/REWARD_LEVELUP_CONTRACT.md`
- `Docs/SUPPORT_INTERACTION_CONTRACT.md`
- `Docs/TEST_STRATEGY.md`
- `Docs/SAVE_SCHEMA.md`
- `Docs/DECISION_LOG.md`

Hard rules for the whole track:
- most new content should be data-first, not special-case code
- do not hide mechanic changes inside content additions
- do not add new effect families, trigger families, resource axes, slot types, node families, or flow states here
- do not change save shape or save schema version
- treat current deterministic selection surfaces as behavior-sensitive
- if the desired addition cannot fit the current grammar truthfully, stop and say `escalate first`

Global validation baseline:
- `py -3 Tools/validate_content.py`
- `py -3 Tools/validate_architecture_guards.py`
- `powershell -NoProfile -ExecutionPolicy Bypass -File Tools/run_godot_full_suite.ps1`
- `powershell -NoProfile -ExecutionPolicy Bypass -File Tools/run_godot_smoke.ps1`

Recommended part order:
1. Part 1
2. Part 2
3. Part 3
4. Part 4
5. Part 5

## Part 1 - Content Surface Audit + Gap Plan (NO-CODE)

Goal:
- audit current authored breadth before adding anything
- identify which shortages are real content shortages vs mechanic/tooling shortages

Do not patch in this part.

Audit specifically:
- event template breadth
- roadside encounter breadth
- side-mission definition breadth
- reward pool breadth
- merchant stock breadth
- weapon / armor / belt / consumable / passive breadth
- enemy family and boss breadth
- stage-specific authored variety

Use current docs and live `ContentDefinitions/` as truth, not memory.

Report specifically:
1. families that are still too narrow
2. content pools that are repeated too often
3. which desired additions fit current grammar cleanly
4. which desired additions would actually require mechanic expansion
5. whether Part 2 should run as-is or be adjusted

## Part 2 - Event / Roadside / Support Content Pack (LOW-MEDIUM RISK)

Goal:
- expand authored world feel through more event, roadside, and support-adjacent content

Likely scope:
- more `EventTemplates`
- more roadside-compatible authored outcomes inside the current event grammar
- more `SideMissions`
- more deterministic support stock / support variety inside current contract rules

Hard rule:
- stay inside the currently truthful event outcome and support grammar
- do not invent generic weighted effect routing if the contract does not support it

Validation after patching:
- global validation baseline
- any targeted tests required by touched content surface

## Part 3 - Gear / Reward / Merchant Content Pack (LOW-MEDIUM RISK)

Goal:
- widen item and reward variety so runs have more identity

Likely scope:
- new weapons
- new armors
- new belts if already supported by the current runtime slice
- new consumables inside the current narrow consumable effect slice
- new passive items/perks if already supported by the current runtime slice
- reward pool additions
- merchant stock table additions

Hard rule:
- if a new item idea needs a new runtime behavior, new status routing, or a new effect family, stop and say `escalate first`

Validation after patching:
- global validation baseline
- reward/support-related tests in the touched slice

## Part 4 - Enemy / Stage / Side-Mission Breadth Pack (LOW-MEDIUM RISK)

Goal:
- add more run-level opponent variety and stage identity

Likely scope:
- new enemies that fit the current combat/runtime schema
- new boss or miniboss authored breadth only if the current grammar fully supports it
- stage encounter table breadth
- side-mission target variety

Do not:
- add a new combat mechanic here
- add enemy scripting surfaces that current contracts do not support
- fake content breadth by quietly widening runtime grammar

Validation after patching:
- global validation baseline
- combat- and map-related tests in the touched slice

## Part 5 - Final Content Audit + Behavior-Sensitive Review (LOW RISK)

Goal:
- close the content breadth track truthfully
- confirm new content expanded variety without silently mutating architecture

Tasks:
1. Re-audit the expanded content surface.
2. Confirm validator cleanliness.
3. Call out any additions that are behavior-sensitive because of deterministic authoring order or narrow pools.
4. Call out anything still too thin for future content waves.
5. State whether future expansion should stay data-only or needs explicit mechanic work.

Final report format:
1. Executive Verdict
2. Baseline Validation
3. Content Gap Audit
4. Findings Before Patch
5. Applied Content Packs
6. Validation Results
7. Remaining Thin Areas
8. Behavior-Sensitive Content Risks
9. Intentionally Untouched Mechanic Surfaces
10. Escalation Items
11. Final Verdict

Before ending, give a 5-bullet handoff:
- what content breadth was added
- what stayed intentionally narrow
- what still needs a later content wave
- exact files or families that should be next
- whether the next planned prompt should run as-is or be adjusted
