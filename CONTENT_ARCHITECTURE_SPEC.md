# SIMPLE RPG - Content Architecture Specification

## Purpose

This file defines the canonical format and growth rules for gameplay content.

## Core Principle

Most new content should be added by new data, not new special-case code.

## Canonical Format

- Canonical gameplay content lives in `JSON`
- Path: `ContentDefinitions/<family>/<stable_id>.json`
- One definition per file
- One stable ID per file

## Supported Families

- `Weapons`
- `Armors`
- `Belts`
- `Consumables`
- `PassiveItems`
- `Enemies`
- `Statuses`
- `Effects`
- `Rewards`
- `RouteConditions`
- `EventTemplates`

## Required Top-Level Fields

- `schema_version`
- `definition_id`
- `family`
- `tags`
- `display`
- `rules`

## Naming Rules

- `definition_id` uses `lower_snake_case`
- display name is separate from stable ID
- logic never depends on display text

## Display vs Rules

`display` may contain:
- name
- short description
- icon key
- presentation labels

`rules` may contain:
- stats
- triggers
- conditions
- targets
- effects
- timing
- family-specific behavior blocks

## Common Grammar

The reusable rule grammar is:
- `trigger`
- `condition`
- `target`
- `effect`

Optional family-specific helpers:
- `trait`
- `pattern`
- `modifier_profile`

## Definition vs Instance

Definitions do not contain:
- current HP
- current durability
- active stacks
- current intent
- current owner slot

Those belong to runtime state.

## Tag Policy

- tags are controlled vocabulary
- tags are not a substitute for real mechanics
- tags should stay finite and reviewable

## Validation Expectations

Every content file must support checks for:
- duplicate ID
- missing reference
- invalid family
- invalid tag
- invalid trigger/effect/target
- missing required fields
