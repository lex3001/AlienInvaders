VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
END
Attribute VB_Name = "BrainsABomb"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = True
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = False
Option Explicit

Implements Brains

Private Enum State_Enum
    stateNormal = 0
    stateExploding = 1
End Enum

Private eState As State_Enum

Private oFrameSequence_Normal As FrameSequence
Private oFrameSequence_Explode As FrameSequence

Public Sub Brains_Initialize(roActor As Actor2)
    With roActor.oBitMapDefinition
        Set oFrameSequence_Normal = .GetFrameSequence(.GetFrameSequenceHandle("NORMAL"))
        Set oFrameSequence_Explosion = .GetFrameSequence(.GetFrameSequenceHandle("EXPLODE"))
    End With
            
    eState = stateNormal
    With roActor
        Call .oSequencePlayer.PlayFrameSequence(oFrameSequence_Normal)
        .bCanBeHitByMissle = True
    End With
End Sub

Public Sub Brains_UpdateState(roGame As Game2, roActor As Actor2)
    With roActor
        
        If eState = stateNormal Then
            If .bWasHitByMissle Then
                eState = stateExploding
                'General_PlaySound(X, False)
                Call .oSequencePlayer.PlayFrameSequence(oFrameSequence_Explode)
                With roGame
                    .lScore = .lScore + 10
                End With
                .bCanBeHitByMissle = False
            End If
        
        ElseIf eState = stateExploding Then
            If .oSequencePlayer.IsFinishedPlaying Then
                .bDelete = True
            End If
            
        End If 'STATE

    End With
End Sub
