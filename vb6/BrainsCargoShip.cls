VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
  Persistable = 0  'NotPersistable
  DataBindingBehavior = 0  'vbNone
  DataSourceBehavior  = 0  'vbNone
  MTSTransactionMode  = 0  'NotAnMTSObject
END
Attribute VB_Name = "BrainsCargoShip"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = True
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = False
Option Explicit

Implements Brains

Private bTerminated As Boolean

Private Enum State_Enum
    stateIdle = 0
    stateNormal = 1
    stateExploding = 2
    stateRetired = 3
End Enum

Private Enum Direction_Enum
    directionLeft = 0
    directionRight = 1
End Enum

Private eState As State_Enum
Private eDirection As Direction_Enum

Public lMaxAppearances As Long
Private lAppearances As Long

Public lLongestWaitBeforeAppearanceTicks As Long
Private lTicksBeforeAppearance As Long
Private lTicksPassed As Long

Public lVelocity As Long
Private lVelocityDirection(0 To 1) As Long

Private fStartingXPosition(0 To 1) As Single

Private oFrameSequence_Normal(0 To 1) As FrameSequence
Private oFrameSequence_Explode(0 To 1) As FrameSequence

Private oSoundEffect_Announce As SoundEffect
Private oSoundEffect_Explode As SoundEffect

Private oActor As Actor2
Private oLevel As Level

Public Sub Brains_Initialize(roLevel As Level, roActor As Actor2)
    Set oActor = roActor
    Set oLevel = roLevel
        
    With oActor.oBitMapDefinition
        Set oFrameSequence_Normal(0) = .GetFrameSequence(.GetFrameSequenceHandle("GO_LEFT"))
        Set oFrameSequence_Normal(1) = .GetFrameSequence(.GetFrameSequenceHandle("GO_RIGHT"))
        Set oFrameSequence_Explode(0) = .GetFrameSequence(.GetFrameSequenceHandle("EXPLODE_LEFT"))
        Set oFrameSequence_Explode(1) = .GetFrameSequence(.GetFrameSequenceHandle("EXPLODE_RIGHT"))
    
        fStartingXPosition(0) = oLevel.lPlayWidth
        fStartingXPosition(1) = 0 - .lXFrameSize
    End With

    lVelocityDirection(0) = 180
    lVelocityDirection(1) = 0
    
    With oLevel
        Set oSoundEffect_Explode = .GetSoundEffect("BOOM1")
        Set oSoundEffect_Announce = .GetSoundEffect("HEYHEYHEY")
    End With
End Sub

Public Sub Brains_ResetState()
    With oActor
        Call .oSequencePlayer.PlayFrameSequence(Nothing)
        .lCanBeHitByMissiles = 0&
        .lVelocity = lVelocity
        .fY = 10
    End With
    
    eState = stateIdle
    lAppearances = 0
    lTicksPassed = 0
    lTicksBeforeAppearance = Rnd * lLongestWaitBeforeAppearanceTicks
End Sub

Public Sub Brains_UpdateState()
    With oActor

        If eState = stateIdle Then
            lTicksPassed = lTicksPassed + oLevel.lTicksPassed
            'need new exponential function...? chances increase exponentially as time goes on
'            If lTicksPassed >= lTicksBeforeAppearance Then
            If (lTicksPassed >= lTicksBeforeAppearance) Or _
                    DirectInput_IsKeyDown(DIK_S) Then
                eDirection = Int(Rnd * 2)
                .lVelocityDirection = lVelocityDirection(eDirection)
                .lVelocity = lVelocity
                oSoundEffect_Announce.Play
                Call .oSequencePlayer.PlayFrameSequence(oFrameSequence_Normal(eDirection))
                .fX = fStartingXPosition(eDirection)
                .lCanBeHitByMissiles = 1&
                lAppearances = lAppearances + 1
                eState = stateNormal
                .bIsOffScreenRight = False
                .bIsOffScreenLeft = False
            End If
        
        ElseIf eState = stateNormal Then
            If .lWasHitByMissiles > 0& Then
                oSoundEffect_Explode.Play
                Call .oSequencePlayer.PlayFrameSequence(oFrameSequence_Explode(eDirection))
                .lVelocity = 0
                eState = stateExploding
                Call oLevel.DropCargo(oActor)
            End If
        End If
        
        If ((eState = stateExploding) And .oSequencePlayer.IsFinishedPlaying) _
                Or ((eState = stateNormal) And _
                    (((eDirection = directionLeft) And .bIsOffScreenLeft) Or _
                    ((eDirection = directionRight) And .bIsOffScreenRight))) Then
            Call .oSequencePlayer.PlayFrameSequence(Nothing)
            .lCanBeHitByMissiles = 0&
            .lWasHitByMissiles = 0&
            If lAppearances >= lMaxAppearances Then
                eState = stateRetired
            Else
                eState = stateIdle
                lTicksPassed = 0
                lTicksBeforeAppearance = Rnd * (lLongestWaitBeforeAppearanceTicks - 5000) + 5000
            End If
        End If

    End With
End Sub

Private Sub Brains_Terminate()
    If bTerminated Then Exit Sub
    bTerminated = True
    Set oFrameSequence_Normal(0) = Nothing
    Set oFrameSequence_Normal(1) = Nothing
    Set oFrameSequence_Explode(0) = Nothing
    Set oFrameSequence_Explode(1) = Nothing
    Set oSoundEffect_Announce = Nothing
    Set oSoundEffect_Explode = Nothing
    Set oActor = Nothing
    Set oLevel = Nothing
End Sub

'Public Sub Class_Terminate()
'    Call Brains.Terminate
'End Sub

Private Sub Class_Initialize()
    Dim llRandom As Long
    llRandom = Int(Rnd * 6)
    If llRandom = 5 Then
        lMaxAppearances = 3
    ElseIf llRandom >= 3 Then
        lMaxAppearances = 2
    Else
        lMaxAppearances = 1
    End If
    lLongestWaitBeforeAppearanceTicks = 30000
    lVelocity = 50
End Sub
