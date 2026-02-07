VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
  Persistable = 0  'NotPersistable
  DataBindingBehavior = 0  'vbNone
  DataSourceBehavior  = 0  'vbNone
  MTSTransactionMode  = 0  'NotAnMTSObject
END
Attribute VB_Name = "BrainsPlanet"
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
    stateGoing = 2
    stateGone = 3
End Enum

Private eState As State_Enum
Private lTicksPassed As Long
Private lTicksBeforeAppearance

Private oFrameSequence_Normal As FrameSequence
Private oFrameSequence_Entry As FrameSequence
Private oFrameSequence_Exit As FrameSequence

Private oSoundEffect_Explode As SoundEffect

Private oActor As Actor2
Private oLevel As Level

Public Sub Brains_Initialize(roLevel As Level, roActor As Actor2)
    Set oActor = roActor
    Set oLevel = roLevel
        
    With oActor.oBitMapDefinition
        Set oFrameSequence_Normal = .GetFrameSequence(.GetFrameSequenceHandle("NORMAL"))
        Set oFrameSequence_Entry = .GetFrameSequence(.GetFrameSequenceHandle("ENTERING"))
        Set oFrameSequence_Exit = .GetFrameSequence(.GetFrameSequenceHandle("LEAVING"))
    End With
    
    With oLevel
        Set oSoundEffect_Explode = .GetSoundEffect("SPLAT")
    End With
End Sub

Public Sub Brains_ResetState()
    With oActor
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
                eState = stateVisible
                lTicksPassed = 0
                .lCanBeHitByMissiles = 1&
                Call .oSequencePlayer.PlayFrameSequence(oFrameSequence_Entry, , oFrameSequence_Normal)
            End If
        End If
        
        If (eState = stateVisible) Or (eState = stateGoing) Then
            If .lWasHitByMissiles > 0& Then
                llX = .fX
                llY = .fY
                oSoundEffect_Explode.Play
                With oLevel
                    Call .AddBonus(bonusFrameRandom, llX, llY)
                End With
                If Not (eState = stateGoing) Then
                    Call .oSequencePlayer.PlayFrameSequence(oFrameSequence_Exit)
                End If
                eState = stateGone
                .lCanBeHitByMissiles = 0&
            End If
        End If
        
        If (eState = stateVisible) Then
            lTicksPassed = lTicksPassed + oLevel.lTicksPassed
            If lTicksPassed > lAppearanceLengthTicks Then
                Call .oSequencePlayer.PlayFrameSequence(oFrameSequence_Exit)
                eState = stateGoing
            End If
        End If
        
        If (eState = stateGoing) Or (eState = stateGone) Then
            If .oSequencePlayer.IsFinishedPlaying Then
                .bDelete = True
                .lCanBeHitByMissiles = 0&
            End If
            
        End If
        
    End With
End Sub

Private Sub Class_Initialize()
    lLongestWaitBeforeAppearanceTicks = 30000
    lAppearanceLengthTicks = 5000
End Sub

Private Sub Brains_Terminate()
    If bTerminated Then Exit Sub
    bTerminated = True
    Set oFrameSequence_Normal = Nothing
    Set oFrameSequence_Entry = Nothing
    Set oFrameSequence_Exit = Nothing
    Set oSoundEffect_Explode = Nothing
    Set oActor = Nothing
    Set oLevel = Nothing
End Sub

'Public Sub Class_Terminate()
'    Call Brains.Terminate
'End Sub
