# Alien Invaders - Complete Game Documentation

This directory contains comprehensive documentation for the VB6 DirectX 2D shooter game **Alien Invaders** (c) 1998-1999 by Luther Ananda Miller.

## Documentation Structure

The documentation is organized into 8 comprehensive files covering all aspects of the game's architecture, implementation, and recreation guidance:

### 1. [Executive Summary](01_EXECUTIVE_SUMMARY.md)
**Quick Overview** - Start here for a high-level understanding
- Game overview and purpose
- Architecture summary (7 major subsystems)
- Technical foundation (DirectX 7/8 components)
- Key features (3 levels, 5 enemy types, power-ups)
- Game loop design pattern

**Lines:** 53 | **Read Time:** 2-3 minutes

---

### 2. [Component Catalog](02_COMPONENT_CATALOG.md)
**Complete File Reference** - Detailed inventory of all VB6 source files
- 16 Core Modules (.bas) - Entry points, DirectX wrappers, utilities
- 4 Game Engine Classes - Main controller, level manager, actors
- 17 AI Behavior Classes - Polymorphic enemy/player behaviors
- 8 Graphics Classes - Sprite management, animation system
- 9 Utility Classes - Collision, input, sound, spatial partitioning
- 1 Form - DirectX rendering surface

**Lines:** 496 | **Read Time:** 15-20 minutes

---

### 3. [Architecture Diagrams](03_ARCHITECTURE_DIAGRAMS.md)
**Visual System Design** - ASCII/text-based diagrams
- System architecture overview
- Class hierarchy (Actor system)
- Brains AI class hierarchy (inheritance tree)
- DirectX component architecture
- Collision detection system flow
- Game loop flow diagram
- Movement system architecture
- Data flow (input → update → render)

**Lines:** 492 | **Read Time:** 20-25 minutes

---

### 4. [Game Loop Detailed](04_GAME_LOOP_DETAILED.md)
**Frame-by-Frame Breakdown** - Deep dive into the game loop
- Timing system (25 FPS target, 40ms per frame)
- 7-phase game loop:
  1. Frame timing calculation
  2. Input polling (DirectInput)
  3. Update phase (movement, AI)
  4. Collision detection (spatial partitioning)
  5. State updates (explosions, deaths)
  6. Rendering (draw order, blitting)
  7. Buffer flip (present to screen)
- Performance monitoring system
- Pseudocode for each phase
- Time budget analysis

**Lines:** 507 | **Read Time:** 15-20 minutes

---

### 5. [Feature Documentation](05_FEATURE_DOCUMENTATION.md)
**Gameplay Mechanics** - Every game feature explained in detail
- **Player Mechanics:** Movement (200 px/s), firing (300ms recharge), shields (50,000 ticks)
- **Enemy AI Behaviors:** All 5 alien types with timing constants
  - Alien A: Formation flyer (4000ms bomb interval)
  - Alien B: Decorative non-combatant
  - Alien C: Aggressive attacker (48px range, 8000ms checks)
  - Alien D: Orbital bomber (5000ms bombs)
  - Alien E: Advanced enemy (15000ms attacks, 10000ms/2000ms bombs)
- **Collision Detection:** AABB algorithm with pseudocode
- **Scoring System:** Points per enemy (10-75), multipliers (2x-10x), bonuses (10-200)
- **Power-up System:** 8 cargo types (double shot, rapid fire, multi-shot, shields, lives)
- **Level Progression:** 3 levels with distinct formations
- **Win/Loss Conditions:** Must-destroy aliens, player lives

**Lines:** 1,110 | **Read Time:** 35-40 minutes

---

### 6. [DirectX Technical Specifications](06_DIRECTX_TECHNICAL_SPECS.md)
**Low-Level Implementation** - DirectX 7 API usage
- **DirectX Components:**
  - DirectDraw2 (IDirectDraw2 interface)
  - DirectSound (IDirectSound interface)
  - DirectInput (IDirectInput interface)
- **Graphics System:**
  - Surface management (primary, 2x back buffers)
  - 640x480x8 (256 colors with palette)
  - Page flipping vs BitBlt (fullscreen vs windowed)
  - Sprite blitting pipeline (BltFast operations)
- **Audio System:**
  - Sound buffer architecture (5 copies per effect)
  - WAV file loading and streaming
  - Simultaneous playback
- **Input System:**
  - Keyboard polling (256-key state array)
  - Non-blocking acquisition
- **VB6 Limitations:**
  - COM interface overhead
  - Variant type boxing
  - No inline functions
  - Garbage collection pauses

**Lines:** 1,060 | **Read Time:** 30-35 minutes

---

### 7. [Asset Inventory](07_ASSET_INVENTORY.md)
**Complete Asset Catalog** - All game resources documented
- **Bitmaps:** 19 sprite sheets
  - Player ship (3 states: normal, shields, exploding)
  - 5 alien types (normal + explosion frames)
  - Weapons (missiles, bombs)
  - Bonuses (planets, cargo, multipliers)
  - UI elements (dashboard, text)
- **Audio:** 13 sound effects
  - Weapons (LASER.WAV)
  - Explosions (BOOM1.WAV, BOOM2.WAV)
  - Voice clips (DOH2.WAV, HEYHEYHEY.WAV, GRUNT1.WAV)
  - Ambient (WHOOSH.WAV, SPLAT.WAV)
  - UI (TYPE.WAV)
  - Music (APACHELOOP1.WAV)
- **Palettes:** 2 color palettes (AI.PAL, AI2.PAL)
- **Frame Definitions:** Collision boxes, offsets, dimensions
- **Animation Sequences:** Frame lists, timing, looping behavior

**Lines:** 639 | **Read Time:** 20-25 minutes

---

### 8. [Recreation Roadmap](08_RECREATION_ROADMAP.md)
**Modern Platform Migration Guide** - How to recreate the game
- **Modern Framework Recommendations:**
  - **Desktop:** SDL2 (C/C++), MonoGame (C#), Pygame (Python)
  - **Web:** Phaser 3 (JavaScript/TypeScript)
  - **Cross-Platform:** Unity, Godot
  - **Mobile:** Corona SDK, LibGDX
- **Key Considerations:**
  - VB6 quirks (1-based arrays, COM interfaces, DoEvents)
  - DirectX to modern API mapping
  - Frame-rate independence
  - Asset format conversion
- **Hardcoded Values to Parameterize:**
  - Screen resolution (640x480 → configurable)
  - Enemy spawn rates, velocities
  - Difficulty scaling
  - Control bindings
- **Suggested Improvements:**
  - Particle effects
  - Screen shake
  - Better hit feedback
  - Difficulty modes
  - Save/load system
  - Achievement system
- **7-Phase Migration Strategy:**
  - Phase 1: Core engine (2-3 weeks)
  - Phase 2: Graphics (2-3 weeks)
  - Phase 3: Audio (1 week)
  - Phase 4: Gameplay (3-4 weeks)
  - Phase 5: AI (2-3 weeks)
  - Phase 6: Polish (2-3 weeks)
  - Phase 7: Testing (3-4 weeks)
  - **Total:** 16-27 weeks
- **Platform-Specific Guides:** Desktop, web, mobile, console

**Lines:** 1,010 | **Read Time:** 30-35 minutes

---

## Documentation Statistics

- **Total Files:** 8 markdown documents
- **Total Lines:** 5,367 lines
- **Total Size:** ~176 KB
- **Estimated Read Time:** 2.5-3 hours (complete documentation)
- **Code Snippets:** 50+ examples from actual VB6 source
- **Diagrams:** 15+ ASCII architecture diagrams
- **Constants:** 100+ documented game parameters

## How to Use This Documentation

### For Understanding the Game
1. Start with **Executive Summary** for the big picture
2. Review **Architecture Diagrams** for visual understanding
3. Read **Game Loop Detailed** to understand the core engine
4. Study **Feature Documentation** for gameplay mechanics

### For Code Analysis
1. Use **Component Catalog** as a file reference
2. Check **DirectX Technical Specifications** for API details
3. Reference **Asset Inventory** for resource locations
4. Study actual source code in `/vb6/` directory

### For Recreation/Porting
1. Read **Executive Summary** to understand what to recreate
2. Study **Feature Documentation** for exact mechanics
3. Follow **Recreation Roadmap** for step-by-step guidance
4. Use **DirectX Technical Specifications** for API equivalents
5. Reference **Asset Inventory** for required resources

### For Modern Game Development Students
This codebase demonstrates:
- **Object-Oriented Design:** Polymorphic AI behaviors, composition over inheritance
- **Spatial Partitioning:** Quadrant-based collision detection optimization
- **Game Loop Pattern:** Fixed/variable time step with delta time
- **State Machines:** Enemy AI with well-defined states
- **Data-Driven Design:** Level definitions, sprite frame data
- **Performance Optimization:** Precomputed circular paths, spatial partitioning
- **1990s Best Practices:** Double buffering, dirty rectangles, sprite sheets

## Original Game Information

- **Title:** Alien Invaders
- **Author:** Luther Ananda Miller
- **Copyright:** (c) 1998-1999
- **Contact:** luther@usa.net
- **Website:** http://www.lanandam.com/ai/ai.htm
- **Technology:** Visual Basic 6, DirectX 7/8
- **Release:** Alpha Version 0.0, Build 254

## Controls

- **LEFT/RIGHT Arrow:** Move ship horizontally
- **SPACE:** Stop ship movement
- **SHIFT:** Fire missile
- **ALT:** Activate shields

## Game Features

- **3 Levels** with unique enemy formations
- **5 Enemy Types** with distinct AI behaviors
- **Power-ups:** Double shot, rapid fire, multi-shot, extra lives
- **Scoring:** Points, multipliers (2x-10x), combo bonuses
- **High Scores:** Persistent high score table with name entry

## Source Code Location

The original VB6 source code is located in `/vb6/` directory:
- Entry point: `Main.bas`
- Main game loop: `Game.cls` (Game2.cls)
- Level manager: `Level.cls`
- AI behaviors: `Brains*.cls`
- DirectX modules: `DirectDraw.bas`, `DSModule.bas`, `DirectInput.bas`

## Additional Resources

- Original game executable: `/vb6/AlienInv.exe`
- Build history: `/vb6/readme.txt`
- Debug logs: `/vb6/debug.log`
- Assets: `/vb6/Resource/` (bitmaps, sounds, palettes)

---

**Documentation created:** February 2026  
**Based on:** Original 1998-1999 VB6 source code  
**Purpose:** Complete technical blueprint for game recreation and study

This documentation provides everything needed to understand, maintain, or recreate Alien Invaders on modern platforms while preserving the original gameplay and feel.
