VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
  Persistable = 0  'NotPersistable
  DataBindingBehavior = 0  'vbNone
  DataSourceBehavior  = 0  'vbNone
  MTSTransactionMode  = 0  'NotAnMTSObject
END
Attribute VB_Name = "BrainsCargo"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = True
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = False
Option Explicit

Implements Brains

Private bTerminated As Boolean

Public eCargoType As CargoType_Enum
Private eSelectedCargoType As CargoType_Enum

Private llTicksPassed As Long
Private llTicksToPass As Long
Private bGoAway As Boolean
Private llGoAwayTicksPassed As Long
Private llGoAwayTicksToPass As Long

Private oFrameSequence_Normal( _
    CargoType_Enum.cargoMin To CargoType_Enum.cargoMax) As FrameSequence

Private oSoundEffect_Doh As SoundEffect

Private oActor As Actor2
Private oLevel As Level

Public Sub Brains_Initialize(roLevel As Level, roActor As Actor2)
    Set oActor = roActor
    Set oLevel = roLevel
        
    With oActor.oBitMapDefinition
        Set oFrameSequence_Normal(CargoType_Enum.cargoOrange) = _
            .GetFrameSequence(.GetFrameSequenceHandle("ORANGE"))
        Set oFrameSequence_Normal(CargoType_Enum.cargoPink) = _
            .GetFrameSequence(.GetFrameSequenceHandle("PINK"))
        Set oFrameSequence_Normal(CargoType_Enum.cargoYellow) = _
            .GetFrameSequence(.GetFrameSequenceHandle("YELLOW"))
        Set oFrameSequence_Normal(CargoType_Enum.cargoBlue) = _
            .GetFrameSequence(.GetFrameSequenceHandle("BLUE"))
        Set oFrameSequence_Normal(CargoType_Enum.cargoGreen) = _
            .GetFrameSequence(.GetFrameSequenceHandle("GREEN"))
        Set oFrameSequence_Normal(CargoType_Enum.cargoPurple) = _
            .GetFrameSequence(.GetFrameSequenceHandle("PURPLE"))
        Set oFrameSequence_Normal(CargoType_Enum.cargoRed) = _
            .GetFrameSequence(.GetFrameSequenceHandle("RED"))
        Set oFrameSequence_Normal(CargoType_Enum.cargoNavy) = _
            .GetFrameSequence(.GetFrameSequenceHandle("NAVY"))
        Set oFrameSequence_Normal(CargoType_Enum.cargoRedDot) = _
            .GetFrameSequence(.GetFrameSequenceHandle("REDDOT"))
        Set oFrameSequence_Normal(CargoType_Enum.cargoGreenDot) = _
            .GetFrameSequence(.GetFrameSequenceHandle("GREENDOT"))
        Set oFrameSequence_Normal(CargoType_Enum.cargoBlueDot) = _
            .GetFrameSequence(.GetFrameSequenceHandle("BLUEDOT"))
        Set oFrameSequence_Normal(CargoType_Enum.cargoPinkDot) = _
            .GetFrameSequence(.GetFrameSequenceHandle("PINKDOT"))
        Set oFrameSequence_Normal(CargoType_Enum.cargoYellowDot) = _
            .GetFrameSequence(.GetFrameSequenceHandle("YELLOWDOT"))
        Set oFrameSequence_Normal(CargoType_Enum.cargoColorDot) = _
            .GetFrameSequence(.GetFrameSequenceHandle("COLORDOT"))
    End With
    
    With oLevel
        Set oSoundEffect_Doh = .GetSoundEffect("DOH2")
    End With
End Sub

Public Sub Brains_ResetState()
    If eCargoType = cargoRandom Then
'        eSelectedCargoType = _
            Int(Rnd * (CargoType_Enum.cargoMax - CargoType_Enum.cargoMin + 1)) + CargoType_Enum.cargoMin
        eSelectedCargoType = Int(Rnd * 6)
    Else
        eSelectedCargoType = eCargoType
    End If

    With oActor
        Call .oSequencePlayer.PlayFrameSequence(oFrameSequence_Normal(eSelectedCargoType))
        .lCanBeHitByMissiles = IIf((0 = Int(Rnd * 10)), 1, 0)
        bGoAway = (0 = Int(Rnd * 15))
'bGoAway = True
'.lCanBeHitByMissiles = 1&
        .bCanHitPlayer = True
        .lVelocity = 0
        .lVelocityDirection = 0
        .bReverseAtBorderLeft = True
        .bReverseAtBorderRight = True
        .lAcceleration = 0
    End With
    llTicksPassed = 0
    llTicksToPass = 0
    llGoAwayTicksPassed = 0
    llGoAwayTicksToPass = Int(Rnd * 5000) + 2000
End Sub

Public Sub Brains_UpdateState()
    With oActor
        If .bHitPlayer Then
            Select Case eSelectedCargoType
                Case CargoType_Enum.cargoOrange
                    oLevel.lShieldsLeft = oLevel.lShieldsLeft + 10000
                Case CargoType_Enum.cargoPink
                    Call oLevel.AddBonus(bonusFrameRandom, .fX, .fY)
                Case CargoType_Enum.cargoYellow
                    oLevel.bHasDoubleShots = True
                Case CargoType_Enum.cargoBlue
                    oLevel.bHasMultiShots = True
                Case CargoType_Enum.cargoGreen
                    oLevel.bHasSafetyPin = True
                Case CargoType_Enum.cargoPurple
                    oLevel.bHasRapidFire = True
                Case CargoType_Enum.cargoRed
                Case CargoType_Enum.cargoNavy
                Case CargoType_Enum.cargoRedDot
                Case CargoType_Enum.cargoGreenDot
                Case CargoType_Enum.cargoBlueDot
                Case CargoType_Enum.cargoPinkDot
                Case CargoType_Enum.cargoYellowDot
                Case CargoType_Enum.cargoColorDot
            End Select
                
            .lCanBeHitByMissiles = 0&
            .bCanHitPlayer = False
            .bDelete = True
        End If
        
        If .bIsOffScreen Then
            .lCanBeHitByMissiles = 0&
            .bCanHitPlayer = False
            .bDelete = True
        End If
    
        If .lWasHitByMissiles > 0& Then
            .bReverseAtBorderTop = False
            .bReverseAtBorderLeft = False
            .bReverseAtBorderRight = False
            .lCanBeHitByMissiles = 0&
            oSoundEffect_Doh.Play
            .lVelocity = Int(Rnd * 100) + 180
            .lVelocityDirection = Int(Rnd * 360)
            .lWasHitByMissiles = 0&
            llTicksToPass = 10000
        End If
    
        If Not .bDelete Then
            llTicksPassed = llTicksPassed + oLevel.lTicksPassed
            If llTicksPassed > llTicksToPass Then
                llTicksPassed = 0
                llTicksToPass = Int(Rnd * 3000) + 500
                .lVelocity = Int(Rnd * 80) + 20
                .lVelocityDirection = Int(Rnd * 100) + 40
            End If
            If bGoAway Then
                llGoAwayTicksPassed = llGoAwayTicksPassed + oLevel.lTicksPassed
                If llGoAwayTicksPassed > llGoAwayTicksToPass Then
                    .bReverseAtBorderTop = False
                    .bReverseAtBorderLeft = False
                    .bReverseAtBorderRight = False
                    .lAcceleration = 100
                    .lAccelerationDirection = 270
                End If
            End If
        End If
    End With
End Sub

Private Sub Brains_Terminate()
    If bTerminated Then Exit Sub
    bTerminated = True
    
    Dim llCtr As Long
    For llCtr = CargoType_Enum.cargoMin To CargoType_Enum.cargoMax
        Set oFrameSequence_Normal(llCtr) = Nothing
    Next llCtr
    Set oSoundEffect_Doh = Nothing
    Set oActor = Nothing
    Set oLevel = Nothing
End Sub
