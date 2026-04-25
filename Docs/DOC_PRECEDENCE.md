# SIMPLE RPG - Documentation Precedence Rules

## Purpose

This file explains which docs are authoritative for which topics.

## Main Rule

Use the closest authoritative document for the topic.
Do not resolve conflicts by convenience.
Do not infer ownership from convenience accessors exposed on `RunState` or `AppBootstrap`.

## Role-Based Precedence

### Design Authority

- [GDD.md](GDD.md)

### Technical Authority

- [TECH_BASELINE.md](TECH_BASELINE.md)
- [ARCHITECTURE.md](ARCHITECTURE.md)
- [SOURCE_OF_TRUTH.md](SOURCE_OF_TRUTH.md)
- [CONTENT_ARCHITECTURE_SPEC.md](CONTENT_ARCHITECTURE_SPEC.md)
- [COMBAT_RULE_CONTRACT.md](COMBAT_RULE_CONTRACT.md)
- [GAME_FLOW_STATE_MACHINE.md](GAME_FLOW_STATE_MACHINE.md)
- [MAP_CONTRACT.md](MAP_CONTRACT.md)
- [SUPPORT_INTERACTION_CONTRACT.md](SUPPORT_INTERACTION_CONTRACT.md)
- [REWARD_LEVELUP_CONTRACT.md](REWARD_LEVELUP_CONTRACT.md)
- [SAVE_SCHEMA.md](SAVE_SCHEMA.md)
- [TEST_STRATEGY.md](TEST_STRATEGY.md)

### Production Authority

- [VISUAL_AUDIO_STYLE_GUIDE.md](VISUAL_AUDIO_STYLE_GUIDE.md)
- [ASSET_PIPELINE.md](ASSET_PIPELINE.md)
- [ASSET_BACKLOG.md](ASSET_BACKLOG.md)
- [ASSET_LICENSE_POLICY.md](ASSET_LICENSE_POLICY.md)
- [ProductionAssetBriefs/map_asset_external_request_pack.md](ProductionAssetBriefs/map_asset_external_request_pack.md): the single AI-facing map production asset request

### Workflow Authority

- [AGENTS.md](../AGENTS.md)
- [CLAUDE.md](../CLAUDE.md): Claude-specific working memory alias; defers to `AGENTS.md`, not a separate rule source
- [DOC_PRECEDENCE.md](DOC_PRECEDENCE.md): this documentation-routing file
- [HANDOFF.md](HANDOFF.md): current-state snapshot only; not a rule source

### Context and History

- [ROADMAP.md](ROADMAP.md): active short-horizon roadmap and next-lane index; not a rule source
- [PRODUCTION_RISK_REGISTER.md](PRODUCTION_RISK_REGISTER.md): reference-only continuation guardrails for growth risks; non-authoritative
- [COMMAND_EVENT_CATALOG.md](COMMAND_EVENT_CATALOG.md): implemented command/event name reference plus reserved naming registry; non-authoritative
- [CONTENT_BALANCE_TRACKER.md](CONTENT_BALANCE_TRACKER.md): reference-only current content inventory and balance-reading snapshot; subordinate to authority docs and live definitions
- [WINDOWS_PLAYTEST_BRIEF.md](WINDOWS_PLAYTEST_BRIEF.md): playtest launch and feedback brief; not a gameplay authority
- [DECISION_LOG.md](DECISION_LOG.md): historical accepted decisions; not active rule authority
- [DEFERRED_DECISIONS.md](DEFERRED_DECISIONS.md): consciously deferred topics
- [EXPERIMENT_BANK.md](EXPERIMENT_BANK.md): non-authoritative experiment inventory

## Fast Topic Map

| Topic | Authority |
|---|---|
| game identity and scope timing | `GDD.md` |
| project vocabulary | `GDD.md` |
| layer boundaries | `ARCHITECTURE.md` |
| data ownership | `SOURCE_OF_TRUTH.md` |
| ownership vs compatibility-facade interpretation | `SOURCE_OF_TRUTH.md` |
| content schema | `CONTENT_ARCHITECTURE_SPEC.md` |
| combat behavior | `COMBAT_RULE_CONTRACT.md` |
| flow transitions | `GAME_FLOW_STATE_MACHINE.md` |
| map structure | `MAP_CONTRACT.md` |
| support interactions and economy | `SUPPORT_INTERACTION_CONTRACT.md` |
| rewards and level-up flow | `REWARD_LEVELUP_CONTRACT.md` |
| save rules | `SAVE_SCHEMA.md` |
| test expectations | `TEST_STRATEGY.md` |
| implemented command/event names | `COMMAND_EVENT_CATALOG.md` |
| short-horizon roadmap and next-lane state | `ROADMAP.md` |
| visual/audio style | `VISUAL_AUDIO_STYLE_GUIDE.md` |
| asset source-of-truth, folder flow, promotion stages, and runtime approval boundary | `ASSET_PIPELINE.md` |
| first-pass visual/audio backlog and event-to-audio mapping | `ASSET_BACKLOG.md` |
| license, provenance, and AI-assisted asset rules | `ASSET_LICENSE_POLICY.md` |
| map production asset generation request | `ProductionAssetBriefs/map_asset_external_request_pack.md` |

## Important Clarifications

- `README.md` is an entrypoint, not the final rule source.
- `AGENTS.md` and `CLAUDE.md` are workflow files, not gameplay rule contracts.
- `CLAUDE.md` is not an independent rule source. It is a Claude working-memory alias over `AGENTS.md`.
- `HANDOFF.md` is a current-state handoff file, not a rule contract.
- `ROADMAP.md` is the active planning and next-lane file, not a rule contract.
- `HANDOFF.md` should stay a compact snapshot. `ROADMAP.md` should stay focused on the next lane.
- There is no active queued work surface unless `ROADMAP.md` explicitly opens one.
- Do not infer active queue state from stale drafts, future-lane stubs, or reference-only design companions.
- `SOURCE_OF_TRUTH.md` decides runtime ownership questions. `RunState` or `AppBootstrap` convenience access does not override the owner named there.
- `COMMAND_EVENT_CATALOG.md` is a naming/reference file, not the authority for whether a command family or event family should exist.
- `PRODUCTION_RISK_REGISTER.md` is a reference-only continuation guardrail, not a rule contract or current-state source.
- `ASSET_BACKLOG.md` is an execution backlog, not a style or licensing authority.
- Every active root `Docs/*.md` file must be routed by this document.

## Documentation Maintenance Rules

- `HANDOFF.md` is the only rolling current-state file.
- `HANDOFF.md` should be rewritten as the current state changes; resolved items should be removed or replaced instead of accumulated.
- `README.md` should change rarely and remain the stable repo entrypoint.
- validator commands, Godot runners, and platform/tooling notes should stay in the closest authority doc, typically `TECH_BASELINE.md`, not in `README.md`.
- `ROADMAP.md` should stay focused on the next lane and near phases.
- `DECISION_LOG.md` is only for accepted project-level decisions.
- `DEFERRED_DECISIONS.md` is only for consciously open topics, not backlog tracking.

## Daily Production Working Set

Use these files actively during normal visual/audio production:
- `HANDOFF.md`
- `VISUAL_AUDIO_STYLE_GUIDE.md`
- `ASSET_BACKLOG.md`
- `ASSET_PIPELINE.md`
- `ASSET_LICENSE_POLICY.md`
- `ProductionAssetBriefs/map_asset_external_request_pack.md`
- `AssetManifest/asset_manifest.csv`

Open a new doc only if:
- one topic keeps getting confused repeatedly
- the current ownership of that topic is unclear
- a separate authoritative owner is genuinely required

## Reference Doc Retention Rule

Reference-only docs are allowed to stay in the repo only if they do at least one useful job:
- prevent the same confusion from repeating
- give a reusable checklist for repeated work
- capture a cross-cutting rule that does not fit cleanly in a closer authority doc

Do not promote reference docs into daily required reading by default.
Do not keep them just because they already exist.

Retire, merge, or delete a reference-only doc if:
- it duplicates a closer authority file
- nobody needs it during normal work
- its checklist has become obvious and stable enough to live elsewhere
- it creates more reading cost than decision clarity
