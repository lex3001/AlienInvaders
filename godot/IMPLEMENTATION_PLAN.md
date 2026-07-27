# Alien Invaders - Godot 4.x Implementation Plan

This document provides a comprehensive, phased implementation plan for porting the Alien Invaders VB6 game to Godot 4.x using GDScript. This plan is designed for execution by AI coding agents.

## Objective

Port the Alien Invaders VB6 game to Godot 4.x using GDScript for modern cross-platform deployment (Windows, macOS, Linux, Web, mobile).

---

## Phase 1: Core Engine Foundation

**Goal:** Establish basic game loop, timing, and entity system

### Files to Create

1. **`scripts/core/Constants.gd`** - Port all constants from `vb6/docs/05_FEATURE_DOCUMENTATION.md`:
   - Player velocity: 200 px/s
   - Fire recharge: 300ms
   - Shields max: 50,000 ticks
   - All alien timing constants (bomb intervals, check frequencies)
   - Scoring values (10-75 points per enemy)
   - Multiplier values (2x-10x)

2. **`scripts/core/Actor.gd`** - Port from `vb6/Actor2.cls`:
   - Base class extending Node2D
   - Properties: position, velocity, sprite, collision_shape, brain
   - Methods: _ready(), _process(delta), move(delta), take_damage(), destroy()
   - Composition: holds reference to Brain instance

3. **`scripts/core/Game.gd`** - Port from `vb6/Game.cls`:
   - Main game loop orchestration
   - Frame timing (track delta, maintain 25-30 FPS)
   - State management (game_state enum: MENU, PLAYING, PAUSED, GAME_OVER)
   - Score tracking, lives tracking
   - Reference to current Level instance

4. **`scenes/Main.tscn`** - Entry point with Game node

### Architecture Reference

- Study `vb6/docs/03_ARCHITECTURE_DIAGRAMS.md` for system overview
- Study `vb6/docs/04_GAME_LOOP_DETAILED.md` for timing system

### Success Criteria

- Game window opens at 640x480
- Basic game loop runs at ~25-30 FPS
- Actor base class can be instantiated with sprite

---

## Phase 2: AI Behavior System

**Goal:** Implement polymorphic AI system using OO inheritance

### Files to Create

1. **`scripts/ai/Brain.gd`** - Port from `vb6/Brains.cls`:
   ```gdscript
   class_name Brain
   extends Resource
   
   var actor: Actor
   var level: Level
   
   func initialize(p_actor: Actor, p_level: Level):
       actor = p_actor
       level = p_level
   
   func update_state(delta: float):
       # Virtual method - override in derived classes
       pass
   
   func reset_state():
       pass
   ```

2. **`scripts/ai/BrainPlayer.gd`** - Port from `vb6/BrainsPlayer.cls`:
   - Handle input (LEFT/RIGHT arrows, SPACE, SHIFT, ALT)
   - Movement logic (200 px/s velocity)
   - Fire missiles (300ms recharge time)
   - Shield activation

3. **`scripts/ai/BrainAlienA.gd`** - Port from `vb6/BrainsAlienA.cls`:
   - Formation flying behavior
   - Bomb dropping (4000ms interval)
   - Reference constants from Constants.gd

4. **`scripts/ai/BrainAlienB.gd`** - Port from `vb6/BrainsAlienB.cls`:
   - Decorative movement (no attacks)

5. **`scripts/ai/BrainAlienC.gd`** - Port from `vb6/BrainsAlienC.cls`:
   - Aggressive attack behavior
   - Player detection (48px range)
   - Attack checks (8000ms intervals)

6. **`scripts/ai/BrainAlienD.gd`** - Port from `vb6/BrainsAlienD.cls`:
   - Orbital movement pattern
   - Bomb dropping (5000ms interval)

7. **`scripts/ai/BrainAlienE.gd`** - Port from `vb6/BrainsAlienE.cls`:
   - Advanced AI (15000ms attack interval)
   - Complex bomb patterns (10000ms/2000ms)

### Architecture Reference

- Study `vb6/docs/05_FEATURE_DOCUMENTATION.md` sections on Enemy AI Behaviors
- Study VB6 source files: `vb6/BrainsAlienA.cls` through `vb6/BrainsAlienE.cls`

### Success Criteria

- All Brain classes inherit from base Brain
- Each alien type has distinct behavior matching VB6 original
- Player input controls ship movement and firing

---

## Phase 3: Level System & Spawning

**Goal:** Implement level management, enemy spawning, progression

### Files to Create

1. **`scripts/level/Level.gd`** - Port from `vb6/Level.cls`:
   - Manage arrays of actors (aliens, missiles, bombs)
   - Spawn system (create actors with appropriate brains)
   - Collision detection (port spatial partitioning from VB6)
   - Level completion detection
   - Update all entities each frame

2. **`scripts/level/LevelDefinitions.gd`** - Port from `vb6/LevelDefinitions.bas`:
   - Level 1 configuration (enemy formations, positions)
   - Level 2 configuration
   - Level 3 configuration
   - Enemy type definitions
   - Spawn timing data

3. **`scenes/Level.tscn`** - Level scene template with:
   - Boundaries (top border at 32px, bottom border at 20px)
   - Spawn points
   - Background layers

### Architecture Reference

- Study `vb6/docs/05_FEATURE_DOCUMENTATION.md` section on Level Progression
- Study `vb6/LevelDefinitions.bas` for exact enemy positions and formations

### Success Criteria

- Level 1 spawns correctly with proper enemy formations
- Enemies move according to their AI behaviors
- Level completion triggers next level

---

## Phase 4: Collision Detection & Combat

**Goal:** Implement collision system, projectiles, explosions

### Files to Create

1. **`scripts/utils/CollisionManager.gd`** - Port from VB6 collision system:
   - Quadrant-based spatial partitioning (O(n*m/k) performance)
   - AABB collision detection
   - Collision response (damage, destruction)

2. **Actor collision scenes:**
   - `scenes/actors/Missile.tscn` - Player projectile
   - `scenes/actors/Bomb.tscn` - Enemy projectile

3. **Collision logic in Actor.gd:**
   - Hit detection
   - Damage calculation
   - Explosion animations
   - Death sequences

### Architecture Reference

- Study `vb6/docs/05_FEATURE_DOCUMENTATION.md` section on Collision Detection
- Study `vb6/docs/03_ARCHITECTURE_DIAGRAMS.md` for collision system flow
- Study `vb6/PlayQuadrantManager.cls` for spatial partitioning implementation

### Success Criteria

- Missiles destroy aliens on hit
- Bombs destroy player on hit
- Spatial partitioning optimizes collision checks
- Explosions play on destruction

---

## Phase 5: Scoring & Power-ups

**Goal:** Implement scoring system, multipliers, power-ups

### Files to Create/Modify

1. **Update `scripts/core/Game.gd`:**
   - Score tracking with multipliers (2x-10x)
   - Bonus system (10-200 points)
   - High score persistence

2. **Power-up system:**
   - Cargo drops (8 types from VB6)
   - Double shot, rapid fire, multi-shot
   - Shield recharge
   - Extra lives
   - Score bonuses

3. **Update `scripts/level/Level.gd`:**
   - Power-up spawning logic
   - Power-up collection detection

### Architecture Reference

- Study `vb6/docs/05_FEATURE_DOCUMENTATION.md` sections on Scoring System and Power-up System
- Study exact point values and multiplier rules

### Success Criteria

- Score increases correctly for each enemy type
- Multipliers apply and stack properly
- Power-ups spawn and apply effects
- High scores save/load

---

## Phase 6: Assets & Audio Integration

**Goal:** Import and integrate all visual and audio assets

### Tasks

1. **Import sprites from `vb6/Resource/*.bmp`:**
   - Player ship sprites (normal, shields, exploding)
   - All 5 alien type sprites + explosion frames
   - Missile and bomb sprites
   - UI elements, dashboard graphics
   - Convert BMPs to PNG if needed for better Godot compatibility

2. **Import audio from `vb6/Resource/*.wav`:**
   - LASER.WAV (weapon fire)
   - BOOM1.WAV, BOOM2.WAV (explosions)
   - DOH2.WAV, HEYHEYHEY.WAV, GRUNT1.WAV (voice clips)
   - WHOOSH.WAV, SPLAT.WAV (ambient)
   - TYPE.WAV (UI)
   - APACHELOOP1.WAV (music)

3. **Create `scripts/utils/SoundManager.gd`:**
   - Multi-channel audio playback (match VB6's 5 buffer copies)
   - Simultaneous sound effect support
   - Music looping

4. **Apply sprites to all actor scenes:**
   - Update Player.tscn, AlienA-E.tscn with proper sprites
   - Configure animation frames
   - Set collision shapes based on sprite bounds

### Architecture Reference

- Study `vb6/docs/07_ASSET_INVENTORY.md` for complete asset catalog
- Study `vb6/docs/06_DIRECTX_TECHNICAL_SPECS.md` for audio system details

### Success Criteria

- All sprites display correctly
- Animations play smoothly
- Sound effects trigger appropriately
- Music loops seamlessly

---

## Phase 7: UI & Dashboard

**Goal:** Implement HUD, menus, game over screens

### Files to Create

1. **UI scenes:**
   - HUD display (score, lives, shields, multiplier)
   - Title screen
   - Game over screen
   - High score entry screen
   - Pause menu

2. **Dashboard rendering:**
   - Port dashboard logic from `vb6/Game.cls`
   - Top border (32px) with status indicators
   - Bottom border (20px)
   - Shield energy bar
   - Lives indicator

### Architecture Reference

- Study VB6 dashboard rendering code in `vb6/Game.cls`
- Study UI element positions and layouts

### Success Criteria

- HUD displays all game state correctly
- Menus are functional and navigable
- High score entry works with keyboard
- Dashboard matches VB6 layout

---

## Phase 8: Testing & Polish

**Goal:** Bug fixes, performance tuning, cross-platform testing

### Tasks

1. **Gameplay testing:**
   - Verify all 3 levels work correctly
   - Test all 5 alien AI behaviors
   - Test all power-ups
   - Verify scoring calculations
   - Test game over and restart flows

2. **Performance optimization:**
   - Profile frame time (maintain 25-30 FPS)
   - Optimize collision detection if needed
   - Memory usage checks

3. **Cross-platform testing:**
   - Test on Windows
   - Test on Linux
   - Test Web export (HTML5)
   - Test on macOS if available

4. **Polish:**
   - Particle effects for explosions
   - Screen shake on hits
   - Better visual feedback
   - Smooth transitions

### Success Criteria

- Game matches VB6 gameplay feel
- Runs smoothly on all target platforms
- No game-breaking bugs
- Professional polish level

---

## Architecture Mapping Summary

| VB6 Component | Godot Equivalent | Notes |
|---------------|------------------|-------|
| Game.cls | Game.gd + Game.tscn | Main orchestration |
| Level.cls | Level.gd + Level.tscn | Level management |
| Actor2.cls | Actor.gd (Node2D) | Base entity class |
| Brains.cls | Brain.gd (Resource) | Base AI class |
| BrainsPlayer.cls | BrainPlayer.gd | Player input handler |
| BrainsAlienA-E.cls | BrainAlienA-E.gd | Enemy AI behaviors |
| DirectDraw surfaces | Sprite2D nodes | Graphics rendering |
| DirectSound buffers | AudioStreamPlayer | Sound effects |
| DirectInput | Input singleton | Keyboard input |
| LevelDefinitions.bas | LevelDefinitions.gd | Level data |
| PlayQuadrantManager.cls | CollisionManager.gd | Spatial partitioning |

---

## Key Design Principles

### 1. Preserve OO Design

- Use `extends` for all inheritance (Brain hierarchy)
- Composition pattern: Actor contains Brain reference
- Virtual method overrides for AI behaviors
- Encapsulation via private variables (prefix with `_`)

### 2. Maintain Original Gameplay

- All constants from `vb6/docs/05_FEATURE_DOCUMENTATION.md`
- Exact timing values (4000ms, 8000ms intervals, etc.)
- Same scoring rules and multipliers
- Same level formations and progressions

### 3. Modern Godot Patterns

- Scene-based architecture
- Signals for event communication
- Resource types for data objects
- Input mapping for cross-platform support
- Export presets for multi-platform builds

---

## Reference Documentation Priority

1. **Start here:** `vb6/docs/01_EXECUTIVE_SUMMARY.md` - Overview
2. **Architecture:** `vb6/docs/03_ARCHITECTURE_DIAGRAMS.md` - System design
3. **Constants:** `vb6/docs/05_FEATURE_DOCUMENTATION.md` - All gameplay values
4. **Game loop:** `vb6/docs/04_GAME_LOOP_DETAILED.md` - Frame-by-frame logic
5. **Assets:** `vb6/docs/07_ASSET_INVENTORY.md` - Complete asset list
6. **Source code:** `vb6/*.cls`, `vb6/*.bas` - Original implementation

---

## Implementation Notes for AI Agents

### General Guidelines

- **Complete phases sequentially** - Each phase builds on the previous
- **Reference VB6 documentation extensively** - Use exact values and behaviors
- **Preserve original game feel** - Match timing, movement, and gameplay
- **Write clean code** - Comment complex logic, use meaningful variable names
- **Test incrementally** - Verify each phase before moving to the next

### Specific Considerations

1. **Timing System:**
   - VB6 used millisecond timing - convert to Godot's delta time
   - Maintain 25-30 FPS target (game was designed for this rate)
   - Use accumulated time for interval-based behaviors

2. **Coordinate System:**
   - VB6 used top-left origin - Godot uses center origin by default
   - Viewport is 640x480 (match VB6 resolution)
   - Top border at 32px, bottom border at 20px

3. **Collision Detection:**
   - Port PlayQuadrantManager's spatial partitioning system
   - Use AABB (Axis-Aligned Bounding Box) collision
   - Optimize for many entities (aliens, missiles, bombs)

4. **AI Behaviors:**
   - Each Brain class should be independent and reusable
   - Use composition (Actor has-a Brain) not inheritance
   - Timing constants are critical - use exact VB6 values

5. **Asset Integration:**
   - BMPs may need conversion to PNG for Godot
   - Maintain original sprite dimensions
   - Audio should be imported at original sample rates

---

## Expected Deliverables

Upon completion of all 8 phases, the project should include:

1. **Fully functional Godot 4.x project**
   - All scenes and scripts implemented
   - All assets imported and configured
   - Export presets configured

2. **Complete gameplay implementation**
   - All 3 levels playable
   - All 5 alien types with correct AI
   - All power-ups functional
   - Scoring system working

3. **Cross-platform support**
   - Windows export preset
   - Linux export preset
   - Web (HTML5) export preset
   - Optional: macOS, Android, iOS presets

4. **Documentation**
   - Code comments explaining complex logic
   - README with build/run instructions
   - Export instructions for each platform

5. **Quality assurance**
   - Gameplay matches VB6 original
   - Performance meets targets (25-30 FPS)
   - No game-breaking bugs
   - Professional polish

---

## Quick Start Checklist

For AI agents beginning implementation:

- [ ] Read `vb6/docs/01_EXECUTIVE_SUMMARY.md` for overview
- [ ] Study `vb6/docs/03_ARCHITECTURE_DIAGRAMS.md` for system design
- [ ] Review `vb6/docs/05_FEATURE_DOCUMENTATION.md` for all constants
- [ ] Begin Phase 1: Core Engine Foundation
- [ ] Test each phase before proceeding to next
- [ ] Reference VB6 source code for exact implementations
- [ ] Maintain original gameplay feel throughout

---

**Version:** 1.0  
**Last Updated:** 2026-02-08  
**Target Godot Version:** 4.3+
