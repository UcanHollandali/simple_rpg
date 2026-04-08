# SIMPLE RPG - Combat Information Model

## Purpose

This file defines what the player should know during combat.

## Main Rule

Combat should be hard because of decision pressure, not hidden information.

The intended player reaction after a loss is:
"I made the wrong call,"
not
"the game hid something important."

## Minimum Visible Information

The first playable version must show:
- player HP
- player hunger
- active weapon
- critical durability state
- player statuses
- enemy name or type
- enemy HP
- enemy current intent
- enemy important statuses
- three core player actions

## Intent Visibility

- the first enemy intent is shown before the player's first turn
- intent shows action family
- intent shows relative threat strength
- optional short side hint is allowed
- full future scripting is not shown

## Trait and Tendency Hints

Short trait hints are allowed when they improve readability.

Examples:
- armored
- heal-prone
- dodge-prone
- crit-resistant

These hints should answer:
"What kind of enemy is this?"
They should not answer:
"What exactly will it do three turns from now?"

## Information Layers

### Primary

Always visible:
- HP
- intent
- actions
- critical statuses
- critical durability warning

### Secondary

Easy-access helper:
- short trait hints
- short item explanations
- short status explanations
- compact combat log

### Tertiary

Optional deeper explanation:
- expanded log
- extra enemy notes

## Combat Log Role

The combat log is a support layer, not the main information channel.

It should help answer:
- what just happened
- why damage or status changed
- why durability dropped

It should not replace:
- intent display
- HP display
- action availability

## Hidden By Default

Do not show by default:
- full resolver internals
- full RNG tables
- full future enemy script
- technical IDs
- hidden weighting tables

## Boss Clarity Rule

Bosses may show clearer threat telegraphs than normal enemies.
They still should not reveal full script order or phase internals by default.
