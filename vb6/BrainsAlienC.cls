VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
  Persistable = 0  'NotPersistable
  DataBindingBehavior = 0  'vbNone
  DataSourceBehavior  = 0  'vbNone
  MTSTransactionMode  = 0  'NotAnMTSObject
END
Attribute VB_Name = "BrainsAlienC"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = True
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = False
Option Explicit

Implements Brains

Private bTerminated As Boolean

Public lAverageAttackIntervalTicks As Long
Public lAttackRangePixels As Long

Private Enum State_Enum
    stateNormal = 0
    stateAttacking = 1
    stateExploding = 2
End Enum

Private eState As State_Enum

Private Enum AttackDirection_Enum
    attackNone = 0
    attackLeft = 1
    attackRight = 2
End Enum

Private eLastAttackDirection As AttackDirection_Enum

Private oFrameSequence_Normal As FrameSequence
Private oFrameSequence_AttackLeft As FrameSequence
Private oFrameSequence_AttackRight As FrameSequence
Private oFrameSequence_Explode As FrameSequence

Private oSoundEffect_Explode As SoundEffect

Private oActor As Actor2
Private oLevel As Level

Public Sub Brains_Initialize(roLevel As Level, roActor As Actor2)
    Set oActor = roActor
    Set oLevel = roLevel
        
    With oActor.oBitMapDefinition
        Set oFrameSequence_Normal = .GetFrameSequence(.GetFrameSequenceHandle("NORMAL"))
        Set oFrameSequence_AttackLeft = .GetFrameSequence(.GetFrameSequenceHandle("ATTACK_LEFT"))
        Set oFrameSequence_AttackRight = .GetFrameSequence(.GetFrameSequenceHandle("ATTACK_RIGHT"))
        Set oFrameSequence_Explode = .GetFrameSequence(.GetFrameSequenceHandle("EXPLODE"))
    End With
    
    With oLevel
        Set oSoundEffect_Explode = .GetSoundEffect("WHOOSH")
    End With
End Sub

Public Sub Brains_ResetState()
    eState = stateNormal
    eLastAttackDirection = attackNone
    
    With oActor
        Call .oSequencePlayer.PlayFrameSequence(oFrameSequence_Normal)
        .lCanBeHitByMissiles = 1&
        .bCanHitPlayer = False
    End With
End Sub

Public Sub Brains_UpdateState()
    Dim llXDistanceToPlayer As Long
    Dim leAttackDirection As AttackDirection_Enum
    Dim llX As Long
    Dim llY As Long
    
    With oActor
        
        If eState = stateNormal Then
            If .lWasHitByMissiles > 0& Then
                eState = stateExploding
                oSoundEffect_Explode.Play
                Call .oSequencePlayer.PlayFrameSequence(oFrameSequence_Explode)
                With oLevel
                    .lScore = .lScore + 10
                End With
                .lCanBeHitByMissiles = 0&
            
            Else
                llXDistanceToPlayer = oLevel.oPlayer.CenterX() - .CenterX()
                If (Abs(llXDistanceToPlayer) < lAttackRangePixels) _
                        And Rnd < (oLevel.lTicksPassed / lAverageAttackIntervalTicks) Then
                    'Attack!
                    eState = stateAttacking
                    
                    .bCanHitPlayer = True
                    .eMovementType = movementNormal
                    .lVelocityDirection = 90 'straight down
                    .lVelocity = 80
                    .lAcceleration = 500
                    .bStopAtBorderBottom = True
                    .bStopAtBorderLeft = False
                    .bStopAtBorderRight = False
                    
                    leAttackDirection = IIf(llXDistanceToPlayer > 0, attackRight, attackLeft)
                End If 'start attack
            End If
        
        ElseIf eState = stateAttacking Then
            If (.lWasHitByMissiles > 0&) Or .bIsAtBorderBottom Then
                eState = stateExploding
                'General_PlaySound(X, False)
                Call .oSequencePlayer.PlayFrameSequence(oFrameSequence_Explode)
                .lCanBeHitByMissiles = 0&
                .bCanHitPlayer = True
                llX = .fX
                llY = .fY
                If .lWasHitByMissiles > 0& Then
                    With oLevel
                        .lScore = .lScore + 10
                        Call .AddBonus(bonusFrameRed75, llX, llY)
                    End With
                Else
                    With oLevel
                        .lScore = .lScore + 10
                        Call .AddBonus(bonusFrameRed50, llX, llY)
                    End With
                End If
            
            ElseIf .bHitPlayer Or .bHitShields Then
                eState = stateExploding
                'General_PlaySound(X, False)
                Call .oSequencePlayer.PlayFrameSequence(oFrameSequence_Explode)
                .lCanBeHitByMissiles = 0&
                .bCanHitPlayer = True
            
            Else
                llXDistanceToPlayer = oLevel.oPlayer.CenterX() - .CenterX()
                leAttackDirection = IIf(llXDistanceToPlayer > 0, attackRight, attackLeft)
            End If
        
        ElseIf eState = stateExploding Then
            If .oSequencePlayer.IsFinishedPlaying Then
                .bDelete = True
            End If
            
        End If 'STATE

        If eState = stateAttacking Then
            If Not eLastAttackDirection = leAttackDirection Then
                If leAttackDirection = attackRight Then
                    Call .oSequencePlayer.PlayFrameSequence(oFrameSequence_AttackRight)
                    eLastAttackDirection = attackRight
                    .lAccelerationDirection = 0
                Else
                    Call .oSequencePlayer.PlayFrameSequence(oFrameSequence_AttackLeft)
                    eLastAttackDirection = attackLeft
                    .lAccelerationDirection = 180
                End If
                eLastAttackDirection = leAttackDirection
            End If
        End If

        If .bIsAtBorderBottom Then
            .lVelocity = 0
            .lAcceleration = 0
        End If

        If eState = stateExploding Then .lAcceleration = 0
        
    End With
End Sub

Private Sub Class_Initialize()
    lAverageAttackIntervalTicks = 8000
    lAttackRangePixels = 48
End Sub

Private Sub Brains_Terminate()
    If bTerminated Then Exit Sub
    bTerminated = True
    Set oFrameSequence_Normal = Nothing
    Set oFrameSequence_AttackLeft = Nothing
    Set oFrameSequence_AttackRight = Nothing
    Set oFrameSequence_Explode = Nothing
    Set oSoundEffect_Explode = Nothing
    Set oActor = Nothing
    Set oLevel = Nothing
End Sub

'Public Sub Class_Terminate()
'    Call Brains.Terminate
'End Sub

