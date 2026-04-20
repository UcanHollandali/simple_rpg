# W0-05 — Register `turn_phase_resolved` and `BossPhaseChanged` in the command/event catalog (P-02)

- mode: Fast Lane, doc-only
- scope: `Docs/COMMAND_EVENT_CATALOG.md` only
- do not touch: any code, any authority doc other than the catalog
- validation budget: `py -3 Tools/validate_architecture_guards.py`
- doc policy: the catalog is a naming/reference register, not an authority. Add entries, do not invent new event families.

## Confirmed drift (measured 2026-04-20)

- `turn_phase_resolved` appears 6 times in `.gd` code and 0 times in the catalog.
- `BossPhaseChanged` appears 9 times in `.gd` code and 0 times in the catalog.

## Task

1. Open `Docs/COMMAND_EVENT_CATALOG.md`.
2. Insert entries for both names into their matching section (event families vs command families) using the existing bullet format. Keep the surrounding alphabetical order intact.
3. For each entry, add a one-sentence note indicating what runtime emits it — derive the note by grepping the codebase for every `turn_phase_resolved` and `BossPhaseChanged` occurrence and naming the closest emitter.
4. Do not add families that are not yet in code. This is a register-what-exists pass, not a reservation pass.

## Non-goals

- Do not edit `ARCHITECTURE.md` — authority on whether these families should exist lives there, and this prompt does not propose new families.
- Do not modify code.
- Do not rename existing entries.

## Report format

- listed additions with the one-sentence origin note for each
- grep summary: emitter file(s) confirmed for each of the two names
- explicitly: no code changed, no authority doc changed
