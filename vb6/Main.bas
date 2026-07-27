Attribute VB_Name = "modMain"
Option Explicit

#Const WINDOWED = True

'if this is set, any loop should exit
Global gbErrorFlag As Boolean
Global gsErrorInfo As String

Global Const SCREENWIDTH% = 640
Global Const SCREENHEIGHT% = 480

Private mGame As Game2

Sub Initialize()
    gbErrorFlag = False
    On Error GoTo Initialize_ErrorHandler
    
    'initialize VB's random number generator
    Randomize
    
    'load the form that we will use for DirectX
    Load frmDDForm
#If WINDOWED Then
    frmDDForm.Top = 0
    frmDDForm.Left = 0
    frmDDForm.Show
    DoEvents
#End If
    
    'Init other modules
    GUID_Initialize
    GameUtils_Initialize
    DirectX_Initialize
    
    Exit Sub

Initialize_ErrorHandler:
    HandleError Err.Number, Err.Description, Err.LastDllError, Err.source, "Initialize"
    Exit Sub
End Sub

Sub Main()
    On Error GoTo Main_ErrorHandler
    
    LogInfo "** STARTING **", "Main", App.EXEName & " v" & App.Major & "." & App.Minor & "." & App.Revision
    
    Initialize
    
    'Hide mouse
    ShowCursor 0
    
    GameMenu_Init
    Do
        If gbErrorFlag Then Exit Do
        GameMenu_Start
        If (isTimeToPlay()) Then
            If mGame Is Nothing Then Set mGame = New Game2
            mGame.StartPlay glStartLevel
        End If
    Loop While Not isTimeToQuit()

    Set mGame = Nothing

    Terminate
    Exit Sub

Main_ErrorHandler:
    HandleError Err.Number, Err.Description, Err.LastDllError, Err.source, "Main"
    Terminate
    Exit Sub
End Sub

Sub Terminate()
    Set mGame = Nothing
    DirectX_Terminate
    GameUtils_Terminate
    
    'Redisplay mouse
    ShowCursor 1
    
    On Error Resume Next
    Unload frmDDForm
    On Error GoTo 0
    
    'End
End Sub

Public Sub XX()
    Terminate
    End
End Sub

Public Sub YY()
    gbErrorFlag = True
End Sub

Sub DirectX_Terminate()
    Call DirectDraw_Terminate
'    Call DirectSound_Terminate
    Call Init_UninitializeDirectSound
    Call DirectInput_Terminate
End Sub

Sub DirectX_Initialize()
    Dim lbOk As Boolean
    
    '====== DIRECT SOUND ======
    'Initialize DirectSound
'    lbOk = DirectSound_Initialize()
'    If Not lbOk Then Exit Sub
    Call Init_InitializeDirectSound(frmDDForm)

    'Set DirectSound Cooperative Level
    'try DSSCL_EXCLUSIVE?
'    lbOk = DirectSound_SetCooperativeLevel(frmDDForm, DSSCL_NORMAL)
'    If Not lbOk Then Exit Sub

    '====== DIRECT DRAW ======
    'Initialize DirectDraw
    lbOk = DirectDraw_Initialize()
    If Not lbOk Then Exit Sub

    'Set DirectDraw Cooperative Level
#If WINDOWED Then
    lbOk = DirectDraw_SetCooperativeLevel(frmDDForm, DDSCL_NORMAL)
#Else
    lbOk = DirectDraw_SetCooperativeLevel(frmDDForm, DDSCL_EXCLUSIVE Or DDSCL_FULLSCREEN)
#End If
    If Not lbOk Then Exit Sub

    'Set DirectDraw Display Mode
#If Not WINDOWED Then
    lbOk = DirectDraw_SetDisplayMode(SCREENWIDTH, SCREENHEIGHT, 8)
#End If
    If Not lbOk Then Exit Sub

    'Create DirectDraw Flipping Buffers
#If WINDOWED Then
    lbOk = DirectDraw_CreateFlippingBuffers_Window(frmDDForm)
#Else
    lbOk = DirectDraw_CreateFlippingBuffers()
#End If
    If Not lbOk Then Exit Sub

    '====== DIRECT INPUT ======
    'Initialize DirectInput
    lbOk = DirectInput_Initialize()
    If Not lbOk Then Exit Sub

    'Init for keyboard input
    lbOk = DirectInput_SetupKeyboard(frmDDForm)
    If Not lbOk Then Exit Sub

#If Not WINDOWED Then
    'load my palette into the primary surface
    Dim lPalette As IDirectDrawPalette
    Set lPalette = LoadPalette8BitPSP(gDirectDraw, App.Path & "\Resource\ai.pal")
    If Not lPalette Is Nothing Then
        gDDSFront.SetPalette lPalette
        gDDSBack.SetPalette lPalette
    End If
    Set lPalette = Nothing
#End If
    
End Sub

Sub HandleError(rvNum, rvDesc, rvDLL, rvSource, rsWhere As String, _
                                Optional rvMoreInfo As Variant)
    
    Dim lsMsg As String
    Dim lsErrInfo As String
    
    On Error Resume Next
    lsErrInfo = GetDirectXError(CLng(rvNum))
    On Error GoTo HandleError_ErrorHandler
    
    lsMsg = Now() & ": *** ERROR *** in " & rsWhere & ": " & vbCrLf & _
        "  Number: " & rvNum & " (" & lsErrInfo & ")" & vbCrLf & _
        "  Description: " & rvDesc & vbCrLf & _
        "  LastDllError: " & rvDLL & vbCrLf & _
        "  Source: " & rvSource & vbCrLf & _
        "  *ErrorInfo: " & gsErrorInfo & vbCrLf
    
    If Not IsMissing(rvMoreInfo) Then
        lsMsg = lsMsg & rvMoreInfo
    End If
    
    On Error Resume Next
    If Not gbErrorFlag Then
        gbErrorFlag = True
        DebugPrint "========== FIRST ERROR ===========" & vbCrLf & lsMsg
    Else
        DebugPrint "========== additional error(s) ===========" & vbCrLf & lsMsg
    End If
    
    On Error GoTo HandleError_ErrorHandler
    Exit Sub

HandleError_ErrorHandler:
    gbErrorFlag = True
    On Error GoTo 0
    Exit Sub
End Sub

Function GetDirectXError(ByVal vlErrNum As Long) As String
    Select Case vlErrNum
        Case -2005532667:   GetDirectXError = "DDERR_ALREADYINITIALIZED"  '88760005
        Case -2005532662:   GetDirectXError = "DDERR_CANNOTATTACHSURFACE" '8876000A
        Case -2005532632:   GetDirectXError = "DDERR_CURRENTLYNOTAVAIL"   '88760028
        Case -2005532617:   GetDirectXError = "DDERR_EXCEPTION"   '88760037
        Case -2005532582:   GetDirectXError = "DDERR_HEIGHTALIGN" '8876005A
        Case -2005532577:   GetDirectXError = "DDERR_INCOMPATIBLEPRIMARY" '8876005F
        Case -2005532572:   GetDirectXError = "DDERR_INVALIDCAPS" '88760064
        Case -2005532562:   GetDirectXError = "DDERR_INVALIDCLIPLIST" '8876006E
        Case -2005532552:   GetDirectXError = "DDERR_INVALIDMODE" '88760078
        Case -2005532542:   GetDirectXError = "DDERR_INVALIDOBJECT"   '88760082
        Case -2005532527:   GetDirectXError = "DDERR_INVALIDPIXELFORMAT"  '88760091
        Case -2005532522:   GetDirectXError = "DDERR_INVALIDRECT" '88760096
        Case -2005532512:   GetDirectXError = "DDERR_LOCKEDSURFACES"  '887600A0
        Case -2005532502:   GetDirectXError = "DDERR_NO3D"    '887600AA
        Case -2005532492:   GetDirectXError = "DDERR_NOALPHAHW"   '887600B4
        Case -2005532467:   GetDirectXError = "DDERR_NOCLIPLIST"  '887600CD
        Case -2005532462:   GetDirectXError = "DDERR_NOCOLORCONVHW"   '887600D2
        Case -2005532460:   GetDirectXError = "DDERR_NOCOOPERATIVELEVELSET"   '887600D4
        Case -2005532457:   GetDirectXError = "DDERR_NOCOLORKEY"  '887600D7
        Case -2005532452:   GetDirectXError = "DDERR_NOCOLORKEYHW"    '887600DC
        Case -2005532450:   GetDirectXError = "DDERR_NODIRECTDRAWSUPPORT" '887600DE
        Case -2005532447:   GetDirectXError = "DDERR_NOEXCLUSIVEMODE" '887600E1
        Case -2005532442:   GetDirectXError = "DDERR_NOFLIPHW"    '887600E6
        Case -2005532422:   GetDirectXError = "DDERR_NOMIRRORHW"  '887600FA
        Case -2005532417:   GetDirectXError = "DDERR_NOTFOUND"    '887600FF
        Case -2005532412:   GetDirectXError = "DDERR_NOOVERLAYHW" '88760104
        Case -2005532392:   GetDirectXError = "DDERR_NORASTEROPHW"    '88760118
        Case -2005532382:   GetDirectXError = "DDERR_NOROTATIONHW"    '88760122
        Case -2005532362:   GetDirectXError = "DDERR_NOSTRETCHHW" '88760136
        Case -2005532356:   GetDirectXError = "DDERR_NOT4BITCOLOR"    '8876013C
        Case -2005532355:   GetDirectXError = "DDERR_NOT4BITCOLORINDEX"   '8876013D
        Case -2005532352:   GetDirectXError = "DDERR_NOT8BITCOLOR"    '88760140
        Case -2005532342:   GetDirectXError = "DDERR_NOTEXTUREHW" '8876014A
        Case -2005532337:   GetDirectXError = "DDERR_NOVSYNCHW"   '8876014F
        Case -2005532332:   GetDirectXError = "DDERR_NOZBUFFERHW" '88760154
        Case -2005532322:   GetDirectXError = "DDERR_NOZOVERLAYHW"    '8876015E
        Case -2005532312:   GetDirectXError = "DDERR_OUTOFCAPS"   '88760168
        Case -2005532292:   GetDirectXError = "DDERR_OUTOFVIDEOMEMORY"    '8876017C
        Case -2005532290:   GetDirectXError = "DDERR_OVERLAYCANTCLIP" '8876017E
        Case -2005532288:   GetDirectXError = "DDERR_OVERLAYCOLORKEYONLYONEACTIVE"    '88760180
        Case -2005532285:   GetDirectXError = "DDERR_PALETTEBUSY" '88760183
        Case -2005532272:   GetDirectXError = "DDERR_COLORKEYNOTSET"  '88760190
        Case -2005532262:   GetDirectXError = "DDERR_SURFACEALREADYATTACHED"  '8876019A
        Case -2005532252:   GetDirectXError = "DDERR_SURFACEALREADYDEPENDENT" '887601A4
        Case -2005532242:   GetDirectXError = "DDERR_SURFACEBUSY" '887601AE
        Case -2005532237:   GetDirectXError = "DDERR_CANTLOCKSURFACE" '887601B3
        Case -2005532232:   GetDirectXError = "DDERR_SURFACEISOBSCURED"   '887601B8
        Case -2005532222:   GetDirectXError = "DDERR_SURFACELOST" '887601C2
        Case -2005532212:   GetDirectXError = "DDERR_SURFACENOTATTACHED"  '887601CC
        Case -2005532202:   GetDirectXError = "DDERR_TOOBIGHEIGHT"    '887601D6
        Case -2005532192:   GetDirectXError = "DDERR_TOOBIGSIZE"  '887601E0
        Case -2005532182:   GetDirectXError = "DDERR_TOOBIGWIDTH" '887601EA
        Case -2005532162:   GetDirectXError = "DDERR_UNSUPPORTEDFORMAT"   '887601FE
        Case -2005532152:   GetDirectXError = "DDERR_UNSUPPORTEDMASK" '88760208
        Case -2005532135:   GetDirectXError = "DDERR_VERTICALBLANKINPROGRESS" '88760219
        Case -2005532132:   GetDirectXError = "DDERR_WASSTILLDRAWING" '8876021C
        Case -2005532112:   GetDirectXError = "DDERR_XALIGN"  '88760230
        Case -2005532111:   GetDirectXError = "DDERR_INVALIDDIRECTDRAWGUID"   '88760231
        Case -2005532110:   GetDirectXError = "DDERR_DIRECTDRAWALREADYCREATED"    '88760232
        Case -2005532109:   GetDirectXError = "DDERR_NODIRECTDRAWHW"  '88760233
        Case -2005532108:   GetDirectXError = "DDERR_PRIMARYSURFACEALREADYEXISTS" '88760234
        Case -2005532107:   GetDirectXError = "DDERR_NOEMULATION" '88760235
        Case -2005532106:   GetDirectXError = "DDERR_REGIONTOOSMALL"  '88760236
        Case -2005532105:   GetDirectXError = "DDERR_CLIPPERISUSINGHWND"  '88760237
        Case -2005532104:   GetDirectXError = "DDERR_NOCLIPPERATTACHED"   '88760238
        Case -2005532103:   GetDirectXError = "DDERR_NOHWND"  '88760239
        Case -2005532102:   GetDirectXError = "DDERR_HWNDSUBCLASSED"  '8876023A
        Case -2005532101:   GetDirectXError = "DDERR_HWNDALREADYSET"  '8876023B
        Case -2005532100:   GetDirectXError = "DDERR_NOPALETTEATTACHED"   '8876023C
        Case -2005532099:   GetDirectXError = "DDERR_NOPALETTEHW" '8876023D
        Case -2005532098:   GetDirectXError = "DDERR_BLTFASTCANTCLIP" '8876023E
        Case -2005532097:   GetDirectXError = "DDERR_NOBLTHW" '8876023F
        Case -2005532096:   GetDirectXError = "DDERR_NODDROPSHW"  '88760240
        Case -2005532095:   GetDirectXError = "DDERR_OVERLAYNOTVISIBLE"   '88760241
        Case -2005532094:   GetDirectXError = "DDERR_NOOVERLAYDEST"   '88760242
        Case -2005532093:   GetDirectXError = "DDERR_INVALIDPOSITION" '88760243
        Case -2005532092:   GetDirectXError = "DDERR_NOTAOVERLAYSURFACE"  '88760244
        Case -2005532091:   GetDirectXError = "DDERR_EXCLUSIVEMODEALREADYSET" '88760245
        Case -2005532090:   GetDirectXError = "DDERR_NOTFLIPPABLE"    '88760246
        Case -2005532089:   GetDirectXError = "DDERR_CANTDUPLICATE"   '88760247
        Case -2005532088:   GetDirectXError = "DDERR_NOTLOCKED"   '88760248
        Case -2005532087:   GetDirectXError = "DDERR_CANTCREATEDC"    '88760249
        Case -2005532086:   GetDirectXError = "DDERR_NODC"    '8876024A
        Case -2005532085:   GetDirectXError = "DDERR_WRONGMODE"   '8876024B
        Case -2005532084:   GetDirectXError = "DDERR_IMPLICITYCREATED "  '8876024C
        Case -2005532083:   GetDirectXError = "DDERR_NOTPALETTIZED"   '8876024D
        Case -2005532082:   GetDirectXError = "DDERR_UNSUPPORTEDMODE" '8876024E
        Case -2005532081:   GetDirectXError = "DDERR_NOMIPMAPHW"  '8876024F
        Case -2005532080:   GetDirectXError = "DDERR_INVALIDSURFACETYPE"  '88760250
        Case -2005532072:   GetDirectXError = "DDERR_NOOPTIMIZEHW"    '88760258
        Case -2005532071:   GetDirectXError = "DDERR_NOTLOADED"   '88760259
        Case -2005532052:   GetDirectXError = "DDERR_DCALREADYCREATED"    '8876026C
        Case -2005532042:   GetDirectXError = "DDERR_NONONLOCALVIDMEM"    '88760276
        Case -2005532032:   GetDirectXError = "DDERR_CANTPAGELOCK"    '88760280
        Case -2005532012:   GetDirectXError = "DDERR_CANTPAGEUNLOCK"  '88760294
        Case -2005531992:   GetDirectXError = "DDERR_NOTPAGELOCKED"   '887602A8
        Case -2005531982:   GetDirectXError = "DDERR_MOREDATA"    '887602B2
        Case -2005531977:   GetDirectXError = "DDERR_VIDEONOTACTIVE"  '887602B7
        Case -2005531973:   GetDirectXError = "DDERR_DEVICEDOESNTOWNSURFACE"  '887602BB
        Case -2005531891:   GetDirectXError = "D3DRMERR_BADOBJECT"    '8876030D
        Case -2005531890:   GetDirectXError = "D3DRMERR_BADTYPE"  '8876030E
        Case -2005531889:   GetDirectXError = "D3DRMERR_BADALLOC" '8876030F
        Case -2005531888:   GetDirectXError = "D3DRMERR_FACEUSED" '88760310
        Case -2005531887:   GetDirectXError = "D3DRMERR_NOTFOUND" '88760311
        Case -2005531886:   GetDirectXError = "D3DRMERR_NOTDONEYET"   '88760312
        Case -2005531885:   GetDirectXError = "D3DRMERR_FILENOTFOUND" '88760313
        Case -2005531884:   GetDirectXError = "D3DRMERR_BADFILE"  '88760314
        Case -2005531883:   GetDirectXError = "D3DRMERR_BADDEVICE"    '88760315
        Case -2005531882:   GetDirectXError = "D3DRMERR_BADVALUE" '88760316
        Case -2005531881:   GetDirectXError = "D3DRMERR_BADMAJORVERSION"  '88760317
        Case -2005531880:   GetDirectXError = "D3DRMERR_BADMINORVERSION"  '88760318
        Case -2005531879:   GetDirectXError = "D3DRMERR_UNABLETOEXECUTE"  '88760319
        Case -2005531876:   GetDirectXError = "D3DRMERR_PENDING"  '8876031C
        Case -2005531875:   GetDirectXError = "D3DRMERR_NOTENOUGHDATA"    '8876031D
        Case -2005531874:   GetDirectXError = "D3DRMERR_REQUESTTOOLARGE"  '8876031E
        Case -2005531873:   GetDirectXError = "D3DRMERR_REQUESTTOOSMALL"  '8876031F
        Case -2005531872:   GetDirectXError = "D3DRMERR_CONNECTIONLOST"   '88760320
        Case -2005531868:   GetDirectXError = "D3DRMERR_BOXNOTSET"    '88760324
        Case -2005531867:   GetDirectXError = "D3DRMERR_BADPMDATA"    '88760325
        Case Else: GetDirectXError = ""
    End Select
End Function

Sub LogInfo(rvDesc, rsWhere As String, _
                                Optional rvMoreInfo As Variant)
    On Error GoTo LogInfo_ErrorHandler
    
    Dim lsMsg As String
    lsMsg = Now() & ": *** INFO *** in " & rsWhere & ": " & vbCrLf & _
        "  Description: " & rvDesc & vbCrLf
    
    If Not IsMissing(rvMoreInfo) Then
        lsMsg = lsMsg & rvMoreInfo
    End If
    
    On Error Resume Next
    DebugPrint lsMsg
    On Error GoTo LogInfo_ErrorHandler
    Exit Sub

LogInfo_ErrorHandler:
    Exit Sub
End Sub

Public Function DoFlip()
#If WINDOWED Then
    DoFlip = DirectDraw_FlipWindow()
#Else
    DoFlip = DirectDraw_FlipX()
#End If
End Function

Public Function GetGamePalette(ByVal vlHDc As Long) As Long
#If WINDOWED Then
    GetGamePalette = CreatePalette256(GetSystemPaletteCopy(vlHDc))
#Else
    GetGamePalette = CreatePalette256(GetSurfacePaletteCopy(gDDSFront))
#End If
End Function
