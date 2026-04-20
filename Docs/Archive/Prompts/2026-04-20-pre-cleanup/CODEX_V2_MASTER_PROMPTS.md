# CODEX V2 MASTER PROMPTS

Purpose: one practical copy-paste file for the current V2 maintenance pass.
Audience: the user starting fresh Codex chats and wanting small, single-step prompts without jumping between multiple backlog docs.
Scope: follow-up audit/doc/tooling passes first, then UI/app cleanup, then hotspot reports, with big-file micro-refactors deferred to a later master file.

Active files for this pass:
1. `Docs/Promts/CODEX_V2_MASTER_PROMPTS.md`
2. `Docs/Promts/CODEX_V2_BIG_FILE_MASTER_PROMPTS.md`

> **Pass ordering:** The map redesign pass in `Docs/Promts/MAP_MASTER_PROMPTS.md` is the primary active pass. Do NOT start this V2 maintenance pass until the map pass is closed (through Prompt `8`) or explicitly paused. Several prompts here touch files that the map pass is also editing (e.g. `map_board_composer_v2.gd` preflight, scene/UI helpers); running both in parallel will cause churn.

## 0. Reading This File

Every prompt body below begins with `ROL: (genel kural özeti)` as a shorthand. When you paste a prompt into Codex, REPLACE that shorthand line with this block so Codex has the workflow context:

```text
ROL: simple_rpg repo'sunda çalışan AI kod ajanısın. AGENTS.md + Docs/DOC_PRECEDENCE.md + Docs/HANDOFF.md kuralları bağlayıcı. Değişmeden önce ilgili otorite doc'u oku. High-risk escalate-first dosyalara (map_runtime_state.gd, inventory_state.gd, support_interaction_state.gd, save_service.gd, run_state.gd) explicit escalate olmadan dokunma. Save-shape, flow state, owner move, autoload, command/event family genişletmesi escalate-first lane'de. Küçük, yerel, tek amaçlı patch tercih et.
```

If a prompt body already includes a more specific ROL line or extra constraints, keep those on top of this baseline.

---

## 1. Quick Order

If you only want the practical run order, use this:

1. Prompt `0.1`
2. Prompt `1.1`
3. Prompt `1.2`
4. Prompt `1.6`
5. checkpoint commit for doc/tooling work
6. Prompt `1.3`
7. Prompt `1.4`
8. Prompt `2.4`
9. Prompt `2.3`
10. Prompt `2.5`
11. checkpoint commit for UI work
12. Prompt `2.1`
13. Prompt `2.2`
14. Prompt `2.6`
15. checkpoint commit for application work
16. Prompt `3.1`
17. Prompt `3.2`
18. optional on a clean baseline: Prompt `1.5`
19. optional polish: Prompt `5.1`
20. optional polish: Prompt `5.2`
21. only after this file is stable, switch to `Docs/Promts/CODEX_V2_BIG_FILE_MASTER_PROMPTS.md`

Manual mode recommendation:
- open a fresh chat for each prompt
- paste only one prompt block at a time
- if a prompt reports blocker, unsafe, unstable, failed validation, or stop, do not continue the chain

---

## 2. The Clean Order

Use this order:

1. Prompt `0.1` - maintainability audit artifact
2. Prompt `1.1` - SAVE_SCHEMA doc drift
3. Prompt `1.2` - command/event catalog drift
4. Prompt `1.6` - architecture guard expansion
5. checkpoint commit for doc/tooling-only work
6. Prompt `1.3` - inventory display-name helper extraction
7. Prompt `1.4` - texture loader consolidation
8. Prompt `2.4` - inventory panel traversal hotspot
9. Prompt `2.3` - scene theme/layout consolidation
10. Prompt `2.5` - portrait constants/accessibility floor
11. checkpoint commit for UI slice
12. Prompt `2.1` - narrow scene -> AppBootstrap dependency
13. Prompt `2.2` - invalid-state handling consistency
14. Prompt `2.6` - SceneRouter overlay contract hardening
15. checkpoint commit for application slice
16. Prompt `3.1` - map_board_composer_v2 preflight report
17. Prompt `3.2` - inventory_actions + support_interaction_state deep audit
18. optional on a clean baseline: Prompt `1.5`
19. optional polish: Prompt `5.1`, then `5.2`
20. much later, separate chat/file: `Docs/Promts/CODEX_V2_BIG_FILE_MASTER_PROMPTS.md`

Rule:
- safest manual mode: one prompt per fresh chat
- report-only prompts do not need a commit if they did not change repo files
- do not mix UI prompts with application prompts in the same queue batch
- do not start the big-file refactor chain until this follow-up pass is stable

---

## 3. Queue Mode

If you want queue execution in the same chat, use narrow batches instead of dropping the whole chain at once.

Guard line to place before every queued prompt after the first:

```text
Before doing anything, run `git status --short` and read the previous assistant message in this chat. If the repo has unrelated dirty changes outside this prompt's scope, or if the previous step says blocker, unsafe, unstable, failed validation, or stop, do not continue the planned work. Only report that you are halting because the chain did not close cleanly.
```

Queue batch plan:

1. Batch `1`
   - Prompt `0.1`
2. Batch `2`
   - Prompt `1.1`
   - guard line
   - Prompt `1.2`
   - guard line
   - Prompt `1.6`
3. Batch `3`
   - Prompt `1.3`
4. Batch `4`
   - Prompt `1.4`
5. Batch `5`
   - Prompt `2.4`
6. Batch `6`
   - Prompt `2.3`
   - guard line
   - Prompt `2.5`
7. Batch `7`
   - Prompt `2.1`
8. Batch `8`
   - Prompt `2.2`
   - guard line
   - Prompt `2.6`
9. Batch `9`
   - Prompt `3.1`
   - guard line
   - Prompt `3.2`
10. Optional clean-baseline batch
   - Prompt `1.5`
   - guard line
   - Prompt `5.1`
   - guard line
   - Prompt `5.2`

Do NOT queue `1.3 -> 2.6` in one shot.

---

## 4. Current Guardrails

- these prompts assume either a clean worktree or explicit scope isolation
- high-risk owner files stay out unless the prompt explicitly says escalate-first and you have decided to do that
- if a prompt proposes touching files already dirty for unrelated reasons, stop and split the work first

---

## Prompt 0.1 — A6 Maintainability Audit (REPORT-ONLY)

```text
ROL: (genel kural özeti)
KURAL: REPORT-ONLY. Kod DEĞİŞTİRME.

REFERANS:
- B1 backlog = Docs/Audit/2026-04-18-patch-backlog.md
- Tamamlanmış audit'ler: Docs/Audit/2026-04-18-{runtimestate,application,scene,ui,architecture}-audit.md

GÖREV:
Eksik kalan maintainability audit'ini üret:
Docs/Audit/2026-04-18-maintainability-audit.md

KAPSAM:
- Game/ + scenes/ tüm .gd dosyaları
- Tools/ Python script'leri
- Tests/ test yüzeyi

TARAMA KRİTERLERİ:

1) File Size Hotspot
   - Her .gd dosyasının satır sayısını current worktree üzerinden yeniden ölç.
   - 500+ olanları liste; HANDOFF extraction-first guard listesiyle karşılaştır.
   - Liste DIŞINDA olup 500+ olan YENİ dosyaları ayrı işaretle.
   - 2026-04-19 tarihli önceki referans notunda şu dosyalar büyük görünüyordu:
     map_runtime_state.gd, map_board_composer_v2.gd, combat.gd,
     inventory_actions.gd, inventory_state.gd, run_session_coordinator.gd,
     map_route_binding.gd, support_interaction_state.gd, map_explore.gd.
     Sabit satır sayılarını canlı gerçek gibi kullanma; yeniden ölç.

2) Function Length
   - 80+ satırlık fonksiyonları liste (dosya:fn_adı:satır_sayısı).
   - B1 raporu MAINT-F2 = 28 fonksiyon dedi; doğrula veya güncelle.

3) Cyclomatic Complexity Kaba Tahmini
   - 3+ seviye iç içe kontrol akışı olan en karmaşık 10 fonksiyonu listele.
   - Özellikle: map_board_composer_v2, save_service, support_action_application_policy.

4) Naming Tutarlılığı
   - snake_case ihlalleri.
   - Legacy naming (side_mission_, node_resolve, brace) durumu.
   - "stable ID/save key zorunluluğu" mu yoksa rename adayı mı sınıflandır.

5) Comment Health
   - TODO / FIXME / HACK / XXX listesi.
   - "Deprecated" yorumu olup hâlâ çağrılan fonksiyonlar.
   - Stale compatibility comment'leri (run_state.gd, save_service.gd, flow_state.gd).

6) Test Coverage Gap
   - Game/Core/ ve Game/Application/ public fonksiyonlarından Tests/ altında
     hiç referansı olmayanlar.
   - Smoke-only coverage ile birim testi olmayan fark.

7) Duplicate Code Block
   - 5+ satır birebir tekrar; özellikle _hash_seed_string, deep-copy loop'ları,
     inventory-family mapping, policy branch'leri.

8) Dead Code
   - 0 caller'lı public fonksiyon (Tests/ ve validate hariç).
   - Özellikle: game_flow_manager.gd, playtest_logger.gd, save_service.gd,
     map_runtime_state.gd, Game/UI/* için dikkatli tara.

9) Tool/Script Sağlığı
   - Tools/validate_content.py büyük mü, bölünebilir mi?
   - Tools/run_godot_*.ps1 runner'larında log/çıktı path tutarlılığı.

RAPOR ŞABLONU:
Docs/Audit/ ortak şablon (Findings: Critical/Major/Minor/Info, Patch
Candidates tablosu, Open Questions, Not Changed bölümleri).

ÇIKTI: Docs/Audit/2026-04-18-maintainability-audit.md

DOKUNMA: Hiçbir kod dosyasına YAZI YOK.

BAŞARI:
- Rapor var.
- B-1 blocker (B1 backlog) çözülmüş sayılır.
- Top Offenders tablosu var.
- py -3 Tools/validate_architecture_guards.py PASS.
```

---

## Prompt 1.1 — SAVE_SCHEMA pending-node ownership doc düzeltmesi (B1: P-01)

```text
ROL: (genel kural özeti)
KURAL: Fast lane. SADECE doc düzeltmesi. Kod DOKUNMA.

GÖREV:
B1 audit raporu (RS-F1) tespit etti:
- Docs/SAVE_SCHEMA.md "MapRuntimeState save payload pending_node_id ve
  pending_node_type içerir" diyor.
- Gerçekte runtime save bu alanları YAZMIYOR.
- Pending-node continuity şu an RunSessionCoordinator.get_app_state_save_data()
  içinde, app_state altında.
- SaveService run_state_data içinde bu alanları REDDEDİYOR
  (unexpected_pending_node_id / unexpected_pending_node_type).

Docs/SAVE_SCHEMA.md'yi gerçek owner'ı yansıtacak şekilde güncelle:
- pending_node_id / pending_node_type alanlarını "MapRuntimeState save payload"
  bölümünden ÇIKAR.
- "RunSessionCoordinator.app_state" bölümüne ekle (yoksa oluştur).
- SAVE_SCHEMA versiyon bumb'ı YAPMA — sadece doc drift düzeltmesi.

DOĞRULAMA:
- py -3 Tools/validate_architecture_guards.py PASS.
- Save roundtrip testleri ETKİLENMEMELİ (kod değişmediği için).

DOKUNMA:
- Save kodu, save_service, run_session_coordinator, map_runtime_state YOK.
- save_schema_version sayısı YOK.

BAŞARI:
- SAVE_SCHEMA.md gerçek runtime save shape'ini yansıtıyor.
```

---

## Prompt 1.2 — COMMAND_EVENT_CATALOG drift düzeltmesi (B1: P-02)

```text
ROL: (genel kural özeti)
KURAL: Fast lane. Sadece doc düzeltmesi.

GÖREV:
B1 audit raporu (APP-F3, ARCH-F5) tespit etti: combat_flow.gd canlı command/
event yüzeyleri COMMAND_EVENT_CATALOG.md ile drift halinde.

ADIMLAR:
1. Game/Application/combat_flow.gd içindeki tüm command emit / event
   publish noktalarını listele.
2. Docs/COMMAND_EVENT_CATALOG.md'deki listeyle karşılaştır.
3. Eksik isimleri ekle, var olmayanları işaretle veya kaldır.
4. Her ekleme için "producer file" sütununa combat_flow.gd ekle.

DOKUNMA:
- combat_flow.gd kod tarafına YOK.
- Yeni command/event family OLUŞTURMA.

BAŞARI:
- Catalog combat_flow ile birebir tutarlı.
- py -3 Tools/validate_architecture_guards.py PASS.
```

---

## Prompt 1.6 — Architecture guard genişletme (B1: P-06)

```text
ROL: (genel kural özeti)
KURAL: Fast lane (tooling). Yeni guard ekleme; mevcutları ZAYIFLATMA.

GÖREV:
B1 audit raporu (ARCH-F6, APP-F3, MAINT-F8): validate_architecture_guards.py
şu drift'lere karşı koruma EKLEMESİ:

EKLENECEK CHECK'LER:
1. Catalog drift: COMMAND_EVENT_CATALOG.md ile combat_flow.gd / app_bootstrap.gd
   command emit isimleri eşleşmiyorsa FAIL.
2. Stale wrapper regression: Daha önce silinmiş bilinen dead pattern'lar
   (örn. dispatch(), transition_to varsa) tekrar eklenirse FAIL.
3. AppBootstrap facade growth: app_bootstrap.gd'ye yeni public gameplay
   convenience method eklenirse uyarı (FAIL değil, INFO).

ADIMLAR:
1. Mevcut Tools/validate_architecture_guards.py kontrollerini oku.
2. Yeni check'leri AYRI fonksiyonlar olarak ekle.
3. Her check için açıklayıcı hata mesajı.
4. Self-test: doğru durumda PASS, kasıtlı bozuk dosya simülasyonunda FAIL.

DOĞRULAMA:
- py -3 Tools/validate_architecture_guards.py PASS.
- Yeni check'lerin kasıtlı kırılma testlerini commit MESAJINA ekle (kod
  olarak değil, kanıt olarak).

DOKUNMA:
- Mevcut check'leri zayıflatma.
- Yeni autoload eklemekten KAÇIN.

BAŞARI:
- 3 yeni check live.
- Mevcut testler aynen PASS.
```

---

## Prompt 1.3 — Inventory display-name/family mapping helper extraction (B1: P-03)

```text
ROL: (genel kural özeti)
KURAL: Fast lane. Pure extraction; davranış değişikliği YOK.

GÖREV:
B1 audit raporu (UI-F2, MAINT-F7): event_presenter.gd ve reward_presenter.gd
inventory display-name/family mapping logic'i tekrar ediyor.

ADIMLAR:
1. Game/UI/event_presenter.gd ve Game/UI/reward_presenter.gd içindeki
   inventory display-name/family mapping fonksiyonlarını birebir karşılaştır.
2. Birebir aynı kısmı Game/UI/inventory_display_helper.gd (yeni dosya) altına
   taşı.
3. İki presenter da yeni helper'ı çağırsın.
4. Çağrı imzası ve dönüş şekli AYNI kalsın.

DOĞRULAMA:
- py -3 Tools/validate_architecture_guards.py
- powershell -File Tools/run_godot_tests.ps1 test_event_node.gd test_reward_node.gd
- powershell -File Tools/run_godot_full_suite.ps1

DOKUNMA:
- Inventory item definition shape'i YOK.
- RuntimeState'e YOK.

BAŞARI:
- Iki presenter da helper'a delegate ediyor.
- Tüm testler PASS.
```

---

## Prompt 1.4 — Texture loader helper konsolidasyonu (B1: P-04)

```text
ROL: (genel kural özeti)
KURAL: Fast lane. Davranış aynı; tek loader policy.

GÖREV:
B1 audit raporu (UI-F3): inventory_card_factory.gd, map_board_canvas.gd,
scene_layout_helper.gd üç farklı texture loader logic'i kullanıyor.

ADIMLAR:
1. Üç dosyadaki texture loading fonksiyonlarını birebir karşılaştır.
2. Tek bir helper (örn. Game/UI/texture_loader.gd) altında konsolide et.
3. Üç çağıran da bu helper'a delegate etsin.
4. Fallback davranışı (dosya yok ise) korunmalı.

DOĞRULAMA:
- py -3 Tools/validate_architecture_guards.py
- powershell -File Tools/run_godot_scene_isolation.ps1 -ScenePath scenes/map_explore.tscn
- powershell -File Tools/run_godot_full_suite.ps1

DOKUNMA:
- Asset path constants YOK.
- Yeni asset eklemek YOK.

BAŞARI:
- Tek loader policy.
- Three call sites delegate ediyor.
- Tüm testler PASS.
```

---

## Prompt 2.4 — Inventory panel post-render traversal hotspot kaldır (B1: P-13)

```text
ROL: (genel kural özeti)
KURAL: Guarded lane. CODEX_POLISH_PROMPTS Faz 4.2 cache pass'ini tamamladı,
bu kart-child traversal'ını çözüyor.

GÖREV:
B1 audit raporu (SCN-F4, SCN-F5): Game/UI/run_inventory_panel.gd ve
inventory_card_factory.gd post-render'da kart-child traversal yapıyor.
combat.gd ve map_explore.gd bu kalıbı kullanıyor.

ADIMLAR:
1. Post-render traversal yapan call site'ları tespit et.
2. Kart shell yapısına explicit handle ekle (örn. card.icon_node, card.name_node).
3. get_node_or_null çağrılarını handle erişimine çevir.
4. Combat.gd get_node_or_null sayısının 13'e çıktığı tespit edildi
   (önceki tur 6'ydı). Regresyon kaynağı bu hotspot olabilir; düzeltirken
   sayıyı 8 altına indir.

DOĞRULAMA:
- py -3 Tools/validate_architecture_guards.py
- powershell -File Tools/run_godot_tests.ps1
  test_inventory_card_interaction_handler.gd test_button_tour.gd test_phase2_loop.gd
- powershell -File Tools/run_godot_scene_isolation.ps1 -ScenePath scenes/map_explore.tscn
- powershell -File Tools/run_godot_scene_isolation.ps1 -ScenePath scenes/combat.tscn
- powershell -File Tools/run_godot_full_suite.ps1

DOKUNMA:
- InventoryState YOK.
- Inventory item shape YOK.

BAŞARI:
- combat.gd get_node_or_null sayısı <= 8.
- map_explore.gd kart traversal kalıbı handle-based.
- Tüm testler PASS.
```

---

## Prompt 2.3 — Scene tema/layout konsolidasyon kalan drift'i (B1: P-12)

```text
ROL: (genel kural özeti)
KURAL: Guarded lane. CODEX_POLISH_PROMPTS Faz 2.1/2.2 kısmen kapatmıştı,
bu kalanı tamamlıyor.

GÖREV:
B1 audit raporu (SCN-F3, UI-F4, UI-F5): 11 scene'de _apply_portrait_safe_layout
ve _apply_temp_theme hâlâ kendi body'leri ile drift halinde.

ADIMLAR:
1. 11 scene'in mevcut body'leri ile Game/UI/scene_layout_helper.gd ve
   Game/UI/temp_screen_theme.gd'deki helper imzalarını karşılaştır.
2. Hangi scene'ler helper'a delegate olmuş, hangileri kendi body'sini koruyor
   tablo çıkar.
3. Drift olanları helper'a delegate et; helper'da eksik özellik varsa
   helper'a YENI parametre EKLEYEREK çöz (kod kopyalama YOK).
4. Helper'a eklenen her parametre default değerli olsun (geri uyumlu).

DOĞRULAMA:
- py -3 Tools/validate_architecture_guards.py
- powershell -File Tools/run_portrait_review_capture.ps1 (varsa)
- powershell -File Tools/run_godot_scene_isolation.ps1 -ScenePath scenes/map_explore.tscn
- powershell -File Tools/run_godot_scene_isolation.ps1 -ScenePath scenes/combat.tscn
- powershell -File Tools/run_godot_full_suite.ps1

DOKUNMA:
- Theme resource shape YOK.
- Yeni autoload YOK.

BAŞARI:
- 11 scene helper'a delegate.
- Visual regression yok (portrait capture'da diff minimum).
```

---

## Prompt 2.5 — Portrait density/theme/accessibility floor merkezi (B1: P-14)

```text
ROL: (genel kural özeti)
KURAL: Guarded lane. UI consistency + accessibility.

GÖREV:
B1 audit raporu (UI-F4, UI-F5, UI-F6, UI-F7): combat_scene_ui,
map_explore_scene_ui, safe_menu_overlay, temp_screen_theme,
inventory_card_factory, run_status_strip portrait density ve tap-target
floor'ları farklı.

ADIMLAR:
1. Mobil tap target minimum: 44dp (~88px).
2. Compact font minimum: 16pt eşdeğeri.
3. Ortak constants dosyası: Game/UI/portrait_layout_constants.gd (yeni).
4. 6 dosyada hard-coded değerleri bu constants'a delegate et.
5. Accessibility: contrast / state-icon dual signal kontrolü; sadece
   color'a bağımlı feedback varsa not düş.

DOĞRULAMA:
- py -3 Tools/validate_architecture_guards.py
- powershell -File Tools/run_portrait_review_capture.ps1 (varsa)
- powershell -File Tools/run_godot_scene_isolation.ps1 (combat + map_explore)
- powershell -File Tools/run_godot_full_suite.ps1

DOKUNMA:
- Combat/map gameplay logic YOK.
- Theme resource shape YOK.

BAŞARI:
- portrait_layout_constants.gd live.
- 6 dosya delegate ediyor.
- Accessibility floor final response'ta kısa not olarak raporlanmış.
```

---

## Prompt 2.1 — Scene'lerin AppBootstrap'a doğrudan bağımlılığını daralt (B1: P-10)

```text
ROL: (genel kural özeti)
KURAL: Guarded lane. AppBootstrap GAMEPLAY method eklemek YOK; AZALTACAĞIZ.

GÖREV:
B1 audit raporu (APP-F2, ARCH-F2): scenes/* AppBootstrap raw getter'larına
sıkı bağlı. Bu bağımlılığı dar bir interface arkasına al.

ADIMLAR:
1. scenes/*.gd içindeki AppBootstrap.* erişimlerini grup grup listele
   (örn. RunState okuma, MapRuntimeState okuma, InventoryState okuma).
2. Her grup için scene-side bir narrow accessor öner (preload veya
   helper class).
3. Önce DOC-only patch yap: Docs/ARCHITECTURE.md'de "scene -> AppBootstrap
   bağımlılığı azaltılacak" stratejisini yazılı hale getir.
4. Sonra EN AZ DROP'LU 1-2 scene için raw getter'ı narrow accessor'a çevir.
5. Tam refactor için B1 önerisi L effort; bu prompt sadece doc + 2 scene
   pilotu.

DOĞRULAMA:
- py -3 Tools/validate_architecture_guards.py
- powershell -File Tools/run_godot_smoke.ps1
- powershell -File Tools/run_godot_full_suite.ps1

DOKUNMA:
- AppBootstrap.gd'ye yeni method EKLEME.
- RuntimeState owner'ları YOK.

BAŞARI:
- Doc strateji yazılı.
- 2 scene pilot tamamlanmış (örn: scenes/main_menu.gd ve scenes/run_end.gd).
- Tüm testler PASS.
- Geriye kalan scene'ler final response backlog notu olarak listelenmiş.
```

---

## Prompt 2.2 — Application invalid-state/error handling stilini standartlaştır (B1: P-11)

```text
ROL: (genel kural özeti)
KURAL: Guarded lane. Davranış DEĞİŞMESİN, ifade biçimi standartlaşsın.

GÖREV:
B1 audit raporu (APP-F4): run_session_coordinator, app_bootstrap, combat_flow,
save_runtime_bridge, game_flow_manager invalid state durumunda farklı stil
kullanıyor (silent return / assert / push_error / domain event karışık).

ADIMLAR:
1. Her dosyadaki "invalid state branch"leri grupla.
2. Standart politikayı Docs/ARCHITECTURE.md'ye yaz:
   - silent return: yalnızca beklenen no-op için
   - push_error: development-only beklenmeyen durum
   - domain event: gameplay-impact varsa
3. Her dosyada politikaya göre minimum patch uygula.
4. Davranış aynı kalmalı; sadece tutarlı stil.

DOĞRULAMA:
- py -3 Tools/validate_architecture_guards.py
- targeted: powershell -File Tools/run_godot_tests.ps1
  test_flow_state.gd test_save_terminal_states.gd test_combat_spike.gd
- powershell -File Tools/run_godot_full_suite.ps1

DOKUNMA:
- Yeni domain event family OLUŞTURMA.
- Mevcut event isimlerini RENAME ETME.
- Save shape YOK.

BAŞARI:
- Doc politikası live.
- 5 dosya stilde tutarlı.
- Tüm testler PASS.
```

---

## Prompt 2.6 — SceneRouter overlay contract sertleştir (B1: P-15)

```text
ROL: (genel kural özeti)
KURAL: Guarded lane. SceneRouter contract'ı magic-string'den uzaklaştır.

GÖREV:
B1 audit raporu (ARCH-F4): scene_router.gd scene-specific choreography
string'lerine sıkı bağlı.

ADIMLAR:
1. scene_router.gd içindeki magic string'leri listele.
2. Her birini Game/Infrastructure/scene_router_constants.gd (yeni) altına
   const olarak taşı.
3. Caller'lar (overlay-opening scene method'ları) constants'a referans versin.
4. Yeni overlay tipi eklemek için contract'ı doc'a yaz: Docs/ARCHITECTURE.md.
5. Yeni autoload eklemekten KAÇIN.

DOĞRULAMA:
- py -3 Tools/validate_architecture_guards.py
- powershell -File Tools/run_godot_tests.ps1 test_flow_state.gd test_phase2_loop.gd
- powershell -File Tools/run_godot_smoke.ps1
- powershell -File Tools/run_godot_full_suite.ps1

DOKUNMA:
- Yeni flow state YOK.
- Yeni overlay scene EKLEME (sadece contract sertleştirme).

BAŞARI:
- scene_router.gd magic string-free.
- Caller'lar constants kullanıyor.
- Tüm testler PASS.
```

---

## Prompt 3.1 — `map_board_composer_v2.gd` extraction preflight'i (REPORT-ONLY, inline)

```text
ROL: (genel kural özeti)
KURAL: REPORT-ONLY. Kod DEĞİŞTİRME.

GÖREV:
Game/UI/map_board_composer_v2.gd 1258 satır, hotspot guard listesinde olmasına
rağmen henüz extraction preflight'i eksik. Yeni bir plan dosyası oluşturma;
final response içinde aşağıdaki bölümlerle raporla:
- symbol/function map
- responsibility groups
- hedef helper dosyaları
- önerilen patch sırası

İÇERİK:
1. Mevcut sorumluluklar (sembol/fonksiyon listesi).
2. Önerilen extraction parçaları (örn. trail geometry, node placement,
   canopy generation, fallback layout).
3. Her parça için:
   - hedef dosya/path
   - public API yüzeyi
   - backwards compat plan
   - test stratejisi
4. Risk lane: bu dosya UI presentation, ama map runtime ile sıkı entegre.
   Etkilenen owner'lar listesi.

DOKUNMA:
- map_board_composer_v2.gd KOD YOK.
- map_runtime_state.gd YOK.

BAŞARI:
- Inline preflight raporu eksiksiz.
- Sembol/fonksiyon haritası eksiksiz.
```

---

## Prompt 3.2 — `inventory_actions.gd` ve `support_interaction_state.gd` deep audit (REPORT-ONLY, inline)

```text
ROL: (genel kural özeti)
KURAL: REPORT-ONLY.

GÖREV:
İki dosya hotspot listesinde ama audit pass'inde derinlemesine işlenmemiş:
- Game/Application/inventory_actions.gd (1087 satır)
- Game/RuntimeState/support_interaction_state.gd (976 satır)

A1 / A2 audit raporlarına ek olarak final response içinde derin audit raporu
ver. Ayrı bir dosya ancak kullanıcı özellikle isterse oluştur.

ÖZELLIK:
- Cyclomatic complexity hotspot'ları
- Duplicate branch'ler
- Dead helper'lar
- Owner sınırı ihlali olup olmadığı
- Save schema implications

DOKUNMA: Kod YOK.

BAŞARI:
- Inline rapor eksiksiz.
- Patch candidates tablosu var.
```

---

## Prompt 1.5 — Stale wrapper / dead alias temizliği (B1: P-05)

```text
ROL: (genel kural özeti)
KURAL: Fast lane. SADECE 0-caller'lı dead path silimi.

GÖREV:
B1 audit raporu (RS-F5, APP-F5, MAINT-F8): aşağıdaki adaylar için repo
genelinde caller var mı doğrula; YOKSA sil.

ADAYLAR (B1 önerisi; her birini DOĞRULAMADAN silme):
- Game/Application/game_flow_manager.gd:transition_to (eğer dead ise)
- Game/Infrastructure/save_service.gd:is_supported_save_state_now
- Game/Infrastructure/playtest_logger.gd public alias'lar

ADIMLAR:
1. Her aday için repo genelinde grep + Tests/ altında özel arama yap.
2. 0 caller doğrulanırsa sil; aksi halde "caller var" raporla, geç.
3. Stale comment'leri (run_state.gd, save_service.gd, flow_state.gd) aynı
   patch'te temizle.

DOĞRULAMA:
- py -3 Tools/validate_architecture_guards.py
- powershell -File Tools/run_godot_full_suite.ps1
- silinen her method için kısa bir kanıt notu ekle commit message'a

DOKUNMA:
- High-risk owner dosyaları YOK (`map_runtime_state.gd`, `inventory_state.gd`,
  `support_interaction_state.gd`).
- run_state.gd compatibility accessor field/property YOK (E-2 escalate
  kapsamında, bu prompt değil).

BAŞARI:
- Sadece 0-caller doğrulanan path'ler silinmiş.
- Tüm testler PASS.
```

---

## Prompt 5.1 — Compact UI accessibility polish (B1: O-1)

```text
ROL: (genel kural özeti)
KURAL: Fast lane. Optional. UI quality choice.

GÖREV:
B1 audit raporu (UI-F6, UI-F7): inventory_card_factory.gd, run_status_strip.gd,
safe_menu_overlay.gd compact UI tap-target / contrast / signal lifecycle
floor'larını yükselt.

ADIMLAR:
1. Tap target minimum 88px (mobile guideline).
2. State-icon dual signal: color-only feedback varsa icon/shape ile destekle.
3. Signal connect/disconnect simetrisi.

DOĞRULAMA:
- portrait captures
- targeted scene isolation
- powershell -File Tools/run_godot_full_suite.ps1

BAŞARI: Accessibility raporu live, breakdown var.
```

---

## Prompt 5.2 — Tooling hijyen pass (B1: O-2)

```text
ROL: (genel kural özeti)
KURAL: Fast lane. Optional.

GÖREV:
B1 audit raporu (MAINT-F5, MAINT-F9):
- Tools/validate_content.py büyük; bölümlere ayır.
- Local cache artifact'ları (.godot/, _godot_profile/) gitignore tutarlılığı.
- Stale helper comment'leri.
- Runner doc'ları güncel mi?

ADIMLAR:
1. validate_content.py'yi sub-validator'lara böl (rules vs schema vs reference).
2. .gitignore'da cache path'leri kontrol et.
3. Runner doc'larını TECH_BASELINE.md ile karşılaştır.

DOĞRULAMA:
- py -3 Tools/validate_architecture_guards.py
- her sub-validator ayrı ayrı

BAŞARI: validate_content.py daha küçük modüler dosyalar; doc tutarlı.
```

---
