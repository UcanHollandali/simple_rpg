# SIMPLE RPG - Figma Truth Alignment Reference

## Purpose

This file is a reference-only Figma correction bridge for the current runtime-backed placeholder UI shell.

It is:
- a historical execution brief kept for corrective sync when the placeholder Figma shell drifts from repo truth
- a bridge from active gameplay, architecture, and production docs into Figma work
- subordinate to the real gameplay, architecture, and production authority docs

It is not:
- part of the active authority set
- a default continuation-reading file
- a gameplay rule source
- a gate before manifest-backed production continuation
- a license to invent new mechanics
- a final art brief

Use it with:
- `Docs/GDD.md`
- `Docs/MAP_CONTRACT.md`
- `Docs/REWARD_LEVELUP_CONTRACT.md`
- `Docs/SUPPORT_INTERACTION_CONTRACT.md`
- `Docs/VISUAL_AUDIO_STYLE_GUIDE.md`
- `Docs/ASSET_PIPELINE.md`
- `Docs/HANDOFF.md`

Open this doc only when the task is:
- doing corrective Figma sync against already-implemented runtime truth
- exporting or re-exporting runtime UI placeholder assets from Figma
- reconciling an older Figma shell with the current repo truth

If the active authority docs already answer the question, those docs win and this file does not need to be reopened.

## Reference Scope

When using this bridge:
- truth-align `combat`, `reward`, and `map` placeholder screens to the current runtime-backed flow
- keep the layout portrait-first
- define only the reusable component shells needed by those screens
- keep `support` as one reusable shell for `rest`, `merchant`, and `blacksmith`

Do not do in this pass:
- final art
- final iconography
- texture polish
- loot-drop fantasy cards
- new gameplay verbs
- new gameplay information not already backed by runtime truth

## Locked Runtime Truth

### Run Spine

- The game is preparation-first and exploration-first.
- A run contains exactly `3` stages.
- Each stage starts from a central map anchor inside a bounded cluster map.
- Movement is adjacency-based.
- Partial fog is part of the read.
- Revisit is allowed, but revisit must not reopen resolved value for farming.
- Each stage contains one stage-local `key` and one boss gate.

### Combat Floor

- Combat is a visible decision layer, not the game's main identity.
- Visible combat actions remain:
  - `Attack`
  - `Defend`
  - `Use Item`
- The combat screen must expose:
  - player HP
  - hunger
  - active weapon
  - critical durability
  - player status row
  - enemy name and type framing
  - enemy HP
  - enemy intent
  - enemy important statuses only when they matter

### Reward Floor

- `Reward` is its own flow state.
- Combat victory enters `Reward` before returning to free exploration.
- Reward is a generic authored choice screen, not an item-drop reveal.
- Current reward truth:
  - combat reward: `3` offers, choose `1`
  - reward node: `2` offers, choose `1`
- Current reward families:
  - `heal`
  - `repair_weapon`
  - `grant_xp`
  - `grant_gold`
  - `grant_item`

### Map Floor

- Node families currently used by the runtime are:
  - `start`
  - `combat`
  - `event`
  - `reward`
  - `hamlet`
  - `rest`
  - `merchant`
  - `blacksmith`
  - `key`
  - `boss`
- The map screen must read:
  - center-start bounded exploration
  - local adjacency-based movement
  - partial fog
  - discovered versus unresolved versus resolved readability
  - current node emphasis
  - reachable adjacent node emphasis
  - event-node readability alongside the existing combat/reward/support/key/boss families
  - stage key marker
  - locked versus unlocked boss gate state

### Support Floor

- Current support families:
  - `rest`
  - `merchant`
  - `blacksmith`
  - `hamlet`
- `rest` and `blacksmith` are one-shot interactions.
- `merchant` is a repeated-buy visit until the player leaves or offers are exhausted.

## Screen Guidance

### Combat

Goal:
- make attrition pressure readable first
- keep enemy intent above the decision point
- keep the bottom action bar compact and stable

Recommended portrait structure:
1. top run strip
2. enemy card
3. player attrition panel
4. player status row
5. optional enemy status row
6. compact combat log area
7. fixed bottom action bar

Rules:
- enemy intent must stay near the enemy card, not buried in the log
- the combat log is secondary, never the main information model
- the bottom action bar always shows exactly three primary action buttons

### Reward

Goal:
- keep reward generic
- remove item-drop expectation
- make `choose 1` the main read

Recommended portrait structure:
1. header
2. compact run-state strip
3. vertically stacked `choice_card` list

Rules:
- do not mock named loot like `Rusty Sword` unless runtime truth actually supports it
- keep cards systemic and reusable
- combat reward and reward-node reward use the same shell with different counts

### Map

Goal:
- show a real center-start exploration board, not a route ladder
- make local traversal and fog readability clear in portrait

Recommended portrait structure:
1. top run strip
2. stage header
3. cluster map shell
4. compact legend row
5. current node and reachable-node emphasis

Rules:
- draw nearby neighborhoods, spokes, or short branches around the center
- do not imply full-board certainty
- `undiscovered`, `discovered`, `resolved`, and `locked` need one consistent visual grammar
- current node gets the strongest emphasis
- reachable adjacent nodes get the second-strongest emphasis

### Support

Goal:
- keep support visually real
- avoid collapsing support into a throwaway modal

Shared portrait shell:
1. support title
2. short summary panel
3. compact run-state strip
4. action card stack
5. leave action

Rules:
- `rest` and `blacksmith` each show one primary action plus leave
- `merchant` keeps the same shell but with a small offer stack
- spacing and CTA language should feel like the same non-combat UI family as `Reward`

## Reusable Component Floor

Build only the smallest reusable set needed for this pass:
- `status_chip`
- `choice_card`
- `node_badge`
- `node_state_marker`
- `key_marker`
- `boss_gate_marker`
- `support_action_card`
- `item_slot_shell`
- `bar_system`

Component notes:
- `node_state_marker` uses gameplay states only for:
  - `undiscovered`
  - `discovered`
  - `resolved`
  - `locked`
- `current` and `adjacent_reachable` are presentation emphasis variants, not new gameplay states
- `item_slot_shell` is a reusable shell, not permission to turn reward into an item-drop screen

## Fixed Vs Flexible

### Fixed

- portrait-first layout direction
- combat action count and labels
- combat information floor
- reward as generic authored choice
- combat reward `3 -> choose 1`
- reward node `2 -> choose 1`
- support families
- center-start cluster map shell
- partial fog
- current node and reachable adjacent node emphasis
- key marker read
- locked versus unlocked boss gate read
- placeholder-only output for this pass

### Flexible

- exact spacing and panel heights
- enemy type as badge versus subtitle
- exact graph silhouette and spoke count
- whether the combat log is collapsed or simply de-emphasized
- whether support uses stacked cards or card-like button rows

## Done Criteria

Before calling this pass done:
- `combat` exposes the required runtime-backed information and no extra mechanic surface
- `reward` reads as a reusable `choice_card` screen, not a loot fantasy screen
- `map` reads as bounded exploration with fog and local traversal, not as a ladder or loose button grid
- `support` reuses one shell for `rest`, `merchant`, and `blacksmith`
- exported runtime assets follow `Docs/ASSET_PIPELINE.md` promotion and manifest rules
