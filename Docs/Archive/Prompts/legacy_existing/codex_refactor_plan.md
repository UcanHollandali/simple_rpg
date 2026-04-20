# Codex Refactor Plan — Değerlendirme + Düzeltilmiş Promptlar

Son güncelleme: 2026-04-15

## Bölüm A — Konuşma Değerlendirmesi

### Doğru Olan Tespitler

1. **Dosya boyutu tespiti doğru.** combat.gd (1838), map_explore.gd (1784), map_runtime_state.gd (1628), combat_flow.gd (1001), save_service.gd (838), run_session_coordinator.gd (777), combat_presenter.gd (713), inventory_actions.gd (788), map_explore_scene_ui.gd (507), app_bootstrap.gd (413). Bunlar gerçek hotspot'lar.

2. **"Spagetti değil ama şişme var" tespiti doğru.** Katmanlama kurulmuş, architecture guard'lar var, doc policy sağlam. Sorun boundary değil, file-level bloat ve wiring yoğunluğu.

3. **Doc politikası doğru.** "Yeni doc açma, mevcut authority docs'a minimal ek yap" yaklaşımı DOC_PRECEDENCE.md ile tam uyumlu.

4. **Sert kurallar (save shape, flow state, owner boundary) doğru.** AGENTS.md non-negotiables ve risk lanes ile birebir örtüşüyor.

5. **Part sıralama mantığı doğru.** Önce stabilize, sonra extract, sonra guard, sonra audit. Bu repo'nun risk lane yapısına uygun.

### Konuşmada Yanlış veya Eksik Olan Şeyler

#### 1. NodeResolve Ölü Kod DEĞİL — Bu Kritik Bir Hata

Konuşma NodeResolve'u "eski bridge, kaldırılmış" gibi ele alıyor. Ama kod gerçeği farklı:

- `scene_router.gd` hâlâ `FlowState.Type.NODE_RESOLVE → "res://scenes/node_resolve.tscn"` mapping'i tutuyor
- `run_session_coordinator.gd` non-combat node tıklamalarında hâlâ `NODE_RESOLVE` state'ine geçiyor
- `game_flow_manager.gd` NODE_RESOLVE'u aktif flow transition olarak tanımlıyor
- `flow_state.gd` enum'da NODE_RESOLVE hâlâ var

**Sadece combat/boss NodeResolve'u atlıyor.** Event, reward ve diğer non-combat node'lar hâlâ NodeResolve üzerinden geçiyor. Bu "çift ekran" hissinin gerçek kaynağı: NodeResolve açılıyor → sonra overlay açılıyor.

HANDOFF.md'de de bu çelişki var:
- Satır 11: "non-combat node interactions render as popup overlays on top of MapExplore"
- Satır 18: "Event (via NodeResolve) | Reward (via NodeResolve)"

Bu iki ifade birbiriyle çelişiyor. Ya overlay sistemi NodeResolve'u tam olarak devre dışı bırakmalıydı (ama bırakmamış), ya da HANDOFF yanlış yazılmış.

**Promptlara etkisi:** Part 0 (overlay cleanup) bunu doğru hedeflemeli. NodeResolve'u "ölü kod sil" olarak değil, "event/reward hattında NodeResolve hâlâ aktif, overlay sistemiyle çakışıyor mu incele" olarak çerçevelemeli.

#### 2. ~~Codex Godot Testlerini Çalıştıramaz~~ — YANLIŞ TESPİT

Codex local'de çalışıyor ve Godot dahil tüm toolchain'e erişimi var. Hem Python validator'ları hem Godot test/smoke scriptlerini çalıştırabiliyor. Promptlardaki tüm validation komutları aynen kalabilir.

#### 3. combat_flow.gd (1001 satır) Hiçbir Promptta Yok

Bu dosya 4. en büyük .gd dosyası. Konuşmada kısaca geçiyor ama hiçbir cleanup/extraction promptuna dahil edilmemiş. Application layer'da orchestration yapıyor ve combat_resolver ile combat_state arasında köprü kuruyor.

#### 4. inventory_actions.gd (788 satır) Hiçbir Promptta Yok

Aynı şekilde büyük bir dosya, hiçbir prompt'ta hedef olarak yer almıyor.

#### 5. Application/Runtime Extraction Fazı Son Versiyonda Düşürülmüş

İlk planda Part 2 olarak "Application / Runtime Guarded Extraction" vardı (run_session_coordinator.gd ve map_runtime_state.gd parçalama). Son versiyonda (Part 0-3) bu faz tamamen kaldırılmış. Yani en büyük blast-radius dosyaları (run_session_coordinator, map_runtime_state) extraction almayacak.

#### 6. Prompt Dili Karışık

Promptlar Türkçe-İngilizce karışık. Repo'nun tüm dokümanları İngilizce. Codex İngilizce promptlarla daha tutarlı çalışır. Promptları tamamen İngilizce yazmak daha güvenli.

#### 7. Geçici Dosya Tespiti Stale

Önceki konuşmadaki "geçici dosyalar zaten temiz" çıkarımı artık doğru değil:

- root'ta `_tmp_map_capture.png` ve `_tmp_map_capture.png.import` hâlâ mevcut
- `Tools/` ve `Tests/` altında `_temp_scatter_*` / `_temp_scatter_probe*` artıkları da hâlâ görünüyor

Bu yüzden cleanup prompt'ları bu kalemi "repo-state'a göre referans audit yap" diye çerçevelemeli; "zaten temiz" varsayımıyla yazılmamalı.

#### 8. safe_menu_overlay.gd (751 satır) Hiç Bahsedilmiyor

Bu dosya UI katmanında ciddi bir hotspot ama hiçbir yerde geçmiyor. Pause menu, settings, save/load UI hepsini tek dosyada topluyor.

#### 9. Part'lar Arası Overlap Fazla

Part 0 (overlay cleanup) ve Part 1 (de-AIification) arasında map_explore.gd üzerinde ciddi çakışma var. Part 1 ve Part 2 (scene/UI extraction) arasında da combat.gd ve map_explore.gd üzerinde overlap var. Bu, Codex'in aynı dosyalarda birden fazla turda benzer işler yapmasına yol açar.

---

## Bölüm B — Ek Tespitlerim (Konuşmada Olmayan)

### 1. HANDOFF.md İç Çelişkisi
Runtime spine "Event (via NodeResolve)" diyor ama overlay sistemi "popup on MapExplore" diyor. Bu çelişki ya kodda ya da dokümanda düzeltilmeli.

### 2. support_interaction_state.gd (568 satır) Büyük Ama Gözden Kaçmış
Side-mission, merchant, rest, blacksmith hepsinin pending state'ini tutuyor. Potansiyel kitchen-sink riski.

### 3. map_board_composer_v2.gd (830 satır) UI Katmanında Büyük
Procedural board layout, world-space positioning, edge/forest rendering. Pure presentation ama çok büyük.

### 4. Duplicate Threshold Riski
`HUNGRY_THRESHOLD`, `STARVING_THRESHOLD` gibi değerler combat_resolver.gd, combat.gd ve combat_presenter.gd'de tekrarlanıyor. Balance değişikliği multi-file edit gerektiriyor.

### 5. Node Family String Literals
`"combat"`, `"boss"`, `"event"` gibi string'ler dosyalar arasında tekrarlanıyor. Constant'lar var ama her yerde kullanılmıyor.

---

## Bölüm C — Düzeltilmiş Codex Promptları

Aşağıdaki promptları sırayla, her biri ayrı bir Codex task olarak at.

---

### Part 0 — Overlay / Resolve / Redundant Screen Cleanup

```
This repo has a UI flow issue where non-combat node interactions may show redundant intermediate screens or overlapping visual shells.

Context:
- HANDOFF.md says the overlay system is live: non-combat nodes (event, reward, support, level_up) should render as popup overlays on top of MapExplore.
- But the runtime spine in HANDOFF.md also says "Event (via NodeResolve) | Reward (via NodeResolve)" — meaning NodeResolve is still an active flow step for these node families.
- Current checked-out `run_session_coordinator.gd` and `HANDOFF.md` indicate combat/boss nodes go directly to Combat, but at least one current test still expects boss traversal to pass through `NODE_RESOLVE`. Audit live repo truth first; do not assume docs/tests are already aligned.
- run_session_coordinator.gd still transitions to NODE_RESOLVE for non-combat nodes.
- scene_router.gd still maps NODE_RESOLVE to scenes/node_resolve.tscn.
- game_flow_manager.gd and flow_state.gd still define NODE_RESOLVE as an active flow state.
- The user reports feeling "one screen opens, then another opens on top" for some interactions.

Goal:
- Audit the NodeResolve → overlay handoff for event/reward/support/level_up paths.
- Determine if NodeResolve is causing a redundant visual step before the overlay opens.
- If NodeResolve is fully redundant for paths that now use overlays, remove the intermediate step so those interactions go directly from MapExplore to the overlay.
- If NodeResolve still serves a purpose (threat read, data setup), clarify that and document it.
- Ensure only one visible UI surface per interaction (no double shell, no stale scrim, no extra transition).
- Fix the HANDOFF.md internal contradiction: runtime spine says "via NodeResolve" but overlay description says "popup on MapExplore."

Read first:
- AGENTS.md
- Docs/DOC_PRECEDENCE.md
- Docs/HANDOFF.md
- Docs/ARCHITECTURE.md
- Docs/SOURCE_OF_TRUTH.md
- Docs/GAME_FLOW_STATE_MACHINE.md
- Docs/TEST_STRATEGY.md

Then examine:
- scenes/node_resolve.gd and scenes/node_resolve.tscn
- scenes/map_explore.gd — especially _move_to_node(), _sync_overlays_with_flow_state(), overlay open/close logic
- Game/Application/run_session_coordinator.gd — how it routes non-combat nodes
- Game/Application/game_flow_manager.gd — NODE_RESOLVE transitions
- Game/Application/flow_state.gd — NODE_RESOLVE enum
- Game/Infrastructure/scene_router.gd — NODE_RESOLVE mapping
- scenes/event.gd, scenes/reward.gd, scenes/support_interaction.gd, scenes/level_up.gd — top_level / overlay detection
- Game/UI/transition_shell_presenter.gd — node resolve text building

Hard rules:
- Do not change save shape or save schema version.
- Do not add new flow states. You may remove NODE_RESOLVE from active flow if it is fully redundant, but only if all paths that used it have been safely rerouted.
- Do not change owner boundaries.
- Do not add new command/event families.
- Do not move gameplay truth into UI.
- If removing NODE_RESOLVE requires migration or breaks save compatibility, stop and say `escalate first`.
- Do not do broad scene routing rewrite — make the minimum safe change.

Baseline validation (run before any patches):
- py -3 Tools/validate_content.py
- py -3 Tools/validate_assets.py
- py -3 Tools/validate_architecture_guards.py
- powershell -NoProfile -ExecutionPolicy Bypass -File Tools/run_godot_full_suite.ps1
- powershell -NoProfile -ExecutionPolicy Bypass -File Tools/run_godot_smoke.ps1
- powershell -NoProfile -ExecutionPolicy Bypass -File Tools/run_godot_scene_isolation.ps1 -ScenePath scenes/map_explore.tscn
- powershell -NoProfile -ExecutionPolicy Bypass -File Tools/run_godot_scene_isolation.ps1 -ScenePath scenes/combat.tscn
Do not start patching until baseline is established.

Before each non-trivial patch:
- State: touched owner layer, authority doc, impact (runtime truth / save shape / flow state / public surface), minimum validation set.

After each patch:
- Run the full validation set above.
- State what behavior was verified and what changed.

Report specifically:
1. Is NodeResolve still needed for any interaction path?
2. Which node families were going through NodeResolve unnecessarily?
3. What overlay/shell/scrim redundancies were found?
4. Which open/close flows were simplified?
5. What HANDOFF.md contradictions were fixed?
6. What still needs manual Godot playtest verification?

Report format:
1. Executive Verdict
2. NodeResolve Audit
3. Overlay Flow Audit
4. Findings Before Patch
5. Applied Patches
6. Validation Results
7. Remaining Visual Flow Risks
8. Intentionally Untouched Areas
9. Doc Alignment
10. Escalation Items
11. Final Verdict

Important:
- This pass eliminates redundant intermediate screens.
- It does not redesign the overlay system.
- It does not add new abstractions.
- Stop when there are no more safe patches to apply.
```

---

### Part 1 — GDScript Stabilization + Code Cleanup

```
This repo has been worked on by multiple AI models of varying quality. This pass stabilizes the codebase before structural refactoring.

Goal:
- Clean low-quality AI patch residue, dead code, stale branches, redundant helpers.
- Reduce repeated wiring/lookup/null-check noise in large files.
- Fix obvious bugs, null-safety issues, and silent failures.
- Do not change mechanics, save shape, flow state, or owner boundaries.
- Do not add new abstractions — reduce code, do not grow it.

Read first:
- AGENTS.md
- Docs/DOC_PRECEDENCE.md
- Docs/HANDOFF.md
- Docs/ARCHITECTURE.md
- Docs/SOURCE_OF_TRUTH.md
- Docs/TECH_BASELINE.md
- Docs/TEST_STRATEGY.md

Target files (in priority order):
1. scenes/combat.gd (1838 lines) — clean dead code, repeated node lookups, stale fallbacks, redundant local variables. Do not touch combat truth or mechanics.
2. scenes/map_explore.gd (1784 lines) — clean repeated get_node_or_null spam, duplicate UI mutation blocks, stale overlay wiring left from previous pass. Do not touch map/save truth.
3. Game/Application/combat_flow.gd (1001 lines) — audit for dead branches, redundant state checks, duplicate resolution paths. Owner stays the same. This file was missed in prior analysis.
4. Game/Application/run_session_coordinator.gd (777 lines) — clean stale branches, redundant local logic, obvious duplication. Owner and orchestration behavior stay the same.
5. Game/Application/inventory_actions.gd (788 lines) — audit for dead code, redundant validation, duplicate paths. This file was missed in prior analysis.
6. Game/UI/combat_presenter.gd (713 lines) — clean duplicate text/view-model helpers. Presentation owner stays intact.
7. Game/UI/map_explore_scene_ui.gd (507 lines) — if it has become a kitchen-sink static utility, clean duplicate or single-use helpers.
8. Game/Application/app_bootstrap.gd (413 lines) — clean stale initialization or redundant delegation. Do not expand public surface.
9. Game/RuntimeState/support_interaction_state.gd (568 lines) — this file handles merchant, rest, blacksmith, AND side-mission pending state all in one place. Audit for kitchen-sink risk: are there duplicate setup patterns, dead branches from feature iterations, or overly defensive AI patches? Clean only what is safe. Do not change owner or pending-state contract.
10. Game/RuntimeState/map_runtime_state.gd (1628 lines) — HIGH RISK. Only dead-code removal and readability cleanup that is provably safe. Do not touch save behavior, serialization shape, or graph truth. If in doubt, do not patch — say `escalate first`.
11. Game/UI/map_board_composer_v2.gd (830 lines) — AUDIT ONLY in this pass. Note whether it has dead code or AI patch residue, but do not extract or restructure. It is pure presentation and large but may be justified by domain complexity. Report findings for future pass.

KNOWN SPECIFIC DUPLICATION (verified by independent audit — fix these):
- `_extract_consumable_use_profile()` exists identically in BOTH combat_flow.gd (~line 869-912) AND run_session_coordinator.gd (~line 737-777) — 44 lines of identical code. Extract to a shared Application-layer utility helper.
- Overlay cleanup functions (`_remove_event_overlay()`, `_remove_support_overlay()`, `_remove_reward_overlay()`, `_remove_level_up_overlay()`) in map_explore.gd are identical except variable name — consolidate into a single generic `_remove_overlay(overlay_ref)` helper.

What to look for:
- Near-duplicate helpers (merge or remove the redundant one)
- One-use wrappers / thin pass-through clutter (inline or remove)
- Stale branches / unreachable code (remove)
- Repeated get_node_or_null / label mutation / button mutation blocks (consolidate — combat.gd has 40+ instances of this pattern)
- Ad-hoc runtime UI creation accumulated in scene scripts (note for next pass, extract only if trivially safe)
- Facade growth beyond documented intent
- Inconsistent typing / naming / null checks
- Repeated fallback logic
- Silent failures where a guard or assertion is safer
- Unnecessary local variables and redundant dictionary shuffling
- Nested conditionals that can be simplified without behavior change
- Duplicate threshold constants across files (note but do not consolidate if it touches multiple owners)
- Node family string literals used instead of constants (note locations)
- AI-generated overly defensive null-check patterns (e.g. checking is_instance_valid + is_queued_for_deletion + null in sequence — consolidate into single validation helper)

Hard rules:
- Do not change save shape or save schema version.
- Do not change flow state.
- Do not add new mechanics.
- Do not change content grammar.
- Do not change owner boundaries.
- Do not expand AppBootstrap public surface.
- Do not expand RunState compatibility accessors.
- If cleanup requires migration, stop and say `escalate first`.
- Do not do broad architecture rewrite.
- Do not write new docs.

Baseline validation (run before any patches):
- py -3 Tools/validate_content.py
- py -3 Tools/validate_assets.py
- py -3 Tools/validate_architecture_guards.py
- powershell -NoProfile -ExecutionPolicy Bypass -File Tools/run_godot_full_suite.ps1
- powershell -NoProfile -ExecutionPolicy Bypass -File Tools/run_godot_smoke.ps1
Do not start patching until baseline is established.

Before each non-trivial patch:
- State: touched owner layer, authority doc, impact (runtime truth / save shape / public surface), minimum validation set.

After each patch:
- Run the full validation set above.
- State what was cleaned, what behavior was preserved, and flag any test result changes.

Report specifically:
1. Which files had low-quality AI patch residue?
2. Which helpers were redundant and removed/merged?
3. Which repeated blocks were consolidated?
4. Which bugs/fragilities were fixed?
5. Which files are still too large and need the next extraction pass?
6. Which areas were intentionally untouched because of high risk?
7. Where are duplicate threshold constants? Where are bare string literals instead of constants?

Report format:
1. Executive Verdict
2. Baseline Validation
3. Hotspot Audit (line counts before/after)
4. Findings Before Patch
5. Applied Patches
6. Validation Results
7. Remaining High-Risk Areas
8. Files Still Too Large
9. Escalation Items
10. Final Verdict

Important:
- Goal is to calm the code down, not redesign it.
- Reduce code quantity and noise.
- Do not add new abstractions to replace removed ones.
- Stop when there are no more safe cleanup patches.
```

---

### Part 2 — Scene/UI Structural Extraction

```
This is the structural extraction pass. Previous passes cleaned dead code and overlay residue. This pass reduces file sizes by extracting only cross-cut/shared presentation logic from scene scripts into Game/UI.

Goal:
- Extract only cross-cut/shared presentation logic from scenes/combat.gd and scenes/map_explore.gd into Game/UI helpers.
- Leave scene-local screen strategy, theming, and layout rework to `codex_ui_rework_prompts.md`.
- Scene files should trend toward pure composition/wiring hubs without doing a full screen-by-screen UI rewrite here.
- Gameplay/save/flow truth must not move into scene or UI layer.
- Do not do broad rewrite — make focused, testable extractions.

Read first:
- AGENTS.md
- Docs/DOC_PRECEDENCE.md  
- Docs/HANDOFF.md
- Docs/ARCHITECTURE.md (especially "UI layer decision" section)
- Docs/SOURCE_OF_TRUTH.md
- Docs/TEST_STRATEGY.md

Then examine:
- scenes/combat.gd — identify only cross-cut/shared extractable blocks, especially inventory card interaction wiring shared with other scenes
- scenes/map_explore.gd — identify only cross-cut/shared extractable blocks, especially generic overlay lifecycle helpers shared across overlay types
- Game/UI/ — understand existing presenters and helpers to know where extractions should land
- Game/UI/safe_menu_overlay.gd (751 lines) — this file was missed in prior analysis. Audit whether it also needs extraction or is at least stable.
- Previous cleanup pass changes

KNOWN SPECIFIC CROSS-FILE DUPLICATION (verified by independent audit — extract these):
1. Inventory card interaction code is copy-pasted between combat.gd and map_explore.gd (~120+ lines): `_refresh_inventory_cards()`, `_connect_inventory_card_interactions()`, `_on_inventory_card_gui_input()` and related drag logic. Extract into a shared Game/UI/inventory_card_interaction_handler.gd (or similar) that both scenes can use.
2. Overlay open/close/tween pattern is repeated 4 times in map_explore.gd (event, reward, support, level_up variants) — ~200+ lines. Extract into a generic overlay lifecycle helper.
3. Theme/styling application, screen-local layout tuning, and height-budget polish in combat.gd are scene-local UI concerns. Audit and note them for `codex_ui_rework_prompts.md` Part 5, but do not extract them here unless a tiny shared helper falls out naturally.
4. MapExplore-local board presentation strategy is also scene-local. Audit and note it for `codex_ui_rework_prompts.md` Part 4, but do not turn this pass into a screen-level rework.

Extraction criteria:
- Extract ONLY if the block is clearly presentation logic, not gameplay truth.
- Prioritize helpers reused by more than one scene or overlay type.
- Extract into existing Game/UI files when they already handle that concern.
- Create new Game/UI files only when no existing file is the right home.
- Keep the scene file as the wiring hub — it still instantiates, connects, and coordinates.
- Each extraction must be independently testable.
- Prefer small, focused extractions over large moves.
- Do NOT extract combat-only theming, height-budget layout strategy, or MapExplore-local layout composition in this pass; those belong to the UI rework track.

Hard rules:
- Do not change save shape or flow state.
- Do not change owner boundaries.
- Do not move gameplay truth into UI.
- Do not create hidden new owners in Game/UI.
- Do not do scene/core boundary rewrite.
- If an extraction risks changing public behavior, stop and say `escalate first`.

Also audit but do not necessarily extract:
- Game/Application/run_session_coordinator.gd (777 lines) — note which orchestration sub-responsibilities could be extracted in a future pass, but do not extract in this pass unless trivially safe.
- Game/RuntimeState/map_runtime_state.gd (1628 lines) — same: note opportunities but do not extract. HIGH RISK.
- Game/UI/map_board_composer_v2.gd (830 lines) — note if it needs splitting but do not touch in this pass.

Baseline validation (run before any patches):
- py -3 Tools/validate_content.py
- py -3 Tools/validate_assets.py
- py -3 Tools/validate_architecture_guards.py
- powershell -NoProfile -ExecutionPolicy Bypass -File Tools/run_godot_full_suite.ps1
- powershell -NoProfile -ExecutionPolicy Bypass -File Tools/run_godot_smoke.ps1
- powershell -NoProfile -ExecutionPolicy Bypass -File Tools/run_godot_scene_isolation.ps1 -ScenePath scenes/map_explore.tscn
- powershell -NoProfile -ExecutionPolicy Bypass -File Tools/run_godot_scene_isolation.ps1 -ScenePath scenes/combat.tscn
Do not start extracting until baseline is established.

Before each extraction:
- State: what is being extracted, from where, to where, touched owner layer, authority doc, impact, minimum validation set.

After each extraction:
- Run the full validation set above.
- State what behavior was preserved, what scene file line count dropped to, and flag any test result changes.

Report format:
1. Executive Verdict
2. Baseline Validation  
3. Extraction Plan (what moves where)
4. Applied Extractions
5. Line Count Before/After per file
6. Validation Results
7. Remaining Scene/UI Bloat
8. Application/Runtime Extraction Opportunities (noted, not applied)
9. Escalation Items
10. Final Verdict

Important:
- This pass reduces scene file sizes through focused presentation extraction.
- It does not redesign the scene/UI architecture.
- It does not touch Application or RuntimeState internal structure.
- Stop when safe extractions are exhausted.
```

---

### Part 3 — Doc/Guard Hardening + AppBootstrap Freeze

```
This is the guard and documentation pass. Previous passes cleaned code and extracted presentation logic. This pass locks down growth patterns and aligns docs.

Goal:
- Add minimum guardrails to AGENTS.md to prevent re-bloat.
- Add narrow architecture guards if needed.
- Rewrite HANDOFF.md to reflect current state after cleanup passes (do not accumulate — rewrite).
- Freeze AppBootstrap growth with explicit guard.
- Do not create new docs. Do not expand existing docs significantly.

Read first:
- AGENTS.md
- Docs/DOC_PRECEDENCE.md
- Docs/HANDOFF.md
- Docs/ARCHITECTURE.md
- Docs/SOURCE_OF_TRUTH.md
- Tools/validate_architecture_guards.py
- Game/Application/app_bootstrap.gd
- Changes from previous passes

Tasks:

1. AGENTS.md guardrail addition — add a short "Maintainability Guardrails" section:
   - Large hotspot files (>500 lines) should prefer extraction-first over additive growth.
   - No new AppBootstrap convenience gameplay methods without explicit escalation.
   - No new RunState compatibility accessors.
   - Scene/UI changes in large files must preserve composition-only intent.
   - Owner-changing cleanup is not fast-lane work.
   - Duplicate threshold constants across owners should be consolidated when the opportunity arises.
   - Node family references should use constants, not bare strings.

2. validate_architecture_guards.py — if useful, add a narrow guard:
   - AppBootstrap method count growth check (warn if public methods exceed current count).
   - Or a file-size warning threshold for known hotspot files.
   - Keep it minimal. Do not turn the guard into a linter.

3. HANDOFF.md rewrite — rewrite (not append) to reflect the repo state after all cleanup passes:
   - Update the runtime spine to reflect NodeResolve changes from Part 0.
   - Remove contradictions.
   - Update open risks.
   - Update next steps.
   - Keep it short — HANDOFF is a snapshot, not a journal.

4. Check if ARCHITECTURE.md or SOURCE_OF_TRUTH.md need any update:
   - Only if owner meaning or boundary interpretation actually changed.
   - If nothing changed, do not touch them.

Hard rules:
- Do not create new docs.
- Do not change save shape or flow state.
- Do not change owner boundaries.
- Do not expand AppBootstrap public surface.
- Do not do broad refactor.

Validation:
- py -3 Tools/validate_content.py
- py -3 Tools/validate_assets.py
- py -3 Tools/validate_architecture_guards.py
- powershell -NoProfile -ExecutionPolicy Bypass -File Tools/run_godot_full_suite.ps1
- powershell -NoProfile -ExecutionPolicy Bypass -File Tools/run_godot_smoke.ps1
- Confirm new guards catch what they should by testing a deliberate violation if possible.

Report format:
1. Executive Verdict
2. AGENTS.md Changes
3. Guard Changes
4. HANDOFF.md Rewrite Summary
5. Authority Doc Changes (if any)
6. Validation Results
7. Remaining Risks
8. Final Verdict
```

---

### Part 4 — Final Review + Audit + Patch Verification

```
This is the final audit pass. All previous cleanup, extraction, and guard passes are complete. This pass independently verifies the results.

Goal:
- Re-verify the repo against its own authority docs.
- Confirm previous passes actually reduced risk and file sizes.
- Catch anything missed or broken.
- Apply only very small, safe final patches if needed.
- Produce an honest assessment — do not assume previous passes succeeded.

Read first:
- AGENTS.md
- Docs/DOC_PRECEDENCE.md
- Docs/HANDOFF.md
- Docs/ARCHITECTURE.md
- Docs/SOURCE_OF_TRUTH.md
- Docs/TEST_STRATEGY.md
- All files changed in previous passes

Do NOT trust previous pass reports. Verify independently by reading the actual code.

Full validation (run at the start and after any patches):
- py -3 Tools/validate_content.py
- py -3 Tools/validate_assets.py
- py -3 Tools/validate_architecture_guards.py
- powershell -NoProfile -ExecutionPolicy Bypass -File Tools/run_godot_full_suite.ps1
- powershell -NoProfile -ExecutionPolicy Bypass -File Tools/run_godot_smoke.ps1
- powershell -NoProfile -ExecutionPolicy Bypass -File Tools/run_godot_scene_isolation.ps1 -ScenePath scenes/map_explore.tscn
- powershell -NoProfile -ExecutionPolicy Bypass -File Tools/run_godot_scene_isolation.ps1 -ScenePath scenes/combat.tscn

Answer these questions with evidence:
1. Is the NodeResolve/overlay contradiction resolved? Is there still a double-screen path?
2. Are docs and runtime spine aligned?
3. Is the Core/Application/RuntimeState/Infrastructure/UI layer separation preserved?
4. Are RunState and AppBootstrap compatibility surfaces still contained?
5. Do scene scripts still avoid owning gameplay/save/flow truth?
6. What are the current line counts for the hotspot files? Did they actually decrease?
7. Is adding a new item/enemy/reward/event still straightforward?
8. Is adding a new mechanic still contract-controlled?
9. Do validators catch the right things at the right layer?
10. Which files still carry owner-boundary risk?
11. Which docs are stale, contradictory, or misplaced?
12. Where does AI/human handover still struggle?
13. Did the previous passes actually reduce blast radius?

If final patches are needed:
- Only safe, small, verifiable patches.
- State: touched owner layer, authority doc, impact, validation set.
- Run validators after each patch.

Report format:
1. Executive Verdict
2. Baseline vs Current (line counts, risk map)
3. Independent Findings
4. Final Patches (if any)
5. Validation Results
6. Remaining Critical Risks
7. NodeResolve/Overlay Status
8. Authority Risk Assessment
9. Doc-Code Alignment
10. Extensibility Review
11. What Is Strong
12. What Is Still Weak
13. Concrete Recommendations (now / soon / later)
14. Godot Tests That Must Be Run Manually
15. Escalation Items
16. Final Verdict

Rules:
- Do not be kind — be accurate.
- Do not score "it works" — score "will it last."
- Do not assume previous passes succeeded — verify.
- If you find something broken, say so clearly.
- If you are not patching something, explain why.
```

---

### Part 5 — Pre-Migration Readiness Check

```
This pass verifies the codebase is ready to receive major gameplay changes. It does NOT implement those changes. It checks that the refactor passes produced a codebase where new mechanics, new content, and schema changes can land safely.

Context:
After this pass, a separate migration prompt series will:
- Change inventory model (shared bag → explicit equipment slots + backpack)
- Change combat model (Brace → Defend/Guard + shield + dual wield)
- Add character perk system (replacing item-based progression)
- Add new node types (Hamlet, Roadside Encounter as distinct from Event)
- Add significant new content (weapons, shields, enemies, events, quests)
- Change save schema version multiple times

This readiness check ensures the ground is solid before that work begins.

Read first:
- AGENTS.md
- Docs/DOC_PRECEDENCE.md
- Docs/HANDOFF.md
- Docs/ARCHITECTURE.md
- Docs/SOURCE_OF_TRUTH.md
- Docs/CONTENT_ARCHITECTURE_SPEC.md
- Docs/SAVE_SCHEMA.md
- Docs/COMBAT_RULE_CONTRACT.md
- Docs/GAME_FLOW_STATE_MACHINE.md
- Docs/SUPPORT_INTERACTION_CONTRACT.md
- Docs/REWARD_LEVELUP_CONTRACT.md

Full validation:
- py -3 Tools/validate_content.py
- py -3 Tools/validate_assets.py
- py -3 Tools/validate_architecture_guards.py
- powershell -NoProfile -ExecutionPolicy Bypass -File Tools/run_godot_full_suite.ps1
- powershell -NoProfile -ExecutionPolicy Bypass -File Tools/run_godot_smoke.ps1

Answer these questions with evidence from actual code, not docs alone:

CONTENT EXTENSIBILITY:
1. How many files must be touched to add a single new weapon to ContentDefinitions/Weapons/ and make it appear in merchant stock? List each file and what change is needed.
2. How many files must be touched to add a single new enemy? List each file.
3. How many files must be touched to add a new event template? List each file.
4. Is validate_content.py catching schema violations for all content families? Test by checking what happens if a required field is missing.
5. Are there any content families where the validator is lenient or missing checks?

MECHANIC EXTENSIBILITY:
6. What would need to change to add a new combat action (e.g., replacing Brace with Defend)? List every file that references ACTION_BRACE or "brace".
7. What would need to change to add a new equipment slot type? List every file that references current slot types.
8. What would need to change to add a new node family (e.g., "hamlet")? List every file that references node families.
9. Are gameplay tunables (thresholds, costs, multipliers) still hardcoded across multiple files, or have they been consolidated? List any remaining scattered constants.

SAVE/LOAD READINESS:
10. Is save_service.gd ready for a schema version bump? Can it handle v5→v6 migration cleanly?
11. Does test_save_file_roundtrip.gd cover all current state owners?
12. Are there any state values that exist in runtime but are not saved?

ARCHITECTURE READINESS:
13. After the refactor passes, are scene files actually smaller? Report current line counts for combat.gd, map_explore.gd, and all files that were refactor targets.
14. Is the shared consumable parser utility (from Part 1) actually shared, or was the duplication left in place?
15. Is the inventory card interaction handler (from Part 2) actually shared, or was the duplication left in place?
16. Are architecture guards still passing? Do they catch what they should?

DOC READINESS:
17. Are all authority docs current and accurate after the refactor passes?
18. Is HANDOFF.md updated to reflect the refactored state?
19. Are there any doc claims that will become false during migration (e.g., "current combat actions: Attack, Brace, Use Item")?

If you find issues:
- For small safe fixes: apply them and validate.
- For pre-migration blockers: list them clearly with `MIGRATION BLOCKER:` prefix.
- For recommendations: list them as `MIGRATION NOTE:` for the migration prompts to consume.

Do NOT start migration work. Do NOT change mechanics. This is an assessment and preparation pass only.

Report format:
1. Executive Verdict (is the codebase ready for migration?)
2. Content Extensibility Findings (with file counts)
3. Mechanic Extensibility Findings (with file lists)
4. Save/Load Readiness
5. Architecture Readiness (line counts, shared utilities status)
6. Doc Readiness
7. Migration Blockers (if any)
8. Migration Notes (recommendations for migration prompts)
9. Pre-Migration Patches Applied (if any)
10. Validation Results
11. Final Verdict: GO / NO-GO for migration

Important:
- Be specific. "Content extensibility is good" is useless. "Adding a weapon requires touching 3 files: X, Y, Z" is useful.
- If the refactor passes left duplication in place, say so.
- If a migration prompt will break something the refactor should have fixed, say so.
```

---

### Part 6 — Post-Migration Grand Audit

This prompt goes into the queue AFTER all migration prompts (codex_migration_prompts.md Part 0-12) are complete.

```
This is the grand final audit after both the refactor series and the full migration series are complete. The codebase has undergone major changes: overlay/resolve cleanup, code stabilization, UI extraction, guard hardening, inventory model migration, combat system rewrite (Brace → Defend/Guard), perk system addition, item taxonomy overhaul, new content packs, and map/node routing changes.

This pass independently verifies everything.

Read first:
- AGENTS.md
- Docs/DOC_PRECEDENCE.md
- Docs/HANDOFF.md
- ALL authority docs in Docs/
- ALL files in Game/Application/, Game/RuntimeState/, Game/Core/, Game/Infrastructure/, Game/UI/
- ALL files in scenes/
- ALL content in ContentDefinitions/
- Tools/validate_*.py

Do NOT trust any previous pass reports. Verify by reading actual code.

Full validation (run at start):
- py -3 Tools/validate_content.py
- py -3 Tools/validate_assets.py
- py -3 Tools/validate_architecture_guards.py
- powershell -NoProfile -ExecutionPolicy Bypass -File Tools/run_godot_full_suite.ps1
- powershell -NoProfile -ExecutionPolicy Bypass -File Tools/run_godot_smoke.ps1
- powershell -NoProfile -ExecutionPolicy Bypass -File Tools/run_godot_scene_isolation.ps1 -ScenePath scenes/map_explore.tscn
- powershell -NoProfile -ExecutionPolicy Bypass -File Tools/run_godot_scene_isolation.ps1 -ScenePath scenes/combat.tscn

Answer ALL of these with evidence:

LEGACY CLEANUP:
1. Search entire repo for: "brace", "Brace", "ACTION_BRACE", "brace_multiplier". Any remaining references?
2. Search for old shared inventory model assumptions: "shared_inventory", old slot type references, old bag model code.
3. Search for stale UI labels, tooltips, button texts referencing removed mechanics.
4. Search for old level-up-gives-items assumptions.
5. Are there orphaned content definitions (JSON files) that reference removed mechanics?

ARCHITECTURE INTEGRITY:
6. Is Core/Application/RuntimeState/Infrastructure/UI layer separation still intact?
7. Do scene scripts own any gameplay truth? (Check for RunState writes in scenes/)
8. Has AppBootstrap grown beyond facade-only? Count public methods.
9. Are RunState compatibility accessors still contained, or did migration expand them?
10. Are architecture guards still catching violations? Test with a deliberate violation if possible.

OWNERSHIP ACCURACY:
11. Does SOURCE_OF_TRUTH.md match the actual implemented owners after migration?
12. Does the new equipment slot model have a single clear owner?
13. Does the perk system have a single clear owner?
14. Does the Guard combat state have a clear owner?
15. Are there any "two files both think they own X" situations?

SAVE/LOAD INTEGRITY:
16. What is the current save_schema_version?
17. Can a fresh save roundtrip cleanly? (Run test_save_file_roundtrip.gd)
18. Can a v5 save (pre-migration) load in the current code? Is migration handled?
19. Are all new state values (perks, guard, equipment slots, quest items) included in save?

CONTENT INTEGRITY:
20. Does validate_content.py pass for ALL content families including new ones?
21. Are new content families (shields, shield attachments, perks, hamlet quests, roadside encounters) properly validated?
22. Is the acquisition matrix documented and does it match implementation?

DOC ACCURACY:
23. Is every authority doc current? Check each one against code.
24. Are there stale docs that should be updated or retired?
25. Is HANDOFF.md current?
26. Is COMBAT_RULE_CONTRACT.md accurate for the new Defend/Guard system?
27. Is CONTENT_ARCHITECTURE_SPEC.md accurate for the new item taxonomy?

GAMEPLAY COHERENCE:
28. Does a full run (Stage 1 → Stage 3 boss) make logical sense with the new systems?
29. Are defend/guard/shield mechanics reachable and functional?
30. Can the player actually acquire and use all new item types?
31. Do hamlet quests work end-to-end?
32. Do roadside encounters trigger correctly?

If final patches are needed:
- Only safe, small, verifiable patches.
- State: touched owner layer, authority doc, impact, validation set.
- Run validators after each patch.

Report format:
1. Executive Verdict
2. Validation Results (all commands)
3. Legacy Cleanup Status (with grep evidence)
4. Architecture Integrity
5. Ownership Accuracy (SOURCE_OF_TRUTH vs code)
6. Save/Load Integrity
7. Content Integrity
8. Doc Accuracy (per doc)
9. Gameplay Coherence
10. File Size Report (all hotspot files, before/after comparison if data available)
11. What Is Strong
12. What Is Weak
13. Remaining Stale References
14. Missing Tests or Validators
15. Concrete Recommendations (now / soon / later)
16. Escalation Items
17. Final Verdict

Rules:
- Do not be kind — be accurate.
- Do not say "migration was successful" without evidence.
- If something is broken, say exactly what and where.
- If docs and code disagree, say which one is wrong.
- Score on "will this survive the next 6 months of development" not "does it run today."
```

---

## Bölüm D — Kullanım Sırası (Bu Dosyanın Yerel Sırası)

```
BU DOSYANIN KENDİ İÇ SIRASI:
Part 0  →  Part 1  →  Part 2  →  Part 3  →  Part 4  →  Part 5
overlay    stabilize   shared     guard       audit       pre-migration
cleanup    code        extraction + docs      + verify    readiness

                              ↓ Part 5 GO verse ↓

BÜTÜN DİĞER AKTİF TRACK'LER (UI / map redesign / migration) BİTTİKTEN SONRA:
Part 6
post-everything grand audit
```

Bu dosya tek başına global queue değildir. Global çok-track sıra için `codex_master_queue_plan.md` kullan.

Kısa global özet:
1. Refactor Part 0-2
2. UI Rework Part 1-3
3. Map Redesign Part 1-8
4. UI Rework Part 4-7
5. Refactor Part 3-5 (GO / NO-GO)
6. Migration Part 0-12
7. UI Rework Part 8
8. Refactor Part 6

Codex local'de çalışıyor ve hem Python validator'ları hem Godot testlerini çalıştırabiliyor — her prompt kendi baseline validation'ını çalıştıracak.

Kritik kontrol noktaları (buralarda queue'yu durdurup kontrol et):
1. Refactor Part 4 sonrası: Refactor gerçekten işe yaradı mı? Satır sayıları düştü mü?
2. Refactor Part 5 sonrası: GO / NO-GO kararı. NO-GO varsa migration'a geçme.
3. Migration Part 2 sonrası: Save schema değişti. Save roundtrip çalışıyor mu?
4. Migration Part 3 sonrası: Combat tamamen değişti. Oynanabilir mi?
5. Migration Part 12 sonrası: Migration cleanup temiz mi?
6. Refactor Part 6 sonrası: Her şey tutarlı mı? Grand final audit temiz mi?

## Bölüm E — Konuşmadaki Promptlardan Farklı Ne Yaptım

| Değişiklik | Neden |
|---|---|
| NodeResolve'u "ölü kod" değil "aktif ama potansiyel olarak gereksiz flow step" olarak çerçeveledim | Kod incelemesi NodeResolve'un hâlâ aktif olduğunu gösterdi |
| ~~Godot test komutlarını "list for manual run" olarak değiştirdim~~ — Codex local'de çalışıyor, Godot dahil her şeyi çalıştırabiliyor. Tam validation komutları geri konuldu. | İlk varsayım yanlıştı, düzeltildi |
| combat_flow.gd (1001 satır) ve inventory_actions.gd (788 satır) eklendi | Konuşmada tamamen atlanmış büyük dosyalar |
| safe_menu_overlay.gd (751 satır) eklendi | Konuşmada hiç bahsedilmeyen UI hotspot |
| Application/Runtime extraction'ı Part 2'ye not olarak eklendi | Son versiyonda tamamen düşürülmüştü |
| Promptlar tamamen İngilizce | Repo dokümanları İngilizce, Codex İngilizce ile daha tutarlı |
| Part overlap azaltıldı | Her part'ın net bir odağı var, dosya çakışması minimize edildi |
| HANDOFF.md iç çelişkisi açıkça hedeflendi | Konuşmada fark edilmemiş bir sorun |
| Geçici dosya kalemi "repo-state'a göre audit et" diye düzeltildi | `_tmp_map_capture.png` ve `_temp_scatter_*` artıkları canlı repoda hâlâ görünüyor |
| Duplicate threshold ve string literal riskleri eklendi | Konuşmada kısaca geçip promptlara girmemişti |
| map_board_composer_v2.gd (830 satır) not olarak eklendi | Konuşmada tamamen atlanmış |
| support_interaction_state.gd (568 satır) Part 1'e audit hedefi olarak eklendi | Konuşmada atlanmış, merchant+rest+blacksmith+side_mission hepsini tek dosyada tutuyor |
| Spesifik duplication'lar (consumable parser 44 satır, inventory card 120+ satır, overlay lifecycle 200+ satır) satır numarasıyla eklendi | Konuşma genel "şişme" diyordu, şimdi somut hedefler var |
| Part 5: Pre-Migration Readiness Check eklendi | Migration öncesi GO/NO-GO gate'i — refactor'ın gerçekten işe yaradığını doğrular |
| Part 6: Post-Everything Grand Audit eklendi | Tüm migration bitince bağımsız final doğrulama — legacy kalıntı grep'i, ownership doğrulama, save roundtrip |
| Bu dosyanın yerel sırası ile global multi-track sıranın ayrımı netleştirildi | UI/map/migration track'leri ayrı prompt dosyaları olduğundan global queue artık `codex_master_queue_plan.md` üzerinden okunmalı |
| Kritik kontrol noktaları eklendi | Part 5 GO/NO-GO, M-Part 2 save check, M-Part 3 combat check gibi duraklar |
