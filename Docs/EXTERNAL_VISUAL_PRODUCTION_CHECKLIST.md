# SIMPLE RPG - External Visual Production Checklist

This file is your personal production/checklist workspace.

- Purpose: keep external visual production organized in one place
- Scope: `non-map visual` production only
- Out of scope: `audio`, `map-specific final art`, runtime integration
- This is not an authority doc
- When needed, authority docs are:
  - `Docs/VISUAL_AUDIO_STYLE_GUIDE.md`
  - `Docs/ASSET_PIPELINE.md`
  - `Docs/ASSET_LICENSE_POLICY.md`

---

## 1. Current Focus

Only focus on these for now:

- non-map background families
- player bust
- enemy bust set
- boss token set
- icon refresh set

Do not produce these yet:

- `bg_map_far`
- `bg_map_mid`
- `bg_map_overlay`
- map canopy / trail / clearing / prop assets
- audio/music

Why:
- producing final map art before `Map Composer V2` is the wrong order

---

## 2. Which Tool To Use

Recommended production stack:

- `Backgrounds`: `Adobe Firefly` or `Midjourney`
- `Bust + Token`: `Leonardo`
- `Icons`: `Recraft`

Practical rule:

- do not switch tools inside one background family
- ideally keep the whole bust/token set in the same tool and same session logic
- keep the icon set under one tool

My recommendation:

- backgrounds: start with `Firefly`
- bust/token: `Leonardo`
- icons: `Recraft`

---

## 3. Production Order

Go in this order:

1. `bg_menu_*`
2. `bg_choice_*`
3. `bg_terminal_*`
4. `bg_combat_*`
5. `player_bust`
6. first `6` enemy busts
7. `3` boss tokens
8. remaining enemy busts
9. icon refresh set

Working rule:

- make `2-3` variants for each asset family first
- pick the best one
- do not put anything into runtime immediately
- collect the images first
- then open the integration chat

---

## 4. Full Production Checklist

### A. Background Families

Target:
- `1080x1920`
- portrait
- each family uses `far + mid + overlay`

Checklist:

- [ ] `bg_menu_far`
- [ ] `bg_menu_mid`
- [ ] `bg_menu_overlay`
- [ ] `bg_choice_far`
- [ ] `bg_choice_mid`
- [ ] `bg_choice_overlay`
- [ ] `bg_terminal_far`
- [ ] `bg_terminal_mid`
- [ ] `bg_terminal_overlay`
- [ ] `bg_combat_far`
- [ ] `bg_combat_mid`
- [ ] `bg_combat_overlay`

### B. Player Bust

Target:
- `1024x1536`
- transparent background

Checklist:

- [ ] `player_bust`

### C. Enemy Bust Set

Target:
- `1024x1536`
- transparent background
- same silhouette family

Checklist:

- [ ] `enemy_ash_gnawer_bust`
- [ ] `enemy_barbed_hunter_bust`
- [ ] `enemy_bone_raider_bust`
- [ ] `enemy_briar_alchemist_bust`
- [ ] `enemy_briar_sovereign_bust`
- [ ] `enemy_chain_herald_bust`
- [ ] `enemy_chain_trapper_bust`
- [ ] `enemy_drain_adept_bust`
- [ ] `enemy_dusk_pikeman_bust`
- [ ] `enemy_ember_harrier_bust`
- [ ] `enemy_forest_brigand_bust`
- [ ] `enemy_gate_warden_bust`
- [ ] `enemy_grave_chanter_bust`
- [ ] `enemy_lantern_cutpurse_bust`
- [ ] `enemy_mossback_ram_bust`
- [ ] `enemy_rotbound_reaver_bust`
- [ ] `enemy_skeletal_hound_bust`
- [ ] `enemy_venom_scavenger_bust`

### D. Boss Token Set

Target:
- `256x256`
- transparent background
- separate from bust art

Checklist:

- [ ] `enemy_gate_warden_token`
- [ ] `enemy_chain_herald_token`
- [ ] `enemy_briar_sovereign_token`

### E. Icon Refresh Set

Target:
- `128x128` master
- vector-first
- transparent background

Checklist:

- [ ] `icon_attack`
- [ ] `icon_brace`
- [ ] `icon_cancel`
- [ ] `icon_confirm`
- [ ] `icon_consumable`
- [ ] `icon_durability`
- [ ] `icon_enemy_intent_attack`
- [ ] `icon_enemy_intent_heavy`
- [ ] `icon_hp`
- [ ] `icon_hunger`
- [ ] `icon_map_blacksmith`
- [ ] `icon_map_merchant`
- [ ] `icon_map_rest`
- [ ] `icon_map_start`
- [ ] `icon_node_marker`
- [ ] `icon_reward`
- [ ] `icon_settings`
- [ ] `icon_use_item`
- [ ] `icon_weapon`

---

## 5. Shared Style Rules

Keep this style language in every prompt:

- `dark forest wayfinder`
- `dark misty forest`
- `readable before atmospheric`
- `silhouette-focused`
- `stylized not realistic`
- `2D flat shading`
- `mobile-readable`
- `small-screen-first composition`
- `upper-left light source`

Shared negative language:

- `NOT photorealistic`
- `NOT anime`
- `NOT chibi`
- `NOT bright pastel`
- `NOT neon fantasy`
- `NOT pixel art`
- `NOT watercolor`
- `NOT muddy green wash`
- `NOT glossy sci-fi`
- `NOT heavy bloom`
- `NOT busy micro-detail`
- `NOT inconsistent light direction`

Palette direction:

- charcoal
- deep forest teal
- aged bronze
- guide gold
- restrained rust accent

---

## 6. Background Prompts

### 6.1 General Background Master Prompt

Use this as the base for every background family.

```text
Create a portrait mobile game background for a dark fantasy roguelite UI.

Dark Forest Wayfinder. Dark misty forest. Readable before atmospheric. Silhouette-focused. Stylized not realistic. 2D flat shading. Mobile-readable. Small-screen-first composition. Upper-left light source.

The image must feel sharp, intentional, and readable on a phone screen. Strong silhouette separation. Clear value hierarchy. Low blur reliance. No muddy wash.

Color direction: charcoal, deep forest teal, aged bronze, guide gold, restrained rust accent.

No text, no logo, no UI frame, no mockup device, no watermark.

Avoid photorealism, anime, chibi, bright pastel fantasy, neon fantasy, pixel art, watercolor, muddy green wash, glossy sci-fi, heavy bloom, busy micro-detail.
```

### 6.2 `bg_menu_*`

```text
Create a portrait mobile game background layer for a dark fantasy roguelite main menu.

Dark Forest Wayfinder. Dark misty forest. Readable before atmospheric. Silhouette-focused. Stylized not realistic. 2D flat shading. Mobile-readable. Small-screen-first composition. Upper-left light source.

Scene: a lonely forest road leading toward a distant gate or shrine silhouette, framed by layered canopy and restrained guide lights. The center vertical band must stay visually calm and readable for a main menu card. Stronger silhouettes should live near the upper third and outer edges.

Color direction: charcoal, deep forest teal, aged bronze, guide gold, restrained rust accent. Clear value separation. Crisp silhouette edges. Low blur reliance.

No text, no logo, no UI frame, no device mockup, no watermark.

Avoid photorealism, anime, chibi, bright pastel fantasy, neon fantasy, pixel art, watercolor, muddy green wash, glossy sci-fi, heavy bloom, giant centered object, washed-out fog blob.
```

Variation suffix:

- `far layer emphasis, distant forest depth, tree line, far road`
- `mid layer emphasis, gate-path silhouette, broken trunks, canopy breaks`
- `overlay layer emphasis, subtle edge framing, branch arcs, leaf silhouettes`

### 6.3 `bg_choice_*`

```text
Create a portrait mobile game background layer for a dark fantasy roguelite choice screen.

Dark Forest Wayfinder. Dark misty forest. Readable before atmospheric. Silhouette-focused. Stylized not realistic. 2D flat shading. Mobile-readable. Small-screen-first composition. Upper-left light source.

Scene: a ruin-field or waystone clearing inside a dark forest, with broken pillars, restrained guide lights, and a readable central pocket for choice cards. The center must remain lower-noise and readable. Stronger detail should live on the edges and upper third.

Color direction: charcoal, muted teal, aged bronze, guide gold, restrained rust accent. Crisp silhouette separation. Low blur reliance.

No text, no logo, no UI frame, no watermark.

Avoid loot-room clutter, giant glowing shrine, bright treasure-room gold, photoreal stone texture, noisy center detail, muddy haze.
```

Variation suffix:

- `far layer emphasis, ruin depth, distant tree line, atmospheric silhouette masses`
- `mid layer emphasis, waystone, broken pillar framing, mid-depth ruins`
- `overlay layer emphasis, edge vines, branch arcs, subtle ruin framing`

### 6.4 `bg_terminal_*`

```text
Create a portrait mobile game background layer for a dark fantasy roguelite terminal screen.

Dark Forest Wayfinder. Readable before atmospheric. Silhouette-focused. Stylized not realistic. 2D flat shading. Mobile-readable. Small-screen-first composition. Upper-left light source.

Scene: a monumental road silhouette, distant gate or obelisk forms, somber destination mood, restrained guide-light accents, broad readable middle band for a result card.

Color direction: charcoal, panel-tone darks, aged bronze, guide gold, restrained rust accent, muted teal.

No text, no logo, no UI frame, no watermark.

Avoid throne-room fantasy, heaven-light ending scene, giant skull motif, photoreal graveyard, giant centered monolith, red apocalypse wash.
```

Variation suffix:

- `far layer emphasis, distant road, horizon glow, terminal architecture mass`
- `mid layer emphasis, gate, arch, or obelisk silhouette`
- `overlay layer emphasis, subtle edge vignette, branch or ruin framing`

### 6.5 `bg_combat_*`

```text
Create a portrait mobile game combat background layer for a dark fantasy roguelite.

Dark Forest Wayfinder. Dark misty forest. Readable before atmospheric. Silhouette-focused. Stylized not realistic. 2D flat shading. Mobile-readable. Small-screen-first composition. Upper-left light source.

Scene: a dangerous forest clearing prepared for combat, with sharper ground separation, restrained ruins or trunks, and a clear central battle read. The center must remain readable for combat UI and character busts. Keep the scene cleaner than a map screen.

Color direction: charcoal, deep forest teal, aged bronze, guide gold, restrained rust accent. Crisp value contrast. Low blur reliance.

No text, no logo, no UI frame, no watermark.

Avoid overgrown clutter in the center, giant setpiece in the middle, photoreal gore, anime combat scene, bright fantasy saturation, muddy haze.
```

Variation suffix:

- `far layer emphasis, forest depth, distant trunks, battle clearing silhouette`
- `mid layer emphasis, cleaner combat ground, broken trunks, ruin edges`
- `overlay layer emphasis, edge framing only, no center obstruction`

---

## 7. Player Bust Prompt

Recommended tool:
- `Leonardo`

Target:
- `1024x1536`
- transparent background

Prompt:

```text
Create a transparent-background character bust for a dark fantasy roguelite RPG.

Dark Forest Wayfinder. Silhouette-focused. Stylized not realistic. 2D flat shading. Mobile-readable. Upper-left light source. Clear chest-up portrait composition.

Subject: the player character, a lone road-worn wayfinder adventurer. Slightly left-facing or straight-on. Strong readable head-and-shoulder silhouette. Clear cloak or mantle shape. Distinct collar, shoulder shape, and simple gear silhouette. A restrained relic-fantasy look, not ornate, not heroic-anime, not realistic armor rendering.

Mood: tired but determined traveler in a dark forest world. Clean silhouette first, face detail second. The bust must still read clearly on a phone-sized combat UI.

Palette: charcoal, muted teal, aged bronze, guide gold, restrained rust accent, light bone or cloth highlights.

Transparent background. No text. No frame. No watermark. No floating props.
```

Negative:

```text
photorealistic face, anime hero, chibi proportions, hyper-detailed metal, soft watercolor edges, giant weapon covering the face, muddy low-contrast silhouette, bright fantasy colors, blurry shoulder line
```

Checklist:

- [ ] silhouette reads in 2 seconds
- [ ] head and shoulder shape is clear
- [ ] still readable on a small screen
- [ ] detail level is restrained

---

## 8. Enemy Bust Prompt

Recommended tool:
- `Leonardo`

Target:
- `1024x1536`
- transparent background

Common enemy master prompt:

```text
Create a transparent-background enemy bust for a dark fantasy roguelite RPG.

Dark Forest Wayfinder. Silhouette-focused. Stylized not realistic. 2D flat shading. Mobile-readable. Upper-left light source. Clear chest-up portrait composition.

The subject must read clearly in two seconds on a phone-sized combat screen. Prioritize silhouette, headgear, shoulder width, weapon mass, and family readability over face detail. The bust should feel threatening and distinct, but still belong to the same art family as the player bust.

Palette: charcoal, muted teal, aged bronze, restrained rust accent, guide gold highlights, limited light-bone edge accents.

Transparent background. No text. No frame. No watermark.
```

Enemy-specific subject lines:

- `enemy_ash_gnawer_bust`: feral scavenger creature, lean jaw silhouette, gnawing menace
- `enemy_barbed_hunter_bust`: hunter silhouette, barbed weapon presence, narrow predatory head shape
- `enemy_bone_raider_bust`: raider with bone motif, rough helmet or skull framing
- `enemy_briar_alchemist_bust`: alchemist silhouette, bottle or satchel cues, thorn-wrapped shoulders
- `enemy_briar_sovereign_bust`: boss-level briar ruler silhouette, broader crown or antler plant mass
- `enemy_chain_herald_bust`: boss herald silhouette, chain-linked shoulders, tall ritual profile
- `enemy_chain_trapper_bust`: trapper silhouette, hook or chain weight, narrow tense posture
- `enemy_drain_adept_bust`: ritual caster silhouette, gaunt face area, draining relic cues
- `enemy_dusk_pikeman_bust`: long pike presence, rigid military silhouette
- `enemy_ember_harrier_bust`: hotter accent read, winglike cloth or ember-torn silhouette
- `enemy_forest_brigand_bust`: rugged bandit silhouette, hood or layered scavenged gear
- `enemy_gate_warden_bust`: heavy guardian silhouette, frontal boss pose, clear headgear and weapon
- `enemy_grave_chanter_bust`: ritual chanter silhouette, hooded or shrine-like head frame
- `enemy_lantern_cutpurse_bust`: sneaky thief silhouette, lantern or hook cue, light-footed shape
- `enemy_mossback_ram_bust`: beast-like mass, ram head or horn silhouette
- `enemy_rotbound_reaver_bust`: rotted heavy raider silhouette, brutal weapon mass
- `enemy_skeletal_hound_bust`: houndlike enemy silhouette, elongated jaw and bony frame
- `enemy_venom_scavenger_bust`: poison scavenger silhouette, hooked posture, toxic cues

Negative:

```text
photoreal monster, anime villain, soft watercolor edge, unreadable face blob, muddy silhouette, giant centered weapon hiding the head, too many tiny ornaments, bright fantasy saturation
```

Checklist:

- [ ] reads as the same family
- [ ] clearly different from other enemies
- [ ] readable in 2 seconds on a small screen
- [ ] head / shoulder / weapon shape is clear

---

## 9. Boss Token Prompt

Recommended tool:
- `Leonardo`

Target:
- `256x256`
- transparent background

Common boss token master prompt:

```text
Create a transparent-background boss token for a dark fantasy roguelite RPG.

Dark Forest Wayfinder. Silhouette-focused. Stylized not realistic. 2D flat shading. Mobile-readable. Upper-left light source.

This is a separate token asset, not a reduced bust. Show head plus upper shoulders only. Strong compact silhouette. The token must stay readable at small size and feel like it belongs to the same family as the matching boss bust.

Use a contained emblem-like composition suitable for a circular or rounded-square frame. Transparent background. No text. No watermark.
```

Boss-specific subject lines:

- `enemy_gate_warden_token`: heavy frontal gate guardian, stern headgear, dominant weapon cue
- `enemy_chain_herald_token`: chain-linked herald, ritual profile, sharp ceremonial silhouette
- `enemy_briar_sovereign_token`: briar-crowned sovereign, plant-thorn crown mass, regal hostile silhouette

Negative:

```text
miniature bust crop, photoreal portrait, icon emoji style, unreadable detail, muddy silhouette, bright cartoon colors, glossy mobile app icon
```

Checklist:

- [ ] still feels readable at `64x64`
- [ ] boss silhouette is clear
- [ ] matches the bust family
- [ ] feels like a true token, not a tiny portrait crop

---

## 10. Icon Pack Prompt

Recommended tool:
- `Recraft`

Target:
- `128x128` master
- vector-first
- transparent background

Common master prompt:

```text
Create a cohesive vector game icon set for a dark fantasy roguelite UI.

Dark Forest Wayfinder. Silhouette-first. Minimal inner detail. Clean vector shapes. Mobile-readable. Upper-left light source. Consistent line weight. 2D flat shading. Transparent background.

Canvas intent: 128x128 master icon, safe centered composition, strong readable silhouette, no unnecessary detail.

Palette: aged bronze, muted teal, light bone highlight, system-color accent only where needed. Use at most 3 colors per icon. Keep the family visually consistent.

The icon set should feel like the same game as a dark forest roguelite with readable relic-style UI. Do not make them glossy, realistic, cute, or sci-fi.
```

Icon descriptions:

- `icon_attack`: attack action symbol, direct combat read
- `icon_brace`: defense/brace symbol, stable and protective silhouette
- `icon_cancel`: cancel/back/close symbol in dark relic UI language
- `icon_confirm`: confirm/accept symbol in dark relic UI language
- `icon_consumable`: bag, vial, or usable-item silhouette
- `icon_durability`: worn shield, riveted plate, or maintenance symbol
- `icon_enemy_intent_attack`: hostile intent marker, direct attack read
- `icon_enemy_intent_heavy`: heavy attack intent marker, stronger mass read
- `icon_hp`: health symbol, heart-emblem or blood-vial-inspired
- `icon_hunger`: ration/loaf/meal silhouette
- `icon_map_blacksmith`: forge/hammer/anvil map marker
- `icon_map_merchant`: trader/shop marker
- `icon_map_rest`: rest/camp marker
- `icon_map_start`: origin/start marker
- `icon_node_marker`: generic node marker
- `icon_reward`: reward/relic/loot marker
- `icon_settings`: settings/utility symbol in the same visual language
- `icon_use_item`: use-item action symbol
- `icon_weapon`: weapon inventory/action symbol

Negative:

```text
glossy app icon, emoji style, neon, sci-fi HUD, overly thin lines, too much detail, realistic metal texture, inconsistent perspective, bright pastel, cartoon mobile game
```

Checklist:

- [ ] same line weight
- [ ] same light direction
- [ ] same palette behavior
- [ ] readable at small size
- [ ] feels like the same game

---

## 11. First-Day Mini Plan

Only do these today:

- [ ] `bg_menu_far`
- [ ] `bg_menu_mid`
- [ ] `bg_menu_overlay`
- [ ] `bg_choice_far`
- [ ] `bg_choice_mid`
- [ ] `bg_choice_overlay`

After that, bring the results back.

I will help you filter:

- which ones are on the right direction
- which ones are too blurry or tonally wrong
- which ones are most runtime-usable

---

## 12. How To Use This File

Use this file like this:

1. go to the relevant asset family section
2. copy the prompt
3. paste it into the external tool
4. generate `2-3` variants
5. mark the checklist
6. collect the results
7. bring them back here
8. we review before integration

Use this as a production worksheet, not as authority.
