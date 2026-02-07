Attribute VB_Name = "modDirectInput"
Option Explicit

'DirectInput version # (required to create DI object)
Const mlDIRECTINPUT_VERSION& = &H500    '0x0500

'DirectInput Object
Global gDirectInputA As IDirectInputA
Private mdidKeyboard As IDirectInputDeviceA
Private mybufKeyboardState(0 To 255) As Byte

'Host form
Private mFormHost As Form

Public Function DirectInput_Initialize() As Boolean
    On Error GoTo DirectInput_Initialize_ErrorHandler
    
    DirectInputCreateA ByVal App.hInstance&, mlDIRECTINPUT_VERSION&, gDirectInputA, Nothing
    DirectInput_Initialize = True
    Exit Function
        
DirectInput_Initialize_ErrorHandler:
    HandleError Err.Number, Err.Description, Err.LastDllError, Err.source, "DirectInput_Initialize"
    DirectInput_Initialize = False
End Function

Public Sub DirectInput_Terminate()
    On Error Resume Next
    
    If Not (mdidKeyboard Is Nothing) Then
        Call DirectInput_ReleaseKeyboard
    End If
    
    Set gDirectInputA = Nothing
    Set mFormHost = Nothing

    On Error GoTo 0
End Sub

Public Function DirectInput_SetupKeyboard(rForm As Form) As Boolean
    On Error GoTo DirectInput_SetupKeyboard_ErrorHandler
    
    Set mFormHost = rForm
    gDirectInputA.CreateDevice GUID_SysKeyboard, mdidKeyboard, Nothing
    
    'Set data format
    mdidKeyboard.SetDataFormat c_dfDIKeyboard
    'Set cooperative level
'    mdidKeyboard.SetCooperativeLevel mFormHost.hwnd, DISCL_FOREGROUND Or DISCL_NONEXCLUSIVE
    mdidKeyboard.SetCooperativeLevel mFormHost.hwnd, DISCL_BACKGROUND Or DISCL_NONEXCLUSIVE
    'Acquire the device
    mdidKeyboard.Acquire
    
    DirectInput_SetupKeyboard = True
    Exit Function

DirectInput_SetupKeyboard_ErrorHandler:
    HandleError Err.Number, Err.Description, Err.LastDllError, Err.source, "DirectInput_SetupKeyboard"
    DirectInput_SetupKeyboard = False
End Function

Public Sub DirectInput_ReleaseKeyboard()
    On Error Resume Next
    
    'Unacquire the device
    mdidKeyboard.Unacquire
    Set mdidKeyboard = Nothing

    On Error GoTo 0
End Sub

Public Function DirectInput_GetKeyboardState() As Boolean
    Dim llCount As Long
    Dim lbOk As Boolean
    Dim lbRaiseError As Boolean
    
    On Error Resume Next
    
    DirectInput_GetKeyboardState = True
    lbOk = False
    lbRaiseError = False
    
    Do While True
        mdidKeyboard.GetDeviceState 256, mybufKeyboardState(0)
        If Err.Number = 0 Then
            Exit Do
'        ElseIf Err.Number = DIERR_INPUTLOST Then
'            mdidKeyboard.Acquire
'            If (Err.Number <> 0) And (Err.Number <> DIERR_OTHERAPPHASPRIO) Then
'                lbRaiseError = True
'            End If
        Else
            lbRaiseError = True
        End If
        
        If lbRaiseError Then
            HandleError Err.Number, Err.Description, Err.LastDllError, Err.source, "DirectInput_GetKeyboardState"
            DirectInput_GetKeyboardState = False
            Exit Do
        End If
    Loop
    
    Exit Function
    
DirectInput_GetKeyboardState_ErrorHandler:
    HandleError Err.Number, Err.Description, Err.LastDllError, Err.source, "DirectInput_GetKeyboardState"
    DirectInput_GetKeyboardState = False
End Function

Public Function DirectInput_IsKeyDown(ryKey As Byte) As Boolean
    If (mybufKeyboardState(ryKey) And &H80) > 0 Then
        DirectInput_IsKeyDown = True
    Else
        DirectInput_IsKeyDown = False
    End If
End Function
