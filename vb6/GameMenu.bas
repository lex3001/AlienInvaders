Attribute VB_Name = "modGameMenu"
Option Explicit

Global glStartLevel As Long

Private msMsg As String
Private msMsg2 As String

'Loop control / Game control
Private mbQuit As Boolean
Private mbPlay As Boolean

'Descriptor for DirectDraw special blitting abilitiy
Private mDDBLTFX As DDBLTFX

Private moHighScores As New HighScores
Private mbInputHighScoreName As Boolean
Private msPlayerName As String
Private mlNameEntryTickCounter As Long
Private mlHighScoreIndex As Long
Private mlLastScore As Long
Private mlCursorPos As Long
Private mlKeyDelayTicksLeft As Long
Private mlClearScoresKeyCount As Long

Public Sub GameMenu_RegisterLastScore(ByVal vlScore&)
    Dim llCtr As Long
    Dim llCtr2 As Long
    
    mlLastScore = vlScore
    mlHighScoreIndex = moHighScores.AddScore("", vlScore)
    msPlayerName = ""
    mlCursorPos = 0
    If mlHighScoreIndex > 0 Then
        mbInputHighScoreName = True
    Else
        mlHighScoreIndex = 0
        mbInputHighScoreName = False
    End If

    moHighScores.WriteScores App.Path & "\AI.HS"
End Sub

Public Sub GameMenu_Init()
    mlLastScore = -1
    moHighScores.ReadScores App.Path & "\AI.HS"
    mlKeyDelayTicksLeft = 0
End Sub

Public Sub GameMenu_Start()
    On Error GoTo GameMenu_Start_ErrorHandler
    Dim llTicks As Long
    Dim llTicksPassed As Long
    
'    msMsg = "ALIEN INVADERS (" & App.Major & "." & App.Minor & " build " & App.Revision & ")"
'    msMsg2 = "<esc>=quit, <enter>=play"
    msMsg = "Alien Invaders --- <ENTER> zu starten"
    msMsg2 = "<linke/rechte Pfeile> links/rechts, <SHIFT> schieﬂen, <ALT> shutzen, <Leertaste> stoppen"
    
    
    'set up so that we can paint back surface black
    With mDDBLTFX
        .dwSize = Len(mDDBLTFX)
        .dwFillColor = RGB(0, 0, 0)
    End With
    
    mbQuit = False
    mbPlay = False
    mlClearScoresKeyCount = 0
    
    'Menu Loop
    Do
        llTicks = Win32.timeGetTime()
        If gbErrorFlag Then Exit Do
        GameMenu_Draw
'        DirectDraw_Flip
        DoFlip
        DirectInput_GetKeyboardState
        GameMenu_CheckInput
        DoEvents
        llTicksPassed = Win32.timeGetTime() - llTicks
        mlNameEntryTickCounter = mlNameEntryTickCounter + llTicksPassed
        If mlNameEntryTickCounter > 1000 Then mlNameEntryTickCounter = 0
        If mlKeyDelayTicksLeft > 0 Then mlKeyDelayTicksLeft = mlKeyDelayTicksLeft - llTicksPassed
    Loop While Not (mbQuit Or mbPlay)
    
    Exit Sub
    
GameMenu_Start_ErrorHandler:
    HandleError Err.Number, Err.Description, Err.LastDllError, Err.source, "GameMenu_Start"
End Sub

Public Function isTimeToQuit() As Boolean
    isTimeToQuit = mbQuit
End Function

Public Function isTimeToPlay() As Boolean
    isTimeToPlay = mbPlay
End Function

Public Function GetDIKSpecial(ByRef rsChar, ByRef rlDIK As Long)
    Dim lsChar As String
    Dim llDIK As Long
    llDIK = -1
    lsChar = ""
    
    Select Case True
        Case DirectInput_IsKeyDown(DirectX.DIK_1): lsChar = "1"
        Case DirectInput_IsKeyDown(DirectX.DIK_2): lsChar = "2"
        Case DirectInput_IsKeyDown(DirectX.DIK_3): lsChar = "3"
        Case DirectInput_IsKeyDown(DirectX.DIK_4): lsChar = "4"
        Case DirectInput_IsKeyDown(DirectX.DIK_5): lsChar = "5"
        Case DirectInput_IsKeyDown(DirectX.DIK_6): lsChar = "6"
        Case DirectInput_IsKeyDown(DirectX.DIK_7): lsChar = "7"
        Case DirectInput_IsKeyDown(DirectX.DIK_8): lsChar = "8"
        Case DirectInput_IsKeyDown(DirectX.DIK_9): lsChar = "9"
        Case DirectInput_IsKeyDown(DirectX.DIK_0): lsChar = "0"
        Case DirectInput_IsKeyDown(DirectX.DIK_A): lsChar = "A"
        Case DirectInput_IsKeyDown(DirectX.DIK_B): lsChar = "B"
        Case DirectInput_IsKeyDown(DirectX.DIK_C): lsChar = "C"
        Case DirectInput_IsKeyDown(DirectX.DIK_D): lsChar = "D"
        Case DirectInput_IsKeyDown(DirectX.DIK_E): lsChar = "E"
        Case DirectInput_IsKeyDown(DirectX.DIK_F): lsChar = "F"
        Case DirectInput_IsKeyDown(DirectX.DIK_G): lsChar = "G"
        Case DirectInput_IsKeyDown(DirectX.DIK_H): lsChar = "H"
        Case DirectInput_IsKeyDown(DirectX.DIK_I): lsChar = "I"
        Case DirectInput_IsKeyDown(DirectX.DIK_J): lsChar = "J"
        Case DirectInput_IsKeyDown(DirectX.DIK_K): lsChar = "K"
        Case DirectInput_IsKeyDown(DirectX.DIK_L): lsChar = "L"
        Case DirectInput_IsKeyDown(DirectX.DIK_M): lsChar = "M"
        Case DirectInput_IsKeyDown(DirectX.DIK_N): lsChar = "N"
        Case DirectInput_IsKeyDown(DirectX.DIK_O): lsChar = "O"
        Case DirectInput_IsKeyDown(DirectX.DIK_P): lsChar = "P"
        Case DirectInput_IsKeyDown(DirectX.DIK_Q): lsChar = "Q"
        Case DirectInput_IsKeyDown(DirectX.DIK_R): lsChar = "R"
        Case DirectInput_IsKeyDown(DirectX.DIK_S): lsChar = "S"
        Case DirectInput_IsKeyDown(DirectX.DIK_T): lsChar = "T"
        Case DirectInput_IsKeyDown(DirectX.DIK_U): lsChar = "U"
        Case DirectInput_IsKeyDown(DirectX.DIK_V): lsChar = "V"
        Case DirectInput_IsKeyDown(DirectX.DIK_W): lsChar = "W"
        Case DirectInput_IsKeyDown(DirectX.DIK_X): lsChar = "X"
        Case DirectInput_IsKeyDown(DirectX.DIK_Y): lsChar = "Y"
        Case DirectInput_IsKeyDown(DirectX.DIK_Z): lsChar = "Z"
        Case DirectInput_IsKeyDown(DirectX.DIK_SPACE): lsChar = " "
        Case DirectInput_IsKeyDown(DirectX.DIK_LEFT): llDIK = DirectX.DIK_LEFT
        Case DirectInput_IsKeyDown(DirectX.DIK_RIGHT): llDIK = DirectX.DIK_RIGHT
        Case DirectInput_IsKeyDown(DirectX.DIK_BACK): llDIK = DirectX.DIK_BACK
        Case DirectInput_IsKeyDown(DirectX.DIK_DELETE): llDIK = DirectX.DIK_DELETE
        Case DirectInput_IsKeyDown(DirectX.DIK_ESCAPE): llDIK = DirectX.DIK_ESCAPE
        Case DirectInput_IsKeyDown(DirectX.DIK_RETURN): llDIK = DirectX.DIK_RETURN
    End Select

    If Len(lsChar) > 0 Then
        If DirectInput_IsKeyDown(DirectX.DIK_LSHIFT) Or DirectInput_IsKeyDown(DirectX.DIK_RSHIFT) Then
            If 0 = InStr(1, "ABCDEFGHIJKLMNOPQRSTUVWXYZ", lsChar) Then
                lsChar = ""
            ElseIf GetCapsLock() Then
                lsChar = LCase$(lsChar)
            End If
        ElseIf Not GetCapsLock() Then
            lsChar = LCase$(lsChar)
        End If
    End If

    rsChar = lsChar
    rlDIK = llDIK

    GetDIKSpecial = (Len(lsChar) > 0) Or (llDIK >= 0)
End Function

Public Sub GameMenu_CheckInput()
    Dim lsPlayerName As String
    Dim lsChar As String
    Dim llDIK As Long
    Static lsLastChar As String
    Static llLastDIK As Long
    Static lbFirstOfRepeating As Boolean
    
    If Not GetDIKSpecial(lsChar, llDIK) Then
        mlKeyDelayTicksLeft = 0
        lbFirstOfRepeating = True
    ElseIf (UCase$(lsChar) <> UCase$(lsLastChar)) Or (llDIK <> llLastDIK) Then
        mlKeyDelayTicksLeft = 0
        lbFirstOfRepeating = True
    End If
    
    lsLastChar = lsChar
    llLastDIK = llDIK
    If mlKeyDelayTicksLeft > 0 Then Exit Sub
    
    mlKeyDelayTicksLeft = IIf(lbFirstOfRepeating, 200, 50)
    lbFirstOfRepeating = False
    
    If mbInputHighScoreName Then
        lsPlayerName = msPlayerName
        
        If Len(lsChar) > 0 Then
            msPlayerName = Mid$(msPlayerName, 1, mlCursorPos) & lsChar & Mid$(msPlayerName, mlCursorPos + 1)
            mlCursorPos = mlCursorPos + 1
        End If
        
        If (mlCursorPos > 0) Then
            If DirectX.DIK_LEFT = llDIK Then
                mlCursorPos = mlCursorPos - 1
            ElseIf DirectX.DIK_BACK = llDIK Then
                msPlayerName = Mid$(msPlayerName, 1, Len(msPlayerName) - 1)
                mlCursorPos = mlCursorPos - 1
            End If
        End If
        
        If mlCursorPos < Len(msPlayerName) Then
            If DirectX.DIK_RIGHT = llDIK Then
                mlCursorPos = mlCursorPos + 1
            ElseIf DirectX.DIK_DELETE = llDIK Then
                msPlayerName = Mid$(msPlayerName, 1, mlCursorPos) & Mid$(msPlayerName, mlCursorPos + 2)
            End If
        End If
        
        If lsPlayerName <> msPlayerName Then
            moHighScores.SetPlayer mlHighScoreIndex, msPlayerName
            moHighScores.WriteScores App.Path & "\AI.HS"
        End If
    ElseIf lsChar = "c" Then
        mlClearScoresKeyCount = mlClearScoresKeyCount + 1
        If mlClearScoresKeyCount > 3 Then
            mlClearScoresKeyCount = 0
            moHighScores.ClearScores
        End If
    End If
    
    If DirectInput_IsKeyDown(DirectX.DIK_ESCAPE) Then
        mbQuit = True
    ElseIf DirectInput_IsKeyDown(DirectX.DIK_RETURN) Then
        If mbInputHighScoreName Then
            mbInputHighScoreName = False
        Else
            mbPlay = True
            glStartLevel = 1
        End If
    ElseIf Not mbInputHighScoreName Then
        If DirectInput_IsKeyDown(DirectX.DIK_1) Then
            mbPlay = True
            glStartLevel = 1
        ElseIf DirectInput_IsKeyDown(DirectX.DIK_2) Then
            mbPlay = True
            glStartLevel = 2
        ElseIf DirectInput_IsKeyDown(DirectX.DIK_3) Then
            mbPlay = True
            glStartLevel = 3
        End If
    End If
End Sub

Private Sub GameMenu_Draw()
    On Error GoTo GameMenu_Draw_ErrorHandler
    Dim llHdc As Long
    Dim llCtr As Long
    Dim lsMsg As String
    Dim lsPlayer As String
    Dim llScore As Long
    
    'Clear back buffer (fill with black)
    gDDSBack.Blt ByVal 0&, Nothing, ByVal 0&, DDBLT_COLORFILL Or DDBLT_WAIT, mDDBLTFX

    Call gDDSBack.GetDC(llHdc)
    
    Dim lMsgSize As Size
    Call SetBkColor(llHdc, RGB(0, 0, 0))
    Call SetTextColor(llHdc, RGB(196, 196, 64))

    Call GetTextExtentPoint32(llHdc, msMsg, Len(msMsg), lMsgSize)
    Call TextOut(llHdc, (SCREENWIDTH - lMsgSize.cx) / 2, (SCREENHEIGHT / 2) - lMsgSize.cy - 9, msMsg, Len(msMsg))

    Call SetTextColor(llHdc, RGB(0, 96, 192))
    Call GetTextExtentPoint32(llHdc, msMsg2, Len(msMsg2), lMsgSize)
    Call TextOut(llHdc, (SCREENWIDTH - lMsgSize.cx) / 2, (SCREENHEIGHT / 2) - lMsgSize.cy + 7, msMsg2, Len(msMsg2))

    For llCtr = 1 To 10
        Call moHighScores.GetScore(llCtr, lsPlayer, llScore)
        If mlHighScoreIndex = llCtr Then
            Call SetTextColor(llHdc, RGB(192, 96, 96))
            If mbInputHighScoreName And (mlNameEntryTickCounter < 500) Then
                lsPlayer = Mid$(lsPlayer, 1, mlCursorPos) & "|" & Mid$(lsPlayer, mlCursorPos + 1)
            Else
                lsPlayer = Mid$(lsPlayer, 1, mlCursorPos) & " " & Mid$(lsPlayer, mlCursorPos + 1)
            End If
        Else
            Call SetTextColor(llHdc, RGB(96, 192, 96))
        End If
        lsMsg = llCtr & "."
        Call GetTextExtentPoint32(llHdc, lsMsg, Len(lsMsg), lMsgSize)
        Call TextOut(llHdc, 318 - lMsgSize.cx, 250 + llCtr * 18, lsMsg, Len(lsMsg))
        lsMsg = Format(llScore, "00000000")
        Call TextOut(llHdc, 320, 250 + llCtr * 18, lsMsg, Len(lsMsg))
        If Not mbInputHighScoreName Then Call SetTextColor(llHdc, RGB(96, 192, 96))
        Call TextOut(llHdc, 400, 250 + llCtr * 18, lsPlayer, Len(lsPlayer))
    Next llCtr

    If mlLastScore > 0 Then
        lsMsg = "Last Score "
        Call SetTextColor(llHdc, RGB(192, 96, 96))
        Call GetTextExtentPoint32(llHdc, lsMsg, Len(lsMsg), lMsgSize)
        Call TextOut(llHdc, 318 - lMsgSize.cx, 250 + 200, lsMsg, Len(lsMsg))
        lsMsg = Format(mlLastScore, "00000000")
        Call TextOut(llHdc, 320, 250 + 200, lsMsg, Len(lsMsg))
    End If

    Call gDDSBack.ReleaseDC(llHdc)
    
    Exit Sub
    
GameMenu_Draw_ErrorHandler:
    HandleError Err.Number, Err.Description, Err.LastDllError, Err.source, "GameMenu_Draw"
End Sub
