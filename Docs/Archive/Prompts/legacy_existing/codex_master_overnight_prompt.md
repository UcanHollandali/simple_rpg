# SIMPLE RPG — Master Overnight Queue Prompt

Use this prompt as the first message in the thread before pasting the queued task prompts from:
- `codex_refactor_plan.md`
- `codex_ui_rework_prompts.md`
- `codex_map_redesign_prompts.md`
- `codex_migration_prompts.md`
- `codex_audio_rework_prompt.md`
- `codex_playtest_tuning_prompts.md`
- `codex_content_expansion_prompts.md`
- `codex_final_hardening_prompts.md`
- `codex_master_queue_plan.md`

This file is the queue wrapper and execution contract.
It is not the authority for gameplay rules.
Authority still comes from `AGENTS.md`, `Docs/DOC_PRECEDENCE.md`, `Docs/HANDOFF.md`, and the closest relevant authority doc.

---

## 1. Reality / Honesty Contract

Separate verified facts from assumptions.

- `VERIFIED` = directly confirmed from the current checked-out repo, current docs, current code, current tests, or current tool output.
- `INFERENCE` = reasonable conclusion from verified facts, but not directly proven yet.
- If the prompt text disagrees with the current checked-out repo, the current checked-out repo wins.
- If `HANDOFF.md` conflicts with an authority doc, the authority doc wins.
- If the prompt text is stale because a previous queued task already changed the repo, use the current repo state and say that the prompt assumption was stale.

Do not pretend a task is complete if it is blocked.
Do not claim a validation passed unless it actually ran and passed.

---

## 2. Overnight Execution Contract

The user is queueing multiple prompts overnight.
Each prompt must be handled as a full end-to-end task, not as a partial analysis pass.

For every queued task:

1. Read `AGENTS.md`, `Docs/DOC_PRECEDENCE.md`, and `Docs/HANDOFF.md` first.
2. Read only the closest authority docs needed for the current task.
3. Re-read the files touched by previous queued tasks if they are relevant to the current task.
4. Re-establish the current repo truth before patching.
5. Run the baseline validation required by that prompt before patching, unless the prompt explicitly says otherwise.
6. Implement the safe scope fully.
7. Re-run the required validation after each non-trivial patch or at the end of the pass, per prompt rules.
8. Do not stop at analysis if there are safe patches still available.
9. Do not leave the task half-finished just because it is large. Continue until:
   - the prompt scope is completed, or
   - a real blocker requires `escalate first`, or
   - a required gate says `NO-GO`, or
   - a validation failure reveals a separate deeper regression that must be reported instead of papered over.

If a prompt encounters failure:
- diagnose it
- attempt the safe fix
- rerun the required validations
- only stop early if the remaining issue is genuinely blocked by risk-lane or missing prerequisite work

Do not silently widen scope because related debt is visible.

---

## 3. Cross-Task Gate Rules

These rules exist because this thread will receive sequential queued prompts.

If any previous queued task in this same thread ended with one of the following:
- `ESCALATE FIRST`
- `NO-GO`
- `MIGRATION BLOCKER:`

and that blocker is relevant to the current task, then:

1. do not blindly continue implementation
2. quickly verify whether the blocker still applies in the checked-out repo
3. if it still applies, report that this queued task must not proceed yet
4. do not fake a completion report
5. do not push into a higher-risk lane just to keep queue momentum

Specific gate rules:

- Do not start migration work past `Migration Part 1` if `Refactor Part 5` did not produce a real `GO`.
- Do not start `Migration Part 6` if the map redesign track was intended but `codex_map_redesign_prompts.md` Part 4-8 are not yet settled.
- Do not treat `Migration Part 10` as a full UI redesign if the UI rework track already established the shared foundation.
- If a prior task changed a label/semantic contract such as event-facing naming, use the new checked-out repo truth instead of the stale prompt wording.

---

## 4. Risk-Lane Discipline

Respect the repo risk lanes in `AGENTS.md`.

Fast-lane / low-risk work:
- UI helper extraction
- screen/presenter cleanup
- doc truth alignment
- validators/tests cleanup toward existing owners

Guarded lane:
- application orchestration changes that keep the same owners
- map routing cleanup inside current authority boundaries
- save/load orchestration changes that do not change schema shape
- large-file extraction with real fan-out risk

Escalate-first lane:
- save-schema/version changes
- new flow states
- new command families
- new event/domain-event families
- source-of-truth owner changes
- gameplay autoload additions
- scene/core boundary rewrites

When in doubt, choose the higher-risk lane.

---

## 5. Non-Negotiable Implementation Rules

- Do not move gameplay truth into UI.
- Do not use display text as logic keys.
- Do not widen `RunState` compatibility accessors.
- Do not widen `AppBootstrap` public surface without explicit need.
- Do not change save shape unless the prompt is explicitly a migration/save-schema step that requires it.
- Do not create new docs unless the prompt explicitly justifies it and the closest authority doc is insufficient.
- Do not delete files just because they look stale; verify references first.
- Do not treat `codex_*.md` workflow files as cleanup targets.
- Do not trust old line numbers or old file-existence assumptions inside prompts without checking the repo.

Current known repo-specific gotchas:
- `NodeResolve` is still an active flow concern unless a prior queued task has safely removed/replaced it.
- boss routing truth currently shows drift across code, tests, and handoff wording; use checked-out runtime truth plus validation results, not stale assumptions.
- `Event` save is still outside the implemented save-safe baseline unless a later migration explicitly changes that.
- map-related labels, roadside semantics, and UI wording may drift across tracks; current checked-out code wins.
- `Brace` is still widely live across combat code, tests, and docs until the migration track explicitly replaces it.
- if the prototype map asset track is active, finish it before the migration track starts; do not interleave asset hookup with migration-core changes.
- some root temp/legacy artifacts may still exist; audit them against the actual repo before deleting.

---

## 6. Required Reporting Style For Every Queued Task

Each queued task must end with:

1. the prompt-specific report format requested by that task
2. a short explicit statement of:
   - what was completed
   - what was intentionally untouched
   - what remains risky
3. the following 5-bullet handoff exactly in substance:
   - what was fixed
   - what was intentionally untouched
   - what remains risky
   - exact files that should be next
   - whether the next planned prompt should be run as-is or adjusted

If a task is blocked, the handoff must say so clearly.

---

## 7. Validation Discipline

For each queued task:
- run the exact validation commands required by that prompt
- do not replace a full suite with a smaller subset unless the prompt explicitly allows it
- if baseline validation already fails before patching, say so clearly and continue only if the task can still safely proceed
- if a required validation fails after patching, attempt the safe fix before ending
- if a queued task is supposed to establish flow truth for later tasks and cannot do so cleanly, explicitly say the next queued prompt should be adjusted rather than run as-is

If a validation failure is unrelated to the current change:
- say so explicitly
- do not hide it
- do not claim the repo is green

---

## 8. Queue Order To Use

Use the global order from `codex_master_queue_plan.md`.

Recommended order:

### Phase 1 — Foundation Cleanup
1. Refactor Part 0
2. Refactor Part 1

### Phase 2 — UI Foundation
3. UI Rework Part 1
4. UI Rework Part 2
5. UI Rework Part 3

### Phase 3 — Shared Structural Extraction
6. Refactor Part 2

### Phase 4 — Map Redesign
7. Map Redesign Part 1
8. Map Redesign Part 2
9. Map Redesign Part 3
10. Map Redesign Part 4
11. Map Redesign Part 5
12. Map Redesign Part 6
13. Map Redesign Part 7
14. Map Redesign Part 8

### Phase 5 — Screen Rework
15. UI Rework Part 4
16. UI Rework Part 5
17. UI Rework Part 6
18. UI Rework Part 7

### Phase 6 — Audit Gate
19. Refactor Part 3
20. Refactor Part 4
21. Refactor Part 5

### Phase 7 — Migration Core
22. Migration Part 0
23. Migration Part 1
24. Migration Part 2
25. Migration Part 3
26. Migration Part 4
27. Migration Part 5

### Phase 8 — Content + Routing
28. Migration Part 6
29. Migration Part 7
30. Migration Part 8
31. Migration Part 9

### Phase 9 — Polish + Tuning
32. Migration Part 10
33. Migration Part 11
34. Migration Part 12

### Phase 10 — Final Audit
35. UI Rework Part 8
36. Refactor Part 6

Optional later:
- map asset A1-A4
- migration bonus A-F

---

## 9. Safe Parallel Pairs

Only use these if the queue system or workflow supports true separation and later merge review:

- UI Rework Part 4 + UI Rework Part 5
- Migration Part 0 + Migration Part 1
- Migration Part 8 + Migration Part 9
- Migration Part 10 + Migration Part 11

If not sure, run serially.

---

## 10. Playtest Gates

These are the points where the user should strongly consider pausing the overnight chain and checking the build manually.

Checkpoint A:
- after Map Redesign Part 8
- question: topology, roadside fix, and map feel good enough?

Checkpoint B:
- after UI Rework Part 7
- question: UI readability, mobile fit, and desktop preview acceptable?

Checkpoint C:
- after Migration Part 3
- question: Defend/Guard/Shield combat loop actually feels playable?

Checkpoint D:
- after Migration Part 12
- question: full run balance and coherence good enough for playtest judgment?

If the queue cannot be paused automatically, still obey the gate rules in section 3.

---

## 11. Suggested Extra Safeguards

These are additions beyond the part prompts and should be followed unless a task explicitly conflicts:

- Re-read `Docs/HANDOFF.md` after any task that changes flow, UI shell behavior, save policy, or player-facing naming.
- If a task changes runtime spine wording, update `HANDOFF.md` in the same pass if the prompt allows doc sync.
- If a task changes a player-facing term that tests assert on, update the relevant test in the same pass.
- If a task removes duplication by extraction, keep the new helper narrow and named by concern, not by screen.
- If a task discovers a stale prompt assumption, mention it in the report so the next queued prompt inherits the corrected context.
- If a task touches map routing, explicitly check `test_phase2_loop.gd`, `test_stage_progression.gd`, and `test_map_runtime_state.gd` if they are in scope.
- If a task touches combat UI or combat rules, explicitly check presenter tests and combat-related Godot tests if the prompt requires them.
- If a task touches save-sensitive code, explicitly call out current `save_schema_version` before and after.

---

## 12. Copy/Paste Use

Recommended workflow:

1. Paste this master prompt first.
2. Then paste one queued task prompt at a time in the order above.
3. Keep all queued tasks in the same thread so blocker/gate context carries forward.
4. If the queue runner cannot preserve prior context, prepend each task with:
   - "Use the rules from `codex_master_overnight_prompt.md`."

---

## 13. Final Instruction To The Agent

For every subsequent queued prompt in this thread:

- treat this master prompt as the execution wrapper
- treat the queued part prompt as the task-specific scope
- finish the current task fully unless a real blocker requires `ESCALATE FIRST`, `NO-GO`, or `MIGRATION BLOCKER`
- do not end with partial work when safe completion is still possible
- preserve repo truth, authority boundaries, and validation discipline

---

## 14. Optional Post-Core Tracks

These are optional follow-up tracks after the main `Q01-Q36` overhaul queue.

Recommended order:

1. audio replacement track
2. playtest and tuning track
3. content breadth track
4. final hardening track

Use this order unless the checked-out repo state gives a concrete reason to adjust it.

Gate rules for these optional tracks:

- If the audio track is planned, prefer it before the playtest/tuning track so subjective playtest judgement is not distorted by known-bad temp music.
- Prefer the playtest/tuning track before the content breadth track so new content responds to real identified gaps instead of guesswork.
- Run the final hardening track last.
- If any optional track ends with `ESCALATE FIRST` or `NO-GO`, do not blindly continue to the next optional track.
