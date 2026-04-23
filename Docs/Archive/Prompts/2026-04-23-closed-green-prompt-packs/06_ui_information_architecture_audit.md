# Prompt 06 - UI Information Architecture Audit

Use this prompt pack only after Prompt 04 and Prompt 05 are closed green.
This is a future-queue pack. Do not start it while Prompt 04 or Prompt 05 is still open.

Read first:
- `AGENTS.md`
- `Docs/DOC_PRECEDENCE.md`
- `Docs/HANDOFF.md`
- `Docs/ROADMAP.md`
- `Docs/TEST_STRATEGY.md`
- `Docs/ASSET_PIPELINE.md`
- `Docs/VISUAL_AUDIO_STYLE_GUIDE.md`

Optional reference (only if a finding leans on the underlying contract; do not let these widen this pack into a map/asset scope):
- `Docs/MAP_CONTRACT.md`
- `Docs/COMBAT_RULE_CONTRACT.md`

## Goal

Audit the current player-facing UI information architecture across map explore, event modal, combat, equipment, and backpack surfaces.

The core question is:

Does the player see the right existing gameplay state at the right time to make the next decision?

This is not a theme-refactor pass.
This is not a gameplay-logic pass.
This is not an asset pass.

The output is a reference-only planning document at `Docs/UI_INFORMATION_ARCHITECTURE_AUDIT.md` plus a concrete next-step queue for Prompt 06.5-12.5.

## Direction Statement

- One screen, one dominant task.
- Map explore dominant task: choose a route.
- Event modal dominant task: compare choices.
- Combat dominant task: choose an action.
- Inventory/equipment dominant task: equip, use, or inspect items.
- Gameplay state should be visible when it affects the current decision.
- The first UI pass must surface existing truth better; it must not create new truth.
- Code-first terrain presentation remains the live map direction.
- Generated terrain asset hookup remains blocked.
- Semantic icon / prop / item / portrait work is later and is not part of this pack.

## Existing-Truth Rule

Do not add new gameplay prediction logic.

Do not introduce new combat math preview systems.

Do not display values such as:
- exact post-action damage
- exact mitigation forecasts
- recommendation systems like `recommended defend`
- exact post-action state deltas

unless that value already exists as reliable current runtime truth in the live combat / intent / item surfaces.

If a desired UI value would require new gameplay calculation, mark it as:

`NEEDS_FUTURE_LOGIC_SUPPORT`

and do not implement it in this pack.

Use audit phrasing such as:
- `Is the current action effect, as already represented by existing runtime truth, visible enough?`

## Hard Guardrails

- No save schema change.
- No runtime state schema change.
- No combat math change.
- No item effect change.
- No event outcome logic change.
- No route logic change.
- No map graph-truth change.
- No visibility-filtering semantic change.
- No progression-logic change.
- No new command family or event family.
- No scene/core ownership move.
- No asset approval, move, rename, convert, import, or hookup.
- No `UiAssetPaths` constant changes.
- No generated terrain asset policy change.

Prompt 06 may create or update documentation only.
If inspection reveals an implementation need, report it as a recommendation for Prompt 06.5-12.5. Do not implement it here.

## Validation

- `py -3 Tools/validate_architecture_guards.py`
- markdown/internal link sanity for any touched docs
- existing screenshot capture tooling if available and safe

If only docs are changed, full Godot suite is not required. Report whether it was skipped.

## Done Criteria

- `Docs/UI_INFORMATION_ARCHITECTURE_AUDIT.md` exists and is clearly marked reference-only.
- The audit includes screen-dominant-task analysis, state visibility matrix, top decision-visibility problems, and top readability problems.
- The audit explicitly separates:
  - always visible
  - context visible
  - on demand
  - debug only
  - not currently visible but needed
  - visible but unreadable
  - visible but wrong context
  - needs future logic support
- Prompt 06.5 and Prompt 07 hand-off scope is recommended from repo truth rather than guessed.
- No gameplay logic changed.
- No asset was generated, approved, moved, renamed, imported, converted, or hooked.

## Copy/Paste Parts

### Part A - Screenshot And State Audit

```text
Apply only Prompt 06 Part A.

Scope:
- Audit current player-facing UI information architecture across:
  - map explore
  - event modal
  - combat
  - equipment
  - backpack
- Capture or inspect enough current states to evaluate decision visibility and portrait readability.
- Create Docs/UI_INFORMATION_ARCHITECTURE_AUDIT.md as a reference-only planning document.

Required screen/state coverage:

Map Explore
- stage start
- mid progression
- late progression if available
- selected node if supported
- reachable node visible
- locked / unavailable route visible if available
- low HP or low hunger state if easy to capture safely
- hunger threshold warning toast active (capture or note that it is currently shared between map and combat)

Event Modal
- rest / campfire event
- reward event if available
- event with at least one choice
- event with unavailable / disabled choice if available
- event return / back option
- event modal rendered as overlay above MapExplore (note overlay vs standalone framing)

Combat
- combat start
- after player takes damage
- enemy intent visible
- player has guard if available
- guard decay carryover into next turn visible (signed gain / absorb / decay readouts)
- usable consumable available
- no usable consumable available if available
- equipment locked state
- left-hand slot showing both `shield` and `weapon` variants (note that the same slot is dual-purpose)
- combat feedback lane during a same-target follow-up hit (no overwrite)

Inventory / Equipment
- empty backpack
- partially filled backpack
- full backpack if easy to capture safely
- equipped weapon
- open equipment slot
- item usable
- item not usable in current context
- equipment row showing all four slots: `right_hand`, `left_hand`, `armor`, `belt`
- backpack-utility belt that exposes capacity bonus

Run-Status Shells (lighter coverage, hierarchy/readability only - no decision-visibility audit needed)
- StageTransition (stage number, personality, objective line)
- RunEnd (final run summary)

The audit document must include:
1. Scope And Current Direction
2. Screen Dominant Task Matrix
3. Global State Visibility Matrix
4. Map Explore Findings
5. Event Modal Findings (note: event modal is an overlay over MapExplore via `OverlayFlowContract` / `MapOverlayContract`)
6. Combat Screen Findings (include guard delta readability + dual-purpose `left_hand` slot clarity)
7. Inventory And Equipment Findings (include all four equipment slots + belt capacity bonus)
8. Run-Status Shell Findings (StageTransition + RunEnd hierarchy/readability only)
9. Font And Icon Readability Findings (decorative-font usage inventory; this list feeds Prompt 10)
10. Recommended Prompt 06.5-12.5 Plan
11. Explicit Non-Goals

For the Global State Visibility Matrix, include at least:
- HP / max HP
- Hunger / max hunger
- Hunger threshold warning toast (timing + dismissal behavior; same toast used on map and combat)
- Gold
- Durability
- XP
- Level
- Guard (current value)
- Guard delta readouts (signed gain / absorb / decay carryover)
- Armor
- Equipped weapon
- Equipment slot identity (`right_hand`, `left_hand`, `armor`, `belt`) and the dual-purpose `left_hand` (`shield` vs `weapon`) signal
- Backpack capacity (and any belt-driven capacity bonus)
- Current stage
- Stage personality (`pilgrim` / `frontier` / `trade`) and stage objective line (visible via StageTransition)
- Open routes
- Seen nodes
- Cleared nodes
- Current node
- Reachable nodes
- Locked route reason
- Node type
- Node risk / reward
- Event title
- Event choice cost
- Event choice reward
- Event disabled reason
- Enemy HP
- Enemy armor
- Enemy intent
- Combat action availability
- Combat usable items
- Combat feedback lane (per-action / per-target feedback ordering)
- Last combat result
- Full combat log

Classify each field as one of:
- ALWAYS_VISIBLE
- CONTEXT_VISIBLE
- ON_DEMAND
- DEBUG_ONLY
- NOT_CURRENTLY_VISIBLE_BUT_NEEDED
- VISIBLE_BUT_UNREADABLE
- VISIBLE_BUT_WRONG_CONTEXT
- NEEDS_FUTURE_LOGIC_SUPPORT

Do not:
- implement the UI overhaul
- change gameplay logic
- change save schema
- change combat math
- change route logic
- approve or hook assets
- add new prediction systems

Validation:
- validate_architecture_guards
- markdown/internal link sanity on the new audit doc
- capture tooling if available and safe

Report:
- files created/changed
- screenshot paths captured
- screens/states audited
- top 10 decision-visibility problems
- top 5 readability problems
- recommended Prompt 06.5 / Prompt 07 hand-off scope
- explicit confirmation that no gameplay logic changed
- explicit confirmation that no asset was generated, approved, moved, renamed, imported, converted, or hooked
```

### Part B - Audit Closeout

```text
Apply only Prompt 06 Part B.

Scope:
- Refine Docs/UI_INFORMATION_ARCHITECTURE_AUDIT.md from Part A into its final reference-only form.
- Update Docs/HANDOFF.md and Docs/ROADMAP.md so Prompt 06 is recorded and Prompt 06.5 becomes the next active future UI step.
- Keep Prompt 04 / Prompt 05 history intact.

Do not:
- change any gameplay or runtime owner meaning
- reopen earlier prompt packs
- turn Prompt 06 into an implementation pass
- add any asset hookup wording

Validation:
- markdown/internal link sanity
- validate_architecture_guards

Report:
- files changed
- final top findings
- final Prompt 06.5 / Prompt 07 recommendation
- exact handoff / roadmap wording updated
```
