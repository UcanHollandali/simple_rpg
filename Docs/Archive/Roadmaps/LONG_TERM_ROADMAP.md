# SIMPLE RPG — Long-Term Roadmap (2026 Q2 → Q4)

Last regenerated: 2026-04-20.

This file is a planning scratchpad — **not an authority doc**. Gameplay rules still live where `Docs/DOC_PRECEDENCE.md` says they live. Short-horizon execution lives in `Docs/ROADMAP_2026Q2.md` and `Docs/Promts/Q2_Plan/STATUS.md`.

The purpose here is to zoom out: what does the project look like 3–6 ay sonra, and what is the sequence of commitments that get us there?

---

## 1. Where the project is today (2026-04-20, kesin bilgi)

- **Engine / platform**: Godot `4.6.2`, typed GDScript, mobile portrait.
- **Playability**: the repo is described as prototype-playable in `HANDOFF.md`.
- **Save shape**: `save_schema_version = 8`, `content_version = prototype_content_v7`.
- **Runtime owners**: `RunState`, `MapRuntimeState`, `InventoryState`, `SupportInteractionState`, `CombatState`, `RunSessionCoordinator`, `GameFlowManager`, `SaveService`.
- **Content**: JSON under `ContentDefinitions/` (weapons, armors, belts, consumables, passives, enemies, events, rewards, stages, biomes, statuses, boss encounters).
- **Art stage**: first-pass masters (bg/map/combat/menu/choice) live in `SourceArt/Edited/`; approved tree under `Assets/UI/Map/Canopy` and `Assets/UI/Map/Clearings` exists but path-variant assets aren't wired.
- **Audio stage**: `music_ui_hub_loop_proto_01`, `music_combat_loop_proto_01`, `music_run_end_loop_proto_01` are live as the calmer prototype music floor.
- **Validator**: `Tools/validate_architecture_guards.py` (360 lines) enforces hotspot caps + compat rules + several SoT rules.
- **Open structural debt** (tespit edildi):
  - four big-file hotspots at or near cap: `map_runtime_state.gd` (2395/2397), `map_board_composer_v2.gd` (1251/1258), `combat.gd` (1184/1200), `inventory_actions.gd` (1087/1087 — AT cap), `inventory_state.gd` (1060/1060 — AT cap), `run_session_coordinator.gd` (1016/1018), `map_route_binding.gd` (1060), `support_interaction_state.gd` (976/976 — AT cap), `combat_flow.gd` (764/764 — AT cap);
  - `RunState` compat accessors (frozen by D-042, not retired);
  - `NodeResolve` generic-fallback reading drifted from docs (B-2 / D-041);
  - `gate_warden` dead content (31 refs, retiring per D-046);
  - command/event catalog drift (`turn_phase_resolved`, `BossPhaseChanged`);
  - missing A6 maintainability audit artifact;
  - map asset hooks not wired (MAP `Prompt 7`/`Prompt 8` blocked on human-approved filenames).

Varsayım (kesinleştirilmedi): prototype balancing is "legible" in isolated combats and map walks, but full-run playtest signal is not captured as a living dataset.

---

## 2. Stance for the next 3–6 months

Three north-star commitments, in priority order:

1. **Structural soundness before new features.** Hotspots at cap must be drained (big-file extraction) before any new gameplay system lands. One new system on top of a 1087-line `inventory_actions.gd` bricks the validator and invites rollback-class regressions like the one already experienced.
2. **Authority-doc truth stays current.** Every prompt in `Q2_Plan` that updates a doc in the same patch is doing this job. Code landing without a doc patch is treated as drift.
3. **Playtest loop before polish.** A single, cheap, repeatable playtest workflow (run → capture → read → balance-patch) is worth more than another content wave. Polish passes (visual/audio) pay off only once the run loop feels fair on repeated plays.

---

## 3. Phase map

Phases are targets, not promises. Each one names its entry conditions, deliverables, and validator/test baseline.

### Phase A — Q2 Cleanup (2026 Q2; in progress)

Entry condition: already open.
Deliverable: every row in `Docs/Promts/Q2_Plan/STATUS.md` is `applied`.
Validator baseline: `py -3 Tools/validate_architecture_guards.py` + `Tools/run_godot_full_suite.ps1` pass on a clean branch.
Exit criteria:
- Authority docs aligned with code (B-1, B-2, D-041..D-046 all landed).
- Fast-lane debt cleared (W0 + W1).
- Guarded-lane structural drift cleared (W2).
- `map_runtime_state.gd` either extracted (W3-01) or explicitly deferred with an updated validator cap note.

Risk: rollback happened mid-cleanup before; another rollback costs at least one week. Keep commits small and batched per `Q2_Plan/README.md`.

### Phase B — Big-File Extraction (2026 Q2 → early Q3)

Entry condition: Phase A green.
Deliverable: `map_board_composer_v2.gd`, `inventory_actions.gd`, `run_session_coordinator.gd`, `map_route_binding.gd` each below their validator cap with visible headroom, split into well-named helpers, same owner.
Validator baseline: same + per-slice targeted tests + scene isolation for `map_explore`, `combat`.
Exit criteria:
- Every `*-0` preflight is a checked-in file.
- Every `*-1..*-3` extraction leaves the suite green.
- Validator caps updated to the new, lower baselines.

Risk: owner-preserving extraction still produces merge/conflict noise. Prefer a dedicated `codex/extraction-*` branch per hotspot family; merge only when green.

### Phase C — Playtest Instrumentation (2026 Q3)

Entry condition: Phases A + B green. Large files small enough that instrumentation doesn't re-inflate them.
Deliverable: a narrow, deterministic playtest capture pass:
- Run seed, stream-seeds (`map_rng`, `combat_rng`, `reward_rng`) logged at run start.
- Per-encounter outcome (HP/hunger delta, gold delta, duration, used consumables) written to a local JSONL stream.
- A small reader script under `Tools/` (for example `Tools/read_playtest_log.py`) that reduces one JSONL run into a summary line.
- Doc: `Docs/PLAYTEST_CAPTURE.md` describing where the log lives, how to turn capture on, and the summary format.
Validator baseline: same as Phase A, plus a new small test that the log file exists after a smoke run.
Exit criteria:
- Three real runs are captured and their summaries are committed under `Docs/PlaytestData/` (or an equivalent data folder).
- The capture code is behind an explicit `run_capture_enabled` toggle that is off by default.

Risk: balance work without data is narrative. Defer C only at the cost of making D noisy.

### Phase D — Balance Tuning Pass (2026 Q3 → Q4)

Entry condition: Phase C delivered at least three captured runs.
Deliverable: a balance-patch batch that touches definition JSON only (no rules change):
- Enemy HP / attack curves rebalanced against captured run data.
- Consumable drop rates rebalanced against run length.
- Reward pool weights rebalanced against run completion rate.
- `Docs/CONTENT_BALANCE_TRACKER.md` updated with before/after snapshot.
Validator baseline: content validator + full suite.
Exit criteria:
- A 5-to-1 win/loss target (or whatever the designer sets) is reached by the captured run sample.
- Zero rule changes: every patch is data-only per D-013.

Risk: balance is iterative. One pass is one pass; expect two or three.

### Phase E — Visual / Audio Production Wave 1 (2026 Q3)

Entry condition: Phases A + B green (does not block on C/D — can run in parallel with Phase D).
Deliverable: map asset hook wiring (MAP `Prompt 7`, `Prompt 8`), first wave of approved production assets in `Assets/UI/Map/Canopy`, `Assets/UI/Map/Clearings`, `Assets/UI/Map/Paths`, and associated manifest rows in `AssetManifest/asset_manifest.csv`.
Validator baseline: portrait-capture, scene isolation, `Tools/run_portrait_review_capture.ps1`, `Tools/run_godot_scene_isolation.ps1`.
Exit criteria:
- Every map node family renders with an approved asset, not a placeholder.
- License/provenance rows in the manifest filled for every new asset.
- `AI_ASSET_ROADMAP_V2.md` updated with "wave 1 done" note; the file does not claim active work it isn't doing.

Risk: asset licensing drift is a real legal risk. Do not bypass `ASSET_LICENSE_POLICY.md`.

### Phase F — Combat / Support Polish Wave (2026 Q4)

Entry condition: Phase B green; `combat_flow.gd` and `support_interaction_state.gd` have extracted headroom.
Deliverable: a narrow, deliberate set of combat and support polish patches:
- Combat phase transitions readable on a single screen without scroll.
- Support-interaction overlays share density/theme with the rest of the game (done partially via `w2_06`; Phase F finishes residual cases).
- Boss phase transitions spelled out in `COMBAT_RULE_CONTRACT.md` so code + docs read the same.
Validator baseline: flow state tests, combat safe-menu tests, phase2 loop.
Exit criteria:
- One captured boss encounter reads cleanly from start to finish on a portrait screen.

Risk: polish lures scope. Do not let Phase F absorb C/D work that hasn't happened.

### Phase G — Save Migration Hardening (2026 Q4)

Entry condition: Phase A green (compat accessors frozen); Phase B green (save service small enough to audit).
Deliverable: an explicit save-version upgrade path for a single experimental schema change (for example moving a runtime field from one owner to another) exercised end-to-end:
- Dump → upgrade → reload roundtrip test.
- Migration code under `Game/Infrastructure/save_service_legacy_loader.gd` with a clean new/old branching point.
- Migration tested against three historical save samples captured during Phase C.
Validator baseline: save roundtrip tests, legacy loader tests, full suite.
Exit criteria:
- A single real migration (either hamlet split codified, or the zz_prefix exception codified) lands and survives reload.

Risk: this is high-risk work per AGENTS.md. It must be explicitly escalated and planned as its own pass.

---

## 4. Commitment sequencing (short-form)

| Month | Primary commitment | Secondary commitment | Do not start |
|---|---|---|---|
| 2026-04 (Apr) | Phase A — W0 + W1 | Phase A W2-01, W2-02 preflight | Phase B extractions |
| 2026-05 (May) | Phase A — W2 + W3-01 | Phase B — preflights only | Phase C capture code |
| 2026-06 (Jun) | Phase B — MBC + INV extractions | Phase E — map `Prompt 4`, `Prompt 5` audits | Phase D balance patches |
| 2026-07 (Jul) | Phase B — RSC + MRB extractions | Phase C — capture v1 | Phase G migration |
| 2026-08 (Aug) | Phase C — three captured runs | Phase E — asset wave 1 | Phase G |
| 2026-09 (Sep) | Phase D — balance pass 1 | Phase E — asset wave 1 finish | Phase G |
| 2026-10 (Oct) | Phase F — combat polish | Phase D — balance pass 2 | — |
| 2026-11 (Nov) | Phase G — migration dry-run | Phase F — support polish | — |
| 2026-12 (Dec) | Phase G — real migration | retrospective + roadmap refresh | new system introductions |

These are target months, not deadlines. Slippage lands on the next slot; new systems do not preempt cleanup.

---

## 5. Guardrails that stay true through every phase

These are repo-level rules; none should be relaxed without an explicit escalation decision.

- **No gameplay autoload for convenience.** (AGENTS.md non-negotiable.)
- **No gameplay truth in UI.** (D-007.)
- **No new `RunState` compat accessor.** (D-042.)
- **No display text as logic key.** (AGENTS.md non-negotiable.)
- **No widening scope silently.** Every patch states its Speed Mode Contract fields.
- **Every mechanic change updates its closest authority doc in the same patch.**
- **Save-schema shape changes always escalate first.**

---

## 6. Anti-goals (deliberate non-commitments)

To keep scope honest, these are things **not** on the roadmap:

- Multiplayer, networking, or online features.
- Cross-platform parity work (this is mobile portrait; a desktop pass is an explicit future decision).
- A level editor or in-game content authoring.
- A narrative / story arc layer; `GDD.md` keeps story out of Q2/Q3.
- Steam / store integrations.
- Live-service features (events, seasons, rotating content).
- A second map topology; one is enough for the prototype.
- Any rules rewrite driven by a single playtest reaction; rules changes require captured data per Phase C.

If one of these starts creeping in as an "easy add", it is by definition a scope widening and must be escalated, documented, or rejected — not absorbed silently.

---

## 7. How this file stays honest

- When a phase is entered, edit this file to move the phase from "next" to "in progress".
- When a phase exits, strike it through here and capture the delta in `Docs/DECISION_LOG.md` if any non-obvious call was made.
- If reality diverges from the commitment sequence for two months, rewrite the sequencing table rather than pretending it is still true.
- `Docs/ROADMAP_2026Q2.md` stays the short-horizon file. This file stays long-horizon.
- This file is NOT an authority doc; gameplay rules do not live here.
