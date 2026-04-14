# SIMPLE RPG - Production Risk Register

## Purpose

This file records the current prototype and temporary production-floor risks that are most likely to cause trouble during future continuation work.

This is a reference-only continuation guardrail.
It is not a rule authority.
If this file conflicts with `HANDOFF.md` or an authority doc named in `DOC_PRECEDENCE.md`, the authority doc wins.
Keep only live continuation risks here; resolved or dated status detail should move to `HANDOFF.md` or `Docs/Archive/` instead of accumulating in this file.

## Reading Rule

Confirmed risks:
- directly evidenced by the current repo state, active manifest rows, live scene wiring, application flow code, or existing tests

Inferred risks:
- forward-looking growth hazards extrapolated from the current architecture and production workflow
- useful as warnings, but not active runtime bugs by themselves

Severity scale:
- `P0`: immediate blocker for release-facing production use
- `P1`: high-risk continuation hazard; safe prototype work can continue, but drift here will become expensive quickly
- `P2`: meaningful non-blocking debt; should stay visible during future passes

## Current Continuation Anchor

Keep these live concerns visible during continuation:
- `P0`: the current manifest-tracked production floor is still temporary and must not be misframed as release-ready
- `P1`: provenance drift during in-place swaps, behavior-sensitive content additions, validator overreach, and quiet save-boundary expansion remain the main growth hazards
- `P2`: slot forcing, temp-floor cohesion drift, and premature audio centralization remain meaningful non-blocking debt

Use the detailed risk sections below when a task touches one of those lanes.

## Release And Provenance Risks

### Risk 1: Temp Floor Misframed As Ship-Ready

Basis: Confirmed
Severity: `P0`
Blocker type: release-facing blocker

Why it matters:
The current runtime floor is intentionally temporary. Treating it as ship-ready would create legal, provenance, and aesthetic release risk at the same time.

Trigger:
Any release-adjacent packaging, marketing capture, or store-facing branch that assumes the current `Assets/` floor is already final enough.

Warning sign:
Manifest rows stay on `status=placeholder` and `replace_before_release=yes`, but PR text or planning language starts calling the assets "done" or "final".

Safe mitigation:
Keep `asset_id` and `runtime_path` stable, swap in place later, and update only truthful provenance/licensing/commercial fields when a better asset arrives.

What not to do:
Do not clear `replace_before_release` just because a placeholder looks good enough.
Do not fork a second runtime filename for the same asset role.

Minimum validation:
Run `py -3 Tools/validate_assets.py`.
Review the touched manifest rows manually for `status`, `commercial_status`, `replace_before_release`, and real source/master paths.

### Risk 2: In-Place Swap Provenance Drift

Basis: Confirmed
Severity: `P1`
Blocker type: non-blocking prototype debt

Why it matters:
The repo now has a real temp-floor asset pipeline with `SourceArt/Edited`, `SourceArt/Figma`, `SourceArt/Archive`, and stable runtime exports. Swapping from the wrong source can leave runtime files correct-looking but historically unexplainable.

Trigger:
A future placeholder swap that copies a file from `Archive/`, a scratch Figma export, or an unreviewed candidate without updating the manifest truthfully.

Warning sign:
`runtime_path` changes are proposed during a swap, `master_path` stops matching the real master, or the source file comes from somewhere other than the reviewed source/master lane.

Safe mitigation:
Swap in place only.
Prefer `SourceArt/Edited` or the approved Figma export path as the recorded master.
Update the existing manifest row instead of inventing a new runtime identity.

What not to do:
Do not rename `asset_id`.
Do not rename `runtime_path`.
Do not leave `source_origin`, `license`, or `commercial_status` on the old placeholder values after a real swap.

Minimum validation:
Run `py -3 Tools/validate_assets.py`.
Open the swapped runtime asset in the live scene that uses it.
Diff the touched manifest row and confirm `master_path` and provenance fields are truthful.

## Runtime And Content Growth Risks

### Risk 3: Content-Only Additions Silently Change Live Behavior

Basis: Confirmed
Severity: `P1`
Blocker type: non-blocking prototype debt

Why it matters:
Current enemy rotation, boss selection, reward sourcing, and level-up offer windows are still narrow and deterministic. New content definitions can change live runtime behavior without any scene or application code change.

Trigger:
Adding or reordering `Enemies`, `Rewards`, or `PassiveItems` definitions, especially when the continuation assumes a change is "content only".

Warning sign:
A content PR changes `authoring_order`, adds a new definition into a currently cycled family, or alters a live deterministic slice without mentioning runtime behavior.

Safe mitigation:
Treat any change to current cycled content as behavior-sensitive.
Call out the behavioral impact explicitly.
Re-run the most relevant tests for the changed family or add a new narrow regression.

What not to do:
Do not hide mechanic changes inside content additions.
Do not assume a new definition is inert just because no code changed.

Minimum validation:
Use the content/schema validator already required by the lane.
Re-run the affected runtime tests such as combat, reward, level-up, or stage progression where applicable.

### Risk 4: Safe-State Save Boundary Widening

Basis: Confirmed
Severity: `P1`
Blocker type: non-blocking prototype debt

Why it matters:
The current save model is intentionally bounded to safe screens and restore-backed runtime states. If future work quietly expands saving into unsafe states, save truth and restore invariants can drift fast.

Trigger:
Any attempt to add save/load to `Combat`, mid-resolution flow steps, or a new state that is not already covered by the current save contract.

Warning sign:
A new save button appears on an unsafe scene, or snapshot restore starts needing hidden scene-only reconstruction logic.

Safe mitigation:
Keep save/load limited to the current safe-state surface unless the owning save and flow docs are explicitly updated first.
Use the runtime owner, not scene-local reconstruction, when restore support is added.

What not to do:
Do not bolt combat save on through `AppBootstrap` convenience accessors.
Do not paper over missing runtime state with scene-only fallback values.

Minimum validation:
Run the relevant save/restore regressions for the touched state.
Confirm that the restored active flow state still reconstructs from runtime-owned data only.

### Risk 5: New Icon Or Boss-Token Lanes Forced Into The Wrong Surface

Basis: Confirmed
Severity: `P2`
Blocker type: non-blocking prototype debt

Why it matters:
The icon floor is broader than the currently opened runtime slots, and the boss token is intentionally parked until a real slot exists. The map already has dedicated key and boss treatment through reused stable icons, but future additions can still break the runtime-truth boundary by forcing unwarranted special cases into generic surfaces.

Trigger:
Adding HP/Hunger/Durability icons, boss-token visuals, or special key/boss markers without first introducing an explicit owned slot.

Warning sign:
UI starts inferring gameplay state from display text, or a generic marker is repurposed to act like a boss token slot.

Safe mitigation:
Open only obvious existing slots.
If no slot exists, keep the asset parked.
If a new slot is truly needed, introduce the narrow runtime surface first and then wire the art.

What not to do:
Do not use label text as a logic key.
Do not move gameplay truth into presenters or scene scripts just to unlock art.

Minimum validation:
Run the presenter test and the scene regression that covers the touched surface.
Visually inspect the affected scene for readability after the slot is wired.

## Validation And Production-Quality Risks

### Risk 6: Validator Green Can Be Misread As Full Production Approval

Basis: Confirmed
Severity: `P1`
Blocker type: non-blocking prototype debt

Why it matters:
`Tools/validate_assets.py` enforces manifest presence, stable path coverage, controlled enums, and some policy consistency. It does not validate scene reachability, style cohesion, source quality, or whether the right runtime slot is being used.

Trigger:
A production pass ends at "validator passed" without also checking the live scene or relevant bounded tests.

Warning sign:
An asset patch changes visuals or audio significantly, but the only verification note is the validator output.

Safe mitigation:
Treat the validator as the minimum floor.
Pair it with the most relevant scene/test reruns and a human readability/style review.

What not to do:
Do not use a green validator result as evidence that the asset is production-ready.
Do not skip targeted scene checks after a swap or wiring pass.

Minimum validation:
Run `py -3 Tools/validate_assets.py`.
Run the relevant bounded regression tests for the touched scene or lane.
Open the touched scene and verify the asset is actually the one intended.

### Risk 7: Temp-Floor Cohesion Drift

Basis: Confirmed
Severity: `P2`
Blocker type: non-blocking prototype debt

Why it matters:
The current floor mixes repo-authored placeholders, Figma exports, and temp audio loops across multiple lanes. A validator-clean repo can still become visually or sonically inconsistent enough to hurt readability and future swap discipline.

Trigger:
Incremental additions land one lane at a time without checking whether the whole slice still reads like one game.

Warning sign:
Icons, backgrounds, busts, and utility shells are all individually acceptable, but side-by-side screens start feeling like they came from different passes.

Safe mitigation:
Review changes against the locked style guide priorities: readability first, then icon clarity, enemy readability, and atmosphere.
Use the current playable scenes as the real comparison surface instead of judging assets in isolation.

What not to do:
Do not promote a candidate just because it is technically tracked and readable in a vacuum.
Do not let one lane chase polish that forces the others to follow with redesign work.

Minimum validation:
Run the validator.
Open the affected screens together and compare them against the current style-guide anchors.
Re-run the scene tests that already guard the touched shell.

### Risk 8: Scene-Local Audio Floor Pressures A Premature Global Audio Layer

Basis: Inferred
Severity: `P2`
Blocker type: non-blocking prototype debt

Why it matters:
Current audio wiring is intentionally local to each scene. As more polish work lands, duplicated scene-owned players can create pressure to centralize too early, which would become a broad architecture change rather than a safe production pass.

Trigger:
A future audio pass needs more cross-scene coordination, longer transitions, or shared routing behavior and tries to solve it with a convenience autoload.

Warning sign:
The patch starts introducing a global audio manager even though the current task is only a narrow production-floor refinement.

Safe mitigation:
Keep audio local and scene-owned for the current prototype unless a true cross-scene requirement appears and the architecture implications are surfaced first.

What not to do:
Do not add a gameplay or global audio autoload just to remove a few repeated scene lines.
Do not silently expand a local audio pass into an architecture pass.

Minimum validation:
If a future change stays local, run the relevant scene tests and confirm no flow behavior changed.
If a future change cannot stay local, stop and escalate before implementation.

## Short Continuation Rules

1. Treat `HANDOFF.md` as the only rolling current-state file; this register is a reference-only risk map.
2. Treat `py -3 Tools/validate_assets.py` as the minimum floor, never as the whole approval decision.
3. Keep `asset_id` and `runtime_path` stable on every asset improvement; swap in place and update provenance truthfully.
4. Assume content additions are behavior-sensitive whenever current runtime selection depends on authoring order or a narrow offer window.
5. Open a new visual/audio slot only when the runtime owner and scene surface are explicit; otherwise keep the asset parked.
6. Keep save/load on the current safe-state surface unless the owning save and flow docs are updated first.
7. When extending this file, label each new risk as `Confirmed` or `Inferred` and cite the live repo evidence that supports it.
