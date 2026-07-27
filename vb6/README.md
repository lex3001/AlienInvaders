# Alien Invaders - VB6 DirectX 2D Shooter Game

![Alien Invaders](https://img.shields.io/badge/Year-1998--1999-blue) ![VB6](https://img.shields.io/badge/VB6-DirectX%207%2F8-yellow) ![Status](https://img.shields.io/badge/Status-Documented-green)

A classic 2D shooter game developed in Visual Basic 6 with DirectX 7/8.

The primary influence is the Mac game **Solarian II** (Ben Haller, Stick Software, 1989 — Action, Shareware; supported on System 7–9 and Mac OS X 10.3–10.5). Official page: https://www.sticksoftware.com/archive/Solarian.html. It in turn riffs on **Space Invaders**, **Galaxian**, and related arcade staples—with a few extra twists that make it feel more playful and dynamic. Although VB6 was rarely used for arcade-style games, it is compiled and can leverage DirectX, so building a smooth shooter in it was entirely feasible—so why not?

**Author:** Luther Ananda Miller  
**Copyright:** (c) 1998-1999  
**Website:** [redacted]

---

## 🎮 Game Overview

Alien Invaders is a nostalgic trip back to 1999-era game development, showcasing what was possible with VB6 and DirectX. Battle through three levels of alien formations, collect power-ups, and aim for the high score!

### Features
- ✨ **3 Distinct Levels** with unique enemy formations
- 👾 **5 Enemy Types** with specialized AI behaviors
- 🚀 **Power-up System:** Double shots, rapid fire, multi-shots, extra lives
- 🛡️ **Shield System** with limited energy
- 🎯 **Scoring System** with multipliers up to 10x
- 💾 **High Score Persistence** with name entry
- 🎵 **DirectSound Audio** with simultaneous sound effects
- 🖼️ **Sprite-based Graphics** with smooth animations

### Controls
- **LEFT/RIGHT Arrow:** Move ship
- **SPACE:** Stop movement
- **SHIFT:** Fire missile
- **ALT:** Activate shields

---

## 📚 Complete Documentation

This repository includes **comprehensive technical documentation** covering every aspect of the game's architecture, implementation, and recreation guidance.

### Documentation Files (in `/docs/`)

| File | Description | Lines | Read Time |
|------|-------------|-------|-----------|
| [**README**](docs/README.md) | Documentation index & guide | 260 | 5 min |
| [**01 - Executive Summary**](docs/01_EXECUTIVE_SUMMARY.md) | High-level overview | 53 | 3 min |
| [**02 - Component Catalog**](docs/02_COMPONENT_CATALOG.md) | Complete file reference | 496 | 20 min |
| [**03 - Architecture Diagrams**](docs/03_ARCHITECTURE_DIAGRAMS.md) | Visual system design | 492 | 25 min |
| [**04 - Game Loop Detailed**](docs/04_GAME_LOOP_DETAILED.md) | Frame-by-frame breakdown | 507 | 20 min |
| [**05 - Feature Documentation**](docs/05_FEATURE_DOCUMENTATION.md) | Gameplay mechanics | 1,110 | 40 min |
| [**06 - DirectX Technical Specs**](docs/06_DIRECTX_TECHNICAL_SPECS.md) | Low-level implementation | 1,060 | 35 min |
| [**07 - Asset Inventory**](docs/07_ASSET_INVENTORY.md) | Complete asset catalog | 639 | 25 min |
| [**08 - Recreation Roadmap**](docs/08_RE-CREATION_ROADMAP.md) | Modern platform guide | 1,010 | 35 min |

**Total:** 5,367 lines of comprehensive documentation

See the full documentation index in [docs/README.md](docs/README.md).

---

## 🏗️ Architecture Highlights

### Core Components
- **Game loop & orchestration** - Central controller that owns timing, frame updates, and the overall run state.
- **World & level system** - Manages level rules, spawns, and high-level progression.
- **Entity & sprite layer** - Uniform representation for player, enemies, and projectiles, including rendering and state.
- **Behavior system** - Pluggable AI routines that define how each entity thinks and acts.

### Technical Stack
- **VB6** - Primary application logic, game flow, and control code
- **DirectX (via VB6)** - Low-level system integration used by the VB6 app:
    - **DirectDraw2** for 2D rendering (640x480, 8-bit color)
    - **DirectSound** for multi-buffer audio
    - **DirectInput** for keyboard polling

### Key Algorithms
- **Spatial Partitioning:** Quadrant-based collision detection for O(n*m/k) performance
- **Precomputed Paths:** RadialMovementPoints for efficient circular movement
- **State Machines:** AI behaviors with well-defined states
- **Double Buffering:** Smooth 25-30 FPS rendering

---

## 📂 Repository Structure

```
AlienInvaders/
├── docs/                          # Complete game documentation
│   ├── README.md                  # Documentation index
│   ├── 01_EXECUTIVE_SUMMARY.md
│   ├── 02_COMPONENT_CATALOG.md
│   ├── 03_ARCHITECTURE_DIAGRAMS.md
│   ├── 04_GAME_LOOP_DETAILED.md
│   ├── 05_FEATURE_DOCUMENTATION.md
│   ├── 06_DIRECTX_TECHNICAL_SPECS.md
│   ├── 07_ASSET_INVENTORY.md
│   └── 08_RE-CREATION_ROADMAP.md
│
└── vb6/                           # Original VB6 source code
    ├── AlienInvaders.vbp          # VB6 project file
    ├── AlienInv.exe               # Compiled game executable
    ├── Main.bas                   # Entry point
    ├── Game.cls                   # Main game controller
    ├── Level.cls                  # Level manager
    ├── Actor2.cls                 # Sprite entity
    ├── Brains*.cls                # AI behaviors (17 classes)
    ├── DirectDraw.bas             # Graphics module
    ├── DSModule.bas               # Sound module
    ├── DirectInput.bas            # Input module
    ├── GameUtils.bas              # Utilities
    ├── LevelDefinitions.bas       # Level configurations
    ├── Resource/                  # Game assets
    │   ├── *.bmp                  # 19 sprite sheets
    │   ├── *.wav                  # 13 sound effects
    │   └── *.pal                  # 2 color palettes
    └── readme.txt                 # Original release notes
```

---

## 🎯 Documentation Goals

This documentation provides:

1. **Complete Technical Blueprint** - Everything needed to recreate the game
2. **Architecture Analysis** - Modern design patterns in 1999 code
3. **Learning Resource** - Classic game development techniques
4. **Migration Guide** - Porting to modern platforms (Unity, Godot, SDL, Phaser, etc.)

### Who This Is For
- 🎓 **Game Development Students** learning classic game architecture
- 👨‍💻 **Developers** interested in VB6/DirectX game programming
- 🔄 **Porters** wanting to recreate the game on modern platforms
- 📖 **Historians** preserving 1990s game development knowledge
- 🎮 **Retro Enthusiasts** appreciating classic game design

---

## 🚀 Quick Start

### View Documentation
Start with the [Documentation Index](docs/README.md) for guided reading.

### Run the Game (Windows Only)
1. Navigate to `/vb6/` directory
2. Run `AlienInv.exe`
3. Requires Windows 95/98/XP or compatibility mode
4. May need DirectX 7/8 runtime libraries

### Explore Source Code
1. Open `vb6/AlienInvaders.vbp` in Visual Basic 6
2. Entry point: `Main.bas` → `Sub Main()`
3. Game loop: `Game.cls` (Game2) → `UpdateFrame()`
4. Enemies: `BrainsAlien[A-E].cls`

---

## 🛠️ Recreating on Modern Platforms

This LLM generated [**Recreation Roadmap**](docs/08_RE-CREATION_ROADMAP.md) provides detailed guidance for porting to:

### Recommended Frameworks
| Platform | Framework | Language | Difficulty |
|----------|-----------|----------|------------|
| Desktop | SDL2 | C/C++ | Medium |
| Desktop | MonoGame | C# | Easy |
| Desktop | Pygame | Python | Easy |
| Web | Phaser 3 | TypeScript | Easy |
| Cross-Platform | Unity | C# | Easy |
| Cross-Platform | Godot | GDScript | Easy |
| Mobile | LibGDX | Java/Kotlin | Medium |

### Migration Estimate
**16-27 weeks** for full recreation with polish (see Phase breakdown in Recreation Roadmap)

---

## 📊 Code Statistics

- **Total VB6 Files:** 60+ source files
- **Modules (.bas):** 16
- **Classes (.cls):** 42
- **Forms (.frm):** 1
- **Estimated LOC:** 8,000-10,000 lines
- **Bitmaps:** 19 sprite sheets
- **Sound Effects:** 13 WAV files
- **Levels:** 3 configured

---

## 🎓 Educational Value

This codebase demonstrates:

- **Object-Oriented Design** in VB6 (late binding, COM interfaces)
- **Polymorphic AI** through Brains interface hierarchy
- **Spatial Partitioning** for collision detection optimization
- **Game Loop Pattern** with delta time
- **State Machines** for enemy behaviors
- **Double Buffering** and page flipping
- **DirectX API Usage** (DrawDraw, DirectSound, DirectInput)
- **Resource Management** (sprite sheets, sound buffers)
- **1990s Best Practices** and limitations

---

## 📝 Version History

**Build 254** (Final documented release)
- High score name entry
- Bug fixes for DirectX RECT errors
- Custom palette support

**Build 251**
- 3 levels implemented
- Power-up system (rockets, cargo drops)

**Build 191**
- Planet prizes
- Bonus multipliers

**Build 189**
- 8.3 filename support

---

## 📜 License

Copyright (c) 1998-1999 Luther Ananda Miller

*Documentation created February 2026 for historical preservation and educational purposes.*

---

## 🤝 Contributing

This is a historical preservation project. The documentation is complete, but contributions welcome for:
- Additional analysis or insights
- Modern framework port examples
- Corrections or clarifications

---

## 📧 Contact

**Original Author:** Luther Ananda Miller ([redacted])  
**Documentation:** GitHub Community

---

## ⭐ Acknowledgments

- **Luther Ananda Miller** - Original game developer
- **Patrice Scribe** - DirectX 6 Type Library (1998)
- Classic arcade games that inspired this project

---

**Start exploring:** [Documentation Index](docs/README.md)

*A piece of 1999 game development history, preserved and documented.*
