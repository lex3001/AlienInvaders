# Component Catalog - Complete File Reference

## Core Modules (.bas)

### Main.bas
**Entry Point & Initialization**
- Contains `Sub Main()` - application entry point
- Manages DirectX initialization sequence (DirectSound, DirectDraw, DirectInput)
- Defines screen constants: `SCREENWIDTH=640`, `SCREENHEIGHT=480`
- Implements main game loop calling `GameMenu_Start()` and `Game2.StartPlay()`
- Contains error handling system with DirectX error code translation
- Manages windowed/fullscreen mode via `#Const WINDOWED` compilation flag
- Handles application termination and DirectX cleanup

### DirectDraw.bas (modDirectDraw)
**DirectDraw Graphics Management**
- Initializes DirectDraw2 interface via `DirectDrawCreate()`
- Creates primary and back buffer surfaces for page flipping
- Manages cooperative level (DDSCL_NORMAL for windowed, DDSCL_EXCLUSIVE for fullscreen)
- Sets display mode (640x480x8 in fullscreen)
- Implements surface flipping for double buffering
- Handles palette attachment for 8-bit color mode
- Provides cleanup and surface restoration

### DirectSound.bas & DSModule.bas
**Audio System**
- **DirectSound.bas**: Legacy initialization (commented out in favor of DSModule)
- **DSModule.bas**: Active sound system
  - Initializes DirectSound with cooperative level
  - Creates sound buffers from WAV files
  - Manages multiple buffer instances for simultaneous sound playback
  - Handles buffer streaming and looping

### DirectInput.bas (modDirectInput)
**Keyboard Input Management**
- Initializes DirectInput interface
- Creates keyboard device via `IDirectInput.CreateDevice()`
- Sets cooperative level for keyboard access
- Acquires keyboard in non-exclusive mode
- Polls keyboard state via `GetDeviceStateKeyboard()`
- Releases keyboard on termination

### DirectXUtils.bas
**DirectX Utility Functions**
- Loads 8-bit palettes from .PAL files (`LoadPalette8BitPSP()`)
- Creates palette copies from surfaces
- Provides surface creation helpers
- Implements BMP loading utilities
- Color conversion functions

### GameUtils.bas (modGameUtils)
**Math & Utility Functions**
- Defines PI constant (3.14159265358979)
- `GetDirectionFromDeltas()`: Calculates angle from X/Y deltas (0-359 degrees)
- `GetDistance()`: Calculates Euclidean distance between two points
- `GetPointAtDirection()`: Calculates X/Y offset for given distance and direction
- `DebugPrint()`: Writes to debug log file
- Initialization/termination routines for logging system

### GameMenu.bas (modGameMenu)
**Menu System**
- Manages title screen and menu state
- Handles high score display
- Controls game start/quit logic
- Tracks menu selection state via global variables

### GUID.bas & modGUID.bas
**DirectX GUID Management**
- Defines GUIDs for DirectX components (DirectDraw, DirectSound, DirectInput)
- Provides GUID_Initialize() for setup
- Contains device enumeration GUIDs

### TypeDefs.bas
**Enumerations & Type Definitions**
```vb
Enum CargoType_Enum
    cargoNone, cargoDoubleShot, cargoRapidFire, cargoMultiShot, cargoSafetyPin
End Enum

Enum BonusFrame_Enum
    bonusBlank, bonus10, bonus20, bonus30, bonus50, bonus75, bonus100, bonus150, bonus200
End Enum

Enum MovementTypes_Enum
    movementNormal, movementMarch, movementFollowTheLeader, movementCircle, movementAttack, movementRadialPoints
End Enum

Enum BombDir_Enum
    bombLeft = 0, bombRight = 1
End Enum

Enum LoopingType_Enum
    loopOnce, loopContinuous
End Enum
```

### AlienDefinitions.bas
**Enemy Sprite Definitions**
- Defines sprite sheet frame coordinates for each alien type
- Specifies animation sequences (normal flight, explosions)
- Sets collision box dimensions for each enemy
- Contains frame definitions for bombs, missiles, bonuses

### LevelDefinitions.bas
**Level Configuration**
- `Levels123_LoadBitMapDefinitions()`: Loads all sprite definitions
- `Levels123_LoadSounds()`: Loads all sound effects with buffer counts
- `Level1_Initialize2()`: Level 1 setup (15 AlienA, 6 AlienB, 2 AlienC, 2 AlienD, 4 AlienE)
- `Level2_Initialize2()`: Level 2 setup (20 AlienA, 9 AlienB, 2 AlienC, 2 AlienD, 6 AlienE)
- `Level3_Initialize2()`: Level 3 setup (24 AlienA, 14 AlienB, 2 AlienC, 2 AlienD, 4 AlienE)
- Sets enemy formation positions using marching, circular, and radial movement patterns

### Level1.bas
**Level 1 Behavior Constants**
```vb
mlALIENA_BOMB_INTERVAL = 4000  ' Alien A bomb drop interval (ms)
mlALIENC_ATTACK_INTERVAL = 8000  ' Alien C attack check interval
mlALIEND_BOMB_INTERVAL = 5000  ' Alien D bomb drop interval
mlALIENE_ATTACK_INTERVAL = 15000  ' Alien E attack interval
mlALIENE1_BOMB_INTERVAL = 10000  ' Alien E idle bombing
mlALIENE2_BOMB_INTERVAL = 2000  ' Alien E aggressive bombing
miALIENC_ATTACK_RANGE = 48  ' Horizontal range for Alien C attacks
```

### FastArrayManager.bas
**Dynamic Array Helper**
- Provides efficient array element management
- Tracks used/unused indices in dynamic arrays
- Implements index allocation and release
- Supports iteration over active elements

## Game Engine Classes (.cls)

### Game2.cls (formerly Game.cls)
**Main Game Controller - 500+ lines**
- **Properties:**
  - Frame timing: `lTickCount`, `lLastTickCount`, `dAvgFramesPerSecond`
  - Performance monitoring arrays: `dPerfTicksUsed()`, `sPerfItem()`
  - Level reference: `oLevel As Level`
  - Display surfaces: `ddsDash`, `ddsBonuses` (UI bitmaps)
  - Border constants: `lTOP_BORDER=32`, `lBOTTOM_BORDER=20`
  - Stars array: `sStars(1 To 50)` with velocity and color
- **Key Methods:**
  - `StartPlay(level)`: Initializes level, enters game loop
  - `UpdateFrame()`: Main game loop iteration
  - `DrawPlayingField()`: Renders all game elements
  - `DrawDashboard()`: Renders score, lives, shields
  - `DrawStars()`: Animates scrolling star background
  - `UpdateShields()`: Manages shield indicator with blinking
  - Performance monitoring methods for profiling

### Level.cls
**Level Manager & Entity Container - 800+ lines**
- **Entity Arrays:**
  - `oPlayer As Actor2`: Player ship
  - `oAliens() As Actor2`: Enemy array
  - `oMissiles() As Actor2`: Player projectile array
  - `oABombs() As Actor2`: Alien A bombs
  - `oDBombs() As Actor2`: Alien D bombs
  - `oCargo() As Actor2`: Collectible items
- **Fast Array Managers:**
  - `oAliensFAM`, `oMissilesFAM`, `oABombsFAM`, `oDBombsFAM`, `oCargoFAM`
- **Collision System:**
  - `oPlayQuadrantManager As PlayQuadrantManager`
- **Game State:**
  - Score: `lScore`, Bonus: `lBonus`, Multiplier: `lBonusMultiplier`
  - Lives: `lNumShips`, Shield time: `lShieldsLeft`
  - Power-ups: `bHasDoubleShots`, `bHasRapidFire`, `bHasMultiShots`, `bHasSafetyPin`
  - Flags: `bIsGameOver`, `bIsPlayerDead`, `bIsLevelComplete`
- **Key Methods:**
  - `Initialize()`: Sets up play area dimensions
  - `InitializeActorArrays()`: Allocates entity arrays
  - `SetPlayer()`, `AddNewAlien()`, `AddNewABomb()`, etc.: Entity factories
  - `Update()`: Updates all actors, processes collisions
  - `Draw()`: Renders all actors in proper order
  - `CheckCollisions()`: Quadrant-based collision detection
  - `FirePlayerMissle()`: Creates player projectile
  - Sound management: `AddNewSoundEffect()`, `GetSoundEffect()`

### Actor2.cls
**Sprite Entity - 400+ lines**
- **Core Properties:**
  - Position: `fX As Single`, `fY As Single`
  - Graphics: `oBitMapDefinition As BitMapDefinition`
  - Animation: `oSequencePlayer As SequencePlayer`
  - AI: `oBrains As Brains` (polymorphic)
- **Movement System:**
  - `eMovementType As MovementTypes_Enum`
  - Normal movement: `lVelocity`, `lVelocityDirection`, `lAcceleration`
  - Marching: `lMarchingDistance`, `fDistanceMarched`
  - Follow-the-leader: `oLeader As Actor2`, relative offsets
  - Circular: `lCircleRadiusX/Y`, `lCircleCenterX/Y`, `lCirlceTicksPerRotation`
  - Radial points: `oRadialMovementPoints As RadialMovementPoints`
- **Collision Data:**
  - `lCanBeHitByMissiles As Long`: Health/vulnerability
  - `lWasHitByMissiles As Long`: Damage taken
  - `bCanHitPlayer As Boolean`: Is harmful to player
  - `bMustBeDestroyed As Boolean`: Required for level completion
- **Border Behavior:**
  - `bStopAtBorder[Top/Bottom/Left/Right]`
  - `bReverseAtBorder[Top/Bottom/Left/Right]`
- **Position Flags:**
  - `bIsOffScreen[Top/Bottom/Left/Right]`
  - `bIsAtBorder[Top/Bottom/Left/Right]`
- **State Flags:**
  - `bDelete`: Mark for removal
  - `bHitShields`, `bHitPlayer`: Collision results
- **Key Methods:**
  - `Initialize()`: Set graphics and AI
  - `SetMovement[Normal/Marching/RelativePosition/Circle/RadialPoints]()`
  - `Update()`: Apply movement, update position, run AI
  - `Draw()`: Blit sprite to back buffer
  - `DetectCollision()`: Check collision with another actor
  - `ResetState()`: Call AI reset

## AI Behavior Classes (Brains*.cls)

All Brains classes implement the `Brains` interface with these methods:
- `Brains_Initialize(roLevel, roActor)`: Set references, load sequences
- `Brains_ResetState()`: Initialize state machine
- `Brains_UpdateState()`: Per-frame AI logic
- `Brains_Terminate()`: Cleanup

### Brains.cls
**Base Class (Brain-dead)**
- Empty implementations
- Used for invisible formation leaders

### BrainsPlayer.cls
**Player Ship AI**
- **States:** Normal, Shields, Exploding
- **Input Handling:**
  - Left/Right arrow: Horizontal movement
  - Space: Stop movement
  - Shift: Fire missile
  - Alt: Activate shields
- **Missile System:**
  - Recharge time tracking
  - Rapid fire power-up halves recharge time
  - Sound effect on fire
- **Shield System:**
  - Drains `lShieldsLeft` over time
  - Visual state change
  - Blocks collisions
- **Death:**
  - Plays explosion animation
  - Sets `bIsPlayerDead` flag

### BrainsAlienA.cls
**Formation Alien (Weakest)**
- **States:** Normal, Exploding
- **Behavior:**
  - Follows formation leader via `movementFollowTheLeader`
  - Drops bombs at timed intervals (4000ms)
  - Checks if above player before bombing
  - Plays "WHOOSH" sound on death
- **Scoring:** 10 points

### BrainsAlienB.cls
**Decorative Alien (Non-combatant)**
- **States:** Normal, Exploding
- **Behavior:**
  - No attack behavior
  - Part of visual formation
  - Cannot hit player
  - `bMustBeDestroyed = False`
- **Scoring:** 20 points

### BrainsAlienC.cls
**Aggressive Attacker**
- **States:** Normal, Attacking, Exploding
- **Behavior:**
  - Checks player position every 8000ms
  - If within 48px horizontally, enters attack mode
  - Swoops down toward player
  - Returns to formation after attack
  - Cannot drop bombs
- **Scoring:** 30 points

### BrainsAlienD.cls
**Orbital Bomber**
- **States:** Normal, Exploding
- **Behavior:**
  - Follows circular/orbital movement pattern
  - Drops bombs at 5000ms intervals
  - Bombs aim left or right based on position
- **Scoring:** 50 points

### BrainsAlienE.cls
**Advanced Enemy (Strongest)**
- **States:** Normal, Attacking, Turning, Exploding
- **Behavior:**
  - Two variants: E1 (idle bomber), E2 (aggressive bomber)
  - E1: Drops bombs every 10000ms while circling
  - E2: Drops bombs every 2000ms (very aggressive)
  - Periodic attack mode: Swoops toward player
  - Can turn/rotate during maneuvers
- **Scoring:** 75 points

### BrainsMissile.cls
**Player Projectile**
- **Behavior:**
  - Moves straight up at high velocity
  - Deletes when off-screen (top)
  - No collision with player

### BrainsABomb.cls & BrainsDBomb.cls
**Enemy Projectiles**
- **Behavior:**
  - Move downward
  - ABomb: Straight down
  - DBomb: Can angle left/right based on `eBombDirection`
  - Delete when off-screen (bottom)
  - Harm player on contact

### BrainsCargoShip.cls
**Bonus Carrier (Rocket)**
- **Behavior:**
  - Flies horizontally across screen
  - When destroyed, drops cargo item
  - Cargo contains power-ups
- **Scoring:** 100 points

### BrainsCargo.cls
**Power-up Collectible**
- **Types:** (via CargoType_Enum)
  - cargoDoubleShot: Fire 2 missiles simultaneously
  - cargoRapidFire: Faster fire rate
  - cargoMultiShot: Fire 3 missiles in spread
  - cargoSafetyPin: Extra life
- **Behavior:**
  - Falls slowly downward
  - Collected by player contact
  - Applies power-up effect
  - Timeout deletion

### BrainsPlanet.cls
**Bonus Obstacle**
- **Behavior:**
  - Moves slowly across screen
  - Awards random bonus points when hit (50-200)
  - Shows temporary score popup
- **Scoring:** Variable (50, 75, 100, 150, 200 points)

### BrainsXBonus.cls
**Multiplier Power-up**
- **Behavior:**
  - Moves across screen
  - When collected, increases score multiplier
  - Multiplier ranges: 2x, 3x, 5x, 10x
  - Visual "X2", "X3", etc. display

### BrainsGeneric.cls
**Template Class**
- Unused in final game
- Can be copied for new enemy types

## Graphics & Animation Classes

### BitMapDefinition.cls
**Sprite Sheet Manager**
- **Properties:**
  - `sSurfaceName As String`: Identifier
  - `ddsSpriteSurface As IDirectDrawSurface2`: Loaded sprite sheet
  - `oFrameDefinitions()`: Array of frame metadata
  - `oFrameSequences()`: Array of animation sequences
- **Key Methods:**
  - `LoadFromFile()`: Loads BMP into DirectDraw surface
  - `DefineFrame()`: Adds frame with rect, offsets, collision boxes
  - `DefineFrameSequence()`: Creates animation sequence
  - `GetFrameDefinition()`, `GetFrameSequence()`: Accessors

### FrameDefinition.cls
**Single Frame Metadata**
- **Properties:**
  - `rectSource As RECT`: Source rect in sprite sheet
  - `lXSize`, `lYSize`: Frame dimensions
  - `lXOffset`, `lYOffset`: Draw offset for centering
  - `oCollisionBoxes()`: Array of collision boxes
- **Methods:**
  - `AddCollisionBox()`: Define collision region

### FrameSequence.cls
**Animation Sequence**
- **Properties:**
  - `sName As String`: Sequence identifier
  - `lFrameIndexes()`: Array of frame indices
  - `lTicksPerFrame As Long`: Animation speed
  - `eLoopingType As LoopingType_Enum`: Once or continuous
- **Methods:**
  - `AddFrameIndex()`: Append frame to sequence

### SequencePlayer.cls
**Animation Playback Controller**
- **Properties:**
  - `oFrameSequence As FrameSequence`: Current sequence
  - `lCurrentFrameIndex As Long`: Playback position
  - `lTicksSpentInFrame As Long`: Time tracking
  - `bIsFinishedPlaying As Boolean`: Completion flag
- **Methods:**
  - `PlayFrameSequence()`: Start new sequence
  - `Update()`: Advance animation based on elapsed time
  - `GetCurrentFrame()`: Returns FrameDefinition
  - `IsFinishedPlaying()`: Check completion

## Utility Classes

### CollisionBox.cls
**Bounding Box**
- **Properties:**
  - `sID As String`: Collision box identifier
  - `lXOffset`, `lYOffset`: Offset from sprite origin
  - `lXSize`, `lYSize`: Box dimensions
- Uses simple AABB (Axis-Aligned Bounding Box) collision

### PlayQuadrantManager.cls
**Spatial Partitioning for Collision Detection**
- **Purpose:** Optimize collision checks by dividing play area into grid
- **Properties:**
  - `mlQuadrantWidth`, `mlQuadrantHeight`: Grid cell size
  - `mlOverlapWidth`, `mlOverlapHeight`: Border overlap
  - `moObjects()`: 2D array of objects by quadrant
  - `mlNumObjects()`: Count per quadrant
- **Methods:**
  - `Initialize()`: Set up grid dimensions
  - `Clear()`: Reset all quadrants each frame
  - `AddObject()`: Place object in appropriate quadrant(s)
  - `StartIterator()`: Begin collision query at point
  - `GetNextObject()`: Iterate objects in same quadrant
  - `DeleteLastObject()`: Remove from quadrant
- **Algorithm:** Objects can span up to 4 quadrants if near boundaries

### RadialMovementPoints.cls
**Precomputed Circular Path**
- **Purpose:** Efficient circular/orbital movement without trig per frame
- **Properties:**
  - `lRadiusX`, `lRadiusY`: Ellipse radii
  - `lCenterX`, `lCenterY`: Orbit center
  - Array of precomputed X/Y positions for 360 degrees
- **Usage:** Alien D and E use for orbital patterns

### MovingPosition.cls
**Position Tracking**
- Tracks previous position for interpolation/trails

### PlayerInput.cls
**Input State Manager**
- **Properties:**
  - `bMoveLeftRequested`, `bMoveRightRequested`
  - `bStopMoveRequested`
  - `bMissleRequested`
  - `bShieldsRequested`
- **Method:**
  - `CheckInput()`: Polls DirectInput keyboard state

### HighScores.cls
**Score Persistence**
- **Properties:**
  - Array of high scores with names
- **Methods:**
  - `LoadFromFile()`: Read from disk
  - `SaveToFile()`: Write to disk
  - `AddScore()`: Insert new score
  - `IsHighScore()`: Check if score qualifies

### SoundEffect.cls
**Multi-buffer Sound**
- **Properties:**
  - `sSoundName As String`
  - `dsBuffers()`: Array of DirectSound buffers
  - `lNumBuffers`: Buffer count (allows overlapping sounds)
  - `lCurrentBuffer`: Round-robin index
- **Methods:**
  - `Initialize()`: Load WAV, create buffers
  - `Play()`: Play on next available buffer
  - `Stop()`: Stop all instances

## Form

### DDForm.frm
**DirectX Rendering Surface**
- Simple form with no controls
- Provides hWnd for DirectDraw
- Handles window mode rendering
- Can be hidden for fullscreen mode

## Summary Statistics

- **Total Files:** 60+ VB6 source files
- **Modules (.bas):** 16
- **Classes (.cls):** 42
- **Forms (.frm):** 1
- **Lines of Code:** ~8,000-10,000 estimated
- **Bitmaps:** 18 sprite sheets
- **Sound Effects:** 13 WAV files
- **Levels:** 3 configured levels
