VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
END
Attribute VB_Name = "PlayQuadrantManager"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = True
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = False
Option Explicit

Private mlFieldWidth As Long
Private mlFieldHeight As Long
Private mlQuadrantWidth As Long
Private mlQuadrantHeight As Long
Private mlOverlapWidth As Long
Private mlOverlapHeight As Long

Private mlLowestX As Long
Private mlLowestY As Long
Private mlHighestX As Long
Private mlHighestY As Long

Private mlXBlocks As Long
Private mlYBlocks As Long

Private mlQuadrants As Long
Private mlMaxObjects As Long

Private moObjects() As Object
Private mlObjectData() As Long
Private mlNumObjects() As Long

'number of qudrants the iterator must handle
Private mlIteratorNumQs As Long
'the quadrant numbers for the 2nd, 3rd, and 4th
Private mlIteratorQs(2 To 4) As Long
'current quadrant number 1,2,3,4
Private mlIteratorQIdx As Long
'current real Quadrant number
Private mlIteratorQ As Long
'current index in current quadrant's object list
Private mlIteratorIdx As Long
Private mlLastIteratorIdx As Long
'current max index of current quadrant's object list
Private mlIteratorIdxMax As Long

Public Sub Initialize(ByVal vlFieldWidth As Long, ByVal vlFieldHeight As Long, ByVal vlQuadrantWidth As Long, ByVal vlQuadrantHeight As Long, ByVal vlOverlapWidth As Long, ByVal vlOverlapHeight As Long, ByVal vlMaxObjects)
    Dim llXCtr As Long
    Dim llYCtr As Long
    
    mlFieldWidth = vlFieldWidth
    mlFieldHeight = vlFieldHeight
    mlQuadrantWidth = vlQuadrantWidth
    mlQuadrantHeight = vlQuadrantHeight
    mlOverlapWidth = vlOverlapWidth
    mlOverlapHeight = vlOverlapHeight

    mlLowestX = 0 - vlOverlapWidth
    mlLowestY = 0 - vlOverlapHeight
    mlHighestX = vlFieldWidth + vlOverlapWidth
    mlHighestY = vlFieldHeight + vlOverlapHeight

    mlXBlocks = mlFieldWidth / mlQuadrantWidth
    mlYBlocks = mlFieldHeight / mlQuadrantHeight
    
    mlQuadrants = mlXBlocks * mlYBlocks
    mlMaxObjects = vlMaxObjects
    ReDim moObjects(1 To mlQuadrants, 1 To vlMaxObjects)
    ReDim mlObjectData(1 To mlQuadrants, 1 To vlMaxObjects)
    ReDim mlNumObjects(1 To mlQuadrants)
End Sub

Public Sub Clear()
    Dim llCtr As Long
    
    For llCtr = 1 To mlQuadrants
        mlNumObjects(llCtr) = 0
    Next llCtr
End Sub

'BEWARE!
'Only one Iterator at a time!!!!
'iterates all objects which are in the same quadrant(s) as the point
Public Sub StartIterator(ByVal vlX As Long, ByVal vlY As Long)
    Dim llIteratorQ1 As Long
    Dim llIteratorQ2 As Long
    Dim llIteratorQ3 As Long
    Dim llIteratorQ4 As Long
    
    Call GetQuadrants(vlX, vlY, mlIteratorNumQs, mlIteratorQ, llIteratorQ2, llIteratorQ3, llIteratorQ4)
    mlIteratorQs(2) = llIteratorQ2
    mlIteratorQs(3) = llIteratorQ3
    mlIteratorQs(4) = llIteratorQ4
    mlIteratorQIdx = 1
    mlIteratorIdx = 1
    mlIteratorIdxMax = mlNumObjects(mlIteratorQ)
End Sub

'returns Nothing when at end of iteration
Public Function GetNextObject(ByRef rlObjectData As Long) As Object
    If mlIteratorQIdx > mlIteratorNumQs Then Exit Function
    
    Do
        Do While mlIteratorIdx > mlIteratorIdxMax
            mlIteratorQIdx = mlIteratorQIdx + 1
            If mlIteratorQIdx > mlIteratorNumQs Then Exit Function
            mlIteratorQ = mlIteratorQs(mlIteratorQIdx)
            mlIteratorIdxMax = mlNumObjects(mlIteratorQ)
            mlIteratorIdx = 1
        Loop
        
        Set GetNextObject = moObjects(mlIteratorQ, mlIteratorIdx)
        If Not GetNextObject Is Nothing Then
            rlObjectData = mlObjectData(mlIteratorQ, mlIteratorIdx)
            mlLastIteratorIdx = mlIteratorIdx
            mlIteratorIdx = mlIteratorIdx + 1
            Exit Function
        End If
        
        mlIteratorIdx = mlIteratorIdx + 1
    Loop While True
End Function

Public Sub DeleteLastObject()
    Set moObjects(mlIteratorQ, mlLastIteratorIdx) = Nothing
End Sub

Public Sub AddObject(ByVal vlX As Long, ByVal vlY As Long, roObject As Object, ByVal vlData As Long)
    Dim llNumQs As Long
    Dim llQ1 As Long
    Dim llQ2 As Long
    Dim llQ3 As Long
    Dim llQ4 As Long
    Dim llIdx As Long
    
    Call GetQuadrants(vlX, vlY, llNumQs, llQ1, llQ2, llQ3, llQ4)
    
    If llNumQs = 0 Then Exit Sub
    
    llIdx = mlNumObjects(llQ1)
    If llIdx < mlMaxObjects Then
        llIdx = llIdx + 1
        Set moObjects(llQ1, llIdx) = roObject
        mlObjectData(llQ1, llIdx) = vlData
        mlNumObjects(llQ1) = llIdx
    End If

    If llNumQs = 1 Then Exit Sub
    
    llIdx = mlNumObjects(llQ2)
    If llIdx < mlMaxObjects Then
        llIdx = llIdx + 1
        Set moObjects(llQ2, llIdx) = roObject
        mlObjectData(llQ2, llIdx) = vlData
        mlNumObjects(llQ2) = llIdx
    End If

    If llNumQs = 2 Then Exit Sub
    
    llIdx = mlNumObjects(llQ3)
    If llIdx < mlMaxObjects Then
        llIdx = llIdx + 1
        Set moObjects(llQ3, llIdx) = roObject
        mlObjectData(llQ3, llIdx) = vlData
        mlNumObjects(llQ3) = llIdx
    End If

'never 3 ... either 1, 2, or 4
'    If llNumQs = 3 Then Exit Sub
    
    llIdx = mlNumObjects(llQ4)
    If llIdx < mlMaxObjects Then
        llIdx = llIdx + 1
        Set moObjects(llQ4, llIdx) = roObject
        mlObjectData(llQ4, llIdx) = vlData
        mlNumObjects(llQ4) = llIdx
    End If
End Sub

Private Sub GetQuadrants(ByVal vlX As Long, ByVal vlY As Long, ByRef rlNumQs, ByRef rlQ1, ByRef rlQ2, ByRef rlQ3, ByRef rlQ4)
    Dim llXBlock1 As Long
    Dim llXBlock2 As Long
    Dim llYBlock1 As Long
    Dim llYBlock2 As Long
    
    rlNumQs = 0
    If vlX < mlLowestX Then Exit Sub
    If vlX > mlHighestX Then Exit Sub
    If vlY < mlLowestY Then Exit Sub
    If vlY > mlHighestY Then Exit Sub
   
    llXBlock1 = Fix(vlX / mlQuadrantWidth) + 1
    If llXBlock1 >= mlXBlocks Then
        llXBlock1 = mlXBlocks
        llXBlock2 = mlXBlocks
    Else
        llXBlock2 = Fix((vlX + mlOverlapWidth) / mlQuadrantWidth) + 1
        If llXBlock2 > mlXBlocks Then llXBlock2 = mlXBlocks
    End If
    
    llYBlock1 = Fix(vlY / mlQuadrantHeight) + 1
    If llYBlock1 >= mlYBlocks Then
        llYBlock1 = mlYBlocks
        llYBlock2 = mlYBlocks
    Else
        llYBlock2 = Fix((vlY + mlOverlapHeight) / mlQuadrantHeight) + 1
        If llYBlock2 > mlYBlocks Then llYBlock2 = mlYBlocks
    End If
    
    If llXBlock1 = llXBlock2 Then
        If llYBlock1 = llYBlock2 Then
            rlNumQs = 1
            rlQ1 = (llYBlock1 - 1) * mlXBlocks + llXBlock1
        Else
            rlNumQs = 2
            rlQ1 = (llYBlock1 - 1) * mlXBlocks + llXBlock1
            rlQ2 = rlQ1 + mlXBlocks
        End If
    Else
        If llYBlock1 = llYBlock2 Then
            rlNumQs = 2
            rlQ1 = (llYBlock1 - 1) * mlXBlocks + llXBlock1
            rlQ2 = rlQ1 + 1
        Else
            rlNumQs = 4
            rlQ1 = (llYBlock1 - 1) * mlXBlocks + llXBlock1
            rlQ2 = rlQ1 + mlXBlocks
            rlQ3 = rlQ1 + 1
            rlQ4 = rlQ2 + 1
        End If
    End If
End Sub
