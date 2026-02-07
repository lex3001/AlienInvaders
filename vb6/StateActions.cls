VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
END
Attribute VB_Name = "StateActions"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = True
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = False
Option Explicit

Public sID As String

Private sActionIDs(1 To actorEventMAXVALUE) As String
Private lActionHs(1 To actorEventMAXVALUE) As String

Public Sub Initialize(rsID$)
    sID = rsID
End Sub

Public Sub AddEventAction(ByVal veEvent As ActorEvents_Enum, rsActionID$)
    sActionIDs(veEvent) = rsActionID
End Sub
