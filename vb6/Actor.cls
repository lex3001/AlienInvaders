VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
END
Attribute VB_Name = "Sprite"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = True
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = False
Option Explicit

Public sID As String

'POSITION/MOVEMENT
Public fX As Single
Public fY As Single
'movement
Public eMovementType As MovementTypes_Enum
'normal
Public iVelocityDirection As Integer
Public iVelocity As Integer
Public iAccelerationDirection As Integer
Public iAcceleration As Integer
'follow the leader
Public oSpriteToFollow As Sprite
Public fXRelPos As Single
Public fYRelPos As Single
'march
Public iMarchingDistance As Integer
Public fDistanceMarched As Single
'attack
Private oTargetSprite As Sprite

'GRAPHICS
Public oBitMapDefinition As BitMapDefinition
Public oSequencePlayer As SequencePlayer

Public Sub Initialize_Normal(rsID$, vfX%, vfY%, ByVal viVelocityDirection%, ByVal viVelocity%, _
        ByVal viAccelerationDirection%, ByVal viAcceleration%, ByVal viMarchingDistance%)
    sID = rsID
    fX = vfX
    fY = vfY
    iVelocityDirection = viVelocityDirection
    iVelocity = viVelocity
    iAccelerationDirection = viAccelerationDirection
    iAcceleration = viAcceleration
    iMarchingDistance = viMarchingDistance
    eMovementType = IIf(iMarchingDistance > 0, movementMarch, movementNormal)
End Sub

Public Sub Initialize_FollowTheLeader(rsID$, roLeader As Sprite, ByVal vfXRelPos%, ByVal vfYRelPos%)
    sID = rsID
    eMovementType = movementFollowTheLeader
    fXRelPos = vfXRelPos
    fYRelPos = vfYRelPos
    Set oSpriteToFollow = roLeader
    fX = roLeader.fX + vfXRelPos
    fY = roLeader.fY + vfYRelPos
    iVelocityDirection = 0
    iVelocity = 0
    iAccelerationDirection = 0
    iAcceleration = 0
End Sub

Public Sub Initialize_Special(rsID$, ByVal veMovementType As MovementTypes_Enum)
    sID = rsID
    eMovementType = veMovementType
    iVelocityDirection = 0
    iVelocity = 0
    iAccelerationDirection = 0
    iAcceleration = 0
End Sub
