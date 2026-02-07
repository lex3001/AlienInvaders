# Game Loop - Detailed Technical Documentation

## Overview
The Alien Invaders game loop follows a classic fixed-timestep game loop pattern with real-time variations. The main loop resides in `GamePlay.bas` and orchestrates timing, input, update, and rendering phases.

## Loop Architecture

### Main Loop Structure
```vb
' From GamePlay.bas - GamePlay_Start
Do
    ' PHASE 1: Input Processing
    Call CheckInput()
    
    ' PHASE 2: Timing Update
    Call GamePlay_Update_Clock()
    
    ' PHASE 3: Game State Update
    Call Level1_Update()
    
    ' PHASE 4: Rendering
    Call Level1_Draw()
    
    ' PHASE 5: Frame Presentation
    Call DirectDraw_PresentBackBuffer()
    
    DoEvents  ' Allow Windows messages
Loop While Not (mbQuit Or mgGame.bIsLevelComplete Or mgGame.bIsGameOver Or mgGame.bIsPlayerDead)
```

## Timing System

### Key Timing Constants
```vb
' From GamePlay.bas
.lTicksPerLoop = 40        ' Target 40ms per frame = 25 FPS
.lMaxTicksPerLoop = 60     ' Maximum time delta allowed (prevents spiral of death)
.bRealTime = True          ' Enable real-time mode vs fixed timestep
```

### Clock Management
```vb
' Initialization - GamePlay_Init_Clock()
mlTicksPassed = 0
mdFrames = 0
mlTickCount = Win32.GetTickCount()        ' Current time in milliseconds
mlFirstTickCount = mlTickCount
mlLastTickCount = mlTickCount

' Per-Frame Update - GamePlay_Update_Clock()
Do
    DoEvents
    mlTickCount = Win32.GetTickCount()
    mlTicksPassed = mlTickCount - mlLastTickCount
    If .bRealTime Then Exit Do
Loop While (mlTicksPassed < .lTicksPerLoop)  ' Wait until 40ms elapsed

' Apply timing with cap
If .bRealTime Then
    If .lTicksPassed <= .lMaxTicksPerLoop Then
        .lTicksPassed = mlTicksPassed         ' Use actual time
    Else
        .lTicksPassed = .lMaxTicksPerLoop     ' Cap at 60ms maximum
    End If
Else
    .lTicksPassed = .lTicksPerLoop            ' Fixed 40ms timestep
End If

' Calculate FPS
mdAvgFramesPerSecond = mdFrames * 1000 / (mlTickCount - mlFirstTickCount)
```

### Timing Modes

#### Real-Time Mode (bRealTime = True)
- Uses actual elapsed time between frames
- Capped at `lMaxTicksPerLoop` (60ms) to prevent large jumps
- Results in smoother gameplay but variable frame rates
- Formula: `deltaTime = min(actualElapsed, 60ms)`

#### Fixed-Timestep Mode (bRealTime = False)
- Uses constant 40ms per frame regardless of actual time
- Waits until 40ms has elapsed before continuing
- More deterministic but can lag on slow systems
- Formula: `deltaTime = 40ms (always)`

## Phase 1: Input Processing

### Input Polling
```vb
' From Level.cls - CheckInput()
Call oPlayerInput.GetInputState()

' From PlayerInput.cls
DirectInput_GetKeyboardState()  ' Poll DirectInput keyboard
mybufKeyboardState(0 To 255)   ' Stores key states

' Process keys
bMoveLeftRequested = (mybufKeyboardState(DIK_LEFT) And &H80)
bMoveRightRequested = (mybufKeyboardState(DIK_RIGHT) And &H80)
bMissleRequested = (mybufKeyboardState(DIK_SPACE) And &H80)
bShieldsRequested = (mybufKeyboardState(DIK_LSHIFT) And &H80)
```

### Input Actions
- **Left Arrow**: Request left movement
- **Right Arrow**: Request right movement  
- **Space**: Request missile fire
- **Left Shift**: Request shield activation
- **ESC**: Quit game

## Phase 2: Game State Update

### Update Hierarchy
```vb
' Level.cls - Update()
1. CheckInput()                          ' Get player input
2. oPlayer.Update(Me, vbMove:=True)     ' Update player position/state

3. FOR EACH Missile:
     oMissiles(i).Update(Me, vbMove:=True)

4. FOR EACH Alien:
     .Update(Me, vbMove:=True, vbState:=False)   ' Move alien
     
     ' Collision Detection: Alien vs Missiles
     FOR EACH Missile:
         If .DetectCollision(oMissiles(j)) Then
             .bWasHitByMissle = True
             Release Missile
         End If
     End FOR
     
     ' Collision Detection: Alien vs Player
     If .DetectCollision(oPlayer) Then
         If bShieldsOn Then
             .bHitShields = True
         Else
             .bHitPlayer = True
             oPlayer.bWasHitByMissle = True
         End If
     End If
     
     .Update(Me, vbAnimate:=False)    ' Update animation/state
     
     If .bDelete Then
         If .bMustBeDestroyed Then
             iNumAliensMustBeDestroyed--
         Release Alien
     End If
   END FOR

5. FOR EACH ABomb:
     .Update(Me, vbMove:=True, vbState:=False)
     
     ' Collision Detection: Bomb vs Player
     If .DetectCollision(oPlayer) Then
         If Not bShieldsOn Then
             oPlayer.bWasHitByMissle = True
         Release Bomb
     End If
     
     .Update(Me, vbAnimate:=False)
     If .bDelete Then Release Bomb
   END FOR

6. FOR EACH DBomb:
     ' Similar to ABomb update
   END FOR
```

### Movement Calculation
```vb
' GameUtils.bas - CalculateNewVelocity()
' Physics: velocity += acceleration * deltaTime

' Get component velocities
ldVelX = Cos(radians(rlVelDirection)) * rlVelocity
ldVelY = Sin(radians(rlVelDirection)) * rlVelocity

' Get component accelerations
ldAccelX = Cos(radians(viAccDirection)) * viAcceleration
ldAccelY = Sin(radians(viAccDirection)) * viAcceleration

' Apply acceleration over time
ldNewVelX = ldVelX + (ldAccelX * vlTicksPassed / 1000.0)
ldNewVelY = ldVelY + (ldAccelY * vlTicksPassed / 1000.0)

' Calculate new velocity magnitude and direction
rlVelocity = sqrt(ldNewVelX^2 + ldNewVelY^2)
rlVelDirection = atan2(ldNewVelY, ldNewVelX) * (180 / PI)

' Position update
ldPixels = (Velocity * TicksPassed) / 1000.0
fX += Cos(radians(Direction)) * ldPixels
fY += Sin(radians(Direction)) * ldPixels
```

### Velocity Units
- Velocity is in **pixels per second**
- Acceleration is in **pixels per second per second**
- Time delta (`lTicksPassed`) is in **milliseconds**
- Division by 1000 converts milliseconds to seconds

## Phase 3: Animation Updates

### Frame Sequencing
```vb
' Actor.bas - UpdateAnimation()
.lTicksSinceLastFrame += rgGame.lTicksPassed

If .lTicksSinceLastFrame >= CurrentSequence.lTicksPerFrame Then
    .lTicksSinceLastFrame -= CurrentSequence.lTicksPerFrame
    
    ' Advance to next frame based on looping type
    Select Case .eLoopingType
        Case loopingOneWay:
            .lCurrentFrame++
            If .lCurrentFrame > .lLastFrame Then
                .lCurrentFrame = .lFirstFrame  ' Loop
            End If
        
        Case loopingNone:
            If .lCurrentFrame < .lLastFrame Then
                .lCurrentFrame++
            Else
                bFinishedPlaying = True
            End If
        
        Case loopingTwoWay:
            ' Ping-pong animation
            ' ... (alternates forward/reverse)
    End Select
End If
```

### Animation Timing
- Each sequence defines `lTicksPerFrame` (milliseconds per frame)
- Accumulates time until enough has passed to advance frame
- Examples:
  - Alien A normal: 50ms per frame = 20 FPS animation
  - Alien B: 80ms per frame = 12.5 FPS animation
  - Alien C: 125ms per frame = 8 FPS animation

## Phase 4: Rendering

### Draw Order (Back-to-Front)
```vb
' Level.cls - Draw()
1. Clear back buffer to black
2. Draw stars (parallax background)
3. Draw missiles
4. Draw ABombs (alien bombs - straight)
5. Draw DBombs (alien bombs - directed)
6. Draw aliens
7. Draw player
8. Draw HUD/dashboard
9. Draw bonuses (score popups)
```

### Sprite Blitting
```vb
' Actor.cls - Draw()
' Get frame definition for current animation frame
Set loFrameDefinition = .oBitMapDefinition.GetFrameDefinition(.oSequencePlayer.CurrentBitMapFrame)

' Calculate source rectangle (sprite sheet position)
With lrSource
    .Left = loFrameDefinition.lXOffset
    .Top = loFrameDefinition.lYOffset
    .Right = .Left + loFrameDefinition.lXSize
    .Bottom = .Top + loFrameDefinition.lYSize
End With

' Calculate destination rectangle (screen position)
With lrDest
    .Left = CInt(.fX) + roLevel.iPlayXOffset
    .Top = CInt(.fY) + roLevel.iPlayYOffset
    .Right = .Left + loFrameDefinition.lXSize
    .Bottom = .Top + loFrameDefinition.lYSize
End With

' Blit sprite with transparency
roLevel.ddsBackBufferSurface.Blt lrDest, SpriteSheet, lrSource, DDBLT_KEYSRCOVERRIDE, mddfxNormalBlt
```

### Transparency
- Uses color key transparency (DDBLT_KEYSRCOVERRIDE)
- Typically color index 0 (first palette entry) is transparent
- DirectDraw automatically skips pixels matching the color key

## Phase 5: Frame Presentation

### Page Flipping
```vb
' DirectDraw.bas
Public Sub DirectDraw_PresentBackBuffer()
    If bWindowedMode Then
        ' Windowed: Blt from back to front
        Dim lrDest As RECT
        frmDDForm.GetWindowRect lrDest
        gDDSFront.Blt lrDest, gDDSBack, mrBackBufferRect, DDBLT_WAIT, mddfxNormalBlt
    Else
        ' Fullscreen: Hardware page flip
        gDDSFront.Flip Nothing, DDFLIP_WAIT
    End If
End Sub
```

### Vsync Behavior
- `DDFLIP_WAIT` flag waits for vertical blank before flipping
- Prevents screen tearing in fullscreen mode
- Windowed mode uses software blit (no vsync)

## Special Update Logic

### Shield Drain
```vb
' BrainsPlayer.cls - UpdateState()
If eState = stateShields Then
    oLevel.lShieldsLeft = oLevel.lShieldsLeft - oLevel.lTicksPassed
    
    If (Not .bShieldsRequested) Or (oLevel.lShieldsLeft <= 0) Then
        ' Deactivate shields
        eState = stateNormal
        oLevel.bShieldsOn = False
    End If
End If
```
- Shields drain at 1:1 ratio with time (1 tick = 1 shield unit)
- Maximum shields: `glMAX_SHIELDS_TICKS = 50000` (50 seconds at 25 FPS)

### Missile Recharge
```vb
' BrainsPlayer.cls
lTicksSinceLastMissle += oLevel.lTicksPassed

If oLevel.bHasRapidFire Then
    llMissileRechargeTicksNeeded = lMissileRechargeTicks / 2
Else
    llMissileRechargeTicksNeeded = lMissileRechargeTicks
End If

If .bMissleRequested And (lTicksSinceLastMissle >= llMissileRechargeTicksNeeded) Then
    If oLevel.FirePlayerMissle() Then
        lTicksSinceLastMissle = 0
    End If
End If
```
- Base recharge: `lMissileRechargeTicks` (typically set per level)
- Rapid fire power-up: halves recharge time

### Bonus Score Decay
```vb
' GamePlay_Update_Clock()
.lBonusTicks = .lBonusTicks + .lTicksPassed
If .lBonusTicks > 500 Then
    .lBonusTicks = 0
    .lBonus = .lBonus - 10
End If
```
- Bonus decreases by 10 points every 500ms
- Starts at 2500 at level start
- Awarded when level completed

## Performance Characteristics

### Frame Budget
- Target: 40ms per frame (25 FPS)
- Rendering time varies by number of active objects
- Typical object counts:
  - Aliens: 15-35 active
  - Missiles: up to 10
  - Bombs: up to 22 (20 A-bombs + 2 D-bombs)

### VB6 Performance Considerations
- DirectDraw blits are relatively fast (hardware accelerated)
- Main bottleneck: VB6's interpreted nature and COM overhead
- Object iteration uses FastArrayManager for efficient sparse arrays
- DoEvents allows Windows message processing but adds overhead

## Pseudocode Summary

```
INITIALIZE:
    Create DirectDraw surfaces (primary, back buffer, sprites)
    Load all bitmaps and sounds
    Set up game state (score=0, ships=3, shields=25000 ticks)
    Initialize clock (GetTickCount)

MAIN_LOOP:
    WHILE NOT (quit OR level_complete OR game_over):
        // TIMING
        current_time = GetTickCount()
        delta_time = current_time - last_time
        
        IF real_time_mode:
            WAIT until delta_time >= 40ms
            delta_time = min(delta_time, 60ms)  // Cap
        ELSE:
            delta_time = 40ms  // Fixed
        END IF
        
        last_time = current_time
        
        // INPUT
        Poll DirectInput keyboard
        Store key states (arrows, space, shift, ESC)
        
        // UPDATE
        Update player position based on input
        Update player state (normal/shields/exploding)
        
        FOR EACH missile:
            Update position
            Check if off-screen, mark for deletion
        END FOR
        
        FOR EACH alien:
            Update position
            Update AI state machine
            Check collision with missiles
            Check collision with player
            Update animation frame
            Drop bombs based on AI
            Mark for deletion if destroyed
        END FOR
        
        FOR EACH bomb:
            Update position
            Check collision with player
            Mark for deletion if hit or off-screen
        END FOR
        
        Update shields (drain if active)
        Update bonus score (decay over time)
        Update score popup timers
        
        // RENDER
        Clear back buffer to black
        Draw parallax stars
        Draw all missiles
        Draw all bombs
        Draw all aliens
        Draw player
        Draw HUD (score, ships, shields, bonus)
        Draw score popups
        
        // PRESENT
        IF windowed:
            Blt back buffer to front buffer
        ELSE:
            Flip surfaces (vsync)
        END IF
        
        Calculate FPS
        DoEvents()
    END WHILE

CLEANUP:
    Release all DirectDraw surfaces
    Release DirectInput devices
    Release DirectSound buffers
    Unload form
END
```

## Loop Variations

### Level Complete Check
```vb
If iNumAliensMustBeDestroyed <= 0 Then
    bIsLevelComplete = True
End If
```

### Player Death Check
```vb
If oPlayer.bWasHitByMissle Then
    ' Explosion animation plays
    ' After animation completes:
    bIsPlayerDead = True
    iNumShips = iNumShips - 1
End If
```

### Game Over Check
```vb
If iNumShips <= 0 Then
    bIsGameOver = True
End If
```

## Performance Optimization Notes

1. **Fast Array Manager**: Uses a free-list system to avoid array resizing during gameplay
2. **Collision Detection**: Only checks active objects (skips dead/off-screen)
3. **Sparse Iteration**: Iterates only allocated array indices
4. **Dirty Rectangle**: Not implemented (full-screen clear each frame)
5. **Object Pooling**: Missiles and bombs are pre-allocated and reused

## Timing Accuracy

- Windows `GetTickCount()` has ~15ms resolution (Windows timer interrupt frequency)
- Actual frame times will vary: 40-55ms typical
- No frame interpolation (objects may appear jerky at low FPS)
- No frame skipping (rendering happens every update)
