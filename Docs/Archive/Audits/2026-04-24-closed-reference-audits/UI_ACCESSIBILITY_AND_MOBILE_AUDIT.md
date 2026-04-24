# UI Accessibility And Mobile Audit

Reference-only audit document for Prompt 12.5.

## 1. Status

- Date: 2026-04-22
- Output type: reference-only
- Part A scope in this document: accessibility minimum audit only
- Part B scope in this document: mobile interaction audit
- Part C scope in this document: consolidated prioritized implementation queue
- Code changed in this prompt pack so far: none

## 2. Scope And Evidence Basis

This document audits the live UI against these accessibility minimums:

1. text contrast
2. icon contrast
3. color-only signaling
4. text scaling
5. motion / flash safety
6. focus / selection visibility
7. portrait safe-area handling

Evidence basis used in Part A:

- screenshot review already captured in prior closed-green passes:
  - `export/portrait_review/prompt07_part_c_review/map_explore_1080x1920.png`
  - `export/portrait_review/prompt08_part_c_review/event_live_1080x1920.png`
  - `export/portrait_review/prompt09_part_c_review/combat_1080x1920.png`
  - `export/portrait_review/prompt10_part_b_review/main_menu_1080x1920.png`
  - `export/portrait_review/prompt10_part_b_review/map_explore_1080x1920.png`
  - `export/portrait_review/prompt10_part_b_review/combat_1080x1920.png`
  - `export/portrait_review/prompt10_part_b_review/run_end_1080x1920.png`
  - `export/portrait_review/prompt10_5_part_b/first_low_hunger_warning_trigger_1080x1920.png`
  - `export/portrait_review/prompt10_5_part_c/first_key_required_route_trigger_1080x1920.png`
- repo-truth owner inspection:
  - `Game/UI/temp_screen_theme.gd`
  - `Game/UI/scene_layout_helper.gd`
  - `Game/UI/map_route_binding.gd`
  - `Game/UI/combat_feedback_lane.gd`
  - `Game/UI/action_hint_controller.gd`
  - `Game/UI/first_run_hint_controller.gd`
  - `Game/UI/run_inventory_panel.gd`
  - `Game/UI/map_explore_scene_ui.gd`
- existing reference audits:
  - `Docs/UI_INFORMATION_ARCHITECTURE_AUDIT.md`
  - `Docs/UI_MICROCOPY_AUDIT.md`

Confidence rule used in Part A:

- `Confirmed`: directly grounded in current screenshots, checked-in owner code, or current tests
- `Inference`: a UX/accessibility conclusion drawn from confirmed repo truth

## 3. Accessibility Minimum Matrix

| minimum | current state | evidence | severity if not PASS | proposed narrow follow-up scope |
|---|---|---|---|---|
| 1. Text contrast: body text and important values readable on actual backgrounds at portrait scale | `PASS` | `Confirmed`: Prompt 10 review already closed green for smallest text, disabled text, and gameplay-value emphasis across `main_menu`, `map_explore`, `combat`, and `run_end`; shared readable floors live in `Game/UI/temp_screen_theme.gd` and `Game/UI/scene_layout_helper.gd`. | N/A | none in Part A |
| 2. Icon contrast: meaningful icons readable on actual backgrounds | `WEAK` | `Confirmed`: shell/status/inventory icons passed Prompt 10 readability review; `Inference`: map node icons remain the weakest lane because they sit small on mixed board backgrounds and `Docs/UI_INFORMATION_ARCHITECTURE_AUDIT.md` already marked map node type as `VISIBLE_BUT_UNREADABLE`. | `MEDIUM` | `Game/UI/map_route_binding.gd` |
| 3. Color-only signaling: meaning must not rely on color alone | `WEAK` | `Confirmed`: selected and locked map nodes do gain non-color cues through `SelectionRing` and chip text in `Game/UI/map_route_binding.gd`; `Confirmed`: that chip is not persistent for ordinary open-node family identity, so unselected map-node meaning still leans on icon+tint literacy more than a stable second cue. | `MEDIUM` | `Game/UI/map_route_binding.gd` |
| 4. Text scaling: player-controllable text scale if practical | `FAIL` | `Confirmed`: repo-wide search found no player-facing text-scale setting, no shared text-scale multiplier, and no accessibility setting lane; current shared theme only clamps minimum readable sizes. | `HIGH` | `Game/UI/temp_screen_theme.gd` |
| 5. Motion / flash: no UI motion or flash should exceed safe thresholds for photosensitive players | `WEAK` | `Confirmed`: `Game/UI/combat_feedback_lane.gd` uses local hit flashes, pulses, floating text, and intent reveal tweens; `Game/UI/action_hint_controller.gd` and `Game/UI/first_run_hint_controller.gd` also animate panel entry. `Inference`: these do not read as screen-wide strobe behavior today, but there is no explicit reduced-motion / reduced-flash guard. | `MEDIUM` | `Game/UI/combat_feedback_lane.gd` |
| 6. Focus / selection visibility: selected target visible without color alone | `PASS` | `Confirmed`: map route selection uses a ring plus selected pill; shared buttons receive explicit focus border/shadow styling in `Game/UI/temp_screen_theme.gd`; safe menu focus is actively restored in `Game/UI/safe_menu_overlay.gd`. | N/A | none in Part A |
| 7. Portrait safe-area: nothing critical sits inside device cutouts at standard portrait targets | `WEAK` | `Confirmed`: major shells go through `Game/UI/scene_layout_helper.gd` and `apply_portrait_safe_margins(...)` with explicit side/top/bottom margins; `Confirmed`: top-right overlay lanes are weaker because `Game/UI/first_run_hint_controller.gd` clamps only to a fixed `16px` margin and is not cutout-aware. | `MEDIUM` | `Game/UI/scene_layout_helper.gd` |

## 4. Gap Counts By Severity

- `BLOCKER`: 0
- `HIGH`: 1
- `MEDIUM`: 4
- `LOW`: 0

## 5. Top 5 Most Impactful Accessibility Gaps

1. No player-controllable text scaling exists today.
2. Map node icon readability is still the weakest meaningful-icon lane on portrait backgrounds.
3. Unselected map node meaning still leans too heavily on icon+tint literacy instead of a stronger persistent secondary cue.
4. Combat feedback motion is currently restrained, but there is no explicit reduced-motion / reduced-flash guard.
5. Shared shell margins are decent, but top-right hint/overlay lanes are not yet clearly cutout-safe by contract.

## 6. Part A Closeout

Confirmed in this pass:

- body text and important values are currently readable enough to pass the minimum floor
- focus and selection visibility already have real non-color cues in the live shared UI layer
- the largest current accessibility gap is not contrast; it is the absence of player-controllable text scaling

Deferred to later parts of Prompt 12.5:

- accidental-tap / drag / swipe / long-press conflict audit
- final cross-surface prioritized follow-up queue

## 7. Mobile Interaction Evidence Basis

Evidence basis used in Part B:

- screenshot review already captured in prior closed-green passes:
  - `export/portrait_review/prompt07_part_a_after/map_explore_1080x1920.png`
  - `export/portrait_review/prompt07_part_b_after/combat_1080x1920.png`
  - `export/portrait_review/prompt07_part_c_review/map_explore_1080x1920.png`
  - `export/portrait_review/prompt09_part_c_review/combat_1080x1920.png`
- repo-truth owner inspection:
  - `scenes/map_explore.gd`
  - `scenes/combat.gd`
  - `Game/UI/run_inventory_panel.gd`
  - `Game/UI/inventory_card_interaction_handler.gd`
  - `Game/UI/map_route_binding.gd`
  - `Game/UI/map_explore_scene_ui.gd`
  - `Game/UI/safe_menu_overlay.gd`
  - `Game/UI/safe_menu_launcher_style.gd`
  - `Game/UI/temp_screen_theme.gd`
- current targeted tests used as evidence only:
  - `Tests/test_button_tour.gd`
  - `Tests/test_phase2_loop.gd`
  - `Tests/test_ui_readability_guardrails.gd`

## 8. Mobile Interaction Matrix

| mobile minimum | current state | evidence | severity if not PASS | proposed narrow follow-up scope |
|---|---|---|---|---|
| 1. Tap vs swipe conflict on the inventory drawer | `PASS` | `Confirmed`: the drawer uses a plain `pressed` handler in `scenes/map_explore.gd` (`_on_inventory_drawer_toggle_pressed`) and no swipe gesture owner exists in `scenes/map_explore.gd` or `Game/UI/run_inventory_panel.gd`. | N/A | none in Part B |
| 2. Tap vs drag conflict on inventory cards | `WEAK` | `Confirmed`: `Game/UI/inventory_card_interaction_handler.gd` routes both click and drag through the same press lane and starts drag at `14.0px`; both `scenes/map_explore.gd` and `scenes/combat.gd` use that same threshold. `Inference`: on touch, a small finger drift can turn an intended tap into a drag/reorder interaction. | `HIGH` | `Game/UI/inventory_card_interaction_handler.gd` |
| 3. Tap vs swipe / pan conflict on the map board | `PASS` | `Confirmed`: repo search found no board-pan or swipe gesture owner in `Game/UI/map_route_binding.gd` or `scenes/map_explore.gd`; live board interaction remains route-selection only. | N/A | none in Part B |
| 4. Long-press semantics: consistent or inconsistent | `PASS` | `Confirmed`: repo search found no long-press gesture owner across the audited UI wave, so there is no inconsistent long-press grammar in the live UI today. | N/A | none in Part B |
| 5. Accidental-tap zones near the bottom of the screen | `WEAK` | `Confirmed`: Prompt 07/09 portrait captures keep the map drawer handle and combat quick-use lane in the lower portrait band; those actions are not destructive, but the interactive density is high near the bottom edge. | `MEDIUM` | `Game/UI/inventory_panel_layout.gd` |
| 6. Edge-of-screen safe area on portrait targets | `WEAK` | `Confirmed`: `Game/UI/safe_menu_launcher_style.gd` uses fixed top insets (`10-18px`) and `Game/UI/first_run_hint_controller.gd` uses a fixed `16px` top margin; these top-edge interactive lanes are not device-cutout aware by contract. | `MEDIUM` | `Game/UI/safe_menu_launcher_style.gd` |
| 7. Touch target overlap (overlapping hitboxes) | `PASS` | `Confirmed`: no overlapping hitboxes were proven in the reviewed screens; `Tests/test_phase2_loop.gd` explicitly guards launcher-vs-run-summary separation and `Tests/test_button_tour.gd` guards compact combat inventory/equipment stacking without lane collision. | N/A | none in Part B |
| 8. Minimum touch target dimension on the live theme | `PASS` | `Confirmed`: `Game/UI/temp_screen_theme.gd` sets `MIN_TOUCH_TARGET_HEIGHT := 48.0` and `MIN_SMALL_BUTTON_WIDTH := 96.0`; `Tests/test_ui_readability_guardrails.gd` verifies the shared button floors. | N/A | none in Part B |
| 9. Confirm-vs-destructive separation on portrait | `WEAK` | `Confirmed`: `Game/UI/safe_menu_overlay.gd` keeps `Quit Game` below the non-destructive actions and gives it the rust/destructive accent, but it still lives in the same vertical action stack with no extra grouping break or confirmation sub-step. | `LOW` | `Game/UI/safe_menu_overlay.gd` |

## 9. Mobile Interaction Gap Counts By Severity

- `BLOCKER`: 0
- `HIGH`: 1
- `MEDIUM`: 2
- `LOW`: 1

## 10. Top Mobile Interaction Gaps

1. Inventory cards still use a shared tap-and-drag lane with a `14px` drag threshold, which is the highest accidental-input risk on touch.
2. Bottom-of-screen inventory and quick-use interaction density is still high on portrait targets.
3. Top-edge launcher and hint lanes are not explicitly cutout-safe by contract.
4. Destructive `Quit Game` placement is visually differentiated, but not yet structurally separated from the rest of the safe-menu action stack.

## 11. Part B Closeout

Confirmed in this pass:

- the drawer model chosen by Prompt 07 remains tap-first; no swipe gesture was added
- the map board still has no user-pan gesture, so there is no tap-vs-pan conflict today
- long-press is currently absent rather than inconsistent
- the main mobile interaction risk is accidental drag on inventory cards, not a missing gesture system

Part B handoff note:

- final merged follow-up queue now appears below as candidate-only work

## 12. Prioritized Candidate Follow-Up Queue

Candidate-only rule:

- This queue records narrow follow-up candidates only.
- No item below is promoted to active work by this document.
- Each item names a single owner surface and the smallest scope that closes the audited gap.

| priority | owner surface | smallest possible scope | closes which gap | save change required | status |
|---|---|---|---|---|---|
| 1 | `Game/UI/inventory_card_interaction_handler.gd` | Tighten touch drag-intent disambiguation only: raise or split the drag-start threshold for touch-style movement and keep the existing tap/drag semantics otherwise unchanged. | Highest-risk mobile gap: accidental tap-vs-drag conflict on inventory cards. | `NO` | candidate only |
| 2 | `Game/UI/temp_screen_theme.gd` | Add a shared text-scale multiplier hook for existing font-size helpers only, using the current UI-helper preference lane rather than a save-schema lane. | Missing player-controllable text scaling. | `NO` | candidate only |
| 3 | `Game/UI/map_route_binding.gd` | Add a stronger persistent non-color route/node cue for portrait map markers without changing route logic, discovery logic, or node truth. | Map node icon readability plus color-only signaling weakness. | `NO` | candidate only |
| 4 | `Game/UI/combat_feedback_lane.gd` | Add a reduced-motion / reduced-flash presentation guard that only dampens flash alpha, pulse scale, and reveal timing. | Motion/flash safety gap. | `NO` | candidate only |
| 5 | `Game/UI/safe_menu_launcher_style.gd` | Replace fixed portrait top/right launcher insets with a cutout-safe inset resolver only. | Top-edge portrait safe-area weakness on the launcher lane. | `NO` | candidate only |
| 6 | `Game/UI/first_run_hint_controller.gd` | Make the top-right hint panel respect the same cutout-safe inset contract instead of the current fixed `16px` edge margin. | Top-edge portrait safe-area weakness on the hint lane. | `NO` | candidate only |
| 7 | `Game/UI/inventory_panel_layout.gd` | Increase portrait-only spacing between bottom-band drawer / quick-use controls and neighboring content without changing the Prompt 07 drawer model. | Bottom-of-screen accidental-tap density. | `NO` | candidate only |
| 8 | `Game/UI/safe_menu_overlay.gd` | Add a structural separation break around `Quit Game` only; no quit behavior, routing, or confirmation-policy change. | Confirm-vs-destructive separation on portrait. | `NO` | candidate only |

## 13. Prompt 12.5 Closeout

- Prompt 12.5 remains reference-only and docs-only.
- Accessibility is not declared complete here; the pack only frames current gaps and records narrow candidate follow-ups.
- No accessibility/mobile fix was implemented in this pack.
- No follow-up was promoted to active work by this closeout.
- The UI overhaul wave is now documented as closed for Prompts `06` through `12.5`, pending explicit approval of any later candidate follow-up.

## 14. Non-Goals

- no code change
- no gameplay logic change
- no theme redesign
- no asset approval or asset hookup
- no claim that this audit implements an accessibility or mobile fix by itself
