# SIMPLE RPG - Foundation Migration: Codex Prompt Serisi

Bu dosya, repo'yu yeni gameplay foundation'a taşımak icin hazırlanmıs Codex prompt'larını icerir.
Her part bağımsız bir Codex chat olarak calistırılabilir.
Part sırası önemlidir; her part bir öncekinin tamamlanmıs olmasını bekler.

> **Not:** Her prompt'un basında agent'a `AGENTS.md`, `Docs/DOC_PRECEDENCE.md`, `Docs/HANDOFF.md` ve ilgili authority doc'ları okumasını söyleyin. Bu dosyada tekrar etmiyorum ama Codex chat'inde agent'ın bunu ilk is olarak yapması gerekir.

---

## PART 0 — Gameplay Tunables Merkezilestirme

**Risk:** Düsük  
**Tahmini scope:** Küçük

### Prompt

```
Bu repo icin gameplay tunables'ı merkezilestir. Henüz büyük gameplay refactor yapma.

Önce AGENTS.md, Docs/DOC_PRECEDENCE.md ve Docs/HANDOFF.md oku. Sonra repo genelinde gameplay'i etkileyen tüm hardcoded sayıları bul.

En az su aileleri merkezi config'e tası:
- base inventory capacity (su an 5)
- belt capacity bonus (su an +2)
- hunger move cost (su an 1)
- hunger combat tick cost (su an 1)
- hungry threshold (su an 6) ve penalty (-1 attack)
- starving threshold (su an 2) ve penalty (-2 attack)
- starvation HP loss (su an 1)
- brace damage multiplier (su an 0.5) — ileride defend/guard'a dönüsecek
- rest HP gain (su an 8) ve hunger cost (su an 4)
- xp thresholds (su an 10/25/45/70)
- blacksmith upgrade costs ve etkileri
- fallback attack damage

Davranıs degistirme. Sadece magic number'ları merkezi config'e tası.
Ilgili docs'ta "tunable vs hard rule" ayrımını yaz.
Test: mevcut davranıs bozulmamıs olmalı.
```

---

## PART 1 — Authority Audit ve Migration Plan

**Risk:** Düsük (sadece doc isı)  
**Tahmini scope:** Orta

### Prompt

```
Bu repo icin yeni foundation'a gecis hazırlıgı yap. Büyük gameplay refactor yapma; sadece audit + authority + migration plan.

Önce AGENTS.md, Docs/DOC_PRECEDENCE.md ve Docs/HANDOFF.md oku.
Sonra su dosyaları tara:
- root .md dosyaları
- Docs/ icindeki tüm authority doc'lar
- Game/RuntimeState/ (inventory_state.gd, run_state.gd, map_runtime_state.gd)
- Game/Core/ (combat_resolver.gd)
- Game/Application/ (combat_flow.gd, reward_application_policy.gd)
- ContentDefinitions/ klasör yapısı
- save/load tarafı (Game/Infrastructure/save_service.gd)

Yeni hedef foundation:
- equipment slots: Right Hand, Left Hand, Armor, Belt (ayrı, backpack slot yemez)
- backpack: base 5 slot, belt bonusu ile artar
- passive item'lar backpack'te tasınır, yer kaplar, tasındıgı sürece bonus verir
- Brace kalkacak, yerine Defend + Guard gelecek
- shield = left-hand savunma ekipmanı, Defend'i güclendiren
- dual wield = loadout modifier (ilk asamada ikinci bagimsiz attack engine degil)
- XP -> Character Perk (item degil)
- Event Node / Roadside Encounter / Hamlet Request sorumlulukları ayrılacak
- shield attachment (dar, authored, sadece shield'a takılan)

Bu part'ta yap:
1. Mevcut truth haritasını cıkar (hangi dosya neyin authority'si).
2. Yeni foundation ile catısan eski truth'leri tespit et.
3. Migration part sırasını öner.
4. Hangi .md dosyalarının güncellenmesi/deprecated edilmesi gerektigini listele.
5. Riskli alanları isaretle.

Cıktı formatı:
A) Mevcut sistem özeti
B) Stale/catısan truth alanları
C) Önerilen migration part sırası
D) Güncellenecek/deprecated docs listesi
E) En riskli alanlar

Büyük gameplay refactor yapma. Sadece küçük ve güvenli doc cleanup serbest.
```

---

## PART 2 — Inventory / Equipment Migration

**Risk:** Yüksek (save schema degisir, RunState degisir)  
**Tahmini scope:** Büyük

### Prompt

```
Inventory ve equipment modelini yeni foundation'a tasI. Bu gerçek migration part'ıdır.

Önce AGENTS.md, Docs/DOC_PRECEDENCE.md, Docs/HANDOFF.md ve Part 1'de güncellenen authority doc'ları oku.
Sonra oku: inventory_state.gd, run_state.gd, save_service.gd, combat_flow.gd (sadece equipment baglantıları), starter loadout, item schema'lar, inventory UI dosyaları.

Yeni canonical model:
- Equipment slots (ayrı, backpack slot yemez):
  - Right Hand (weapon)
  - Left Hand (shield veya offhand weapon)
  - Armor
  - Belt
- Backpack:
  - base 5 slot (merkezi config'den oku)
  - belt kapasite bonusu ile artar
- Backpack icinde tasınır: consumables, passive items, spare gear, quest items
- Passive item'lar equip slot istemez, backpack'te yer kaplar, tasındıgı sürece pasif bonus saglar
- Belt'in canonical rolü inventory utility'dir (combat-stat ana sınıfı degil)

Bu part'ta yap:
1. Player state'i explicit equipment slots + backpack modeline gecir.
2. Eski shared/common inventory mantıgını canonical olmaktan cıkar.
3. Backpack capacity validator'ı yeni modele göre kur.
4. Equipped gear ile carried item ayrımını netlestir.
5. Save/load migration yap. save_schema_version artır.
6. Starter loadout'u yeni sisteme bagla.
7. Item schema'da slot compatibility alanlarını ekle (right_hand, left_hand, offhand_capable).
8. UI'da equipment slots ile backpack'i acık ve user-friendly sekilde ayır.
9. Stale label, stale docs, eski shared inventory truth'lerini temizle.

Bu part'ta yapma:
- Brace/Defend combat refactor
- Shield combat davranıs kurulumu
- Dual wield combat cözümlemesi
- XP/perk migration

Ama hazırlık olarak:
- Right Hand / Left Hand veri modelini temiz kur
- Shield ve offhand compatibility alanlarını ac

Minimum validation:
- validate_content.py
- validate_architecture_guards.py
- test_save_file_roundtrip.gd
- Godot full suite
- Godot smoke

Cıktıda ver: degisen dosyalar, güncellenen docs, kaldırılan legacy truth'ler, kalan riskler.
```

---

## PART 3 — Combat Foundation Migration (Brace -> Defend/Guard)

**Risk:** Yüksek (combat resolver yeniden yazılır)  
**Tahmini scope:** Büyük

### Prompt

```
Combat foundation'ı yeni modele tasI. Bu gerçek gameplay refactor part'ıdır.

Önce AGENTS.md, Docs/COMBAT_RULE_CONTRACT.md, ve önceki part'larda güncellenen tüm ilgili doc'ları oku.
Sonra oku: combat_flow.gd, combat_resolver.gd, combat state dosyaları, combat HUD/UI, item schema'lardaki weapon/shield/armor tanımları.

Yeni canonical combat model:
- Ana aksiyonlar: Attack, Defend, Use Item
- Brace kaldırılacak
- Herkes Defend yapabilir
- Defend temporary Guard üretir (Guard degeri config-driven)
- Guard gelen hasarı HP'den önce emer
- Shield (Left Hand) varsa Defend daha güclü Guard üretir (shield_defend_bonus config'den)
- Right Hand ana saldırı profilini belirler
- Left Hand:
  - shield ise savunma/guard katkısı
  - weapon ise dual wield modifier (attack bonus + defend/guard penalty, config-driven)
- Dual wield ikinci bagimsiz attack engine DEGILDIR
- Combat ici equip juggling canonical DEGILDIR (armor/belt swap yok)

Damage order (tek truth olarak yaz ve code/docs'a isle):
1. Raw damage hesapla (base + bonuslar)
2. Armor flat reduction uygula
3. Kalan Guard'dan düs
4. Kalan HP'den düs
5. Brace yerine artık bu sıra gecerli

Bu part'ta yap:
1. Brace action ve tüm Brace referanslarını kaldır.
2. Defend action ekle.
3. Guard state'ini CombatState'e ekle.
4. Damage order'ı yukarıdaki sıraya göre kur.
5. Shield synergy'yi config-driven bagla.
6. Dual wield modifier'ı config-driven bagla.
7. Combat ici equip/unequip akısını ciddi bicimde daralt veya kaldır.
8. Combat log'u yeni terimlere göre güncelle.
9. COMBAT_RULE_CONTRACT.md'yi yeni sisteme göre yeniden yaz.
10. UI: Brace butonunu kaldır, Defend getir; Guard degeri görünür olsun.

Bu part'ta yapma:
- XP/perk migration
- Acquisition/reward expansion
- Map/node refactor

Minimum validation:
- combat_resolver testleri
- test_save_file_roundtrip.gd
- Godot full suite
- Godot smoke

Cıktıda ver: degisen dosyalar, güncellenen docs, kaldırılan Brace/legacy truth'ler, yeni combat canonical özeti, kalan riskler.
```

---

## PART 4 — Progression Migration (XP -> Character Perk)

**Risk:** Orta-Yüksek (save schema degisebilir)  
**Tahmini scope:** Orta

### Prompt

```
XP/level-up/progression sistemini inventory'den ayırıp Character Perk modeline tasI.

Önce AGENTS.md, Docs/REWARD_LEVELUP_CONTRACT.md ve önceki part'larda güncellenen doc'ları oku.
Sonra oku: level_up_state.gd, reward_state.gd, reward_application_policy.gd, player state, save/load, reward/level-up UI dosyaları.

NOT: Mevcut repo'da level-up zaten item vermiyor (heal/repair/xp/gold veriyor). Ama level-up ile item arasındaki kavramsal ayrım net degil ve perk sistemi yok. Bu part bunu kuruyor.

Yeni canonical progression model:
- XP kazanımı korunacak
- Level threshold sistemi korunabilir
- Level-up item VERMEZ
- Level-up = 1-of-3 Character Perk secimi
- Character Perk:
  - inventory item degil, backpack'te tasınmaz
  - equip edilmez, drop olmaz
  - run ici kalıcı karakter bonusu
- Perk aileleri: offense, defense, survival, economy/route
- Passive item sistemi oyunda kalacak (backpack'te, yer kaplar, progression degildir)

Bu part'ta yap:
1. Character Perk state modeli ekle.
2. Level-up anında perk secim akısını kur.
3. Minimal ama temiz ilk perk havuzu bagla (her aileden en az 2-3 perk).
4. Perk application logic'ini kur.
5. Reward flow ile level-up flow'u birbirinden net ayır.
6. Save/load migration yap.
7. UI'da level-up ekranı "item ödülü" gibi görünmesin; perk secimi olsun.
8. Passive item ile perk kullanıcı acısından karısmasın.
9. Stale docs ve label'ları temizle.
10. REWARD_LEVELUP_CONTRACT.md'yi güncelle.

Bu part'ta yapma:
- Acquisition/merchant/reward content expansion
- Map/hamlet refactor
- Büyük balance pass

Minimum validation:
- test_save_file_roundtrip.gd
- Godot full suite
- Godot smoke

Cıktıda ver: degisen dosyalar, güncellenen docs, kaldırılan legacy progression truth'ler, kalan riskler.
```

---

## PART 5 — Item Taxonomy Temizligi

**Risk:** Orta  
**Tahmini scope:** Orta

### Prompt

```
Item taxonomy'yi yeni canonical modele göre temizle.

Önce AGENTS.md, Docs/CONTENT_ARCHITECTURE_SPEC.md ve önceki part'larda güncellenen doc'ları oku.
Sonra oku: ContentDefinitions/ altındaki tüm item JSON'lar, item schema yapısı, inventory/equipment state, save/load, item UI dosyaları.

Yeni canonical item sınıfları:
- Right-hand weapon (slot: right_hand)
- Left-hand shield (slot: left_hand, subtype: shield)
- Offhand-capable weapon (slot: right_hand + left_hand, uygun oldugunda)
- Armor (slot: armor)
- Belt (slot: belt, canonical rol: inventory utility)
- Passive Item (slot: yok, backpack'te tasınır, yer kaplar)
- Consumable (slot: yok, backpack'te tasınır)
- Quest Item (slot: yok, backpack'te tasınır, normal loot ile karısmaz)
- Shield Attachment (slot: yok, item olarak backpack'te; shield'a takılınca shield state'inin parcası)

Kritik kurallar:
- Belt'in canonical rolü inventory utility; combat-stat ana sınıfı olmasın
- Passive item perk degildir
- Quest item normal loot gibi davranmasın
- Shield attachment V1'de sadece shield destekler

Bu part'ta yap:
1. Mevcut item schema'ları yeni taxonomy'ye göre yeniden düzenle.
2. Weapon'lara handedness/slot compatibility alanlarını netlestir.
3. Shield desteğini true left-hand item olarak standardize et.
4. Belt'leri inventory utility sınıfına cek.
5. Passive item ile perk ayrımını schema/code düzeyinde netlestir.
6. Quest item ailesini acıkca destekle.
7. Shield attachment icin temiz bir veri modeli kur:
   - ayrı item tipi
   - shield'a takılıp cıkarılabilir
   - her shield en fazla 1 attachment
   - combat dısında takılır/cıkarılır
   - backpack'te bos yer yoksa detach yapılamaz
8. Mevcut content'i yeni taxonomy'ye göre convert et.
9. Save/load'u yeni type sistemine uyumlu hale getir.
10. UI item grouping/tooltip/category'yi güncelle.
11. Ilgili docs'u güncelle ama docs kalabalıgı üretme.

NOT: Repo'da zaten var olan item'lar (lean_pack_token, marchwarden_talisman, trailhook_bandolier vb.) yeni taxonomy'ye adapt edilecek, sıfırdan yazılmayacak.

Bu part'ta yapma:
- Acquisition expansion
- Büyük content pack ekleme
- Map/node routing refactor

Minimum validation:
- validate_content.py
- validate_architecture_guards.py
- test_save_file_roundtrip.gd
- Godot full suite

Cıktıda ver: degisen dosyalar, güncellenen docs, dönüstürülen legacy item truth'ler, kalan riskler.
```

---

## PART 6 — Map / Node / Content Routing Temizligi

**Risk:** Orta  
**Tahmini scope:** Orta

### Prompt

```
Map, node, traversal ve side-content sorumluluklarını temiz bir yapıya oturt.

Önce AGENTS.md, Docs/MAP_CONTRACT.md, Docs/SUPPORT_INTERACTION_CONTRACT.md ve önceki part doc'larını oku.
Sonra oku: map_runtime_state.gd, map generation kodu, node resolve akısı, event/roadside/hamlet/side quest routing, map UI dosyaları.

Yeni canonical ayrım:
- Event Node = node'a girince calısan authored olay (mevcut event sistemi)
- Roadside Encounter = node'dan node'a yürürken cıkan traversal overlay (ayrı node tipi degil)
- Hamlet = support ailesi icinde ayrı yerlesim/köy etkilesimi; side quest + özel ödül yüzeyi
- Side Quest = haritada mevcut node'ları isaretleyebilen ayrı system

Support alt türleri:
- Rest
- Merchant
- Blacksmith
- Hamlet (yeni)

Bu part'ta yap:
1. Event Node ile Roadside Encounter'ı ayrı code path ve icerik yüzeyi yap.
2. Hamlet'i Support icinde net bir alt tür olarak oturt.
3. Side quest isaretleme akısını map sorumlulugundan ayır.
4. Roadside encounter akısını node cözümlemesinden temiz ayır.
5. Map graph generation'ı gereksiz yere bozma; sadece taxonomy ve routing rafine et.
6. Stale docs ve eski side_mission/event/roadside karısıklıklarını temizle.
7. MAP_CONTRACT.md ve SUPPORT_INTERACTION_CONTRACT.md'yi güncelle.

Hamlet quest hook'larını hazırla (henüz icerik yazmak zorunda degilsin ama hooklar calisır olsun):
- hunt_marked_enemy
- deliver_supplies (quest item tasıma)
- rescue_missing_scout
- bring_proof (kanıt quest item'ı)

Bu part'ta yapma:
- Büyük authored content expansion
- Combat/progression yeniden acma
- Procedural map üretimini bastan yazma

Minimum validation:
- test_map_runtime_state.gd
- validate_content.py
- Godot full suite
- Godot smoke

Cıktıda ver: degisen dosyalar, güncellenen docs, kaldırılan legacy routing truth'ler, kalan riskler.
```

---

## PART 7 — Acquisition Routing + Ilk Content Pack

**Risk:** Orta  
**Tahmini scope:** Büyük

### Prompt

```
Acquisition routing'i kur ve ilk authored content pack'i oyuna bagla.

Önce AGENTS.md ve önceki part'larda güncellenen tüm ilgili doc'ları oku.
Sonra oku: reward routing, merchant stock, event/roadside/hamlet/quest content, mevcut item havuzları.

Canonical acquisition model:
- Perks: sadece level-up
- Consumables: merchant, event, roadside, reward
- Weapons: merchant, reward, hamlet reward
- Shields: merchant, reward, hamlet reward
- Armor: merchant, reward, hamlet reward
- Belts: merchant, hamlet reward, nadiren event
- Passive items: reward, hamlet reward, event, nadiren merchant
- Shield attachments: agırlıklı hamlet/quest reward, nadiren özel reward
- Quest items: sadece quest akısı

Bu part'ta yap:

1. ACQUISITION ROUTING:
   - Reward routing'i dar eski ailelerden cıkar.
   - Merchant stock'larını yeni taxonomy'ye göre genislet.
   - Hamlet reward'larını özel ve build-acan yap.
   - Roadside/event tarafında küçük ama gercek item/source giris ac.

2. WEAPON CONTENT (mevcut repo'da olanları adapt et, yenilerini ekle):
   Repo'da zaten var: iron_sword, forager_knife, splitter_axe, watchman_mace, thorn_rapier, moonspur_pike, emberhook_blade, salvage_cleaver
   Yeni ekle:
   - Bandit Hatchet (offhand-capable, dual wield'e uygun, hızlı/kirli his)
   - Briar Knife (offhand-capable, bleed temalı)
   - Gatebreaker Club (agır, savunma kırıcı his)
   - Warden Spear (güvenli, düzenli right-hand)

3. SHIELD CONTENT (tamamen yeni):
   - Watchman Shield (temel/dengeli, ögretici)
   - Thornwood Buckler (hafif/agresif)
   - Gatewall Kite Shield (agır, güclü defend/guard)
   - Pilgrim Board (survival temalı, orta)

4. PASSIVE ITEM CONTENT (mevcut olanları adapt et, yenilerini ekle):
   Repo'da zaten var: lean_pack_token, marchwarden_talisman, bulwark_reliquary, gate_oak_idol, iron_grip_charm
   Yeni ekle:
   - Packrat Clasp (lojistik/survival, belt'in isini calmasın)
   - Briar Whetstone Loop (saldırı/bleed destegi)
   - Mossbound Wraps (savunma/survival)

5. BELT CONTENT (mevcut olanları adapt et, yenilerini ekle):
   Repo'da zaten var: trailhook_bandolier, duelist_knot
   Yeni ekle:
   - Scavenger Strap (utility + loot/repair)
   - Provisioner Belt (utility + food/consumable verimi)

6. SHIELD ATTACHMENT CONTENT (tamamen yeni):
   - Warden Boss Plate (defend/guard güclendirme)
   - Briar Spikes (savunmacı/bleed his)
   - Lantern Crest (ilk defend/guard anını güclendiren)
   - Pilgrim Seal (survival temalı küçük koruma)

7. CONSUMABLE CONTENT:
   - Binding Resin (hazırlık/repair, heal kopyası olmasın)
   - War Biscuit (hunger + küçük temporary combat/survival)
   - Hearth-Knot Charm (özel quest reward passive, hamlet minnettarlıgı)

8. HAMLET QUEST CONTENT:
   - Hunt Marked Brigand (isaretli combat node, ödül: Bandit Hatchet / Trailhook Bandolier / erzak)
   - Deliver Supplies (quest item tasıma, backpack baskısı, ödül: Provisioner Belt / Pilgrim Seal / food)
   - Rescue Missing Scout (kurtarma görevi, ödül: Watchman Shield / Mossbound Wraps / food+gold)
   - Bring Proof (kanıt quest item'ı, ödül: Briar Spikes / Scavenger Strap / gold+consumable)

Her item icin kısa flavor text yaz. Balance'ı ucurma.
Acquisition matrix'i code ve docs düzeyinde tek truth yap.

Minimum validation:
- validate_content.py
- test_save_file_roundtrip.gd
- Godot full suite
- Godot smoke

Cıktıda ver: degisen dosyalar, güncellenen docs, eklenen content özeti, kalan riskler.
```

---

## PART 8 — Event + Roadside Content Pack

**Risk:** Düsük-Orta  
**Tahmini scope:** Orta

### Prompt

```
Event Node ve Roadside Encounter icerikleri ekle.

Önce AGENTS.md ve önceki part doc'larını oku.
Sonra oku: event ve roadside content formatı, routing kodu, mevcut icerikler, UI sunumu.

Icerik tasarım kuralları:
- Her encounter kısa ve okunur olsun
- Tam iyi / tam kötü yerine tradeoff üret
- Roadside kısa ve tek ekranlık
- Event biraz daha authored his tasısın
- Sonuclar sadece hp/xp/gold olmasın: hunger, consumable, küçük loot, repair, bilgi de olsun
- Mobile-friendly sunum

ROADSIDE ENCOUNTER'LAR (en az 6 ekle):
1. Enkaz Altındaki Yolcu (yardım/fırsatcılık/nötr — hunger vs gold/consumable)
2. Yol Kesen Haydutlar (gold ver/karsı koy/geri cekil — gold vs risk vs tempo)
3. Yarı Sönmüs Kamp Atesi (dinlen/karıstır/gec — survival vs küçük loot vs nötr)
4. Yıkık Muhafız Kulübesi (iceriyi ara/kısa süre oyalan/gec — savunma temalı risk-reward)
5. Kayıp Erzak Arabası (erzak topla/parcaları sök/gec — backpack baskısı + kaynak tercihi)
6. Ac Kurt Izleri (izle/uzaklas/tuzak kur — av/risk/kacınma)

EVENT NODE'LAR (en az 6 ekle):
1. The Shrine in the Moss (adak/dokunma/ayrıl — kutsal/tekinsiz risk-reward)
2. Lantern at the Split Path (takip/söndür/isaretle — yol, fırsat, temkin)
3. Waystone Toll (bedel öde/zorla as/dolanıp gec — bedel vs risk vs güvenli)
4. Table Set by Nothing (otur/arastır/ayrıl — cazibe vs temkin)
5. Wardenless Gate Toll (bedel bırak/zorla gec/kenardan sız — düzenli bedel vs risk vs temkin)
6. Wrecked Bell Tower (yukarı tırman/enkazı kars/uzak dur — yüksek risk vs küçük kazanc)

Her icerik icin kısa ama atmosferli metinler yaz.
Gercekten routing'e bagla ve oynanabilir yap.

Minimum validation:
- validate_content.py
- Godot full suite
- Godot smoke

Cıktıda ver: degisen dosyalar, eklenen event/roadside listesi, kalan riskler.
```

---

## PART 9 — Enemy Content Pack

**Risk:** Düsük-Orta  
**Tahmini scope:** Orta

### Prompt

```
Yeni düsman varyantları ekle ve mevcut olanları yeni foundation ile uyumlu hale getir.

Önce AGENTS.md ve önceki part doc'larını oku.
Sonra oku: ContentDefinitions/Enemies/, enemy intent sistemi, combat resolver, spawn/routing.

NOT: Repo'da zaten 16+ düsman var (briar_alchemist, skeletal_hound, lantern_cutpurse vb.). Bunları yeni combat modeline (Defend/Guard, shield, dual wield) göre adapt et.

Yeni düsmanlar (en az 3 ekle):
1. Cutpurse Duelist
   - hafif, hızlı, dual wield hissi, chip pressure, bleed/weakened kullanabilir
   - Bandit Hatchet dünyasıyla bag
   
2. Thornwood Warder
   - shield kullanan savunmacı, Defend/Guard oynayan, sabırlı
   - oyuncuya "savunmacı düsmana karsı nasıl oynarım" sorusunu sordurmalı
   
3. Gatebreaker Brute
   - agır, yavas, yüksek tehdit, telegraphed büyük vuruslar
   - defend/tempo kararını düsündürmeli

Her düsman icin:
- Okunur intent pool (en az 3 intent)
- Net threat identity
- Stage uyumu (hangi stage'de görünecegi)
- Kısa flavor text

Mevcut düsmanları incele ve yeni combat modeline uymayan (Brace varsayan vb.) intent'leri temizle.

Minimum validation:
- validate_content.py
- Godot full suite
- Godot smoke

Cıktıda ver: eklenen düsmanlar, adapt edilen mevcutlar, kalan riskler.
```

---

## PART 10 — UI Polish + Terim Tutarlılıgı

**Risk:** Düsük  
**Tahmini scope:** Orta

### Prompt

```
Yeni foundation'ın kullanıcıya temiz, anlasılır ve mobile-friendly görünmesini sagla.

Önce AGENTS.md ve önceki part doc'larını oku.
Sonra oku: tüm UI dosyaları, label/tooltip/helper text, HUD, screen component'ler.

Bu part'ta sunu yap:
- Stale label, tooltip, button text, helper text temizle (Brace, eski inventory dili, eski progression)
- Equipment slots + backpack ayrımını net göster
- Defend/Guard + shield/dual wield durumunu combat HUD'da anlasılır yap
- Perk vs passive item farkını UI'da net yansıt
- Reward vs level-up ekran kimligini ayır
- Hamlet / Event / Roadside farkını map ekranında net göster
- Shield attachment varsa takılı/cıkarılabilir durumu göster
- Ekranlar arası terim tutarlılıgı sagla
- Mobile-first okunabilik koru

Yapma:
- Combat/progression/item sistemlerini yeniden acma
- Büyük görsel redesign
- Final audit pass

Minimum validation:
- Godot smoke
- Godot full suite

Cıktıda ver: degisen UI dosyaları, temizlenen stale metinler, kalan riskler.
```

---

## PART 11 — Merchant / Reward / Stage Tuning

**Risk:** Düsük  
**Tahmini scope:** Küçük-Orta

### Prompt

```
Merchant stock, reward havuzu ve stage bazlı icerik dagılımını küçük bir tuning pass ile rafine et.

Önce AGENTS.md ve önceki part doc'larını oku.
Sonra oku: merchant stock JSON'lar, reward policy, stage template'ler, mevcut dagılım.

Istenen his:
- Stage 1: ögretici, hafif, hazırlık odaklı (Watchman Shield, Thornwood Buckler, Trailhook Bandolier, basic food/repair)
- Stage 2: build acan, biraz daha nisin (Bandit Hatchet, Briar Knife, Packrat Clasp, Mossbound Wraps, Pilgrim Board)
- Stage 3: daha nisin, daha güclü, daha pahalı (Gatebreaker Club, Warden Spear, Gatewall Kite Shield, Lean Pack Token)

Shield attachment'lar nadir ve daha cok hamlet/özel reward'da kalsın.
Quest-exclusive item'lar merchant'a düsmesin.
Hamlet reward sıradan reward'dan daha degerli hissetsin.
Eski item'ları tamamen bogma ama yeni item'lar da görünmez kalmasın.

Reward choice aileleri ekle (sırf heal/gold/xp degil):
- Field Provisions (food/consumable)
- Quick Refit (repair/durability)
- Scavenger's Find (gold/utility/passive fırsatı)

Enemy ailesi ile reward tonu arasında hafif bag kur:
- Bandit hattı: gold, hafif silah, utility
- Savunmacı hattı: shield, repair, defend
- Beast hattı: food, survival
- Status hattı: consumable, hazırlık

Minimum validation:
- validate_content.py
- Godot full suite

Cıktıda ver: stage tuning özeti, dagılım degisiklikleri, kalan riskler.
```

---

## PART 12 — Final Cleanup + Audit

**Risk:** Düsük  
**Tahmini scope:** Orta

### Prompt

```
Tam review + audit + fix yap. Eski sistemin tüm izlerini temizle.

Önce AGENTS.md ve tüm authority doc'ları oku.
Sonra repo genelinde su eski izleri tara (grep/ripgrep kullan):

- "brace" / "Brace" / "ACTION_BRACE" referansları
- shared/common inventory mantıgı kalıntıları
- equipped gear'in bag slot tükettigini varsayan yerler
- level-up item/passive akısı kalıntıları
- perk ile passive item karısıklıkları
- belt'in eski combat-stat canonical izleri
- event/roadside/hamlet sorumluluk karısıklıkları
- item taxonomy'de eski sınıf/type/label kalıntıları
- combat ici equip juggling varsayımları
- eski UI metinleri, tooltip'ler, button text'ler
- save/load veya engine state'te sessiz legacy varsayımlar

Her buldugun stale referansı güvenli sekilde temizle veya deprecated et.
Docs senkronizasyonu yap.
Sonra tekrar tara.

Smoke test:
- Yeni run baslar mı
- Equipment slotları dogru mu
- Backpack kapasitesi dogru mu
- Shield + Defend calısıyor mu
- Dual wield calısıyor mu
- Level-up perk veriyor mu
- Hamlet request calısıyor mu
- Roadside encounter calısıyor mu
- Save/load bozulmadı mı

Tüm validation'ları calıstır:
- validate_content.py
- validate_assets.py
- validate_architecture_guards.py
- Godot full suite
- Godot smoke

Cıktıda ver: temizlenen legacy izleri, güncellenen docs, kalan bilinçli ertelemeler.
```

---

## Ek Notlar

### Part Sırası Gerekceleri
- Part 0 altyapı hazırlıgıdır; magic number'ları merkezilestirmek sonraki tüm part'ları kolaylastırır.
- Part 1 audit yapar, büyük ise girmez.
- Part 2-3 en riskli part'lardır (save schema + combat resolver). Bunları erken yapmak gerekir cünkü geri kalan her sey bunlara bagımlı.
- Part 4-5 Part 2-3 üstüne oturur.
- Part 6 map/routing temizligi Part 7'nin content eklemesi icin zemini hazırlar.
- Part 7-9 content pack'lerdir; Part 2-6 tamamlanmadan baslamamalı.
- Part 10-11 polish ve tuning.
- Part 12 son temizlik.

### Paralel Calistırma
- Part 0 ve Part 1 birbirine bagımlı degil, paralel gidebilir.
- Part 8 ve Part 9 (event/roadside ve enemy content) Part 7 tamamlandıktan sonra paralel gidebilir.
- Part 10 ve Part 11 paralel gidebilir.
- Digerleri sıralı olmak zorunda.

### Repo'da Zaten Var Olan Icerikler (dikkat)
Bu item/enemy'ler repo'da mevcut ve yeni taxonomy'ye adapt edilmeli, sıfırdan yazılmamalı:
- Items: lean_pack_token, marchwarden_talisman, trailhook_bandolier, duelist_knot, bulwark_reliquary, gate_oak_idol, iron_grip_charm
- Enemies: briar_alchemist, skeletal_hound, lantern_cutpurse, bone_raider, chain_herald, gate_warden

---

## BONUS — Kendi Önerilerim (Opsiyonel Codex Part'ları)

Bu bölüm repo'yu inceledikten sonra benim kendi fikirlerimdir.
Bunlar core migration'dan bağımsız, tamamlandıktan sonra ayrı part'lar olarak çalıştırılabilir.

### BONUS PART A — Weapon Identity: Durability Profilleri

**Fikir:** Şu an tüm silahlar aynı durability mantığıyla çalışıyor. Ama yeni weapon havuzunda çok farklı kimlikler var (Forager Knife vs Gatebreaker Club). Her weapon'a `durability_profile` eklenebilir:
- `sturdy`: yavaş durability kaybı (Warden Spear, Iron Sword)
- `fragile`: hızlı durability kaybı ama daha yüksek burst (Thorn Rapier, Briar Knife)
- `heavy`: her vuruşta fazla durability harcar ama daha yüksek base damage (Gatebreaker Club, Splitter Axe)

Bu, silah seçimini sadece "damage sayısı" yerine "ne kadar sürdürebilirim" sorusuyla zenginleştirir. Preparation-first kimliğe çok uygun: blacksmith/repair kararları daha anlamlı olur.

```
Weapon'lara durability_profile alanı ekle. Mevcut combat resolver'da durability tüketimini profile'a göre farklılaştır. Üç profil: sturdy (0.5x durability cost), standard (1x), fragile (1.5x), heavy (2x durability cost ama daha yüksek base damage zaten var). Config-driven olsun. Mevcut silahları uygun profillere ata. Yeni büyük sistem açma; sadece mevcut durability_cost hesabını profile multiplier ile çarp.
```

### BONUS PART B — Guard Decay Sistemi

**Fikir:** Şu an planladığın Defend/Guard sisteminde Guard sadece "kullan ve bit" gibi görünüyor. Ama guard decay eklenirse daha taktik olur:
- Guard tur sonunda tamamen sıfırlanmasın, küçük bir kısmı (örn. %25) sonraki tura taşınsın
- Böylece art arda Defend yapan bir oyuncu birikimli guard oluşturabilir ama verimlilik azalarak düşer
- Bu, "ne zaman defend ne zaman attack" sorusunu daha ilginç yapar

```
Guard decay sistemi ekle. Her tur sonunda kalan guard'ın %75'i kaybolsun, %25'i sonraki tura taşınsın. Defend yapınca yeni guard, kalan guard'ın üstüne eklensin. Config-driven: guard_decay_rate = 0.75. Bu sayede art arda defend yapan oyuncu birikimli ama azalan verimli guard oluşturabilir. Boss fight'larda taktik derinlik artar.
```

### BONUS PART C — Roadside Encounter: Sıklık ve Tetikleyici Çeşitliliği

**Fikir:** Şu an repo'da roadside encounter max 1 per stage. Bu çok az — dünya boş hissedebilir. Öneri:
- Stage başına 2-3 roadside encounter olsun ama hepsi zorunlu olmasın
- Bazı encounter'lar hunger durumuna göre tetiklensin (aç iken farklı, tok iken farklı)
- Bazıları HP durumuna göre tetiklensin
- Bu, "dünya sana tepki veriyor" hissini verir

```
Roadside encounter sıklığını stage başına 2-3'e çıkar. RouteConditions sistemine oyuncu state bazlı tetikleyiciler ekle: hunger_below_threshold, hp_below_percent, gold_above_threshold, has_empty_backpack_slot. Her encounter'a opsiyonel trigger_condition alanı ekle. Condition yoksa normal rastgele çıkar. Condition varsa sadece uygun olduğunda çıkar. Mevcut max 1 per stage limitini config'e taşı ve 2-3'e çek.
```

### BONUS PART D — Hamlet Flavor: Köy Kişilikleri

**Fikir:** Hamlet şu an sadece quest veren bir node. Ama her hamlet'e küçük bir "kişilik" eklenebilir:
- `frontier_hamlet`: sınır köyü, daha agresif quest'ler (hunt, bring proof), silah/hatchet ödülleri
- `pilgrim_hamlet`: yolcu köyü, survival quest'ler (deliver supplies, rescue), shield/survival ödülleri
- `trade_hamlet`: ticaret köyü, daha iyi merchant, belt/passive ödülleri

Bu, aynı "hamlet" node'unun her seferinde farklı hissetmesini sağlar.

```
Hamlet node'larına hamlet_personality alanı ekle. Üç kişilik: frontier, pilgrim, trade. Her kişilik farklı quest havuzu ağırlığı ve farklı reward bias'ı taşısın. Stage template'lerde hamlet kişiliği stage tonuyla uyumlu atansın (Stage 1 = pilgrim ağırlıklı, Stage 2 = frontier, Stage 3 = trade). Mevcut hamlet quest hook'larını kişiliğe göre ağırlıklandır. Büyük yeni sistem açma; sadece hamlet node'una personality tag ekle ve quest/reward selection'da bu tag'e göre bias uygula.
```

### BONUS PART E — Ek Event/Roadside İçerik Turu

**Fikir:** Part 8'deki 6+6 içerik iyi bir başlangıç ama dünya hâlâ dar kalabilir. Orijinal dosyandaki bazı ek fikirler çok iyi:

```
Aşağıdaki ek içerikleri mevcut event/roadside sistemine ekle:

EK ROADSIDE (4 adet):
- Şüpheli Tüccar (satın al/pazarlık/geç — güven vs fırsat)
- Eski Yol İşareti (incele/takip/yoksay — bilgi vs zaman)
- Kırık Köprü Geçişi (riskli geç/dolaş/tamir — tempo vs güvenlik vs kaynak)
- Sessiz Mezar Yığını (saygı göster/karıştır/uzaklaş — ahlaki seçim + küçük reward)

EK EVENT (4 adet):
- Watchfire Ruin Cache (külleri eşele/sandığı zorla/geç — güvenli küçük vs riskli büyük)
- Weathered Signal Tree (işaretleri incele/kendi işaretini bırak/uzak dur — bilgi/bedel/temkin)
- Woodsmoke Bunkhouse (dinlen/eşyaları karıştır/ayrıl — güvenli dinlenme vs loot riski)
- Woundvine Altar (kana bulanmış adak/sarmaşıkları kes/ayrıl — HP bedeli vs güç kazanımı)

Her içerik için kısa ama atmosferli metinler yaz. Mevcut event/roadside formatını koru.
```

### BONUS PART F — Ek Enemy Varyantları

**Fikir:** Part 9'daki 3 düşman iyi ama repo'da zaten var olan bazı düşmanları da yeni sisteme göre zenginleştirmek lazım. Özellikle shield/guard kullanan düşman eksikliği var.

```
Aşağıdaki 3 ek düşmanı ekle:

1. Chain Trapper
   - tempo bozan, hazırlığı bozan support-disruptor
   - oyuncunun rahat akışını bozsun
   - kısa süreli defend/item baskısı, guard baskısı veya yavaşlatma
   - sürekli stun spam yapmasın

2. Briar Alchemist (repo'da var, adapt et)
   - poison, bleed, corroded veya weakened status baskısı
   - yavaş yavaş boğan, attrition oynayan tehdit
   - yeni Defend/Guard sistemine uyumlu intent'ler ver

3. Skeletal Hound (repo'da var, adapt et)
   - beast tipi, hızlı, chip damage, takipçi baskı
   - insan düşmanlardan farklı oynansın
   - bleed eğilimi olabilir

Mevcut briar_alchemist ve skeletal_hound JSON'larını yeni combat modeline adapt et.
Chain Trapper için yeni JSON oluştur.
```
