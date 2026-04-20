# Dürüst Repo Değerlendirmesi — 2026-04-15

## Genel Hüküm

Repo spagetti değil. Mimari iskelet sağlam, dokümanlar tutarlı, validator'lar çalışıyor. Ama kod tarafında gerçek şişme ve tekrar var — bu "hissedilen" bir sorun değil, ölçülebilir bir sorun. Refactor promptları bu sorunların büyük kısmını hedefliyor ama birkaç spesifik bulguyu eklemek gerekiyor.

---

## Kod Durumu — Dosya Bazlı Dürüst Değerlendirme

### Gerçekten Şişmiş Dosyalar (Müdahale Gerekli)

**scenes/map_explore.gd (1785 satır) — EN KRİTİK**
- combat.gd ile 120+ satır birebir kopyalanmış inventory card interaction kodu var
- Overlay open/close mantığı 4 kez tekrarlanmış (event, reward, support, level_up) — 200+ satır pure duplication
- `_remove_event_overlay()`, `_remove_support_overlay()`, `_remove_reward_overlay()` birebir aynı fonksiyon, sadece değişken adı farklı
- Tween pattern'ı 4 kez tekrar
- Gerçekçi hedef: 1785 → ~900 satır (yaklaşık %50 azalma mümkün)

**scenes/combat.gd (1839 satır) — KRİTİK**
- 40+ yerde aynı `get_node_or_null(...)` + null check + mutation pattern'ı tekrar ediyor
- 142 satırlık theme/styling kodu scene içinde — Game/UI'ya taşınmalı
- 189 satırlık responsive layout hesaplaması scene içinde — extract edilmeli
- Inventory drag logic map_explore.gd ile duplicate
- Gerçekçi hedef: 1839 → ~1200 satır

**combat_flow.gd + run_session_coordinator.gd — PAYLAŞILAN DUPLİKASYON**
- `_extract_consumable_use_profile()` fonksiyonu her iki dosyada birebir aynı (44 satır)
- Bu, shared utility eksikliğinin kanıtı — birisi bu problemi iki kez bağımsız çözmüş

### Büyük Ama Haklı Dosyalar (Şimdilik Dokunma)

**map_runtime_state.gd (1628 satır)** — Graph building, scatter algoritması, persistence. Karmaşıklık domain'den geliyor, koddan değil. Sadece 20-30 satır payload builder tekrarı var. HIGH RISK, düşük getiri. Dokunma.

**inventory_actions.gd (788 satır)** — Solid kod. `add_carried_weapon()` ve `add_carried_armor()` %90 aynı logic ama okunabilirlik için kabul edilebilir. Dokunma.

**safe_menu_overlay.gd (751 satır)** — Temiz UI kodu. 5-10 satır minor tekrar. Dokunma.

### Özet Tablo

| Dosya | Satır | Durum | Gerçek Sorun |
|---|---|---|---|
| map_explore.gd | 1785 | KRİTİK | 650+ satır pure duplication |
| combat.gd | 1839 | KRİTİK | 400+ satır extractable bloat |
| combat_flow.gd | ~1001 | ORTA | 44 satır shared duplicate |
| run_session_coordinator.gd | 777 | ORTA | 44 satır shared duplicate |
| map_runtime_state.gd | 1628 | İYİ | Domain complexity, dokunma |
| inventory_actions.gd | 788 | İYİ | Minor, dokunma |
| safe_menu_overlay.gd | 751 | İYİ | Temiz, dokunma |

---

## Doküman Durumu — Dürüst Değerlendirme

**Dokümanlar ÇOK İYİ.** Bu projenin en güçlü tarafı.

- SOURCE_OF_TRUTH.md ownership tablosu kodla birebir eşleşiyor (doğrulandı)
- ARCHITECTURE.md katman kuralları validator ile enforce ediliyor (ihlal yok)
- GAME_FLOW_STATE_MACHINE.md 12 flow state ile flow_state.gd enum'u birebir eşleşiyor
- CONTENT_ARCHITECTURE_SPEC.md 14 content family ile ContentDefinitions/ yapısı eşleşiyor
- AGENTS.md risk lane'leri kodla tutarlı
- DOC_PRECEDENCE.md routing tablosu doğru, circular reference yok
- 35 doc var, hiçbiri stale veya redundant değil — her birinin DOC_PRECEDENCE'da tanımlı amacı var

**Tek sorun:** HANDOFF.md'deki runtime spine "Event (via NodeResolve)" diyor ama overlay sistemi "popup on MapExplore" diyor. Bu bir çelişki değil tam olarak — NodeResolve data setup yapıyor, sonra overlay açılıyor — ama kullanıcı deneyiminde gereksiz ara ekran yaratıyor. Part 0 bunu hedefliyor.

**Debug/çöp:** Hiç `print()` debug statement'ı bulamadım. Geçici dosyalar da temizlenmiş. Repo temiz.

---

## Uzun Vadede Sıkıntısız Çalışabilir misin?

**Mimari olarak: EVET.** Katmanlama, ownership, validator, doc policy hepsi sağlam. Bu altyapı uzun vadeli çalışmaya uygun.

**Kod olarak: HAYIR, şu haliyle değil.** İki büyük risk var:

1. **Duplication debt:** map_explore.gd ve combat.gd arasında 120+ satır copy-paste var. Her ikisine de dokunacak herhangi bir değişiklik (inventory UI, overlay davranışı) iki yerde ayrı ayrı yapılmak zorunda. Bu, yeni özellik eklerken bug kaynağı.

2. **Monolithic scene scripts:** combat.gd 1839 satır olması, her küçük UI değişikliğinin çok büyük bir dosyada yapılması demek. AI modelleri büyük dosyalarda daha çok hata yapar, insan okuyucu daha çok kaybolur.

**Refactor sonrası: EVET.** Eğer promptlar başarılı olursa ve dosya boyutları gerçekten düşerse, uzun vadeli çalışma için sağlam bir zemin olur.

---

## Mevcut Promptlar Bu Riskleri Karşılıyor mu?

### Karşılanan Riskler

| Risk | Hangi Part | Nasıl |
|---|---|---|
| NodeResolve çift ekran | Part 0 | NodeResolve audit + removal |
| map_explore.gd overlay tekrarı | Part 0 + Part 2 | Overlay cleanup + extraction |
| combat.gd monolithic yapı | Part 1 + Part 2 | Dead code cleanup + UI extraction |
| AI patch kalıntıları | Part 1 | De-AIification pass |
| Doc/guard eksikliği | Part 3 | AGENTS.md guardrail + HANDOFF rewrite |
| Genel doğrulama | Part 4 | Bağımsız audit |

### EKSİK — Promptlara Eklenmesi Gereken Spesifik Bulgular

Aşağıdaki 3 spesifik duplication hiçbir prompt'ta açıkça hedeflenmemiş. Bunları Part 1 ve Part 2'ye ek olarak eklemek gerekiyor:

**1. Shared consumable parser duplication (Part 1'e ekle)**
- `_extract_consumable_use_profile()` fonksiyonu combat_flow.gd (~satır 869-912) ve run_session_coordinator.gd (~satır 737-777) arasında 44 satır birebir aynı
- Çözüm: Shared utility'ye extract et (Game/Application/ içinde küçük helper)

**2. Inventory card interaction duplication (Part 2'ye ekle)**  
- `_refresh_inventory_cards()`, `_connect_inventory_card_interactions()`, `_on_inventory_card_gui_input()` fonksiyonları combat.gd ve map_explore.gd arasında 120+ satır birebir copy-paste
- Çözüm: Game/UI/ içinde shared InventoryCardInteractionHandler'a extract et

**3. Overlay open/close pattern duplication (Part 2'ye ekle)**
- map_explore.gd içinde `open_event_overlay()`, `close_event_overlay()`, `open_support_overlay()`, `close_support_overlay()` vb. hepsi aynı pattern — 200+ satır tekrar
- Çözüm: Generic overlay lifecycle manager'a extract et

---

## Final Cevap

**Şu an ne durumdayız?**
Mimari ve dokümanlar çok iyi. Kod tarafında gerçek şişme var — ama bu spagetti değil, copy-paste debt. Ölçülebilir: ~650 satır pure duplication + ~400 satır extractable bloat.

**Şişme ve gereksiz kod var mı?**
Evet. map_explore.gd'nin yaklaşık %40'ı ve combat.gd'nin yaklaşık %30'u refactor edilebilir. İki dosya arasında 120+ satır birebir kopyalanmış kod var.

**.md'ler iyi kurulmuş mu?**
Evet, çok iyi. 35 doküman, hepsi güncel, hepsi kodla tutarlı, hiçbiri stale değil. Bu projenin en güçlü tarafı.

**Uzun vadede sıkıntısız çalışabilir misin?**
Refactor öncesi: riskli. Her yeni UI özelliği iki yerde ayrı ayrı yapılmak zorunda.
Refactor sonrası: evet, sağlam zemin olur.

**Promptlar riskleri gideriyor mu?**
Büyük kısmını evet. Ama 3 spesifik duplication eksik — yukarıda yazdım, bunları eklemek lazım.

**Bunları attıktan sonra iyi durumdayız diyebilir miyiz?**
Eğer Part 0-4 başarılı olursa ve dosya boyutları gerçekten düşerse: evet. Ama "başarılı oldu" demek için Part 4'ün (bağımsız audit) somut kanıt üretmesi lazım — satır sayıları düştü mü, duplication kalktı mı, testler geçiyor mu. O rapora bakana kadar "iyi durumdayız" demek erken.
