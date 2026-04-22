# UI Microcopy Audit

Reference-only planning document for Prompt 06.5 Part A.

## 1. Status

- Date: 2026-04-22
- Prompt state: Prompt 06 is already closed green on this workspace. Prompt 06.5 Part A is satisfied by this document only.
- Output type: reference-only audit and follow-up planning
- Change type: docs only
- Live strings changed in this pass: none
- Code changed in this pass: none

## 2. Scope And Current Direction

This audit covers current player-facing wording across:

- map route and node surfaces
- event modal titles, body text, choice labels, and current disabled-reason support
- combat action labels, hints, guard feedback labels, and status readouts
- inventory and equipment labels, slot names, usability text, and overflow messaging
- stage transition and run-end shell copy
- warnings, toasts, and currently visible empty or error strings

Direction for the later UI wave:

- Reuse existing runtime truth. Do not invent new gameplay explanation text.
- Keep decision-time wording short, readable, and actionable.
- Let atmospheric tone live mostly in headings, chips, and shell framing.
- Improve clarity by presentation and wording first, not by new gameplay math or new derived state.

Repo-truth basis for this audit:

- `Game/UI/map_explore_presenter.gd`
- `Game/UI/event_presenter.gd`
- `Game/UI/combat_presenter.gd`
- `Game/UI/inventory_presenter.gd`
- `Game/UI/inventory_overflow_prompt.gd`
- `Game/UI/stage_transition_presenter.gd`
- `Game/UI/run_status_strip.gd`
- `Game/UI/run_menu_scene_helper.gd`
- `Game/UI/support_interaction_presenter.gd`
- `Game/UI/reward_presenter.gd`
- `scenes/run_end.gd`
- `Docs/UI_INFORMATION_ARCHITECTURE_AUDIT.md`
- `Docs/VISUAL_AUDIO_STYLE_GUIDE.md`

## 3. Tone Baseline

Current tone baseline, grounded in the checked-in style guide:

- readability first
- short action-first copy at decision points
- decorative flavor allowed in shell headings, not in dense gameplay text
- `Inter` remains the safe body-copy baseline; decorative typography should not carry critical decision text

Current strengths to keep:

- short slot labels such as `RIGHT HAND`, `LEFT HAND`, `ARMOR`, `BELT`
- blunt state labels such as `Backpack Full`, `Open Slot`, `Run saved.`, `Save failed: %s`
- direct combat nouns such as `HP`, `Hunger`, `Durability`, `Guard`
- shell framing that adds tone without hiding the next step, especially `GATE REACHED` and `ROAD CLOSED`

Current tone drift to fix later:

- hover-first phrasing in a portrait/mobile-forward UI, especially `Hover for details.`
- mixed interaction verbs such as `Click`, `Tap`, `Choose`, `Take`, `Pack`, `Risk`, `Settle`
- route language that shifts between `route`, `path`, `road`, `stop`, and `ahead` without a stable hierarchy
- some helper lines that compress too much information into one sentence and become mechanically correct but harder to scan

## 4. Surface Inventory

| Surface | Current examples from repo truth | Current read | Problem classification |
|---|---|---|---|
| Map header and progress strip | `Stage %d`, `Open Routes %d | Seen %d | Cleared %d`, `At %s` | Core facts are present and compact. | `clear and keep`, `unclear but fixable with wording only` |
| Map node buttons and chips | `Open Route`, `Seen Path`, `Seen Lock`, `Need Key`, `Locked`, `Cleared`, `KEY`, `LOCK`, `CLEAR`, `OPEN` | Functional, but the label family mixes route-state words and can feel inconsistent. | `unclear but fixable with wording only`, `duplicate phrasing` |
| Map focus panel and node hints | `Current Stop`, `Route Ahead`, `Need key first`, `Locked for now`, `Fight here to move on.`, `Recover HP or hunger.` | Mostly useful and grounded in truth. Some hints are crisp; some feel like mixed terminology. | `clear and keep`, `tone mismatch`, `duplicate phrasing` |
| Inventory pressure on map | `Carry %d/%d` plus weapon summary | Correct and short. Useful as a pressure read. | `clear and keep` |
| Event shell framing | `ROADSIDE ENCOUNTER`, `Event unavailable.`, `Roadside stop. Resolve it and move on.`, `Pick 1 result.`, `Hover for details.` | The framing works, but the hint line drifts toward desktop hover language and the fallback shell is generic. | `unclear but fixable with wording only`, `tone mismatch` |
| Event choice buttons and reward labels | `Choose Recovery`, `Take the Windfall`, `Take the Insight`, `Settle Hunger`, `Risk the Encounter`, `Pack the Find` | The buttons are expressive, but the verb family is inconsistent and comparison-first reading is weak. | `unclear but fixable with wording only`, `duplicate phrasing`, `tone mismatch` |
| Event detail lines | `Recover %d HP.`, `Gain %d gold.`, `Gain %d XP.`, `Restore %d hunger.`, `Take %d damage.` | Short, concrete, and grounded in live truth. | `clear and keep` |
| Combat action labels and tooltips | `Attack`, `Defend`, `Use a consumable card. Only HP or hunger items work.`, `Attack. Costs durability. Broken weapons hit for 1.` | Mechanically clear, but some helper copy is longer than it needs to be for a hot loop. | `clear and keep`, `too long / too noisy` |
| Combat guard and status feedback | `Guard: %d`, `Defend raised %d guard.`, `Guard absorbed %d damage.`, `Guard absorbed %d damage. %d still reached HP.` | Good truth surface. Wording is correct, but the family could be normalized for faster scanning. | `clear and keep`, `duplicate phrasing`, `too long / too noisy` |
| Combat item-state text | `No usable item.`, `%s won't trigger now. Only HP or hunger items work.`, `Select a consumable card below.` | Useful truth exists, but the reason language is split across tooltip, hint, and log. | `unclear but fixable with wording only`, `too long / too noisy` |
| Equipment and backpack labels | `Equipment`, `Backpack X/Y`, `Open Slot`, `Equip weapon.`, `Equip shield or offhand.`, `Equip belt for pack space.` | Strong baseline. Slot identity is explicit and worth preserving. | `clear and keep` |
| Equipment and backpack helper hints | `Tap a slot to equip or unequip...`, `Only consumables work in combat.`, `Click in combat to use now. This ends your turn.` | Helpful but mixed-input wording and some long helper lines reduce polish. | `unclear but fixable with wording only`, `too long / too noisy`, `tone mismatch` |
| Overflow prompt | `Backpack Full`, `Choose one backpack item to discard for %s, or leave it behind.`, `Leave Item`, `Keep Equipped` | Clear, concrete, and decision-oriented. Good shared baseline for later polishing. | `clear and keep` |
| Stage transition shell | `STAGE %d CLEAR`, `Find the key. Beat the boss.`, personality summaries such as `Hard contracts. Rougher pay.` | Good shell tone. Objective line is short and useful. | `clear and keep` |
| Run-end shell | `Gate Reached`, `Journey's End`, `Return to Main Menu`, `Back to menu when ready.` | Stable, readable ending shell copy. | `clear and keep` |
| Warnings and status toasts | hunger threshold warnings, `Run saved.`, `Save failed: %s`, `Load failed: %s` | Save/load messaging is strong. Hunger warning text should be handled carefully because shell encoding artifacts were observed during inspection. | `clear and keep`, `unclear but fixable with wording only` |
| Shared unavailable and empty fallbacks | `Reward unavailable.`, `Support unavailable.`, `No Item`, `Nothing left here.`, `Back to Services`, `Back to the Road` | Useful baseline, but the family is not yet fully standardized across surfaces. | `clear and keep`, `duplicate phrasing` |

Top microcopy problem categories from the current audit:

- missing disabled reason on some decision surfaces
- mixed interaction verbs and mixed input vocabulary
- hover-first copy on a mobile-forward surface set
- short but inconsistent route and node terminology
- helper text that is correct but too noisy for repeated use

## 5. Disabled-Reason Audit

Current benchmark surfaces:

- Support interaction already exposes meaningful unavailable text such as `Sold out`, `Spent`, `No valid target.`, `Request already active.`, and `Already settled.`
- Equipment and inventory already expose useful local blockers such as `Locked during combat`, `Requires equipped shield`, `No HP or hunger gain right now`, and `Free %d backpack slot%s before unequipping that belt.`

Disabled-reason inventory:

| Surface | Current state | Audit read | Classification |
|---|---|---|---|
| Boss route lock on map | `Need Key`, `Need key first`, `Boss lane locked. Need key.` | Strong existing reason signal. Keep the truth; later normalize the wording family only. | `clear and keep` |
| Generic locked route on map | `Locked`, `Locked for now`, `Seen Lock` | The player can tell the route is blocked, but the reason is not very legible or specific. | `unclear but fixable with wording only` |
| Event choices | No disabled state or disabled-reason model is exposed in the current event presenter | This is the largest wording gap in the audited UI wave. The surface cannot currently explain unavailability because the reason is not modeled there. | `missing disabled reason` |
| Combat equipment actions | `Equipment is locked during combat.`, `Locked during combat` | Good local reason truth. Later passes should collapse duplicate phrasings into one family. | `clear and keep`, `duplicate phrasing` |
| Combat consumable unusable state | `%s ready, but it needs missing HP or hunger.`, `%s won't trigger now. Only HP or hunger items work.`, `No usable item.` | The reason exists, but it is spread across multiple message shapes instead of one local explanation pattern. | `unclear but fixable with wording only` |
| Shield-mod attachment | `Requires equipped shield` | Clear and specific. Keep as the benchmark for item dependency blockers. | `clear and keep` |
| Belt unequip overflow block | `Free %d backpack slot%s before unequipping that belt.` | Strong blocker reason. It explains both the constraint and the immediate fix. | `clear and keep` |

Top disabled-reason gaps:

- event choices have no current disabled-reason surface
- generic locked-route wording is thinner than the boss-key route wording
- combat consumable and action-blocker copy is fragmented across tooltip, hint, and feedback text instead of staying local to the blocked action

## 6. Empty / Loading / Error Surface Inventory

| Surface family | Current examples | Audit read | Classification |
|---|---|---|---|
| Unavailable shells | `Event unavailable.`, `Reward unavailable.`, `Support unavailable.` | Stable fallbacks. Later cleanup should standardize the supporting subcopy pattern. | `clear and keep` |
| Empty equipment and backpack states | `Open Slot`, `No Item`, `Open backpack slot.` | Clear and compact. Good baseline. | `clear and keep` |
| Depleted local state | `Nothing left here.` | Useful, short local closure copy. | `clear and keep` |
| Overflow prompt | `Backpack Full`, discard-or-leave context line | One of the stronger empty-or-limit surfaces in the current build. | `clear and keep` |
| Save/load status | `Run saved.`, `Save failed: %s`, `Load failed: %s` | Clear and operationally useful. | `clear and keep` |
| Combat boot/idle shell | `Combat ready.` | Correct but low-information. This is a candidate for later polishing, not a current blocker. | `unclear but fixable with wording only` |
| Hunger threshold warning | current hunger warning toast text is shared between map and combat | Important shared warning surface. Wording should be treated in the later wave without assuming shell mojibake reflects a checked-in copy bug. | `unclear but fixable with wording only` |
| Loading surfaces | No dedicated player-facing loading string was confirmed in the audited UI set | There is nothing to rewrite yet; if a later pass adds loading states, wording should stay brief and functional. | `needs future logic support` |

## 7. High-Impact Rewrite Candidates

These are planning targets for later UI prompts, not live rewrite instructions for this pack.

1. Normalize route vocabulary on the map.
Reason: the current family mixes `route`, `path`, `road`, `stop`, `ahead`, `seen`, and `locked` in ways that are individually readable but not yet systematized.

2. Remove hover-first guidance from event presentation.
Reason: `Hover for details.` is misaligned with the portrait/mobile-forward direction and weakens compare-first reading.

3. Standardize event CTA verbs.
Reason: `Choose`, `Take`, `Pack`, `Risk`, and `Settle` create tone variety, but the current mix does not always help the player compare outcomes faster.

4. Consolidate combat blocker wording around the blocked action.
Reason: `No usable item`, item tooltip reasons, and readiness hints currently split the same truth across separate locations.

5. Tighten guard feedback language for repeated scanning.
Reason: the current lines are correct, but later UI hierarchy passes should reduce repetition and keep the signed gain or absorb readouts easier to parse.

6. Split long equipment and backpack helper lines into a shorter primary cue plus optional detail.
Reason: several helper lines are mechanically good but dense for repeated portrait use.

7. Standardize cross-surface input wording.
Reason: `Click` and `Tap` both appear in the current UI layer; later passes should align input language to the actual shipping interaction model.

8. Standardize unavailable and empty-state framing.
Reason: the repo already has usable fallbacks, but later shared-state cleanup should make their title/body/action pattern more uniform.

## 8. `NEEDS_FUTURE_LOGIC_SUPPORT` Cases

These cases should not be solved by wording alone unless the required truth becomes available in the owning runtime surface.

- Event disabled reasons for authored choices that are not currently modeled as disabled or annotated with a reason.
- More specific generic route-lock explanations beyond the already-modeled boss-key truth.
- Richer explanations for why a combat action or consumable is unavailable if the owning runtime surface does not expose a stable reason beyond current HP-or-hunger checks.
- Any copy that would predict post-action damage, exact mitigation, or exact outcome deltas.
- Any run-end explanatory line that would depend on a finer-grained failure-cause model than the current shell exposes.

## 9. Prompt 07-11.5 Handoff Plan

Recommended follow-up queue, aligned to the checked-in prompt files:

- `Docs/Promts/07_inventory_equipment_drawer.md`
  - own the map-facing inventory and equipment wording cleanup that depends on drawer hierarchy
  - preserve the explicit four-slot identity and belt-capacity truth
  - normalize map route versus inventory helper competition

- `Docs/Promts/08_event_modal_choice_cards.md`
  - own event title, body, choice-card, and compare-first wording cleanup
  - remove hover-first guidance from the final event presentation
  - surface disabled reasons only if the required truth exists by then

- `Docs/Promts/09_combat_hierarchy.md`
  - own combat action wording, guard feedback hierarchy, and local blocked-action phrasing
  - keep current truth surfaces; do not invent prediction copy

- `Docs/Promts/10_font_icon_readability_guardrails.md`
  - use this audit to decide which text surfaces must remain body-copy first
  - do not let decorative typography or icon-first treatment replace essential wording

- `Docs/Promts/10_5_first_run_hints.md`
  - teach the final UI hierarchy with short hints
  - do not use onboarding copy to patch missing gameplay truth

- `Docs/Promts/11_ui_theme_token_cleanup.md`
  - preserve the wording hierarchy established by Prompts 07-10.5
  - theme and token cleanup should not invent new microcopy families

- `Docs/Promts/11_5_empty_error_states.md`
  - own shared empty, unavailable, save/load, overflow, and fallback-message cleanup
  - standardize title/body/action patterns across shells once the structural UI wave is stable

Queue recommendation:

- Prompt 07 should treat this audit as wording guidance, not as permission to expand gameplay explanation.
- Prompt 08 and Prompt 09 carry the highest wording payoff after Prompt 07 because the largest decision-pressure gaps live in event and combat surfaces.
- Prompt 11.5 should be the shared-string consolidation pass after the higher-level structure is settled.

## 10. Non-Goals

- no code changes
- no live string rewrites in this pack
- no gameplay explanation text invented from unavailable runtime truth
- no localization-system work
- no failure-semantics change
- no asset approval, generation, import, move, rename, or hookup
