VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
  Persistable = 0  'NotPersistable
  DataBindingBehavior = 0  'vbNone
  DataSourceBehavior  = 0  'vbNone
  MTSTransactionMode  = 0  'NotAnMTSObject
END
Attribute VB_Name = "BrainsXBonus"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = True
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = False
Option Explicit

Implements Brains

Private bTerminated As Boolean

Public lLongestWaitBeforeAppearanceTicks As Long
Public lAppearanceLengthTicks As Long

Private Enum State_Enum
    stateHasNotAppeared = 0
    stateVisible = 1
    stateGone = 3
End Enum

Private lTicksBeforeAppearance As Long
Private eState As State_Enum
Private lTicksPassed As Long
Private iMultiplier As Integer

Private oFrameSequence_Normal(2 To 5) As FrameSequence

Private oSoundEffect_Announce As SoundEffect
Private oSoundEffect_Explode As SoundEffect

Private oActor As Actor2
Private oLevel As Level

Public Sub Brains_Initialize(roLevel As Level, roActor As Actor2)
    Set oActor = roActor
    Set oLevel = roLevel
        
    With oActor.oBitMapDefinition
        Set oFrameSequence_Normal(2) = .GetFrameSequence(.GetFrameSequenceHandle("2XBONUS"))
        Set oFrameSequence_Normal(3) = .GetFrameSequence(.GetFrameSequenceHandle("3XBONUS"))
        Set oFrameSequence_Normal(4) = .GetFrameSequence(.GetFrameSequenceHandle("4XBONUS"))
        Set oFrameSequence_Normal(5) = .GetFrameSequence(.GetFrameSequenceHandle("5XBONUS"))
    End With
    
    With oLevel
        Set oSoundEffect_Announce = .GetSoundEffect("SLUDGE")
        Set oSoundEffect_Explode = .GetSoundEffect("PHONE")
    End With
End Sub

Public Sub Brains_ResetState()
    With oActor
        iMultiplier = Int(Rnd * 4 + 2)
        eState = stateHasNotAppeared
        Call .oSequencePlayer.PlayFrameSequence(Nothing)
        .lCanBeHitByMissiles = 0&
        lTicksPassed = 0
        Call .SetMovementNormal( _
            Rnd * (oLevel.lPlayWidth - .oBitMapDefinition.lXFrameSize), _
            oLevel.lPlayHeight - 96, _
            0, 0)
    End With

    lTicksBeforeAppearance = Rnd * lLongestWaitBeforeAppearanceTicks
End Sub

Public Sub Brains_UpdateState()
    Dim llX As Long
    Dim llY As Long
            
    With oActor
        If (eState = stateHasNotAppeared) And (oLevel.lTicksPassed > 0) Then
            lTicksPassed = lTicksPassed + oLevel.lTicksPassed
            'need new exponential function...? chances increase exponentially as time goes on
            If lTicksPassed >= lTicksBeforeAppearance Then
                oSoundEffect_Announce.Play
                eState = stateVisible
                lTicksPassed = 0
                .lCanBeHitByMissiles = 1&
                Call .oSequencePlayer.PlayFrameSequence(oFrameSequence_Normal(iMultiplier))
            End If
        End If
        
        If (eState = stateVisible) Then
            If .lWasHitByMissiles > 0& Then
                oSoundEffect_Explode.Play
                llX = .fX
                llY = .fY
                With oLevel
                    Call .SetBonusMultiplier(iMultiplier)
                End With
                Call .oSequencePlayer.PlayFrameSequence(Nothing)
                eState = stateGone
                .lCanBeHitByMissiles = 0&
                .bDelete = True
            
            Else
                lTicksPassed = lTicksPassed + oLevel.lTicksPassed
                If lTicksPassed > lAppearanceLengthTicks Then
                    Call .oSequencePlayer.PlayFrameSequence(Nothing)
                    eState = stateGone
                    .lCanBeHitByMissiles = 0&
                    .bDelete = True
                End If
            End If
        End If
        
    End With
End Sub

Private Sub Class_Initialize()
    lLongestWaitBeforeAppearanceTicks = 30000
    lAppearanceLengthTicks = 4500
End Sub

Private Sub Brains_Terminate()
    If bTerminated Then Exit Sub
    bTerminated = True
    Set oFrameSequence_Normal(2) = Nothing
    Set oFrameSequence_Normal(3) = Nothing
    Set oFrameSequence_Normal(4) = Nothing
    Set oFrameSequence_Normal(5) = Nothing
    Set oSoundEffect_Explode = Nothing
    Set oSoundEffect_Announce = Nothing
    Set oActor = Nothing
    Set oLevel = Nothing
End Sub

'Public Sub Class_Terminate()
'    Call Brains.Terminate
'End Sub

