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
- `Scenes`
- `ContentDefinitions`
- `Tests`
- `Tools`

## Dependency Direction

- UI -> Application
- Application -> Core
- Application -> RuntimeState
- Application -> ContentDefinitions
- Infrastructure -> Application/Core support
- Scenes -> UI/Application wiring

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
| `Game/RuntimeState` | run/map/combat/inventory/reward state models |
| `Game/Infrastructure` | save/load, config, routing, input adapters, file IO |
| `Game/UI` | view models, presenters, UI command emitters |
| `Scenes` | composition, visual structure, presentation wiring |
| `ContentDefinitions` | canonical JSON content files |

## Godot Scene Rule

- Scene files are presentation/composition assets.
- Scene scripts may translate input or render state.
- Scene scripts must not become the hidden owner of combat, inventory, reward, or save truth.

## Signal Policy

- Signals are allowed for UI and presentation coordination.
- Signals must not be used as a substitute for explicit command and state contracts.
- Critical gameplay flow should stay understandable without tracing arbitrary signal chains.

## Autoload Policy

Allowed autoloads:
- `AppBootstrap`
- `SceneRouter`
- `SaveService`
- `ConfigService`

Disallowed as gameplay owners:
- combat truth
- inventory truth
- reward truth
- enemy truth

## Preferred Runtime Pattern

`UI/Input -> Command -> Application -> Core Resolve -> Runtime State Update -> Domain Events -> UI Refresh`
