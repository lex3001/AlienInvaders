VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
END
Attribute VB_Name = "Level"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = True
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = False
Option Explicit

Public oPlayer As Actor2
Public oPlayerInput As PlayerInput
Private iMaxNumAliens As Integer
Private oAliens() As Actor2
Private oAliensFAM As FastArrayManager2
Private iMaxNumMissiles As Integer
Private oMissiles() As Actor2
Private oMissilesFAM As FastArrayManager2
Private iMaxNumABombs As Integer
Private oABombs() As Actor2
Private oABombsFAM As FastArrayManager2
Private iMaxNumDBombs As Integer
Private oDBombs() As Actor2
Private oDBombsFAM As FastArrayManager2

Public iNumAliensMustBeDestroyed As Integer

Public ddDirectDraw As IDirectDraw2    'local copy - don't forget to Set to Nothing!
Public ddsBackBufferSurface As IDirectDrawSurface2    'local copy - don't forget to Set to Nothing!
Public lTicksPassed As Long
Public bRealTime As Boolean
Public lTicksPerLoop As Long
Public lMaxTicksPerLoop As Long
Public iPlayHeight As Integer
Public iPlayWidth As Integer
Public iPlayXOffset As Integer
Public iPlayYOffset As Integer
Public iNumShips As Integer
Public lScore As Long
Public bIsGameOver As Boolean
Public bIsPlayerDead As Boolean
Public bIsLevelComplete As Boolean
Public lShieldsLeft As Long    'in ticks
Public lBonus As Long
Public lBonusTicks As Long
Public iBonusMultiplier As Integer
Public bShieldsOn As Boolean

Private iNumBitMapDefinitions As Integer
Private oBitMapDefinitions() As BitMapDefinition

'----------------------------



Public Sub Draw()
    Dim llCtr As Long
    
    llCtr = oMissilesFAM.StartIteration()
    Do While llCtr > 0
        Call oMissiles(llCtr).Draw(Me)
        llCtr = oMissilesFAM.NextIteration()
    Loop
    
    llCtr = oABombsFAM.StartIteration()
    Do While llCtr > 0
        Call oABombs(llCtr).Draw(Me)
        llCtr = oABombsFAM.NextIteration()
    Loop
    
    llCtr = oDBombsFAM.StartIteration()
    Do While llCtr > 0
        Call oDBombs(llCtr).Draw(Me)
        llCtr = oDBombsFAM.NextIteration()
    Loop
    
    llCtr = oAliensFAM.StartIteration()
    Do While llCtr > 0
        Call oAliens(llCtr).Draw(Me)
        llCtr = oAliensFAM.NextIteration()
    Loop
    
    Call oPlayer.Draw(Me)
End Sub

Public Sub Update()
    Dim llCtr1 As Long
    Dim llCtr2 As Long
    
    Call CheckInput
    
    'move player and give player a chance to turn on shields, etc.
    Call oPlayer.Update(Me, vbMove:=True)
    
    llCtr1 = oMissilesFAM.StartIteration()
    Do While llCtr1 > 0
        Call oMissiles(llCtr1).Update(Me, vbMove:=True)
        llCtr1 = oMissilesFAM.NextIteration()
    Loop
    
    llCtr1 = oAliensFAM.StartIteration()
    Do While llCtr1 > 0
        With oAliens(llCtr1)
            Call .Update(Me, vbMove:=True, vbState:=False)
            If .bCanBeHitByMissle Then
                llCtr2 = oMissilesFAM.StartIteration()
                Do While llCtr2 > 0
                    If .DetectCollision(oMissiles(llCtr2)) Then
                        .bWasHitByMissle = True
                        Call oMissilesFAM.ReleaseIndex(llCtr2)
                    End If
                    llCtr2 = oMissilesFAM.NextIteration()
                Loop
            End If
            If Not .bWasHitByMissle And .bCanHitPlayer Then
                If .DetectCollision(oPlayer) Then
                    If bShieldsOn Then
                        .bHitShields = True
                    Else
                        .bHitPlayer = True
                        oPlayer.bWasHitByMissle = True 'well, not a missile, but hey...
                    End If
                End If
            End If
            Call .Update(Me, vbAnimate:=False)
            If .bDelete Then
                If .bMustBeDestroyed Then iNumAliensMustBeDestroyed = iNumAliensMustBeDestroyed - 1
                oAliensFAM.ReleaseIndex (llCtr1)
            End If
        End With
        llCtr1 = oAliensFAM.NextIteration()
    Loop
    
    llCtr1 = oABombsFAM.StartIteration()
    Do While llCtr1 > 0
        With oABombs(llCtr1)
            Call .Update(Me, vbMove:=True, vbState:=False)
            If .DetectCollision(oPlayer) Then
                If bShieldsOn Then
                Else
                    oPlayer.bWasHitByMissle = True 'well, not a missile, but hey...
                End If
                Call oABombs.ReleaseIndex(llCtr1)
            End If
            Call .Update(Me, vbAnimate:=False)
            If .bDelete Then oABombsFAM.ReleaseIndex (llCtr1)
        End With
        llCtr1 = oABombsFAM.NextIteration()
    Loop
    
    llCtr1 = oDBombsFAM.StartIteration()
    Do While llCtr1 > 0
        With oDBombs(llCtr1)
            Call .Update(Me, vbMove:=True, vbState:=False)
            If .DetectCollision(oPlayer) Then
                If bShieldsOn Then
                Else
                    oPlayer.bWasHitByMissle = True 'well, not a missile, but hey...
                End If
                Call oDBombs.ReleaseIndex(llCtr1)
            End If
            Call .Update(Me, vbAnimate:=False)
            If .bDelete Then oABombsFAM.ReleaseIndex (llCtr1)
        End With
        llCtr1 = oDBombsFAM.NextIteration()
    Loop
    
    'handle collisions, etc
    Call oPlayer.Update(Me, vbAnimate:=False)

    If iNumAliensMustBeDestroyed <= 0 Then
        bIsLevelComplete = True
    End If
End Sub

Public Sub CheckInput()
    With oPlayerInput
        .bMissleRequested = DirectInput_IsKeyDown(DirectX.DIK_LSHIFT) Or _
            DirectInput_IsKeyDown(DirectX.DIK_RSHIFT)
        .bShieldsRequested = DirectInput_IsKeyDown(DirectX.DIK_LMENU) Or _
            DirectInput_IsKeyDown(DirectX.DIK_RMENU)
        .bStopMoveRequested = DirectInput_IsKeyDown(DirectX.DIK_SPACE)
        .bMoveLeftRequested = DirectInput_IsKeyDown(DirectX.DIK_LEFT)
        .bMoveRightRequested = DirectInput_IsKeyDown(DirectX.DIK_RIGHT)
    End With
End Sub

Public Function InitializeActorArrays(ByVal viAliens%, ByVal viMissiles%, ByVal viABombs%, ByVal viDBombs%)
    iMaxNumAliens = viAliens
    iMaxNumMissiles = viMissiles
    iMaxNumABombs = viABombs
    iMaxNumDBombs = viDBombs
    
    oAliensFAM.Initialize (iMaxNumAliens)
    If 0 = iMaxNumAliens Then
        Erase oAliens
    Else
        ReDim oAliens(1 To iMaxNumAliens)
    End If
    
    oMissilesFAM.Initialize (iMaxNumMissiles)
    If 0 = iMaxNumMissiles Then
        Erase oMissiles
    Else
        ReDim oMissiles(1 To iMaxNumMissiles)
    End If

    oABombsFAM.Initialize (iMaxNumABombs)
    If 0 = iMaxNumABombs Then
        Erase oABombs
    Else
        ReDim oABombs(1 To iMaxNumABombs)
    End If

    oABombsFAM.Initialize (iMaxNumABombs)
    If 0 = iMaxNumABombs Then
        Erase oABombs
    Else
        ReDim oABombs(1 To iMaxNumABombs)
    End If
End Function

Public Function AddNewBitMapDefinition(rsID$, rddsDirectDrawSurface As IDirectDrawSurface2, _
        ByVal viXFrameSize%, ByVal viYFrameSize%, viWidthInFrame%, ByVal viNumFrames)
    
    Dim loNewBitMapDefinition As New BitMapDefinition
    Call loNewBitMapDefinition.Initialize(rsID, rddsDirectDrawSurface, _
        viXFrameSize, viYFrameSize, viWidthInFrame, viNumFrames)
    
    iNumBitMapDefinitions = iNumBitMapDefinitions + 1
    ReDim Preserve oBitMapDefinitions(1 To iNumBitMapDefinitions)
    Set oBitMapDefinitions(iNumBitMapDefinitions) = loNewBitMapDefinition
    
    Set AddNewBitMapDefinition = loNewBitMapDefinition
End Function

Public Sub ClearBitMapDefinitions()
    iNumBitMapDefinitions = 0
    Erase oBitMapDefinitions()
End Sub

Public Function GetBitMapDefinition(rsID$) As BitMapDefinition
    Dim liCtr As Integer
    
    For liCtr = 1 To iNumBitMapDefinitions
        If oBitMapDefinitions(liCtr).sID = rsID Then
            Set GetBitMapDefinition = oBitMapDefinitions(liCtr)
            Exit Function
        End If
    Next liCtr
    
    Set GetBitMapDefinition = Nothing
End Function

Public Function AddNewAlien(rsBitMapID$, roBrains As Brains) As Actor2
    Set AddNewAlien = AddActorToListGeneric(rsBitMapID, roBrains, oAliensFAM, oAliens())
End Function

Public Function SetPlayer(rsBitMapID$, roBrains As Brains) As Actor2
    Set oPlayer = CreateNewActor(rsBitMapID, roBrains)
    Set SetPlayer = oPlayer
End Function

Public Function CreateNewActor(rsBitMapID$, roBrains As Brains) As Actor2
    Dim loNewActor As Actor2
    
    'create new actor
    Set loNewActor = New Actor2
    Set roActors(llNewActorIndex) = loNewActor

    'initialize the new actor
    If "" = rsBitMapID Then
        Call loNewActor.Initialize(Nothing, roBrains)
    Else
        Call loNewActor.Initialize(GetBitMapDefinition(rsBitMapID), roBrains)
    End If
    
    'initialize the brains
    Call roBrains.Initialize(Me, loNewActor)
    
    'return the new alien
    Set CreateNewActor = loNewActor
End Function

Public Function AddNewActorToListGeneric(rsBitMapID$, roBrains As Brains, _
        roActorFAM As FastArrayManager2, roActors() As Actor2) As Actor2
    Dim loNewActor As Actor2
    Dim llNewActorIndex As Long
    
    'add to list
    llNewActorIndex = roActorsFAM.GetFreeIndex()
    If llNewActorIndex > 0 Then
        'create new actor
        Set loNewActor = CreateNewActor(rsBitMapID, roBrains)
    Else
        Set loNewActor = Nothing
    End If
    
    'return the new alien
    Set AddNewActorToListGeneric = loNewActor
End Function

Private Function DropBombGeneric(roFromActor As Actor2, roTargetActor As Actor2, _
        roBombsFAM As FastArrayManager2, roBombs() As Actor2, _
        ByVal veBombDir As BombDir_Enum) As Boolean
    Dim llNewBombIndex As Long
    Dim lfStartX As Single
    Dim lfStartY As Single
    Dim lfTargetX As Single
    Dim lfTargetY As Single

    llNewBombIndex = roBombsFAM.GetFreeIndex()

    If llNewBombIndex > 0 Then
        Call roBombs(llNewBombIndex).oBrains.ResetState
            
        With roFromActor
            lfStartX = .CenterX()
            lfStartY = .fY
        End With
        
        With roBombs(llNewBombIndex)
            With .oBitMapDefinition.GetFrameDefinition(.oSequencePlayer.CurrentBitMapFrame)
                lfStartX = lfStartX - (.iXSize / 2!) - 1!
                If Not veBombDir = bombStraightUp Then lfStartY = lfStartY + .iYSize
            End With
    
            .fX = lfStartX
            .fY = lfStartY
        
            If Not veBombDir = bombDefaultDir Then
                If veBombDir = bombToTarget Then
                    With roTargetActor
                        Call .GetCenter(lfTargetX, lfTargetY)
                    End With
                    .iVelocityDirection = GetAngleFromXYSng(lfTargetX - lfStartX, lfTargetY - lfStartY)
                ElseIf veBombDir = bombStraightDown Then
                    .iVelocityDirection = 90
                ElseIf veBombDir = bombStraightUp Then
                    .iVelocityDirection = 270
                End If
            End If
        End With
        
        DropBombGeneric = True
    Else
        DropBombGeneric = False
    End If
End Function

Public Function FirePlayerMissle() As Boolean
    FirePlayerMissle = DropBombGeneric(oPlayer, Nothing, oMissilesFAM, oMissiles(), bombStraightUp)
End Function

Public Function DropABomb(roBomber As Actor2) As Boolean
    DropABomb = DropBombGeneric(roBomber, Nothing, oABombsFAM, oABombs(), bombStraightDown)
End Function

Public Function DropDBomb(roBomber As Actor2) As Boolean
    DropDBomb = DropBombGeneric(roBomber, oPlayer, oDBombsFAM, oDBombs(), bombToTarget)
End Function

Private Sub Class_Initialize()
    Set oPlayerInput = New PlayerInput
End Sub
