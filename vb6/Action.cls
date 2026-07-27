VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
END
Attribute VB_Name = "Action"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = True
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = False
Option Explicit

Public sID As String

Public bRemoveActor As Boolean

Public bPlaySound As Boolean
Public iSoundToPlay As Integer

Public bScorePoints As Boolean
Public iScorePoints As Integer

Public bBonusPoints As Boolean
Public bShowBonusIndicator As Boolean
Public iBonusPoints As Integer

Public bChangeState As Boolean
Public sNewStateID As String
Public lNewStateH As Long

Public bChangeSequence As Boolean
Public sNewSequenceID As String
Public lNewSequenceH As Long

Public bChangeMovementType As Boolean
Public eNewMovementType As MovementTypes_Enum
'reset mover?

Public bKillPlayer As Boolean

Public bDropBombA As Boolean
Public bDropBombD As Boolean

Public bResetTickCounter1 As Boolean

Public Sub Initialize(rsID$, ByVal vbRemoveActor As Boolean, ByVal viSoundToPlay%, _
        ByVal viScorePoints%, ByVal viBonusPoints%, ByVal vbShowBonusIndicator As Boolean, _
        rsNewStateID$, rsNewSequenceID$, ByVal veNewMovementType As MovementTypes_Enum, _
        ByVal vbKillPlayer As Boolean, _
        ByVal vbDropBombA As Boolean, ByVal vbDropBombD As Boolean, _
        ByVal vbResetTickCounter1 As Boolean)
    sID = rsID
    bRemoveActor = vbRemoveActor
    bPlaySound = (viSoundToPlay >= 0)
    iSoundToPlay = viSoundToPlay
    bScorePoints = (viScorePoints > 0)
    iScorePoints = viScorePoints
    bBonusPoints = (viBonusPoints > 0)
    iBonusPoints = viBonusPoints
    bShowBonusIndicator = vbShowBonusIndicator
    bChangeState = ("" <> rsNewStateID)
    sNewStateID = rsNewStateID
    bChangeSequence = ("" <> rsNewSequenceID)
    sNewSequenceID = rsNewSequenceID
    bChangeMovementType = (movementNone <> veNewMovementType)
    eNewMovementType = veNewMovementType
    bKillPlayer = vbKillPlayer
    bDropBombA = vbDropBombA
    bDropBombD = vbDropBombD
    bResetTickCounter1 = vbResetTickCounter1
End Sub

Private Sub Class_Initialize()
    bRemoveActor = False
    bPlaySound = False
    bScorePoints = False
    bBonusPoints = False
    bChangeState = False
    bChangeSequence = False
    bChangeMovementType = False
    bKillPlayer = False
    bDropBombA = False
    bDropBombD = False
    bResetTickCounter1 = False
End Sub
