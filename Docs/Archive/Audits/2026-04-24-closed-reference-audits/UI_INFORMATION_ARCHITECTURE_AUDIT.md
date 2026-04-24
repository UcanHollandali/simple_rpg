# UI Information Architecture Audit

Reference-only planning document for Prompt 06, finalized in Part B.

Date: 2026-04-22

Status:
- Prompt 06 closed green on the current workspace
- the follow-up Prompt 06.5-12.5 execution wave is archived; this document remains reference-only

Scope rule for this document:
- docs-only
- no gameplay logic change
- no save/runtime schema change
- no asset move/import/hookup
- no new prediction system

Confidence rule used throughout this audit:
- `Confirmed`: directly verified from current screenshots, current owner code, or current tests.
- `Inference`: a UX/readability conclusion drawn from confirmed repo truth.
- `Not captured in this pass`: current state was inspected from owner code/tests rather than a fresh live screenshot.

## 1. Scope And Current Direction

This audit checks whether the player sees the right existing gameplay state at the right time to make the next decision across:
- map explore
- event modal
- combat
- equipment
- backpack
- StageTransition
- RunEnd

Current direction confirmed from prompt authority and repo truth:
- one screen, one dominant task
- map explore dominant task: choose a route
- event modal dominant task: compare choices
- combat dominant task: choose an action
- inventory/equipment dominant task: equip, use, or inspect items
- first pass should surface existing runtime truth better, not create new truth

Evidence basis used for this audit:
- Fresh portrait captures at `1080x1920`:
  - `export/portrait_review/map_explore_1080x1920.png`
  - `export/portrait_review/combat_1080x1920.png`
  - `export/portrait_review/event_1080x1920.png`
  - `export/portrait_review/stage_transition_1080x1920.png`
  - `export/portrait_review/run_end_1080x1920.png`
- Existing current progression captures inspected:
  - `export/portrait_review/prompt04_no_stamp_after_20260422_074912/stage_start_1080x1920.png`
  - `export/portrait_review/prompt04_no_stamp_after_20260422_074912/mid_progression_1080x1920.png`
  - `export/portrait_review/prompt04_no_stamp_after_20260422_074912/late_progression_1080x1920.png`
- Owner/code/test inspection used where a safe live capture was not available in Part A:
  - `Game/UI/map_explore_presenter.gd`
  - `Game/UI/event_presenter.gd`
  - `Game/UI/combat_presenter.gd`
  - `Game/UI/inventory_presenter.gd`
  - `Game/UI/run_status_presenter.gd`
  - `Game/UI/stage_transition_presenter.gd`
  - `Game/UI/hunger_warning_toast.gd`
  - `Game/UI/run_status_strip.gd`
  - `Game/UI/map_overlay_contract.gd`
  - `Game/UI/map_overlay_director.gd`
  - `Game/UI/combat_feedback_lane.gd`
  - `Game/UI/action_hint_controller.gd`
  - `scenes/map_explore.gd`
  - `scenes/event.gd`
  - `scenes/combat.gd`
  - `scenes/stage_transition.gd`
  - `scenes/run_end.gd`
  - `Tests/test_event_presenter.gd`
  - `Tests/test_inventory_presenter.gd`
  - `Tests/test_combat_presenter.gd`
  - `Tests/test_run_status_presenter.gd`

Audit limits:
- Low-HP / low-hunger live screenshots were not safely captured in Part A. Hunger-threshold behavior was inspected from the shared owner surfaces instead.
- The fresh `event_1080x1920.png` capture is an isolated event scene capture. Overlay-above-MapExplore behavior was confirmed from `MapOverlayContract`, `MapOverlayDirector`, and `scenes/event.gd`, not from that isolated image alone.
- No live disabled-choice event state was found in a safe capture path. Event choice availability was inspected from the presenter and scene code.

## 2. Screen Dominant Task Matrix

| Surface | Dominant task | Current truth already surfaced | Main IA conflict or gap |
|---|---|---|---|
| Map Explore | Choose a route | Stage, open routes, seen, cleared, HP, hunger, gold, durability, XP, current board state, equipment row, backpack row | Route-choice screen also keeps equipment and backpack fully expanded, so route reading competes with inventory management |
| Event Modal | Compare choices | Event title, compact summary, choice title/detail/button, tooltip detail, overlay framing over map | Choice comparison relies too much on compact copy plus hover tooltip; disabled-reason support is not modeled |
| Combat | Choose an action | Enemy HP/armor/intent, player HP/hunger/durability/guard, weapon/loadout, action cards, locked equipment, consumables, feedback lane, combat log | Guard truth is split across badge, preview, bursts, and log; action explanation is hover-led |
| Equipment / Backpack | Equip, use, or inspect items | Four explicit equipment slots, backpack count, item family icons, action hints, belt capacity bonus | Slot identity is clear, but the dual-purpose `left_hand` role still needs stronger player-facing signaling |
| StageTransition | Read stage status, then continue | Stage chip, title, summary, objective line, standard status strip, continue CTA | Decorative title, status strip, and CTA share one narrow portrait card |
| RunEnd | Read result, then exit | Result chip, title, result line, hint, standard status strip, return CTA | Good clarity overall, but hierarchy is still title-heavy for a simple final action |

## 3. Global State Visibility Matrix

Classification note:
- classification is about the current player-facing surface, not whether code/test truth exists internally
- `NEEDS_FUTURE_LOGIC_SUPPORT` is used only when the desired player-facing field is not currently modeled as stable runtime truth

| Field | Classification | Current surface | Notes |
|---|---|---|---|
| HP / max HP | `CONTEXT_VISIBLE` | Map status strip, combat player card, run-status shells | Confirmed. Event overlay does not repeat it locally. |
| Hunger / max hunger | `CONTEXT_VISIBLE` | Map status strip, combat player card, run-status shells | Confirmed. Event overlay does not repeat it locally. |
| Hunger threshold warning toast | `CONTEXT_VISIBLE` | Shared map/combat toast | Confirmed. Same owner surface on map and combat. Auto-dismiss after `2.0s`. |
| Gold | `CONTEXT_VISIBLE` | Map status strip, run-status shells | Confirmed. Not foregrounded in combat because it does not drive the immediate action choice. |
| Durability | `CONTEXT_VISIBLE` | Map status strip, combat player card, run-status shells | Confirmed. |
| XP | `CONTEXT_VISIBLE` | Map status strip, StageTransition, RunEnd | Confirmed. |
| Level | `CONTEXT_VISIBLE` | XP progress line (`XP -> Lv X`) | Confirmed. Present as part of XP progress, not as a separate badge. |
| Guard (current value) | `ALWAYS_VISIBLE` | Combat player card and guard badge | Confirmed. Where guard matters, it is visible. |
| Guard delta readouts (gain / absorb / decay carryover) | `CONTEXT_VISIBLE` | Combat feedback lane, preview text, combat log | Confirmed. Exists, but is distributed across multiple surfaces. |
| Armor | `CONTEXT_VISIBLE` | Combat enemy line, combat loadout text, equipment row | Confirmed. Enemy armor is explicit; player armor is contextual via loadout/equipment. |
| Equipped weapon | `CONTEXT_VISIBLE` | Combat player card, map equipment row, run-status shells | Confirmed. |
| Equipment slot identity (`right_hand`, `left_hand`, `armor`, `belt`) and dual-purpose `left_hand` signal | `VISIBLE_BUT_UNREADABLE` | Equipment row, empty-slot copy, combat loadout text | Confirmed. Slot labels exist, but shield vs offhand-weapon meaning is not equally clear at a glance. |
| Backpack capacity (and belt-driven capacity bonus) | `CONTEXT_VISIBLE` | Backpack title and belt card detail | Confirmed. `Backpack X/Y` plus `+2 INV` style surfacing exists. |
| Current stage | `CONTEXT_VISIBLE` | Map header, StageTransition, RunEnd | Confirmed. |
| Stage personality and objective line | `CONTEXT_VISIBLE` | StageTransition | Confirmed from presenter/scene. Captured shell used the default fallback personality text. |
| Open routes | `ALWAYS_VISIBLE` | Map header | Confirmed. |
| Seen nodes | `ALWAYS_VISIBLE` | Map header | Confirmed. |
| Cleared nodes | `ALWAYS_VISIBLE` | Map header | Confirmed. |
| Current node | `ALWAYS_VISIBLE` | Map board and focus model | Confirmed. Player anchor stays visible on board. |
| Reachable nodes | `ALWAYS_VISIBLE` | Map board and focus hint text | Confirmed. |
| Locked route reason | `CONTEXT_VISIBLE` | Map route/focus text | Confirmed for boss-key lane (`Boss lane locked. Need key.`). Generic per-route lock reasons are thinner. |
| Node type | `VISIBLE_BUT_UNREADABLE` | Map icons, color, route text | Confirmed. Type exists, but reading it depends too much on icon/color literacy. |
| Node risk / reward | `NEEDS_FUTURE_LOGIC_SUPPORT` | N/A | Confirmed. Broad family identity exists, but an explicit risk/reward field is not currently modeled as stable runtime truth. |
| Event title | `CONTEXT_VISIBLE` | Event modal header | Confirmed. |
| Event choice cost | `VISIBLE_BUT_UNREADABLE` | Choice detail text / tooltip | Confirmed. Costs can appear in copy, but there is no consistent compare-first cost lane. |
| Event choice reward | `VISIBLE_BUT_UNREADABLE` | Choice detail text / tooltip | Confirmed. Rewards can appear in copy, but not in a dedicated scan lane. |
| Event disabled reason | `NEEDS_FUTURE_LOGIC_SUPPORT` | N/A | Confirmed. Real choice models currently default to enabled and do not surface a disabled reason field. |
| Enemy HP | `ALWAYS_VISIBLE` | Combat enemy card | Confirmed. |
| Enemy armor | `ALWAYS_VISIBLE` | Combat enemy card | Confirmed. |
| Enemy intent | `ALWAYS_VISIBLE` | Combat intent card | Confirmed. |
| Combat action availability | `ALWAYS_VISIBLE` | Combat action cards / buttons | Confirmed for attack/defend. Consumable use is represented through the backpack lane rather than a third fixed action button. |
| Combat usable items | `CONTEXT_VISIBLE` | Combat backpack cards and hints | Confirmed. Item presence and direct-click affordance exist. |
| Combat feedback lane (per-action / per-target ordering) | `CONTEXT_VISIBLE` | Combat feedback bursts | Confirmed. Same-target follow-up hits fall back to text-only instead of overwriting visuals. |
| Last combat result | `CONTEXT_VISIBLE` | Combat log and feedback lane | Confirmed. No dedicated last-result card exists. |
| Full combat log | `CONTEXT_VISIBLE` | Combat log panel | Confirmed. Present on screen, but visually heavy relative to the immediate action row. |

## 4. Map Explore Findings

Confirmed:
- Map header currently surfaces stage, open routes, seen nodes, cleared nodes, HP, hunger, gold, durability, and XP.
- Current node and reachable routes are visible on the board.
- Focused-node support exists through `focused_node_id` and `build_focus_panel_model(...)`.
- Locked boss-lane messaging exists as current truth: `Boss lane locked. Need key.`
- Equipment and backpack are always present below the board.

Decision-visibility findings:
- The route-choice screen is not yet a one-dominant-task screen. Full equipment and backpack sections remain expanded under the board, so route choice and inventory management compete for the same portrait stack.
- Current route context is split across three places:
  - top header progress line
  - board icon/path state
  - focus/read text
  This is truthful, but not especially scan-friendly.
- Node type is present, but mostly through icon/color plus route labels. That is enough for familiar players, weaker for first-pass route comparison.
- Locked-route reason is strongest for the boss-key lane. More generic route lock context is less direct.
- Node risk/reward is not an explicit current runtime field. Any later UI that tries to show exact node risk/reward must not invent new truth inside Prompt 06.

Readability findings:
- The board itself reads better after Prompt 04/05, but the full lower inventory stack still reduces route-reading calm.
- The backpack hint/pressure line is explicitly hidden below `2000px` viewport height in `scenes/map_explore.gd`. At `1080x1920`, the backpack panel keeps title/cards but drops the hint line.
- `SHOW_BOTTOM_CONTEXT := false` means the dedicated bottom context card lane is off, so route-reading burden stays in smaller top/header text.

Coverage note:
- A safe live low-hunger / low-HP map screenshot was not produced in Part A.
- Shared hunger-threshold behavior was still confirmed from the shared map/combat warning owners.

## 5. Event Modal Findings

Confirmed:
- Event is an overlay over MapExplore, not a standalone replacement flow, via `MapOverlayContract` / `MapOverlayDirector`.
- `scenes/event.gd` hides duplicate background layers and enables scrim/margins when used as a top-level overlay.
- The modal intentionally hides its local run-status card to avoid duplicating the map shell status.
- Event cards surface title, compact detail, action button text, and tooltip text.
- Tooltips already expose exact existing truth for some choices, such as heal amount and granted-item effect details.

Important audit limit:
- The fresh `event_1080x1920.png` capture is an isolated scene capture and currently shows the unavailable fallback shell.
- Overlay-above-MapExplore framing was confirmed from current owners, not from that isolated image alone.

Decision-visibility findings:
- Choice comparison is still too tooltip-dependent. The visible card detail line stays compact, but exact reward/cost context often moves into hover detail.
- Disabled-choice reasoning is not yet a supported player-facing field. Real choice view models currently set `button_disabled` to `false` and do not surface a disabled-reason string.
- The modal removes local status duplication, which is good for focus, but it also means HP/hunger context is not foregrounded inside the choice layer when an event choice changes those values.
- No dedicated in-modal back/dismiss affordance was found in the current event choice shell. Current escape path is the broader safe menu / return-to-main-menu flow, not a local "back to map" choice surface.

Readability findings:
- Event title and summary hierarchy is clean, but the compare-first choice lane is not yet strong enough for touch-first reading without tooltip help.
- The isolated shell leaves large empty vertical space; this is not itself a final overlay verdict because the live modal sits above MapExplore.

Repo-truth conclusion for later prompts:
- Prompt 08 should treat the event modal as an overlay-first comparison surface, not as a standalone event page.

## 6. Combat Screen Findings

Confirmed:
- Combat start currently surfaces enemy HP, enemy armor, enemy intent, player HP, hunger, durability, guard, equipped weapon, equipment lock state, backpack, and combat log.
- Equipment remains visible but locked during combat.
- Consumables are represented through the backpack lane, with direct-click use affordance.
- Guard feedback truth already exists as:
  - current guard value
  - signed gain text
  - absorb text
  - decay carryover text
  - combat log lines
- Same-target follow-up feedback does not overwrite earlier feedback visuals; later bursts are downgraded to text-only by the feedback lane.
- `left_hand` truth is genuinely dual-purpose:
  - `Shield X` if family is `shield`
  - `Offhand X` if family is `weapon`

Decision-visibility findings:
- Combat mostly succeeds at "choose an action" in the first visible band, but the action explanation layer is still hover-led through `ActionHintController`.
- Guard truth exists, but it is not hierarchically unified. Current guard, guard gain, guard absorb, and guard decay are each visible somewhere, yet the player has to stitch them together from separate surfaces.
- The dual-purpose `left_hand` slot is mechanically real, but the current UI does not strongly teach the shield-vs-offhand-weapon tradeoff in the exact moment of decision.
- "No usable item" truth exists in presenter/log surfaces, but the empty/useless consumable state is not promoted strongly near the action decision row.

Readability findings:
- The combat log claims a large portrait block even when it contains only `Combat ready.` This is truthful but visually expensive.
- Combat keeps many truthful surfaces on screen at once:
  - enemy card
  - player card
  - action cards
  - equipment row
  - backpack row
  - combat log
  The density is high before the player has taken enough turns to need that whole stack.

Coverage note:
- A fresh after-damage live screenshot was not produced in Part A.
- After-damage, guard gain, absorb, decay carryover, and no-usable-item states were confirmed from current presenters/tests instead.

## 7. Inventory And Equipment Findings

Confirmed:
- Equipment row currently exposes all four explicit slots:
  - `RIGHT HAND`
  - `LEFT HAND`
  - `ARMOR`
  - `BELT`
- Empty-slot placeholders are explicit and contextual:
  - `Open Slot`
  - `Equip shield or offhand.`
  - `Equip armor.`
  - `Equip belt for pack space.`
- Belt-driven capacity bonus is already surfaced in current truth:
  - belt detail text like `+2 INV`
  - backpack title like `Backpack 3/7`
- Combat context correctly changes item affordances:
  - equipment says `Locked during combat`
  - combat backpack says `Only consumables work in combat.`
  - not-currently-beneficial consumables can say `No HP or hunger gain right now`

Decision-visibility findings:
- Slot identity is explicit, but `left_hand` still needs stronger player-facing explanation because it can mean shield or offhand weapon depending on current family.
- Belt utility is one of the clearer current truths in this UI stack. The capacity bonus already reads well enough to preserve as-is into later passes.
- Inventory item families are already semantically separated by icon and copy. Prompt 07 should reuse that truth instead of inventing a new family grammar.

Readability findings:
- The equipment/backpack rows themselves are understandable, but keeping them permanently expanded on map weakens map readability.
- Full-backpack state was not safely live-captured in Part A, but current presenter/test truth shows:
  - expanded slot count from belt bonus
  - open-slot placeholders
  - overflow handling path from event inventory prompt

Repo-truth conclusion for later prompts:
- Prompt 07 should focus on information architecture and presentation hierarchy, not on redefining inventory truth.

## 8. Run-Status Shell Findings

Scope note:
- This section is hierarchy/readability only, not decision-visibility audit.

StageTransition:
- Confirmed current shell shows stage chip, stage title, summary text, objective line, standard run-status strip, and `Step Into Next Route`.
- Presenter truth supports stage personalities `pilgrim`, `frontier`, and `trade`, even though the fresh capture used the default fallback title/summarizer.
- Readability issue: the main decorative title, status strip, and CTA all share one centered card. The hierarchy is understandable, but title weight is still dominant for a simple continue action.

RunEnd:
- Confirmed current shell shows result chip, result title, result line, hint text, standard run-status strip, and `Return to Main Menu`.
- Readability issue: the centered shell is clear and calmer than combat/map, but still title-heavy relative to the single next action.

Overall shell conclusion:
- Both shells are already coherent.
- Later passes should tune hierarchy and spacing, not add new status fields.

## 9. Font And Icon Readability Findings

Confirmed typography inventory:

| Role | Current font owner | Current use | Audit note |
|---|---|---|---|
| Body | `Inter` | body labels, metrics, most general copy | Good default for readability |
| Button | `Inter` | primary and small buttons | Good default for readability |
| Heading / decorative | `Cinzel` | titles, chips, accent/reward/danger labels, section headings | Atmospherically correct, but long portrait headings become visually dominant quickly |

Confirmed decorative-font usage hotspots:
- Map header stage title
- Event title
- Section titles like `Equipment` / `Backpack`
- Combat enemy and player naming lanes
- StageTransition title and chip
- RunEnd title and chip

Typography finding:
- `Cinzel` is not the problem everywhere. It works for chips and short titles.
- The readability risk is broad heading use on narrow portrait cards, especially where a large title competes with summary text, status strips, or a single CTA.

Confirmed icon inventory already wired in current truth:
- status icons: HP, hunger, gold, durability, guard
- equipment icons: weapon, shield, armor, belt
- inventory family icons: passive, quest item, shield attachment, consumable
- combat intent icons: standard attack, heavy attack
- event / route icons: event icon and route-family icon surfaces

Icon finding:
- The repo already has semantic family separation for the most important current item/state lanes.
- Prompt 10 should prioritize size, contrast, and consistency guardrails before asking for any new semantic icon work.

Uncertainty note:
- Terminal inspection of some Turkish warning-copy output showed mojibake in shell text. That is not enough evidence to claim a live in-game rendering bug, so it is not treated as a confirmed readability defect in this audit.

## 10. Archived Prompt 06.5-12.5 Plan

### Top 10 Decision-Visibility Problems

1. MapExplore still shares the route-choice screen with fully expanded equipment and backpack sections, so the dominant task is diluted before the player even starts reading the board.
2. Event modal does not currently support a real disabled-choice reason surface.
3. Event choice comparison is too tooltip-dependent; cost/reward information is not separated into an easy scan lane.
4. Event overlay improves focus by hiding duplicate status, but that also removes foreground HP/hunger context from the actual choice layer.
5. Combat action explanation depends too heavily on hover-only action hints.
6. Combat's "no usable item" or "present but not useful right now" state is not promoted strongly enough near the immediate action decision.
7. Guard truth exists, but gain / absorb / decay is spread across too many surfaces to read as one coherent defensive story.
8. The dual-purpose `left_hand` slot is truthful but under-signaled in the exact decision moment.
9. Map node type and route meaning are still too icon-and-color heavy for first-pass route comparison.
10. Map current/next/locked context is accurate but text-heavy and spatially fragmented across header, board, and focus/read text.

### Top 5 Readability Problems

1. Combat reserves a large log panel before the log has enough content to justify that height.
2. Map route reading is weakened by the always-expanded equipment/backpack stack below the board.
3. Map backpack hint/pressure copy is hidden at `1080x1920` because of the hard `>= 2000` viewport gate.
4. Event card detail still depends too much on hover tooltip for full readability on touch-sized portrait play.
5. Decorative heading weight is strongest on StageTransition, RunEnd, and Event, where large titles compete with simpler next-step content.

### Recommended Queue

| Prompt | Recommended target from repo truth | Why this order |
|---|---|---|
| `06.5` | Audit all current UI microcopy, especially disabled/locked/empty/no-usable text, event choice compare copy, hunger warning copy, guard delta wording, and route-read wording | Current IA gaps are partly layout, partly copy. This docs-only pass should freeze the language problems before implementation passes start. |
| `07` | Rework map inventory/equipment into a clearer drawer-style hierarchy while preserving four explicit slots and belt-capacity truth | The largest current dominant-task conflict is on MapExplore, not in combat. |
| `08` | Rebuild event choice cards as overlay-first compare surfaces with stronger inline cost/reward clarity and truthful disabled-state handling if supported later | Event overlay truth is already established; the compare layer is the next problem. |
| `09` | Tighten combat hierarchy: guard story, item-state clarity, loadout clarity, log weight, and action explanation | Combat already exposes rich truth. The main need is prioritization, not new data. |
| `10` | Apply font/icon readability guardrails after map/event/combat hierarchy decisions stabilize | Typography and icon tuning should follow the IA decisions, not precede them. |
| `10.5` | Add first-run hints only after the core surfaces stop shifting | Tutorial hints should teach the final hierarchy, not a moving target. |
| `11` | Token/theme cleanup after layout and readability work land | Theme token cleanup is safest once the hierarchy is stable. |
| `11.5` | Empty/error/loading-state rewrite from the audited microcopy queue | Empty/error text should align with the new hierarchy, not the old one. |
| `12` | Semantic icon readiness pass using the current icon inventory as the baseline | New semantic icon work should not run before hierarchy and readability stabilize. |
| `12.5` | Accessibility/mobile audit after all earlier UI hierarchy passes close green | This should validate the actual final stack, especially touch/no-hover behavior. |

### Explicit Prompt 06.5 / Prompt 07 Handoff Scope

Prompt `06.5` should specifically audit:
- map route-read copy
- locked-route copy
- shared hunger warning toast copy
- event choice detail/cost/reward wording
- event unavailable / no-choice / failure wording
- combat guard gain / absorb / decay wording
- no-usable-item wording
- left-hand slot naming where shield vs offhand weapon meaning changes
- full / empty / locked / unusable inventory states

Prompt `07` should specifically implement:
- map-first dominant-task hierarchy
- drawer or collapsible inventory/equipment presentation
- preserved four-slot equipment identity
- preserved belt capacity bonus readability
- preserved quick inspect/use/equip affordances without keeping the whole inventory stack permanently open on MapExplore

## 11. Explicit Non-Goals

This audit does not:
- implement a UI overhaul
- change gameplay logic
- change combat math
- change route logic
- change event outcome logic
- change save schema
- change runtime state schema
- move owner boundaries
- add new command families or event families
- approve, generate, move, rename, import, convert, or hook assets
- change `UiAssetPaths`
- add prediction systems such as exact post-action damage forecasts

Prompt 06 Part A conclusion:
- current repo truth is strong enough to plan the next UI queue without changing gameplay
- the biggest current IA issue is hierarchy and focus, not missing raw state
- later passes should surface existing truth more clearly before asking for any new logic support

Prompt 06 Part B closeout:
- this document remains reference-only
- implementation is deferred to Prompt `06.5` through Prompt `12.5`
