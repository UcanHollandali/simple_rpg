# W1-06 — Document the `InventoryState` cached-getter write-through exception (D-044)

- mode: Fast Lane, doc-only (inline block comment + authority-doc text)
- scope: a short block comment around the cached slot-family getter site in `Game/RuntimeState/inventory_state.gd`; a short paragraph in `Docs/SOURCE_OF_TRUTH.md`
- do not touch: the getter implementation; any caller; any other authority doc
- validation budget: `py -3 Tools/validate_architecture_guards.py`
- doc policy: apply decision `D-044`. Do not invent a new pattern allowance.

## Context

The cached slot-family getter in `InventoryState` writes through its cache on read. `D-044` says this is an accepted named exception, not a general pattern.

## Task

1. Find the cached slot-family getter site in `Game/RuntimeState/inventory_state.gd` (the one flagged by `RS-F4` / `ARCH-F3` in `Docs/Audit/2026-04-18-patch-backlog.md`).
2. Add a 4–8 line comment immediately above the site explaining:
   - the cache write-through is intentional,
   - it is a named exception, not a generic allowance,
   - new callers must not treat this as a pattern,
   - the authority is `D-044` and `SOURCE_OF_TRUTH.md`.
3. Add a short paragraph to `Docs/SOURCE_OF_TRUTH.md` naming the exception and its site file.

## Non-goals

- Do not change the getter implementation.
- Do not change any caller.
- Do not change cache policy.

## Report format

- exact site line number before and after the comment
- before/after of the SOURCE_OF_TRUTH paragraph
- validator result
