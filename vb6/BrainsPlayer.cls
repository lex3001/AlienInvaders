VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
  Persistable = 0  'NotPersistable
  DataBindingBehavior = 0  'vbNone
  DataSourceBehavior  = 0  'vbNone
  MTSTransactionMode  = 0  'NotAnMTSObject
END
Attribute VB_Name = "BrainsPlayer"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = True
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = False
Option Explicit

Implements Brains

Private bTerminated As Boolean

Private Enum State_Enum
    stateNormal = 0
    stateShields = 1
    stateExploding = 2
End Enum

Private eState As State_Enum

Public lVelocity As Long
Public lMissileRechargeTicks As Long
Private lTicksSinceLastMissle As Long

Private oFrameSequence_Normal As FrameSequence
Private oFrameSequence_Shields As FrameSequence
Private oFrameSequence_Explode As FrameSequence

Private oSoundEffect_Missile As SoundEffect
Private oSoundEffect_Explode As SoundEffect

Private oActor As Actor2
Private oLevel As Level

Const bFastShots = True

Public Sub Brains_Initialize(roLevel As Level, roActor As Actor2)
    Set oActor = roActor
    Set oLevel = roLevel
        
    With oActor.oBitMapDefinition
        Set oFrameSequence_Normal = .GetFrameSequence(.GetFrameSequenceHandle("NORMAL"))
        Set oFrameSequence_Shields = .GetFrameSequence(.GetFrameSequenceHandle("SHIELDS"))
        Set oFrameSequence_Explode = .GetFrameSequence(.GetFrameSequenceHandle("EXPLODE"))
    End With

    With oActor
        .bStopAtBorderLeft = True
        .bStopAtBorderRight = True
        .bStopAtBorderTop = True
        .bStopAtBorderBottom = True
    End With

    With oLevel
        Set oSoundEffect_Missile = .GetSoundEffect("LASER")
        Set oSoundEffect_Explode = .GetSoundEffect("DOH3")
    End With
End Sub

Public Sub Brains_ResetState()
    eState = stateNormal
    With oActor
        Call .oSequencePlayer.PlayFrameSequence(oFrameSequence_Normal)
        .lCanBeHitByMissiles = 1&
    End With
    
    lTicksSinceLastMissle = lMissileRechargeTicks
    oLevel.bShieldsOn = False
End Sub

Public Sub Brains_UpdateState()
    Dim llMissileRechargeTicksNeeded As Long
    
    With oActor
        
        If eState = stateNormal Then
            If .lWasHitByMissiles > 0& Then
                eState = stateExploding
                oSoundEffect_Explode.Play
                Call .oSequencePlayer.PlayFrameSequence(oFrameSequence_Explode)
                .lVelocity = 0
                With oLevel
                    .lScore = .lScore + 10
                End With
                .lCanBeHitByMissiles = 0&
            
            Else
                With oLevel.oPlayerInput
                    'shields
                    If .bShieldsRequested And oLevel.lShieldsLeft > 0 Then
                        Call oActor.oSequencePlayer.PlayFrameSequence(oFrameSequence_Shields)
                        eState = stateShields
                        oLevel.bShieldsOn = True
                    End If
                End With
            End If
            
        ElseIf eState = stateShields Then
            With oLevel
                .lShieldsLeft = .lShieldsLeft - .lTicksPassed
            End With
            With oLevel.oPlayerInput
                If (Not .bShieldsRequested) Or (oLevel.lShieldsLeft <= 0) Then
                    Call oActor.oSequencePlayer.PlayFrameSequence(oFrameSequence_Normal)
                    eState = stateNormal
                    oLevel.bShieldsOn = False
                End If
            End With
        
        ElseIf eState = stateExploding Then
            If .oSequencePlayer.IsFinishedPlaying Then
                .bDelete = True
                oLevel.bIsPlayerDead = True
            End If
            
        End If 'STATE
                    
        If (eState = stateNormal) Or (eState = stateShields) Then
            With oLevel.oPlayerInput
                'player movement
                If .bMoveLeftRequested Then
                    oActor.lVelocityDirection = 180
                    oActor.lVelocity = lVelocity
                ElseIf .bMoveRightRequested Then
                    oActor.lVelocityDirection = 0
                    oActor.lVelocity = lVelocity
                ElseIf .bStopMoveRequested Then
                    oActor.lVelocity = 0
                End If
        
                'missles
                lTicksSinceLastMissle = lTicksSinceLastMissle + oLevel.lTicksPassed
                If oLevel.bHasRapidFire Then
                    llMissileRechargeTicksNeeded = lMissileRechargeTicks / 2
                Else
                    llMissileRechargeTicksNeeded = lMissileRechargeTicks
                End If
                If .bMissleRequested And (lTicksSinceLastMissle >= llMissileRechargeTicksNeeded) Then
                    'Fire Missle!
                    If oLevel.FirePlayerMissle() Then
                        oSoundEffect_Missile.Play
                        lTicksSinceLastMissle = 0
                    End If
                End If
            End With
        End If

    End With
End Sub

Private Sub Class_Initialize()
    lVelocity = 90
    lMissileRechargeTicks = 750
End Sub

Private Sub Brains_Terminate()
    If bTerminated Then Exit Sub
    bTerminated = True
    Set oFrameSequence_Normal = Nothing
    Set oFrameSequence_Shields = Nothing
    Set oFrameSequence_Explode = Nothing
    Set oSoundEffect_Missile = Nothing
    Set oSoundEffect_Explode = Nothing
    Set oActor = Nothing
    Set oLevel = Nothing
End Sub

'Public Sub Class_Terminate()
'    Call Brains.Terminate
'End Sub

