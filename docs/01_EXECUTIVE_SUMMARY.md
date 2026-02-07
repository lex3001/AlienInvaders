# Alien Invaders - Executive Summary

## Overview

**Alien Invaders** is a 2D vertical-scrolling shooter game developed in Visual Basic 6 (VB6) using DirectX 7/8 APIs, created by Luther Ananda Miller in 1998-1999. The game is inspired by classic arcade titles like Space Invaders and Galaxian, featuring multiple enemy types, power-ups, and progressive difficulty across three levels.

## Architecture

The game follows a classic object-oriented architecture built around a main game loop that runs at approximately 30-60 FPS. The architecture consists of:

1. **Core Engine** (`Game2.cls`): Main game controller managing timing, rendering pipeline, level progression, and performance monitoring
2. **Level Manager** (`Level.cls`): Orchestrates all game entities (player, enemies, projectiles, bonuses), handles collision detection via spatial partitioning, and maintains game state
3. **Actor System** (`Actor2.cls`): Sprite-based entity system where each game object is an Actor with position, graphics, collision data, and AI behavior
4. **AI System** (Brains hierarchy): Polymorphic AI behaviors where each enemy type has specialized behavior patterns (BrainsAlienA through BrainsAlienE, BrainsPlayer, etc.)
5. **Graphics System**: DirectDraw 2 based rendering with sprite animation sequences, double buffering, and palette management for 8-bit color mode
6. **Audio System**: DirectSound implementation with buffered sound effects supporting multiple simultaneous playback instances
7. **Input System**: DirectInput keyboard polling for responsive player control

## Technical Foundation

The game uses DirectX 7/8 components:
- **DirectDraw2** for 2D graphics rendering with page flipping
- **DirectSound** for audio playback with multiple sound buffers
- **DirectInput** for keyboard input handling
- Screen resolution: 640x480 pixels (8-bit color in fullscreen, windowed mode supported)
- Play area: 640x428 pixels (accounting for 32px top border and 20px bottom border)

## Key Features

- **Three Levels** with distinct enemy formations and difficulty scaling
- **Five Enemy Types** with unique AI behaviors:
  - Alien A: Formation flyers that drop bombs
  - Alien B: Non-aggressive decorative enemies
  - Alien C: Aggressive attackers that pursue player
  - Alien D: Orbital enemies with bomb drops
  - Alien E: Advanced enemies with periodic attacks and turning maneuvers
- **Player Mechanics**: Horizontal movement, rapid fire missiles, limited-use shields
- **Power-up System**: Cargo ships drop collectibles (double shots, rapid fire, multi-shots, bonus multipliers)
- **Scoring System**: Points for enemy kills, bonus multipliers (up to 10x), combo bonuses
- **Collision Detection**: Spatial partitioning using quadrant-based system for performance optimization
- **High Score Persistence**: Name entry and score saving to disk

## Game Loop Design

The game implements a time-based game loop pattern:
1. **Input Processing**: Poll DirectInput for keyboard state
2. **Update Phase**: Update all actor positions, run AI state machines, check timers
3. **Collision Phase**: Use PlayQuadrantManager to detect missile-enemy and player-enemy collisions
4. **State Management**: Process collision results, remove dead actors, trigger sound effects
5. **Render Phase**: Clear back buffer, draw stars/background, blit all sprites, draw UI, flip buffers
6. **Frame Timing**: Track elapsed milliseconds between frames for consistent movement speed

This architecture demonstrates solid 1990s game development practices with clear separation of concerns, efficient rendering, and scalable AI behaviors suitable for recreation on modern platforms.
