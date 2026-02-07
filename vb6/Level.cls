VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
  Persistable = 0  'NotPersistable
  DataBindingBehavior = 0  'vbNone
  DataSourceBehavior  = 0  'vbNone
  MTSTransactionMode  = 0  'NotAnMTSObject
END
Attribute VB_Name = "Level"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = True
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = False
Option Explicit

Public bPaused As Boolean
Public oGame As Game2
Private bTerminated As Boolean
Public oPlayer As Actor2
Public oPlayerInput As PlayerInput
Private lMaxNumAliens As Long
Private oAliens() As Actor2
Private oAliensFAM As New FastArrayManager2
Private lMaxNumMissiles As Long
Private oMissiles() As Actor2
Private oMissilesFAM As New FastArrayManager2
Private lMaxNumABombs As Long
Private oABombs() As Actor2
Private oABombsFAM As New FastArrayManager2
Private lMaxNumDBombs As Long
Private oDBombs() As Actor2
Private oDBombsFAM As New FastArrayManager2
Private lMaxNumCargo As Long
Private oCargo() As Actor2
Private oCargoFAM As New FastArrayManager2

Private oPlayQuadrantManager As New PlayQuadrantManager

Public lNumAliensMustBeDestroyed As Long

Public ddDirectDraw As IDirectDraw2    'local copy - don't forget to Set to Nothing!
Public ddsBackBufferSurface As IDirectDrawSurface2    'local copy - don't forget to Set to Nothing!
Public lTicksPassed As Long
Public bRealTime As Boolean
Public lTicksPerLoop As Long
Public lMaxTicksPerLoop As Long
Public lPlayHeight As Long
Public lPlayWidth As Long
Public lPlayXOffset As Long
Public lPlayYOffset As Long
Public lNumShips As Long
Public lScore As Long
Public bIsGameOver As Boolean
Public bIsPlayerDead As Boolean
Public bIsLevelComplete As Boolean
Public lShieldsLeft As Long    'in ticks
Public lStartingBonus As Long
Public lBonus As Long
Public lBonusTicks As Long
Public lBonusMultiplier As Long
Public bShieldsOn As Boolean
Public bHasDoubleShots As Boolean
Public bHasRapidFire As Boolean
Public bHasMultiShots As Boolean
Public bHasSafetyPin As Boolean

Private lNumBitMapDefinitions As Long
Private oBitMapDefinitions() As BitMapDefinition

Private oSoundsCollection As New Collection



'----------------------------

Public Sub InitializeActorBrains()
    Dim llCtr As Long
    
    llCtr = oMissilesFAM.StartIteration()
    Do While llCtr > 0
        Call oMissiles(llCtr).ResetState
        llCtr = oMissilesFAM.NextIteration()
    Loop
    
    llCtr = oABombsFAM.StartIteration()
    Do While llCtr > 0
        Call oABombs(llCtr).ResetState
        llCtr = oABombsFAM.NextIteration()
    Loop
    
    llCtr = oDBombsFAM.StartIteration()
    Do While llCtr > 0
        Call oDBombs(llCtr).ResetState
        llCtr = oDBombsFAM.NextIteration()
    Loop
    
    llCtr = oCargoFAM.StartIteration()
    Do While llCtr > 0
        Call oCargo(llCtr).ResetState
        llCtr = oCargoFAM.NextIteration()
    Loop
    
    llCtr = oAliensFAM.StartIteration()
    Do While llCtr > 0
        Call oAliens(llCtr).ResetState
        llCtr = oAliensFAM.NextIteration()
    Loop
    
    Call oPlayer.ResetState
End Sub

Public Sub Draw()
    Dim llCtr As Long
    
    llCtr = oCargoFAM.StartIteration()
    Do While llCtr > 0
        Call oCargo(llCtr).Draw(Me)
        llCtr = oCargoFAM.NextIteration()
    Loop
    
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
    Dim loMissile As Actor2
    Dim llMissileFAMIndex As Long
    
    Call CheckInput
    
    'move player and give player a chance to turn on shields, etc.
    Call oPlayer.Update(Me, vbMove:=True)
    
    oPlayQuadrantManager.Clear
    llCtr1 = oMissilesFAM.StartIteration()
    Do While llCtr1 > 0
        With oMissiles(llCtr1)
            Call .Update(Me, vbMove:=True)
            If .bDelete Then
                Call oMissilesFAM.ReleaseIndex(llCtr1)
            Else
                Call oPlayQuadrantManager.AddObject(.fX, .fY, oMissiles(llCtr1), llCtr1)
'    If .fY < 301 Then
'        Debug.Print .fX, .fY
'    End If
            End If
        End With
        llCtr1 = oMissilesFAM.NextIteration()
    Loop
    
    llCtr1 = oAliensFAM.StartIteration()
    Do While llCtr1 > 0
        With oAliens(llCtr1)
            Call .Update(Me, vbMove:=True, vbState:=False)
            If .lCanBeHitByMissiles > .lWasHitByMissiles Then
                Call oPlayQuadrantManager.StartIterator(.fX, .fY)
'If TypeOf oAliens(llCtr1).oBrains Is BrainsAlienA Then
'    If .fX < 95 Then
'        Debug.Print .fX, .fY
'    End If
'End If
Dim llSafety As Long
llSafety = 0
                Do While True
llSafety = llSafety + 1
If llSafety > 100 Then
    Debug.Print "Shit! Endless Loop!"
End If
                    Set loMissile = oPlayQuadrantManager.GetNextObject(llMissileFAMIndex)
                    If loMissile Is Nothing Then
                        Exit Do
                    Else
                        If .DetectCollision(loMissile) Then
                            .lWasHitByMissiles = .lWasHitByMissiles + 1
                            Call oPlayQuadrantManager.DeleteLastObject
                            Call oMissilesFAM.ReleaseIndex(llMissileFAMIndex)
                            Exit Do
                        End If
                    End If
                Loop
'                llCtr2 = oMissilesFAM.StartIteration()
'                Do While llCtr2 > 0
'                    If Not .bWasHitByMissile Then
'                        If .DetectCollision(oMissiles(llCtr2)) Then
'                            .bWasHitByMissile = True
'                            Call oMissilesFAM.ReleaseIndex(llCtr2)
'                        End If
'                    End If
'                    llCtr2 = oMissilesFAM.NextIteration()
'                Loop
            End If
            If ((0& = .lCanBeHitByMissiles) Or (.lCanBeHitByMissiles > .lWasHitByMissiles)) And .bCanHitPlayer Then
                If .DetectCollision(oPlayer) Then
                    If bShieldsOn Then
                        .bHitShields = True
                    Else
                        .bHitPlayer = True
                        oPlayer.lWasHitByMissiles = oPlayer.lWasHitByMissiles + 1 'well, not a missile, but hey...
                    End If
                End If
            End If
            Call .Update(Me, vbAnimate:=False)
            If .bDelete Then
                If .bMustBeDestroyed Then lNumAliensMustBeDestroyed = lNumAliensMustBeDestroyed - 1
                Call oAliensFAM.ReleaseIndex(llCtr1)
            ElseIf .bMustBeDestroyed And (Not .oSequencePlayer Is Nothing) Then
                If Not .oSequencePlayer.IsValid Then
                    LogInfo "Warning: Alien not deleted but invalid Sequence Player!", "Level_Update", _
                        "llCtr1=" & llCtr1 & ": " & TypeName(.oBrains)
'                    If .bMustBeDestroyed Then lNumAliensMustBeDestroyed = lNumAliensMustBeDestroyed - 1
'                    Call oAliensFAM.ReleaseIndex(llCtr1)
                End If
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
                    oPlayer.lWasHitByMissiles = oPlayer.lWasHitByMissiles + 1 'well, not a missile, but hey...
                End If
                .bDelete = True
            End If
            Call .Update(Me, vbAnimate:=False)
            If .bDelete Then Call oABombsFAM.ReleaseIndex(llCtr1)
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
                    oPlayer.lWasHitByMissiles = oPlayer.lWasHitByMissiles + 1 'well, not a missile, but hey...
                End If
                .bDelete = True
            End If
            Call .Update(Me, vbAnimate:=False)
            If .bDelete Then Call oDBombsFAM.ReleaseIndex(llCtr1)
        End With
        llCtr1 = oDBombsFAM.NextIteration()
    Loop
    
    llCtr1 = oCargoFAM.StartIteration()
    Do While llCtr1 > 0
        With oCargo(llCtr1)
            Call .Update(Me, vbMove:=True, vbState:=False)
            If .lCanBeHitByMissiles > .lWasHitByMissiles Then
                llCtr2 = oMissilesFAM.StartIteration()
                Do While llCtr2 > 0
                    If .DetectCollision(oMissiles(llCtr2)) Then
                        .lWasHitByMissiles = .lWasHitByMissiles + 1
                        Call oMissilesFAM.ReleaseIndex(llCtr2)
                    End If
                    llCtr2 = oMissilesFAM.NextIteration()
                Loop
            End If
            If ((0& = .lCanBeHitByMissiles) Or (.lCanBeHitByMissiles > .lWasHitByMissiles)) And .bCanHitPlayer Then
                If .DetectCollision(oPlayer) Then
                    .bHitPlayer = True
                End If
            End If
            Call .Update(Me, vbAnimate:=False)
            If .bDelete Then Call oCargoFAM.ReleaseIndex(llCtr1)
        End With
        llCtr1 = oCargoFAM.NextIteration()
    Loop
    
    'handle collisions, etc
    Call oPlayer.Update(Me, vbAnimate:=False)

    If lNumAliensMustBeDestroyed <= 0 Then
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

Public Sub InitializeActorArrays(ByVal vlAliens&, ByVal vlMissiles&, ByVal vlABombs&, ByVal vlDBombs&, ByVal vlCargo&)
    lMaxNumAliens = vlAliens
    lMaxNumMissiles = vlMissiles
    lMaxNumABombs = vlABombs
    lMaxNumDBombs = vlDBombs
    lMaxNumCargo = vlCargo
    
    Dim llCtr As Long
    
    Call oAliensFAM.Initialize(lMaxNumAliens)
    If 0 = lMaxNumAliens Then
        Erase oAliens
    Else
        ReDim oAliens(1 To lMaxNumAliens)
    End If
    
    Call oMissilesFAM.Initialize(lMaxNumMissiles)
    If 0 = lMaxNumMissiles Then
        Erase oMissiles
    Else
        ReDim oMissiles(1 To lMaxNumMissiles)
        For llCtr = 1 To lMaxNumMissiles
gsErrorInfo = "ZX1"
            Set oMissiles(llCtr) = CreateNewActor("MISSILE", New BrainsMissile)
            oMissiles(llCtr).lVelocity = 200
gsErrorInfo = "ZX2"
        Next llCtr
    End If

    Call oABombsFAM.Initialize(lMaxNumABombs)
    If 0 = lMaxNumABombs Then
        Erase oABombs
    Else
        ReDim oABombs(1 To lMaxNumABombs)
        For llCtr = 1 To lMaxNumABombs
gsErrorInfo = "ZX3"
            Set oABombs(llCtr) = CreateNewActor("ABOMB", New BrainsMissile)
            oABombs(llCtr).lVelocity = 80
gsErrorInfo = "ZX4"
        Next llCtr
    End If

    Call oDBombsFAM.Initialize(lMaxNumDBombs)
    If 0 = lMaxNumDBombs Then
        Erase oDBombs
    Else
        ReDim oDBombs(1 To lMaxNumDBombs)
        For llCtr = 1 To lMaxNumDBombs
gsErrorInfo = "ZX5"
            Set oDBombs(llCtr) = CreateNewActor("DBOMB", New BrainsMissile)
            oDBombs(llCtr).lVelocity = 100
gsErrorInfo = "ZX6"
        Next llCtr
    End If

    Call oCargoFAM.Initialize(lMaxNumCargo)
    If 0 = lMaxNumCargo Then
        Erase oCargo
    Else
        ReDim oCargo(1 To lMaxNumCargo)
        For llCtr = 1 To lMaxNumCargo
gsErrorInfo = "ZX5"
            Set oCargo(llCtr) = CreateNewActor("CARGO", New BrainsCargo)
gsErrorInfo = "ZX6"
        Next llCtr
    End If

    Call oPlayQuadrantManager.Initialize(lPlayWidth, lPlayHeight, 128, 64, 32, 16, lMaxNumMissiles)
End Sub

Public Function AddNewSoundEffect(rsID$, rsWAVFile$, ByVal vlCopiesRequested&) As SoundEffect
    Dim loSoundEffect As New SoundEffect
    Call loSoundEffect.Initialize(rsID, rsWAVFile, vlCopiesRequested)
    Call AddSoundEffect(rsID, loSoundEffect)
    Set AddNewSoundEffect = loSoundEffect
End Function

Public Sub AddSoundEffect(rsID$, roSoundEffect As SoundEffect)
    oSoundsCollection.Add roSoundEffect, rsID
End Sub

Public Function GetSoundEffect(rsID$) As SoundEffect
    Set GetSoundEffect = oSoundsCollection.Item(rsID)
End Function

Public Function AddNewBitMapDefinition(rsID$, rddsDirectDrawSurface As IDirectDrawSurface2, _
        ByVal vlXFrameSize&, ByVal vlYFrameSize&, vlWidthInFrame&, ByVal vlNumFrames&)
    
    Dim loNewBitMapDefinition As New BitMapDefinition
    Call loNewBitMapDefinition.Initialize(rsID, rddsDirectDrawSurface, _
        vlXFrameSize, vlYFrameSize, vlWidthInFrame, vlNumFrames)
    
    lNumBitMapDefinitions = lNumBitMapDefinitions + 1
    ReDim Preserve oBitMapDefinitions(1 To lNumBitMapDefinitions)
    Set oBitMapDefinitions(lNumBitMapDefinitions) = loNewBitMapDefinition
    
    Set AddNewBitMapDefinition = loNewBitMapDefinition
End Function

Public Sub ClearBitMapDefinitions()
    lNumBitMapDefinitions = 0
    Erase oBitMapDefinitions()
End Sub

Public Function GetBitMapDefinition(rsID$) As BitMapDefinition
    Dim llCtr As Long
    
    For llCtr = 1 To lNumBitMapDefinitions
        If oBitMapDefinitions(llCtr).sID = rsID Then
            Set GetBitMapDefinition = oBitMapDefinitions(llCtr)
            Exit Function
        End If
    Next llCtr
    
    LogInfo "WARNING: BitMapDefinition '" & rsID & "' not found!", "Level.GetBitMapDefinition"
    
    Set GetBitMapDefinition = Nothing
End Function

Public Function AddNewAlien(rsBitMapID$, roBrains As Brains) As Actor2
    Set AddNewAlien = AddNewActorToListGeneric(rsBitMapID, roBrains, oAliensFAM, oAliens())
End Function

Public Function SetPlayer(rsBitMapID$, roBrains As Brains) As Actor2
    Set oPlayer = CreateNewActor(rsBitMapID, roBrains)
    Set SetPlayer = oPlayer
End Function

Public Function CreateNewActor(rsBitMapID$, roBrains As Brains) As Actor2
    Dim loNewActor As Actor2
    
    'create new actor
    Set loNewActor = New Actor2

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
        roActorsFAM As FastArrayManager2, roActors() As Actor2) As Actor2
    Dim loNewActor As Actor2
    Dim llNewActorIndex As Long
    
    'add to list
    llNewActorIndex = roActorsFAM.GetFreeIndex()
    If llNewActorIndex > 0 Then
        'create new actor
        Set loNewActor = CreateNewActor(rsBitMapID, roBrains)
        Set roActors(llNewActorIndex) = loNewActor
    Else
        Set loNewActor = Nothing
    End If
    
    'return the new alien
    Set AddNewActorToListGeneric = loNewActor
End Function

Private Function DropBombOrCargoGeneric(roFromActor As Actor2, roTargetActor As Actor2, _
        roBombsFAM As FastArrayManager2, roBombs() As Actor2, _
        Optional ByVal veBombDir As BombDir_Enum = bombDefaultDir, _
        Optional ByVal veCargoType As CargoType_Enum = cargoRandom, _
        Optional ByVal vlXOffset As Long = 0, _
        Optional ByVal vlOnScreenObjectLimit As Long = -1, _
        Optional ByVal vlNumObjectsInAllOrNothingGroup = 1 _
) As Boolean
    Dim llNewBombIndex As Long
    Dim lfStartX As Single
    Dim lfStartY As Single
    Dim lfTargetX As Single
    Dim lfTargetY As Single
    Dim loCargoBrains As BrainsCargo

gsErrorInfo = "1"
    If vlOnScreenObjectLimit > -1 Then
        If vlNumObjectsInAllOrNothingGroup + roBombsFAM.Count() > vlOnScreenObjectLimit Then
            DropBombOrCargoGeneric = False
            Exit Function
        End If
    End If
    
    If vlNumObjectsInAllOrNothingGroup > 1 Then
        If vlNumObjectsInAllOrNothingGroup + roBombsFAM.Count() > roBombsFAM.Max() Then
            DropBombOrCargoGeneric = False
            Exit Function
        End If
    End If
    
    llNewBombIndex = roBombsFAM.GetFreeIndex()

gsErrorInfo = "2"
    If llNewBombIndex > 0 Then
        With roBombs(llNewBombIndex)
            If TypeOf .oBrains Is BrainsCargo Then
                Set loCargoBrains = .oBrains
                loCargoBrains.eCargoType = veCargoType
            End If
            Call .ResetState
        End With
gsErrorInfo = "3"
            
        With roFromActor
            lfStartX = .CenterX() + vlXOffset
gsErrorInfo = "4"
            If veBombDir = bombStraightUp Then
                lfStartY = .GetTop()
            Else
                lfStartY = .GetBottom()
            End If
        End With
        
gsErrorInfo = "5"
        With roBombs(llNewBombIndex)
gsErrorInfo = "6"
'            With .oBitMapDefinition.GetFrameDefinition(.oSequencePlayer.CurrentBitMapFrame)
'gsErrorInfo = "7"
'                lfStartX = lfStartX - (.lXSize / 2!) - 1!
'                If Not veBombDir = bombStraightUp Then lfStartY = lfStartY + .lYSize
'            End With
gsErrorInfo = "8"
    
            .fX = lfStartX
            .fY = lfStartY
        
gsErrorInfo = "9"
            If Not veBombDir = bombDefaultDir Then
                If veBombDir = bombToTarget Then
                    With roTargetActor
                        Call .GetCenter(lfTargetX, lfTargetY)
                    End With
                    .lVelocityDirection = GetAngleFromXYSng(lfTargetX - lfStartX, lfTargetY - lfStartY)
                ElseIf veBombDir = bombStraightDown Then
                    .lVelocityDirection = 90
                ElseIf veBombDir = bombStraightUp Then
                    .lVelocityDirection = 270
                End If
            End If
        End With
gsErrorInfo = "10"
        
        DropBombOrCargoGeneric = True
    Else
        DropBombOrCargoGeneric = False
    End If
End Function

Public Function FirePlayerMissle() As Boolean
    If bHasDoubleShots Then
        If bHasMultiShots Then
            If DropBombOrCargoGeneric(oPlayer, Nothing, oMissilesFAM, oMissiles(), bombStraightUp, vlXOffset:=-4, vlNumObjectsInAllOrNothingGroup:=2) Then
                Call DropBombOrCargoGeneric(oPlayer, Nothing, oMissilesFAM, oMissiles(), bombStraightUp, vlXOffset:=4)
                FirePlayerMissle = True
            Else
                FirePlayerMissle = False
            End If
        Else
            If DropBombOrCargoGeneric(oPlayer, Nothing, oMissilesFAM, oMissiles(), bombStraightUp, vlXOffset:=-4, vlOnScreenObjectLimit:=4, vlNumObjectsInAllOrNothingGroup:=2) Then
                Call DropBombOrCargoGeneric(oPlayer, Nothing, oMissilesFAM, oMissiles(), bombStraightUp, vlXOffset:=4)
                FirePlayerMissle = True
            Else
                FirePlayerMissle = False
            End If
        End If
    Else
        If bHasMultiShots Then
            FirePlayerMissle = DropBombOrCargoGeneric(oPlayer, Nothing, oMissilesFAM, oMissiles(), bombStraightUp)
        Else
            FirePlayerMissle = DropBombOrCargoGeneric(oPlayer, Nothing, oMissilesFAM, oMissiles(), bombStraightUp, vlOnScreenObjectLimit:=2)
        End If
    End If
End Function

Public Function DropABomb(roBomber As Actor2) As Boolean
    DropABomb = DropBombOrCargoGeneric(roBomber, Nothing, oABombsFAM, oABombs(), bombStraightDown)
End Function

Public Function DropDBomb(roBomber As Actor2) As Boolean
    DropDBomb = DropBombOrCargoGeneric(roBomber, oPlayer, oDBombsFAM, oDBombs(), bombToTarget)
End Function

Public Function DropCargo(roCargoShip As Actor2, _
        Optional ByVal veCargoType As CargoType_Enum = cargoRandom) As Boolean
    DropCargo = DropBombOrCargoGeneric(roCargoShip, oPlayer, oCargoFAM, oCargo())
End Function

Public Sub ResetLevel()
    Dim llCtr As Long
    
    For llCtr = 1 To lNumBitMapDefinitions
        If Not oBitMapDefinitions(llCtr) Is Nothing Then Call oBitMapDefinitions(llCtr).Terminate
        Set oBitMapDefinitions(llCtr) = Nothing
    Next llCtr
    Erase oBitMapDefinitions()
    lNumBitMapDefinitions = 0
        
    If Not oPlayer Is Nothing Then Call oPlayer.Terminate
    Set oPlayer = Nothing
    
    For llCtr = 1 To lMaxNumAliens
        If Not oAliens(llCtr) Is Nothing Then Call oAliens(llCtr).Terminate
        Set oAliens(llCtr) = Nothing
    Next llCtr
    Erase oAliens()
    lMaxNumAliens = 0
    
    For llCtr = 1 To lMaxNumMissiles
        If Not oMissiles(llCtr) Is Nothing Then Call oMissiles(llCtr).Terminate
        Set oMissiles(llCtr) = Nothing
    Next llCtr
    Erase oMissiles()
    lMaxNumMissiles = 0
    
    For llCtr = 1 To lMaxNumABombs
        If Not oABombs(llCtr) Is Nothing Then Call oABombs(llCtr).Terminate
        Set oABombs(llCtr) = Nothing
    Next llCtr
    Erase oABombs()
    lMaxNumABombs = 0
    
    For llCtr = 1 To lMaxNumDBombs
        If Not oDBombs(llCtr) Is Nothing Then Call oDBombs(llCtr).Terminate
        Set oDBombs(llCtr) = Nothing
    Next llCtr
    Erase oDBombs()
    lMaxNumDBombs = 0

    For llCtr = 1 To lMaxNumCargo
        If Not oCargo(llCtr) Is Nothing Then Call oCargo(llCtr).Terminate
        Set oCargo(llCtr) = Nothing
    Next llCtr
    Erase oCargo()
    lMaxNumCargo = 0

    lBonusMultiplier = 1
    lBonus = lStartingBonus

    Set oSoundsCollection = Nothing
End Sub

Public Sub AddBonus(ByVal veBonusFrame As BonusFrame_Enum, ByVal vlX&, ByVal vlY&)
    If veBonusFrame = bonusFrameRandom Then
        veBonusFrame = (Rnd * 10)
    End If
    
    Call oGame.AddBonus(veBonusFrame, vlX, vlY)
    Select Case veBonusFrame
        Case BonusFrame_Enum.bonusFrameRed25: lBonus = lBonus + 25
        Case BonusFrame_Enum.bonusFrameRed50: lBonus = lBonus + 50
        Case BonusFrame_Enum.bonusFrameRed75: lBonus = lBonus + 75
        Case BonusFrame_Enum.bonusFrameRed100: lBonus = lBonus + 100
        Case BonusFrame_Enum.bonusFrame100: lBonus = lBonus + 100
        Case BonusFrame_Enum.bonusFrame200: lBonus = lBonus + 200
        Case BonusFrame_Enum.bonusFrame300: lBonus = lBonus + 300
        Case BonusFrame_Enum.bonusFrame400: lBonus = lBonus + 400
        Case BonusFrame_Enum.bonusFrame500: lBonus = lBonus + 500
        Case BonusFrame_Enum.bonusFrame600: lBonus = lBonus + 600
        Case BonusFrame_Enum.bonusFrame700: lBonus = lBonus + 700
        Case BonusFrame_Enum.bonusFrame800: lBonus = lBonus + 800
        Case BonusFrame_Enum.bonusFrame900: lBonus = lBonus + 900
        Case BonusFrame_Enum.bonusFrame1000: lBonus = lBonus + 1000
    End Select
End Sub

Public Sub SetBonusMultiplier(ByVal viBonusMultiplier As Integer)
    lBonusMultiplier = viBonusMultiplier
End Sub

Public Sub Terminate()
    If bTerminated Then Exit Sub
    bTerminated = True
    Call Me.ResetLevel
    Set oGame = Nothing
    Set ddsBackBufferSurface = Nothing
    Set ddDirectDraw = Nothing
    
    Set oAliensFAM = Nothing
    Set oMissilesFAM = Nothing
    Set oABombsFAM = Nothing
    Set oDBombsFAM = Nothing

'    If Not oPlayerInput Is Nothing Then Call oPlayerInput.Terminate
    Set oPlayerInput = Nothing
End Sub

Private Sub Class_Initialize()
    Set oPlayerInput = New PlayerInput
End Sub

Public Sub Class_Terminate()
    Call Terminate
End Sub
