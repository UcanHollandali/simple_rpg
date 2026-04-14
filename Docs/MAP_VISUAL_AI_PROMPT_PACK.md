# SIMPLE RPG - Map Visual AI Prompt Pack

## Status

- This file is a production brief for external third-party AI-assisted generation of modular `Map Composer V2` art inputs.
- Authority remains:
  - `Docs/VISUAL_AUDIO_STYLE_GUIDE.md`
  - `Docs/ASSET_PIPELINE.md`
  - `Docs/ASSET_LICENSE_POLICY.md`
  - `Docs/MAP_COMPOSER_V2_ASSET_REQUIREMENTS.md`
- This file does not redefine runtime map gameplay truth, node meaning, map icons, or the walker family.
- This file is model-agnostic on purpose. Use plain-language prompts, not tool-specific flags or syntax.

## Continuation Gate

- touched owner layer: `workflow/docs + asset production brief`
- authority doc: `Docs/VISUAL_AUDIO_STYLE_GUIDE.md` + `Docs/ASSET_PIPELINE.md` + `Docs/ASSET_LICENSE_POLICY.md`
- impact: `runtime truth yok / save shape yok / asset-provenance yok`
- minimum validation set: `design-only prompt/spec output`

## Certain Repo Facts

These are repo facts taken from the current authority/reference docs and the current asset tree.

- `Map Composer V2` wants modular composition assets, not one full-screen baked map board image.
- The required environmental families named by the repo are:
  - `ui_map_v2_trail_*`
  - `ui_map_v2_clearing_*`
  - `ui_map_v2_canopy_*`
  - `ui_map_v2_prop_*`
  - `ui_map_v2_landmark_*`
  - optional `ui_map_v2_foreground_*`
- The repo already has map-facing backdrop assets:
  - `Assets/Backgrounds/bg_map_far.png`
  - `Assets/Backgrounds/bg_map_mid.png`
  - `Assets/Backgrounds/bg_map_overlay.png`
- The repo already has walker assets:
  - `Assets/UI/Map/Walker/ui_map_walker_idle.svg`
  - `Assets/UI/Map/Walker/ui_map_walker_walk_a.svg`
  - `Assets/UI/Map/Walker/ui_map_walker_walk_b.svg`
- The repo already has overlay-facing map icon assets, including:
  - `icon_map_start`
  - `icon_attack`
  - `icon_reward`
  - `icon_map_rest`
  - `icon_map_merchant`
  - `icon_map_blacksmith`
  - `icon_confirm`
  - `icon_enemy_intent_heavy`
  - `icon_node_marker`
- Current style authority locks the project to `Dark Forest Wayfinder`:
  - dark and misty, not muddy
  - readable before atmospheric
  - stylized before realistic
  - silhouette-focused
  - `2D flat shading`
- The style guide's reusable prompt anchors are already defined:
  - `dark forest wayfinder, dark misty forest, readable UI contrast`
  - `silhouette-focused, stylized not realistic, 2D flat shading`
  - `lone traveler seeking a path, distant guide lights, layered depth`
  - `mobile-readable, small-screen-first composition`
- `Map Composer V2` design and asset docs already state that:
  - the board should read as a local forest pocket
  - visible trail masks connect local clearings
  - hidden nodes must stay hidden
  - overlay/UI remains responsible for node family and state readability
  - landmark accents must be used sparingly, not one bespoke asset per node family
- AI-assisted visual generation is allowed for concept exploration, placeholders, variation passes, and background exploration, but raw AI output must not go directly into runtime without human review.
- `SourceArt/Generated/` is the raw external-generation lane, `SourceArt/Edited/` is the cleanup lane, and `Assets/` only receives reviewed runtime exports.

## Recommended Working Rules

These are production recommendations, not current repo facts.

- Treat every target resolution below as a `source-master` target for `SourceArt/Generated/`, not as a direct runtime import size.
- Ask for one isolated asset per prompt, not a sprite sheet and not a full board composition.
- Keep the prompt focused on a reusable cutout or segment with generous padding around it.
- If the external provider cannot export alpha:
  - render on a flat single-color matte background
  - keep that background untextured and unlit
  - remove it during cleanup in `SourceArt/Edited/`
- Do not ask the model for:
  - node icons
  - labels
  - text
  - UI rings
  - embedded markers
  - full-screen map scenes
  - gameplay symbols
- Prefer neutral asset meaning in the art itself. Runtime and UI should decide what a node means.
- Do not mirror assets if that flips the locked upper-left light direction in a visible way.

## Shared Global Prompt Block

Recommended shared wording to reuse at the start of every family prompt:

```text
Create one modular 2D source asset for a Godot 4 roguelite RPG map composer.
Camera: exact top-down orthographic view from directly above at 90 degrees.
Style: dark forest wayfinder, dark misty forest, silhouette-focused, stylized not realistic, 2D flat shading, readable before atmospheric, mobile-readable contrast.
Composition: one isolated reusable asset only, centered with clean padding, no text, no UI, no characters, no embedded node marker, no map icon, no full scene, no full-screen background.
Lighting: consistent upper-left light direction.
```

## Family 1 - Canopy Cluster Family

### Certain tie-in

- This family is required by `Docs/MAP_COMPOSER_V2_ASSET_REQUIREMENTS.md`.
- Repo purpose: hide unreadable space and frame the local pocket.
- Repo direction: large / medium / small silhouette clusters.

### Recommended production spec

- target resolution: `1024x1024` source master per cluster; allow `1536x1536` only for extra-large edge-framing clusters
- transparent vs opaque export rule: transparent preferred; fallback opaque export only on a flat cleanup matte
- tileability / repeatability: not seamless-tileable; repeatable as modular cutout clusters
- exact top-down restriction: absolute overhead canopy mass, only top surfaces visible, no horizon, no visible trunk sides
- no-perspective / no-isometric / no side-view rule: reject any camera tilt, vanishing point, angled tree trunks, side-facing branches, or diorama view
- exact style anchors:
  - `dark forest wayfinder`
  - `dark misty forest`
  - `silhouette-focused`
  - `2D flat shading`
  - `readable before atmospheric`
  - `dense canopy mass framing a forest pocket`
  - palette bias: charcoal greens, deep teal shadow, restrained warm highlight
- anti-pattern list:
  - individual botanical studies
  - side-view tree crowns
  - photoreal leaf texture
  - bright fairy-forest glow
  - visible hidden-node circles in the canopy gaps
  - giant single hero tree that reads as a landmark by itself
- recommended variant count: `9-12`
  - suggested split: `3` small, `4` medium, `2-3` large, `1-2` edge-heavy silhouettes

### Master prompt template

```text
Create one modular 2D source asset for a Godot 4 roguelite RPG map composer.
Camera: exact top-down orthographic view from directly above at 90 degrees.
Style: dark forest wayfinder, dark misty forest, silhouette-focused, stylized not realistic, 2D flat shading, readable before atmospheric, mobile-readable contrast.
Subject: a [size_class] forest canopy cluster used to conceal unreadable map space and frame a local path pocket.
Composition: one isolated canopy cluster only on a transparent background, centered with generous padding, irregular silhouette, reusable as a modular cutout, no text, no UI, no characters, no embedded node marker, no path icon, no symbols, no full scene, no full-screen background.
Material and color: clustered treetop leaf mass, deep charcoal-green foliage, muted teal-shadowed depth, restrained warm edge highlight from upper-left light.
Mood: moody but readable, forest pressure around a navigable clearing, not muddy, not magical.
Deliver a single reusable canopy cutout, not a map screenshot.
```

### Negative prompt / avoid list

```text
no perspective, no isometric, no side view, no horizon, no visible tree trunk sides, no photorealism, no watercolor, no anime, no pixel art, no neon, no fairy lights, no magic circle gaps, no UI frame, no node icon, no quest marker, no full map, no background scene
```

### Review checklist

- The asset reads as treetop mass from directly above within two seconds.
- The silhouette is strong enough to hide space without looking like a blob of noise.
- The piece frames a pocket but does not accidentally reveal hidden node sockets.
- The light direction still reads upper-left.
- The edges are clean enough for cutout use after cleanup.
- The palette matches the style guide and avoids muddy green wash.

### Runtime integration notes

- Use canopy only outside the visible clearing and trail union.
- Prefer cluster stacking over one giant canopy sheet.
- Keep canopy below overlay icons and below the walker.
- Do not use canopy to encode node family, rarity, or gameplay secrets.
- Avoid mirroring if it visibly reverses lighting.

## Family 2 - Trail Mask / Trail Edge Family

### Certain tie-in

- This family is required by `Docs/MAP_COMPOSER_V2_ASSET_REQUIREMENTS.md`.
- Repo purpose: spline trail fill, edge breakup, and worn-path readability.
- Repo direction: modular trail masks and edge brushes, not ruler-straight UI lines.

### Recommended production spec

- target resolution: `1536x768` source master per segment
- transparent vs opaque export rule: transparent preferred; fallback opaque export only on a flat cleanup matte
- tileability / repeatability: yes for segment stitching; each segment should continue cleanly at both ends
- exact top-down restriction: absolute overhead ground read with only top surfaces visible
- no-perspective / no-isometric / no side-view rule: reject any road vanishing point, side berms, raised side walls, or angled camera read
- exact style anchors:
  - `dark forest wayfinder`
  - `lone traveler seeking a path`
  - `worn earth trail through forest floor`
  - `slightly irregular trail edge`
  - `readable before atmospheric`
  - `2D flat shading`
  - palette bias: worn earth browns, desaturated bronze-dust highlights, subdued teal-shadowed edges
- anti-pattern list:
  - cobblestone road
  - fantasy glowing lane
  - painted arrow directions
  - footprints as gameplay hints
  - trail ending in a node socket or icon circle
  - thick black outline like UI chrome
- recommended variant count: `4-6`
  - suggested first set: straight narrow, straight medium, gentle left curve, gentle right curve, soft S-curve, broken edge patch

### Master prompt template

```text
Create one modular 2D source asset for a Godot 4 roguelite RPG map composer.
Camera: exact top-down orthographic view from directly above at 90 degrees.
Style: dark forest wayfinder, lone traveler seeking a path, silhouette-focused, stylized not realistic, 2D flat shading, readable before atmospheric, mobile-readable contrast.
Subject: a single [segment_profile] forest trail segment used as a reusable path mask between clearings.
Composition: one isolated trail segment only on a transparent background, centered with generous padding, clean continuation at both ends for stitching, no text, no UI, no characters, no embedded node marker, no road signs, no full scene.
Material and color: worn earth and flattened leaf litter, irregular trail shoulders, subtle lighter center wear, restrained warm highlight from upper-left light, no hard border stroke.
Mood: a readable human-made path through a dark forest pocket, grounded and non-magical.
Deliver a single reusable trail cutout, not a map screenshot.
```

### Negative prompt / avoid list

```text
no perspective road, no isometric, no side berms, no cobblestone, no paving stones, no glowing runes, no arrows, no footprints as markers, no node circle, no UI line, no full board, no full scene, no photorealism, no watercolor, no neon
```

### Review checklist

- The segment reads as a worn forest trail, not a road or trench.
- Both ends can visually stitch into another segment or under a clearing.
- Edge breakup is irregular but still clean at runtime scale.
- The center line is readable without needing a glow effect.
- There is no implied node socket, arrow, or hidden mechanic cue.
- The asset remains legible under overlay icons and the walker.

### Runtime integration notes

- Use trail pieces as modular spline-following segments or masks, not as fixed whole-route art.
- Hide segment endpoints under clearing underlays.
- Keep trail below props, overlays, and the walker.
- Avoid per-node color coding baked into the art.
- Allow engine-side tint only if it stays subtle and does not become gameplay truth.

## Family 3 - Clearing / Pocket Underlay Family

### Certain tie-in

- This family is required by `Docs/MAP_COMPOSER_V2_ASSET_REQUIREMENTS.md`.
- Repo purpose: start/node/boss pocket readability.
- Repo direction: at least small / medium / large underlay variants.

### Recommended production spec

- target resolution: `1536x1536` source master per underlay
- transparent vs opaque export rule: transparent preferred; fallback opaque export only on a flat cleanup matte
- tileability / repeatability: not seamless-tileable; repeatable as overlapping pocket cutouts
- exact top-down restriction: absolute overhead worn-ground read with only top surfaces visible
- no-perspective / no-isometric / no side-view rule: reject any crater wall side faces, angled roots, side-view rocks, or camera tilt
- exact style anchors:
  - `dark forest wayfinder`
  - `forest pocket`
  - `clearing under dense canopy`
  - `worn earth and flattened leaf litter`
  - `readable before atmospheric`
  - `2D flat shading`
  - palette bias: muted earth, dark charcoal fringe, restrained warm guide-light edge
- anti-pattern list:
  - magic circle
  - glowing summoning pad
  - explicit node socket
  - carved symbol or rune
  - perfectly round disc
  - giant empty arena that breaks compact portrait framing
- recommended variant count: `3-5`
  - suggested first set: small, medium, large, large-rimmed, elongated junction pocket

### Master prompt template

```text
Create one modular 2D source asset for a Godot 4 roguelite RPG map composer.
Camera: exact top-down orthographic view from directly above at 90 degrees.
Style: dark forest wayfinder, forest pocket under canopy, silhouette-focused, stylized not realistic, 2D flat shading, readable before atmospheric, mobile-readable contrast.
Subject: a [size_class] clearing underlay used to create a local path pocket around a node and merge with nearby trail segments.
Composition: one isolated clearing underlay only on a transparent background, centered with generous padding, irregular organic silhouette, reusable as a modular cutout, no text, no UI, no characters, no embedded node marker, no icon socket, no full scene.
Material and color: worn earth, flattened leaf litter, subtle rim breakup, slight root or moss edge texture kept soft and readable, restrained upper-left light.
Mood: safe-enough open ground in a dark forest, atmospheric but not magical, compact and mobile-readable.
Deliver a single reusable clearing cutout, not a map screenshot.
```

### Negative prompt / avoid list

```text
no magic circle, no glowing ring, no summoning pad, no carved rune, no icon socket, no perspective crater, no isometric, no side wall, no full arena, no full map, no UI ring, no text, no photorealism, no watercolor, no neon
```

### Review checklist

- The asset reads as open worn ground, not as a spell effect or button.
- The silhouette helps form a local pocket without becoming a perfect circle.
- The clearing can host an overlay icon without looking like the icon is baked into the art.
- The edges can merge cleanly into trail and canopy shapes.
- The piece stays readable in portrait scale and does not balloon into a full-board patch.
- Nothing in the art alone tells the player whether the node is combat, reward, support, or boss.

### Runtime integration notes

- Use clearing size by runtime node role, but keep actual gameplay meaning in overlay/UI.
- Resolved-node treatment should come from tint, opacity, or UI state, not from a separate symbol baked into the clearing art.
- Keep clearings under overlay icons, state chips, and the walker.
- Use clearing overlap to help build the visible pocket union.
- Do not attach text labels or family symbols to the underlay.

## Family 4 - Forest Prop Family

### Certain tie-in

- This family is required by `Docs/MAP_COMPOSER_V2_ASSET_REQUIREMENTS.md`.
- Repo purpose: roots, rocks, shrubs, broken logs, and edge-shaping variation.
- Repo direction: support edge framing and variation, not hidden mechanic encoding.

### Recommended production spec

- target resolution: `1024x1024` source master per prop; allow `1536x1024` for long horizontal props only
- transparent vs opaque export rule: transparent preferred; fallback opaque export only on a flat cleanup matte
- tileability / repeatability: not seamless-tileable; repeatable as isolated scatter props
- exact top-down restriction: absolute overhead prop read, top surfaces only
- no-perspective / no-isometric / no side-view rule: reject any side-facing stumps, profile logs, angled rocks, or cinematic camera tilt
- exact style anchors:
  - `dark forest wayfinder`
  - `silhouette-first forest props`
  - `roots, shrubs, rocks, broken logs`
  - `2D flat shading`
  - `readable before atmospheric`
  - `edge framing for a forest pocket`
  - palette bias: charcoal bark, muted earth, restrained bronze-highlight edge, limited teal shadow
- anti-pattern list:
  - treasure chest
  - weapon rack
  - signpost arrow
  - campfire as route signal
  - giant decorative mushrooms
  - props shaped like UI badges or icons
- recommended variant count: `10-16`
  - suggested balance: `3-4` roots, `2-3` shrubs, `2-3` rock clusters, `2-3` broken logs, `1-2` stump clusters

### Master prompt template

```text
Create one modular 2D source asset for a Godot 4 roguelite RPG map composer.
Camera: exact top-down orthographic view from directly above at 90 degrees.
Style: dark forest wayfinder, silhouette-focused, stylized not realistic, 2D flat shading, readable before atmospheric, mobile-readable contrast.
Subject: one isolated [prop_subject] used to frame a forest path pocket without carrying gameplay meaning.
Composition: one modular prop only on a transparent background, centered with clean padding, readable silhouette, no text, no UI, no characters, no embedded node marker, no map symbol, no full scene.
Material and color: top-down forest prop surfaces only, dark bark or stone, muted earth palette, restrained upper-left highlight, subtle edge wear, no photoreal bark detail.
Mood: grounded forest debris and framing material, atmospheric but practical.
Deliver a single reusable prop cutout, not a map screenshot.
```

### Negative prompt / avoid list

```text
no perspective, no isometric, no side view, no treasure chest, no signpost, no arrows, no skull emblem, no weapons, no camp icon, no bright flowers, no giant mushrooms, no UI badge shape, no full scene, no photorealism, no watercolor, no neon
```

### Review checklist

- The prop reads clearly from overhead and keeps a simple silhouette.
- It helps frame space without stealing focus from the route or overlay icon.
- It does not look like a collectible, interactable, or node marker by itself.
- It can sit near trail or canopy edges without visual collision.
- Texture detail stays stylized and controlled at runtime scale.
- The light direction remains consistent with the rest of the set.

### Runtime integration notes

- Use props near pocket borders, not in the center of tap targets.
- Keep props outside the walker lane and trail centerline.
- Use density and placement to differentiate scaffold mood, not bespoke prop meaning.
- Do not rely on props alone to signal boss, key, reward, or support nodes.
- Prefer rotation over mirroring if a transform is needed and the light read stays intact.

## Family 5 - Route Landmark Accent Family

### Certain tie-in

- This family is required by `Docs/MAP_COMPOSER_V2_ASSET_REQUIREMENTS.md`.
- Repo purpose: boss approach, key hint, and guide-light emphasis.
- Repo direction: use sparingly, not one bespoke landmark per node family.

### Recommended production spec

- target resolution: `1024x1024` source master per accent
- transparent vs opaque export rule: transparent preferred; fallback opaque export only on a flat cleanup matte
- tileability / repeatability: not seamless-tileable; repeat as sparse accents only
- exact top-down restriction: absolute overhead accent read, top surfaces only
- no-perspective / no-isometric / no side-view rule: reject any standing sign seen from the side, gate facade, oblique arch, or cinematic angle
- exact style anchors:
  - `dark forest wayfinder`
  - `distant guide lights`
  - `subtle route emphasis`
  - `stylized not realistic`
  - `2D flat shading`
  - `readable before atmospheric`
  - palette bias: guide gold and aged bronze for guidance, restrained rust accent for danger, dark charcoal base
- anti-pattern list:
  - explicit boss skull emblem
  - key icon carved into the art
  - quest arrow
  - giant exclamation mark
  - full gate set-piece that becomes the whole screen
  - anything that explains gameplay meaning without overlay/UI support
- recommended variant count: `4-6`
  - suggested first set: guide-light stump, weathered waystone fragment, twisted root arch fragment, ominous stone cluster, muted danger accent, soft route beacon

### Master prompt template

```text
Create one modular 2D source asset for a Godot 4 roguelite RPG map composer.
Camera: exact top-down orthographic view from directly above at 90 degrees.
Style: dark forest wayfinder, distant guide lights, silhouette-focused, stylized not realistic, 2D flat shading, readable before atmospheric, mobile-readable contrast.
Subject: one isolated [accent_subject] used as a sparse route landmark accent near a path pocket.
Composition: one modular accent only on a transparent background, centered with clean padding, elegant silhouette, no text, no UI, no characters, no embedded node marker, no explicit gameplay icon, no full scene.
Material and color: weathered forest or stone material, restrained guide-light or danger tint, upper-left light, subtle emphasis without becoming a UI object.
Mood: wayfinding cue inside a dark forest, atmospheric but restrained, useful as emphasis rather than explanation.
Deliver a single reusable landmark accent cutout, not a map screenshot.
```

### Negative prompt / avoid list

```text
no perspective, no isometric, no side-view sign, no giant gate, no arrow sign, no skull badge, no key icon, no exclamation mark, no glowing quest marker, no UI frame, no full scene, no photorealism, no watercolor, no neon
```

### Review checklist

- The accent reads as environmental emphasis, not as a UI marker.
- The silhouette is strong but not loud enough to replace overlay meaning.
- The piece can sit near a route without forcing gameplay interpretation on its own.
- Highlight color remains restrained and style-guide aligned.
- The asset stays modular and does not become a full landmark scene.
- The top-down read remains clean at runtime scale.

### Runtime integration notes

- Use landmarks sparsely at important route moments only.
- If a landmark is removed, the player should still understand the route from overlay/UI truth.
- Prefer shared neutral landmark shapes plus placement and tint differences over bespoke boss/key art families.
- Keep landmarks below overlay icons and outside tap target centers.
- Do not place one landmark on every visible node.

## Family 6 - Optional Foreground Overlay Family

### Certain tie-in

- This family is optional baseline in `Docs/MAP_COMPOSER_V2_ASSET_REQUIREMENTS.md`.
- Repo purpose: light depth and framing only if readability remains strong.

### Recommended production spec

- target resolution: `2048x1024` source master per overlay strip
- transparent vs opaque export rule: transparent strongly preferred; fallback opaque export only on a flat cleanup matte
- tileability / repeatability: not seamless-tileable; repeat as sparse edge-framing overlays only
- exact top-down restriction: absolute overhead branch, leaf, or mist-fringe read, cropped from the screen edge inward
- no-perspective / no-isometric / no side-view rule: reject any side-hanging branch, frontal vine curtain, horizon fog wall, or camera tilt
- exact style anchors:
  - `dark forest wayfinder`
  - `layered depth`
  - `thin foreground framing`
  - `stylized not realistic`
  - `2D flat shading`
  - `readable before atmospheric`
  - palette bias: deep charcoal foliage with restrained transparency and minimal warm highlight
- anti-pattern list:
  - thick vignette
  - center-screen fog bank
  - heavy blur
  - screen-covering branch mat
  - side-view hanging vines
  - anything that blocks route reading or the key/read panels
- recommended variant count: `3-4`
  - suggested split: top edge branch, corner leaf sweep, side-edge mist fringe, sparse crossed branch

### Master prompt template

```text
Create one modular 2D source asset for a Godot 4 roguelite RPG map composer.
Camera: exact top-down orthographic view from directly above at 90 degrees.
Style: dark forest wayfinder, layered depth, silhouette-focused, stylized not realistic, 2D flat shading, readable before atmospheric, mobile-readable contrast.
Subject: one [overlay_profile] foreground overlay used only for thin edge framing around a forest path pocket.
Composition: one isolated overlay strip only on a transparent background, edge-cropped and open toward the center, no text, no UI, no characters, no embedded node marker, no map icon, no full scene.
Material and color: top-down leaves, branches, or mist-fringe only, dark charcoal mass, subtle transparency, restrained upper-left highlight, no dominant blur.
Mood: atmospheric framing at the edge of the board, light-touch and non-obstructive.
Deliver a single reusable foreground overlay cutout, not a full-screen map image.
```

### Negative prompt / avoid list

```text
no perspective, no isometric, no side-view vines, no full fog wall, no thick vignette, no center-screen occlusion, no heavy blur, no UI frame, no node icon, no full map, no full scene, no photorealism, no watercolor, no neon
```

### Review checklist

- The overlay frames from the edge inward and leaves the center readable.
- The piece feels optional; the board would still work without it.
- Transparency and mass are restrained enough for portrait readability.
- The overlay does not look like a separate biome layer or weather effect.
- It does not compete with overlay icons, walker readability, or top-right map UI.
- The top-down read remains clear with no side-view drift.

### Runtime integration notes

- Treat this family as lowest priority and easiest to disable.
- Keep foreground overlays below overlay icons and usually below the walker.
- Never let foreground pieces cross active tap targets or the top-right status/read panels.
- Use one or two pieces at most on a board state.
- If readability drops, cut this family before cutting clearings or trails.

## Recommended First Production Order

This is a production recommendation, not a repo fact.

1. `ui_map_v2_clearing_*`
2. `ui_map_v2_trail_*`
3. `ui_map_v2_canopy_*`
4. `ui_map_v2_prop_*`
5. `ui_map_v2_landmark_*`
6. optional `ui_map_v2_foreground_*`

Reason:

- `clearing` establishes the local pocket language first.
- `trail` then makes adjacency feel walked rather than diagrammatic.
- `canopy` is most effective after the pocket silhouette exists.
- props and landmarks should decorate a readable base, not define it.

## Runtime And Pipeline Reminder

These are production reminders, not new authority.

- Put raw external outputs in `SourceArt/Generated/`.
- Clean, cut out, normalize, and de-duplicate in `SourceArt/Edited/`.
- Add truthful manifest provenance before any runtime import.
- Do not promote raw AI output straight into `Assets/`.
- Keep current icon and walker families as reused overlay/actor layers unless a later scoped task says otherwise.
