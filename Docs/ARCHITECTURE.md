# SIMPLE RPG - Architecture

## Purpose

This file defines the project's layer boundaries and dependency rules.

## Architecture Principles

- command-driven flow
- single source of truth
- definition/runtime separation
- data-driven content where possible
- deterministic rule resolution
- engine-light core logic

## Layers

- `Game/Core`
- `Game/Application`
- `Game/RuntimeState`
- `Game/Infrastructure`
- `Game/UI`
- `scenes/`
- `ContentDefinitions`
- `Tests`
- `Tools`

## Dependency Direction

- UI -> Application
- Application -> Core
- Application -> RuntimeState
- Application -> ContentDefinitions
- Infrastructure -> Application/Core support
- scenes/ -> UI/Application wiring

Core must not depend on:
- scene tree composition
- presentation widgets
- display strings
- engine-facing singleton gameplay state

## Allowed Artifacts By Layer

| Layer | Allowed artifacts |
|---|---|
| `Game/Core` | resolvers, rule evaluators, validators, rule-side pure helpers |
| `Game/Application` | commands, flow orchestration, state transitions, event dispatch coordination |
| `Game/RuntimeState` | run, combat, map, inventory, reward, support, and level state models |
| `Game/Infrastructure` | save/load, config, routing, input adapters, file IO |
| `Game/UI` | view models, presenters, UI command emitters |
| `scenes/` | composition, visual structure, presentation wiring |
| `ContentDefinitions` | canonical JSON content files |

UI layer decision:
- `Game/UI` is a real current layer, not a deferred target.
- `scenes/` are not the project's prototype presenter layer.
- If presentation text assembly, button-state shaping, or screen-specific view models start growing beyond trivial wiring, that logic should move into `Game/UI`.

## Godot Scene Rule

- Scene files are presentation/composition assets.
- Scene scripts may translate input or render state.
- Scene scripts must not become the hidden owner of combat, inventory, reward, or save truth.
- Prototype loop mutations should route through a narrow Application-owned surface, not direct `RunState` writes from scenes.

## RunState Compatibility Facade Rule

- Current repo reality still includes limited compatibility-focused test reads plus save/load compatibility mirrors through `RunState` compatibility accessors.
- Treat that surface as transitional compatibility, not as a permanent owner-facing API.
- Runtime scene/UI/test code should prefer the real owner state (`MapRuntimeState`, `InventoryState`, pending-choice owners) or a narrow Application-owned surface when that owner already exists.
- Do not add new gameplay fields or new long-lived dependencies behind the `RunState` compatibility facade just for convenience.
- `Tools/validate_architecture_guards.py` is the current narrow automation floor for keeping `dispatch()`, runtime-side `RunState` compatibility creep, test-side inventory compatibility creep, and scene/UI direct gameplay-truth mutation creep from quietly returning.
- The same guard also blocks new runtime-side `current_node_index` spread outside explicit compatibility files.

## Signal Policy

- Signals are allowed for UI and presentation coordination.
- Signals must not be used as a substitute for explicit command and state contracts.
- Critical gameplay flow should stay understandable without tracing arbitrary signal chains.

## Autoload Policy

Allowed autoloads registered in `project.godot`:
- `AppBootstrap`
- `SceneRouter`

Infrastructure/service owners that are not autoloads:
- `SaveService` remains a `Game/Infrastructure` service owner and should stay documented as service wiring, not as an autoload.

Disallowed as gameplay owners:
- combat truth
- inventory truth
- reward truth
- enemy truth

## Preferred Runtime Pattern

`UI/Input -> Command -> Application -> Core Resolve -> Runtime State Update -> Domain Events -> UI Refresh`

Current prototype note:
- formal command classes are not complete yet; the only implemented formal command-style path is `GameFlowManager.request_transition`
- for current implemented runtime owners and their scope, see `Docs/SOURCE_OF_TRUTH.md` Ownership Table
- for current command/event surface, see `Docs/COMMAND_EVENT_CATALOG.md`
