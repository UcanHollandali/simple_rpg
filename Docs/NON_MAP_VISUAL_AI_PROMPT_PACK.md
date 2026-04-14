# SIMPLE RPG - Non-Map Visual AI Prompt Pack

## Status And Authority

This file is a reference-only production brief for third-party AI-assisted visual generation.
It does not replace the authoritative production docs.

Authority remains:
- `Docs/VISUAL_AUDIO_STYLE_GUIDE.md`
- `Docs/ASSET_PIPELINE.md`
- `Docs/ASSET_LICENSE_POLICY.md`

This brief covers non-map visual assets only.
Map-specific final background prompts stay out of scope here and are intentionally deferred until composer v2.

## Repo Facts Used In This Brief

Confirmed from current repo docs and runtime files:
- visual direction is `Dark Forest Wayfinder`
- locked palette and style anchors come from `Docs/VISUAL_AUDIO_STYLE_GUIDE.md`
- logical portrait baseline is `1080x1920`
- non-map background families are already live as:
  - `bg_menu_far`, `bg_menu_mid`, `bg_menu_overlay`
  - `bg_choice_far`, `bg_choice_mid`, `bg_choice_overlay`
  - `bg_terminal_far`, `bg_terminal_mid`, `bg_terminal_overlay`
  - `bg_combat_far`, `bg_combat_mid`, `bg_combat_overlay`
- current runtime background files are `1080x1920`
- current runtime `player_bust` file is `1024x1536`
- checked current runtime enemy bust files use the same `1024x1536` floor
- checked current runtime boss token files use `256x256`
- current runtime icons are `SVG` files with `128x128` canvas metadata
- current live icon pack has `19` stable runtime IDs
- current live enemy bust runtime IDs and boss token runtime IDs are listed in the appendix of this file

Confirmed from authority docs:
- backgrounds should stay split into `far`, `mid`, and `overlay` layers when practical
- runtime names must stay stable and use `lower_snake_case`
- `SourceArt/Generated/` is for AI-generated or externally generated source material
- `SourceArt/Edited/` is for cleaned or reviewed masters
- raw AI output must not be promoted directly into runtime
- any AI-assisted asset promoted into runtime needs truthful manifest provenance and `ai_used=yes`
- AI must not become the source of truth for the icon system

## Recommendations Used In This Brief

These are production recommendations, not repo facts:
- use the current live raster floor for new non-map bust and token prompt work so replacements match the assets already in runtime:
  - bust prompt target: `1024x1536`
  - boss token prompt target: `256x256`
- treat `Docs/ASSET_PIPELINE.md` export sizes as the minimum fallback baseline, not the preferred prompt target for the currently refreshed combat art lane
- oversample only when the external tool can do it cleanly, then downscale to the target master
- batch enemy ideation by silhouette cluster for consistency, but keep runtime IDs unchanged
- use shared family prompt sessions for backgrounds and icons so style does not drift between sibling assets

## Common Prompt Rules

### Common Style Anchor Stack

Repeat these exact phrases in every prompt:
- `dark forest wayfinder`
- `dark misty forest`
- `readable before atmospheric`
- `silhouette-focused`
- `stylized not realistic`
- `2D flat shading`
- `mobile-readable`
- `small-screen-first composition`
- `upper-left light source`

Use these palette anchors when a model responds well to color language:
- `charcoal #0B1216`
- `panel tone #131B20`
- `aged bronze #8C7A5B`
- `wayfinder teal #395856`
- `rust accent #B6543C`
- `guide gold #C9B26B`
- `text primary #E6DFC9`

### Common Negative Stack

Use this as a shared avoid block.
If the tool has no dedicated negative-prompt field, append the same language to the end of the main prompt.

- `NOT photorealistic`
- `NOT anime`
- `NOT chibi`
- `NOT bright pastel`
- `NOT neon fantasy`
- `NOT pixel art`
- `NOT watercolor`
- `NOT muddy green wash`
- `NOT glossy sci-fi UI`
- `NOT heavy bloom`
- `NOT busy micro-detail`
- `NOT inconsistent light direction`

### Common Output Contract

Use this final instruction block in every generation request:

```text
Deliver a clean source image only. No text, no logos, no watermark, no UI frame, no mockup device, no collage layout, no extra border. Keep the silhouette readable on a phone screen. Preserve clear separation between subject and background. Export a single asset-focused image that can enter SourceArt/Generated for review.
```

### Common Naming And Versioning Rule

- generated candidates: `SourceArt/Generated/<asset_id>_candidate_v001.<ext>`
- reviewed masters: `SourceArt/Edited/<asset_id>_master_v001.<ext>`
- later revisions increment only the master suffix:
  - `..._master_v002`
  - `..._master_v003`
- runtime export names stay stable:
  - `Assets/Backgrounds/<asset_id>.png`
  - `Assets/Characters/<asset_id>.png`
  - `Assets/Enemies/<asset_id>.png`
  - `Assets/Icons/<asset_id>.svg`

Do not create a new runtime name just because the source art improved.

### Common Human Review Gate

Before any runtime promotion, ask:
1. Is the source trail clear and recordable in `AssetManifest/asset_manifest.csv`?
2. Does it match the locked style guide more than it matches any outside aesthetic?
3. Is the silhouette still readable at runtime scale?
4. Is `replace_before_release` still truthful?
5. If AI assisted the work, is `ai_used=yes` required for the manifest row?

If any answer is uncertain, do not promote.

## Asset Family Briefs

## Menu Background Family

Stable runtime targets:
- `bg_menu_far`
- `bg_menu_mid`
- `bg_menu_overlay`

Target size and resolution:
- target master per layer: `1080x1920`
- optional oversample: `2160x3840`, then downscale to `1080x1920`

Transparent vs opaque export:
- `bg_menu_far`: visually opaque scene layer
- `bg_menu_mid`: alpha-capable `PNG` is acceptable and preferred
- `bg_menu_overlay`: transparent `PNG`

Exact style anchors:
- `dark forest wayfinder`
- `gate-path silhouette`
- `distant guide lights`
- `layered canopy depth`
- `crisper canopy separation`
- `quiet center lane for menu card readability`

Anti-pattern list:
- giant focal subject in the center
- bright castle fantasy
- symmetrical postcard composition
- fog blob with no path language
- hard horizon line cutting through the middle

Composition rules:
- keep the strongest silhouette mass in upper third and outer edges
- reserve the center `40-60%` band for readable menu-card contrast
- far layer carries forest depth and distant light
- mid layer carries gate, path, trunks, or canopy breaks
- overlay layer carries edge framing only, never central obstruction

Naming and versioning rule:
- candidate lanes:
  - `SourceArt/Generated/bg_menu_far_candidate_v001.png`
  - `SourceArt/Generated/bg_menu_mid_candidate_v001.png`
  - `SourceArt/Generated/bg_menu_overlay_candidate_v001.png`
- reviewed masters:
  - `SourceArt/Edited/bg_menu_far_master_v00x.png`
  - `SourceArt/Edited/bg_menu_mid_master_v00x.png`
  - `SourceArt/Edited/bg_menu_overlay_master_v00x.png`

Recommended variant count:
- `3` complete family sets
- one set means `far + mid + overlay` built from the same composition idea

Master prompt template:

```text
Create a portrait mobile game background layer for SIMPLE RPG.
Asset: {bg_menu_far|bg_menu_mid|bg_menu_overlay}.
Style: dark forest wayfinder, dark misty forest, readable before atmospheric, silhouette-focused, stylized not realistic, 2D flat shading, mobile-readable, small-screen-first composition, upper-left light source.
Scene anchors: gate-path silhouette, distant guide lights, layered canopy depth, crisper canopy separation, lone traveler path language without showing a full character.
Composition: keep the center band quiet for menu card readability, push the strongest shapes toward the upper third and outer edges, preserve clean layer separation.
Palette: charcoal #0B1216, panel tone #131B20, aged bronze #8C7A5B, wayfinder teal #395856, guide gold #C9B26B.
Output: single-layer source image at 1080x1920 portrait, no text, no UI, no watermark.
```

Negative prompt and avoid list:
- photoreal forest photography
- bright moonlit blue fantasy
- heroic figure in foreground
- centered gate blocking the menu card lane
- heavy blur haze hiding silhouettes

Review checklist:
- readable gate/path idea within `2` seconds
- center lane stays calmer than the corners
- layer works with the other menu siblings
- no detail hotspot competes with menu buttons
- guide lights read as restrained accents, not neon dots

Runtime integration notes:
- used by `Main`, `MainMenu`, and `RunSetup`
- keep visual weight away from the central action-card band
- export as separate runtime layers; do not flatten the family into one file

## Choice Background Family

Stable runtime targets:
- `bg_choice_far`
- `bg_choice_mid`
- `bg_choice_overlay`

Target size and resolution:
- target master per layer: `1080x1920`
- optional oversample: `2160x3840`, then downscale

Transparent vs opaque export:
- `bg_choice_far`: visually opaque scene layer
- `bg_choice_mid`: alpha-capable `PNG`
- `bg_choice_overlay`: transparent `PNG`

Exact style anchors:
- `dark forest wayfinder`
- `ruin field silhouette`
- `waystone focus`
- `broken pillar framing`
- `decision-space atmosphere`
- `clear card readability over low-noise center`

Anti-pattern list:
- cluttered loot-room pileup
- literal choice arrows or UI symbols inside the art
- cathedral interior grandeur
- bright treasure-room gold splash
- centered ruin pillar blocking choice cards

Composition rules:
- shape the family around a readable central staging pocket
- use far layer for tree line, ruin depth, and distant haze
- use mid layer for waystone, broken pillar, or shrine silhouette
- use overlay only for edge vines, branch arcs, or subtle ruin framing
- keep the immediate card area lower in contrast than the edges

Naming and versioning rule:
- `bg_choice_{far|mid|overlay}_candidate_v001.png`
- `bg_choice_{far|mid|overlay}_master_v00x.png`
- runtime names remain `bg_choice_far.png`, `bg_choice_mid.png`, `bg_choice_overlay.png`

Recommended variant count:
- `3` complete family sets

Master prompt template:

```text
Create a portrait mobile game background layer for SIMPLE RPG.
Asset: {bg_choice_far|bg_choice_mid|bg_choice_overlay}.
Style: dark forest wayfinder, dark misty forest, readable before atmospheric, silhouette-focused, stylized not realistic, 2D flat shading, mobile-readable, small-screen-first composition, upper-left light source.
Scene anchors: ruin field silhouette, weathered waystone, broken pillar framing, restrained guide-light accents, decision-space atmosphere.
Composition: preserve a readable central pocket for event, reward, support, level-up, and node-resolve cards; keep detail heavier on the edges and upper third.
Palette: charcoal #0B1216, wayfinder teal #395856, aged bronze #8C7A5B, rust accent #B6543C, guide gold #C9B26B.
Output: single-layer source image at 1080x1920 portrait, no text, no UI, no watermark.
```

Negative prompt and avoid list:
- loot explosion
- high-fantasy treasure cave
- giant glowing shrine
- photoreal stone textures
- noisy grass detail in the center pocket

Review checklist:
- reads as a place of choice, not combat
- waystone or ruin cue is present without becoming a mascot object
- choice-card zone stays calm and legible
- edge framing supports, not traps, the eye
- sibling layers feel like the same location

Runtime integration notes:
- used by `Event`, `Reward`, `SupportInteraction`, `LevelUp`, and `NodeResolve`
- this family should feel more contemplative than menu and less monumental than terminal
- do not leak map-specific landmark language into this family

## Terminal Background Family

Stable runtime targets:
- `bg_terminal_far`
- `bg_terminal_mid`
- `bg_terminal_overlay`

Target size and resolution:
- target master per layer: `1080x1920`
- optional oversample: `2160x3840`, then downscale

Transparent vs opaque export:
- `bg_terminal_far`: visually opaque scene layer
- `bg_terminal_mid`: alpha-capable `PNG`
- `bg_terminal_overlay`: transparent `PNG`

Exact style anchors:
- `dark forest wayfinder`
- `monumental road silhouette`
- `gate or obelisk forms`
- `terminal destination mood`
- `somber end-state atmosphere`
- `wide interstitial-card readability`

Anti-pattern list:
- throne room fantasy
- heaven-light ending screen
- giant skull motif
- victory-banner composition
- central obelisk blocking summary text

Composition rules:
- build stronger vertical monument shapes than menu or choice
- keep the middle band readable for wider interstitial cards
- far layer carries distant road, horizon glow, or terminal architecture mass
- mid layer carries gate, arch, or obelisk silhouette
- overlay layer should vignette the edges without crushing title readability

Naming and versioning rule:
- `bg_terminal_{far|mid|overlay}_candidate_v001.png`
- `bg_terminal_{far|mid|overlay}_master_v00x.png`
- runtime names remain stable

Recommended variant count:
- `2` complete family sets for `StageTransition`
- `2` complete family sets for `RunEnd`
- if batching, still keep the runtime layer names stable and swap in place later

Master prompt template:

```text
Create a portrait mobile game background layer for SIMPLE RPG.
Asset: {bg_terminal_far|bg_terminal_mid|bg_terminal_overlay}.
Style: dark forest wayfinder, readable before atmospheric, silhouette-focused, stylized not realistic, 2D flat shading, mobile-readable, small-screen-first composition, upper-left light source.
Scene anchors: monumental road silhouette, gate or obelisk forms, terminal destination mood, somber but readable atmosphere, restrained guide-light accents.
Composition: leave a broad readable middle band for stage-transition and run-end cards, push monument shapes slightly above center, keep edge framing subtle.
Palette: charcoal #0B1216, panel tone #131B20, aged bronze #8C7A5B, wayfinder teal #395856, guide gold #C9B26B, rust accent #B6543C.
Output: single-layer source image at 1080x1920 portrait, no text, no UI, no watermark.
```

Negative prompt and avoid list:
- triumphant sunburst ending
- celestial fantasy temple
- photoreal graveyard
- giant centered monolith
- heavy red apocalypse wash

Review checklist:
- reads as terminal or transitional, not generic map art
- monument silhouettes stay readable in silhouette alone
- center band supports summary-card readability
- mood is sober, not melodramatic
- family still feels like the same world as menu and choice

Runtime integration notes:
- used by `StageTransition` and `RunEnd`
- keep this family broader and more monumental than choice, but quieter than a marketing splash image

## Combat Background Family

Stable runtime targets:
- `bg_combat_far`
- `bg_combat_mid`
- `bg_combat_overlay`

Target size and resolution:
- target master per layer: `1080x1920`
- optional oversample: `2160x3840`, then downscale

Transparent vs opaque export:
- `bg_combat_far`: visually opaque scene layer
- `bg_combat_mid`: alpha-capable `PNG`
- `bg_combat_overlay`: transparent `PNG`

Exact style anchors:
- `dark forest wayfinder`
- `clean combat arena silhouette`
- `stakes and broken field geometry`
- `clear skyline read`
- `less diffuse haze`
- `combat readability before spectacle`

Anti-pattern list:
- firestorm battlefield spectacle
- dense props behind combat HUD
- centered explosion or magical vortex
- photo-real mud textures
- crowd-arena framing

Composition rules:
- keep the center and lower-middle readable for busts, tokens, action buttons, and combat log
- far layer carries skyline and distant terrain mass
- mid layer carries stakes, barriers, or field silhouettes
- overlay layer frames the edges and corners only
- combat family must stay cleaner and less busy than map backgrounds

Naming and versioning rule:
- `bg_combat_{far|mid|overlay}_candidate_v001.png`
- `bg_combat_{far|mid|overlay}_master_v00x.png`
- runtime names remain stable

Recommended variant count:
- `3` complete family sets

Master prompt template:

```text
Create a portrait mobile combat background layer for SIMPLE RPG.
Asset: {bg_combat_far|bg_combat_mid|bg_combat_overlay}.
Style: dark forest wayfinder, readable before atmospheric, silhouette-focused, stylized not realistic, 2D flat shading, mobile-readable, small-screen-first composition, upper-left light source.
Scene anchors: clean combat arena silhouette, clear skyline read, broken field geometry, stakes or sparse barriers, less diffuse haze.
Composition: protect the center and lower-middle for combat readability, keep background shapes broad and simple, avoid busy detail behind the fighter zone.
Palette: charcoal #0B1216, panel tone #131B20, aged bronze #8C7A5B, wayfinder teal #395856, rust accent #B6543C.
Output: single-layer source image at 1080x1920 portrait, no text, no UI, no watermark.
```

Negative prompt and avoid list:
- cinematic battlefield splash art
- giant monster already in the background
- magical effect storm
- strong focal object behind the busts
- orange fire glow taking over the palette

Review checklist:
- combat silhouettes remain readable on top of the background
- no background object competes with enemy bust area
- haze supports depth without smearing the scene
- family feels intentionally cleaner than map art
- three layers still read as one location

Runtime integration notes:
- used only by `Combat`
- combat UI already carries the information load, so this family must stay visually quieter than the character art

## Player Bust

Stable runtime target:
- `player_bust`

Target size and resolution:
- confirmed current runtime floor: `1024x1536`
- optional oversample: `2048x3072`, then downscale

Transparent vs opaque export:
- transparent `PNG`

Exact style anchors:
- `dark forest wayfinder`
- `lone traveler`
- `worn gear`
- `silhouette-first bust`
- `determined but restrained`
- `stylized flat-shaded portrait`

Anti-pattern list:
- anime hero face
- glossy fantasy armor glamour shot
- giant smiling protagonist energy
- cinematic hair wind effect
- cluttered backpack details below chest line

Composition rules:
- crop from chest or shoulder height upward
- keep head in the upper `40-50%` of frame
- slightly left-facing or straight-on
- shoulder and collar silhouette must read before facial detail
- lower edge may fade softly; background must stay transparent

Naming and versioning rule:
- `SourceArt/Generated/player_bust_candidate_v001.png`
- `SourceArt/Edited/player_bust_master_v00x.png`
- runtime export stays `Assets/Characters/player_bust.png`

Recommended variant count:
- `4` bust variants with the same silhouette family
- vary only pose angle, shoulder treatment, and hood/collar balance

Master prompt template:

```text
Create a transparent player bust for SIMPLE RPG.
Asset: player_bust.
Style: dark forest wayfinder, silhouette-focused, stylized not realistic, 2D flat shading, mobile-readable, small-screen-first composition, upper-left light source.
Character anchors: lone traveler, worn gear, restrained determination, practical fantasy clothing, readable shoulder silhouette, no ornate hero armor.
Composition: portrait bust, chest-up crop, head in upper half, slightly left-facing or straight-on, transparent background, readable on a phone screen.
Palette: charcoal-adjacent shadows, aged bronze accents, wayfinder teal secondary accents, text-primary highlights kept restrained.
Output: transparent PNG at 1024x1536, no text, no watermark, no frame.
```

Negative prompt and avoid list:
- photoreal face rendering
- celebrity likeness
- anime protagonist styling
- glowing runes everywhere
- ornate cape filling the frame

Review checklist:
- reads as the same game as the enemy bust family
- shoulder and hood/collar silhouette is clear at small size
- expression is readable without exaggerated facial detail
- transparent edges are clean
- not more detailed than the enemy set

Runtime integration notes:
- this is the combat-facing player portrait asset
- keep runtime filename stable
- if AI-assisted output becomes runtime art, the manifest row must flip to truthful AI provenance

## Live Enemy Bust Family

Stable runtime target pattern:
- `enemy_<definition_id>_bust`

Current live runtime IDs are listed in the appendix.
Current repo fact: outside the boss-token trio listed later in this file, live enemy token files are not runtime-tracked today.

Target size and resolution:
- confirmed current runtime floor: `1024x1536` per bust
- optional oversample: `2048x3072`, then downscale

Transparent vs opaque export:
- transparent `PNG`

Exact style anchors:
- `dark forest wayfinder`
- `enemy silhouette readable in two seconds`
- `stylized flat-shaded bust`
- `shoulders headgear and weapon mass before micro-detail`
- `mobile combat readability`
- `shared upper-left light source`

Anti-pattern list:
- monster-poster splash art
- complex full-body anatomy posing
- glossy skin or wet realism
- painterly brush soup
- same face with different hats

Composition rules:
- crop chest-up or shoulder-up only
- enemy busts face slightly right or straight-on
- keep the dominant silhouette cue in the headgear, shoulders, horns, jawline, lantern, pike, hook, vial, or weapon mass
- preserve transparent background
- if the silhouette only works when zoomed in, reject it

Naming and versioning rule:
- candidate: `SourceArt/Generated/enemy_<definition_id>_bust_candidate_v001.png`
- reviewed master: `SourceArt/Edited/enemy_<definition_id>_bust_master_v00x.png`
- runtime export stays `Assets/Enemies/enemy_<definition_id>_bust.png`

Recommended variant count:
- `2` bust variants per live enemy definition
- approve one silhouette direction before detail cleanup

Master prompt template:

```text
Create a transparent enemy bust for SIMPLE RPG.
Asset: enemy_{definition_id}_bust.
Style: dark forest wayfinder, silhouette-focused, stylized not realistic, 2D flat shading, mobile-readable, small-screen-first composition, upper-left light source.
Readability goal: identify the enemy in two seconds through shoulders, headgear, weapon mass, horn shape, lantern shape, jawline, or posture before facial detail.
Character anchors: {enemy-specific silhouette anchors}.
Composition: portrait bust, chest-up crop, slightly right-facing or straight-on, transparent background, clean silhouette against empty alpha.
Palette: charcoal shadows, bronze or bone highlights, restrained teal or rust accents only when they support the silhouette.
Output: transparent PNG at 1024x1536, no text, no watermark, no frame.
```

Negative prompt and avoid list:
- photoreal monster portrait
- body-horror gore showcase
- anime villain styling
- muddy grayscale wash
- decorative background scenery

Review checklist:
- silhouette cue is obvious before facial detail
- same light direction as player bust and boss set
- crop logic matches the other busts
- family differences read at silhouette level
- runtime alpha edge is clean

Runtime integration notes:
- applies to the live bust runtime IDs in the appendix
- current repo fact: boss tokens are live separately; do not invent new minor-enemy runtime token IDs in this pass unless the runtime actually needs them
- if a future minor-enemy token lane is opened later, reuse the `Boss Token Set` composition rules and the stable naming pattern `enemy_<definition_id>_token`, but that expansion is intentionally not locked here as a current runtime requirement
- batching recommendation only: ideate by silhouette cluster such as `beast`, `brigand/hunter`, `undead`, `cultist`, `soldier/guardian`

## Boss Token Set

Stable runtime targets:
- `enemy_gate_warden_token`
- `enemy_chain_herald_token`
- `enemy_briar_sovereign_token`

Target size and resolution:
- confirmed current runtime floor: `256x256`
- optional oversample: `512x512`, then downscale

Transparent vs opaque export:
- transparent `PNG`

Exact style anchors:
- `dark forest wayfinder`
- `boss-token clarity`
- `frontal authority`
- `head plus upper shoulders only`
- `circular or rounded-square token framing`
- `shared bust-family light direction`

Anti-pattern list:
- cropped full bust shrunk down
- tiny facial-detail dependency
- thick glow ring doing the readability work
- cartoon avatar badge styling
- frame design larger than the head silhouette

Composition rules:
- tokens are separate compositions, not auto-crops from busts
- show head plus upper shoulders only
- boss pose should read more frontal and more dominant than minor enemy art
- keep silhouette centered and bold enough to read at `64x64`
- frame may support readability, but the head silhouette must still do the main work

Naming and versioning rule:
- candidates:
  - `enemy_gate_warden_token_candidate_v001.png`
  - `enemy_chain_herald_token_candidate_v001.png`
  - `enemy_briar_sovereign_token_candidate_v001.png`
- reviewed masters:
  - `enemy_gate_warden_token_master_v00x.png`
  - `enemy_chain_herald_token_master_v00x.png`
  - `enemy_briar_sovereign_token_master_v00x.png`
- runtime names stay stable

Recommended variant count:
- `2` token variants per boss
- one should prioritize strongest silhouette
- one may test alternative frame emphasis

Master prompt template:

```text
Create a transparent boss token for SIMPLE RPG.
Asset: {enemy_gate_warden_token|enemy_chain_herald_token|enemy_briar_sovereign_token}.
Style: dark forest wayfinder, silhouette-focused, stylized not realistic, 2D flat shading, mobile-readable, upper-left light source.
Readability goal: boss-token clarity at 64x64, head plus upper shoulders only, frontal authority, separate token composition not a reduced bust crop.
Character anchors: {boss-specific silhouette anchors}.
Composition: centered head and shoulder token, transparent background, rounded or circular framing optional but subordinate to the silhouette.
Palette: charcoal shadows, aged bronze frame accents, restrained teal/rust/gold according to the boss silhouette.
Output: transparent PNG at 256x256, no text, no watermark.
```

Negative prompt and avoid list:
- emote badge face
- bright MMO raid icon style
- thin-line detailed face
- giant glowing frame
- background vignette that fills the token interior

Review checklist:
- reads cleanly at `64x64`
- boss identity survives without the full bust
- token and bust clearly belong together
- frame supports but does not replace silhouette readability
- transparent edge cleanup is solid

Runtime integration notes:
- current live token set is boss-only
- keep token art aligned with matching bust art but do not crop from bust source automatically

## Icon Refresh Pack

Stable runtime targets:
- all current live icon IDs listed in the appendix

Target size and resolution:
- AI concept phase: `1024x1024` or `1536x1536` sheet, optionally `4-6` icons per sheet
- final runtime master per icon: `128x128`
- required read check: `64x64`

Transparent vs opaque export:
- AI concept sheets may use a neutral opaque charcoal background for visibility
- final runtime exports must be transparent
- final runtime format should remain `SVG` when possible

Exact style anchors:
- `dark forest wayfinder`
- `silhouette-first icon readability`
- `Slay the Spire relic readability`
- `minimal inner detail`
- `upper-left light source`
- `aged bronze plus oxidized teal palette discipline`

Anti-pattern list:
- direct AI-to-runtime SVG shortcut
- photoreal metal rendering
- emblem clutter
- more than one perspective family in the same set
- outline weight drift from icon to icon

Composition rules:
- one primary silhouette per icon
- icon silhouette fills at least `60%` of the safe area
- keep within the `96x96` safe area on the `128x128` grid
- use at most `3` colors for the final icon
- keep line and light logic consistent across the full pack

Naming and versioning rule:
- AI concept sheets:
  - `SourceArt/Generated/icon_refresh_pack_sheet_candidate_v001.png`
  - `SourceArt/Generated/icon_combat_pack_sheet_candidate_v001.png`
  - `SourceArt/Generated/icon_map_pack_sheet_candidate_v001.png`
- reviewed runtime masters stay one file per stable icon ID:
  - `SourceArt/Edited/icon_attack_master_v00x.svg`
  - `SourceArt/Edited/icon_hp_master_v00x.svg`
  - and so on
- runtime icon filenames stay unchanged

Recommended variant count:
- `1` shared style-board sheet before any redraw
- then `2` silhouette variants per stable icon ID
- do not approve icons one by one against different style prompts

Master prompt template:

```text
Create a concept sheet for SIMPLE RPG UI icons.
Asset pack: {combat|map|status|utility}.
Style: dark forest wayfinder, silhouette-first icon readability, stylized not realistic, 2D flat shading, minimal inner detail, upper-left light source, mobile-readable.
Visual anchors: Slay the Spire relic readability, aged bronze primary forms, restrained oxidized teal secondary accents, clean silhouette, consistent line family.
Icons to explore: {icon_id_list}.
Composition: one centered icon concept per tile, consistent perspective, consistent light direction, no text labels, no decorative poster layout.
Output: concept sheet only at 1024x1024 or 1536x1536. The final runtime icons will be human-cleaned vector redraws on a 128x128 grid with transparent background.
```

Negative prompt and avoid list:
- photoreal brushed metal
- glossy app-store icon style
- game-logo badge treatment
- tiny engraved detail
- perspective drift

Review checklist:
- pack reads as one family before any individual icon is judged
- every icon still works at `64x64`
- line weight and light direction stay consistent
- each icon survives as a pure silhouette
- final runtime plan remains human/vector controlled

Runtime integration notes:
- current repo rule: AI must not become the source of truth for the icon system
- use AI only for concept exploration, silhouette ideation, or style-board generation
- final runtime icons should still be human-cleaned `SVG` masters with stable runtime names

## Appendix - Current Live Runtime ID Inventory Covered By This Brief

### Live Enemy Bust IDs

- `enemy_ash_gnawer_bust`
- `enemy_barbed_hunter_bust`
- `enemy_bone_raider_bust`
- `enemy_briar_alchemist_bust`
- `enemy_briar_sovereign_bust`
- `enemy_chain_herald_bust`
- `enemy_chain_trapper_bust`
- `enemy_drain_adept_bust`
- `enemy_dusk_pikeman_bust`
- `enemy_ember_harrier_bust`
- `enemy_forest_brigand_bust`
- `enemy_gate_warden_bust`
- `enemy_grave_chanter_bust`
- `enemy_lantern_cutpurse_bust`
- `enemy_mossback_ram_bust`
- `enemy_rotbound_reaver_bust`
- `enemy_skeletal_hound_bust`
- `enemy_venom_scavenger_bust`

### Live Boss Token IDs

- `enemy_gate_warden_token`
- `enemy_chain_herald_token`
- `enemy_briar_sovereign_token`

### Live Icon IDs

- `icon_attack`
- `icon_brace`
- `icon_cancel`
- `icon_confirm`
- `icon_consumable`
- `icon_durability`
- `icon_enemy_intent_attack`
- `icon_enemy_intent_heavy`
- `icon_hp`
- `icon_hunger`
- `icon_map_blacksmith`
- `icon_map_merchant`
- `icon_map_rest`
- `icon_map_start`
- `icon_node_marker`
- `icon_reward`
- `icon_settings`
- `icon_use_item`
- `icon_weapon`
