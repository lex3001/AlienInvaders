VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
END
Attribute VB_Name = "BitMapDefinition"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = True
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = False
Option Explicit

Private bTerminated As Boolean
Public sID As String
Public ddsDirectDrawSurface As IDirectDrawSurface2
Public lXFrameSize As Long
Public lYFrameSize As Long
Public lWidthInFrames As Long
Private lNumFrameDefinitions As Long
Private oFrameDefinitions() As FrameDefinition
Private lNumFrameSequences As Long
Private oFrameSequences() As FrameSequence

Public Sub Initialize(rsID$, rddsDirectDrawSurface As IDirectDrawSurface2, _
        ByVal vlXFrameSize&, ByVal vlYFrameSize&, vlWidthInFrames&, ByVal vlNumFrames)
    
    sID = rsID
    Set ddsDirectDrawSurface = rddsDirectDrawSurface
    lXFrameSize = vlXFrameSize
    lYFrameSize = vlYFrameSize
    lWidthInFrames = vlWidthInFrames
    lNumFrameDefinitions = vlNumFrames
    ReDim Preserve oFrameDefinitions(1 To lNumFrameDefinitions)
    lNumFrameSequences = 0
    Erase oFrameSequences()
End Sub

Public Sub AssignFrameDefinition(roFrameDefinition, _
        ByVal veFrameDefAssignmentType As FrameDefAssignmentTypes_Enum, ParamArray Args())
    
    Dim llCtr As Long
    
    If (veFrameDefAssignmentType = frameDefAssignmentSingle) _
            Or (veFrameDefAssignmentType = frameDefAssignmentList) Then
        For llCtr = LBound(Args) To UBound(Args)
            Set oFrameDefinitions(Args(llCtr)) = roFrameDefinition
        Next llCtr
    ElseIf veFrameDefAssignmentType = frameDefAssignmentRange Then
        For llCtr = Args(0) To Args(1)
            Set oFrameDefinitions(llCtr) = roFrameDefinition
        Next llCtr
    ElseIf veFrameDefAssignmentType = frameDefAssignmentAll Then
        For llCtr = 1 To lNumFrameSequences
            Set oFrameDefinitions(llCtr) = roFrameDefinition
        Next llCtr
    End If
End Sub

Public Function AddFrameDefinition(rsID$, ByVal vlXOffset&, ByVal vlYOffset&, ByVal vlXSize&, ByVal vlYSize&, _
        ByVal vbCollisionBoxesInsideFrame As Boolean, _
        ByVal veFrameDefAssignmentType As FrameDefAssignmentTypes_Enum, ParamArray Args())
    
    Dim llCtr As Long
    Dim loNewFrameDefinition As New FrameDefinition
    Call loNewFrameDefinition.Initialize(rsID, vlXOffset, vlYOffset, vlXSize, vlYSize, _
        vbCollisionBoxesInsideFrame)
    
    If (veFrameDefAssignmentType = frameDefAssignmentSingle) _
            Or (veFrameDefAssignmentType = frameDefAssignmentList) Then
        For llCtr = LBound(Args) To UBound(Args)
            Set oFrameDefinitions(Args(llCtr)) = loNewFrameDefinition
        Next llCtr
    ElseIf veFrameDefAssignmentType = frameDefAssignmentRange Then
        For llCtr = Args(0) To Args(1)
            Set oFrameDefinitions(llCtr) = loNewFrameDefinition
        Next llCtr
    ElseIf veFrameDefAssignmentType = frameDefAssignmentAll Then
        For llCtr = 1 To lNumFrameSequences
            Set oFrameDefinitions(llCtr) = loNewFrameDefinition
        Next llCtr
    End If
    
    Set AddFrameDefinition = loNewFrameDefinition
End Function

'referenced from 0 not 1!
Public Function GetFrameDefinition(ByVal vlBitMapFrame&) As FrameDefinition
    Set GetFrameDefinition = oFrameDefinitions(vlBitMapFrame + 1)
End Function

Public Function AddFrameSequence(rsID$, ByVal vlStartFrame&, ByVal vlNumFrames&, _
        ByVal veLoopingType As LoopingType_Enum, ByVal vlTicksPerFrame&) As FrameSequence
    
    Dim loNewFrameSequence As New FrameSequence
    Call loNewFrameSequence.Initialize(rsID, vlStartFrame, vlNumFrames, veLoopingType, vlTicksPerFrame)
    
    lNumFrameSequences = lNumFrameSequences + 1
    loNewFrameSequence.lHandle = lNumFrameSequences
    ReDim Preserve oFrameSequences(1 To lNumFrameSequences)
    Set oFrameSequences(lNumFrameSequences) = loNewFrameSequence
    Set AddFrameSequence = loNewFrameSequence
End Function

Public Function GetFrameSequence(ByVal vlHandle&) As FrameSequence
    Set GetFrameSequence = oFrameSequences(vlHandle)
End Function

Public Function GetFrameSequenceHandle(rsSequenceID$) As Integer
    Dim llCtr As Long
    For llCtr = 1 To lNumFrameSequences
        With oFrameSequences(llCtr)
            If .sID = rsSequenceID Then
                GetFrameSequenceHandle = llCtr
                Exit Function
            End If
        End With
    Next llCtr
End Function

Public Sub Terminate()
    If bTerminated Then Exit Sub
    bTerminated = True
    Dim llCtr As Long
    
    For llCtr = 1 To lNumFrameDefinitions
        If Not oFrameDefinitions(llCtr) Is Nothing Then Call oFrameDefinitions(llCtr).Terminate
        Set oFrameDefinitions(llCtr) = Nothing
    Next llCtr
    Erase oFrameDefinitions()
    lNumFrameDefinitions = 0
    
    For llCtr = 1 To lNumFrameSequences
'        If Not oFrameSequences(llCtr) Is Nothing Then Call oFrameSequences(llCtr).Terminate
        Set oFrameSequences(llCtr) = Nothing
    Next llCtr
    Erase oFrameSequences()
    lNumFrameSequences = 0
    
    Set ddsDirectDrawSurface = Nothing
End Sub

Public Sub Class_Terminate()
    Call Terminate
End Sub
