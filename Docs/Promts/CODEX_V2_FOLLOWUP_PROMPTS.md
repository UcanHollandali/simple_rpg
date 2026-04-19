# Codex V2 Follow-Up Görev Listesi — Audit Sentezi Sonrası İkinci Tur

Son güncelleme: 2026-04-19
Hedef: `Docs/Audit/2026-04-18-patch-backlog.md` (B1) sentez raporundaki 19 maddeyi Codex'e verilebilir tam prompt formatına dönüştürmek + eksik kalan A6 maintainability audit'i tamamlamak + yeni hotspot bulgularını eklemek.

## Kaynak Doğrulama

`Kesin bilgi`:
- Önceki polish round'u uygulandı (CODEX_POLISH_PROMPTS Faz 1.1, 1.2, 1.5, 2.1, 2.2, 3.1, 4.1–4.3, 5.1, 5.2, 5.4 tamamlanmış)
- Audit round'u uygulandı (A1–A5 + B1 raporları üretilmiş; A6 eksik)
- HANDOFF.md `2026-04-18`'e güncellenmiş
- 19 maddelik B1 backlog hazır ama henüz prompt formatına dönüştürülmemiş

`Varsayım`:
- Codex bu V2 listesini commit edilmemiş working tree üzerinde çalıştıracak (git log'da audit raporları henüz yok)
- Açık karar maddeleri (E-1..E-5) ön onay gerektirir; Codex'e doğrudan patch olarak verilmez

## Nasıl Kullanılır

Önerilen sıra (faz bağımsızlık matrisine göre):

1. **Tur 0 — Eksiği kapat:** Prompt 0.1 (A6 maintainability audit)
2. **Tur 1 — Quick Wins (Fast Lane, paralel ver):** Prompt 1.1 → 1.6
3. **Tur 2 — Strategic (Guarded Lane, sıralı):** Prompt 2.1 → 2.6
4. **Tur 3 — Yeni hotspot tarama:** Prompt 3.1, 3.2
5. **Tur 4 — Escalate kararları (insana karar):** Bölüm "Açık Kararlar"
6. **Tur 5 — Optional polish:** Prompt 5.1, 5.2

Her tur sonunda ortak doğrulama:

```
py -3 Tools/validate_content.py
py -3 Tools/validate_assets.py
py -3 Tools/validate_architecture_guards.py
powershell -NoProfile -ExecutionPolicy Bypass -File Tools/run_godot_full_suite.ps1
```

Smoke yalnızca scene/autoload boot wiring değişirse:

```
powershell -NoProfile -ExecutionPolicy Bypass -File Tools/run_godot_smoke.ps1
```

## Genel Kural Özeti (her promptun başına dahili olarak ekleyin)

```
ROL: Godot 4 + typed GDScript üzerinde çalışan Simple RPG mühendisisin.
KURAL:
- AGENTS.md risk lane disiplini ZORUNLU.
- High-Risk Escalate-First alanlarına (RunState, MapRuntimeState,
  InventoryState, SaveService, GameFlowManager, SAVE_SCHEMA) sadece
  açıkça izin verildiyse dokun.
- "Kesin bilgi" ile "varsayım" ayrımı raporda net olsun.
- DOC drift varsa authority doc'u ayrı patch olarak güncelle, kodla
  karıştırma.
- Save schema, flow state, command/event family değişikliği = STOP +
  escalate.
```

---

## TUR 0 — Eksik Audit'i Tamamla

### Prompt 0.1 — A6 Maintainability Audit (REPORT-ONLY)

```
ROL: (genel kural özeti)
KURAL: REPORT-ONLY. Kod DEĞİŞTİRME.

GÖREV:
Eksik kalan maintainability audit'ini üret:
Docs/Audit/2026-04-18-maintainability-audit.md

KAPSAM:
- Game/ + scenes/ tüm .gd dosyaları (84 dosya, 30132 satır)
- Tools/ Python script'leri
- Tests/ test yüzeyi

TARAMA KRİTERLERİ:

1) File Size Hotspot
   - Her .gd dosyasının satır sayısını ölç.
   - 500+ olanları liste; HANDOFF extraction-first guard listesiyle karşılaştır.
   - Liste DIŞINDA olup 500+ olan YENİ dosyaları ayrı işaretle.
   - Mevcut bilinen büyük dosyalar:
     map_runtime_state.gd 2397, map_board_composer_v2.gd 1258,
     combat.gd 1098, inventory_actions.gd 1087, inventory_state.gd 1060,
     run_session_coordinator.gd 1018, map_route_binding.gd 980,
     support_interaction_state.gd 976, map_explore.gd 905

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

## TUR 1 — Quick Wins (Fast Lane)

Hepsi paralel verilebilir. Doc drift + dead code + küçük extraction.

### Prompt 1.1 — SAVE_SCHEMA pending-node ownership doc düzeltmesi (B1: P-01)

```
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

### Prompt 1.2 — COMMAND_EVENT_CATALOG drift düzeltmesi (B1: P-02)

```
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

### Prompt 1.3 — Inventory display-name/family mapping helper extraction (B1: P-03)

```
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

### Prompt 1.4 — Texture loader helper konsolidasyonu (B1: P-04)

```
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

### Prompt 1.5 — Stale wrapper / dead alias temizliği (B1: P-05)

```
ROL: (genel kural özeti)
KURAL: Fast lane. SADECE 0-caller'lı dead path silimi.

GÖREV:
B1 audit raporu (RS-F5, APP-F5, MAINT-F8): aşağıdaki adaylar için repo
genelinde caller var mı doğrula; YOKSA sil.

ADAYLAR (B1 önerisi; her birini DOĞRULAMADAN silme):
- Game/Application/game_flow_manager.gd:transition_to (eğer dead ise)
- Game/Infrastructure/save_service.gd:is_supported_save_state_now
- Game/Infrastructure/playtest_logger.gd public alias'lar
- Game/RuntimeState/map_runtime_state.gd public alias'lar (escalate sınırına
  YAKLAŞMA — sadece açıkça 0 caller'lı yardımcı method'lar)

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
- map_runtime_state.gd ana behavior YOK.
- run_state.gd compatibility accessor field/property YOK (E-2 escalate
  kapsamında, bu prompt değil).

BAŞARI:
- Sadece 0-caller doğrulanan path'ler silinmiş.
- Tüm testler PASS.
```

### Prompt 1.6 — Architecture guard genişletme (B1: P-06)

```
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

## TUR 2 — Strategic (Guarded Lane)

Sıralı verin; çakışma riski var. Her birinin sonunda smoke + full suite.

### Prompt 2.1 — Scene'lerin AppBootstrap'a doğrudan bağımlılığını daralt (B1: P-10)

```
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
- Geriye kalan scene'ler için backlog notu Docs/Audit/ altına eklenmiş.
```

### Prompt 2.2 — Application invalid-state/error handling stilini standartlaştır (B1: P-11)

```
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

### Prompt 2.3 — Scene tema/layout konsolidasyon kalan drift'i (B1: P-12)

```
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

### Prompt 2.4 — Inventory panel post-render traversal hotspot kaldır (B1: P-13)

```
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

### Prompt 2.5 — Portrait density/theme/accessibility floor merkezi (B1: P-14)

```
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
- Accessibility floor raporlanmış (Docs/Audit/ ek not).
```

### Prompt 2.6 — SceneRouter overlay contract sertleştir (B1: P-15)

```
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

## TUR 3 — Yeni Hotspot Tarama

A6 audit'i tamamlanırsa muhtemelen bu maddelerin bir kısmı orada da çıkacak.
Yine de eksiksiz olsun diye burada listelenmiş.

### Prompt 3.1 — `map_board_composer_v2.gd` extraction planı (REPORT-ONLY)

```
ROL: (genel kural özeti)
KURAL: REPORT-ONLY. Kod DEĞİŞTİRME.

GÖREV:
Game/UI/map_board_composer_v2.gd 1258 satır, hotspot guard listesinde olmasına
rağmen henüz extraction planı yok. Bu dosyaya benzer bir
MAP_RUNTIME_STATE_EXTRACTION_PLAN.md tarzı plan yaz:
Docs/Promts/MAP_BOARD_COMPOSER_V2_EXTRACTION_PLAN.md

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
- Plan dosyası live.
- Sembol/fonksiyon haritası eksiksiz.
```

### Prompt 3.2 — `inventory_actions.gd` ve `support_interaction_state.gd` audit (REPORT-ONLY)

```
ROL: (genel kural özeti)
KURAL: REPORT-ONLY.

GÖREV:
İki dosya hotspot listesinde ama audit pass'inde derinlemesine işlenmemiş:
- Game/Application/inventory_actions.gd (1087 satır)
- Game/RuntimeState/support_interaction_state.gd (976 satır)

A1 / A2 audit raporlarına ek olarak Docs/Audit/2026-04-19-inventory-support-deep.md
yaz.

ÖZELLIK:
- Cyclomatic complexity hotspot'ları
- Duplicate branch'ler
- Dead helper'lar
- Owner sınırı ihlali olup olmadığı
- Save schema implications

DOKUNMA: Kod YOK.

BAŞARI:
- Rapor live.
- Patch candidates tablosu var.
```

---

## TUR 4 — Açık Kararlar (İnsana Karar)

Bu maddeler Codex'e DOĞRUDAN VERİLMEZ. Sen (Meltem) karar verdikten sonra
ayrı escalate prompt'u yazılır.

B1'in Open Questions bölümünden ve Escalate kümesinden:

1. **NodeResolve fallback** — gerçekten canlı contract olarak mı kalsın, yoksa
   docs kadar daraltılsın mı? (B1: B-2, APP-F1, SCN-F7)
2. **RunState compatibility accessors** — dondurulmuş compat yüzeyi mi yoksa
   migration ile kaldırılsın mı? (B1: E-2, RS-F2)
3. **Hamlet side-quest state** — iki owner arasında bilinçli phase split mi
   yoksa net owner cleanup mı? (B1: E-3, RS-F3)
4. **InventoryState cached getter** — yazan-read semantiği kabul mu yoksa
   explicit accessor API'ye dönüş mü? (B1: E-4, RS-F4, ARCH-F3)
5. **zz_ event-template rename** — stable-ID churn'e değer mi? (B1: E-5,
   CODEX_POLISH_PROMPTS Faz 1.3 covered ama blocked)
6. **gate_warden** — test/rezerv olarak mı kalsın yoksa archive/4. boss
   planı mı? (CODEX_POLISH_PROMPTS Faz 1.4 covered ama prior decision'a göre
   parked)
7. **MapRuntimeState extraction implementation** — owner-preserving extraction
   şu an riske değer mi? (B1: E-1)

Karar verdiğinde her madde için ayrı escalate prompt yazılır. Şu an Codex'e
verme.

---

## TUR 5 — Optional Polish

### Prompt 5.1 — Compact UI accessibility polish (B1: O-1)

```
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

### Prompt 5.2 — Tooling hijyen pass (B1: O-2)

```
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

## Tur Sonrası Karar Noktası

Her turdan sonra:

1. `git status` çalıştır; uncommit değişiklikleri commit et (kritik —
   Codex çalışmalarını commit ETMEZSEN crash'te kaybedersin).
2. HANDOFF.md'yi turu yansıtacak şekilde güncelle.
3. Sonraki turu vermeden önce mevcut audit raporlarını hızlıca tara —
   yeni bulgular V2'ye eklenecek mi?

## `Kesin bilgi` Notları

- Bu V2 listesi sadece B1 sentez backlog'unu prompt formatına çeviriyor +
  eksik A6 audit'ini ekliyor + 2 yeni hotspot raporu istiyor.
- Hiçbir prompt high-risk lane'e izinsiz girmiyor.
- Açık kararlar bölümü Codex'e değil sana yöneliktir.
- Bu liste tamamlanırsa repo `Quick Wins + Strategic + 2 yeni rapor` kapsamında
  derli toplu olur. Kalan high-risk işler senin karar verdiğinde escalate
  pass'i ile çözülür.

## `Varsayım` Notları

- Codex'in commit-disiplini düşük; bu V2'yi vermeden önce mevcut working
  tree'yi commit'lemen gerek (audit raporları + HANDOFF güncellemesi şu an
  uncommit duruyor).
- Tur 0 (A6) tamamlanırsa B-1 blocker düşer; o anda B1 backlog "tam ve durable"
  sayılır.
- Tur 1+2 tamamlanırsa repo CODEX_POLISH_PROMPTS + audit pass + V2 strategic
  patch'leri ile playtest-ready durur. Yeni audit/round muhtemelen 4-6 hafta
  sonra anlamlı olur.
