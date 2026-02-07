VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
END
Attribute VB_Name = "CollisionBox"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = True
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = False
Option Explicit

Public sID As String
Public lXOffset As Long
Public lYOffset As Long
Public lXSize As Long
Public lYSize As Long

Public Sub Initialize(rsID$, ByVal vlXOffset&, ByVal vlYOffset&, ByVal vlXSize&, ByVal vlYSize&)
    sID = rsID
    lXOffset = vlXOffset
    lYOffset = vlYOffset
    lXSize = vlXSize
    lYSize = vlYSize
End Sub
