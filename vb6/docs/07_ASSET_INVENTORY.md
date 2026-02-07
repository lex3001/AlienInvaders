# Asset Inventory - Complete Resource Catalog

## BMP Files (Bitmap Graphics)

### Core Sprite Sheets

#### How Sprite Sheets and Animations Work

Most bitmap files in this project are **sprite sheets** rather than single images. Each sheet packs multiple frames into a grid, and the game treats each frame as a small rectangle to copy (blit) onto the screen. Animation is created by stepping through frame numbers in a defined order at a fixed timing interval.

At a high level:
- **Layout** defines the grid (frames wide × frames tall) and total frame count.
- **Frame size** is the pixel size of a single frame on the sheet.
- **Frame definitions** map a frame index to a source rectangle within the sheet (and the collision box for gameplay).
- **Animation sequences** are named lists of frame indices with a playback speed and loop/once behavior (for example: `NORMAL`, `ATTACK_LEFT`, `EXPLODE`).

The result is that a single bitmap file can contain idle, movement, attack, and explosion frames for one entity, keeping asset loading simple and rendering fast.

#### AlienA.bmp
- **File Size**: 18K
- **Dimensions**: 256 × 72 pixels (estimated)
- **Frame Size**: 32 × 8 pixels per frame
- **Layout**: 8 frames wide × 4 frames tall = 36 total frames
- **Total Frames**: 36
- **Purpose**: Small swarmer alien type
- **Frame Definitions**:
  - All frames: 23×8 pixels (display size)
  - Collision box: 23×4 (offset 0,2)
- **Animation Sequences**:
  - `NORMAL`: Frames 1-20, 50ms/frame, looping (1.0 second cycle)
  - `EXPLODE`: Frames 21-36, 10ms/frame, once (160ms total)

#### AlienB.bmp  
- **File Size**: 18K
- **Dimensions**: 128 × 128 pixels
- **Frame Size**: 16 × 16 pixels per frame
- **Layout**: 8 frames wide × 8 frames tall = 64 total frames
- **Total Frames**: 64
- **Purpose**: Multi-hit tank alien (loses legs progressively)
- **Frame Definitions**:
  - All frames: 16×16 pixels
  - Collision box: 16×9 (offset 0,0)
- **Animation Sequences**:
  - `3_LEGS`: Frames 1-8, 80ms/frame, looping
  - `3_LEGS_HIT`: Frames 9-16, 80ms/frame, once (flash)
  - `2_LEGS`: Frames 17-24, 80ms/frame, looping
  - `2_LEGS_HIT`: Frames 25-32, 80ms/frame, once
  - `1_LEG`: Frames 33-40, 80ms/frame, looping
  - `1_LEG_HIT`: Frames 41-48, 80ms/frame, once
  - `0_LEGS`: Frames 49-56, 80ms/frame, looping (crawling)
  - `EXPLODE`: Frames 57-64, 40ms/frame, once

#### AlienC.bmp
- **File Size**: 9.1K
- **Dimensions**: 128 × 64 pixels
- **Frame Size**: 16 × 16 pixels per frame
- **Layout**: 8 frames wide × 4 frames tall = 32 total frames
- **Total Frames**: 32
- **Purpose**: Flanker alien with side attacks
- **Frame Definitions**:
  - All frames: 10×16 pixels (narrow)
  - Collision box: 10×9 (offset 0,0)
- **Animation Sequences**:
  - `NORMAL`: Frames 1-8, 125ms/frame, looping
  - `ATTACK_LEFT`: Frames 9-16, 125ms/frame, looping
  - `ATTACK_RIGHT`: Frames 17-24, 125ms/frame, looping
  - `EXPLODE`: Frames 25-32, 40ms/frame, once

#### AlienD.bmp
- **File Size**: 26K
- **Dimensions**: 128 × 168 pixels
- **Frame Size**: 32 × 24 pixels per frame
- **Layout**: 4 frames wide × 7 frames tall = 28 total frames
- **Total Frames**: 28
- **Purpose**: Spinner alien (rotates continuously)
- **Frame Definitions**:
  - All frames: 20×20 pixels
  - Collision box: 20×20 (offset 0,0)
- **Animation Sequences**:
  - `NORMAL`: Frames 1-20, 25ms/frame, looping (500ms rotation)
  - `EXPLODE`: Frames 21-28, 40ms/frame, once

#### AlienE2.bmp
- **File Size**: 18K
- **Dimensions**: 128 × 128 pixels  
- **Frame Size**: 16 × 16 pixels per frame
- **Layout**: 8 frames wide × 8 frames tall = 64 total frames
- **Total Frames**: 64
- **Purpose**: Elite attacker (dive bombing)
- **Frame Definitions**:
  - Formation frames (1-24): 13×8 pixels (compact)
    - Collision box: 13×4 (offset 0,0)
  - Attack frames (25-64): 14×13 pixels (larger)
    - Collision box: 14×9 (offset 0,0)
- **Animation Sequences**:
  - `FORMATION`: Frames 1-8, 75ms/frame, looping
  - `LEAVE_FORMATION`: Frames 9-16, 75ms/frame, reverse once
  - `ENTER_FORMATION`: Frames 9-16, 75ms/frame, forward once
  - `FORMATION_EXPLODE`: Frames 17-24, 40ms/frame, once
  - `ATTACK_LEFT`: Frames 25-32, 75ms/frame, looping
  - `ATTACK_RIGHT`: Frames 33-40, 75ms/frame, looping
  - `TURN_RIGHT`: Frames 41-44, 75ms/frame, once
  - `TURN_LEFT`: Frames 45-48, 75ms/frame, once
  - `ATTACK_LEFT_EXPLODE`: Frames 49-56, 40ms/frame, once
  - `ATTACK_RIGHT_EXPLODE`: Frames 57-64, 40ms/frame, once

#### AlienE.bmp (Old Version)
- **File Size**: 16K
- **Purpose**: Older version of AlienE, replaced by AlienE2.bmp
- **Status**: Legacy file, not actively used

### Player and Weapons

#### Ship.bmp
- **File Size**: 20K
- **Dimensions**: 128 × 72 pixels
- **Frame Size**: 32 × 18 pixels per frame
- **Layout**: 4 frames wide × 4 frames tall = 24 total frames (estimate)
- **Total Frames**: 24
- **Purpose**: Player spaceship
- **Frame Definitions**:
  - All frames: 26×18 pixels
  - Collision boxes (multiple for precise hit detection):
    - Box 1: 4×7 (offset 11,2) - cockpit
    - Box 2: 16×4 (offset 5,9) - mid section
    - Box 3: 20×5 (offset 3,13) - base/engines
- **Animation Sequences**:
  - `NORMAL`: Frame 1, static, 120ms/frame
  - `SHIELDS`: Frames 5-8, 120ms/frame, looping (shield aura)
  - `EXPLODE`: Frames 9-24, 40ms/frame, once (16 frames = 640ms)

#### Missle.bmp
- **File Size**: 1.2K
- **Dimensions**: 2 × 16 pixels (1 frame wide, tall sheet)
- **Frame Size**: 2 × 8 pixels
- **Total Frames**: 1 (static sprite)
- **Purpose**: Player missile projectile
- **Frame Definitions**:
  - Single frame: 2×8 pixels
  - Collision box: 2×8 (offset 0,0)
- **Animation Sequences**:
  - `NORMAL`: Frame 1, static

### Enemy Projectiles

#### BombA.bmp
- **File Size**: 1.1K
- **Dimensions**: 2 × 8 pixels
- **Frame Size**: 2 × 8 pixels
- **Total Frames**: 1 (static)
- **Purpose**: Alien bomb type A (straight down)
- **Frame Definitions**:
  - Single frame: 2×8 pixels
  - Collision box: 2×8 (offset 0,0)
- **Animation Sequences**:
  - `NORMAL`: Frame 1, static

#### BombD.bmp
- **File Size**: 1.8K
- **Dimensions**: 24 × 30 pixels (estimated)
- **Frame Size**: 6 × 6 pixels per frame
- **Layout**: 4 frames wide × 5 frames tall = 20 frames
- **Total Frames**: 20
- **Purpose**: Alien bomb type D (directed/seeking)
- **Frame Definitions**:
  - All frames: 5×5 pixels
  - Collision box: 3×3 (offset 1,1)
- **Animation Sequences**:
  - `NORMAL`: Frames 1-20, 40ms/frame, looping (800ms cycle)

### Bonus and Power-Up Items

#### Bonuses.bmp
- **File Size**: 3.4K
- **Dimensions**: 48 × 56 pixels (estimated)
- **Frame Size**: 24 × 7 pixels per frame
- **Layout**: 2 frames wide × 7 frames tall = 14 frames
- **Total Frames**: 14
- **Purpose**: Score popup sprites
- **Frame Contents** (based on TypeDefs.bas):
  - Frame 0: "100"
  - Frame 1: "200"
  - Frame 2: "300"
  - Frame 3: "400"
  - Frame 4: "500"
  - Frame 5: "600"
  - Frame 6: "700"
  - Frame 7: "800"
  - Frame 8: "900"
  - Frame 9: "1000"
  - Frame 10: "Red 25%" (shield indicator)
  - Frame 11: "Red 50%"
  - Frame 12: "Red 75%"
  - Frame 13: "Red 100%"

#### XBonus.bmp
- **File Size**: 1.7K
- **Dimensions**: 48 × 12 pixels
- **Frame Size**: 12 × 12 pixels per frame
- **Layout**: 4 frames wide × 1 frame tall = 4 frames
- **Total Frames**: 4
- **Purpose**: Score multiplier bonus items (X2, X3, X4, X5)
- **Frame Definitions**:
  - All frames: 12×12 pixels
  - Collision box: 12×12 (offset 0,0)
- **Animation Sequences**:
  - `2XBONUS`: Frame 1, static
  - `3XBONUS`: Frame 2, static
  - `4XBONUS`: Frame 3, static
  - `5XBONUS`: Frame 4, static

#### Cargo.bmp
- **File Size**: 5.1K
- **Dimensions**: 44 × 91 pixels (estimated)
- **Frame Size**: 11 × 7 pixels per frame
- **Layout**: 4 frames wide × 8 frames tall = 32 frames
- **Total Frames**: 32
- **Purpose**: Cargo drops from cargo ship (points & power-ups)
- **Frame Definitions**:
  - All frames: 11×7 pixels
  - Collision box: 11×7 (offset 0,0)
- **Animation Sequences** (14 types):
  - `ORANGE`: Frame 1 (100 points)
  - `PINK`: Frame 2 (200 points)
  - `YELLOW`: Frame 3 (300 points)
  - `BLUE`: Frame 4 (400 points)
  - `GREEN`: Frame 5 (500 points)
  - `PURPLE`: Frame 6 (600 points)
  - `RED`: Frame 7 (700 points)
  - `NAVY`: Frame 8 (800 points)
  - `REDDOT`: Frames 9-12, 80ms/frame (shield +25%)
  - `GREENDOT`: Frames 13-16, 80ms/frame (shield +50%)
  - `BLUEDOT`: Frames 17-20, 80ms/frame (shield +75%)
  - `PINKDOT`: Frames 21-24, 80ms/frame (shield +100%)
  - `YELLOWDOT`: Frames 25-28, 80ms/frame (multiplier +1)
  - `COLORDOT`: Frames 29-32, 40ms/frame (rapid fire)

### Special Objects

#### Rocket.bmp
- **File Size**: 20K
- **Dimensions**: 128 × 144 pixels (estimated)
- **Frame Size**: 32 × 12 pixels per frame
- **Layout**: 4 frames wide × 12 frames tall = 48 frames
- **Total Frames**: 48
- **Purpose**: Cargo ship carrier (flies across screen)
- **Frame Definitions**:
  - All frames: 32×12 pixels
  - Collision box: 32×12 (offset 0,0)
- **Animation Sequences**:
  - `GO_LEFT`: Frames 1-16, 40ms/frame, looping (640ms)
  - `EXPLODE_LEFT`: Frames 17-24, 10ms/frame, once (80ms)
  - `GO_RIGHT`: Frames 25-40, 40ms/frame, looping
  - `EXPLODE_RIGHT`: Frames 41-48, 10ms/frame, once

#### Planet.bmp
- **File Size**: 9.0K
- **Dimensions**: 96 × 84 pixels (estimated)
- **Frame Size**: 24 × 12 pixels per frame
- **Layout**: 4 frames wide × 7 frames tall = 28 frames
- **Total Frames**: 28
- **Purpose**: Planetary obstacle (floats across playfield)
- **Frame Definitions** (5 size categories):
  - `SIZE1`: 24×12 pixels, collision 6×4 (offset 9,4) - tiny
  - `SIZE2`: 24×12 pixels, collision 12×4 (offset 6,4) - small
  - `SIZE3`: 24×12 pixels, collision 15×5 (offset 5,3) - medium
  - `SIZE4`: 24×12 pixels, collision 19×5 (offset 2,3) - large
  - `NORMAL`: 24×12 pixels, collision 24×7 (offset 0,2) - full size
- **Animation Sequences**:
  - `ENTERING`: Frames 1-4, 80ms/frame, once (grow in)
  - `NORMAL`: Frames 5-23, 80ms/frame, looping (rotation/drift)
  - `LEAVING`: Frames 25-28, 80ms/frame, once (shrink out)

#### Fish.bmp
- **File Size**: 27K
- **Dimensions**: 160 × 160 pixels
- **Frame Size**: 40 × 16 pixels per frame
- **Layout**: 4 frames wide × 10 frames tall = 40 frames
- **Total Frames**: 40
- **Purpose**: Fish alien (unused in main game?)
- **Frame Definitions**:
  - All frames: 40×16 pixels
  - Collision box: 40×12 (offset 0,2)
- **Animation Sequences**:
  - `NORMAL`: Frames 1-12, 50ms/frame, ping-pong (two-way)
  - `EXPLODE`: Frames 25-32, 10ms/frame, once

### User Interface

#### Dash.bmp
- **File Size**: 181K (largest asset)
- **Dimensions**: 640 × 200 pixels (estimated, dashboard graphics)
- **Purpose**: HUD/dashboard elements
- **Contents**:
  - Score display template
  - Ship icons (lives remaining)
  - Shield meter graphics
  - Bonus multiplier indicators
  - Border decorations
  - Number font (0-9 digits)
  - Miscellaneous UI elements

#### Text.bmp
- **File Size**: 41K
- **Dimensions**: 640 × 128 pixels (estimated)
- **Purpose**: Text rendering / bitmap font
- **Contents**:
  - Full character set (A-Z, 0-9, symbols)
  - Menu text
  - Title text
  - Game over / victory messages
  - High score entry characters

#### Stars.bmp
- **File Size**: 1.2K
- **Dimensions**: Unknown (small, star particles)
- **Purpose**: Background star field (parallax scrolling)
- **Contents**: Individual star sprites or star palette

---

## WAV Files (Sound Effects)

### Active Sound Effects (Used in Game)

#### Laser.wav
- **File Size**: ~2K (estimated, not listed)
- **Buffer Copies**: 5
- **Purpose**: Player missile fire
- **Trigger**: Space bar pressed (if recharged)
- **Usage Context**: High frequency (rapid fire)

#### Boom1.wav
- **File Size**: 8.7K
- **Buffer Copies**: 1
- **Purpose**: Small explosion
- **Trigger**: Alien Type A/C destroyed
- **Usage Context**: Medium frequency

#### Boom2.wav
- **File Size**: 17K
- **Buffer Copies**: 2
- **Purpose**: Large explosion
- **Trigger**: Alien Type D/E destroyed, boss explosions
- **Usage Context**: Medium frequency

#### Whoosh.wav
- **File Size**: ~4K (estimated, not listed)
- **Buffer Copies**: 5
- **Purpose**: Alien swoosh/movement sound
- **Trigger**: Alien Type E dive attack
- **Usage Context**: Medium-high frequency

#### Doh2.wav
- **File Size**: 3.6K
- **Buffer Copies**: 1
- **Purpose**: Player hit (voice: "D'oh!")
- **Trigger**: Player takes damage (voice reaction)
- **Usage Context**: Low frequency

#### Doh3.wav
- **File Size**: 6.0K
- **Buffer Copies**: 1
- **Purpose**: Player death (voice: "D'oh!" different variant)
- **Trigger**: Player ship destroyed
- **Usage Context**: Low frequency

#### Grunt1.wav
- **File Size**: 2.4K
- **Buffer Copies**: 5
- **Purpose**: Alien hit/grunt
- **Trigger**: Alien takes damage (non-fatal hit)
- **Usage Context**: High frequency

#### HeyHeyHey.wav
- **File Size**: 14K
- **Buffer Copies**: 1
- **Purpose**: Bonus collected (voice: "Hey hey hey!")
- **Trigger**: Player collects cargo/bonus
- **Usage Context**: Low-medium frequency

#### Sludge.wav
- **File Size**: 6.4K
- **Buffer Copies**: 1
- **Purpose**: Alien destruction (sludge/splat)
- **Trigger**: Alien destroyed (gooey enemy type)
- **Usage Context**: Medium frequency

#### Splat.wav
- **File Size**: 11K
- **Buffer Copies**: 1
- **Purpose**: Collision/impact effect
- **Trigger**: Various collision events
- **Usage Context**: Medium frequency

#### ApacheLoop1.wav
- **File Size**: 23K
- **Buffer Copies**: 1
- **Purpose**: Background ambiance (helicopter loop)
- **Trigger**: Background music/ambiance (looped)
- **Usage Context**: Continuous playback (DSBPLAY_LOOPING)

#### Phone.wav
- **File Size**: 27K
- **Buffer Copies**: 1
- **Purpose**: Special event trigger (phone ringing?)
- **Trigger**: Unknown (special game event)
- **Usage Context**: Low frequency (rare event)

#### Yeah.wav
- **File Size**: 9.3K
- **Buffer Copies**: 1
- **Purpose**: Victory/celebration (voice: "Yeah!")
- **Trigger**: Level complete, high score, special achievement
- **Usage Context**: Low frequency

### Unused/Test Sound Files (in Arbeit/temp folders)

#### Resource/Arbeit/ folder:
- `apacheloop1.wav` (23K) - Duplicate or alternate version
- `doh1.wav` - Unused "D'oh" variant
- `grunt2.wav` - Unused grunt variant
- `yeah.wav` (9.3K) - Duplicate or test version

#### temp/Sounds/ folder:
- `32dohs.wav` - Test file (32 "D'oh" sounds?)
- `Chopper.wav` - Helicopter sound (unused)
- `Creak.wav` - Creak effect (unused)
- `DoubleTake.wav` - Reaction sound (unused)
- `ElectChirp.wav` - Electronic chirp (unused)
- `Glitch.wav` - Glitch effect (unused)
- `HarpGliss1.wav` - Harp glissando (unused)
- `Jangle.wav` - Jangle sound (unused)
- `SnapHit.wav` - Snap/hit sound (unused)
- `Transform.wav` - Transformation sound (unused)
- `Zap.wav` - Zap effect (unused)
- `apache1.wav`, `apache2.wav` - Apache variants
- `barny(1).wav` - Barney sound (test?)
- `frogs.wav` - Frog sounds (test?)
- `hey.wav` - "Hey" voice clip
- `houst.wav` - Houston voice clip?
- `medley.wav` - Sound medley
- `mexpl.wav` - Explosion variant
- `mshot.wav` - Shot sound
- `tarzan.wav` - Tarzan yell (test/joke)

---

## Palette Files

### ai.pal
- **File Size**: 768 bytes (256 colors × 3 bytes RGB)
- **Purpose**: Primary game palette
- **Format**: 256 × PALETTEENTRY (RGB + flags)
- **Usage**: Main gameplay, all sprites share this palette
- **Color Allocation** (typical):
  - Index 0: Black (transparent)
  - Indices 1-15: UI/HUD colors
  - Indices 16-31: Player ship colors
  - Indices 32-128: Alien sprite colors
  - Indices 129-255: Background, effects, gradients

### ai2.pal
- **File Size**: 768 bytes
- **Purpose**: Alternate/secondary palette
- **Usage**: Possibly for different levels, menu screens, or palette animation

---

## Frame Definition Summary Table

| Asset | Sprite Size | Frames | Sheet Layout | Total Size |
|-------|-------------|--------|--------------|------------|
| AlienA | 32×8 | 36 | 8×4.5 | 256×72 |
| AlienB | 16×16 | 64 | 8×8 | 128×128 |
| AlienC | 16×16 | 32 | 8×4 | 128×64 |
| AlienD | 32×24 | 28 | 4×7 | 128×168 |
| AlienE | 16×16 | 64 | 8×8 | 128×128 |
| Ship | 32×18 | 24 | 4×6 | 128×108 |
| Missile | 2×8 | 1 | 1×2 | 2×16 |
| BombA | 2×8 | 1 | 1×1 | 2×8 |
| BombD | 6×6 | 20 | 4×5 | 24×30 |
| Bonuses | 24×7 | 14 | 2×7 | 48×49 |
| XBonus | 12×12 | 4 | 4×1 | 48×12 |
| Cargo | 11×7 | 32 | 4×8 | 44×56 |
| Rocket | 32×12 | 48 | 4×12 | 128×144 |
| Planet | 24×12 | 28 | 4×7 | 96×84 |
| Fish | 40×16 | 40 | 4×10 | 160×160 |

---

## Animation Sequence Catalog

### Looping Types
- **loopingNone**: Play once, stop at last frame
- **loopingNoneReverse**: Play once in reverse
- **loopingOneWay**: Loop continuously (1→N→1→N...)
- **loopingTwoWay**: Ping-pong (1→N→N-1→1...)

### Timing Patterns

| Speed Class | ms/frame | Usage |
|-------------|----------|-------|
| Very Fast | 10ms | Explosion flashes, fast effects |
| Fast | 25-40ms | Spinner, bombs, quick animations |
| Normal | 50-80ms | Most alien animations |
| Slow | 120-125ms | Player, complex alien behaviors |

### Complete Sequence List

**Player (Ship.bmp):**
1. NORMAL - Frame 1 (static), 120ms
2. SHIELDS - Frames 5-8 (looping), 120ms
3. EXPLODE - Frames 9-24 (once), 40ms

**Alien A (AlienA.bmp):**
1. NORMAL - Frames 1-20 (looping), 50ms
2. EXPLODE - Frames 21-36 (once), 10ms

**Alien B (AlienB.bmp):**
1. 3_LEGS - Frames 1-8 (looping), 80ms
2. 3_LEGS_HIT - Frames 9-16 (once), 80ms
3. 2_LEGS - Frames 17-24 (looping), 80ms
4. 2_LEGS_HIT - Frames 25-32 (once), 80ms
5. 1_LEG - Frames 33-40 (looping), 80ms
6. 1_LEG_HIT - Frames 41-48 (once), 80ms
7. 0_LEGS - Frames 49-56 (looping), 80ms
8. EXPLODE - Frames 57-64 (once), 40ms

**Alien C (AlienC.bmp):**
1. NORMAL - Frames 1-8 (looping), 125ms
2. ATTACK_LEFT - Frames 9-16 (looping), 125ms
3. ATTACK_RIGHT - Frames 17-24 (looping), 125ms
4. EXPLODE - Frames 25-32 (once), 40ms

**Alien D (AlienD.bmp):**
1. NORMAL - Frames 1-20 (looping), 25ms
2. EXPLODE - Frames 21-28 (once), 40ms

**Alien E (AlienE2.bmp):**
1. FORMATION - Frames 1-8 (looping), 75ms
2. LEAVE_FORMATION - Frames 9-16 (reverse once), 75ms
3. ENTER_FORMATION - Frames 9-16 (once), 75ms
4. FORMATION_EXPLODE - Frames 17-24 (once), 40ms
5. ATTACK_LEFT - Frames 25-32 (looping), 75ms
6. ATTACK_RIGHT - Frames 33-40 (looping), 75ms
7. TURN_RIGHT - Frames 41-44 (once), 75ms
8. TURN_LEFT - Frames 45-48 (once), 75ms
9. ATTACK_LEFT_EXPLODE - Frames 49-56 (once), 40ms
10. ATTACK_RIGHT_EXPLODE - Frames 57-64 (once), 40ms

**Bombs (BombD.bmp):**
1. NORMAL - Frames 1-20 (looping), 40ms

**Planet (Planet.bmp):**
1. ENTERING - Frames 1-4 (once), 80ms
2. NORMAL - Frames 5-23 (looping), 80ms
3. LEAVING - Frames 25-28 (once), 80ms

**Rocket (Rocket.bmp):**
1. GO_LEFT - Frames 1-16 (looping), 40ms
2. EXPLODE_LEFT - Frames 17-24 (once), 10ms
3. GO_RIGHT - Frames 25-40 (looping), 40ms
4. EXPLODE_RIGHT - Frames 41-48 (once), 10ms

**Cargo (Cargo.bmp):**
- 8 static color frames (ORANGE through NAVY)
- 6 animated power-up frames (dot variants, 4 frames each, 40-80ms)

**XBonus (XBonus.bmp):**
- 4 static multiplier frames (2X through 5X)

**Fish (Fish.bmp):**
1. NORMAL - Frames 1-12 (ping-pong), 50ms
2. EXPLODE - Frames 25-32 (once), 10ms

---

## Total Asset Statistics

### File Count
- **BMP Files**: 19 active + 3 unused/test = 22 total
- **WAV Files**: 13 active + 22 unused/test = 35 total
- **PAL Files**: 2
- **Total Assets**: 59 files

### Storage Breakdown
- **Graphics (Active BMPs)**: ~400K
- **Sounds (Active WAVs)**: ~150K
- **Palettes**: 1.5K
- **Total Active Assets**: ~550K
- **Unused/Test Files**: ~100K
- **Grand Total**: ~650K

### Frame Count
- **Total Sprite Frames**: 475+ frames across all sprite sheets
- **Most Complex**: AlienB (64 frames), AlienE (64 frames)
- **Simplest**: Missile, BombA (1 frame each)

### Memory Footprint (8-bit palettized)
- **Largest Asset**: Dash.bmp (181K, ~640×200 est.)
- **Smallest Assets**: Missiles/Bombs (~1-2K)
- **Average Sprite Sheet**: ~15K
- **Total VRAM Usage**: ~1.2 MB (surfaces + buffers)
- **Sound Buffer Memory**: ~200K (with copies)

### Asset Organization
```
AlienInvaders/
├── vb6/
│   ├── Resource/           ← Main asset folder
│   │   ├── *.bmp          ← 19 active bitmap files
│   │   ├── *.wav          ← 13 active sound files
│   │   ├── *.pal          ← 2 palette files
│   │   └── Arbeit/        ← Test/alternate assets
│   └── temp/
│       └── Sounds/        ← Unused sound library
```

---

## Usage Notes

### Color Key Transparency
- All sprite sheets use **palette index 0** (black) as transparent
- Bitmap files must have pure black (RGB 0,0,0) backgrounds
- Saved with 8-bit indexed color depth

### Sprite Sheet Layout
- Frames arranged in grids (left-to-right, top-to-bottom)
- Frame size consistent within each sheet
- Some sheets have unused frames (padding)

### Sound Format Requirements
- **Format**: WAV (PCM uncompressed)
- **Sample Rate**: 22050 Hz typical
- **Bit Depth**: 8-bit or 16-bit
- **Channels**: Mono (1 channel)
- **DirectSound** handles format conversion

### Collision Box Philosophy
- Collision boxes smaller than visible sprites (forgiving gameplay)
- Player has multiple boxes (precise hitbox for body, wings, engines)
- Aliens typically single box
- Boxes defined per-frame (change with animation state)

### Animation Design Patterns
- Looping animations: smooth movement, swimming, rotation
- One-shot animations: explosions, transformations, transitions
- Flash animations: hit reactions (8 frames typical)
- Explosion animations: 8-16 frames, 10-40ms per frame
