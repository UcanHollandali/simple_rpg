# Prompt 07 - Inventory And Equipment Drawer

Use this prompt pack only after Prompt 06 and Prompt 06.5 are closed green.
This is a future-queue pack. Do not start it while Prompt 04, Prompt 05, Prompt 06, or Prompt 06.5 is still open.

Read first:
- `AGENTS.md`
- `Docs/DOC_PRECEDENCE.md`
- `Docs/HANDOFF.md`
- `Docs/ROADMAP.md`
- `Docs/TEST_STRATEGY.md`
- `Docs/UI_INFORMATION_ARCHITECTURE_AUDIT.md`
- `Docs/UI_MICROCOPY_AUDIT.md`

## Goal

Make inventory and equipment presentation context-sensitive instead of permanently open, so map and combat keep their dominant task visible.

This pack keeps one prompt file and splits map/combat behavior internally by parts.

## Direction Statement

- Map board should remain the primary visual focus on map explore.
- Combat action hierarchy should remain the primary visual focus in combat.
- Inventory/equipment should become a drawer or compact summary where appropriate.
- Gameplay rules do not change.
- Inventory ownership does not move.
- The live shared inventory family remains `RunInventoryPanel`; this pack changes presentation hierarchy, not item truth.

## Preferred Owner Surfaces

- `Game/UI/run_inventory_panel.gd` (shared inventory family used by both map and combat)
- `Game/UI/map_explore_scene_ui.gd`
- `Game/UI/combat_scene_ui.gd`
- `Game/UI/inventory_panel_layout.gd` (only for shared density / panel-height adjustments; do not move ownership)
- `Game/UI/inventory_tooltip_controller.gd` (only if drawer collapsed-state changes tooltip eligibility)

Minimal scene edits are allowed only when a presentation hook cannot be kept in the UI helper layer.

## Shared-Owner Risk

`run_inventory_panel.gd` is the same file edited by Part A (map) and Part B (combat). Treat Part A landing as a baseline that Part B must not regress; Part C must explicitly re-verify the Part A map behavior after Part B lands.

## Hard Guardrails

- No save schema change.
- No runtime ownership move.
- No combat item-rule change.
- No equip / unequip semantic change.
- No reorder-rule change.
- No new flow state.
- No map graph-truth change.
- No event or combat logic change.
- No asset hookup or `UiAssetPaths` changes.
- No widening of `/root/AppBootstrap` lookup spread.
- Avoid large `scenes/*.gd` edits unless a small composition-only hook is unavoidable.

## Validation

- `py -3 Tools/validate_architecture_guards.py`
- targeted inventory/UI tests
- scene isolation for affected scenes when wiring changes
- full suite before closing each implementation part
- portrait screenshots plus a short hierarchy report

## Done Criteria

- Map no longer keeps the full inventory/equipment surface permanently open by default.
- Combat no longer keeps a full backpack-style panel open by default.
- Map and combat both remain readable and interactive on portrait targets.
- Existing item interactions keep working in their allowed contexts.
- No gameplay truth moved into UI.

## Copy/Paste Parts

### Part A - Map Inventory Drawer

```text
Apply only Prompt 07 Part A.

Scope:
- Make map inventory/equipment presentation collapsed by default.
- Keep map board as the dominant task surface.
- Use the existing RunInventoryPanel family rather than introducing a second inventory owner.
- Preferred file scope:
  - Game/UI/run_inventory_panel.gd
  - Game/UI/map_explore_scene_ui.gd
- Minimal scene composition hook only if unavoidable.

Target behavior:
- default map presentation shows a compact inventory/equipment handle or summary
- expanded state reveals equipment + backpack rows
- collapse/expand is presentation-only
- existing map-mode interactions stay intact when expanded
- collapsed-state interaction model is explicit: define whether (a) any interaction requires a one-tap expand first, or (b) a narrow consumable / quick-use surface remains reachable from the collapsed handle. Pick one, implement only that one, and document the choice in the report.

Do not:
- change item use/equip/reorder rules
- move inventory truth into UI
- change save behavior
- touch combat presentation in this part
- change asset hookups

Validation:
- validate_architecture_guards
- targeted inventory/map UI tests
- map scene isolation if scene wiring changed
- full suite before closing
- portrait screenshots before/after plus short hierarchy report

Report:
- files changed
- before/after line counts
- interaction states kept intact
- screenshot paths
- explicit confirmation that gameplay rules did not change
```

### Part B - Combat Compact Inventory

```text
Apply only Prompt 07 Part B.

Scope:
- Make combat inventory presentation compact and consumable-first.
- Keep equipment as a compact summary when locked during combat.
- Preferred file scope:
  - Game/UI/run_inventory_panel.gd
  - Game/UI/combat_scene_ui.gd
- Minimal scene composition hook only if unavoidable.

Target behavior:
- compact equipment summary instead of large always-open equipment cards where safe
- combat inventory emphasizes usable consumables first
- non-combat inventory clutter is reduced
- locked-state messaging remains clear

Do not:
- change combat inventory legality
- allow new combat-time gear swaps
- change combat math
- change item effect logic
- touch map drawer behavior in this part except shared helper adjustments required for safety

Validation:
- validate_architecture_guards
- targeted combat/inventory UI tests
- combat scene isolation if scene wiring changed
- full suite before closing
- portrait screenshots before/after plus short hierarchy report

Report:
- files changed
- before/after line counts
- screenshot paths
- what became compact vs what stayed visible
- explicit confirmation that combat rules did not change
- explicit confirmation that Part A's map collapsed-drawer behavior still passes after the shared-owner edits in `run_inventory_panel.gd`
```

### Part C - Screenshot Review And Interaction Check

```text
Apply only Prompt 07 Part C.

Scope:
- Capture portrait screenshots for map and combat after Parts A-B.
- Verify:
  1. map board is more dominant
  2. combat action area is more dominant
  3. inventory/equipment remains discoverable
  4. locked / usable states stay understandable
  5. no interaction regression appears in the shared inventory family
  6. Part B landed after Part A: explicitly re-verify that Part A map drawer behavior (collapsed-by-default, chosen collapsed-state interaction model, expanded full-row layout) is still intact after the shared-owner edits in the same `run_inventory_panel.gd` file
  7. equipment row still surfaces all four slots (`right_hand`, `left_hand`, `armor`, `belt`) and the dual-purpose `left_hand` (`shield` vs `weapon`) signal stays distinguishable

If a checkpoint fails:
- open a narrow follow-up tuning pass inside the same UI owner scope
- do not widen into gameplay logic

Validation:
- validate_architecture_guards if any code changed
- relevant targeted UI tests if any code changed
- map/combat scene isolation
- full suite before closing if any code changed

Report:
- captured files
- pass/fail per checkpoint
- any follow-up tuning
- explicit confirmation that scope stayed presentation-only
```

### Part D - Closeout And Handoff Refresh

```text
Apply only Prompt 07 Part D.

Scope:
- Update Docs/HANDOFF.md and Docs/ROADMAP.md so Prompt 07 is recorded and Prompt 08 becomes next.
- Record the new inventory/equipment presentation direction:
  - map = collapsed drawer / contextual expand
  - combat = compact summary + consumable-first surface

Do not:
- rewrite authority docs
- claim gameplay-rule changes
- mention asset hookup changes

Validation:
- markdown/internal link sanity
- validate_architecture_guards

Report:
- files changed
- final before/after hierarchy summary
- any remaining open UI risk
```
