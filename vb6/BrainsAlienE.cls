VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
  Persistable = 0  'NotPersistable
  DataBindingBehavior = 0  'vbNone
  DataSourceBehavior  = 0  'vbNone
  MTSTransactionMode  = 0  'NotAnMTSObject
END
Attribute VB_Name = "BrainsAlienE"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = True
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = False
Option Explicit

Implements Brains

Private bTerminated As Boolean

Public lAverageAttackIntervalTicks As Long
Public lMinAttackTurnInterval As Long
Public lMaxAttackTurnInterval As Long
Public lAverageBombRateAttack As Long
Public lAverageBombRateFormation As Long

Private lAttackTurnIntervalTicks As Long
Private lAttackTurnIntervalTicksPassed As Long

Private Enum State_Enum
    stateNormal = 0
    stateAttackingRight = 1
    stateAttackingLeft = 2
    stateExploding = 3
End Enum

Private eState As State_Enum
Private lExplodeSequence As Long
Private eSaveMovementType As MovementTypes_Enum

Private oFrameSequence_Formation As FrameSequence
Private oFrameSequence_AttackLeft As FrameSequence
Private oFrameSequence_AttackRight As FrameSequence
Private oFrameSequence_TurnLeft As FrameSequence
Private oFrameSequence_TurnRight As FrameSequence
Private oFrameSequence_EnterFormation As FrameSequence
Private oFrameSequence_Explode(0 To 2) As FrameSequence

Private oSoundEffect_Explode As SoundEffect

Private oActor As Actor2
Private oLevel As Level

Public Sub Brains_Initialize(roLevel As Level, roActor As Actor2)
    Set oActor = roActor
    Set oLevel = roLevel
        
    With oActor.oBitMapDefinition
        Set oFrameSequence_Formation = .GetFrameSequence(.GetFrameSequenceHandle("FORMATION"))
        Set oFrameSequence_AttackLeft = .GetFrameSequence(.GetFrameSequenceHandle("ATTACK_LEFT"))
        Set oFrameSequence_AttackRight = .GetFrameSequence(.GetFrameSequenceHandle("ATTACK_RIGHT"))
        Set oFrameSequence_TurnLeft = .GetFrameSequence(.GetFrameSequenceHandle("TURN_LEFT"))
        Set oFrameSequence_TurnRight = .GetFrameSequence(.GetFrameSequenceHandle("TURN_RIGHT"))
        Set oFrameSequence_EnterFormation = .GetFrameSequence(.GetFrameSequenceHandle("ENTER_FORMATION"))
        Set oFrameSequence_Explode(0) = .GetFrameSequence(.GetFrameSequenceHandle("FORMATION_EXPLODE"))
        Set oFrameSequence_Explode(1) = .GetFrameSequence(.GetFrameSequenceHandle("ATTACK_LEFT_EXPLODE"))
        Set oFrameSequence_Explode(2) = .GetFrameSequence(.GetFrameSequenceHandle("ATTACK_RIGHT_EXPLODE"))
            
    End With
    
    With oLevel
        Set oSoundEffect_Explode = .GetSoundEffect("WHOOSH")
    End With
End Sub

Public Sub Brains_ResetState()
    eState = stateNormal
    lExplodeSequence = 0
    
    With oActor
        Call .oSequencePlayer.PlayFrameSequence(oFrameSequence_Formation, True)
        .lCanBeHitByMissiles = 1&
        .bCanHitPlayer = False
    End With
End Sub

Public Sub Brains_UpdateState()
    Dim llX As Long
    Dim llY As Long

    With oActor
        
        If eState = stateExploding Then
            If .oSequencePlayer.IsFinishedPlaying Then
                .bDelete = True
            End If
        
        ElseIf .lWasHitByMissiles > 0& Then
            oSoundEffect_Explode.Play
            'General_PlaySound(X, False)
            Call .oSequencePlayer.PlayFrameSequence(oFrameSequence_Explode(lExplodeSequence))
            llX = .fX
            llY = .fY
            With oLevel
                .lScore = .lScore + 10
                If eState <> stateNormal Then
                    Call .AddBonus(bonusFrameRed25, llX, llY)
                End If
            End With
            eState = stateExploding
            .lCanBeHitByMissiles = 0&
            .bCanHitPlayer = False
            
        ElseIf .bHitPlayer Or .bHitShields Then
            'General_PlaySound(X, False)
            Call .oSequencePlayer.PlayFrameSequence(oFrameSequence_Explode(lExplodeSequence))
            With oLevel
                .lScore = .lScore + 10
            End With
            eState = stateExploding
            .lCanBeHitByMissiles = 0&
            .bCanHitPlayer = False

        ElseIf eState = stateNormal Then
            If Rnd < (oLevel.lTicksPassed / lAverageBombRateFormation) Then
                Call oLevel.DropABomb(oActor)
            End If
            
            If Rnd < (oLevel.lTicksPassed / lAverageAttackIntervalTicks) Then
                .bCanHitPlayer = True
                eSaveMovementType = .eMovementType
                .eMovementType = movementNormal
                .lVelocity = 30
                If 1 = Int(Rnd * 2) Then
                    eState = stateAttackingLeft
                    lExplodeSequence = 1
                    Call .oSequencePlayer.PlayFrameSequence(oFrameSequence_AttackLeft)
                    .lVelocityDirection = 135
                Else
                    eState = stateAttackingRight
                    lExplodeSequence = 2
                    Call .oSequencePlayer.PlayFrameSequence(oFrameSequence_AttackRight)
                    .lVelocityDirection = 45
                End If
                lAttackTurnIntervalTicksPassed = 0
                lAttackTurnIntervalTicks = (Rnd * (lMaxAttackTurnInterval - lMinAttackTurnInterval)) + lMinAttackTurnInterval
            End If
        
        Else
            If Rnd < (oLevel.lTicksPassed / lAverageBombRateAttack) Then
                Call oLevel.DropABomb(oActor)
            End If
            
            lAttackTurnIntervalTicksPassed = lAttackTurnIntervalTicksPassed + oLevel.lTicksPassed
            If lAttackTurnIntervalTicksPassed > lAttackTurnIntervalTicks Then
                lAttackTurnIntervalTicksPassed = 0
                lAttackTurnIntervalTicks = (Rnd * (lMaxAttackTurnInterval - lMinAttackTurnInterval)) + lMinAttackTurnInterval
                If eState = stateAttackingRight Then
                    eState = stateAttackingLeft
                    lExplodeSequence = 1
                    Call .oSequencePlayer.PlayFrameSequence(oFrameSequence_TurnLeft, , _
                        oFrameSequence_AttackLeft)
                    .lVelocityDirection = 135
                Else
                    eState = stateAttackingRight
                    lExplodeSequence = 2
                    Call .oSequencePlayer.PlayFrameSequence(oFrameSequence_TurnRight, , _
                        oFrameSequence_AttackRight)
                    .lVelocityDirection = 45
                End If
            End If
            
            If .bIsOffScreenBottom Then
                .bCanHitPlayer = False
                .eMovementType = eSaveMovementType
                Call .oSequencePlayer.PlayFrameSequence(oFrameSequence_EnterFormation, _
                        , oFrameSequence_Formation)
                lExplodeSequence = 0
                eState = stateNormal
            End If
        End If
            
    End With
End Sub

Private Sub Class_Initialize()
    lAverageAttackIntervalTicks = 15000
    lMinAttackTurnInterval = 2500
    lMaxAttackTurnInterval = 4500
    lAverageBombRateAttack = 2000
    lAverageBombRateFormation = 10000
End Sub

Private Sub Brains_Terminate()
    If bTerminated Then Exit Sub
    bTerminated = True
    Set oFrameSequence_Formation = Nothing
    Set oFrameSequence_AttackLeft = Nothing
    Set oFrameSequence_AttackRight = Nothing
    Set oFrameSequence_TurnLeft = Nothing
    Set oFrameSequence_TurnRight = Nothing
    Set oFrameSequence_EnterFormation = Nothing
    Set oFrameSequence_Explode(0) = Nothing
    Set oFrameSequence_Explode(1) = Nothing
    Set oFrameSequence_Explode(2) = Nothing
    Set oSoundEffect_Explode = Nothing
    Set oActor = Nothing
    Set oLevel = Nothing
End Sub

'Public Sub Class_Terminate()
'    Call Brains.Terminate
'End Sub



