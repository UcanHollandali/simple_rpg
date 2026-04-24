# SIMPLE RPG - Map Asset Brief Pack

Last updated: 2026-04-24

## Status

- This is a candidate-generation brief pack, not an authority document.
- Use with `Docs/ASSET_PIPELINE.md`, `Docs/ASSET_LICENSE_POLICY.md`, and `Docs/VISUAL_AUDIO_STYLE_GUIDE.md`.
- Generated results are candidates only. They are not final art and not structural proof.
- Runtime integration still requires manifest/provenance rows and screenshot review.

## Global Requirements

- Dark Forest Wayfinder mood.
- Stylized, silhouette-first, mobile-readable.
- Transparent background.
- No baked board image.
- No UI icon, no flat badge, no circle token.
- No text, letters, numbers, arrows, exclamation marks, or quest markers.
- No hard rectangular frame unless the object itself is a gate, stall, sign, slab, or tent.
- No large glow that hides roads, pockets, or route choices.
- No candidate may imply gameplay rules beyond the runtime socket that places it.

## Key Landmark Prompt

Create a small map landmark asset for a key shrine or keyed reliquary in a dark forest wayfinder map.
The object should read as a physical prop in the world: a stone or wood shrine holding a key-shaped relic, with aged bronze, muted gold, charcoal, and a small teal accent.
It must remain readable at small mobile size as a silhouette, with one clear keyed form and a grounded base.
Use a transparent background and a centered `128x128` composition.
Make it rotation-tolerant and avoid thin details.

Negative examples:
- no UI key icon
- no flat badge
- no circle token
- no glowing quest marker
- no text

## Boss Gate Prompt

Create a small boss gate landmark asset for a dark forest wayfinder map.
The object should feel like a physical threshold: paired posts, crossed stakes, sword altar, or compact gate silhouette with rust danger accents and aged bronze edges.
It must read as a dangerous destination prop, not as a combat button or warning badge.
Use a transparent background and a centered `128x128` composition.
Keep the silhouette strong when drawn around `18-38px` and make it safe to rotate.

Negative examples:
- no UI skull badge
- no flat red circle
- no combat icon token
- no giant glow
- no text or warning mark

## Merchant / Rest Prompt

Create a small support landmark asset family for a dark forest wayfinder map.
Produce either a merchant stall or a rest camp prop.
Merchant should read as a compact canvas stall, crate table, hanging goods, or waypost shop in muted teal, bronze, and dark wood.
Rest should read as a small campfire, bedroll, tent, or safe camp marker with warm ember accents.
Use a transparent background and a centered `128x128` composition.
The asset must read as a world prop, not as a menu icon.

Negative examples:
- no shop UI icon
- no flat tent badge
- no circular safe-zone token
- no text or coin symbol
- no oversized fire glow

## Path Brush Prompt

Create a small modular path-surface brush for a dark forest wayfinder map.
It should look like a worn earthen road fragment with irregular edges, aged bronze/warm dirt highlights, and a few subtle stones or root marks.
Use a transparent background and a horizontal `128x64` composition designed to rotate along a path direction.
The brush must support roads without becoming the road truth; avoid hard ends and avoid a stamped rectangle.

Negative examples:
- no flat line icon
- no railroad track
- no rectangular tile border
- no bright yellow stripe
- no object that looks like a button or progress bar

## Decor / Filler Prompt

Create a small route-edge decor/filler stamp for a dark forest wayfinder map.
It should be a sparse world prop such as roots, stones, broken twigs, tiny shrubs, or a lantern remnant.
Use a transparent background and a centered `96x96` composition.
The asset must add texture to negative space without competing with node landmarks or road readability.

Negative examples:
- no UI ornament
- no flat badge
- no circle token
- no full canopy blob
- no large dark oval shadow

## Candidate Review Checklist

- Reads at runtime scale before zooming.
- Has transparent background and no token frame.
- Works when rotated by socket metadata.
- Does not cover route throats, current-node read, or pocket shape.
- Can be explained as candidate/provisional art with truthful provenance.
- Keeps `replace_before_release=yes` if promoted into runtime.
