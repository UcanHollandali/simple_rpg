# SIMPLE RPG - Direct Prompt Order

This file replaces the wrapper/runner workflow.

Use this if you want to run the overhaul through direct source prompts only.
Do not use:
- `codex_master_overnight_prompt.md`
- `codex_master_queue_runner.md`

Instead:
- open a new chat
- paste the actual source prompt part text directly from the listed file
- run one part at a time
- stop at the listed checkpoints

Important:
- if you keep the current checked-out repo state, the new chat must treat the current repo as truth
- do not assume the old queue completed cleanly
- if you want a truly clean restart, do it in a fresh branch/worktree or after manually deciding what to keep

---

## 0. Direct Source Files

Use only these files as prompt sources:

1. `codex_refactor_plan.md`
2. `codex_ui_rework_prompts.md`
3. `codex_map_redesign_prompts.md`
4. `codex_migration_prompts.md`
5. `codex_audio_rework_prompt.md`
6. `codex_playtest_tuning_prompts.md`
7. `codex_content_expansion_prompts.md`
8. `codex_final_hardening_prompts.md`

---

## 1. Main Overhaul Order

Paste these source parts directly, in this order:

1. `codex_refactor_plan.md` -> `Part 0`
2. `codex_refactor_plan.md` -> `Part 1`
3. `codex_ui_rework_prompts.md` -> `Part 1`
4. `codex_ui_rework_prompts.md` -> `Part 2`
5. `codex_ui_rework_prompts.md` -> `Part 3`
6. `codex_refactor_plan.md` -> `Part 2`
7. `codex_map_redesign_prompts.md` -> `Part 1`
8. `codex_map_redesign_prompts.md` -> `Part 2`
9. `codex_map_redesign_prompts.md` -> `Part 3`
10. `codex_map_redesign_prompts.md` -> `Part 4`
11. `codex_map_redesign_prompts.md` -> `Part 5`
12. `codex_map_redesign_prompts.md` -> `Part 6`
13. `codex_map_redesign_prompts.md` -> `Part 7`
14. `codex_map_redesign_prompts.md` -> `Part 8`
15. `codex_ui_rework_prompts.md` -> `Part 4`
16. `codex_ui_rework_prompts.md` -> `Part 5`
17. `codex_ui_rework_prompts.md` -> `Part 6`
18. `codex_ui_rework_prompts.md` -> `Part 7`
19. `codex_refactor_plan.md` -> `Part 3`
20. `codex_refactor_plan.md` -> `Part 4`
21. `codex_refactor_plan.md` -> `Part 5`
22. `codex_migration_prompts.md` -> `Part 0`
23. `codex_migration_prompts.md` -> `Part 1`
24. `codex_migration_prompts.md` -> `Part 2`
25. `codex_migration_prompts.md` -> `Part 3`
26. `codex_migration_prompts.md` -> `Part 4`
27. `codex_migration_prompts.md` -> `Part 5`
28. `codex_migration_prompts.md` -> `Part 6`
29. `codex_migration_prompts.md` -> `Part 7`
30. `codex_migration_prompts.md` -> `Part 8`
31. `codex_migration_prompts.md` -> `Part 9`
32. `codex_migration_prompts.md` -> `Part 10`
33. `codex_migration_prompts.md` -> `Part 11`
34. `codex_migration_prompts.md` -> `Part 12`
35. `codex_ui_rework_prompts.md` -> `Part 8`
36. `codex_refactor_plan.md` -> `Part 6`

---

## 2. Optional Prototype Map Asset Track

If you want the prototype map asset kit, insert these here:
- after `Main Overhaul 18`
- before `Main Overhaul 19`

Order:
1. `codex_map_redesign_prompts.md` -> `Asset Part 1`
2. `codex_map_redesign_prompts.md` -> `Asset Part 2`
3. `codex_map_redesign_prompts.md` -> `Asset Part 3`
4. `codex_map_redesign_prompts.md` -> `Asset Part 4`

---

## 3. Post-Core Order

Run these only after the main overhaul is stable.

Recommended order:

### Audio
1. `codex_audio_rework_prompt.md` -> `Part 1`
2. `codex_audio_rework_prompt.md` -> `Part 2`
3. `codex_audio_rework_prompt.md` -> `Part 3`
4. `codex_audio_rework_prompt.md` -> `Part 4`
5. `codex_audio_rework_prompt.md` -> `Part 5`

### Playtest / Tuning
1. `codex_playtest_tuning_prompts.md` -> `Part 1`
2. `codex_playtest_tuning_prompts.md` -> `Part 2`
3. `codex_playtest_tuning_prompts.md` -> `Part 3`
4. `codex_playtest_tuning_prompts.md` -> `Part 4`
5. `codex_playtest_tuning_prompts.md` -> `Part 5`

### Content Breadth
1. `codex_content_expansion_prompts.md` -> `Part 1`
2. `codex_content_expansion_prompts.md` -> `Part 2`
3. `codex_content_expansion_prompts.md` -> `Part 3`
4. `codex_content_expansion_prompts.md` -> `Part 4`
5. `codex_content_expansion_prompts.md` -> `Part 5`

### Final Hardening
1. `codex_final_hardening_prompts.md` -> `Part 1`
2. `codex_final_hardening_prompts.md` -> `Part 2`
3. `codex_final_hardening_prompts.md` -> `Part 3`
4. `codex_final_hardening_prompts.md` -> `Part 4`

---

## 4. Stop Points

Stop and manually review after these:

1. after Main Overhaul `14`
   - map topology / routing / roadside behavior
2. after Main Overhaul `18`
   - UI readability / screen fit / overlay behavior
3. after Main Overhaul `21`
   - migration readiness
4. after Main Overhaul `25`
   - combat feel after migration
5. after Main Overhaul `34`
   - full run coherence before final audits
6. after Audio `Part 2`
   - music quality check
7. after Playtest/Tuning `Part 5`
   - decide whether content breadth should expand as-is or be adjusted
8. after Final Hardening `Part 4`
   - final repo verdict

---

## 5. Recommended New-Chat Start

Use a fresh chat.

First message:
- tell the agent to use the current checked-out repo as truth
- tell it you are running direct source prompts one by one
- tell it not to rely on `codex_master_overnight_prompt.md` or `codex_master_queue_runner.md`

Then paste the actual part body from the source file you want to run.

Example first message:

```text
Use the current checked-out repo as truth.
I am running the overhaul through direct source prompts one by one.
Do not rely on codex_master_overnight_prompt.md or codex_master_queue_runner.md.
For each prompt I paste, execute only that source prompt part fully, run the validations requested inside it, and report blockers honestly.
```

---

## 6. Current Recommendation

Because the old redirected queue produced a mix of real patches and NO-GO no-op passes, the safer workflow now is:

1. direct source prompt only
2. one part at a time
3. manual stop at checkpoints
4. no deep queued overnight chain until the repo is green again
