Attribute VB_Name = "modDirectX"
Option Explicit

'DirectDraw Object
Private mDirectDraw As IDirectDraw2
'Front and Back Surface, for double Buffering
Private mDDSFront As IDirectDrawSurface2
Private mDDSBack As IDirectDrawSurface2
'Host form
Private mFormHost As Form

Private Function DirectDraw_Initialize() As Boolean
    On Error GoTo DirectDraw_Initialize_ErrorHandler
        
    DirectDrawCreate ByVal 0&, mDirectDraw, Nothing
    DirectDraw_Initialize = True
    Exit Function
        
DirectDraw_Initialize_ErrorHandler:
    HandleError "DirectDraw_Initialize"
    DirectDraw_Initialize = False
End Function

Private Sub DirectDraw_Terminate()
    On Error Resume Next
    
    'Flip from mDirectDraw-Surface to standard GDI
    mDirectDraw.FlipToGDISurface
    'Restore old resolution and depth
    mDirectDraw.RestoreDisplayMode
    'Return control to windows
    mDirectDraw.SetCooperativeLevel mFormHost.hWnd, DDSCL_NORMAL
    
    Set mDDSBack = Nothing
    Set mDDSFront = Nothing
    Set mDirectDraw = Nothing

    On Error GoTo 0
End Sub

Public Function DirectDraw_SetCooperativeLevel(rForm As Form, riLevel) As Boolean
    On Error GoTo DirectDraw_SetCooperativeLevel_ErrorHandler
    Set mFormHost = rForm
    mDirectDraw.SetCooperativeLevel mFormHost.hWnd, riLevel
    mDirectDraw.SetCooperativeLevel mFormHost.hWnd, DDSCL_EXCLUSIVE Or DDSCL_FULLSCREEN
    DirectDraw_SetCooperativeLevel = True
    Exit Function
    
DirectDraw_SetCooperativeLevel_ErrorHandler:
    HandleError "DirectDraw_SetCooperativeLevel"
    DirectDraw_SetCooperativeLevel = False
End Function

Public Function DirectDraw_SetDisplayMode(riWidth As Integer, riHeight As Integer, riDepth As Integer) As Boolean
    On Error GoTo DirectDraw_SetDisplayMode_ErrorHandler
     mDirectDraw.SetDisplayMode riWidth, riHeight, riDepth, 0, 0
    DirectDraw_SetDisplayMode = True
    Exit Function

DirectDraw_SetDisplayMode_ErrorHandler:
    HandleError "DirectDraw_SetDisplayMode"
    DirectDraw_SetDisplayMode = False
End Function

Public Function DirectDraw_CreateFlippingBuffers() As Boolean
    On Error GoTo DirectDraw_CreateFlippingBuffers_ErrorHandler
    
    'Description of DirectDraw Surface
    Dim lDDSurfaceDescFront As DDSURFACEDESC
    'Display capabilities
    Dim lDDSCapsBack As DDSCAPS
    
    ' Initialize front buffer description
    With lDDSurfaceDescFront
        ' Get Structure size
        .dwSize = Len(lDDSurfaceDescFront)
        ' Structure uses Surface Caps and count of BackBuffers
        .dwFlags = DDSD_CAPS Or DDSD_BACKBUFFERCOUNT
        ' Structure describes a flippable (buffered) surface
        .DDSCAPS.dwCaps = DDSCAPS_PRIMARYSURFACE Or DDSCAPS_FLIP Or DDSCAPS_COMPLEX Or DDSCAPS_SYSTEMMEMORY
        '         ' Structure uses one BackBuffer
        '         .dwBackBufferCount = 1
        ' Structure uses two BackBuffers
        .dwBackBufferCount = 2
    End With
    
    ' Create front buffer from structure
    mDirectDraw.CreateSurface lDDSurfaceDescFront, mDDSFront, Nothing
    
    ' Create back buffer from front buffer
    lDDSCapsBack.dwCaps = DDSCAPS_BACKBUFFER
    mDDSFront.GetAttachedSurface lDDSCapsBack, mDDSBack

    DirectDraw_CreateFlippingBuffers = True
    Exit Function

DirectDraw_CreateFlippingBuffers_ErrorHandler:
    HandleError "DirectDraw_CreateFlippingBuffers"
    DirectDraw_CreateFlippingBuffers = False
End Function

Public Function DirectDraw_Get() As IDirectDraw2
    Set DirectDraw_Get = mDirectDraw
End Function

Public Function DirectDraw_GetBackBufferSurface() As IDirectDrawSurface2
    Set DirectDraw_GetBackBufferSurface = mDDSBack
End Function

Public Function DirectDraw_CreateSurfaceFromBitmapFile(rsFile) As IDirectDrawSurface2
    Set DirectDraw_CreateSurfaceFromBitmapFile = LoadBitmapIntoDXS(mDirectDraw, rsFile)
End Function

Public Function DirectDraw_Flip() As Boolean
    DirectDraw_Flip = True
    Dim llCount As Long
    llCount = 0
    On Error Resume Next
    Do
        mDDSFront.Flip Nothing, 0
        If Err.Number = DDERR_SURFACELOST Then
            llCount = llCount + 1
            If (llCount > 1000) Then
                HandleError "DirectDraw_Flip"
                DirectDraw_Flip = False
                Exit Do
            End If
            mDDSFront.Restore
        End If
    Loop Until Err.Number = 0
    On Error GoTo 0
End Function
