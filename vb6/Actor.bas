Attribute VB_Name = "modActor"
Option Explicit

Global Const giDONT_MARCH% = -1

Type DisplayBonus
    bActive As Boolean
    iFrame As Long
    lTicks As Long
    iX As Integer
    iY As Integer
End Type

Enum BombDir_Enum
    bombDefaultDir = 0
    bombStraightDown = 1
    bombStraightUp = 2
    bombToTarget = 3
End Enum

Enum ActorType_Enum
    actorPlayer = 0
    actorPlayerMissle = 1
    actorAlienBombA = 10
    actorAlienBombB = 11
    actorAlienA = 101
    actorAlienB = 102
    actorAlienC = 103
    actorAlienD = 104
    actorAlienE = 105
    actorXBonus = 1000
    actorPlanet = 1001
End Enum

Type ActorMover
    'Properties
    bActive As Boolean
    dX As Double
    dY As Double
    iVelocity As Integer
    iDirection As Integer
    iAcceleration As Integer
    iAccDirection As Integer
    bXStopAtBorder As Boolean
    bYStopAtBorder As Boolean
    bXReverseAtBorder As Boolean
    bYReverseAtBorder As Boolean
    iXSize As Integer
    iYSize As Integer
    iMarchingDistance As Integer  'or DONT_MARCH
    'State
    iLastX As Integer
    iLastY As Integer
    bIsOffScreenX As Boolean
    bIsOffScreenY As Boolean
    bIsOffScreen As Boolean
    bIsAtXBorder As Boolean
    bIsAtYBorder As Boolean
    bIsAtBorder As Boolean
    dMarched As Double
    bFirstMove As Boolean
End Type

Type ActorDrawer
    'Properties
    ddsBitMapSurface As IDirectDrawSurface2
    iFrameSizeX As Integer
    iFrameSizeY As Integer
    iWidthInFrames As Integer
    iStartFrame As Integer
    iNumFrames As Integer
    iNextStartFrame As Integer
    iNextNumFrames As Integer
    iExplosionStartFrame As Integer
    iExplosionNumFrames As Integer
    iExplosionFramesPerSecond As Integer
    lExplosionTicksPerFrame As Long
    bAutoSwitchToNextSequence As Boolean
    iFramesPerSecond As Integer
    lTicksPerFrame As Long
    lTicksSinceLastFrame As Long
    bLoopAnimation As Boolean
    'State
    iCurrentFrameInSequence As Integer
    bIsAnimationDone As Boolean
End Type

Type Actor
    eActorType As ActorType_Enum
    iXSize As Integer
    iYSize As Integer
    iNumCollisionBoxes As Integer
    iXCollisionBoxOffset() As Integer
    iYCollisionBoxOffset() As Integer
    iXCollisionBoxSize() As Integer
    iYCollisionBoxSize() As Integer
    bExploding As Boolean
    bIsDoneExploding As Boolean
    lState1 As Long
    lState2 As Long
    lHMover As Long 'Handle to the mover
    lHFormationMover As Long 'Handle to the mover
    bInFormation As Boolean
    iXFormationOffset As Integer
    iYFormationOffset As Integer
    adDrawer As ActorDrawer
    iHseCollisionSound As Integer
    lPoints As Long
    lBonusPoints As Long
End Type

Type PlayerGuns
    iMaxOnScreen As Integer
    lRechargeTime As Long
    lTicksSinceLastShot As Long
    bShotReady As Boolean
End Type

Type Game
    ddDirectDraw As IDirectDraw2 'local copy - don't forget to Set to Nothing!
    ddsBackBufferSurface As IDirectDrawSurface2 'local copy - don't forget to Set to Nothing!
    lTicksPassed As Long
    bRealTime As Boolean
    lTicksPerLoop As Long
    lMaxTicksPerLoop As Long
    iPlayHeight As Integer
    iPlayWidth As Integer
    iPlayXOffset As Integer
    iPlayYOffset As Integer
    iNumShips As Integer
    lScore As Long
    bIsGameOver As Boolean
    bIsPlayerDead As Boolean
    bIsLevelComplete As Boolean
    lShieldsLeft As Long 'in ticks
    lBonus As Long
    lBonusTicks As Long
    iBonusMultiplier As Integer
    udtMovers() As ActorMover
    famMovers As FastArrayManager
End Type

'
'============= Actor_Move =============
'
'
'Direction is in degrees
'Velocity is in pixels/second
'rgGame.TicksPassed is milliseconds
'Marching means going back and forth in a line over a specified distance
Public Sub ActorMover_Move(rudtMover As ActorMover, rgGame As Game)
    'Pixels to move
    Dim ldPixels As Double
    'X,Y factor (-1.0 to 1.0) in movement
    Dim ldXInc As Double
    Dim ldYInc As Double
    'If direction should reverse
    Dim lbReverse As Boolean
    
    With rudtMover
        If Not .bActive Then Exit Sub
        
        'Store last position
        .iLastX = .dX
        .iLastY = .dY
        
        'Clear reverse flag
        lbReverse = False
                
        'Accelerate
        Call CalculateNewVelocity(.iVelocity, .iDirection, .iAcceleration, .iAccDirection, rgGame.lTicksPassed)
        'Determine X,Y factor from direction angle (degrees)
        Call GetXYIncFromAngle(.iDirection, ldXInc, ldYInc)
        'Determine distance to move in pixels
        ldPixels = CDbl(.iVelocity * rgGame.lTicksPassed) / 1000
        
        'See if we are marching
        If .iMarchingDistance > 0 Then
            'If we are marching, are we go to march to far?
            If ((.dMarched + ldPixels) > .iMarchingDistance) Then
                'Adjust distance so we do not march to far, and reverse (later)
                ldPixels = .iMarchingDistance - .dMarched
                lbReverse = True
            Else
                'add distance to distance marched so far
                .dMarched = .dMarched + ldPixels
            End If
        End If
        
        'Calculate new X and Y positions
        .dX = .dX + (ldPixels * ldXInc)
        .dY = .dY + (ldPixels * ldYInc)
        
        'clear border flags
        .bIsAtXBorder = False
        .bIsAtYBorder = False
        .bIsOffScreenX = False
        .bIsOffScreenY = False
        
        'see if we are going to go off the playfield to the right
        If ((.dX + .iXSize) > rgGame.iPlayWidth) Then
            'We are partially or fully off the playfield - so we stop or reverse?
            If .bXReverseAtBorder Or .bXStopAtBorder Then
                'WIP: Hmm, shouldn't we check this and then adjust distance afterwords?? or decrement Y same way?
                'don't go off- go to the edge
                .dX = rgGame.iPlayWidth - .iXSize
                .bIsAtXBorder = True
                If .bXReverseAtBorder Then lbReverse = True
            Else
                If (.dX > rgGame.iPlayWidth) Then .bIsOffScreenX = True
            End If
        'see if we are going to go off the playfield to the left
        ElseIf (.dX < 0) Then
            If .bXReverseAtBorder Or .bXStopAtBorder Then
                .dX = 0
                .bIsAtXBorder = True
                If .bXReverseAtBorder Then lbReverse = True
            Else
                If (.dX + .iXSize < 0) Then .bIsOffScreenX = True
            End If
        End If
        
        'see if we are going to go off the playfield to the bottom
        If ((.dY + .iYSize) > rgGame.iPlayHeight) Then
            If .bYReverseAtBorder Or .bYStopAtBorder Then
                .dY = rgGame.iPlayHeight - .iYSize
                .bIsAtYBorder = True
                If .bYReverseAtBorder Then lbReverse = True
            Else
                If (.dY > rgGame.iPlayHeight) Then .bIsOffScreenY = True
            End If
        'see if we are going to go off the playfield to the top
        ElseIf (.dY < 0) Then
            If .bYReverseAtBorder Or .bYStopAtBorder Then
                .dY = 0
                .bIsAtYBorder = True
                If .bYReverseAtBorder Then lbReverse = True
            Else
                If (.dY + .iYSize < 0) Then .bIsOffScreenY = True
            End If
        End If
        
        If lbReverse Then
            .iDirection = .iDirection + 180
            .dMarched = 0
        End If
    
        .bIsOffScreen = .bIsOffScreenX Or .bIsOffScreenY
        .bIsAtBorder = .bIsAtXBorder Or .bIsAtYBorder
        
    End With
End Sub

'
'============= Actor_Move =============
'
'
'Direction is in degrees
'Velocity is in pixels/second
'rgGame.TicksPassed is milliseconds
'Marching means going back and forth in a line over a specified distance
Public Sub Actor_MoveOLD(raActor As Actor, rgGame As Game)
    'Pixels to move
    Dim ldPixels As Double
    'X,Y factor (-1.0 to 1.0) in movement
    Dim ldXInc As Double
    Dim ldYInc As Double
    'If direction should reverse
    Dim lbReverse As Boolean
    
    With rgGame.udtMovers(raActor.lHMover)
        'Store last position
        .iLastX = .dX
        .iLastY = .dY
        
        'Clear reverse flag
        lbReverse = False
                
        'Accelerate
        Call CalculateNewVelocity(.iVelocity, .iDirection, .iAcceleration, .iAccDirection, rgGame.lTicksPassed)
        'Determine X,Y factor from direction angle (degrees)
        Call GetXYIncFromAngle(.iDirection, ldXInc, ldYInc)
        'Determine distance to move in pixels
        ldPixels = CDbl(.iVelocity * rgGame.lTicksPassed) / 1000
        
        'See if we are marching
        If .iMarchingDistance > 0 Then
            'If we are marching, are we go to march to far?
            If ((.dMarched + ldPixels) > .iMarchingDistance) Then
                'Adjust distance so we do not march to far, and reverse (later)
                ldPixels = .iMarchingDistance - .dMarched
                lbReverse = True
            Else
                'add distance to distance marched so far
                .dMarched = .dMarched + ldPixels
            End If
        End If
        
        'Calculate new X and Y positions
        .dX = .dX + (ldPixels * ldXInc)
        .dY = .dY + (ldPixels * ldYInc)
        
        'clear border flags
        .bIsAtXBorder = False
        .bIsAtYBorder = False
        .bIsOffScreenX = False
        .bIsOffScreenY = False
        
        'see if we are going to go off the playfield to the right
        If ((.dX + raActor.iXSize) > rgGame.iPlayWidth) Then
            'We are partially or fully off the playfield - so we stop or reverse?
            If .bXReverseAtBorder Or .bXStopAtBorder Then
                'WIP: Hmm, shouldn't we check this and then adjust distance afterwords?? or decrement Y same way?
                'don't go off- go to the edge
                .dX = rgGame.iPlayWidth - raActor.iXSize
                .bIsAtXBorder = True
                If .bXReverseAtBorder Then lbReverse = True
            Else
                If (.dX > rgGame.iPlayWidth) Then .bIsOffScreenX = True
            End If
        'see if we are going to go off the playfield to the left
        ElseIf (.dX < 0) Then
            If .bXReverseAtBorder Or .bXStopAtBorder Then
                .dX = 0
                .bIsAtXBorder = True
                If .bXReverseAtBorder Then lbReverse = True
            Else
                If (.dX + raActor.iXSize < 0) Then .bIsOffScreenX = True
            End If
        End If
        
        'see if we are going to go off the playfield to the bottom
        If ((.dY + raActor.iYSize) > rgGame.iPlayHeight) Then
            If .bYReverseAtBorder Or .bYStopAtBorder Then
                .dY = rgGame.iPlayHeight - raActor.iYSize
                .bIsAtYBorder = True
                If .bYReverseAtBorder Then lbReverse = True
            Else
                If (.dY > rgGame.iPlayHeight) Then .bIsOffScreenY = True
            End If
        'see if we are going to go off the playfield to the top
        ElseIf (.dY < 0) Then
            If .bYReverseAtBorder Or .bYStopAtBorder Then
                .dY = 0
                .bIsAtYBorder = True
                If .bYReverseAtBorder Then lbReverse = True
            Else
                If (.dY + raActor.iYSize < 0) Then .bIsOffScreenY = True
            End If
        End If
        
        If lbReverse Then
            .iDirection = .iDirection + 180
            .dMarched = 0
        End If
    
        .bIsOffScreen = .bIsOffScreenX Or .bIsOffScreenY
        .bIsAtBorder = .bIsAtXBorder Or .bIsAtYBorder
        
    End With
End Sub

'
'============= Actor_StartExplosion =============
'
'
Public Sub Actor_StartExplosion(ByRef raActor As Actor)
    raActor.bExploding = True
    With raActor.adDrawer
        .iStartFrame = .iExplosionStartFrame
        .iNumFrames = .iExplosionNumFrames
        .iFramesPerSecond = .iExplosionFramesPerSecond
        .lTicksPerFrame = .lExplosionTicksPerFrame
        .iCurrentFrameInSequence = 0
        .bLoopAnimation = False
    End With
End Sub

'
'============= Actor_Draw =============
'
'
Public Sub Actor_Draw(raActor As Actor, rgGame As Game)
    On Error GoTo Actor_Draw_ErrorHandler
    
    Dim RS As RECT
    Dim RD As RECT
    Dim DXFX As DDBLTFX
    
    Dim liFrameOffsetX As Integer
    Dim liFrameOffsetY As Integer
    Dim liClippedWidth As Integer
    Dim liClippedHeight As Integer
    Dim liFrameNumber As Integer
    Dim liBitMapOffsetX As Integer
    Dim liBitMapOffsetY As Integer
    
    With raActor.adDrawer
        'first part handles off the screen to the left, second normal, third off the screen to the right
        liClippedWidth = MinOfDbl(MinOfDbl(rgGame.iPlayWidth - rgGame.udtMovers(raActor.lHMover).dX, CDbl(raActor.iXSize)), _
                rgGame.udtMovers(raActor.lHMover).dX + raActor.iXSize)
        liClippedHeight = MinOfDbl(MinOfDbl(rgGame.iPlayHeight - rgGame.udtMovers(raActor.lHMover).dY, CDbl(raActor.iYSize)), _
                rgGame.udtMovers(raActor.lHMover).dY + raActor.iYSize)
        
        
        If (liClippedWidth <= 0) Or (liClippedHeight <= 0) Then
            Exit Sub
        End If
        
        liFrameNumber = .iCurrentFrameInSequence + .iStartFrame
        liFrameOffsetX = (liFrameNumber Mod .iWidthInFrames) * .iFrameSizeX
        liFrameOffsetY = Int(liFrameNumber / .iWidthInFrames) * .iFrameSizeY
        
        liBitMapOffsetX = Abs(MinOfDbl(rgGame.udtMovers(raActor.lHMover).dX, 0))
        RS.Left = liBitMapOffsetX + liFrameOffsetX
        RS.Right = liClippedWidth + RS.Left
        liBitMapOffsetY = Abs(MinOfDbl(rgGame.udtMovers(raActor.lHMover).dY, 0))
        RS.Top = liBitMapOffsetY + liFrameOffsetY
        RS.Bottom = liClippedHeight + RS.Top
        
        RD.Left = rgGame.iPlayXOffset + rgGame.udtMovers(raActor.lHMover).dX + liBitMapOffsetX
        RD.Right = RD.Left + liClippedWidth
        RD.Top = rgGame.iPlayYOffset + rgGame.udtMovers(raActor.lHMover).dY + liBitMapOffsetY
        RD.Bottom = RD.Top + liClippedHeight
        
        DXFX.dwSize = Len(DXFX)
        DXFX.ddckSrcColorkey.dwColorSpaceHighValue = 0
        DXFX.ddckSrcColorkey.dwColorSpaceLowValue = 0
        
        .lTicksSinceLastFrame = .lTicksSinceLastFrame + rgGame.lTicksPassed
        If (.lTicksSinceLastFrame >= .lTicksPerFrame) Then
            .lTicksSinceLastFrame = 0
            '.lTicksSinceLastFrame = .lTicksSinceLastFrame - .lTicksPerFrame
            If (.iCurrentFrameInSequence + 1) >= .iNumFrames Then
                If .bAutoSwitchToNextSequence Then
                    .bAutoSwitchToNextSequence = False
                    .iStartFrame = .iNextStartFrame
                    .iNumFrames = .iNextNumFrames
                Else
                    raActor.bIsDoneExploding = raActor.bExploding
                    .bIsAnimationDone = True
                End If
                If .bLoopAnimation Then
                    .iCurrentFrameInSequence = 0
                    .bIsAnimationDone = False
                End If
            Else
                .iCurrentFrameInSequence = .iCurrentFrameInSequence + 1
            End If
        End If
    
'        rgGame.ddsBackBufferSurface.BltFast RD.Left, RD.Top, .ddsBitMapSurface, RS, DDBLTFAST_SRCCOLORKEY
        rgGame.ddsBackBufferSurface.Blt RD, .ddsBitMapSurface, _
                RS, DDBLT_KEYSRCOVERRIDE, DXFX
    End With
    Exit Sub

Actor_Draw_ErrorHandler:
    HandleError Err.Number, Err.Description, Err.LastDllError, Err.source, "Actor_Draw", _
        "  X,Y = " & rgGame.udtMovers(raActor.lHMover).dX & "," & rgGame.udtMovers(raActor.lHMover).dY & vbCrLf & _
        "  RS.Left = " & RS.Left & vbCrLf & _
        "  RS.Right = " & RS.Right & vbCrLf & _
        "  RS.Top = " & RS.Top & vbCrLf & _
        "  RS.Bottom = " & RS.Bottom & vbCrLf & _
        "  RD.Left = " & RD.Left & vbCrLf & _
        "  RD.Right = " & RD.Right & vbCrLf & _
        "  RD.Top = " & RD.Top & vbCrLf & _
        "  RD.Bottom = " & RD.Bottom & vbCrLf
    Exit Sub
End Sub

Public Function Actor_GetPan(raActor As Actor, rgGame As Game) As Double
    Dim liX As Integer
    Dim liPWFactor As Integer
    liPWFactor = rgGame.iPlayWidth / 2
    liX = rgGame.udtMovers(raActor.lHMover).dX + (raActor.iXSize / 2)
    If (liX < 0) Then
        Actor_GetPan = -1#
    ElseIf (liX > rgGame.iPlayWidth) Then
        Actor_GetPan = 1#
    Else
        Actor_GetPan = (liX - liPWFactor) / liPWFactor
    End If
End Function

Function Actor_DetectCollision(rgGame As Game, raActor1 As Actor, raActor2 As Actor) As Boolean
    Dim liX1 As Integer
    Dim liY1 As Integer
    Dim liX2 As Integer
    Dim liY2 As Integer
    Dim lbCollision As Boolean
    Dim lbCheckCollisionBoxes  As Boolean
    Dim liCollisionBoxCtr1 As Integer
    Dim liCollisionBoxCtr2 As Integer
    
    lbCollision = False
    lbCheckCollisionBoxes = False
    
    'determine if we should go into more detail
    If (1 = raActor1.iNumCollisionBoxes) And (1 = raActor2.iNumCollisionBoxes) Then
        'only one collision box per actor, so going into detail
        'doesn't take any longer than checking the outer rectangles.
        lbCheckCollisionBoxes = True
    Else
        'do the larger rectangles intersect?
        liX1 = rgGame.udtMovers(raActor1.lHMover).dX
        liY1 = rgGame.udtMovers(raActor1.lHMover).dY
        liX2 = rgGame.udtMovers(raActor2.lHMover).dX
        liY2 = rgGame.udtMovers(raActor2.lHMover).dY
        If ((liY1 + raActor1.iYSize) >= liY2) And _
                (liY1 < (liY2 + raActor2.iYSize)) Then
            If ((liX1 + raActor1.iXSize) >= liX2) And _
                    (liX1 < (liX2 + raActor2.iXSize)) Then
                'actor rectangles intersect- go into more detail
                lbCheckCollisionBoxes = True
            End If
        End If
    End If
    
    If lbCheckCollisionBoxes Then
        For liCollisionBoxCtr1 = 1 To raActor1.iNumCollisionBoxes
            For liCollisionBoxCtr2 = 1 To raActor2.iNumCollisionBoxes
                liX1 = rgGame.udtMovers(raActor1.lHMover).dX + raActor1.iXCollisionBoxOffset(liCollisionBoxCtr1)
                liY1 = rgGame.udtMovers(raActor1.lHMover).dY + raActor1.iYCollisionBoxOffset(liCollisionBoxCtr1)
                liX2 = rgGame.udtMovers(raActor2.lHMover).dX + raActor2.iXCollisionBoxOffset(liCollisionBoxCtr2)
                liY2 = rgGame.udtMovers(raActor2.lHMover).dY + raActor2.iYCollisionBoxOffset(liCollisionBoxCtr2)
                If ((liY1 + raActor1.iYCollisionBoxSize(liCollisionBoxCtr1)) >= liY2) And _
                        (liY1 < (liY2 + raActor2.iYCollisionBoxSize(liCollisionBoxCtr2))) Then
                    If ((liX1 + raActor1.iXCollisionBoxSize(liCollisionBoxCtr1)) >= liX2) And _
                            (liX1 < (liX2 + raActor2.iXCollisionBoxSize(liCollisionBoxCtr2))) Then
                        'BANG!
                        lbCollision = True
                        Exit For
                    End If
                End If
            Next liCollisionBoxCtr2
            If lbCollision Then Exit For
        Next liCollisionBoxCtr1
    End If
    
    Actor_DetectCollision = lbCollision
End Function

Public Sub PlayerGuns_UpdateState(rpgPlayerGuns As PlayerGuns, rgGame As Game)
    With rpgPlayerGuns
        If Not .bShotReady Then
            .lTicksSinceLastShot = .lTicksSinceLastShot + rgGame.lTicksPassed
            If .lTicksSinceLastShot >= .lRechargeTime Then
                .bShotReady = True
                '.lTicksSinceLastShot = .lTicksSinceLastShot - .lRechargeTime
                .lTicksSinceLastShot = 0
            End If
        End If
    End With
End Sub

'
'============= Actor_DropBomb =============
'
'
Public Function Actor_DropBomb(raBomber As Actor, rgGame As Game, _
        ByRef riNumBombs%, ByVal viMaxBombs%, ByRef raBombs() As Actor, _
        ByVal viHseBombSound%, ByVal veBombDir As BombDir_Enum, _
        raTarget As Actor)
    On Error GoTo Actor_DropBomb_ErrorHandler
    
    If (riNumBombs < viMaxBombs) Then
        riNumBombs = riNumBombs + 1
        With rgGame.udtMovers(raBombs(riNumBombs).lHMover)
            .bActive = True
            .dX = rgGame.udtMovers(raBomber.lHMover).dX + (raBomber.iXSize / 2) - 1 - (raBombs(riNumBombs).iXSize / 2)
            .dY = rgGame.udtMovers(raBomber.lHMover).dY + raBomber.iYSize
            If Not veBombDir = bombDefaultDir Then
                If veBombDir = bombToTarget Then
                    .iDirection = GetAngleFromXY( _
                            (rgGame.udtMovers(raTarget.lHMover).dX + (raTarget.iXSize / 2)) - (rgGame.udtMovers(raBomber.lHMover).dX + (raBomber.iXSize / 2)), _
                            (rgGame.udtMovers(raTarget.lHMover).dY + (raTarget.iYSize / 2)) - (rgGame.udtMovers(raBomber.lHMover).dY + (raBomber.iYSize / 2)) _
                    )
                ElseIf veBombDir = bombStraightDown Then
                    .iDirection = 90
                ElseIf veBombDir = bombStraightUp Then
                    .iDirection = 270
                End If
            End If
            
        End With
        
        If viHseBombSound > -1 Then
'            Call DirectSound_PlaySoundEffect(viHseBombSound, 0&, _
                    Actor_GetPan(maAlienABombs(miNumAlienABombs), rgGame))
            Call General_PlaySound(viHseBombSound, False)
          End If
    End If

    Exit Function
    
Actor_DropBomb_ErrorHandler:
    HandleError Err.Number, Err.Description, Err.LastDllError, Err.source, "Actor_DropBomb"
End Function

'
'============= Actor_CheckMissleCollision =============
'
'
Public Function Actor_CheckMissleCollision(ByRef raActor As Actor, ByRef raMissles() As Actor, _
        ByRef riNumMissles As Integer, rgGame As Game) As Boolean
    Dim lbCollision As Boolean
    Dim liMisslesIdx As Integer
    
    lbCollision = False
    liMisslesIdx = 1
    
    'check for collision against each missle (until one is detected)
    Do While (liMisslesIdx <= riNumMissles)
        If Actor_DetectCollision(rgGame, raActor, raMissles(liMisslesIdx)) Then
            'BANG!
            lbCollision = True
            
            'Play collision sound
            If (raActor.iHseCollisionSound > 0) Then
'                Call DirectSound_PlaySoundEffect(raActor.iHseCollisionSound, 0&, _
                        Actor_GetPan(raActor, rgGame))
                Call General_PlaySound(raActor.iHseCollisionSound, False)
            End If
            
            'Get rid of the missle
            DeleteActorArrayElement rgGame, raMissles, liMisslesIdx, riNumMissles
            
            'Update the score
            rgGame.lScore = rgGame.lScore + raActor.lPoints
            rgGame.lBonus = rgGame.lBonus + raActor.lBonusPoints
            
            'show points for this guy?
            
            'Turn into an explosion
            Call Actor_StartExplosion(raActor)
            
            'collision- don't check any more missles
            Exit Do
        End If
        liMisslesIdx = liMisslesIdx + 1
    Loop 'missles

    Actor_CheckMissleCollision = lbCollision
End Function



