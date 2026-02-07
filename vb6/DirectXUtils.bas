Attribute VB_Name = "modDirectXUtils"
Option Explicit

Const LR_LOADFROMFILE = &H10
Const LR_CREATEDIBSECTION = &H2000
Private Declare Sub CopyMemoryXXX Lib "kernel32" Alias "RtlMoveMemory" (ByVal Destination As Long, ByVal source As Long, ByVal Length As Long)

'
' DirectX Bitmap Loader
'
Public Function LoadBitmapIntoDXS( _
    DXObject As IDirectDraw2, _
    ByVal BMPFile As String, _
    Optional rPalette As IDirectDrawPalette = Nothing _
) As IDirectDrawSurface2
    
    Dim hBitmap As Long                 ' Handle on bitmap
    Dim dBitmap As BITMAP               ' Handle on bitmap descriptor
    Dim TempDXD As DDSURFACEDESC        ' Surface description
    Dim TempDXS As IDirectDrawSurface2   ' Created surface
    Dim dcBitmap As Long                ' Handle on image
    Dim dcDXS As Long                   ' Handle on surface context
   
    ' Load bitmap
    hBitmap = Win32.LoadImage(ByVal 0&, BMPFile, 0, 0, 0, LR_LOADFROMFILE Or LR_CREATEDIBSECTION)
    ' Get bitmap descriptor
    Win32.GetObject hBitmap, Len(dBitmap), dBitmap
    
    ' Fill DX surface description
    With TempDXD
        .dwSize = Len(TempDXD)
        .dwFlags = DDSD_CAPS Or DDSD_HEIGHT Or DDSD_WIDTH
'        .dwFlags = DDSD_CAPS Or DDSD_HEIGHT Or DDSD_WIDTH Or DDSD_PIXELFORMAT
        .DDSCAPS.dwCaps = DDSCAPS_OFFSCREENPLAIN
        .dwWidth = dBitmap.bmWidth
        .dwHeight = dBitmap.bmHeight
'        .ddpfPixelFormat.dwSize = Len(.ddpfPixelFormat)
'        .ddpfPixelFormat.dwFlags = DDPF_PALETTEINDEXED8
    End With
    ' Create DX surface
    DXObject.CreateSurface TempDXD, TempDXS, Nothing
    
    ' Restore DX surface
    TempDXS.Restore
    
    'maybe I can work with Animate Palette somehow??
    
'    'Set Palette
'    If Not rPalette Is Nothing Then TempDXS.SetPalette rPalette
'    Dim lPalette As IDirectDrawPalette
'    gDDSFront.GetPalette lPalette
'    If Not lPalette Is Nothing Then TempDXS.SetPalette lPalette
'    Set lPalette = Nothing
    
    ' Get DX surface API DC
    TempDXS.GetDC dcDXS
    
    ' Create API memory DC
'    dcBitmap = CreateCompatibleDC(ByVal 0&)
    dcBitmap = CreateCompatibleDC(dcDXS)
    ' Select the bitmap into API memory DC
    SelectObject dcBitmap, hBitmap
    
    ' Blit BMP from API DC into DX DC using standard API BitBlt
'    StretchBlt dcDXS, 0, 0, TempDXD.dwWidth, TempDXD.dwHeight, dcBitmap, 0, 0, dBitmap.bmWidth, dBitmap.bmHeight, SRCCOPY
    BitBlt dcDXS, 0, 0, TempDXD.dwWidth, TempDXD.dwHeight, dcBitmap, 0, 0, SRCCOPY
    
    ' Cleanup
    TempDXS.ReleaseDC dcDXS
    DeleteDC dcBitmap
    DeleteObject hBitmap
    
    ' Return created DX surface
    Set LoadBitmapIntoDXS = TempDXS
End Function


'
' Loads a Wave file into a direct sound buffer
'
Public Sub LoadWAVIntoDSB(Lds As IDirectSound, ByVal fName As String, Ldsb As IDirectSoundBuffer)
    
    Dim hWave As Long
    Dim pcmwave As WAVEFORMATEX
    Dim lngSize As Long
    Dim lngPosition As Long
    Dim Ptr1 As Long, Ptr2 As Long, Lng1 As Long, Lng2 As Long
    Dim aByte() As Byte
    
    ReDim aByte(1 To FileLen(fName))
    hWave = FreeFile
    Open fName For Binary As hWave
    Get hWave, , aByte
    Close hWave
    lngPosition = 1
    While Chr$(aByte(lngPosition)) + Chr$(aByte(lngPosition + 1)) + Chr$(aByte(lngPosition + 2)) <> "fmt"
        lngPosition = lngPosition + 1
    Wend
    CopyMemoryXXX VarPtr(pcmwave), VarPtr(aByte(lngPosition + 8)), Len(pcmwave)
    While Chr$(aByte(lngPosition)) + Chr$(aByte(lngPosition + 1)) + Chr$(aByte(lngPosition + 2)) + Chr$(aByte(lngPosition + 3)) <> "data"
        lngPosition = lngPosition + 1
    Wend
    CopyMemoryXXX VarPtr(lngSize), VarPtr(aByte(lngPosition + 4)), Len(lngSize)
    Dim dsbd As DSBUFFERDESC
    With dsbd
        .dwSize = Len(dsbd)
        .dwFlags = DSBCAPS_CTRLDEFAULT
        .dwBufferBytes = lngSize
        .lpwfxFormat = VarPtr(pcmwave)
    End With
    Lds.CreateSoundBuffer dsbd, Ldsb, Nothing
    Ldsb.Lock 0&, lngSize, Ptr1, Lng1, Ptr2, Lng2, 0&
    CopyMemoryXXX Ptr1, VarPtr(aByte(lngPosition + 4 + 4)), Lng1
    If Lng2 <> 0 Then
        CopyMemoryXXX Ptr2, VarPtr(aByte(lngPosition + 4 + 4 + Lng1)), Lng2
    End If
    Ldsb.Unlock Ptr1, Lng1, Ptr2, Lng2
End Sub

Public Function LoadPalette8BitPSP(rIDirectDraw As IDirectDraw2, rsFileName As String) As IDirectDrawPalette
    Dim liFileNo As Integer
    Dim llCtr As Long
    Dim lbOpen As Boolean
    Dim lPalette As IDirectDrawPalette
    Dim lPaletteEntries(1 To 256) As PALETTEENTRY
    Dim lsTemp As String
    Dim llNumEntries As Long
    
    'open the file
    lbOpen = False
    On Error GoTo LoadPalette_ErrorHandler
    
    liFileNo = FreeFile()

    Open rsFileName For Input As #liFileNo
    lbOpen = True
    
    'read header
    Input #liFileNo, lsTemp
    Input #liFileNo, lsTemp
    Input #liFileNo, llNumEntries
    
    'read the entries
    For llCtr = 1 To llNumEntries
        With lPaletteEntries(llCtr)
            Input #liFileNo, .peRed, .peGreen, .peBlue
            .peFlags = 0
        End With
    Next llCtr
    
    'close the file
    Close #liFileNo
    lbOpen = False
    
    'create the palette in DirextX
    gDirectDraw.CreatePalette _
        DirectX.DDPCAPS_8BIT Or DirectX.DDPCAPS_ALLOW256, _
        lPaletteEntries(1), lPalette, Nothing
    
    Set LoadPalette8BitPSP = lPalette
    Exit Function
    
LoadPalette_ErrorHandler:
    Call HandleError(Err.Number, Err.Description, Err.LastDllError, Err.source, "LoadPalette", rsFileName)
    On Error Resume Next
    If lbOpen Then Close #liFileNo
    Set LoadPalette8BitPSP = Nothing
End Function
