# Map Socket Production Asset Brief

Generated: 2026-04-25

Source: live GDScript render/socket metadata, not archived prompt packs or retired art briefs.

## Snapshot Inputs

- Generator: `Tools/map_socket_asset_brief_export.gd`
- Board size: `920x1180`
- Stages: `1, 2, 3`
- Seeds: `11, 29, 41, 73, 97`
- Progress steps: `0, 3, 6`
- Scenarios: `45`
- Coverage mode: path/landmark coverage uses all nodes revealed inside export pass; environment family sizing also samples normal visible compositions before reveal.

Source `.gd` files:

- `Game/RuntimeState/run_state.gd`
- `Game/RuntimeState/map_runtime_state.gd`
- `Game/UI/map_board_composer_v2.gd`
- `Game/UI/map_board_render_model_masks_slots.gd`
- `Game/UI/map_board_canvas.gd`
- `Game/UI/ui_asset_paths.gd`

## Default Render Boundary

- Default socket draw entries: path `0`, landmark `0`, decor `0`.
- When explicit prototype socket dressing is enabled: path `11`, landmark `10`, decor `1`.
- Promotion boundary: normal/default render remains render_model.path_surfaces + junctions + clearing_surfaces; socket art requires explicit prototype/debug canvas enablement.

## Render Model

- Path surfaces per scenario: `9-14`.
- Junctions per scenario: `10-14`.
- Clearing surfaces per scenario: `14-14`.
- Canopy masks per scenario: `1-1`.
- Landmark slots per scenario: `14-14`.
- Decor slots per scenario: `1-1`.
- Template profiles: `corridor, loop, openfield`.
- Orientation profiles: `center_outward_balanced, center_outward_east_weighted, center_outward_west_weighted`.

## Path Brush

| role | count | surface width | outer width | path families | status |
|---|---:|---:|---:|---|---|
| `branch_actionable_corridor` | 88 | `28-28` | `38-38` | `gentle_curve, outward_reconnecting_arc, short_straight, wider_curve` | candidate_hidden_by_default |
| `branch_history_corridor` | 36 | `22-22` | `32-32` | `gentle_curve, outward_reconnecting_arc, short_straight, wider_curve` | candidate_hidden_by_default |
| `history_corridor` | 326 | `18-18` | `28-28` | `gentle_curve, outward_reconnecting_arc, short_straight, wider_curve` | candidate_hidden_by_default |
| `primary_actionable_corridor` | 45 | `34-34` | `44-44` | `gentle_curve, outward_reconnecting_arc, short_straight, wider_curve` | candidate_hidden_by_default |
| `reconnect_corridor` | 58 | `14-14` | `24-24` | `gentle_curve, outward_reconnecting_arc, wider_curve` | candidate_hidden_by_default |

## Landmark Sockets

| family | asset family keys | landmark shapes | pocket shapes | landmark half-size | pocket half-size | status |
|---|---|---|---|---:|---:|---|
| `blacksmith` | `blacksmith:forge` | `forge` | `rect` | `22.75x16.12-27.38x19.39` | `66.36x44.55-79.86x53.62` | candidate_hidden_by_default |
| `boss` | `boss:gate` | `gate` | `rect` | `45.04x30.03-45.04x30.03` | `120.12x77.57-120.12x77.57` | candidate_hidden_by_default |
| `combat` | `combat:crossed_stakes` | `crossed_stakes` | `ellipse` | `18.99x12.95-23.07x15.73` | `66.48x47.48-83.99x59.99` | candidate_hidden_by_default |
| `event` | `event:standing_stone` | `standing_stone` | `ellipse` | `10.36x18.13-12.59x22.02` | `61.30x44.89-77.44x56.72` | gap |
| `hamlet` | `hamlet:waypost` | `waypost` | `rect` | `15.44x17.06-18.88x20.87` | `54.44x36.56-66.57x44.71` | gap |
| `key` | `key:shrine` | `shrine` | `diamond` | `20.53x29.66-20.53x29.66` | `81.00x66.17-81.00x66.17` | candidate_hidden_by_default |
| `merchant` | `merchant:stall` | `stall` | `rect` | `24.65x15.17-29.66x18.25` | `67.31x43.61-81.00x52.48` | candidate_hidden_by_default |
| `rest` | `rest:campfire` | `campfire` | `ellipse` | `21.80x15.17-26.24x18.25` | `64.46x46.45-77.57x55.90` | candidate_hidden_by_default |
| `reward` | `reward:cache_slab` | `cache_slab` | `rect` | `22.75x13.27-27.38x15.97` | `61.62x43.61-74.15x52.48` | gap |
| `start` | `start:standing_stone` | `standing_stone` | `ellipse` | `14.08x20.58-16.74x24.47` | `79.09x58.50-97.78x72.33` | gap |

## Coverage Gaps

- Hidden candidate landmark families: `blacksmith, boss, combat, key, merchant, rest`.
- Missing production landmark families: `event, hamlet, reward, start`.
- Required-but-unobserved families: ``.
- Required gap callout: event/reward/hamlet remain production gaps when no hidden candidate texture path exists; start remains optional/lower-priority origin marker gap; production review is still required before default render promotion.

## Canopy And Decor

| socket | family | count | size/radius | relations | status |
|---|---|---:|---:|---|---|
| canopy | `canopy` | 90 | radius `59.75-138.48` | `opening_canopy_frame, route_canopy_frame` | mask_metadata_only_no_runtime_asset_path |
| decor | `forest_decor` | 90 | half `0x0-0x0`, radius `22.62-40.73` | `clearing_edge, route_side` | generic_candidate_hidden_by_default |
| filler-wrapper | `none observed` | 0 | n/a | n/a | no live filler_shapes observed in sampled compositions |

## Production Request Queue

- `map_path_brush_production`: pilot_candidate_replacement, source `render_model.path_surfaces`, status `candidate hidden by default`.
- `map_landmark_blacksmith_production`: gap_fill, source `render_model.landmark_slots`, status `candidate_hidden_by_default`.
- `map_landmark_boss_production`: pilot_candidate_replacement, source `render_model.landmark_slots`, status `candidate_hidden_by_default`.
- `map_landmark_combat_production`: gap_fill, source `render_model.landmark_slots`, status `candidate_hidden_by_default`.
- `map_landmark_event_production`: gap_fill, source `render_model.landmark_slots`, status `gap`.
- `map_landmark_hamlet_production`: gap_fill, source `render_model.landmark_slots`, status `gap`.
- `map_landmark_key_production`: pilot_candidate_replacement, source `render_model.landmark_slots`, status `candidate_hidden_by_default`.
- `map_landmark_merchant_production`: pilot_candidate_replacement, source `render_model.landmark_slots`, status `candidate_hidden_by_default`.
- `map_landmark_rest_production`: pilot_candidate_replacement, source `render_model.landmark_slots`, status `candidate_hidden_by_default`.
- `map_landmark_reward_production`: gap_fill, source `render_model.landmark_slots`, status `gap`.
- `map_landmark_start_production`: optional_origin_marker, source `render_model.landmark_slots`, status `gap`.
- `map_canopy_frame_family_production`: environment_expansion, source `render_model.canopy_masks`, status `mask metadata only; no runtime asset path`.
- `map_decor_stamp_family_production`: pilot_candidate_replacement, source `render_model.decor_slots`, status `generic candidate hidden by default`.
- `map_filler_shape_family_watch`: deferred_observation, source `filler_shapes wrapper metadata feeding render_model.decor_slots`, status `no live filler_shapes observed in sampled compositions`.

## Promotion Gate

- Do not enable candidate or production art in normal/default board render inside this brief step.
- Runtime promotion still needs manifest/provenance truth, screenshot review, and pixel diff.
- This brief does not change gameplay truth, save shape, flow state, or asset approval status.
