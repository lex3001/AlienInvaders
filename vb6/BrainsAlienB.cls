VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
  Persistable = 0  'NotPersistable
  DataBindingBehavior = 0  'vbNone
  DataSourceBehavior  = 0  'vbNone
  MTSTransactionMode  = 0  'NotAnMTSObject
END
Attribute VB_Name = "BrainsAlienB"
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
Private lNumberOfLegs As Long

Private oFrameSequence_Normal(0 To 3) As FrameSequence
Private oFrameSequence_TransitionTo(0 To 2) As FrameSequence
Private oFrameSequence_Explode As FrameSequence

Private oSoundEffect_LoseLeg As SoundEffect
Private oSoundEffect_Explode As SoundEffect

Private oActor As Actor2
Private oLevel As Level

Public Sub Brains_Initialize(roLevel As Level, roActor As Actor2)
    Set oActor = roActor
    Set oLevel = roLevel
        
    With oActor.oBitMapDefinition
        Set oFrameSequence_Normal(3) = .GetFrameSequence(.GetFrameSequenceHandle("3_LEGS"))
        Set oFrameSequence_Normal(2) = .GetFrameSequence(.GetFrameSequenceHandle("2_LEGS"))
        Set oFrameSequence_Normal(1) = .GetFrameSequence(.GetFrameSequenceHandle("1_LEG"))
        Set oFrameSequence_Normal(0) = .GetFrameSequence(.GetFrameSequenceHandle("0_LEGS"))
        Set oFrameSequence_TransitionTo(2) = .GetFrameSequence(.GetFrameSequenceHandle("3_LEGS_HIT"))
        Set oFrameSequence_TransitionTo(1) = .GetFrameSequence(.GetFrameSequenceHandle("2_LEGS_HIT"))
        Set oFrameSequence_TransitionTo(0) = .GetFrameSequence(.GetFrameSequenceHandle("1_LEG_HIT"))
        Set oFrameSequence_Explode = .GetFrameSequence(.GetFrameSequenceHandle("EXPLODE"))
    End With
    
    With oLevel
        Set oSoundEffect_LoseLeg = .GetSoundEffect("GRUNT1")
        Set oSoundEffect_Explode = .GetSoundEffect("WHOOSH")
    End With
End Sub

Public Sub Brains_ResetState()
    lNumberOfLegs = 3
    eState = stateNormal
    With oActor
        Call .oSequencePlayer.PlayFrameSequence(oFrameSequence_Normal(lNumberOfLegs), True)
        .lCanBeHitByMissiles = lNumberOfLegs + 1&
        .bCanHitPlayer = False
    End With
End Sub

Public Sub Brains_UpdateState()
    With oActor
        
        If eState = stateNormal Then
            If .lWasHitByMissiles > 0& Then
                lNumberOfLegs = lNumberOfLegs - .lWasHitByMissiles
                .lWasHitByMissiles = 0&
                If lNumberOfLegs < 0 Then
                    eState = stateExploding
                    oSoundEffect_Explode.Play
                    Call .oSequencePlayer.PlayFrameSequence(oFrameSequence_Explode)
                    With oLevel
                        .lScore = .lScore + 10
                    End With
                    .lCanBeHitByMissiles = 0&
                Else
                    .lCanBeHitByMissiles = lNumberOfLegs + 1&
                    'General_PlaySound(X, False)
                    oSoundEffect_LoseLeg.Play
                    Call .oSequencePlayer.PlayFrameSequence( _
                        oFrameSequence_TransitionTo(lNumberOfLegs), , _
                        oFrameSequence_Normal(lNumberOfLegs))
                    With oLevel
                        .lScore = .lScore + 5
                    End With
                End If
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
    Dim llCtr As Long
    
    For llCtr = LBound(oFrameSequence_Normal) To UBound(oFrameSequence_Normal)
        Set oFrameSequence_Normal(llCtr) = Nothing
    Next llCtr
'    Erase oFrameSequence_Normal()
    
    For llCtr = LBound(oFrameSequence_TransitionTo) To UBound(oFrameSequence_TransitionTo)
        Set oFrameSequence_TransitionTo(llCtr) = Nothing
    Next llCtr
'    Erase oFrameSequence_TransitionTo()
    
    Set oFrameSequence_Explode = Nothing
    Set oSoundEffect_LoseLeg = Nothing
    Set oSoundEffect_Explode = Nothing
    
    Set oActor = Nothing
    Set oLevel = Nothing
End Sub

'Public Sub Class_Terminate()
'    Call Brains.Terminate
'End Sub

