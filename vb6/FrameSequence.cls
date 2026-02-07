VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
END
Attribute VB_Name = "FrameSequence"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = True
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = False
Option Explicit

Public sID As String
Public lHandle As Long
Public lStartFrame As Long
Public lNumFrames As Long
Public eLoopingType As LoopingType_Enum
Public lTicksPerFrame As Long

Public Sub Initialize(rsID$, ByVal vlStartFrame&, ByVal vlNumFrames&, _
        ByVal veLoopingType As LoopingType_Enum, ByVal vlTicksPerFrame&)
    sID = rsID
    lStartFrame = vlStartFrame
    lNumFrames = vlNumFrames
    eLoopingType = veLoopingType
    lTicksPerFrame = vlTicksPerFrame
End Sub
