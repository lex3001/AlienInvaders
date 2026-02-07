VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
END
Attribute VB_Name = "ActorBehavior"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = True
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = False
Option Explicit

Public sID As String

Private miNumActions As Integer
Private oActions() As Action

Private miNumStates As Integer
Private oStates() As StateActions

Public lTickCountTrigger1 As Long
Public lTriggerChance1 As Long

Public Sub Initialize(rsID$)
    sID = rsID
End Sub

Public Function AddNewAction(rsID$, ByVal vbRemoveActor As Boolean, ByVal viSoundToPlay%, _
        ByVal viScorePoints%, ByVal viBonusPoints%, ByVal vbShowBonusIndicator As Boolean, _
        rsNewStateID$, rsNewSequenceID$, ByVal veNewMovementType As MovementTypes_Enum, ByVal vbKillPlayer As Boolean, _
        ByVal vbDropBombA As Boolean, ByVal vbDropBombD As Boolean, _
        ByVal vbResetTickCounter1 As Boolean) As Action
        
    Dim loNewAction As New Action
    Call loNewAction.Initialize(rsID, vbRemoveActor, viSoundToPlay, _
        viScorePoints, viBonusPoints, vbShowBonusIndicator, _
        rsNewStateID, rsNewSequenceID, veNewMovementType, vbKillPlayer, _
        vbDropBombA, vbDropBombD, _
        vbResetTickCounter1)

    miNumActions = miNumActions + 1
    ReDim Preserve oActions(1 To miNumActions)
    Set oActions(miNumActions) = loNewAction
    Set AddNewAction = loNewAction
End Function

Public Function AddNewState(rsID$) As StateActions
    Dim loNewState As New StateActions
    Call loNewState.Initialize(rsID)

    miNumStates = miNumStates + 1
    ReDim Preserve oStates(1 To miNumStates)
    Set oStates(miNumStates) = loNewState
    Set AddNewState = loNewState
End Function
