# SIMPLE RPG — Map Render + Asset Plan (Concrete / Implementable)

## Amaç
Bu dosya, harita tarafında **gerçekten ne çizileceğini**, **hangi asset’lerin gerekli olduğunu**, **nelerin zaten repoda bulunduğunu** ve **bundan sonra hangi küçük paketlerle ilerlenmesi gerektiğini** netleştirir.

Bu planın amacı “tek seferde final art” değildir.
Amaç:
- node graph mantığını bozmadan
- yolları graph üstünden çizip
- kalan boşlukları reusable asset kit ile doldurmak
- prototipte çalışan, upgrade edilebilir bir map board üretmektir.

---

## Repo’dan kesin bildiklerimiz

### Runtime / presentation ayrımı
- `MapRuntimeState` graph truth sahibidir: node family, node state, adjacency, current node, key/boss-gate, pending node context.
- `MapBoardComposerV2` presentation-only derived output üretir: world positions, visible trails, forest shapes.
- Save payload içinde board coordinate, spline point, decor placement tutulmaz.

### Node family seti
Canlı runtime-backed node family seti:
- `start`
- `combat`
- `event`
- `reward`
- `hamlet`
- `rest`
- `merchant`
- `blacksmith`
- `key`
- `boss`

Player-facing anlamlar:
- `event` => `Trail Event`
- `hamlet` => support-family settlement stop

### Şu an repoda canlı/bağlı map asset yüzeyleri var
- map background üçlüsü (`bg_map_far`, `bg_map_mid`, `bg_map_overlay`)
- map board backdrop (`ui_map_board_backdrop`)
- walker frame’leri (`ui_map_walker_idle`, `walk_a`, `walk_b`)
- map iconları: start, rest, merchant, blacksmith, reward, trail event, side-mission/hamlet
- graph-native board kit parçaları:
  - 3 canopy clump
  - 2 clearing decal
  - 3 node plate state
  - 4 trail family SVG

### Bu ne anlama geliyor?
Sıfırdan başlamıyoruz.
Asıl eksik olan şey:
- **eksik node icon yüzeylerini tamamlamak / aynı stile çekmek**
- **path-edge ve filler kit’i büyütmek**
- **kalan alanları dolduracak reusable map decals** üretmek
- hepsini tek parça resim gibi değil, **modüler board asset set** olarak kullanmak

---

## Bu iş nasıl çözülmeli?

Harita için doğru pipeline şu:

### Pass 1 — Graph
Önce node graph oluşur.
Burada sadece:
- node id
- node family
- node state
- adjacency
- current node
vardır.

### Pass 2 — Path / clearing composition
Composer şunları türetir:
- node world positions
- edge trail geometry
- node clearings

### Pass 3 — Environment fill
Path ve clearings belli olduktan sonra:
- canopy clumps
- path-edge filler
- clearing decals
- ground clutter
- fog/shadow patches
boş alanlara yerleşir.

**Kural:**
Graph truth runtime’da kalır.
Asset placement presentation-only kalır.

---

## Ne çizilmeyecek?
Bunları şimdi yapmaya çalışma:
- her run için tek parça büyük arka plan resmi
- node + path + forest her şeyin aynı PNG’de baked olduğu harita
- her node family için sıfırdan büyük illüstrasyon kartı
- path’i background içine gömülü final painting gibi çözmek
- full final art production

Bunlar random map mantığıyla kavga eder.

---

## Asıl gereken asset seti

Aşağıdaki liste **uygulanabilir minimum set**tir.
Amaç küçük paketlerle ilerlemek.

# 1) NODE LAYER

## 1A. Zaten repoda doğrulanmış / canlı olanlar
- `icon_map_start`
- `icon_map_rest`
- `icon_map_merchant`
- `icon_map_blacksmith`
- `icon_reward`
- `icon_map_trail_event`
- `icon_map_side_mission` (hamlet yüzeyi)
- `icon_node_marker`

## 1B. Bu turda netleştirilmesi gerekenler
Bunlar ya eksik ya da stil birliği açısından ayrı ele alınmalı:
- `combat` map icon
- `key` map icon
- `boss` map icon

## 1C. Node state / shell yüzeyi
Şu an repoda state plate seti var:
- reachable
- resolved
- locked

Bu turda sıfırdan node frame çizmek zorunlu değil.
Öncelik:
- mevcut state plate setini kullan
- ikonları tutarlılaştır
- sonra gerekirse tek ortak node shell polish yap

## Node tarafında gerçekten yapılacak iş
### Minimum gerekli üretim
1. `icon_map_combat`
2. `icon_map_key`
3. `icon_map_boss`

### İsteğe bağlı ama faydalı polish
4. `icon_map_reward` ile `icon_reward` yüzeyini tutarlılaştırma
5. `icon_map_side_mission` / hamlet icon’unu final prototype seviyesine yükseltme

---

# 2) PATH LAYER

## 2A. Zaten repoda doğrulanmış trail ailesi
- `ui_map_v2_trail_short_straight`
- `ui_map_v2_trail_gentle_curve`
- `ui_map_v2_trail_wider_curve`
- `ui_map_v2_trail_outward_reconnecting_arc`

## 2B. Buradaki problem
Sadece trail çizgisi yetmez.
Board’un “çizilmiş path” yerine “orman içi patika” gibi görünmesi için şu ara katman eksik kalır:
- path edge vegetation
- dirt-to-forest transition
- küçük kırık toprağımsı decal

## 2C. Bu turda çizilecek gerçek path destek asset’leri
1. `ui_map_v2_path_edge_filler_a`
2. `ui_map_v2_path_edge_filler_b`
3. `ui_map_v2_path_edge_filler_c`
4. `ui_map_v2_path_breakup_decal_a`
5. `ui_map_v2_path_breakup_decal_b`

Bunlar büyük asset değil; küçük, transparent, top-down reusable stamp olmalı.

---

# 3) CLEARING LAYER

## 3A. Zaten repoda var
- `ui_map_v2_clearing_decal_neutral`
- `ui_map_v2_clearing_decal_boss`

## 3B. Eksik olan pratik varyantlar
Mevcut iki decal ile her şeyi çözmek yerine küçük bir set daha iyi olur.

### Bu turda eklenmesi mantıklı olanlar
1. `ui_map_v2_clearing_decal_start`
2. `ui_map_v2_clearing_decal_support`

Ama bu ikisi zorunlu değil.
Eğer scope’u dar tutacaksak boss + neutral ile devam edilebilir.

---

# 4) FOREST / FILLER LAYER

## 4A. Zaten repoda var
- `ui_map_v2_canopy_clump_a`
- `ui_map_v2_canopy_clump_b`
- `ui_map_v2_canopy_clump_c`

## 4B. Buradaki eksik
3 canopy clump başlangıç için iyi ama yeterli varyasyon vermez.
Tekrar hissini azaltmak için birkaç küçük stamp daha gerekir.

## 4C. Bu turda çizilecek gerçek filler set
### Canopy
1. `ui_map_v2_canopy_clump_d`
2. `ui_map_v2_canopy_clump_e`

### Ground clutter
3. `ui_map_v2_ground_clutter_a`
4. `ui_map_v2_ground_clutter_b`
5. `ui_map_v2_ground_clutter_c`

### Fog / shadow pockets
6. `ui_map_v2_fog_patch_a`
7. `ui_map_v2_fog_patch_b`

### Small ruin / stone detail
8. `ui_map_v2_ruin_scatter_a`
9. `ui_map_v2_ruin_scatter_b`

Bunlar node’u kapatmayacak, yolu örtmeyecek, sadece boşluğu dolduracak küçük reusable decal’ler olmalı.

---

# 5) GERÇEKÇİ MİNİMUM PROTOTYPE PAKETİ

Eğer “en az iş ile harita bir anda çok daha iyi görünsün” istiyorsak, ilk uygulanabilir paket şu olmalı:

## Paket A — En küçük faydalı set
### Node
- `icon_map_combat`
- `icon_map_key`
- `icon_map_boss`

### Path destek
- `ui_map_v2_path_edge_filler_a`
- `ui_map_v2_path_edge_filler_b`
- `ui_map_v2_path_breakup_decal_a`

### Forest fill
- `ui_map_v2_canopy_clump_d`
- `ui_map_v2_canopy_clump_e`
- `ui_map_v2_ground_clutter_a`
- `ui_map_v2_ground_clutter_b`
- `ui_map_v2_fog_patch_a`

Toplam: **11 yeni asset**

Bu sayı küçüktür ama board hissini ciddi şekilde iyileştirir.

---

## Üretim biçimi

### Format tercihi
Bu repo’nun mevcut yönüne göre ilk tercih:
- basit SVG
- veya küçük transparent PNG

### Stil kuralları
Her asset için:
- strict top-down
- no perspective
- no isometric
- dark forest wayfinder
- readable before atmospheric
- stylized not realistic
- mobile-readable
- transparent background
- isolated asset / reusable stamp

### Asset tipi dili
AI promptlarda şu kelimeleri kullan:
- `single isolated asset`
- `top-down orthographic`
- `transparent background`
- `reusable filler stamp`
- `clean silhouette`
- `no scene`
- `no map`
- `no text`
- `no ui`

---

## Klasör / isimlendirme kuralı

### Source master
- `SourceArt/Generated/Map/...`

### Runtime
- `Assets/Icons/...`
- `Assets/UI/Map/Trails/...`
- `Assets/UI/Map/Clearings/...`
- `Assets/UI/Map/Canopy/...`
- gerekiyorsa:
  - `Assets/UI/Map/Decor/...`
  - `Assets/UI/Map/Fog/...`

### Manifest
Her yeni asset `AssetManifest/asset_manifest.csv` içine işlenmeli.

---

## Codex için uygulanabilir iş sırası

# Phase 1 — Inventory + gap lock
Codex şunu yapsın:
1. mevcut runtime asset referanslarını oku
2. mevcut map icon/trail/canopy/clearing hook’larını çıkar
3. yukarıdaki minimum paket ile repo’daki mevcut yüzeyi karşılaştır
4. gerçekten eksik olan asset id listesini netleştir

Çıktı:
- `already live`
- `still missing`
- `polish later`

# Phase 2 — Small prototype asset production
Önce sadece Paket A üretilsin:
- combat icon
- key icon
- boss icon
- 2 path-edge filler
- 1 path breakup decal
- 2 canopy clump
- 2 ground clutter
- 1 fog patch

# Phase 3 — Hookup
Composer/scene tarafında:
- trail geometry değişmeyecek
- node truth değişmeyecek
- sadece presentation hooks yeni assetleri kullanacak

# Phase 4 — Visual review
Kontrol edilecekler:
- yollar daha doğal mı?
- boş alanlar daha dolu ama yine okunur mu?
- node’lar asset altında kayboluyor mu?
- combat/key/boss artık ayrışıyor mu?
- portrait readability bozuldu mu?

---

## Acceptance criteria
Bu plan ancak şu olursa başarılı sayılmalı:

1. Node truth runtime’da kalır.
2. Path geometry composer-derived kalır.
3. Asset placement presentation-only kalır.
4. Yeni assetler transparent ve reusable olur.
5. Board tek parça resim gibi değil, modüler pocket gibi görünür.
6. Combat / key / boss node’ları artık görsel olarak net ayrışır.
7. Yol çevresi daha doğal görünür.
8. Boş kalan alanlar filler ile dolar ama node/path okunurluğu bozulmaz.
9. Save shape değişmez.
10. AssetManifest güncel tutulur.

---

## Codex’e verilecek kısa yönlendirme

Bu repo için map board’u tek büyük arka plan resmi olarak çözme.
Mevcut runtime truth + composer truth ayrımını koru.
Önce mevcut map asset hook’larını audit et.
Sonra aşağıdaki minimum prototype paketini uygula:
- combat icon
- key icon
- boss icon
- 2 path-edge filler
- 1 path breakup decal
- 2 canopy clump
- 2 ground clutter
- 1 fog patch

Bunları transparent reusable asset olarak üret veya repo içinde author et.
SourceArt + runtime path + AssetManifest’i düzgün tut.
Ardından presentation hook’larına bağla.
Runtime truth, save shape ve graph logic’e dokunma.

