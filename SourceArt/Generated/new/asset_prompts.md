Evet. Bunu daha garanti hale getirmek için **tek tek asset prompt seti** yazalım.

Güncel repo truth’una göre canlı node aileleri `start`, `combat`, `event`, `reward`, `hamlet`, `rest`, `merchant`, `blacksmith`, `key`, `boss`; player-facing tarafta `event` = **Trail Event**, `hamlet` ise settlement/support stop. Board tarafında da `MapBoardComposerV2` derived presentation üretiyor; Handoff’ta trail decals, clearing decals, state plates ve canopy clumps’ın prototip olarak canlı olduğu yazıyor. ([GitHub][1])

## Kullanım şekli

Önce **01 node shell** çizdir.
Sonra her yeni node için o shell görselini yeni chatte yükleyip **edit** yaptır:

* “shell aynı kalsın”
* “sadece orta sembol/prop değişsin”
* “arka plan transparent olsun”

Bu, tek tek sıfırdan üretmekten daha tutarlı olur.

## Ortak negative prompt

Bunu node ve çoğu asset için ortak kullan:

```text
full scene, full map, road composition, ui, text, labels, character, creature body, card frame, background painting, perspective, isometric, side view, horizon, large environment, cinematic composition, multiple objects, centered illustration scene
```

Eğer ayrı negative kutusu yoksa, prompt sonuna `no ...` şeklinde ekle.

---

# WAVE 1 — NODE SHELL + NODE VARIANTS

## 01. map_node_shell_neutral

```text
single isolated 2D top-down orthographic game node shell asset, transparent background, hand-painted stylized dark fantasy forest relic style, mossy stone platform, slightly hexagonal or softly octagonal stone rim, clean centered composition, empty central icon area, mobile readable silhouette, soft oil-brush texture, subtle warm ambient light, no symbol, no prop, no path, no scene, no text, no ui, reusable base shell for multiple node types
```

## Node varyantları için ortak edit prefix

Aşağıdaki prefix’i aynen kullan, sonra ilgili asset satırını ekle:

```text
edit the provided node shell image, keep the exact same shell silhouette, same top-down orthographic camera, same rim shape, same stone material, same brush style, same scale, same lighting direction, same transparent background, only replace the central empty area with:
```

## 02. map_node_start_waypoint

Prefix sonuna bunu ekle:

```text
a small guiding lantern and waypoint flame, warm glow, subtle sacred travel-marker feeling, readable from mobile distance
```

## 03. map_node_combat_threat

```text
a compact threat symbol made from crossed blades and a small hostile camp marker, dangerous but readable, no full character body
```

## 04. map_node_trail_event_shrine

```text
a small relic shrine or rune stone, mysterious trail event feeling, subtle curiosity, not hostile, not reward-like
```

## 05. map_node_reward_cache

```text
a supply cache or treasure chest, reward feeling, compact readable prop, slightly warm highlight
```

## 06. map_node_hamlet_stop

```text
a tiny warm-lit hut or small settlement sign, safe support stop feeling, simple silhouette, readable at small size
```

## 07. map_node_rest_camp

```text
a small campfire with bedroll or resting setup, calm safe rest feeling, compact and readable
```

## 08. map_node_merchant_stall

```text
a tiny merchant pack, bags, and small trade stand, commerce feeling, compact silhouette, readable from distance
```

## 09. map_node_blacksmith_forge

```text
a small anvil with ember glow or forge tools, blacksmith identity, compact readable silhouette
```

## 10. map_node_key_relic

```text
a relic key on a small stone holder, important progression marker, readable strong shape, slightly brighter highlight
```

## 11. map_node_boss_gate

```text
a cursed gate, ominous altar, or skull brazier, strong dangerous final-node feeling, darker contrast, readable silhouette
```

---

# WAVE 2 — STATE OVERLAYS

Bunlar shell’in üstüne ayrıca çizdirilebilir. Ayrı asset olarak üret.

## 12. map_node_state_reachable

```text
single isolated top-down node state overlay for a 2D game, transparent background, subtle luminous rim, warm gold reachable highlight, thin clean shape matching a mossy stone node shell, no shell body, no icon, reusable overlay
```

## 13. map_node_state_resolved

```text
single isolated top-down node state overlay for a 2D game, transparent background, subdued dimmed stone rim overlay, faded cool-grey resolved state, low contrast, reusable overlay
```

## 14. map_node_state_locked

```text
single isolated top-down node state overlay for a 2D game, transparent background, sealed locked rim, darker metal-stone accent, restrained red warning hint, reusable overlay
```

## 15. map_node_state_special

```text
single isolated top-down node state overlay for a 2D game, transparent background, special progression rim, elegant relic glow, slightly stronger gold-blue contrast, reusable overlay
```

---

# WAVE 3 — PATH ASSETS

Burada tam harita değil, **parça** üret.

## 16. map_path_base_strip

```text
single isolated top-down dirt path strip asset for a 2D fantasy game, transparent background, orthographic view, hand-painted stylized forest path, soft worn dirt, subtle pebble detail, clean reusable strip, no scene, no full map, no center composition
```

## 17. map_path_edge_filler_a

```text
single isolated top-down forest path-edge filler asset for a 2D game, transparent background, orthographic view, hand-painted stylized vegetation cluster, low bushes, grass tufts, moss, tiny stones, irregular edge shape designed to blend beside a dirt path
```

## 18. map_path_edge_filler_b

```text
single isolated top-down rocky path-edge filler asset for a 2D game, transparent background, orthographic view, hand-painted stylized forest edge, broken stones, weeds, moss, slightly rougher irregular edge, reusable beside path segments
```

## 19. map_path_junction_decal

```text
single isolated top-down dirt path junction decal for a 2D fantasy game, transparent background, orthographic view, hand-painted stylized split-path intersection patch, worn central dirt, subtle stone wear, reusable procedural board junction piece
```

## 20. map_path_breakup_decal

```text
single isolated top-down path breakup decal for a 2D game, transparent background, orthographic view, hand-painted stylized dirt and moss irregular patch, designed to break repetition on path surfaces, subtle and reusable
```

## 21. map_path_relic_overlay

```text
single isolated top-down relic path overlay asset for a 2D fantasy game, transparent background, orthographic view, hand-painted stylized broken old stones and faded ruin marks, decorative path overlay, subtle, reusable
```

---

# WAVE 4 — CLEARING / GROUND

## 22. map_clearing_decal_neutral

```text
single isolated top-down forest clearing decal for a 2D game, transparent background, orthographic view, hand-painted stylized soft dirt and moss clearing, circular or softly hexagonal open pocket, designed under a map node, neutral readable ground
```

## 23. map_clearing_decal_special

```text
single isolated top-down special forest clearing decal for a 2D game, transparent background, orthographic view, hand-painted stylized relic clearing with subtle stone ring and faint glow accents, designed for key or boss node placement
```

## 24. map_ground_clutter_a

```text
single isolated top-down forest ground clutter decal for a 2D game, transparent background, orthographic view, hand-painted stylized leaves, moss, tiny pebbles, tiny weeds, subtle organic shape, reusable filler decal
```

## 25. map_ground_clutter_b

```text
single isolated top-down forest ground clutter decal for a 2D game, transparent background, orthographic view, hand-painted stylized dirtier patch with stones and sparse weeds, low contrast, reusable filler decal
```

## 26. map_ruin_stones_patch

```text
single isolated top-down forest ruin stones patch for a 2D game, transparent background, orthographic view, hand-painted stylized broken relic stones, moss, small fragments, subtle decorative cluster, reusable filler
```

---

# WAVE 5 — CANOPY / FOG / FILLER

## 27. map_canopy_clump_small

```text
single isolated top-down forest canopy clump asset for a 2D game, transparent background, strict 90-degree orthographic view, hand-painted stylized fantasy forest vegetation cluster, small leafy bushes and tiny tree crowns, reusable filler stamp
```

## 28. map_canopy_clump_medium

```text
single isolated top-down forest canopy clump asset for a 2D game, transparent background, strict 90-degree orthographic view, hand-painted stylized fantasy forest vegetation cluster, medium dense leafy canopy, reusable filler stamp
```

## 29. map_canopy_clump_large

```text
single isolated top-down forest canopy clump asset for a 2D game, transparent background, strict 90-degree orthographic view, hand-painted stylized fantasy forest vegetation cluster, broad dense canopy mass for map edges, reusable filler stamp
```

## 30. map_fog_patch_soft

```text
single isolated top-down soft fog patch asset for a 2D game, transparent background, orthographic view, gentle low-contrast mist cloud, hand-painted stylized fantasy atmosphere, soft irregular shape, reusable filler patch
```

## 31. map_shadow_pocket

```text
single isolated top-down forest shadow pocket asset for a 2D game, transparent background, orthographic view, soft dark foliage shadow patch, subtle and reusable, no hard edge
```

---

## En güvenli üretim sırası

İlk yeni chatte sadece bunları sırayla yaptır:

1. `map_node_shell_neutral`
2. `map_node_start_waypoint`
3. `map_node_combat_threat`
4. `map_node_trail_event_shrine`
5. `map_node_reward_cache`

Sonra stil oturursa kalan node’lara geç.

## Çok kısa kullanım notu

Yeni chatte her turda şunu yaz:

* “Sadece bu asset’i çiz.”
* “Transparent background zorunlu.”
* “Full scene çizme.”
* “Önceki shell’i bozma.”

İstersen ben bunu sana bir de **kopyala-yapıştır tek dosya halinde .md prompt pack** olarak çıkarayım.

[1]: https://raw.githubusercontent.com/UcanHollandali/simple_rpg/main/Docs/MAP_CONTRACT.md "raw.githubusercontent.com"
