# SIMPLE RPG - Windows Playtest Brief

## How To Launch

- Keep `simple_rpg_playtest.exe` and `simple_rpg_playtest.pck` in the same folder.
- Open `simple_rpg_playtest.exe`.
- Optional developer telemetry capture: launch from a terminal with `simple_rpg_playtest.exe --playtest-log` when a JSONL session trace is explicitly needed.
- Explicit telemetry capture now writes a `session_start` header plus a stable `session_id` so repeated local playtests can share one JSONL file without losing per-session boundaries.
- Use `Start New Run` to enter the current prototype slice.
- `Load Saved Run` only unlocks after the first safe-state save.
- Save/load is intentionally bounded to the current safe screens. Mid-combat restore is not part of this playtest pass.

## Prototype Scope

- This is a Windows-only playtest build for the current prototype slice.
- Current live flow is `Main Menu -> Run Setup -> Map Explore -> Combat / Event / Reward / SupportInteraction -> LevelUp? / StageTransition / RunEnd`.
- Current non-combat node interactions (`Event`, `Reward`, `SupportInteraction`, `LevelUp`) render as overlays on top of `MapExplore` during the active prototype flow.
- The slice is intentionally compact and deterministic. It is not content-complete, balance-complete, or release-ready.

## Feedback Focus

- Main menu clarity and first-run comprehension.
- Map readability, route-choice clarity, and safe-screen save/load expectations.
  - whether roads read first as the structure of the neighborhood
  - whether landmark pockets read as primary node identity rather than icon discs alone
  - whether the lower half of the board carries meaningful structure instead of mostly void or decorative spill
  - whether UI and overlay surfaces support the small-world illusion instead of reframing the map as a dashboard inset
- Combat pacing inside the current compact loop, especially:
  - whether `Defend` feels worth its `2` hunger turn cost when spike turns are readable
  - whether enemy telegraphs create real decisions instead of noise
  - whether `Technique` choices feel distinct and worth carrying between combats
  - whether `SwapHand` feels useful mainly as broken-weapon recovery or also produces proactive decisions
- Event, reward, and support pacing inside the same compact run slice.
- Confusion, friction, or dead-end moments in the current prototype flow.

## Temporary Floor

- The current visual/audio floor is still temporary prototype surface, not final production art/audio.
- The current music floor is the calmer repo-authored `proto_01` set, but it is still marked temporary and replace-before-release.
- Feedback about readability, contrast, clarity, and information hierarchy is useful.
- If candidate map art appears in later playtests, judge structural readability separately from asset polish; candidate art is not proof that the map system is already structurally correct.
- If portrait review captures are refreshed, use the paired `export/portrait_review/*.review.json` sidecars to confirm the exact screenshot paths reviewed, note lower-half occupancy readback, and call out any visible UI overlap entries before making a human judgment on the PNGs.
- Feedback that assumes final art polish, final balance breadth, or release-ready content coverage should be treated as provisional.
