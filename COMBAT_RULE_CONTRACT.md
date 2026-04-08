# SIMPLE RPG - Combat Rule Contract

## Purpose

This file defines the official combat rules and timing.

## Combat Identity

- single-target
- turn-based
- intent-visible
- minimal action set
- attrition-aware

## Player Actions

- `Attack`
- `Brace`
- `Use Item`

## Turn Order

1. Turn Start Effects
2. Conditional or Threshold Checks
3. Player Action Selection
4. Player Action Resolve
5. Enemy Defeat Check
6. Enemy Action Resolve
7. Player Defeat Check
8. Turn End Effects
9. Status Cleanup
10. Combat Hunger Tick
11. Next Intent Preparation

Combat hunger officially resolves at `turn_end`.

## Intent Rule

- first intent is shown before the first player choice
- current intent is meaningful, not cosmetic
- next intent is prepared only after the current turn resolves

## Durability Rule

- a valid attack attempt that starts resolving consumes durability
- dodge or miss does not refund durability
- durability behavior must be deterministic

## Dodge Rule

- dodge must be telegraphed
- dodge must be explainable to the player
- dodge does not cancel the fact that the attack attempt happened

## Fallback Attack Rule

If the active weapon breaks:
- the player does not become unable to act
- the player falls back to a weak default attack
- fallback is intentionally inferior to a proper weapon

## Simultaneous Death Priority

If edge cases produce simultaneous lethal outcomes:
- enemy defeat is checked after player action resolve
- player defeat is checked after enemy action resolve
- exact simultaneous-death resolution must follow this ordering, not ad-hoc scene logic

## Invalid States That Must Not Be Silent

- dead enemy resolving action
- negative durability
- invalid target damage application
- duplicate authoritative intent
- negative status duration
