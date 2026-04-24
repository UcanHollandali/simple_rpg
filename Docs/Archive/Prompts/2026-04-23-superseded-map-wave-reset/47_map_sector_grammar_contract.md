# Prompt 47 - Map Sector Grammar Contract

Use this prompt only after Prompt 57 is closed green.
This prompt defines the hidden board partition grammar before runtime implementation begins.
It is primarily a contract/spec pack; do not widen into large runtime changes here.

Checked-in filename note:
- this pack lives at `Docs/Promts/47_map_sector_grammar_contract.md`

Read first:
- `AGENTS.md`
- `Docs/DOC_PRECEDENCE.md`
- `Docs/MAP_CONTRACT.md`
- `Docs/SOURCE_OF_TRUTH.md`
- `Docs/MAP_COMPOSER_V2_DESIGN.md`
- Prompt `43-46` outputs
- Prompt `57` baseline harness outputs

Preflight:
- touched owner layer: `map authority/docs + design contract`
- authority doc: `Docs/MAP_CONTRACT.md`
- impact: `runtime truth may be affected later / save shape unchanged in this prompt / asset-provenance unchanged`
- minimum validation set: `markdown/internal link sanity + validate_architecture_guards`

## Goal

Replace vague "board spread" language with an explicit hidden-sector grammar that later runtime and UI prompts can implement.

## Direction Statement

- sectors are invisible to the player
- sectors are not a rigid visible UI grid
- sectors exist to create full-board usage, lane separation, and route identity
- exact center start is not required; deliberate start anchor is required
- sector occupancy should usually read sparse rather than uniform:
  - often `0-2` nodes in a sector by default
  - denser pockets only where explicitly justified by route role or stage pressure
- later prompts may implement this in runtime generation and layout, but Prompt `47` itself is the contract gate
- the new sector/layout/router chain should be introduced side-by-side with the older presentation chain until the green switch gate is met

## Required Sector Direction

Minimum baseline sectors:
- `center_anchor`
- `north_west`
- `north_center`
- `north_east`
- `mid_left`
- `mid_right`
- `south_west`
- `south_center`
- `south_east`

Allowed later extension:
- one or two optional outer-late sectors if needed for key/boss pressure

For each sector, define:
- allowed neighboring sectors
- min/max occupancy
- optional empty chance
- slot/anchor budget
- role bias
- corridor exits

## Hard Guardrails

- No save-shape change in Prompt `47`.
- No runtime owner move in Prompt `47`.
- No hidden visible-grid UI surface.
- Node placement must not default to sector center as a silent byproduct of the grammar.
- Visible checkerboard, visible cell-centering, or obvious symmetry should be treated as contract failure, not as acceptable randomness.
- Do not turn sectors into player-facing logic labels.

## Validation

- markdown/internal link sanity
- `py -3 Tools/validate_architecture_guards.py`

## Done Criteria

- the hidden-sector grammar is explicit enough for runtime implementation
- allowed neighbor and occupancy rules are locked
- later prompts do not need to improvise the board partition model

## Copy/Paste Parts

### Part A - Sector Grammar Spec

```text
Apply only Prompt 47 Part A.

Scope:
- Define the hidden-sector grammar for the new map system.

Required outcomes:
- sector list
- neighbor rules
- occupancy bounds
- slot budgets
- role biases
- corridor exits

Do not:
- patch runtime code in Part A
- widen into asset or UI implementation

Validation:
- validate_architecture_guards

Report:
- exact sector grammar chosen
- why it is not just a visible rigid grid
- explicit note whether any later implementation step now appears to require `escalate first`
```

### Part B - Contract Sync

```text
Apply only Prompt 47 Part B.

Scope:
- Update only the closest active docs needed to lock the sector grammar:
  - `Docs/MAP_CONTRACT.md`
  - the closest map reference companion if needed

Do not:
- patch runtime
- widen into route rendering or asset work

Validation:
- markdown/internal link sanity
- validate_architecture_guards

Report:
- files changed
- exact sector grammar wording landed
```
