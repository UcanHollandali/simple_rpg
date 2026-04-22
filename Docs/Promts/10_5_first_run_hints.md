# Prompt 10.5 - First-Run Contextual Hints

Use this prompt pack only after Prompt 10 is closed green.
This is a future-queue pack. Do not start it while Prompt 04, Prompt 05, Prompt 06, Prompt 06.5, Prompt 07, Prompt 08, Prompt 09, or Prompt 10 is still open.

This pack is the only pack in the 06-12.5 wave that touches the save schema. Read the guardrails twice.
Do not start Prompt 10.5 casually. Treat it as optional until the Prompt 06-10 gains are already stable in screenshot review and manual playtests.
Per `AGENTS.md`, any real save-shape change is high-risk `escalate first` work. If Part A confirms that a persisted shown-hint field is required, surface that explicitly before implementation instead of treating this as ordinary UI polish.

Read first:
- `AGENTS.md`
- `Docs/DOC_PRECEDENCE.md`
- `Docs/HANDOFF.md`
- `Docs/ROADMAP.md`
- `Docs/TEST_STRATEGY.md`
- `Docs/SAVE_SCHEMA.md`
- `Docs/UI_INFORMATION_ARCHITECTURE_AUDIT.md`
- `Docs/UI_MICROCOPY_AUDIT.md`

## Goal

Add a small, save-aware, one-shot contextual hint surface so a first-time player learns the unique-to-this-game ideas without a tutorial mode.

This pack does NOT add a tutorial mode, a guided onboarding overlay, or a separate scene. It adds a narrow shared `FirstRunHintController` that gates lightweight hints by a "hint already shown" save flag.

## Direction Statement

- One hint at a time. Never stack.
- Each hint is contextual: it triggers when the relevant gameplay state first appears, not on a timed schedule.
- Each hint has a single short line and one dismiss action.
- Each hint is shown at most once per save.
- A new run reuses the same shown-hint set; the player does not need to re-learn between runs.
- Hints never gate gameplay. Combat does not pause. Map does not freeze. Hints overlay, not interrupt.
- The set of in-scope hints is fixed by this pack. No "tips" pipeline, no rotating tip system.

## In-Scope Hint Set (frozen)

Only these hints. Do not add more in this pack.

- `first_combat_defend` - on entering the first combat ever, briefly explain that Defend generates Guard and is sometimes safer than Attack.
- `first_left_hand_shield` - on first time picking up or being granted any shield, briefly explain that the left-hand slot is dual-purpose (`shield` or `weapon`).
- `first_left_hand_offhand_weapon` - on first time picking up an offhand-capable weapon, briefly explain dual-wield trade-off.
- `first_hamlet` - on first hamlet entry, briefly explain stage-personality and that requests are deterministic per run.
- `first_roadside_encounter` - on first travel-triggered roadside encounter, briefly explain that this is an interruption and the original destination is preserved.
- `first_key_required_route` - on first time the player encounters a route gated by a key requirement, briefly explain key-then-boss flow.
- `first_belt_capacity` - on first time a belt grants backpack capacity bonus, briefly explain that belts are backpack-utility items now.
- `first_low_hunger_warning` - on first hunger threshold trigger, briefly explain that hunger pressure compounds across nodes.

That is the entire frozen set.

## Existing-Truth Rule

Hints never reveal predicted outcomes. Hints describe rules and surface meaning that already exist. Do not introduce text that implies new gameplay calculation.

If a desired hint would require new gameplay logic, drop it from this pack. Do not implement it.

## Save Schema Contract

This pack is the only pack in the 06-12.5 wave that may add to the save schema.

- Add a single namespaced field, e.g. `app_state.shown_first_run_hints`, as a string-set / array of stable hint identifiers.
- Bump `save_schema_version` only if `Docs/SAVE_SCHEMA.md` requires it. Otherwise add the field as additive-optional with safe default `[]`.
- Loading an older save: missing field defaults to empty set; no migration step is required beyond default fill.
- `content_version` does not change; this is not content data.
- The shown-hint set MUST be persisted, not session-scoped. Treat it like other run-independent state, not like `RunState`.

If the save audit reveals that adding the field cleanly would require a migration, an owner-boundary move, or a broader schema interpretation change, stop and say `escalate first`; do not silently fall back to in-memory-only behavior.

## Escalation Gate

- Part A must explicitly restate:
  - touched owner layer
  - authority doc
  - impact: runtime truth / save shape / asset-provenance
  - minimum validation set
- If the honest answer is `save shape changes`, treat the work as high-risk `escalate first` per `AGENTS.md`.
- Do not hide a save-shape change behind "UI polish" wording.

## Preferred Owner Surfaces

- new shared owner: `Game/UI/first_run_hint_controller.gd` (introduced in this pack; small, single-purpose)
- presentation hooks in: `Game/UI/combat_scene_ui.gd`, `Game/UI/map_explore_scene_ui.gd`, `Game/UI/event_presenter.gd`
- save lane: `Game/Infrastructure/save_service.gd` plus the relevant runtime owner that already carries app-level non-run state

Do not move the field into `RunState`. Hints persist across runs.

## Hard Guardrails

- No new gameplay logic.
- No combat math change.
- No item effect change.
- No event outcome change.
- No flow change. A hint never blocks input.
- No tutorial mode. No guided overlay sequence. No timed tip rotation.
- No ownership move beyond introducing the new `FirstRunHintController` shared owner.
- No asset hookup or `UiAssetPaths` changes.
- No widening of `/root/AppBootstrap` lookup spread.
- No new hint outside the frozen in-scope set.
- If the save change cannot remain additive-optional under `Docs/SAVE_SCHEMA.md`, stop and say `escalate first`.

## Validation

- `py -3 Tools/validate_architecture_guards.py`
- targeted save round-trip test (older save loads with empty set, new save writes / reads field)
- targeted UI tests for the new `FirstRunHintController`
- scene isolation for any scene whose composition was touched
- full suite before closing implementation parts
- portrait screenshots: at least one capture of each hint at trigger, plus a capture proving the hint does not retrigger

## Done Criteria

- The frozen 8 hints are wired and triggerable in the right runtime moments.
- Each hint shows at most once per save.
- A second run on the same save does not retrigger hints that were dismissed.
- A fresh save shows hints in the right contextual order.
- Combat, map, and event flows are not blocked by any hint.
- Save round-trip is clean: older saves load without crash, newer saves persist the shown-hint set.
- No tutorial mode added; no rotating tips system added; the in-scope hint set is exactly the frozen 8.

## Copy/Paste Parts

### Part A - Hint Controller And Save Field

```text
Apply only Prompt 10.5 Part A.

Scope:
- Add Game/UI/first_run_hint_controller.gd as a small shared owner.
- Add an additive-optional save field (e.g. app_state.shown_first_run_hints) for the persisted shown-hint set.
- Wire load/save round-trip with safe default (empty set) for older saves.
- No hint UI yet; this part is owner + save plumbing only.

Do not:
- introduce hint UI yet
- add gameplay logic
- change RunState
- change content_version
- bump save_schema_version unless `Docs/SAVE_SCHEMA.md` requires it; otherwise treat the new field as additive-optional with default []
- if the field cannot stay additive-optional under `Docs/SAVE_SCHEMA.md`, stop and say `escalate first`

Validation:
- validate_architecture_guards
- targeted save round-trip test (older save loads, new save writes / reads new field)
- targeted FirstRunHintController unit test (idempotent mark-shown, query)

Report:
- files added/changed
- exact save field name
- whether save_schema_version was bumped (and why or why not)
- whether the field remained additive-optional under `Docs/SAVE_SCHEMA.md`
- whether Part A required an explicit `escalate first` acknowledgement before implementation
- save round-trip evidence
```

### Part B - Hint Triggers (Combat And Inventory)

```text
Apply only Prompt 10.5 Part B.

Scope:
- Wire these hints to their first contextual trigger:
  - first_combat_defend
  - first_left_hand_shield
  - first_left_hand_offhand_weapon
  - first_belt_capacity
  - first_low_hunger_warning
- Each hint shows once, then is marked shown via FirstRunHintController.
- Combat input is not blocked. Map input is not blocked.

Do not:
- add hints outside the frozen set
- pause combat
- redesign tooltip system
- widen owner surfaces beyond combat / inventory presentation files plus the new controller

Validation:
- validate_architecture_guards
- targeted UI tests (each hint triggers once, no retrigger)
- combat scene isolation if scene wiring changed
- full suite before closing
- portrait screenshots: each hint at trigger plus a capture proving non-retrigger

Report:
- files changed
- screenshot paths per hint
- explicit confirmation that combat input was never blocked
- explicit confirmation that no out-of-scope hint was added
```

### Part C - Hint Triggers (Map / Event)

```text
Apply only Prompt 10.5 Part C.

Scope:
- Wire these hints to their first contextual trigger:
  - first_hamlet
  - first_roadside_encounter
  - first_key_required_route
- Each hint shows once, then is marked shown via FirstRunHintController.
- Map flow and event flow are never blocked.

Do not:
- add hints outside the frozen set
- pause map travel
- block event modal input
- widen into other map/event UI changes already owned by Prompts 07-09

Validation:
- validate_architecture_guards
- targeted UI tests (each hint triggers once, no retrigger)
- map / event scene isolation if scene wiring changed
- full suite before closing
- portrait screenshots: each hint at trigger plus a capture proving non-retrigger

Report:
- files changed
- screenshot paths per hint
- explicit confirmation that map / event input was never blocked
- explicit confirmation that no out-of-scope hint was added
```

### Part D - Cross-Run Verification And Closeout

```text
Apply only Prompt 10.5 Part D.

Scope:
- Verify that:
  1. a fresh save shows hints in the correct contextual order
  2. a second run on the same save never retriggers a dismissed hint
  3. an older save loads cleanly with default empty shown-hint set
  4. no hint blocks input
- Update Docs/HANDOFF.md and Docs/ROADMAP.md so Prompt 10.5 is recorded and Prompt 11 stays the next active step.
- Record that the frozen hint set was fully wired and that no tutorial mode was added.

Do not:
- introduce a tutorial mode
- introduce a rotating tips system
- bump content_version
- expand the hint set

Validation:
- validate_architecture_guards
- save round-trip on at least one older save
- full suite before closing
- markdown/internal link sanity

Report:
- files changed
- cross-run verification evidence
- final hint coverage list
- any remaining open hint-related risk
```
