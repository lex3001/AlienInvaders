VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
END
Attribute VB_Name = "MovementDefinition"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = True
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = False
Option Explicit

Public sID As String
Public iVelocityDirection As Integer
Public iVelocity As Integer
Public iAccelerationDirection As Integer
Public iAcceleration As Integer
Public iMarchingDistance As Integer
Public eMovementType As MovementTypes_Enum
'---
Public fDistanceMarched As Single
Private iActorCount As Integer 'How many actors currently reference this Mover(?)
Public fXStep As Single
Public fYStep As Single
Private oSourceSprite As Sprite
Private oTargetSprite As Sprite

Public Sub Initialize1(rsID$, ByVal viVelocityDirection%, ByVal viVelocity%, _
        ByVal viAccelerationDirection%, ByVal viAcceleration%, ByVal viMarchingDistance%)
    sID = rsID
    iVelocityDirection = viVelocityDirection
    iVelocity = viVelocity
    iAccelerationDirection = viAccelerationDirection
    iAcceleration = viAcceleration
    iMarchingDistance = viMarchingDistance
    eMovementType = IIf(iMarchingDistance > 0, movementMarch, movementNormal)
End Sub

Public Sub Initialize2(rsID$, ByVal veMovementType As MovementTypes_Enum)
    sID = rsID
    eMovementType = veMovementType
    iVelocityDirection = 0
    iVelocity = 0
    iAccelerationDirection = 0
    iAcceleration = 0
End Sub

Public Sub IncreaseActorCount()
    iActorCount = iActorCount + 1
End Sub

Public Sub DecreaseActorCount()
    iActorCount = iActorCount - 1
End Sub
