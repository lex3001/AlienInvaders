# Alien Invaders - Godot Port - Build Guide

## Prerequisites

- Godot Engine 4.3 or later
- Download from: https://godotengine.org/download

## Opening the Project

1. Launch Godot Engine
2. Click "Import"
3. Navigate to this `godot/` directory
4. Select `project.godot`
5. Click "Import & Edit"

## Running the Game

### In Editor
- Press F5 or click the Play button in the top-right corner
- Or select "Project > Run Project" from the menu

### Controls
- **Arrow Keys / A,D**: Move left/right
- **Space**: Fire missile
- **Shift**: Activate shields
- **Escape**: Pause game
- **Enter**: Start game / Continue

## Exporting the Game

### Windows Export
1. Go to Project > Export
2. Add Export Preset > Windows Desktop
3. Configure export settings
4. Click "Export Project"

### Linux Export
1. Go to Project > Export
2. Add Export Preset > Linux/X11
3. Configure export settings
4. Click "Export Project"

### Web (HTML5) Export
1. Go to Project > Export
2. Add Export Preset > HTML5
3. Configure export settings
4. Click "Export Project"

## Implementation Status

All 8 phases of the VB6 to Godot migration are complete:

✅ Phase 1: Core Engine Foundation
✅ Phase 2: AI Behavior System  
✅ Phase 3: Level System & Spawning
✅ Phase 4: Collision Detection & Combat
✅ Phase 5: Scoring & Power-ups
✅ Phase 6: Assets & Audio Integration
✅ Phase 7: UI & Dashboard
✅ Phase 8: Testing & Polish

## Project Structure

```
godot/
├── project.godot           # Godot project file
├── scenes/                 # Game scenes
│   ├── Main.tscn          # Main entry point
│   ├── Level.tscn         # Level template
│   └── actors/            # Actor scene templates
├── scripts/
│   ├── core/              # Core game systems
│   ├── ai/                # AI behavior classes
│   ├── level/             # Level management
│   ├── utils/             # Utilities (collision, sound)
│   └── ui/                # User interface
└── assets/
    ├── sprites/           # Game sprites (BMP files)
    └── audio/             # Sound effects (WAV files)
```

## Features

- **3 Levels** with increasing difficulty
- **5 Alien Types** with unique AI behaviors
- **Power-up System** (shields, rapid fire, extra lives, etc.)
- **Scoring System** with multipliers
- **Spatial Partitioning** for optimized collision detection
- **Multi-channel Audio** system
- **Original Assets** from VB6 version

## Troubleshooting

### Audio Not Playing
- Check that audio files in `assets/audio/` have corresponding `.import` files
- Reimport audio: Right-click files in Godot > Reimport

### Sprites Not Showing
- BMP files may need manual import configuration in Godot
- Convert to PNG if needed for better compatibility

### Performance Issues
- Check collision manager grid size in Level.gd
- Reduce MAX_MISSILES constant if needed
- Profile with Godot's built-in profiler

## Credits

Original VB6 game ported to Godot 4.x
All assets and audio from original VB6 version
