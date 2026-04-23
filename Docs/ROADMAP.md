# SIMPLE RPG - Active Roadmap

Last updated: 2026-04-23 (Prompt `36` is closed green; Prompt `21-36` combat/content wave is now closed for the current prototype scope)

This is the single active roadmap and queue index for the repo.
It is a planning file, not an authority doc.
Prompt packs may guide execution, but authority still lives where `Docs/DOC_PRECEDENCE.md` says it lives.
Use this file for the active prompt-wave order and open/closed state; do not infer that state from prompt packs or design companions.

## Measured Current State

- The repo is prototype-playable per `Docs/HANDOFF.md`.
- Prompt `14-20` is now closed green on this workspace snapshot as the guarded fixed-board map-overhaul wave.
- Prompt `21-36` are now closed green on this workspace snapshot as the combat/content queue reset, the first executable combat slice, the technique MVP, the narrow hand-slot swap runtime surface, the advanced-enemy-intent escalation spec, the trainer-node necessity/deferral audit, the first technical checkpoint/handoff gate, the combat mechanic UI audit, the onboarding refresh, the post-wave balance checkpoint, and the final integrated review/audit/playtest/screenshot closeout.
- No further prompt is queued inside the `21-36` combat/content wave; any new continuation now needs a separate approved wave or an explicit deferred/escalation lane.
- No active execution pack currently remains under `Docs/Promts/`.
- The fully applied Prompt `06-36` pack set is now archived under `Docs/Archive/Prompts/2026-04-23-closed-green-prompt-packs/`.
- Runtime/save/flow boundary decisions remain stable:
  - canonical pending-node owner: `MapRuntimeState`
  - live `NodeResolve` generic fallback stays until an explicit flow audit approves removal
  - existing `/root/AppBootstrap` usage may shrink only when owner meaning and live flow behavior stay unchanged
- Prompt `15` landed the runtime procedural-grammar reset:
  - explicit stage-local blueprint choice before board placement
  - deterministic rooted abstract graph generation inside `MapRuntimeState`
  - bounded/local reconnect rules instead of long-span rescue edges
  - realized-graph save payload shape preserved
- Prompt `16` landed the family placement / pacing reset:
  - topology-aware constrained placement runs after topology generation
  - exact family quotas and the early combat/reward/support floor stay intact
  - key/boss remain late-pressure placements
  - event/hamlet/support remain readable route decisions without widening save or flow contracts
- Prompt `17` landed the fixed-board presentation reset:
  - fixed board / fixed camera is now the desired default traversal model
  - the walker moves on the board instead of moving the board under the walker
  - playable rect, node safe margins, and path-safe bounds are explicit
  - route-follow / recenter behavior is retired as the default traversal presentation
  - save, flow, and graph-truth ownership boundaries stayed unchanged
- Current map direction is explicitly:
  - template-driven procedural grammar
  - constrained family placement
  - fixed board / no follow
  - walker on board
  - world fill after structure
  - manifest-tracked map-only asset/filler hookup after structure is green
  - temporary/prototype map assets stay truthful and replace-before-release when required
- Prompt `20` closeout also landed narrow corrective review fixes without reopening scope:
  - textured filler / canopy clearance now matches the stamped draw footprint instead of the smaller abstract placement footprint
  - node-resolve now uses the dedicated map `combat`, `key`, and `boss` icon lane for map-flow consistency
  - save shape, flow state, and owner meaning stayed unchanged
- The next combat/content wave is no longer left as generic future drift:
  - Prompt `22` and Prompt `25` are low-risk visibility passes if they stay presentation-only
  - Prompt `23`, `24`, `27`, and `29` are guarded runtime/content passes
  - Prompt `26`, `28`, `30`, and `31` are explicit `escalate first` docs/spec gates
- Prompt `32-36` are now closed checkpoint, UI-follow-through, onboarding, playtest, and final-audit packs
- The first technical tranche that actually shipped is now explicit:
  - Prompt `22` threat readability follow-up
  - Prompt `23` defend tempo/hunger pass
  - Prompt `24` enemy pattern pack A
  - Prompt `25` quest update surface
  - Prompt `27` technique runtime MVP
  - Prompt `29` hand-slot swap runtime surface
- Prompt `32` closed that first technical tranche with narrow corrective fixes only:
  - post-swap combat truth now follows the actually equipped right-hand weapon
  - open `hamlet` training choices no longer persist as future revisit offers on `leave`
  - combat inventory card hints no longer imply a blanket global equipment lock once hand-slot swap is live
- The allowed first executable combat/content wave is explicitly limited to:
  - threat readability follow-up
  - defend rebalance with tempo/hunger cost
  - enemy pattern variety inside the current sequential-intent grammar
  - quest/update follow-up visibility where it stays presentation-only
- The following items remain explicitly deferred behind escalation-first packs:
  - dedicated trainer node family
  - persistent top-level skill bar
  - true multi-hit
  - enemy self-buff / self-guard / armor-up runtime
  - stage-count increase
- Prompt `30` now closes the spec-only half of advanced enemy intents:
  - Prompt `24` still stayed inside the current sequential grammar
  - no advanced enemy-intent runtime is live
  - implementation remains deferred until a later approved runtime wave opens on top of the Prompt `30` spec

## Archived Summary

- Prompt `01-03`: foundation, guarded cleanup, and first extraction wave are closed green and archived.
- Prompt `04-05`: the code-first map renderer and layout-regression wave are closed green and archived.
- Prompt `06-12.5`: the UI overhaul wave is closed green on this workspace and its prompt packs are archived.
- Prompt `13`: map visual world ownership is closed green; `MapBoardGroundBuilder` and `MapBoardFillerBuilder` live inside the existing composer chain with procedural fallbacks only, and the prompt pack is archived.

## Archived Prompt Pack Index

No active prompt queue is open on this snapshot.
The closed Prompt `14-36` chain is historical only; the detailed packs live under `Docs/Archive/Prompts/2026-04-23-closed-green-prompt-packs/`.

- Prompt `14-20`: closed green fixed-board map-overhaul wave.
- Prompt `21`: closed green docs-only combat/content queue reset.
- Prompt `22-25`, `27`, `29`: closed green shipped runtime/UI slice for combat/content.
- Prompt `26`, `28`, `30`, `31`: closed green docs-only escalation/spec gates.
- Prompt `32-36`: closed green checkpoint, UI follow-through, onboarding, playtest, and final audit closeout.

## Near Phases

- Phase `D` - Playtest and Telemetry
  Still a near phase, but the Prompt `21-36` combat/content wave is now closed; any new combat playtest work needs a new approved continuation lane.
- Phase `E` - Balance and Content Tuning
  Broader combat/content tuning remains a future lane, not an already-reopened Prompt `21-36` queue.
- Phase `F` - Broader Asset Wave
  Expand beyond the map-only asset lane only after Prompt `14-20` are green and the approval/manifest gates remain satisfied.
- Phase `G` - Expansion
  Open broader feature/content work only after Phases `D-F` are green.
