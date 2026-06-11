# Phase 10M-O AI Art Tool Sourcing Report

This report is a sourcing gate only. It does not approve an account signup, accept tool terms,
purchase a plan, generate art, download tool outputs, or import generated art into runtime slots.
Any future generated asset still needs a saved source record, generator/plan/license review, visual
review, and Godot import validation before it becomes production art.

## Candidate Tools

| Tool | Official URL | Signup Required? | Free Export Signal | Sprite-Sheet Signal | Transparent PNG Signal | Commercial-Use Signal | Batch/API Signal | Godot Fit |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| PixelLab | [Product](https://www.pixellab.ai/) / [Docs](https://www.pixellab.ai/docs/) | Yes for account-backed creation/API paths; docs surface sign-in and account pages | Product says try for free, but high-value tileset and animation tooling documents Tier requirements | Character workflow exports sprite sheets or frames; animation tooling targets directional pixel sprites | Animation/UI/API docs expose no-background or optional transparent background output | Terms say users own PixelLab creations for commercial and non-commercial use | Official API and MCP/assistant workflow are documented | Strongest first fit for 32 px pixel tiles, sprite sheets, enemy sheets, icons, and iterative cleanup |
| Scenario | [Product](https://www.scenario.com/) / [Help](https://help.scenario.com/) | Yes; pricing/terms are account and plan based | Free tier exists for evaluation; free outputs are not commercial production assets | Official spritesheet guide exists, but it assembles generated frames into sheets as a workflow | Remove-background and transparent-generation tooling are documented | Pricing says paid plans include commercial license; free outputs are personal/evaluation only | API-first platform and automation docs are explicit | Good second tool for backgrounds, props, cleanup, batch jobs, and higher-resolution scene plates |
| Layer | [Product](https://www.layer.ai/) / [Docs](https://docs.layer.ai/) | Yes; terms require an account for the service | Free trial is advertised, but production use still needs plan review | Sprite-generation page says sprites, animation frames, and sprite sheets | Sprite page advertises PNG/WebP export; transparent output depends on chosen workflow/model review | Terms/help say customer owns compliant generated content and commercial use is allowed | REST API, workflows, and batch-oriented game-asset pipeline are explicit | Good studio-scale candidate for sprite/prop libraries after model, plan, and workflow review |
| Rosebud PixelVibe | [PixelVibe](https://lab.rosebud.ai/ai-game-assets) / [Terms](https://lab.rosebud.ai/terms-of-service) | PixelVibe advertises no-sign-up trial entry; broader service terms are account based | Trial entry is visible, but export and plan limits need manual approval review | Tool page emphasizes 2D assets; direct production sprite-sheet export is not as clear as PixelLab | Background-removed asset examples exist, but output contract needs manual review | Terms explicitly discuss paid commercial UGC rights; free/trial commercial status is not a safe production assumption | Batch/API suitability is not the main product signal checked here | Prototype/sourcing candidate for game assets, not the first safe production path for this project |
| Recraft | [Product](https://www.recraft.ai/) / [Ownership](https://www.recraft.ai/docs/trust-and-security/ownership) | Yes for normal studio/API workflow | Free plan exists, but free-plan images are not commercial production assets | No direct sprite-sheet production claim used here | Transparent cutout/background-removal workflow is documented | Paid plan docs grant ownership/commercial rights; free plan is not commercial | API exists | Secondary candidate for icons, prop cutouts, and backgrounds, not the primary pixel-sheet/tileset tool |

## Ranking

| Tool | Best For | Signup Needed | Export Quality | License Clarity | Automation Suitability | Verdict |
| --- | --- | --- | --- | --- | --- | --- |
| PixelLab | Pixel tilesets, directional characters, enemy sheets, pixel UI/icons | Yes | High task fit for this project's pixel contracts | Clear PixelLab terms signal, still capture the terms snapshot before production use | Good through API/MCP after approval | Recommended first manual approval target |
| Scenario | Arena plates, props, background cleanup, batch asset families | Yes | Strong broad-asset workflow, less sheet-native than PixelLab | Clear paid-plan/commercial split | Strong | Recommended secondary tool after tool/plan approval |
| Layer | Larger sprite/prop libraries and production automation | Yes | Strong if workflow and model choice are controlled | Clear platform ownership/commercial signal with compliance caveats | Strong | Worth a later production-pipeline review |
| Rosebud PixelVibe | Fast game-asset ideation | Trial entry says no sign-up | Useful exploratory scope | Paid commercial signal is clearer than trial/free export status | Unclear from checked product pages | Keep for manual evaluation only |
| Recraft | Item icons, transparent cutouts, broad scene illustrations | Yes | Useful for non-sheet outputs | Clear free-vs-paid commercial split | Good API path | Do not use as first sprite/tile generator |

## Recommended Approval Path

1. Approve a manual PixelLab review first for Oakhaven tileset and sheet-contract tests.
2. During that review, confirm the actual plan tier needed for top-down tilesets, sheet export,
   transparent PNG export, and whether exports can match exact row/frame contracts without manual
   assembly.
3. Treat Scenario as the next manual candidate for arena/background plates and batch prop work if
   PixelLab's scene outputs are too small or too pixel-constrained.
4. Do not use any generated output commercially until the selected tool's terms, plan status, and
   source record are saved with the asset intake record.

## License and Commercial-Use Notes

- Tool capability does not equal commercial clearance. Store the exact official page or terms
  snapshot used for the approved generation session.
- Avoid prompts that request named commercial franchises, living-artist imitation, or copied
  commercial game styles.
- Treat free/evaluation outputs from Scenario and free outputs from Recraft as non-production for
  this repo unless the applicable official terms later say otherwise.
- Rosebud's product page is useful for exploration, but the checked signals are not enough to make it
  the first safe production pipeline for sprite-sheet contracts here.
- Layer and Scenario are broad platforms with many underlying models and workflows. Review the
  selected model/workflow before export, not only the platform homepage.

## Risks

| Risk | Why It Matters Here | Guardrail |
| --- | --- | --- |
| Sheet layout drift | Godot slices current production slots by fixed rows and frame sizes | Generate against the exact prompts in `phase10mo_generation_prompts.md`, then validate dimensions before import |
| Tileset incoherence | A pretty map image is not a reusable 32 px RPG tileset | Ask for tile families and transitions, not one scene screenshot |
| Style contamination | Named-game or named-artist prompts can create IP risk and visual mismatch | Use original dark fantasy plus digital glitch language only |
| Plan/license mismatch | Free/trial outputs may be evaluation-only | Save source/plan/terms record before production use |
| Alpha cleanup failures | Halos and opaque backgrounds break sprite composition | Require transparent PNG where needed and inspect edge pixels |
| Automation overreach | API generation can scale mistakes quickly | Start with manual approval and one reviewed asset family before batch generation |

## Exact Generation Prompts

The prompt library is stored in
[`phase10mo_generation_prompts.md`](./phase10mo_generation_prompts.md). It contains:

- Oakhaven, Ironhold, and Fractured Wastes tileset prompts
- Kaelen top-down player sheet prompt
- Tutorial Knight production sheet prompt
- Fracture Slime, Clock Mite, and Memory Wisp enemy sheet prompts
- Tutorial Knight arena background prompt

## Import Plan

### Intake Stages

1. Generate only after a tool is approved manually.
2. Save source exports and generation notes under `assets/art_sources/`.
3. Record tool name, source URL, terms/license page checked, plan state, prompt revision, generated
   date, export dimensions, and any manual edits in `docs/art_pipeline/`.
4. Validate size, frame grid, alpha handling, style fit, and naming before touching
   `assets/production_art/`.
5. Export only validated runtime PNGs into existing production slots.
6. Run AssetManager fallback validation and target-scene smoke before claiming an art replacement.

### Existing Source and Runtime Slots

| Asset Family | Source Slot | Runtime Slot |
| --- | --- | --- |
| Oakhaven tileset | `assets/art_sources/tilesets/oakhaven/` | `assets/production_art/tilesets/oakhaven_tileset.png` |
| Ironhold tileset | `assets/art_sources/tilesets/ironhold/` | `assets/production_art/tilesets/ironhold_tileset.png` |
| Fractured Wastes tileset | `assets/art_sources/tilesets/fractured_wastes/` | `assets/production_art/tilesets/fractured_wastes_tileset.png` |
| Kaelen top-down sheet | `assets/art_sources/characters/` | `assets/production_art/characters/player/kaelen_topdown_alpha_sheet.png` |
| Tutorial Knight sheet | `assets/art_sources/characters/` | `assets/production_art/characters/bosses/tutorial_knight_alpha_sheet.png` |
| Enemy sheets | `assets/art_sources/characters/` | `assets/production_art/characters/enemies/<enemy_id>_alpha_sheet.png` |
| Arena floor/backdrop source | `assets/art_sources/backgrounds/tutorial_knight_arena/` | integrate only after the approved arena runtime slot decision |

### First Approved Test Batch

1. Oakhaven tileset family
2. One Oakhaven building/fence/prop support mini-batch if the same approved tool can keep style
   coherence
3. One Kaelen or Slime sheet-contract test only after the environment export path is understood

Do not start a broad replacement batch from the first acceptable image.

## Decision

Ready for manual tool approval

