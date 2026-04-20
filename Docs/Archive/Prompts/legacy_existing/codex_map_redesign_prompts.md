# Codex Map Redesign — Full Prompt Queue

Bu dosya **Codex'e yapıştırmalık** prompt'ları içerir. Her başlık (Part 1, Part 2, ...) bağımsız bir Codex queue item'ıdır. Sıra önemlidir: Part N tamamlanmadan Part N+1 başlamasın.

Referans plan dosyası: `codex_map_redesign_plan.md`.

Toplam: **8 code part + 4 asset part = 12 queue item.**

---

## Part 1 — Audit + Scope Lock + Stale Inventory (NO-CODE)

```
Bu pass implementasyon değil.
Önce repo truth'unu kilitle, drift çıkar, stale/unused envanter üret, part sırasını netleştir.
Hiç kod yazma. Hiç doc değiştirme. Hiç dosya silme.

Bu pass'in input'u olarak mutlaka oku:
- codex_map_redesign_plan.md (bu dosya senin input kontextinin bir parçası; iddiaları re-verify et ama tekrar tam scratch'ten audit yapma)

Önce authority docs oku:
- AGENTS.md
- Docs/DOC_PRECEDENCE.md
- Docs/TECH_BASELINE.md
- Docs/SOURCE_OF_TRUTH.md
- Docs/MAP_CONTRACT.md
- Docs/SCATTER_MAP_GENERATION_DESIGN.md
- Docs/MAP_COMPOSER_V2_DESIGN.md
- Docs/HANDOFF.md
- Docs/GAME_FLOW_STATE_MACHINE.md

Sonra kod oku:
- Game/RuntimeState/map_runtime_state.gd
- Game/Application/run_session_coordinator.gd
- Game/UI/map_board_composer_v2.gd
- Game/UI/map_explore_presenter.gd
- scenes/map_explore.gd
- Tests/test_map_runtime_state.gd
- Tests/test_map_board_composer_v2.gd
- Tests/test_map_explore_presenter.gd
- Tests/test_phase2_loop.gd
- Tests/test_stage_progression.gd
- Tests/test_event_node.gd

Read-only bağlam için:
- Docs/SAVE_SCHEMA.md
- Game/RuntimeState/run_state.gd
- Game/Infrastructure/save_service.gd

KESİN BİLGİ VS VARSAYIM AYRIMI
Her bulgu için:
- KESİN: doğrudan kod/doc satırı ile kanıt
- VARSAYIM: inference ile çıkarılmış ama henüz doğrulanmamış

ÇIKARILACAK RAPOR

1. AUTHORITY SUMMARY
   - Map redesign için authoritative docs listesi
   - Runtime truth owner: kim?
   - Presentation truth owner: kim?
   - Flow owner: kim?
   - Save-sensitive yüzeyler: hangileri?

2. CURRENT IMPLEMENTATION AUDIT (verify edilmiş durum)
   - Runtime graph generation: gerçekte nasıl çalışıyor?
     - Hard-coded mı, scatter mı, ikisi karışık mı?
     - _build_controlled_scatter_adjacency'nin base edge listesi satır numaralı raporla
     - _build_scatter_profile_extra_edges'ın profile-driven davranışını raporla
     - SCATTER_NODE_COUNT sabiti ve değeri
   - Family placement: graph-native mı depth-biased mı?
   - Roadside/event flow: run_session_coordinator.gd içinde roadside trigger olunca ne oluyor?
     - ÖZELLİKLE: mark_node_resolved çağrısı var mı? Satır numarası ver.
   - Composer ring/arc dominance:
     - RING_RADIUS_FACTORS değerleri
     - Path family sabitleri
   - Scene slot fallback:
     - slot_factors ve BOARD_FOCUS_ANCHOR_FACTOR satır numaraları
     - Fallback normal path mi emergency mi?
   - Presenter label drift:
     - FAMILY_DISPLAY_NAMES dictionary
     - Test lock satır numarası

3. DOC TRUTH DRIFT REPORT
   Her drift için:
   - file
   - current claim (satır numarası)
   - actual code reality (satır numarası)
   - severity (low/medium/high)
   - fix timing: now / with redesign part X / after redesign

4. CLEANUP INVENTORY
   İki ayrı bölüm: CODE CLEANUP INVENTORY, DOC CLEANUP INVENTORY
   Her item için kategori:
   - SAFE_DELETE_LATER
   - DELETE_ONLY_AFTER_REDESIGN
   - KEEP_FOR_COMPAT
   - STALE_DOC_UPDATE_NEEDED
   - MAY_LOOK_UNUSED_BUT_IS_ACTIVE
   - NEEDS_MORE_EVIDENCE
   Ve her item için: why it looks stale, evidence, risk if removed now, recommended timing.

5. RISK CLASSIFICATION
   Aşağıdaki her surface için low/medium/high:
   - map_runtime_state.gd (graph generator)
   - map_runtime_state.gd (family placement)
   - run_session_coordinator.gd (roadside flow)
   - map_board_composer_v2.gd (layout)
   - scenes/map_explore.gd
   - Game/UI/map_explore_presenter.gd
   - Save surface
   - Tests

6. RECOMMENDED PATCH ORDER
   Plan dosyasındaki sıra ile hemfikir misin? Farklı bir sıra daha iyi olacaksa açıkla.
   Default beklenen sıra:
   - Part 2: runtime graph redesign
   - Part 3: family placement redesign
   - Part 4: roadside split + bug fix
   - Part 5: composer/layout redesign
   - Part 6: scene/presenter cleanup
   - Part 7: stale cleanup + doc sync
   - Part 8: final audit/patch

7. VALIDATION PLAN
   Bu redesign boyunca hangi komutlar hangi checkpoint'lerde koşmalı?
   Changed-area validation vs final checkpoint validation'ı ayır.

8. NO-CODE DECISION
   Bu pass'in sonunda açıkça söyle:
   - code changes required now: yes/no
   - if no, neden
   - if yes, neden kaçınılmaz
   Default olarak NO bekliyorum.

GUARDRAILS
- Hiçbir broad cleanup yapma.
- "Unused görünüyor" diye referance audit yapmadan silme.
- Ownership move yapma.
- Save schema shape değiştirme.
- Doc'u şimdi rewrite etme, sadece drift inventory çıkar.
- Plan dosyasındaki bulgular input; re-verify et ama tekrar full scratch audit yapma.

Son olarak continuation gate yaz:
- Part 2'ye hazır mı?
- Part 2 için özel dikkat gerektiren ek risk var mı?
- Başka bir partın önce çalışması gerekiyor mu?
```

---

## Part 2 — Runtime Graph Redesign ONLY (HIGH RISK)

```
Bu pass'in amacı yalnızca runtime map graph generation'ı redesign etmek.
Henüz roadside/event semantic split yapma.
Henüz composer/layout redesign yapma.
Henüz presenter label cleanup yapma.
Henüz broad repo cleanup yapma.

KESİN BİLGİ VS VARSAYIM AYRIMI
Mevcut kod durumu (Part 1 audit ile doğrulandı):
- map_runtime_state.gd ZATEN procedural controlled scatter kullanıyor
- _build_controlled_scatter_adjacency() (yaklaşık satır 925) base edge listesi tutuyor
- _build_scatter_profile_extra_edges() (yaklaşık satır 958) profile'a göre extra edge ekliyor
- SCATTER_NODE_COUNT = 14 (satır 22)

Bu pass'in GERÇEK amacı:
"Scaffold'dan scatter'a geçiş" DEĞİL. Zaten scatter var.
"Yarı-scatter + sabit base edge list" yapısını gerçek "center-start frontier growth + controlled reconnect" modeline taşımak.

Önce oku:
- AGENTS.md
- Docs/DOC_PRECEDENCE.md
- Docs/HANDOFF.md
- Docs/MAP_CONTRACT.md
- Docs/SCATTER_MAP_GENERATION_DESIGN.md
- Docs/SAVE_SCHEMA.md
- Docs/GAME_FLOW_STATE_MACHINE.md (sadece sınırlar için)

Sonra kod oku (write target):
- Game/RuntimeState/map_runtime_state.gd
- Tests/test_map_runtime_state.gd

Read-only bağlam:
- Game/RuntimeState/run_state.gd
- Game/Infrastructure/save_service.gd
- Tests/test_phase2_loop.gd (flow-level testler değişebilir mi kontrol)
- Tests/test_stage_progression.gd

STRICT SCOPE — Değiştirebileceğin yüzey:
- Game/RuntimeState/map_runtime_state.gd
- gerekirse çok yakın helper extraction (private helper)
- Tests/test_map_runtime_state.gd
- behavior gerçekten değişiyorsa en yakın authority doc'ta minimal sync:
  - Docs/SCATTER_MAP_GENERATION_DESIGN.md
  - Docs/MAP_CONTRACT.md
Başka yere yayılma.

AMAÇ
Current graph generation'ı gerçek anlamda "center-start constrained scatter + controlled reconnect" modeline taşı.
Bunu yaparken:
- MapRuntimeState gameplay truth owner olarak kalsın
- save shape DEĞİŞMESİN
- current stage profile ids (procedural_stage_corridor_v1, procedural_stage_openfield_v1, procedural_stage_loop_v1) aktif runtime/save ids olarak kalsın
- node identity stabil kalsın
- node 0 = start
- total node count = 14
- graph connected kalsın
- exact restore via saved node/edge list çalışsın

TARGET MODEL — Generator davranışı
1. start node merkez anchor
2. İlk hop seviyesinde 2-4 outward choice (ideal çoğu seed'de 3)
3. Kalan node'lar constrained frontier growth ile outward büyüsün
4. Branch-growth ring/halka hissi vermesin; overlapped radial bands / controlled scatter hissi
5. Her yeni node en az bir parent ile bağlı gelsin
6. Sonradan sınırlı sayıda late reconnect (1-2)
7. Graph aşırı tree-like olmasın ama spaghetti de olmasın
8. Degree dağılımı çoğunlukla 2-way, biraz leaf, biraz 3-way

PRESERVE CURRENT CONTRACT BASELINES
- node 0 = start
- start başlangıçta resolved traversal anchor
- graph start'tan bağlı
- total nodes = 14
- start adjacency [2,4]
- en az bir reconnect
- early adjacency floor:
  - en az bir early combat exposure
  - en az bir early reward exposure
  - en az bir early support exposure
- stage profile ids korunmalı
- MAP_CONTRACT family count floor KORUNMALI:
  - 1 start, 6 non-boss combat, 1 event, 1 reward, 1 side_mission, 2 support, 1 key, 1 boss
- deterministic RNG behavior korunmalı

YENİ EKLENMESİ GEREKEN — Family Budget Reservation
Topology üretirken family'lerin yerleşebileceği uygun slot'ları pre-reserve et:
- 1 uygun boss slot (outer/frontier, far from start)
- 1 uygun key slot (outer/late, separate from boss pocket)
- en az 2 uygun support slot (connected branches, early + late)
- en az 1 uygun side_mission slot (leaf-like, optional detour)
- en az 1 uygun event slot (connector/detour pocket)
- en az 1 uygun reward slot (early-reachable, different branch from support)
Bu slot'lar Part 3'te family assignment tarafından kullanılacak.
Bu pass'te sadece slot'ların mevcudiyetini validate et.

TOPOLOGY-FIRST, FAMILY-ASSIGNMENT-SECOND
- Bu pass graph topology ve slot reservation'a odaklanır
- Family assignment logic (Part 3) değiştirilirse ayrı bir patch olur
- Minimum adaptation: yeni topology API Part 3 için hazır olsun

DEGREE / RECONNECT CONTROL
- ideal total edges: 15-16
- late reconnect budget: 1-2
- non-start node degree çoğunlukla 1-3
- bu pass'te 3 üstü degree verme
- start için gerektiğinde 3, nadiren 4 (mevcut test range'i bozmasın)

VALIDATION / REROLL / REPAIR
Graph kabul edilmeden önce validate et. Gerekirse reroll/repair.
Hard validity:
- fully connected
- every node reachable from start
- no isolated nodes
- start not leaf
- at least one leaf-like route
- at least one reconnect route
- family budget reservation met (her family için en az bir uygun slot var)
- boss/key pocket over-connected olmasın
- hidden-information rules bozulmasın

SAVE / OWNER WATCHPOINTS — STOP + ESCALATE FIRST
Aşağıdakilere girersen implement etmeden dur:
- save schema shape change
- new saved coordinate fields as authoritative truth
- load restore için seed-only regeneration zorunluluğu
- graph truth ownership move out of MapRuntimeState
- current profile/save identity meaning'inin kırılması

INTERNAL CLEANUP RULE
Bu pass'te yalnız:
- current generator içinde gerçekten replaced/dead hale gelen local helper/const/function'lar
- reference audit ile gerçekten inactive oldukları kanıtlanırsa
Broad prune yok.

PATCH STYLE
- typed GDScript
- helper'lar küçük ve tek sorumluluklu
- topology generation ile validation/repair mantığını okunur ayır
- family placement ile graph generation sınırını daha netleştir
- magic number'ları named constant'a taşı

TESTS
Mevcut test kilitlerini zayıflatma.
En az şunları doğrula:
- connectedness
- node count 14
- start node 0
- start adjacency in [2,4]
- at least one reconnect
- degree cap obeyed
- early combat/reward/support exposure preserved
- family budget slot reservation mevcut
- boss/key outer/late bias still intact
- stage profile ids still map to valid distinct runtime graphs
- deterministic: aynı seed + aynı profile = aynı graph

WORK ORDER
1. Önce mevcut graph generator kodunu kısa audit et. Scaffold kalıntılarını satır numaralı not et.
2. Implementation planını 5-10 maddede yaz.
3. Patch uygula.
4. Changed-area validation:
   - Windows: py -3 Tools/validate_content.py
   - Windows: py -3 Tools/validate_architecture_guards.py
   - Godot test runner: powershell -NoProfile -ExecutionPolicy Bypass -File Tools/run_godot_tests.ps1
5. Full suite checkpoint:
   - powershell -NoProfile -ExecutionPolicy Bypass -File Tools/run_godot_full_suite.ps1
6. Eğer scene/autoload wiring değişmediyse smoke gereksiz; değiştiyse:
   - powershell -NoProfile -ExecutionPolicy Bypass -File Tools/run_godot_smoke.ps1

REPORT FORMAT
1. touched files
2. generator'da ne değişti (before/after kısa özet)
3. hangi invariants korundu (listele)
4. save shape changed? yes/no
5. family budget reservation nasıl çalışıyor
6. hangi eski helper/const/function gerçekten silindi ve neden
7. hangi şüpheli legacy parça bilerek bırakıldı
8. hangi testler/validators koştu
9. hangileri geçti / kaldı
10. remaining risks before Part 3

STOP CONDITIONS — escalate first
- save schema değişmesi zorunlu
- load exact restore için yeni authoritative coordinate save gerekirse
- family placement'ı korumak imkansız olup Part 3 scope'a taşacak drift
- composer/UI truth'a runtime dependency taşımadan bu part bitmiyorsa
```

---

## Part 3 — Family Placement / Node Role Assignment Redesign ONLY (MEDIUM RISK)

```
Bu pass'in amacı yalnızca runtime family placement sistemini redesign etmek.
Part 2'de graph/topology generator değişmiş olabilir; önce current checked-out code'u yeniden oku ve canlı repo durumunu source of truth kabul et.

Bu pass'te DOKUNMA:
- roadside / random encounter semantic split
- presenter label rename
- composer/layout redesign
- scene/UI cleanup
- broad repo cleanup
- save schema shape
- flow state machine

Önce oku:
- AGENTS.md
- Docs/DOC_PRECEDENCE.md
- Docs/MAP_CONTRACT.md
- Docs/SCATTER_MAP_GENERATION_DESIGN.md
- Docs/HANDOFF.md
- Game/RuntimeState/map_runtime_state.gd (current checked-out)
- Tests/test_map_runtime_state.gd

Read-only bağlam:
- Docs/SOURCE_OF_TRUTH.md
- Docs/SAVE_SCHEMA.md
- Game/RuntimeState/run_state.gd

STRICT SCOPE
- Game/RuntimeState/map_runtime_state.gd
- Tests/test_map_runtime_state.gd
- behavior gerçekten değişiyorsa Docs/MAP_CONTRACT.md minimal sync

GOAL
Current family placement fazla sequential/depth-biased.
Bunu, topology'den türeyen structural role scoring sistemine çevir.

İstenen sonuç:
- aynı graph üstünde farklı seed'lerde family placement anlamlı his versin
- oyuncu farklı route karakterleri görsün
- "derin node'a boss, sığ node'a reward" mekanik hissi olmasın
- early route exposure, optional detour, support line, risk-reward outer push okunur

PRESERVE — MAP_CONTRACT family count floor
- total nodes 14
- exactly 1 start
- exactly 1 reward
- exactly 1 event
- exactly 1 side_mission
- exactly 1 key
- exactly 1 boss
- exactly 2 support opportunities (rest/merchant/blacksmith combinations)
- remaining non-start nodes primarily combat (6)
- start adjacency early floor: en az 1 combat, 1 reward, 1 opening-support
- boss outer/late baskın
- key outer/late baskın
- deterministic RNG

STRUCTURAL METRICS TO DERIVE
Topology üretildikten sonra helper'lar:
- depth_by_node_id
- degree_by_node_id
- leaf_like detection
- branch_root_by_node_id (start'tan ilk-hop ancestor / branch root)
- frontier_score (outer depth + low branching)
- connector_score (orta derinlik / junction)
- optional_detour_score (ana omurgadan ayrılan yan rota hissi)
- support_branch_score (erken erişilebilir ama derinleşebilen branch)
- progress_corridor_score (boss/key doğal ilerleme hattı)
- gerekirse shortest path / branch lineage helpers

TARGET PLACEMENT MODEL
Family placement salt depth sırasıyla değil, role-based:

Önerilen sıra:
1. start fixed
2. opening branch analysis
3. opening_support (early, ideal depth 1 veya 2)
4. reward (early-readable, farklı branch root'ta)
5. boss (outer/deepest frontier)
6. key (outer/late, boss pocket'a yığılmasın)
7. late_support (opening support ile lineage bias, ama rigid değil)
8. side_mission (leaf-like, optional detour, late-ish)
9. event (planned connector/detour)
10. remaining combat

Daha iyi bir sıra varsa açıkla ve uygula.

ROLE INTENT DETAYLARI — Plan dosyasındaki A-I maddelerine uy
A) OPENING SUPPORT: depth 1-2, güvenli utility lane hissi
B) REWARD: early, farklı branch root, gerçek route choice
C) EARLY COMBAT: start adjacency'de en az 1
D) LATE SUPPORT: opening support ile same-lineage bias (direct-adjacency rigid değilse)
E) SIDE MISSION: leaf-like, late-ish, optional contract hissi
F) EVENT: planned node, connector/detour, start adjacency'de değil, boss/key pocket'a çakışmasın
G) KEY: outer/late, boss yolunu trivialize etmesin, meaningful prep/chokepoint
H) BOSS: en outer frontier, start'a yakın olmasın
I) COMBAT FILL: route hissini destekleyen dağılım

DECISION POINT — Opening vs Late Support
İki seçenek arasında bilinçli seç ve raporla:
1. Current direct-adjacent support branch rule korunur
2. Same branch lineage / same corridor bias modeline geçilir

Hangisini seçiyorsun? Neden? Hangi testleri güncelledin? Hangi doc satırını sync ettin?

DETERMINISM
- scoring/tiebreak deterministic
- seed/stage/profile aynıysa aynı placement
- random variation sadece deterministic RNG stream üstünden

VALIDATION / REPAIR
- family counts exact
- no duplicate special assignment
- start adjacency early floor preserved
- boss outermost/near-outermost
- key outer/late enough
- side_mission optional detour feel
- support layout uyumlu
- event planned node mantıklı pocket
- family clustering okunur
- graph semantics bounded

TESTS
Mevcut testleri audit et.
Stale/over-rigid expectation'ı bilinçli değiştir.
Guarantee floor'u kazara gevşetme.

Yeni helper assertions ekle:
- branch-root diversity (opening support vs reward)
- optional detour semantics (side_mission)
- boss/key separation
- support lineage intent
- event placement sanity

ALLOWED CLEANUP
Bu pass'te yalnız family-placement redesign yüzünden dead kalan local helper/const/function.
- reference audit olmadan silme
- ambiguous parçayı bırak ve report et
- broad stale cleanup yok
- unrelated doc cleanup yok

PATCH STYLE
- helper'lar küçük
- topology analysis ile assignment logic'i ayır
- named scoring helpers
- magic number'ları açık isimlendir
- display names'i logic key yapma

WORK ORDER
1. Önce current family placement kodunu audit et
2. Implementation plan yaz
3. Patch uygula
4. Changed-area validation:
   - py -3 Tools/validate_content.py
   - py -3 Tools/validate_architecture_guards.py
   - powershell -NoProfile -ExecutionPolicy Bypass -File Tools/run_godot_tests.ps1
5. Logic değiştiği için full suite:
   - powershell -NoProfile -ExecutionPolicy Bypass -File Tools/run_godot_full_suite.ps1
6. Docs değiştiyse ilgili validators

REPORT FORMAT
1. touched files
2. family placement'ta ne değişti (before/after)
3. hangi invariants korundu
4. save shape changed? yes/no
5. support branch kuralı: direct-adjacency mi lineage mi? neden?
6. hangi eski helper/const/function silindi ve neden
7. hangi legacy/stale parça bilerek bırakıldı
8. hangi testler/validators koştu
9. hangileri geçti / kaldı
10. Part 4 öncesi remaining risks

STOP CONDITIONS — escalate first
- save schema değişmesi zorunlu
- flow state veya roadside system'e dokunmadan bitmiyorsa
- Part 2 topology yetersiz
- placement için composer/UI truth içine veri taşımak gerekiyorsa
```

---

## Part 4 — Roadside / Event Semantic Split + Destination Bug Fix (HIGH — GAMEPLAY BUG)

```
Bu pass iki iş yapar:
1. ÖNCELİKLİ BUG FIX: roadside encounter trigger olunca destination node content'inin tüketilmesini engelle
2. SEMANTIC SPLIT: planned map event node ≠ movement-triggered roadside encounter

KRİTİK BUG — Verified
run_session_coordinator.gd dosyasında roadside encounter handling bloğunda:
  if _should_open_roadside_encounter(...):
    var should_open_roadside_event: bool = _open_event_state(...)
    if should_open_roadside_event and map_runtime_state.consume_roadside_encounter_slot():
      map_runtime_state.mark_node_resolved(target_node_id)  # <-- BUG: destination content tüketiliyor
      target_state = FlowStateScript.Type.EVENT

Roadside transient bir travel interruption olmalı. Destination node (combat / support / reward / etc.) roadside'dan sonra normal akışına devam etmeli.

Bu pass'te DOKUNMA:
- composer/layout redesign
- broad scene cleanup
- broad stale cleanup
- flow state machine'i yeniden yazma (yalnız tiny local adaptation izin)
- save schema (unless truly unavoidable)

Önce oku:
- AGENTS.md
- Docs/DOC_PRECEDENCE.md
- Docs/MAP_CONTRACT.md
- Docs/HANDOFF.md
- Docs/GAME_FLOW_STATE_MACHINE.md
- Docs/SOURCE_OF_TRUTH.md
- Game/Application/run_session_coordinator.gd
- Game/RuntimeState/map_runtime_state.gd
- Game/UI/map_explore_presenter.gd
- scenes/map_explore.gd
- Tests/test_map_runtime_state.gd
- Tests/test_map_explore_presenter.gd
- Tests/test_phase2_loop.gd
- Tests/test_stage_progression.gd
- Tests/test_event_node.gd

STRICT SCOPE
- Game/Application/run_session_coordinator.gd
- Game/RuntimeState/map_runtime_state.gd
- Game/UI/map_explore_presenter.gd
- Tests/test_map_runtime_state.gd
- Tests/test_map_explore_presenter.gd
- Tests/test_phase2_loop.gd (flow tests etkilenirse)
- Tests/test_event_node.gd
- minimal doc sync: Docs/MAP_CONTRACT.md veya yeni Docs/ROADSIDE_ENCOUNTER_CONTRACT.md (hangi daha temiz karar ver ve raporla)

TARGET SEMANTIC MODEL

A) Planned node-based event
- Real node family on the map.
- Consumes a node slot.
- Visible/discoverable/resolvable.
- No longer player-facing labeled as "Roadside Encounter".

B) Travel-triggered roadside encounter
- Not a map node.
- Does not occupy a slot.
- Triggered during edge/path movement.
- Transient, movement-scoped.
- Only thing called "Roadside Encounter".

CORE FLOW RULES — Bug Fix
Player moves successfully to adjacent destination:
1. Movement cost applied.
2. Travel/roadside encounter eligibility checked.
3. If no roadside triggers:
   - Continue into normal destination node flow.
4. If roadside triggers:
   - Present/resolve roadside encounter FIRST
   - Then continue into normal destination node flow
   - Destination node MUST still behave as its own family
   - Destination node MUST NOT be silently consumed just because roadside occurred

ABSOLUTE REQUIREMENTS
- Roadside encounter NOT an extra node
- Roadside encounter NOT marking destination resolved
- Roadside encounter NOT consuming destination primary content
- After roadside, destination flow continues correctly
- Planned map event node family distinct and functional

NORMAL DESTINATION FLOW AFTER ROADSIDE
Destination continues as its family requires:
- direct combat if family is direct-combat
- support interaction if family is direct-support
- node resolve shell if family requires resolve shell
- event handling if family is planned event
- no-op/return if already resolved or non-resolving

ELIGIBILITY RULES — Roadside Trigger
Roadside trigger HARİÇ TUT aşağıdaki destination'lara hareket:
- start
- boss
- key
- side_mission
- direct support families (rest, merchant, blacksmith)
- locked targets
- undiscovered targets
- already invalid/non-movable targets
- planned event destinations (YENİ — çift event olmasın)

ROADSIDE FREQUENCY / CONTROL
- stage quota/cap preserve (mevcut cap'i audit raporla, sonra tune et)
- deterministic RNG
- anti-chain cooldown preserve/add
- arka arkaya roadside önle
- config/named constants, magic numbers değil

STATE / OWNERSHIP
- MapRuntimeState runtime truth owner kalsın
- run_session_coordinator.gd flow orchestrator kalsın
- UI/presenter presentation-only
- map truth scene/UI'ya taşınmasın
- display label'ları logic key yapma
- pending node context flow bozulmasın
- side mission targeting bozulmasın
- key/boss gate flow bozulmasın
- deterministic save/restore bozulmasın

SOURCE CONTEXT / ANALYTICS
Runtime logic'te iki source ayrı:
- node-based planned event source
- movement-triggered roadside source

Downstream logic hangisi tetiklendiğini bilebilsin.

PLAYER-FACING NAMING
Planned event node için yeni label seç. "Roadside Encounter" KULLANMA.
Kabul edilebilir seçenekler:
- Trail Event
- Forest Shrine
- Relic Site
- Unknown Ruins

Birini seç ve raporla. Önerilen default: "Trail Event" (kısa, okunur, semantic olarak doğru, mobile-readable).

Apply consistently: minimal required presentation surface.
Reserve "Roadside Encounter" for travel-triggered only.

TEST UPDATES — BİLİNÇLİ
Aşağıdaki test assertion'ları bilinçli değişecek. Her değişiklik commit message'ında "intentional test behavior change — old test locked wrong semantic" olarak belirt:

- Tests/test_map_explore_presenter.gd: "event" → "Roadside Encounter" assertion'ı yeni label'la değişecek
- Tests/test_phase2_loop.gd: roadside + destination flow senaryosu güncellenecek
- Tests/test_event_node.gd: planned event node behavior (eğer roadside ile karışık ise)

Yeni testler ekle:
1. Roadside triggers on movement, not as a node
2. Roadside does NOT mark destination resolved
3. After roadside, destination still resolves correctly
4. Same seed + same move context = deterministic roadside result
5. Stage quota/cap still works
6. Cooldown/anti-chain works
7. Excluded families never trigger roadside
8. Planned event node shows new label (not "Roadside Encounter")
9. Save/load remains valid
10. Pending node context continuation intact

ALLOWED CLEANUP
- dead local helper/branch/constant doğrudan replaced
- stale label helper doğrudan superseded
- dead test expectation doğrudan old broken behavior'a bağlı
- ambiguous legacy'yi bırak ve report et

PATCH STYLE
- typed
- helper'lar named
- travel encounter eligibility/continuation için clear helper'lar
- giant coordinator method'lardan kaçın
- continuation logic explicit ve readable

WORK ORDER
1. Current roadside/event behavior audit. Semantic mixing nerelerde? Satır numaralı not.
2. Mevcut roadside cap/quota/cooldown değerlerini rapora al.
3. Implementation plan yaz.
4. Patch uygula (bug fix öncelikli).
5. Changed-area validation:
   - py -3 Tools/validate_content.py
   - py -3 Tools/validate_architecture_guards.py
   - powershell -NoProfile -ExecutionPolicy Bypass -File Tools/run_godot_tests.ps1
6. Flow-level değişiklik olduğu için full suite:
   - powershell -NoProfile -ExecutionPolicy Bypass -File Tools/run_godot_full_suite.ps1
7. Scene wiring değiştiyse smoke:
   - powershell -NoProfile -ExecutionPolicy Bypass -File Tools/run_godot_smoke.ps1
8. Scene isolation (map_explore değiştiyse):
   - powershell -NoProfile -ExecutionPolicy Bypass -File Tools/run_godot_scene_isolation.ps1 -ScenePath scenes/map_explore.tscn

REPORT FORMAT
1. touched files
2. what changed in roadside/event semantics (before/after)
3. destination consumption bug: fixed? before/after flow diagram
4. chosen player-facing label for planned event nodes
5. mevcut roadside cap/cooldown değerleri (raporlandı)
6. which invariants preserved
7. save shape changed? yes/no
8. doc target (MAP_CONTRACT section or new ROADSIDE_ENCOUNTER_CONTRACT.md?): karar ve rationale
9. direct dead/stale pieces removed
10. suspicious leftovers intentionally left
11. tests/validators run
12. passed / failed
13. remaining risks before Part 5

STOP CONDITIONS — escalate first
- save schema change becomes necessary
- destination continuation cannot be repaired without major flow state redesign
- roadside split unexpectedly requires composer/layout redesign
- fixing this forces broad scene/UI ownership changes
- current runtime truth boundaries insufficient without larger architecture change
```

---

## Part 5 — Map Composer / Layout Redesign ONLY (MEDIUM RISK)

```
Bu pass yalnızca map board composition ve layout derivation.
Goal: board graph-native, top-down, local, forest-pocket-like hisler versin — ownership/save shape değişmeden.

Bu pass'te DOKUNMA:
- broad scene cleanup
- broad stale cleanup
- runtime graph truth redesign
- family placement redesign
- roadside/event semantics
- asset-pipeline (minimal placeholder metadata hook hariç)

Önce oku:
- AGENTS.md
- Docs/DOC_PRECEDENCE.md
- Docs/MAP_CONTRACT.md
- Docs/MAP_COMPOSER_V2_DESIGN.md
- Docs/HANDOFF.md
- Docs/VISUAL_AUDIO_STYLE_GUIDE.md
- Game/UI/map_board_composer_v2.gd
- scenes/map_explore.gd (read-only, bu pass'te dokunmamayı tercih et)
- Tests/test_map_board_composer_v2.gd

STRICT SCOPE
- Game/UI/map_board_composer_v2.gd
- Tests/test_map_board_composer_v2.gd
- Minimal doc sync: Docs/MAP_COMPOSER_V2_DESIGN.md
- Scene touch sadece composer parity gerektiriyorsa

GOAL
Board composition'ı ring/arc-slot flavored placement'tan graph-native forest pocket composition'a kaydır.

Target feel:
- center-start, top-down local map pocket
- portrait-safe, mobile-readable
- node clearings intentionally carved into forest mass
- paths feel like trails, not UI connectors
- branch structure organic/scattered, not neat arcs/rings
- generated route map, not fixed radial template
- hidden information stays hidden

IMPORTANT BOUNDARIES
- MapRuntimeState authoritative gameplay/map truth owner
- board composition derived presentation only
- authoritative board coordinates runtime state'e EKLENMESİN
- save field'lar EKLENMESİN (layout, spline points, decor, masks)
- gameplay RNG cursor'ları board redraw için TÜKETİLMESİN
- compose output deterministic from already-owned truth

PRESERVE CURRENT PUBLIC EXPECTATIONS
- deterministic composition for same saved truth
- stable world positions (same realized graph + run seed + stage)
- path family classification deterministic
- existing path family vocabulary korunsun:
  - short_straight
  - gentle_curve
  - wider_curve
  - outward_reconnecting_arc
- save/restore parity without layout fields in save

CURRENT PROBLEM — Verified
Composer shows RING_RADIUS_FACTORS := [0.0, 0.20, 0.33, 0.46, 0.58, 0.70] (satır 10).
Placement visibly ring/arc-first.

TARGET COMPOSITION MODEL

A) GRAPH-NATIVE POSITIONING
Ring-first placement'ı soften et (dominant identity olmasın).
- depth = soft radial budget, visible ring contract değil
- first-hop ancestry = branch grouping hint
- local graph density/degree/reconnect role = spacing modifier
- frontier nodes = slightly more outward (not forced to ring shell)
- reconnect nodes = intermediate pockets (not obvious bridge glyphs)
- jitter = deterministic, collision-aware
- collision resolution = shrink/nudge/within-branch önce, cross-branch drift sonra

B) CENTER-ROOTED TOP-DOWN MAP FEEL
Map hâlâ start merkezli.
"Centered" = "planetary rings" değil.
- start = anchor/origin pocket
- opening routes spread outward multiple directions
- deeper nodes drift into nearby forest pockets
- reconnects feel like forest detours/side trails
- overall read = local explored region from above

C) CLEARING-FIRST NODE PLACEMENT
Her visible node için:
- clearing center
- overlay hit target spacing
- path endpoints meet clearing edge (not icon center logic)
- visual hierarchy by family/state (sensible)
Family visuals truth logic'e girmesin.

D) PATH GEOMETRY
- edge path control point logic
- curvature direction consistency
- sibling-branch divergence readability
- reconnect path outward-then-return
- short edges over-bending yok
- path endpoints clearing boundaries

E) FOREST / POCKET FILL
Per-template flavor:
- corridor = denser tunnel/funnel feeling
- openfield = broader negative space
- loop = more visible reconnect room

Composition metadata / placeholder shape logic.
Asset production DEĞİL.

F) PORTRAIT READABILITY — CRITICAL
Portrait zoom'da:
- compact local neighborhood
- 2-3 meaningful outward choices
- overlays overlap yok
- current node + reachable options visually clear
- key/boss readiness readable without leaking hidden graph info

DON'T BREAK
- hidden node concealment
- discovered/resolved visibility semantics
- locked boss approach readability
- deterministic repeated compose
- save/restore parity
- current path family vocabulary
- current board focus assumptions (unless absolutely necessary)

TESTS
1. compose deterministic from same realized graph/save truth
2. path family classification deterministic
3. allowed path family labels valid
4. save/restore reproduces board composition without layout fields in save
5. visible node world positions non-zero, portrait-safe
6. visible overlays/anchors don't collapse into overlap
7. reconnect edges sensible family/geometry
8. forest shapes deterministic
9. hidden/deeper graph info not leaked

ALLOWED CLEANUP
- dead local placement constants/helpers proven unused
- old path geometry helpers fully superseded
- stale tiny test expectations tied to old arc-dominant behavior

Ambiguous scene fallback DOKUNMA (Part 6'da).

PATCH STYLE
- typed
- composer responsibilities clear:
  - seed derivation
  - topology analysis
  - world position derivation
  - path family resolution
  - path geometry generation
  - forest/decor fill generation
- small helpers over giant methods
- named constants

WORK ORDER
1. Current composer math audit. Ring/arc-first kısımları satır numaralı list.
2. Short implementation plan.
3. Patch map_board_composer_v2.gd.
4. Update/add tests.
5. Changed-area validation:
   - py -3 Tools/validate_content.py
   - py -3 Tools/validate_architecture_guards.py
   - powershell -NoProfile -ExecutionPolicy Bypass -File Tools/run_godot_tests.ps1
6. Full suite if presentation-impacting:
   - powershell -NoProfile -ExecutionPolicy Bypass -File Tools/run_godot_full_suite.ps1
7. Scene isolation for map_explore parity:
   - powershell -NoProfile -ExecutionPolicy Bypass -File Tools/run_godot_scene_isolation.ps1 -ScenePath scenes/map_explore.tscn

REPORT FORMAT
1. touched files
2. what changed in board composition (before/after visual approach)
3. ring/arc dominance reduction nasıl
4. what stayed deterministic
5. save shape changed? yes/no
6. scene fallback left intact for Part 6
7. local dead helpers/constants removed
8. suspicious leftovers intentionally left
9. tests/validators run
10. passed / failed
11. remaining risks before Part 6

STOP CONDITIONS — escalate first
- composer redesign requires save fields for layout truth
- deterministic restore cannot preserve without saving presentation state
- hidden-info rules cannot preserve with intended geometry changes
- meaningful composer improvement requires broad scene ownership changes
- path/render changes require larger UI architecture rewrite
```

---

## Part 6 — Map Explore Scene / Presenter / UI Cleanup ONLY (LOW RISK)

```
Bu pass'in amacı map/runtime/composer değişikliklerinden sonra player-facing map surfaces ve scene wiring temizliği.

Bu pass'te DOKUNMA:
- runtime graph generation redesign
- family placement redesign
- composer math (unless tiny parity fix strictly required)
- roadside flow semantics (unless tiny continuation/wiring repair strictly required)
- broad repo cleanup
- save schema
- source-of-truth ownership moves

Önce oku:
- AGENTS.md
- Docs/DOC_PRECEDENCE.md
- Docs/MAP_CONTRACT.md
- Docs/HANDOFF.md
- Game/UI/map_explore_presenter.gd
- scenes/map_explore.gd
- Tests/test_map_explore_presenter.gd
- Game/UI/map_board_composer_v2.gd (read-only context)

STRICT SCOPE
- Game/UI/map_explore_presenter.gd
- scenes/map_explore.gd
- Tests/test_map_explore_presenter.gd
- Minimal doc sync (nearest authority doc)

GOAL
Map board presentation yeni semantics + graph-native composer output'u yansıtsın.

Bu pass temizler:
1. old route-slot fallback assumptions in scene
2. stale player-facing naming on route nodes
3. presentation surfaces still making board feel like legacy slot UI
4. tiny leftover scene/presenter duplication or dead presentation branches

CURRENT KNOWN ISSUES — Verify ederek başla
Checked-out code'u oku ve doğrula:
- presenter event family hâlâ "Roadside Encounter" label mı?
  (Part 4 sonrası güncellenmiş olmalı; değilse raporla)
- tests hâlâ o label'ı kilitliyor mu?
- map_explore.gd composer world_position yoksa hâlâ slot_factors fallback'e dönüyor mu?
  (satır 878 civarı kontrol et)
- scene hâlâ BOARD_FOCUS_ANCHOR_FACTOR fallback'i normal path olarak kullanıyor mu?
- UI copy/transition text planned event vs travel roadside'ı blurlıyor mu?

TARGET OUTCOME

A) PRESENTATION SEMANTIC CLEANUP
- Planned map event no longer presents as "Roadside Encounter"
- Reserve "Roadside Encounter" only for travel-triggered
- Player-facing naming presenter-owned
- New node-family label consistently applied
- Tests updated deliberately

Part 4'te seçilen label'ı burada yay. Default öneri: "Trail Event".

B) SCENE WIRING CLEANUP
- Composer world positions = normal source for route-marker placement
- Legacy slot-factor placement: ya RETIRE, ya EMERGENCY-ONLY demoted
- Safety fallback ise clearly documented emergency, silent normal değil
- Scene half graph-native + half legacy-slot-driven olmasın
- Focus/hover/current-target behavior çalışsın

Layout truth scene'ye TAŞINMASIN.
Scene composition output'u consume eder, own etmez.

C) BOARD INTERACTION CLEANUP
- active target focus çalışsın
- hovered target focus çalışsın
- reachable routes markers ile align
- route icons/text family/state doğru
- current-node/cluster/anchor summary text yeni naming ile coherent

D) MINIMAL UI COPY CLEANUP
Sadece semantic split + graph-native board gerektirdiği kadar:
- planned event node label
- nearby helper copy misleading olmayacak
- tiny map-explore wording fixed-slot-list implying değil, route board implying
Broad localization/text polish yok.

E) PRESENTER OWNERSHIP
- runtime owns gameplay truth
- presenter owns player-facing map text/icon resolution
- scene consumes presenter + composer outputs
- display strings logic key olmasın

SCENE / FALLBACK POLICY — SEÇ VE RAPORLA

Option 1 — HARD RETIRE legacy slot fallback
- composer world_position required
- missing = fail loudly in debug/tests, narrow emergency anchor fallback

Option 2 — TINY EMERGENCY FALLBACK
- minimal safety only
- clearly marked non-authoritative compatibility safety
- normal parallel layout system gibi davranmasın

Default preference: Option 2 yalnız scene safety gerekli ise.
Aksi halde slot system retire.

VERY IMPORTANT
Legacy slot behavior first-class layout system olarak silently KORUMA.
Board'ın artık tek real layout source'u olsun.

TESTS
1. presenter display name for event = new label
2. "Roadside Encounter" NO longer presenter label for map event
3. boss/side_mission/support naming correct
4. route icon mapping resolves correctly
5. scene route-marker positioning prefers composer world_position
6. legacy slot-fallback removed or emergency-only
7. current-anchor/cluster/route-summary text coherent
8. focus/hover/current-target logic works
9. no save/runtime ownership drift

Stale UI testleri bilinçli değiştir.

ALLOWED CLEANUP
- dead local presentation constants/helpers
- stale label constants directly superseded
- legacy slot-position branch proven no longer needed
- dead tests encoding old wrong presentation meaning

Ambiguous scene helpers DOKUNMA ispatsız.

PATCH STYLE
- presenter-owned presentation logic
- scene focused on composition consumption + interaction wiring
- small helper extraction over giant scene methods
- typed
- UI wording changes minimal/intentional

WORK ORDER
1. Audit current presenter/scene. Stale UI/scene assumptions listele.
2. Short implementation plan.
3. Patch presenter + scene + tests.
4. Changed-area validation:
   - py -3 Tools/validate_content.py
   - py -3 Tools/validate_architecture_guards.py
   - powershell -NoProfile -ExecutionPolicy Bypass -File Tools/run_godot_tests.ps1
5. Full suite:
   - powershell -NoProfile -ExecutionPolicy Bypass -File Tools/run_godot_full_suite.ps1
6. Scene wiring değiştiyse smoke:
   - powershell -NoProfile -ExecutionPolicy Bypass -File Tools/run_godot_smoke.ps1
7. Scene isolation:
   - powershell -NoProfile -ExecutionPolicy Bypass -File Tools/run_godot_scene_isolation.ps1 -ScenePath scenes/map_explore.tscn

REPORT FORMAT
1. touched files
2. player-facing map semantics: ne değişti
3. planned event node label (Part 4'ten devraldı, burada yaydı)
4. legacy slot-fallback: removed, reduced, or emergency-only? karar + rationale
5. invariants intact
6. save shape changed? yes/no
7. direct dead presentation branches/helpers removed
8. suspicious leftovers intentionally left
9. tests/validators run
10. passed / failed
11. remaining risks before Part 7

STOP CONDITIONS — escalate first
- scene cleanup requires moving ownership away from presenter/composer/runtime boundaries
- save/runtime truth would move into scene
- route-marker correctness cannot fix without reopening composer redesign broadly
- UI cleanup unexpectedly requires larger flow-state rewrite
- this patch would become broad cross-scene refactor
```

---

## Part 7 — Stale/Dead Cleanup + Doc Truth Sync ONLY (LOW RISK)

```
Bu pass controlled cleanup + doc truth alignment (önceki map redesign pass'leri sonrası).

Goal:
- genuinely replaced dead/passive leftovers remove
- stale docs sync to checked-out code
- ambiguous compatibility surfaces leave alone unless now clearly obsolete
- migration/ownership drift yaratmadan repo cleaner

Bu pass'te DOKUNMA:
- runtime graph redesign
- family placement redesign
- roadside/event flow semantics redesign
- composer math redesign
- broad repo-wide stylistic refactor
- save schema change
- compatibility removals requiring migration/back-compat policy

Önce oku:
- AGENTS.md
- Docs/DOC_PRECEDENCE.md
- Docs/HANDOFF.md
- Docs/MAP_CONTRACT.md
- Docs/MAP_COMPOSER_V2_DESIGN.md
- Docs/SCATTER_MAP_GENERATION_DESIGN.md
- Docs/TECH_BASELINE.md
- Docs/SOURCE_OF_TRUTH.md
- Part 2-6 tarafından touched files (checked-out state)
- Touched tests

Re-read current checked-out code before deciding stale.
Pre-patch state varsaymayı bırak.

STRICT SCOPE
- Stale docs directly related to implemented map changes
- Dead local helpers/constants/branches in touched map files
- Directly stale tests encoding old replaced behavior
- Minimal handoff snapshot sync

CLEANUP PRINCIPLE
Remove ONLY:
- clearly replaced / unreachable / unused / misleading
Suspicious ise LEAVE + REPORT.
Compatibility/save/flow/hidden-ownership risk varsa REMOVE ETME.

CLEANUP INVENTORY CATEGORIES
- SAFE_DELETE_NOW
- SAFE_DELETE_AFTER_TEST_CONFIRMATION
- DOC_SYNC_REQUIRED
- KEEP_FOR_COMPAT
- KEEP_UNTIL_FURTHER_EVIDENCE
- ESCALATE_FIRST_IF_REMOVED

AREAS TO AUDIT

A) MAP/PRESENTER/SCENE LEFTOVERS
- old presenter label mappings no longer matching
- old route-slot/slot-factor/anchor fallback branches unneeded
- dead local presentation helpers/constants
- duplicate route-marker positioning paths
- stale comments describing old layout model

B) RUNTIME / FLOW LEFTOVERS
- helper branches obsolete by new graph generator
- helper branches obsolete by new family placement logic
- roadside/event semantic leftovers dead after split
- stale constants/counters unused
- old "temporary compatibility" branches now dead

C) DOC TRUTH DRIFT — Authority docs
- MAP_CONTRACT.md
- MAP_COMPOSER_V2_DESIGN.md
- SCATTER_MAP_GENERATION_DESIGN.md
- HANDOFF.md
- any tiny supporting doc

Typical drift examples:
- old claim: technical event rendered as "Roadside Encounter"
- old claim: layout slot/ring dominated when composer no longer is
- old snapshot notes not matching new generator/family/roadside behavior
- stale "next step" notes in HANDOFF referring to completed work

D) TEST LEFTOVERS
- tests locking old wrong labels
- tests locking old fallback behavior
- duplicate assertions obsolete by new stronger invariants
- brittle checks tied to replaced internals

HIGH-RISK NO-TOUCH — unless proven safe
- save/load compatibility surface
- stable IDs
- flow-state shape
- runtime owner boundaries
- long-standing compatibility shims requiring migration policy
- repo-level unrelated legacy

Any cleanup touching above: ESCALATE_FIRST_IF_REMOVED.

DOC SYNC RULES
- update nearest authority doc, not every mention
- concise docs
- no doc bloat
- no README → status file rewrite
- HANDOFF snapshot only materially changed
- doc precedence resolve disagreements

ALLOWED DELETIONS — 3 koşul true
1. clear replacement veya no remaining reference
2. behavior covered by tests/validators after removal
3. removal migration/back-compat work açmıyor

Herhangi biri false → REPORT, don't delete.

WORK ORDER
1. Audit checked-out state after Parts 2-6.
2. Produce cleanup inventory (categorized).
3. Apply ONLY safe cleanup/doc-sync subset.
4. Changed-area validation:
   - py -3 Tools/validate_content.py
   - py -3 Tools/validate_architecture_guards.py
   - powershell -NoProfile -ExecutionPolicy Bypass -File Tools/run_godot_tests.ps1
5. Broader checkpoint:
   - powershell -NoProfile -ExecutionPolicy Bypass -File Tools/run_godot_full_suite.ps1
6. Report.

VALIDATION EXPECTATIONS
- changed-area tests
- validators from TECH_BASELINE
- docs with authority meaning changed → relevant validators
- scene wiring cleanup → smoke (AGENTS fast-lane requires)
- "clean" claim öncesi explicit broader checkpoint

REPORT FORMAT

1. CLEANUP INVENTORY SUMMARY (categorized)

2. TOUCHED FILES
For each: what changed, why safe, deletion/simplification/doc alignment

3. DOC TRUTH ALIGNMENT
- which docs stale
- which claims corrected
- which intentionally left + why

4. REMOVED ITEMS
- exact helpers/constants/branches/tests/doc lines
- why dead/replaced

5. LEFTOVER ITEMS
- suspicious not removed
- missing evidence
- later pass owner

6. INVARIANTS PRESERVED
- runtime truth ownership moved? yes/no
- save shape changed? yes/no
- flow-state shape changed? yes/no
- stable IDs changed? yes/no

7. VALIDATION
- commands run
- passed / failed
- checkpoint suite run

8. READINESS FOR FINAL PASS
- what remains
- risks open
- escalate-first items

STOP CONDITIONS — escalate first
- removing requires migration/back-compat policy
- candidate touches save schema or stable IDs
- cleanup reopens runtime truth ownership questions
- cleanup requires larger flow-state rewrite
- candidate appears unused but evidence insufficient
```

---

## Part 8 — Final Review + Audit + Patch (LOW RISK)

```
Final integration/hardening pass after earlier map redesign parts.
Currently checked-out branch = source of truth.
Re-read repo, audit actual branch state BEFORE patching.
Earlier prompt'ların tam landed olduğunu varsayma.

Mission:
- review what was actually implemented
- audit remaining semantic drift, runtime/presentation mismatches, stale docs, dead leftovers, broken tests
- patch ONLY remaining necessary issues
- right validation stack
- finish clean, truthful, repo-safe

Bu YENI REDESIGN pass'i DEĞİL.
Broad architecture açma unless real correctness issue forces.
Small targeted fixes over one more large refactor.

Önce oku:
- AGENTS.md
- Docs/DOC_PRECEDENCE.md
- Docs/TECH_BASELINE.md
- Docs/SOURCE_OF_TRUTH.md
- Docs/MAP_CONTRACT.md
- Docs/MAP_COMPOSER_V2_DESIGN.md
- Docs/SCATTER_MAP_GENERATION_DESIGN.md
- Docs/HANDOFF.md

Sonra checked-out:
- Game/RuntimeState/map_runtime_state.gd
- Game/Application/run_session_coordinator.gd
- Game/UI/map_board_composer_v2.gd
- Game/UI/map_explore_presenter.gd
- scenes/map_explore.gd
- Tests/test_map_runtime_state.gd
- Tests/test_map_board_composer_v2.gd
- Tests/test_map_explore_presenter.gd
- Tests/test_phase2_loop.gd
- Tests/test_stage_progression.gd
- Tests/test_event_node.gd
- Adjacent files/tests/docs touched

Keep scope map-related and local.

OBJECTIVES

1. INTEGRATION AUDIT
Branch şunları actually achieve ediyor mu:
- center-start constrained scatter runtime graph
- topology-first then family-assignment
- meaningful route semantics near start
- roadside encounter split from planned node-based event (bug fixed)
- composer-driven graph-native board layout
- presenter/scene surfaces reflecting new semantics
- stale replaced leftovers removed where safe
- docs aligned to checked-out truth

2. REMAINING GAP PATCH
Patch ONLY real remaining gaps.

Acceptable work:
- missed semantic mismatch
- small continuation bug
- stale presenter/scene/test expectation
- doc truth drift
- dead local helper/branch left behind
- small parity fix (runtime/composer/presenter disagree)
- missing validation hardening
- tiny cleanup for final coherence

NOT acceptable (unless absolutely forced):
- another full graph redesign
- another full family-placement rewrite
- another large composer redesign
- broad repo-wide cleanup outside map area
- save schema redesign
- new flow-state architecture
- ownership moves across runtime/application/UI boundaries

3. CLEANLINESS GOAL
- remove genuinely dead/passive leftovers
- remove stale test expectations
- sync stale docs
- ambiguous compatibility DOKUNMA
- migration/back-compat cleanup GENİŞLETME

FINAL AUDIT CHECKLIST

A) OWNER / BOUNDARY CHECK
- MapRuntimeState runtime truth owner
- RunSessionCoordinator orchestration owner
- MapBoardComposerV2 derived presentation only
- scene/presenter don't own gameplay truth
- display labels not logic keys
- save shape not drifted

B) TOPOLOGY / FAMILY GUARANTEE CHECK
- total nodes 14
- exactly 1 start
- start adjacency readable & constrained
- connected graph from start
- at least one reconnect
- early route floor
- boss/key late/outer enough
- family counts/semantics sensible
- side mission correct

C) ROADSIDE / EVENT SEMANTIC CHECK
- planned map event ≠ travel-triggered roadside
- roadside NOT fake node
- roadside NOT consuming destination content
- destination resolves correctly afterward (BUG FIXED?)
- player-facing naming reflects split
- tests don't lock old mixed meaning

D) COMPOSER / SCENE CHECK
- deterministic from authoritative truth
- world positions composer-driven
- legacy slot-fallback removed or emergency-only
- path families valid/deterministic
- portrait-readable
- hidden info not leaked
- scene not silently second layout authority

E) DOC TRUTH CHECK
Drift audit:
- MAP_CONTRACT.md
- MAP_COMPOSER_V2_DESIGN.md
- SCATTER_MAP_GENERATION_DESIGN.md
- HANDOFF.md
- tiny supporting docs

Update only actually stale. Concise. No bloat.

F) HANDOFF / OPEN RISK CHECK
Re-check HANDOFF.md truthfully describes:
- current runtime spine
- current map/event/roadside semantics
- current board truth and generator state
- current validation status
- current open risks

Overlay/responsive layout actually runtime-tested bu pass'te ise UPDATE.
If not, don't falsely mark resolved.

ALLOWED WRITE SCOPE
- map-related files
- directly related tests
- nearest authority/support docs
- tiny validator/tooling
Map-related area dışı SADECE final-pass blocker ise.

VALIDATION — REQUIRED
- py -3 Tools/validate_content.py
- py -3 Tools/validate_architecture_guards.py
- powershell -NoProfile -ExecutionPolicy Bypass -File Tools/run_godot_tests.ps1
- powershell -NoProfile -ExecutionPolicy Bypass -File Tools/run_godot_full_suite.ps1
- powershell -NoProfile -ExecutionPolicy Bypass -File Tools/run_godot_smoke.ps1 (scene wiring changed)
- powershell -NoProfile -ExecutionPolicy Bypass -File Tools/run_godot_scene_isolation.ps1 -ScenePath scenes/map_explore.tscn (map scene changed materially)

Final cleanliness claim'i için MUTLAKA:
- changed-area validation
- validators
- explicit broader checkpoint/full suite

Command fail ederse exact komut + neden raporla.

WORK ORDER
1. Audit branch against intended end-state.
2. Gap list:
   - correctness gaps
   - stale docs
   - dead leftovers
   - risky leftovers to keep
3. Patch real remaining issues.
4. Changed-area validation first.
5. Validators.
6. Broader checkpoint / full suite.
7. Scene wiring changed → smoke / scene isolation.
8. Update docs/handoff truthfully.
9. Final status report.

REPORT FORMAT — STRICT

1. FINAL AUDIT SUMMARY
- what is now complete
- what was still wrong before this pass
- what was patched this pass

2. TOUCHED FILES
For each: what/why/fix|cleanup|doc-sync|test-sync

3. INVARIANT CHECK — state clearly
- runtime truth ownership moved? yes/no
- save shape changed? yes/no
- flow-state shape changed? yes/no
- stable IDs changed? yes/no
- display text as logic key? yes/no

4. CLEANUP RESULT
- exact dead leftovers removed
- exact suspicious leftovers kept
- why each kept not safe

5. DOC TRUTH RESULT
- which stale
- claims corrected
- HANDOFF updated
- any open risk still open

6. VALIDATION RESULT
Every command run:
- passed / failed
- short note

7. FINAL RISK REGISTER
- remaining risks
- severity
- blocking "good enough to continue" or not

8. FINAL READINESS — choose one
- READY
- READY WITH NON-BLOCKING FOLLOW-UPS
- ESCALATE FIRST

Not fully READY → explain exactly why.

STOP CONDITIONS — escalate first
- save schema shape would change
- new flow state required
- ownership move across runtime/application/UI
- cleanup requires migration/back-compat policy
- fixing reopens broad redesign scope
- validation reveals deeper regression requiring separate guarded pass
```

---

## Asset Part 1 — Prototype Map Asset Audit + Gap Plan (NO-CODE)

```
Bu pass'in amacı final-quality art üretmek değil.
Amaç:
- mevcut repo map-related asset yüzeylerini audit
- hangi prototype asset zaten var
- küçük geçici asset kit map redesign'ı görünür bağlayacak
- kontrollü production plan

Henüz:
- broad code refactor yok
- final art hedeflemek yok
- broad stil değişikliği yok
- bütün oyun asset'lerini elden geçirmek yok

Önce oku:
- AGENTS.md
- Docs/DOC_PRECEDENCE.md
- Docs/VISUAL_AUDIO_STYLE_GUIDE.md
- Docs/MAP_COMPOSER_V2_DESIGN.md
- Docs/HANDOFF.md
- AssetManifest/asset_manifest.csv
- Map board/icon/background yakın source dosyaları
- Game/UI/map_board_composer_v2.gd (checked-out post-Part 5)
- scenes/map_explore.gd (checked-out post-Part 6)
- Game/UI/map_explore_presenter.gd (checked-out post-Part 6)

AUDIT ÇIKAR

1. REPO'DA ZATEN VAR OLAN MAP ASSET YÜZEYLERİ
- map backgrounds
- map board backdrop
- walker assets
- existing map icons
- placeholder kalan map icons
- runtime'da gerçekten kullanılan asset paths (manifest + code ile cross-ref)

2. GÖRSEL OLARAK EKSİK PROTOTYPE KATMANLAR
Check checked-out branch. Beklenen eksikler:
- node clearing decal
- path/trail decal family
- canopy/forest clump stamps
- fog pocket / shadow pocket stamps
- node plate / pedestal / rim variants
- state rims (reachable / resolved / locked)
- event node new label'a uygun icon (Part 4/6'dan sonra)
- placeholder side mission icon iyileştirmesi
Verify edilmeden addition ekleme.

3. STİL KİLİTLERİ (VISUAL_AUDIO_STYLE_GUIDE'dan)
- renk yönü
- kontrast önceliği
- icon sadeliği
- forest/dark fantasy ton sınırı
- NE OLMAMASI gerektiği
- küçük ekran okunabilirlik

4. EN KÜÇÜK FAYDALI MAP KIT
Öneri (checked-out state'e göre tune et):
- 3 canopy clump
- 2 clearing decal
- 4 path decal (straight/gentle/wider/reconnect mapping)
- 3 node plate/rim (neutral/subdued/locked)
- 1 event/trail icon fix (yeni label'a uygun)
- 1 side mission icon polish
Better minimum set varsa öner.

5. INTEGRATION RISK — her item için
- asset-only
- scene/composer hookup gerektiriyor
- riskli
- sonraya bırakılmalı

ÇIKTI FORMATI
1. Current asset audit
2. Missing prototype map kit
3. Minimum viable asset production plan
4. Files/folders to touch
5. Safe production order
6. No-code or tiny-code recommendation
7. Asset Part 2 için hazırlık durumu

Bu pass sonunda PATCH YAPMA.
Audit + plan + report.
```

---

## Asset Part 2 — Generate / Add Small Prototype Map Kit (ASSETS + MANIFEST)

```
Bu pass'in amacı final-quality art değil.
Amaç: map redesign'ın çalıştığını görsel bağlayacak küçük temiz prototype map kit.

Önce checked-out branch'i yeniden oku.
Önceki asset audit (Asset Part 1) çıktısını kullan ama dosyaları re-verify et.

Önce oku:
- Docs/VISUAL_AUDIO_STYLE_GUIDE.md
- Docs/MAP_COMPOSER_V2_DESIGN.md
- AssetManifest/asset_manifest.csv
- Map asset paths
- SourceArt/Generated ve SourceArt/Edited (varsa)
- Runtime asset references (composer/scene/presenter)

STRICT SCOPE
- Yeni küçük prototype map asset'ler üret veya repo içinde author et
- Doğru runtime paths'e koy
- Source/master kopyalarını SourceArt'a koy
- AssetManifest'e kayıt düş

Henüz:
- broad integration refactor yok
- broad UI rewrite yok

STYLE RULES — Bağlı kal
- dark forest wayfinder
- readable before atmospheric
- stylized not realistic
- mobile-readable, small-screen-first
- not photorealistic
- not anime
- not watercolor
- not pixel art
- not muddy green wash

ASSET GOAL

1. Canopy clump stamps — en az 3 varyant
- top-down forest canopy
- okunurluğu boğmasın

2. Clearing decals — en az 2 varyant
- node altına oturan açık zemin/pocket

3. Trail/path visuals — en az 4 görünüş
- mevcut path family ile mapping:
  - short_straight
  - gentle_curve
  - wider_curve
  - outward_reconnecting_arc

4. Node plate / rim / pedestal — en az 3 state
- neutral/reachable
- resolved/subdued
- locked or special emphasis

5. Missing or placeholder icon polish
- side mission placeholder ise iyileştir
- event node yeni semantiğe uygun icon

FORMAT / AUTHORING
- SVG veya basit PNG (hızlı prototype)
- Ağır painterly final art YOK
- Repo içinden üretilebilen temiz placeholder/prototype quality
- Runtime'da stabil kullanılacak paths
- Source/master ayrı

PATH / FOLDER RULES
- source/master → SourceArt/Generated/ veya uygun existing source klasörü
- runtime → Assets/... altındaki uygun klasör
- mevcut klasör yapısını bozma
- asset provenance AssetManifest'te
- replace_before_release dürüst işaretle
- prototype/placeholder/temp notları açık

MANIFEST RULE — Her yeni asset için AssetManifest/asset_manifest.csv'ye satır ekle:
- asset_id
- area
- status
- source_tool
- source_origin
- license
- ai_used
- commercial_status
- master_path
- runtime_path
- replace_before_release
- last_reviewed_at
- notes

Kod değişikliği gerekiyorsa TINY HOOKUP HAZIRLIĞI ONLY.
Asıl hookup Asset Part 3'te.

VALIDATION
- py -3 Tools/validate_content.py (manifest tutarlılığı)
- Manifest format check
- Broken path ref check

REPORT FORMAT
1. produced assets (liste + paths)
2. source paths
3. runtime paths
4. manifest updates
5. style choices
6. what stayed intentionally temporary
7. whether any code was touched
8. Asset Part 3 için hazırlık
```

---

## Asset Part 3 — Hook Prototype Map Kit Into Board (CODE + ASSET)

```
Bu pass'in amacı Asset Part 2'de üretilen prototype map kit'i mevcut map board'a bağlamak.

Henüz:
- broad redesign yok
- unrelated cleanup yok
- final polish yok

Önce oku:
- Game/UI/map_board_composer_v2.gd (checked-out post-Part 5)
- scenes/map_explore.gd (checked-out post-Part 6)
- Game/UI/map_explore_presenter.gd (checked-out post-Part 6)
- Docs/MAP_COMPOSER_V2_DESIGN.md
- Docs/VISUAL_AUDIO_STYLE_GUIDE.md
- AssetManifest/asset_manifest.csv
- Yeni map asset paths (Asset Part 2'den)

STRICT SCOPE
- map board rendering / presentation
- tiny scene hookup
- tiny presenter/icon mapping
- directly related tests
- minimal manifest/doc sync

GOAL
Yeni prototype map kit:
- node clearings daha kasıtlı görünsün
- paths trail hissi versin
- board etrafı forest pocket
- reachable/resolved/locked/special readability artsın
- portrait-safe kalsın
- gameplay truth presentation'a taşınmasın

IMPLEMENTATION INTENT
- composer'dan gelen derived data kullan
- asset binding presentation-only
- canopy/decor/clearing/path asset'leri board'a deterministic yerleştir
- asset yoksa dar fallback
- fallback emergency-only safety, normal sistem gibi değil

IMPORTANT
- runtime truth'a yeni layout/save alanı EKLEME
- display paths gameplay key yapma
- performance bozacak ağır particle/animation YOK
- küçük ekran readability bozma
- hidden info leak YOK

TEST / VALIDATION
En az:
1. map scene açılıyor
2. asset paths kırık değil
3. board assets visible bağlanıyor
4. reachable node readability düşmüyor
5. same seed/stage → aynı board compose + asset placement
6. missing asset → crash yok
7. hidden node semantics bozulmuyor

VALIDATION COMMANDS
- py -3 Tools/validate_content.py
- py -3 Tools/validate_architecture_guards.py
- powershell -NoProfile -ExecutionPolicy Bypass -File Tools/run_godot_tests.ps1
- powershell -NoProfile -ExecutionPolicy Bypass -File Tools/run_godot_smoke.ps1
- powershell -NoProfile -ExecutionPolicy Bypass -File Tools/run_godot_scene_isolation.ps1 -ScenePath scenes/map_explore.tscn

REPORT FORMAT
1. touched files
2. hooked assets (id + runtime path)
3. fallback policy
4. what improved visually
5. save shape changed? (beklenen: no)
6. tests/validation run
7. passed / failed
8. remaining visual rough edges (Asset Part 4 için)

STOP CONDITIONS — escalate first
- asset hookup runtime truth'a layout alanı ekletiyorsa
- display paths gameplay key haline geliyorsa
- performance regression
- hidden info leak
```

---

## Asset Part 4 — Final Prototype Asset Review + Cleanup + Doc/Manifest Sync (NO-CODE + MANIFEST)

```
Bu pass'in amacı:
- prototype map asset pass gerçekten temiz bittiğini doğrula
- dead temp denemeleri temizle
- AssetManifest truth'unu düzelt
- docs/handoff küçük sync
- final-release art işine GİRMEK YOK

Önce checked-out branch'i yeniden oku.

Oku:
- AssetManifest/asset_manifest.csv
- Docs/HANDOFF.md
- Docs/VISUAL_AUDIO_STYLE_GUIDE.md
- Map board touched files
- Yeni asset dosyaları
- İlgili test/validator çıktıları

YAPILACAKLAR
1. Prototype map asset pass sonrası dead/replaced denemeleri tespit et
2. Gerçekten kullanılmayan temp dosyaları sadece GÜVENLİYSE temizle
3. AssetManifest satırlarını doğrula (runtime path consistency)
4. Handoff'a gerekiyorsa küçük current-state notu ekle
5. Yeni asset'ler final değilse open olarak bırak
6. Görsel olarak tutarsız asset varsa not düş (broad repaint YOK)

VALIDATION
- py -3 Tools/validate_content.py
- Broken path/reference check
- Manifest/runtime path consistency
- powershell -NoProfile -ExecutionPolicy Bypass -File Tools/run_godot_tests.ps1
- powershell -NoProfile -ExecutionPolicy Bypass -File Tools/run_godot_smoke.ps1
- Environment yüzünden çalışmayan komut varsa dürüst yaz

REPORT FORMAT
1. Final asset audit summary
2. Kept assets (liste + status)
3. Removed temp leftovers
4. Manifest/doc sync changes
5. Passed/failed validation
6. Remaining non-blocking art debt (Dark Forest Wayfinder final art için beklenen)
7. FINAL READINESS — choose one:
   - READY
   - READY WITH FOLLOW-UPS
   - ESCALATE FIRST

Not fully READY → explain why.

STOP CONDITIONS — escalate first
- cleanup AssetManifest schema'sına dokunuyorsa
- removal stable asset_id'leri etkiliyorsa
- repo-wide unrelated asset changes gerekiyorsa
```

---

## Queue Kullanım Notları

1. **Her part bağımsız queue item**. Aralarında insan müdahalesi olmadan çalışabilirler ama çıktı kalitesi için Part N tamamlandıktan sonra Part N+1'e geçmek en güvenli.

2. **Sıra değiştirme**:
   - Part 1 atlanabilir (bu plan dosyası + Part 1'in input'u zaten Part 1'in yapacağı audit'i içeriyor), ama Codex kendi audit'ini yapmak isterse tercih edilebilir.
   - Part 4 bug fix kritik — mümkünse Part 2+3'ten sonra beklemeden çalıştır.
   - Asset parts (A1-A4) ayrı track. Kod pipeline (Part 1-8) bittikten sonra çalıştır.

3. **Stop conditions** her partta tanımlı. Codex bir partta `escalate first` derse, sonraki partı başlatma; ilgili kararı manuel ver.

4. **Save schema immutability** her partta tekrarlandı. Herhangi bir part save shape değiştirmek zorundaysa bu ciddi bir sinyal — plan re-visit edilmeli.

5. **Test güncellemeleri bilinçli**. Aşağıdaki testler kesinlikle değişecek:
   - `Tests/test_map_explore_presenter.gd` (Part 4/6 — label)
   - `Tests/test_map_runtime_state.gd` (Part 2/3 — topology + placement)
   - `Tests/test_map_board_composer_v2.gd` (Part 5 — ring reduction)
   - `Tests/test_phase2_loop.gd` (Part 4 — roadside flow)
   - `Tests/test_event_node.gd` (Part 4 — event vs roadside)

6. **Mevcut diğer pipeline'larla entegrasyon** (plan dosyasındaki öneri):
   - Refactor pipeline (`codex_refactor_plan.md`) bittikten SONRA bu map redesign başlasın (özellikle NodeResolve audit önce bitmeli).
   - Migration pipeline (`codex_migration_prompts.md`) map redesign + assets bittikten SONRA başlasın (Part 6'ya kadar Migration çakışır).

7. **Toplam queue süresi tahmini**: Her part 30-90 dk (Codex hızına göre). Toplam ~8-15 saat (overnight yeterli, Asset parts dahil).
