VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
END
Attribute VB_Name = "BrainsMissile"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = True
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = False
Option Explicit

Implements Brains

Private bTerminated As Boolean

Private oFrameSequence_Normal As FrameSequence

Private oActor As Actor2
Private oLevel As Level

Public Sub Brains_Initialize(roLevel As Level, roActor As Actor2)
    Set oActor = roActor
    Set oLevel = roLevel
        
    With oActor.oBitMapDefinition
        Set oFrameSequence_Normal = .GetFrameSequence(.GetFrameSequenceHandle("NORMAL"))
    End With
End Sub

Public Sub Brains_ResetState()
    With oActor
        Call .oSequencePlayer.PlayFrameSequence(oFrameSequence_Normal)
    End With
End Sub

Public Sub Brains_UpdateState()
    With oActor
        If .bIsOffScreen Then .bDelete = True
    End With
End Sub

Private Sub Brains_Terminate()
    If bTerminated Then Exit Sub
    bTerminated = True
    Set oFrameSequence_Normal = Nothing
    Set oActor = Nothing
    Set oLevel = Nothing
End Sub
