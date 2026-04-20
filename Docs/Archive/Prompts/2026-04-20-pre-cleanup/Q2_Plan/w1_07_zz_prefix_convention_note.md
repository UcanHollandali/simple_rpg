# W1-07 — Document the `zz_*` event-template stable-ID convention (D-045)

- mode: Fast Lane, doc-only
- scope: short paragraph in `Docs/CONTENT_ARCHITECTURE_SPEC.md`
- do not touch: any `ContentDefinitions/EventTemplates/zz_*.json`; any runtime reference; any test
- validation budget: `py -3 Tools/validate_architecture_guards.py`; `py -3 Tools/validate_content.py`
- doc policy: apply decision `D-045`. No rename, no churn.

## Context

`ContentDefinitions/EventTemplates/zz_*.json` uses a `zz_` prefix to force alphabetical-sort ordering. Without a note, the prefix reads as a code smell and keeps getting proposed for rename. `D-045` says the IDs are deliberate and must not be renamed.

## Task

1. Add a short paragraph (3–6 sentences) to `Docs/CONTENT_ARCHITECTURE_SPEC.md` in the stable-ID section explaining:
   - `zz_*` is a deliberate alphabetical-sort convention,
   - the prefix is part of the stable ID and will not be renamed,
   - future event templates that need similar ordering may reuse the convention,
   - the decision is `D-045`.
2. Do not rename any existing event template.
3. Do not update the event templates themselves.

## Non-goals

- Do not change `Tools/validate_content.py` behavior.
- Do not rename any content file.
- Do not update the patch backlog.

## Report format

- the paragraph in final form
- validator + content validator results
- explicitly: no content file changed
