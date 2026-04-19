# Codex UI Rework — Full Prompt Queue

Bu dosya **Codex'e yapıştırmalık** prompt'ları içerir. Her Part bağımsız bir Codex queue item'ıdır.
Sıra önemlidir: Part N tamamlanmadan Part N+1 başlamasın.

Toplam: **8 part = 8 queue item.**

Referans kaynak: önceki root planning note dump'ları (cleanup sonrası repoda bulunmayabilir)

---

## Önceki AI Değerlendirmesi ve Ek Bulgular

### Doğrulanmış Gerçekler (Kod ile kanıtlanmış)

| İddia | Doğrulama | Satır/Dosya |
|---|---|---|
| `RunStatusPresenter.build_compact_status_text()` tek satırlık raw string üretiyor | DOĞRU. `"HP %d \| Hunger %d \| Gold %d \| Durability %d"` | `run_status_presenter.gd:6-16` |
| Event/reward/support presenter'ları buna yaslanıyor | DOĞRU. Üçü de `RunStatusPresenterScript.build_compact_status_text(run_state)` çağırıyor | `event_presenter.gd:30`, `reward_presenter.gd:85`, `support_interaction_presenter.gd:71` |
| LevelUp ve StageTransition run-status göstermiyor | DOĞRU. İkisinde de `build_compact_status_text` çağrısı yok | `level_up_presenter.gd`, `stage_transition_presenter.gd` |
| Combat presenter kapsamlı ama unified HUD yok | DOĞRU. Her metric için ayrı `build_X_text()` var, ortak HUD pattern yok | `combat_presenter.gd:138-195` |
| `TempScreenTheme` color palette + panel helper + margin utility | DOĞRU | `temp_screen_theme.gd:5-32` |
| Viewport/window 1080x1920, stretch canvas_items/expand | DOĞRU | `project.godot` |
| `FAMILY_DISPLAY_NAMES["event"] = "Roadside Encounter"` hâlâ aktif | DOĞRU | `map_explore_presenter.gd:14` |
| `TransitionShellPresenter` NodeResolve için content üretiyor | DOĞRU | `transition_shell_presenter.gd:36-91` |
| `slot_factors` fallback normal path olarak kullanılıyor | DOĞRU | `map_explore.gd:878` |

### Önceki AI Promptlarının Zayıf/Eksik Noktaları

1. **AGENTS.md disiplini yetersiz**: Prompt'lar "read AGENTS.md" diyor ama escalate-first lane, validation command seti, save/flow boundary explicit olarak prompt guardrail'ına girmemiş. Bu dosyadaki prompt'larda her Part'a AGENTS-uyumlu guardrail ve validation komutu eklendi.

2. **Test dosyaları hedef alınmamış**: Repo'da 47 test dosyası var. UI rework sonrası `test_non_combat_presenters.gd`, `test_combat_presenter.gd`, `test_map_explore_presenter.gd`, `test_reward_presenter.gd` gibi dosyalar kırılacak. Her Part'a test güncellemesi eklendi.

3. **`scenes/event.gd` mevcut**: Önceki AI `scenes/event.gd` durumunu yanlış okumuş. Event ekranı ayrı scene script'i ile mevcut; ayrıca MapExplore overlay wiring'i de audit edilmeli. Prompt hedefleri buna göre net olmalı.

4. **Map redesign pipeline çakışma riski**: `codex_map_redesign_prompts.md` zaten var. Part 4 roadside/event semantiğini, Part 6 presenter label'ı değiştirecek. UI rework `FAMILY_DISPLAY_NAMES`'e dokunursa çakışır. Bu dosyadaki prompt'larda "map redesign ile çakışma notu" eklendi.

5. **Validation komutları generic**: TECH_BASELINE.md'deki exact Windows komutları kullanılmamış. Her Part'a repo-local validation komutları eklendi.

6. **Resolution/scaling pass'in zamanlaması doğru ama bağımlılık zayıf**: Part 2 foundation'dan sonra Part 2.5 scaling gelmesi mantıklı. Bu dosyada Part 3 olarak konumlandırıldı.

7. **Legacy note/temp dosyaları repo-state'a göre ele alınmalı**: `_tmp_map_capture.png` canlı repoda var. Root'taki planning note dump'ları ise workflow materyali olabilir ama runtime-authoritative değildir; cleanup prompt'ları bunları "varsa audit et" diye yazmalı, mevcut varsaymamalı.

### Part Yapısı

| # | Part | Tip | Risk | Bağımlılık |
|---|---|---|---|---|
| 1 | Authority-First UI Audit + Cleanup Inventory | NO-CODE | Low | — |
| 2 | Shared UI Foundation / Design System | CODE | Medium | Part 1 |
| 3 | Resolution / Scaling / Desktop Preview Fix | CODE | Low-Medium | Part 2 |
| 4 | MapExplore Full UI Rework | CODE | Medium | Part 3, ayrıca map redesign track aktifse onun Part 8'i |
| 5 | Combat Full UI Rework | CODE | Medium | Part 2, Part 3 tavsiye edilir |
| 6 | Overlay Screens Unified Rework | CODE | Medium | Part 2, Part 4, Part 5 |
| 7 | Cleanup / Dead UI / Stale Doc Removal | CODE | Low | Part 6 |
| 8 | Final Review + Audit + Patch | CODE | Low | Part 7 |

### Pipeline Çakışma Notu

Repo'da `codex_map_redesign_prompts.md` (8 code part + 4 asset part) zaten var. Map redesign Part 4 `event` → `Trail Event` label değiştirecek, Part 6 presenter label yaygınlaştıracak.

**Önerilen sıralama**:
- UI Rework Part 1-3 (audit + shared foundation + scaling) önce çalışabilir.
- Eğer `codex_map_redesign_prompts.md` track'i de kullanılacaksa, UI Rework Part 4-8'i map redesign Part 8 sonrasına bırak.
- Böylece MapExplore label/semantic değişiklikleri (`event` → yeni oyuncu-facing label) ve roadside flow düzeltmeleri önce sabitlenir; ekran rework bunların üstüne oturur.

Kısa karar:
- UI foundation önce olabilir.
- Screen-by-screen UI rework, map redesign sonrası daha güvenli.
- İki track'i aynı dosyalar üzerinde AYNI ANDA çalıştırma.

---

## Part 1 — Authority-First UI Audit + Cleanup Inventory (NO-CODE)

```
Bu pass implementasyon değil.
Önce repo truth'unu oku, UI durumunu audit et, cleanup envanteri çıkar.
Hiç kod yazma. Hiç doc değiştirme. Hiç dosya silme.

KESİN BİLGİ VS VARSAYIM AYRIMI
Her bulgu için:
- KESİN: doğrudan kod/doc satırı ile kanıt
- VARSAYIM: inference ile çıkarılmış ama henüz doğrulanmamış

Önce authority docs oku (bu sırayla):
- AGENTS.md
- Docs/DOC_PRECEDENCE.md
- Docs/HANDOFF.md
- Docs/GDD.md
- Docs/GAME_FLOW_STATE_MACHINE.md
- Docs/MAP_CONTRACT.md
- Docs/COMBAT_RULE_CONTRACT.md
- Docs/REWARD_LEVELUP_CONTRACT.md
- Docs/SUPPORT_INTERACTION_CONTRACT.md
- Docs/VISUAL_AUDIO_STYLE_GUIDE.md
- Docs/FIGMA_TRUTH_ALIGNMENT_PASS.md
- Docs/TEST_STRATEGY.md

Sonra sahne ve presenter kodu oku:
- scenes/map_explore.tscn + scenes/map_explore.gd
- scenes/combat.tscn + scenes/combat.gd
- scenes/event.tscn + scenes/event.gd
- scenes/reward.tscn + scenes/reward.gd
- scenes/support_interaction.tscn + scenes/support_interaction.gd
- scenes/level_up.tscn + scenes/level_up.gd
- scenes/stage_transition.tscn + scenes/stage_transition.gd
- scenes/run_end.tscn + scenes/run_end.gd
- scenes/node_resolve.tscn + scenes/node_resolve.gd
- scenes/main_menu.tscn + scenes/main_menu.gd
- scenes/run_setup.tscn + scenes/run_setup.gd

Presenter ve UI katmanı oku:
- Game/UI/run_status_presenter.gd
- Game/UI/map_explore_presenter.gd
- Game/UI/map_explore_scene_ui.gd
- Game/UI/combat_presenter.gd
- Game/UI/event_presenter.gd
- Game/UI/reward_presenter.gd
- Game/UI/support_interaction_presenter.gd
- Game/UI/level_up_presenter.gd
- Game/UI/stage_transition_presenter.gd
- Game/UI/transition_shell_presenter.gd
- Game/UI/inventory_presenter.gd
- Game/UI/inventory_card_factory.gd
- Game/UI/temp_screen_theme.gd
- Game/UI/safe_menu_overlay.gd
- Game/UI/run_menu_scene_helper.gd
- Game/UI/map_board_canvas.gd
- Game/UI/map_board_composer_v2.gd
- Game/UI/map_board_style.gd
- Game/UI/ui_asset_paths.gd

Ayrıca cleanup için oku:
- project.godot (window/stretch ayarları)
- Root'taki geçici veya legacy notlar varsa: _tmp_map_capture.png ve runtime dışı planning note dump'ları
- `codex_*.md` plan/prompt dosyalarını cleanup adayı gibi ele alma

Test dosyalarını oku (presentation ile ilgili olanlar):
- Tests/test_combat_presenter.gd
- Tests/test_non_combat_presenters.gd
- Tests/test_map_explore_presenter.gd
- Tests/test_reward_presenter.gd
- Tests/test_inventory_presenter.gd

IMPORTANT RULES
- UI/readability/repo-cleanliness audit. İmplementasyon değil.
- Gameplay truth'u UI'ya taşıma önerme.
- Flow-state / save-schema / source-of-truth ownership değişikliği önerme.
- "Kullanılmıyor gibi" diye referans audit yapmadan dead deme.

ÇIKARILACAK RAPOR

1. AUTHORITY SUMMARY
   - UI rework için authoritative docs listesi
   - Presentation truth owner: kim?
   - Runtime truth owner: kim?
   - Flow owner: kim?
   - Save-sensitive yüzeyler: hangileri?

2. CURRENT IMPLEMENTATION AUDIT (verify edilmiş durum)
   Her ekran için:
   - şu an oyuncuya ne gösteriyor?
   - eksik/zayıf/gömülü bilgi ne?
   - bilgi hiyerarşisi sorunu ne?
   - layout/readability sorunu ne?
   - shared component fırsatı ne?

   Ekranlar:
   - MapExplore
   - Combat
   - Event
   - Reward
   - SupportInteraction
   - LevelUp
   - StageTransition
   - RunEnd
   - NodeResolve (hâlâ aktif mi? hangi flow'larda?)
   - RunSetup
   - MainMenu

3. CROSS-SCREEN UI SYSTEM FINDINGS
   - header/panel/card consistency
   - stat presentation language
   - spacing/rhythm
   - overlay/shell behavior
   - presenter helper sağlığı

4. RUN-STATUS PRESENTATION HEALTH
   build_compact_status_text() analizi:
   - kim kullanıyor, kim kullanmıyor
   - ne gösteriyor, ne göstermiyor (XP? weapon? armor?)
   - neden tek raw string yetersiz

5. RESOLUTION / SCALING AUDIT
   project.godot ayarlarını oku.
   - viewport: kaç x kaç?
   - window override: kaç x kaç?
   - stretch mode / aspect: ne?
   - 1080p desktop'ta neden sığmıyor?
   - hangi sahneler fixed-size varsayımı yapıyor?

6. TEST HEALTH
   Presentation testlerini oku.
   - hangi presenter'lar test ediliyor?
   - hangileri eksik?
   - UI rework sonrası hangileri kırılacak?

7. CLEANUP INVENTORY (3 bucket)
   A) Confirmed dead / safe delete later
   B) Likely legacy / investigate during implementation
   C) Keep
   Her item: path, category, evidence, risk if removed

8. MAP REDESIGN PIPELINE ÇAKIŞMA ANALİZİ
   codex_map_redesign_prompts.md var. Hangi UI rework part'ları hangi map redesign part'ları ile çakışır?
   - FAMILY_DISPLAY_NAMES["event"] Part 4 map redesign ile çakışır mı?
   - build_compact_status_text Part 2 UI rework ile çakışır mı?
   - Önerilen sıralama?

9. RECOMMENDED IMPLEMENTATION ORDER
   Default beklenen: Part 2 → Part 3 → Part 4 → Part 5 → Part 6 → Part 7 → Part 8
   Farklı sıra daha iyi olacaksa açıkla.

10. STOP HERE
    - no code changes made
    - no docs changed
    - no files deleted
    - ready for Part 2

GUARDRAILS
- Broad cleanup yapma.
- "Unused görünüyor" diye referans audit yapmadan silme.
- Ownership move yapma.
- Save schema shape değiştirme.
- Doc'u şimdi rewrite etme, sadece inventory çıkar.
```

---

## Part 2 — Shared UI Foundation / Design System Pass (MEDIUM RISK)

```
Bu pass'in amacı: bütün ekranların ortak kullanacağı UI dili kurulsun.
Ekran bazlı full rework HENÜZ yapma.
Sahnelere sadece foundation'ı wire etmek için minimal dokun.

KESİN BİLGİ — Başlangıç Noktası
- RunStatusPresenter.build_compact_status_text() şu an yalnızca "HP %d | Hunger %d | Gold %d | Durability %d" üretiyor (run_status_presenter.gd:6-16)
- Event/reward/support buna yaslanıyor; level_up ve stage_transition hiç run-status göstermiyor
- Combat presenter kendi ad-hoc metric builder'larını kullanıyor (build_player_hp_text, build_hunger_text, build_durability_text vb.)
- TempScreenTheme zaten color palette + panel helper + margin utility içeriyor

Önce oku:
- AGENTS.md
- Docs/DOC_PRECEDENCE.md
- Docs/HANDOFF.md
- Docs/GDD.md
- Docs/VISUAL_AUDIO_STYLE_GUIDE.md
- Docs/FIGMA_TRUTH_ALIGNMENT_PASS.md

STRICT SCOPE — değiştirebileceğin yüzey:
- Game/UI/run_status_presenter.gd
- Game/UI/temp_screen_theme.gd
- Gerekirse yeni shared UI helper dosyaları (Game/UI/ altında)
- Mevcut presenter'larda sadece shared foundation'a wire etmek için minimal değişiklik
- Sahnelerde sadece wiring için minimal dokunuş
- Tests: etkilenen presenter testlerini güncelle

DOKUNMA:
- Gameplay rules
- Save schema / save version
- Flow state machine
- Source-of-truth ownership
- Runtime state dosyaları
- Ekranları baştan sona redesign etme

GOAL
Reusable shared UI foundation oluştur:

A) RUN STATUS HUD SYSTEM
build_compact_status_text yerine yapılandırılmış bir run-status sistemi:
- HP (bar veya chip, raw text değil)
- Hunger
- Gold
- Durability
- XP / level progress (isteğe bağlı, relevant ekranlarda)
- Active weapon summary (isteğe bağlı)
Farklı ekranlar için compact/standard/minimal variant'lar desteklesin.

B) STAT PRESENTATION LANGUAGE
Tutarlı stat gösterme dili:
- stat chip / mini card / icon+value+label
- compact bar
- segmented row
2-3 ilişkili pattern yeterli, tek rigid component zorla değil.

C) SHARED FORMATTING HELPERS
Merkezileştirilmiş formatting:
- HP / Hunger / Durability display
- Gold display
- XP / progress display
- Weapon summary
- Status summary
- Enemy intent summary scaffold
- Consequence preview scaffold
Ad-hoc string building azalsın.

D) SHARED VISUAL LANGUAGE
Minimum shared shell parçaları:
- screen header block
- panel shell
- compact status area
- choice/action card shell
- badge/state marker
TempScreenTheme üstüne kur, overengineer etme.

E) PORTRAIT LAYOUT DEFAULTS
Safe defaults:
- spacing rhythm
- section grouping
- panel padding
- title/value emphasis
- vertical compression under limited height

F) FUTURE-PROOFING FOR MIGRATION
Shared foundation migration sonrası gelecek yeni stat türlerini kaldırabilmeli:
- Guard
- shield/offhand summary
- perk summary
- equipment slot summary
Bugünkü HP/Hunger/Gold/Durability modeline rigid bağlanma; yeni chip/bar/row tipleri eklenebilir olsun.

IMPLEMENTATION RULES
1. Mevcut sistemi extend et, sıfırdan framework yazma
2. Presenter/helper extraction fast-lane — AGENTS uyumlu
3. Scene script'ler presentation-only kalsın
4. Display text logic key olmasın
5. Raw compact status string fallback olarak kalabilir ama main strategy olmasın
6. "looks unused" diye kanıtsız silme

TESTS
- Mevcut test_non_combat_presenters.gd, test_combat_presenter.gd, test_reward_presenter.gd presenter testlerini audit et
- Shared foundation değişiklikleri yüzünden kırılan testleri bilinçli güncelle
- Yeni shared helper'lar için minimum test yaz

VALIDATION — REQUIRED
- py -3 Tools/validate_content.py
- py -3 Tools/validate_architecture_guards.py
- powershell -NoProfile -ExecutionPolicy Bypass -File Tools/run_godot_tests.ps1
- Eğer scene wiring değiştiyse: powershell -NoProfile -ExecutionPolicy Bypass -File Tools/run_godot_smoke.ps1

REPORT FORMAT
1. Touched files
2. Foundation decisions: shared UI language nasıl kuruldu
3. Run-status system: before/after
4. Variants/reuse points
5. What was intentionally NOT done yet
6. Tiny safe removals (if any)
7. Tests updated/added
8. Validation results
9. Risk notes (runtime verification gereken)
10. Ready for Part 3

STOP CONDITIONS — escalate first
- Save schema change gerekiyorsa
- Flow state değişikliği gerekiyorsa
- Runtime truth UI'ya taşınması zorunluysa
- Presenter extraction scope'un dışına çıkıyorsa
```

---

## Part 3 — Resolution / Scaling / Desktop Preview Fix (LOW-MEDIUM RISK)

```
Bu pass yalnızca çözünürlük/ölçeklendirme/desktop preview sorununu çözer.
Part 2 shared foundation sonrası, ekran rework'lerinden ÖNCE gelir.

KESİN BİLGİ — Başlangıç Noktası
- project.godot: viewport_width=1080, viewport_height=1920
- window_width_override=1080, window_height_override=1920
- stretch mode: canvas_items, aspect: expand
- 4K monitörde kabul edilebilir görünüyor
- 1080p desktop'ta portrait pencere dikeyde sığmıyor

Önce oku:
- AGENTS.md
- Docs/DOC_PRECEDENCE.md
- Docs/HANDOFF.md
- Docs/TECH_BASELINE.md

Sonra incele:
- project.godot (display/window/stretch tam bölümü)
- scenes/ dizinindeki ana sahne dosyaları (root container yapıları)
- Part 2'de oluşturulan shared UI foundation dosyaları
- Hardcoded window/size varsayımı yapan script'ler

STRICT SCOPE
- project.godot ayarları
- Sahnelerde container/anchor yapısal düzeltmeler
- Gerekirse küçük dev-preview helper
- Minimal doc sync

DOKUNMA:
- Ekranları full redesign etme (Part 4-6'da)
- Gameplay rules
- Save schema
- Flow state

GOAL
Mobile portrait referans layout'u koruyarak, projeyi desktop'ta (özellikle 1080p) geliştirmeyi/test etmeyi pratik hale getir.

Sonuç:
1. Oyun mobile-first ve portrait-first kalsın
2. Temiz mantıksal base resolution stratejisi
3. Sahne bazlı hacky scale fix olmasın
4. Desktop preview 1080p'de kullanılabilir olsun
5. Layout farklı portrait hedeflerinde stabil olsun

IMPLEMENTATION DIRECTION
A) LOGICAL / DESIGN REFERENCE: portrait mobile referans korunacak
B) RUNTIME SCALING: canvas_items + expand doğru mu, ayarlama gerekiyor mu?
C) DESKTOP PREVIEW: dev-friendly preview sizing, zorunlu tam-boy portrait pencere açma
D) CONTAINER / ANCHOR safety pass: brittle fixed sizing/offset kır
E) MULTI-TARGET test: 1080x2400, 1080x1920, 720x1280, 1366x768, 1920x1080

IMPORTANT RULES
- Per-node manual scale yapma
- Control node'ları tek tek scale etme
- Container/anchor tabanlı çözüm tercih et
- Scene flow bozma
- Mobile portrait'ı desktop'a çevirme

VALIDATION — REQUIRED
- py -3 Tools/validate_content.py
- py -3 Tools/validate_architecture_guards.py
- powershell -NoProfile -ExecutionPolicy Bypass -File Tools/run_godot_tests.ps1
- powershell -NoProfile -ExecutionPolicy Bypass -File Tools/run_godot_smoke.ps1

REPORT FORMAT
1. Current scaling strategy found
2. Problems solved
3. Files changed
4. Scaling strategy chosen (base/runtime/preview)
5. Layout stability changes
6. Verification targets checked (5 resolution)
7. Risk notes
8. Ready for Part 4

STOP CONDITIONS — escalate first
- Scaling fix scene/core boundary rewrite gerektiriyorsa
- Save/flow ownership taşınıyorsa
```

---

## Part 4 — MapExplore Full UI Rework (MEDIUM RISK)

```
Bu pass MapExplore ekranını tam UI rework'e tabi tutar.
Part 2 shared foundation + Part 3 scaling üstüne kurar.
Diğer ekranları burada redesign etme.

PIPELINE ÇAKIŞMA NOTU
codex_map_redesign_prompts.md mevcut. O pipeline'ın Part 4'ü event→Trail Event rename yapacak, Part 6'sı presenter label yaygınlaştıracak.
Bu UI rework'te FAMILY_DISPLAY_NAMES'e DOKUNMA. Label değişikliği map redesign pipeline'ına bırak.
Sadece shared HUD/layout/readability'e odaklan.

Önce oku:
- AGENTS.md
- Docs/DOC_PRECEDENCE.md
- Docs/HANDOFF.md
- Docs/MAP_CONTRACT.md
- Docs/GDD.md
- Docs/VISUAL_AUDIO_STYLE_GUIDE.md

Sonra current implementation oku:
- scenes/map_explore.tscn + scenes/map_explore.gd
- Game/UI/map_explore_presenter.gd
- Game/UI/map_explore_scene_ui.gd
- Game/UI/map_board_canvas.gd
- Game/UI/map_board_composer_v2.gd
- Game/UI/map_board_style.gd
- Game/UI/inventory_presenter.gd
- Game/UI/inventory_card_factory.gd
- Game/UI/run_status_presenter.gd (Part 2 sonrası hali)
- Game/UI/temp_screen_theme.gd
- Game/UI/safe_menu_overlay.gd
- Tests/test_map_explore_presenter.gd

STRICT SCOPE
- scenes/map_explore.tscn + gd
- Game/UI/map_explore_presenter.gd
- Game/UI/map_explore_scene_ui.gd
- Shared helper'lara sadece MapExplore gerektirdiği kadar dokunuş
- Tests/test_map_explore_presenter.gd güncelleme
- Minimal doc sync

DOKUNMA:
- Combat / event / reward / support / level_up redesign
- FAMILY_DISPLAY_NAMES label rename (map redesign pipeline'ına bırak)
- Runtime truth / save schema
- Flow state machine
- Composer math (map redesign pipeline Part 5)

GOAL
MapExplore = oyunun ana "run overview" ekranı.
Oyuncu bir bakışta anlasın:
1. Şu anki kondisyonum (HP/Hunger/Gold/Durability)
2. Run'da neredeyim (stage/progress)
3. Hangi node'dayım / hangileri erişilebilir
4. Yakında ne tür risk/fırsat var
5. Ne yapabilirim
6. Inventory/loadout basıncı

DESIGN REQUIREMENTS
A) TOP RUN HUD — Part 2 shared foundation'ı kullan
   - HP, Hunger, Gold, Durability okunur ve gruplu
   - XP/level varsa compact göster
   - Weapon summary varsa göster
   - Portrait-safe, haritayı ezmeyecek kadar compact

B) MAP = VİZUEL MERKEZ
   - Harita ekranın ana odağı
   - Current/selected/reachable node belirgin
   - Locked/resolved/key/boss state visual distinct
   - HUD haritayı küçültmesin

C) STAGE / ROUTE / PROGRESSION
   - Stage/phase indicator görünür
   - Node depth/objective/key-gate progress compact

D) CURRENT NODE CONTEXT PANEL
   - Focused node ne demek: type, title, practical meaning
   - Kısa, karar odaklı, flavor text baskın değil

E) INVENTORY INTEGRATION
   - Carried items/pressure hızlıca anlaşılır
   - Active weapon görünür
   - Portrait-safe

F) BOTTOM AREA CLEANUP
   - Tek uzun status text'e bağımlılığı azalt
   - Kritik bilgi zaten üstte/ortada olsun
   - Alt metin secondary/supportive

G) OVERLAY COMPATIBILITY
   - Event/reward/support/level_up overlay'ları bozma
   - Safe menu overlay davranışı korunsun

INFORMATION HIERARCHY
Primary: HP, Hunger, current node/focus, reachable choices, stage progress
Secondary: Durability, Gold, XP, weapon summary, inventory pressure, node sub-labels
Tertiary: Flavor copy, verbose text, redundant status lines

TESTS
- test_map_explore_presenter.gd: güncelle, yeni shared HUD ile uyumlu yap
- Yeni map UI assertions ekle gerekiyorsa

VALIDATION — REQUIRED
- py -3 Tools/validate_content.py
- py -3 Tools/validate_architecture_guards.py
- powershell -NoProfile -ExecutionPolicy Bypass -File Tools/run_godot_tests.ps1
- powershell -NoProfile -ExecutionPolicy Bypass -File Tools/run_godot_full_suite.ps1
- powershell -NoProfile -ExecutionPolicy Bypass -File Tools/run_godot_scene_isolation.ps1 -ScenePath scenes/map_explore.tscn

REPORT FORMAT
1. Map-specific problems solved
2. Files changed
3. Layout changes (before/after)
4. Readability improvements
5. Inventory/route integration changes
6. Tiny safe removals (if any)
7. Tests updated
8. Validation results
9. Risk / runtime verification notes
10. Ready for Part 5

STOP CONDITIONS — escalate first
- Map redesign pipeline scope'una girdiyse
- Runtime truth / save shape değişiyorsa
- Flow state machine değişikliği zorunluysa
- FAMILY_DISPLAY_NAMES rename gerekliyse (map redesign'a bırak)
```

---

## Part 5 — Combat Full UI Rework (MEDIUM RISK)

```
Bu pass Combat ekranını tam UI rework'e tabi tutar.
Part 2 shared foundation üstüne kurar.

KOORDİNASYON NOTU
Bu aşamada combat hâlâ `Brace` aksiyonunu kullanıyor. Ancak Migration Part 3 bunu `Defend/Guard` modeline çevirecek.
Bu yüzden defensive action slot'unu generic bir "primary defensive action card" olarak kur:
- bu pass'te current label `Brace` olabilir
- ama layout, preview alanı ve emphasis yapısı Migration Part 3'te sadece label + Guard veri alanı değişerek yaşayabilsin
- combat UI'ı `Brace` kelimesine sert kodlama ile bağlama

KESİN BİLGİ — Başlangıç Noktası
- Combat presenter 700+ satır, kapsamlı ama unified HUD yok
- Her metric için ayrı build_X_text() helper: build_player_hp_text, build_hunger_text, build_durability_text, build_active_weapon_text
- build_resource_hud_texts() bir Dictionary dönüyor ama formatted raw string: "HP %d/%d"
- build_state_text() giant raw concat: "Player HP: %d | Hunger: %d | Durability: %d | Items: %d | ..."
- Intent summary sistemi iyi: build_intent_summary_text() intent effects'i parse edip "Attack %d + Status" üretiyor
- Impact feedback model (pulse/flash/float) var
- Preview texts sistemi var (attack/defense/incoming/brace/hunger_tick/durability_spend)
- HANDOFF: combat height-budget layout ile çalışıyor

Önce oku:
- AGENTS.md
- Docs/DOC_PRECEDENCE.md
- Docs/HANDOFF.md
- Docs/COMBAT_RULE_CONTRACT.md
- Docs/GDD.md
- Docs/VISUAL_AUDIO_STYLE_GUIDE.md

STRICT SCOPE
- scenes/combat.tscn + scenes/combat.gd
- Game/UI/combat_presenter.gd
- Shared helper'lara sadece Combat gerektirdiği kadar dokunuş
- Tests/test_combat_presenter.gd güncelleme
- Minimal doc sync

DOKUNMA:
- Combat rules rewrite
- Turn order changes
- Map / event / reward / support / level_up redesign
- Runtime truth
- Save schema
- NodeResolve (combat zaten bypass ediyor, HANDOFF'a göre)

GOAL
Combat ekranı tek bakışta anlaşılsın:
1. Kim ile savaşıyorum
2. Düşmanın HP'si ne
3. Düşman ne yapmak üzere (intent)
4. Benim kondisyonum ne (HP/Hunger/Durability/weapon)
5. Ne yapabilirim (Attack/current defensive action/Use Item)
6. Her aksiyonun muhtemel sonucu ne
7. Son turda ne oldu (log — secondary)

DESIGN REQUIREMENTS
A) ENEMY BLOCK
   - Enemy name/type/trait hemen okunur
   - Enemy HP bar/visual
   - Intent PRIMARY bilgi — gömülü olmasın
   - Enemy statuses compact

B) PLAYER BLOCK
   - HP, Hunger, Durability hızlı scan
   - Active weapon görünür
   - Armor/belt relevance varsa göster
   - Player statuses compact

C) ACTION AREA
   - Attack / current defensive action / Use Item distinct
   - Preview/hint text karar destekleyici
   - Tooltip/preview concise
   - Portrait-fit

D) COMBAT LOG — SECONDARY
   - Son olaylar görünür ama dominant değil
   - Oyuncu taktik state'i okumak için log'a muhtaç olmasın
   - Aşırı yükseklik tüketmesin

E) QUICK ITEM / INVENTORY
   - Combat-relevant consumable'lar anlaşılır
   - Equipped vs carried net
   - Portrait-readable

F) HEIGHT-BUDGET / PORTRAIT STABILITY
   - Mevcut height-budget approach'u koru veya iyileştir
   - Overflow yok, giant boşluk yok
   - Primary info secondary'den önce sığsın

INFORMATION HIERARCHY
Primary: enemy intent, enemy HP, player HP, hunger (tactical), action choices, weapon/durability
Secondary: statuses, armor/belt, item availability, preview text, recent events
Tertiary: verbose descriptions, long log, decorative labels

TESTS
- test_combat_presenter.gd: intent/preview/status builder testleri korunsun
- Yeni layout/formatting değişiklikleri test edilsin
- build_resource_hud_texts() / build_state_text() değişirse testler güncellensin

VALIDATION — REQUIRED
- py -3 Tools/validate_content.py
- py -3 Tools/validate_architecture_guards.py
- powershell -NoProfile -ExecutionPolicy Bypass -File Tools/run_godot_tests.ps1
- powershell -NoProfile -ExecutionPolicy Bypass -File Tools/run_godot_full_suite.ps1
- powershell -NoProfile -ExecutionPolicy Bypass -File Tools/run_godot_scene_isolation.ps1 -ScenePath scenes/combat.tscn

REPORT FORMAT
1. Combat-specific problems solved
2. Files changed
3. Layout changes
4. Threat/readability improvements
5. Log/item/status changes
6. Tiny safe removals
7. Tests updated
8. Validation results
9. Risk / runtime verification notes
10. Ready for Part 6

STOP CONDITIONS — escalate first
- Combat rules değişmesi zorunluysa
- Save schema change
- Flow state change
- NodeResolve'a dokunmak gerekiyorsa
```

---

## Part 6 — Overlay Screens Unified Rework (MEDIUM RISK)

```
Bu pass event/reward/support_interaction/level_up/stage_transition/run_end ekranlarını birleşik UI ailesine bağlar.

KESİN BİLGİ — Başlangıç Noktası
- Event presenter: chip "ROADSIDE ENCOUNTER", title/summary/hint/badge/detail/outcome/button text builder'ları var, run_status = compact string
- Reward presenter: chip (COMBAT SPOILS/CACHE FIND/SALVAGE), context/hint text, offer view models, run_status = compact string
- Support interaction presenter: chip (SAFE REST/ROAD TRADE/FORGE SERVICE/VILLAGE REQUEST), title/summary/hint/action models, run_status = compact string
- Level up presenter: title/note/offer models VAR — ama run_status HİÇ YOK
- Stage transition presenter: title/summary ONLY — en minimal presenter, run_status HİÇ YOK
- Run end: audit sonrası doğrula
- scenes/event.gd mevcut; event ekranı ayrı scene script'i ile audit edilmeli
- TransitionShellPresenter: NodeResolve için content üretiyor, hâlâ aktif referansları var

Önce oku:
- AGENTS.md
- Docs/DOC_PRECEDENCE.md
- Docs/HANDOFF.md
- Docs/REWARD_LEVELUP_CONTRACT.md
- Docs/SUPPORT_INTERACTION_CONTRACT.md
- Docs/GDD.md
- Docs/VISUAL_AUDIO_STYLE_GUIDE.md

STRICT SCOPE
- scenes/event.tscn + scenes/event.gd
- scenes/reward.tscn + scenes/reward.gd
- scenes/support_interaction.tscn + scenes/support_interaction.gd
- scenes/level_up.tscn + scenes/level_up.gd
- scenes/stage_transition.tscn + scenes/stage_transition.gd
- scenes/run_end.tscn + scenes/run_end.gd
- Game/UI/event_presenter.gd
- Game/UI/reward_presenter.gd
- Game/UI/support_interaction_presenter.gd
- Game/UI/level_up_presenter.gd
- Game/UI/stage_transition_presenter.gd
- Game/UI/transition_shell_presenter.gd (NodeResolve hâlâ aktifse dikkat)
- Game/UI/safe_menu_overlay.gd
- Tests/test_non_combat_presenters.gd
- Tests/test_reward_presenter.gd
- Shared foundation helpers (Part 2'den)
- Minimal doc sync

DOKUNMA:
- MapExplore / Combat (zaten Part 4-5'te yapıldı)
- FAMILY_DISPLAY_NAMES / event label rename (map redesign pipeline)
- Runtime truth / save schema
- Flow state machine
- NodeResolve'u silme (hâlâ aktif flow'larda kullanılıyor olabilir — önce doğrula)

GOAL
Bütün overlay/decision/transition ekranları tek bir UI ailesi gibi hissettirsin:
1. Bu ekran ne?
2. Neden buradayım?
3. Kondisyonum ne?
4. Seçeneklerim ne?
5. Her seçenek ne veriyor/ne maliyeti var?
6. Primary vs secondary bilgi net
7. Nasıl devam ederim?

DESIGN REQUIREMENTS
A) CONSISTENT SCREEN SHELL
   Shared shell dili: title + context + compact run-state HUD + decision content + action area + secondary flavor

B) RUN-STATE VISIBILITY
   Level up ve stage transition'a run-status EKLE (şu an hiç yok).
   Event/reward/support'ta compact string yerine shared HUD kullan.

C) CHOICE CARD / ACTION CLARITY
   Her seçenek net göstersin: title, effect, cost, tradeoff, risk tone

D) HIERARCHY
   Primary: current decision, cost/benefit, run condition
   Secondary: supporting numbers, item/inventory relevance, stage context
   Tertiary: flavor prose, verbose explanation

E) PORTRAIT-SAFE
   Giant empty area yok, vertical overstacking yok, tiny buttons yok

F) OVERLAY / FLOW COHERENCE
   Overlay architecture korunsun.
   Event scene'in map_explore üzerinden overlay olarak açılma davranışı bozulmasın.

SPECIFIC SCREEN TARGETS
1. EVENT: narrative vs decision hierarchy, run-state HUD ekle, choice scan kolay
2. REWARD: offer comparison kolay, cost/tradeoff visible, run-state HUD iyileştir
3. SUPPORT: service/merchant/helper decision space, prices/costs obvious, run-state HUD iyileştir
4. LEVEL UP: gain/tradeoff explicit, run-state HUD EKLE (şu an yok)
5. STAGE TRANSITION: progression meaning clear, run-state HUD EKLE (şu an yok), same UI family
6. RUN END: outcome strong, summary readable, next action obvious

TESTS
- test_non_combat_presenters.gd: event/reward/support/level_up presenter assertion'ları güncelle
- test_reward_presenter.gd: reward-specific testler güncelle
- Yeni run-status integration testleri ekle

VALIDATION — REQUIRED
- py -3 Tools/validate_content.py
- py -3 Tools/validate_architecture_guards.py
- powershell -NoProfile -ExecutionPolicy Bypass -File Tools/run_godot_tests.ps1
- powershell -NoProfile -ExecutionPolicy Bypass -File Tools/run_godot_full_suite.ps1
- powershell -NoProfile -ExecutionPolicy Bypass -File Tools/run_godot_smoke.ps1

REPORT FORMAT
1. Cross-screen problems solved
2. Files changed
3. Shared shell/UI-language changes
4. Screen-specific improvements (subsection per screen)
5. Choice/consequence clarity improvements
6. Tiny safe removals
7. Tests updated
8. Validation results
9. Risk / runtime verification notes
10. Ready for Part 7

STOP CONDITIONS — escalate first
- Save schema change
- Flow state redesign
- NodeResolve silme gerekiyorsa (aktif flow varsa bırak)
- Overlay system broad rewrite gerektiriyorsa
```

---

## Part 7 — Cleanup / Dead UI / Stale Doc Removal (LOW RISK)

```
Bu pass UI rework sonrası ölü/parazit yapıları temizler.

Önce oku:
- AGENTS.md
- Docs/DOC_PRECEDENCE.md
- Docs/HANDOFF.md

Part 2-6 tarafından dokunulmuş dosyaları yeniden oku (checked-out state).

STRICT BOUNDARY
Cleanup pass. Yeni redesign DEĞİL.
- Gameplay rewrite yok
- Flow rewrite yok
- Save/schema change yok
- Source-of-truth ownership move yok

WHAT TO CLEAN

A) DEAD / DUPLICATED UI HELPERS
- Eski build_compact_status_text kullanıcıları hâlâ varsa ve yeni shared HUD'a geçildiyse: eski helper'ı retire et
- Duplicate formatter helpers
- Stale theme/panel helpers
- Presenter methods no longer called

B) STALE SCENE FRAGMENTS
- Unused nodes in reworked scenes
- Obsolete containers/labels/spacers
- Old layout scaffolding replaced

C) LEGACY FLOW-PRESENTATION REMNANTS
- NodeResolve: SADECE referans audit proof ile ölü kısımları temizle
  - Eğer hâlâ aktif flow'da kullanılıyorsa BIRAК
  - Sadece presentation debris varsa trim et
- Old full-screen assumptions in overlay scenes

D) ROOT / TEMP / MIGRATION ARTIFACTS
Referans audit yap:
- _tmp_map_capture.png + .import
- Root'taki planning note dump'ları (varsa)
Sadece non-authoritative ve non-runtime ise sil.

`codex_*.md` plan/prompt dosyaları cleanup adayı değildir; bunlar workflow materyalidir.

E) STALE DOCS
- Outdated wording from UI rework
- Stale references to old full-screen behavior
- Stale flow wording

REFERENCE-PROOF RULES
Her silme öncesi:
1. Referans ara
2. Aktif code'da hâlâ çağrılıyor/import ediliyor/mention ediliyor mu?
3. Scene node kaldırılırsa script hâlâ path ile erişiyor mu?
4. Kesinlik düşükse SILME, RAPORLA

Categories: CONFIRMED SAFE DELETE / KEEP / INVESTIGATE LATER / ESCALATE FIRST

DELETION SAFETY RULES
- Asset silinirse paired .import da sil
- Docs "eski" diye silme; non-authoritative ve pointless ise sil
- README'ye dokunma (zorunlu olmadıkça)
- CLAUDE.md / GEMINI.md / AGENTS.md silme
- Test/tool kanıtsız silme
- Save/flow compatibility surface silme

VALIDATION — REQUIRED
- py -3 Tools/validate_content.py
- py -3 Tools/validate_architecture_guards.py
- powershell -NoProfile -ExecutionPolicy Bypass -File Tools/run_godot_tests.ps1
- powershell -NoProfile -ExecutionPolicy Bypass -File Tools/run_godot_full_suite.ps1
- Scene wiring değiştiyse: powershell -NoProfile -ExecutionPolicy Bypass -File Tools/run_godot_smoke.ps1

REPORT FORMAT
1. Cleanup scope used
2. Confirmed safe deletes (each: path, type, why safe, evidence)
3. Kept on purpose (each: why)
4. Investigate later items
5. Escalate first items
6. Files changed
7. Doc truth-alignment changes
8. Validation results
9. Ready for Part 8

STOP CONDITIONS — escalate first
- Removal requires migration/back-compat policy
- Candidate touches save schema or stable IDs
- Cleanup reopens runtime truth ownership
- Candidate appears unused but evidence insufficient
```

---

## Part 8 — Final Review + Audit + Patch (LOW RISK)

```
Final closing pass. Repo'yu temiz, reviewable, handoff-ready bırak.

Önce oku:
- AGENTS.md
- Docs/DOC_PRECEDENCE.md
- Docs/HANDOFF.md
- Docs/TECH_BASELINE.md

Sonra Part 2-7 tarafından dokunulmuş tüm dosyaları yeniden oku.

Bu YENI REDESIGN pass'i DEĞİL.
Küçük hedefli fix'ler ve final doğrulama.

FINAL AUDIT CHECKLIST

A) OWNER / BOUNDARY CHECK
- MapRuntimeState runtime truth owner
- RunSessionCoordinator orchestration owner
- MapBoardComposerV2 derived presentation only
- Scene/presenter don't own gameplay truth
- Display labels not logic keys
- Save shape not drifted

B) CROSS-SCREEN UI CONSISTENCY CHECK
- Bütün ekranlar aynı UI ailesinde mi?
- Run-state HUD tutarlı mı?
- Primary/secondary/tertiary hierarchy tutarlı mı?
- Overlay family coherent mi?
- Geride kalan eski-stil ekran var mı?

C) COMBAT CLARITY CHECK
- Intent/threat/action clarity yeterli mi?
- Height-budget korundu mu?
- Log secondary mi?

D) OVERLAY / FLOW CHECK
- Event/reward/support/level_up overlay olarak MapExplore üstünde düzgün açılıyor mu?
- NodeResolve wiring tutarlı mı?
- Docs ile code arasında çelişki var mı?

E) RESOLUTION / SCALING CHECK
- 1080p desktop preview pratik mi?
- Portrait stability sağlam mı?

F) DOC TRUTH CHECK
Drift audit:
- HANDOFF.md
- DOC_PRECEDENCE.md (routing stale mi?)
- VISUAL_AUDIO_STYLE_GUIDE.md
- İlgili contract docs

G) CLEANUP VERIFICATION
- Part 7 dead references bırakmış mı?
- Dangling node paths var mı?
- Stale doc references var mı?

IMPLEMENTATION TASKS
1. Final audit restatement
2. Repo-wide static review
3. Small/medium final patch
4. Doc truth-alignment pass (HANDOFF.md mutlaka)
5. VALIDATION STACK (FULL):
   - py -3 Tools/validate_content.py
   - py -3 Tools/validate_architecture_guards.py
   - powershell -NoProfile -ExecutionPolicy Bypass -File Tools/run_godot_tests.ps1
   - powershell -NoProfile -ExecutionPolicy Bypass -File Tools/run_godot_full_suite.ps1
   - powershell -NoProfile -ExecutionPolicy Bypass -File Tools/run_godot_smoke.ps1
   - powershell -NoProfile -ExecutionPolicy Bypass -File Tools/run_godot_scene_isolation.ps1 -ScenePath scenes/map_explore.tscn
   - powershell -NoProfile -ExecutionPolicy Bypass -File Tools/run_godot_scene_isolation.ps1 -ScenePath scenes/combat.tscn
6. Runtime-oriented visual verification:
   - Overlay screens open correctly over MapExplore
   - Combat height budget preserved
   - No clipping/dead space/button crowding
   - Portrait targets: 1080x2400, 720x1280, 1366x768
7. Final cleanliness check
8. Final HANDOFF.md update

REPORT FORMAT — STRICT
1. Final audit summary
2. Final patches applied
3. Files changed
4. Truth-alignment fixes
5. Invariant check:
   - runtime truth ownership moved? yes/no
   - save shape changed? yes/no
   - flow-state shape changed? yes/no
   - display text as logic key? yes/no
6. Validation results (every command, passed/failed)
7. Runtime/visual verification results
8. Remaining risks
9. Repo readiness verdict: READY / READY WITH FOLLOW-UPS / ESCALATE FIRST
10. Updated handoff summary

STOP CONDITIONS — escalate first
- Save schema shape would change
- New flow state required
- Ownership move across runtime/application/UI
- Fixing reopens broad redesign scope
- Validation reveals deeper regression requiring separate pass
```

---

## Queue Kullanım Notları

1. **İç sıra**: Bu dosyanın kendi içinde Part 1 → Part 2 → Part 3 → Part 4 → Part 5 → Part 6 → Part 7 → Part 8

2. **Part 1 atlanabilir**: Bu dosyadaki "Doğrulanmış Gerçekler" tablosu zaten Part 1'in çoğunu kapsıyor. Ama Codex'in kendi audit'ini yapması daha güvenli.

3. **Global sırada öneri**:
   - UI Rework Part 1-3 önce çalışabilir
   - Eğer map redesign track aktifse, onun Part 1-8'ini bitir
   - Sonra UI Rework Part 4-8'e geç

4. **Part 4 ve Part 5 paralel çalışabilir**: MapExplore ve Combat birbirinden bağımsız ekranlar. İkisi de Part 2-3 ve varsa map redesign stabil state'i üstüne kuruyor. Aynı anda queue'ya koyulabilir (farklı branch'lerde) ama merge dikkat ister.

5. **Map redesign pipeline ile çakışma**:
   - UI foundation (`Part 1-3`) map redesign'dan önce olabilir
   - UI screen rework (`Part 4-8`) map redesign sonrası daha güvenli
   - İkisini AYNI ANDA çalıştırma
   - UI rework `FAMILY_DISPLAY_NAMES`'e dokunmasın
   - Map redesign Part 4 label'ı değiştirecek

6. **Toplam queue süresi tahmini**: Her part 30-90 dk. Toplam ~5-10 saat (overnight yeterli).

7. **Stop conditions** her partta tanımlı. Codex `escalate first` derse sonraki partı başlatma.

8. **Validation komutları**: Her part kendi validation setini içeriyor. Part 8 full stack koşuyor.
