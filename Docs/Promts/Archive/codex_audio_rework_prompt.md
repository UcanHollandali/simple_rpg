This is a standalone prototype audio replacement track.

Do not run this in parallel with the active overhaul queue on the same worktree.
If another large queue is already patching this repo, either:
- wait until that queue finishes, or
- run this pass in a separate branch/worktree

Primary goal:
- replace the current harsh, fatiguing temporary music floor
- make menu/map/overlay music calmer, darker, and more repeat-safe
- make combat music tenser and more epic without becoming shrill
- remove the old temp music set from code, tests, manifest, runtime folders, and source-master folders once replacements are safely wired

User brief:
- current music is too tiz / piercing / annoying
- menu, combat, and map audio all feel bad right now
- this is still temporary prototype audio
- later it can be replaced by real assets
- for now it should feel much more polished and less irritating

Read first for every part:
- `AGENTS.md`
- `Docs/DOC_PRECEDENCE.md`
- `Docs/HANDOFF.md`
- `Docs/VISUAL_AUDIO_STYLE_GUIDE.md`
- `Docs/ASSET_PIPELINE.md`
- `Docs/ASSET_LICENSE_POLICY.md`
- `Docs/TECH_BASELINE.md`
- `Docs/TEST_STRATEGY.md`

Shared runtime surface to inspect before touching any part:
- `AssetManifest/asset_manifest.csv`
- `Assets/Audio/Music/`
- `Assets/Audio/SFX/`
- `SourceArt/Edited/`
- `Game/UI/scene_audio_players.gd`
- `Game/UI/scene_audio_cleanup.gd`
- `Game/UI/audio_preferences.gd`
- `scenes/main_menu.gd`
- `scenes/main.gd`
- `scenes/map_explore.gd`
- `scenes/event.gd`
- `scenes/reward.gd`
- `scenes/support_interaction.gd`
- `scenes/level_up.gd`
- `scenes/stage_transition.gd`
- `scenes/combat.gd`
- `scenes/run_end.gd`
- `Tests/test_phase2_loop.gd`
- `Tests/test_event_node.gd`
- `Tests/test_stage_transition.gd`

Known repo truth to verify before patching:
- `music_ui_hub_loop_temp_01.ogg` is currently reused by:
  - `main_menu`
  - `main`
  - `map_explore`
  - `event`
  - `reward`
  - `support_interaction`
  - `level_up`
  - `stage_transition`
- `music_combat_loop_temp_01.ogg` is currently used by `combat`
- `music_run_end_loop_temp_01.ogg` is currently used by `run_end`
- `Tests/test_phase2_loop.gd` currently asserts old music resource paths directly

Hard rules for the whole track:
- do not change save shape or save schema version
- do not change gameplay mechanics, flow state, or owner boundaries
- do not build a broad new audio architecture
- do not break shared music session behavior in `scene_audio_players.gd`
- do not break music toggle / mute behavior in `audio_preferences.gd`
- do not leave manifest drift, dead runtime files, or dead source-master files behind
- do not use unclear-license or unclear-provenance audio
- do not claim release-readiness; this is still temporary prototype audio
- if this pass cannot safely run because another queue is editing the same repo, stop and say `run in separate worktree`

Sourcing rules:
- follow `Docs/ASSET_PIPELINE.md` and `Docs/ASSET_LICENSE_POLICY.md` exactly
- for temporary music prefer only:
  - `Kenney`
  - `Mixkit`
  - `Pixabay`
- do not use:
  - `OpenGameArt`
  - `Freesound`
  - `Zapsplat`
  - free-plan AI music tools
  - unclear-license or unclear-provenance sources
- if no acceptable safe-first free replacement exists, a very simple repo-authored generated temp loop/cue is allowed only if provenance stays truthful
- if `Docs/TECH_BASELINE.md` disagrees with the final temporary music approach, fix the doc drift in the same patch instead of leaving a contradiction

Global validation baseline:
- `py -3 Tools/validate_assets.py`
- `py -3 Tools/validate_architecture_guards.py`
- `powershell -NoProfile -ExecutionPolicy Bypass -File Tools/run_godot_full_suite.ps1`
- `powershell -NoProfile -ExecutionPolicy Bypass -File Tools/run_godot_smoke.ps1`

Recommended part order:
1. Part 1
2. Part 2
3. Part 3
4. Part 4
5. Part 5

Do not skip directly to cleanup before replacement references are already aligned.

## Part 1 — Audio Surface Audit + Replacement Plan (NO-CODE)

Goal:
- audit the current audio surface completely before any patching
- identify every place where the old temp music set is referenced
- decide the safest replacement shape for non-combat, combat, and run-end

Do not patch in this part.

Required reads:
- all shared runtime surface files listed above

Tasks:
1. List every scene and test that still points at the old temp music paths.
2. List every manifest row tied to the old temp music floor.
3. List every runtime music file and matching source-master file involved.
4. Decide whether the replacement floor should be:
   - one shared non-combat loop + one combat loop + one run-end loop
   - or one shared non-combat loop + one combat loop only
5. Decide whether any current UI SFX are clearly harsh enough to justify replacement in this track.
6. Check whether `Docs/TECH_BASELINE.md` still truthfully matches the intended temporary music sourcing model.
7. State whether this pass can safely run now or should be delayed because another active queue is touching overlapping files.

Report specifically:
1. audio surface inventory
2. old runtime music files
3. old source-master files
4. scene/test references
5. manifest rows
6. proposed replacement floor
7. whether Part 2 can run as-is or should be adjusted

## Part 2 — Music Floor Replacement (MEDIUM RISK)

Goal:
- replace the current unpleasant music floor with calmer, more polished temporary music
- keep non-combat cohesive and low-fatigue
- keep combat more driving and epic without harsh highs

Touched owner layer:
- `Assets/Audio/`
- `SourceArt/Edited/`
- `AssetManifest/`
- scene-local presentation scripts
- tests that assert music paths

Authority docs:
- `Docs/VISUAL_AUDIO_STYLE_GUIDE.md`
- `Docs/ASSET_PIPELINE.md`
- `Docs/ASSET_LICENSE_POLICY.md`
- `Docs/TECH_BASELINE.md`

Impact:
- `runtime truth`: no gameplay truth change
- `save shape`: none
- `asset provenance`: yes
- `public surface`: scene-local asset paths and tests

Before patching:
- run the global validation baseline
- state the minimum validation set again

Tasks:
1. Introduce the new temporary music floor:
   - non-combat bed
   - combat bed
   - optional run-end bed if justified
2. Prefer stable cleaner runtime filenames rather than keeping `_temp_01` names if full alignment is done in the same pass.
3. Update all scene script music constants to the new runtime paths.
4. Update tests that assert the old music paths directly.
5. Update manifest rows truthfully:
   - source origin
   - license
   - commercial status
   - replace-before-release
   - master path
   - runtime path
6. If needed, update `Docs/TECH_BASELINE.md` or another doc for truth alignment.

Do not delete the old files yet if any code/test/manifest reference still points at them.

After patching:
- run the global validation baseline
- also run:
  - `powershell -NoProfile -ExecutionPolicy Bypass -File Tools/run_godot_scene_isolation.ps1 -ScenePath scenes/main_menu.tscn`
  - `powershell -NoProfile -ExecutionPolicy Bypass -File Tools/run_godot_scene_isolation.ps1 -ScenePath scenes/map_explore.tscn`
  - `powershell -NoProfile -ExecutionPolicy Bypass -File Tools/run_godot_scene_isolation.ps1 -ScenePath scenes/combat.tscn`
  - `powershell -NoProfile -ExecutionPolicy Bypass -File Tools/run_godot_scene_isolation.ps1 -ScenePath scenes/run_end.tscn`

Report specifically:
1. which replacement tracks were introduced
2. which scenes changed to which tracks
3. which tests changed
4. which manifest rows changed
5. whether old files are now fully unreferenced

## Part 3 — Optional UI / SFX Harshness Cleanup (LOW-MEDIUM RISK)

Run this only if Part 1 found that some current SFX are clearly brittle, piercing, or unpleasant enough to justify replacement now.

Goal:
- replace only the worst offending temp UI/SFX cues
- keep the scope narrow

Do not expand into a full audio redesign.

Likely candidates to audit:
- `sfx_ui_confirm_01`
- `sfx_ui_cancel_01`
- `sfx_panel_open_01`
- `sfx_panel_close_01`
- `sfx_node_select_01`

Tasks:
1. Decide which cues are genuinely bad enough to replace now.
2. Introduce calmer temporary replacements only for those cues.
3. Update scene-local references and manifest rows.
4. Keep `AudioPreferences` and shared music behavior untouched.

Validation after patching:
- `py -3 Tools/validate_assets.py`
- `py -3 Tools/validate_architecture_guards.py`
- `powershell -NoProfile -ExecutionPolicy Bypass -File Tools/run_godot_full_suite.ps1`
- `powershell -NoProfile -ExecutionPolicy Bypass -File Tools/run_godot_smoke.ps1`

Report specifically:
1. which SFX were replaced
2. which SFX were intentionally left alone
3. whether this part improved polish without widening scope

## Part 4 — Old Audio Reference Cleanup + File Deletion (MEDIUM RISK)

Goal:
- remove the old temp music set completely once replacements are already live
- leave no stale code, test, manifest, runtime, or source-master references behind

Cleanup rule:
- the user explicitly wants the old temp music removed from engine references, code, and folders
- do not keep obsolete `_temp_01` music files alive if the repo no longer points at them
- do not delete anything until all references are clean

Tasks:
1. Verify all old music references are gone from:
   - scene scripts
   - tests
   - manifest rows
   - docs if any referenced exact old names
2. Delete obsolete runtime music files from `Assets/Audio/Music/`.
3. Delete obsolete source-master files from `SourceArt/Edited/` if they no longer serve as active provenance.
4. Keep `.gitkeep` files and any still-live SFX untouched.
5. Re-run a repo-wide search for old temp music names and continue until no live reference remains.

Validation after patching:
- `py -3 Tools/validate_assets.py`
- `py -3 Tools/validate_architecture_guards.py`
- `powershell -NoProfile -ExecutionPolicy Bypass -File Tools/run_godot_full_suite.ps1`
- `powershell -NoProfile -ExecutionPolicy Bypass -File Tools/run_godot_smoke.ps1`
- `powershell -NoProfile -ExecutionPolicy Bypass -File Tools/run_godot_scene_isolation.ps1 -ScenePath scenes/map_explore.tscn`
- `powershell -NoProfile -ExecutionPolicy Bypass -File Tools/run_godot_scene_isolation.ps1 -ScenePath scenes/combat.tscn`

Report specifically:
1. which old runtime files were deleted
2. which old source-master files were deleted
3. whether any old temp audio reference survived
4. whether Part 5 can run as-is

## Part 5 — Final Audio Audit + Truth Alignment (LOW RISK)

Goal:
- verify the temporary audio floor is cleaner, calmer, and repo-truthful
- close the pass only when no safe cleanup remains

Tasks:
1. Re-audit the entire audio surface after the replacements and cleanup.
2. Confirm that shared music routing still works and mute toggle behavior still works.
3. Confirm manifest/runtime/source-master alignment is truthful.
4. Confirm no obsolete temp music reference remains.
5. Note anything still temporary and still needing later replacement.
6. Note what still needs manual Godot listening/playtest verification.

Final report format:
1. Executive Verdict
2. Baseline Validation
3. Audio Surface Audit
4. Findings Before Patch
5. Applied Audio Replacements
6. Reference Cleanup
7. Manifest And Provenance Updates
8. Validation Results
9. Remaining Temporary Audio Risks
10. Intentionally Untouched Areas
11. Escalation Items
12. Final Verdict

Before ending, give a 5-bullet handoff:
- what audio was replaced
- what old audio was removed
- what was intentionally untouched
- what remains risky or temporary
- whether a later audio polish pass should run as-is or be adjusted
