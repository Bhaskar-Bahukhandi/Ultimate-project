# ComfyUI Oakhaven P6 Review

Phase 10M-P6 generated exactly 12 local ComfyUI outputs: two attempts for each of six Oakhaven
tile-family targets. All outputs remain in `assets/art_sources/comfyui_tests/oakhaven_p6/`.
Nothing was imported into `assets/production_art/`.

## Setup

| Check | Result | Notes |
| --- | --- | --- |
| ComfyUI endpoint | Pass | `http://127.0.0.1:8000` |
| Base checkpoint | Pass | `v1-5-pruned-emaonly.safetensors` |
| Pixel-art LoRA | Pass | `sedatal_pixel_art_lora.safetensors` |
| LoRA strength | Used | `0.85` |
| Resolution | Used | `512x512` |
| Batch size | Used | `1` |

## Contact Sheets

| Artifact | Path |
| --- | --- |
| All raw outputs contact sheet | `assets/art_sources/comfyui_tests/oakhaven_p6/review/phase10mp6_all_outputs_contact_sheet.png` |
| Candidate crops contact sheet | `assets/art_sources/comfyui_tests/oakhaven_p6/review/phase10mp6_candidate_contact_sheet.png` |
| Draft preview atlas | `assets/art_sources/comfyui_tests/oakhaven_p6/oakhaven_p6_draft_preview_atlas.png` |

## Generation Review

| Family | Attempt | Seed | Style Fit | Top-Down | Tile Usefulness | Cell Cleanliness | Extraction Potential | Overall |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| Grass terrain | 1 | `610001` | 5/10 | 5/10 | 4/10 | 3/10 | 4/10 | 4/10 |
| Grass terrain | 2 | `610002` | 5/10 | 4/10 | 3/10 | 4/10 | 3/10 | 3/10 |
| Dirt path | 1 | `620001` | 5/10 | 5/10 | 3/10 | 2/10 | 2/10 | 3/10 |
| Dirt path | 2 | `620002` | 6/10 | 6/10 | 5/10 | 5/10 | 5/10 | 5/10 |
| Path transitions | 1 | `630001` | 6/10 | 6/10 | 5/10 | 5/10 | 5/10 | 5/10 |
| Path transitions | 2 | `630002` | 6/10 | 6/10 | 5/10 | 5/10 | 5/10 | 5/10 |
| Fence/hedge | 1 | `640001` | 5/10 | 5/10 | 4/10 | 4/10 | 4/10 | 4/10 |
| Fence/hedge | 2 | `640002` | 7/10 | 7/10 | 6/10 | 6/10 | 6/10 | 6/10 |
| Cottage family | 1 | `650001` | 5/10 | 2/10 | 1/10 | 1/10 | 1/10 | 2/10 |
| Cottage family | 2 | `650002` | 6/10 | 5/10 | 4/10 | 4/10 | 4/10 | 4/10 |
| Small props | 1 | `660001` | 5/10 | 5/10 | 4/10 | 4/10 | 4/10 | 4/10 |
| Small props | 2 | `660002` | 4/10 | 4/10 | 2/10 | 2/10 | 2/10 | 2/10 |

## Family Summary

| Family | What Worked | What Failed | Best Attempt | Verdict |
| --- | --- | --- | --- | --- |
| Grass terrain | LoRA produced more pixel-art structure than P4 | Still produces scene-ish blocks and tile crossings | Attempt 1 | Some rough candidates, not production-ready |
| Dirt path | Attempt 2 has usable stone/dirt-like cells | Not really dirt path; more stone floor than village path | Attempt 2 | Extractable rough texture cells |
| Path transitions | More tile-like strips and edge pieces than prior runs | Not coherent grass-to-dirt transition grammar | Attempts 1 and 2 | Some edge-study crops worth keeping |
| Fence/hedge | Attempt 2 looks closest to a game asset sheet | Mixed props and scale inconsistencies | Attempt 2 | Best family of the run |
| Cottage family | Attempt 2 has building-like pieces | Attempt 1 became a scenic landscape; no clean house kit | Attempt 2 | Weak, needs better workflow |
| Small props | Some prop-like blocks and hedge pieces | Still not isolated flower/herb/sign props | Attempt 1 | Limited source crops only |

## Reusable Candidates

| Output | Candidate Cell/Region | Intended Use | Quality | Keep/Reject |
| --- | --- | --- | --- | --- |
| `grass_terrain_attempt1_seed610001.png` | `(256,192)-(320,256)` | Grass terrain filler | Medium | Keep as source |
| `grass_terrain_attempt2_seed610002.png` | `(320,96)-(384,160)` | Alternate floor/trim study | Low | Keep only for reference |
| `dirt_path_attempt2_seed620002.png` | `(64,64)-(128,128)` | Rough path/floor texture | Medium | Keep as source |
| `dirt_path_attempt2_seed620002.png` | `(256,64)-(320,128)` | Rough path/floor texture | Medium | Keep as source |
| `path_transitions_attempt1_seed630001.png` | `(0,32)-(64,96)` | Path edge transition study | Medium | Keep as source |
| `path_transitions_attempt2_seed630002.png` | `(32,224)-(96,288)` | Hedge/path edge study | Medium | Keep as source |
| `path_transitions_attempt2_seed630002.png` | `(288,64)-(352,128)` | Magic marker/prop study | Low | Keep only for reference |
| `fence_hedge_attempt2_seed640002.png` | `(160,96)-(224,160)` | Hedge/bush prop | Medium | Keep as source |
| `fence_hedge_attempt2_seed640002.png` | `(64,288)-(128,352)` | Wood prop/fence support | Medium | Keep as source |
| `fence_hedge_attempt2_seed640002.png` | `(320,288)-(384,352)` | Cottage/fence support | Medium | Keep as source |
| `small_props_attempt1_seed660001.png` | `(64,192)-(128,256)` | Village prop/source | Low | Keep only for reference |
| `small_props_attempt1_seed660001.png` | `(320,96)-(384,160)` | Hedge/clutter source | Medium | Keep as source |

## Verdict

- The LoRA is helping compared to base SD 1.5. It produced more pixel-art-like asset sheets and
  fewer pure concept plates.
- The best family was `fence_hedge`, especially attempt 2.
- The worst family was `cottage_family` attempt 1, which became a scenic illustration.
- We did get reusable source candidates, but they are rough crop candidates, not final tiles.
- Extraction/refinement is worth one more pass if the goal is to build a review-only Oakhaven draft
  atlas from selected crops.
- This is closer to Oakhaven than P3/P4, but still not clearly better than the current fallback as
  a complete tileset.
- Nothing from this pass should be promoted to production art without manual cleanup, downscale
  testing, and Godot scene review.

