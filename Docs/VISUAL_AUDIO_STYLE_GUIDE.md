# SIMPLE RPG - Visual And Audio Style Guide

## Purpose

This file locks the first-pass visual and audio direction for prototype production.

## Chosen Direction

`Dark Forest Wayfinder`

The project should feel:
- dark and misty, not muddy
- like a lone traveler reading a road through the woods
- readable before atmospheric
- stylized before realistic

## Priority Order

1. UI readability
2. icon clarity
3. enemy readability
4. atmosphere

## Style Reference Anchors

These are word-based style anchors for prototype production.
They are not a replacement for a future moodboard board, but they reduce interpretation drift.

### Nearest Game References

- UI mood: the cleanliness of `Slay the Spire` plus the tone of `Darkest Dungeon`, landing between the two
- Icon style: `Slay the Spire` relic readability, silhouette-first with minimal detail
- Enemy bust style: `Darkest Dungeon`, but less painterly and more flat/stylized
- Background mood: deep forest layers, distant guide lights, and restrained path language

Not like:
- `Genshin Impact` -> too bright, too anime
- `Diablo` -> too realistic, too gritty
- `Balatro` -> too flat, too cartoony
- muddy olive admin shell -> too washed, too static

### AI Prompt Anchor Phrases

Use these phrases repeatedly in AI-assisted generation requests:
- `dark forest wayfinder, dark misty forest, readable UI contrast`
- `silhouette-focused, stylized not realistic, 2D flat shading`
- `lone traveler seeking a path, distant guide lights, layered depth`
- `mobile-readable, small-screen-first composition`
- `NOT: muddy green wash, NOT: bright pastel, NOT: photorealistic, NOT: anime, NOT: pixel art, NOT: watercolor`

### Anti-Pattern Anchors

Reject or revise output that drifts into:
- overly detailed realistic metal rendering
- bright neon fantasy color language
- anime or chibi character styling
- pixel art retro presentation
- watercolor or loose painterly rendering
- inconsistent icon perspective or light direction across the same set

### Consistency Test

Ask:
`Does this asset look like it belongs to the same game as the other approved assets?`

If the answer is no, revise or reject it.

Real moodboard images may later be added in `SourceArt/Generated/` or a Figma board.
This section is the minimum written anchor until that board exists.

## Core Palette

- background charcoal: `#0B1216`
- panel tone: `#131B20`
- text primary: `#E6DFC9`
- aged bronze: `#8C7A5B`
- wayfinder teal: `#395856`
- rust accent: `#B6543C`
- guide gold: `#C9B26B`

System colors:
- HP: `#C44E4E`
- Hunger: `#B38A3D`
- Durability: `#5FA287`
- Reward: `#D2B85A`

## Typography

### Font Families

- Primary UI font: `Inter`
- Heading and accent font: `Cinzel`
- Stat and damage numbers: `Inter` with tabular figures enabled

### Usage Rules

- Use `Inter` for:
  - body text
  - stat labels
  - buttons
  - captions
  - combat numbers by default
- Use `Cinzel` only for:
  - headings
  - section accents
  - relic-fantasy flavor labels where readability remains strong
- Do not use `Cinzel` for body text, button text, or dense combat information.
- If a runtime environment cannot reliably use `Inter` tabular figures, a monospace fallback such as `JetBrains Mono` may be used for numbers only.

### Minimum Size Baseline

- Body text: minimum `14sp`
- Stat numbers: minimum `16sp`
- Button text: minimum `14sp`
- Caption or tooltip text: minimum `12sp`
- Headings: `18-24sp`

### License Rule

- Runtime UI fonts must use `SIL Open Font License` or `Apache 2.0`.
- `Inter` and `Cinzel` satisfy the prototype baseline.
- Preferred sources: `Google Fonts` or `Font Squirrel`.
- Record chosen font files and licenses in `AssetManifest`.

### Runtime Storage Rule

- Store approved runtime font files under `Assets/UI/Fonts/`.
- Keep only the font files actually used by the prototype runtime in that folder.
- Figma may reference the same families, but runtime font files still need their own tracked source and license record.

## UI Rules

- UI must stay higher contrast than the background
- panels use clean layers, not heavy bevels
- rounded corners stay subtle
- only one main accent plus one system color should dominate a screen at a time
- combat numbers and system text must stay simple and legible

## Icon Rules

- silhouette first
- minimal inner detail
- readable at small sizes
- one consistent light direction
- rarity is shown through framing or badges, not by redrawing the whole icon

### Canvas And Grid

- Master canvas: `128x128`
- Safe area: `96x96`
- Required padding: `16px` on each edge
- Icon content should stay inside the safe area
- The main silhouette should fill at least `60%` of the safe area

### Line Weight

- Outline weight: `2-3px` at `128x128`
- Inner detail lines: `1-2px`
- Keep line weight consistent across the entire icon set

### Light Direction

- Use one consistent light source from the upper-left
- Treat the light direction as roughly `10-11 o'clock`
- Do not flip light direction between icons

### Color Rules

- Base icon colors should come from the locked palette, especially the `aged bronze` and `oxidized teal` range
- Highlights may use `text primary` or a lighter bronze value
- System icons may use their matching system colors:
  - `HP`
  - `Hunger`
  - `Durability`
- Use at most `3` colors per icon:
  - base
  - shadow
  - highlight

### Background And Framing

- Icon background stays transparent
- Rarity framing belongs around the icon as a frame or badge
- Do not redraw the icon itself for rarity tiers

### Export Rule

- Export `PNG` at `128x128` as the master size
- Export `PNG` at `64x64` for runtime readability checks
- `SVG` is also acceptable for vector-authored icons

### Template Rule

- Use `SourceArt/icon_template_128.png` as the baseline icon template
- Every new icon should be checked against its safe area and padding before export

### Consistency Test

When a new icon is added, check:
- same line weight
- same light direction
- same palette behavior
- readable at `64x64`

If any one of these fails, revise the icon before approval.

Do not use:
- thin unreadable lines
- heavy glow
- realistic metal rendering
- different perspective styles inside the same icon set

## Character And Enemy Rules

- prototype representation is `bust + token`
- silhouette matters more than face detail
- each enemy family should be identifiable in two seconds
- variation comes from shape, shoulders, headgear, and weapon mass before micro-detail

## Bust And Token Composition

### Bust Frame

- Bust canvas: `512x768`
- Visible framing should show roughly chest or shoulder height upward
- The head should sit in the upper `40-50%` of the frame
- Lower-edge fade or crop is acceptable
- Bust background stays transparent

### Orientation

- Player bust: slightly left-facing or straight-on
- Enemy bust: slightly right-facing or straight-on
- Boss bust: more frontal and more dominant in pose

### Silhouette Priority

- Shoulder width, headgear, and weapon silhouette should be recognizable within the first two seconds
- Face detail is secondary to shape readability on a mobile screen
- If the bust reads only when zoomed in, the composition is wrong

### Token Rule

- Tokens are separate assets, not reduced bust exports
- Token canvas: `128x128`
- Tokens should sit inside a circular or rounded-square frame
- Tokens should show head plus upper shoulders only
- Tokens must keep the same light direction and palette logic as the matching bust
- Tokens are intended for map or node-marker readability first

### Enemy Family Readability

- Enemies in the same family should share a recognizable silhouette language
- Variation inside a family should come from headgear, weapon shape, and shoulder treatment
- Different enemy families should look clearly different at silhouette level

### Consistency Test

When reviewing `1` player bust, `2` enemy busts, and `1` boss bust side by side, check:
- same art style
- same light direction
- same crop logic
- palette alignment with the style guide

If any one of these fails, revise before approval.

## Background Rules

- backgrounds carry atmosphere, not gameplay information
- use a simple three-layer approach:
  - far
  - mid
  - overlay
- combat backgrounds stay cleaner than map backgrounds
- backgrounds must never overpower panels or core combat information

## Animation Rules

- only micro-feedback for the prototype
- prefer cheap but clear motion:
  - hit flash
  - button bounce
  - intent reveal
  - loot pop
  - panel open and close
  - small screen shake

### Timing Table

| Animation | Duration | Easing | Notes |
|---|---|---|---|
| `button_bounce` | `100ms` down + `80ms` up | `ease-out` | Scale: `1.0 -> 0.95 -> 1.0` |
| `hit_flash` | `60ms` on + `60ms` off, `2` cycles | `linear` | White overlay, opacity `0.7` |
| `intent_reveal` | `200ms` | `ease-out` | Fade in + slight scale up (`0.9 -> 1.0`) |
| `loot_pop` | `150ms` | `ease-out-back` | Scale: `0 -> 1.1 -> 1.0` |
| `panel_open` | `200ms` | `ease-out` | Fade in + slide up `8px` |
| `panel_close` | `150ms` | `ease-in` | Fade out + slide down `4px` |
| `screen_shake` | `120ms` total | `linear` | `3px` amplitude, `3` oscillations |
| `damage_number` | `400ms` total | `ease-out` | Float up `20px` + fade out during last `150ms` |
| `status_apply` | `200ms` | `ease-out` | Badge scale pop (`0.8 -> 1.0`) + glow pulse |

### General Rules

- UI response should begin within `100ms` of the player action
- Never block input for the full duration of a feedback animation
- Animations may be interrupted; a new higher-priority action may cancel the current one
- Sync SFX at animation start, not at animation end
- Prefer opacity and transform changes over particle-heavy effects for mobile battery safety

### Easing Reference

- `ease-out`: fast start, slow end; use for UI response and reveal motion
- `ease-in`: slow start, fast end; use for dismiss and close motion
- `ease-out-back`: overshoot feel; use for reward emphasis and pop feedback
- `linear`: constant pace; use for flashes and shakes

Do not build:
- heavy character animation systems
- cinematic transitions
- high-particle spectacle effects

## Audio Rules

- audio should be short, readable, and repeat-safe
- UI sounds must clearly differ from combat sounds
- prototype music uses library loops only
- avoid overproduced or cinematic audio that promises more polish than the prototype can support

## Visual Errors To Avoid

- muddy low-contrast fantasy
- each screen using a different art language
- realistic enemies with flat placeholder UI
- noisy backgrounds behind critical HUD
- placeholders becoming final without explicit approval
