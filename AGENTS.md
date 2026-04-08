# SIMPLE RPG - AI Agent Rules

This file is the repo-level operating contract for AI coding agents.

## Read First

Read these before changing code:
- [Docs/TECH_BASELINE.md](Docs/TECH_BASELINE.md)
- [Docs/ARCHITECTURE.md](Docs/ARCHITECTURE.md)
- [Docs/SOURCE_OF_TRUTH.md](Docs/SOURCE_OF_TRUTH.md)
- [Docs/CONTENT_ARCHITECTURE_SPEC.md](Docs/CONTENT_ARCHITECTURE_SPEC.md)
- [Docs/DOC_PRECEDENCE.md](Docs/DOC_PRECEDENCE.md)

Task-specific docs:
- Combat work -> [Docs/COMBAT_RULE_CONTRACT.md](Docs/COMBAT_RULE_CONTRACT.md), [Docs/COMBAT_INFO_MODEL.md](Docs/COMBAT_INFO_MODEL.md)
- Save work -> [Docs/SAVE_SCHEMA.md](Docs/SAVE_SCHEMA.md)
- Flow work -> [Docs/GAME_FLOW_STATE_MACHINE.md](Docs/GAME_FLOW_STATE_MACHINE.md)
- Testing work -> [Docs/TEST_STRATEGY.md](Docs/TEST_STRATEGY.md)

## Non-Negotiables

- Do not move gameplay truth into UI.
- Do not mix definition data with runtime state.
- Do not use display text as logic keys.
- Do not add gameplay autoloads for convenience.
- Do not hide mechanic changes inside content additions.
- Do not widen scope silently.

## Allowed Change Matrix

| Task type | Typical write scope | Required checks |
|---|---|---|
| Content-only | `ContentDefinitions/`, maybe `Docs/CONTENT_ARCHITECTURE_SPEC.md` | schema validation, ID/reference checks |
| UI-only | `Game/UI/`, `Scenes/` | no gameplay truth drift |
| Core rule change | `Game/Core/`, related docs | rule tests, invariants |
| Flow change | `Game/Application/`, flow docs | transition tests |
| Save-sensitive | `Game/RuntimeState/`, `Game/Infrastructure/`, save docs | roundtrip plus invariant checks |
| Mechanic change | code plus authoritative docs plus decision log | docs updated before done |

## Escalation Triggers

Stop and surface the change if it affects:
- stable ID rename
- save schema shape
- new flow state
- new command family
- new domain event family
- source-of-truth ownership rule
- gameplay autoload need
- scene/core boundary change

## Content Patch Template

For content additions, reason using:
- `definition_id`
- `family`
- `tags`
- `reused grammar`
- `new mechanic required: yes/no`
- `validation required`

## Working Style

- Make small, local changes.
- Read only the docs relevant to the task.
- Prefer the smallest safe patch.
- Validate the changed area.
- Report what changed, what did not, and what still needs checking.

## Success Condition

A change is successful when:
- the request is solved
- unrelated systems are not destabilized
- docs stay truthful
- future humans and agents can understand the change quickly
