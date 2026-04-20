# W0-03 — Add `D-041..D-046` to `Docs/DECISION_LOG.md`

- mode: Fast Lane, doc-only
- scope: `Docs/DECISION_LOG.md` only
- do not touch: any code, any authority doc
- validation budget: `py -3 Tools/validate_architecture_guards.py`
- doc policy: use the existing table style of `## Accepted Decisions`. Match the existing row format exactly: `| D-0xx | <decision sentence ending with a period.> | <authority doc refs separated by commas> |`.

## Why

`Docs/Audit/2026-04-18-patch-backlog.md` leaves seven Open Questions unresolved. The W0 wave of this Q2 plan closes six of them (B-1 closure — recreating the maintainability audit — does not need a decision row). The remaining six closures need to be durable as decision entries before W1-05..W1-08 and W1-09 apply them.

## Decisions to append

Append these six rows to the existing `| ID | Decision | Authority |` table, keeping the next free numeric ID. If the latest row before this change is `D-040`, these become `D-041..D-046`. If later numbers exist, shift accordingly and report the final IDs.

| ID (first free) | Decision | Authority |
|---|---|---|
| D-041 | `NodeResolve` is an orchestrated transition shell only and has no generic runtime fallback; docs and code must read consistently on this. | `GAME_FLOW_STATE_MACHINE.md`, `MAP_CONTRACT.md` |
| D-042 | `RunState` compatibility accessors (`weapon_instance`, `armor_instance`, `belt_instance`, `consumable_slots`, `passive_slots`) are a frozen compat surface, not an expansion surface; the validator already guards them and will remain the enforcement point. | `SOURCE_OF_TRUTH.md`, `SAVE_SCHEMA.md` |
| D-043 | The hamlet side-quest runtime state stays split between `MapRuntimeState` and `SupportInteractionState` by design; both owners must name the split explicitly in their own file header. | `SOURCE_OF_TRUTH.md`, `SUPPORT_INTERACTION_CONTRACT.md`, `MAP_CONTRACT.md` |
| D-044 | `InventoryState` cached slot-family getters are allowed to write-through their cache as a named exception; new callers must not treat this pattern as a generic allowance. | `SOURCE_OF_TRUTH.md` |
| D-045 | `zz_*` stable IDs for event templates are a deliberate alphabetical-sort convention, not churn debt; no rename is planned. | `CONTENT_ARCHITECTURE_SPEC.md` |
| D-046 | `gate_warden` is retired; its definitions, assets, and references are to be removed and the dead content is not reserved for a future boss slot. | `CONTENT_ARCHITECTURE_SPEC.md`, `GDD.md` |

## Rules

- Do not rewrite the decision text; copy the sentences above verbatim.
- Do not add a rationale column (the log uses a three-column format).
- Do not edit any authority doc in this patch. The follow-up prompts W1-05..W1-09 patch the authority docs.
- Preserve the alphabetical/numeric ordering that the existing log uses.

## Report format

- listed changes: the six new rows
- final IDs used
- confirmation: no authority doc changed, no code changed
