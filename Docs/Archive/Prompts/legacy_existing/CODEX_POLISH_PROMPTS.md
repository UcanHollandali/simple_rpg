# Codex Görev Listesi — Playtest Öncesi Cila, Optimizasyon, Ölü Kod Temizliği

Son güncelleme: 2026-04-18
Hedef: Simple RPG prototype'u playtest öncesi cilalamak, hotspot dosyaları küçültmek, net ölü kodu silmek ve inventory/combat sıcak yollarını optimize etmek.

## Nasıl Kullanılır

Her prompt kendi başına Codex'e verilecek şekilde yazıldı — önceki konuşmayı görmediğini varsayar. Her promptun başında **repo kuralları özeti** var; `AGENTS.md` ve authority doc'larla çakışmadığından emin olun.

Önerilen sıra: **Faz 1 → Faz 2 → Faz 3 → Faz 4 → Faz 5.** Faz 3 (hotspot extraction) Faz 2'den önce yapılırsa test yüzeyi sallanır.

Her faz sonunda zorunlu doğrulama komutları:

```
py -3 Tools/validate_content.py
py -3 Tools/validate_assets.py
py -3 Tools/validate_architecture_guards.py
powershell -NoProfile -ExecutionPolicy Bypass -File Tools/run_godot_full_suite.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File Tools/run_godot_smoke.ps1
```

---

## FAZ 1 — Düşük Riskli Hızlı Kazançlar (Fast Lane)

Ölü koda dokunan, playtest'e hazırlayan küçük işler. `AGENTS.md` "Low-Risk Fast Lane" kriterlerine uyar.

### Prompt 1.1 — `GameFlowManager.dispatch()` ölü kodunu sil

```
ROL: Godot 4 + typed GDScript üzerinde çalışan bir Simple RPG mühendisisin.
KURAL: AGENTS.md low-risk fast lane; save schema, flow state, veya command
family değişikliği YOK. Sadece doğrulanmış ölü kod temizliği.

GÖREV:
Game/Application/game_flow_manager.gd içindeki `dispatch(command: Dictionary)`
fonksiyonunu (46-65 satırları civarı) tamamen sil. Dosyanın kendi yorumu diyor ki:
"Deprecated compatibility shim for older call sites only. Current repo truth:
there are no in-repo runtime callers that should be using this path."

ADIMLAR:
1. `dispatch(` için tüm repo'da arama yap; Tools/validate_architecture_guards.py
   hariç hiçbir `.gd` dosyasında çağrısı OLMADIĞINI doğrula.
2. Fonksiyonu sil.
3. Tools/validate_architecture_guards.py'nin `dispatch` referansı hâlâ
   compatibility kontrolü için gerekliyse DOKUNMA; gerekli değilse ilgili
   kontrolü zayıflatmak yerine `dispatch` yokluğunu garanti eden halini koru.
4. Docs/COMMAND_EVENT_CATALOG.md'de `dispatch` referansı varsa güncelle.
5. Doğrulama:
   - py -3 Tools/validate_architecture_guards.py
   - powershell -File Tools/run_godot_full_suite.ps1

BAŞARI KRİTERİ: tüm testler PASS; repo'da `.dispatch(` çağrısı kalmamış;
Game/Application/game_flow_manager.gd en az 20 satır daha kısa.

DOKUNMA: başka hiçbir flow dosyası, save/inventory/combat truth.
```

### Prompt 1.2 — `sfx_brace_01` referansını düzelt

```
ROL: Simple RPG mühendisi.
KURAL: low-risk fast lane; sadece isim/varlık temizliği.

GÖREV:
scenes/combat.gd içinde `DEFEND_SFX_PATH := "res://Assets/Audio/SFX/sfx_brace_01.ogg"`
satırı var. `Brace` mekaniği çoktan söküldü (D-036); SFX hâlâ Defend için
kullanılıyor ama ismi yanıltıcı.

ADIMLAR:
1. Assets/Audio/SFX/sfx_brace_01.ogg dosyasını sfx_defend_01.ogg olarak
   yeniden adlandır. .import dosyasını da güncelle.
2. AssetManifest/asset_manifest.csv içinde ilgili satırı güncelle
   (asset_id, master_path, runtime_path, notes alanlarını).
3. scenes/combat.gd içindeki path'i güncelle.
4. py -3 Tools/validate_assets.py -> PASS olmalı.
5. powershell -File Tools/run_godot_full_suite.ps1 -> PASS.

BAŞARI KRİTERİ: repo'da kalan TEK `brace` referansı Tests/test_enemy_content.gd
içindeki scrub-guard'ı (o kalmalı, çünkü regresyon koruyor).

DOKUNMA: combat rule contract, test assertion, Docs/DECISION_LOG.md
tarihsel D-009/D-019/D-032 satırları.
```

### Prompt 1.3 — Event dosyalarındaki `zz_` prefix temizliği

```
ROL: Simple RPG içerik mühendisi.
KURAL: content-only patch; schema ve gameplay rule değişmiyor.

GÖREV:
ContentDefinitions/EventTemplates altında 10 dosya `zz_` prefix'li (alfabetik
sıralama hack'i). JSON içindeki `stable_id` ile dosya adı aynı OLMAK zorunda
olduğu için her dosyanın hem adını hem `stable_id` alanını değiştireceksin.

ADIMLAR:
1. Her zz_*.json için:
   - dosya adını zz_ prefix'i olmadan yeniden adlandır
   - JSON içindeki `stable_id` alanını eşleştir
2. Repo geneli grep: `zz_ash_tree_ledger`, `zz_dry_well_cache`, vs. için
   referans ara. RouteConditions, MapTemplates, tests, docs içinde varsa
   hepsini güncelle.
3. py -3 Tools/validate_content.py -> PASS.
4. powershell -File Tools/run_godot_full_suite.ps1 -> PASS.

BAŞARI KRİTERİ: ContentDefinitions/EventTemplates altında tek bir `zz_` dosyası
kalmamış.

DOKUNMA: event içerik kuralları (effect/choice yapısı).
```

### Prompt 1.4 — Kullanılmayan `gate_warden` içeriğini arşivle

```
ROL: Simple RPG içerik mühendisi.
KURAL: content-only; live stage boss pool'u değiştirme.

GÖREV:
ContentDefinitions/Enemies/gate_warden.json canlı boss pool'unda değil ama
hâlâ duruyor. İki seçenekten birini uygula ve hangisini seçtiğini rapor et:

SEÇENEK A (sadece arşivle — daha güvenli):
1. Dosyayı ContentDefinitions/Archive/Enemies/ altına taşı (klasör yoksa yarat).
2. validate_content.py, enemy tanımının referansını canlı yapılara aramıyorsa
   PASS verecektir; vermezse referans nokta(ları)nı bul ve A yerine B'ye geç.

SEÇENEK B (geri-getirilebilir — 4. boss olarak planla):
1. Hangi content dosyasının boss_enemy_id field'ında `gate_warden` geçtiğini
   bul; bir stage'e atanmamışsa orada kal.

Önce B yönünde bir referans ara; referans varsa B'yi raporla, yoksa A'yı
uygula.

DOĞRULAMA:
- py -3 Tools/validate_content.py -> PASS.
- powershell -File Tools/run_godot_full_suite.ps1 -> PASS.

DOKUNMA: live stage boss pool (`tollhouse_captain`, `chain_herald`, `briar_sovereign`).
```

### Prompt 1.5 — `main_menu`'ye kısa oyun loop bilgisi

```
ROL: Simple RPG UI mühendisi.
KURAL: UI-only; gameplay truth'a dokunma.

GÖREV:
scenes/main_menu.gd içinde playtest okunabilirliği için kısa bir alt-başlık /
tagline ekle: "Hazırlık odaklı, rota önemli, 3 aşama, 18-25 dk." tarzı bir satır.
Amaç: ilk playtest oyuncularının ne oynadığını hızlı kavraması.

ADIMLAR:
1. scenes/main_menu.tscn'ye MoodLabel/SubtitleLabel varsa onu kullan, yoksa
   mevcut Label yapısına minik bir satır ekle.
2. String: "Prepare. Route. Survive. — 3 aşama, ~20 dk koşu"
   (Türkçe istiyorsan: "Hazırlan. Rotanı Seç. Hayatta Kal. — 3 aşama, ~20 dk koşu")
3. TempScreenThemeScript.apply_label(..., "muted") ile stil uygula.
4. powershell -File Tools/run_godot_scene_isolation.ps1 -ScenePath scenes/main_menu.tscn

BAŞARI KRİTERİ: main menu screenshot'ta subtitle okunuyor; testler PASS.
```

---

## FAZ 2 — Scene Duplikasyonunu Ortak Yardımcıya Çıkar

12 sahne dosyası `_apply_portrait_safe_layout`, `_apply_temp_theme`, `_configure_audio_players`, `_connect_viewport_layout_updates`, `_disconnect_viewport_layout_updates`, `_on_viewport_size_changed`, `_load_texture_or_null` fonksiyonlarını tekrar tekrar yazıyor. Tek ortak yardımcıya taşıma ~1500-2000 satır kazandırır.

### Prompt 2.1 — `SceneLayoutHelper` yardımcısı oluştur

```
ROL: Simple RPG UI mühendisi.
KURAL: AGENTS low-risk fast lane; gameplay truth değişmez, sadece presentation
sarıcısı çıkarılıyor. scenes/ katmanında composition-only kalmalı.

GÖREV:
Game/UI/ altında YENİ bir script yarat: scene_layout_helper.gd. 12 sahne
dosyasında tekrarlanan şu operasyonları oraya taşı:

  - viewport size_changed bağla/çöz
  - portrait safe margin uygula (her sahnenin kendi MAX_WIDTH ve
    MIN_SIDE_MARGIN constant'larını parametre olarak alacak)
  - layout band hesabı (large / medium / compact eşikleri + font boyutları)
  - TextureRect için null-güvenli doku yükleme (_load_texture_or_null yerine)

12 sahne:
  main.gd, main_menu.gd, map_explore.gd, node_resolve.gd,
  combat.gd, event.gd, reward.gd, support_interaction.gd, level_up.gd,
  stage_transition.gd, run_end.gd

ADIMLAR:
1. Her sahnenin _apply_portrait_safe_layout + _on_viewport_size_changed +
   _connect/_disconnect_viewport_layout_updates + _load_texture_or_null
   fonksiyonlarını oku; ortak pattern'i çıkar.
2. scene_layout_helper.gd'ye parametrik API yaz:
      static func bind_viewport_size_changed(scene: Control, handler: Callable) -> void
      static func unbind_viewport_size_changed(scene: Control, handler: Callable) -> void
      static func apply_portrait_layout(scene: Control, config: Dictionary) -> Dictionary
          # config: { max_width, min_side_margin, top_margin, bottom_margin,
          #          large_band: {width, height, fonts...}, medium_band: {...},
          #          compact_band: {...} }
          # döner: { "safe_width", "layout_band" ("large"|"medium"|"compact") }
      static func load_texture_or_null(asset_path: String) -> Texture2D
3. Her sahneyi sırayla bu API'yi çağıracak şekilde güncelle (TEK COMMIT PER SCENE
   değil; tek bir commit içinde 12 sahneyi de güncelle ki davranış ve test
   çıktısı tutarlı kalsın).
4. Her sahne kendi özel constants'larını korur (PORTRAIT_SAFE_MAX_WIDTH,
   büyük/orta/küçük eşiği), helper sadece parametrelerle çağrılır.
5. Çıkartılan kodun kopyalanmış VE silinmiş hâlinin EŞDEĞER olduğunu göster:
   - powershell -File Tools/run_portrait_review_capture.ps1
     (öncesi/sonrası screenshot karşılaştırması)
6. Tüm validator zinciri PASS olmalı.

BAŞARI KRİTERİ:
- scenes/*.gd dosyalarında toplam satır sayısı <= eskinin %70'i.
- scene_layout_helper.gd < 200 satır.
- Hiçbir sahnenin davranışı değişmemiş.
- Arch guard PASS.

DOKUNMA: sahne scene tree (.tscn) yapısı; sadece .gd içlerini değiştir.
```

### Prompt 2.2 — `scene_audio_players.gd` kullanım konsolidasyonu

```
ROL: Simple RPG UI mühendisi.
KURAL: low-risk fast lane; audio truth yok, sadece çağrı temizliği.

GÖREV:
Her sahne _configure_audio_players'ı farklı dosya path'leriyle ama aynı
pattern'le yazıyor. Game/UI/scene_audio_players.gd zaten statik helper'lara
sahip. Bunu genişlet:

  static func configure_from_config(scene: Node, config: Dictionary) -> void
    # config: { "UiConfirmSfxPlayer": {"path": "...", "loop": false, "music": false}, ... }

Sonra 12 sahnenin _configure_audio_players'ını bu tek config dict tabanlı
çağrıya indir.

ADIMLAR:
1. scene_audio_players.gd'ye configure_from_config yaz.
2. Her sahnenin AUDIO_PLAYER_NODE_NAMES + path constants'larını tek dict'e dök.
3. Doğrulama: smoke + full suite.

BAŞARI KRİTERİ: sahnelerde _configure_audio_players ortalama 5 satıra indi;
scene_audio_players.gd < 200 satır kaldı.
```

---

## FAZ 3 — Hotspot Dosyaların Güvenli Ekstraksiyonu

Satır sayısı guard'ı `validate_architecture_guards.py` zaten büyümeyi bloke ediyor. Şimdi kontrollü biçimde küçültelim. Her prompt **guarded lane** — tam test suite PASS olmadan sonuçlandırma.

Hedef dosyalar ve mevcut büyüklükleri:
- `Game/RuntimeState/map_runtime_state.gd` — 2397 satır (HIGH RISK — escalate first)
- `scenes/map_explore.gd` — 1936 satır
- `scenes/combat.gd` — 1826 satır
- `Game/UI/map_board_composer_v2.gd` — 1258 satır
- `Game/Application/inventory_actions.gd` — 1073 satır
- `Game/Infrastructure/save_service.gd` — 1068 satır
- `Game/RuntimeState/inventory_state.gd` — 1039 satır

### Prompt 3.1 — `scenes/combat.gd` presentation extraction

```
ROL: Simple RPG UI mühendisi.
KURAL: AGENTS guarded lane; scenes/combat.gd UI katmanı, gameplay truth
CombatState/CombatFlow içinde kalmalı. SOURCE_OF_TRUTH.md dokunma.

GÖREV:
scenes/combat.gd 1826 satır. İçindeki saf sunum logiğini Game/UI/combat_presenter.gd
veya yeni bir Game/UI/combat_scene_ui.gd dosyasına taşı.

TAŞINACAK KALEMLER (bu sırayla — her kademede test et):
1. _ensure_feedback_shells + _ensure_action_hint_controls şemaları
   -> Game/UI/combat_scene_shell.gd (yeni)
2. Feedback lane / visual-delay bookkeeping (_feedback_lane_by_target,
   _feedback_visual_delay_by_target, _feedback_lane_reset_scheduled)
   -> Game/UI/combat_feedback_lane.gd (yeni)
3. Action hint panel open/close tween + hover tracking
   -> Game/UI/action_hint_controller.gd (yeni)

KORUNACAK KALEMLER:
- input handling (_input, _unhandled_input)
- flow event connect/disconnect (_on_domain_event_emitted, _on_combat_ended)
- scene-tree node path constants (ATTACK_BUTTON_PATH, vs.) — helper'a geçerse
  constants'lar da gitsin.

ADIMLAR:
1. Her ekstraksiyonun ardından tam test zinciri:
   - py -3 Tools/validate_architecture_guards.py
   - powershell -File Tools/run_godot_full_suite.ps1
   - powershell -File Tools/run_godot_scene_isolation.ps1 -ScenePath scenes/combat.tscn
2. Feedback behaviour'unun aynı kaldığını göstermek için
   powershell -File Tools/run_portrait_review_capture.ps1 ile görsel karşılaştır.
3. scenes/combat.gd sonucu < 1100 satır olmalı; yeni helper dosyaları
   bireysel olarak < 400 satır.

BAŞARI KRİTERİ: line-count guard PASS (eşik bu dosya için artık 1200 civarı
olarak güncellensin); tüm testler PASS; combat davranışı, feedback timing,
ve guard/damage sayıları aynı.

DOKUNMA: CombatState, CombatFlow, CombatResolver, hiçbir ContentDefinition.
```

### Prompt 3.2 — `scenes/map_explore.gd` presentation extraction

```
ROL: Simple RPG UI mühendisi.
KURAL: guarded lane. MapRuntimeState authority değişmez; map_explore.gd
composition + presentation'da kalır. MAP_CONTRACT.md dokunma.

GÖREV:
scenes/map_explore.gd 1936 satır. Aşağıdaki kümeleri Game/UI/ altına taşı:

1. Overlay açma/kapama koreografisi (event/support/reward/level_up overlay'leri)
   -> Game/UI/map_overlay_director.gd (yeni) — OverlayLifecycleHelper'ı
   kullanacak ama scene-specific koreografiyi sarmalıyor.
2. Tooltip yönetimi (INVENTORY_TOOLTIP_* constants + ilgili fonksiyonlar)
   -> Game/UI/inventory_tooltip_controller.gd (yeni)
3. Route button/marker constants ve grid bağlama pattern'i
   -> Game/UI/map_route_binding.gd (yeni) — route button path'lerini merkezi
   yapar; map_explore.gd sadece callback'leri register eder.

ADIMLAR:
1. Her ekstraksiyon sonrası: full_suite + scene_isolation scenes/map_explore.tscn
2. scenes/map_explore.gd sonucu < 1100 satır olmalı.
3. MAP_BOARD_BACKDROP_TEXTURE gibi presentation path constants'ları kalabilir;
   runtime path'leri değişmez.

DOKUNMA: MapRuntimeState, MapBoardComposerV2 gameplay read'leri,
roadside encounter tetiklemesi.
```

### Prompt 3.3 — `Game/Infrastructure/save_service.gd` load-path split

```
ROL: Simple RPG infrastructure mühendisi.
KURAL: guarded lane, ama save schema shape DEĞİŞMİYOR — sadece 5 eski
sürümün load-compat kodu ayrı dosyaya çıkarılıyor. SAVE_SCHEMA.md ve
save_schema_version değişmez.

GÖREV:
save_service.gd 1068 satır ve v1/v2/v5/v6/v7/v8 yükleme yolları aynı dosyada.
Eski yükleme yollarını Game/Infrastructure/save_service_legacy_loader.gd
altına taşı; save_service.gd sadece v8 yazma + dispatch + validation tutsun.

ADIMLAR:
1. load_from_save_dict ve v<8 schema dal'larını yeni legacy_loader'a taşı.
2. save_service.gd içindeki `if save_schema_version >= ...` dallarını
   legacy_loader'a delegate et.
3. save_schema_version sabitleri (SAVE_SCHEMA_VERSION, PREVIOUS, OLDER,
   SHARED_BAG, LEGACY_REWARD, LEGACY) nerede ihtiyaç varsa oraya yerleşsin.
4. Doğrulama:
   - py -3 Tools/validate_architecture_guards.py
   - powershell -File Tools/run_godot_full_suite.ps1
   - Tests/test_save_file_roundtrip.gd ve test_save_*.gd testleri ÖZELLİKLE
     PASS olmalı.

BAŞARI KRİTERİ: save_service.gd < 700 satır; legacy_loader.gd < 500 satır;
tüm save_schema_version 1..8 testleri PASS; yazma tarafı SAVE_SCHEMA_VERSION=8
olarak kalır.

DOKUNMA: SaveRuntimeBridge orchestration, RunState.load_from_save_dict
imzası, save payload shape.

ESCALATE-FIRST ALARMI: eğer iş sırasında save shape veya
save_schema_version numarası değişmesi gerekiyormuş gibi hissedersen
DUR ve "escalate first" de. Bu prompt bunu yapma yetkisi vermiyor.
```

### Prompt 3.4 — `Game/RuntimeState/map_runtime_state.gd` — YALNIZCA ölçüm raporu

```
ROL: Simple RPG runtime mühendisi.
KURAL: AGENTS high-risk lane; map_runtime_state.gd = stage truth owner.
Bu dosyada DEĞİŞİKLİK YAPMA. Sadece raporla.

GÖREV:
map_runtime_state.gd 2397 satır, 146 fonksiyon. Güvenli ekstraksiyon
adaylarını listele, sahiplik risklerini işaretle.

TESLİMAT:
1. docs/MAP_RUNTIME_STATE_EXTRACTION_PLAN.md (yeni) oluştur. İçinde:
   - Her fonksiyon bloğu (graph build, node state, pending context,
     stage key, boss gate, support revisit, hamlet side-quest, roadside
     quota, persistence)
   - Her blok için "ownership impact: none | yes | ambiguous" işareti.
   - Güvenli taşınabilirlik sıralaması (en az owner değişikliği gerekenden
     en fazlaya).
   - Her blok için tahmini yeni dosya adı (örn. map_graph_builder.gd).
2. HİÇBİR .gd DOSYASINI DEĞİŞTİRME.

BAŞARI KRİTERİ: rapor dosyası mevcut; map_runtime_state.gd aynı.
Rapor AGENTS.md "escalate-first lane" uyarısı ile açılsın.
```

---

## FAZ 4 — Hot-Path Performans İyileştirmeleri

Sıcak yollarda deep-copy ve scene-tree traversal maliyetini düşür.

### Prompt 4.1 — Combat sıcak yolunda deep-copy azaltma

```
ROL: Simple RPG core mühendisi.
KURAL: guarded lane. Combat rule contract DAVRANIŞI DEĞİŞMEZ; damage,
guard, durability, status timing aynı kalacak. TÜM test_status_*,
test_combat_*, test_boss_phases testleri PASS olmalı.

GÖREV:
Game/Core/combat_resolver.gd (11), Game/Application/combat_flow.gd (21),
Game/RuntimeState/combat_state.gd (32) içindeki `duplicate(true)` çağrılarını
incele ve sadece gerektikleri yerlerde tut.

METODOLOJİ:
1. Her duplicate(true) çağrısı için "bu copy gerçekten yeni bir state üretmek
   için mi, yoksa read-after-write paranoyasından mı?" sorusunu cevapla.
2. Saf okuma yolları (dict .get ile alınan değerler) için duplicate gerekmez.
3. Mutasyon sonucu döndürülen `updated_X_state` değerleri için tek bir
   terminal duplicate yeter; ara adımlarda çoklu kopya gerekmez.
4. Array[Dictionary] içinde for döngüsü ile her eleman duplicate ediliyorsa
   ve dışarıya sadece belirli alanlar göze gidiyorsa, dict literal ile
   daralt.

KONTROL:
- Her değişikliğin ardından `powershell -File Tools/run_godot_full_suite.ps1`
- Hiçbir test_status_* veya test_combat_spike testi FAIL olmamalı.
- Combat integer sonuçlarının aynı olduğunu göstermek için
  test_combat_spike'da sayısal assertion varsa onları doğrula.

BAŞARI KRİTERİ: combat_resolver + combat_flow + combat_state içindeki toplam
duplicate(true) sayısı en az %30 azalmış; tüm testler PASS.

DOKUNMA: damage order, guard decay rate, status tick timing, intent rotation.
```

### Prompt 4.2 — Sahne get_node_or_null cache (özellikle combat.gd)

```
ROL: Simple RPG UI mühendisi.
KURAL: UI-only; gameplay truth'a dokunma.

GÖREV:
scenes/combat.gd 118 get_node_or_null çağrısı yapıyor. Çoğu her refresh'te
aynı path'i yeniden çözüyor. @onready ile bir kez cache'leyelim.

ADIMLAR:
1. Sık kullanılan path constants (ATTACK_BUTTON_PATH, DEFENSE_BUTTON_PATH,
   USE_ITEM_BUTTON_PATH, ENEMY_HP_BAR_NAME, INTENT_CARD_PATH,
   PLAYER_RUN_SUMMARY_CARD_PATH, vs.) için @onready var X: Control =
   get_node_or_null(...) deklarasyonları ekle.
2. Refresh fonksiyonlarında her çağrıda tekrar get_node_or_null yapan
   yerleri cache'lenmiş değişkenle değiştir.
3. EDGE CASE: sahne yeniden inşa edildiğinde (örn. stage reset) cache
   geçersiz olur; _ready içinde init'i zorla veya null-check'i koru.
4. Aynı pattern'i scenes/map_explore.gd (60 çağrı), scenes/event.gd (53),
   scenes/reward.gd (59), scenes/level_up.gd (59), scenes/support_interaction.gd
   (49) için de uygula.

DOĞRULAMA:
- powershell -File Tools/run_godot_full_suite.ps1
- powershell -File Tools/run_godot_scene_isolation.ps1 -ScenePath scenes/combat.tscn
- Görsel regresyon: Tools/run_portrait_review_capture.ps1 önce/sonra karşılaştır.

BAŞARI KRİTERİ: toplam get_node_or_null çağrıları <= eskinin %40'ı; hiçbir
davranış regresyonu yok.

DOKUNMA: scene tree yapısı (.tscn), node path'leri.
```

### Prompt 4.3 — `InventoryState.consumable_slots` / `passive_slots` cache

```
ROL: Simple RPG runtime mühendisi.
KURAL: guarded lane; InventoryState owner sözleşmesi korunacak. Canonical
truth inventory_slots array + equipment slot dict'leridir. Compat accessor
davranışı aynı kalır.

GÖREV:
Game/RuntimeState/inventory_state.gd içindeki `consumable_slots` ve
`passive_slots` getter'ları her çağrıda `_collect_family_slots(...)` ile
O(n) tarama yapıyor. UI refresh'te defalarca çağrılıyor.

ADIMLAR:
1. Private cache alanları ekle:
     var _consumable_slots_cache: Array[Dictionary] = []
     var _consumable_cache_version: int = -1
     var _passive_slots_cache: Array[Dictionary] = []
     var _passive_cache_version: int = -1
     var _inventory_version: int = 0
2. inventory_slots'u mutate eden her fonksiyonda (move_backpack_slot_to_equipment,
   replace_equipped_slot, _replace_family_slots, reset_for_new_run, load_from_flat_save_dict)
   `_inventory_version += 1` çağır.
3. Getter'ı:
     get:
       if _consumable_cache_version != _inventory_version:
         _consumable_slots_cache = _collect_family_slots(INVENTORY_FAMILY_CONSUMABLE)
         _consumable_cache_version = _inventory_version
       return _consumable_slots_cache
4. DİKKAT: Getter'dan dönen dizinin mutasyon sonrası stale kalmaması için
   çağıran kod mutasyonda version bump'ı tetikliyor olmalı. Bu yüzden her
   mutate noktasını denetle.

DOĞRULAMA:
- test_inventory_*.gd ve test_save_*.gd testleri PASS.
- Özellikle test_save_file_roundtrip'in consumable/passive save-load sonuç
  eşitliğini doğrula.

BAŞARI KRİTERİ: consumable_slots/passive_slots getter'ları artık kendi
kendine linear tarama yapmıyor; testler PASS; hiçbir davranış regresyonu yok.

DOKUNMA: save shape, equipment slot semantics, InventoryActions API.
```

---

## FAZ 5 — Playtest-Hazır Cila (Game Feel)

Oyuncu deneyimini doğrudan iyileştiren küçük düzeltmeler.

### Prompt 5.1 — Defend/Guard okunabilirlik feedback'i

```
ROL: Simple RPG UI mühendisi.
KURAL: combat rule contract dokunma (COMBAT_RULE_CONTRACT.md). Sadece
presentation layer.

GÖREV:
Defend sonrası guard değerinin (ve decay'in) oyuncuya net bir feedback
vermesi. Şu anda kodda BossPhaseChanged benzeri bir sinyal var ama guard
decay/carryover için okunabilir bir hint yok.

ADIMLAR:
1. Game/UI/combat_presenter.gd'ye guard_delta feedback üretimi ekle
   (+X guard, -Y decay). Floating text zaten FeedbackTextLayer var.
2. scenes/combat.gd'de guard'ın kalan değerini küçük bir sayı rozeti
   olarak player card üstüne bas (hp bar'ın altına "Guard: N").
3. Rozet sıfıra düştüğünde fade-out; yeni guard eklenince pop.

DOĞRULAMA:
- test_combat_presenter.gd + smoke; scenes/combat.tscn isolation.

BAŞARI KRİTERİ: Defend turn'ünden sonra rakam gözle seçiliyor; combat math
değişmemiş.

DOKUNMA: CombatResolver, CombatFlow guard hesabı.
```

### Prompt 5.2 — Hunger threshold uyarısı

```
ROL: Simple RPG UI mühendisi.
KURAL: COMBAT_RULE_CONTRACT.md hunger eşiklerine (6 ve 2) dokunma. Sadece
presentation.

GÖREV:
Oyuncu `Hungry` (<=6) veya `Starving` (<=2) eşiğini geçtiğinde görünür ve
tek seferlik bir uyarı göster. Şu an hunger azalıyor ama kritik eşik
aşımı pasif kalıyor.

ADIMLAR:
1. Game/UI/run_status_strip.gd içinde hunger_threshold_crossed sinyali ekle
   (old_threshold, new_threshold).
2. scenes/map_explore.gd ve scenes/combat.gd'de bu sinyale bağlan, tek
   seferlik toast/rozet göster (fade-in, 2sn, fade-out).
3. String'ler:
   - 6'ya giriş: "Hungry — saldırı gücün -1"
   - 2'ye giriş: "Starving — saldırı gücün -2"
   - 0: "Starvation damage!"

DOĞRULAMA: smoke + scene isolation.

BAŞARI KRİTERİ: eşik geçişinde feedback çıkıyor; hiçbir gameplay math
değişmemiş.
```

### Prompt 5.3 — Stage açılışında kısa bilgi kartı

```
ROL: Simple RPG UI mühendisi.
KURAL: flow state eklemeden, mevcut StageTransition ekranını zenginleştir.

GÖREV:
scenes/stage_transition.gd'de stage numarası + hedef özeti (keyi bul, boss'u
yen) + aşamaya özgü bir satırlık "personality" metni (pilgrim / frontier /
trade) göster. Aynı şeyi MapRuntimeState zaten türetiyor; oradan oku.

ADIMLAR:
1. MapRuntimeState'in stage personality getter'ı üzerinden stage'e özgü
   satırı al.
2. stage_transition.gd içinde panel içeriğini zenginleştir (title +
   personality + one-liner objective).
3. TempScreenThemeScript ile stil.

DOĞRULAMA: test_stage_transition.gd + smoke.

BAŞARI KRİTERİ: her aşama başlangıcında oyuncu ne yapacağını kısa bir
kartta görüyor.

DOKUNMA: stage progression logic, save payload.
```

### Prompt 5.4 — Playtest telemetri logger (opsiyonel)

```
ROL: Simple RPG infrastructure mühendisi.
KURAL: release-facing değil, sadece local playtest için. Save payload'a
girmeyecek.

GÖREV:
Playtest oturumunda her node transition, her combat result, her perk
seçim ve her run end'i user://playtest_log.jsonl dosyasına ekle. Amaç:
playtest dönüşünde hangi kararların dengeyi çözdüğünü okumak.

ADIMLAR:
1. Game/Infrastructure/playtest_logger.gd (yeni) — append-only JSONL yazar.
2. AppBootstrap boot'ta ENABLE flag'ine bak (OS.is_debug_build() ||
   cmdline arg "--playtest-log").
3. Olayları GameFlowManager.flow_state_changed, CombatFlow.combat_ended_signal,
   RewardState seçim, LevelUpState seçim'e bağla.
4. Payload minimal: {timestamp, event_type, stage_index, hunger, gold, hp,
   current_node_id, selected_id?}.

DOĞRULAMA:
- py -3 Tools/validate_architecture_guards.py
  (yeni dosyanın infrastructure layer kurallarına uyduğunu doğrula)
- powershell -File Tools/run_godot_full_suite.ps1

BAŞARI KRİTERİ: debug build'de dosya yazılıyor; release build'de hiçbir
etki yok; save payload değişmemiş.

DOKUNMA: save service, RunState, gameplay truth.
```

---

## FAZ 6 — Dokümantasyon Uyumlaması (Küçük)

### Prompt 6.1 — `NodeResolve` dokümantasyon drift'i

```
ROL: Simple RPG teknik yazar.
KURAL: AGENTS doc-only patch; kod değişmeyecek.

GÖREV:
Docs/GAME_FLOW_STATE_MACHINE.md hâlâ NodeResolve'u aktif flow state olarak
listeliyor. Docs/HANDOFF.md ise "no longer on the live map-to-interaction
path" diyor. Bu drift'i kapat.

ADIMLAR:
1. Docs/GAME_FLOW_STATE_MACHINE.md'de NodeResolve'u "legacy-compat only,
   reached only from direct-entry fallback for legacy side_mission saves"
   olarak işaretle.
2. Docs/HANDOFF.md + Docs/DECISION_LOG.md ile uyumluluğu doğrula.
3. Dokümantasyon değişiklikleri ile kod arasında hiçbir çakışma kalmamalı.

DOĞRULAMA: manuel oku; validator zincirinde doc değişikliği test
yapmıyor ama arch guard PASS olmalı.
```

---

## Kullanım Rehberi

**Öncelik sırası (önerilen):**
1. Faz 1 (hızlı kazançlar — 1 güne kadar)
2. Faz 2 (scene duplikasyonu — 1-2 gün)
3. Faz 5 (playtest cila — paralel yapılabilir)
4. **Playtest!** HANDOFF.md Next Step listesindeki manuel playtest'i koş.
5. Faz 4 (perf, playtest sonrası bulgularla birlikte)
6. Faz 3 (büyük ekstraksiyon — playtest geçtikten sonra)
7. Faz 6 (doc drift — herhangi bir anda)

**Güvenlik ağı:** Her faz sonunda `Tools/run_godot_full_suite.ps1` PASS değilse o faz "bitti" sayılmaz. Faz 3.4 (map_runtime_state) explicit olarak **rapor-only** — Codex bu dosyayı değiştirmesin, yanlış karar verir.

**Kırmızı çizgiler** (bütün prompt'larda):
- save_schema_version DEĞİŞMEZ (v8 sabit)
- yeni flow state YOK
- yeni command / domain event family YOK
- `RunState` compat accessor genişlemez
- gameplay truth scenes/ içine SIZMAZ
