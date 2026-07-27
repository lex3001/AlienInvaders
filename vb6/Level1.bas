Attribute VB_Name = "modLevel1"
Option Explicit

'Direct draw resources for animation bitmaps
Dim mddsAlienA As IDirectDrawSurface2
Dim mddsAlienB As IDirectDrawSurface2
Dim mddsAlienABomb As IDirectDrawSurface2
Dim mddsAlienC As IDirectDrawSurface2
Dim mddsAlienD As IDirectDrawSurface2
Dim mddsAlienE As IDirectDrawSurface2
Dim mddsAlienDBomb As IDirectDrawSurface2
Dim mddsPlayer As IDirectDrawSurface2
Dim mddsMissle As IDirectDrawSurface2
Dim mddsPlanet As IDirectDrawSurface2
Dim mddsXBonus As IDirectDrawSurface2

Dim miHseMissle As Integer
Dim miHseExplosion As Integer

'Player guns
Dim mpgPlayerGuns As PlayerGuns

'Actors
Dim maPlayer As Actor
Dim maPlanet As Actor
Dim maXBonus As Actor
Dim maMissles() As Actor
Dim maAliensA() As Actor
Dim maAliensB() As Actor
Dim maAliensC() As Actor
Dim maAliensD() As Actor
Dim maAliensE1() As Actor
Dim maAliensE2() As Actor
Dim maAlienABombs() As Actor
Dim maAlienDBombs() As Actor
Const miMAX_ALIENA_BOMBS% = 25
Const mlALIENA_BOMB_INTERVAL& = 4000 'each AlienA drops a bomb avg every 5 sec.
Const miALIENC_ATTACK_RANGE% = 48 'when centers of alien/player within 48 pixels left/right
Const mlALIENC_ATTACK_INTERVAL& = 8000 'chance one in ten seconds that it will drop when in range
Const miMAX_ALIEND_BOMBS% = 25
Const mlALIEND_BOMB_INTERVAL& = 5000 'each AlienA drops a bomb avg every 5 sec.
Const mlALIENE_ATTACK_INTERVAL& = 15000 'idle alienE attacks avg every 15 sec
Const mlALIENE_ATTACK_TURN_INTERVAL& = 3500 'idle alienE attacks avg every 8 sec
Const mbALIENE_ATTACK_TURN_INTERVAL_FIX = True 'idle alienE attacks avg every 8 sec
Const mlALIENE1_BOMB_INTERVAL& = 10000 'idle alienE drops bomb avg every 10 sec
Const mlALIENE2_BOMB_INTERVAL& = 2000 'bombing alienE drops bomb avg every 1 sec
Const mlPLANET_INTERVAL& = 15000
Const mlPLANET_DURATION& = 5000

Dim miNumMissles As Integer
Dim miNumAlienABombs As Integer
Dim miNumAlienDBombs As Integer
Dim miNumAliensA As Integer
Dim miMaxAliensA As Integer
Dim miNumAliensB As Integer
Dim miMaxAliensB As Integer
Dim miNumAliensC As Integer
Dim miMaxAliensC As Integer
Dim miNumAliensD As Integer
Dim miMaxAliensD As Integer
Dim miNumAliensE As Integer
Dim miMaxAliensE As Integer

Dim mbMissleRequested As Boolean
Dim mbShieldsRequested As Boolean
Dim mbShieldsOn As Boolean

Public Sub Level1_UpdateAndDraw(rgGame As Game)
    Call Level1_CheckInput(rgGame)
    Call Level1_HandleMissles(rgGame)
    Call Level1_HandleAlienABombs(rgGame)
    Call Level1_HandleAlienDBombs(rgGame)
    Call Level1_HandleAliensA(rgGame)
    Call Level1_HandleAliensB(rgGame)
    Call Level1_HandleAliensC(rgGame)
    Call Level1_HandleAliensD(rgGame)
    Call Level1_HandleAliensE(rgGame)
    Call Level1_HandlePlanet(rgGame)
    Call Level1_HandleXBonus(rgGame)
    Call Level1_HandlePlayer(rgGame)
    
    Dim llHMover As Long
    llHMover = FAM_StartIteration(rgGame.famMovers)
    Do While llHMover > 0
        Call ActorMover_Move(rgGame.udtMovers(llHMover), rgGame)
        llHMover = FAM_NextIteration(rgGame.famMovers)
    Loop
    
    If (miNumAliensA <= 0) And (miNumAliensC <= 0) And _
        (miNumAliensD <= 0) And (miNumAliensE <= 0) Then
        rgGame.bIsLevelComplete = True
    End If
End Sub

Private Sub Level1_HandleMissles(rgGame As Game)
    On Error GoTo Level1_HandleMissles_ErrorHandler
    
    'Draw Missles then Update
    Dim liMissleIdx As Integer
    
    liMissleIdx = 1
    Do While (liMissleIdx <= miNumMissles)
        Call Actor_Draw(maMissles(liMissleIdx), rgGame)
'        Call Actor_Move(maMissles(liMissleIdx), rgGame)
        
        If (rgGame.udtMovers(maMissles(liMissleIdx).lHMover).bIsOffScreen) Then
            'Get rid of the missle
            DeleteActorArrayElement rgGame, maMissles, liMissleIdx, miNumMissles
        Else
            liMissleIdx = liMissleIdx + 1
        End If
    Loop
        
    'update state of player's guns
    Call PlayerGuns_UpdateState(mpgPlayerGuns, rgGame)
    
    'see if we should launch a missle
    If (mbMissleRequested) And (mpgPlayerGuns.bShotReady) Then
        If (miNumMissles < mpgPlayerGuns.iMaxOnScreen) Then
            mpgPlayerGuns.bShotReady = False
            miNumMissles = miNumMissles + 1
            With rgGame.udtMovers(maMissles(miNumMissles).lHMover)
                .bActive = True
                .dX = rgGame.udtMovers(maPlayer.lHMover).dX + (maPlayer.iXSize / 2) - 1
                .dY = rgGame.udtMovers(maPlayer.lHMover).dY
            End With
            
'            Call DirectSound_PlaySoundEffect(miHseMissle, 0&, _
'                    Actor_GetPan(maMissles(miNumMissles), rgGame))
            Call General_PlaySound(miHseMissle, False)
'            Call DirectSound_PlaySoundEffect(miHseMissle)
            'PLAY SOUND!
            
        End If
    End If

    Exit Sub
    
Level1_HandleMissles_ErrorHandler:
    HandleError Err.Number, Err.Description, Err.LastDllError, Err.source, "Level1_HandleMissles"
End Sub

Private Sub Level1_HandlePlayer(rgGame As Game)
    On Error GoTo Level1_HandlePlayer_ErrorHandler
    
    If rgGame.bIsPlayerDead Then Exit Sub
    
    'Draw Player
    Call Actor_Draw(maPlayer, rgGame)

    'See if an exploding player is done exploding
    If maPlayer.bExploding And _
            maPlayer.adDrawer.bIsAnimationDone Then
        rgGame.bIsPlayerDead = True
    ElseIf Not maPlayer.bExploding Then
        'check shields
        If mbShieldsOn Then
            With rgGame
                .lShieldsLeft = .lShieldsLeft - .lTicksPassed
                If (.lShieldsLeft < 0) Then .lShieldsLeft = 0
            End With
        End If
        
        'ignore shields request if shields are out
        If mbShieldsRequested Then
            If (rgGame.lShieldsLeft <= 0) Then mbShieldsRequested = False
        End If
        
        'determine if action needs to be taken with shields
        If Not (mbShieldsRequested = mbShieldsOn) Then
            mbShieldsOn = mbShieldsRequested
            If mbShieldsOn Then
                maPlayer.adDrawer.iCurrentFrameInSequence = 0
                maPlayer.adDrawer.iNumFrames = 4
                maPlayer.adDrawer.iStartFrame = 4
            Else
                maPlayer.adDrawer.iCurrentFrameInSequence = 0
                maPlayer.adDrawer.iNumFrames = 1
                maPlayer.adDrawer.iStartFrame = 0
            End If
        End If
        
        'Move Player
        'Call Actor_Move(maPlayer, rgGame)
    End If
        
    Exit Sub
    
Level1_HandlePlayer_ErrorHandler:
    HandleError Err.Number, Err.Description, Err.LastDllError, Err.source, "Level1_HandlePlayer"
End Sub

Private Sub Level1_HandlePlanet(rgGame As Game)
    On Error GoTo Level1_HandlePlanet_ErrorHandler
    Dim liSaveCurrentFrame  As Integer
    
    With maPlanet
        'already been displayed?
        If .lState1 < 0 Then
            Exit Sub
        'not displayed yet? Randomly happen in the first X seconds
        ElseIf .lState1 < mlPLANET_INTERVAL& Then
            .lState1 = .lState1 + rgGame.lTicksPassed
            'For the Rnd, I think we need an exponential function..
            If Rnd < (rgGame.lTicksPassed / mlPLANET_INTERVAL&) Then
                .lState1 = mlPLANET_INTERVAL&
                .lState2 = 0
            End If
        Else
            'Draw Planet
            Call Actor_Draw(maPlanet, rgGame)

            If Not (.lState2 < 0) Then
                .lState2 = .lState2 + rgGame.lTicksPassed
                If .lState2 > mlPLANET_DURATION& Then
                    'this is a trick to make it dissapear but allow player to shoot it still
                    Actor_StartExplosion maPlanet
                    maPlanet.bExploding = False
                    .lState2 = -1
                End If
            ElseIf .adDrawer.bIsAnimationDone Then
                .lState1 = -1
            End If
            
            If Not .bExploding Then
                'Planet hit?
                If .lState2 < 0 Then liSaveCurrentFrame = .adDrawer.iCurrentFrameInSequence
                If Actor_CheckMissleCollision(maPlanet, maMissles(), miNumMissles, rgGame) Then
                    Call AddBonus(Int(maPlanet.lBonusPoints / 100) - 1, rgGame.udtMovers(maPlanet.lHMover).dX, _
                            rgGame.udtMovers(maPlanet.lHMover).dY)
                    If .lState2 < 0 Then .adDrawer.iCurrentFrameInSequence = liSaveCurrentFrame
                    .lState2 = -1
                End If
            End If
        
            'See if an exploding actor is done exploding
            If maPlanet.bIsDoneExploding Then .lState1 = -1
            
            'Move Planet
            'Call Actor_Move(maPlanet, rgGame)
        End If
            
    End With
        
    Exit Sub
    
Level1_HandlePlanet_ErrorHandler:
    HandleError Err.Number, Err.Description, Err.LastDllError, Err.source, "Level1_HandlePlanet"
End Sub

Private Sub Level1_HandleXBonus(rgGame As Game)
    On Error GoTo Level1_HandleXBonus_ErrorHandler
    Dim liSaveCurrentFrame  As Integer
    Dim liMultiplier As Integer
    
    With maXBonus
        'already been displayed?
        If .lState1 < 0 Then
            Exit Sub
        'not displayed yet? Randomly happen in the first X seconds
        ElseIf .lState1 < mlPLANET_INTERVAL& Then
            .lState1 = .lState1 + rgGame.lTicksPassed
            'For the Rnd, I think we need an exponential function..
            If Rnd < (rgGame.lTicksPassed / mlPLANET_INTERVAL&) Then
                .lState1 = mlPLANET_INTERVAL&
                .lState2 = 0
                .adDrawer.iStartFrame = Int(Rnd * 4)
            End If
        Else
            'Draw XBonus
            Call Actor_Draw(maXBonus, rgGame)

            .lState2 = .lState2 + rgGame.lTicksPassed
            If .lState2 > mlPLANET_DURATION& Then
                .lState1 = -1
            End If
            
            'XBonus hit?
            liMultiplier = .adDrawer.iStartFrame + 2
            If Actor_CheckMissleCollision(maXBonus, maMissles(), miNumMissles, rgGame) Then
                rgGame.iBonusMultiplier = liMultiplier
                .lState1 = -1
            End If
        
            'Move XBonus
            'Call Actor_Move(maXBonus, rgGame)
        End If
            
    End With
        
    Exit Sub
    
Level1_HandleXBonus_ErrorHandler:
    HandleError Err.Number, Err.Description, Err.LastDllError, Err.source, "Level1_HandleXBonus"
End Sub

Private Sub Level1_HandleAliensA(rgGame As Game)
    On Error GoTo Level1_HandleAliensA_ErrorHandler
    
    Dim liAlienIdx As Integer
    Dim liMisslesIdx As Integer
    
    'Draw BadGuys then Update
    liAlienIdx = 1
    Do While (liAlienIdx <= miNumAliensA)
        'Draw Alien
        Call Actor_Draw(maAliensA(liAlienIdx), rgGame)
        
        'If this alien is not exploding...
        If (Not maAliensA(liAlienIdx).bExploding) Then
            'See if it should drop a bomb
'            If Rnd < (rgGame.lTicksPassed / mlALIENA_BOMB_INTERVAL&) Then
'                Call Level1_DropAlienABomb(maAliensA(liAlienIdx), rgGame)
'            End If
        
            'See if it hit a missle
            liMisslesIdx = 1
            Do While (liMisslesIdx <= miNumMissles)
                If Actor_DetectCollision(rgGame, maAliensA(liAlienIdx), maMissles(liMisslesIdx)) Then
                    'BANG!
'                    Call DirectSound_PlaySoundEffect(miHseExplosion, 0&, _
'                            Actor_GetPan(maAliensA(liAlienIdx), rgGame))
                    Call General_PlaySound(miHseExplosion, False)
                    
                    'Get rid of the missle
                    DeleteActorArrayElement rgGame, maMissles, liMisslesIdx, miNumMissles
                    
                    'Update the score
                    rgGame.lScore = rgGame.lScore + 10
                    
                    'Turn the alien into an explosion
                    maAliensA(liAlienIdx).bExploding = True
                    With maAliensA(liAlienIdx).adDrawer
                        .iStartFrame = 20
                        .iNumFrames = 8
                        .iFramesPerSecond = -1 'use TicksPerFrame
                        .lTicksPerFrame = 40
                        .iCurrentFrameInSequence = 0
                        .bLoopAnimation = False
                    End With
                    
                    'collision- don't check any more missles
                    Exit Do
                End If
                liMisslesIdx = liMisslesIdx + 1
            Loop 'missles
        End If

        'See if an exploding alien is done exploding
        If maAliensA(liAlienIdx).bExploding And _
                maAliensA(liAlienIdx).adDrawer.bIsAnimationDone Then
            'get rid of it
            DeleteActorArrayElement rgGame, maAliensA, liAlienIdx, miNumAliensA
        Else
            'Update Alien Position
            'Call Actor_Move(maAliensA(liAlienIdx), rgGame)
            liAlienIdx = liAlienIdx + 1
        End If
        
    Loop 'aliens
        
    Exit Sub
    
Level1_HandleAliensA_ErrorHandler:
    HandleError Err.Number, Err.Description, Err.LastDllError, Err.source, "Level1_HandleAliensA"
End Sub

Private Sub Level1_HandleAliensB(rgGame As Game)
    On Error GoTo Level1_HandleAliensB_ErrorHandler
    
    Dim liAlienIdx As Integer
    Dim liMisslesIdx As Integer
    
    'Draw BadGuys then Update
    liAlienIdx = 1
    Do While (liAlienIdx <= miNumAliensB)
        'Draw Alien
        Call Actor_Draw(maAliensB(liAlienIdx), rgGame)
        
        'If this alien is not exploding...
        If (Not maAliensB(liAlienIdx).bExploding) Then
        
            'See if it hit a missle
            liMisslesIdx = 1
            Do While (liMisslesIdx <= miNumMissles)
                If Actor_DetectCollision(rgGame, maAliensB(liAlienIdx), maMissles(liMisslesIdx)) Then
                    'BANG!
'                    Call DirectSound_PlaySoundEffect(miHseExplosion, 0&, _
'                            Actor_GetPan(maAliensB(liAlienIdx), rgGame))
                    Call General_PlaySound(miHseExplosion, False)
                    
                    'Get rid of the missle
                    DeleteActorArrayElement rgGame, maMissles, liMisslesIdx, miNumMissles
                    
                    
'================================
                    With maAliensB(liAlienIdx)
                        .lState1 = .lState1 + 1
                        If .lState1 > 3 Then
                            'Turn the alien into an explosion
                            maAliensB(liAlienIdx).bExploding = True
                            With .adDrawer
                                .bAutoSwitchToNextSequence = False
                                .iStartFrame = 56
                                .iNumFrames = 8
                                .iFramesPerSecond = -1 'use TicksPerFrame
                                .lTicksPerFrame = 40
                                .iCurrentFrameInSequence = 0
                                .bLoopAnimation = False
                            End With
                            'Update the score
                            rgGame.lScore = rgGame.lScore + 5
                        Else
                            'Transition alien to next state
                            With .adDrawer
                                .bAutoSwitchToNextSequence = True
                                .iStartFrame = ((maAliensB(liAlienIdx).lState1 * 2) - 1) * 8
                                .iNumFrames = 8
                                .iNextStartFrame = (maAliensB(liAlienIdx).lState1 * 2) * 8
                                .iNextNumFrames = 8
                                .iCurrentFrameInSequence = 0
                                .bLoopAnimation = True
                            End With
                            'Update the score
                            rgGame.lScore = rgGame.lScore + 10
                        End If
                    End With
                    
                    'collision- don't check any more missles
                    Exit Do
                End If
                
                liMisslesIdx = liMisslesIdx + 1
            Loop 'missles
        End If

        'See if an exploding alien is done exploding
        If maAliensB(liAlienIdx).bExploding And _
                maAliensB(liAlienIdx).adDrawer.bIsAnimationDone Then
            'get rid of it
            DeleteActorArrayElement rgGame, maAliensB, liAlienIdx, miNumAliensB
        Else
            'Update Alien Position
            'Call Actor_Move(maAliensB(liAlienIdx), rgGame)
            liAlienIdx = liAlienIdx + 1
        End If
        
    Loop 'aliens
        
    Exit Sub
    
Level1_HandleAliensB_ErrorHandler:
    HandleError Err.Number, Err.Description, Err.LastDllError, Err.source, "Level1_HandleAliensB"
End Sub

Private Sub Level1_HandleAliensC(rgGame As Game)
    On Error GoTo Level1_HandleAliensC_ErrorHandler
    
    Dim liAlienIdx As Integer
    Dim liMisslesIdx As Integer
    Dim liPlayerX As Integer
    Dim liAlienX As Integer
    Dim lbExplodeAlien As Boolean
    
    'Draw BadGuys then Update
    liAlienIdx = 1
    Do While (liAlienIdx <= miNumAliensC)
        'Draw Alien
        Call Actor_Draw(maAliensC(liAlienIdx), rgGame)
        
        'If this alien is not exploding...
        If (Not maAliensC(liAlienIdx).bExploding) Then
            'Determine center of alien and player (in horizontal)
            liPlayerX = rgGame.udtMovers(maPlayer.lHMover).dX + (maPlayer.iXSize / 2)
            liAlienX = rgGame.udtMovers(maAliensC(liAlienIdx).lHMover).dX + (maAliensC(liAlienIdx).iXSize / 2)
            
            'if alien is idle
            If maAliensC(liAlienIdx).lState1 < 1 Then
                If Abs(liAlienX - liPlayerX) < miALIENC_ATTACK_RANGE% Then
                    If Rnd < (rgGame.lTicksPassed / mlALIENC_ATTACK_INTERVAL&) Then
                        maAliensC(liAlienIdx).lState1 = 1
                        With maAliensC(liAlienIdx).adDrawer
                            .bAutoSwitchToNextSequence = False
                            .bLoopAnimation = True
                            .iCurrentFrameInSequence = 0
                            .iNumFrames = 8
                            .iStartFrame = IIf(liAlienX < liPlayerX, 8, 16)
                        End With
                        With rgGame.udtMovers(maAliensC(liAlienIdx).lHMover)
                            .iMarchingDistance = -1
                            .iDirection = 90
                            .iVelocity = 80
                            .iAccDirection = IIf(liAlienX < liPlayerX, 0, 180)
                            .iAcceleration = 500
                            .bYStopAtBorder = True
                            .bXStopAtBorder = False
                        End With
                    End If 'decided to attack
                End If 'in range
            Else 'alien is attacking
                rgGame.udtMovers(maAliensC(liAlienIdx).lHMover).iAccDirection = IIf(liAlienX < liPlayerX, 0, 180)
                maAliensC(liAlienIdx).adDrawer.iStartFrame = IIf(liAlienX < liPlayerX, 8, 16)
            End If 'alien is idle/attacking
        
            lbExplodeAlien = False
            
            'if attacking and hit the bottom of the screen then blow it up
            If ((maAliensC(liAlienIdx).lState1 = 1) And _
                    (rgGame.udtMovers(maAliensC(liAlienIdx).lHMover).bIsAtYBorder)) Then
                lbExplodeAlien = True
            Else
                'See if a missle hit it
                liMisslesIdx = 1
                Do While (liMisslesIdx <= miNumMissles)
                    If Actor_DetectCollision(rgGame, maAliensC(liAlienIdx), maMissles(liMisslesIdx)) Then
                        lbExplodeAlien = True
                        
                        'Get rid of the missle
                        DeleteActorArrayElement rgGame, maMissles, liMisslesIdx, miNumMissles
                        
                        'collision- don't check any more missles
                        Exit Do
                    End If
                    
                    liMisslesIdx = liMisslesIdx + 1
                Loop 'missles
            End If
        
            'explode the alien?
            If lbExplodeAlien Then
                'BANG!
'                Call DirectSound_PlaySoundEffect(miHseExplosion, 0&, _
'                        Actor_GetPan(maAliensC(liAlienIdx), rgGame))
                Call General_PlaySound(miHseExplosion, False)
                
                With maAliensC(liAlienIdx)
                    'Turn the alien into an explosion
                    .bExploding = True
                    With .adDrawer
                        .iStartFrame = 24
                        .iNumFrames = 8
                        .iFramesPerSecond = -1 'use TicksPerFrame
                        .lTicksPerFrame = 40
                        .iCurrentFrameInSequence = 0
                        .bLoopAnimation = False
                    End With
                    'Update the score
                    'worth more points if it was attacking - hmm... draw score on screen?
                    rgGame.lScore = rgGame.lScore + 10
                    If .lState1 = 1 Then
                        If (rgGame.udtMovers(maAliensC(liAlienIdx).lHMover).bIsAtYBorder) Then
                            rgGame.lBonus = rgGame.lBonus + 50 'bonus for avoiding attacker
                            Call AddBonus(11, rgGame.udtMovers(maAliensC(liAlienIdx).lHMover).dX, _
                                    rgGame.udtMovers(maAliensC(liAlienIdx).lHMover).dY)
                        Else
                            rgGame.lBonus = rgGame.lBonus + 25 'bonus for avoiding attacker
                            Call AddBonus(10, rgGame.udtMovers(maAliensC(liAlienIdx).lHMover).dX, _
                                    rgGame.udtMovers(maAliensC(liAlienIdx).lHMover).dY)
                        End If
                    End If
                End With
            End If
        
            'see if the alien hit the player
            If (Not maAliensC(liAlienIdx).bExploding) And (Not maPlayer.bExploding) And _
                    (Actor_DetectCollision(rgGame, maAliensC(liAlienIdx), maPlayer)) Then
                If Level1_HandlePlayerCollision(rgGame) Then
                    'player hit!
                Else
                    'player had shields on
                    rgGame.lScore = rgGame.lScore + 5
                End If
                'blow up alien
                With maAliensC(liAlienIdx)
                    'Turn the alien into an explosion
                    .bExploding = True
                    With .adDrawer
                        .iStartFrame = 24
                        .iNumFrames = 8
                        .iFramesPerSecond = -1 'use TicksPerFrame
                        .lTicksPerFrame = 40
                        .iCurrentFrameInSequence = 0
                        .bLoopAnimation = False
                    End With
                End With
            End If 'collision with player
        
        End If

        'See if an exploding alien is done exploding
        'if it is exploding or it is off the screen after an attack attempt
        If (maAliensC(liAlienIdx).bExploding And _
                maAliensC(liAlienIdx).adDrawer.bIsAnimationDone) Then
            'get rid of it
            DeleteActorArrayElement rgGame, maAliensC, liAlienIdx, miNumAliensC
        Else
            If Not maAliensC(liAlienIdx).bExploding Then
                'Update Alien Position
                'Call Actor_Move(maAliensC(liAlienIdx), rgGame)
            End If
            liAlienIdx = liAlienIdx + 1
        End If
            
    Loop 'aliens
        
    Exit Sub
    
Level1_HandleAliensC_ErrorHandler:
    HandleError Err.Number, Err.Description, Err.LastDllError, Err.source, "Level1_HandleAliensC"
End Sub

Private Sub Level1_HandleAliensD(rgGame As Game)
    On Error GoTo Level1_HandleAliensD_ErrorHandler
    
    Dim liAlienIdx As Integer
    Dim liMisslesIdx As Integer
    
    'Draw BadGuys then Update
    liAlienIdx = 1
    Do While (liAlienIdx <= miNumAliensD)
        'Draw Alien
        Call Actor_Draw(maAliensD(liAlienIdx), rgGame)
        
        'If this alien is not exploding...
        If (Not maAliensD(liAlienIdx).bExploding) Then
            'See if it should drop a bomb
            maAliensD(liAlienIdx).lState1 = maAliensD(liAlienIdx).lState1 + rgGame.lTicksPassed
            If maAliensD(liAlienIdx).lState1 >= mlALIEND_BOMB_INTERVAL& Then
                maAliensD(liAlienIdx).lState1 = 0
                Call Actor_DropBomb(maAliensD(liAlienIdx), rgGame, _
                    miNumAlienDBombs, miMAX_ALIEND_BOMBS, maAlienDBombs, _
                    -1, bombToTarget, maPlayer)
            End If
        
            'See if it hit a missle
            liMisslesIdx = 1
            Do While (liMisslesIdx <= miNumMissles)
                If Actor_DetectCollision(rgGame, maAliensD(liAlienIdx), maMissles(liMisslesIdx)) Then
                    'BANG!
'                    Call DirectSound_PlaySoundEffect(miHseExplosion, 0&, _
'                            Actor_GetPan(maAliensD(liAlienIdx), rgGame))
                    Call General_PlaySound(miHseExplosion, False)
                    
                    'Get rid of the missle
                    DeleteActorArrayElement rgGame, maMissles, liMisslesIdx, miNumMissles
                    
                    'Update the score
                    rgGame.lScore = rgGame.lScore + 25
                    
                    'Turn the alien into an explosion
                    maAliensD(liAlienIdx).bExploding = True
                    With maAliensD(liAlienIdx).adDrawer
                        .iStartFrame = 20
                        .iNumFrames = 8
                        .iFramesPerSecond = -1 'use TicksPerFrame
                        .lTicksPerFrame = 50
                        .iCurrentFrameInSequence = 0
                        .bLoopAnimation = False
                    End With
                    
                    'collision- don't check any more missles
                    Exit Do
                End If
                liMisslesIdx = liMisslesIdx + 1
            Loop 'missles
        End If

        'See if an exploding alien is done exploding
        If maAliensD(liAlienIdx).bExploding And _
                maAliensD(liAlienIdx).adDrawer.bIsAnimationDone Then
            'get rid of it
            DeleteActorArrayElement rgGame, maAliensD, liAlienIdx, miNumAliensD
        Else
            'Update Alien Position
            'Call Actor_Move(maAliensD(liAlienIdx), rgGame)
            liAlienIdx = liAlienIdx + 1
        End If
        
    Loop 'aliens
        
    Exit Sub
    
Level1_HandleAliensD_ErrorHandler:
    HandleError Err.Number, Err.Description, Err.LastDllError, Err.source, "Level1_HandleAliensD"
End Sub

Private Sub Level1_HandleAliensE(rgGame As Game)
    On Error GoTo Level1_HandleAliensE_ErrorHandler
    
    Dim liAlienIdx As Integer
    Dim liMisslesIdx As Integer
    Dim lbExploding As Boolean
    Dim lbIsAnimationDone  As Boolean
    Dim liBomberExplosionNumber As Integer
    
    'Draw BadGuys then Update
    liAlienIdx = 1
    Do While (liAlienIdx <= miNumAliensE)
        'Draw Alien
        If maAliensE1(liAlienIdx).lState1 = 0 Then 'not bombing
            'NORMAL [NOT BOMBING] ALIENE1
            Call Actor_Draw(maAliensE1(liAlienIdx), rgGame)
            lbExploding = maAliensE1(liAlienIdx).bExploding
            lbIsAnimationDone = maAliensE1(liAlienIdx).adDrawer.bIsAnimationDone
            If Not lbExploding Then
                'See if it should drop a bomb
                If Rnd < (rgGame.lTicksPassed / mlALIENE1_BOMB_INTERVAL&) Then
'                    Call Level1_DropAlienABomb(maAliensE1(liAlienIdx), rgGame)
                    Call Actor_DropBomb(maAliensE1(liAlienIdx), rgGame, _
                        miNumAlienABombs, miMAX_ALIENA_BOMBS, maAlienABombs, _
                        -1, bombDefaultDir, maPlayer)
                End If
            
                'See if it hit a missle
                liMisslesIdx = 1
                Do While (liMisslesIdx <= miNumMissles)
                    If Actor_DetectCollision(rgGame, maAliensE1(liAlienIdx), maMissles(liMisslesIdx)) Then
                        'BANG!
'                        Call DirectSound_PlaySoundEffect(miHseExplosion, 0&, _
'                                Actor_GetPan(maAliensE1(liAlienIdx), rgGame))
                        Call General_PlaySound(miHseExplosion, False)
                        
                        'Get rid of the missle
                        DeleteActorArrayElement rgGame, maMissles, liMisslesIdx, miNumMissles
                        
                        'Update the score
                        rgGame.lScore = rgGame.lScore + 10
                        
                        'Turn the alien into an explosion
                        lbExploding = True
                        lbIsAnimationDone = False
                        maAliensE1(liAlienIdx).bExploding = True
                        With maAliensE1(liAlienIdx).adDrawer
                            .bAutoSwitchToNextSequence = False
                            .iStartFrame = 16
                            .iNumFrames = 8
                            .iFramesPerSecond = -1 'use TicksPerFrame
                            .lTicksPerFrame = 40
                            .iCurrentFrameInSequence = 0
                            .bLoopAnimation = False
                        End With
                        
                        'collision- don't check any more missles
                        Exit Do
                    End If
                    liMisslesIdx = liMisslesIdx + 1
                Loop 'missles
                
                If (Not lbExploding) And _
                        (Rnd < (rgGame.lTicksPassed / mlALIENE_ATTACK_INTERVAL&)) Then
                    'attack
                    maAliensE1(liAlienIdx).lState1 = CInt(Rnd * 2) + 1
                    maAliensE2(liAlienIdx).lState1 = 0
                    With rgGame.udtMovers(maAliensE2(liAlienIdx).lHMover)
                        .dX = rgGame.udtMovers(maAliensE1(liAlienIdx).lHMover).dX
                        .dY = rgGame.udtMovers(maAliensE1(liAlienIdx).lHMover).dY
                        .iDirection = IIf(1 = maAliensE1(liAlienIdx).lState1, 135, 45)
                    End With
                    With maAliensE2(liAlienIdx).adDrawer
                        .bAutoSwitchToNextSequence = False
                        .bIsAnimationDone = False
                        .bLoopAnimation = True
                        .iStartFrame = IIf(1 = maAliensE1(liAlienIdx).lState1, 16, 24)
                        .iNumFrames = 8
                        .iCurrentFrameInSequence = CInt(Rnd * .iNumFrames)
                    End With
                End If
            End If
        
        Else 'BOMBING ALIENE2
            Call Actor_Draw(maAliensE2(liAlienIdx), rgGame)
            lbExploding = maAliensE2(liAlienIdx).bExploding
            lbIsAnimationDone = maAliensE2(liAlienIdx).adDrawer.bIsAnimationDone
            If Not lbExploding Then
                'See if it should drop a bomb
                If Rnd < (rgGame.lTicksPassed / mlALIENE2_BOMB_INTERVAL&) Then
'                    Call Level1_DropAlienABomb(maAliensE2(liAlienIdx), rgGame)
                    Call Actor_DropBomb(maAliensE2(liAlienIdx), rgGame, _
                        miNumAlienABombs, miMAX_ALIENA_BOMBS, maAlienABombs, _
                        -1, bombDefaultDir, maPlayer)
                End If
            
                'See if it hit a missle
                liMisslesIdx = 1
                Do While (liMisslesIdx <= miNumMissles)
                    If Actor_DetectCollision(rgGame, maAliensE2(liAlienIdx), maMissles(liMisslesIdx)) Then
                        'BANG!
'                        Call DirectSound_PlaySoundEffect(miHseExplosion, 0&, _
'                                Actor_GetPan(maAliensE2(liAlienIdx), rgGame))
                        Call General_PlaySound(miHseExplosion, False)
                        
                        'Get rid of the missle
                        DeleteActorArrayElement rgGame, maMissles, liMisslesIdx, miNumMissles
                        
                        'Update the score
                        rgGame.lScore = rgGame.lScore + 50
                        Call AddBonus(11, rgGame.udtMovers(maAliensE2(liAlienIdx).lHMover).dX, _
                                rgGame.udtMovers(maAliensE2(liAlienIdx).lHMover).dY)
                        
                        'which explosion?
                        Select Case maAliensE1(liAlienIdx).lState1
                            Case 2: liBomberExplosionNumber = 1
                            Case 3: 'transition from 1 to 2
                                liBomberExplosionNumber = IIf( _
                                        maAliensE2(liAlienIdx).adDrawer.iCurrentFrameInSequence < 2, 1, 2)
                            Case 4: 'transition from 2 to 1
                                liBomberExplosionNumber = IIf( _
                                        maAliensE2(liAlienIdx).adDrawer.iCurrentFrameInSequence < 2, 2, 1)
                            Case Else: liBomberExplosionNumber = 1
                        End Select
                        
                        'Turn the alien into an explosion
                        lbExploding = True
                        lbIsAnimationDone = False
                        maAliensE2(liAlienIdx).bExploding = True
                        With maAliensE2(liAlienIdx).adDrawer
                            .bAutoSwitchToNextSequence = False
                            .iStartFrame = IIf(liBomberExplosionNumber = 1, 40, 48)
                            .iNumFrames = 8
                            .iFramesPerSecond = -1 'use TicksPerFrame
                            .lTicksPerFrame = 40
                            .iCurrentFrameInSequence = 0
                            .bLoopAnimation = False
                        End With
                        
                        'collision- don't check any more missles
                        Exit Do
                    End If
                    liMisslesIdx = liMisslesIdx + 1
                Loop 'missles
            End If
            
            If Not lbExploding Then
                'is alien off the bottom of the screen? (done attacking)
                If rgGame.udtMovers(maAliensE2(liAlienIdx).lHMover).bIsOffScreenY Then
                    maAliensE1(liAlienIdx).lState1 = 0
                    'rejoin formation (animation)
                    With maAliensE1(liAlienIdx).adDrawer
                        .bAutoSwitchToNextSequence = True
                        .iStartFrame = 8
                        .iNumFrames = 8
                        .iNextStartFrame = 0
                        .iNextNumFrames = 8
                    End With
                Else 'not done attacking
                    'is this alien turning?
                    If maAliensE1(liAlienIdx).lState1 > 2 Then
                        'is it done turning? (turning frames are 32-35 and 36-39, others are less)
                        If maAliensE2(liAlienIdx).adDrawer.iStartFrame < 32 Then
                            '3 becomes 2, 4 becomes 1
                            maAliensE1(liAlienIdx).lState1 = 5 - maAliensE1(liAlienIdx).lState1
                        Else 'not done turning, is it time to change direction?
                            If maAliensE2(liAlienIdx).adDrawer.iCurrentFrameInSequence >= 2 Then
                                rgGame.udtMovers(maAliensE2(liAlienIdx).lHMover).iDirection = IIf( _
                                    32 = maAliensE2(liAlienIdx).adDrawer.iStartFrame, 45, 135)
                            End If
                        End If 'time to change direction (middle of turning animation)
                    Else 'alien not turning
                        'how long since alien turned?
                        maAliensE2(liAlienIdx).lState1 = maAliensE2(liAlienIdx).lState1 _
                                + rgGame.lTicksPassed
                        'should we turn (every second)
                        If (mbALIENE_ATTACK_TURN_INTERVAL_FIX And _
                                (maAliensE2(liAlienIdx).lState1 > mlALIENE_ATTACK_TURN_INTERVAL&)) _
                                Or (Not mbALIENE_ATTACK_TURN_INTERVAL_FIX And _
                                (Rnd < (rgGame.lTicksPassed / mlALIENE_ATTACK_TURN_INTERVAL&))) Then
                            maAliensE2(liAlienIdx).lState1 = 0
                            With maAliensE2(liAlienIdx).adDrawer
                                .bAutoSwitchToNextSequence = True
                                .iCurrentFrameInSequence = 0
                                .iStartFrame = IIf(maAliensE1(liAlienIdx).lState1 = 1, 32, 36)
                                .iNumFrames = 4
                                .iNextStartFrame = IIf(maAliensE1(liAlienIdx).lState1 = 1, 24, 16)
                                .iNextNumFrames = 8
                            End With
                            '1 -> 3, or 2 -> 4
                            maAliensE1(liAlienIdx).lState1 = maAliensE1(liAlienIdx).lState1 + 2
                        End If 'time to turn
                    End If 'alien not turning
                End If 'not done attacking
                
                'see if the alien hit the player
                If (Not maPlayer.bExploding) And _
                        (Actor_DetectCollision(rgGame, maAliensE2(liAlienIdx), maPlayer)) Then
                    If Level1_HandlePlayerCollision(rgGame) Then
                        'player hit!
                    Else
                        'player had shields on
                        rgGame.lScore = rgGame.lScore + 5
                    End If
                    'blow up alien
                    With maAliensE2(liAlienIdx)
                        'Turn the alien into an explosion
                        lbExploding = True
                        lbIsAnimationDone = False
                        .bExploding = True
                        With .adDrawer
                            .iStartFrame = IIf(liBomberExplosionNumber = 1, 40, 48)
                            .iNumFrames = 8
                            .iFramesPerSecond = -1 'use TicksPerFrame
                            .lTicksPerFrame = 40
                            .iCurrentFrameInSequence = 0
                            .bLoopAnimation = False
                        End With
                    End With
                End If 'collision with player
                
            End If 'not exploding
        End If 'BOMBING
        
        'See if an exploding alien is done exploding
        If lbExploding And lbIsAnimationDone Then
            'get rid of it
            Dim liTempNumAliensE As Integer
            liTempNumAliensE = miNumAliensE
            DeleteActorArrayElement rgGame, maAliensE1, liAlienIdx, liTempNumAliensE
            DeleteActorArrayElement rgGame, maAliensE2, liAlienIdx, miNumAliensE
        Else
            'Update Alien Position
            'Call Actor_Move(maAliensE1(liAlienIdx), rgGame)
            If maAliensE1(liAlienIdx).lState1 > 0 Then
                'Call Actor_Move(maAliensE2(liAlienIdx), rgGame)
            End If
            liAlienIdx = liAlienIdx + 1
        End If
        
    Loop 'aliens
        
    Exit Sub
    
Level1_HandleAliensE_ErrorHandler:
    HandleError Err.Number, Err.Description, Err.LastDllError, Err.source, "Level1_HandleAliensE"
End Sub

Private Sub Level1_HandleAlienABombs(rgGame As Game)
    On Error GoTo Level1_HandleAlienABombs_ErrorHandler
    
    'Draw AlienABombs then Update
    Dim liBombIdx As Integer
    Dim lbRemoveBomb As Boolean
    
    liBombIdx = 1
    Do While (liBombIdx <= miNumAlienABombs)
        Call Actor_Draw(maAlienABombs(liBombIdx), rgGame)
        'Call Actor_Move(maAlienABombs(liBombIdx), rgGame)
        
        lbRemoveBomb = False
        If (rgGame.udtMovers(maAlienABombs(liBombIdx).lHMover).bIsOffScreen) Then
            lbRemoveBomb = True
        ElseIf Not maPlayer.bExploding And _
                (Actor_DetectCollision(rgGame, maAlienABombs(liBombIdx), maPlayer)) Then
            If Level1_HandlePlayerCollision(rgGame) Then
                'collision- don't check any more missles
                Exit Do
            End If
            lbRemoveBomb = True
        End If

        If lbRemoveBomb Then
            'Get rid of the bomb
            DeleteActorArrayElement rgGame, maAlienABombs, liBombIdx, miNumAlienABombs
        Else
            liBombIdx = liBombIdx + 1
        End If
    Loop
        
    Exit Sub
    
Level1_HandleAlienABombs_ErrorHandler:
    HandleError Err.Number, Err.Description, Err.LastDllError, Err.source, "Level1_HandleAlienABombs"
End Sub

Private Sub Level1_HandleAlienDBombs(rgGame As Game)
    On Error GoTo Level1_HandleAlienDBombs_ErrorHandler
    
    'Draw AlienDBombs then Update
    Dim liBombIdx As Integer
    Dim lbRemoveBomb As Boolean
    
    liBombIdx = 1
    Do While (liBombIdx <= miNumAlienDBombs)
        Call Actor_Draw(maAlienDBombs(liBombIdx), rgGame)
        'Call Actor_Move(maAlienDBombs(liBombIdx), rgGame)
        
        lbRemoveBomb = False
        If (rgGame.udtMovers(maAlienDBombs(liBombIdx).lHMover).bIsOffScreen) Then
            lbRemoveBomb = True
        ElseIf Not maPlayer.bExploding And _
                (Actor_DetectCollision(rgGame, maAlienDBombs(liBombIdx), maPlayer)) Then
            If Level1_HandlePlayerCollision(rgGame) Then
                'collision- don't check any more missles
                Exit Do
            End If
            lbRemoveBomb = True
        End If

        If lbRemoveBomb Then
            'Get rid of the bomb
            DeleteActorArrayElement rgGame, maAlienDBombs, liBombIdx, miNumAlienDBombs
        Else
            liBombIdx = liBombIdx + 1
        End If
    Loop
        
    Exit Sub
    
Level1_HandleAlienDBombs_ErrorHandler:
    HandleError Err.Number, Err.Description, Err.LastDllError, Err.source, "Level1_HandleAlienDBombs"
End Sub

Private Function Level1_HandlePlayerCollision(rgGame As Game) As Boolean
    If Not mbShieldsOn Then
        Level1_HandlePlayerCollision = True
        'BANG!
'        Call DirectSound_PlaySoundEffect(miHseExplosion, 0&, _
'                Actor_GetPan(maPlayer, rgGame))
        Call General_PlaySound(miHseExplosion, False)
        
        'Turn the player into an explosion
        maPlayer.bExploding = True
        rgGame.udtMovers(maPlayer.lHMover).iVelocity = 0
        With maPlayer.adDrawer
            .iStartFrame = 8
            .iNumFrames = 24
            .iFramesPerSecond = -1 'use TicksPerFrame
            .lTicksPerFrame = 40
            .iCurrentFrameInSequence = 0
            .bLoopAnimation = False
        End With
        
        'Play Boom
        'Do some other stuff
        rgGame.iNumShips = rgGame.iNumShips - 1
    Else
        Level1_HandlePlayerCollision = False
        'Play another sound
    End If
    
End Function

Public Function Level1_Initialize(rgGame As Game) As Boolean
    On Error GoTo Level1_Initialize_ErrorHandler
    Level1_Initialize = False
    
gsErrorInfo = "1"
    Set mddsAlienA = LoadBitmapIntoDXS(rgGame.ddDirectDraw, _
            App.Path + "\Resource\AlienA.bmp")
gsErrorInfo = "2"
    Set mddsAlienB = LoadBitmapIntoDXS(rgGame.ddDirectDraw, _
            App.Path + "\Resource\AlienB.bmp")
    Set mddsAlienC = LoadBitmapIntoDXS(rgGame.ddDirectDraw, _
            App.Path + "\Resource\AlienC.bmp")
    Set mddsAlienD = LoadBitmapIntoDXS(rgGame.ddDirectDraw, _
            App.Path + "\Resource\AlienD.bmp")
    Set mddsAlienE = LoadBitmapIntoDXS(rgGame.ddDirectDraw, _
            App.Path + "\Resource\AlienE.bmp")
    Set mddsAlienABomb = LoadBitmapIntoDXS(rgGame.ddDirectDraw, _
            App.Path + "\Resource\BombA.bmp")
    Set mddsAlienDBomb = LoadBitmapIntoDXS(rgGame.ddDirectDraw, _
            App.Path + "\Resource\BombD.bmp")
    Set mddsPlayer = LoadBitmapIntoDXS(rgGame.ddDirectDraw, _
            App.Path + "\Resource\Ship.bmp")
    Set mddsMissle = LoadBitmapIntoDXS(rgGame.ddDirectDraw, _
            App.Path + "\Resource\Missle.bmp")
    Set mddsPlanet = LoadBitmapIntoDXS(rgGame.ddDirectDraw, _
            App.Path + "\Resource\Planet.bmp")
    Set mddsXBonus = LoadBitmapIntoDXS(rgGame.ddDirectDraw, _
            App.Path + "\Resource\XBonus.bmp")
    
gsErrorInfo = "3"
'    If Not DirectSound_LoadSoundEffect(miHseMissle, _
'            App.Path + "\Resource\Laser.wav", 1) Then Exit Function
    miHseMissle = General_LoadStaticSound(App.Path + "\Resource\Laser.wav", False)
gsErrorInfo = "4"
'    If Not DirectSound_LoadSoundEffect(miHseExplosion, _
'            App.Path + "\Resource\Whoosh.wav", 5) Then Exit Function
    miHseExplosion = General_LoadStaticSound(App.Path + "\Resource\Whoosh.wav", False)
gsErrorInfo = "5"
    
    ReDim rgGame.udtMovers(1 To 100)
    Call FAM_Initialize(rgGame.famMovers, 100)
    
    If Not Level1_Init_Player(rgGame) Then Exit Function
    If Not Level1_Init_AliensA(rgGame) Then Exit Function
    If Not Level1_Init_AliensB(rgGame) Then Exit Function
    If Not Level1_Init_AliensC(rgGame) Then Exit Function
    If Not Level1_Init_AliensD(rgGame) Then Exit Function
    If Not Level1_Init_AliensE(rgGame) Then Exit Function
    If Not Level1_Init_Missles(rgGame) Then Exit Function
    If Not Level1_Init_AlienABombs(rgGame) Then Exit Function
    If Not Level1_Init_AlienDBombs(rgGame) Then Exit Function
    If Not Level1_Init_Planet(rgGame) Then Exit Function
    If Not Level1_Init_XBonus(rgGame) Then Exit Function
    rgGame.iBonusMultiplier = 1
    
    Level1_Initialize = True
    
gsErrorInfo = ""
    Exit Function
        
Level1_Initialize_ErrorHandler:
    HandleError Err.Number, Err.Description, Err.LastDllError, Err.source, "Level1_Initialize"
End Function

Public Sub Level1_Terminate()
    On Error Resume Next
    
    Dim liIdx As Integer
    
    Set mddsAlienA = Nothing
    Set mddsAlienB = Nothing
    Set mddsAlienC = Nothing
    Set mddsAlienD = Nothing
    Set mddsAlienE = Nothing
    Set mddsAlienABomb = Nothing
    Set mddsAlienDBomb = Nothing
    Set mddsPlayer = Nothing
    Set mddsMissle = Nothing
    Set mddsPlanet = Nothing
    Set mddsXBonus = Nothing

'    Call DirectSound_ReleaseSoundEffect(miHseMissle)
'    Call DirectSound_ReleaseSoundEffect(miHseExplosion)
    Call General_DeleteSound(miHseMissle)
    Call General_DeleteSound(miHseExplosion)

    Set maPlayer.adDrawer.ddsBitMapSurface = Nothing
    
    For liIdx = 1 To giMAX_MISSLES%
        Set maMissles(liIdx).adDrawer.ddsBitMapSurface = Nothing
    Next
    Erase maMissles()
    
    For liIdx = 1 To miMAX_ALIENA_BOMBS%
        Set maAlienABombs(liIdx).adDrawer.ddsBitMapSurface = Nothing
    Next
    Erase maAlienABombs()
    
    For liIdx = 1 To miMAX_ALIEND_BOMBS%
        Set maAlienDBombs(liIdx).adDrawer.ddsBitMapSurface = Nothing
    Next
    Erase maAlienDBombs()
    
    For liIdx = 1 To miMaxAliensA
        Set maAliensA(liIdx).adDrawer.ddsBitMapSurface = Nothing
    Next
    Erase maAliensA()
    
    For liIdx = 1 To miMaxAliensB
        Set maAliensB(liIdx).adDrawer.ddsBitMapSurface = Nothing
    Next
    Erase maAliensB()
    
    For liIdx = 1 To miMaxAliensC
        Set maAliensC(liIdx).adDrawer.ddsBitMapSurface = Nothing
    Next
    Erase maAliensC()
    
    For liIdx = 1 To miMaxAliensD
        Set maAliensD(liIdx).adDrawer.ddsBitMapSurface = Nothing
    Next
    Erase maAliensD()
    
    For liIdx = 1 To miMaxAliensE
        Set maAliensE1(liIdx).adDrawer.ddsBitMapSurface = Nothing
        Set maAliensE2(liIdx).adDrawer.ddsBitMapSurface = Nothing
    Next
    Erase maAliensD()
    
    Set maPlanet.adDrawer.ddsBitMapSurface = Nothing
    
    Set maXBonus.adDrawer.ddsBitMapSurface = Nothing
    
    On Error GoTo 0
End Sub

Private Function Level1_Init_Player(rgGame As Game) As Boolean
    On Error GoTo Level1_Init_Player_ErrorHandler
    
    Dim ladDrawer As ActorDrawer

    With maPlayer
        .eActorType = actorPlayer
        .iXSize = 26
        .iYSize = 18
        .iNumCollisionBoxes = 3
        ReDim .iXCollisionBoxOffset(1 To .iNumCollisionBoxes)
        ReDim .iXCollisionBoxSize(1 To .iNumCollisionBoxes)
        ReDim .iYCollisionBoxOffset(1 To .iNumCollisionBoxes)
        ReDim .iYCollisionBoxSize(1 To .iNumCollisionBoxes)
        .iXCollisionBoxOffset(1) = 11
        .iXCollisionBoxSize(1) = 4
        .iYCollisionBoxOffset(1) = 2
        .iYCollisionBoxSize(1) = 7
        .iXCollisionBoxOffset(2) = 5
        .iXCollisionBoxSize(2) = 16
        .iYCollisionBoxOffset(2) = 9
        .iYCollisionBoxSize(2) = 4
        .iXCollisionBoxOffset(3) = 3
        .iXCollisionBoxSize(3) = 20
        .iYCollisionBoxOffset(3) = 13
        .iYCollisionBoxSize(3) = 5
        .bExploding = False
        .lHMover = FAM_AddElement(rgGame.famMovers)
    End With
    
    With maPlayer.adDrawer
        Set .ddsBitMapSurface = mddsPlayer
        .bAutoSwitchToNextSequence = False
        .iFrameSizeX = 32
        .iFrameSizeY = 18
        .iWidthInFrames = 4
        .iStartFrame = 0
        .iNumFrames = 1
        .iFramesPerSecond = -1 'use TicksPerFrame
        .lTicksPerFrame = 120
        .bLoopAnimation = True
    End With
        
    With rgGame.udtMovers(maPlayer.lHMover)
        .bActive = True
        .iXSize = 26
        .iYSize = 18
        .iMarchingDistance = giDONT_MARCH
        .iDirection = 0
        .iVelocity = 0 '120 Pix/Sec is about 4 seconds to go accross screen
        .dX = (rgGame.iPlayWidth / 2) - (maPlayer.iXSize / 2)
        .dY = rgGame.iPlayHeight - (maPlayer.iYSize + 1) - 16
        .bXReverseAtBorder = False
        .bYReverseAtBorder = False
        .bXStopAtBorder = True
        .bYStopAtBorder = True
    End With
    
    mbShieldsOn = False
    
    With mpgPlayerGuns
        .bShotReady = True
        .iMaxOnScreen = 2
        .lRechargeTime = 500
        .lTicksSinceLastShot = 0
    End With
    
    Level1_Init_Player = True
    Exit Function
    
Level1_Init_Player_ErrorHandler:
    HandleError Err.Number, Err.Description, Err.LastDllError, Err.source, "Level1_Init_Player"
    Level1_Init_Player = False
End Function

Private Function Level1_Init_Planet(rgGame As Game) As Boolean
    On Error GoTo Level1_Init_Planet_ErrorHandler
    
    Dim ladDrawer As ActorDrawer

    With maPlanet
        .eActorType = actorPlanet
        .iXSize = 24
        .iYSize = 12
        .iNumCollisionBoxes = 1
        ReDim .iXCollisionBoxOffset(1 To .iNumCollisionBoxes)
        ReDim .iXCollisionBoxSize(1 To .iNumCollisionBoxes)
        ReDim .iYCollisionBoxOffset(1 To .iNumCollisionBoxes)
        ReDim .iYCollisionBoxSize(1 To .iNumCollisionBoxes)
        .iXCollisionBoxOffset(1) = 1
        .iXCollisionBoxSize(1) = 22
        .iYCollisionBoxOffset(1) = 3
        .iYCollisionBoxSize(1) = 6
        .bExploding = False
        .bIsDoneExploding = False
        .lBonusPoints = ((Int(Rnd * 10) + 1) * 100)
        .iHseCollisionSound = miHseExplosion
        .lState1 = 0
        .lState2 = 0
        .lHMover = FAM_AddElement(rgGame.famMovers)
    End With
    
    With maPlanet.adDrawer
        Set .ddsBitMapSurface = mddsPlanet
        .bAutoSwitchToNextSequence = True
        .iFrameSizeX = 24
        .iFrameSizeY = 12
        .iWidthInFrames = 4
        .iStartFrame = 0
        .iNumFrames = 4
        .iNextStartFrame = 4
        .iNextNumFrames = 19
        .iFramesPerSecond = -1 'use TicksPerFrame
        .lTicksPerFrame = 80
        .bLoopAnimation = True
        .iExplosionStartFrame = 24
        .iExplosionNumFrames = 4
        .iExplosionFramesPerSecond = -1
        .lExplosionTicksPerFrame = 120
    End With
        
    With rgGame.udtMovers(maPlanet.lHMover)
        .iMarchingDistance = giDONT_MARCH
        .iDirection = 0
        .iVelocity = 0 '120 Pix/Sec is about 4 seconds to go accross screen
        .dX = Rnd * (rgGame.iPlayWidth - maPlanet.iXSize)
        .dY = rgGame.iPlayHeight - 96
        .bXReverseAtBorder = True
        .bYReverseAtBorder = True
        .bXStopAtBorder = True
        .bYStopAtBorder = True
    End With
    
    Level1_Init_Planet = True
    Exit Function
    
Level1_Init_Planet_ErrorHandler:
    HandleError Err.Number, Err.Description, Err.LastDllError, Err.source, "Level1_Init_Planet"
    Level1_Init_Planet = False
End Function

Private Function Level1_Init_XBonus(rgGame As Game) As Boolean
    On Error GoTo Level1_Init_XBonus_ErrorHandler
    
    Dim ladDrawer As ActorDrawer

    With maXBonus
        .eActorType = actorXBonus
        .iXSize = 12
        .iYSize = 12
        .iNumCollisionBoxes = 1
        ReDim .iXCollisionBoxOffset(1 To .iNumCollisionBoxes)
        ReDim .iXCollisionBoxSize(1 To .iNumCollisionBoxes)
        ReDim .iYCollisionBoxOffset(1 To .iNumCollisionBoxes)
        ReDim .iYCollisionBoxSize(1 To .iNumCollisionBoxes)
        .iXCollisionBoxOffset(1) = 0
        .iXCollisionBoxSize(1) = 12
        .iYCollisionBoxOffset(1) = 0
        .iYCollisionBoxSize(1) = 12
        .bExploding = False
        .bIsDoneExploding = False
        .lBonusPoints = 0
        .iHseCollisionSound = miHseExplosion
        .lState1 = 0
        .lState2 = 0
        .lHMover = FAM_AddElement(rgGame.famMovers)
    End With
    
    With maXBonus.adDrawer
        Set .ddsBitMapSurface = mddsXBonus
        .bAutoSwitchToNextSequence = False
        .iFrameSizeX = 12
        .iFrameSizeY = 12
        .iWidthInFrames = 4
        .iStartFrame = 0
        .iNumFrames = 1
        .iFramesPerSecond = -1 'use TicksPerFrame
        .lTicksPerFrame = 80
        .bLoopAnimation = True
        .iExplosionStartFrame = 0
        .iExplosionNumFrames = 0
        .iExplosionFramesPerSecond = -1
        .lExplosionTicksPerFrame = 120
    End With
        
    With rgGame.udtMovers(maXBonus.lHMover)
        .iMarchingDistance = giDONT_MARCH
        .iDirection = 0
        .iVelocity = 0 '120 Pix/Sec is about 4 seconds to go accross screen
        .dX = Rnd * (rgGame.iPlayWidth - maXBonus.iXSize)
        .dY = rgGame.iPlayHeight - 96
        .bXReverseAtBorder = True
        .bYReverseAtBorder = True
        .bXStopAtBorder = True
        .bYStopAtBorder = True
    End With
    
    Level1_Init_XBonus = True
    Exit Function
    
Level1_Init_XBonus_ErrorHandler:
    HandleError Err.Number, Err.Description, Err.LastDllError, Err.source, "Level1_Init_XBonus"
    Level1_Init_XBonus = False
End Function

Private Function Level1_Init_Missles(rgGame As Game) As Boolean
    On Error GoTo Level1_Init_Missles_ErrorHandler
    
    Dim liCtr As Integer
    ReDim maMissles(1 To giMAX_MISSLES%)
    miNumMissles = 0
    mbMissleRequested = False

    'Initialize everything except for position
    For liCtr = 1 To giMAX_MISSLES%
        With maMissles(liCtr)
            .eActorType = actorPlayerMissle
            .iXSize = 2
            .iYSize = 16
            .iNumCollisionBoxes = 1
            ReDim .iXCollisionBoxOffset(1 To .iNumCollisionBoxes)
            ReDim .iXCollisionBoxSize(1 To .iNumCollisionBoxes)
            ReDim .iYCollisionBoxOffset(1 To .iNumCollisionBoxes)
            ReDim .iYCollisionBoxSize(1 To .iNumCollisionBoxes)
            .iXCollisionBoxOffset(1) = 0
            .iXCollisionBoxSize(1) = 2
            .iYCollisionBoxOffset(1) = 0
            .iYCollisionBoxSize(1) = 16
            .lHMover = FAM_AddElement(rgGame.famMovers)
        End With
        With maMissles(liCtr).adDrawer
            Set .ddsBitMapSurface = mddsMissle
            .bAutoSwitchToNextSequence = False
            .iFrameSizeX = 2
            .iFrameSizeY = 16
            .iWidthInFrames = 1
            .iStartFrame = 0
            .iNumFrames = 1
            .iFramesPerSecond = -1 'use TicksPerFrame
            .lTicksPerFrame = 40
            .bLoopAnimation = True
        End With
        With rgGame.udtMovers(maMissles(liCtr).lHMover)
            .bActive = False
            .iXSize = 2
            .iYSize = 16
            .iDirection = 270
            .iVelocity = 200 '120 Pix/Sec is about 4 seconds to go accross screen
'            .dX = APlayer.dX + (APlayer.XSize / 2) - 1
'            .dY = APlayer.dY - 8
            .bXReverseAtBorder = False
            .bXReverseAtBorder = False
            .bYStopAtBorder = False
            .bYStopAtBorder = False
        End With
    Next liCtr

    Level1_Init_Missles = True
    Exit Function
    
Level1_Init_Missles_ErrorHandler:
    HandleError Err.Number, Err.Description, Err.LastDllError, Err.source, "Level1_Init_Missles"
    Level1_Init_Missles = False
End Function

Private Function Level1_Init_AlienABombs(rgGame As Game) As Boolean
    On Error GoTo Level1_Init_AlienABombs_ErrorHandler
    
    Dim liCtr As Integer
    ReDim maAlienABombs(1 To miMAX_ALIENA_BOMBS%)
    miNumAlienABombs = 0

    'Initialize everything except for position
    For liCtr = 1 To miMAX_ALIENA_BOMBS%
        With maAlienABombs(liCtr)
            .eActorType = actorAlienBombA
            .iXSize = 2
            .iYSize = 8
            .iNumCollisionBoxes = 1
            ReDim .iXCollisionBoxOffset(1 To .iNumCollisionBoxes)
            ReDim .iXCollisionBoxSize(1 To .iNumCollisionBoxes)
            ReDim .iYCollisionBoxOffset(1 To .iNumCollisionBoxes)
            ReDim .iYCollisionBoxSize(1 To .iNumCollisionBoxes)
            .iXCollisionBoxOffset(1) = 0
            .iXCollisionBoxSize(1) = 2
            .iYCollisionBoxOffset(1) = 0
            .iYCollisionBoxSize(1) = 8
            .lHMover = FAM_AddElement(rgGame.famMovers)
        End With
        With maAlienABombs(liCtr).adDrawer
            Set .ddsBitMapSurface = mddsAlienABomb
            .bAutoSwitchToNextSequence = False
            .iFrameSizeX = 2
            .iFrameSizeY = 8
            .iWidthInFrames = 1
            .iStartFrame = 0
            .iNumFrames = 1
            .iFramesPerSecond = -1 'use TicksPerFrame
            .lTicksPerFrame = 40
            .bLoopAnimation = True
        End With
        With rgGame.udtMovers(maAlienABombs(liCtr).lHMover)
            .bActive = False
            .iXSize = 2
            .iYSize = 8
            .iDirection = 90
            .iVelocity = 80 '120 Pix/Sec is about 4 seconds to go accross screen
'            .dX = APlayer.dX + (APlayer.XSize / 2) - 1
'            .dY = APlayer.dY - 8
            .bXReverseAtBorder = False
            .bYReverseAtBorder = False
            .bXStopAtBorder = False
            .bYStopAtBorder = False
        End With
    Next liCtr

    Level1_Init_AlienABombs = True
    Exit Function
    
Level1_Init_AlienABombs_ErrorHandler:
    HandleError Err.Number, Err.Description, Err.LastDllError, Err.source, "Level1_Init_AlienABombs"
    Level1_Init_AlienABombs = False
End Function

Private Function Level1_Init_AlienDBombs(rgGame As Game) As Boolean
    On Error GoTo Level1_Init_AlienDBombs_ErrorHandler
    
    Dim liCtr As Integer
    ReDim maAlienDBombs(1 To miMAX_ALIEND_BOMBS%)
    miNumAlienDBombs = 0

    'Initialize everything except for position
    For liCtr = 1 To miMAX_ALIEND_BOMBS%
        With maAlienDBombs(liCtr)
            .eActorType = actorAlienBombB
            .iXSize = 5
            .iYSize = 5
            .iNumCollisionBoxes = 1
            ReDim .iXCollisionBoxOffset(1 To .iNumCollisionBoxes)
            ReDim .iXCollisionBoxSize(1 To .iNumCollisionBoxes)
            ReDim .iYCollisionBoxOffset(1 To .iNumCollisionBoxes)
            ReDim .iYCollisionBoxSize(1 To .iNumCollisionBoxes)
            .iXCollisionBoxOffset(1) = 1
            .iXCollisionBoxSize(1) = 3
            .iYCollisionBoxOffset(1) = 1
            .iYCollisionBoxSize(1) = 3
            .lHMover = FAM_AddElement(rgGame.famMovers)
        End With
        With maAlienDBombs(liCtr).adDrawer
            Set .ddsBitMapSurface = mddsAlienDBomb
            .bAutoSwitchToNextSequence = False
            .iFrameSizeX = 6
            .iFrameSizeY = 6
            .iWidthInFrames = 4
            .iStartFrame = 0
            .iNumFrames = 20
            .iFramesPerSecond = -1 'use TicksPerFrame
            .lTicksPerFrame = 40
            .bLoopAnimation = True
        End With
        With rgGame.udtMovers(maAlienDBombs(liCtr).lHMover)
            .bActive = False
            .iXSize = 5
            .iYSize = 5
            .iDirection = 90
            .iVelocity = 100 '120 Pix/Sec is about 4 seconds to go accross screen
'            .dX = APlayer.dX + (APlayer.XSize / 2) - 1
'            .dY = APlayer.dY - 8
            .bXReverseAtBorder = False
            .bYReverseAtBorder = False
            .bXStopAtBorder = False
            .bYStopAtBorder = False
        End With
    Next liCtr

    Level1_Init_AlienDBombs = True
    Exit Function
    
Level1_Init_AlienDBombs_ErrorHandler:
    HandleError Err.Number, Err.Description, Err.LastDllError, Err.source, "Level1_Init_AlienDBombs"
    Level1_Init_AlienDBombs = False
End Function

Private Function Level1_Init_AliensA(rgGame As Game) As Boolean
    On Error GoTo Level1_Init_AliensA_ErrorHandler
    
    Dim liCtrX As Integer
    Dim liCtrY As Integer
    Dim liNumAliensX As Integer
    Dim liNumAliensY As Integer
    Dim liAlienAIdx As Integer
    Dim liWidthPerAlien As Integer
    Dim liInsetX  As Integer
    Dim liXSize As Integer
    Dim liYSize As Integer
    
    liXSize = 23
    liYSize = 8
    liNumAliensX = 8
    liNumAliensY = 2
    liInsetX = 32
'    liWidthPerAlien = rgGame.iPlayWidth / liNumAliensX
    liWidthPerAlien = 26
    miMaxAliensA = liNumAliensX * liNumAliensY - 1
    miNumAliensA = miMaxAliensA
    
    ReDim maAliensA(1 To miNumAliensA)
    
    For liCtrX = 1 To liNumAliensX
        For liCtrY = 1 To liNumAliensY
            If (liCtrY < liNumAliensY) Or (liCtrX < liNumAliensX) Then
                liAlienAIdx = (liCtrY - 1) * liNumAliensX + liCtrX
                With maAliensA(liAlienAIdx)
                    .eActorType = actorAlienA
                    .iXSize = liXSize
                    .iYSize = liYSize
                    .iNumCollisionBoxes = 1
                    ReDim .iXCollisionBoxOffset(1 To .iNumCollisionBoxes)
                    ReDim .iXCollisionBoxSize(1 To .iNumCollisionBoxes)
                    ReDim .iYCollisionBoxOffset(1 To .iNumCollisionBoxes)
                    ReDim .iYCollisionBoxSize(1 To .iNumCollisionBoxes)
                    .iXCollisionBoxOffset(1) = 0
                    .iXCollisionBoxSize(1) = liXSize
                    .iYCollisionBoxOffset(1) = 2
                    .iYCollisionBoxSize(1) = liYSize - 4
                    .bExploding = False
                    .iHseCollisionSound = miHseExplosion
                    .lState1 = 0
                    .bIsDoneExploding = False
                    .lHMover = FAM_AddElement(rgGame.famMovers)
                    .lHFormationMover = .lHMover
                    .bInFormation = True
                    .iXFormationOffset = 0
                    .iYFormationOffset = 0
                End With
                With maAliensA(liAlienAIdx).adDrawer
                    Set .ddsBitMapSurface = mddsAlienA
                    .bAutoSwitchToNextSequence = False
                    .iFrameSizeX = 32
                    .iFrameSizeY = 8
                    .iWidthInFrames = 4
                    .iStartFrame = 0
                    .iNumFrames = 20
                    .iFramesPerSecond = -1 'use TicksPerFrame
                    .lTicksPerFrame = 40
                    .iCurrentFrameInSequence = Int(.iNumFrames * Rnd)
                    .bLoopAnimation = True
                End With
                With rgGame.udtMovers(maAliensA(liAlienAIdx).lHMover)
                    .bActive = True
                    .iXSize = liXSize
                    .iYSize = liYSize
                    .iDirection = 0
                    .iVelocity = 30 '160 Pix/Sec is about 4 seconds to go accross screen
    '                .dX = liWidthPerAlien * (liCtrX - 1) + (liWidthPerAlien / 2) - (liXSize / 2)
                    .dX = liWidthPerAlien * (liCtrX - 1) + ((liWidthPerAlien - liXSize) / 2) _
                            + ((liCtrY - 1) * (liWidthPerAlien / 2))
                    .dY = ((liYSize + 4) * (liCtrY - 1)) + (rgGame.iPlayHeight / 2) - 32
                    .bXReverseAtBorder = False
                    .bYReverseAtBorder = False
                    .bXStopAtBorder = False
                    .bYStopAtBorder = False
    '                .iMarchingDistance = (liWidthPerAlien - liXSize)
                    .iMarchingDistance = rgGame.iPlayWidth - (liNumAliensX * liWidthPerAlien) - 32
                    If (.dX < 0) Then .dX = 0
                    If (.dX + liXSize) > rgGame.iPlayWidth Then .dX = rgGame.iPlayWidth - liXSize
                    If (.dY < 0) Then .dY = 0
                    If (.dY + liYSize) > rgGame.iPlayHeight Then .dY = rgGame.iPlayHeight - liYSize
                End With
            End If
        Next
    Next

    Level1_Init_AliensA = True
    Exit Function
    
Level1_Init_AliensA_ErrorHandler:
    HandleError Err.Number, Err.Description, Err.LastDllError, Err.source, "Level1_Init_AliensA"
    Level1_Init_AliensA = False
End Function

Private Function Level1_Init_AliensB(rgGame As Game) As Boolean
    On Error GoTo Level1_Init_AliensB_ErrorHandler
    
    Dim liAlienIdx As Integer
    Dim liAlienAIdx As Integer
    Dim liOffset As Integer
    Dim liInsetX  As Integer
    Dim liXSize As Integer
    Dim liYSize As Integer
    
    liXSize = 16
    liYSize = 16
    liInsetX = 32
    miMaxAliensB = 6
    miNumAliensB = miMaxAliensB
    
    ReDim maAliensB(1 To miNumAliensB)
    
    For liAlienIdx = 1 To miNumAliensB
        With maAliensB(liAlienIdx)
            .eActorType = actorAlienB
            .iXSize = liXSize
            .iYSize = liYSize
            .iNumCollisionBoxes = 1
            ReDim .iXCollisionBoxOffset(1 To .iNumCollisionBoxes)
            ReDim .iXCollisionBoxSize(1 To .iNumCollisionBoxes)
            ReDim .iYCollisionBoxOffset(1 To .iNumCollisionBoxes)
            ReDim .iYCollisionBoxSize(1 To .iNumCollisionBoxes)
            .iXCollisionBoxOffset(1) = 0
            .iXCollisionBoxSize(1) = liXSize
            .iYCollisionBoxOffset(1) = 0
            .iYCollisionBoxSize(1) = liYSize - 7
            .bExploding = False
            .iHseCollisionSound = miHseExplosion
            .lState1 = 0
            .bIsDoneExploding = False
            .lHMover = FAM_AddElement(rgGame.famMovers)
            .lHFormationMover = .lHMover
            .bInFormation = True
            .iXFormationOffset = 0
            .iYFormationOffset = 0
        End With
        With maAliensB(liAlienIdx).adDrawer
            Set .ddsBitMapSurface = mddsAlienB
            .bAutoSwitchToNextSequence = False
            .iFrameSizeX = 16
            .iFrameSizeY = 16
            .iWidthInFrames = 8
            .iStartFrame = 0
            .iNumFrames = 8
            .iFramesPerSecond = -1 'use TicksPerFrame
            .lTicksPerFrame = 80
            .iCurrentFrameInSequence = Int(.iNumFrames * Rnd)
            .bLoopAnimation = True
        End With
        With rgGame.udtMovers(maAliensB(liAlienIdx).lHMover)
            .bActive = True
            .iXSize = liXSize
            .iYSize = liYSize
            .iDirection = 0
            .iVelocity = 30 '160 Pix/Sec is about 4 seconds to go accross screen
            Select Case liAlienIdx
                Case 1 To 3:
                    liAlienAIdx = 3
                    liOffset = liAlienIdx - 2
                Case 4 To 6:
                    liAlienAIdx = 6
                    liOffset = liAlienIdx - 5
                Case Else:
                    liAlienAIdx = 5
                    liOffset = 0
            End Select
            .dX = rgGame.udtMovers(maAliensA(liAlienAIdx).lHMover).dX + (maAliensA(liAlienAIdx).iXSize / 2) - liXSize / 2 + (liOffset * (liYSize + 1))
            .dY = rgGame.udtMovers(maAliensA(liAlienAIdx).lHMover).dY - liYSize - 4 - 18
            .bXReverseAtBorder = False
            .bYReverseAtBorder = False
            .bXStopAtBorder = False
            .bYStopAtBorder = False
            .iMarchingDistance = rgGame.udtMovers(maAliensA(liAlienIdx).lHMover).iMarchingDistance
            .dMarched = rgGame.udtMovers(maAliensA(liAlienIdx).lHMover).dMarched
        End With
    Next

    Level1_Init_AliensB = True
    Exit Function
    
Level1_Init_AliensB_ErrorHandler:
    HandleError Err.Number, Err.Description, Err.LastDllError, Err.source, "Level1_Init_AliensB"
    Level1_Init_AliensB = False
End Function

Private Function Level1_Init_AliensC(rgGame As Game) As Boolean
    On Error GoTo Level1_Init_AliensC_ErrorHandler
    
    Dim liAlienIdx As Integer
    Dim liAlienAIdx As Integer
    Dim liInsetX  As Integer
    Dim liXSize As Integer
    Dim liYSize As Integer
    
    liXSize = 10
    liYSize = 16
    liInsetX = 32
    miMaxAliensC = 2
    miNumAliensC = miMaxAliensC
    
    ReDim maAliensC(1 To miNumAliensC)
    
    For liAlienIdx = 1 To 2
        With maAliensC(liAlienIdx)
            .eActorType = actorAlienC
            .iXSize = liXSize
            .iYSize = liYSize
            .iNumCollisionBoxes = 1
            ReDim .iXCollisionBoxOffset(1 To .iNumCollisionBoxes)
            ReDim .iXCollisionBoxSize(1 To .iNumCollisionBoxes)
            ReDim .iYCollisionBoxOffset(1 To .iNumCollisionBoxes)
            ReDim .iYCollisionBoxSize(1 To .iNumCollisionBoxes)
            .iXCollisionBoxOffset(1) = 0
            .iXCollisionBoxSize(1) = liXSize
            .iYCollisionBoxOffset(1) = 0
            .iYCollisionBoxSize(1) = liYSize - 7
            .bExploding = False
            .iHseCollisionSound = miHseExplosion
            .lState1 = 0
            .bIsDoneExploding = False
            .lHMover = FAM_AddElement(rgGame.famMovers)
            .lHFormationMover = .lHMover
            .bInFormation = True
            .iXFormationOffset = 0
            .iYFormationOffset = 0
        End With
        With maAliensC(liAlienIdx).adDrawer
            Set .ddsBitMapSurface = mddsAlienC
            .bAutoSwitchToNextSequence = False
            .iFrameSizeX = 16
            .iFrameSizeY = 16
            .iWidthInFrames = 8
            .iStartFrame = 0
            .iNumFrames = 8
            .iFramesPerSecond = -1 'use TicksPerFrame
            .lTicksPerFrame = 125
            .iCurrentFrameInSequence = Int(.iNumFrames * Rnd)
            .bLoopAnimation = True
        End With
        With rgGame.udtMovers(maAliensC(liAlienIdx).lHMover)
            .bActive = True
            .iXSize = liXSize
            .iYSize = liYSize
            .iDirection = 0
            .iVelocity = 30 '160 Pix/Sec is about 4 seconds to go accross screen
            Select Case liAlienIdx
                Case 1: liAlienAIdx = 3
                Case 2: liAlienAIdx = 6
                Case Else: liAlienAIdx = 5
            End Select
            .dX = rgGame.udtMovers(maAliensA(liAlienAIdx).lHMover).dX + (maAliensA(liAlienAIdx).iXSize / 2) - liXSize / 2
            .dY = rgGame.udtMovers(maAliensA(liAlienAIdx).lHMover).dY - liYSize - 4
            .bXReverseAtBorder = False
            .bYReverseAtBorder = False
            .bXStopAtBorder = True
            .bYStopAtBorder = True
'                .iMarchingDistance = (liWidthPerAlien - liXSize)
            .iMarchingDistance = rgGame.udtMovers(maAliensA(IIf(liAlienIdx = 1, 2, 6)).lHMover).iMarchingDistance
            .dMarched = rgGame.udtMovers(maAliensA(IIf(liAlienIdx = 1, 2, 6)).lHMover).dMarched
        End With
    Next

    Level1_Init_AliensC = True
    Exit Function
    
Level1_Init_AliensC_ErrorHandler:
    HandleError Err.Number, Err.Description, Err.LastDllError, Err.source, "Level1_Init_AliensC"
    Level1_Init_AliensC = False
End Function

Private Function Level1_Init_AliensD(rgGame As Game) As Boolean
    On Error GoTo Level1_Init_AliensD_ErrorHandler
    
    Dim liAlienIdx As Integer
    Dim liAlienAIdx As Integer
    Dim liInsetX  As Integer
    Dim liXSize As Integer
    Dim liYSize As Integer
    
    liXSize = 20
    liYSize = 20
    liInsetX = 32
    miMaxAliensD = 2
    miNumAliensD = miMaxAliensD
    
    ReDim maAliensD(1 To miNumAliensD)
    
    For liAlienIdx = 1 To 2
        With maAliensD(liAlienIdx)
            .eActorType = actorAlienD
            .iXSize = liXSize
            .iYSize = liYSize
            .iNumCollisionBoxes = 1
            ReDim .iXCollisionBoxOffset(1 To .iNumCollisionBoxes)
            ReDim .iXCollisionBoxSize(1 To .iNumCollisionBoxes)
            ReDim .iYCollisionBoxOffset(1 To .iNumCollisionBoxes)
            ReDim .iYCollisionBoxSize(1 To .iNumCollisionBoxes)
            .iXCollisionBoxOffset(1) = 0
            .iXCollisionBoxSize(1) = liXSize
            .iYCollisionBoxOffset(1) = 0
            .iYCollisionBoxSize(1) = liYSize
            .bExploding = False
            .iHseCollisionSound = miHseExplosion
            .lState1 = 0
            .bIsDoneExploding = False
            .lHMover = FAM_AddElement(rgGame.famMovers)
            .lHFormationMover = .lHMover
            .bInFormation = True
            .iXFormationOffset = 0
            .iYFormationOffset = 0
        End With
        With maAliensD(liAlienIdx).adDrawer
            Set .ddsBitMapSurface = mddsAlienD
            .bAutoSwitchToNextSequence = False
            .iFrameSizeX = 32
            .iFrameSizeY = 24
            .iWidthInFrames = 4
            .iStartFrame = 0
            .iNumFrames = 20
            .iFramesPerSecond = -1 'use TicksPerFrame
            .lTicksPerFrame = 25
            .iCurrentFrameInSequence = Int(.iNumFrames * Rnd)
            .bLoopAnimation = True
        End With
        With rgGame.udtMovers(maAliensD(liAlienIdx).lHMover)
            .bActive = True
            .iXSize = liXSize
            .iYSize = liYSize
            .iDirection = 0
            .iVelocity = 30 '160 Pix/Sec is about 4 seconds to go accross screen
            Select Case liAlienIdx
                Case 1: liAlienAIdx = 3
                Case 2: liAlienAIdx = 6
                Case Else: liAlienAIdx = 5
            End Select
            .dX = rgGame.udtMovers(maAliensA(liAlienAIdx).lHMover).dX + (maAliensA(liAlienAIdx).iXSize / 2) - liXSize / 2
            .dY = rgGame.udtMovers(maAliensA(liAlienAIdx).lHMover).dY - liYSize - 4 - 18 - 18
            .bXReverseAtBorder = False
            .bYReverseAtBorder = False
            .bXStopAtBorder = True
            .bYStopAtBorder = True
'                .iMarchingDistance = (liWidthPerAlien - liXSize)
            .iMarchingDistance = rgGame.udtMovers(maAliensA(IIf(liAlienIdx = 1, 2, 6)).lHMover).iMarchingDistance
            .dMarched = rgGame.udtMovers(maAliensA(IIf(liAlienIdx = 1, 2, 6)).lHMover).dMarched
        End With
    Next

    Level1_Init_AliensD = True
    Exit Function
    
Level1_Init_AliensD_ErrorHandler:
    HandleError Err.Number, Err.Description, Err.LastDllError, Err.source, "Level1_Init_AliensD"
    Level1_Init_AliensD = False
End Function

Private Function Level1_Init_AliensE(rgGame As Game) As Boolean
    On Error GoTo Level1_Init_AliensE_ErrorHandler
    
    Dim liAlienIdx As Integer
    Dim liAlienAIdx As Integer
    Dim liInsetX  As Integer
    Dim liXSize As Integer
    Dim liYSize As Integer
    
    liInsetX = 32
    miMaxAliensE = 4
    miNumAliensE = miMaxAliensE
    
    ReDim maAliensE1(1 To miNumAliensE)
    ReDim maAliensE2(1 To miNumAliensE)
    
    For liAlienIdx = 1 To miNumAliensE
        liXSize = 13
        liYSize = 8
        With maAliensE1(liAlienIdx)
            .eActorType = actorAlienE
            .iXSize = liXSize
            .iYSize = liYSize
            .iNumCollisionBoxes = 1
            ReDim .iXCollisionBoxOffset(1 To .iNumCollisionBoxes)
            ReDim .iXCollisionBoxSize(1 To .iNumCollisionBoxes)
            ReDim .iYCollisionBoxOffset(1 To .iNumCollisionBoxes)
            ReDim .iYCollisionBoxSize(1 To .iNumCollisionBoxes)
            .iXCollisionBoxOffset(1) = 0
            .iXCollisionBoxSize(1) = liXSize
            .iYCollisionBoxOffset(1) = 2
            .iYCollisionBoxSize(1) = liYSize - 4
            .bExploding = False
            .iHseCollisionSound = miHseExplosion
            .lState1 = 0
            .bIsDoneExploding = False
            .lHMover = FAM_AddElement(rgGame.famMovers)
            .lHFormationMover = .lHMover
            .bInFormation = True
            .iXFormationOffset = 0
            .iYFormationOffset = 0
        End With
        With maAliensE1(liAlienIdx).adDrawer
            Set .ddsBitMapSurface = mddsAlienE
            .bAutoSwitchToNextSequence = False
            .iFrameSizeX = 16
            .iFrameSizeY = 8
            .iWidthInFrames = 8
            .iStartFrame = 0
            .iNumFrames = 8
            .iFramesPerSecond = -1 'use TicksPerFrame
            .lTicksPerFrame = 75
            .iCurrentFrameInSequence = Int(.iNumFrames * Rnd)
            .bLoopAnimation = True
        End With
        With rgGame.udtMovers(maAliensE1(liAlienIdx).lHMover)
            .bActive = True
            .iXSize = liXSize
            .iYSize = liYSize
            .iDirection = 0
            .iVelocity = 30 '160 Pix/Sec is about 4 seconds to go accross screen
            Select Case liAlienIdx
                Case 1: liAlienAIdx = 2
                Case 2: liAlienAIdx = 4
                Case 3: liAlienAIdx = 5
                Case 4: liAlienAIdx = 7
                Case Else: liAlienAIdx = 5
            End Select
            .dX = rgGame.udtMovers(maAliensA(liAlienAIdx).lHMover).dX + (maAliensA(liAlienAIdx).iXSize / 2) - liXSize / 2
            .dY = rgGame.udtMovers(maAliensA(liAlienAIdx).lHMover).dY - liYSize - 4
            .bXReverseAtBorder = False
            .bYReverseAtBorder = False
            .bXStopAtBorder = True
            .bYStopAtBorder = True
'                .iMarchingDistance = (liWidthPerAlien - liXSize)
            .iMarchingDistance = rgGame.udtMovers(maAliensA(liAlienIdx).lHMover).iMarchingDistance
            .dMarched = rgGame.udtMovers(maAliensA(liAlienIdx).lHMover).dMarched
        End With
    
        liXSize = 14
        liYSize = 13
        With maAliensE2(liAlienIdx)
            .eActorType = actorAlienE
            .iXSize = liXSize
            .iYSize = liYSize
            .iNumCollisionBoxes = 1
            ReDim .iXCollisionBoxOffset(1 To .iNumCollisionBoxes)
            ReDim .iXCollisionBoxSize(1 To .iNumCollisionBoxes)
            ReDim .iYCollisionBoxOffset(1 To .iNumCollisionBoxes)
            ReDim .iYCollisionBoxSize(1 To .iNumCollisionBoxes)
            .iXCollisionBoxOffset(1) = 0
            .iXCollisionBoxSize(1) = liXSize
            .iYCollisionBoxOffset(1) = 2
            .iYCollisionBoxSize(1) = liYSize - 4
            .lState1 = 0
            .lHMover = FAM_AddElement(rgGame.famMovers)
            .bInFormation = False
        End With
        With maAliensE2(liAlienIdx).adDrawer
            Set .ddsBitMapSurface = mddsAlienE
            .bAutoSwitchToNextSequence = False
            .iFrameSizeX = 16
            .iFrameSizeY = 16
            .iWidthInFrames = 8
            .iStartFrame = 16
            .iNumFrames = 8
            .iFramesPerSecond = -1 'use TicksPerFrame
            .lTicksPerFrame = 75
            .iCurrentFrameInSequence = Int(.iNumFrames * Rnd)
            .bLoopAnimation = True
        End With
        With rgGame.udtMovers(maAliensE2(liAlienIdx).lHMover)
            .bActive = True
            .iXSize = liXSize
            .iYSize = liYSize
            .iDirection = 135 'or 45
            .iVelocity = 30 '160 Pix/Sec is about 4 seconds to go accross screen
            Select Case liAlienIdx
                Case 1: liAlienAIdx = 1
                Case 2: liAlienAIdx = 3
                Case 3: liAlienAIdx = 6
                Case 4: liAlienAIdx = 8
                Case Else: liAlienAIdx = 5
            End Select
            .dX = rgGame.udtMovers(maAliensA(liAlienAIdx).lHMover).dX + (maAliensA(liAlienAIdx).iXSize / 2) - liXSize / 2
            .dY = rgGame.udtMovers(maAliensA(liAlienAIdx).lHMover).dY - liYSize - 4
            .bXReverseAtBorder = False
            .bYReverseAtBorder = False
            .bXStopAtBorder = False
            .bYStopAtBorder = False
            .iMarchingDistance = -1
        End With
    Next

    Level1_Init_AliensE = True
    Exit Function
    
Level1_Init_AliensE_ErrorHandler:
    HandleError Err.Number, Err.Description, Err.LastDllError, Err.source, "Level1_Init_AliensE"
    Level1_Init_AliensE = False
End Function

Public Sub Level1_CheckInput(rgGame As Game)
    If Not maPlayer.bExploding Then
        mbMissleRequested = DirectInput_IsKeyDown(DirectX.DIK_LSHIFT) Or _
                DirectInput_IsKeyDown(DirectX.DIK_RSHIFT)
        mbShieldsRequested = DirectInput_IsKeyDown(DirectX.DIK_LMENU) Or _
                DirectInput_IsKeyDown(DirectX.DIK_RMENU)
        
        With rgGame.udtMovers(maPlayer.lHMover)
            If DirectInput_IsKeyDown(DirectX.DIK_SPACE) Then
                .iVelocity = 0
            ElseIf DirectInput_IsKeyDown(DirectX.DIK_LEFT) Then
                .iDirection = 180
                .iVelocity = 90
            ElseIf DirectInput_IsKeyDown(DirectX.DIK_RIGHT) Then
                .iDirection = 0
                .iVelocity = 90
            End If
        End With
    Else
        mbMissleRequested = False
        mbShieldsOn = False
    End If
End Sub

