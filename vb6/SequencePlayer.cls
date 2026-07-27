VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
END
Attribute VB_Name = "SequencePlayer"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = True
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = False
Option Explicit

Private bTerminated As Boolean
Private eCurrentDirection As SequenceDirection_Enum
Private bFinishedPlaying As Boolean
Private lCurrentFrame As Long
Private oFrameSequence As FrameSequence
Private oNextFrameSequence As FrameSequence
Private lTicksSinceLastFrame As Long

Public Sub PlayFrameSequence(roFrameSequence As FrameSequence, _
        Optional ByVal vbStartWithRandomFrame As Boolean = False, _
        Optional roNextFrameSequence As FrameSequence = Nothing)
    Set oFrameSequence = roFrameSequence
    Set oNextFrameSequence = roNextFrameSequence
    If oFrameSequence Is Nothing Then Exit Sub
    With oFrameSequence
        bFinishedPlaying = False
        If (.eLoopingType = loopingNone) _
                Or (.eLoopingType = loopingOneWay) _
                Or (.eLoopingType = loopingTwoWay) Then
            lCurrentFrame = IIf(vbStartWithRandomFrame, Int(Rnd * .lNumFrames + 1), 1)
            eCurrentDirection = sequenceDirectionForward
        Else
            lCurrentFrame = IIf(vbStartWithRandomFrame, Int(Rnd * .lNumFrames + 1), .lNumFrames)
            eCurrentDirection = sequenceDirectionReverse
        End If
    End With
    lTicksSinceLastFrame = 0
End Sub

Public Sub Update(ByVal vlTicksPassed&)
    'If oFrameSequence Is Nothing Then Exit Sub
    With oFrameSequence
        lTicksSinceLastFrame = lTicksSinceLastFrame + vlTicksPassed
        'next frame?
        If lTicksSinceLastFrame > .lTicksPerFrame Then
            lTicksSinceLastFrame = 0
            'lTicksSinceLastFrame = lTicksSinceLastFrame - .lTicksPerFrame
            If eCurrentDirection = sequenceDirectionForward Then
                'FORWARD
                If lCurrentFrame >= .lNumFrames Then
                    'AT END
                    If .eLoopingType = loopingNone Then
                        bFinishedPlaying = True
                    ElseIf .eLoopingType = loopingOneWay Then
                        lCurrentFrame = 1
                    Else
                        'must be two way to get here
                        eCurrentDirection = sequenceDirectionReverse
                        'note: last frame will play twice
                    End If
                Else
                    'NOT AT END
                    lCurrentFrame = lCurrentFrame + 1
                End If
            Else
                'REVERSE
                If lCurrentFrame <= 1 Then
                    'AT BEGINNING
                    If .eLoopingType = loopingNoneReverse Then
                        bFinishedPlaying = True
                    ElseIf .eLoopingType = loopingOneWayReverse Then
                        lCurrentFrame = .lNumFrames
                    Else
                        'must be two way to get here
                        eCurrentDirection = sequenceDirectionForward
                        'note: last frame will play twice
                    End If
                Else
                    'NOT AT BEGINNING
                    lCurrentFrame = lCurrentFrame - 1
                End If
            End If 'currently in reverse
        End If 'Frame changed
    End With

    If bFinishedPlaying And (Not oNextFrameSequence Is Nothing) Then
        Call Me.PlayFrameSequence(oNextFrameSequence)
        Set oNextFrameSequence = Nothing
    End If
End Sub

Public Property Get CurrentBitMapFrame() As Long
    With oFrameSequence
        'lCurrentFrame referenced from 1
        'lStartFrame referenced from 1
        'to referenced from zero, subtract 2
        CurrentBitMapFrame = lCurrentFrame + .lStartFrame - 2
    End With
End Property

Public Property Get IsFinishedPlaying() As Boolean
    IsFinishedPlaying = bFinishedPlaying
End Property

Public Property Get IsValid() As Boolean
    IsValid = (Not bFinishedPlaying) And (Not (oFrameSequence Is Nothing))
End Property

Public Sub Terminate()
    If bTerminated Then Exit Sub
    bTerminated = True
'    If Not oFrameSequence = Nothing Then Call oFrameSequence.Terminate
    Set oFrameSequence = Nothing
    Set oNextFrameSequence = Nothing
End Sub

Public Sub Class_Terminate()
    Call Terminate
End Sub
