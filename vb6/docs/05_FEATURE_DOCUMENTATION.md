# Feature Documentation - Comprehensive Gameplay Mechanics

## Player Movement Mechanics

### Basic Movement System
```vb
' From BrainsPlayer.cls - UpdateState()
' Player movement is direction-based with instant velocity

If .bMoveLeftRequested Then
    oActor.lVelocityDirection = 180     ' Left (degrees)
    oActor.lVelocity = lVelocity        ' Set to movement speed
ElseIf .bMoveRightRequested Then
    oActor.lVelocityDirection = 0       ' Right (degrees)
    oActor.lVelocity = lVelocity        ' Set to movement speed
ElseIf .bStopMoveRequested Then
    oActor.lVelocity = 0                ' Stop immediately
End If
```

### Player Physics Constants
```vb
' Typical setup in level initialization
lVelocity = 200  ' pixels per second (200 is typical)

' Position update formula (from Actor movement):
ldPixels = (lVelocity * lTicksPassed) / 1000.0
fX = fX + Cos(radians(lVelocityDirection)) * ldPixels
fY = fY + Sin(radians(lVelocityDirection)) * ldPixels
```

### Movement Formula
```
Δposition = velocity * (elapsed_ms / 1000.0)

Examples (at 40ms frame time):
- Velocity 200 px/s: moves 8 pixels per frame
- Velocity 150 px/s: moves 6 pixels per frame
- Velocity 250 px/s: moves 10 pixels per frame

At 200 px/s:
- Crosses 640px screen in: 640/200 = 3.2 seconds
- Or about 80 frames at 25 FPS
```

### Border Constraints
```vb
' From BrainsPlayer.cls - Initialize()
With oActor
    .bStopAtBorderLeft = True
    .bStopAtBorderRight = True
    .bStopAtBorderTop = True
    .bStopAtBorderBottom = True
End With

' Enforcement in Actor movement code:
If bStopAtBorderLeft And (fX < 0) Then fX = 0
If bStopAtBorderRight And (fX > PlayWidth) Then fX = PlayWidth
' (Similar for top/bottom)
```

### Movement Characteristics
- **No acceleration**: Instant velocity change (arcade-style)
- **No momentum**: Stops immediately when no input
- **Pixel-perfect control**: No floating-point drift issues
- **Constrained to playfield**: Cannot move off-screen

---

## Firing System

### Missile Configuration
```vb
' From BrainsPlayer.cls
Public lMissileRechargeTicks As Long  ' Set during level init (typical: 200-400ms)
Private lTicksSinceLastMissle As Long ' Accumulator

' From Level initialization
lVelocity = 400          ' Missile speed in px/s (typically 350-450)
lVelocityDirection = 270 ' Straight up
```

### Firing Logic
```vb
' BrainsPlayer.cls - UpdateState()
lTicksSinceLastMissle = lTicksSinceLastMissle + oLevel.lTicksPassed

' Check if rapid fire power-up is active
If oLevel.bHasRapidFire Then
    llMissileRechargeTicksNeeded = lMissileRechargeTicks / 2
Else
    llMissileRechargeTicksNeeded = lMissileRechargeTicks
End If

' Fire if ready and requested
If .bMissleRequested And (lTicksSinceLastMissle >= llMissileRechargeTicksNeeded) Then
    If oLevel.FirePlayerMissle() Then
        oSoundEffect_Missile.Play        ' "Laser.wav"
        lTicksSinceLastMissle = 0        ' Reset accumulator
    End If
End If
```

### Recharge Times

| Mode | Recharge Time | Missiles/Second | Description |
|------|---------------|-----------------|-------------|
| Normal | 300ms | ~3.3 | Standard fire rate |
| Rapid Fire | 150ms | ~6.7 | Power-up doubles rate |

### Missile Pool
```vb
' From GamePlay.bas / Level initialization
Global Const giMAX_MISSLES% = 10

' Maximum 10 missiles on screen simultaneously
' If pool full, fire request fails silently
' Missiles auto-release when they exit play area
```

### Missile Properties
```vb
' From AlienDefinitions.bas - Define_Missle()
' Sprite: 8x8 pixels (frame 1), 7x5 pixels (frames 2-4)
' Speed: ~400 pixels/second (typical)
' Direction: 270 degrees (straight up)
' Animation: 4 frames, 100ms per frame, looping

' Travel time across screen:
' Height = 428 pixels (480 - 32 top - 20 bottom)
' At 400 px/s: 428/400 = 1.07 seconds = ~27 frames
```

### Firing Sound
```vb
' Resource: "Laser.wav" (no size specified in search)
' Loaded with 5 buffer copies for simultaneous playback
```

### Missile Spawn Position
```vb
' Level.cls - FirePlayerMissle()
With roFromActor  ' (Player)
    lfStartX = .CenterX()  ' Horizontally centered on player
    lfStartY = .fY         ' At player's top edge
End With

' Adjust for missile sprite dimensions
With MissileFrameDef
    lfStartX = lfStartX - (.iXSize / 2)  ' Center horizontally
    lfStartY = lfStartY - .iYSize        ' Just above player
End With
```

---

## Shield System

### Shield Constants
```vb
' From GamePlay.bas
Global Const glMAX_SHIELDS_TICKS = 50000  ' 50 seconds worth at 1000ms/s

' Initialized per game:
mgGame.lShieldsLeft = glMAX_SHIELDS_TICKS / 2  ' Start with 25000 (25 seconds)
```

### Activation & Drain
```vb
' BrainsPlayer.cls - UpdateState()

' Activation check (normal state):
If .bShieldsRequested And oLevel.lShieldsLeft > 0 Then
    Call oActor.oSequencePlayer.PlayFrameSequence(oFrameSequence_Shields)
    eState = stateShields
    oLevel.bShieldsOn = True
End If

' Drain logic (shields state):
If eState = stateShields Then
    oLevel.lShieldsLeft = oLevel.lShieldsLeft - oLevel.lTicksPassed
    
    ' Deactivate conditions:
    If (Not .bShieldsRequested) Or (oLevel.lShieldsLeft <= 0) Then
        Call oActor.oSequencePlayer.PlayFrameSequence(oFrameSequence_Normal)
        eState = stateNormal
        oLevel.bShieldsOn = False
    End If
End If
```

### Shield Drain Rate
```
Drain = 1 tick per 1 millisecond elapsed

At 25 FPS (40ms per frame):
- 40 ticks drained per frame
- 25000 ticks / 40 per frame = 625 frames
- 625 frames / 25 FPS = 25 seconds of continuous shield

At 20 FPS (50ms per frame):
- 50 ticks drained per frame  
- 25000 / 50 = 500 frames
- 500 / 20 = 25 seconds of continuous shield

Note: Duration is real-time independent (25 seconds of shield
regardless of frame rate, due to tick-based drain)
```

### Shield Behavior
```vb
' Collision with shields active:
If .DetectCollision(oPlayer) Then
    If bShieldsOn Then
        .bHitShields = True    ' Alien or bomb is destroyed
        ' Player is unharmed
    Else
        .bHitPlayer = True     ' Player takes hit
        oPlayer.bWasHitByMissle = True
    End If
End If
```

### Shield Animation
```vb
' From AlienDefinitions.bas - Define_Player()
' Animation: "SHIELDS" sequence
' Typically shows energy field / force field animation
' Frames loop continuously while shields active
' Visual indicator to player that shields are on
```

### Shield HUD Display
```vb
' GamePlay.bas - HUD drawing
' Bar indicator showing remaining shield energy
' Width proportional to lShieldsLeft / glMAX_SHIELDS_TICKS
' Max width: 100 pixels
' Color: RGB(96, 96, 192) - blue-ish

miShieldLength = ((mgGame.lShieldsLeft / glMAX_SHIELDS_TICKS) * 100)
mrShields.Right = 320 + miShieldLength  ' Draw filled rectangle
```

---

## Enemy AI Behaviors

### Alien Type A - "Swarmer"

```vb
' From BrainsAlienA.cls
' Sprite: 32x8 pixels per frame, 36 frames total
' Animation: Frames 1-20 (normal), 50ms per frame = 1 second loop
' Explosion: Frames 21-36 (16 frames), 10ms per frame = 160ms total
```

**Behavior States:**
```vb
Enum State_Enum
    stateNormal = 0        ' Following formation
    stateExploding = 2     ' Hit by missile
End Enum
```

**AI Logic:**
```vb
' Simple formation follower - no attack patterns
' Follows marching formation leader
' Collision box: 23x4 pixels (offset 0,2)

' Movement: SetMovementRelativePosition(leader, xOffset, yOffset)
' Stays in fixed position relative to formation leader

' Scoring:
If hit Then
    oLevel.lScore = oLevel.lScore + 10
End If
```

**Timing Constants:**
- Animation: 50ms/frame
- Total animation cycle: 1 second
- Explosion duration: 160ms

### Alien Type B - "Tank"

```vb
' From BrainsAlienB.cls
' Sprite: 16x16 pixels per frame, 64 frames total
' Multi-hit enemy: Takes 4 hits to destroy
```

**Hit States:**
```vb
' Animation sequences per damage level:
' 3 legs: Frames 1-8,   normal animation
'         Frames 9-16,  hit flash
' 2 legs: Frames 17-24, normal
'         Frames 25-32, hit flash  
' 1 leg:  Frames 33-40, normal
'         Frames 41-48, hit flash
' 0 legs: Frames 49-56, torso only (crawling)
' Explode: Frames 57-64

' All animations: 80ms per frame
```

**AI Logic:**
```vb
Private iNumHits As Integer  ' Tracks damage (0-3)

If .lWasHitByMissiles > 0& Then
    iNumHits = iNumHits + 1
    
    Select Case iNumHits
        Case 1:  ' Lost one leg
            Call .oSequencePlayer.PlayFrameSequence(oFrameSequence_2Legs_Hit)
            oLevel.lScore = oLevel.lScore + 10
            
        Case 2:  ' Lost second leg
            Call .oSequencePlayer.PlayFrameSequence(oFrameSequence_1Leg_Hit)
            oLevel.lScore = oLevel.lScore + 10
            
        Case 3:  ' Lost third leg (torso only)
            Call .oSequencePlayer.PlayFrameSequence(oFrameSequence_0Legs)
            oLevel.lScore = oLevel.lScore + 5
            
        Case Else:  ' Final hit - explode
            Call .oSequencePlayer.PlayFrameSequence(oFrameSequence_Explode)
            oLevel.lScore = oLevel.lScore + 10
            eState = stateExploding
    End Select
End If
```

**Scoring Breakdown:**
- 1st hit: +10 points
- 2nd hit: +10 points  
- 3rd hit: +5 points
- 4th hit: +10 points
- **Total: 35 points**

**Timing:**
- Animation: 80ms/frame (slower than Type A)
- Not marked as `bMustBeDestroyed` (optional target)

### Alien Type C - "Flanker"

```vb
' From BrainsAlienC.cls
' Sprite: 16x16 pixels (10px wide displayed), 32 frames
' Performs left/right attack swoops
```

**Behavior States:**
```vb
Enum State_Enum
    stateNormal = 0
    stateAttackingLeft = 1
    stateAttackingRight = 2  
    stateExploding = 3
End Enum
```

**Attack Pattern:**
```vb
Public lAverageAttackIntervalTicks As Long  ' Time between attacks
Private lAttackIntervalTicks As Long        ' Current countdown

' Normal state - countdown to attack
lAttackIntervalTicks = lAttackIntervalTicks - oLevel.lTicksPassed
If lAttackIntervalTicks <= 0 Then
    ' Choose random attack direction
    If Rnd < 0.5 Then
        eState = stateAttackingLeft
        PlayFrameSequence(oFrameSequence_AttackLeft)
    Else
        eState = stateAttackingRight
        PlayFrameSequence(oFrameSequence_AttackRight)
    End If
    ' Reset interval with randomness
    lAttackIntervalTicks = lAverageAttackIntervalTicks + RandomVariation()
End If
```

**Animation Sequences:**
- Normal: Frames 1-8, 125ms/frame
- Attack Left: Frames 9-16, 125ms/frame
- Attack Right: Frames 17-24, 125ms/frame
- Explode: Frames 25-32, 40ms/frame

**Scoring:**
```vb
' 10 points per hit
' Bonus 10 points if hit during attack pattern
If eState = stateAttackingLeft Or eState = stateAttackingRight Then
    oLevel.lScore = oLevel.lScore + 10  ' Bonus for hitting during attack
End If
oLevel.lScore = oLevel.lScore + 10      ' Base score
```

### Alien Type D - "Spinner"

```vb
' From BrainsAlienD.cls
' Sprite: 32x24 pixels (20x20 displayed), 28 frames
' Rotates continuously, drops bombs
```

**Animation:**
```vb
' Normal: Frames 1-20, 25ms/frame = 500ms full rotation
' Explode: Frames 21-28, 40ms/frame = 320ms explosion
```

**AI Logic:**
```vb
' Fast spinner with bombing capability
' No special attack pattern - stays in formation
' Can drop A-bombs randomly

' Bomb drop logic (example):
If (Rnd() * 1000) < BombDropChance Then
    oLevel.DropABomb(oActor)
End If
```

**Scoring:**
```vb
' High value target
oLevel.lScore = oLevel.lScore + 25
```

**Timing:**
- Fast rotation: 25ms/frame (40 FPS animation)
- Full rotation: 500ms (very fast visual)

### Alien Type E - "Elite Attacker"

```vb
' From BrainsAlienE.cls  
' Sprite: 16x16 pixels, 64 frames
' Complex state machine with dive attacks
```

**Behavior States:**
```vb
Enum State_Enum
    stateNormal = 0              ' In formation
    stateAttackingRight = 1      ' Right-side dive
    stateAttackingLeft = 2       ' Left-side dive
    stateExploding = 3           ' Destroyed
End Enum
```

**Attack Timing:**
```vb
Public lAverageAttackIntervalTicks As Long    ' Average time between attacks
Public lMinAttackTurnInterval As Long         ' Min time during attack maneuver
Public lMaxAttackTurnInterval As Long         ' Max time during attack maneuver
Public lAverageBombRateAttack As Long         ' Bomb frequency during attack
Public lAverageBombRateFormation As Long      ' Bomb frequency in formation

Private lAttackTurnIntervalTicks As Long      ' Current turn timer
```

**Attack Pattern:**
```vb
' Formation mode - countdown to attack
If eState = stateNormal Then
    lNextAttackTicks = lNextAttackTicks - oLevel.lTicksPassed
    
    If lNextAttackTicks <= 0 Then
        ' Begin dive attack
        If PlayerIsToLeft() Then
            eState = stateAttackingLeft
            PlayFrameSequence(oFrameSequence_AttackLeft)
        Else
            eState = stateAttackingRight
            PlayFrameSequence(oFrameSequence_AttackRight)
        End If
        
        ' Set random turn interval
        lAttackTurnIntervalTicks = RandomRange(lMinAttackTurnInterval, lMaxAttackTurnInterval)
    End If
End If

' Attack mode - dive toward player
If eState = stateAttackingLeft Or eState = stateAttackingRight Then
    ' Drop bombs more frequently
    If (Rnd * 1000) < (lAverageBombRateAttack / oLevel.lTicksPassed) Then
        oLevel.DropDBomb(oActor)  ' Directed bomb
    End If
    
    ' Change direction periodically
    lAttackTurnIntervalTicks = lAttackTurnIntervalTicks - oLevel.lTicksPassed
    If lAttackTurnIntervalTicks <= 0 Then
        ' Alter attack angle
        AdjustAttackVector()
        lAttackTurnIntervalTicks = RandomRange(lMinAttackTurnInterval, lMaxAttackTurnInterval)
    End If
    
    ' Return to formation if off-screen or timer expired
    If ShouldReturnToFormation() Then
        eState = stateNormal
        PlayFrameSequence(oFrameSequence_EnterFormation)
    End If
End If
```

**Animation Sequences:**
- Formation: Frames 1-8, 75ms/frame
- Attack Left: Frames 25-40, variable speed
- Attack Right: Similar
- Turn sequences: Smooth rotation between states
- Explode: 3 different sequences based on current state

**Scoring:**
```vb
' 10 points per hit (standard)
' Higher difficulty justifies more caution, not more points
oLevel.lScore = oLevel.lScore + 10
```

**Collision Boxes:**
- Formation frame: 13x4 pixels (compact)
- Attack frame: 14x9 pixels (larger during dive)

---

## Collision Detection Algorithm

### High-Level Overview
```vb
' Level.cls - Update()
' Collision detection is hierarchical and optimized

FOR EACH Alien:
    ' Only check if alien can be hit
    If .bCanBeHitByMissles Then
        FOR EACH Missile:
            If DetectCollision(Alien, Missile) Then
                Alien.bWasHitByMissle = True
                Release Missile
                Break  ' One missile hits once
            End If
        END FOR
    End If
    
    ' Only check if alien can hit player
    If .bCanHitPlayer Then
        If DetectCollision(Alien, Player) Then
            If bShieldsOn Then
                Alien.bHitShields = True
            Else
                Alien.bHitPlayer = True
                Player.bWasHitByMissle = True
            End If
        End If
    End If
END FOR
```

### Collision Box System
```vb
' CollisionBox.cls - Per-frame collision definition
Public lXOffset As Long    ' Offset from sprite origin
Public lYOffset As Long
Public lXSize As Long      ' Box dimensions
Public lYSize As Long
```

### Rectangle Intersection Test
```vb
' Actor.cls - DetectCollision()
Public Function DetectCollision(roOtherActor As Actor2) As Boolean
    ' Get collision boxes for both actors' current frames
    Set loMyCollisionBox = GetCurrentCollisionBox()
    Set loOtherCollisionBox = roOtherActor.GetCurrentCollisionBox()
    
    ' Calculate absolute collision rectangles
    With lrMyRect
        .Left = CInt(fX) + loMyCollisionBox.lXOffset
        .Top = CInt(fY) + loMyCollisionBox.lYOffset
        .Right = .Left + loMyCollisionBox.lXSize
        .Bottom = .Top + loMyCollisionBox.lYSize
    End With
    
    With lrOtherRect
        .Left = CInt(roOtherActor.fX) + loOtherCollisionBox.lXOffset
        .Top = CInt(roOtherActor.fY) + loOtherCollisionBox.lYOffset
        .Right = .Left + loOtherCollisionBox.lXSize
        .Bottom = .Top + loOtherCollisionBox.lYSize
    End With
    
    ' AABB (Axis-Aligned Bounding Box) intersection test
    DetectCollision = Not ( _
        lrMyRect.Right < lrOtherRect.Left Or _
        lrMyRect.Left > lrOtherRect.Right Or _
        lrMyRect.Bottom < lrOtherRect.Top Or _
        lrMyRect.Top > lrOtherRect.Bottom)
End Function
```

### Pseudocode for AABB Test
```
function rectangles_intersect(rect1, rect2):
    if rect1.right < rect2.left:    // rect1 is entirely to the left
        return false
    if rect1.left > rect2.right:    // rect1 is entirely to the right
        return false
    if rect1.bottom < rect2.top:    // rect1 is entirely above
        return false
    if rect1.top > rect2.bottom:    // rect1 is entirely below
        return false
    
    // If none of the separation conditions are true, boxes overlap
    return true
```

### Collision Box Examples

**Player:**
```vb
' Ship.bmp - 32x24 pixels per frame
' Collision box: 28x18 (offset 2,3)
' Slightly inset from sprite edges for forgiving gameplay
```

**Missile:**
```vb
' Missle.bmp - 8x8 pixels
' Collision box: 6x6 (offset 1,1)
' Small precise hitbox
```

**Alien A:**
```vb
' AlienA.bmp - 32x8 pixels per frame
' Collision box: 23x4 (offset 0,2)
' Narrow horizontal box for thin sprite
```

**Alien E (Formation):**
```vb
' AlienE2.bmp - Formation frames
' Collision box: 13x4 (offset 0,0)
' Very small when in formation (harder to hit)
```

**Alien E (Attack):**
```vb
' AlienE2.bmp - Attack frames
' Collision box: 14x9 (offset 0,0)
' Larger during attack (easier to hit, more dangerous)
```

### Optimization Flags
```vb
' Actor2 flags to skip unnecessary checks
Public bCanBeHitByMissles As Boolean    ' Default: False
Public bCanHitPlayer As Boolean         ' Default: False

' Set during actor initialization:
Alien.bCanBeHitByMissles = True
Alien.bCanHitPlayer = True

Missile.bCanBeHitByMissles = False  ' Missiles don't collide with missiles
Missile.bCanHitPlayer = False       ' Missiles are player's projectiles
```

### Performance Considerations
- **O(n × m)** complexity: Aliens × Missiles per frame
- Typical: 30 aliens × 10 missiles = 300 collision checks per frame
- AABB test is very fast (4-8 integer comparisons)
- Early-out via flags prevents most unnecessary checks
- No spatial partitioning (grid, quadtree) - unnecessary at this scale

---

## Scoring System

### Base Enemy Values
```vb
' Points awarded per alien type (from AI behavior code):

Alien A:  10 points (standard)
Alien B:  35 points total (10+10+5+10 across 4 hits)
Alien C:  10 points base, +10 if hit during attack = 20 max
Alien D:  25 points (high value)
Alien E:  10 points (difficulty, not points)
Rocket:   Varies (cargo carrier)
Cargo:    100-1000 points depending on color/type
```

### Bonus Score Multiplier
```vb
' From Level.cls and TypeDefs.bas
Public iBonusMultiplier As Integer  ' Ranges from 1 to 10+

' Multiplier increases when collecting certain power-ups or cargo
' Applied to alien destruction scores:
ActualScore = BaseScore * iBonusMultiplier

' Visual indicator in HUD:
' "X2", "X3", "X4", etc. displayed when active
```

### Completion Bonus
```vb
' GamePlay.bas - Level completion
Public lBonus As Long             ' Starts at 2500
Public lBonusTicks As Long        ' Timer for decay

' Decay logic (per frame):
.lBonusTicks = .lBonusTicks + .lTicksPassed
If .lBonusTicks > 500 Then
    .lBonusTicks = 0
    .lBonus = .lBonus - 10     ' -10 points every 500ms
End If

' On level complete:
FinalScore = CurrentScore + lBonus
```

**Bonus Calculation:**
```
Start:    2500 points
Decay:    -10 points per 0.5 seconds
Duration: 2500 / 10 = 250 seconds maximum theoretical time

Fast completion examples:
- 30 seconds:  2500 - (30 * 2 * 10) = 1900 bonus
- 60 seconds:  2500 - (60 * 2 * 10) = 1300 bonus
- 120 seconds: 2500 - (120 * 2 * 10) = 100 bonus
```

### On-Screen Score Popups
```vb
' TypeDefs.bas - DisplayBonus
Type DisplayBonus
    bActive As Boolean
    lFrame As Long       ' Which bonus sprite (100, 200, etc.)
    lTicks As Long       ' Time displayed
    lX As Long          ' Position
    lY As Long
End Type

' GamePlay.bas
Const miMAX_BONUSES% = 20
Dim mDisplayBonuses(1 To 20) As DisplayBonus

' Display duration: 1500ms per popup
If .lTicks > 1500 Then .bActive = False
```

**Popup Frames (from TypeDefs.bas):**
```vb
Enum BonusFrame_Enum
    bonusFrame100 = 0
    bonusFrame200 = 1
    bonusFrame300 = 2
    bonusFrame400 = 3
    bonusFrame500 = 4
    bonusFrame600 = 5
    bonusFrame700 = 6
    bonusFrame800 = 7
    bonusFrame900 = 8
    bonusFrame1000 = 9
    bonusFrameRed25 = 10    ' Power-up indicators
    bonusFrameRed50 = 11
    bonusFrameRed75 = 12
    bonusFrameRed100 = 13
End Enum
```

### Score Display
```vb
' GamePlay.bas - BltNumber()
' Renders 7-digit score with leading zeros
' Position: Top-right of HUD (582, 7)
' Uses bitmap font from Text.bmp
BltNumber mgGame.lScore, 7, 582, 7, True
```

---

## Power-Up System

### Cargo System
```vb
' TypeDefs.bas - CargoType_Enum
Enum CargoType_Enum
    cargoOrange = 0      ' Standard cargo types
    cargoPink = 1
    cargoYellow = 2
    cargoBlue = 3
    cargoGreen = 4
    cargoPurple = 5
    cargoRed = 6
    cargoNavy = 7
    cargoRedDot = 8      ' Special dotted variants
    cargoGreenDot = 9
    cargoBlueDot = 10
    cargoPinkDot = 11
    cargoYellowDot = 12
    cargoColorDot = 13   ' Rainbow/multi-color
    cargoRandom = -1     ' Random selection
End Enum
```

### Cargo Values & Effects
```vb
' BrainsCargo.cls - Different cargo types grant different bonuses

' Point values (examples based on color):
Orange:    100 points
Pink:      200 points
Yellow:    300 points
Blue:      400 points
Green:     500 points
Purple:    600 points
Red:       700 points
Navy:      800 points

' Dot variants (power-ups):
RedDot:    Shield refill (25% - 12500 ticks)
GreenDot:  Shield refill (50% - 25000 ticks)
BlueDot:   Shield refill (75% - 37500 ticks)
PinkDot:   Shield refill (100% - 50000 ticks)
YellowDot: Bonus multiplier increase (+1)
ColorDot:  Rapid fire power-up
```

### Shield Refill Power-Ups
```vb
' BrainsCargo.cls - OnCollectedByPlayer()
Select Case CargoType
    Case cargoRedDot:
        oLevel.lShieldsLeft = oLevel.lShieldsLeft + (glMAX_SHIELDS_TICKS / 4)
        ShowBonus(bonusFrameRed25, X, Y)
        
    Case cargoGreenDot:
        oLevel.lShieldsLeft = oLevel.lShieldsLeft + (glMAX_SHIELDS_TICKS / 2)
        ShowBonus(bonusFrameRed50, X, Y)
        
    Case cargoBlueDot:
        oLevel.lShieldsLeft = oLevel.lShieldsLeft + (glMAX_SHIELDS_TICKS * 3 / 4)
        ShowBonus(bonusFrameRed75, X, Y)
        
    Case cargoPinkDot:
        oLevel.lShieldsLeft = glMAX_SHIELDS_TICKS  ' Full refill
        ShowBonus(bonusFrameRed100, X, Y)
End Select

' Cap at maximum
If oLevel.lShieldsLeft > glMAX_SHIELDS_TICKS Then
    oLevel.lShieldsLeft = glMAX_SHIELDS_TICKS
End If
```

### Rapid Fire Power-Up
```vb
' When ColorDot cargo collected:
oLevel.bHasRapidFire = True

' Effect (in BrainsPlayer firing logic):
If oLevel.bHasRapidFire Then
    llMissileRechargeTicksNeeded = lMissileRechargeTicks / 2
Else
    llMissileRechargeTicksNeeded = lMissileRechargeTicks
End If

' Duration: Typically expires after time or level completion
' (Implementation may vary per level design)
```

### Bonus Multiplier Power-Up
```vb
' YellowDot cargo increases multiplier
oLevel.iBonusMultiplier = oLevel.iBonusMultiplier + 1

' Visual feedback: HUD shows "X2", "X3", etc.
' All subsequent enemy kills worth: BaseScore * Multiplier
' Example: Alien A normally 10 points, with X5 = 50 points
```

### Cargo Delivery
```vb
' BrainsCargoShip.cls - Drops cargo periodically
' Cargo falls at set velocity (typically 50-100 px/s)
' Player must position under cargo to collect
' Collision detection same as enemy collision
' On collect: cargo disappears, effect applied, sound plays
```

### X-Bonus Special
```vb
' AlienDefinitions.bas - Define_XBonus()
' Rare floating "X" bonus item
' Sprite: XBonus.bmp
' Worth: Variable points or special effect
' Appears: Random or scripted events
```

---

## Level Progression Logic

### Level Initialization
```vb
' LevelDefinitions.bas - Level1_Initialize2()

' Load resources
Call Levels123_LoadBitMapDefinitions(roLevel)
Call Levels123_LoadSounds(roLevel)

' Set alien counts and pools
liNumAliens = 1 + 15 + 6 + 2 + 2 + 4 + 1 + 1 + 1  ' = 33 total
Call roLevel.InitializeActorArrays(liNumAliens, 10, 20, 2, 1)
'   Args: MaxAliens, MaxMissiles, MaxABombs, MaxDBombs, (unused)

' Track win condition
roLevel.lNumAliensMustBeDestroyed = 15 + 2 + 2 + 4  ' = 23 critical aliens
' (Alien B's are optional - not required for completion)
```

### Player Setup
```vb
' Place player at bottom center
Set loActor = roLevel.SetPlayer("PLAYER", New BrainsPlayer)
With loActor.oBitMapDefinition.GetFrameDefinition(0)
    loActor.fX = (roLevel.lPlayWidth / 2)              ' Center: 320
    loActor.fY = roLevel.lPlayHeight - (.lYSize / 2) - 16  ' Bottom minus offset
End With

' Configure player abilities
With BrainsPlayer
    .lVelocity = 200                    ' Movement speed
    .lMissileRechargeTicks = 300        ' Fire rate (300ms)
End With
```

### Formation Setup
```vb
' Create invisible formation leader
Set loFormationLeader = roLevel.AddNewAlien("", New Brains)
Call loFormationLeader.SetMovementMarching(0, 0, 30, 0, roLevel.lPlayWidth - 240)
'   Args: StartX, StartY, StartDirection, VelocityDirection, MarchingDistance

' Formation marches horizontally:
' - Starts at X=0
' - Moves right until X = PlayWidth - 240 (400 pixels)
' - Reverses direction
' - Marches back to X=0
' - Repeat
```

### Alien Positioning
```vb
' Position aliens relative to formation leader
For liCtr = 1 To 15  ' Alien A's
    Set loActor = roLevel.AddNewAlien("ALIENA", New BrainsAlienA)
    loActor.bMustBeDestroyed = True
    
    ' SetMovementRelativePosition(leader, xOffset, yOffset)
    ' Example positions:
    Case 1: loActor.SetMovementRelativePosition(loFormationLeader, 1.5, 182)
    Case 2: loActor.SetMovementRelativePosition(loFormationLeader, 14.5, 194)
    Case 3: loActor.SetMovementRelativePosition(loFormationLeader, 27.5, 182)
    ' ... creates wave pattern with vertical offset alternation
Next liCtr

' Result: Aliens maintain formation while leader marches
' Creates classic "space invaders" wave motion
```

### Level Completion Check
```vb
' Level.cls - Update()
' After processing all alien updates:

If iNumAliensMustBeDestroyed <= 0 Then
    bIsLevelComplete = True
End If

' Main loop detects completion:
Do
    Call Level1_Update()
    Call Level1_Draw()
Loop While Not (mbQuit Or mgGame.bIsLevelComplete Or mgGame.bIsGameOver Or mgGame.bIsPlayerDead)

If mgGame.bIsLevelComplete Then
    ' Award completion bonus
    mgGame.lScore = mgGame.lScore + mgGame.lBonus
    
    ' Proceed to next level (if implemented)
    ' Or show victory screen
End If
```

### Life System
```vb
' GamePlay.bas - GamePlay_Initialize()
mgGame.iNumShips = 3  ' Start with 3 lives

' Player death:
If oPlayer.bWasHitByMissle Then
    mgGame.iNumShips = mgGame.iNumShips - 1
    mgGame.bIsPlayerDead = True
    
    ' Play explosion animation
    ' Reset level (aliens return to positions)
End If

' Game over check:
If mgGame.iNumShips <= 0 Then
    mgGame.bIsGameOver = True
End If
```

### Level Configuration
```vb
' Each level can customize:
- Alien types and counts
- Formation patterns
- Marching speed and distance
- AI aggressiveness (attack intervals)
- Bombing rates
- Power-up frequencies
- Starting player attributes (shields, fire rate)
- Bonus decay rate

' Example variations:
Level 1: 15 Type A, 6 Type B (slow march, rare bombs)
Level 2: More Type C & E (faster, aggressive attacks)
Level 3: Primarily Type D & E (high bomb rate, fast pace)
```

### Difficulty Progression
```vb
' Suggested difficulty curve (not all implemented):
- Increase marching speed
- Decrease attack intervals for Type C/E
- Increase bomb drop rates
- Add more Type E aliens
- Reduce starting shields
- Faster enemy animations (visual intensity)
- More complex formation patterns
```

### Level Structure Pattern
```vb
1. Initialize resources (bitmaps, sounds)
2. Set object pool sizes
3. Create formation leader with marching behavior
4. Spawn aliens in formation positions
5. Mark critical aliens (bMustBeDestroyed = True)
6. Optionally spawn:
   - Cargo ships
   - Bonus items
   - Planetary obstacles
7. Set initial player position and stats
8. Begin main game loop
```

---

## Summary Tables

### Player Stats
| Property | Value | Notes |
|----------|-------|-------|
| Movement Speed | 200 px/s | Typical |
| Missile Speed | 400 px/s | Typical |
| Missile Recharge | 300ms | Base, varies by level |
| Rapid Fire Recharge | 150ms | With power-up |
| Max Missiles | 10 | Pool size |
| Starting Lives | 3 | Standard |
| Starting Shields | 25000 ticks | 25 seconds |
| Max Shields | 50000 ticks | 50 seconds |

### Alien Stats
| Type | Points | HP | Speed | Animation Speed | Must Destroy |
|------|--------|-------|-------|-----------------|--------------|
| A | 10 | 1 | Formation | 50ms/frame | Yes |
| B | 35 | 4 | Formation | 80ms/frame | No |
| C | 10-20 | 1 | Formation+Attacks | 125ms/frame | Yes |
| D | 25 | 1 | Formation | 25ms/frame | Yes |
| E | 10 | 1 | Formation+Dives | 75ms/frame | Yes |

### Timing Constants
| System | Value | Notes |
|--------|-------|-------|
| Target FPS | 25 | 40ms per frame |
| Max Delta | 60ms | Frame time cap |
| Shield Drain | 1:1 | 1 tick per ms |
| Bonus Decay | -10/500ms | Per half-second |
| Popup Duration | 1500ms | Score displays |

### Power-Up Effects
| Item | Effect | Value |
|------|--------|-------|
| Red Dot | Shield +25% | +12500 ticks |
| Green Dot | Shield +50% | +25000 ticks |
| Blue Dot | Shield +75% | +37500 ticks |
| Pink Dot | Shield +100% | Full refill |
| Yellow Dot | Multiplier +1 | Cumulative |
| Color Dot | Rapid Fire | 2x fire rate |
