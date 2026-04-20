# EXECUTION ROADMAP — Docs/Promts

Bu dosya `Docs/Promts/` altındaki **tüm aktif prompt'ların** ne işe yaradığını ve **hangi sırayla** Codex'e verileceğini tek yerde toplar.

- Kaynak envanter: bu repo, 2026-04-20 tarihli canlı tarama
- Durum tablosu kaynağı: `Docs/Promts/Q2_Plan/STATUS.md`
- Otorite dokümanlar: `AGENTS.md`, `Docs/DOC_PRECEDENCE.md`, `Docs/HANDOFF.md`
- İlgili roadmap'ler: `Docs/ROADMAP_2026Q2.md` (kısa vade), `Docs/LONG_TERM_ROADMAP.md` (uzun vade)

---

## 0. Nasıl kullanılır

1. Her satırı tek tek Codex'e ver. Satırdaki dosya yolunu kopyala, Codex o dosyayı kendi okur.
2. Bir satır bitmeden sonrakine geçme. Her prompt dosyasının kendi `validation budget` bloğu var; validator yeşil olmadan sıradaki prompt'a geçmek ilerde geri dönüş yaratır.
3. Lane renkleri:
   - **Fast** = dar kapsamlı, düşük risk (doc-only veya küçük kod)
   - **Guarded** = birden fazla dosya etkilenir, save/flow/contract'a dokunabilir
   - **Escalate-First** = owner layer veya save shape'e yakın; önce escalate-first ifadesini doldurman gerekir
4. Her satır bittiğinde STATUS.md'deki ilgili satırı "applied" olarak işaretle.
5. Batch'ler arasında commit at. Bir batch'in tamamı biter → tek commit → sonraki batch.

---

## 1. Prompt dosyaları — ne işe yarıyor (genel)

### 1.1 `Q2_Plan/` (25 prompt, aktif Q2 kuyruğu)

Bu klasör AGENTS.md Speed Mode Contract formatında, Q2 audit backlog'unu (P-01..P-15, E-1..E-5, O-1..O-2) **madde madde uygulatan** prompt'lardır. STATUS.md + README.md birlikte indeks görevi görür.

- **W0 grubu** (w0_01..w0_06): Doküman baseline'ı. Audit report'unu, HANDOFF'u, DECISION_LOG'u, SAVE_SCHEMA'yı ve catalog drift'i canlı repo ile eşitler. Kod dokunmaz.
- **W1 grubu** (w1_01..w1_09): Düşük riskli kod hijyeni + karar dokümantasyonu. Stale wrapper silme, helper extraction, texture loader konsolidasyonu, validator guard genişletme, 6 kararın (D-041..D-046) koda ve dokümana işlenmesi, gate_warden retire.
- **W2 grubu** (w2_01..w2_07): Guarded yapı temizliği. NodeResolve contract alignment, AppBootstrap narrowing, error handling standardı, scene theme konsolidasyonu, inventory panel traversal hotspot kaldırma, portrait density sabitleri, SceneRouter overlay sertleştirme.
- **W3 grubu** (w3_01): Tek escalate-first iş — `MapRuntimeState` extraction.
- **W4 grubu** (w4_01..w4_02): Opsiyonel, evidence-gated kalite pasları.

### 1.2 `CODEX_V2_MASTER_PROMPTS.md` (V1 seti, 17 prompt inline)

Q2_Plan'dan **önce** yazılmış orijinal master set. Çoğu prompt Q2_Plan tarafından **yeniden üretildi**, ama bir kısmı hâlâ tek kaynak. STATUS.md'deki V2_MASTER tablosu hangilerinin uygulandığını/süperseded olduğunu gösterir.

- Prompt 0.1 (Maintainability Audit) → Q2_Plan `w0_01` ile süperseded.
- Prompt 1.1..1.6 (doc + helper düzeltmeleri) → büyük kısmı Q2 W0/W1 ile süperseded; 1.5 (stale wrapper) ve 1.6 (validator guard) hâlâ aktif alternatif.
- Prompt 2.1 (AppBootstrap narrow) → **zaten uygulanmış** durumda (scene'lerde 0 çağrı), STATUS.md'de işaretli.
- Prompt 2.2..2.6 → Q2 W2 grubuyla örtüşüyor; Codex'e W2 dosyalarını ver, bunları verme.
- Prompt 3.1, 3.2 (extraction preflight, REPORT-ONLY) → BIG_FILE set tarafından süperseded.
- Prompt 5.1, 5.2 (polish) → Q2_Plan `w4_01`, `w4_02` ile aynı işi yapar.

**Sonuç:** V2_MASTER dosyası referans olarak kalsın, yeni Codex koşusunda **Q2_Plan dosyalarını ver**. V2_MASTER'dan çalıştırılacak tek şey: Prompt 1.5 + 1.6'nın muadili olan W1 versiyonları.

### 1.3 `CODEX_V2_BIG_FILE_MASTER_PROMPTS.md` (20 prompt, büyük dosya extraction kuyruğu)

Bu dosya 4 hotspot dosyanın extraction planını çıkarır ve madde madde uygulatır:

- **MBC-0..MBC-4**: `map_board_composer_v2.gd` (1251 satır) → Trail Geometry + Node Placement + Canopy + Fallback helper'larına ayır.
- **INV-0..INV-4**: `inventory_actions.gd` (1087 satır) → Equip/Unequip + Reorder/Swap + Use/Consume + Grant command family'lerine ayır.
- **RSC-0..RSC-3**: `run_session_coordinator.gd` (1016 satır) → Movement Resolution + Roadside Continuation + Pending Screen helper'larına ayır.
- **MRB-0..MRB-3**: `map_route_button_binder.gd` (1060 satır) → Route Button + Marker State + Hover/Tooltip binder'larına ayır.
- **CMB-OPT, MEP-OPT**: combat.gd + map_explore.gd kart-child traversal hotspot'ları.

Bu kuyruk Q2 W3-01 tamamlandıktan sonra devreye alınacak (long-term roadmap Faz B). Şu an **zamanlaması erken** — Q2 Cleanup bitmeden bu kuyruk açılmasın.

### 1.4 `MAP_MASTER_PROMPTS.md` (8 prompt, map overhaul kuyruğu)

Harita redesign kuyruğu. Canlı grep'e göre:

- **Prompt 1** (combined redesign + theming audit): REPORT-ONLY, tek seferlik. Şu an koşmaya değer mi tartışılır; opsiyonel.
- **Prompt 2A** (display-name helper): **uygulandı** — `Game/UI/map_display_name_helper.gd` mevcut.
- **Prompt 2B** (presenter wiring): **uygulandı**.
- **Prompt 3** (topology refactor): **uygulandı** — `map_runtime_graph_codec.gd` mevcut.
- **Prompt 4** (reconnect tuning): kısmen uygulandı; tekrar koşmaya değer.
- **Prompt 5** (placement tuning): kısmen uygulandı; tekrar koşmaya değer.
- **Prompt 6** (composer path-family differentiation): **uygulandı** — `PATH_FAMILY_GENTLE_CURVE`, `PATH_FAMILY_SHORT_STRAIGHT` composer'da canlı.
- **Prompt 7** (asset hook wiring): **uygulanmadı** — asset pipeline devreye alınmamış.
- **Prompt 8** (variation verification + residue cleanup): **uygulanmadı**.

**Sonuç:** Map pipeline'ının core'u kapalı. Prompt 7 + 8 asset üretimi başlayınca (LONG_TERM_ROADMAP Faz E) çalıştırılır. Şu an **dokunma**.

### 1.5 `AI_ASSET_ROADMAP_V2.md` (asset üretim rehberi, prompt değil)

Bu dosya Codex'e verilen bir prompt değil — **kullanıcı için** asset üretim rehberi (FLUX/SDXL + ComfyUI + Krita). LoRA eğitimi, prompt şablonları, 7 günlük plan içerir. Asset üretimi başlayınca (Faz E) bu dosyayı kullanıcı kendisi takip eder. Codex kuyruğuna **girmez**.

### 1.6 `MAP_RUNTIME_STATE_EXTRACTION_PLAN.md` (plan, prompt değil)

W3-01'in okumak zorunda olduğu teknik plan. `Docs/MAP_RUNTIME_STATE_EXTRACTION_PLAN.md` ile **aynı içeriği duplicate** eder. `Q2_Plan/w0_06` tam olarak bu duplicate'i silmek için yazılmış — W0'ı koşarken otomatik temizlenir.

### 1.7 `Q2_Plan/README.md` ve `Q2_Plan/STATUS.md`

- README.md: Q2_Plan 25-satırlık batch kuyruğunun indeksi.
- STATUS.md: V1 + Q2 + MAP + BIG_FILE dört grubun birleşik durum tablosu + 37-satırlık yürütme sırası.

Bu iki dosya Codex'e prompt olarak verilmez; **sen** takip için okursun.

### 1.8 `Archive/` klasörü

Eski prompt kuyrukları. Hiçbirini Codex'e verme. Referans olarak kalsın.

---

## 2. Kesin yürütme sırası (Codex'e bu sırayla ver)

Aşağıdaki tabloda **yalnız aktif, hâlâ uygulanmamış** prompt'lar var. "Applied" olanlar listeden çıkarıldı.

### Batch 1 — Doc baseline (Fast, 6 prompt)

| # | Prompt dosyası | Ne yapar | Lane |
|---|---|---|---|
| 1 | `Q2_Plan/w0_01_recreate_maintainability_audit.md` | Audit raporunu canlı grep'lerle yeniden üretir | Fast |
| 2 | `Q2_Plan/w0_06_extraction_plan_duplicate_cleanup.md` | `Docs/Promts/MAP_RUNTIME_STATE_EXTRACTION_PLAN.md` duplicate'ini siler | Fast |
| 3 | `Q2_Plan/w0_04_save_schema_pending_node_drift.md` | SAVE_SCHEMA pending-node ownership doc drift'ini kapatır (P-01) | Fast |
| 4 | `Q2_Plan/w0_05_catalog_drift_register.md` | `turn_phase_resolved`, `BossPhaseChanged` event'lerini catalog'a ekler (P-02) | Fast |
| 5 | `Q2_Plan/w0_03_decision_log_q2_entries.md` | D-041..D-046'yı DECISION_LOG'a yazar | Fast |
| 6 | `Q2_Plan/w0_02_handoff_refresh.md` | HANDOFF.md'yi güncel snapshot'a çeker | Fast |

**Batch 1 exit:** `py -3 Tools/validate_architecture_guards.py` yeşil. Commit: "docs: refresh Q2 doc baseline (W0-01..W0-06)".

### Batch 2 — Karar dokümantasyonu (Fast, doc-only, 4 prompt)

| # | Prompt dosyası | Ne yapar | Lane |
|---|---|---|---|
| 7 | `Q2_Plan/w1_08_runstate_compat_freeze_note.md` | RunState compat-surface freeze kararını (D-042) kod + doc'a yazar | Fast |
| 8 | `Q2_Plan/w1_05_hamlet_phase_split_note.md` | Hamlet phase-split kararını (D-043) işler | Fast |
| 9 | `Q2_Plan/w1_06_inventory_cached_getter_exception_note.md` | InventoryState cached-getter write-through istisnasını (D-044) işler | Fast |
| 10 | `Q2_Plan/w1_07_zz_prefix_convention_note.md` | `zz_*` event-template stable-ID konvansiyonunu (D-045) işler | Fast |

**Batch 2 exit:** 6 kararın hepsi DECISION_LOG + kod block comment + authority doc'ta tutarlı. Commit: "docs: codify Q2 decisions D-042..D-045 in owner files".

### Batch 3 — Kod hijyeni (Fast, 5 prompt)

| # | Prompt dosyası | Ne yapar | Lane |
|---|---|---|---|
| 11 | `Q2_Plan/w1_01_prune_stale_wrappers.md` | `transition_to`, `is_supported_save_state_now` vb. stale wrapper'ları siler (P-05) | Fast |
| 12 | `Q2_Plan/w1_02_inventory_display_helper_extraction.md` | Duplicate inventory display-name helper'ı tek yere toplar (P-03) | Fast |
| 13 | `Q2_Plan/w1_03_texture_loader_consolidation.md` | Texture loader helper'ı konsolide eder (P-04) | Fast |
| 14 | `Q2_Plan/w1_04_validator_guard_expansion.md` | Validator'a catalog-drift + stale-wrapper guard ekler (P-06) | Fast |
| 15 | `Q2_Plan/w1_09_gate_warden_retire.md` | `gate_warden` içerik + referanslarını retire eder (D-046) | Fast |

**Batch 3 exit:** Full suite yeşil. Commit: her prompt için ayrı ayrı atılabilir.

### Batch 4 — Yapı temizliği (Guarded, 7 prompt)

| # | Prompt dosyası | Ne yapar | Lane |
|---|---|---|---|
| 16 | `Q2_Plan/w2_01_node_resolve_contract_alignment.md` | NodeResolve live fallback contract'ını doc ile hizalar (B-2, D-041) | Guarded |
| 17 | `Q2_Plan/w2_02_app_bootstrap_raw_getter_narrowing.md` | AppBootstrap raw getter'larını daraltır (P-10) | Guarded |
| 18 | `Q2_Plan/w2_03_application_error_handling_standardization.md` | Application invalid-state/error handling stilini standartlaştırır (P-11) | Guarded |
| 19 | `Q2_Plan/w2_04_scene_theme_layout_finish.md` | Scene tema/layout drift'ini tamamlar (P-12) | Guarded |
| 20 | `Q2_Plan/w2_05_inventory_panel_traversal_hotspots.md` | Inventory panel post-render traversal hotspot'larını kaldırır (P-13) | Guarded |
| 21 | `Q2_Plan/w2_06_portrait_density_constants.md` | Portrait density/theme rhythm/accessibility sabitlerini tek yere alır (P-14) | Guarded |
| 22 | `Q2_Plan/w2_07_scene_router_overlay_hardening.md` | SceneRouter overlay contract'ını sertleştirir (P-15) | Guarded |

**Batch 4 exit:** Full suite + scene isolation yeşil. Her Guarded prompt kendi commit'i olsun.

### Batch 5 — Escalate-first (1 prompt)

| # | Prompt dosyası | Ne yapar | Lane |
|---|---|---|---|
| 23 | `Q2_Plan/w3_01_map_runtime_state_extraction.md` | `map_runtime_state.gd`'yi (2397 satır) helper'lara böler, owner korunur, save roundtrip yapılır (E-1) | Escalate-First |

**Batch 5 exit:** Save roundtrip field-for-field eşit, full suite + scene isolation yeşil, `HOTSPOT_FILE_LINE_LIMITS` cap güncellendi. Ayrı commit.

### Batch 6 — Opsiyonel polish (Fast, 2 prompt)

| # | Prompt dosyası | Ne yapar | Lane |
|---|---|---|---|
| 24 | `Q2_Plan/w4_01_accessibility_polish.md` | Compact UI min font/tap target/contrast floor (O-1) | Fast (evidence-gated) |
| 25 | `Q2_Plan/w4_02_tooling_hygiene.md` | `Tools/validate_content.py` içinde dead code temizliği (O-2) | Fast |

**Batch 6 exit:** Q2 kapandı. LONG_TERM_ROADMAP Faz A bitti, Faz B (big-file extraction) açılabilir.

---

## 3. Q2 sonrası — sonraki kuyruklar

Q2 bittikten sonra hangi prompt setinin ne zaman açılacağı `Docs/LONG_TERM_ROADMAP.md` içinde fazlara bağlı:

- **Faz B (Big-File Extraction)**: `CODEX_V2_BIG_FILE_MASTER_PROMPTS.md` dosyasındaki MBC/INV/RSC/MRB kuyruğu açılır. Sırası: her dosya için önce `-0` (report-only plan), sonra `-1`, `-2`, `-3` (varsa `-4`). 4 dosya paralel değil, **sırayla** — MBC bitmeden INV açma.
- **Faz E (Visual/Audio Wave 1)**: `MAP_MASTER_PROMPTS.md` Prompt 7 + 8 devreye girer. `AI_ASSET_ROADMAP_V2.md` rehber olarak kullanılır.
- **Faz C/D/F/G**: Q2_Plan kapsamı dışı, yeni prompt setleri gerekir — o zamana kadar bekle.

---

## 4. Hızlı referans: Codex'e ne vereceksin

Codex oturumu açtığında tek satırlık komut:

```
Oku: Docs/Promts/Q2_Plan/w0_01_recreate_maintainability_audit.md — talimatları aynen uygula, rapor şeklini prompt dosyası söylüyor.
```

Sonraki her prompt için dosya yolunu değiştir, gerisi aynı kalır.

---

## 5. Kesin bilgi / varsayım ayrımı

- **Kesin:** Yukarıdaki 25 Q2_Plan prompt dosyası canlı repo'da mevcut (2026-04-20 tarama). STATUS.md'deki "applied" işaretleri canlı grep'e dayanır.
- **Kesin:** V2_MASTER dosyasındaki Prompt 2.1 (AppBootstrap narrow) ve MAP prompt 2A/2B/3/6 canlı repo'da uygulanmış; STATUS.md bunu doğruladı.
- **Varsayım:** V2_MASTER Prompt 4'ün (reconnect tuning) + Prompt 5'in (placement tuning) ne ölçüde uygulandığı sadece semptomla değerlendirildi; tekrar koşmak ister misin LONG_TERM_ROADMAP Faz E'de karar ver.
- **Varsayım:** Big-file kuyruğundaki satır sayısı tahminleri (MBC 1251, INV 1087, RSC 1016, MRB 1060) 2026-04-20'de doğrulandı; Q2 bittiğinde tekrar ölçüp plan güncellenmeli.

---

## 6. Bu dosyayı nasıl güncel tutarsın

- Her prompt koşulduğunda STATUS.md'deki satırı "applied" yap.
- Batch tamamlandığında bu dosyadaki tabloda o batch'i üstü çizili işaretle veya aşağıdaki "done" bölümüne taşı.
- Q2 bittiğinde bu dosyayı `Docs/Promts/Archive/EXECUTION_ROADMAP_Q2.md` olarak taşı, Q3 için yenisini çıkar.
