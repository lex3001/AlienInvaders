# Alien Invaders - Godot 4.x Port

This directory contains the Godot 4.x port of the classic VB6 Alien Invaders game.

## Project Overview

**Goal:** Port the Alien Invaders VB6 game to Godot 4.x using GDScript for modern cross-platform deployment (Windows, macOS, Linux, Web, mobile).

**Original Source:** The VB6 source code and documentation can be found in the `../vb6/` directory.

## Project Structure

```
godot/
├── project.godot                 # Godot 4.x project file
├── README.md                     # This file
├── IMPLEMENTATION_PLAN.md        # Detailed implementation plan
├── scripts/                      # GDScript files
│   ├── core/                     # Core engine scripts
│   │   ├── Game.gd               # Main game loop, timing, orchestration
│   │   ├── Actor.gd              # Base entity class (Node2D)
│   │   └── Constants.gd          # Game constants from VB6 docs
│   ├── ai/                       # AI behavior scripts
│   │   ├── Brain.gd              # Base brain class (abstract)
│   │   ├── BrainPlayer.gd        # Player input brain
│   │   ├── BrainAlienA.gd        # Formation flyer AI
│   │   ├── BrainAlienB.gd        # Decorative non-combatant AI
│   │   ├── BrainAlienC.gd        # Aggressive attacker AI
│   │   ├── BrainAlienD.gd        # Orbital bomber AI
│   │   └── BrainAlienE.gd        # Advanced enemy AI
│   ├── level/                    # Level management
│   │   ├── Level.gd              # Level manager, spawn system
│   │   └── LevelDefinitions.gd   # Level data (from VB6 LevelDefinitions.bas)
│   └── utils/                    # Utility scripts
│       ├── CollisionManager.gd   # Spatial partitioning collision detection
│       └── SoundManager.gd       # Audio management
├── scenes/                       # Godot scene files
│   ├── Main.tscn                 # Entry point scene
│   ├── Game.tscn                 # Main game scene
│   ├── Level.tscn                # Level scene template
│   └── actors/                   # Actor scene templates
│       ├── Player.tscn           # Player ship
│       ├── AlienA.tscn           # Alien type A
│       ├── AlienB.tscn           # Alien type B
│       ├── AlienC.tscn           # Alien type C
│       ├── AlienD.tscn           # Alien type D
│       ├── AlienE.tscn           # Alien type E
│       ├── Missile.tscn          # Player missile
│       └── Bomb.tscn             # Enemy bomb
├── assets/                       # Game assets
│   ├── sprites/                  # Imported BMP files
│   └── audio/                    # Imported WAV files
└── export/                       # Export presets directory
```

## Getting Started

### Prerequisites

- Godot 4.3 or later
- Basic understanding of GDScript
- Familiarity with the original VB6 game (optional but helpful)

### Opening the Project

1. Install Godot 4.3+ from [godotengine.org](https://godotengine.org/)
2. Open Godot and select "Import"
3. Navigate to this `godot/` directory and select `project.godot`
4. Click "Import & Edit"

### Building the Game

The game is implemented in phases as outlined in `IMPLEMENTATION_PLAN.md`. Each phase builds upon the previous one:

1. **Phase 1:** Core Engine Foundation
2. **Phase 2:** AI Behavior System
3. **Phase 3:** Level System & Spawning
4. **Phase 4:** Collision Detection & Combat
5. **Phase 5:** Scoring & Power-ups
6. **Phase 6:** Assets & Audio Integration
7. **Phase 7:** UI & Dashboard
8. **Phase 8:** Testing & Polish

### Running the Game

Once the implementation is complete:

1. Press F5 in the Godot editor to run the game
2. Or select Project > Export to build for your target platform

## Key Design Principles

1. **Preserve OO Design:**
   - Use `extends` for inheritance (Brain hierarchy)
   - Composition pattern: Actor contains Brain reference
   - Virtual method overrides for AI behaviors
   - Encapsulation via private variables (prefix with `_`)

2. **Maintain Original Gameplay:**
   - All constants from VB6 documentation preserved
   - Exact timing values maintained
   - Same scoring rules and multipliers
   - Same level formations and progressions

3. **Modern Godot Patterns:**
   - Scene-based architecture
   - Signals for event communication
   - Resource types for data objects
   - Input mapping for cross-platform support
   - Export presets for multi-platform builds

## Architecture Mapping

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
| PlayQuadrantManager | CollisionManager.gd | Spatial partitioning |

## Reference Documentation

The original VB6 game is extensively documented in `../vb6/docs/`:

1. **Start here:** `01_EXECUTIVE_SUMMARY.md` - Overview
2. **Architecture:** `03_ARCHITECTURE_DIAGRAMS.md` - System design
3. **Constants:** `05_FEATURE_DOCUMENTATION.md` - All gameplay values
4. **Game loop:** `04_GAME_LOOP_DETAILED.md` - Frame-by-frame logic
5. **Assets:** `07_ASSET_INVENTORY.md` - Complete asset list
6. **Source code:** `../vb6/*.cls`, `../vb6/*.bas` - Original implementation

## Export Targets

The Godot port supports the following platforms:

- **Windows** (64-bit)
- **Linux** (64-bit)
- **macOS** (Universal)
- **Web** (HTML5)
- **Android** (ARM/ARM64)
- **iOS** (ARM64)

Export presets will be configured in Phase 8 of the implementation plan.

## Contributing

When implementing features, please:

1. Follow the phased approach in `IMPLEMENTATION_PLAN.md`
2. Reference the VB6 documentation extensively
3. Preserve the original game feel while modernizing the codebase
4. Write clean, commented GDScript code
5. Test on multiple platforms when possible

## License

This port follows the licensing of the original VB6 game. See the root repository README for details.

## Contact

For questions or issues related to the Godot port, please refer to the main repository.
