# SIMPLE RPG

Small-scope, preparation-focused, turn-based roguelite RPG for mobile portrait.

This repository is documentation-routed. The docs are here to make authority, workflow, and current-state routing explicit:
- AI-friendly
- human-maintainable
- content-extensible
- safe to refactor when owner/save/flow boundaries stay intact

## Start Here

`README.md` is intentionally stable and should change rarely.

Use these docs as the repo entry surface:
- [Docs/HANDOFF.md](Docs/HANDOFF.md): current implementation state, active blockers, recommended next step
- [Docs/DOC_PRECEDENCE.md](Docs/DOC_PRECEDENCE.md): topic routing and authority-doc ownership
- [Docs/ROADMAP.md](Docs/ROADMAP.md): active cleanup queue and forward roadmap
- [Docs/TECH_BASELINE.md](Docs/TECH_BASELINE.md): validator commands, Godot runners, platform/tooling rules
- [Docs/WINDOWS_PLAYTEST_BRIEF.md](Docs/WINDOWS_PLAYTEST_BRIEF.md): Windows playtest build brief for shared prototype builds

Fresh-chat shortcut:
- read `Docs/HANDOFF.md` for the current snapshot
- read `Docs/DOC_PRECEDENCE.md` for routing
- then open only the closest authority doc for the task
- treat workflow docs as discipline and routing surfaces, not as a ban on guarded cleanup or helper extraction

Do not treat `README.md` as the rolling status file or as the detailed topic authority.

## Repo Map

- [AGENTS.md](AGENTS.md): repo-level AI operating rules
- [CLAUDE.md](CLAUDE.md): short memory layer for Claude-style agents
- [Docs/](Docs/): mixed authority and reference docs; route by `Docs/DOC_PRECEDENCE.md` instead of treating the whole folder as one authority surface
- [Game/](Game/): layered gameplay/application/runtime code
- [scenes/](scenes/): Godot presentation/composition scenes
- [ContentDefinitions/](ContentDefinitions/): canonical JSON gameplay content
- [Tests/](Tests/): automated regression and smoke checks
- [Tools/](Tools/): validators and Godot helper scripts
- [Assets/](Assets/): runtime-facing visual/audio assets
- [SourceArt/](SourceArt/): source/master visual and audio files
- [AssetManifest/](AssetManifest/): asset provenance and replacement tracking
