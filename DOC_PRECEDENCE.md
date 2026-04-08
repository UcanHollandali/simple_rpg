# SIMPLE RPG - Documentation Precedence Rules

## Purpose

This file explains which docs are authoritative for which topics.

## Main Rule

Use the closest authoritative document for the topic.
Do not resolve conflicts by convenience.

## Role-Based Precedence

### Design Authority

- [GDD.md](GDD.md)
- [SCOPE.md](SCOPE.md)

### Technical Authority

- [TECH_BASELINE.md](TECH_BASELINE.md)
- [ARCHITECTURE.md](ARCHITECTURE.md)
- [SOURCE_OF_TRUTH.md](SOURCE_OF_TRUTH.md)
- [CONTENT_ARCHITECTURE_SPEC.md](CONTENT_ARCHITECTURE_SPEC.md)
- [COMBAT_RULE_CONTRACT.md](COMBAT_RULE_CONTRACT.md)
- [COMBAT_INFO_MODEL.md](COMBAT_INFO_MODEL.md)
- [GAME_FLOW_STATE_MACHINE.md](GAME_FLOW_STATE_MACHINE.md)
- [SAVE_SCHEMA.md](SAVE_SCHEMA.md)
- [TEST_STRATEGY.md](TEST_STRATEGY.md)
- [COMMAND_EVENT_CATALOG.md](COMMAND_EVENT_CATALOG.md)

### Workflow Authority

- [AGENTS.md](../AGENTS.md)
- [CLAUDE.md](../CLAUDE.md)
- [HANDOFF.md](HANDOFF.md)
- [DOC_FREEZE_CHECKLIST.md](DOC_FREEZE_CHECKLIST.md)

### Context and History

- [DECISION_LOG.md](DECISION_LOG.md)
- [DEFERRED_DECISIONS.md](DEFERRED_DECISIONS.md)
- [EXPERIMENT_BANK.md](EXPERIMENT_BANK.md)

## Fast Topic Map

| Topic | Authority |
|---|---|
| game identity | `GDD.md` |
| scope timing | `SCOPE.md` |
| layer boundaries | `ARCHITECTURE.md` |
| data ownership | `SOURCE_OF_TRUTH.md` |
| content schema | `CONTENT_ARCHITECTURE_SPEC.md` |
| combat behavior | `COMBAT_RULE_CONTRACT.md` |
| combat visibility | `COMBAT_INFO_MODEL.md` |
| flow transitions | `GAME_FLOW_STATE_MACHINE.md` |
| save rules | `SAVE_SCHEMA.md` |
| test expectations | `TEST_STRATEGY.md` |
| commands/events | `COMMAND_EVENT_CATALOG.md` |

## Important Clarifications

- `README.md` is an entrypoint, not the final rule source.
- `AGENTS.md` and `CLAUDE.md` are workflow files, not gameplay rule contracts.
- `HANDOFF.md` is a current-state handoff file, not a rule contract.
- `DOC_FREEZE_CHECKLIST.md` is a quality gate checklist, not a rule contract.
- `DECISION_LOG.md` gives historical context, not active rule authority.
- `DEFERRED_DECISIONS.md` tracks open timing, not active rules.
- `EXPERIMENT_BANK.md` is non-authoritative by design.

## Documentation Maintenance Rules

- `HANDOFF.md` is the only rolling current-state file.
- `README.md` should change rarely and remain the stable repo entrypoint.
- `DECISION_LOG.md` is only for accepted project-level decisions.
- `DEFERRED_DECISIONS.md` is only for consciously open topics, not backlog tracking.

Open a new doc only if:
- one topic keeps getting confused repeatedly
- the current ownership of that topic is unclear
- a separate authoritative owner is genuinely required
