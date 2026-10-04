# 🎨 CHARACTER DESIGN REFERENCE SHEET
## Aethelgard: The Glitch Sovereign - Visual Character Guide

**IMPORTANT:** The game code contains ZERO physical descriptions of characters. All sprites currently use colored rectangles as placeholders. This reference is created from narrative context and genre conventions.

---

## 🎯 PROTAGONIST: KAELEN "REN" VANCE

### Character Context
- **Age:** Late 20s (26-29)
- **Profession:** Senior Systems Architect / Game Engine Programmer
- **Background:** 3 years at AetherCorp, just resigned
- **Personality:** Analytical, introverted, workaholic, cynical about corporate life
- **Arc:** Programmer gaining "Root Access" powers in a game world

### Physical Description (Based on Character Type)

**Build:**
- Height: 5'9" - 5'11" (175-180cm) - Average programmer height
- Build: Lean/thin - Programmer physique (sedentary job)
- Posture: Slightly hunched (from years at a desk)
- Body type: Ectomorph - Narrow shoulders, limited muscle mass

**Face:**
- Age appearance: Late 20s, looks tired
- Face shape: Oval or rectangular (common for protagonists)
- Eye color: Dark brown or hazel
- Eyes: Tired, bags under eyes (chronic overwork)
- Expression: Neutral to skeptical resting face
- Glasses: YES - Rectangular frame glasses (programmer stereotype but fits)

**Hair:**
- Color: Dark brown or black
- Style: Short-medium length, slightly messy/unkempt
- Length: Covers ears, touches collar in back
- Texture: Straight or slightly wavy
- Maintenance: Low - "I forgot to get a haircut" look
- Reference: Tech worker who doesn't prioritize appearance

**Clothing (When Transported):**

*Day 1 - Flight Clothing:*
- Dark hoodie or zip-up jacket (travel comfort)
- Plain t-shirt underneath (dark gray or black)
- Jeans (dark blue or black)
- Sneakers (comfortable, worn)
- Laptop bag strap across chest

*Post-Arrival - "Spawned" Look:*
- Same clothes but slightly "digitized" appearance
- Clothes might have subtle glitch effects
- Colors: Dark palette (programmer aesthetic)
  - Primary: Dark gray/black
  - Secondary: Deep blue or charcoal
  - Accent: Cyan/electric blue (glitch color)

**Distinctive Features:**
- Glasses (CRITICAL - part of identity)
- Dark circles under eyes (exhaustion)
- Pale skin (office worker tan)
- Thin wrists (keyboard warrior)
- Slightly hunched posture

---

## 🎨 PIXEL ART SPECIFICATIONS

### Sprite Dimensions
**Recommended:** 32x32 pixels (standard indie size)
**Alternative:** 48x48 pixels (more detail possible)

### Color Palette

**Base Colors:**
```
Skin: #D4A891 (light brown/tan)
Hair: #2C2416 (dark brown/black)
Eyes: #5C4A3A (dark brown)
Glasses: #CCCCCC (silver frame), #E6F2FF (lens glint)

Hoodie: #2B3E50 (dark slate blue)
Shirt: #1A1A1A (near black)
Jeans: #3A4A5A (dark denim)
Shoes: #404040 (dark gray)

Glitch Accent: #00FFFF (cyan) - for effects only
```

### Animation Frames Needed

#### Exploration Mode (Top-Down):
1. **Idle** (2-4 frames)
   - Standing still
   - Slight breathing motion
   - Glasses glint every 3-4 seconds

2. **Walk** (6-8 frames per direction)
   - North (walking away)
   - South (walking toward camera)
   - East (walking right)
   - West (walking left)
   - Diagonal walk cycles optional

3. **Interact** (2-3 frames)
   - Reaching forward
   - Examining object
   - Return to idle

**Total Top-Down Frames:** 30-40 minimum

#### Combat Mode (Side-Scrolling):
1. **Idle** (4-6 frames)
   - Standing ready
   - Slight bob
   - Glasses glint

2. **Walk** (6-8 frames)
   - Left and right (can mirror)

3. **Run** (6-8 frames)
   - Faster walk cycle
   - More pronounced lean

4. **Jump** (3-4 frames)
   - Crouch prep
   - Launch
   - Airborne
   - Land

5. **Attack** (4-6 frames)
   - Wind-up
   - Strike (2 frames)
   - Recovery

6. **Hurt** (2-3 frames)
   - Recoil
   - Flash red

7. **Death** (6-8 frames)
   - Stagger
   - Collapse
   - Fade/pixelate

**Total Combat Frames:** 40-50 minimum

**GRAND TOTAL:** 70-90 animation frames for Kaelen

---

## 👥 COMPANION CHARACTERS

### ELARA - Glitch-Witch (Broken Guide NPC)

**Character Context:**
- Age: Unknown (appears Mid-20s, 24-26)
- Role: Was originally coded as a guide NPC, but her script broke long ago
- In-Game Title: "Glitch-Witch" / "The Broken Guide"
- Personality: Cheerful on the surface, masks deep vulnerability; self-aware, knows she's broken
- Arc: First social link, teaches Kaelen about glitch magic, Root Access, and Data Vision
- Key Trait: Her left arm is permanently glitched/wireframe — "part of what broke in me"
- Note: She is NOT the flight attendant Mira. Elara is a native NPC of Aethelgard who gained self-awareness through a script exception

**Physical Description:**

**Build:**
- Height: 5'6" - 5'8" (168-173cm)
- Build: Ethereal, slightly translucent at edges
- Body type: Slim — she flickers in and out of solidity

**Face:**
- Age: Mid-20s appearance, but timeless (she's been wandering "a long time")
- Face shape: Oval with soft features
- Eye color: Green or light brown — eyes occasionally glitch/flash with code
- Expression: Warm, encouraging smile that sometimes flickers to reveal genuine sadness beneath

**Hair:**
- Color: Light brown or auburn
- Style: Practical - pulled back in ponytail or bun, but occasionally glitches loose
- Length: Shoulder-length when down
- Note: Strands may float/glitch slightly

**Clothing:**
- Patchwork robes made of visible code fragments and torn textures
- Color scheme: Purple/black with cyan glitch accents
- Her left arm is permanently wireframe/see-through
- Clothes have missing textures (purple-black checkerboard patches)
- Subtle scan lines across her body

**Sprite Notes:**
- Left arm MUST show wireframe/transparency effect
- Appears with glitch effects (she materializes from nothing)
- Warm expression that occasionally cracks to reveal vulnerability
- Corruption visibly worsens on her arm when she casts spells

---

### KAITO - Shadow Warrior (Former Businessman)

**Character Context:**
- Age: Early 30s (32-35)
- Profession: Was corporate executive, now "Shadow Warrior"
- Personality: Strategic, aggressive, competitive
- Arc: Rivalry with Kaelen
- Status: NOT YET INTRODUCED in current game build — planned for Chapter 2+
- Note: The businessman passenger on Flight 707 (Seat 12C) is implied to become Kaito after the crash, but this transformation is not yet shown in-game

**Physical Description:**

**Build:**
- Height: 5'11" - 6'0" (180-183cm)
- Build: Lean but toned (gym membership)
- Shoulders: Broader than Kaelen
- Posture: Confident, upright

**Face:**
- Age: Early 30s, sharp features
- Face shape: Angular/square jaw
- Eye color: Dark brown or gray
- Expression: Intense, focused

**Hair:**
- Color: Black
- Style: Short, slicked back (executive style)
- Length: Professional short
- Maintained: Perfectly groomed

**Clothing:**
- "Shadow Warrior" dark armor
- Black and dark purple scheme
- Sharp, angular design
- Looks like corrupted business suit + armor
- Tie becomes scarf/cape element

---

### SERAPHINA - Oracle Mage (Former Student)

**Character Context:**
- Age: Early 20s (20-22)
- Profession: College student, now "Oracle Mage"
- Personality: Quiet, observant, knows more than she says
- Arc: Mystery character, prophetic warnings
- Status: NOT YET INTRODUCED in current game build — planned for Chapter 2+
- Note: May have been a passenger on Flight 707, but her real-world identity is not yet established in-game

**Physical Description:**

**Build:**
- Height: 5'4" - 5'6" (163-168cm)
- Build: Petite, delicate
- Body type: Slim

**Face:**
- Age: Early 20s, youthful
- Face shape: Heart-shaped
- Eye color: Blue or violet (oracle theme)
- Expression: Distant, thoughtful

**Hair:**
- Color: Platinum blonde or silver
- Style: Long, flowing
- Length: Mid-back
- Effect: Slightly floats (magic aura)

**Clothing:**
- Oracle robes (flowing, ethereal)
- White and light blue scheme
- Lots of cloth physics potential
- Barefoot or soft slippers
- Mystical jewelry/accessories

---

### MIRA - Flight Attendant (Early Prologue Only)

**Character Context:**
- Age: Late 20s
- Profession: Flight attendant on Flight 707
- Personality: Warm but mysterious — "too perfect," as if performing warmth rather than feeling it
- Note: May be an AI/NPC planted by the System. In the prologue, she has a "glitch moment" where her face freezes and eyes go dead before resetting. She dissolves into static during the crash.
- Important: Mira is NOT Elara. They are separate characters. Elara is a native Aethelgard NPC; Mira exists only on the plane.

**Physical Description:**

**Build:**
- Height: 5'5" - 5'7" (165-170cm)
- Build: Professional fit
- Standard flight attendant appearance

**Face:**
- Age: Late 20s
- Face shape: Oval
- Eye color: Brown
- Expression: Professional smile with hint of knowing

**Hair:**
- Color: Dark brown
- Style: Airline regulation bun
- Length: Unknown (always up)

**Clothing:**
- Standard airline uniform
- Navy blue suit with white shirt
- Neckerchief/scarf
- Professional appearance
- Might have glitch effects later

---

## CINEMATIC ENVIRONMENT BACKGROUNDS (Procedural)

The game currently uses procedurally generated backgrounds for its animatic-style cinematic sequences. These environments are built from layered ColorRect nodes with animated tweens. When sprite art is added, these backgrounds should be replaced with proper tilesets and parallax layers, but the environment structure serves as a design reference.

### Sequence 1: Glitch Crater Awakening
- **Sky:** Near-black void (0.02, 0.01, 0.06) with purple nebula glow
- **Stars:** 25 twinkling white-blue dots with randomized fade animations
- **Terrain:** Dark purple-brown ground with crater depression in center
- **Crater Rim:** Silhouetted terrain shapes on left and right sides
- **Floating Rocks:** 6 corrupted debris pieces bobbing up and down (sine wave)
- **Corruption Veins:** 5 pulsing purple lines across the ground
- **Golden Path:** Hidden initially, revealed with fade + pulse during cutscene
- **Scan Lines:** 4 drifting CRT-style lines (broken machine aesthetic)
- **Vignette:** Dark gradient edges top and bottom
- **Letterbox Bars:** Cinematic bars slide in after fade-in, out before transition
- **Palette:** Purple-black void tones with cyan/magenta corruption accents

### Sequence 2: Meeting Elara (Forest Clearing)
- **Sky:** Deep purple twilight (0.08, 0.05, 0.15) with upper glow
- **Ground:** Dark forest green with lighter dirt path
- **Golden Trail:** Pulsing gold line on the path (sine wave glow)
- **Trees:** 7 silhouette trees with trunks and canopies, canopies sway gently
- **Fireflies:** 8 yellow-green floating lights with position drift + alpha fade
- **Vignette:** Subtle dark edges with slight blue tint
- **Letterbox Bars:** Active throughout cinematic

### Sequence 3: Path to Oakhaven
- **Sky:** Warmer twilight (0.1, 0.07, 0.14) with sunset-tinted gradient
- **Far Background:** Distant treeline silhouette layer
- **Ground:** Warmer forest green, lighter dirt path
- **Golden Trail:** Softer pulsing gold line
- **Trees:** 8 denser tree silhouettes with larger canopies, swaying
- **Fireflies:** 10 warmer-toned (gold-yellow) floating lights
- **Village Glow:** Warm orange glow on right horizon, pulsing subtly
- **Vignette:** Softer dark edges
- **Letterbox Bars:** Active throughout cinematic

### Environment Transition Progression
The environments progress from:
1. **Crater** (cold, void, alien) -> dark purples, floating debris, corruption
2. **Forest** (mysterious, twilight) -> deep greens, fireflies, golden path
3. **Path** (warmer, approaching civilization) -> warmer tones, village glow, denser trees

This color temperature shift mirrors Kaelen's emotional arc: shock -> curiosity -> cautious hope.

---

## ANIMATION EFFECTS REFERENCE

### Tween-Based Animations Currently in Game
- **Star twinkle:** Random alpha fade between 0.15-1.0, 1.5-3.5s cycle
- **Floating rocks:** Vertical sine bob, 5-18px amplitude, 2-4.5s cycle
- **Corruption vein pulse:** Alpha fade between 0.2-1.0, 1.2-2.5s cycle
- **Golden path glow:** Alpha pulse 0.3-1.0, 2-2.5s cycle
- **Tree canopy sway:** Horizontal position shift 2-6px, 3-5.5s cycle
- **Firefly drift:** Position + alpha tween chain, 3-6s position / 1-2.5s alpha
- **Village glow pulse:** Alpha 0.5-1.0, 3.5s cycle
- **Scan line drift:** Vertical position tween across screen, 5-9s cycle
- **Horizon pulse:** Alpha 0.4-1.0, 3s sine cycle

### Cutscene Transition Effects
- **Letterbox bars:** 60px height, 0.8s ease-out slide in / 0.4s ease-in slide out
- **Screen transitions:** FADE (1.5-3.0s) and GLITCH (1.5s) types
- **Camera shake:** Intensity-based legacy + trauma-based modern system
- **Elara spawn glitch:** Static particles + white flash (0.2s)
- **Elara model glitch:** Y-stretch to (0.3, 5.0) for 0.08s + magenta color flash
- **Golden path reveal:** Color alpha tween to 0.35 over 1.5s + continuous pulse

---

## 🎨 STYLE GUIDE

### Overall Art Direction

**Aesthetic:** Post-modern pixel art with glitch elements

**Influences:**
- Hollow Knight (fluid animation, dark palette)
- Celeste (expressive pixel art)
- Hyper Light Drifter (glitch aesthetic)
- VA-11 Hall-A (cyberpunk pixel art)

**Key Visual Themes:**

1. **Programmer Aesthetic:**
   - Darker, muted colors for Kaelen
   - Tech-wear inspired but subtle
   - Glasses are identity marker
   - Tired, overworked appearance

2. **Glitch Effects:**
   - Characters have subtle scan lines
   - Occasional pixel displacement
   - Chromatic aberration on edges
   - Becomes worse with corruption

3. **Class Disparity:**
   - NPCs have bright, saturated colors
   - Kaelen has muted, realistic tones
   - Shows he's from "outside" the game

---

## 📐 TECHNICAL SPECIFICATIONS

### Canvas Size
- Character sprite: 32x32 or 48x48 pixels
- Canvas: 128x128 (for working space)
- Export: Transparent PNG

### Pixel Density
- Use 1px = 1 pixel (no sub-pixels)
- Crisp edges for retro look
- Anti-aliasing: Minimal to none

### Color Limits
- 8-16 colors per character
- Shared palette across similar elements
- Black outlines: 1-2 pixels thick

### Frame Rate
- Idle: 2-4 FPS (slow bob)
- Walk: 8-12 FPS (smooth motion)
- Action: 12-16 FPS (fast moves)
- Combat: 16-20 FPS (responsive)

---

## 🎬 ANIMATION PRINCIPLES

### Personality Through Motion

**Kaelen's Movement:**
- Slightly hesitant
- Analytical (pauses before acting)
- Economic motion (programmer efficiency)
- Glasses catch light
- Shoulders slightly forward (desk posture)

**Combat Style:**
- Not a natural fighter
- Calculated strikes
- Defensive posture
- Heavy reliance on abilities over physical

**Emotes:**
- Confused head tilt
- Glasses adjustment (nervous tell)
- Rubbing temples (stress)
- Hunched thinking pose

---

## 🖼️ REFERENCE MATERIALS

### Real-World References

**For Kaelen:**
- Google "programmer at desk" for posture
- Tech conference photos for clothing
- Tired office worker aesthetic
- Glasses styles: rectangular frames

**Body Language:**
- Introverted posture (arms close to body)
- Minimal gestures
- Weight shifts rather than steps
- Uncomfortable in combat stance

### Pixel Art References

**Study These Games:**
- Celeste (character expressiveness)
- Hyper Light Drifter (combat fluidity)
- Eastward (detailed pixel characters)
- Owlboy (large pixel sprites)

---

## 💡 ARTIST NOTES

### What the Code Tells Us

**Current Placeholder:**
- Player sprite: Blue ColorRect (16x20 pixels)
- No animations
- Basic collision box

**Scene Requirements:**
```gdscript
# From player_topdown.tscn:
Sprite (ColorRect currently)
  - Size: 16x20 pixels
  - Color: Blue (0.3, 0.6, 1)
  - Position: Centered on collision

# From player_combat.gd:
Sprite (placeholder)
  - Needs: Idle, Walk, Jump, Attack, Hurt animations
  - Facing: Left and Right
```

### What We DON'T Know

**The game never specifies:**
- ❌ Exact height
- ❌ Hair color or style
- ❌ Eye color
- ❌ Skin tone
- ❌ Clothing details
- ❌ Any distinguishing marks
- ❌ Weapon design
- ❌ Facial features

**This means YOU HAVE CREATIVE FREEDOM!**

The only requirements from the narrative:
- ✅ Programmer aesthetic (casual, tech-wear)
- ✅ Looks tired/overworked
- ✅ From modern era (2024)
- ✅ Late 20s age
- ✅ Not a natural fighter

Everything else is up to your artistic interpretation.

---

## 🎨 SUGGESTED APPROACH

### Phase 1: Concept Art
1. Sketch 3-5 different designs
2. Get feedback on which feels right
3. Nail down color palette
4. Create turnaround sheet (front, side, back, 3/4)

### Phase 2: Pixel Art
1. Create base idle sprite
2. Test in game to verify scale
3. Adjust proportions if needed
4. Lock in final design

### Phase 3: Animation
1. Idle animation
2. Walk cycles
3. Jump cycle
4. Attack animations
5. Hurt/death
6. Polish and cleanup

### Phase 4: Variants
1. Damaged state (less HP)
2. Corrupted state (high glitch meter)
3. Powered up state (special mode)

---

## 📝 DELIVERABLES CHECKLIST

For the artist, create:

### Exploration Mode:
- [ ] Idle (4 frames)
- [ ] Walk North (8 frames)
- [ ] Walk South (8 frames)  
- [ ] Walk East (8 frames)
- [ ] Walk West (8 frames)
- [ ] Interact (3 frames)

### Combat Mode:
- [ ] Idle (6 frames)
- [ ] Walk (8 frames)
- [ ] Run (8 frames)
- [ ] Jump (4 frames)
- [ ] Attack 1 (6 frames)
- [ ] Attack 2 (6 frames)
- [ ] Hurt (3 frames)
- [ ] Death (8 frames)

### Portraits (Optional):
- [ ] Neutral expression
- [ ] Surprised expression
- [ ] Determined expression
- [ ] Tired expression

### Export Format:
- Transparent PNG
- Sprite sheet with all frames
- JSON or XML animation data
- Color palette file

---

## 💰 BUDGET CONSIDERATIONS

### If Hiring:

**Freelance Pixel Artist Rates:**
- Junior: $15-25/hour
- Mid-level: $30-50/hour
- Senior: $60-100/hour

**Project Pricing:**
- Character design: $100-300
- Base sprite: $150-400
- Full animation set: $800-2,000
- **Total per character: $1,000-$2,500**

**Kaelen + 3 companions = $4,000-$10,000**

### If Learning:

**Time Investment:**
- Basics: 20-40 hours (tutorials)
- First character: 80-120 hours (lots of iteration)
- Each additional: 60-90 hours (faster with practice)
- Professional level: 500+ hours practice

**Tools Needed:**
- Aseprite: $19.99 (recommended)
- Or GraphicsGale: Free
- Or Piskel: Free (web-based)

---

## 🎯 FINAL NOTES

### What We Know FOR SURE:
1. Kaelen is a programmer (casual tech aesthetic)
2. Late 20s (youngish but not teenager)
3. Just quit his job (probably tired, stressed)
4. Not a natural fighter (awkward in combat)
5. Wears glasses (likely, given profession and narrative)

### What's INTERPRETATION:
1. Exact height, build, proportions
2. Hair color and style
3. Skin tone
4. Clothing specifics
5. Weapon design
6. Facial features

### What's RECOMMENDED:
1. Darker, muted color palette (programmer/exhausted aesthetic)
2. Glasses (strongly implied by narrative tone)
3. Casual/hoodie style (travel comfort)
4. Lean build (desk job physique)
5. Tired expression (overworked theme)

---

## 🚀 READY TO START?

**Before you begin, decide:**

1. **Art Style:**
   - Hollow Knight detail level?
   - Celeste simplicity?
   - Hyper Light Drifter abstraction?

2. **Pixel Density:**
   - 16x16 (very low detail)
   - 32x32 (standard indie)
   - 48x48 (high detail)
   - 64x64 (very detailed)

3. **Animation Complexity:**
   - Minimal (4-6 frames per action)
   - Standard (6-8 frames)
   - Fluid (10-12 frames)

4. **Budget:**
   - DIY (free but 200+ hours)
   - Commission ($1,000-$2,500 per character)
   - Asset packs ($20-100 but generic)

**The game is waiting for your art!**

The code foundation is solid. The mechanics work. The story is there.

**All it needs is visual life.**

Good luck! 🎨
