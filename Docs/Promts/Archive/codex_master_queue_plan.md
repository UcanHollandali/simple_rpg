# Codex Master Queue Plan — Tüm Pipeline'ların Birleşik Sıralaması

**Son güncelleme:** 2026-04-16
**Amaç:** 4 ayrı prompt dosyasındaki ~35 task'i çakışmasız bir sırada Codex kuyruğuna atmak.
**Hedef:** Playtest edilebilir, "iyi mi değil mi" kararı verilebilir bir oyun.

---

## 0 — Kaynak Dosyalar

| # | Dosya | Parçalar |
|---|---|---|
| A | `codex_refactor_plan.md` | Part 0–5 + Part 6 (grand audit) |
| B | `codex_ui_rework_prompts.md` | Part 1–8 |
| C | `codex_map_redesign_prompts.md` | Part 1–8 + Asset A1–A4 |
| D | `codex_migration_prompts.md` | Part 0–12 + Bonus A–F |

KESİN BİLGİ: Dört dosya da tek repo (`simple_rpg`) üzerinde çalışıyor. Her biri kendi track'inde yazılmış ama aralarındaki bağımlılıklar ve çakışmalar dosyalar arasında explicit olarak resolve edilmemiş. Bu dosya bu çakışmaları kapatıyor.

---

## 1 — Kritik Çakışmalar ve Çözümleri

### Çakışma #1 — Refactor Part 2 ↔ UI Rework Part 4/5 (combat.gd & map_explore.gd)
- **Durum:** Refactor Part 2 combat.gd ve map_explore.gd'den presentation extraction yapıyor. UI Rework Part 4/5 aynı dosyaları tamamen rework ediyor.
- **Risk:** Refactor Part 2 çıkarttığı kodu UI Rework Part 4/5 tekrar dokunup rework ederse iş çift yapılır; üstelik UI Rework farklı ayrıştırma tercih ederse refactor'ın çıkardığı helper'lar ölü kalabilir.
- **Çözüm:** Refactor Part 2'nin scope'unu daralt. Scene-local UI extraction'ı UI Rework'e bırak. Refactor Part 2 sadece **cross-cut / shared handler**'ları extract etsin (inventory_card_interaction, generic overlay lifecycle helper). combat.gd ve map_explore.gd'deki scene-local bloklara (theme application, responsive layout, height-budget) dokunmasın.
- **Edit uygulanacak dosya:** `codex_refactor_plan.md` Part 2.

### Çakışma #2 — UI Rework Part 2 foundation ↔ Migration Part 2/3/4 (HUD içeriği değişecek)
- **Durum:** UI Rework Part 2 shared HUD/run-status foundation kuruyor. Migration Part 2 (equipment slots), Part 3 (Guard/Defend/Shield), Part 4 (Perk) sonrası HUD gereksinimleri değişecek.
- **Risk:** UI Rework Part 2 mevcut HP/Hunger/Gold/Durability modeline göre kurulursa, migration sonrası Guard bar, shield indicator, perk summary, equipment slot summary için foundation yeniden yazılabilir.
- **Çözüm:** UI Rework Part 2 prompt'una **"future-proofing" notu** ekle: stat chip / bar pattern extensible olsun, yeni stat türleri (Guard, Shield durability, Perk count) eklenebilir olsun. Mevcut stat'lara bağımlı hardcode yapılmasın.
- **Edit uygulanacak dosya:** `codex_ui_rework_prompts.md` Part 2.

### Çakışma #3 — UI Rework Part 5 (Brace button hâlâ canlı) ↔ Migration Part 3 (Brace → Defend/Guard)
- **Durum:** UI Rework Part 5 combat UI'ı rework ederken Brace aksiyonu hâlâ aktif. Migration Part 3 Brace'i kaldıracak.
- **Risk:** UI Rework Part 5 Brace için UI kurarsa, Migration Part 3 sonrası bu UI yeniden yazılır. Çift iş.
- **Çözüm:** İki seçenek:
  - **Opsiyon A (önerilen):** UI Rework Part 5 Brace'i hâlâ Brace olarak çizer ama action slot'unu **generic "primary defensive action"** olarak kursun; Migration Part 3 sadece label + Guard bar eklesin. Generic action card pattern Part 2'den gelecek.
  - **Opsiyon B:** UI Rework Part 5'i Migration Part 3'ten sonraya al. Bu sefer UI Rework Part 4 (MapExplore) ile Part 5 (Combat) arasına migration giriyor — pipeline fragmente olur, kaçınılması iyi.
- **Karar:** Opsiyon A. UI Rework Part 5'e koordinasyon notu ekle.
- **Edit uygulanacak dosya:** `codex_ui_rework_prompts.md` Part 5.

### Çakışma #4 — Map Redesign Part 4 (event → Trail Event label rename) ↔ UI Rework Part 4 (MapExplore)
- **Durum:** UI Rework Part 4 zaten "FAMILY_DISPLAY_NAMES'e dokunma" diyor. Map Redesign Part 4 rename yapacak.
- **Risk:** Eğer Map Redesign UI Rework'ten sonra gelirse, UI Rework rework sırasında "Roadside Encounter" label'ı görecek; sonra Map Redesign rename yapacak ve UI Rework'ün assertion'larını kırabilir.
- **Çözüm:** **Map Redesign önce, UI Rework Part 4 sonra**. Bu zaten önerilen sıra. Ama Map Redesign Part 4'ün prompt'una "UI rework henüz başlamadı — label değişikliği commit edildiğinde UI Rework Part 4 bunu pickup edecek" notu ekle.
- **Edit uygulanacak dosya:** `codex_map_redesign_plan.md` Part 4.

### Çakışma #5 — Migration Part 10 (UI polish) ↔ UI Rework tamamı
- **Durum:** Migration Part 10 "stale label temizle, equipment/backpack ayrımını göster, Defend/Guard + shield HUD" diyor. UI Rework zaten shared foundation kurmuş olacak.
- **Risk:** Migration Part 10 "UI rework yokmuş gibi" yazılmış; tam UI rework yapacak gibi duruyor. Bu UI Rework'ün üstüne yazabilir veya tutarsızlık üretebilir.
- **Çözüm:** Migration Part 10 scope'unu hafiflet. "UI Rework Part 2 shared foundation'ı mevcut varsayımı" ile yaz. Migration Part 10 sadece:
  - Yeni stat türlerini (Guard, Shield, Perk) shared foundation'a plug et.
  - Yeni terminolojiyi (Defend, Guard, Perk, Equipment Slots) yerleştir.
  - Reward vs level-up ekran ayrımı zaten UI Rework Part 6'da yapıldı — sadece perk secimi UI'sı ekle.
- **Edit uygulanacak dosya:** `codex_migration_prompts.md` Part 10.

### Çakışma #6 — Refactor Part 0 (NodeResolve) ↔ UI Rework Part 6 (transition_shell_presenter)
- **Durum:** Refactor Part 0 NodeResolve'u potansiyel olarak kaldıracak. UI Rework Part 6 transition_shell_presenter'a dokunuyor ve "NodeResolve'u silme" diyor.
- **Risk:** Refactor Part 0 sonrası NodeResolve tamamen kalkarsa, UI Rework Part 6 transition_shell_presenter'ın zaten ölü olduğunu görür. Eğer kalırsa UI Rework Part 6 onu normal rework ediyor.
- **Çözüm:** Refactor Part 0'ın **önce** gelmesi yeterli. UI Rework Part 6 durumu zaten netleşmiş bulur. Ek edit gerekmez.

### Çakışma #7 — Migration Part 6 (Map/Node routing) ↔ Map Redesign Part 4/6 (Roadside/Event split)
- **Durum:** Migration Part 6 Hamlet, Roadside Encounter, Event Node'ları ayrıştırıyor. Map Redesign Part 4 Roadside/Event semantic split yapıyor.
- **Risk:** Eğer Map Redesign önce yapılmazsa, Migration Part 6 map redesign'ın çözmeye çalıştığı bug'ları (satır 321 destination consume) inheriting olarak çalışır.
- **Çözüm:** Map Redesign Part 4 **kesinlikle** Migration Part 6'dan önce yapılmalı. Bu zaten planda var. Ek edit gerekmez.

---

## 2 — Önerilen Queue Sırası (35 Task, Faz Faz)

### FAZ 1 — FOUNDATION CLEANUP (2 task, serial)
**Amaç:** Flow confusion ve low-quality AI patch residue'yi temizle.

| Q# | Task | Risk | Notes |
|---|---|---|---|
| 1 | Refactor Part 0 — Overlay / NodeResolve cleanup | Medium | Flow state değişebilir, save compat dikkat |
| 2 | Refactor Part 1 — GDScript stabilization | Low-Medium | Dead code removal, no mechanic change |

### FAZ 2 — UI FOUNDATION (3 task, serial)
**Amaç:** Shared UI language, scaling, foundation HUD.

| Q# | Task | Risk | Notes |
|---|---|---|---|
| 3 | UI Rework Part 1 — Audit (no-code) | Low | Sadece envanter |
| 4 | UI Rework Part 2 — Shared foundation (**future-proofed for migration**) | Medium | **Edit uygulanacak** |
| 5 | UI Rework Part 3 — Resolution/scaling | Low-Medium | project.godot + anchors |

### FAZ 3 — STRUCTURAL EXTRACTION (1 task, serial)
**Amaç:** Cross-cut shared helper extraction. Scene-local UI bırakılıyor UI Rework'e.

| Q# | Task | Risk | Notes |
|---|---|---|---|
| 6 | Refactor Part 2 — **Scope daraltılmış extraction** | Medium | **Edit uygulanacak:** sadece shared handlers, scene-local UI Rework'e bırak |

### FAZ 4 — MAP REDESIGN (8 task, serial)
**Amaç:** Topology fix + roadside bug fix + composer.

| Q# | Task | Risk | Notes |
|---|---|---|---|
| 7 | Map Part 1 — Audit (no-code) | Low | Bulgular zaten plan dosyasında, scope daraltılabilir |
| 8 | Map Part 2 — Runtime graph redesign | HIGH | Family count invariant, save compat |
| 9 | Map Part 3 — Family placement / roles | Medium | Contract floor preserve |
| 10 | Map Part 4 — Roadside bug fix + rename | HIGH | **Gameplay bug fix**, test update bilinçli. **Edit uygulanacak:** UI rework koordinasyon notu |
| 11 | Map Part 5 — Composer layout redesign | Medium | Ring dominance soften |
| 12 | Map Part 6 — Scene/presenter cleanup | Low | slot_factors fallback demote |
| 13 | Map Part 7 — Stale/dead + doc sync | Low | |
| 14 | Map Part 8 — Final review | Low | Map milestone kapanır |

**→ PLAYTEST CHECKPOINT 1:** Map değişikliği sonrası run oyna. Topoloji iyi mi? Roadside bug fix çalışıyor mu?

### FAZ 5 — UI SCREEN REWORK (4 task; Part 4+5 paralel olabilir)
**Amaç:** Screen-by-screen UI rework. Map label'lar stabil.

| Q# | Task | Risk | Notes |
|---|---|---|---|
| 15 | UI Rework Part 4 — MapExplore | Medium | **PARALEL PAIR** |
| 16 | UI Rework Part 5 — Combat (**Brace still live**) | Medium | **PARALEL PAIR**, **Edit uygulanacak:** generic action card notu |
| 17 | UI Rework Part 6 — Overlay screens | Medium | event/reward/support/level_up/stage_trans/run_end |
| 18 | UI Rework Part 7 — UI cleanup | Low | Dead helper temizle |

**Paralel not:** Q15 ve Q16 farklı scene'ler, aynı shared foundation üstüne kuruyor. Paralel gidebilir ama merge dikkat.

**→ PLAYTEST CHECKPOINT 2:** UI iyi mi okunur? Mobile-safe mi? 1080p desktop'ta sığıyor mu? (Bu aşamada oyun hâlâ eski mekaniklerle — Brace, shared inventory.)

### FAZ 5.5 — OPSİYONEL ASSET PROTOTYPE KIT (4 task, serial, önerilen yer)
**Amaç:** Map redesign + UI rework sonrası prototype map görsel kitini bağlamak. Final art değil; playtest/readability için geçici ama düzenli asset katmanı.

| Q# | Task | Risk | Notes |
|---|---|---|---|
| A1 | Map Asset A1 — Prototype asset audit | Low | |
| A2 | Map Asset A2 — Generate prototype map kit | Low | SVG/PNG + manifest |
| A3 | Map Asset A3 — Hook kit into board | Low | map board / presenter / scene'de code-light hookup |
| A4 | Map Asset A4 — Asset review + manifest sync | Low | |

**Kritik sıra notu:** Bu asset track kullanılacaksa en güvenli yer **Q18 sonrası, Q19 öncesi**. Böylece:
- map redesign code part'ları bitmiş olur
- UI Rework Part 4-7 map/presenter yapısını settle etmiş olur
- migration başlamadan önce prototype map görselleri bağlanmış olur

**→ OPSİYONEL PLAYTEST CHECKPOINT 2.5:** A4 sonrası map board readability, trail/clearing/node state okunurluğu, asset path kırığı var mı?

### FAZ 6 — REFACTOR AUDIT GATE (3 task, serial, GO/NO-GO)
**Amaç:** Migration öncesi temizlik ve readiness check.

| Q# | Task | Risk | Notes |
|---|---|---|---|
| 19 | Refactor Part 3 — Doc/Guard hardening + AppBootstrap freeze | Low | |
| 20 | Refactor Part 4 — Final review + audit | Low | Line count verify |
| 21 | Refactor Part 5 — **Pre-migration readiness GO/NO-GO** | Low | Bu gate NO-GO olursa Faz 7 başlatma |

### FAZ 7 — MIGRATION CORE (6 task; 0+1 paralel)
**Amaç:** Gerçek gameplay migration. High-risk core.

| Q# | Task | Risk | Notes |
|---|---|---|---|
| 22 | Migration Part 0 — Gameplay tunables central | Low | **PARALEL PAIR** |
| 23 | Migration Part 1 — Authority audit + plan | Low | **PARALEL PAIR**, no-code |
| 24 | Migration Part 2 — Inventory/Equipment | HIGH | **Save schema bump**, v5→v6 |
| 25 | Migration Part 3 — Combat Brace→Defend/Guard | HIGH | **Playable combat checkpoint** |
| 26 | Migration Part 4 — Progression XP→Perk | Medium-High | Save schema bump olabilir |
| 27 | Migration Part 5 — Item taxonomy | Medium | |

**→ PLAYTEST CHECKPOINT 3 (KRİTİK):** Q25 sonrası combat oyna. Defend/Guard + Shield + Dual wield sistem iyi hissettiriyor mu? Oyun hâlâ oynanabilir mi?

### FAZ 8 — CONTENT + ROUTING (4 task; 8+9 paralel)
**Amaç:** Yeni content pack'ler.

| Q# | Task | Risk | Notes |
|---|---|---|---|
| 28 | Migration Part 6 — Map/node routing (Hamlet/Roadside/Event/SideQuest) | Medium | |
| 29 | Migration Part 7 — Acquisition routing + content pack (weapons/shields/items) | Medium | Büyük content ekleme |
| 30 | Migration Part 8 — Event + Roadside content | Low-Med | **PARALEL PAIR** |
| 31 | Migration Part 9 — Enemy content | Low-Med | **PARALEL PAIR** |

### FAZ 9 — POLISH + TUNING (3 task; 10+11 paralel)
**Amaç:** Terminology + balance + cleanup. UI Rework zaten yapıldığı için Part 10 hafifletilmiş.

| Q# | Task | Risk | Notes |
|---|---|---|---|
| 32 | Migration Part 10 — UI label/term polish (**scope daraltılmış**) | Low | **PARALEL PAIR**, **Edit uygulanacak** |
| 33 | Migration Part 11 — Merchant/reward/stage tuning | Low | **PARALEL PAIR** |
| 34 | Migration Part 12 — Final legacy cleanup | Low | |

**→ PLAYTEST CHECKPOINT 4:** Full run (Stage 1 → Stage 3 boss). Balance iyi mi? Progression hissediliyor mu?

### FAZ 10 — GRAND FINALE (2 task, serial)
**Amaç:** End-to-end bağımsız doğrulama.

| Q# | Task | Risk | Notes |
|---|---|---|---|
| 35 | UI Rework Part 8 — Final UI audit (migration sonrası) | Low | Son UI pass |
| 36 | Refactor Part 6 — Post-everything grand audit | Low | Tüm pipeline doğrulama |

**→ PLAYTEST CHECKPOINT 5 (FINAL):** Tam oyun testi. "İyi oynanabilir mi?" kararı.

### OPSIYONEL — Migration Bonus (Faz 10 sonrası)

| Q# | Task | Kategori |
|---|---|---|
| B1 | Migration Bonus A — Durability profiles | Weapon identity |
| B2 | Migration Bonus B — Guard decay | Combat depth |
| B3 | Migration Bonus C — Roadside trigger diversity | World feel |
| B4 | Migration Bonus D — Hamlet personalities | Content variety |
| B5 | Migration Bonus E — Extra event/roadside | Content depth |
| B6 | Migration Bonus F — Extra enemy variants | Combat variety |

---

## 3 — Paralel Çalıştırılabilen Task Pair'leri (Özet)

KESİN BİLGİ (kaynak dosyalarda bahsedilen paralelizasyon):
- Migration Part 0 + Part 1 (Q22 + Q23) — migration dosyası önerisi
- UI Rework Part 4 + Part 5 (Q15 + Q16) — UI dosyası önerisi
- Migration Part 8 + Part 9 (Q30 + Q31) — migration dosyası önerisi
- Migration Part 10 + Part 11 (Q32 + Q33) — migration dosyası önerisi

VARSAYIM (Codex'in davranışına dayalı): Paralel çalıştırma farklı branch'lerde yapılmalı, merge sırasında conflict çıkabilir. Tek queue'da seri vermek daha güvenli ama daha yavaş.

---

## 4 — Playtest Checkpoints (Oyun Kararı Noktaları)

| # | Checkpoint | Ne Test Edilir | NO-GO ise |
|---|---|---|---|
| 1 | Q14 sonrası (Map milestone) | Topoloji, roadside fix, composer | Map geri al / ayrı fix pass |
| 2 | Q18 sonrası (UI milestone) | UI okunur mu, mobile-safe mi | UI Part 8'i erkene al |
| 2.5 | A4 sonrası (opsiyonel asset milestone) | Board readability, trail/clearing/node-state görsel bağları, broken asset path var mı | Asset hook/fallback pass |
| 3 | **Q25 sonrası (Combat migration)** | Defend/Guard/Shield hissi | **Kritik: migration'ı durdur** |
| 4 | Q34 sonrası (Content + tune) | Full run balance | Part 11 tuning tekrar |
| 5 | Q36 sonrası (Grand audit) | Her şey tutarlı mı | Final patch round |

Kullanıcı notu: "En azından play test seviyesi güzel mi değil mi kararını verebilirim" — Checkpoint 2 (UI) ve Checkpoint 3 (Combat) bu kararın esas verildiği noktalar.

---

## 5 — Önceki Promt Sıralama Açısından Ön Hazırlık (Eklenmesi Gerekenler)

### Faz 1 — Refactor Part 0 önüne eklenmesi gereken ön hazırlık
Refactor Part 0 NodeResolve'u sorgularken HANDOFF.md iç çelişkisini de düzeltiyor (iyi). Ön hazırlık gerekmez.

### Faz 2 — UI Rework Part 2 önüne eklenmesi gereken ön hazırlık
**Ek:** Part 2 prompt'una "Migration sonrası yeni stat türleri (Guard, Shield, Perk, Equipment slots) gelecek — shared HUD bunları plug-in olarak kabul etsin" notu eklenecek. **→ Edit #2**

### Faz 4 — Map Part 2 önüne eklenmesi gereken ön hazırlık
Map Part 1 audit zaten plan dosyasındaki bulguları input olarak kullanabilir. Redundant yapmak istemiyorsan Map Part 1 kısaltılmış versiyonda gidebilir veya skip edilebilir. **Öneri:** Map Part 1'i at ama scope'u "plan dosyasındaki bulguları verify et + drift envanteri çıkar" olarak daralt (plan dosyasında zaten önerilmiş).

### Faz 5 — UI Rework Part 5 önüne eklenmesi gereken ön hazırlık
**Ek:** UI Rework Part 5 Brace action slot'unu "generic primary defensive action card" olarak kursun notu. Migration Part 3 sadece label + Guard value doldursun. **→ Edit #3**

### Faz 7 — Migration Part 2 önüne eklenmesi gereken ön hazırlık
Migration Part 2 save schema bump yapacak. Refactor Part 5 (pre-migration readiness) zaten save roundtrip doğrulaması yapıyor — ön hazırlık yeterli.

### Faz 7 — Migration Part 3 önüne eklenmesi gereken ön hazırlık
Migration Part 3 combat resolver'ı rewrite. UI Rework Part 5 (Faz 5) Brace UI'ı generic kurmuş olmalı (Edit #3 sayesinde). Migration Part 3 sadece:
- Brace action'ı Defend action'a map et (label + behavior)
- Guard value CombatState'e ekle, HUD'da gösterilecek alan zaten var (shared foundation)
- Shield synergy wiring

### Faz 9 — Migration Part 10 önüne eklenmesi gereken ön hazırlık
Migration Part 10 scope'u hafifletilmiş (Edit #5). UI Rework zaten her şeyi rework etmiş. Part 10 sadece terim + yeni stat plug-in.

---

## 6 — Dosyalarda Uygulanacak Rafinasyonlar (Özet)

| Edit # | Dosya | Part | Değişiklik |
|---|---|---|---|
| 1 | `codex_refactor_plan.md` | Part 2 | Scope daraltma: combat.gd/map_explore.gd scene-local UI extraction UI Rework'e devrediliyor. Sadece cross-cut shared handlers burada extract edilecek. |
| 2 | `codex_ui_rework_prompts.md` | Part 2 | Future-proof notu: shared HUD extensible (Guard, Shield, Perk, Equipment slot için genişleyebilir) olsun. |
| 3 | `codex_ui_rework_prompts.md` | Part 5 | Brace action card generic "primary defensive action" olarak kurulsun ki Migration Part 3 minimal değişiklikle Defend'e geçsin. |
| 4 | `codex_migration_prompts.md` | Part 10 | UI Rework tamamlandı varsayımıyla scope hafifletildi. Sadece yeni stat plug-in + terminoloji. |
| 5 | `codex_map_redesign_plan.md` | Part 4 | UI Rework koordinasyon notu: label rename commit edildiğinde UI Rework Part 4 bunu pickup edecek. |

Bu 5 edit sıralı olarak bu dosyanın altındaki "Bölüm F — Uygulanan Edit Patches" kısmında gösterilecek (Codex'in her seferinde tüm dosyayı okumasına gerek kalmaması için özet yeterli).

---

## 7 — Queue'yu Nasıl Atacaksın

1. **Serial default.** Her prompt'u tek tek, önceki bitince atmak en güvenli. Paralel atmak istersen aynı faz içindeki "PARALEL PAIR" işaretli task'lerde yap.
2. **Checkpoint'lerde DUR.** Playtest checkpoints'larda queue'yu pause et, manuel oyna, kararını ver.
3. **GO/NO-GO gate'i ciddiye al.** Q21 (Refactor Part 5) NO-GO derse migration'a geçme.
4. **Edit sırası:** Her dosyaya attığın prompt'u, bu dosyanın belirttiği **rafine edilmiş hâliyle** at. Orijinal dosyadaki prompt'u değil, bu plan dosyasındaki **Edit** notlarıyla güncellenmiş hâlini kullan.

---

## 8 — Sonraki Adım

Bu plan onaylanırsa:
- Rafinasyon edit'leri kaynak dosyalara uygulanacak.
- Her task'i sırasıyla Codex queue'ya atabilirsin.
- Her playtest checkpoint sonrası oyun kararın (GO / NO-GO / ROLLBACK) ile devam.

**VARSAYIM:** Queue 30+ task = overnight batch'e sığmayabilir. Paralel pair'leri kullanmazsan tek session'da Faz 1–6 (Q1–Q21) tam, Faz 7–10 ayrı bir batch daha mantıklı.
