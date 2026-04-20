# Q2 PLAYBOOK — Tek dosya, sıralı Codex kuyruğu

Bu dosya Q2 temizlik kuyruğunun **tek** kaynağıdır. 25 prompt, 6 batch, her biri kendi başlığı altında.

- Otorite dokümanlar: `AGENTS.md`, `Docs/DOC_PRECEDENCE.md`, `Docs/HANDOFF.md`
- Uzun vade: `Docs/LONG_TERM_ROADMAP.md`
- Q2 sonrası kuyruklar: `Docs/Promts/BIG_FILE_QUEUE.md`, `Docs/Promts/MAP_ASSET_QUEUE.md`
- Asset üretim rehberi (kullanıcıya): `Docs/Promts/AI_ASSET_GUIDE.md`

---

## 0. Nasıl kullanılır

1. Bu dosyayı sırayla okut. Her `## W…` başlığı tek bir Codex koşusudur.
2. Codex'e tek satır ver:
   ```
   Oku: Docs/Promts/Q2_PLAYBOOK.md — sadece W0-01 bölümünü uygula, sonraki bölümlere geçme.
   ```
   Sıradaki prompt için `W0-01` yerine `W0-06`, `W0-04`, … yaz.
3. Her bölümün kendi **validation budget** satırı var. Validator yeşil olmadan sıradaki bölüme geçme.
4. Bir batch bitince commit at, sonra sıradaki batch.

---

## 1. Batch özeti

| Batch | Lane | Kapsam | Prompt sayısı |
|---|---|---|---|
| 1. Doc baseline | Fast, doc-only | Audit, HANDOFF, SAVE_SCHEMA, catalog, decision log, duplicate cleanup | 6 |
| 2. Karar dokümantasyonu | Fast, doc-only | D-042..D-045 kararlarını koda + otorite dokümanlara işle | 4 |
| 3. Kod hijyeni | Fast | Stale wrapper, helper extraction, texture loader, validator guard, gate_warden retire | 5 |
| 4. Yapı temizliği | Guarded | NodeResolve align, AppBootstrap narrow, error handling, theme consolidation, traversal hotspots, density constants, router overlay | 7 |
| 5. Escalate-first | Escalate | MapRuntimeState extraction | 1 |
| 6. Opsiyonel polish | Fast | Accessibility polish, tooling hygiene | 2 |

---

## BATCH 1 — Doc baseline (6 prompt)

### W0-01 — Audit raporunu yeniden üret (B-1)

- mode: Fast Lane, doc-only
- scope: `Docs/Audit/2026-04-18-maintainability-audit.md` oluştur; başka hiçbir şey
- do not touch: kod, diğer dokümanlar, patch-backlog, roadmap
- validation budget: `py -3 Tools/validate_architecture_guards.py`
- doc policy: `Docs/Audit/2026-04-18-patch-backlog.md` içindeki `MAINT-F1..MAINT-F9` atıflarından yeniden inşa et; yeni bulgu icat etme.

**Neden:** Patch backlog şu an "`Docs/Audit/2026-04-18-maintainability-audit.md` is not present" diyor; bu da `MAINT-F*` atıflarını boşa çıkarıyor.

**Görev:**
1. `Docs/Audit/2026-04-18-maintainability-audit.md` oluştur.
2. Kardeş dosyaların (application / architecture / runtimestate / scene / ui audit) yapı ve tonunu kullan.
3. Her `MAINT-F1..MAINT-F9` için metin kaynağı: patch-backlog'daki her atıf (P-03, P-04, P-05, P-06, E-1, vs.).
4. Report-only ton. Üstte tek paragraf method notu: "reconstructed 2026-04-20 from patch-backlog citations".
5. Üst satıra: `Status: reconstructed 2026-04-20 from backlog citations; not a fresh scan.`

**Non-goals:** Patch backlog'u düzenleme. Yeni ID uydurma. Kod değiştirme.

**Report format:** değişiklik listesi; "no code changed" beyanı; `MAINT-F` ID'leri artık çözülüyor doğrulaması.

### W0-06 — Duplicate extraction plan'ı sil

- mode: Fast Lane, doc-only
- scope: `Docs/Promts/MAP_RUNTIME_STATE_EXTRACTION_PLAN.md` sil; `Docs/MAP_RUNTIME_STATE_EXTRACTION_PLAN.md` aynen kalsın
- do not touch: kod, diğer dokümanlar
- validation budget: `py -3 Tools/validate_architecture_guards.py`; eski path'e grep
- doc policy: extraction plan `Docs/` root altında otorite; `Docs/Promts/` altında değil.

**Görev:**
1. İki dosyayı diff'le; `Docs/Promts/` altındakinin stale kopya olduğunu teyit et.
2. Eğer içerik farklıysa diff'i raporla ve dur; silme.
3. Eğer esasen aynılarsa `Docs/Promts/MAP_RUNTIME_STATE_EXTRACTION_PLAN.md`'yi sil.
4. Repo'da eski path'e kalan referansları grep'le, bul, `Docs/` root kopyasına çevir.

**Non-goals:** Otoritatif planın içeriğine dokunma. Kod değiştirme.

**Report format:** diff özeti; silme kararı; eski path için `0 remaining references` grep çıktısı.

### W0-04 — SAVE_SCHEMA pending-node ownership düzelt (P-01)

- mode: Fast Lane, doc-only
- scope: sadece `Docs/SAVE_SCHEMA.md`
- do not touch: kod, diğer otorite dokümanlar, audit dokümanları
- validation budget: `py -3 Tools/validate_architecture_guards.py`
- doc policy: konuyu taşıma; ownership ifadesini yerinde düzelt.

**Görev:**
1. `Docs/Audit/2026-04-18-runtimestate-audit.md` `RS-F1` bulgusunu oku; tam drift ifadesini teyit et.
2. `SAVE_SCHEMA.md` pending-node bölümünü güncel runtime owner'ı (SOURCE_OF_TRUTH.md'deki gibi) söyleyecek şekilde düzelt.
3. Yeni owner getirme. Kodda ownership kaydırma. Migration notu yazma (RS-F1 açıkça istemiyorsa).

**Non-goals:** Save version değişikliği. Kod değişikliği. `SAVE_SCHEMA.md` restructure.

**Report format:** before/after quote; SOURCE_OF_TRUTH owner adı artık save schema cümlesiyle eşleşiyor doğrulaması.

### W0-05 — Catalog drift kaydı (P-02)

- mode: Fast Lane, doc-only
- scope: sadece `Docs/COMMAND_EVENT_CATALOG.md`
- do not touch: kod, catalog dışı otorite dokümanlar
- validation budget: `py -3 Tools/validate_architecture_guards.py`
- doc policy: catalog bir naming register'dır; yeni event family icat etme.

**Kesin drift (2026-04-20 ölçümü):**
- `turn_phase_resolved`: kodda 6 kez, catalog'da 0.
- `BossPhaseChanged`: kodda 9 kez, catalog'da 0.

**Görev:**
1. Catalog'u aç.
2. Her iki ismi mevcut bullet formatında (event vs command family ayrımı korunarak) alfabetik sırayı bozmadan ekle.
3. Her giriş için tek cümlelik origin notu: hangi runtime yayıyor — kodu grep'leyip en yakın emitter'ı adlandır.
4. Kodda olmayan family ekleme.

**Non-goals:** `ARCHITECTURE.md`'ye dokunma. Kod değişikliği. Mevcut girişlerin yeniden adlandırılması.

**Report format:** eklemeler; her isim için emitter dosyası grep doğrulaması.

### W0-03 — DECISION_LOG'a D-041..D-046

- mode: Fast Lane, doc-only
- scope: sadece `Docs/DECISION_LOG.md`
- do not touch: kod, otorite dokümanlar
- validation budget: `py -3 Tools/validate_architecture_guards.py`
- doc policy: mevcut `## Accepted Decisions` tablosunun satır formatına birebir uy: `| D-0xx | <decision sentence ending with a period.> | <authority doc refs separated by commas> |`.

**Eklenecek kararlar (sıradaki boş ID'den başlayarak):**

| ID | Decision | Authority |
|---|---|---|
| D-041 | `NodeResolve` is an orchestrated transition shell only and has no generic runtime fallback; docs and code must read consistently on this. | `GAME_FLOW_STATE_MACHINE.md`, `MAP_CONTRACT.md` |
| D-042 | `RunState` compatibility accessors (`weapon_instance`, `armor_instance`, `belt_instance`, `consumable_slots`, `passive_slots`) are a frozen compat surface, not an expansion surface; the validator already guards them and will remain the enforcement point. | `SOURCE_OF_TRUTH.md`, `SAVE_SCHEMA.md` |
| D-043 | The hamlet side-quest runtime state stays split between `MapRuntimeState` and `SupportInteractionState` by design; both owners must name the split explicitly in their own file header. | `SOURCE_OF_TRUTH.md`, `SUPPORT_INTERACTION_CONTRACT.md`, `MAP_CONTRACT.md` |
| D-044 | `InventoryState` cached slot-family getters are allowed to write-through their cache as a named exception; new callers must not treat this pattern as a generic allowance. | `SOURCE_OF_TRUTH.md` |
| D-045 | `zz_*` stable IDs for event templates are a deliberate alphabetical-sort convention, not churn debt; no rename is planned. | `CONTENT_ARCHITECTURE_SPEC.md` |
| D-046 | `gate_warden` is retired; its definitions, assets, and references are to be removed and the dead content is not reserved for a future boss slot. | `CONTENT_ARCHITECTURE_SPEC.md`, `GDD.md` |

**Kurallar:** karar metnini birebir kopyala; rasyonel kolonu ekleme; otorite dokümanlara bu patch'te dokunma (W1-05..W1-09 onları işleyecek).

**Report format:** eklenen satırlar; final ID'ler; "no authority doc changed, no code changed".

### W0-02 — HANDOFF.md refresh

- mode: Fast Lane, doc-only
- scope: sadece `Docs/HANDOFF.md`
- do not touch: kod, diğer dokümanlar, audit
- validation budget: `py -3 Tools/validate_architecture_guards.py`
- doc policy: HANDOFF rolling current-state; stale kısmı yeniden yaz, ekleme yapma.

**Düzeltilecekler:**
1. `Last updated: 2026-04-18` → bugünün tarihi.
2. ~188. satırdaki "there is still no Docs/Audit/ folder..." bullet'ı artık yanlış — `Docs/Audit/` var. Bullet'ı gerçeği yansıtacak şekilde yeniden yaz.
3. Validator hotspot bölümüne tek satır: `HOTSPOT_FILE_LINE_LIMITS` artık 14 dosyayı kapsıyor (combat_flow, inventory_actions, inventory_state, support_interaction_state, combat_presenter, inventory_presenter, safe_menu_overlay dahil).
4. Diğer bölümleri bırak.

**Non-goals:** otorite anlamı değiştirme; otorite dokümanda yer alan kuralları tekrar etme; yeni bölüm ekleme.

**Report format:** satır anchor'ıyla değişiklik listesi; "no code changed, no authority doc changed".

**Batch 1 exit:** `py -3 Tools/validate_architecture_guards.py` yeşil. Commit: `docs: refresh Q2 doc baseline (W0-01..W0-06)`.

---

## BATCH 2 — Karar dokümantasyonu (4 prompt)

### W1-08 — RunState compat-surface freeze notu (D-042)

- mode: Fast Lane, doc-only (inline block comment + authority-doc text)
- scope: `Game/RuntimeState/run_state.gd` compat accessor block'unun (yaklaşık satır 38-68) hemen üstüne block comment; `Docs/SOURCE_OF_TRUTH.md` ve `Docs/SAVE_SCHEMA.md` içine kısa paragraf
- do not touch: accessor implementasyonu; herhangi caller; `Tools/validate_architecture_guards.py` (zaten aynı isimleri koruyor); test
- validation budget: `py -3 Tools/validate_architecture_guards.py`
- doc policy: D-042'yi uygula. Accessor'ları retire etme. Yeni accessor ekleme.

**Görev:**
1. Compat accessor block'unun hemen üstüne 6-10 satırlık block comment ekle:
   - bu frozen compatibility surface,
   - beş isim expansion surface değil,
   - validator yeni caller'ları yakalar,
   - karar D-042,
   - read/write owner InventoryState.
2. `Docs/SOURCE_OF_TRUTH.md`'ye freeze'i yineleyen kısa paragraf ekle.
3. `Docs/SAVE_SCHEMA.md` bu isimlerden bahsediyorsa tek satır cross-reference.

**Non-goals:** accessor ekle/sil; validator kuralı değiştir; caller'lara dokun.

**Report format:** comment'in exact line span'ı; SOURCE_OF_TRUTH paragrafı final; SAVE_SCHEMA cross-reference (veya gereksiz notu); validator sonucu.

### W1-05 — Hamlet phase-split notu (D-043)

- mode: Fast Lane, doc-only
- scope: `Game/RuntimeState/map_runtime_state.gd` ve `Game/RuntimeState/support_interaction_state.gd` dosyalarına header block comment; `Docs/SOURCE_OF_TRUTH.md`, `Docs/SUPPORT_INTERACTION_CONTRACT.md`, `Docs/MAP_CONTRACT.md` içine kısa paragraf
- do not touch: function body; runtime-state field; save shape
- validation budget: `py -3 Tools/validate_architecture_guards.py`
- doc policy: D-043'ü uygula; yeni ownership kuralı yaratma.

**Görev:**
1. İki `.gd` dosyasının üstüne 3-6 satırlık block comment: hamlet side-quest runtime state bilerek iki owner arasında bölünmüştür; diğer owner'ın adı; D-043 + SOURCE_OF_TRUTH.md referansı.
2. `Docs/SOURCE_OF_TRUTH.md` ownership bölümüne aynı anlamda kısa paragraf.
3. `Docs/SUPPORT_INTERACTION_CONTRACT.md` ve `Docs/MAP_CONTRACT.md` içine tek cümle: tam split için SOURCE_OF_TRUTH.md'ye yönlendirme.
4. Alanları iki owner arasında taşıma.

**Non-goals:** function body dokunma; save shape ayar; yeni command/event family.

**Report format:** beş edit için before/after; alan taşınmadı/signal değişmedi/test güncellemesi gerekmedi beyanı; validator sonucu.

### W1-06 — InventoryState cached-getter write-through istisnası (D-044)

- mode: Fast Lane, doc-only
- scope: `Game/RuntimeState/inventory_state.gd` cached slot-family getter site etrafına block comment; `Docs/SOURCE_OF_TRUTH.md` içine kısa paragraf
- do not touch: getter implementasyonu; caller; başka otorite dokümanı
- validation budget: `py -3 Tools/validate_architecture_guards.py`
- doc policy: D-044'ü uygula; yeni pattern allowance icat etme.

**Görev:**
1. `Game/RuntimeState/inventory_state.gd` içindeki cached slot-family getter site'ını (patch-backlog'da `RS-F4` / `ARCH-F3` ile işaretli olanı) bul.
2. Site'ın hemen üstüne 4-8 satırlık comment:
   - cache write-through kasıtlı,
   - named exception, generic allowance değil,
   - yeni caller'lar bunu pattern olarak kabul etmemeli,
   - authority D-044 + SOURCE_OF_TRUTH.md.
3. `Docs/SOURCE_OF_TRUTH.md`'ye istisnayı ve site dosyasını adlandıran kısa paragraf.

**Non-goals:** getter implementasyonu değiştirme; caller değiştirme; cache politikası değiştirme.

**Report format:** site'ın comment öncesi/sonrası line number'ı; SOURCE_OF_TRUTH paragrafı before/after; validator sonucu.

### W1-07 — `zz_*` event-template konvansiyonu (D-045)

- mode: Fast Lane, doc-only
- scope: `Docs/CONTENT_ARCHITECTURE_SPEC.md` içine kısa paragraf
- do not touch: `ContentDefinitions/EventTemplates/zz_*.json`; runtime referans; test
- validation budget: `py -3 Tools/validate_architecture_guards.py`; `py -3 Tools/validate_content.py`
- doc policy: D-045; rename yok.

**Görev:**
1. `Docs/CONTENT_ARCHITECTURE_SPEC.md` stable-ID bölümüne 3-6 cümlelik paragraf:
   - `zz_*` kasıtlı alphabetical-sort konvansiyonu,
   - prefix stable ID'nin parçası, rename edilmeyecek,
   - benzer ordering gerektiren yeni template'ler konvansiyonu tekrar kullanabilir,
   - karar D-045.
2. Mevcut template'i rename etme.
3. Event template dosyalarını update etme.

**Non-goals:** `Tools/validate_content.py` davranışını değiştirme; içerik dosyası rename; patch backlog güncelleme.

**Report format:** final paragraf; validator + content validator sonuçları; "no content file changed".

**Batch 2 exit:** Altı kararın hepsi DECISION_LOG + kod block comment + otorite dokümanda tutarlı. Commit: `docs: codify Q2 decisions D-042..D-045 in owner files`.

---

## BATCH 3 — Kod hijyeni (5 prompt)

### W1-01 — Stale wrapper ve dead alias temizliği (P-05)

- mode: Fast Lane
- scope: `Game/Application/game_flow_manager.gd:transition_to`, `Game/Infrastructure/save_service.gd:is_supported_save_state_now`, artı grep ile repo içinde sıfır caller'ı olduğu teyit edilebilen her stale wrapper
- do not touch: `Game/RuntimeState/run_state.gd` compat accessor'ları (D-042 ile frozen); save shape; flow-state transition; command/event family
- validation budget: `py -3 Tools/validate_architecture_guards.py`; touched slice için targeted test; `Tools/run_godot_full_suite.ps1`
- doc policy: bir wrapper `Docs/` içinde dokumente edilmişse ya referansı bu patch'te güncelle ya da wrapper'a dokunma.

**Görev:**
1. Her aday wrapper için:
   1. Repo içinde sıfır caller — grep ile teyit.
   2. `Docs/` altında sıfır referans — grep ile teyit.
   3. Wrapper tanımını kaldır.
2. Sadece açıkça adlandırılmış iki wrapper + bağımsız teyit ettiğin her ekstra wrapper. Her ekstra silme ayrı raporla.
3. Wrapper kullanılmıyor gibi görünüyor ama "kept for save compat" gibi external-intent yorumu varsa dokunma, raporla.

**Non-goals:** public API rename; yeni indirection; RunState compat accessor; `Docs/COMMAND_EVENT_CATALOG.md` değişikliği.

**Report format:** wrapper başına path + karar (removed / kept with reason); her silme için sıfır caller grep sonucu; validator + test sonuçları.

### W1-02 — Inventory display-name/family helper extraction (P-03)

- mode: Fast Lane
- scope: `Game/UI/event_presenter.gd`, `Game/UI/reward_presenter.gd` ve `Game/UI/` altında yeni thin helper (örn. `Game/UI/inventory_display_labels.gd`). İki presenter yeni helper'ı tüketmeli.
- do not touch: gameplay truth; `Game/RuntimeState/*`; content schema; command/event catalog
- validation budget: `py -3 Tools/validate_architecture_guards.py`; `Tools/run_godot_tests.ps1 test_event_node.gd test_reward_node.gd`; `Tools/run_godot_full_suite.ps1`
- doc policy: UI helper extraction gameplay truth benimsememelidir. Otorite doküman güncellemesi gerekmiyor.

**Görev:**
1. `event_presenter.gd` ve `reward_presenter.gd`'de duplicate display-name/family mapping'i bul.
2. `Game/UI/` altına static helper: açıkça presentation-only rolü taşısın (örn. `inventory_display_labels.gd`).
3. İki callsite'ı yeni helper çağrısıyla değiştir.
4. Helper stateless: static functions veya stateless class; autoload yok, signal yok.
5. Davranış değişmesin; helper eski callsite'ların döndürdüğünün aynısını döndürmeli.

**Non-goals:** helper'ı bootstrap autoload listesine ekleme; helper içinde `RunState` / runtime-state file kullanma; mapping'i genişletme.

**Report format:** diff özeti (yeni dosya + iki değiştirilmiş callsite); validator + targeted test + full suite; "no gameplay truth moved, no new autoload".

### W1-03 — Texture loader konsolidasyonu (P-04)

- mode: Fast Lane
- scope: `Game/UI/inventory_card_factory.gd`, `Game/UI/map_board_canvas.gd`, `Game/UI/scene_layout_helper.gd`. Hiçbiri natural owner değilse `Game/UI/` altına yeni helper eklenebilir.
- do not touch: `Game/RuntimeState/*`; scene dosyası; texture asset; `ASSET_PIPELINE.md`; `ASSET_LICENSE_POLICY.md`
- validation budget: `py -3 Tools/validate_architecture_guards.py`; `Tools/run_godot_scene_isolation.ps1 -ScenePath scenes/map_explore.tscn`; `Tools/run_godot_full_suite.ps1`
- doc policy: asset-pipeline authority yerinde kalsın; bu sadece yükleme-kodu konsolidasyonu.

**Görev:**
1. Üç dosyada tekrar eden texture-load pattern'ını belirle.
2. Üç callsite'ı tek helper çağrısıyla yönlendir. `scene_layout_helper.gd` natural owner ise oraya; yoksa `Game/UI/` altına dar helper, stateless tut.
3. Davranış birebir aynı: aynı fallback, aynı error reporting, aynı cache davranışı (yeni cache ekleme).
4. Asset path değiştirme.

**Non-goals:** yeni cache; fallback semantics değiştirme; `ASSET_PIPELINE.md` / `ASSET_BACKLOG.md` güncelleme.

**Report format:** diff özeti; before/after callsite sayısı; validator + scene isolation + full suite.

### W1-04 — Validator guard genişletme (P-06)

- mode: Fast Lane
- scope: sadece `Tools/validate_architecture_guards.py`; gerekirse `Tests/` altında küçük fixture
- do not touch: production `.gd` kodu; mevcut validator kuralları; `RUNTIME_RUNSTATE_COMPATIBILITY_PATTERNS` / `TEST_RUNSTATE_INVENTORY_COMPATIBILITY_PATTERNS` (RunState compat zaten korunuyor — ikinci kural ekleme)
- validation budget: `py -3 Tools/validate_architecture_guards.py`; `Tools/run_godot_full_suite.ps1`
- doc policy: validator tooling; otorite doküman güncellemesi gerekmiyor.

**RunState compat guard'ı tekrar ekleme:** mevcut `RUNTIME_RUNSTATE_COMPATIBILITY_PATTERNS` + `TEST_RUNSTATE_INVENTORY_COMPATIBILITY_PATTERNS` `weapon_instance | armor_instance | belt_instance | consumable_slots | passive_slots | current_node_index` isimlerini zaten kapsıyor.

**İki dar ekleme:**

1. **Catalog-drift guard:** `Docs/COMMAND_EVENT_CATALOG.md`'de kayıtlı olmayan event/command adlarına yapılan kod referanslarını yakala.
   - Catalog'u parse et (bir satırlık bullet'lar: `- name_here`).
   - `.gd` dosyalarında CamelCase signal'lar ve event key olarak kullanılan `lower_snake_case` literal'ları tara.
   - Heuristic muhafazakar olsun — false positive sıfıra yakın.
   - Guard şu anki repo'da geçsin (`w0_05` önce koşmalı yoksa `turn_phase_resolved` / `BossPhaseChanged` üzerinde hemen patlar).

2. **Stale-wrapper guard:** tek `return` veya tek call'la başka public API'ye delegate eden, repo içinde sıfır caller'ı olan wrapper'ları yakala.
   - AST veya regex ile tespit.
   - Grep cross-check.
   - In-file allowlist comment: `# validator:stale_wrapper_allow`.

**Non-goals:** `RUNTIME_RUNSTATE_COMPATIBILITY_PATTERNS` / `TEST_RUNSTATE_INVENTORY_COMPATIBILITY_PATTERNS`'e dokunma; yeni guard'ı tatmin etmek için production kod değişikliği (önce `w0_05` + `w1_01`).

**Report format:** yeni guard adları; catalog-drift guard'ın bildiği isim seti; stale-wrapper allowlist comment syntax'ı; validator sonucu; full-suite sonucu.

### W1-09 — gate_warden retire (D-046)

- mode: Fast Lane
- scope: `gate_warden` adlı her `ContentDefinitions/` tanımı, referans veren test fixture, `.gd` grep hit'i, `HANDOFF.md`/`DECISION_LOG.md` cross-reference, `Assets/` altında sadece `gate_warden` için olan her asset
- do not touch: başka enemy definition; boss sistemi; `gate_warden` dışı stage/key/encounter; save shape
- validation budget: `py -3 Tools/validate_architecture_guards.py`; `py -3 Tools/validate_content.py`; `Tools/run_godot_full_suite.ps1`
- doc policy: D-046; content retirement, reservation değil.

**Görev:**
1. Repo'da `gate_warden`'ı (case-sensitive) grep'le, tüm hit'leri listele. Beklenen yüzeyler: content JSON, testler, scene node'ları, dokümanlar.
2. Her hit için:
   - Content definition veya tek amacı `gate_warden` yüzeyi olan dosya → sil.
   - Büyük dosya içinde referans → temiz kaldır; `TODO` bırakma.
   - Test içinde → retired ID'ye bağımlılığı kaldır; test trivial kalırsa sil.
3. `Assets/` altında sadece `gate_warden` için olan asset varsa onu + `.import` / `.uid` kardeşlerini aynı patch'te sil.
4. Kaldırmadan sonra tekrar grep, sıfır hit doğrulaması.

**Non-goals:** content'i reserved klasöre arşivle; replacement boss getirme; boss pipeline değişikliği (escalate-first); `GDD.md` dokunma (orada `gate_warden` geçmiyorsa).

**Report format:** before-grep listesi + her hit için disposition (removed / reference removed / test updated / asset removed); final grep sıfır hit; validator + content validator + full suite.

**Batch 3 exit:** Full suite yeşil. Her prompt için ayrı commit atılabilir.

---

## BATCH 4 — Yapı temizliği (7 prompt, Guarded)

### W2-01 — NodeResolve live fallback contract alignment (B-2, D-041)

- mode: Guarded Lane
- scope:
  - doc: `Docs/GAME_FLOW_STATE_MACHINE.md`, `Docs/MAP_CONTRACT.md`
  - kod: `Game/Application/game_flow_manager.gd`, `Game/Application/run_session_coordinator.gd`, `scenes/map_explore.gd`, `scenes/node_resolve.gd`, `Game/Infrastructure/scene_router.gd`
- do not touch: save shape; flow-state families; command/event families; RunState compat accessor
- validation budget: `py -3 Tools/validate_architecture_guards.py`; `Tools/run_godot_tests.ps1 test_flow_state.gd test_phase2_loop.gd`; `Tools/run_godot_smoke.ps1`; `Tools/run_godot_full_suite.ps1`
- doc policy: D-041 verildi. Uygula — NodeResolve orchestrated transition shell only, generic runtime fallback değil. Otorite doküman aynı patch'te.

**Mevcut durum (2026-04-20):** `scenes/node_resolve.gd` 170 satır; `NodeResolve` hâlâ `run_session_coordinator.gd`, `scene_router.gd`, `map_runtime_state.gd`, `transition_shell_presenter.gd`, test'ler ve dört scene dosyasından referanslanıyor. `APP-F1`/`SCN-F7` docs ile live fallback mismatch'ini işaretliyor.

**Görev:**
1. Doc passage'larını oku.
2. Aynı patch'te:
   - Kod: `NodeResolve` bilinmeyen node kind'larına generic fallback olarak davranmasın; bilinmeyen kind mevcut flow-error path'inden loud fail etsin, sessizce `NodeResolve` üzerinden route olmasın.
   - Doc passage'larını `NodeResolve` transition shell only olarak tanımlayacak şekilde güncelle.
3. `NodeResolve` scene'inin kendisi kalsın — shell gerçek. Sadece "generic fallback" yorumu retire.
4. Signal adı / flow-state adı değiştirme. Belirsiz signal varsa raporla, dur.

**Escalate edilecekler:** yeni flow state; yeni command/event family; save-schema değişikliği.

**Report format:** doc diff; kod diff; `test_flow_state.gd` + `test_phase2_loop.gd` sonucu; smoke; full-suite; "no save shape change, no flow-state addition, no new event family".

### W2-02 — AppBootstrap raw getter narrowing (P-10)

- mode: Guarded Lane
- scope: `Game/Application/app_bootstrap.gd`, `AppBootstrap`'tan raw runtime reference okuyan `scenes/*.gd`
- do not touch: `Game/RuntimeState/*`; save shape; flow-state family; command/event family
- validation budget: `py -3 Tools/validate_architecture_guards.py`; `Tools/run_godot_smoke.ps1`; `Tools/run_godot_full_suite.ps1`
- doc policy: narrowing `AGENTS.md` Risk Map'teki `app_bootstrap.gd` okumasını değiştirirse aynı patch'te `AGENTS.md` güncelle.

**Görev:**
1. Scene'leri `AppBootstrap.` raw getter kullanımı için grep'le. Her hit:
   - Scene'in application surface yerine runtime owner (RunState, InventoryState, MapRuntimeState vb.) çektiğini teyit et.
   - Okumayı mevcut narrow application surface'e (`RunSessionCoordinator`, `GameFlowManager` vb.) çevir.
2. `AppBootstrap` yeni convenience getter almayacak. Scene yeni getter olmadan daraltılamıyorsa dur ve raporla — getter ekleme (AGENTS.md non-negotiable).
3. Composition-only intent: scene layer runtime truth benimsemesin.

**Escalate edilecekler:** yeni `AppBootstrap` methodu; yeni `RunState` compat accessor (D-042 freeze); source-of-truth ownership taşıma.

**Report format:** scene edit listesi; before path / after path; `AppBootstrap` net-eklenen method sayısı sıfır doğrulaması; validator + smoke + full suite.

### W2-03 — Application error handling standardı (P-11)

- mode: Guarded Lane
- scope: `Game/Application/run_session_coordinator.gd`, `Game/Application/app_bootstrap.gd`, `Game/Application/combat_flow.gd`, `Game/Application/save_runtime_bridge.gd`, `Game/Application/game_flow_manager.gd`
- do not touch: `Game/RuntimeState/*`; save shape; command/event catalog; W2-01 NodeResolve narrowing (ayrı patch)
- validation budget: `py -3 Tools/validate_architecture_guards.py`; targeted flow/save/combat testleri; `Tools/run_godot_full_suite.ps1`
- doc policy: shared helper gerekirse `Docs/ARCHITECTURE.md` içinde tek kez kaydet; aksi halde otorite değişikliği yok.

**Görev:**
1. Beş dosyanın invalid-state/error path'lerini envanterle (`APP-F4`).
2. Zaten en az iki dosyada görünen bir idiom seç; diğer üçünü ona converge et. Yeni idiom icat etme.
3. Davranış birebir korunsun: happy path'te aynı control flow, error path'te aynı observable error (log line / signal / return value).
4. `combat_flow.gd` validator line cap'inde (764 / 764). Standardization bir dosyayı cap'in üzerine çıkarıyorsa dur — extraction gerekir, bu patch'te scope dışı. Blocker'ı raporla.

**Escalate edilecekler:** yeni command/event family; source-of-truth ownership taşıma; beş dosyadan birinin `HOTSPOT_FILE_LINE_LIMITS` cap'ini aşması.

**Report format:** seçilen idiom + neden (tek cümle); dosya başına diff; validator + targeted test + full suite; beş dosyanın before/after line count'u.

### W2-04 — Scene theme/layout konsolidasyon finish (P-12)

- mode: Guarded Lane
- scope: `scenes/*.gd`, `Game/UI/scene_layout_helper.gd`, `Game/UI/temp_screen_theme.gd`, `Game/UI/scene_audio_players.gd`
- do not touch: `Game/RuntimeState/*`; save shape; command/event catalog
- validation budget: `py -3 Tools/validate_architecture_guards.py`; `Tools/run_portrait_review_capture.ps1`; scene isolation `map_explore.tscn` + `combat.tscn`; `Tools/run_godot_full_suite.ps1`
- doc policy: theme helper public API değişirse `Docs/VISUAL_AUDIO_STYLE_GUIDE.md` güncelle.

**Görev:**
1. Hâlâ theme/layout/audio'yu duplicate eden 11 scene function'ı belirle (`SCN-F3`, `UI-F4`, `UI-F5`).
2. Her birini mevcut sorumluluğu sahiplenen helper'a çevir. Hiçbiri temiz owner değilse dur ve raporla.
3. Portrait capture'da görsel çıktı birebir korunsun. Herhangi pixel diff rapora gerekçesiyle girmeli; sürpriz pixel diff fail sayılır.
4. Scene'ler gameplay truth benimsemesin.

**Escalate edilecekler:** yeni UI autoload; scene'in gameplay truth sahiplenmesi.

**Report format:** 11 scene function ve yönlendirildikleri helper; portrait-capture diff özeti; scene isolation + full suite; her dokunulmuş dosya için line count before/after.

### W2-05 — Inventory panel post-render traversal hotspot kaldır (P-13)

- mode: Guarded Lane
- scope: `Game/UI/run_inventory_panel.gd`, `Game/UI/inventory_card_factory.gd`, `scenes/combat.gd`, `scenes/map_explore.gd`
- do not touch: `Game/RuntimeState/*`; save shape; command/event catalog
- validation budget: `py -3 Tools/validate_architecture_guards.py`; `Tools/run_godot_tests.ps1 test_inventory_card_interaction_handler.gd test_button_tour.gd test_phase2_loop.gd`; scene isolation `map_explore.tscn` + `combat.tscn`; `Tools/run_godot_full_suite.ps1`
- doc policy: optimization-only; caching semantics adlandırılması gerekmedikçe otorite değişikliği yok.

**Görev:**
1. Her render'da koşan per-card traversal site'larını bul (`SCN-F4`, `SCN-F5`).
2. Şununla değiştir:
   - kart construction'da cached lookup, veya
   - tek outer traversal — child'lara veriyi ver; her child yukarı yürümesin.
3. Davranış birebir. `test_phase2_loop.gd` fail olursa regression, refactor değil.
4. `scenes/combat.gd` 1184 (cap 1200). Cap'i aşma; aşacaksa önce extraction gerekir (scope dışı).

**Escalate edilecekler:** dört dosyadan birinin cap aşması; yeni runtime-state field; yeni event family.

**Report format:** callsite başına diff; mümkünse frame-time before/after (değilse qualitative note); targeted test + scene isolation + full suite; dört dosya için line count.

### W2-06 — Portrait density/theme rhythm/accessibility floor merkezi (P-14)

- mode: Guarded Lane
- scope: `Game/UI/combat_scene_ui.gd`, `Game/UI/map_explore_scene_ui.gd`, `Game/UI/safe_menu_overlay.gd`, `Game/UI/temp_screen_theme.gd`, `Game/UI/inventory_card_factory.gd`, `Game/UI/run_status_strip.gd`; isteğe bağlı tek yeni helper (`Game/UI/` altı)
- do not touch: `Game/RuntimeState/*`; save shape; content definitions; `ASSET_PIPELINE.md`
- validation budget: `py -3 Tools/validate_architecture_guards.py`; portrait captures; scene isolation `map_explore.tscn` + `combat.tscn`; `Tools/run_godot_full_suite.ps1`
- doc policy: yeni constants owner yaratılırsa `Docs/VISUAL_AUDIO_STYLE_GUIDE.md`'ye tek paragraf: owner + topic.

**Görev:**
1. Altı dosyada tekrar eden portrait density / theme rhythm / accessibility floor literal'larını listele (`UI-F4..UI-F7`).
2. Her literal'i seçilen owner dosyasındaki tek named constant'a yönlendir.
3. Görünür değeri değiştirme. Visual diff rapora gerekçesiyle girmeli.
4. Accessibility floor (min font, min tap target) mevcut garantisini korusun — bu patch'te sıkılaştırma yok.

**Escalate edilecekler:** yeni UI autoload; constant'ın UI'dan runtime ownership'e flip etmesi.

**Report format:** constants listesi source/target ownership ile; dosya başına diff; portrait-capture diff; full-suite; altı dosya + opsiyonel yeni owner için line count.

### W2-07 — SceneRouter overlay contract sertleştir (P-15)

- mode: Guarded Lane
- scope: `Game/Infrastructure/scene_router.gd`, scene-specific string ile overlay açan her scene method; overlay contract otorite dokümanda tanımlıysa `Docs/GAME_FLOW_STATE_MACHINE.md`
- do not touch: `Game/RuntimeState/*`; save shape; flow-state families; command/event families
- validation budget: `py -3 Tools/validate_architecture_guards.py`; `Tools/run_godot_tests.ps1 test_flow_state.gd test_phase2_loop.gd`; `Tools/run_godot_smoke.ps1`; `Tools/run_godot_full_suite.ps1`
- doc policy: overlay contract otorite doc'taysa aynı patch'te güncelle.

**Görev:**
1. `scene_router.gd` overlay opener'larındaki scene-specific string choreography'yi `scene_router.gd` içinde yaşayan typed enum / const set ile değiştir.
2. Her scene callsite typed path'e güncellensin. `scenes/` altında string-based overlay key kalmasın.
3. Overlay rename etme — typed isimler mevcut string isimleri birebir yansıtsın.
4. Yeni command/event family gerekirse dur ve escalate.

**Escalate edilecekler:** yeni flow state; yeni event family.

**Report format:** typed-enum / const declaration final; güncellenen scene callsite listesi; flow/phase2 test; smoke + full suite.

**Batch 4 exit:** Full suite + scene isolation yeşil. Her Guarded prompt kendi commit'i.

---

## BATCH 5 — Escalate-first (1 prompt)

### W3-01 — MapRuntimeState extraction (E-1)

- mode: Escalate-First
- scope: `Game/RuntimeState/map_runtime_state.gd` + `Docs/MAP_RUNTIME_STATE_EXTRACTION_PLAN.md` planındaki helper dosyaları
- do not touch: save shape (owner-preserving extraction); command/event families; NodeResolve narrowing (W2-01); RunState compat accessor
- validation budget: full suite + map-specific testler + `scenes/map_explore.tscn` scene isolation + smoke
- doc policy: `Docs/MAP_CONTRACT.md` ve extraction plan aynı patch. Plan `Docs/` altında otorite, `Docs/Promts/` altında değil.

**Escalate-first (kod yazmadan önce cevapla):**
- `touched owner layer`: RuntimeState (owner-preserving extraction)
- `authority doc`: `Docs/MAP_CONTRACT.md`, `Docs/MAP_RUNTIME_STATE_EXTRACTION_PLAN.md`
- `impact: runtime truth / save shape / asset-provenance`: runtime-internal only; save shape değişmemeli (roundtrip zorunlu)
- `minimum validation set`: `py -3 Tools/validate_architecture_guards.py`; `Tools/run_godot_tests.ps1 test_map_runtime_state.gd test_map_explore_presenter.gd test_flow_state.gd`; `scenes/map_explore.tscn` scene isolation; full suite; save roundtrip testi

Dürüst cevap flow/save shape/source-of-truth ownership değişikliği ima ediyorsa dur ve raporla.

**Görev:**
1. `Docs/MAP_RUNTIME_STATE_EXTRACTION_PLAN.md` oku. W0-06 duplicate'i silmediyse önce onu koş.
2. Planı adım adım uygula. Her extracted module aynı owner'ı korusun — `MapRuntimeState` delegate eder, caller'lar hâlâ `MapRuntimeState` üzerinden geçer.
3. Her adım sıradaki başlamadan önce suite'i yeşil bırakmalı. Yapamıyorsa dur, blocker'ı raporla.
4. Extraction sonrası `map_runtime_state.gd` şu anki `HOTSPOT_FILE_LINE_LIMITS` cap'inin (2397) altına görünür headroom ile düşsün. Cap'i yeni baseline'a göre aynı patch'te güncelle.
5. Save roundtrip: dump, quit, reload. Reloaded map-runtime payload pre-dump payload ile field-for-field eşit. Diff'i raporla.

**Non-goals:** persisted field değişikliği; ownership'i yeni autoload'a taşıma; hamlet phase-split redesign (D-043 / W1-05); yeni event family.

**Report format:** escalate-first statement (dört cevap) ilk section; adım adım extraction log + adım sonrası line count; save roundtrip diff; final line count (`map_runtime_state.gd` + her yeni helper); validator cap update; full suite + scene isolation.

**Batch 5 exit:** Save roundtrip eşit; suite yeşil; cap güncellendi. Ayrı commit.

---

## BATCH 6 — Opsiyonel polish (2 prompt)

### W4-01 — Compact UI accessibility polish (O-1)

- mode: Fast Lane, evidence-gated
- scope: `Game/UI/inventory_card_factory.gd`, `Game/UI/run_status_strip.gd`, `Game/UI/safe_menu_overlay.gd`
- do not touch: `Game/RuntimeState/*`; save shape; content definitions
- validation budget: portrait captures; scene isolation `map_explore.tscn` + `combat.tscn`; behavior dokunulduysa `Tools/run_godot_full_suite.ps1`
- doc policy: pass accessibility floor'u yükseltiyorsa `Docs/VISUAL_AUDIO_STYLE_GUIDE.md` aynı patch'te.

**Görev:**
1. Üç dosyada accessibility floor (min font, min tap target, contrast) için pass (`UI-F6`, `UI-F7`).
2. Sadece portrait-capture delilli değişiklikler. Floor zaten karşılanıyorsa "no change required" raporla ve o dosya için dur.
3. Değişiklik önerilirse visually minimal — polish pass, redesign değil.

**Non-goals:** theme rhythm constants taşıma (W2-06); yeni style helper; string değişikliği.

**Report format:** dosya başına "no change required" veya değişen floor listesi; portrait-capture evidence; behavior dokunulduysa full-suite.

### W4-02 — Tooling hijyen pass (O-2)

- mode: Fast Lane
- scope: `Tools/validate_content.py`, `Tools/` altına ait local cache artifact'ları, `Tools/*.py` stale helper yorumları, `Tools/` altında veya yanında runner doc'ları
- do not touch: `.gd` kodu; content definition; `ContentDefinitions/*`; runner komut string'i değişmediyse otorite doc
- validation budget: `py -3 Tools/validate_architecture_guards.py`; `py -3 Tools/validate_content.py`; gerektikçe tool-specific validator'lar
- doc policy: runner komut yüzeyi değiştiyse `Docs/TECH_BASELINE.md`. Runner komutları `README.md`'ye yazma (DOC_PRECEDENCE).

**Görev:**
1. `Tools/validate_content.py` için dead branches, stale helper yorumları, unreachable allowlist'ler (`MAINT-F5`, `MAINT-F9`).
2. Dead code'u kaldır; logic rewrite etme; output format birebir kalsın.
3. Runner doc'ları audit'le. Stale komut string'i varsa düzelt; yoksa "no change required".
4. Local cache artifact'larını yalnızca yanlışlıkla repo'ya check-in edilmişlerse temizle; yeni ignore rule eklemem.

**Non-goals:** `Tools/validate_content.py` structure rewrite; yeni validator rule; `README.md` düzenleme.

**Report format:** dosya başına dead code removed; runner doc edits; validator + content validator sonucu; "no production code changed, no content file changed".

**Batch 6 exit:** Q2 kapandı. LONG_TERM_ROADMAP Faz A bitti, Faz B (big-file extraction → `BIG_FILE_QUEUE.md`) açılabilir.

---

## 2. Hızlı referans — Codex'e komut şablonu

```
Oku: Docs/Promts/Q2_PLAYBOOK.md — sadece "## W1-02" bölümünü uygula. O bölümdeki validation budget yeşil olmadan başka bölüme geçme. Report format'ını birebir takip et.
```

---

## 3. Kesin bilgi / varsayım

- **Kesin** (canlı repo 2026-04-20): 25 prompt içeriği, batch sıralaması, W1-01'deki iki stale wrapper (`transition_to`, `is_supported_save_state_now`), catalog drift sayıları (`turn_phase_resolved` 6 kullanım, `BossPhaseChanged` 9 kullanım), `scenes/node_resolve.gd` 170 satır, `map_runtime_state.gd` cap 2397.
- **Varsayım:** Her prompt'un ilk denemede yeşil kalması; gerçekte bazı Guarded prompt'lar escalate'e evrilebilir — prompt kendi içinde bunu yakalıyor.

---

## 4. Bu dosya nasıl güncel tutulur

- Bir W bölümü uygulandığında başlığa `[DONE]` ekle veya bölümü sil.
- Q2 bittiğinde bu dosyayı `Docs/Promts/Archive/Q2_PLAYBOOK_FINAL.md`'ye taşı, yeni Q kuyruğu için yenisini yaz.
