Attribute VB_Name = "LevelDefinitions"
Option Explicit

Public Sub Levels123_LoadBitMapDefinitions(roLevel As Level)
    Call Define_Player(roLevel)
    Call Define_Missle(roLevel)
    Call Define_XBonus(roLevel)
    Call Define_Planet(roLevel)
    Call Define_ABomb(roLevel)
    Call Define_DBomb(roLevel)
    Call Define_AlienA(roLevel)
    Call Define_AlienB(roLevel)
    Call Define_AlienC(roLevel)
    Call Define_AlienD(roLevel)
    Call Define_AlienE(roLevel)
    Call Define_Rocket(roLevel)
    Call Define_Cargo(roLevel)
End Sub

Public Sub Levels123_LoadSounds(roLevel As Level)
    Call roLevel.AddNewSoundEffect("TYPE", App.Path & "\Resource\Type.wav", 10)
    Call roLevel.AddNewSoundEffect("APACHELOOP1", App.Path & "\Resource\ApacheLoop1.wav", 1)
    Call roLevel.AddNewSoundEffect("LASER", App.Path & "\Resource\Laser.wav", 5)
    Call roLevel.AddNewSoundEffect("WHOOSH", App.Path & "\Resource\Whoosh.wav", 5)
    Call roLevel.AddNewSoundEffect("DOH2", App.Path & "\Resource\Doh2.wav", 1)
    Call roLevel.AddNewSoundEffect("HEYHEYHEY", App.Path & "\Resource\HeyHeyHey.wav", 1)
    Call roLevel.AddNewSoundEffect("GRUNT1", App.Path & "\Resource\Grunt1.wav", 5)
    Call roLevel.AddNewSoundEffect("DOH3", App.Path & "\Resource\Doh3.wav", 1)
    Call roLevel.AddNewSoundEffect("BOOM2", App.Path & "\Resource\Boom2.wav", 2)
    Call roLevel.AddNewSoundEffect("BOOM1", App.Path & "\Resource\Boom1.wav", 1)
    Call roLevel.AddNewSoundEffect("SLUDGE", App.Path & "\Resource\Sludge.wav", 1)
    Call roLevel.AddNewSoundEffect("SPLAT", App.Path & "\Resource\Splat.wav", 1)
    Call roLevel.AddNewSoundEffect("PHONE", App.Path & "\Resource\Phone.wav", 1)
End Sub

Public Function Level1_Initialize2(roLevel As Level) As Boolean
    On Error GoTo Level1_Initialize2_ErrorHandler
    Level1_Initialize2 = False

    Dim liCtr As Integer
    Dim loFormationLeader As Actor2
    Dim loActor As Actor2
    Dim liNumAliens As Integer
    
    Call Levels123_LoadBitMapDefinitions(roLevel)
    Call Levels123_LoadSounds(roLevel)
    
    '1 formation leader, 15xA, 6xB, 2xC, 2xD, 4xE, 1xPlanet, 1xXBonus, 1 CargoShip
    liNumAliens = 1 + 15 + 6 + 2 + 2 + 4 + 1 + 1 + 1
    Call roLevel.InitializeActorArrays(liNumAliens, 10, 20, 2, 1)
    roLevel.lNumAliensMustBeDestroyed = 15 + 2 + 2 + 4
    Set loActor = roLevel.SetPlayer("PLAYER", New BrainsPlayer)
    With loActor.oBitMapDefinition.GetFrameDefinition(0)
        loActor.fX = (roLevel.lPlayWidth / 2)
        loActor.fY = roLevel.lPlayHeight - (.lYSize / 2) - 16
    End With
    Set loFormationLeader = roLevel.AddNewAlien("", New Brains)
    Call loFormationLeader.SetMovementMarching(0, 0, 30, 0, roLevel.lPlayWidth - 240)
    
    For liCtr = 1 To 15
        Set loActor = roLevel.AddNewAlien("ALIENA", New BrainsAlienA)
        If loActor Is Nothing Then
            Exit For
        End If
        loActor.bMustBeDestroyed = True
        Select Case liCtr
            Case 1: Call loActor.SetMovementRelativePosition(loFormationLeader, 1.5, 182)
            Case 2: Call loActor.SetMovementRelativePosition(loFormationLeader, 14.5, 194)
            Case 3: Call loActor.SetMovementRelativePosition(loFormationLeader, 27.5, 182)
            Case 4: Call loActor.SetMovementRelativePosition(loFormationLeader, 40.5, 194)
            Case 5: Call loActor.SetMovementRelativePosition(loFormationLeader, 53.5, 182)
            Case 6: Call loActor.SetMovementRelativePosition(loFormationLeader, 66.5, 194)
            Case 7: Call loActor.SetMovementRelativePosition(loFormationLeader, 79.5, 182)
            Case 8: Call loActor.SetMovementRelativePosition(loFormationLeader, 92.5, 194)
            Case 9: Call loActor.SetMovementRelativePosition(loFormationLeader, 105.5, 182)
            Case 10: Call loActor.SetMovementRelativePosition(loFormationLeader, 118.5, 194)
            Case 11: Call loActor.SetMovementRelativePosition(loFormationLeader, 131.5, 182)
            Case 12: Call loActor.SetMovementRelativePosition(loFormationLeader, 144.5, 194)
            Case 13: Call loActor.SetMovementRelativePosition(loFormationLeader, 157.5, 182)
            Case 14: Call loActor.SetMovementRelativePosition(loFormationLeader, 170.5, 194)
            Case 15: Call loActor.SetMovementRelativePosition(loFormationLeader, 183.5, 182)
        End Select
    Next liCtr
    
    For liCtr = 1 To 6
        Set loActor = roLevel.AddNewAlien("ALIENB", New BrainsAlienB)
        If loActor Is Nothing Then
            Exit For
        End If
        loActor.bMustBeDestroyed = False
        Select Case liCtr
            Case 1: Call loActor.SetMovementRelativePosition(loFormationLeader, 40, 144)
            Case 2: Call loActor.SetMovementRelativePosition(loFormationLeader, 57, 144)
            Case 3: Call loActor.SetMovementRelativePosition(loFormationLeader, 74, 144)
            Case 4: Call loActor.SetMovementRelativePosition(loFormationLeader, 118, 144)
            Case 5: Call loActor.SetMovementRelativePosition(loFormationLeader, 135, 144)
            Case 6: Call loActor.SetMovementRelativePosition(loFormationLeader, 152, 144)
        End Select
    Next liCtr
    
    For liCtr = 1 To 2
        Set loActor = roLevel.AddNewAlien("ALIENC", New BrainsAlienC)
        If loActor Is Nothing Then
            Exit For
        End If
        loActor.bMustBeDestroyed = True
        Select Case liCtr
            Case 1: Call loActor.SetMovementRelativePosition(loFormationLeader, 57, 162)
            Case 2: Call loActor.SetMovementRelativePosition(loFormationLeader, 135, 162)
        End Select
    Next liCtr
  
    For liCtr = 1 To 2
        Set loActor = roLevel.AddNewAlien("ALIEND", New BrainsAlienD)
        If loActor Is Nothing Then
            Exit For
        End If
        loActor.bMustBeDestroyed = True
        Select Case liCtr
            Case 1: Call loActor.SetMovementRelativePosition(loFormationLeader, 57, 122)
            Case 2: Call loActor.SetMovementRelativePosition(loFormationLeader, 135, 122)
        End Select
    Next liCtr
  
    For liCtr = 1 To 4
        Set loActor = roLevel.AddNewAlien("ALIENE", New BrainsAlienE)
        If loActor Is Nothing Then
            Exit For
        End If
        loActor.bMustBeDestroyed = True
        Select Case liCtr
            Case 1: Call loActor.SetMovementRelativePosition(loFormationLeader, 32.5, 170)
            Case 2: Call loActor.SetMovementRelativePosition(loFormationLeader, 84.5, 170)
            Case 3: Call loActor.SetMovementRelativePosition(loFormationLeader, 110.5, 170)
            Case 4: Call loActor.SetMovementRelativePosition(loFormationLeader, 162.5, 170)
        End Select
    Next liCtr
  
    Set loActor = roLevel.AddNewAlien("PLANET", New BrainsPlanet)
  
    Set loActor = roLevel.AddNewAlien("XBONUS", New BrainsXBonus)
  
    Set loActor = roLevel.AddNewAlien("ROCKET", New BrainsCargoShip)
  
    Level1_Initialize2 = True
    
    Exit Function
        
Level1_Initialize2_ErrorHandler:
    HandleError Err.Number, Err.Description, Err.LastDllError, Err.source, "Level1_Initialize2"
End Function

Public Function Level2_Initialize2(roLevel As Level) As Boolean
    On Error GoTo Level2_Initialize2_ErrorHandler
    Level2_Initialize2 = False

    Dim liCtr As Integer
    Dim liTemp As Integer
    Dim loActor As Actor2
    Dim liNumAliens As Integer
    Dim loRadialMovementPoints As RadialMovementPoints
    Dim loRadialMovementPoints2 As RadialMovementPoints
    
    Call Levels123_LoadBitMapDefinitions(roLevel)
    Call Levels123_LoadSounds(roLevel)
    
    Const liALIENSA = 20
    Const liALIENSB = 9
    Const liALIENSC = 2
    Const liALIENSD = 2
    Const liALIENSE = 6
    '+ 1xPlanet, 1xXBonus, 1 CargoShip
    liNumAliens = liALIENSA + liALIENSB + liALIENSC + liALIENSD + liALIENSE + 1 + 1 + 1
    roLevel.lNumAliensMustBeDestroyed = liALIENSA + liALIENSC + liALIENSD + liALIENSE
    Call roLevel.InitializeActorArrays(liNumAliens, 10, 20, 2, 1)
    Set loActor = roLevel.SetPlayer("PLAYER", New BrainsPlayer)
    With loActor.oBitMapDefinition.GetFrameDefinition(0)
        loActor.fX = (roLevel.lPlayWidth / 2)
        loActor.fY = roLevel.lPlayHeight - (.lYSize / 2) - 16
    End With
    
    For liCtr = 1 To liALIENSA
        Set loActor = roLevel.AddNewAlien("ALIENA", New BrainsAlienA)
        If loActor Is Nothing Then
            Exit For
        End If
        loActor.bMustBeDestroyed = True
        
        If liCtr <= (liALIENSA / 2) Then
            liTemp = liCtr - 1
'            Call loActor.SetMovementNormal(220! - (liTemp * 15!) , 180 + (liTemp * 9) , 0, 0)
            Call loActor.SetMovementNormal(85! + (liTemp * 15!), 300 - 100 * Sin(liTemp * 5 / 180 * 2 * 3.14), 0, 0)
        Else
            liTemp = liCtr - (liALIENSA / 2) - 1
'            Call loActor.SetMovementNormal(420! + (liTemp * 15!) , 180 + (liTemp * 9) , 0, 0)
            Call loActor.SetMovementNormal(555! - (liTemp * 15!), 300 - 100 * Sin(liTemp * 5 / 180 * 2 * 3.14), 0, 0)
        End If
    Next liCtr
    
    For liCtr = 1 To liALIENSB
    Set loActor = roLevel.AddNewAlien("ALIENB", New BrainsAlienB)
        If loActor Is Nothing Then
            Exit For
        End If
        loActor.bMustBeDestroyed = False
        Call loActor.SetMovementNormal(320 - (CSng(liALIENSB - 1) * 18! / 2!) + ((liCtr - 1) * 18), 200, 0, 0)
    Next liCtr
    
    For liCtr = 1 To liALIENSC
        Set loActor = roLevel.AddNewAlien("ALIENC", New BrainsAlienC)
        If loActor Is Nothing Then
            Exit For
        End If
        loActor.bMustBeDestroyed = True
        Select Case liCtr
            Case 1: Call loActor.SetMovementNormal(110, 210, 0, 0)
            Case 2: Call loActor.SetMovementNormal(530, 210, 0, 0)
        End Select
    Next liCtr
  
    Set loRadialMovementPoints = CreateRadialMovementPoints(65, 20, 320, 150)
    For liCtr = 1 To liALIENSD
        Set loActor = roLevel.AddNewAlien("ALIEND", New BrainsAlienD)
        If loActor Is Nothing Then
            Exit For
        End If
        loActor.bMustBeDestroyed = True
        Call loActor.SetMovementRadialPoints(loRadialMovementPoints, 4000, (liCtr - 1) * (360! / liALIENSD))
    Next liCtr
  
    Set loRadialMovementPoints = CreateRadialMovementPoints(20, 20, 110, 210)
    Set loRadialMovementPoints2 = CreateRadialMovementPoints(20, 20, 530, 210)
    For liCtr = 1 To liALIENSE
        Set loActor = roLevel.AddNewAlien("ALIENE", New BrainsAlienE)
        If loActor Is Nothing Then
            Exit For
        End If

        If liCtr <= (liALIENSE / 2) Then
            liTemp = liCtr - 1
            Call loActor.SetMovementRadialPoints(loRadialMovementPoints, 3000, 360 / (liALIENSE / 2) * liTemp)
        Else
            liTemp = liCtr - (liALIENSE / 2) - 1
            Call loActor.SetMovementRadialPoints(loRadialMovementPoints2, -3000, 360 / (liALIENSE / 2) * liTemp)
        End If

        loActor.bAlwaysUpdateRadialPosition = True
        loActor.bMustBeDestroyed = True
    Next liCtr
  
    Set loActor = roLevel.AddNewAlien("PLANET", New BrainsPlanet)
  
    Set loActor = roLevel.AddNewAlien("XBONUS", New BrainsXBonus)
  
    Set loActor = roLevel.AddNewAlien("ROCKET", New BrainsCargoShip)
  
    Level2_Initialize2 = True
    
    Exit Function
        
Level2_Initialize2_ErrorHandler:
    HandleError Err.Number, Err.Description, Err.LastDllError, Err.source, "Level2_Initialize2"
End Function

Public Function Level3_Initialize2(roLevel As Level) As Boolean
    On Error GoTo Level3_Initialize2_ErrorHandler
    Level3_Initialize2 = False

    Dim liCtr As Integer
    Dim loFormationLeader As Actor2
    Dim loActor As Actor2
    Dim liNumAliens As Integer
    Dim loRadialMovementPoints As RadialMovementPoints
    Dim loRadialMovementPoints2 As RadialMovementPoints
    
    Call Levels123_LoadBitMapDefinitions(roLevel)
    Call Levels123_LoadSounds(roLevel)
    
    Const liALIENSA1 = 14
    Const liALIENSA2 = 10
    Const liALIENSB = 14
    Const liALIENSC = 2
    Const liALIENSD = 2
    Const liALIENSE = 4
    '+ 1xPlanet, 1xXBonus, 1 CargoShip
    liNumAliens = liALIENSA1 + liALIENSA2 + liALIENSB + liALIENSC + liALIENSD + liALIENSE + 1 + 1 + 1
    roLevel.lNumAliensMustBeDestroyed = liALIENSA1 + liALIENSA2 + liALIENSC + liALIENSD + liALIENSE
    Call roLevel.InitializeActorArrays(liNumAliens, 10, 20, 2, 1)
    Set loActor = roLevel.SetPlayer("PLAYER", New BrainsPlayer)
    With loActor.oBitMapDefinition.GetFrameDefinition(0)
        loActor.fX = (roLevel.lPlayWidth / 2)
        loActor.fY = roLevel.lPlayHeight - (.lYSize / 2) - 16
    End With
'    Set loFormationLeader = roLevel.AddNewAlien("", New Brains)
'    Call loFormationLeader.SetMovementMarching(0, 0, 30, 0, roLevel.lPlayWidth - 240)
    
    Set loRadialMovementPoints = CreateRadialMovementPoints(65, 65, 320, 150)
    For liCtr = 1 To liALIENSA1
        Set loActor = roLevel.AddNewAlien("ALIENA", New BrainsAlienA)
        If loActor Is Nothing Then
            Exit For
        End If
        loActor.bMustBeDestroyed = True
'        Call loActor.SetMovementCircle(320, 150, 65, 65, -10000, (liCtr - 1) * (360! / liALIENSA1))
        Call loActor.SetMovementRadialPoints(loRadialMovementPoints, -10000, (liCtr - 1) * (360! / liALIENSA1))
'        Select Case liCtr
'            Case 1: Call loActor.SetMovementCircle(320, 200, 200, 80, 16000, 0, 1, 2)
'        End Select
    Next liCtr
    
    Set loRadialMovementPoints = CreateRadialMovementPoints(40, 40, 320, 150)
    For liCtr = 1 To liALIENSA2
        Set loActor = roLevel.AddNewAlien("ALIENA", New BrainsAlienA)
        If loActor Is Nothing Then
            Exit For
        End If
        loActor.bMustBeDestroyed = True
'        Call loActor.SetMovementCircle(320, 150, 40, 40, 8000, (liCtr - 1) * (360! / liALIENSA2))
        Call loActor.SetMovementRadialPoints(loRadialMovementPoints, 8000, (liCtr - 1) * (360! / liALIENSA2))
'        Select Case liCtr
'            Case 1: Call loActor.SetMovementCircle(320, 200, 200, 80, 16000, 0, 1, 2)
'        End Select
    Next liCtr
    
    Set loRadialMovementPoints = CreateRadialMovementPoints(25, 25, 180, 200)
    Set loRadialMovementPoints2 = CreateRadialMovementPoints(25, 25, 460, 200)
    For liCtr = 1 To liALIENSB
    Set loActor = roLevel.AddNewAlien("ALIENB", New BrainsAlienB)
        If loActor Is Nothing Then
            Exit For
        End If
        loActor.bMustBeDestroyed = False
        Select Case liCtr
            'center, radius, ticks/rotation, initial degress, (clockwise)
'            Case 1: Call loActor.SetMovementCircle(180, 200, 25, 25, 4000, 0)
'            Case 2: Call loActor.SetMovementCircle(180, 200, 25, 25, 4000, 51)
'            Case 3: Call loActor.SetMovementCircle(180, 200, 25, 25, 4000, 103)
'            Case 4: Call loActor.SetMovementCircle(180, 200, 25, 25, 4000, 154)
'            Case 5: Call loActor.SetMovementCircle(180, 200, 25, 25, 4000, 206)
'            Case 6: Call loActor.SetMovementCircle(180, 200, 25, 25, 4000, 257)
'            Case 7: Call loActor.SetMovementCircle(180, 200, 25, 25, 4000, 309)
'            Case 8: Call loActor.SetMovementCircle(460, 200, 25, 25, -4000, 0)
'            Case 9: Call loActor.SetMovementCircle(460, 200, 25, 25, -4000, 51)
'            Case 10: Call loActor.SetMovementCircle(460, 200, 25, 25, -4000, 103)
'            Case 11: Call loActor.SetMovementCircle(460, 200, 25, 25, -4000, 154)
'            Case 12: Call loActor.SetMovementCircle(460, 200, 25, 25, -4000, 206)
'            Case 13: Call loActor.SetMovementCircle(460, 200, 25, 25, -4000, 257)
'            Case 14: Call loActor.SetMovementCircle(460, 200, 25, 25, -4000, 309)
            Case 1: Call loActor.SetMovementRadialPoints(loRadialMovementPoints, 4000, 0)
            Case 2: Call loActor.SetMovementRadialPoints(loRadialMovementPoints, 4000, 51)
            Case 3: Call loActor.SetMovementRadialPoints(loRadialMovementPoints, 4000, 103)
            Case 4: Call loActor.SetMovementRadialPoints(loRadialMovementPoints, 4000, 154)
            Case 5: Call loActor.SetMovementRadialPoints(loRadialMovementPoints, 4000, 206)
            Case 6: Call loActor.SetMovementRadialPoints(loRadialMovementPoints, 4000, 257)
            Case 7: Call loActor.SetMovementRadialPoints(loRadialMovementPoints, 4000, 309)
            Case 8: Call loActor.SetMovementRadialPoints(loRadialMovementPoints2, -4000, 0)
            Case 9: Call loActor.SetMovementRadialPoints(loRadialMovementPoints2, -4000, 51)
            Case 10: Call loActor.SetMovementRadialPoints(loRadialMovementPoints2, -4000, 103)
            Case 11: Call loActor.SetMovementRadialPoints(loRadialMovementPoints2, -4000, 154)
            Case 12: Call loActor.SetMovementRadialPoints(loRadialMovementPoints2, -4000, 206)
            Case 13: Call loActor.SetMovementRadialPoints(loRadialMovementPoints2, -4000, 257)
            Case 14: Call loActor.SetMovementRadialPoints(loRadialMovementPoints2, -4000, 309)
        End Select
    Next liCtr
    
    Set loRadialMovementPoints = CreateRadialMovementPoints(10, 10, 320, 150)
    For liCtr = 1 To liALIENSC
        Set loActor = roLevel.AddNewAlien("ALIENC", New BrainsAlienC)
        If loActor Is Nothing Then
            Exit For
        End If
        loActor.bMustBeDestroyed = True
'        Call loActor.SetMovementCircle(320, 150, 10, 10, 3000, (liCtr - 1) * (360! / liALIENSC))
        Call loActor.SetMovementRadialPoints(loRadialMovementPoints, 3000, (liCtr - 1) * (360! / liALIENSC))
'        Select Case liCtr
'            Case 1: Call loActor.SetMovementRelativePosition(loFormationLeader, 60, 162)
'        End Select
    Next liCtr
  
    For liCtr = 1 To liALIENSD
        Set loActor = roLevel.AddNewAlien("ALIEND", New BrainsAlienD)
        If loActor Is Nothing Then
            Exit For
        End If
        loActor.bMustBeDestroyed = True
        Select Case liCtr
            Case 1: Call loActor.SetMovementNormal(180, 200, 0, 0)
            Case 2: Call loActor.SetMovementNormal(460, 200, 0, 0)
        End Select
    Next liCtr
  
    Set loRadialMovementPoints = CreateRadialMovementPoints(20, 20, 320, 150)
    For liCtr = 1 To liALIENSE
        Set loActor = roLevel.AddNewAlien("ALIENE", New BrainsAlienE)
'        Call loActor.SetMovementCircle(320, 150, 20, 20, -6000, (liCtr - 1) * (360! / liALIENSE))
        Call loActor.SetMovementRadialPoints(loRadialMovementPoints, -6000, (liCtr - 1) * (360! / liALIENSE))
        If loActor Is Nothing Then
            Exit For
        End If
        loActor.bMustBeDestroyed = True
        loActor.bAlwaysUpdateRadialPosition = True
'        Select Case liCtr
'            Case 1: Call loActor.SetMovementRelativePosition(loFormationLeader, 32.5, 170)
'        End Select
    Next liCtr
  
    Set loActor = roLevel.AddNewAlien("PLANET", New BrainsPlanet)
  
    Set loActor = roLevel.AddNewAlien("XBONUS", New BrainsXBonus)
  
    Set loActor = roLevel.AddNewAlien("ROCKET", New BrainsCargoShip)
  
    Level3_Initialize2 = True
    
    Exit Function
        
Level3_Initialize2_ErrorHandler:
    HandleError Err.Number, Err.Description, Err.LastDllError, Err.source, "Level3_Initialize2"
End Function
