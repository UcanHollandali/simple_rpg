# SIMPLE RPG - Glossary

## Purpose

This file locks the project's preferred technical vocabulary.

## Preferred Terms

- `Run` -> one play attempt from start to fail/finish
- `Stage` -> a major chunk within a run
- `Map` -> the full route and node structure of a stage
- `Node` -> a content-bearing map point
- `Segment` -> path between nodes
- `Route` -> the player's chosen path
- `Combat` -> turn-based encounter with rules and resolution
- `Intent` -> visible preview of enemy action family
- `Definition` -> static design data
- `Runtime State` -> live gameplay truth
- `Instance` -> concrete spawned version of a definition
- `Stable ID` -> permanent technical identifier
- `Display Name` -> player-facing name

## Non-Preferred or Secondary Terms

- `Battle` -> acceptable conversational synonym, but technical docs prefer `Combat`
- `POI` -> acceptable shorthand, but technical docs prefer `Node`
- `Domain` -> acceptable architecture word, but technical docs prefer `Core`
- `Proc` -> conversational only; not a primary schema term

## Important Distinctions

- `Definition` is not `Runtime State`
- `Trait` is not `Status`
- `Effect` is not `Trigger`
- `Loot` is not all `Reward`
- `View Data` is not authoritative truth

## Naming Rule

If a new term is introduced:
- it must add a real new concept
- it must not silently rename an existing concept
