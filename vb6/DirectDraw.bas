Attribute VB_Name = "modDirectDraw"
Option Explicit

'DirectDraw Object
Global gDirectDraw As IDirectDraw2
'Front and Back Surface, for double Buffering
Global gDDSFront As IDirectDrawSurface2
Global gDDSBack As IDirectDrawSurface2
'Host form
Private mFormHost As Form
'Clipper for windowed mode
Private mDDCWindow As IDirectDrawClipper

Private bWindowedMode As Boolean

Public Function DirectDraw_Initialize() As Boolean
    On Error GoTo DirectDraw_Initialize_ErrorHandler
        
    DirectDrawCreate ByVal 0&, gDirectDraw, Nothing
    DirectDraw_Initialize = True
    Exit Function
        
DirectDraw_Initialize_ErrorHandler:
    HandleError Err.Number, Err.Description, Err.LastDllError, Err.source, "DirectDraw_Initialize"
    DirectDraw_Initialize = False
End Function

Public Sub DirectDraw_Terminate()
    On Error Resume Next
    
    If Not (gDirectDraw Is Nothing) Then
        'Flip from gDirectDraw-Surface to standard GDI
        If Not bWindowedMode Then gDirectDraw.FlipToGDISurface
        'Restore old resolution and depth
        gDirectDraw.RestoreDisplayMode
        'Return control to windows
        gDirectDraw.SetCooperativeLevel mFormHost.hwnd, DDSCL_NORMAL
    End If
    
    If bWindowedMode Then gDDSFront.SetClipper Nothing
    Set mDDCWindow = Nothing
    
    Set gDDSBack = Nothing
    Set gDDSFront = Nothing
    Set gDirectDraw = Nothing
    Set mFormHost = Nothing

    On Error GoTo 0
End Sub

Public Function DirectDraw_SetCooperativeLevel(rForm As Form, rlLevel As Long) As Boolean
    On Error GoTo DirectDraw_SetCooperativeLevel_ErrorHandler
    Set mFormHost = rForm
    gDirectDraw.SetCooperativeLevel mFormHost.hwnd, rlLevel
    DirectDraw_SetCooperativeLevel = True
    Exit Function
    
DirectDraw_SetCooperativeLevel_ErrorHandler:
    HandleError Err.Number, Err.Description, Err.LastDllError, Err.source, "DirectDraw_SetCooperativeLevel"
    DirectDraw_SetCooperativeLevel = False
End Function

Public Function DirectDraw_SetDisplayMode(riWidth As Integer, riHeight As Integer, riDepth As Integer) As Boolean
    On Error GoTo DirectDraw_SetDisplayMode_ErrorHandler
     gDirectDraw.SetDisplayMode riWidth, riHeight, riDepth, 0, 0
    DirectDraw_SetDisplayMode = True
    Exit Function

DirectDraw_SetDisplayMode_ErrorHandler:
    HandleError Err.Number, Err.Description, Err.LastDllError, Err.source, "DirectDraw_SetDisplayMode"
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
        .DDSCAPS.dwCaps = DDSCAPS_PRIMARYSURFACE Or DDSCAPS_FLIP Or DDSCAPS_COMPLEX 'Or DDSCAPS_SYSTEMMEMORY
        '         ' Structure uses one BackBuffer
        '         .dwBackBufferCount = 1
        ' Structure uses two BackBuffers
        .dwBackBufferCount = 2
    End With
    
    ' Create front buffer from structure
    gDirectDraw.CreateSurface lDDSurfaceDescFront, gDDSFront, Nothing
    
    ' Create back buffer from front buffer
    lDDSCapsBack.dwCaps = DDSCAPS_BACKBUFFER
    gDDSFront.GetAttachedSurface lDDSCapsBack, gDDSBack

    DirectDraw_CreateFlippingBuffers = True
    Exit Function

DirectDraw_CreateFlippingBuffers_ErrorHandler:
    HandleError Err.Number, Err.Description, Err.LastDllError, Err.source, "DirectDraw_CreateFlippingBuffers"
    DirectDraw_CreateFlippingBuffers = False
End Function

Public Function DirectDraw_CreateFlippingBuffers_Window(rForm As Form) As Boolean
    On Error GoTo DirectDraw_CreateFlippingBuffers_ErrorHandler
    
    'Description of DirectDraw Surface
    Dim lDDSurfaceDescFront As DDSURFACEDESC
    'Display capabilities
    Dim lDDSCapsBack As DDSCAPS
    
    ' Initialize front buffer description
    With lDDSurfaceDescFront
        ' Get Structure size
        .dwSize = Len(lDDSurfaceDescFront)
        ' Structure uses Surface Caps
        .dwFlags = DDSD_CAPS
        ' Structure describes a flippable (buffered) surface
        .DDSCAPS.dwCaps = DDSCAPS_PRIMARYSURFACE
    End With
    
    ' Create front buffer from structure
    gDirectDraw.CreateSurface lDDSurfaceDescFront, gDDSFront, Nothing
    
    'CLIPPER FOR WINDOWED MODE!
    ' Create clipper from front buffer
    gDirectDraw.CreateClipper 0&, mDDCWindow, Nothing
    ' Set clipper to the window we are using
    mDDCWindow.SetHWnd 0, rForm.hwnd
    'Set the clipper on the primary surface for our windowed mode..
    gDDSFront.SetClipper mDDCWindow
    
    ' Create back buffer
    ' Fill DX surface description
    With lDDSurfaceDescFront
        .dwSize = Len(lDDSurfaceDescFront)
        .dwFlags = DDSD_CAPS Or DDSD_HEIGHT Or DDSD_WIDTH
        .DDSCAPS.dwCaps = DDSCAPS_OFFSCREENPLAIN
        .dwWidth = 640
        .dwHeight = 480
    End With
    ' Create DX surface
    gDirectDraw.CreateSurface lDDSurfaceDescFront, gDDSBack, Nothing

    bWindowedMode = True
    DirectDraw_CreateFlippingBuffers_Window = True
    Exit Function

DirectDraw_CreateFlippingBuffers_ErrorHandler:
    HandleError Err.Number, Err.Description, Err.LastDllError, Err.source, "DirectDraw_CreateFlippingBuffers_Window"
    DirectDraw_CreateFlippingBuffers_Window = False
End Function

Public Function DirectDraw_Get() As IDirectDraw2
    Set DirectDraw_Get = gDirectDraw
End Function

Public Function DirectDraw_GetBackBufferSurface() As IDirectDrawSurface2
    Set DirectDraw_GetBackBufferSurface = gDDSBack
End Function

Public Function DirectDraw_CreateSurfaceFromBitmapFile(rsFile) As IDirectDrawSurface2
    Set DirectDraw_CreateSurfaceFromBitmapFile = LoadBitmapIntoDXS(gDirectDraw, rsFile)
End Function

Public Function DirectDraw_FlipX() As Boolean
    DirectDraw_FlipX = True
    Dim llCount As Long
    llCount = 0
    On Error Resume Next
    Do
        gDDSFront.Flip Nothing, DDFLIP_WAIT
        If Err.Number = DDERR_SURFACELOST Then
            llCount = llCount + 1
            If (llCount > 1000) Then
                HandleError Err.Number, Err.Description, Err.LastDllError, Err.source, "DirectDraw_Flip"
                DirectDraw_FlipX = False
                Exit Do
            End If
            gDDSFront.Restore
        End If
    Loop Until Err.Number = 0
    On Error GoTo 0
End Function

Public Function DirectDraw_FlipWindow() As Boolean
    DirectDraw_FlipWindow = True
    On Error Resume Next
    
    Dim rectS As RECT
    Dim rectD As RECT
    
    Dim rectClient As RECT

    Dim ddfxNormalBlt As DDBLTFX
    
    With ddfxNormalBlt
        .dwSize = Len(ddfxNormalBlt)
        .ddckSrcColorkey.dwColorSpaceHighValue = 0
        .ddckSrcColorkey.dwColorSpaceLowValue = 0
    End With

    Win32.GetClientRect frmDDForm.hwnd, rectClient
    Win32.ClientToScreen frmDDForm.hwnd, rectClient.Left
    Win32.ClientToScreen frmDDForm.hwnd, rectClient.Right
    
    With rectD
        .Top = rectClient.Top
        .Left = rectClient.Left
'        .Bottom = rectClient.Bottom - rectClient.Top + .Top
'        .Right = rectClient.Right - rectClient.Right + .Right
        .Bottom = .Top + 480
        .Right = .Left + 640
    End With
    
    With rectS
        .Top = 0
        .Left = 0
        .Bottom = 480
        .Right = 640
    End With
    
    gDDSFront.Blt rectD, gDDSBack, _
            rectS, 0, ddfxNormalBlt
    
    If Err.Number <> 0 Then
        HandleError Err.Number, Err.Description, Err.LastDllError, Err.source, "DirectDraw_Flip"
        DirectDraw_FlipWindow = False
    End If
    On Error GoTo 0
End Function

