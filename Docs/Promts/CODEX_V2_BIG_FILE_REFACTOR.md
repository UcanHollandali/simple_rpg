# Codex V2 — Büyük Dosya Refactor Micro-Patch Listesi

Son güncelleme: 2026-04-19
Hedef: Önceki turlarda iki kez prompt verilmesine rağmen değişmeyen **1000+ satırlık hotspot dosyaları** parça parça, küçük ve odaklı micro-patch'lerle refactor etmek.

## `Kesin bilgi` — Durum Teşhisi

İki prompt turundan sonra hâlâ büyük kalan dosyalar:

| Dosya | Satır | Tur 1 sonucu | Tur 2 sonucu | Kök neden |
|---|---|---|---|---|
| `Game/RuntimeState/map_runtime_state.gd` | 2397 | değişmedi | rapor-only (A1) | **High-risk escalate-first** — AGENTS.md açık izin gerektiriyor |
| `Game/UI/map_board_composer_v2.gd` | 1258 | değişmedi | değişmedi | Yeni hotspot, önceki promptlarda spesifik plan yoktu |
| `scenes/combat.gd` | 1098 | 1826 → 1099 (kısmi) | 1099 → 1098 | Ek extraction marjinal değer, doygunluk noktası yakın |
| `Game/Application/inventory_actions.gd` | 1087 | değişmedi | değişmedi | Command family ayrımı net değildi |
| `Game/RuntimeState/inventory_state.gd` | 1060 | cache pass oldu | değişmedi | **High-risk escalate-first** |
| `Game/Application/run_session_coordinator.gd` | 1018 | değişmedi | değişmedi | Orkestrasyon parçalı; tek prompt'ta çıkarmak zor |
| `Game/UI/map_route_binding.gd` | 980 | değişmedi | değişmedi | UI helper, binding çeşidi karışık |
| `Game/RuntimeState/support_interaction_state.gd` | 976 | değişmedi | değişmedi | **High-risk escalate-first** |
| `scenes/map_explore.gd` | 905 | 975 → 905 (hafif) | 905 | Doygunluk noktası yakın |

**`Kesin bilgi` neden iki tur başarısız oldu:**

1. **High-risk dosyalar** için (`map_runtime_state`, `inventory_state`, `support_interaction_state`) Codex doğru davranış gösterdi — AGENTS.md "Escalate-First Lane" kuralı sebebiyle dokunmadı. Bu bir hata değil, **kural gereği**.
2. **Medium-risk dosyalar** için (`map_board_composer_v2`, `inventory_actions`, `run_session_coordinator`, `map_route_binding`) önceki promptlar çok kapsamlı / belirsizdi. Codex ya tek oturumda 1000+ satırlık refactoru tamamlayamadı ya da nereden başlayacağını seçemedi.

**Çözüm:** Her dosya için **önce plan (report-only)**, **sonra 2-4 micro-patch** (her biri tek bir sorumluluk grubunu çıkarır, 150-300 satırlık dar iş).

## Lane Sınıflandırması

| Dosya | Lane | Bu dosyada işlem |
|---|---|---|
| `map_board_composer_v2.gd` | Guarded | Plan + 4 micro-patch HAZIR |
| `inventory_actions.gd` | Guarded | Plan + 4 micro-patch HAZIR |
| `run_session_coordinator.gd` | Guarded | Plan + 3 micro-patch HAZIR |
| `map_route_binding.gd` | Guarded | Plan + 3 micro-patch HAZIR |
| `combat.gd` | Guarded | Opsiyonel (doygunluk noktası yakın); plan-only |
| `map_explore.gd` | Guarded | Opsiyonel; plan-only |
| `map_runtime_state.gd` | **High-risk ESCALATE** | Escalate prompt HAZIR (karar gerek) |
| `inventory_state.gd` | **High-risk ESCALATE** | Escalate prompt HAZIR (karar gerek) |
| `support_interaction_state.gd` | **High-risk ESCALATE** | Escalate prompt HAZIR (karar gerek) |

## Ortak Promptlama Kuralları

Her micro-patch için Codex'e ver:

```
ROL: Godot 4 + typed GDScript Simple RPG mühendisisin.
KURAL:
- AGENTS.md risk lane disiplini.
- Tek sorumluluk grubu çıkarılacak; BAŞKA bir extraction'a girme.
- Davranış AYNI kalsın; sadece kod şekli değişir.
- Public API yüzeyi eski çağıranlar için GERİYE UYUMLU kalsın.
- 500+ satır hedefine inmek şart değil; tek dar kazanç önemli.
DOĞRULAMA: py -3 Tools/validate_architecture_guards.py + ilgili targeted test +
powershell -File Tools/run_godot_full_suite.ps1
```

Her micro-patch SONUNDA:
1. Etkilenen dosyaların yeni satır sayısı.
2. Eklenen yeni dosyaların satır sayısı.
3. Test sonuçları (PASS listesi).
4. Değişmeyen public API listesi (geriye uyum kanıtı).

---

## MBC — `map_board_composer_v2.gd` (1258 satır, Guarded)

### Prompt MBC-0 — Extraction Planı (REPORT-ONLY)

```
(genel kural özeti)
GÖREV: REPORT-ONLY. Game/UI/map_board_composer_v2.gd dosyasını analiz et.
Docs/Promts/MAP_BOARD_COMPOSER_V2_EXTRACTION_PLAN.md yaz.

İÇERİK:
1. Sembol/fonksiyon tablosu (fn adı, satır aralığı, kısa açıklama).
2. Sorumluluk grupları (tahmin: trail geometry, node placement, canopy/forest,
   fallback layout, board follow/camera). Doğrula veya güncelle.
3. Her grup için:
   - önerilen yeni dosya path
   - public API yüzeyi
   - grup içi private helper'lar
   - kalan composer dosyasıyla arayüz
4. Her grup için effort tahmini (S/M/L) ve bağımsızlık skoru (0-3).
5. Önerilen sıra: en bağımsız önce, en girift en son.
6. Risk notları: board follow/camera grup gameplay-presentation sınırına
   yakın olabilir; dikkatli bölünmesi gerekir.

DOKUNMA: map_board_composer_v2.gd ve map_runtime_state.gd KOD YOK.
BAŞARI: Plan dosyası live; 4 micro-patch için sağlam temel.
```

### Prompt MBC-1 — Trail Geometry Helper extraction

```
(genel kural özeti)
GÖREV: map_board_composer_v2.gd içinden SADECE "trail geometry" sorumluluğunu
yeni bir helper'a taşı.

HEDEF DOSYA: Game/UI/map_board_trail_geometry.gd (yeni)

KAPSAM:
- Trail/path koordinat hesaplaması
- Edge geometry curve builder'lar
- Trail decoration placement
- SADECE bu grup; başka hiçbir grubu TAŞIMA.

ADIMLAR:
1. MBC-0 planındaki trail geometry fonksiyonlarını taşı.
2. Helper'a geçilecek parametreleri minimum tut (seed, graph, bounds).
3. composer tarafı helper'ı static class_name olarak çağırsın.
4. Eski public API'ler composer üzerinde koruma amaçlı wrapper olarak KAL.
   Sadece 0-caller olanları sil.

DOĞRULAMA:
- py -3 Tools/validate_architecture_guards.py
- powershell -File Tools/run_godot_scene_isolation.ps1 -ScenePath scenes/map_explore.tscn
- powershell -File Tools/run_godot_full_suite.ps1
- portrait capture varsa çalıştır; visual regression KONTROL ET.

DOKUNMA:
- map_runtime_state.gd YOK.
- Başka composer sorumluluğu grubuna YOK.

BAŞARI:
- composer dosyası yeni satır sayısı raporlandı.
- trail_geometry.gd yeni dosya, dar public API ile live.
- Visual regression yok.
```

### Prompt MBC-2 — Node Placement Helper extraction

```
(genel kural özeti)
GÖREV: MBC-1 tamamlandıysa, map_board_composer_v2.gd içinden "node placement"
sorumluluğunu çıkar.

HEDEF DOSYA: Game/UI/map_board_node_placer.gd (yeni)

KAPSAM:
- Graph node -> board pozisyon hesaplama
- Node scatter/jitter
- Start/boss konumlandırma özel kuralları

ADIMLAR: MBC-1 pattern'i aynı.

DOKUNMA: map_runtime_state.gd YOK.
BAŞARI: Yeni helper live; composer daha küçük; visual regression yok.
```

### Prompt MBC-3 — Canopy / Forest Composition extraction

```
(genel kural özeti)
GÖREV: MBC-2 tamamlandıysa, map_board_composer_v2.gd içinden "canopy /
forest decoration composition" sorumluluğunu çıkar.

HEDEF DOSYA: Game/UI/map_board_canopy_composer.gd (yeni)

KAPSAM:
- Forest clump placement
- Canopy decoration seeding
- Tree/bush variation logic

ADIMLAR: MBC-1 pattern'i aynı.

DOKUNMA: trail/node placement helperlarına YOK.
BAŞARI: Yeni helper live; composer 700 satır altına düşerse bonus.
```

### Prompt MBC-4 — Fallback Layout extraction (opsiyonel, en son)

```
(genel kural özeti)
GÖREV: MBC-3 tamamlandıysa, kalan "fallback layout / emergency slot" kodunu
çıkar. Bu grup küçükse opsiyonel — MBC-0 planında "fallback" grubu marjinal
ise BU PROMPTU ATLAYABILIRSIN.

HEDEF DOSYA: Game/UI/map_board_fallback_layout.gd (yeni)

BAŞARI: composer <= 600 satır (hedef; şart değil).
```

---

## INV — `inventory_actions.gd` (1087 satır, Guarded)

### Prompt INV-0 — Extraction Planı (REPORT-ONLY)

```
(genel kural özeti)
GÖREV: REPORT-ONLY. Game/Application/inventory_actions.gd dosyasını analiz et.
Docs/Promts/INVENTORY_ACTIONS_EXTRACTION_PLAN.md yaz.

İÇERİK:
1. Sembol/fonksiyon tablosu.
2. Command family grupları (tahmin: equip/unequip, reorder/swap, use/consume,
   attach/detach mod, grant/reward routing, drop/discard). Doğrula.
3. Her command family için:
   - önerilen yeni dosya path (Game/Application/inventory_actions_*.gd
     veya policy altına)
   - public API (mevcut caller'ların aynen çağırabilmesi için)
   - RuntimeState ile arayüz (InventoryState'e yazma noktaları)
4. Command family'leri bağımsızlık skoruna göre sırala.
5. Risk: InventoryState ownership; bu dosya YAZMA noktalarını değiştirmeyecek,
   sadece ORGANIZE edecek.

DOKUNMA: InventoryState, RunState, SaveService YOK.
BAŞARI: Plan dosyası live; 3-4 micro-patch için temel.
```

### Prompt INV-1 — Equip / Unequip command family extraction

```
(genel kural özeti)
GÖREV: inventory_actions.gd içinden SADECE equip/unequip command family'sini
çıkar.

HEDEF DOSYA: Game/Application/inventory_actions_equip.gd (yeni)

KAPSAM:
- equip_weapon, unequip_weapon (varsa)
- equip_shield, equip_offhand
- equip_armor, equip_belt
- attach_shield_mod, detach_shield_mod (eğer equip grubunda kabul edilirse)
- SADECE equip/unequip; use/reorder/grant HARİÇ.

ADIMLAR:
1. Command function'ları yeni dosyaya taşı.
2. inventory_actions.gd orijinal public isimleri yeni dosyaya delegate eden
   wrapper olarak KORUSUN (geri uyum).
3. InventoryState'e yazma shape'i AYNI kalsın.

DOĞRULAMA:
- py -3 Tools/validate_architecture_guards.py
- powershell -File Tools/run_godot_tests.ps1 test_inventory_actions.gd
  test_inventory_state.gd test_combat_spike.gd
- powershell -File Tools/run_godot_full_suite.ps1

DOKUNMA: InventoryState write API YOK; save shape YOK.
BAŞARI: Yeni dosya live; eski caller'lar aynen çalışıyor; testler PASS.
```

### Prompt INV-2 — Reorder / Swap command family extraction

```
(genel kural özeti)
GÖREV: INV-1 tamamlandıysa, reorder/swap command family'sini çıkar.

HEDEF DOSYA: Game/Application/inventory_actions_reorder.gd (yeni)

KAPSAM:
- backpack slot reorder
- hand swap
- mod/attachment swap

ADIMLAR: INV-1 pattern'i aynı.
DOKUNMA: equip/unequip dosyasına YOK.
BAŞARI: Yeni dosya live; testler PASS.
```

### Prompt INV-3 — Use / Consume command family extraction

```
(genel kural özeti)
GÖREV: INV-2 tamamlandıysa, use/consume command family'sini çıkar.

HEDEF DOSYA: Game/Application/inventory_actions_use.gd (yeni)

KAPSAM:
- consumable kullanımı (combat ve map modunda)
- quest cargo kullanımı
- passive item pasif etkileri HARİÇ (policy dosyasında zaten olmalı)

ADIMLAR: INV-1 pattern'i aynı.
DOKUNMA: equip/reorder dosyalarına YOK.
BAŞARI: Yeni dosya live; combat + map use path'leri bozulmamış.
```

### Prompt INV-4 — Grant / Reward routing extraction (opsiyonel)

```
(genel kural özeti)
GÖREV: INV-3 tamamlandıysa, grant_item / reward routing'i çıkar.

HEDEF DOSYA: Game/Application/inventory_actions_grant.gd (yeni)

BAŞARI: inventory_actions.gd <= 400 satır (hedef).
```

---

## RSC — `run_session_coordinator.gd` (1018 satır, Guarded)

### Prompt RSC-0 — Extraction Planı (REPORT-ONLY)

```
(genel kural özeti)
GÖREV: REPORT-ONLY. Game/Application/run_session_coordinator.gd analizi ve
Docs/Promts/RUN_SESSION_COORDINATOR_EXTRACTION_PLAN.md.

İÇERİK:
1. Sembol/fonksiyon tablosu.
2. Orkestrasyon grupları (tahmin: movement resolution, roadside interruption
   continuation, pending screen orchestration, save/load bridge forwarding,
   node entry dispatch). Doğrula.
3. Her grup için yeni dosya path önerisi ve bağımsızlık skoru.
4. HANDOFF uyarısı: bu dosya "movement resolution owner + pending screen
   orchestration" demiş; bu ownership AYNI kalmalı — extraction sadece
   organize eder, owner move yapmaz.

DOKUNMA: MapRuntimeState, InventoryState, SaveService YOK.
BAŞARI: Plan dosyası live.
```

### Prompt RSC-1 — Movement Resolution extraction

```
(genel kural özeti)
GÖREV: RSC-0 planına göre movement resolution logic'i çıkar.

HEDEF DOSYA: Game/Application/run_session_movement.gd (yeni)

KAPSAM:
- next node validation
- travel cost application (varsa)
- movement result dispatch

DOĞRULAMA:
- py -3 Tools/validate_architecture_guards.py
- powershell -File Tools/run_godot_tests.ps1 test_flow_state.gd
  test_phase2_loop.gd test_map_runtime_state.gd
- powershell -File Tools/run_godot_smoke.ps1
- powershell -File Tools/run_godot_full_suite.ps1

DOKUNMA: MapRuntimeState YOK; owner move YOK.
BAŞARI: Yeni dosya live; movement orchestration ownership run_session_coordinator
üzerinde kalıyor (sadece kod organize edildi).
```

### Prompt RSC-2 — Roadside Interruption Continuation extraction

```
(genel kural özeti)
GÖREV: RSC-1 tamamlandıysa, roadside interruption continuation'ı çıkar.

HEDEF DOSYA: Game/Application/run_session_roadside.gd (yeni)

KAPSAM:
- roadside trigger resolution
- interruption suspend/resume
- destination preservation logic

DOĞRULAMA: RSC-1 testleri + test_roadside_encounter.gd (varsa).
DOKUNMA: movement extraction'a YOK; owner move YOK.
BAŞARI: Yeni dosya live; roadside interruption davranışı aynı.
```

### Prompt RSC-3 — Pending Screen Orchestration extraction

```
(genel kural özeti)
GÖREV: RSC-2 tamamlandıysa, pending screen (reward / event / support) open/
close orchestration'ı çıkar.

HEDEF DOSYA: Game/Application/run_session_pending_screens.gd (yeni)

KAPSAM:
- pending screen open dispatch
- overlay close continuation
- post-screen state resume

BAŞARI: run_session_coordinator.gd <= 500 satır (hedef).
```

---

## MRB — `map_route_binding.gd` (980 satır, Guarded)

### Prompt MRB-0 — Extraction Planı (REPORT-ONLY)

```
(genel kural özeti)
GÖREV: REPORT-ONLY. Game/UI/map_route_binding.gd analizi ve
Docs/Promts/MAP_ROUTE_BINDING_EXTRACTION_PLAN.md.

İÇERİK:
1. Sembol/fonksiyon tablosu.
2. Binding grupları (tahmin: route button binding, marker state binding,
   hover/tooltip binding, travel feedback binding). Doğrula.
3. Her grup için yeni dosya path önerisi.

DOKUNMA: map_runtime_state.gd YOK.
BAŞARI: Plan dosyası live.
```

### Prompt MRB-1 — Route Button Binding extraction

```
(genel kural özeti)
GÖREV: route button binding logic'i çıkar.

HEDEF DOSYA: Game/UI/map_route_button_binding.gd (yeni)

KAPSAM:
- route button create / destroy
- button -> node id binding
- availability state rendering

DOĞRULAMA:
- py -3 Tools/validate_architecture_guards.py
- powershell -File Tools/run_godot_scene_isolation.ps1 -ScenePath scenes/map_explore.tscn
- powershell -File Tools/run_godot_full_suite.ps1

DOKUNMA: map_runtime_state.gd YOK.
BAŞARI: Yeni dosya live; route butonu davranışı aynı.
```

### Prompt MRB-2 — Marker State Binding extraction

```
(genel kural özeti)
GÖREV: MRB-1 tamamlandıysa, marker state binding çıkar.

HEDEF DOSYA: Game/UI/map_route_marker_binding.gd (yeni)

KAPSAM:
- node marker pozisyon/state binding
- key/boss gate marker state

BAŞARI: Yeni dosya live.
```

### Prompt MRB-3 — Hover/Tooltip Binding extraction (opsiyonel)

```
(genel kural özeti)
GÖREV: MRB-2 tamamlandıysa, hover ve tooltip binding çıkar.

HEDEF DOSYA: Game/UI/map_route_hover_binding.gd (yeni)

BAŞARI: map_route_binding.gd <= 400 satır (hedef).
```

---

## Opsiyonel — `combat.gd` ve `map_explore.gd` (doygunluk noktası)

Bu iki dosya zaten Faz 3.1 ve 3.2 ile kayda değer küçüldü. Ek extraction
değer/risk oranı düşük. Sadece SPESIFIK hotspot patch'i öner:

### Prompt CMB-OPT — combat.gd kart-child traversal sıcak noktası

Bu CODEX_V2_FOLLOWUP_PROMPTS.md Prompt 2.4 (B1: P-13) ile AYNI iştir. Tekrar
yazmıyorum. O dosyayı kullan.

### Prompt MEP-OPT — map_explore.gd kart-child traversal sıcak noktası

Aynı şekilde; CODEX_V2_FOLLOWUP_PROMPTS.md Prompt 2.4 kapsamına dahildir.

---

## ESCALATE — High-Risk Dosyalar (Karar Gerek)

Bu dosyalar AGENTS.md "High-Risk Escalate-First Lane" içinde. Codex izinsiz
dokunmadı ve **haklı**. Aşağıdaki promptları Codex'e vermek yerine önce sen
karar ver.

### ESC-MRS — `map_runtime_state.gd` (2397 satır)

**Karar gereken:** Owner-preserving extraction şu an riske değer mi?

Mevcut durum:
- `Docs/Promts/MAP_RUNTIME_STATE_EXTRACTION_PLAN.md` zaten hazır (10792 bytes).
- B1 backlog'u E-1 olarak listelemiş.
- Plan, owner'ı değiştirmeden sadece dosyayı bölmeyi öneriyor.

Kararın **evet** ise Codex'e vereceğin şablon:

```
ROL: (genel kural özeti)
KURAL: High-risk escalate lane. AÇIKÇA onaylı.
Docs/Promts/MAP_RUNTIME_STATE_EXTRACTION_PLAN.md'yi ADIM ADIM uygula.
Her adımı AYRI COMMIT olarak yap; her adım sonrası:
- py -3 Tools/validate_architecture_guards.py
- powershell -File Tools/run_godot_tests.ps1 test_map_runtime_state.gd
  test_save_file_roundtrip.gd test_phase2_loop.gd
- powershell -File Tools/run_godot_full_suite.ps1
- powershell -File Tools/run_godot_smoke.ps1

Test başarısız olursa DUR; bir sonraki adıma geçme.
Owner kontratı KORUNACAK; save shape DEĞIŞMEYECEK.
```

Kararın **hayır** ise dosya olduğu gibi kalır; `Docs/HANDOFF.md` zaten
"MapRuntimeState remains the largest RuntimeState owner" diye not etmiş.

### ESC-INV — `inventory_state.gd` (1060 satır)

**Karar gereken:** Cached getter semantic hardening yapılsın mı + getter'lar
mutable cache döndürüyor (B1: E-4, ARCH-F3) — API değiştirilsin mi?

Riskler:
- Caller'lar cached array'e yazabiliyor (side effect).
- Semantic değişiklik = yüksek test yüzeyi.
- Save shape sabit; davranış değişiyor.

Kararın evet ise escalate promptu: "cached getter'ları read-only snapshot
döndürecek şekilde sertleştir; write için explicit set_* API kullan; tüm
inventory test suite PASS etmeli; save roundtrip etkilenmemeli."

### ESC-SIS — `support_interaction_state.gd` (976 satır)

**Karar gereken:** Hamlet side-quest state owner split'i (B1: E-3, RS-F3) net
owner cleanup mı, bilinçli phase split mi?

Bu karar verilmeden dosya refactor'u anlamsız çünkü ayrım bilinmiyor.

---

## Önerilen Uygulama Sırası

1. **Tur R0** — Bu dosyadaki tüm 0-prompt'ları (MBC-0, INV-0, RSC-0, MRB-0)
   paralel ver. 4 plan dosyası oluşur. `Docs/Promts/` altına düşer. **Commit.**

2. **Tur R1** — Planlar hazır olduktan sonra en bağımsız dosya ile başla.
   Muhtemelen **MBC-1** (trail geometry) — UI-only, gameplay yüzeyine
   dokunmuyor. Bitince commit.

3. **Tur R2** — MBC-2, MBC-3. Her birini ayrı oturumda ve ayrı commit'le.

4. **Tur R3** — INV-1, INV-2, INV-3 sırayla (aynı dosyayı böldüğü için
   paralel VERME).

5. **Tur R4** — RSC-1, RSC-2, RSC-3 sırayla.

6. **Tur R5** — MRB-1, MRB-2 (opsiyonel MRB-3).

7. **Tur R6** — MBC-4 ve INV-4 opsiyonel kalan parçalar.

## `Kesin bilgi` Garantileri

- Hiçbir micro-patch high-risk escalate lane'e izinsiz girmez.
- Her patch **tek sorumluluk grubu** taşır; Codex'in kalite düşmesinin önüne
  geçer.
- Public API geriye uyumlu kalır (eski caller'lar bozulmaz).
- Her patch **kendi commit'i** — problem olursa tek adım geri alınır.
- Plan-first yaklaşım: Codex önce haritayı çıkarır, sonra patch atar.

## `Varsayım` Notları

- Sorumluluk grupları tahminlere dayalı (fonksiyon listesine direkt bakılmadı
  — bu prompt seti Codex'ten plan çıkarmasını istiyor; planı doğrulayacak).
- "Satır hedefleri" (örn. MBC için <= 600) birincil değil; sorumluluk ayrımı
  sağlanırsa satır doygun kalsa da kazanç var.
- Build test süitinin çalıştığı varsayılıyor; ilgili testler yoksa Codex
  eşdeğer smoke + scene isolation ile destekler.
