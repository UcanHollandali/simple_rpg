# Codex Audit & Review Görev Listesi — Repo Geneli Sağlık Taraması

Son güncelleme: 2026-04-18
Hedef: RuntimeState + Application + Scene + UI + Architecture + Maintainability katmanlarını sistematik tarayıp **bilinmeyen** sorunları raporlamak. Patch değil, **audit-first** yaklaşım.

## Nasıl Kullanılır

- Her prompt kendi başına Codex'e verilecek.
- **Tüm Faz A promptları REPORT-ONLY**: Codex kod değiştirmez, sadece `Docs/Audit/` altına markdown rapor yazar.
- Faz B, A1–A6 raporlarını okuyup tek bir önceliklendirilmiş patch backlog üretir — yine report-only.
- Gerçek patch'e geçiş, Faz B çıktısını sen (ve/veya ben) onayladıktan sonra ayrı bir görev olacak.

Önerilen sıra: **A1 → A2 → A3 → A4 → A5 → A6 → B1.** Audit sırası bağımsız da çalışır; sinerji A5 ve A6'nın önce A1–A4'ü okuması.

Ortak doğrulama komutları (her faz sonunda rapor dosyası üretildiğinde çalıştır):

```
py -3 Tools/validate_content.py
py -3 Tools/validate_assets.py
py -3 Tools/validate_architecture_guards.py
```

Dosya değişmediği için headless Godot suite gerekmiyor — ama Codex yanlışlıkla kod değiştirdiyse (ki değiştirmemeli), `run_godot_full_suite.ps1` de çalışmalı.

---

## Ortak Rapor Şablonu

Tüm audit promptları bu şablonu kullansın:

```markdown
# {Area} Audit — {YYYY-MM-DD}

## Scope
- Dosya listesi (absolute path + satır sayısı)
- Okunan authority doc'lar

## Findings

### Critical (ownership/save/flow ihlali)
- [C-1] {bulgu} — `path/to/file.gd:LN` — {risk açıklaması} — {öneri: escalate-first / guarded lane / fast lane}

### Major (davranışsal risk veya belirgin borç)
- [M-1] ...

### Minor (kolay kazanç, kozmetik, ölü kod)
- [m-1] ...

### Info (not / takip / şüphe)
- [i-1] ...

## Patch Candidates

| ID | Risk Lane | Effort | Value | File(s) | Blocker? |
|----|-----------|--------|-------|---------|----------|
| ... | ... | S/M/L | S/M/L | ... | evet/hayır |

## Open Questions (sen/insan onayı gereken)
- ...

## Not Changed
- (kod dokunulmadı — bu bir report-only audit)
```

Her bulgu mutlaka `dosya:satır` referansı içersin, **spekülasyon** ile **kesin tespit** ayrılsın (örn. "Confirmed: ..." / "Likely: ..." / "Unclear: ..."). Kullanıcı tercihi: *Kesin bilgi ile varsayımı ayır.*

---

## FAZ A1 — RuntimeState Audit

### Prompt A1

```
ROL: Godot 4 + typed GDScript üzerinde çalışan Simple RPG mühendisisin.
Bu görev REPORT-ONLY — kod DEĞİŞTİRME.

KURAL:
- AGENTS.md "High-Risk Escalate-First Lane" kapsamındaki alanlara dokunma.
- Sadece statik analiz ve grep tabanlı tarama yap.
- SOURCE_OF_TRUTH.md'yi authority kabul et; RunState/AppBootstrap
  compatibility accessor'ları OWNERSHIP anlamına gelmez.

GÖREV:
Game/RuntimeState/ klasörünün tamamını audit et ve
Docs/Audit/2026-04-18-runtimestate-audit.md raporunu yaz.

KAPSAM:
- Game/RuntimeState/run_state.gd
- Game/RuntimeState/inventory_state.gd
- Game/RuntimeState/map_runtime_state.gd
- Game/RuntimeState/character_perk_state.gd
- Game/RuntimeState/support_interaction_state.gd
- varsa diğer RuntimeState/*.gd dosyaları
- Docs/SOURCE_OF_TRUTH.md
- Docs/SAVE_SCHEMA.md
- Docs/REWARD_LEVELUP_CONTRACT.md (perk owner için)
- Docs/SUPPORT_INTERACTION_CONTRACT.md

TARAMA KRİTERLERİ:

1) Compatibility Accessor Haritası
   - RunState üzerindeki "Compatibility mirror only" yorumlu tüm alanları listele
     (current_node_index, weapon_instance, armor_instance, belt_instance,
     consumable_slots, passive_slots vb.).
   - Her biri için repo genelinde gerçek OKUMA ve YAZMA çağrılarını say.
   - Read-only olanları ayır; yazı yapan callers varsa RED FLAG olarak işaretle.

2) Save Schema Drift
   - InventoryState / MapRuntimeState / RunState serialization yüzeylerini
     SAVE_SCHEMA.md ile karşılaştır.
   - Dokümanda yazmayan saved field? -> Critical.
   - Dokümanda yazıp artık yazılmayan field? -> Major (silinmiş field'ın load
     tarafı hâlâ okuyor mu?).

3) Ownership Overlap
   - Aynı datayı birden fazla RuntimeState owner'ının yazdığı durum var mı?
   - Örn: hamlet request state hem MapRuntimeState hem RunState tarafında
     mı tutuluyor? Eğer öyleyse hangisi SOURCE_OF_TRUTH'a göre owner?

4) Getter Kompleksitesi
   - O(n) linear scan yapan @property/getter fonksiyonları
     (örn. inventory_state.gd'deki consumable_slots / passive_slots).
   - Her çağrıda allocate eden (duplicate / Array.new) getter'lar.

5) Legacy Naming
   - "brace", "side_mission_", "node_resolve", "armor_instance",
     "belt_instance" gibi eski dönem isimleri RuntimeState'te kalmış mı?
   - Her bulguyu "stable ID rename" mi yoksa "zaten eski ismine bağlı save"
     mi olarak sınıflandır.

6) Dead Field / Uncalled Helper
   - Public alan veya fonksiyon; repo içinde 0 caller'ı olan.
   - Test-only olanları ayır, tamamen ölü olanları "Minor" olarak listele.

RAPOR KURALLARI:
- Ortak rapor şablonunu kullan (yukarıda tanımlandı).
- Her bulgu için AGENTS.md risk lane tahminini belirt.
- Spekülasyon ile kesin tespit ayrımı net (Confirmed / Likely / Unclear).
- map_runtime_state.gd çok büyükse tam okumadan önce sembol/fonksiyon
  listesi çıkar, sonra hotspot bölümlere inerek incele.

DOKUNMA:
- RunState veya MapRuntimeState dosyasına YAZI YOK.
- Save schema'ya DOKUNMA.
- Test dosyalarına DOKUNMA.

ÇIKTI:
- Docs/Audit/2026-04-18-runtimestate-audit.md

BAŞARI:
- Rapor var, kod değişmemiş.
- py -3 Tools/validate_architecture_guards.py PASS.
- Bulunan her accessor/alan için "Used / Unused / Ambiguous" sınıflaması var.
```

---

## FAZ A2 — Application Layer Audit

### Prompt A2

```
ROL: Aynı rol.
Bu görev REPORT-ONLY.

KURAL:
- AGENTS.md "Medium-Risk Guarded Lane" alanı ama dokunmadan inceliyoruz.
- ARCHITECTURE.md ve GAME_FLOW_STATE_MACHINE.md'yi authority kabul et.
- Command/event naming için COMMAND_EVENT_CATALOG.md referans.

GÖREV:
Game/Application/ klasörünü audit et ve
Docs/Audit/2026-04-18-application-audit.md raporunu yaz.

KAPSAM:
- Game/Application/app_bootstrap.gd
- Game/Application/run_session_coordinator.gd
- Game/Application/save_runtime_bridge.gd
- Game/Application/combat_flow.gd
- Game/Application/game_flow_manager.gd
- Game/Application/inventory_actions.gd
- varsa diğer Application/*.gd
- Docs/ARCHITECTURE.md
- Docs/GAME_FLOW_STATE_MACHINE.md
- Docs/COMMAND_EVENT_CATALOG.md

TARAMA KRİTERLERİ:

1) Facade Expansion Risk
   - AppBootstrap üzerinde yeni gameplay-facing convenience method eklenmiş mi?
   - Her public method için: "Gerçekten Application'ın işi mi, yoksa scene/UI
     doğrudan owner'a gitmeli mi?"

2) Orchestration Scatter
   - Aynı flow transition'ı (örn. combat->reward->levelup) birden fazla
     Application dosyası mı yönetiyor?
   - Combat bitiş akışında ownership net mi yoksa RunSessionCoordinator +
     CombatFlow + GameFlowManager arasında parçalı mı?

3) Dead Command / Event Path
   - GameFlowManager.dispatch() gibi deprecated path var mı (CODEX_POLISH_PROMPTS
     Faz 1.1 zaten siliyor ama başka dead path var mı diye bak)?
   - 0 caller'ı olan application method?
   - Comment'inde "deprecated" / "legacy" / "compatibility" geçen fonksiyonlar.

4) State Machine Gap
   - GAME_FLOW_STATE_MACHINE.md'deki transition'lar kodda hepsi var mı?
   - Kodda var olup doc'ta olmayan transition var mı? (doc drift)
   - NodeResolve hâlâ bir transition source olarak çağrılıyor mu, yoksa
     sadece legacy fallback mi?

5) Error Recovery
   - Application method'ları invalid state için ne yapıyor? (silent return,
     assert, push_error, domain event?)
   - Tutarlı mı, her dosya farklı stil mi kullanıyor?

6) Autoload Kullanımı
   - AGENTS.md: "Do not add gameplay autoloads for convenience."
   - Application katmanı autoload'larla nasıl konuşuyor — doğrudan global
     referans mı, DI mi?
   - project.godot'taki autoload listesiyle karşılaştır.

7) Save/Load Orchestration
   - save_runtime_bridge.gd ve save_service.gd arasında yazma sorumluluğu
     nasıl bölünmüş?
   - Legacy save versiyonları (v1, v2, v5, v6, v7) için load path'leri hâlâ
     çağrılıyor mu, yoksa ölü kod mu?

RAPOR KURALLARI:
- Ortak rapor şablonu.
- Her bulgu için risk lane tahmini.
- Dead code bulguları Minor; ownership drift bulguları Major; flow gap
  bulguları Critical.

DOKUNMA:
- Application dosyalarına YAZI YOK.
- Doc'lara YAZI YOK.

ÇIKTI:
- Docs/Audit/2026-04-18-application-audit.md

BAŞARI:
- Rapor var, kod değişmemiş.
- py -3 Tools/validate_architecture_guards.py PASS.
```

---

## FAZ A3 — Scene Layer Audit

### Prompt A3

```
ROL: Aynı rol.
Bu görev REPORT-ONLY.

KURAL:
- AGENTS.md non-negotiables:
  - Do not move gameplay truth into UI.
  - Do not use display text as logic keys.
- scenes/ dosyaları UI ve composition yeri; gameplay truth değil.

GÖREV:
scenes/ klasörünü audit et ve
Docs/Audit/2026-04-18-scene-audit.md raporunu yaz.

KAPSAM:
- scenes/*.gd (özellikle combat.gd, map_explore.gd, main_menu.gd,
  support_interaction.gd, run_end.gd, reward.gd, event.gd, level_up.gd,
  stage_transition.gd, run_setup.gd, boot.gd, main.gd, node_resolve.gd,
  safe_menu_overlay.gd)
- scenes/*.tscn dosyaları (sadece okuma)

TARAMA KRİTERLERİ:

1) Gameplay Truth Leak
   - Scene içinde yerel olarak tutulan ama gerçek owner'ı RuntimeState olması
     gereken alanlar (örn. cached hp, cached gold, cached inventory) var mı?
   - UI'ın gerçek state yerine kendi local kopyasına baktığı bir yer var mı?
   - Scene içinde "if label.text == 'Defend':" gibi display-text-as-logic
     kullanımı var mı?

2) Duplicate Pattern
   - _apply_portrait_safe_layout, _apply_temp_theme, _configure_audio_players,
     _connect_viewport_layout_updates, _disconnect_viewport_layout_updates,
     _on_viewport_size_changed, _load_texture_or_null gibi fonksiyonlar
     kaç farklı scene dosyasında tekrarlanıyor?
   - Her tekrarın body'si IDENTICAL mi yoksa drift var mı?
   - CODEX_POLISH_PROMPTS Faz 2 zaten bunu extract etmeyi öneriyor; audit
     amacıyla kaç noktada tekrar olduğunu sayısal raporla.

3) Node Reference Fragility
   - get_node_or_null çağrı sayısını her scene için çıkar.
   - $NodePath kullanan ama path'i kolay kırılabilen yerler.
   - combat.gd'de 118 get_node_or_null var (önceki tespit); bunun kaçı
     initialization sonrası sürekli çağrılıyor (cache candidate)?

4) Lifecycle Doğruluğu
   - _enter_tree / _ready / _exit_tree / _notification kullanımları
     tutarlı mı?
   - queue_free edilmesi gereken ama edilmeyen child node?
   - create_tween ile yaratılıp hiç kill_tween çağrılmayan tween'ler?
   - Connected signal'ler exit'te disconnect ediliyor mu (özellikle bus'a
     bağlı olanlar)?

5) Legacy Scene
   - scenes/node_resolve.gd — HANDOFF diyor ki legacy bridge, live map-to-
     interaction path'inde değil. Gerçek çağrı sayısı nedir?
   - Hâlâ reachable mi? Hangi caller üzerinden?

6) Tsn/TRES Referans Sağlığı
   - .gd içindeki preload/load çağrılarının path'leri .tscn / .tres
     dosyalarında var mı? (missing resource risk)

RAPOR KURALLARI:
- Her bulgu için scene + satır referansı.
- Duplicate pattern için MATRIS ver: scene X pattern -> var/yok/drift.

DOKUNMA:
- scenes/ içine YAZI YOK.
- .tscn dosyalarına YAZI YOK.

ÇIKTI:
- Docs/Audit/2026-04-18-scene-audit.md

BAŞARI:
- Rapor var, kod değişmemiş.
- py -3 Tools/validate_architecture_guards.py PASS.
```

---

## FAZ A4 — UI Layer Audit

### Prompt A4

```
ROL: Aynı rol.
Bu görev REPORT-ONLY.

KURAL:
- AGENTS.md: "UI is presentation, not gameplay truth."
- Game/UI/ katmanı presenter/view; gerçek state RuntimeState'te.

GÖREV:
Game/UI/ klasörünü audit et ve
Docs/Audit/2026-04-18-ui-audit.md raporunu yaz.

KAPSAM:
- Game/UI/*.gd (combat_presenter.gd, inventory_presenter.gd,
  safe_menu_overlay.gd vb.)
- scenes/ tarafındaki UI helper dosyaları (overlap A3 ile; A4 sadece
  Game/UI/ klasörüne odaklanır)
- Docs/VISUAL_AUDIO_STYLE_GUIDE.md
- Docs/FIGMA_TRUTH_ALIGNMENT_PASS.md (reference-only)

TARAMA KRİTERLERİ:

1) Presenter/View Boundary
   - Presenter'lar doğrudan RuntimeState'e mi yazıyor yoksa command
     dispatch ile mi?
   - View katmanı kendi state'ini tutuyor mu, yoksa her frame re-derive
     mi ediyor?

2) Duplicate Formatter / Helper
   - HP/MP/gold/hunger formatting fonksiyonları birden fazla yerde mi
     tanımlı?
   - Icon loading, stat-color lookup, threshold text helper'ları
     duplicate mi?
   - Konsolidasyon fırsatlarını listele.

3) Portrait Layout Tutarlılığı
   - Target portrait resolutions: 1080x2400, 1080x1920, 720x1280.
   - Layout kodu hangi presenter'larda hard-coded pixel kullanıyor?
   - Safe area / margin / padding sabitleri tekrar ediyor mu?

4) Theme Usage
   - Theme resource kullanımı tutarlı mı yoksa bazı yerler inline
     stylebox/color kullanıyor mu?

5) Accessibility Smell
   - Tek başına color'a bağlı feedback var mı (color-blind risk)?
   - Font size / touch target hard-coded minimum altında mı? (mobile
     tap hedefi genellikle 44dp / ~88px civarı)

6) Dead UI Path
   - 0 caller'ı olan UI method?
   - Comment'inde "TODO: remove" / "legacy" / "deprecated" olan UI
     bileşeni?

7) Signal Lifecycle
   - UI signal'leri connect edilmiş ama disconnect edilmeyen noktalar.
   - Loop içinde connect çağrılıp duplicate subscription risk oluşturan
     yerler.

RAPOR KURALLARI:
- Her bulgu dosya+satır referanslı.
- Duplicate formatter bulguları Major.
- Accessibility bulguları Info kategorisinde; karar vermek senin.

DOKUNMA:
- Game/UI/ içine YAZI YOK.

ÇIKTI:
- Docs/Audit/2026-04-18-ui-audit.md

BAŞARI:
- Rapor var, kod değişmemiş.
- py -3 Tools/validate_architecture_guards.py PASS.
```

---

## FAZ A5 — Architecture Hardening Audit

### Prompt A5

```
ROL: Aynı rol.
Bu görev REPORT-ONLY.

KURAL:
- ARCHITECTURE.md authority.
- SOURCE_OF_TRUTH.md authority.
- Layer sırası: Core -> Application -> (RuntimeState owner'ları) -> UI / scenes.

GÖREV:
Repo geneli architecture hardening audit yap ve
Docs/Audit/2026-04-18-architecture-audit.md raporunu yaz.

KAPSAM:
- Game/Core/
- Game/Application/ (A2'de detaylı yapıldı; burada yukarıdan bakış)
- Game/RuntimeState/ (A1'de detaylı yapıldı; burada yukarıdan bakış)
- Game/Infrastructure/
- Game/UI/ (A4'te detaylı yapıldı; burada yukarıdan bakış)
- scenes/ (A3'te detaylı yapıldı; burada yukarıdan bakış)
- Docs/ARCHITECTURE.md
- Docs/SOURCE_OF_TRUTH.md
- Docs/COMBAT_RULE_CONTRACT.md
- Docs/MAP_CONTRACT.md
- Tools/validate_architecture_guards.py (kurallar bu dosyada)

TARAMA KRİTERLERİ:

1) Layer Boundary Violations
   - Game/Core/ içinde scenes/ ya da Game/UI/ referansı var mı? -> Critical.
   - scenes/ içinde Game/Core/ dosyasına doğrudan yazma (sadece read OK) var mı?
   - Game/Infrastructure/ gameplay davranışı mı çalıştırıyor yoksa sadece
     persistence / IO mu yapıyor?

2) Circular Dependency
   - preload-cycle var mı? (a.gd b.gd'yi preload ederken b.gd a.gd'yi ederse)
   - class_name referansları üzerinden implicit cycle var mı?

3) Hidden Side Effects
   - Getter/@property içinde state değiştiren (yazan) fonksiyonlar var mı?
   - "idempotent getter" varsayımını kıran yerler.

4) Command/Event Architecture
   - Command'ler tek yerden mi dispatch ediliyor?
   - Aynı event'i hem Core hem Application mı yayınlıyor (double emit)?
   - 0 producer veya 0 consumer'ı olan event?
   - COMMAND_EVENT_CATALOG.md'deki isimler kodda gerçekten var mı (drift
     kontrolü)?

5) Global Singleton / Autoload Abuse
   - project.godot autoload listesi.
   - Her autoload için: "Gerçekten gerekli mi, yoksa DI ile çözülebilir mi?"
   - AppBootstrap dışındaki her autoload'un erişim deseni ne?

6) Validation Guard Coverage
   - Tools/validate_architecture_guards.py hangi kuralları check ediyor?
   - Repo'da olup guard tarafından check edilmeyen kural var mı?
   - Guard tarafından check edilen ama artık geçerli olmayan kural?

7) Boundary Constants
   - Magic number hotspot'ları (örn. "0.75" guard decay rate, "14" node count,
     "3" roadside encounter cap).
   - Aynı sabit birden fazla owner'da mı tanımlı? (DRY fırsatı)
   - Content definition'lardan mı gelmeli yoksa hard-coded doğru mu?

RAPOR KURALLARI:
- Her Critical bulgu için "neden layer violation" açıkla.
- Circular dependency bulgusu için import zinciri göster.
- Magic number listesi için: değer + dosya:satır + önerilen konum.

DOKUNMA:
- Hiçbir .gd dosyasına YAZI YOK.
- validate_architecture_guards.py'ye YAZI YOK.

ÇIKTI:
- Docs/Audit/2026-04-18-architecture-audit.md

BAŞARI:
- Rapor var.
- py -3 Tools/validate_architecture_guards.py PASS.
```

---

## FAZ A6 — Maintainability Audit

### Prompt A6

```
ROL: Aynı rol.
Bu görev REPORT-ONLY.

KURAL:
- AGENTS.md "Maintainability Guardrails" bölümü referans.
- "500 satır üstü dosyalar extraction-first" kuralı.
- Naming: snake_case fonksiyon/değişken, PascalCase class_name.

GÖREV:
Repo geneli maintainability audit yap ve
Docs/Audit/2026-04-18-maintainability-audit.md raporunu yaz.

KAPSAM:
- Game/ + scenes/ tüm .gd dosyaları
- Tools/ (Python tooling genel sağlık)
- Tests/ (test yüzeyi kapsamı)

TARAMA KRİTERLERİ:

1) File Size Hotspot
   - Her .gd dosyası için satır sayısı.
   - 500+ olanları liste; HANDOFF'taki extraction-first hotspot listesi
     (`map_runtime_state.gd, combat.gd, map_explore.gd, map_board_composer_v2.gd,
     inventory_actions.gd, save_service.gd, run_session_coordinator.gd,
     inventory_state.gd, support_interaction_state.gd, combat_presenter.gd,
     safe_menu_overlay.gd, combat_flow.gd, inventory_presenter.gd`) ile karşılaştır.
   - Listede olmayıp 500+ olan yeni dosya var mı?

2) Function Length
   - 80+ satırlık fonksiyonları liste (dosya:fn_adı:satır_sayısı).
   - Erken return ile kolay bölünür mü diye not.

3) Cyclomatic Complexity Kaba Tahmini
   - if/elif/else, match, while, for iç içe 3+ seviye olan fonksiyonlar.
   - En karmaşık 10 fonksiyonu listele.

4) Naming Tutarlılığı
   - snake_case ihlalleri (fonksiyon adı camelCase olmuş).
   - "ent" / "enti" / "inst" gibi yarım kısaltmalar.
   - "brace" / "side_mission_" / "node_resolve" gibi legacy naming kullanımı
     (kod tarafı; stable ID / save key'leri DOKUNMA listesinde).

5) Comment Health
   - TODO / FIXME / HACK / XXX yorumlarını listele (dosya:satır:metin).
   - Stale olan (kodu eşleşmeyen) yorumları işaretle.
   - "Deprecated" yorumu olup hâlâ çağrılan fonksiyonlar.

6) Test Coverage Gap
   - Game/Core/ ve Game/Application/ içindeki public fonksiyonlardan
     Tests/ altında hiç referansı olmayanlar.
   - Smoke edilen ama birim testi olmayan akışlar.

7) Duplicate Code Block
   - 5+ satır birebir duplicate kod bloğu çiftlerini çıkar.
   - A3'te bulunan scene duplikasyonu dışında Game/ içinde duplicate?

8) Dead Code
   - 0 caller'ı olan public fonksiyonlar (Tests/ ve validate araçları hariç).
   - Hiç okunmayan field'lar.
   - Hiç dispatch edilmeyen command/event isimleri.

9) Tool/Script Sağlığı
   - Tools/ altındaki Python script'lerinden güncel olmayan / stale olan?
   - run_godot_*.ps1 runner'larının log/çıktı path'leri tutarlı mı?

RAPOR KURALLARI:
- Her kategori için TOPLU SAYI ver (örn. "500+ dosya sayısı: 13").
- En kritik 10 bulguyu "Top Offenders" tablosuna al.
- Dead code listesini ayrı bölüm yap — CODEX_POLISH_PROMPTS Faz 1 ile overlap
  eden bulguları belirt ama tekrarlama.

DOKUNMA:
- Hiçbir kod dosyasına YAZI YOK.

ÇIKTI:
- Docs/Audit/2026-04-18-maintainability-audit.md

BAŞARI:
- Rapor var.
- py -3 Tools/validate_architecture_guards.py PASS.
```

---

## FAZ B1 — Patch Backlog Sentezi

### Prompt B1

```
ROL: Aynı rol.
Bu görev REPORT-ONLY — sentez raporu.

KURAL:
- A1–A6 raporları girdi; sen sadece okur, birleştirir, önceliklendirirsin.
- CODEX_POLISH_PROMPTS.md zaten var olan patch planıyla çakışmayı tespit et.
- AGENTS.md risk lane sınıflandırması zorunlu.

GÖREV:
Docs/Audit/2026-04-18-*.md raporlarını oku ve
Docs/Audit/2026-04-18-patch-backlog.md tek bir önceliklendirilmiş plan üret.

KAPSAM:
- Docs/Audit/2026-04-18-runtimestate-audit.md
- Docs/Audit/2026-04-18-application-audit.md
- Docs/Audit/2026-04-18-scene-audit.md
- Docs/Audit/2026-04-18-ui-audit.md
- Docs/Audit/2026-04-18-architecture-audit.md
- Docs/Audit/2026-04-18-maintainability-audit.md
- CODEX_POLISH_PROMPTS.md (çakışma kontrolü için)

SENTEZ ADIMLAR:

1) Tüm bulguları tek bir ham listede topla (her satırda: kaynak rapor ID + bulgu
   özeti + dosya referansı + ham öneri).

2) CODEX_POLISH_PROMPTS ile çakışanları işaretle:
   - "covered by Faz X.Y"
   - aynı dosyaya değen ama farklı öneri varsa "conflict with Faz X.Y"

3) Grupla:
   - Risk Lane: Fast / Guarded / High-Risk-Escalate
   - Domain: RuntimeState / Application / Scene / UI / Architecture / Maintainability
   - Tip: Dead code kaldır / Owner clean / Extraction / Doc drift / Rename /
     Bug fix / Optimization

4) Öncelik skoru ver (Effort S/M/L × Value S/M/L):
   - "Quick Wins" = Fast lane + Low effort + High value
   - "Strategic" = Guarded lane + Medium effort + High value
   - "Escalate" = High-risk lane (plan yap, patch yapma)
   - "Optional" = Low value veya Low confidence

5) Önerilen sıra:
   - Blockerlar (save/flow/ownership kırıcı Critical bulgular)
   - Quick Wins
   - Strategic (önce doc drift, sonra extraction, sonra rename)
   - Escalate kümesi için ayrı "decision needed" bölümü
   - Optional kümesi

6) Her madde için:
   - ID (ör. P-01)
   - Başlık (tek satır)
   - Kapsam (dosya/fonksiyon)
   - Risk lane
   - Effort × Value
   - Doğrulama komutları
   - Kaynak audit bulgu ID'leri
   - CODEX_POLISH_PROMPTS referansı (varsa)

RAPOR FORMATI:

```markdown
# Patch Backlog — Audit Sentezi — 2026-04-18

## Executive Summary
- Toplam bulgu: X
- Critical: X | Major: X | Minor: X | Info: X
- Quick Wins: X | Strategic: X | Escalate: X | Optional: X
- CODEX_POLISH_PROMPTS ile çakışan: X
- Çakışmasız yeni iş: X

## Blockers (Critical, tercihen öncesinde escalate)
- [B-1] ...

## Quick Wins (Fast Lane)
- [P-01] ...

## Strategic (Guarded Lane)
- [P-10] ...

## Escalate-First (High-Risk)
- [E-1] ... — "decision needed"

## Optional / Low Confidence
- [O-1] ...

## Overlap Matrix
| Audit Finding | CODEX_POLISH_PROMPTS Ref | Action |
|---------------|--------------------------|--------|

## Open Questions (insan/sen karar)
- ...
```

DOKUNMA:
- Kod YOK.
- Audit raporlarını değiştirme — sadece oku.
- CODEX_POLISH_PROMPTS.md'ye yazma.

ÇIKTI:
- Docs/Audit/2026-04-18-patch-backlog.md

BAŞARI:
- Rapor var.
- Tüm A1–A6 bulguları backlog'ta referanslı.
- Her madde risk lane + effort + value etiketli.
- Çakışma matrisi eksiksiz.
```

---

## Faz Sonrası — Karar Noktası

Faz B1 çıktısı geldiğinde:

1. Sen (veya ben) backlog'u okuyup kabul/ret kararı veririz.
2. Kabul edilen Quick Wins + Strategic maddeleri için ayrı bir **Faz C — Patch Execution** prompt seti hazırlanır (report-only değil; her madde için AGENTS.md risk lane'ine uygun patch promptu).
3. Escalate kümesi için her biri ayrı escalation görüşmesi — doğrudan patch'e geçilmez.

## Dikkat Edilecekler

- **`Confirmed`**: Audit aşaması Codex tokenı harcar; her rapor 500–2000 satır arası olabilir. Faz A1–A6 peş peşe değil, 2'şer 2'şer sırayla çalıştırmak daha güvenli (ara ara okumalar).
- **`Confirmed`**: Rapor dosyaları `Docs/Audit/` altında. `Docs/DOC_PRECEDENCE.md`'ye göre audit raporları authority değil, reference-only. Eğer bu klasör DOC_PRECEDENCE'te listelenmiyorsa Codex'e "Docs/Audit/ reference-only, authority doc değil" diye açıkça söyle.
- **`Confirmed`**: CODEX_POLISH_PROMPTS.md'deki patch'ler audit bulgularıyla çakışabilir; B1 çakışma matrisi bunu çözer.
- **`Inferred`**: Audit sonrası patch kümesi CODEX_POLISH_PROMPTS'un %30–60'ı kadar büyüyebilir (gerçek bulgu sayısı audit'ten sonra belli olur).

## `Confirmed` Kısıt

- Bu dosya sadece Codex'e verilmek üzere hazırlandı. Cloud sandbox tarafından da okunabilir ama gerçek çalıştırma Windows-local Codex üzerinden olacak.
- Audit'in kendisi hiçbir gameplay / save / flow ownership değiştirmiyor; dolayısıyla AGENTS.md "Escalation Triggers" bu dosyanın çalıştırılması için tetiklenmez.
