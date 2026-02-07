VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
END
Attribute VB_Name = "BitMapFrames"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = True
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = False
Option Explicit

Public sID As String
Public ddsDirectDrawSurface As IDirectDrawSurface2
Public iXFrameSize As Integer
Public iYFrameSize As Integer
Public iWidthInFrames As Integer
Public iNumFrames As Integer
Public oFrameDefinitions() As FrameDefinition
Public iNumFrameSequences As Integer
Public oFrameSequences() As FrameSequence
