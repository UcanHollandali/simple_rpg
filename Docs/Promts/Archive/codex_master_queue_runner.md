# SIMPLE RPG — Single-File Queue Runner

This is the practical queue file.

Use this if you do **not** want to manually jump between:
- `codex_refactor_plan.md`
- `codex_ui_rework_prompts.md`
- `codex_map_redesign_prompts.md`
- `codex_migration_prompts.md`
- `codex_master_queue_plan.md`
- `codex_master_overnight_prompt.md`

With this file, your workflow is:

1. Start one thread.
2. Paste the bootstrap message from section `A`.
3. Then queue the short `Q01`, `Q02`, `Q03`... messages from section `B` in order.

You do **not** need to manually rewrite the source prompt files anymore.
They remain the local source of truth for task bodies.

---

## A. Thread Bootstrap Message

Paste this once at the start of the thread:

```text
Use the execution rules in `codex_master_overnight_prompt.md` as the wrapper for every later queued task in this thread.

Important:
- Re-check current repo truth before each queued task.
- If a queued task depends on a previous GO / NO-GO gate, obey that gate.
- If a previous queued task ended with `ESCALATE FIRST`, `NO-GO`, or `MIGRATION BLOCKER:`, do not blindly continue.
- Treat Q01 as the live truth gate for `NodeResolve`, boss routing, and overlay handoff. If Q01 reports unresolved contradiction or says the next prompt should be adjusted, do not keep queueing as if the old assumptions still hold.
- For each queued task, open the mapped local source file/part from `codex_master_queue_runner.md`, execute that task fully, run the prompt-required validation, and end with the required 5-bullet handoff:
  - what was fixed
  - what was intentionally untouched
  - what remains risky
  - exact files that should be next
  - whether the next planned prompt should be run as-is or adjusted

Do not stop at analysis if safe implementation remains.
Do not fake validation results.
If prompt wording is stale versus the checked-out repo, use the checked-out repo and say so explicitly.
```

---

## B. Queue Messages

Paste these as separate queued user messages in the same thread.

### Q01

```text
Run Q01 from `codex_master_queue_runner.md`.

Task source:
- file: `codex_refactor_plan.md`
- part: `Part 0 — Overlay / Resolve / Redundant Screen Cleanup`

Use the task exactly from that source file, under the wrapper rules from `codex_master_overnight_prompt.md`.
```

Operational note for Q01:
- treat it as the first hard truth-audit for `NodeResolve` vs overlay flow
- treat it as the first hard truth-audit for boss routing drift across code/tests/docs
- if Q01 says later prompts must be adjusted, do not continue as if the original assumptions were still valid

### Q02

```text
Run Q02 from `codex_master_queue_runner.md`.

Task source:
- file: `codex_refactor_plan.md`
- part: `Part 1 — GDScript Stabilization + Code Cleanup`

Use the task exactly from that source file, under the wrapper rules from `codex_master_overnight_prompt.md`.
```

### Q03

```text
Run Q03 from `codex_master_queue_runner.md`.

Task source:
- file: `codex_ui_rework_prompts.md`
- part: `Part 1 — Authority-First UI Audit + Cleanup Inventory`

Use the task exactly from that source file, under the wrapper rules from `codex_master_overnight_prompt.md`.
```

### Q04

```text
Run Q04 from `codex_master_queue_runner.md`.

Task source:
- file: `codex_ui_rework_prompts.md`
- part: `Part 2 — Shared UI Foundation / Design System Pass`

Use the task exactly from that source file, under the wrapper rules from `codex_master_overnight_prompt.md`.
```

### Q05

```text
Run Q05 from `codex_master_queue_runner.md`.

Task source:
- file: `codex_ui_rework_prompts.md`
- part: `Part 3 — Resolution / Scaling / Desktop Preview Fix`

Use the task exactly from that source file, under the wrapper rules from `codex_master_overnight_prompt.md`.
```

### Q06

```text
Run Q06 from `codex_master_queue_runner.md`.

Task source:
- file: `codex_refactor_plan.md`
- part: `Part 2 — Scene/UI Structural Extraction`

Important local note:
- use the currently revised scope from that file
- this pass is shared/cross-cut extraction, not a full screen-by-screen UI rework

Use the task exactly from that source file, under the wrapper rules from `codex_master_overnight_prompt.md`.
```

### Q07

```text
Run Q07 from `codex_master_queue_runner.md`.

Task source:
- file: `codex_map_redesign_prompts.md`
- part: `Part 1 — Audit + Scope Lock + Stale Inventory`

Use the task exactly from that source file, under the wrapper rules from `codex_master_overnight_prompt.md`.
```

### Q08

```text
Run Q08 from `codex_master_queue_runner.md`.

Task source:
- file: `codex_map_redesign_prompts.md`
- part: `Part 2 — Runtime Graph Redesign ONLY`

Use the task exactly from that source file, under the wrapper rules from `codex_master_overnight_prompt.md`.
```

### Q09

```text
Run Q09 from `codex_master_queue_runner.md`.

Task source:
- file: `codex_map_redesign_prompts.md`
- part: `Part 3 — Family Placement / Node Role Assignment Redesign ONLY`

Use the task exactly from that source file, under the wrapper rules from `codex_master_overnight_prompt.md`.
```

### Q10

```text
Run Q10 from `codex_master_queue_runner.md`.

Task source:
- file: `codex_map_redesign_prompts.md`
- part: `Part 4 — Roadside / Event Semantic Split + Destination Bug Fix`

Use the task exactly from that source file, under the wrapper rules from `codex_master_overnight_prompt.md`.
```

### Q11

```text
Run Q11 from `codex_master_queue_runner.md`.

Task source:
- file: `codex_map_redesign_prompts.md`
- part: `Part 5 — Map Composer / Layout Redesign ONLY`

Use the task exactly from that source file, under the wrapper rules from `codex_master_overnight_prompt.md`.
```

### Q12

```text
Run Q12 from `codex_master_queue_runner.md`.

Task source:
- file: `codex_map_redesign_prompts.md`
- part: `Part 6 — Map Explore Scene / Presenter / UI Cleanup ONLY`

Use the task exactly from that source file, under the wrapper rules from `codex_master_overnight_prompt.md`.
```

### Q13

```text
Run Q13 from `codex_master_queue_runner.md`.

Task source:
- file: `codex_map_redesign_prompts.md`
- part: `Part 7 — Stale/Dead Cleanup + Doc Truth Sync ONLY`

Use the task exactly from that source file, under the wrapper rules from `codex_master_overnight_prompt.md`.
```

### Q14

```text
Run Q14 from `codex_master_queue_runner.md`.

Task source:
- file: `codex_map_redesign_prompts.md`
- part: `Part 8 — Final Review + Audit + Patch`

Use the task exactly from that source file, under the wrapper rules from `codex_master_overnight_prompt.md`.
```

### Q15

```text
Run Q15 from `codex_master_queue_runner.md`.

Task source:
- file: `codex_ui_rework_prompts.md`
- part: `Part 4 — MapExplore Full UI Rework`

Important local note:
- this is intended after map redesign has settled

Use the task exactly from that source file, under the wrapper rules from `codex_master_overnight_prompt.md`.
```

### Q16

```text
Run Q16 from `codex_master_queue_runner.md`.

Task source:
- file: `codex_ui_rework_prompts.md`
- part: `Part 5 — Combat Full UI Rework`

Important local note:
- defensive action card should stay migration-friendly for later Defend/Guard work

Use the task exactly from that source file, under the wrapper rules from `codex_master_overnight_prompt.md`.
```

### Q17

```text
Run Q17 from `codex_master_queue_runner.md`.

Task source:
- file: `codex_ui_rework_prompts.md`
- part: `Part 6 — Overlay Screens Unified Rework`

Use the task exactly from that source file, under the wrapper rules from `codex_master_overnight_prompt.md`.
```

### Q18

```text
Run Q18 from `codex_master_queue_runner.md`.

Task source:
- file: `codex_ui_rework_prompts.md`
- part: `Part 7 — Cleanup / Dead UI / Stale Doc Removal`

Use the task exactly from that source file, under the wrapper rules from `codex_master_overnight_prompt.md`.
```

---

## Optional Asset Track

If you want the prototype map asset kit, run `A1` → `A4` **here**, after `Q18` and before `Q19`.

Reason:
- map redesign code part'ları bitmiş olur
- UI Rework Part 4-7 map/presenter yapısını settle etmiş olur
- migration başlamadan önce prototype map visuals bağlanmış olur

### A1

```text
Run A1 from `codex_master_queue_runner.md`.

Task source:
- file: `codex_map_redesign_prompts.md`
- part: `Asset Part 1 — Prototype Map Asset Audit + Gap Plan`

Use the task exactly from that source file, under the wrapper rules from `codex_master_overnight_prompt.md`.
```

### A2

```text
Run A2 from `codex_master_queue_runner.md`.

Task source:
- file: `codex_map_redesign_prompts.md`
- part: `Asset Part 2 — Generate / Add Small Prototype Map Kit`

Use the task exactly from that source file, under the wrapper rules from `codex_master_overnight_prompt.md`.
```

### A3

```text
Run A3 from `codex_master_queue_runner.md`.

Task source:
- file: `codex_map_redesign_prompts.md`
- part: `Asset Part 3 — Hook Prototype Map Kit Into Board`

Use the task exactly from that source file, under the wrapper rules from `codex_master_overnight_prompt.md`.
```

### A4

```text
Run A4 from `codex_master_queue_runner.md`.

Task source:
- file: `codex_map_redesign_prompts.md`
- part: `Asset Part 4 — Final Prototype Asset Review + Cleanup + Doc/Manifest Sync`

Use the task exactly from that source file, under the wrapper rules from `codex_master_overnight_prompt.md`.
```

### Q19

```text
Run Q19 from `codex_master_queue_runner.md`.

Task source:
- file: `codex_refactor_plan.md`
- part: `Part 3 — Doc/Guard Hardening + AppBootstrap Freeze`

Use the task exactly from that source file, under the wrapper rules from `codex_master_overnight_prompt.md`.
```

### Q20

```text
Run Q20 from `codex_master_queue_runner.md`.

Task source:
- file: `codex_refactor_plan.md`
- part: `Part 4 — Final Review + Audit + Patch Verification`

Use the task exactly from that source file, under the wrapper rules from `codex_master_overnight_prompt.md`.
```

### Q21

```text
Run Q21 from `codex_master_queue_runner.md`.

Task source:
- file: `codex_refactor_plan.md`
- part: `Part 5 — Pre-Migration Readiness Check`

Important gate:
- if this ends in `NO-GO` or `MIGRATION BLOCKER:`, later migration tasks must not proceed blindly

Use the task exactly from that source file, under the wrapper rules from `codex_master_overnight_prompt.md`.
```

### Q22

```text
Run Q22 from `codex_master_queue_runner.md`.

Task source:
- file: `codex_migration_prompts.md`
- part: `Part 0 — Gameplay Tunables Merkezilestirme`

Use the task exactly from that source file, under the wrapper rules from `codex_master_overnight_prompt.md`.
```

### Q23

```text
Run Q23 from `codex_master_queue_runner.md`.

Task source:
- file: `codex_migration_prompts.md`
- part: `Part 1 — Authority Audit ve Migration Plan`

Use the task exactly from that source file, under the wrapper rules from `codex_master_overnight_prompt.md`.
```

### Q24

```text
Run Q24 from `codex_master_queue_runner.md`.

Task source:
- file: `codex_migration_prompts.md`
- part: `Part 2 — Inventory / Equipment Migration`

Gate reminder:
- do not proceed if Q21 did not produce a real GO

Use the task exactly from that source file, under the wrapper rules from `codex_master_overnight_prompt.md`.
```

### Q25

```text
Run Q25 from `codex_master_queue_runner.md`.

Task source:
- file: `codex_migration_prompts.md`
- part: `Part 3 — Combat Foundation Migration (Brace -> Defend/Guard)`

Use the task exactly from that source file, under the wrapper rules from `codex_master_overnight_prompt.md`.
```

### Q26

```text
Run Q26 from `codex_master_queue_runner.md`.

Task source:
- file: `codex_migration_prompts.md`
- part: `Part 4 — Progression Migration (XP -> Character Perk)`

Use the task exactly from that source file, under the wrapper rules from `codex_master_overnight_prompt.md`.
```

### Q27

```text
Run Q27 from `codex_master_queue_runner.md`.

Task source:
- file: `codex_migration_prompts.md`
- part: `Part 5 — Item Taxonomy Temizligi`

Use the task exactly from that source file, under the wrapper rules from `codex_master_overnight_prompt.md`.
```

### Q28

```text
Run Q28 from `codex_master_queue_runner.md`.

Task source:
- file: `codex_migration_prompts.md`
- part: `Part 6 — Map / Node / Content Routing Temizligi`

Gate reminder:
- if the map redesign track was intended, it should already be settled before this step

Use the task exactly from that source file, under the wrapper rules from `codex_master_overnight_prompt.md`.
```

### Q29

```text
Run Q29 from `codex_master_queue_runner.md`.

Task source:
- file: `codex_migration_prompts.md`
- part: `Part 7 — Acquisition Routing + Ilk Content Pack`

Use the task exactly from that source file, under the wrapper rules from `codex_master_overnight_prompt.md`.
```

### Q30

```text
Run Q30 from `codex_master_queue_runner.md`.

Task source:
- file: `codex_migration_prompts.md`
- part: `Part 8 — Event + Roadside Content Pack`

Use the task exactly from that source file, under the wrapper rules from `codex_master_overnight_prompt.md`.
```

### Q31

```text
Run Q31 from `codex_master_queue_runner.md`.

Task source:
- file: `codex_migration_prompts.md`
- part: `Part 9 — Enemy Content Pack`

Use the task exactly from that source file, under the wrapper rules from `codex_master_overnight_prompt.md`.
```

### Q32

```text
Run Q32 from `codex_master_queue_runner.md`.

Task source:
- file: `codex_migration_prompts.md`
- part: `Part 10 — UI Polish + Terim Tutarlılığı`

Important local note:
- this is migration-era UI plug-in/polish, not a full redesign pass

Use the task exactly from that source file, under the wrapper rules from `codex_master_overnight_prompt.md`.
```

### Q33

```text
Run Q33 from `codex_master_queue_runner.md`.

Task source:
- file: `codex_migration_prompts.md`
- part: `Part 11 — Merchant / Reward / Stage Tuning`

Use the task exactly from that source file, under the wrapper rules from `codex_master_overnight_prompt.md`.
```

### Q34

```text
Run Q34 from `codex_master_queue_runner.md`.

Task source:
- file: `codex_migration_prompts.md`
- part: `Part 12 — Final Cleanup + Audit`

Use the task exactly from that source file, under the wrapper rules from `codex_master_overnight_prompt.md`.
```

### Q35

```text
Run Q35 from `codex_master_queue_runner.md`.

Task source:
- file: `codex_ui_rework_prompts.md`
- part: `Part 8 — Final Review + Audit + Patch`

Important local note:
- this final UI audit is intended after the migration track, not before it

Use the task exactly from that source file, under the wrapper rules from `codex_master_overnight_prompt.md`.
```

### Q36

```text
Run Q36 from `codex_master_queue_runner.md`.

Task source:
- file: `codex_refactor_plan.md`
- part: `Part 6 — Post-Migration Grand Audit`

This is the final end-to-end audit.
Use the task exactly from that source file, under the wrapper rules from `codex_master_overnight_prompt.md`.
```

---

## Optional Migration Bonus Track

Only use these after the core queue is stable and you deliberately want extra depth/content variety beyond the main playtest baseline.

### B1

```text
Run B1 from `codex_master_queue_runner.md`.

Task source:
- file: `codex_migration_prompts.md`
- part: `BONUS PART A — Weapon Identity: Durability Profilleri`

Use the task exactly from that source file, under the wrapper rules from `codex_master_overnight_prompt.md`.
```

### B2

```text
Run B2 from `codex_master_queue_runner.md`.

Task source:
- file: `codex_migration_prompts.md`
- part: `BONUS PART B — Guard Decay Sistemi`

Use the task exactly from that source file, under the wrapper rules from `codex_master_overnight_prompt.md`.
```

### B3

```text
Run B3 from `codex_master_queue_runner.md`.

Task source:
- file: `codex_migration_prompts.md`
- part: `BONUS PART C — Roadside Encounter: Sıklık ve Tetikleyici Çeşitliliği`

Use the task exactly from that source file, under the wrapper rules from `codex_master_overnight_prompt.md`.
```

### B4

```text
Run B4 from `codex_master_queue_runner.md`.

Task source:
- file: `codex_migration_prompts.md`
- part: `BONUS PART D — Hamlet Flavor: Köy Kişilikleri`

Use the task exactly from that source file, under the wrapper rules from `codex_master_overnight_prompt.md`.
```

### B5

```text
Run B5 from `codex_master_queue_runner.md`.

Task source:
- file: `codex_migration_prompts.md`
- part: `BONUS PART E — Ek Event/Roadside İçerik Turu`

Use the task exactly from that source file, under the wrapper rules from `codex_master_overnight_prompt.md`.
```

### B6

```text
Run B6 from `codex_master_queue_runner.md`.

Task source:
- file: `codex_migration_prompts.md`
- part: `BONUS PART F — Ek Enemy Varyantları`

Use the task exactly from that source file, under the wrapper rules from `codex_master_overnight_prompt.md`.
```

---

## C. Optional Parallel Queue Messages

Only use these if you deliberately want parallel work and are prepared for merge review.

Safe-ish pairs:
- `Q15` + `Q16`
- `Q22` + `Q23`
- `Q30` + `Q31`
- `Q32` + `Q33`

If unsure, stay serial.

---

## D. Recommended Overnight Batching

Most conservative:

### Night 1
`Q01` → `Q18`

Optional if you want prototype map visuals before migration:
`A1` → `A4`

Then review the result of:
- `Q14` map milestone
- `Q18` UI milestone
- optional `A4` asset milestone

### Night 2
First:
`Q19` → `Q21`

Then, only if `Q21` is a real GO:
`Q22` → `Q36`

Aggressive full overnight:
- queue `Q01` → `Q36` in one thread
- rely on the gate rules in `codex_master_overnight_prompt.md`

If you choose aggressive mode, keep everything in one thread.

---

## E. Do You Need The Other Files?

For queueing: no, not manually.

This file plus `codex_master_overnight_prompt.md` is enough for the actual queue workflow.

The other prompt files are still needed locally because each queued task loads its real task body from them.
But you do not need to manually edit or juggle them while queueing.

---

## F. Optional Post-Core Tracks

Use these only after the main `Q01-Q36` queue is stable.

Recommended order:
1. `AQ01-AQ05`
2. `PT01-PT05`
3. `CE01-CE05`
4. `FH01-FH04`

### Audio Track

Use this if you want the temporary audio floor replaced and the old harsh temp music removed cleanly.

#### AQ01

```text
Run AQ01 from `codex_master_queue_runner.md`.

Task source:
- file: `codex_audio_rework_prompt.md`
- part: `Part 1 - Audio Surface Audit + Replacement Plan`

Use the task exactly from that source file, under the wrapper rules from `codex_master_overnight_prompt.md`.
```

#### AQ02

```text
Run AQ02 from `codex_master_queue_runner.md`.

Task source:
- file: `codex_audio_rework_prompt.md`
- part: `Part 2 - Music Floor Replacement`

Use the task exactly from that source file, under the wrapper rules from `codex_master_overnight_prompt.md`.
```

#### AQ03

```text
Run AQ03 from `codex_master_queue_runner.md`.

Task source:
- file: `codex_audio_rework_prompt.md`
- part: `Part 3 - Optional UI / SFX Harshness Cleanup`

Use the task exactly from that source file, under the wrapper rules from `codex_master_overnight_prompt.md`.
```

#### AQ04

```text
Run AQ04 from `codex_master_queue_runner.md`.

Task source:
- file: `codex_audio_rework_prompt.md`
- part: `Part 4 - Old Audio Reference Cleanup + File Deletion`

Use the task exactly from that source file, under the wrapper rules from `codex_master_overnight_prompt.md`.
```

#### AQ05

```text
Run AQ05 from `codex_master_queue_runner.md`.

Task source:
- file: `codex_audio_rework_prompt.md`
- part: `Part 5 - Final Audio Audit + Truth Alignment`

Use the task exactly from that source file, under the wrapper rules from `codex_master_overnight_prompt.md`.
```

### Playtest / Tuning Track

Use this after audio if audio replacement is part of the plan.

#### PT01

```text
Run PT01 from `codex_master_queue_runner.md`.

Task source:
- file: `codex_playtest_tuning_prompts.md`
- part: `Part 1 - Playtest Audit + Tuning Backlog Lock`

Use the task exactly from that source file, under the wrapper rules from `codex_master_overnight_prompt.md`.
```

#### PT02

```text
Run PT02 from `codex_master_queue_runner.md`.

Task source:
- file: `codex_playtest_tuning_prompts.md`
- part: `Part 2 - Readability + UX Tuning Pass`

Use the task exactly from that source file, under the wrapper rules from `codex_master_overnight_prompt.md`.
```

#### PT03

```text
Run PT03 from `codex_master_queue_runner.md`.

Task source:
- file: `codex_playtest_tuning_prompts.md`
- part: `Part 3 - Combat / Economy / Progression Tuning Pass`

Use the task exactly from that source file, under the wrapper rules from `codex_master_overnight_prompt.md`.
```

#### PT04

```text
Run PT04 from `codex_master_queue_runner.md`.

Task source:
- file: `codex_playtest_tuning_prompts.md`
- part: `Part 4 - Run Pacing + Repetition Tuning Pass`

Use the task exactly from that source file, under the wrapper rules from `codex_master_overnight_prompt.md`.
```

#### PT05

```text
Run PT05 from `codex_master_queue_runner.md`.

Task source:
- file: `codex_playtest_tuning_prompts.md`
- part: `Part 5 - Final Playtest Verdict + Tuning Audit`

Use the task exactly from that source file, under the wrapper rules from `codex_master_overnight_prompt.md`.
```

### Content Breadth Track

Use this after the playtest/tuning track so new content answers real gaps.

#### CE01

```text
Run CE01 from `codex_master_queue_runner.md`.

Task source:
- file: `codex_content_expansion_prompts.md`
- part: `Part 1 - Content Surface Audit + Gap Plan`

Use the task exactly from that source file, under the wrapper rules from `codex_master_overnight_prompt.md`.
```

#### CE02

```text
Run CE02 from `codex_master_queue_runner.md`.

Task source:
- file: `codex_content_expansion_prompts.md`
- part: `Part 2 - Event / Roadside / Support Content Pack`

Use the task exactly from that source file, under the wrapper rules from `codex_master_overnight_prompt.md`.
```

#### CE03

```text
Run CE03 from `codex_master_queue_runner.md`.

Task source:
- file: `codex_content_expansion_prompts.md`
- part: `Part 3 - Gear / Reward / Merchant Content Pack`

Use the task exactly from that source file, under the wrapper rules from `codex_master_overnight_prompt.md`.
```

#### CE04

```text
Run CE04 from `codex_master_queue_runner.md`.

Task source:
- file: `codex_content_expansion_prompts.md`
- part: `Part 4 - Enemy / Stage / Side-Mission Breadth Pack`

Use the task exactly from that source file, under the wrapper rules from `codex_master_overnight_prompt.md`.
```

#### CE05

```text
Run CE05 from `codex_master_queue_runner.md`.

Task source:
- file: `codex_content_expansion_prompts.md`
- part: `Part 5 - Final Content Audit + Behavior-Sensitive Review`

Use the task exactly from that source file, under the wrapper rules from `codex_master_overnight_prompt.md`.
```

### Final Hardening Track

Run this last.

#### FH01

```text
Run FH01 from `codex_master_queue_runner.md`.

Task source:
- file: `codex_final_hardening_prompts.md`
- part: `Part 1 - Repo-Wide Hardening Audit`

Use the task exactly from that source file, under the wrapper rules from `codex_master_overnight_prompt.md`.
```

#### FH02

```text
Run FH02 from `codex_master_queue_runner.md`.

Task source:
- file: `codex_final_hardening_prompts.md`
- part: `Part 2 - Docs / Tests / Truth Sync Pass`

Use the task exactly from that source file, under the wrapper rules from `codex_master_overnight_prompt.md`.
```

#### FH03

```text
Run FH03 from `codex_master_queue_runner.md`.

Task source:
- file: `codex_final_hardening_prompts.md`
- part: `Part 3 - Stale File / Asset / Cleanup Pass`

Use the task exactly from that source file, under the wrapper rules from `codex_master_overnight_prompt.md`.
```

#### FH04

```text
Run FH04 from `codex_master_queue_runner.md`.

Task source:
- file: `codex_final_hardening_prompts.md`
- part: `Part 4 - Final End-to-End Audit + Release-Candidate Verdict`

Use the task exactly from that source file, under the wrapper rules from `codex_master_overnight_prompt.md`.
```
