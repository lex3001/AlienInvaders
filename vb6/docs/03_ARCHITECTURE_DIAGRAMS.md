# Architecture Diagrams

## System Architecture Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                         MAIN.BAS (Entry Point)                   │
│  • Sub Main() - Game Loop                                        │
│  • DirectX Initialization                                        │
│  • Error Handling                                                │
└────────────────────┬────────────────────────────────────────────┘
                     │
        ┌────────────┼────────────┐
        │            │            │
        ▼            ▼            ▼
┌──────────────┐ ┌────────────┐ ┌─────────────┐
│  GameMenu    │ │   Game2    │ │  DirectX    │
│  .bas        │ │   .cls     │ │  Modules    │
└──────────────┘ └─────┬──────┘ └─────┬───────┘
                       │              │
                       │       ┌──────┴───────────┐
                       │       │                  │
                       ▼       ▼                  ▼
                  ┌────────────┐          ┌─────────────┐
                  │  Level.cls │          │ DirectDraw  │
                  │            │          │ DirectSound │
                  │  • Actors  │          │ DirectInput │
                  │  • Collision│         └─────────────┘
                  └─────┬──────┘
                        │
        ┌───────────────┼───────────────┐
        │               │               │
        ▼               ▼               ▼
  ┌──────────┐    ┌──────────┐    ┌──────────┐
  │ Actor2   │    │ Actor2   │    │ Actor2   │
  │ (Player) │    │ (Aliens) │    │(Missiles)│
  └────┬─────┘    └────┬─────┘    └────┬─────┘
       │               │               │
       ▼               ▼               ▼
  ┌──────────┐    ┌──────────┐    ┌──────────┐
  │ Brains   │    │ Brains   │    │ Brains   │
  │ Player   │    │ Alien[A-E]│   │ Missile  │
  └──────────┘    └──────────┘    └──────────┘
```

## Class Hierarchy - Actor System

```
┌─────────────────────────────────────────────────────────────┐
│                        Actor2 Class                          │
├─────────────────────────────────────────────────────────────┤
│ Properties:                                                  │
│  • fX, fY: Single (position)                                │
│  • oBitMapDefinition: BitMapDefinition                      │
│  • oSequencePlayer: SequencePlayer                          │
│  • oBrains: Brains (polymorphic AI)                         │
│  • eMovementType: MovementTypes_Enum                        │
│  • lVelocity, lVelocityDirection: Long                      │
│  • lCanBeHitByMissiles, lWasHitByMissiles: Long            │
│  • bDelete, bCanHitPlayer, bMustBeDestroyed: Boolean        │
├─────────────────────────────────────────────────────────────┤
│ Methods:                                                     │
│  • Initialize(BitMapDef, Brains)                            │
│  • SetMovement[Normal/Marching/Circle/...]()               │
│  • Update(Level, bMove, bState)                             │
│  • Draw(Level)                                              │
│  • DetectCollision(OtherActor): Boolean                     │
│  • ResetState()                                             │
└───────┬─────────────────────────────────────────────────────┘
        │
        │ Contains
        ▼
┌────────────────────────┐
│  BitMapDefinition      │
│  ┌──────────────────┐  │
│  │ Sprite Surface   │  │
│  │ Frame Defs []    │  │
│  │ Sequences []     │  │
│  └──────────────────┘  │
└────────────────────────┘
        │
        │ Uses
        ▼
┌─────────────────────────────────────────┐
│        SequencePlayer                    │
│  • Current sequence                      │
│  • Current frame index                   │
│  • Time in frame                         │
│  • PlayFrameSequence(seq)               │
│  • Update(ticks)                         │
│  • GetCurrentFrame(): FrameDefinition    │
└─────────────────────────────────────────┘
```

## Brains Class Hierarchy

```
                    ┌──────────────────┐
                    │   Brains.cls     │
                    │   (Interface)    │
                    ├──────────────────┤
                    │ • Initialize()   │
                    │ • ResetState()   │
                    │ • UpdateState()  │
                    │ • Terminate()    │
                    └────────┬─────────┘
                             │
        ┌────────────────────┼─────────────────────┐
        │                    │                     │
        ▼                    ▼                     ▼
┌──────────────┐    ┌──────────────┐     ┌──────────────┐
│BrainsPlayer  │    │BrainsAlienA  │     │BrainsMissile │
│              │    │              │     │              │
│States:       │    │States:       │     │Behavior:     │
│• Normal      │    │• Normal      │     │• Move up     │
│• Shields     │    │• Exploding   │     │• Delete when │
│• Exploding   │    │              │     │  offscreen   │
│              │    │Behavior:     │     └──────────────┘
│Input:        │    │• Follow      │
│• Arrows      │    │  leader      │     ┌──────────────┐
│• Fire        │    │• Drop bombs  │     │BrainsAlienB  │
│• Shields     │    │  (4000ms)    │     │(Decorative)  │
└──────────────┘    └──────────────┘     └──────────────┘
                                                  
┌──────────────┐    ┌──────────────┐     ┌──────────────┐
│BrainsAlienC  │    │BrainsAlienD  │     │BrainsAlienE  │
│              │    │              │     │              │
│States:       │    │States:       │     │States:       │
│• Normal      │    │• Normal      │     │• Normal      │
│• Attacking   │    │• Exploding   │     │• Attacking   │
│• Exploding   │    │              │     │• Turning     │
│              │    │Behavior:     │     │• Exploding   │
│Behavior:     │    │• Orbit       │     │              │
│• Check range │    │• Bomb        │     │Behavior:     │
│  (48px)      │    │  (5000ms)    │     │• Attack      │
│• Attack if   │    └──────────────┘     │  (15000ms)   │
│  near player │                         │• Bomb E1     │
│  (8000ms)    │    ┌──────────────┐     │  (10000ms)   │
└──────────────┘    │BrainsABomb   │     │• Bomb E2     │
                    │BrainsDBomb   │     │  (2000ms)    │
┌──────────────┐    │              │     └──────────────┘
│BrainsCargo   │    │Behavior:     │
│              │    │• Fall down   │     ┌──────────────┐
│Behavior:     │    │• Harm player │     │BrainsCargoShip│
│• Fall slowly │    └──────────────┘     │BrainsPlanet  │
│• Apply       │                         │BrainsXBonus  │
│  powerup on  │    ┌──────────────┐     │(Special)     │
│  collection  │    │BrainsGeneric │     └──────────────┘
└──────────────┘    │(Template)    │
                    └──────────────┘
```

## DirectX Component Architecture

```
┌────────────────────────────────────────────────────────────────┐
│                    DirectX Initialization                      │
│                    (Main.bas: DirectX_Initialize)              │
└───────┬───────────────────────┬────────────────────┬───────────┘
        │                       │                    │
        ▼                       ▼                    ▼
┌──────────────────┐   ┌──────────────────┐  ┌─────────────────┐
│  DirectSound     │   │  DirectDraw      │  │  DirectInput    │
│  (DSModule.bas)  │   │  (DirectDraw.bas)│  │ (DirectInput.bas)│
├──────────────────┤   ├──────────────────┤  ├─────────────────┤
│ • Initialize     │   │ • Initialize     │  │ • Initialize    │
│   DirectSound    │   │   DirectDraw2    │  │   DirectInput   │
│                  │   │                  │  │                 │
│ • Create Sound   │   │ • Create Surfaces│  │ • Create        │
│   Buffers from   │   │   - Primary      │  │   Keyboard      │
│   WAV files      │   │   - Back (x2)    │  │   Device        │
│                  │   │                  │  │                 │
│ • Play() with    │   │ • SetDisplayMode │  │ • Poll State    │
│   multiple       │   │   (640x480x8)    │  │   (256 keys)    │
│   simultaneous   │   │                  │  │                 │
│   instances      │   │ • Flip/Blit      │  │ • Map to        │
│                  │   │   operations     │  │   PlayerInput   │
│                  │   │                  │  │                 │
│ • Volume control │   │ • Load Palette   │  │ • Acquire/      │
│                  │   │   (8-bit mode)   │  │   Unacquire     │
└──────────────────┘   └──────────────────┘  └─────────────────┘
```

## Collision Detection System

```
┌──────────────────────────────────────────────────────────────┐
│                    Level.Update()                             │
│                    Collision Detection Phase                  │
└────────────┬─────────────────────────────────────────────────┘
             │
             ▼
┌────────────────────────────────────────────────────────────────┐
│              PlayQuadrantManager.Clear()                        │
│              Reset all quadrants for new frame                  │
└────────────┬───────────────────────────────────────────────────┘
             │
             ▼
┌────────────────────────────────────────────────────────────────┐
│         For each Missile:                                       │
│           • Update position                                     │
│           • Add to PlayQuadrantManager at (fX, fY)             │
└────────────┬───────────────────────────────────────────────────┘
             │
             ▼
┌────────────────────────────────────────────────────────────────┐
│         For each Alien:                                         │
│           • Update position                                     │
│           • If can be hit by missiles:                          │
│             - StartIterator at alien's (fX, fY)                │
│             - For each missile in same quadrant(s):            │
│               • DetectCollision(missile)                        │
│               • If hit: lWasHitByMissiles++                    │
│               • Delete missile from quadrant                    │
└────────────┬───────────────────────────────────────────────────┘
             │
             ▼
┌────────────────────────────────────────────────────────────────┐
│    PlayQuadrantManager Spatial Grid (640x480 play area)        │
│                                                                 │
│    ┌─────────┬─────────┬─────────┬─────────┬─────────┐       │
│    │ Q1      │ Q2      │ Q3      │ Q4      │ Q5      │       │
│    │         │         │         │         │         │       │
│    ├─────────┼─────────┼─────────┼─────────┼─────────┤       │
│    │ Q6      │ Q7  M   │ Q8      │ Q9      │ Q10     │       │
│    │         │    ↑    │         │         │         │       │
│    ├─────────┼────★────┼─────────┼─────────┼─────────┤       │
│    │ Q11     │ Q12 A   │ Q13     │ Q14     │ Q15     │       │
│    │         │         │         │         │         │       │
│    └─────────┴─────────┴─────────┴─────────┴─────────┘       │
│                                                                 │
│    M = Missile (added to Q7)                                   │
│    A = Alien (queries Q12 for missiles, finds M in Q7)        │
│    With overlap, objects can be in multiple adjacent quadrants │
└────────────────────────────────────────────────────────────────┘

Algorithm:
1. Each frame, clear all quadrants
2. Add all missiles to their respective quadrant(s)
3. For each alien, query its quadrant(s) for missiles
4. Only test collision against missiles in same quadrant(s)
5. O(n*m/k) instead of O(n*m) where k = number of quadrants

Collision Box Detection:
┌──────────────────────────────────────────────────────────────┐
│  Actor2.DetectCollision(OtherActor)                           │
│                                                                │
│  For each CollisionBox in this actor:                         │
│    box1Left = fX + box.lXOffset                              │
│    box1Right = box1Left + box.lXSize                         │
│    box1Top = fY + box.lYOffset                               │
│    box1Bottom = box1Top + box.lYSize                         │
│                                                                │
│    For each CollisionBox in other actor:                      │
│      box2Left = other.fX + otherBox.lXOffset                │
│      box2Right = box2Left + otherBox.lXSize                 │
│      box2Top = other.fY + otherBox.lYOffset                 │
│      box2Bottom = box2Top + otherBox.lYSize                 │
│                                                                │
│      If AABB overlap:                                         │
│        (box1Right >= box2Left AND                            │
│         box1Left <= box2Right AND                            │
│         box1Bottom >= box2Top AND                            │
│         box1Top <= box2Bottom)                               │
│        Return True                                            │
│                                                                │
│  Return False                                                  │
└────────────────────────────────────────────────────────────────┘
```

## Game Loop Flow

```
┌─────────────────────────────────────────────────────────────────┐
│                     Main.Main() Loop                             │
└───────┬─────────────────────────────────────────────────────────┘
        │
        ▼
┌────────────────────────────────────────────────────────────────┐
│  GameMenu_Init()                                                │
│  GameMenu_Start()                                               │
│  • Display title screen                                         │
│  • Show high scores                                             │
│  • Wait for player input                                        │
└────────┬───────────────────────────────────────────────────────┘
         │
         │ isTimeToPlay() = True
         ▼
┌────────────────────────────────────────────────────────────────┐
│  Game2.StartPlay(level)                                         │
│  • Level.Initialize()                                           │
│  • Load level definition (Level1/2/3_Initialize2)             │
│  • Create all actors                                            │
│  • Enter game loop                                              │
└────────┬───────────────────────────────────────────────────────┘
         │
         ▼
┌────────────────────────────────────────────────────────────────┐
│            Game Loop (UpdateFrame)                              │
│                                                                 │
│  ┌──────────────────────────────────────────────────────────┐ │
│  │ 1. TIMING                                                 │ │
│  │    lCurrentTick = timeGetTime()                          │ │
│  │    lTicksPassed = lCurrentTick - lLastTick               │ │
│  │    Level.lTicksPassed = lTicksPassed                     │ │
│  └──────────────────────────────────────────────────────────┘ │
│                            │                                    │
│  ┌──────────────────────────▼──────────────────────────────┐ │
│  │ 2. INPUT                                                  │ │
│  │    PlayerInput.CheckInput()                              │ │
│  │    • Poll DirectInput keyboard state                     │ │
│  │    • Set movement/fire/shield flags                      │ │
│  └──────────────────────────────────────────────────────────┘ │
│                            │                                    │
│  ┌──────────────────────────▼──────────────────────────────┐ │
│  │ 3. UPDATE                                                 │ │
│  │    Level.Update()                                         │ │
│  │    • Update player (movement, AI state)                  │ │
│  │    • Update all missiles (movement)                      │ │
│  │    • Update all aliens (movement, AI state)              │ │
│  │    • Update all bombs (movement)                         │ │
│  │    • Update all cargo (movement)                         │ │
│  └──────────────────────────────────────────────────────────┘ │
│                            │                                    │
│  ┌──────────────────────────▼──────────────────────────────┐ │
│  │ 4. COLLISION DETECTION                                    │ │
│  │    Level.CheckCollisions()                                │ │
│  │    • PlayQuadrantManager spatial partitioning            │ │
│  │    • Missile vs Alien                                    │ │
│  │    • Bomb vs Player/Shields                              │ │
│  │    • Cargo vs Player                                     │ │
│  └──────────────────────────────────────────────────────────┘ │
│                            │                                    │
│  ┌──────────────────────────▼──────────────────────────────┐ │
│  │ 5. STATE UPDATES                                          │ │
│  │    For each actor with state changes:                    │ │
│  │    • oBrains.UpdateState()                               │ │
│  │    • Process hits, explosions, deaths                    │ │
│  │    • Remove actors marked for deletion                   │ │
│  │    • Trigger sound effects                               │ │
│  └──────────────────────────────────────────────────────────┘ │
│                            │                                    │
│  ┌──────────────────────────▼──────────────────────────────┐ │
│  │ 6. RENDER                                                 │ │
│  │    DrawPlayingField()                                     │ │
│  │    • Clear back buffer (black)                           │ │
│  │    • Draw stars (scrolling background)                   │ │
│  │    • Draw borders (top/bottom lines)                     │ │
│  │    • Level.Draw() - all actors                           │ │
│  │    • Draw dashboard (score, lives, shields)              │ │
│  │    • Draw bonus popups                                   │ │
│  │    • DoFlip() - swap front/back buffers                  │ │
│  └──────────────────────────────────────────────────────────┘ │
│                            │                                    │
│  ┌──────────────────────────▼──────────────────────────────┐ │
│  │ 7. LEVEL COMPLETION CHECK                                 │ │
│  │    If all must-destroy aliens dead:                      │ │
│  │      bIsLevelComplete = True                             │ │
│  │      Exit game loop                                      │ │
│  │    If player dead and no lives left:                     │ │
│  │      bIsGameOver = True                                  │ │
│  │      Exit game loop                                      │ │
│  └──────────────────────────────────────────────────────────┘ │
│                            │                                    │
│                            └─────┐Loop back                     │
└─────────────────────────────────┼─────────────────────────────┘
                                  │
                      Exit when level complete or game over
                                  │
                                  ▼
┌────────────────────────────────────────────────────────────────┐
│  Check for next level or game over screen                      │
│  Return to main menu                                            │
└────────────────────────────────────────────────────────────────┘
```

## Movement System Architecture

```
Actor2 Movement Types (eMovementType):

┌─────────────────────────────────────────────────────────────┐
│  movementNormal                                              │
│  • lVelocity, lVelocityDirection (0-359 degrees)           │
│  • lAcceleration, lAccelerationDirection                    │
│  • Updates: fX, fY based on velocity vector each frame      │
│  • Used by: Simple straight-line movement                   │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│  movementMarch                                               │
│  • Initial position, velocity, direction                     │
│  • lMarchingDistance: Total distance to march               │
│  • fDistanceMarched: Tracking progress                      │
│  • Reverses direction when distance reached                 │
│  • Used by: Level 1 formation leader (back and forth)       │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│  movementFollowTheLeader                                     │
│  • oLeader: Reference to leader Actor2                       │
│  • fXRelPos, fYRelPos: Offset from leader                   │
│  • Each frame: fX = leader.fX + offset                      │
│  • Used by: Formation aliens following formation leader     │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│  movementCircle (Legacy - replaced by RadialPoints)          │
│  • lCircleCenterX/Y: Orbit center                           │
│  • lCircleRadiusX/Y: Ellipse radii                          │
│  • lCirlceTicksPerRotation: Speed                           │
│  • fCirclePosition: Current angle (0-359.99)               │
│  • Calculates: fX = centerX + cos(angle)*radiusX           │
│  •            fY = centerY + sin(angle)*radiusY            │
│  • Used by: Circular enemy patterns (commented out)         │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│  movementRadialPoints (Optimized Circle)                     │
│  • oRadialMovementPoints: Precomputed 360 positions        │
│  • Avoids per-frame trigonometry                            │
│  • Index into array instead of calculating sin/cos          │
│  • Used by: Alien D, Alien E circular/orbital movement      │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│  movementAttack                                              │
│  • Target-seeking behavior                                   │
│  • Controlled by AI (BrainsAlienC, BrainsAlienE)           │
│  • Swoops toward player position                            │
│  • Returns to formation after attack                        │
└─────────────────────────────────────────────────────────────┘
```

## Data Flow - From Input to Render

```
Frame N Start
     │
     ▼
[Keyboard Hardware]
     │
     ▼
[DirectInput.GetDeviceStateKeyboard()]
     │ (256-byte keyboard state array)
     ▼
[PlayerInput.CheckInput()]
     │ Maps keys to flags:
     │ • DIK_LEFT → bMoveLeftRequested
     │ • DIK_RIGHT → bMoveRightRequested
     │ • DIK_SPACE → bStopMoveRequested
     │ • DIK_LSHIFT → bMissleRequested
     │ • DIK_LALT → bShieldsRequested
     ▼
[BrainsPlayer.UpdateState()]
     │ Reads PlayerInput flags
     │ Updates Actor2 properties:
     │ • lVelocity, lVelocityDirection
     │ • Calls Level.FirePlayerMissle()
     │ • Manages shield state
     ▼
[Actor2.Update(Move=True)]
     │ Applies movement:
     │ • Calculate deltaX, deltaY from velocity
     │ • fX += deltaX * (ticksPassed / 1000)
     │ • fY += deltaY * (ticksPassed / 1000)
     │ • Check borders, apply restrictions
     ▼
[Level.CheckCollisions()]
     │ Spatial partitioning collision detection
     │ Updates Actor2 flags:
     │ • lWasHitByMissiles++
     │ • bHitPlayer, bHitShields
     ▼
[Actor2.oBrains.UpdateState()]
     │ Process collision results:
     │ • If hit: Change to exploding state
     │ • Update score
     │ • Play sound effect
     │ • Set bDelete if explosion finished
     ▼
[Actor2.Draw()]
     │ Get current frame from SequencePlayer
     │ Calculate dest rect from fX, fY, offsets
     │ BltFast(source rect, dest rect) to back buffer
     ▼
[DoFlip()]
     │ DirectDraw.Flip() or BitBlt (windowed)
     │ Swap front/back buffers
     ▼
Frame N End → Frame N+1 Start
```
