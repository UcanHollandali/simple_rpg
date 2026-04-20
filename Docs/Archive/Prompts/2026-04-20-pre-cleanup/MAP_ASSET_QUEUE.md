# MAP ASSET QUEUE — Q2 sonrası, asset üretimi başladığında

Bu dosya harita overhaul'unun kalan iki adımını tutar. **Şu an çalıştırma** — önce Q2 (`Q2_PLAYBOOK.md`) biter, asset üretimi (`AI_ASSET_GUIDE.md`) başlar, sonra bu iki prompt sırayla gelir.

Ne zaman açılır: `Docs/LONG_TERM_ROADMAP.md` Faz E (Visual/Audio Wave 1).

## Durum — canlı repo 2026-04-20

- Prompt 1 (redesign + theming audit): report-only, tek sefer. Opsiyonel; atlanabilir.
- Prompt 2A (display-name helper): **UYGULANDI** — `Game/UI/map_display_name_helper.gd` mevcut.
- Prompt 2B (presenter wiring): **UYGULANDI**.
- Prompt 3 (topology refactor): **UYGULANDI** — `map_runtime_graph_codec.gd` mevcut.
- Prompt 4 (reconnect tuning): kısmen; asset üretimi bitince gözden geçir.
- Prompt 5 (placement tuning): kısmen; asset üretimi bitince gözden geçir.
- Prompt 6 (composer path-family differentiation): **UYGULANDI** — `PATH_FAMILY_GENTLE_CURVE`, `PATH_FAMILY_SHORT_STRAIGHT` composer'da canlı.
- Prompt 7 (asset hook wiring): **BEKLEMEDE** — asset dosyaları hazır olduğunda koşulacak.
- Prompt 8 (variation verification + residue cleanup): **BEKLEMEDE** — Prompt 7'den sonra.

---

## Prompt 7 — Asset Hook Wiring

Her `<FILENAME>` yerine gerçek export edilmiş dosya adını yaz. Büyük batch varsa Prompt 7'yi family'lere göre küçük gruplara böl.

```text
Asset hook wiring step for simple_rpg's map pass. Single code-touching step.

Read first:
- AGENTS.md
- Docs/DOC_PRECEDENCE.md
- Docs/HANDOFF.md
- Docs/MAP_CONTRACT.md
- Docs/SOURCE_OF_TRUTH.md
- Docs/ASSET_PIPELINE.md
- Docs/ASSET_LICENSE_POLICY.md

Approved asset filenames:
- <FILENAME e.g. Assets/UI/Map/Ground/ui_map_v2_ground_forest_floor_a.png>
- <FILENAME e.g. Assets/UI/Map/Props/ui_map_v2_prop_root_cluster_a.png>
- <FILENAME e.g. Assets/UI/Map/Landmarks/ui_map_v2_landmark_waystone_a.png>

Task:
1. Create any missing runtime subfolders under `Assets/UI/Map` needed by the filenames above.
2. Wire each approved filename into the appropriate runtime-facing map asset hook.
3. Verify the board renders with the new ground, prop, and landmark families.
4. Update or add manifest rows in `AssetManifest/asset_manifest.csv` with correct provenance.

Hard rules:
- no asset generation in this chat
- no save-shape change
- no new owner surface
- no extraction
- no change to MapRuntimeState ownership
- no change to stable family IDs

Validation:
- py -3 Tools/validate_architecture_guards.py
- py -3 Tools/validate_content.py
- py -3 Tools/validate_assets.py
- powershell -NoProfile -ExecutionPolicy Bypass -File Tools/run_godot_full_suite.ps1
- powershell -NoProfile -ExecutionPolicy Bypass -File Tools/run_godot_scene_isolation.ps1 -ScenePath scenes/map_explore.tscn

Final response format:
- Files changed
- New subfolders created
- Manifest rows added or changed
- Validation results
- Whether the board reads as ground + props + landmarks together
- Safe to continue to Prompt 8: yes/no
```

---

## Prompt 8 — Variation Verification + Residue Cleanup

```text
Closeout step for simple_rpg's map pass. Single code-touching step.

Read first:
- AGENTS.md
- Docs/DOC_PRECEDENCE.md
- Docs/HANDOFF.md
- Docs/MAP_CONTRACT.md
- Docs/SOURCE_OF_TRUTH.md

Task:
1. Verify per-run visual variation across 3 different seeds. If any seed still produces a flat same-looking board, report it and stop.
2. Clean residue from the redesign, theming, and asset-hook passes: dead code, unused constants, obsolete comments.
3. Sync truthful docs only if needed: `HANDOFF.md` and `MAP_CONTRACT.md` if topology or counts actually changed.

Do NOT start extraction in this chat.

Hard rules:
- no save-shape change
- no owner move
- no new autoload
- doc edits are truthful-only

Validation:
- py -3 Tools/validate_architecture_guards.py
- py -3 Tools/validate_content.py
- py -3 Tools/validate_assets.py
- powershell -NoProfile -ExecutionPolicy Bypass -File Tools/run_godot_full_suite.ps1

Final response format:
- Per-seed variation findings
- Residue fixes
- Doc edits
- Validation results
- Whether extraction is still worth running now
```
