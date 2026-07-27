VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
  Persistable = 0  'NotPersistable
  DataBindingBehavior = 0  'vbNone
  DataSourceBehavior  = 0  'vbNone
  MTSTransactionMode  = 0  'NotAnMTSObject
END
Attribute VB_Name = "FrameDefinition"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = True
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = False
Option Explicit

Private bTerminated As Boolean
Public sID As String
Public lXOffset As Long 'offset of drawable part of frame
Public lYOffset As Long
Public lXSize As Long 'size of drawable part of frame
Public lYSize As Long
Public lXSizeOver2 As Long
Public lYSizeOver2 As Long
Public bCollisionBoxesInsideFrame As Boolean 'Are all collision boxes inside the Frame? (if not, don't check the frame box first)
Public lNumCollisionBoxes As Long 'Additional or more detailed collision boxes?
Private oCollisionBoxes() As CollisionBox

Public Sub Initialize(rsID$, ByVal vlXOffset&, ByVal vlYOffset&, ByVal vlXSize&, ByVal vlYSize&, _
        ByVal vbCollisionBoxesInsideFrame As Boolean)
    sID = rsID
    lXOffset = vlXOffset
    lYOffset = vlYOffset
    lXSize = vlXSize
    lXSizeOver2 = vlXSize / 2
    lYSize = vlYSize
    lYSizeOver2 = vlYSize / 2
    bCollisionBoxesInsideFrame = vbCollisionBoxesInsideFrame
End Sub

Public Sub AddCollisionBox(rsID$, ByVal vlXOffset&, ByVal vlYOffset&, ByVal vlXSize&, ByVal vlYSize&)
    Dim loNewCollisionBox As New CollisionBox
    Call loNewCollisionBox.Initialize(rsID, vlXOffset, vlYOffset, vlXSize, vlYSize)
    lNumCollisionBoxes = lNumCollisionBoxes + 1
    ReDim Preserve oCollisionBoxes(1 To lNumCollisionBoxes)
    Set oCollisionBoxes(lNumCollisionBoxes) = loNewCollisionBox
End Sub

Public Sub Terminate()
    If bTerminated Then Exit Sub
    bTerminated = True
    Dim llCtr As Long
    
    For llCtr = 1 To lNumCollisionBoxes
'        If Not oCollisionBoxes(llCtr) Is Nothing Then Call oCollisionBoxes(llCtr).Terminate
        Set oCollisionBoxes(llCtr) = Nothing
    Next llCtr
    Erase oCollisionBoxes()
    lNumCollisionBoxes = 0
End Sub

Public Sub Class_Terminate()
    Call Terminate
End Sub
