Attribute VB_Name = "AlienDefinitions"
Option Explicit

'Dim miHseExplosion As Integer

Public Sub Define_AlienA(roLevel As Level)
    Dim lddsBitMap As IDirectDrawSurface2
    Dim loBitMapDefinition As BitMapDefinition
    Dim loFrameDefinition As FrameDefinition
    
    'Alien A's BitMapDefinition
    Set lddsBitMap = LoadBitmapIntoDXS(roLevel.ddDirectDraw, _
            App.Path + "\Resource\AlienA.bmp")
    Set loBitMapDefinition = roLevel.AddNewBitMapDefinition("ALIENA", lddsBitMap, _
        32, 8, 4, 36)
    Set loFrameDefinition = loBitMapDefinition.AddFrameDefinition("ALL", 0, 0, 23, 8, True, _
        frameDefAssignmentRange, 1, 36)
    Call loFrameDefinition.AddCollisionBox("1", 0, 2, 23, 4)
    Call loBitMapDefinition.AddFrameSequence("NORMAL", 1, 20, loopingOneWay, 50)
    Call loBitMapDefinition.AddFrameSequence("EXPLODE", 21, 16, loopingNone, 10)
End Sub

Public Sub Define_AlienB(roLevel As Level)
    Dim lddsBitMap As IDirectDrawSurface2
    Dim loBitMapDefinition As BitMapDefinition
    Dim loFrameDefinition As FrameDefinition

    'Alien B's BitMapDefinition
    Set lddsBitMap = LoadBitmapIntoDXS(roLevel.ddDirectDraw, _
            App.Path + "\Resource\AlienB.bmp")
    Set loBitMapDefinition = roLevel.AddNewBitMapDefinition("ALIENB", lddsBitMap, _
        16, 16, 8, 64)
    Set loFrameDefinition = loBitMapDefinition.AddFrameDefinition("ALL", 0, 0, 16, 16, True, _
        frameDefAssignmentRange, 1, 64)
    Call loFrameDefinition.AddCollisionBox("1", 0, 0, 16, 9)
    Call loBitMapDefinition.AddFrameSequence("3_LEGS", 1, 8, loopingOneWay, 80)
    Call loBitMapDefinition.AddFrameSequence("3_LEGS_HIT", 9, 8, loopingNone, 80)
    Call loBitMapDefinition.AddFrameSequence("2_LEGS", 17, 8, loopingOneWay, 80)
    Call loBitMapDefinition.AddFrameSequence("2_LEGS_HIT", 25, 8, loopingNone, 80)
    Call loBitMapDefinition.AddFrameSequence("1_LEG", 33, 8, loopingOneWay, 80)
    Call loBitMapDefinition.AddFrameSequence("1_LEG_HIT", 41, 8, loopingNone, 80)
    Call loBitMapDefinition.AddFrameSequence("0_LEGS", 49, 8, loopingOneWay, 80)
    Call loBitMapDefinition.AddFrameSequence("EXPLODE", 57, 8, loopingNone, 40)
End Sub
    
Public Sub Define_AlienC(roLevel As Level)
    Dim lddsBitMap As IDirectDrawSurface2
    Dim loBitMapDefinition As BitMapDefinition
    Dim loFrameDefinition As FrameDefinition

    'Alien C's BitMapDefinition
    Set lddsBitMap = LoadBitmapIntoDXS(roLevel.ddDirectDraw, _
            App.Path + "\Resource\AlienC.bmp")
    Set loBitMapDefinition = roLevel.AddNewBitMapDefinition("ALIENC", lddsBitMap, _
        16, 16, 8, 32)
    Set loFrameDefinition = loBitMapDefinition.AddFrameDefinition("ALL", 0, 0, 10, 16, True, _
        frameDefAssignmentRange, 1, 32)
    Call loFrameDefinition.AddCollisionBox("1", 0, 0, 10, 9)
    Call loBitMapDefinition.AddFrameSequence("NORMAL", 1, 8, loopingOneWay, 125)
    Call loBitMapDefinition.AddFrameSequence("ATTACK_LEFT", 9, 8, loopingOneWay, 125)
    Call loBitMapDefinition.AddFrameSequence("ATTACK_RIGHT", 17, 8, loopingOneWay, 125)
    Call loBitMapDefinition.AddFrameSequence("EXPLODE", 25, 8, loopingNone, 40)
End Sub
    
Public Sub Define_AlienD(roLevel As Level)
    Dim lddsBitMap As IDirectDrawSurface2
    Dim loBitMapDefinition As BitMapDefinition
    Dim loFrameDefinition As FrameDefinition

    'Alien D's BitMapDefinition
    Set lddsBitMap = LoadBitmapIntoDXS(roLevel.ddDirectDraw, _
            App.Path + "\Resource\AlienD.bmp")
    Set loBitMapDefinition = roLevel.AddNewBitMapDefinition("ALIEND", lddsBitMap, _
        32, 24, 4, 28)
    Set loFrameDefinition = loBitMapDefinition.AddFrameDefinition("ALL", 0, 0, 20, 20, True, _
        frameDefAssignmentRange, 1, 28)
    Call loFrameDefinition.AddCollisionBox("1", 0, 0, 20, 20)
    Call loBitMapDefinition.AddFrameSequence("NORMAL", 1, 20, loopingOneWay, 25)
    Call loBitMapDefinition.AddFrameSequence("EXPLODE", 21, 8, loopingNone, 40)
End Sub
    
Public Sub Define_AlienE(roLevel As Level)
    Dim lddsBitMap As IDirectDrawSurface2
    Dim loBitMapDefinition As BitMapDefinition
    Dim loFrameDefinition As FrameDefinition

    'Alien E's BitMapDefinition
    Set lddsBitMap = LoadBitmapIntoDXS(roLevel.ddDirectDraw, _
            App.Path + "\Resource\AlienE2.bmp")
    Set loBitMapDefinition = roLevel.AddNewBitMapDefinition("ALIENE", lddsBitMap, _
        16, 16, 8, 64)
    Set loFrameDefinition = loBitMapDefinition.AddFrameDefinition("FORMATION", 0, 0, 13, 8, True, _
        frameDefAssignmentRange, 1, 24)
    Call loFrameDefinition.AddCollisionBox("1", 0, 0, 13, 4)
    Set loFrameDefinition = loBitMapDefinition.AddFrameDefinition("ATTACK", 0, 0, 14, 13, True, _
        frameDefAssignmentRange, 25, 64)
    Call loFrameDefinition.AddCollisionBox("1", 0, 0, 14, 9)
    Call loBitMapDefinition.AddFrameSequence("FORMATION", 1, 8, loopingOneWay, 75)
    Call loBitMapDefinition.AddFrameSequence("LEAVE_FORMATION", 9, 8, loopingNoneReverse, 75)
    Call loBitMapDefinition.AddFrameSequence("ENTER_FORMATION", 9, 8, loopingNone, 75)
    Call loBitMapDefinition.AddFrameSequence("FORMATION_EXPLODE", 17, 8, loopingNone, 40)
    Call loBitMapDefinition.AddFrameSequence("ATTACK_LEFT", 25, 8, loopingOneWay, 75)
    Call loBitMapDefinition.AddFrameSequence("ATTACK_RIGHT", 33, 8, loopingOneWay, 75)
    Call loBitMapDefinition.AddFrameSequence("TURN_RIGHT", 41, 4, loopingNone, 75)
    Call loBitMapDefinition.AddFrameSequence("TURN_LEFT", 45, 4, loopingNone, 75)
    Call loBitMapDefinition.AddFrameSequence("ATTACK_LEFT_EXPLODE", 49, 8, loopingNone, 40)
    Call loBitMapDefinition.AddFrameSequence("ATTACK_RIGHT_EXPLODE", 57, 8, loopingNone, 40)
End Sub
    
Public Sub Define_ABomb(roLevel As Level)
    Dim lddsBitMap As IDirectDrawSurface2
    Dim loBitMapDefinition As BitMapDefinition
    Dim loFrameDefinition As FrameDefinition

    Dim lPalette As IDirectDrawPalette
    'gDDSFront.GetPalette lPalette
    
    'ABomb's BitMapDefinition
    'Set lddsBitMap = LoadBitmapIntoDXS(roLevel.ddDirectDraw, _
    '        App.Path + "\Resource\BombA.bmp", lPalette)
    Set lddsBitMap = LoadBitmapIntoDXS(roLevel.ddDirectDraw, _
            App.Path + "\Resource\BombA.bmp")
    
    Set loBitMapDefinition = roLevel.AddNewBitMapDefinition("ABOMB", lddsBitMap, _
        2, 8, 1, 1)
    Set loFrameDefinition = loBitMapDefinition.AddFrameDefinition("ALL", 0, 0, 2, 8, True, _
        frameDefAssignmentSingle, 1)
    Call loFrameDefinition.AddCollisionBox("1", 0, 0, 2, 8)
    Call loBitMapDefinition.AddFrameSequence("NORMAL", 1, 1, loopingOneWay, 40)

    Set lPalette = Nothing
End Sub
    
Public Sub Define_DBomb(roLevel As Level)
    Dim lddsBitMap As IDirectDrawSurface2
    Dim loBitMapDefinition As BitMapDefinition
    Dim loFrameDefinition As FrameDefinition

    'DBomb's BitMapDefinition
    Set lddsBitMap = LoadBitmapIntoDXS(roLevel.ddDirectDraw, _
            App.Path + "\Resource\BombD.bmp")
    Set loBitMapDefinition = roLevel.AddNewBitMapDefinition("DBOMB", lddsBitMap, _
        6, 6, 4, 20)
    Set loFrameDefinition = loBitMapDefinition.AddFrameDefinition("ALL", 0, 0, 5, 5, True, _
        frameDefAssignmentRange, 1, 20)
    Call loFrameDefinition.AddCollisionBox("1", 1, 1, 3, 3)
    Call loBitMapDefinition.AddFrameSequence("NORMAL", 1, 20, loopingOneWay, 40)
End Sub
    
Public Sub Define_Missle(roLevel As Level)
    Dim lddsBitMap As IDirectDrawSurface2
    Dim loBitMapDefinition As BitMapDefinition
    Dim loFrameDefinition As FrameDefinition

    'Missle's BitMapDefinition
    Set lddsBitMap = LoadBitmapIntoDXS(roLevel.ddDirectDraw, _
            App.Path + "\Resource\Missle.bmp")
    Set loBitMapDefinition = roLevel.AddNewBitMapDefinition("MISSILE", lddsBitMap, _
        2, 16, 1, 1)
    Set loFrameDefinition = loBitMapDefinition.AddFrameDefinition("ALL", 0, 0, 2, 8, True, _
        frameDefAssignmentSingle, 1)
    Call loFrameDefinition.AddCollisionBox("1", 0, 0, 2, 8)
    Call loBitMapDefinition.AddFrameSequence("NORMAL", 1, 1, loopingOneWay, 40)
End Sub
    
Public Sub Define_Planet(roLevel As Level)
    Dim lddsBitMap As IDirectDrawSurface2
    Dim loBitMapDefinition As BitMapDefinition
    Dim loFrameDefinition As FrameDefinition

    'Planet's BitMapDefinition
    Set lddsBitMap = LoadBitmapIntoDXS(roLevel.ddDirectDraw, _
            App.Path + "\Resource\Planet.bmp")
    Set loBitMapDefinition = roLevel.AddNewBitMapDefinition("PLANET", lddsBitMap, _
        24, 12, 4, 28)
    Set loFrameDefinition = loBitMapDefinition.AddFrameDefinition("SIZE1", 0, 0, 24, 12, True, _
        frameDefAssignmentList, 1, 28)
    Call loFrameDefinition.AddCollisionBox("1", 9, 4, 6, 4)
    Set loFrameDefinition = loBitMapDefinition.AddFrameDefinition("SIZE2", 0, 0, 24, 12, True, _
        frameDefAssignmentList, 2, 27)
    Call loFrameDefinition.AddCollisionBox("1", 6, 4, 12, 4)
    Set loFrameDefinition = loBitMapDefinition.AddFrameDefinition("SIZE3", 0, 0, 24, 12, True, _
        frameDefAssignmentList, 3, 26)
    Call loFrameDefinition.AddCollisionBox("1", 5, 3, 15, 5)
    Set loFrameDefinition = loBitMapDefinition.AddFrameDefinition("SIZE4", 0, 0, 24, 12, True, _
        frameDefAssignmentList, 4, 25)
    Call loFrameDefinition.AddCollisionBox("1", 2, 3, 19, 5)
    Set loFrameDefinition = loBitMapDefinition.AddFrameDefinition("NORMAL", 0, 0, 24, 12, True, _
        frameDefAssignmentRange, 5, 23)
    Call loFrameDefinition.AddCollisionBox("1", 0, 2, 24, 7)
    Call loBitMapDefinition.AddFrameSequence("ENTERING", 1, 4, loopingNone, 80)
    Call loBitMapDefinition.AddFrameSequence("NORMAL", 5, 19, loopingOneWay, 80)
    Call loBitMapDefinition.AddFrameSequence("LEAVING", 25, 4, loopingNone, 80)
End Sub
    
Public Sub Define_Player(roLevel As Level)
    Dim lddsBitMap As IDirectDrawSurface2
    Dim loBitMapDefinition As BitMapDefinition
    Dim loFrameDefinition As FrameDefinition

    'Player's BitMapDefinition
    Set lddsBitMap = LoadBitmapIntoDXS(roLevel.ddDirectDraw, _
            App.Path + "\Resource\Ship.bmp")
    Set loBitMapDefinition = roLevel.AddNewBitMapDefinition("PLAYER", lddsBitMap, _
        32, 18, 4, 24)
    Set loFrameDefinition = loBitMapDefinition.AddFrameDefinition("NO_SHIELDS", 0, 0, 26, 18, True, _
        frameDefAssignmentRange, 1, 24)
    Call loFrameDefinition.AddCollisionBox("1", 11, 2, 4, 7)
    Call loFrameDefinition.AddCollisionBox("2", 5, 9, 16, 4)
    Call loFrameDefinition.AddCollisionBox("3", 3, 13, 20, 5)
    Call loBitMapDefinition.AddFrameSequence("NORMAL", 1, 1, loopingOneWay, 120)
    Call loBitMapDefinition.AddFrameSequence("SHIELDS", 5, 4, loopingOneWay, 120)
    Call loBitMapDefinition.AddFrameSequence("EXPLODE", 9, 16, loopingNone, 40)
End Sub
    
Public Sub Define_XBonus(roLevel As Level)
    Dim lddsBitMap As IDirectDrawSurface2
    Dim loBitMapDefinition As BitMapDefinition
    Dim loFrameDefinition As FrameDefinition

    'XBonus's BitMapDefinition
    Set lddsBitMap = LoadBitmapIntoDXS(roLevel.ddDirectDraw, _
            App.Path + "\Resource\XBonus.bmp")
    Set loBitMapDefinition = roLevel.AddNewBitMapDefinition("XBONUS", lddsBitMap, _
        12, 12, 4, 4)
    Set loFrameDefinition = loBitMapDefinition.AddFrameDefinition("ALL", 0, 0, 12, 12, True, _
        frameDefAssignmentRange, 1, 4)
    Call loFrameDefinition.AddCollisionBox("1", 0, 0, 12, 12)
    Call loBitMapDefinition.AddFrameSequence("2XBONUS", 1, 1, loopingOneWay, 80)
    Call loBitMapDefinition.AddFrameSequence("3XBONUS", 2, 1, loopingOneWay, 80)
    Call loBitMapDefinition.AddFrameSequence("4XBONUS", 3, 1, loopingOneWay, 80)
    Call loBitMapDefinition.AddFrameSequence("5XBONUS", 4, 1, loopingOneWay, 80)
End Sub

Public Sub Define_Fish(roLevel As Level)
    Dim lddsBitMap As IDirectDrawSurface2
    Dim loBitMapDefinition As BitMapDefinition
    Dim loFrameDefinition As FrameDefinition
    
    'Fish's BitMapDefinition
    Set lddsBitMap = LoadBitmapIntoDXS(roLevel.ddDirectDraw, _
            App.Path + "\Resource\Fish.bmp")
    Set loBitMapDefinition = roLevel.AddNewBitMapDefinition("FISH", lddsBitMap, _
        40, 16, 4, 40)
    Set loFrameDefinition = loBitMapDefinition.AddFrameDefinition("ALL", 0, 0, 40, 16, True, _
        frameDefAssignmentRange, 1, 40)
    Call loFrameDefinition.AddCollisionBox("1", 0, 2, 40, 12)
    Call loBitMapDefinition.AddFrameSequence("NORMAL", 1, 12, loopingTwoWay, 50)
    Call loBitMapDefinition.AddFrameSequence("EXPLODE", 25, 8, loopingNone, 10)
End Sub

Public Sub Define_Rocket(roLevel As Level)
    Dim lddsBitMap As IDirectDrawSurface2
    Dim loBitMapDefinition As BitMapDefinition
    Dim loFrameDefinition As FrameDefinition
    
    'Fish's BitMapDefinition
    Set lddsBitMap = LoadBitmapIntoDXS(roLevel.ddDirectDraw, _
            App.Path + "\Resource\Rocket.bmp")
    Set loBitMapDefinition = roLevel.AddNewBitMapDefinition("ROCKET", lddsBitMap, _
        32, 12, 4, 48)
    Set loFrameDefinition = loBitMapDefinition.AddFrameDefinition("ALL", 0, 0, 32, 12, True, _
        frameDefAssignmentRange, 1, 48)
    Call loFrameDefinition.AddCollisionBox("1", 0, 2, 40, 12)
    Call loBitMapDefinition.AddFrameSequence("GO_LEFT", 1, 16, loopingOneWay, 40)
    Call loBitMapDefinition.AddFrameSequence("EXPLODE_LEFT", 17, 8, loopingNone, 10)
    Call loBitMapDefinition.AddFrameSequence("GO_RIGHT", 25, 16, loopingOneWay, 40)
    Call loBitMapDefinition.AddFrameSequence("EXPLODE_RIGHT", 41, 8, loopingNone, 10)
End Sub

Public Sub Define_Cargo(roLevel As Level)
    Dim lddsBitMap As IDirectDrawSurface2
    Dim loBitMapDefinition As BitMapDefinition
    Dim loFrameDefinition As FrameDefinition
    
    'Fish's BitMapDefinition
    Set lddsBitMap = LoadBitmapIntoDXS(roLevel.ddDirectDraw, _
            App.Path + "\Resource\Cargo.bmp")
    Set loBitMapDefinition = roLevel.AddNewBitMapDefinition("CARGO", lddsBitMap, _
        16, 8, 4, 32)
    Set loFrameDefinition = loBitMapDefinition.AddFrameDefinition("ALL", 0, 0, 11, 7, True, _
        frameDefAssignmentRange, 1, 32)
    Call loFrameDefinition.AddCollisionBox("1", 0, 0, 11, 7)
    Call loBitMapDefinition.AddFrameSequence("ORANGE", 1, 1, loopingOneWay, 40)
    Call loBitMapDefinition.AddFrameSequence("PINK", 2, 1, loopingOneWay, 40)
    Call loBitMapDefinition.AddFrameSequence("YELLOW", 3, 1, loopingOneWay, 40)
    Call loBitMapDefinition.AddFrameSequence("BLUE", 4, 1, loopingOneWay, 40)
    Call loBitMapDefinition.AddFrameSequence("GREEN", 5, 1, loopingOneWay, 40)
    Call loBitMapDefinition.AddFrameSequence("PURPLE", 6, 1, loopingOneWay, 40)
    Call loBitMapDefinition.AddFrameSequence("RED", 7, 1, loopingOneWay, 40)
    Call loBitMapDefinition.AddFrameSequence("NAVY", 8, 1, loopingOneWay, 40)
    Call loBitMapDefinition.AddFrameSequence("REDDOT", 9, 4, loopingOneWay, 80)
    Call loBitMapDefinition.AddFrameSequence("GREENDOT", 13, 4, loopingOneWay, 80)
    Call loBitMapDefinition.AddFrameSequence("BLUEDOT", 17, 4, loopingOneWay, 80)
    Call loBitMapDefinition.AddFrameSequence("PINKDOT", 21, 4, loopingOneWay, 80)
    Call loBitMapDefinition.AddFrameSequence("YELLOWDOT", 25, 4, loopingOneWay, 80)
    Call loBitMapDefinition.AddFrameSequence("COLORDOT", 29, 4, loopingOneWay, 40)
End Sub

