VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
  Persistable = 0  'NotPersistable
  DataBindingBehavior = 0  'vbNone
  DataSourceBehavior  = 0  'vbNone
  MTSTransactionMode  = 0  'NotAnMTSObject
END
Attribute VB_Name = "BrainsAlienA"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = True
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = False
Option Explicit

Implements Brains

Private bTerminated As Boolean

Private Enum State_Enum
    stateNormal = 0
    stateExploding = 1
End Enum

Private eState As State_Enum

Private oFrameSequence_Normal As FrameSequence
Private oFrameSequence_Explode As FrameSequence

Private oSoundEffect_Explode As SoundEffect

Private oActor As Actor2
Private oLevel As Level

Public Sub Brains_Initialize(roLevel As Level, roActor As Actor2)
    Set oActor = roActor
    Set oLevel = roLevel
        
    With oActor.oBitMapDefinition
        Set oFrameSequence_Normal = .GetFrameSequence(.GetFrameSequenceHandle("NORMAL"))
        Set oFrameSequence_Explode = .GetFrameSequence(.GetFrameSequenceHandle("EXPLODE"))
    End With
    
    With oLevel
        Set oSoundEffect_Explode = .GetSoundEffect("WHOOSH")
    End With
End Sub

Public Sub Brains_ResetState()
    eState = stateNormal
    With oActor
        Call .oSequencePlayer.PlayFrameSequence(oFrameSequence_Normal, True)
        .lCanBeHitByMissiles = 1&
        .bCanHitPlayer = False
    End With
End Sub

Public Sub Brains_UpdateState()
    With oActor
        
        If eState = stateNormal Then
            If .lWasHitByMissiles > 0& Then
                eState = stateExploding
                oSoundEffect_Explode.Play
                Call .oSequencePlayer.PlayFrameSequence(oFrameSequence_Explode)
                With oLevel
                    .lScore = .lScore + 10
                End With
                .lCanBeHitByMissiles = 0&
            End If
        
        ElseIf eState = stateExploding Then
            If .oSequencePlayer.IsFinishedPlaying Then
                .bDelete = True
            End If
            
        End If 'STATE

    End With
End Sub

Private Sub Brains_Terminate()
    If bTerminated Then Exit Sub
    bTerminated = True
    Set oFrameSequence_Normal = Nothing
    Set oFrameSequence_Explode = Nothing
    Set oSoundEffect_Explode = Nothing
    Set oActor = Nothing
    Set oLevel = Nothing
End Sub

'Public Sub Class_Terminate()
'    Call Brains.Terminate
'End Sub
