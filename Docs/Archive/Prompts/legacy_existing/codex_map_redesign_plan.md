# Codex Map Redesign — Plan Overview

Bu dosya artık **companion plan / rationale** dokümanıdır.
Actionable full prompt queue `codex_map_redesign_prompts.md` içinde mevcut.
Bu dosya neden/sıra/çakışma notlarını ve global queue entegrasyonunu açıklar.

---

## 1. Mevcut Durum — Dürüst Doğrulama

Önceki AI not setinde bazı varsayımlar **güncel kodla uyuşmuyor**. Aşağıdaki tablo, o konuşmadaki iddiaları ve gerçek kod durumunu gösteriyor.

| İddia | Gerçek Kod Durumu | Doğrulama |
|---|---|---|
| "Runtime hâlâ scaffold-first, hard-coded JSON edge skeleton" | YANLIŞ. `map_runtime_state.gd` zaten procedural controlled scatter kullanıyor. `_build_controlled_scatter_adjacency()` (satır 925), `_build_scatter_profile_extra_edges()` (satır 958), `_build_controlled_scatter_family_assignments()` (satır 978) var. | Doğrulandı |
| "14 node, profile-driven (corridor/openfield/loop)" | DOĞRU. `SCATTER_NODE_COUNT = 14` (satır 22). | Doğrulandı |
| "Composer hâlâ RING_RADIUS_FACTORS + arc sabitlerine yaslanıyor" | DOĞRU. `map_board_composer_v2.gd` satır 10: `const RING_RADIUS_FACTORS := [0.0, 0.20, 0.33, 0.46, 0.58, 0.70]`. Layout görsel olarak ring-dominated. | Doğrulandı |
| "4 path family: short_straight, gentle_curve, wider_curve, outward_reconnecting_arc" | DOĞRU. Composer satır 13-16. | Doğrulandı |
| "`map_explore.gd` hâlâ slot_factors + anchor fallback zinciri var" | DOĞRU AMA NİYANSLI. Fallback emergency-only değil, normal path gibi duruyor. `slot_factors` satır 878, `BOARD_FOCUS_ANCHOR_FACTOR` satır 79. | Doğrulandı |
| "Presenter `event` family'yi `Roadside Encounter` diye mapliyor ve test bunu kilitliyor" | DOĞRU VE TEST KİLİTLİ. `map_explore_presenter.gd` satır 14. Test: `test_map_explore_presenter.gd` satır 84. | Doğrulandı |
| "Roadside encounter açılınca destination node `resolved` işaretleniyor" | DOĞRU — VE BU GERÇEK BİR GAMEPLAY BUG. `run_session_coordinator.gd` satır 321: `map_runtime_state.mark_node_resolved(target_node_id)` roadside açıldıktan sonra çalışıyor; destination content tüketiliyor. | Doğrulandı |
| "SCATTER_MAP_GENERATION_DESIGN.md Option B'yi öneriyor" | DOĞRU. Doc mevcut, Option B (Center-Start Frontier Growth With Controlled Scatter) öneriyor. | Doğrulandı |

### Buradan Çıkan Dürüst Sonuç

1. **Topoloji yarı-yolda**: Scatter isminde ama kod aslında sabit base edge list + profile extra edges karışımı. "Center-start constrained frontier growth" adıyla anılan tam model değil. Part 2 hâlâ gerekli ama amacı "scaffold'u söküp yerine scatter koymak" değil, "yarı-scatter'ı gerçek frontier growth + role-based reconnect'e taşımak."

2. **Composer ring'i gerçek** ve gerçekten presentation tarafını ring-dominated gösteriyor. Part 5 haklı.

3. **Scene fallback gerçek**. Part 6 haklı.

4. **Roadside bug gerçek ve büyük**. Part 4 en kritik gameplay fix.

5. **Presenter label gerçek ve test-kilitli**. Part 4/6 label değişikliği bilinçli test güncellemesi gerektiriyor.

---

## 2. Önceki AI Promptlarının Değerlendirmesi

8 code part + 4 asset part toplam 12 prompt. Kalite ortalamaya göre yüksek — doğru authority doc sırası, doğru stop condition disiplini, doğru "çok şey aynı anda yapma" mantığı.

### Güçlü Yanlar

- Her part kendi scope lock'u, stop condition'ı, escalation rule'u ile yazılmış.
- Save schema immutability her partta tekrarlanmış.
- Authority doc okuma zorunluluğu her partta var.
- Roadside/event semantic split ayrı bir part — doğru ayrım.
- Asset part'ları prototype-only olarak sınırlanmış (final art değil).

### Zayıf / Dikkat Edilmesi Gereken Yanlar

1. **Part 2 premise'i kısmen outdated**. "Scaffold-first topology'yi scatter'a çevir" diyor ama zaten yarı-scatter var. Prompt'u güncel duruma göre yeniden çerçevelemek lazım: "mevcut yarı-scatter'ı gerçek frontier growth'a taşı."

2. **Part 1 audit prompt'u iyi ama uzun**. Bu zaten benim bu dosyada kısaca yaptığım iş. Part 1'i yapıp yapmamak tercih — Codex'e tekrar yaptırmak daha ucuz ama redundant olabilir. Öneri: Part 1 yapılsın ama scope'u daraltılsın ("audit + truth drift inventory, fakat bu dosyadaki bulguları input olarak kullan").

3. **Part 4'ün asıl odak noktası bulanık**. İki ayrı şey yapmak istiyor:
   - **Bug fix**: Destination consumption fix (satır 321 kritik).
   - **Rename**: Planned event → "Trail Event" / "Relic Site" gibi.
   Bunlar farklı risk seviyelerinde. Öneri: Part 4'ü "roadside semantic fix + minimal rename" olarak tutalım ama bug fix'e öncelik verelim.

4. **Asset Part'ları güzel ama sıra önemli**. Prompt zaten söylüyor: Part 6 veya final'den sonra gelsin. Bunu dahil edeceğiz.

5. **"Part 8/Final" aynı anda iki iş yapıyor**: hem integration audit hem patch. Final'i daraltmak lazım — broad re-design'a kapıyı kapamak için.

### Önceki AI'nin Atladığı / Belirsiz Bıraktığı Şeyler

Aşağıdaki konular prompt'larda ya hiç yok ya muğlak:

**A) Node family count + early exposure contract'ının yeni topology ile nasıl korunacağı**
MAP_CONTRACT.md şu anda `6` non-boss combat, `1` event, `1` reward, `1` side_mission, `2` support, `1` key, `1` boss (toplam 13 + start = 14) garanti ediyor. Part 2+3 sonrası bu kontrat bozulursa save compat ve test disiplin bozulur. Part 3'te bu açıkça preserve edildiği belirtiliyor, iyi. Ama Part 2 "topology first, family assignment second" derken aynı zamanda family counts'ın korunmasını sağlayacak bir validation/repair loop'u istiyor mu? Net değil. **Part 2 prompt'una eklenmeli: family budget reservation (topology'de her family için en az bir uygun slot garantisi).**

**B) Save schema + stage profile id uyumluluğu**
Mevcut `procedural_stage_corridor_v1` / `openfield_v1` / `loop_v1` id'leri save'de yaşıyor. Part 2 topology değişikliği profile semantics'ini değiştirirse save load-back corrupt olabilir. Part 2'de "stage profile ids korunmalı" denmiş, iyi. Ama **profile'ın ne anlama geldiği (hangi topology biasi) değişirse eski save'ler aynı seed'den farklı graph üretebilir**. Bu, exact-restore için graph truth'un da save'e girdiğini hatırlatır. Part 2'de "graph truth exact-restore via saved node list/edge list" kuralını explicit yazmak gerek. (Bugün muhtemelen öyle zaten ama doğrulanması lazım.)

**C) Roadside trigger eligibility tam tanımlı değil**
Part 4 şunları dışlıyor: start, boss, key, side_mission, direct support, locked, undiscovered. Ama **planned event** node'u dışlasın mı? Prompt "strongly consider" diyor ama net karar yok. Öneri: **planned event node'larını eligibility'den dışla** — çift event olmasın.

**D) "Frequency/cap" için somut rakam yok**
Part 4 "stage quota/cap preserve or improve" diyor ama mevcut cap bilinmiyorsa hedef de bilinmez. **Part 4 audit adımında mevcut cap'i okuyup raporlasın, sonra patch yapsın.**

**E) Tests/test_phase2_loop.gd ve test_stage_progression.gd**
Bunlar flow-level testler. Roadside + family placement değişince kırılabilir. Part 4 ve Part 3'te bu testlerin güncellenmesi explicit yazılmalı.

**F) HANDOFF.md truth drift — final pass'te net kapatılmalı**
Final pass prompt'u bunu söylüyor ama `HANDOFF.md`'de "overlay popup runtime test edilmedi" notu var. Bu bu serinin kapsamında değil (combat pipeline). Final'de "bu run'da runtime test edildi mi, edilmediyse açık risk olarak bırak" denmeli.

**G) Doc precedence — değişen docs için**
Her part "en yakın authority doc'ta minimal sync" diyor ama hangi doc hangi değişiklikle? Net değil:
- Part 2 → `MAP_CONTRACT.md` + `SCATTER_MAP_GENERATION_DESIGN.md`
- Part 3 → `MAP_CONTRACT.md`
- Part 4 → yeni bir `ROADSIDE_ENCOUNTER_CONTRACT.md` gerekebilir? Yoksa `MAP_CONTRACT.md` içine bölüm?
- Part 5 → `MAP_COMPOSER_V2_DESIGN.md`
- Part 6 → `MAP_CONTRACT.md` veya `HANDOFF.md`
- Part 7 → hepsi truth drift sweep
Her part'a doc target'ı açıkça yazalım.

**H) `scenes/node_resolve.gd` veya `NodeResolve` flow state**
Önceki tur refactor planında (`codex_refactor_plan.md` Part 0) NodeResolve'in event/reward için redundant olup olmadığı sorgulanıyor. Bu map redesign serisi NodeResolve'a dokunmuyor. Bu **bilinçli bir ayrım**: map redesign topology + composer + roadside, NodeResolve ise flow routing. İkisi ayrı tracks, çakışmayacak. Ama Part 4 roadside flow'a dokunacağı için NodeResolve etkileşimini tarif etmeli.

---

## 3. Önerilen Part Yapısı (Bu Serinin)

Aşağıdaki 8 part + 4 asset part = 12 task. Her biri Codex'e tek overnight queue item olarak verilecek.

### Sequential Pipeline (Bağımlılıklar Sırayı Zorunlu Kılıyor)

| # | Part | Tip | Risk | Bağımlılık |
|---|---|---|---|---|
| 1 | Audit + Scope Lock + Stale Inventory | NO-CODE | Low | — |
| 2 | Runtime Graph Redesign | CODE (high) | HIGH | Part 1 |
| 3 | Family Placement / Role Assignment | CODE (medium) | MEDIUM | Part 2 |
| 4 | Roadside / Event Semantic Split (bug fix + rename) | CODE (medium) | HIGH (gameplay bug) | Part 3 (family counts) |
| 5 | Map Composer / Layout Redesign | CODE (low-medium) | MEDIUM | Part 2, Part 3 |
| 6 | Map Explore Scene / Presenter / UI Cleanup | CODE (low) | LOW | Part 4, Part 5 |
| 7 | Stale/Dead Cleanup + Doc Truth Sync | CODE (low) | LOW | Part 6 |
| 8 | Final Review + Audit + Patch | CODE (low) | LOW | Part 7 |
| A1 | Prototype Asset Audit + Gap Plan | NO-CODE | Low | Part 6 |
| A2 | Generate Prototype Map Kit | ASSET + MANIFEST | Low | A1 |
| A3 | Hook Kit Into Board | CODE (low) + ASSET | LOW | A2 |
| A4 | Asset Review + Manifest Sync | NO-CODE + MANIFEST | Low | A3 |

### Part Özetleri (tek paragraf; detaylı prompt karşılıkları `codex_map_redesign_prompts.md` içinde)

**Part 1 — Audit + Scope Lock + Stale Inventory** (no-code)
- Bu dosyadaki bulguları **input** olarak kullansın, tekrar tam audit yapmaya gerek yok.
- Çıktı: doğrulanmış drift envanteri + part sırası + validation plan.
- No code. Sadece rapor.

**Part 2 — Runtime Graph Redesign** (HIGH risk)
- Mevcut yarı-scatter'ı gerçek center-start frontier growth + controlled reconnect'e taşı.
- Preserve: 14 node, start adjacency 2-4, profile id'leri, family count floor, early exposure floor.
- Ekle: family budget reservation (topology'de her family için uygun slot sayısı garantisi).
- Save compat: graph truth exact-restore via saved node/edge list.
- Doc target: `SCATTER_MAP_GENERATION_DESIGN.md`, `MAP_CONTRACT.md` minimal sync.

**Part 3 — Family Placement / Role Assignment Redesign** (MEDIUM risk)
- Topology'den role scoring (`frontier_score`, `connector_score`, `optional_detour_score`, `support_branch_score`, `progress_corridor_score`) türet.
- Family'leri role'a göre yerleştir — depth sıralamasıyla değil.
- Opening support vs late support için bilinçli karar: direct-adjacency mi same-lineage bias mi?
- Preserve: tüm family count contract'ı, early exposure floor, boss/key outer bias.
- Doc target: `MAP_CONTRACT.md`.

**Part 4 — Roadside / Event Semantic Split + Bug Fix** (HIGH — gameplay bug)
- **Öncelik 1 BUG FIX**: `run_session_coordinator.gd` satır 321'deki `mark_node_resolved(target_node_id)` — roadside trigger olunca destination content consume olmasın.
- Öncelik 2: Planned event node ≠ roadside encounter. Farklı semantic, farklı label.
- Eligibility: planned event node'u da roadside trigger'ından dışla (çift event olmasın).
- Label: planned event için `Trail Event` / `Relic Site` / `Forest Shrine` / `Unknown Ruins` — birini seç ve sonraki UI rework / migration polish pass'lerine bunu yeniden seçtirme.
- Test güncellemeleri bilinçli: `test_map_explore_presenter.gd` satır 84 açıkça değişecek.
- Doc target: `MAP_CONTRACT.md` yeni bölüm veya ayrı `ROADSIDE_ENCOUNTER_CONTRACT.md`.

**Part 5 — Map Composer / Layout Redesign** (MEDIUM risk)
- `RING_RADIUS_FACTORS` + arc dominance'ı soften et.
- Graph-native branch pocket positioning (center-rooted, soft depth envelope).
- Path geometry trail-like.
- Preserve: deterministic compose, 4 path family vocabulary, save-no-layout-fields rule.
- Doc target: `MAP_COMPOSER_V2_DESIGN.md`.

**Part 6 — Scene / Presenter / UI Cleanup** (LOW risk)
- `map_explore.gd` slot_factors fallback'i: ya tamamen retire ya emergency-only olarak demote.
- Presenter label'ları yeni semantic'e göre (Part 4 sonrası).
- Board interaction (focus/hover/current-target) korunsun.
- Doc target: `HANDOFF.md` snapshot update.

**Part 7 — Stale/Dead Cleanup + Doc Truth Sync** (LOW risk)
- SAFE_DELETE_NOW kategorisindeki replaced helper/constant/branch'leri temizle.
- Doc drift sync: `MAP_CONTRACT.md`, `MAP_COMPOSER_V2_DESIGN.md`, `SCATTER_MAP_GENERATION_DESIGN.md`, `HANDOFF.md`.
- KEEP_FOR_COMPAT ve ESCALATE_FIRST_IF_REMOVED'leri dokunmadan raporla.

**Part 8 — Final Review + Audit + Patch** (LOW risk)
- Full validation stack: `validate_content.py`, `validate_architecture_guards.py`, `run_godot_full_suite.ps1`.
- Gap list → minimal patch (yeniden broad redesign açma).
- HANDOFF.md final snapshot.

**Asset Part 1 — Prototype Asset Audit + Gap Plan** (no-code)
- Mevcut asset manifest audit.
- Minimum map kit define et (canopy / clearing / trail / node plate).

**Asset Part 2 — Generate Prototype Map Kit** (SVG/PNG + manifest)
- 3 canopy, 2 clearing, 4 trail, 3 node plate, placeholder icon fix.
- `SourceArt/Generated/` + `Assets/...` + `AssetManifest/asset_manifest.csv`.

**Asset Part 3 — Hook Kit Into Board** (code-light + asset)
- Composer + scene asset binding (presentation-only).
- Emergency fallback, hidden info leak yasak.

**Asset Part 4 — Asset Review + Manifest Sync** (no-code)
- Dead temp cleanup.
- Manifest/HANDOFF final sync.

---

## 4. Mevcut Queue ile Entegrasyon

Repo'da artık dört ilişkili track var:

1. **`codex_refactor_plan.md`** — 6 part (Part 0-5): scene refactor + migration prep.
2. **`codex_ui_rework_prompts.md`** — 8 part: shared UI foundation + screen rework.
3. **`codex_map_redesign_prompts.md`** — 8 part + 4 asset part: actionable map track.
4. **`codex_migration_prompts.md`** — 13 part (Part 0-12 + bonus): gameplay migration.

Bu plan dosyası map redesign'ın yerel mantığını açıklar; global çok-track sıra için `codex_master_queue_plan.md` esas alınmalı.

Map redesign açısından kritik bağımlılıklar:

- `codex_refactor_plan.md` Part 0: NodeResolve audit. Map redesign Part 4'te roadside flow'a dokunulacağı için bu part **önce** bitmeli. Yoksa roadside fix + NodeResolve change iç içe girer.
- `codex_ui_rework_prompts.md` Part 1-3 map redesign'dan önce çalışabilir; ama UI Part 4-8 map redesign Part 8 sonrasına bırakılmalı.
- `codex_migration_prompts.md` Part 6 (Map/Node/Content routing): map redesign tamamlandıktan sonra gelsin — aksi halde migration henüz değişmekte olan bir sisteme rota koyar.

### Global Sıra İçinde Bu Track'in Yeri

```
refactor Part 0-2
ui rework Part 1-3
map redesign Part 1-8
ui rework Part 4-7
refactor Part 3-5
migration Part 0-12
ui rework Part 8
refactor Part 6
```

Asset A1-A4 alt-track'i map redesign Part 6 veya Part 8 sonrasına bırakılmalı; gameplay migration ile aynı anda açılması gerekmez.

### Alternatif: Map Redesign'ı Migration'dan Ayır

Eğer queue uzun gelirse, map redesign'ı **refactor Part 0-2 ve UI foundation Part 1-3 tamamlandıktan sonra, migration başlamadan önce** ayrı bir "map milestone" olarak çalıştırmak en güvenli seçeneklerden biridir. Böylece migration başladığında map stabil olur ve UI screen rework de settle olmuş semantiğin üstüne kurulabilir.

---

## 5. Dikkat Edilmesi Gereken Kritik Noktalar

**KRİTİK 1: Satır 321 bug fix**
`run_session_coordinator.gd` satır 321'deki `mark_node_resolved(target_node_id)` çağrısı mevcut davranışın bir parçası — kaldırıldığında tests muhtemelen kırılır. Bu testler **yanlış davranışı kilitliyor**. Part 4'te bilinçli olarak değiştirilmeli ve değiştirme sebebi commit message'da açıkça yazılmalı.

**KRİTİK 2: Presenter label test satırı**
`test_map_explore_presenter.gd` satır 84'teki `event → Roadside Encounter` assertion — Part 4 veya Part 6'da güncellenirken karar verilmeli: yeni label ne olacak? Öneri: `Trail Event` (kısa, açıklayıcı, semantic olarak doğru).

**KRİTİK 3: MAP_CONTRACT'in family counts'ı**
Part 2+3 sonrası contract floor aynı kalmalı. Herhangi bir sapma save corrupt eder. Her part'ta bu invariant check explicit.

**KRİTİK 4: Save schema immutability**
Map redesign serisi boyunca save schema'ya **hiçbir yeni alan eklenmemeli**. Layout, board position, composer output — hiçbiri save'e girmemeli. Her part bunu tekrar söylemeli.

**KRİTİK 5: Test-locked behavior değişimleri**
Aşağıdaki testler değişecek (bilinçli):
- `test_map_explore_presenter.gd` satır 84 (label)
- `test_map_runtime_state.gd` (topology metrics güçleniyorsa)
- `test_map_board_composer_v2.gd` (ring dominance zayıflıyorsa)
- `test_phase2_loop.gd` (roadside flow değişiyorsa)

Her değişiklik commit message'da "intentional test behavior change, because X" olarak belirtilmeli.

---

## 6. Onay Noktası

Bu plan ile ilerleyeceksen:

- ayrıntılı prompt karşılığı için `codex_map_redesign_prompts.md` kullan
- global sıra için `codex_master_queue_plan.md` kullan
- bu dosyayı risk/çakışma/reasoning notu olarak tut

---

## Ek — Bu Planın Yazılmasında Kullanılan Doğrulanmış Gerçekler

- `map_runtime_state.gd` satır 22: `SCATTER_NODE_COUNT = 14`
- `map_runtime_state.gd` satır 925: `_build_controlled_scatter_adjacency()`
- `map_runtime_state.gd` satır 958: `_build_scatter_profile_extra_edges()` (profile-driven edges)
- `map_runtime_state.gd` satır 978: `_build_controlled_scatter_family_assignments()`
- `map_board_composer_v2.gd` satır 10: `RING_RADIUS_FACTORS`
- `map_board_composer_v2.gd` satır 13-16: 4 path family sabitleri
- `map_explore.gd` satır 79: `BOARD_FOCUS_ANCHOR_FACTOR`
- `map_explore.gd` satır 878: `slot_factors` fallback
- `map_explore_presenter.gd` satır 14: `"event": "Roadside Encounter"`
- `test_map_explore_presenter.gd` satır 84: roadside assertion
- `run_session_coordinator.gd` satır 321: `mark_node_resolved(target_node_id)` — **bug**
- `Docs/SCATTER_MAP_GENERATION_DESIGN.md`: Option B öneriyor
- `Docs/MAP_CONTRACT.md` satır 104-112: family count contract
- `Docs/HANDOFF.md` satır 26-39: profile-driven controlled scatter note
