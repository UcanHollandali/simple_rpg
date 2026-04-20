# SIMPLE RPG - Implementation Roadmap

## Purpose

This file describes the implementation phase order.
It is a sequencing doc, not a rule authority.
This doc tracks project phasing and rollout order. It is not a rolling status log; HANDOFF.md remains the only rolling current-state file.
If a roadmap step changes a rule, update the owning authority doc first.
When a section becomes mostly dated status or resolved history, move that detail to `HANDOFF.md` or `Docs/Archive/` instead of expanding this file.

## Sequencing Snapshot

This roadmap assumes the playable runtime baseline, save baseline, initial manifest-backed production floor, and first post-baseline mechanic/content expansion wave already exist.
Use `HANDOFF.md` for the current repo snapshot and blockers; this file keeps only the sequencing facts that still shape continuation order.

Historical prerequisites already complete:
- exploration-spine rollout alignment across the active doc set
- first placeholder-shell Figma sync against that settled exploration authority
- first manifest-backed production floor in the playable slice
- first post-baseline mechanic/content expansion wave:
  - seeded `reward_rng` reward generation
  - boss-phase support in combat-local truth
  - expanded combat-local status floor
  - activated `armor` and `belt` runtime/save lanes
  - stage-differentiated map scaffold rotation
  - widened authored weapons, enemies, events, consumables, passives, merchant stocks, and rewards
  - stage-aware live routing for authored minor-enemy pools, boss selection, and merchant stocks

Current continuation order from that baseline:
1. corrective Figma sync only when the placeholder shell drifts from repo truth
2. manifest-backed visual/audio refinement and in-place swaps
3. narrow vertical hardening and integration passes alongside those production passes
4. only then reopen broader selection-policy widening beyond the current stage-aware authored routing, manual feel tuning, or new progression surfaces

Still intentionally open here:
- map graph tuning and broader generation breadth
- broader player-facing acquisition/routing for newer runtime-backed equipment lanes
- broader post-`v1` mechanic expansion timing

## Working Rule

Use this order:
1. keep ownership and scene boundaries stable
2. grow production assets through the manifest
3. expand only narrow, test-backed mechanics
4. reassess before broadening content families or presentation scope

Escalate before continuing if a task requires:
- a new flow state
- a save shape change
- a new command or event family
- a source-of-truth ownership change
- a scene/core boundary break
- a content-only change that quietly becomes a mechanic change

## Active Continuation Tracks

### Track C - Manifest-Backed Visual/Audio Production

Sequence role:
- active continuation track from the current temporary production floor

Start from:
- seeded icon manifest entries
- validator-backed `commercial_status`
- runtime/source/provenance boundary already locked
- Figma truth alignment already updated to the exploration spine
- first temporary manifest-backed floor already live in the playable slice

Focus:
- keep the current temporary floor coherent across bust, background, shared runtime UI component, SFX, music, and icon lanes
- continue from the seeded icon floor into a reviewed prototype icon set
- add later real UI exports from Figma when they are ready
- add later approved prototype bust/token art and in-place swaps where provenance changes
- keep every runtime-bound asset manifest-tracked from day one
- keep runtime-only placeholder coverage truthful as new always-seen UI slots land

Exit:
- the playable slice reads coherently under the temporary production floor and remains ready for in-place swaps
- the asset pipeline stays exercised under actual production load without breaking runtime truth

### Track D - Narrow Vertical Hardening

Sequence role:
- parallel hardening lane alongside corrective sync and Track C work

Focus:
- keep new slices narrow and test-backed
- prevent scene/UI boundary erosion
- prevent command/event naming docs from drifting ahead of runtime
- prevent generic reward/status/content assumptions from sneaking in
- prefer explicit post-integration lanes after mechanic/content growth:
  - `validate_content`
  - `validate_assets`
  - explicit `Tests/test_*.gd` union
  - Godot smoke
  - Windows playtest export

Exit:
- the repo remains understandable after a real production pass
- new asset/content additions do not require architecture cleanup afterward

## Deferred Until After Current Tracks

- broad generic status system
- broad consumable effect routing
- combat save
- meta progression
- custom editor tooling
- large-scale balance automation
- broader authored-to-live selection widening beyond the current stage-aware enemy and merchant routing

## After v1 / Deferred Expansion Direction

This roadmap intentionally stays detailed only through `v1`.
Post-`v1` direction should stay as a lightweight guide until the vertical slice and `v1` content floor are proven.

Use this rule set after the current roadmap completes:
- prefer expanding through current content grammar first:
  - new `Weapons`
  - new `Consumables`
  - new `PassiveItems`
  - new `Rewards`
  - new `Enemies`
- prefer expanding visual/audio production through the existing manifest-backed asset pipeline instead of ad hoc runtime drops
- treat these as architecture-sensitive expansion, not routine content work:
  - new resource axes
  - new slot types
  - new combat verbs
  - new node families
  - broader trigger/effect routing
  - new flow states
  - new command or event families
  - ownership shifts between runtime/application/UI layers
- keep important but not-yet-locked future topics in `DEFERRED_DECISIONS.md`
- keep speculative ideas, archetypes, and mechanic experiments in `EXPERIMENT_BANK.md`
- if post-`v1` direction becomes concrete, write a separate `v1.x` / expansion / `v2` roadmap instead of widening this file into a long-lived wishlist

Practical interpretation:
- the current architecture is meant to make content and asset growth easier inside the existing grammar
- it is not meant to make new mechanic families free
- friction on mechanic-surface expansion is intentional and should remain explicit
