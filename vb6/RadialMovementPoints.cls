VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
END
Attribute VB_Name = "RadialMovementPoints"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = True
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = False
Option Explicit

Private fXPoints() As Single
Private fYPoints() As Single

Public Property Get XPoint(ByVal vlPoint As Long) As Single
    XPoint = fXPoints(vlPoint)
End Property

Public Property Get YPoint(ByVal vlPoint As Long) As Single
    YPoint = fYPoints(vlPoint)
End Property

Public Property Let XPoint(ByVal vlPoint As Long, ByVal vfValue As Single)
    fXPoints(vlPoint) = vfValue
End Property

Public Property Let YPoint(ByVal vlPoint As Long, ByVal vfValue As Single)
    fYPoints(vlPoint) = vfValue
End Property

Private Sub Class_Initialize()
    ReDim fXPoints(0 To 359)
    ReDim fYPoints(0 To 359)
End Sub

Private Sub Class_Terminate()
    Erase fXPoints()
    Erase fYPoints()
End Sub
