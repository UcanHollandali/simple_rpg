# MAP OVERNIGHT QUEUE

Purpose: one short start-here file for the current map redesign + theming pass so the user does not have to juggle many prompt files at night.
Scope: tonight's practical run order only. This file does not replace authority docs or the deeper queue files.

Authority order:
1. `Docs/MAP_CONTRACT.md`
2. `Docs/SOURCE_OF_TRUTH.md`
3. `Docs/CONTENT_ARCHITECTURE_SPEC.md`
4. `Docs/VISUAL_AUDIO_STYLE_GUIDE.md`
5. `Docs/Promts/MAP_REDESIGN_CODEX_QUEUE.md`
6. `Docs/Promts/MAP_NODE_THEMING_CODEX_QUEUE.md`
7. `Docs/Promts/AI_ASSET_ROADMAP_V2.md`
8. `Docs/Promts/MAP_OVERHAUL_EXECUTION_PLAN.md`
9. this file

---

## 1. Tonight Use Only These Files

### Active tonight

1. `Docs/Promts/MAP_OVERNIGHT_QUEUE.md`
   - start here
   - tells you what to run and what to ignore
2. `Docs/Promts/MAP_REDESIGN_CODEX_QUEUE.md`
   - main code queue for map topology / placement / composer work
3. `Docs/Promts/MAP_NODE_THEMING_CODEX_QUEUE.md`
   - player-facing node naming queue
4. `Docs/Promts/AI_ASSET_ROADMAP_V2.md`
   - local asset workflow only
   - not a Codex-heavy overnight file

### Reference only tonight

1. `Docs/Promts/MAP_OVERHAUL_EXECUTION_PLAN.md`
   - full multi-day sequencing
   - read only if you want the broader shape
2. `Docs/Promts/CODEX_MAP_PATCH_QUEUE.md`
   - working-loop reference
   - not the main queue for tonight
3. `Docs/Promts/AI_ASSET_ROADMAP_BEGINNER.md`
   - fallback reference only
4. `Docs/Promts/MAP_RUNTIME_STATE_EXTRACTION_PLAN.md`
   - strictly later
   - do NOT start tonight

### Out of scope for tonight's map pass

Treat these as parked unless the task changes:
- `Docs/Promts/CODEX_AUDIT_REVIEW_PROMPTS.md`
- `Docs/Promts/CODEX_POLISH_PROMPTS.md`
- `Docs/Promts/codex_audio_rework_prompt.md`
- `Docs/Promts/codex_content_expansion_prompts.md`
- `Docs/Promts/codex_direct_prompt_order.md`
- `Docs/Promts/codex_final_hardening_prompts.md`
- `Docs/Promts/codex_map_redesign_plan.md`
- `Docs/Promts/codex_map_redesign_prompts.md`
- `Docs/Promts/codex_master_overnight_prompt.md`
- `Docs/Promts/codex_master_queue_plan.md`
- `Docs/Promts/codex_master_queue_runner.md`
- `Docs/Promts/codex_migration_prompts.md`
- `Docs/Promts/codex_playtest_tuning_prompts.md`
- `Docs/Promts/codex_refactor_plan.md`
- `Docs/Promts/codex_ui_rework_prompts.md`

Reason:
- they may still contain useful ideas
- but they are not part of the current clean map-night flow
- using them tonight increases context drift and prompt overlap risk

---

## 2. The Practical Rule

For tonight:
- use one code-touching prompt at a time
- do not start extraction
- do not ask Codex to generate art
- do local asset generation outside Codex
- keep map redesign and node theming as the only code queues

---

## 3. Decision Gate Before Theming Prompt 2

Before starting `Docs/Promts/MAP_NODE_THEMING_CODEX_QUEUE.md` Prompt 2, one of these must be true:

1. the user answered:
   - Q1 naming tone
   - Q2 stage variance
   - Q3 surface scope
2. the user explicitly accepted the recommended default:
   - `C / C / C`

Recommended default:
- Q1 = `C` mixed tone
- Q2 = `C` hamlet-only variance
- Q3 = `C` map + transition

If this decision gate is not cleared:
- run Theming Prompt 1 only
- stop before Theming Prompt 2

---

## 4. Tonight's Safe Run Order

### If you have NOT approved Q1 / Q2 / Q3 yet

Run in this exact order:

1. `MAP_REDESIGN_CODEX_QUEUE.md` Prompt 1
2. `MAP_NODE_THEMING_CODEX_QUEUE.md` Prompt 1
3. stop and decide Q1 / Q2 / Q3

This is the safest overnight start.

### If you already approve the recommended default `C / C / C`

Run in this exact order:

1. `MAP_REDESIGN_CODEX_QUEUE.md` Prompt 1
2. `MAP_NODE_THEMING_CODEX_QUEUE.md` Prompt 1
3. `MAP_NODE_THEMING_CODEX_QUEUE.md` Prompt 2
4. `MAP_REDESIGN_CODEX_QUEUE.md` Prompt 2
5. stop, validate, report

This is the best "tonight" queue if you want real progress without widening too far.

### If Prompt 2 of the redesign queue is unstable

Stop the overnight run after:
1. redesign Prompt 1
2. theming Prompt 1
3. theming Prompt 2 if approved

Do NOT auto-continue into redesign Prompt 3.

---

## 5. Do Not Run Tonight

Do NOT run tonight:
- `MAP_RUNTIME_STATE_EXTRACTION_PLAN.md`
- redesign Prompt 3+
- theming Prompt 3+
- any old `codex_*` legacy queue file
- any asset-production prompt inside Codex

Why:
- redesign Prompt 2 is the real risky boundary tonight
- extraction is explicitly last
- assets are cheaper and better done locally

---

## 6. Local Asset Work In Parallel

While Codex handles code:
- you can install / open ComfyUI
- you can install Krita AI Diffusion
- you can search Kenney
- you can generate ground / prop smoke tests locally

Do NOT ask Codex to spend the night generating art.

Use `Docs/Promts/AI_ASSET_ROADMAP_V2.md` only for:
- tool stack
- naming-to-asset boundary
- local production order

---

## 7. New Chat Template

If you want to start a fresh overnight Codex chat, use this shape:

```text
Map overnight queue calisiyoruz.

Read first:
- AGENTS.md
- Docs/DOC_PRECEDENCE.md
- Docs/HANDOFF.md
- Docs/MAP_CONTRACT.md
- Docs/SOURCE_OF_TRUTH.md
- Docs/Promts/MAP_OVERNIGHT_QUEUE.md
- Docs/Promts/MAP_REDESIGN_CODEX_QUEUE.md
- Docs/Promts/MAP_NODE_THEMING_CODEX_QUEUE.md

Tonight's rule:
- one code-touching prompt at a time
- no extraction
- no asset generation in Codex
- run validation after each code-touching prompt

Approved theming decision:
- Q1 = C
- Q2 = C
- Q3 = C

Execute only this order tonight:
1. MAP_REDESIGN Prompt 1
2. MAP_NODE_THEMING Prompt 1
3. MAP_NODE_THEMING Prompt 2
4. MAP_REDESIGN Prompt 2

If MAP_REDESIGN Prompt 2 becomes unstable or breaks validation, stop there and report instead of widening scope.
```

If you have NOT approved `C / C / C`, remove that block and stop after the two Prompt 1 audits.

---

## 8. Success Condition For Tonight

Tonight is successful if:
- you used only the active files above
- no one touched extraction
- Prompt 1 audits completed
- theming Prompt 2 landed only if the approval gate was cleared
- redesign Prompt 2 either landed cleanly or stopped with a clear report
- no prompt overlap created confusion

End of overnight queue.
