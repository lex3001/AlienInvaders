Attribute VB_Name = "TypeDefs"
Option Explicit

Enum CargoType_Enum
    cargoRandom = -1
    cargoOrange = 0
    cargoPink = 1
    cargoYellow = 2
    cargoBlue = 3
    cargoGreen = 4
    cargoPurple = 5
    cargoRed = 6
    cargoNavy = 7
    cargoRedDot = 8
    cargoGreenDot = 9
    cargoBlueDot = 10
    cargoPinkDot = 11
    cargoYellowDot = 12
    cargoColorDot = 13
    cargoMax = 13
    cargoMin = 0
End Enum

Enum BonusFrame_Enum
    bonusFrameRed25 = 10
    bonusFrameRed50 = 11
    bonusFrameRed75 = 12
    bonusFrameRed100 = 13
    bonusFrame100 = 0
    bonusFrame200 = 1
    bonusFrame300 = 2
    bonusFrame400 = 3
    bonusFrame500 = 4
    bonusFrame600 = 5
    bonusFrame700 = 6
    bonusFrame800 = 7
    bonusFrame900 = 8
    bonusFrame1000 = 9
    bonusFrameRandom = -1
End Enum

Type DisplayBonus
    bActive As Boolean
    lFrame As Long
    lTicks As Long
    lX As Long
    lY As Long
End Type

Enum BombDir_Enum
    bombDefaultDir = 0
    bombStraightDown = 1
    bombStraightUp = 2
    bombToTarget = 3
End Enum

Enum LoopingType_Enum
    loopingNone = 0
    loopingNoneReverse = 1
    loopingOneWay = 10
    loopingOneWayReverse = 11
    loopingTwoWay = 20
    loopingTwoWayStartReverse = 21
End Enum

Enum SequenceDirection_Enum
    sequenceDirectionForward = 0
    sequenceDirectionReverse = 1
End Enum

Enum FrameDefAssignmentTypes_Enum
    frameDefAssignmentSingle = 0
    frameDefAssignmentRange = 1
    frameDefAssignmentList = 2
    frameDefAssignmentAll = 3
End Enum

Enum MovementTypes_Enum
    movementNone = 0 'does not mean no movement! Means no movement DEFINED
    movementNormal = 1 'set to normal with 0 Velocity and 0 Acceleration for no movement)
    movementMarch = 2
    movementFollowTheLeader = 3
    movementCircle = 4
    movementRadialMovementPoints = 5
End Enum
