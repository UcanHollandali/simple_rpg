# Q2 Plan — Codex Prompt Set (rollback-aware)

Last regenerated: 2026-04-20.

Roadmap: `../../ROADMAP_2026Q2.md`.
Backlog anchor: `../../Audit/2026-04-18-patch-backlog.md`.

## How to use

Each file under this folder is a standalone Codex prompt. Every prompt uses the AGENTS.md Speed Mode Contract fields:
- `mode`
- `scope`
- `do not touch`
- `validation budget`
- `doc policy`

The prompts are ordered by batches (see below). Inside one batch you can copy-paste them back-to-back into Codex; across batches you should stop, let Codex finish, then re-read `Docs/HANDOFF.md` before starting the next batch.

## Batch queue

| Batch | File | Lane | Depends on |
|---|---|---|---|
| B0 | `w0_01_recreate_maintainability_audit.md` | Fast | — |
| B1 | `w0_02_handoff_refresh.md` | Fast | B0 |
| B1 | `w0_03_decision_log_q2_entries.md` | Fast | B0 |
| B1 | `w0_04_save_schema_pending_node_drift.md` | Fast | — |
| B1 | `w0_05_catalog_drift_register.md` | Fast | — |
| B1 | `w0_06_extraction_plan_duplicate_cleanup.md` | Fast | — |
| B2 | `w1_01_prune_stale_wrappers.md` | Fast | B1 |
| B2 | `w1_02_inventory_display_helper_extraction.md` | Fast | B1 |
| B2 | `w1_03_texture_loader_consolidation.md` | Fast | B1 |
| B2 | `w1_04_validator_guard_expansion.md` | Fast | B1 |
| B3 | `w1_05_hamlet_phase_split_note.md` | Fast | B1 (needs W0-03) |
| B3 | `w1_06_inventory_cached_getter_exception_note.md` | Fast | B1 (needs W0-03) |
| B3 | `w1_07_zz_prefix_convention_note.md` | Fast | B1 (needs W0-03) |
| B3 | `w1_08_runstate_compat_freeze_note.md` | Fast | B1 (needs W0-03) |
| B3 | `w1_09_gate_warden_retire.md` | Fast | B1 (needs W0-03) |
| B4 | `w2_01_node_resolve_contract_alignment.md` | Guarded | B3 |
| B4 | `w2_02_app_bootstrap_raw_getter_narrowing.md` | Guarded | B3 |
| B4 | `w2_03_application_error_handling_standardization.md` | Guarded | B3 |
| B5 | `w2_04_scene_theme_layout_finish.md` | Guarded | B4 |
| B5 | `w2_05_inventory_panel_traversal_hotspots.md` | Guarded | B4 |
| B5 | `w2_06_portrait_density_constants.md` | Guarded | B4 |
| B5 | `w2_07_scene_router_overlay_hardening.md` | Guarded | B4 |
| B6 | `w3_01_map_runtime_state_extraction.md` | Escalate-first | B5 |
| B7 | `w4_01_accessibility_polish.md` | Fast | B6 |
| B7 | `w4_02_tooling_hygiene.md` | Fast | B6 |

## Reading order for each prompt

Every prompt assumes:
1. You have read `AGENTS.md`, `Docs/DOC_PRECEDENCE.md`, and `Docs/HANDOFF.md`.
2. You have the closest authority doc open for the relevant topic.

If a prompt asks to "apply decision D-0xx", the decision entry is the one introduced by `w0_03_decision_log_q2_entries.md` — run B0+B1 before any prompt in B3 that references it.
