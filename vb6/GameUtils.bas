Attribute VB_Name = "modGameUtils"
Option Explicit

'For Calculating X,Y from angles
Global Const gdPI = 3.14159265358979
Private mfXInc() As Single
Private mfYInc() As Single
Private mbInitialized As Boolean

'For log file
Private miLogFile As Integer
Private mbLogOpen As Boolean

'used for palette-related stuff
Type LOGPALETTE256
    palVersion As Integer
    palNumEntries As Integer
    palPalEntry(0 To 255) As PALETTEENTRY
End Type
    
Declare Function CreatePalette256 Lib "gdi32" Alias "CreatePalette" (lpLogPalette As LOGPALETTE256) As Long

Public Function GetSystemPaletteCopy(ByVal vlHDc As Long) As LOGPALETTE256
    Dim lpalWPalette As LOGPALETTE256
    lpalWPalette.palNumEntries = 256
    lpalWPalette.palVersion = &H300
    Win32.GetSystemPaletteEntries vlHDc, 0, 256, lpalWPalette.palPalEntry(0)
    GetSystemPaletteCopy = lpalWPalette
End Function

Public Function GetSurfacePaletteCopy(rDDS As IDirectDrawSurface2) As LOGPALETTE256
    Dim lPalette As IDirectDrawPalette
    Dim lpalWPalette As LOGPALETTE256
    lpalWPalette.palNumEntries = 256
    lpalWPalette.palVersion = &H300
    
    rDDS.GetPalette lPalette
    lPalette.GetEntries 0&, 0&, 256&, lpalWPalette.palPalEntry(0)
    
    GetSurfacePaletteCopy = lpalWPalette
End Function

Public Sub GameUtils_Initialize()
    Dim i As Single
    Dim radians As Single
    ReDim mfXInc(0 To 359)
    ReDim mfYInc(0 To 359)
    
    For i = 0# To 359# Step 1#
        radians = i * gdPI / 180#
        mfXInc(i) = Cos(radians)
        mfYInc(i) = Sin(radians)
    Next i
    
    mbInitialized = True
End Sub

Public Sub GameUtils_Terminate()
    Erase mfXInc
    Erase mfYInc
    mbInitialized = False
End Sub

Public Sub GetXYIncFromAngle(rlAngle As Long, rdXInc As Double, rdYInc As Double)
    If Not mbInitialized Then GameUtils_Initialize
    
    Dim llAngle As Integer
    llAngle = rlAngle Mod 360&
    rdXInc = mfXInc(llAngle)
    rdYInc = mfYInc(llAngle)
End Sub

Public Sub GetXYIncFromAngleSng(rlAngle As Long, rdXInc As Single, rdYInc As Single, _
        Optional ByVal vlXFactor As Long = 1, Optional ByVal vlYFactor As Long = 1)
    If Not mbInitialized Then GameUtils_Initialize
    
    rdXInc = mfXInc((rlAngle * vlXFactor) Mod 360&)
    rdYInc = mfYInc((rlAngle * vlYFactor) Mod 360&)
End Sub

Public Sub SetXYFromCircularMotion(ByRef rX!, ByRef rY!, ByVal vlRadiusX&, ByVal vlRadiusY&, _
        ByVal vlAngle&, ByVal vlCenterX&, ByVal vlCenterY&, _
        Optional ByVal vlXFactor As Long = 1, Optional ByVal vlYFactor As Long = 1)
    Dim lfX As Single
    Dim lfY As Single

    Call GetXYIncFromAngleSng(vlAngle, lfX, lfY, vlXFactor, vlYFactor)
    rX = vlCenterX + lfX * vlRadiusX
    rY = vlCenterY + lfY * vlRadiusY
End Sub

Public Function CreateRadialMovementPoints( _
        ByVal vlRadiusX&, ByVal vlRadiusY&, _
        ByVal vlCenterX&, ByVal vlCenterY&, _
        Optional ByVal vlXFactor As Long = 1, Optional ByVal vlYFactor As Long = 1 _
) As RadialMovementPoints
    Dim llCtr As Long
    Dim lfX As Single
    Dim lfY As Single
    Dim loRadialMovementPoints As RadialMovementPoints

    Set loRadialMovementPoints = New RadialMovementPoints

    For llCtr = 0 To 359
        Call SetXYFromCircularMotion(lfX, lfY, _
            vlRadiusX, vlRadiusY, llCtr, vlCenterX, vlCenterY, vlXFactor, vlYFactor _
        )
        loRadialMovementPoints.XPoint(llCtr) = lfX
        loRadialMovementPoints.YPoint(llCtr) = lfY
    Next llCtr
    
    Set CreateRadialMovementPoints = loRadialMovementPoints
End Function

Public Function MinOfLng(rlNum1 As Long, rlNum2 As Long) As Long
    MinOfLng = IIf(rlNum1 < rlNum2, rlNum1, rlNum2)
End Function

Public Function MinOfSng(riNum1 As Single, riNum2 As Single) As Single
    MinOfSng = IIf(riNum1 < riNum2, riNum1, riNum2)
End Function

Public Function MinOfDbl(riNum1 As Double, riNum2 As Double) As Double
    MinOfDbl = IIf(riNum1 < riNum2, riNum1, riNum2)
End Function

Public Sub DebugPrint(msg As String)
    Dim lbOpen As Boolean
    lbOpen = False
    
    On Error GoTo DebugPrint_ErrorHandler
    
    If (Not mbLogOpen) Then
        miLogFile = FreeFile()
        Open App.Path & "\debug.log" For Append As #miLogFile
        lbOpen = True
    End If
    Print #miLogFile, msg
    Close #miLogFile
    lbOpen = False
    Exit Sub

DebugPrint_ErrorHandler:
    Debug.Print "Couldn't log to """ & App.Path & "\debug.log"": " & Err.Number & " - " & Err.Description
    On Error Resume Next
    If lbOpen Then Close #miLogFile
End Sub

Public Function GetAngleFromXY(ByVal vdXFactor As Double, ByVal vdYFactor As Double) As Long
    Dim llDirection As Long
    
    llDirection = CInt(Atn(Abs(vdYFactor / vdXFactor)) * 180# / gdPI)
    
    If vdXFactor < 0 Then
        llDirection = 180 - llDirection
    End If
    
    If vdYFactor < 0 Then
        llDirection = 360 - llDirection
    End If
    
    GetAngleFromXY = llDirection
End Function

Public Function GetAngleFromXYSng(ByVal vdXFactor As Single, ByVal vdYFactor As Single) As Long
    Dim llDirection As Long
    
    llDirection = CInt(Atn(Abs(vdYFactor / vdXFactor)) * 180# / gdPI)
    
    If vdXFactor < 0 Then
        llDirection = 180 - llDirection
    End If
    
    If vdYFactor < 0 Then
        llDirection = 360 - llDirection
    End If
    
    GetAngleFromXYSng = llDirection
End Function

Public Sub CalculateNewVelocity(ByRef rlVelocity As Long, ByRef rlVelDirection As Long, ByVal viAcceleration As Long, ByVal viAccDirection As Long, ByVal vlTicksPassed As Long)
    Dim ldVelX As Double
    Dim ldVelY As Double
    Dim ldAccX As Double
    Dim ldAccY As Double
    Dim ldNewVelX As Double
    Dim ldNewVelY As Double
    
    If viAcceleration = 0 Then Exit Sub
    Call GetXYIncFromAngle(rlVelDirection, ldVelX, ldVelY)
    ldVelX = ldVelX * rlVelocity
    ldVelY = ldVelY * rlVelocity
    
    Call GetXYIncFromAngle(viAccDirection, ldAccX, ldAccY)
    ldAccX = ldAccX * viAcceleration * vlTicksPassed / 1000
    ldAccY = ldAccY * viAcceleration * vlTicksPassed / 1000
    
    ldNewVelX = ldVelX + ldAccX
    ldNewVelY = ldVelY + ldAccY
    
    rlVelocity = CInt(Sqr((ldNewVelX * ldNewVelX) + (ldNewVelY * ldNewVelY)))
    rlVelDirection = GetAngleFromXY(ldNewVelX, ldNewVelY)
End Sub

Public Function DetectIntersection(ByVal vlX1&, ByVal vlY1&, ByVal vlXSize1&, ByVal vlYSize1&, _
        ByVal vlX2&, ByVal vlY2&, ByVal vlXSize2&, ByVal vlYSize2&) As Boolean
'    DetectIntersection = (((vlY1 + vlYSize1) >= vlY2) _
        And (vlY1 < (vlY2 + vlYSize2)) _
        And ((vlX1 + vlXSize1) >= vlX2) _
        And (vlX1 < (vlX2 + vlXSize2)))
    If (vlY1 + vlYSize1) < vlY2 Then Exit Function
    If (vlX1 + vlXSize1) < vlX2 Then Exit Function
    If vlY1 >= (vlY2 + vlYSize2) Then Exit Function
    If vlX1 >= (vlX2 + vlXSize2) Then Exit Function
    DetectIntersection = True
End Function

Public Sub SetCapsLock(Optional ByVal vbOn As Boolean = True)
    Dim Res As Long
    Dim KBState(0 To 255) As Byte
    
    Res = Win32.GetKeyboardState(KBState(0))
    KBState(&H14) = IIf(vbOn, 1, 0)
    Res = Win32.SetKeyboardState(KBState(0))
End Sub

Public Function GetCapsLock() As Boolean
    Dim Res As Long
    Dim KBState(0 To 255) As Byte
    
    Res = Win32.GetKeyboardState(KBState(0))
    GetCapsLock = (1 = KBState(&H14))
End Function
