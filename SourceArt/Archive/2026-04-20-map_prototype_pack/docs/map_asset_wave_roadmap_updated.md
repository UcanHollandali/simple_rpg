# SIMPLE RPG — Map Asset Wave Roadmap (Updated / New Chat Ready)

## Amaç
Bu dosya, **yeni bir chat'te asset üretimini tek tek yönetmek** için hazırlanmış kısa ve uygulanabilir yol haritasıdır.

Bu dosya **kod mimarisi** belgesi değildir.
Bu dosyanın amacı:
- hangi map asset'lerin **zaten canlı** olduğunu ayırmak,
- hangi asset'lerin **hala eksik / zayıf** olduğunu netleştirmek,
- yeni chat'te bunları **tek tek çizdirmek** için doğru sırayı vermektir.

---

## Güncel repo truth'u (özet)

### Map tarafında canlı runtime truth
- Runtime-backed node family seti:
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
- Player-facing adlar:
  - `event` => `Trail Event`
  - `hamlet` => settlement/support stop

### Ownership sınırı
- `MapRuntimeState` = graph truth owner
- `MapBoardComposerV2` = presentation-only derived board output
- Save payload = board coordinate / spline / decor placement saklamaz

### Canlı map presentation yüzeyi
Board tarafında şu prototip yüzeyler zaten canlı:
- trail decals
- clearing decals
- node state plates
- canopy clumps
- dedicated `Trail Event` icon
- refreshed side-mission / hamlet icon
- refreshed map-node icon family for:
  - `start`
  - `rest`
  - `merchant`
  - `blacksmith`
  - `trail event`
  - `hamlet`
  - `combat`
  - `reward`
- refreshed board backdrop
- refreshed walker idle / stride frames

### Açık kalan map asset işleri
Aktif roadmap / handoff çizgisine göre map tarafında özellikle açık kalanlar:
- asset hook wiring follow-up
- variation cleanup
- approved asset filenames ile ilerleyecek asset wave

---

## Bu asset wave'de ne yapmayacağız?

Şimdilik bunları yapmıyoruz:
- her run için tek parça full map painting
- node + path + forest'ın aynı PNG'de baked olduğu büyük harita resmi
- final release art
- photoreal sahne üretimi
- perspective / isometric illüstrasyon
- UI card art

Bu wave'in amacı:
**modüler reusable top-down asset kit**.

---

## Ana prensip

Harita görsel mantığı şu sırayla çalışmalı:

1. **Node graph** kod tarafında oluşur.
2. **Path / clearing** composer tarafında türetilir.
3. **Asset fill** presentation tarafında yerleşir.

Bu yüzden asset wave'de de şu mantıkla ilerleyeceğiz:

1. önce **ortak node shell**
2. sonra **node merkez sembolleri / küçük prop varyantları**
3. sonra **path edge / trail filler**
4. sonra **canopy / clutter / fog / ruin filler**

---

## Stil kilitleri

Her asset aynı dili taşımalı:
- strict 90-degree top-down
- orthographic
- transparent background
- isolated reusable asset
- dark forest wayfinder
- dark and misty, not muddy
- readable before atmospheric
- stylized before realistic
- mobile-readable silhouette
- no scene
- no UI
- no text
- no character
- no perspective
- no isometric angle

---

## Üretim stratejisi

### Doğru yaklaşım
10 ayrı node'u sıfırdan ayrı stil ile çizmek yerine:
- **1 ortak node shell**
- sonra **10 merkez sembol / mini prop**

Bu, tutarlılığı korur.

### Node görsel yaklaşımı
Node'lar saf ikon gibi değil, ama büyük sahne de değil.
En doğru dil:
- küçük top-down prop
- taş kaide / plate üstünde okunur sembol
- merkezde tek anlam
- mobilde bir bakışta ayırt edilir

---

## Çizim sırası (tek tek yeni chat'te üretilecekler)

# A — NODE CORE

## A1. Önce tek ortak shell
### 01. `map_node_shell_neutral`
Amaç:
- bütün node türlerinin oturacağı ortak base
- mossy stone plate / relic forest plate
- ortası boş veya çok hafif boşluklu
- transparent background

Not:
Mevcut repo'da state plates canlı. Bu shell, mevcut seti tamamen çöpe atmak zorunda değil; yeni cohesive repaint için source master olabilir.

## A2. Sonra merkez sembol / prop varyantları
### 02. `map_node_start_waypoint`
Fener / waypoint flame / küçük rehber ateş

### 03. `map_node_combat_threat`
Küçük düşman kampı / saplanmış silah / tehdit işareti

### 04. `map_node_trail_event_shrine`
Yol kenarı sunak / rune taşı / işaret direği

### 05. `map_node_reward_supplies`
Erzak sandığı / ganimet kasası / açık çanta

### 06. `map_node_hamlet_hut`
Küçük kulübe / mini yerleşim / sıcak pencere ışığı

### 07. `map_node_rest_campfire`
Kamp ateşi + battaniye / yatak rulosu

### 08. `map_node_merchant_cart`
Küçük tezgah / çuval + sandık / mini araba

### 09. `map_node_blacksmith_anvil`
Örs + küçük kor ateşi

### 10. `map_node_key_relic`
Kaide üstünde anahtar / relic key

### 11. `map_node_boss_gate`
Lanetli kapı / altar / skull brazier

## A3. İsteğe bağlı sonra
Bunlar şimdilik sonra gelebilir:
- `map_node_shell_special`
- `map_node_shell_subdued`
- özel reward shell
- özel boss shell

---

# B — PATH / TRAIL SUPPORT

Mevcut trail family SVG'leri canlı. Bu wave'de sıfırdan yol geometri sistemi çizmiyoruz.
Eksik olan şey, yolların çevresini doğal gösterecek destek parçaları.

### 12. `ui_map_v2_path_edge_filler_a`
Yol kenarı çim / çalı geçişi

### 13. `ui_map_v2_path_edge_filler_b`
Daha taşlı / daha kırık kenar geçişi

### 14. `ui_map_v2_path_breakup_decal_a`
Toprak kırığı / küçük bozulma / trail variation

### 15. `ui_map_v2_path_breakup_decal_b`
Daha kuru / daha sert zemin varyantı

### 16. `ui_map_v2_junction_patch_neutral`
Kavşak veya branch noktasında kullanılacak hafif merkez patch

Not:
Bu layer node'ları değil, trail hissini iyileştirir.

---

# C — FOREST / FILLER / DECOR

Mevcut repo'da canopy A/B/C ve iki clearing decal var. Bu yüzden yeni wave burada sıfırdan başlangıç değil, varyasyon artışı hedefliyor.

### 17. `ui_map_v2_canopy_clump_d`
Küçük-orta yoğunlukta canopy kümesi

### 18. `ui_map_v2_canopy_clump_e`
Daha yatay / kenar doldurucu canopy kümesi

### 19. `ui_map_v2_canopy_clump_f`
Daha geniş ama node clearings'i kapatmayan canopy kümesi

### 20. `ui_map_v2_ground_clutter_a`
Yaprak + yosun + küçük taş patch

### 21. `ui_map_v2_ground_clutter_b`
Daha kuru / toprak ağırlıklı clutter patch

### 22. `ui_map_v2_ground_clutter_c`
Daha taşlı / daha karışık clutter patch

### 23. `ui_map_v2_fog_patch_a`
Yumuşak düşük kontrast sis lekesi

### 24. `ui_map_v2_ruin_scatter_a`
Küçük harabe taşı / kırık kalıntı patch

### 25. `ui_map_v2_ruin_scatter_b`
Alternatif ruin scatter patch

---

## En uygulanabilir ilk paket

Yeni chat'te doğrudan tüm listeye dalma.
Önce bu küçük paketi üret:

### Paket 1 — Cohesive node başlangıcı
1. `map_node_shell_neutral`
2. `map_node_start_waypoint`
3. `map_node_combat_threat`
4. `map_node_trail_event_shrine`
5. `map_node_reward_supplies`

### Paket 2 — Node set'i tamamlama
6. `map_node_hamlet_hut`
7. `map_node_rest_campfire`
8. `map_node_merchant_cart`
9. `map_node_blacksmith_anvil`
10. `map_node_key_relic`
11. `map_node_boss_gate`

### Paket 3 — Trail çevresi
12. `ui_map_v2_path_edge_filler_a`
13. `ui_map_v2_path_edge_filler_b`
14. `ui_map_v2_path_breakup_decal_a`

### Paket 4 — Çevre doluluk hissi
15. `ui_map_v2_canopy_clump_d`
16. `ui_map_v2_canopy_clump_e`
17. `ui_map_v2_ground_clutter_a`
18. `ui_map_v2_fog_patch_a`

---

## Dosya / klasör mantığı

### Source master
- `SourceArt/Generated/Map/...`

### Runtime path (bağlanacak yüzey)
- node art için: `Assets/Icons/...` veya mevcut runtime hook ne ise ona uygun klasör
- trail support için: `Assets/UI/Map/Trails/...`
- canopy için: `Assets/UI/Map/Canopy/...`
- clutter/fog/ruin için: gerekiyorsa `Assets/UI/Map/Decor/...` veya benzer map presentation klasörü

### Manifest
Her yeni asset sonunda `AssetManifest/asset_manifest.csv` içine işlenmeli.

---

## Yeni chat'te nasıl kullanılmalı?

Bu dosyayı yeni chat'e koy.
Sonra şöyle ilerle:

### Başlangıç komutu
"Bu dosya benim map asset wave yol haritam. Baştan yorum yapma. Önce listedeki **01. map_node_shell_neutral** asset'ini çizelim. Sadece o asset'e odaklan. Transparent background, strict top-down, isolated reusable game asset. Başka asset'e geçme."

### Sonraki turlar
Her turda sadece bir asset iste:
- "Şimdi 02. map_node_start_waypoint"
- "Şimdi 03. map_node_combat_threat"
- ...

### Kural
Aynı anda 10 asset isteme.
Her turda:
- tek asset
- aynı stil
- aynı top-down dil
- transparent background
- reusable game asset

---

## Acceptance criteria

Bu wave başarılı sayılırsa:
- node'lar aynı aile gibi görünür
- trail çevresi daha doğal görünür
- board daha dolu ama daha okunaksız olmaz
- assetler full scene değil reusable parça olur
- transparent background korunur
- node/path/filler katmanları birbirine karışmaz
- runtime truth / save shape / graph logic bundan etkilenmez

---

## Kısa karar

Bu repo için doğru çözüm:
- full map painting değil
- tek tek reusable asset wave
- önce ortak node shell
- sonra node prop varyantları
- sonra trail filler
- sonra canopy/clutter/fog/ruin varyantları

Bu dosya yeni chat'te **tek tek çizdirme sırası** olarak kullanılmalı.
