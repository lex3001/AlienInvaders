Attribute VB_Name = "modGamePlay"
Option Explicit

Private msTitle As String
Private mTitleSize As Size

Const miTOP_BORDER% = 32    'minimum 1
Const miBOTTOM_BORDER% = 20     'minimum 9

Global Const giMAX_MISSLES% = 10
'Global Const glMAX_SHIELDS_TICKS = 5000
Global Const glMAX_SHIELDS_TICKS = 50000

'So we know when to quit
Dim mbQuit As Boolean

'Used to pass game context to other modules
Dim mgGame As Game
Dim mlLastShieldsLeft  As Long
Dim miShieldLength As Integer

'Used to keep time
Dim mlTickCount As Long
Dim mlLastTickCount As Long
Dim mlFirstTickCount As Long
Dim mlTicksPassed As Long
Dim mdFrames As Double
Dim mdAvgFramesPerSecond As Double

'Bitmap with resources for the dashboard
Dim mddsDash As IDirectDrawSurface2

'Bitmap with resources for the bonuses
Dim mddsBonuses As IDirectDrawSurface2

'Number of ships- source and dest RECTs for Blt
Private mrNumShipsS As RECT
Private mrNumShipsD As RECT

'Dash- source and dest RECTs for Blt
Private mrDashS As RECT
Private mrDashD As RECT
Private mrDashXBonusS As RECT
Private mrDashXBonusD As RECT

'DDBltFX for blt'ing from dashboard to screen
Private mddfxNormalBlt As DDBLTFX

'Pen used for drawing lines
Dim mlHPen As Long

'DDBltFX for painting the buffer black
Private mddfxPaintBlack As DDBLTFX
'DDBltFX for painting the border lines
Private mddfxPaintBorders As DDBLTFX
'DDBltFX for painting the shield indicator
Private mddfxPaintShields As DDBLTFX
    
'STARS
Type Star
    dX As Double
    dY As Double
    dVelocity As Double
    lColor As Long
End Type

Const miNUM_STARS% = 50
Dim msStars(1 To miNUM_STARS%) As Star

'Dest RECTs for painting stars
Dim mrStarDest As RECT
'DDBltFX for blting the stars
Dim mddfxStars As DDBLTFX
    
'Rect for top border line
Private mrTopBorder As RECT
'Rect for bottom border line
Private mrBottomBorder As RECT
'Rect for shields indicator
Private mrShields As RECT

Const miMAX_BONUSES% = 20

Dim mDisplayBonuses(1 To miMAX_BONUSES%) As DisplayBonus
Dim mrBonusS As RECT
Dim mrBonusD As RECT

Public Sub DrawBonuses()
    Dim liCtr As Integer
    For liCtr = 1 To miMAX_BONUSES%
        With mDisplayBonuses(liCtr)
            If .bActive Then
                mrBonusS.Top = 7 * Int(.iFrame / 2)
                mrBonusS.Left = 24 * Int(.iFrame Mod 2)
                mrBonusS.Bottom = mrBonusS.Top + 7
                mrBonusS.Right = mrBonusS.Left + 24
                mrBonusD.Top = .iY + mgGame.iPlayYOffset
                mrBonusD.Left = .iX + mgGame.iPlayXOffset
                mrBonusD.Bottom = mrBonusD.Top + 7
                mrBonusD.Right = mrBonusD.Left + 24
                .lTicks = .lTicks + mgGame.lTicksPassed
                If .lTicks > 1500 Then .bActive = False
                mgGame.ddsBackBufferSurface.Blt mrBonusD, mddsBonuses, mrBonusS, _
                        DDBLT_KEYSRCOVERRIDE, mddfxNormalBlt
            End If
        End With
    Next liCtr
End Sub
    
Public Sub AddBonus(ByVal viFrame As Integer, ByVal viX As Integer, ByVal viY As Integer)
    Dim liCtr As Integer
    For liCtr = 1 To miMAX_BONUSES%
        With mDisplayBonuses(liCtr)
            If Not .bActive Then
                .bActive = True
                .iX = viX
                If .iX < 0 Then .iX = 0
                If (.iX + 24) > mgGame.iPlayWidth Then .iX = mgGame.iPlayWidth - 24
                .iY = viY
                If .iY < 0 Then .iY = 0
                If (.iY + 7) > mgGame.iPlayHeight Then .iY = mgGame.iPlayHeight - 7
                .lTicks = 0
                .iFrame = viFrame
                Exit For
            End If
        End With
    Next liCtr
End Sub

Public Sub BltNumber(rlNumber As Long, riTop As Integer, riLeft As Integer, riDigits As Integer, rbLeadingZeros As Boolean)
    Dim liCtr As Integer
    Dim liValue As Integer
    Dim lbStarted As Boolean
    Dim llMultiplier As Long
    Dim liPos As Integer
    Dim lrDigitS As RECT
    Dim lrDigitD As RECT
    
    With lrDigitS
        .Top = 48
        .Bottom = 58
    End With
    
    With lrDigitD
        .Top = riTop
        .Bottom = riTop + 10
    End With
    
    llMultiplier = 10 ^ (riDigits - 1)
    lbStarted = IIf(rbLeadingZeros, True, False)
    liPos = 0
    
    For liCtr = riDigits To 1 Step -1
        liValue = Int(rlNumber / llMultiplier) Mod 10
        If lbStarted Or (liValue > 0) Or (liCtr = 1) Then
            lbStarted = True
            lrDigitS.Left = liValue * 8
            lrDigitS.Right = lrDigitS.Left + 8
            lrDigitD.Left = riLeft + liPos * 8
            lrDigitD.Right = lrDigitD.Left + 8
            'Blt Digit
            mgGame.ddsBackBufferSurface.Blt lrDigitD, mddsDash, _
                    lrDigitS, DDBLT_KEYSRCOVERRIDE, mddfxNormalBlt
        End If
        llMultiplier = llMultiplier / 10
        liPos = liPos + 1
    Next liCtr
End Sub
    
Public Sub GamePlay_Start()
    On Error GoTo GamePlay_Start_ErrorHandler
    mbQuit = False
    
    Call GamePlay_Initialize
    
    Dim liCtr As Integer
    Do
        For liCtr = 1 To miMAX_BONUSES%
            mDisplayBonuses(liCtr).bActive = False
        Next liCtr
        Call Level1_Initialize(mgGame)
        If gbErrorFlag Then
            Call Level1_Terminate
            Call GamePlay_Terminate
            Exit Sub
        End If
        
        
        Call GamePlay_Init_Clock
        'Menu Loop
        Do
            If gbErrorFlag Then Exit Do
            Call GamePlay_Draw
            Call DirectInput_GetKeyboardState
            Call Level1_UpdateAndDraw(mgGame)
            Call DirectDraw_Flip
            Call GamePlay_CheckInput
            DoEvents
            Call GamePlay_Update_Clock
        Loop While Not (mbQuit Or mgGame.bIsLevelComplete Or mgGame.bIsGameOver Or mgGame.bIsPlayerDead)
        mgGame.bIsPlayerDead = False
        If mgGame.iNumShips <= 0 Then mgGame.bIsGameOver = True
        DoEvents
        
        Call Level1_Terminate
    Loop While Not (mbQuit Or mgGame.bIsLevelComplete Or mgGame.bIsGameOver)
    
    Call GamePlay_Terminate
    Exit Sub
    
GamePlay_Start_ErrorHandler:
    HandleError Err.Number, Err.Description, Err.LastDllError, Err.source, "GamePlay_Start"
    Call Level1_Terminate
    Call GamePlay_Terminate
End Sub

Private Sub GamePlay_Init_Clock()
    mlTicksPassed = 0
    mdFrames = 0
    mlTickCount = Win32.GetTickCount()
    mlFirstTickCount = mlTickCount
    mlLastTickCount = mlTickCount
End Sub

Private Sub GamePlay_Update_Clock()
    With mgGame
        mdFrames = mdFrames + 1
        Do
            DoEvents
            mlTickCount = Win32.GetTickCount()
            mlTicksPassed = mlTickCount - mlLastTickCount
            If .bRealTime Then Exit Do
        Loop While (mlTicksPassed < .lTicksPerLoop)
            
        If .bRealTime Then
            If .lTicksPassed <= .lMaxTicksPerLoop Then
                .lTicksPassed = mlTicksPassed
            Else
                .lTicksPassed = .lMaxTicksPerLoop
            End If
        Else
            .lTicksPassed = .lTicksPerLoop
        End If
        
        .lBonusTicks = .lBonusTicks + .lTicksPassed
        If .lBonusTicks > 500 Then
            .lBonusTicks = 0
            .lBonus = .lBonus - 10
        End If
        mlLastTickCount = mlTickCount
        mdAvgFramesPerSecond = mdFrames * 1000 / (mlTickCount - mlFirstTickCount)
    End With
End Sub

Public Sub GamePlay_Initialize()
    Dim llHPalette As Long
    Dim llHDc As Long
    Dim liCtr As Integer
    
    mgGame.iPlayHeight = SCREENHEIGHT - miBOTTOM_BORDER% - miTOP_BORDER%
    mgGame.iPlayWidth = SCREENWIDTH
    mgGame.iPlayXOffset = 0
    mgGame.iPlayYOffset = miTOP_BORDER%
    mgGame.lTicksPassed = 0
    mgGame.lTicksPerLoop = 40 '(60 is about 17 frames per second, 40 is 25fps)
    mgGame.lMaxTicksPerLoop = 60
    mgGame.bRealTime = True 'hopefully smoother????
    mgGame.lScore = 0
    mgGame.iNumShips = 3
    mgGame.lShieldsLeft = glMAX_SHIELDS_TICKS / 2
    mgGame.lBonus = 2500
    Set mgGame.ddDirectDraw = DirectDraw_Get()
    Set mgGame.ddsBackBufferSurface = DirectDraw_GetBackBufferSurface()
    mgGame.bIsGameOver = False
    mgGame.bIsLevelComplete = False

    mlLastShieldsLeft = -1
    miShieldLength = 1
    
    mgGame.ddsBackBufferSurface.GetDC llHDc
        
    'get a windows palette so we can get the correct palette entries for nearest matching colors
    llHPalette = CreatePalette256(GetSystemPaletteCopy(llHDc))
    
    'For clearing the back buffer
    With mddfxPaintBlack
        .dwSize = Len(mddfxPaintBlack)
        .dwFillColor = Win32.GetNearestPaletteIndex(llHPalette, RGB(0, 0, 0))
    End With

    'For painting border lines
    With mddfxPaintBorders
        .dwSize = Len(mddfxPaintBorders)
        .dwFillColor = Win32.GetNearestPaletteIndex(llHPalette, RGB(0, 0, 255))
    End With
    
    'For painting shield indicator
    With mddfxPaintShields
        .dwSize = Len(mddfxPaintShields)
        .dwFillColor = Win32.GetNearestPaletteIndex(llHPalette, RGB(96, 96, 192))
    End With
    
    'For painting top border
    With mrTopBorder
        .Top = miTOP_BORDER% - 1
        .Left = 0
        .Bottom = miTOP_BORDER%
        .Right = SCREENWIDTH
    End With
    
    'For painting bottom border
    With mrBottomBorder
        .Top = SCREENHEIGHT - miBOTTOM_BORDER%
        .Left = 0
        .Bottom = SCREENHEIGHT - miBOTTOM_BORDER% + 1
        .Right = SCREENWIDTH
    End With
    
    'For painting shields
    With mrShields
        .Top = SCREENHEIGHT - miBOTTOM_BORDER% - 2 + 8
        .Left = 320
        .Bottom = .Top + 7
        .Right = 100 + ((mgGame.lShieldsLeft / glMAX_SHIELDS_TICKS) * 100)
    End With
    
    'For drawing horizontal line on screen
    mlHPen = CreatePen(PS_SOLID, 1, RGB(0, 0, 255))

    For liCtr = 1 To miNUM_STARS%
        With msStars(liCtr)
            .dX = mgGame.iPlayXOffset + (Rnd * (mgGame.iPlayWidth - 1))
            .dY = mgGame.iPlayYOffset + (Rnd * (mgGame.iPlayHeight - 1))
            .dVelocity = (Rnd * 9.75) + 0.25
'            .lColor = RGB(Rnd * .dVelocity * 9.6 + 32, Rnd * .dVelocity * 9.6 + 32, Rnd * .dVelocity * 9.6 + 32)
            .lColor = Win32.GetNearestPaletteIndex(llHPalette, RGB(Rnd * .dVelocity * 9.6 + 32, Rnd * .dVelocity * 9.6 + 32, Rnd * .dVelocity * 9.6 + 32))
'            .lColor = Int(.dVelocity)
        End With
    Next liCtr

    With mddfxStars
        .dwSize = Len(mddfxStars)
    End With

    msTitle = "Alien Invaders " & App.Major & "." & App.Minor & " build " & App.Revision & " " & Chr$(169) & " 1998 Luther Ananda Miller"

    'release the windows palette object, if we got one
    Win32.DeleteObject llHPalette
    'release DC on surface
    mgGame.ddsBackBufferSurface.ReleaseDC llHDc

    With mddfxNormalBlt
        .dwSize = Len(mddfxNormalBlt)
        .ddckSrcColorkey.dwColorSpaceHighValue = 0
        .ddckSrcColorkey.dwColorSpaceLowValue = 0
    End With

    Set mddsDash = LoadBitmapIntoDXS(mgGame.ddDirectDraw, _
            App.Path + "\Resource\Dash.bmp")

    '======= get these RECTs ready for Dashboard blits ========
    
    'number of ships left
    With mrNumShipsS
        .Top = 0
        .Left = 0
        .Bottom = .Top + 12
        '.Right = 'must get set at runtime
    End With

    With mrNumShipsD
        .Top = SCREENHEIGHT - miBOTTOM_BORDER% + 2
        .Left = 0
        .Bottom = .Top + 12
        '.Right = 'must get set at runtime
    End With

    'Dash
    With mrDashS
        .Top = 80 'for German
        .Left = 0 'for German, 48
        .Bottom = .Top + 16
        .Right = .Left + 640
    End With

    With mrDashD
        .Top = SCREENHEIGHT - miBOTTOM_BORDER% + 2
        .Left = 0
        .Bottom = .Top + 16
        .Right = .Left + 640
    End With

    'XBonus (multiplier)
    With mrDashXBonusS
        .Top = 0
        .Bottom = .Top + 12
    End With

    With mrDashXBonusD
        .Top = SCREENHEIGHT - miBOTTOM_BORDER% + 4
        .Left = 516
        .Right = .Left + 12
        .Bottom = .Top + 12
    End With

    Set mddsBonuses = LoadBitmapIntoDXS(mgGame.ddDirectDraw, _
            App.Path + "\Resource\Bonuses.bmp")
End Sub

Public Sub GamePlay_Terminate()
    Set mddsBonuses = Nothing
    Set mddsDash = Nothing
    Set mgGame.ddsBackBufferSurface = Nothing
    Set mgGame.ddDirectDraw = Nothing

    'For drawing horizontal line on screen
    DeleteObject mlHPen

End Sub

Public Sub GamePlay_CheckInput()
    If DirectInput_IsKeyDown(DirectX.DIK_ESCAPE) Then
        mbQuit = True
    End If
End Sub

Public Function GamePlay_Draw() As Boolean
    Dim lsMsg As String
    Dim lMsgSize As Size
    Dim llHDc As Long
    Dim liCtr As Integer
    
    'Paint entire back buffer black (clear it!)
    mgGame.ddsBackBufferSurface.Blt ByVal 0&, Nothing, ByVal 0&, _
            DDBLT_COLORFILL Or DDBLT_WAIT, mddfxPaintBlack
    
    'Paint top border
    mgGame.ddsBackBufferSurface.Blt mrTopBorder, Nothing, ByVal 0&, _
            DDBLT_COLORFILL Or DDBLT_WAIT, mddfxPaintBorders
    
    'Paint bottom border
    mgGame.ddsBackBufferSurface.Blt mrBottomBorder, Nothing, ByVal 0&, _
            DDBLT_COLORFILL Or DDBLT_WAIT, mddfxPaintBorders
    
    'Blt Dashboad
    mgGame.ddsBackBufferSurface.Blt mrDashD, mddsDash, _
            mrDashS, DDBLT_KEYSRCOVERRIDE, mddfxNormalBlt
    
    'Blt number of ships
    If mgGame.iNumShips > 0 Then
        mrNumShipsS.Right = IIf(mgGame.iNumShips < 6, mgGame.iNumShips * 13, 72)
        mrNumShipsD.Right = mrNumShipsS.Right
        mgGame.ddsBackBufferSurface.Blt mrNumShipsD, mddsDash, _
                mrNumShipsS, DDBLT_KEYSRCOVERRIDE, mddfxNormalBlt
    End If
    
    'Paint shield indicator
    If mgGame.lShieldsLeft > 0 Then
        'quicker to just compare than to compute every time
        If mlLastShieldsLeft <> mgGame.lShieldsLeft Then
            mlLastShieldsLeft = mgGame.lShieldsLeft
            miShieldLength = ((mgGame.lShieldsLeft / glMAX_SHIELDS_TICKS) * 100)
            If (miShieldLength > 100) Then
                miShieldLength = 100
            ElseIf (miShieldLength < 1) Then
                miShieldLength = 1
            End If
            mrShields.Right = mrShields.Left + miShieldLength
        End If
        
        mgGame.ddsBackBufferSurface.Blt mrShields, Nothing, ByVal 0&, _
                DDBLT_COLORFILL Or DDBLT_WAIT, mddfxPaintShields
    End If
    
    'Blit Bonus multiplier
    If mgGame.iBonusMultiplier > 1 Then
        mrDashXBonusS.Left = 96 + ((mgGame.iBonusMultiplier - 2) * 12)
        mrDashXBonusS.Right = mrDashXBonusS.Left + 12
        mgGame.ddsBackBufferSurface.Blt mrDashXBonusD, mddsDash, _
                mrDashXBonusS, DDBLT_KEYSRCOVERRIDE, mddfxNormalBlt
    End If
    
    'Draw Score
    BltNumber mgGame.lScore, mrDashD.Top + 3, 582, 7, True
    BltNumber mgGame.lBonus, mrDashD.Top + 3, 472, 5, False
    
    'Draw current bonuses
    Call DrawBonuses
    
    'Lock a DC for drawing and text operations
    Call mgGame.ddsBackBufferSurface.GetDC(llHDc)
    
    'Show mdFrames per Second ===== TEMPORARY ======
    If (mlTicksPassed > 0) Then
        lsMsg = Format$(mdAvgFramesPerSecond, "0") & "fps "
    Else
        lsMsg = ""
    End If
    
    'Paint FPS
    Call SetBkColor(llHDc, RGB(0, 0, 0))
    Call SetTextColor(llHDc, RGB(255, 255, 0))
    Call GetTextExtentPoint32(llHDc, lsMsg, Len(lsMsg), lMsgSize)
    Call TextOut(llHDc, SCREENWIDTH - lMsgSize.cx - 1, _
                0, lsMsg, Len(lsMsg))
    
    'Paint Title text
    Call SetTextColor(llHDc, RGB(64, 64, 255))
    Call GetTextExtentPoint32(llHDc, msTitle, Len(msTitle), mTitleSize)
    Call TextOut(llHDc, mgGame.iPlayXOffset + ((mgGame.iPlayWidth - mTitleSize.cx) / 2), _
            mgGame.iPlayYOffset - mTitleSize.cy - 1, msTitle, Len(msTitle))
    
    'Release DC
    Call mgGame.ddsBackBufferSurface.ReleaseDC(llHDc)
    
    'Do Stars
    For liCtr = 1 To miNUM_STARS%
        With msStars(liCtr)
            mrStarDest.Left = CInt(.dX)
            mrStarDest.Right = mrStarDest.Left + 1
            mrStarDest.Top = CInt(.dY)
            mrStarDest.Bottom = mrStarDest.Top + 1
            mddfxStars.dwFillColor = .lColor
            mgGame.ddsBackBufferSurface.Blt mrStarDest, Nothing, ByVal 0&, _
                    DDBLT_COLORFILL Or DDBLT_WAIT, mddfxStars
                        
            .dY = .dY - (mgGame.lTicksPassed * .dVelocity / 1000)
            If (.dY < mgGame.iPlayYOffset) Then
                .dY = mgGame.iPlayYOffset + mgGame.iPlayHeight - 1
                .dX = mgGame.iPlayXOffset + (Rnd * (mgGame.iPlayWidth - 1))
            End If
        End With
    Next liCtr

End Function


