VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
  Persistable = 0  'NotPersistable
  DataBindingBehavior = 0  'vbNone
  DataSourceBehavior  = 0  'vbNone
  MTSTransactionMode  = 0  'NotAnMTSObject
END
Attribute VB_Name = "Game2"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = True
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = False
Option Explicit

'PERFORMANCE MONITORING
Private lPerfTempTickStart As Long
Private dPerfTicksUsed(1 To 100) As Double
Private sPerfItem(1 To 100) As String

'Used to pass game context to other modules
Private oLevel As Level
Private lCurrentLevel As Long

'CLOCK
Private lTickCount As Long
Private lLastTickCount As Long
Private lFirstTickCount As Long
Private lTicksPassed As Long
Private dFrames As Double
Private dAvgFramesPerSecond As Double

'Private bUpdate As Boolean
Private bExitLevelLoop As Boolean
Private Const lEND_LEVEL_PAUSE_TICKS = 500&
Private lEndLevelPauseTicks As Long

'So we know when to quit
Private bQuit As Boolean

'So we exit with the same Caps Lock that we came in with
Private bCapsLockWasDown As Boolean
Private bSaveCapsLock As Boolean

'DASHBOARD and BORDERS

'Game Title
Private sTitle As String
Private sizeTitleSize As Size

'Border Information
Const lTOP_BORDER& = 32&    'minimum 1
Const lBOTTOM_BORDER& = 20&     'minimum 9

'To draw shields
Const lMAX_SHIELDS_TICKS = 50000
Private lLastShieldsLeft  As Long
Private lShieldLength As Long

'Bitmap with resources for the dashboard
Private ddsDash As IDirectDrawSurface2

'Number of ships- source and dest RECTs for Blt
Private rNumShipsS As RECT
Private rNumShipsD As RECT

'Dash- source and dest RECTs for Blt
Private rDashS As RECT
Private rDashD As RECT
Private rDashXBonusS As RECT
Private rDashXBonusD As RECT
Private rDashGadgetS As RECT
Private rDashGadgetD As RECT
Private rLevelFinishedXBonusD As RECT

'DDBltFX for blt'ing from dashboard to screen
Private ddfxNormalBlt As DDBLTFX

'Pen used for drawing lines
Private lHPen As Long

'DDBltFX for painting the buffer black
Private ddfxPaintBlack As DDBLTFX
'DDBltFX for painting the border lines
Private ddfxPaintBorders As DDBLTFX
'DDBltFX for painting the shield indicator
Private ddfxPaintShields As DDBLTFX
Private lShieldsBlue As Long
Private lShieldsYellow As Long
Private lShieldsRed As Long
Private lShieldsBlinkingTicks As Long
Private bShieldsCritical As Boolean
Private bShieldsBlinkingOn As Boolean

'Rect for top border line
Private rTopBorder As RECT
'Rect for bottom border line
Private rBottomBorder As RECT
'Rect for shields indicator
Private rShields As RECT

'STARS
Private Type Star
    fX As Single
    fY As Single
    fVelocity As Single
    lColor As Long
End Type

Const lNUM_STARS& = 50&
Private sStars(1 To lNUM_STARS) As Star

'Dest RECTs for painting stars
Private rStarDest As RECT
'DDBltFX for blting the stars
Private ddfxStars As DDBLTFX
    
'BONUSES (that show as a number like +50 when a bad guy gets killed)
'Bitmap with resources for the bonuses
Private ddsBonuses As IDirectDrawSurface2
Const lMAX_BONUSES& = 20&
Private udtDisplayBonuses(1 To lMAX_BONUSES) As DisplayBonus
Private rectBonusSource As RECT
Private rectBonusDest As RECT

Private Sub PerformanceResetStats()
    Dim llCtr As Long
    For llCtr = LBound(dPerfTicksUsed) To UBound(dPerfTicksUsed)
        dPerfTicksUsed(llCtr) = 0
    Next llCtr
End Sub

Private Sub PerformanceResetCounter()
    lPerfTempTickStart = Win32.timeGetTime()
End Sub

Private Sub PerformanceRecordCounter(ByVal vlIndex As Long)
    dPerfTicksUsed(vlIndex) = Win32.timeGetTime() - lPerfTempTickStart
    PerformanceResetCounter
End Sub

Private Sub PerformanceDumpStatsToLog(ByVal vlToIndex As Long)
    Dim llCtr As Long
    Dim lsTemp As String
    lsTemp = vbCrLf
    For llCtr = LBound(dPerfTicksUsed) To vlToIndex
        lsTemp = lsTemp & "Index (" & Format(llCtr, "000") & ") = " & dPerfTicksUsed(llCtr) & "ms /" & sPerfItem(llCtr) & vbCrLf
    Next llCtr
    LogInfo "Performance Statistics", "", lsTemp
End Sub

Public Sub DrawBonuses()
    Dim llCtr As Long
    For llCtr = 1 To lMAX_BONUSES
        With udtDisplayBonuses(llCtr)
            If .bActive Then
                rectBonusSource.Top = 7 * Int(.lFrame / 2)
                rectBonusSource.Left = 24 * Int(.lFrame Mod 2)
                rectBonusSource.Bottom = rectBonusSource.Top + 7
                rectBonusSource.Right = rectBonusSource.Left + 24
                rectBonusDest.Top = .lY + oLevel.lPlayYOffset
                rectBonusDest.Left = .lX + oLevel.lPlayXOffset
                rectBonusDest.Bottom = rectBonusDest.Top + 7
                rectBonusDest.Right = rectBonusDest.Left + 24
                .lTicks = .lTicks + oLevel.lTicksPassed
                If .lTicks > 1500 Then .bActive = False
                oLevel.ddsBackBufferSurface.Blt rectBonusDest, ddsBonuses, rectBonusSource, _
                        DDBLT_KEYSRCOVERRIDE, ddfxNormalBlt
            End If
        End With
    Next llCtr
End Sub
    
Public Sub AddBonus(ByVal veBonusFrame As BonusFrame_Enum, _
        ByVal vlX As Long, ByVal vlY As Long)
    Dim llCtr As Long
    For llCtr = 1 To lMAX_BONUSES
        With udtDisplayBonuses(llCtr)
            If Not .bActive Then
                .bActive = True
                .lX = vlX
                If .lX < 0 Then .lX = 0
                If (.lX + 24) > oLevel.lPlayWidth Then .lX = oLevel.lPlayWidth - 24
                .lY = vlY
                If .lY < 0 Then .lY = 0
                If (.lY + 7) > oLevel.lPlayHeight Then .lY = oLevel.lPlayHeight - 7
                .lTicks = 0
                .lFrame = veBonusFrame
                Exit For
            End If
        End With
    Next llCtr
End Sub

Public Sub BltNumber(rlNumber As Long, rlTop As Long, rlLeft As Long, rlDigits As Long, rbLeadingZeros As Boolean)
    Dim llCtr As Long
    Dim llValue As Long
    Dim lbStarted As Boolean
    Dim llMultiplier As Long
    Dim llPos As Long
    Dim lrDigitS As RECT
    Dim lrDigitD As RECT
    
    With lrDigitS
        .Top = 48
        .Bottom = 58
    End With
    
    With lrDigitD
        .Top = rlTop
        .Bottom = rlTop + 10
    End With
    
    llMultiplier = 10 ^ (rlDigits - 1)
    lbStarted = IIf(rbLeadingZeros, True, False)
    llPos = 0
    
    For llCtr = rlDigits To 1 Step -1
        llValue = Int(rlNumber / llMultiplier) Mod 10
        If lbStarted Or (llValue > 0) Or (llCtr = 1) Then
            lbStarted = True
            lrDigitS.Left = llValue * 8
            lrDigitS.Right = lrDigitS.Left + 8
            lrDigitD.Left = rlLeft + llPos * 8
            lrDigitD.Right = lrDigitD.Left + 8
            'Blt Digit
            oLevel.ddsBackBufferSurface.Blt lrDigitD, ddsDash, _
                    lrDigitS, DDBLT_KEYSRCOVERRIDE, ddfxNormalBlt
        End If
        llMultiplier = llMultiplier / 10
        llPos = llPos + 1
    Next llCtr
End Sub

Private Sub InitializePlayClock()
    lTicksPassed = 0
    dFrames = 0
    lTickCount = Win32.timeGetTime()
'    lTickCount = Win32.GetTickCount()
    lFirstTickCount = lTickCount
    lLastTickCount = lTickCount
End Sub

Private Sub UpdatePlayClock()
    With oLevel
        dFrames = dFrames + 1
        Do
            DoEvents
            lTickCount = Win32.timeGetTime()
'            lTickCount = Win32.GetTickCount()
            lTicksPassed = lTickCount - lLastTickCount
            If .bRealTime Then Exit Do
        Loop While (lTicksPassed < .lTicksPerLoop)
            
        If .bRealTime Then
            If lTicksPassed <= .lMaxTicksPerLoop Then
                .lTicksPassed = lTicksPassed
            Else
                .lTicksPassed = .lMaxTicksPerLoop
            End If
        Else
            .lTicksPassed = .lTicksPerLoop
        End If
        
        lLastTickCount = lTickCount
        dAvgFramesPerSecond = dFrames * 1000 / (lTickCount - lFirstTickCount)
    End With
End Sub

Public Sub InitializePlay(Optional ByVal vlStartLevel As Long = 1)
    Dim llHPalette As Long
    Dim llHdc As Long
    Dim llCtr As Long
    
    bSaveCapsLock = GetCapsLock()
    SetCapsLock False
    
    lCurrentLevel = vlStartLevel
    Set oLevel = New Level
    Set oLevel.oGame = Me
    Set oLevel.ddDirectDraw = DirectDraw_Get()
    Set oLevel.ddsBackBufferSurface = DirectDraw_GetBackBufferSurface()
    oLevel.lPlayHeight = SCREENHEIGHT - lBOTTOM_BORDER - lTOP_BORDER
    oLevel.lPlayWidth = SCREENWIDTH
    oLevel.lPlayXOffset = 0
    oLevel.lPlayYOffset = lTOP_BORDER
    oLevel.lTicksPassed = 0
    oLevel.lTicksPerLoop = 40 '(60 is about 17 frames per second, 40 is 25fps)
    oLevel.lMaxTicksPerLoop = 80
    oLevel.bRealTime = True 'hopefully smoother????
    oLevel.lScore = 0
    oLevel.lNumShips = 3
    oLevel.lShieldsLeft = lMAX_SHIELDS_TICKS / 2
    oLevel.lStartingBonus = 2500
    oLevel.lBonus = oLevel.lStartingBonus
    oLevel.bIsGameOver = False
    oLevel.bIsLevelComplete = False
    oLevel.bHasDoubleShots = False
    oLevel.bHasRapidFire = False
    oLevel.bHasMultiShots = False

    lLastShieldsLeft = -1
    lShieldLength = 1
    
    DirectDraw_GetBackBufferSurface().GetDC llHdc
        
    'get a windows palette so we can get the correct palette entries for nearest matching colors
    
'    llHPalette = CreatePalette256(GetSystemPaletteCopy(llHdc))
'    llHPalette = CreatePalette256(GetSurfacePaletteCopy(gDDSFront))
    llHPalette = GetGamePalette(llHdc)
    
    'For clearing the back buffer
    With ddfxPaintBlack
        .dwSize = Len(ddfxPaintBlack)
        .dwFillColor = Win32.GetNearestPaletteIndex(llHPalette, RGB(0, 0, 0))
    End With

    'For painting border lines
    With ddfxPaintBorders
        .dwSize = Len(ddfxPaintBorders)
        .dwFillColor = Win32.GetNearestPaletteIndex(llHPalette, RGB(0, 0, 255))
    End With
    
    'For painting shield indicator
    lShieldsBlue = Win32.GetNearestPaletteIndex(llHPalette, RGB(96, 96, 192))
    lShieldsYellow = Win32.GetNearestPaletteIndex(llHPalette, RGB(192, 192, 96))
    lShieldsRed = Win32.GetNearestPaletteIndex(llHPalette, RGB(192, 96, 96))
    With ddfxPaintShields
        .dwSize = Len(ddfxPaintShields)
        .dwFillColor = lShieldsBlue
    End With
    
    'For painting top border
    With rTopBorder
        .Top = lTOP_BORDER - 1
        .Left = 0
        .Bottom = lTOP_BORDER
        .Right = SCREENWIDTH
    End With
    
    'For painting bottom border
    With rBottomBorder
        .Top = SCREENHEIGHT - lBOTTOM_BORDER
        .Left = 0
        .Bottom = SCREENHEIGHT - lBOTTOM_BORDER + 1
        .Right = SCREENWIDTH
    End With
    
    'For painting shields
    With rShields
        .Top = SCREENHEIGHT - lBOTTOM_BORDER - 2 + 8
        .Left = 320
        .Bottom = .Top + 7
        .Right = 100 + ((oLevel.lShieldsLeft / lMAX_SHIELDS_TICKS) * 100)
    End With
    
    'For drawing horizontal line on screen
    lHPen = CreatePen(PS_SOLID, 1, RGB(0, 0, 255))

    For llCtr = 1 To lNUM_STARS
        With sStars(llCtr)
            .fX = oLevel.lPlayXOffset + (Rnd * (oLevel.lPlayWidth - 1))
            .fY = oLevel.lPlayYOffset + (Rnd * (oLevel.lPlayHeight - 1))
            .fVelocity = (Rnd * 9.75) + 0.25
'            .lColor = RGB(Rnd * .dVelocity * 9.6 + 32, Rnd * .dVelocity * 9.6 + 32, Rnd * .dVelocity * 9.6 + 32)
            .lColor = Win32.GetNearestPaletteIndex(llHPalette, RGB(Rnd * .fVelocity * 9.6 + 32, Rnd * .fVelocity * 9.6 + 32, Rnd * .fVelocity * 9.6 + 32))
'            .lColor = Int(.dVelocity)
        End With
    Next llCtr

    With ddfxStars
        .dwSize = Len(ddfxStars)
    End With

    sTitle = "Alien Invaders " & App.Major & "." & App.Minor & " build " & App.Revision & " " & Chr$(169) & " 1998 Luther Ananda Miller"

    'release the windows palette object, if we got one
    Win32.DeleteObject llHPalette
    'release DC on surface
    DirectDraw_GetBackBufferSurface().ReleaseDC llHdc

    With ddfxNormalBlt
        .dwSize = Len(ddfxNormalBlt)
        .ddckSrcColorkey.dwColorSpaceHighValue = 0
        .ddckSrcColorkey.dwColorSpaceLowValue = 0
    End With

    Set ddsDash = LoadBitmapIntoDXS(DirectDraw_Get(), _
            App.Path + "\Resource\Dash.bmp")

    '======= get these RECTs ready for Dashboard blits ========
    
    'number of ships left
    With rNumShipsS
        .Top = 0
        .Left = 0
        .Bottom = .Top + 12
        '.Right = 'must get set at runtime
    End With

    With rNumShipsD
        .Top = SCREENHEIGHT - lBOTTOM_BORDER + 2
        .Left = 0
        .Bottom = .Top + 12
        '.Right = 'must get set at runtime
    End With

    'Dash
    With rDashS
        .Top = 80 'for German
        .Left = 0 'for German, 48
        .Bottom = .Top + 16
        .Right = .Left + 640
    End With

    With rDashD
        .Top = SCREENHEIGHT - lBOTTOM_BORDER + 2
        .Left = 0
        .Bottom = .Top + 16
        .Right = .Left + 640
    End With

    'XBonus (multiplier)
    With rDashXBonusS
        .Top = 0
        .Bottom = .Top + 12
    End With

    With rDashXBonusD
        .Top = SCREENHEIGHT - lBOTTOM_BORDER + 4
        .Left = 516
        .Right = .Left + 12
        .Bottom = .Top + 12
    End With

    'Gadgets
    With rDashGadgetS
        .Top = 0
        .Bottom = .Top + 12
    End With

    With rDashGadgetD
        .Top = SCREENHEIGHT - lBOTTOM_BORDER + 2
        .Bottom = .Top + 12
    End With

    Set ddsBonuses = LoadBitmapIntoDXS(DirectDraw_Get(), _
            App.Path + "\Resource\Bonuses.bmp")
End Sub

Public Sub TerminatePlay()
    Set ddsBonuses = Nothing
    Set ddsDash = Nothing
    If Not oLevel Is Nothing Then
        Set oLevel.ddsBackBufferSurface = Nothing
        Set oLevel.ddDirectDraw = Nothing
        Call oLevel.Terminate
        Set oLevel = Nothing
    End If

    'For drawing horizontal line on screen
    DeleteObject lHPen

    Call SetCapsLock(bSaveCapsLock)
End Sub

Public Sub CheckInput()
    If DirectInput_IsKeyDown(DirectX.DIK_ESCAPE) Then
        bQuit = True
    End If
    
    If DirectInput_IsKeyDown(DirectX.DIK_CAPITAL) Then
        If Not bCapsLockWasDown Then
            With oLevel
                SetCapsLock .bPaused
                .bPaused = Not .bPaused
            End With
        End If
        bCapsLockWasDown = True
    Else
        bCapsLockWasDown = False
    End If
End Sub

Public Function Draw() As Boolean
    Dim lsMsg As String
    Dim lMsgSize As Size
    Dim llHdc As Long
    Dim llCtr As Long
    
    'Paint entire back buffer black (clear it!)
    oLevel.ddsBackBufferSurface.Blt ByVal 0&, Nothing, ByVal 0&, _
            DDBLT_COLORFILL Or DDBLT_WAIT, ddfxPaintBlack
    
    'Paint top border
    oLevel.ddsBackBufferSurface.Blt rTopBorder, Nothing, ByVal 0&, _
            DDBLT_COLORFILL Or DDBLT_WAIT, ddfxPaintBorders
    
    'Paint bottom border
    oLevel.ddsBackBufferSurface.Blt rBottomBorder, Nothing, ByVal 0&, _
            DDBLT_COLORFILL Or DDBLT_WAIT, ddfxPaintBorders
    
    'Blt Dashboad
    oLevel.ddsBackBufferSurface.Blt rDashD, ddsDash, _
            rDashS, DDBLT_KEYSRCOVERRIDE, ddfxNormalBlt
    
    'Blt number of ships
    If oLevel.lNumShips > 0 Then
        rNumShipsS.Right = IIf(oLevel.lNumShips < 6, oLevel.lNumShips * 13, 72)
        rNumShipsD.Right = rNumShipsS.Right
        oLevel.ddsBackBufferSurface.Blt rNumShipsD, ddsDash, _
                rNumShipsS, DDBLT_KEYSRCOVERRIDE, ddfxNormalBlt
    End If
    
    'Blit gadgets
    If oLevel.bHasDoubleShots Then
        rDashGadgetS.Left = 80
        rDashGadgetS.Right = 92
        rDashGadgetD.Left = 80
        rDashGadgetD.Right = 92
        oLevel.ddsBackBufferSurface.Blt rDashGadgetD, ddsDash, _
                rDashGadgetS, DDBLT_KEYSRCOVERRIDE, ddfxNormalBlt
    End If
    If oLevel.bHasRapidFire Then
        rDashGadgetS.Left = 92
        rDashGadgetS.Right = 104
        rDashGadgetD.Left = 92
        rDashGadgetD.Right = 104
        oLevel.ddsBackBufferSurface.Blt rDashGadgetD, ddsDash, _
                rDashGadgetS, DDBLT_KEYSRCOVERRIDE, ddfxNormalBlt
    End If
    If oLevel.bHasMultiShots Then
        rDashGadgetS.Left = 104
        rDashGadgetS.Right = 116
        rDashGadgetD.Left = 104
        rDashGadgetD.Right = 116
        oLevel.ddsBackBufferSurface.Blt rDashGadgetD, ddsDash, _
                rDashGadgetS, DDBLT_KEYSRCOVERRIDE, ddfxNormalBlt
    End If
    If oLevel.bHasSafetyPin Then
        rDashGadgetS.Left = 116
        rDashGadgetS.Right = 128
        rDashGadgetD.Left = 116
        rDashGadgetD.Right = 128
        oLevel.ddsBackBufferSurface.Blt rDashGadgetD, ddsDash, _
                rDashGadgetS, DDBLT_KEYSRCOVERRIDE, ddfxNormalBlt
    End If
    
    'Paint shield indicator
    If oLevel.lShieldsLeft > 0 Then
        'quicker to just compare than to compute every time
        If (lLastShieldsLeft <> oLevel.lShieldsLeft) Then
            lLastShieldsLeft = oLevel.lShieldsLeft
            lShieldLength = ((oLevel.lShieldsLeft / lMAX_SHIELDS_TICKS) * 100)
            If (lShieldLength > 100) Then
                lShieldLength = 100
            ElseIf (lShieldLength < 1) Then
                lShieldLength = 1
            End If
            bShieldsCritical = False
            If lShieldLength > 40 Then
                ddfxPaintShields.dwFillColor = lShieldsBlue
            ElseIf lShieldLength > 20 Then
                ddfxPaintShields.dwFillColor = lShieldsYellow
            Else
                ddfxPaintShields.dwFillColor = lShieldsRed
                If lShieldLength <= 10 Then
                    bShieldsCritical = True
                End If
            End If
            rShields.Right = rShields.Left + lShieldLength
        End If
        
        If bShieldsCritical Then
            lShieldsBlinkingTicks = lShieldsBlinkingTicks + lTicksPassed
            If lShieldsBlinkingTicks > IIf(bShieldsBlinkingOn, 500, 200) Then
                lShieldsBlinkingTicks = 0
                bShieldsBlinkingOn = Not bShieldsBlinkingOn
            End If
        End If
        
        If (Not bShieldsCritical) Or bShieldsBlinkingOn Then
            oLevel.ddsBackBufferSurface.Blt rShields, Nothing, ByVal 0&, _
                    DDBLT_COLORFILL Or DDBLT_WAIT, ddfxPaintShields
        End If
    End If
    
    'Blit Bonus multiplier
    If oLevel.lBonusMultiplier > 1 Then
        rDashXBonusS.Left = 270 + ((oLevel.lBonusMultiplier - 2) * 12)
        rDashXBonusS.Right = rDashXBonusS.Left + 12
        oLevel.ddsBackBufferSurface.Blt rDashXBonusD, ddsDash, _
                rDashXBonusS, DDBLT_KEYSRCOVERRIDE, ddfxNormalBlt
    End If
    
    'Draw Score
    BltNumber oLevel.lScore, rDashD.Top + 3, 582, 7, True
    BltNumber oLevel.lBonus, rDashD.Top + 3, 472, 5, False
    
    'Draw current bonuses
    Call DrawBonuses
    
    'Lock a DC for drawing and text operations
    Call oLevel.ddsBackBufferSurface.GetDC(llHdc)
    
    'Show mdFrames per Second ===== TEMPORARY ======
    If (lTicksPassed > 0) Then
        lsMsg = Format$(dAvgFramesPerSecond, "00") & "/" & Format$(1000! / lTicksPassed, "00") & "fps "
    Else
        lsMsg = ""
    End If
    
    'Paint FPS
    Call SetBkColor(llHdc, RGB(0, 0, 0))
    Call SetTextColor(llHdc, RGB(192, 96, 96))
    Call GetTextExtentPoint32(llHdc, lsMsg, Len(lsMsg), lMsgSize)
    Call TextOut(llHdc, SCREENWIDTH - lMsgSize.cx - 1, _
                0, lsMsg, Len(lsMsg))
    
    'Paint Title text
    Call SetTextColor(llHdc, RGB(0, 96, 192))
    Call GetTextExtentPoint32(llHdc, sTitle, Len(sTitle), sizeTitleSize)
    Call TextOut(llHdc, oLevel.lPlayXOffset + ((oLevel.lPlayWidth - sizeTitleSize.cx) / 2), _
            oLevel.lPlayYOffset - sizeTitleSize.cy - 1, sTitle, Len(sTitle))
    
    'Release DC
    Call oLevel.ddsBackBufferSurface.ReleaseDC(llHdc)
    
    'Do Stars
    For llCtr = 1 To lNUM_STARS
        With sStars(llCtr)
            rStarDest.Left = CLng(.fX)
            rStarDest.Right = rStarDest.Left + 1
            rStarDest.Top = CLng(.fY)
            rStarDest.Bottom = rStarDest.Top + 1
            ddfxStars.dwFillColor = .lColor
            oLevel.ddsBackBufferSurface.Blt rStarDest, Nothing, ByVal 0&, _
                    DDBLT_COLORFILL Or DDBLT_WAIT, ddfxStars
                        
            .fY = .fY - (oLevel.lTicksPassed * .fVelocity / 1000!)
            If (.fY < oLevel.lPlayYOffset) Then
                .fY = oLevel.lPlayYOffset + oLevel.lPlayHeight - 1
                .fX = oLevel.lPlayXOffset + (Rnd * (oLevel.lPlayWidth - 1))
            End If
        End With
    Next llCtr

End Function

Private Sub GameLoop()
Call PerformanceResetStats
sPerfItem(1) = "game Draw"
sPerfItem(2) = "Level.Draw"
sPerfItem(3) = "flip"
sPerfItem(4) = "input/bonus"
sPerfItem(5) = "Level.Update"
sPerfItem(6) = "clock/loop status"
    Do
        If gbErrorFlag Then Exit Do
Call PerformanceResetCounter
        Call Draw
'Call PerformanceRecordCounter(1)
        Call oLevel.Draw
'Call PerformanceRecordCounter(2)
'        Call DirectDraw_Flip
        Call DoFlip
'Call PerformanceRecordCounter(3)
        Call DirectInput_GetKeyboardState
        Call CheckInput
If DirectInput_IsKeyDown(DIK_X) Then oLevel.bIsLevelComplete = True
If DirectInput_IsKeyDown(DIK_Q) Then oLevel.bHasDoubleShots = True
If DirectInput_IsKeyDown(DIK_W) Then oLevel.bHasMultiShots = True
If DirectInput_IsKeyDown(DIK_E) Then oLevel.bHasRapidFire = True
If DirectInput_IsKeyDown(DIK_R) Then oLevel.bHasSafetyPin = True
'If DirectInput_IsKeyDown(DIK_T) Then oLevel.bIsLevelComplete = True
'If DirectInput_IsKeyDown(DIK_Y) Then oLevel.bIsLevelComplete = True
        Call UpdateBonus
'Call PerformanceRecordCounter(4)
        If Not oLevel.bPaused Then Call oLevel.Update
'Call PerformanceRecordCounter(5)
        DoEvents
        Call UpdatePlayClock
        Call CheckLevelLoopStatus
'Call PerformanceRecordCounter(6)
    Loop While Not (bExitLevelLoop Or bQuit Or gbErrorFlag)
    DoEvents
'Call PerformanceDumpStatsToLog(6)
End Sub

Private Sub CheckLevelLoopStatus()
    If oLevel.bIsLevelComplete Or oLevel.bIsGameOver Or oLevel.bIsPlayerDead Then
        lEndLevelPauseTicks = lEndLevelPauseTicks + lTicksPassed
        If lEndLevelPauseTicks > lEND_LEVEL_PAUSE_TICKS Then
            If oLevel.bIsPlayerDead Then
                oLevel.bIsPlayerDead = False
                oLevel.lNumShips = oLevel.lNumShips - 1
                If Not oLevel.bHasSafetyPin Then
                    oLevel.bHasDoubleShots = False
                    oLevel.bHasMultiShots = False
                    oLevel.bHasRapidFire = False
                Else
                    oLevel.bHasSafetyPin = False
                End If
                If oLevel.lNumShips <= 0 Then oLevel.bIsGameOver = True
            End If
            bExitLevelLoop = True
        End If
    End If
End Sub
    
Private Sub InitializeLevelPlay()
    Dim llCtr As Long
    
    For llCtr = 1 To lMAX_BONUSES
        udtDisplayBonuses(llCtr).bActive = False
    Next llCtr
    lEndLevelPauseTicks = 0
    bExitLevelLoop = False
    
    'Initialize Level
    Call oLevel.ResetLevel
    If gbErrorFlag Then Exit Sub
    Select Case (((lCurrentLevel - 1) Mod 3) + 1)
        Case 1: Call Level1_Initialize2(oLevel)
        Case 2: Call Level2_Initialize2(oLevel)
        Case 3: Call Level3_Initialize2(oLevel)
    End Select
    
    If gbErrorFlag Then Exit Sub
    Call oLevel.InitializeActorBrains
    If gbErrorFlag Then Exit Sub

    oLevel.bIsLevelComplete = False

    'Initialize Play clock...
    Call InitializePlayClock
End Sub
    
Public Sub StartPlay(Optional ByVal vlStartLevel As Long = 1)
    On Error GoTo StartPlay_ErrorHandler
    bQuit = False
    
    'Initialize Game Play
    Call InitializePlay(vlStartLevel)
    
    If Not gbErrorFlag Then
        Do
            Call InitializeLevelPlay
            If gbErrorFlag Then Exit Sub
            
            Call LevelIntro
            If gbErrorFlag Then Exit Sub
        
            'Game Loop
            Call GameLoop
            If gbErrorFlag Then Exit Sub
            
            'call level finished view
            If (Not (bQuit Or oLevel.bIsGameOver)) And oLevel.bIsLevelComplete Then
                Call LevelFinished
                lCurrentLevel = lCurrentLevel + 1
            End If
            
        Loop While Not (bQuit Or oLevel.bIsGameOver)
    End If
    
    If oLevel.bIsGameOver Then Call GameMenu_RegisterLastScore(oLevel.lScore)
    
    Call oLevel.Terminate
    Call TerminatePlay
    Exit Sub
    
StartPlay_ErrorHandler:
    HandleError Err.Number, Err.Description, Err.LastDllError, Err.source, "StartPlay"
    If Not oLevel Is Nothing Then oLevel.Terminate
    Call TerminatePlay
End Sub

Private Sub UpdateBonus()
    With oLevel
        If Not .bPaused Then
            .lBonusTicks = .lBonusTicks + .lTicksPassed
            If .lBonusTicks > 500 Then
                .lBonusTicks = 0
                .lBonus = .lBonus - 10
            End If
        End If
    End With
End Sub

Private Sub LevelFinished()
    Dim llState As Long
    Dim llTickCounter As Long
    Dim llTotalBonus As Long
    Const llCHUNK = 100&
    Dim oSoundEffect_Type As SoundEffect
    
    Set oSoundEffect_Type = oLevel.GetSoundEffect("TYPE")
    
    llTotalBonus = (oLevel.lBonus * oLevel.lBonusMultiplier)
    llTickCounter = 0
    llState = 0
    
    Do
        If gbErrorFlag Then Exit Do
        Call Draw
'        Call oLevel.Draw
        Call DrawLevelFinishedStats(lCurrentLevel, llState, llTotalBonus)
'        Call DirectDraw_Flip
        Call DoFlip
        Call DirectInput_GetKeyboardState
        Call CheckInput
'        Call UpdateBonus
'        If Not oLevel.bPaused Then Call oLevel.Update
        DoEvents
        Call UpdatePlayClock
'        Call CheckLevelLoopStatus
        llTickCounter = llTickCounter + lTicksPassed
        If llState = 6 Then
            oSoundEffect_Type.Play
            If llTotalBonus > llCHUNK Then
                oLevel.lScore = oLevel.lScore + llCHUNK
                llTotalBonus = llTotalBonus - llCHUNK
            ElseIf llTotalBonus > 0 Then
                oLevel.lScore = oLevel.lScore + llTotalBonus
                llTotalBonus = 0
            Else
                llState = llState + 1
            End If
        Else
            If llTickCounter > 500 Then
'    If DirectInput_IsKeyDown(DIK_Z) And (llTickCounter > 500) Then
                llState = llState + 1
                If llState > 9 Then Exit Do
                llTickCounter = 0
            End If
        End If
    Loop While Not bQuit
    
    Set oSoundEffect_Type = Nothing

    DoEvents
End Sub

Private Sub DrawLevelFinishedStats(ByVal viLevel%, ByVal viState%, ByVal vlTotalBonus&)
    Dim llHdc As Long
    Dim lsMsg As String
    
    If viState > 1 Then
        BltNumber oLevel.lBonus, 225, 275, 7, True
    End If
    
    If viState > 3 Then
        BltNumber vlTotalBonus, 225, 360, 7, True
    End If
    
    If viState > 4 Then
        BltNumber oLevel.lScore, 245, 360, 7, False
    End If

    If viState > 2 Then
        'Blit Bonus multiplier
        If oLevel.lBonusMultiplier > 1 Then
            With rLevelFinishedXBonusD
                .Top = 225
                .Left = 332
                .Right = .Left + 12
                .Bottom = .Top + 12
            End With
            rDashXBonusS.Left = 270 + ((oLevel.lBonusMultiplier - 2) * 12)
            rDashXBonusS.Right = rDashXBonusS.Left + 12
            oLevel.ddsBackBufferSurface.Blt rLevelFinishedXBonusD, ddsDash, _
                    rDashXBonusS, DDBLT_KEYSRCOVERRIDE, ddfxNormalBlt
        End If
    End If
    
    If viState > 0 Then
        'Lock a DC for drawing and text operations
        Call oLevel.ddsBackBufferSurface.GetDC(llHdc)
        
        'Paint FPS
        Call SetBkColor(llHdc, RGB(0, 0, 0))
        Call SetTextColor(llHdc, RGB(192, 192, 0))
        lsMsg = "Level " & viLevel & " Complete"
    '    Call GetTextExtentPoint32(llHdc, lsMsg, Len(lsMsg), lMsgSize)
    '    Call TextOut(llHdc, (SCREENWIDTH - lMsgSize.cx) / 2, _
                    128, lsMsg, Len(lsMsg))
        Call TextOut(llHdc, 220, 200, lsMsg, Len(lsMsg))
        
        If viState > 1 Then
            Call SetTextColor(llHdc, RGB(192, 128, 64))
            lsMsg = "Bonus:"
            Call TextOut(llHdc, 220, 220, lsMsg, Len(lsMsg))
            
            If viState > 3 Then
                lsMsg = "="
                Call TextOut(llHdc, 347, 220, lsMsg, Len(lsMsg))
            End If
            
            If viState > 4 Then
                Call SetTextColor(llHdc, RGB(192, 32, 32))
                lsMsg = "Total Score:"
                Call TextOut(llHdc, 220, 240, lsMsg, Len(lsMsg))
            End If
        End If
        
        'Release DC
        Call oLevel.ddsBackBufferSurface.ReleaseDC(llHdc)
    End If
End Sub

Private Sub LevelIntro()
    Dim llState As Long
    Dim llTickCounter As Long
    
    Dim oSoundEffect_Intro As SoundEffect
    Set oSoundEffect_Intro = oLevel.GetSoundEffect("APACHELOOP1")
    
    llTickCounter = 0
    llState = 0
    
    Do
        If gbErrorFlag Then Exit Do
        Call Draw
'        Call oLevel.Draw
        Call DrawLevelIntro(lCurrentLevel, llState)
'        Call DirectDraw_Flip
        Call DoFlip
        Call DirectInput_GetKeyboardState
        Call CheckInput
'        Call UpdateBonus
'        If Not oLevel.bPaused Then Call oLevel.Update
        DoEvents
        Call UpdatePlayClock
'        Call CheckLevelLoopStatus
        llTickCounter = llTickCounter + lTicksPassed
        If llTickCounter > 750 Then
'    If DirectInput_IsKeyDown(DIK_Z) And (llTickCounter > 500) Then
            llState = llState + 1
            If 1 = llState Then
                oSoundEffect_Intro.Play
                Set oSoundEffect_Intro = Nothing
            End If
            If llState > 3 Then Exit Do
            llTickCounter = 0
        End If
    Loop While Not bQuit
    DoEvents
End Sub

Private Sub DrawLevelIntro(ByVal viLevel%, ByVal viState%)
    Dim llHdc As Long
    Dim lsMsg As String
    Dim lMsgSize As Size
    
    If viState > 0 And viState < 3 Then
        'Lock a DC for drawing and text operations
        Call oLevel.ddsBackBufferSurface.GetDC(llHdc)
        
        'Paint FPS
        Call SetBkColor(llHdc, RGB(0, 0, 0))
        Call SetTextColor(llHdc, RGB(192, 192, 0))
        lsMsg = "Prepare for Level " & viLevel
        Call GetTextExtentPoint32(llHdc, lsMsg, Len(lsMsg), lMsgSize)
        Call TextOut(llHdc, (SCREENWIDTH - lMsgSize.cx) / 2, _
                    200, lsMsg, Len(lsMsg))
        
        'Release DC
        Call oLevel.ddsBackBufferSurface.ReleaseDC(llHdc)
    End If
End Sub
