# MAP OVERHAUL EXECUTION PLAN

Purpose: single entry point that sequences the map redesign, node theming, asset production, and later extraction work into one executable order.
Audience: the user driving Codex and local asset tools day-to-day.
Scope: only the files listed below. This file does not replace any authority doc.

Created: 2026-04-18.

Practical note:
- if you only want the short "what do I run tonight?" version, start with `Docs/Promts/MAP_OVERNIGHT_QUEUE.md`

---

## 1. Files This Plan Orchestrates

| # | File | Type | Role in this overhaul |
|---|---|---|---|
| 1 | `Docs/Promts/MAP_REDESIGN_CODEX_QUEUE.md` | ordered Codex prompt chain | topology, placement, road-family, and asset-hook redesign |
| 2 | `Docs/Promts/MAP_NODE_THEMING_CODEX_QUEUE.md` | ordered Codex prompt chain | player-facing themed display names |
| 3 | `Docs/Promts/AI_ASSET_ROADMAP_V2.md` | production roadmap | local ComfyUI / Krita / Kenney workflow on the user's 5080 |
| 4 | `Docs/Promts/MAP_RUNTIME_STATE_EXTRACTION_PLAN.md` | technical refactor plan | split `map_runtime_state.gd` only after redesign closes |

Authority order if any of the four files disagree:

1. `Docs/MAP_CONTRACT.md`
2. `Docs/SOURCE_OF_TRUTH.md`
3. `Docs/CONTENT_ARCHITECTURE_SPEC.md`
4. `Docs/VISUAL_AUDIO_STYLE_GUIDE.md`
5. `Docs/Promts/MAP_REDESIGN_CODEX_QUEUE.md`
6. `Docs/Promts/MAP_NODE_THEMING_CODEX_QUEUE.md`
7. `Docs/Promts/AI_ASSET_ROADMAP_V2.md`
8. `Docs/Promts/MAP_RUNTIME_STATE_EXTRACTION_PLAN.md`
9. this file

---

## 2. High-Level Sequencing Rule (Certain)

- Redesign queue changes topology generation and composer wiring. It touches `map_runtime_state.gd` hot regions.
- Theming queue is presentation-only. It should stay in `Game/UI/`.
- Asset roadmap is mostly out-of-engine work plus runtime file handoff after hooks exist.
- Extraction plan splits `map_runtime_state.gd`, so it must run last.

Therefore:

1. Redesign Prompt 1 and Theming Prompt 1 can run immediately. Certain.
2. Theming Prompt 2 should land before serious landmark or node-marker concept work, but only after the user has approved Q1 / Q2 / Q3 or explicitly accepted the recommended default. Certain.
3. Asset install, Kenney search, and ground / prop smoke tests can run in parallel with the audit prompts. Certain.
4. Ground / prop production should sync to redesign Prompt 6 because that prompt wires the new asset hooks. Certain.
5. Landmark concept work should wait for both:
   - redesign Prompt 6 hooks
   - theming Prompt 2 approved display-name language
6. Extraction plan must run only after the redesign queue closes. Certain.

---

## 3. Dependency Graph (Short Form)

```text
[Redesign P1 audit] ----------------------------+
                                               |
                                               v
[Redesign P2-P6 runtime/composer work] ----> [asset hooks ready] ----> [ground/prop production]
                                               |
                                               +---------------------> [landmark production]

[Theming P1 audit] -> [Theming P2 helper] ----+
                                               |
                                               +---------------------> [landmark / marker concept language locked]

[Theming P3-P7 wiring + review + docs] --------+

[Redesign P7-P8 verification + cleanup] ------> [Extraction plan waves, if still needed]
```

Notes:

- Redesign P1 is audit-only.
- Theming P1 is audit-only.
- Asset Day 1 is install / smoke-only.
- Landmark work is the one asset family that depends on early naming decisions.

---

## 4. Parallelism Budget (Real-World Constraints)

Certain constraints from the user:

- ChatGPT Pro `$100` / month with Codex CLI - heavy code work goes here.
- Claude `$20` / month - docs, prompt drafting, short planning.
- One person driving, not a team.

Assumption:
- a realistic cadence is `1-2` Codex prompts per day plus `1-2` hours of asset work

Rule of thumb:

- one code-touching Codex prompt at a time in the working tree
- between any two code-touching prompts run:
  - `py -3 Tools/validate_content.py`
  - `py -3 Tools/validate_assets.py`
  - `powershell -NoProfile -ExecutionPolicy Bypass -File Tools/run_godot_full_suite.ps1`
- asset work in `SourceArt/` can continue without blocking code as long as it does not depend on unwired hooks

---

## 5. Recommended Execution Order

### Phase 1 - Audit and decision lock

Run these first:
- Redesign Prompt 1
- Theming Prompt 1
- Asset Day 1 install / smoke

Output of this phase:
- confirm current map topology baseline
- confirm current family-name leak surfaces
- surface Q1 / Q2 / Q3 early before landmark concepts

### Phase 2 - Core map direction

Run in order:
- Redesign Prompt 2
- Redesign Prompt 3
- Redesign Prompt 4
- Redesign Prompt 5

Optional parallel low-risk work:
- prepare naming options after Theming Prompt 1 is green, but do not start Theming Prompt 2 before approval

Why:
- topology and placement are the risky parts
- helper-only theming can proceed without touching runtime truth once the approval gate is cleared

### Phase 3 - Naming lock + map UI wiring

Run in order:
- Theming Prompt 2
- Theming Prompt 3
- Theming Prompt 4
- Theming Prompt 5

Why:
- the user wants more thematic map language
- the approved naming language should be locked before later landmark / marker polish

### Phase 4 - Asset hook handoff

Run:
- Redesign Prompt 6

After Prompt 6:
- start real ground / prop production
- start landmark production only if Theming Prompt 2 is already landed with an approved naming set

### Phase 5 - Verification and cleanup

Run:
- Redesign Prompt 7
- Redesign Prompt 8
- Theming Prompt 6
- Theming Prompt 7

Output of this phase:
- visual variation confirmed
- themed naming confirmed
- docs synced

### Phase 6 - Extraction only if still worth it

Run `Docs/Promts/MAP_RUNTIME_STATE_EXTRACTION_PLAN.md` only after all redesign prompts are closed and the map still clearly needs file-size reduction.

Do not start high-risk extraction zones automatically.

---

## 6. Seven-Day Shape

### Day 1

- Redesign Prompt 1
- Theming Prompt 1
- install ComfyUI / Krita plugin
- FLUX Schnell smoke render
- Kenney search

### Day 2

- Redesign Prompt 2
- full validation gate
- no second code prompt if Prompt 2 is unstable

### Day 3

- Redesign Prompt 3
- answer Q1 / Q2 / Q3 or accept the recommended default
- Theming Prompt 2
- start ground / prop cleanup if hooks are near-ready

### Day 4

- Redesign Prompt 4
- Theming Prompt 3
- first approved ground / prop export if runtime hooks are ready

### Day 5

- Redesign Prompt 5
- Theming Prompt 4
- portrait review

### Day 6

- Redesign Prompt 6
- Theming Prompt 5
- start landmark batch with approved naming language

### Day 7

- Redesign Prompt 7 and Prompt 8
- Theming Prompt 6 and Prompt 7
- asset review and manifest review
- decide whether extraction is still worth doing

This is a suggested shape, not a contract.

---

## 7. Checkpoint Gates (Between Every Code-Touching Prompt)

Run all of these:

1. `py -3 Tools/validate_content.py`
2. `py -3 Tools/validate_assets.py`
3. `powershell -NoProfile -ExecutionPolicy Bypass -File Tools/run_godot_full_suite.ps1`
4. one manual run to confirm:
   - map renders at portrait resolution
   - center-start shell still reads clearly
   - some nodes have degree `1`, some `2`, some `3`
   - at least one reconnect edge is visible when expected
   - themed labels look correct if the theming queue is already partially wired
5. if any save-touching path changed indirectly, load an earlier save and confirm it still restores

If any step fails, do NOT continue to the next prompt.

---

## 8. Stop-And-Escalate Triggers

Pause and ask if any of the following happens:

- Codex proposes moving map truth out of `MapRuntimeState`
- Codex proposes changing a stable family ID string
- Codex proposes writing display names into save data
- Codex proposes a new autoload
- Codex proposes changing `to_save_dict` / `load_from_save_dict` semantics
- an asset concept tries to bake gameplay truth into reusable environment layers
- the board drifts out of `Dark Forest Wayfinder`
- extraction work is about to touch support revisit, hamlet side-quest runtime, stage key, boss gate, or pending context blocks

---

## 9. Budget Guidance

Assumption:
- the ChatGPT Pro lane can handle the heavier map prompts more comfortably than Claude's lower tier

Suggested routing:

- Redesign Prompts `2`, `4`, `6` -> Codex CLI
- Redesign Prompts `1`, `3`, `5`, `7`, `8` -> Codex CLI
- Theming Prompts `1-7` -> Codex CLI is enough
- Asset generation / cleanup -> local tools, not coding agents
- doc edits and planning -> Claude or Codex, whichever is faster in the moment

The important rule is not "which model" but "one risky code prompt at a time".

---

## 10. What Success Looks Like

Definition of done for this overall pass:

- each run produces a visibly different but readable center-start scatter map
- the board reads closer to the user's reference image in composition and density
- every live node family has a themed player-facing name while stable IDs remain unchanged
- ground / prop / landmark families each have at least one reviewed runtime asset
- docs stay truthful
- no new autoload, no new save field, no new command family was introduced

If these are true, extraction becomes optional rather than mandatory.

---

## 11. What This Plan Deliberately Does NOT Do

- does NOT change combat design
- does NOT touch audio
- does NOT add new node families
- does NOT move map truth ownership out of `MapRuntimeState`
- does NOT auto-schedule high-risk extraction zones
- does NOT require paid cloud image services
- does NOT promise a one-pass exact copy of the reference image

---

## 12. Quick Reference Card

| Phase | Rough duration | Primary file | Main tool |
|---|---|---|---|
| Redesign P1 audit | 1 session | `Docs/Promts/MAP_REDESIGN_CODEX_QUEUE.md` | Codex CLI |
| Theming P1 audit | 1 session | `Docs/Promts/MAP_NODE_THEMING_CODEX_QUEUE.md` | Codex CLI |
| Tool install / smoke | 1 session | `Docs/Promts/AI_ASSET_ROADMAP_V2.md` | local tools |
| Redesign P2-P5 | 3-4 sessions | `Docs/Promts/MAP_REDESIGN_CODEX_QUEUE.md` | Codex CLI |
| Theming P2-P5 | 2-3 sessions | `Docs/Promts/MAP_NODE_THEMING_CODEX_QUEUE.md` | Codex CLI |
| Redesign P6 asset hooks | 1 session | `Docs/Promts/MAP_REDESIGN_CODEX_QUEUE.md` | Codex CLI |
| Ground / prop / landmark batch | 3-5 sessions | `Docs/Promts/AI_ASSET_ROADMAP_V2.md` | local tools |
| Redesign P7-P8 + Theming P6-P7 | 2 sessions | `Docs/Promts/` prompt docs | Codex CLI |
| Extraction review | 1 session | `Docs/Promts/MAP_RUNTIME_STATE_EXTRACTION_PLAN.md` | Codex CLI |

End of execution plan.
