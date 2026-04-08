# SIMPLE RPG

Small-scope, preparation-focused, turn-based roguelite RPG for mobile portrait.

This repository is documentation-first. The project is intentionally being built to stay:
- AI-friendly
- human-maintainable
- low-refactor
- content-extensible

Current repo state:
- docs-only baseline
- no active engine shell committed
- no gameplay code currently kept in the repo

## Status Source

`README.md` is intentionally stable and should change rarely.

For current implementation state, blockers, and next steps, use:
- [Docs/HANDOFF.md](Docs/HANDOFF.md)

## Read Order

Start here:
1. [Docs/TECH_BASELINE.md](Docs/TECH_BASELINE.md)
2. [Docs/HANDOFF.md](Docs/HANDOFF.md)
3. [Docs/ARCHITECTURE.md](Docs/ARCHITECTURE.md)
4. [Docs/SOURCE_OF_TRUTH.md](Docs/SOURCE_OF_TRUTH.md)
5. [Docs/CONTENT_ARCHITECTURE_SPEC.md](Docs/CONTENT_ARCHITECTURE_SPEC.md)
6. [Docs/DOC_PRECEDENCE.md](Docs/DOC_PRECEDENCE.md)

Then read by task:
- Game identity: [Docs/GDD.md](Docs/GDD.md)
- Scope timing: [Docs/SCOPE.md](Docs/SCOPE.md)
- Flow: [Docs/GAME_FLOW_STATE_MACHINE.md](Docs/GAME_FLOW_STATE_MACHINE.md)
- Combat rules: [Docs/COMBAT_RULE_CONTRACT.md](Docs/COMBAT_RULE_CONTRACT.md)
- Combat information: [Docs/COMBAT_INFO_MODEL.md](Docs/COMBAT_INFO_MODEL.md)
- Save rules: [Docs/SAVE_SCHEMA.md](Docs/SAVE_SCHEMA.md)
- Tests: [Docs/TEST_STRATEGY.md](Docs/TEST_STRATEGY.md)
- Commands/events: [Docs/COMMAND_EVENT_CATALOG.md](Docs/COMMAND_EVENT_CATALOG.md)
- Decision history: [Docs/DECISION_LOG.md](Docs/DECISION_LOG.md)
- Deferred topics: [Docs/DEFERRED_DECISIONS.md](Docs/DEFERRED_DECISIONS.md)
- Experimental ideas: [Docs/EXPERIMENT_BANK.md](Docs/EXPERIMENT_BANK.md)
- Current handoff state: [Docs/HANDOFF.md](Docs/HANDOFF.md)
- Baseline freeze gate: [Docs/DOC_FREEZE_CHECKLIST.md](Docs/DOC_FREEZE_CHECKLIST.md)
- Implementation order: [Docs/IMPLEMENTATION_ROADMAP.md](Docs/IMPLEMENTATION_ROADMAP.md)

## Repo Map

- [AGENTS.md](C:\Users\kemal\Documents\Codex\simple_rpg\AGENTS.md): repo-level AI operating rules
- [CLAUDE.md](C:\Users\kemal\Documents\Codex\simple_rpg\CLAUDE.md): short memory layer for Claude-style agents
- [Docs/](C:\Users\kemal\Documents\Codex\simple_rpg\Docs): authoritative design and technical docs
- code and engine shell are intentionally absent until clean re-bootstrap starts

## Locked Technical Baseline

- Engine: `Godot 4 stable`
- Scripting: `typed GDScript`
- Content format: `JSON`
- Content path: `ContentDefinitions/<family>/<stable_id>.json`
- One definition per file
- Stable IDs use `lower_snake_case`
- Gameplay truth does not live in UI
- Gameplay truth does not live in gameplay autoloads
- Save support starts with safe-state saves only

## Workflow Notes

- `README.md` is the standard repo entry file. Use `README.md`, not `.txt`.
- `README.md` is the stable entrypoint, not the rolling status log.
- Do not move session-by-session status into `README.md`; keep that in `Docs/HANDOFF.md`.
- Keep Godot closed while large external patch sets are being applied. Reopen after edits.
- Treat docs as the system of record. Code should follow the docs, not replace them.

## Phase Plan

1. Documentation and technical baseline
2. Clean engine bootstrap
3. Minimum playable slice
4. Safe-state save/load
5. Validation and hardening
6. Minimum content set
7. Vertical slice hardening
