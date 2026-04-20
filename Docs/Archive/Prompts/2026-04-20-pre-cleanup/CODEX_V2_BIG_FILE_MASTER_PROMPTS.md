# CODEX V2 BIG FILE MASTER PROMPTS

Purpose: one practical copy-paste file for the delayed big-file micro-refactor pass.
Audience: the user starting fresh Codex chats later, after the follow-up pass is stable, and wanting one prompt at a time for each hotspot.
Scope: report-only preflights first, then narrow helper extractions by file family, while keeping high-risk RuntimeState owner work out of the normal chain.

Active files for this pass:
1. `Docs/Promts/CODEX_V2_BIG_FILE_MASTER_PROMPTS.md`
2. `Docs/Promts/CODEX_V2_MASTER_PROMPTS.md`

Entry rule:
- start this file only after BOTH of these pass chains are closed:
  1. `Docs/Promts/MAP_MASTER_PROMPTS.md` Prompts `1` → `8`
  2. `Docs/Promts/CODEX_V2_MASTER_PROMPTS.md` clean order through Prompt `3.2`
- safest mode: clean worktree, one prompt per fresh chat
- never queue two code-touching prompts for the same hotspot file in the same batch
- do NOT queue this file overnight without the above pre-conditions met

## 0. Reading This File

Every prompt body below begins with `(genel kural özeti)` as a shorthand. When you paste a prompt into Codex, PREPEND this ROL block so Codex has the workflow context:

```text
ROL: simple_rpg repo'sunda çalışan AI kod ajanısın. AGENTS.md + Docs/DOC_PRECEDENCE.md + Docs/HANDOFF.md kuralları bağlayıcı. Değişmeden önce ilgili otorite doc'u oku. High-risk escalate-first dosyalara (map_runtime_state.gd, inventory_state.gd, support_interaction_state.gd, save_service.gd, run_state.gd) explicit escalate olmadan dokunma. Save-shape, flow state, owner move, autoload, command/event family genişletmesi escalate-first lane'de. Küçük, yerel, tek amaçlı patch tercih et.
```

---

## 1. Quick Order

If you only want the practical run order for the big-file pass, use this:

1. Prompt `MBC-0`
2. Prompt `INV-0`
3. Prompt `RSC-0`
4. Prompt `MRB-0`
5. checkpoint commit only if one of those preflights wrote repo files
6. Prompt `MBC-1`
7. Prompt `MBC-2`
8. Prompt `MBC-3`
9. optional Prompt `MBC-4`
10. Prompt `INV-1`
11. Prompt `INV-2`
12. Prompt `INV-3`
13. optional Prompt `INV-4`
14. Prompt `RSC-1`
15. Prompt `RSC-2`
16. Prompt `RSC-3`
17. Prompt `MRB-1`
18. Prompt `MRB-2`
19. optional Prompt `MRB-3`
20. optional cleanup: Prompt `CMB-OPT`
21. optional cleanup: Prompt `MEP-OPT`

Manual mode recommendation:
- keep one hotspot family at a time
- do not queue code-touching prompts for the same file family together
- if any micro-patch goes unstable, checkpoint before retrying

---

## 2. The Clean Order

Use this order:

1. Prompt `MBC-0` - map_board_composer_v2 preflight
2. Prompt `INV-0` - inventory_actions preflight
3. Prompt `RSC-0` - run_session_coordinator preflight
4. Prompt `MRB-0` - map_route_binding preflight
5. checkpoint commit only if one of those preflights actually wrote repo files
6. Prompt `MBC-1`
7. Prompt `MBC-2`
8. Prompt `MBC-3`
9. optional Prompt `MBC-4`
10. Prompt `INV-1`
11. Prompt `INV-2`
12. Prompt `INV-3`
13. optional Prompt `INV-4`
14. Prompt `RSC-1`
15. Prompt `RSC-2`
16. Prompt `RSC-3`
17. Prompt `MRB-1`
18. Prompt `MRB-2`
19. optional Prompt `MRB-3`
20. optional hotspot cleanup: Prompt `CMB-OPT`, then `MEP-OPT`
21. high-risk RuntimeState owner work stays outside this order until you explicitly decide to escalate

Rule:
- keep one hotspot family at a time
- do not start INV/RSC/MRB code-touching steps before their own preflight
- if a micro-patch goes unstable, stop the chain and checkpoint before retrying

---

## 3. Queue Mode

If you want queue execution in the same chat, use batches instead of dropping the whole refactor chain at once.

Guard line to place before every queued prompt after the first:

```text
Before doing anything, run `git status --short` and read the previous assistant message in this chat. If the repo has unrelated dirty changes outside this prompt's scope, or if the previous step says blocker, unsafe, unstable, failed validation, or stop, do not continue the planned work. Only report that you are halting because the chain did not close cleanly.
```

Queue batch plan:

1. Batch `0`
   - Prompt `MBC-0`
   - guard line
   - Prompt `INV-0`
   - guard line
   - Prompt `RSC-0`
   - guard line
   - Prompt `MRB-0`
2. Batch `1`
   - Prompt `MBC-1`
3. Batch `2`
   - Prompt `MBC-2`
4. Batch `3`
   - Prompt `MBC-3`
   - optional guard line
   - Prompt `MBC-4`
5. Batch `4`
   - Prompt `INV-1`
6. Batch `5`
   - Prompt `INV-2`
7. Batch `6`
   - Prompt `INV-3`
   - optional guard line
   - Prompt `INV-4`
8. Batch `7`
   - Prompt `RSC-1`
9. Batch `8`
   - Prompt `RSC-2`
10. Batch `9`
   - Prompt `RSC-3`
11. Batch `10`
   - Prompt `MRB-1`
12. Batch `11`
   - Prompt `MRB-2`
   - optional guard line
   - Prompt `MRB-3`
13. Optional cleanup batch
   - Prompt `CMB-OPT`
   - guard line
   - Prompt `MEP-OPT`

Do NOT queue `MBC-1 -> MRB-3` in one shot.

---

## 4. Escalate-Only Note

- high-risk RuntimeState owner work for `map_runtime_state.gd`, `inventory_state.gd`, and `support_interaction_state.gd` is intentionally outside this file
- if you later decide to cross that lane, write a fresh escalate prompt from `AGENTS.md`, `Docs/HANDOFF.md`, and the relevant authority docs instead of resuming the normal chain
- do not use the normal micro-patch order for those files

---

## Prompt MBC-0 — Extraction Planı (REPORT-ONLY)

```text
(genel kural özeti)
GÖREV: REPORT-ONLY. Game/UI/map_board_composer_v2.gd dosyasını analiz et.
Yeni bir plan dosyası yazma; final response içinde inline preflight ver.

İÇERİK:
1. Sembol/fonksiyon tablosu (fn adı, satır aralığı, kısa açıklama).
2. Sorumluluk grupları (tahmin: trail geometry, node placement, canopy/forest,
   fallback layout, board follow/camera). Doğrula veya güncelle.
3. Her grup için:
   - önerilen yeni dosya path
   - public API yüzeyi
   - grup içi private helper'lar
   - kalan composer dosyasıyla arayüz
4. Her grup için effort tahmini (S/M/L) ve bağımsızlık skoru (0-3).
5. Önerilen sıra: en bağımsız önce, en girift en son.
6. Risk notları: board follow/camera grup gameplay-presentation sınırına
   yakın olabilir; dikkatli bölünmesi gerekir.

DOKUNMA: map_board_composer_v2.gd ve map_runtime_state.gd KOD YOK.
BAŞARI: Inline preflight eksiksiz; 4 micro-patch için sağlam temel.
```

---

## Prompt MBC-1 — Trail Geometry Helper extraction

```text
(genel kural özeti)
GÖREV: map_board_composer_v2.gd içinden SADECE "trail geometry" sorumluluğunu
yeni bir helper'a taşı.

HEDEF DOSYA: Game/UI/map_board_trail_geometry.gd (yeni)

KAPSAM:
- Trail/path koordinat hesaplaması
- Edge geometry curve builder'lar
- Trail decoration placement
- SADECE bu grup; başka hiçbir grubu TAŞIMA.

ADIMLAR:
1. Current file analysis'e göre trail geometry fonksiyon grubunu taşı.
2. Helper'a geçilecek parametreleri minimum tut (seed, graph, bounds).
3. composer tarafı helper'ı static class_name olarak çağırsın.
4. Eski public API'ler composer üzerinde koruma amaçlı wrapper olarak KAL.
   Sadece 0-caller olanları sil.

DOĞRULAMA:
- py -3 Tools/validate_architecture_guards.py
- powershell -File Tools/run_godot_scene_isolation.ps1 -ScenePath scenes/map_explore.tscn
- powershell -File Tools/run_godot_full_suite.ps1
- portrait capture varsa çalıştır; visual regression KONTROL ET.

DOKUNMA:
- map_runtime_state.gd YOK.
- Başka composer sorumluluğu grubuna YOK.

BAŞARI:
- composer dosyası yeni satır sayısı raporlandı.
- trail_geometry.gd yeni dosya, dar public API ile live.
- Visual regression yok.
```

---

## Prompt MBC-2 — Node Placement Helper extraction

```text
(genel kural özeti)
GÖREV: MBC-1 tamamlandıysa, map_board_composer_v2.gd içinden "node placement"
sorumluluğunu çıkar.

HEDEF DOSYA: Game/UI/map_board_node_placer.gd (yeni)

KAPSAM:
- Graph node -> board pozisyon hesaplama
- Node scatter/jitter
- Start/boss konumlandırma özel kuralları

ADIMLAR: MBC-1 pattern'i aynı.

DOKUNMA: map_runtime_state.gd YOK.
BAŞARI: Yeni helper live; composer daha küçük; visual regression yok.
```

---

## Prompt MBC-3 — Canopy / Forest Composition extraction

```text
(genel kural özeti)
GÖREV: MBC-2 tamamlandıysa, map_board_composer_v2.gd içinden "canopy /
forest decoration composition" sorumluluğunu çıkar.

HEDEF DOSYA: Game/UI/map_board_canopy_composer.gd (yeni)

KAPSAM:
- Forest clump placement
- Canopy decoration seeding
- Tree/bush variation logic

ADIMLAR: MBC-1 pattern'i aynı.

DOKUNMA: trail/node placement helperlarına YOK.
BAŞARI: Yeni helper live; composer 700 satır altına düşerse bonus.
```

---

## Prompt MBC-4 — Fallback Layout extraction (opsiyonel, en son)

```text
(genel kural özeti)
GÖREV: MBC-3 tamamlandıysa, kalan "fallback layout / emergency slot" kodunu
çıkar. Bu grup küçükse opsiyonel — preflight çıktısında "fallback" grubu marjinal
ise BU PROMPTU ATLAYABILIRSIN.

HEDEF DOSYA: Game/UI/map_board_fallback_layout.gd (yeni)

BAŞARI: composer <= 600 satır (hedef; şart değil).
```

---

## Prompt INV-0 — Extraction Planı (REPORT-ONLY)

```text
(genel kural özeti)
GÖREV: REPORT-ONLY. Game/Application/inventory_actions.gd dosyasını analiz et.
Yeni bir plan dosyası yazma; final response içinde inline preflight ver.

İÇERİK:
1. Sembol/fonksiyon tablosu.
2. Command family grupları (tahmin: equip/unequip, reorder/swap, use/consume,
   attach/detach mod, grant/reward routing, drop/discard). Doğrula.
3. Her command family için:
   - önerilen yeni dosya path (Game/Application/inventory_actions_*.gd
     veya policy altına)
   - public API (mevcut caller'ların aynen çağırabilmesi için)
   - RuntimeState ile arayüz (InventoryState'e yazma noktaları)
4. Command family'leri bağımsızlık skoruna göre sırala.
5. Risk: InventoryState ownership; bu dosya YAZMA noktalarını değiştirmeyecek,
   sadece ORGANIZE edecek.

DOKUNMA: InventoryState, RunState, SaveService YOK.
BAŞARI: Inline preflight eksiksiz; 3-4 micro-patch için temel.
```

---

## Prompt INV-1 — Equip / Unequip command family extraction

```text
(genel kural özeti)
GÖREV: inventory_actions.gd içinden SADECE equip/unequip command family'sini
çıkar.

HEDEF DOSYA: Game/Application/inventory_actions_equip.gd (yeni)

KAPSAM:
- equip_weapon, unequip_weapon (varsa)
- equip_shield, equip_offhand
- equip_armor, equip_belt
- attach_shield_mod, detach_shield_mod (eğer equip grubunda kabul edilirse)
- SADECE equip/unequip; use/reorder/grant HARİÇ.

ADIMLAR:
1. Command function'ları yeni dosyaya taşı.
2. inventory_actions.gd orijinal public isimleri yeni dosyaya delegate eden
   wrapper olarak KORUSUN (geri uyum).
3. InventoryState'e yazma shape'i AYNI kalsın.

DOĞRULAMA:
- py -3 Tools/validate_architecture_guards.py
- powershell -File Tools/run_godot_tests.ps1 test_inventory_actions.gd
  test_inventory_state.gd test_combat_spike.gd
- powershell -File Tools/run_godot_full_suite.ps1

DOKUNMA: InventoryState write API YOK; save shape YOK.
BAŞARI: Yeni dosya live; eski caller'lar aynen çalışıyor; testler PASS.
```

---

## Prompt INV-2 — Reorder / Swap command family extraction

```text
(genel kural özeti)
GÖREV: INV-1 tamamlandıysa, reorder/swap command family'sini çıkar.

HEDEF DOSYA: Game/Application/inventory_actions_reorder.gd (yeni)

KAPSAM:
- backpack slot reorder
- hand swap
- mod/attachment swap

ADIMLAR: INV-1 pattern'i aynı.
DOKUNMA: equip/unequip dosyasına YOK.
BAŞARI: Yeni dosya live; testler PASS.
```

---

## Prompt INV-3 — Use / Consume command family extraction

```text
(genel kural özeti)
GÖREV: INV-2 tamamlandıysa, use/consume command family'sini çıkar.

HEDEF DOSYA: Game/Application/inventory_actions_use.gd (yeni)

KAPSAM:
- consumable kullanımı (combat ve map modunda)
- quest cargo kullanımı
- passive item pasif etkileri HARİÇ (policy dosyasında zaten olmalı)

ADIMLAR: INV-1 pattern'i aynı.
DOKUNMA: equip/reorder dosyalarına YOK.
BAŞARI: Yeni dosya live; combat + map use path'leri bozulmamış.
```

---

## Prompt INV-4 — Grant / Reward routing extraction (opsiyonel)

```text
(genel kural özeti)
GÖREV: INV-3 tamamlandıysa, grant_item / reward routing'i çıkar.

HEDEF DOSYA: Game/Application/inventory_actions_grant.gd (yeni)

BAŞARI: inventory_actions.gd <= 400 satır (hedef).
```

---

## Prompt RSC-0 — Extraction Planı (REPORT-ONLY)

```text
(genel kural özeti)
GÖREV: REPORT-ONLY. Game/Application/run_session_coordinator.gd analizi ve
inline preflight raporu.

İÇERİK:
1. Sembol/fonksiyon tablosu.
2. Orkestrasyon grupları (tahmin: movement resolution, roadside interruption
   continuation, pending screen orchestration, save/load bridge forwarding,
   node entry dispatch). Doğrula.
3. Her grup için yeni dosya path önerisi ve bağımsızlık skoru.
4. HANDOFF uyarısı: bu dosya "movement resolution owner + pending screen
   orchestration" demiş; bu ownership AYNI kalmalı — extraction sadece
   organize eder, owner move yapmaz.

DOKUNMA: MapRuntimeState, InventoryState, SaveService YOK.
BAŞARI: Inline preflight eksiksiz.
```

---

## Prompt RSC-1 — Movement Resolution extraction

```text
(genel kural özeti)
GÖREV: RSC-0 planına göre movement resolution logic'i çıkar.

HEDEF DOSYA: Game/Application/run_session_movement.gd (yeni)

KAPSAM:
- next node validation
- travel cost application (varsa)
- movement result dispatch

DOĞRULAMA:
- py -3 Tools/validate_architecture_guards.py
- powershell -File Tools/run_godot_tests.ps1 test_flow_state.gd
  test_phase2_loop.gd test_map_runtime_state.gd
- powershell -File Tools/run_godot_smoke.ps1
- powershell -File Tools/run_godot_full_suite.ps1

DOKUNMA: MapRuntimeState YOK; owner move YOK.
BAŞARI: Yeni dosya live; movement orchestration ownership run_session_coordinator
üzerinde kalıyor (sadece kod organize edildi).
```

---

## Prompt RSC-2 — Roadside Interruption Continuation extraction

```text
(genel kural özeti)
GÖREV: RSC-1 tamamlandıysa, roadside interruption continuation'ı çıkar.

HEDEF DOSYA: Game/Application/run_session_roadside.gd (yeni)

KAPSAM:
- roadside trigger resolution
- interruption suspend/resume
- destination preservation logic

DOĞRULAMA: RSC-1 testleri + roadside akislarini kapsayan mevcut targeted testler
(varsa).
DOKUNMA: movement extraction'a YOK; owner move YOK.
BAŞARI: Yeni dosya live; roadside interruption davranışı aynı.
```

---

## Prompt RSC-3 — Pending Screen Orchestration extraction

```text
(genel kural özeti)
GÖREV: RSC-2 tamamlandıysa, pending screen (reward / event / support) open/
close orchestration'ı çıkar.

HEDEF DOSYA: Game/Application/run_session_pending_screens.gd (yeni)

KAPSAM:
- pending screen open dispatch
- overlay close continuation
- post-screen state resume

BAŞARI: run_session_coordinator.gd <= 500 satır (hedef).
```

---

## Prompt MRB-0 — Extraction Planı (REPORT-ONLY)

```text
(genel kural özeti)
GÖREV: REPORT-ONLY. Game/UI/map_route_binding.gd analizi ve
inline preflight raporu.

İÇERİK:
1. Sembol/fonksiyon tablosu.
2. Binding grupları (tahmin: route button binding, marker state binding,
   hover/tooltip binding, travel feedback binding). Doğrula.
3. Her grup için yeni dosya path önerisi.

DOKUNMA: map_runtime_state.gd YOK.
BAŞARI: Inline preflight eksiksiz.
```

---

## Prompt MRB-1 — Route Button Binding extraction

```text
(genel kural özeti)
GÖREV: route button binding logic'i çıkar.

HEDEF DOSYA: Game/UI/map_route_button_binding.gd (yeni)

KAPSAM:
- route button create / destroy
- button -> node id binding
- availability state rendering

DOĞRULAMA:
- py -3 Tools/validate_architecture_guards.py
- powershell -File Tools/run_godot_scene_isolation.ps1 -ScenePath scenes/map_explore.tscn
- powershell -File Tools/run_godot_full_suite.ps1

DOKUNMA: map_runtime_state.gd YOK.
BAŞARI: Yeni dosya live; route butonu davranışı aynı.
```

---

## Prompt MRB-2 — Marker State Binding extraction

```text
(genel kural özeti)
GÖREV: MRB-1 tamamlandıysa, marker state binding çıkar.

HEDEF DOSYA: Game/UI/map_route_marker_binding.gd (yeni)

KAPSAM:
- node marker pozisyon/state binding
- key/boss gate marker state

BAŞARI: Yeni dosya live.
```

---

## Prompt MRB-3 — Hover/Tooltip Binding extraction (opsiyonel)

```text
(genel kural özeti)
GÖREV: MRB-2 tamamlandıysa, hover ve tooltip binding çıkar.

HEDEF DOSYA: Game/UI/map_route_hover_binding.gd (yeni)

BAŞARI: map_route_binding.gd <= 400 satır (hedef).
```

---

## Prompt CMB-OPT — combat.gd kart-child traversal sıcak noktası

```text
Bu `CODEX_V2_MASTER_PROMPTS.md` icindeki Prompt `2.4` ile AYNI istir.
Tekrar yazmiyorum. Oradaki promptu kullan.
```

---

## Prompt MEP-OPT — map_explore.gd kart-child traversal sıcak noktası

```text
Ayni sekilde; `CODEX_V2_MASTER_PROMPTS.md` icindeki Prompt `2.4`
kapsamina dahildir.
```

---
