VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
  Persistable = 0  'NotPersistable
  DataBindingBehavior = 0  'vbNone
  DataSourceBehavior  = 0  'vbNone
  MTSTransactionMode  = 0  'NotAnMTSObject
END
Attribute VB_Name = "Actor2"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = True
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = False
Option Explicit

Private bTerminated As Boolean
Public oBitMapDefinition As BitMapDefinition
Public oSequencePlayer As SequencePlayer
Public oBrains As Brains
Public fX As Single
Public fY As Single

'INFO
Public lCanBeHitByMissiles As Long
Public bCanHitPlayer As Boolean
Public bMustBeDestroyed As Boolean

'STATE INDICATORS
Public bDelete As Boolean
Public lWasHitByMissiles
Public bHitShields As Boolean
Public bHitPlayer As Boolean

'MOVEMENT
Public eMovementType As MovementTypes_Enum
'normal/marching
Public lVelocityDirection As Long
Public lVelocity As Long
Public lAccelerationDirection As Long
Public lAcceleration As Long
'follow the leader only
Private oLeader As Actor2
Private fXRelPos As Single
Private fYRelPos As Single
'marching only
Private lMarchingDistance As Long
Private fDistanceMarched As Single
'attack
'Private oTargetSprite As Actor2
'circle
Public bAlwaysUpdateRadialPosition As Boolean
Private lCircleRadiusX As Long
Private lCircleRadiusY As Long
Private lCirlceTicksPerRotation As Long
Private fCirclePosition As Single
Private lCircleCenterX As Long
Private lCircleCenterY As Long
Private lCircleXFactor As Long
Private lCircleYFactor As Long
Private oRadialMovementPoints As RadialMovementPoints

'MOVEMENT RESTRICTIONS
Public bStopAtBorderTop As Boolean
Public bStopAtBorderBottom As Boolean
Public bStopAtBorderLeft As Boolean
Public bStopAtBorderRight As Boolean
Public bReverseAtBorderTop As Boolean
Public bReverseAtBorderBottom As Boolean
Public bReverseAtBorderLeft As Boolean
Public bReverseAtBorderRight As Boolean

'POSITION INDICATORS
Public bIsOffScreen As Boolean
Public bIsOffScreenTop As Boolean
Public bIsOffScreenBottom As Boolean
Public bIsOffScreenLeft As Boolean
Public bIsOffScreenRight As Boolean
Public bIsAtBorder As Boolean
Public bIsAtBorderTop As Boolean
Public bIsAtBorderBottom As Boolean
Public bIsAtBorderLeft As Boolean
Public bIsAtBorderRight As Boolean

Public Sub Initialize(roBitMapDefinition As BitMapDefinition, roBrains As Brains)
    Set oBitMapDefinition = roBitMapDefinition
    Set oBrains = roBrains
End Sub

Public Sub SetMovementRelativePosition(roLeader As Actor2, ByVal vfRelX!, ByVal vfRelY!)
    eMovementType = movementFollowTheLeader
    Set oLeader = roLeader
    fXRelPos = vfRelX
    fYRelPos = vfRelY
    fX = oLeader.fX + vfRelX
    fY = oLeader.fY + vfRelY
End Sub

Public Sub SetMovementMarching(ByVal vfX!, ByVal vfY!, ByVal vlVelocity&, ByVal vlVelocityDirection&, _
        ByVal vlMarchingDistance&, Optional ByVal vfDistanceMarched As Single = 0)
    eMovementType = movementMarch
    fDistanceMarched = 0!
    fX = vfX
    fY = vfY
    lVelocity = vlVelocity
    lVelocityDirection = vlVelocityDirection
    lMarchingDistance = vlMarchingDistance
    fDistanceMarched = vfDistanceMarched
End Sub

Public Sub SetMovementNormal(ByVal vfX!, ByVal vfY!, ByVal vlVelocity&, ByVal vlVelocityDirection&)
    eMovementType = movementNormal
    fX = vfX
    fY = vfY
    lVelocity = vlVelocity
    lVelocityDirection = vlVelocityDirection
End Sub

'Call loActor.SetMovementCircle(160, 144, 25, 4000, 0)
Public Sub SetMovementCircle(ByVal vfX!, ByVal vfY!, ByVal vlRadiusX&, ByVal vlRadiusY&, _
        ByVal vlTicksPerRotation&, ByVal vlInitialDegrees&, _
        Optional ByVal vlXFactor As Long = 1, Optional ByVal vlYFactor As Long = 1)
    eMovementType = movementCircle
    lCircleRadiusX = vlRadiusX
    lCircleRadiusY = vlRadiusY
    lCirlceTicksPerRotation = vlTicksPerRotation
    fCirclePosition = vlInitialDegrees
    lCircleCenterX = vfX
    lCircleCenterY = vfY
    lCircleXFactor = vlXFactor
    lCircleYFactor = vlYFactor
    Call SetXYFromCircularMotion(fX, fY, lCircleRadiusX, lCircleRadiusY, CLng(fCirclePosition), _
        lCircleCenterX, lCircleCenterY, lCircleXFactor, lCircleYFactor)
        
'    If (Not oBitMapDefinition Is Nothing) Then
'        With oBitMapDefinition
'            fX = fX - (.lXFrameSize / 2)
'            fY = fY - (.lYFrameSize / 2)
'        End With
'    End If
End Sub

'Call loActor.SetMovementCircle(loRadialMovementPoints)
Public Sub SetMovementRadialPoints(roRadialMovementPoints As RadialMovementPoints, _
        ByVal vlTicksPerRotation&, ByVal vlInitialDegrees&)
    eMovementType = movementRadialMovementPoints
    Set oRadialMovementPoints = roRadialMovementPoints
    lCirlceTicksPerRotation = vlTicksPerRotation
    fCirclePosition = vlInitialDegrees

    fX = oRadialMovementPoints.XPoint(vlInitialDegrees)
    fY = oRadialMovementPoints.YPoint(vlInitialDegrees)

'    If (Not oBitMapDefinition Is Nothing) Then
'        With oBitMapDefinition
'            fX = oRadialMovementPoints.XPoint(lCirclePosition) - (.lXFrameSize / 2)
'            fY = oRadialMovementPoints.YPoint(lCirclePosition) - (.lYFrameSize / 2)
'        End With
'    End If
End Sub

Public Sub SetMovementAcceleration(ByVal vlAcceleration&, ByVal vlAccelerationDirection&)
    lAcceleration = vlAcceleration
    lAccelerationDirection = vlAccelerationDirection
End Sub

Public Sub Draw(roLevel As Level)
    On Error GoTo Draw_ErrorHandler
    
    If oBitMapDefinition Is Nothing Then Exit Sub
    If oSequencePlayer Is Nothing Then Exit Sub
    If Not oSequencePlayer.IsValid Then Exit Sub
    
    Dim RS As RECT
    Dim RD As RECT
    Dim DXFX As DDBLTFX
    
    Dim llFrameOffsetX As Long
    Dim llFrameOffsetY As Long
    Dim llClippedWidth As Long
    Dim llClippedHeight As Long
    Dim llFrameNumber As Long
    Dim llBitMapOffsetX As Long
    Dim llBitMapOffsetY As Long
    Dim llDestX As Long
    Dim llDestY As Long
    
    llFrameNumber = oSequencePlayer.CurrentBitMapFrame
gsErrorInfo = "frame: " & oSequencePlayer.CurrentBitMapFrame
    With oBitMapDefinition.GetFrameDefinition(llFrameNumber)
        llDestX = CLng(fX) - .lXSizeOver2
        llDestY = CLng(fY) - .lYSizeOver2
        'Clip the frame
        'first part handles off the screen to the left, second normal, third off the screen to the right
gsErrorInfo = "WX1"
        llClippedWidth = MinOfLng(MinOfLng(roLevel.lPlayWidth - llDestX, .lXSize), llDestX + .lXSize)
gsErrorInfo = "WX2"
        llClippedHeight = MinOfLng(MinOfLng(roLevel.lPlayHeight - llDestY, .lYSize), llDestY + .lYSize)
gsErrorInfo = "WX3"
        If (llClippedWidth <= 0&) Or (llClippedHeight <= 0&) Then Exit Sub
        llFrameOffsetX = .lXOffset
        llFrameOffsetY = .lYOffset
    End With
        
    With oBitMapDefinition
        llFrameOffsetX = llFrameOffsetX + ((llFrameNumber Mod .lWidthInFrames) * .lXFrameSize)
        llFrameOffsetY = llFrameOffsetY + (Int(llFrameNumber / .lWidthInFrames) * .lYFrameSize)
    End With
        
gsErrorInfo = "WX4"
    llBitMapOffsetX = Abs(MinOfLng(llDestX, 0&))
    RS.Left = llBitMapOffsetX + llFrameOffsetX
    RS.Right = llClippedWidth + RS.Left
    llBitMapOffsetY = Abs(MinOfLng(llDestY, 0&))
    RS.Top = llBitMapOffsetY + llFrameOffsetY
    RS.Bottom = llClippedHeight + RS.Top
        
    RD.Left = roLevel.lPlayXOffset + llDestX + llBitMapOffsetX
    RD.Right = RD.Left + llClippedWidth
    RD.Top = roLevel.lPlayYOffset + llDestY + llBitMapOffsetY
    RD.Bottom = RD.Top + llClippedHeight
        
    DXFX.dwSize = Len(DXFX)
    DXFX.ddckSrcColorkey.dwColorSpaceHighValue = 0
    DXFX.ddckSrcColorkey.dwColorSpaceLowValue = 0
        
gsErrorInfo = "WX5"
    On Error Resume Next
    Do
        roLevel.ddsBackBufferSurface.Blt RD, oBitMapDefinition.ddsDirectDrawSurface, _
            RS, DDBLT_KEYSRCOVERRIDE, DXFX
        Select Case Err.Number
            Case DD_OK:
                Exit Do
            Case DDERR_WASSTILLDRAWING:
            Case DDERR_SURFACEBUSY:
            Case DDERR_SURFACELOST:
                gsErrorInfo = "Attempting to restore lost surface."
                gDDSFront.Restore
                If DD_OK <> Err.Number Then GoTo Draw_ErrorHandler
            Case Else:
                GoTo Draw_ErrorHandler
        End Select
    Loop While True

'    roLevel.ddsBackBufferSurface.BltFast RD.Left, RD.Top, oBitMapDefinition.ddsDirectDrawSurface, RS, DDBLTFAST_SRCCOLORKEY
gsErrorInfo = "WX6"
    
    'Allow actor to change frames
    If (Not oSequencePlayer Is Nothing) Then
        With oSequencePlayer
            If .IsValid Then Call .Update(roLevel.lTicksPassed)
        End With
    End If
    
    Exit Sub

Draw_ErrorHandler:
    HandleError Err.Number, Err.Description, Err.LastDllError, Err.source, "Actor2.Draw", _
        "  X,Y = " & fX & "," & fY & vbCrLf & _
        "  RS.Left = " & RS.Left & vbCrLf & _
        "  RS.Right = " & RS.Right & vbCrLf & _
        "  RS.Top = " & RS.Top & vbCrLf & _
        "  RS.Bottom = " & RS.Bottom & vbCrLf & _
        "  RD.Left = " & RD.Left & vbCrLf & _
        "  RD.Right = " & RD.Right & vbCrLf & _
        "  RD.Top = " & RD.Top & vbCrLf & _
        "  RD.Bottom = " & RD.Bottom & vbCrLf & _
        "  llFrameNumber = " & llFrameNumber & vbCrLf
    Exit Sub
End Sub

Public Sub Update(roLevel As Level, Optional ByVal vbAnimate = True, _
        Optional ByVal vbMove = False, Optional ByVal vbState = True)
'    'Allow actor to change frames
'    If vbAnimate And (Not oSequencePlayer Is Nothing) Then
'        If oSequencePlayer.IsValid Then Call oSequencePlayer.Update(roLevel.lTicksPassed)
'    End If
    
    'Update player position
    If vbMove Then Call Move(roLevel)

    'Update STATE!
    If vbState Then Call oBrains.UpdateState
End Sub

Function DetectCollision(roWithActor As Actor2) As Boolean
    Dim llActorX1 As Long
    Dim llActorY1 As Long
    Dim llActorX2 As Long
    Dim llActorY2 As Long
    Dim llBoxX1 As Long
    Dim llBoxXSize1 As Long
    Dim llBoxY1 As Long
    Dim llBoxYSize1 As Long
    Dim llBoxX2 As Long
    Dim llBoxXSize2 As Long
    Dim llBoxY2 As Long
    Dim llBoxYSize2 As Long
    Dim loFrameDefinition1 As FrameDefinition
    Dim loFrameDefinition2 As FrameDefinition
    Dim lbCollision As Boolean
    Dim lbCheckCollisionBoxes  As Boolean
    Dim llCollisionBoxCtr1 As Long
    Dim llCollisionBoxCtr2 As Long
    
    llActorX1 = GetLeft()
    llActorY1 = GetTop()
    
'    If oSequencePlayer Is Nothing Then Exit Function
    If Not oSequencePlayer.IsValid Then Exit Function
    Set loFrameDefinition1 = oBitMapDefinition.GetFrameDefinition(oSequencePlayer.CurrentBitMapFrame)
    
    With roWithActor
        llActorX2 = .GetLeft()
        llActorY2 = .GetTop()
        Set loFrameDefinition2 = .oBitMapDefinition.GetFrameDefinition(.oSequencePlayer.CurrentBitMapFrame)
    End With
    
    lbCollision = False
    lbCheckCollisionBoxes = False
    
    'determine if we should go into more detail --
    'if the collision boxes are completely in the frames we can check the frames first
    If loFrameDefinition1.bCollisionBoxesInsideFrame _
            And loFrameDefinition2.bCollisionBoxesInsideFrame Then
        If (1 = loFrameDefinition1.lNumCollisionBoxes) _
                And (1 = loFrameDefinition2.lNumCollisionBoxes) Then
            'only one collision box per actor, so going into detail
            'doesn't take any longer than checking the outer rectangles.
            lbCheckCollisionBoxes = True
        Else
            'go into detail only if the outer ones intersect
            With loFrameDefinition1
                llBoxX1 = llActorX1 + .lXOffset
                llBoxXSize1 = .lXSize
                llBoxY1 = llActorY1 + .lYOffset
                llBoxYSize1 = .lYSize
            End With
            With loFrameDefinition2
                llBoxX2 = llActorX2 + .lXOffset
                llBoxXSize2 = .lXSize
                llBoxY2 = llActorY2 + .lYOffset
                llBoxYSize2 = .lYSize
            End With
            lbCheckCollisionBoxes = DetectIntersection(llBoxX1, llBoxY1, llBoxXSize1, llBoxYSize1, _
                llBoxX2, llBoxY2, llBoxXSize2, llBoxYSize2)
        End If
    Else
        lbCheckCollisionBoxes = True
    End If
    
    'go into detail?
    If lbCheckCollisionBoxes Then
        'loop through all combinations of boxes
        For llCollisionBoxCtr1 = 1 To loFrameDefinition1.lNumCollisionBoxes
            For llCollisionBoxCtr2 = 1 To loFrameDefinition2.lNumCollisionBoxes
                With loFrameDefinition1
                    llBoxX1 = llActorX1 + .lXOffset
                    llBoxXSize1 = .lXSize
                    llBoxY1 = llActorY1 + .lYOffset
                    llBoxYSize1 = .lYSize
                End With
                With loFrameDefinition2
                    llBoxX2 = llActorX2 + .lXOffset
                    llBoxXSize2 = .lXSize
                    llBoxY2 = llActorY2 + .lYOffset
                    llBoxYSize2 = .lYSize
                End With
                If DetectIntersection(llBoxX1, llBoxY1, llBoxXSize1, llBoxYSize1, _
                        llBoxX2, llBoxY2, llBoxXSize2, llBoxYSize2) Then
                    lbCollision = True
                    Exit For
                End If
            Next llCollisionBoxCtr2
            If lbCollision Then Exit For
        Next llCollisionBoxCtr1
    End If
    
    DetectCollision = lbCollision
End Function

'Direction is in degrees
'Velocity is in pixels/second
'roLevel.TicksPassed is milliseconds
'Marching means going back and forth in a line over a specified distance
Public Sub Move(roLevel As Level)
    'Pixels to move
    Dim lfPixels As Single
    'X,Y factor (-1.0 to 1.0) in movement
    Dim lfXInc As Single
    Dim lfYInc As Single
    'If direction should reverse
    Dim lbReverse As Boolean
    'Used for bounds checking
    Dim llXPos As Long
    Dim llYPos As Long
    Dim llXSize As Long
    Dim llYSize As Long
    
    If bAlwaysUpdateRadialPosition Or (eMovementType = movementCircle) Or (eMovementType = movementRadialMovementPoints) Then
        fCirclePosition = fCirclePosition + (360! * roLevel.lTicksPassed / lCirlceTicksPerRotation)
        If (fCirclePosition < 0!) Or (fCirclePosition >= 360!) Then
            fCirclePosition = fCirclePosition - (Int(fCirclePosition / 360) * 360!)
        End If
    End If
    
    If (eMovementType = movementCircle) Then
        Call SetXYFromCircularMotion(fX, fY, lCircleRadiusX, lCircleRadiusY, Int(fCirclePosition), _
            lCircleCenterX, lCircleCenterY, lCircleXFactor, lCircleYFactor)
'        'correction from Upper Left to Center ...
'        If (Not oBitMapDefinition Is Nothing) And (Not oSequencePlayer Is Nothing) Then
'            If oSequencePlayer.IsValid Then
'                With oBitMapDefinition.GetFrameDefinition(oSequencePlayer.CurrentBitMapFrame)
'                    fX = fX - .lXOffset - (.lXSize / 2)
'                    fY = fY - .lYOffset - (.lYSize / 2)
'                End With
'            End If
'        End If
        Exit Sub
    ElseIf (eMovementType = movementRadialMovementPoints) Then
        fX = oRadialMovementPoints.XPoint(Int(fCirclePosition))
        fY = oRadialMovementPoints.YPoint(Int(fCirclePosition))
'        'correction from Upper Left to Center ...
'        If (Not oBitMapDefinition Is Nothing) And (Not oSequencePlayer Is Nothing) Then
'            If oSequencePlayer.IsValid Then
'                With oBitMapDefinition.GetFrameDefinition(oSequencePlayer.CurrentBitMapFrame)
'                    fX = oRadialMovementPoints.XPoint(lCirclePosition) - .lXOffset - (.lXSize / 2)
'                    fY = oRadialMovementPoints.YPoint(lCirclePosition) - .lYOffset - (.lYSize / 2)
'                End With
'            End If
'        End If
        Exit Sub
    End If
        
    'Store last position
'    .iLastX = fX
'    .iLastY = fY
        
    'Clear reverse flag
    lbReverse = False
            
    If (eMovementType = movementNormal) Or (eMovementType = movementMarch) Then
        'Accelerate
        If Not 0 = lAcceleration Then
            Call CalculateNewVelocity(lVelocity, lVelocityDirection, _
                lAcceleration, lAccelerationDirection, roLevel.lTicksPassed)
        End If
        
        'Determine X,Y factor from direction angle (degrees)
        Call GetXYIncFromAngleSng(lVelocityDirection, lfXInc, lfYInc)
        'Determine distance to move in pixels
        lfPixels = (lVelocity * roLevel.lTicksPassed) / 1000!
        
        If eMovementType = movementMarch Then
            'See if we are marching
            If lMarchingDistance > 0 Then
                'If we are marching, are we go to march to far?
                If ((fDistanceMarched + lfPixels) > lMarchingDistance) Then
                    'Adjust distance so we do not march to far, and reverse (later)
                    lfPixels = lMarchingDistance - fDistanceMarched
                    lbReverse = True
                    fDistanceMarched = 0
                Else
                    'add distance to distance marched so far
                    fDistanceMarched = fDistanceMarched + lfPixels
                End If
            End If
        End If
        
        'Calculate new X and Y positions
        fX = fX + (lfPixels * lfXInc)
        fY = fY + (lfPixels * lfYInc)
        
    ElseIf eMovementType = movementFollowTheLeader Then
        fX = oLeader.fX + fXRelPos
        fY = oLeader.fY + fYRelPos
    End If
    
    'clear border flags
    bIsOffScreenTop = False
    bIsOffScreenBottom = False
    bIsOffScreenLeft = False
    bIsOffScreenRight = False
    bIsAtBorderTop = False
    bIsAtBorderBottom = False
    bIsAtBorderLeft = False
    bIsAtBorderRight = False
    
    If oBitMapDefinition Is Nothing Then
        llXPos = fX
        llYPos = fY
        llXSize = 0
        llYSize = 0
    ElseIf oSequencePlayer.IsValid Then
        With oBitMapDefinition.GetFrameDefinition(oSequencePlayer.CurrentBitMapFrame)
            llXSize = .lXSize
            llXPos = CLng(fX) + .lXOffset - .lXSizeOver2
            llYSize = .lYSize
            llYPos = CLng(fY) + .lYOffset - .lYSizeOver2
        End With
    Else
        With oBitMapDefinition
            llXSize = .lXFrameSize
            llXPos = fX - (llXSize / 2)
            llYSize = .lYFrameSize
            llYPos = fY + -(llYSize / 2)
        End With
    End If
    
    'see if we are going to go off the playfield to the right
    If ((llXPos + llXSize) > roLevel.lPlayWidth) Then
        'We are partially or fully off the playfield - so we stop or reverse?
        If bReverseAtBorderRight Or bStopAtBorderRight Then
            'don't go off- go to the edge
            fX = roLevel.lPlayWidth - llXSize + (llXSize / 2)
            llXPos = fX
            bIsAtBorderRight = True
            If bReverseAtBorderRight Then lbReverse = True
        Else
            If (llXPos > roLevel.lPlayWidth) Then bIsOffScreenRight = True
        End If
    'see if we are going to go off the playfield to the left
    ElseIf (llXPos < 0) Then
        If bReverseAtBorderLeft Or bStopAtBorderLeft Then
            'don't go off- go to the edge
            fX = (llXSize / 2)
            llXPos = fX
            bIsAtBorderLeft = True
            If bReverseAtBorderLeft Then lbReverse = True
        Else
            If (llXPos + llXSize < 0) Then bIsOffScreenLeft = True
        End If
    End If
    
    'see if we are going to go off the playfield to the bottom
    If ((llYPos + llYSize) > roLevel.lPlayHeight) Then
        If bReverseAtBorderBottom Or bStopAtBorderBottom Then
            fY = roLevel.lPlayHeight - llYSize + (llYSize / 2)
            llYPos = fY
            bIsAtBorderBottom = True
            If bReverseAtBorderBottom Then lbReverse = True
        Else
            If (llYPos > roLevel.lPlayHeight) Then bIsOffScreenBottom = True
        End If
    'see if we are going to go off the playfield to the top
    ElseIf (llYPos < 0) Then
        If bReverseAtBorderTop Or bStopAtBorderTop Then
            fY = llYSize / 2
            llYPos = fY
            bIsAtBorderTop = True
            If bReverseAtBorderTop Then lbReverse = True
        Else
            If (llYPos + llYSize < 0) Then bIsOffScreenTop = True
        End If
    End If

    'set general border flags from specific values
    bIsOffScreen = bIsOffScreenTop Or bIsOffScreenBottom Or bIsOffScreenLeft Or bIsOffScreenRight
    bIsAtBorder = bIsAtBorderTop Or bIsAtBorderBottom Or bIsAtBorderLeft Or bIsAtBorderRight
    
    'reverse direction?
    If lbReverse Then
        If bIsAtBorderRight Then lVelocityDirection = (180& - lVelocityDirection + 360&) Mod 360&
        If bIsAtBorderLeft Then lVelocityDirection = (180& - lVelocityDirection + 360&) Mod 360&
        If bIsAtBorderTop Then lVelocityDirection = (360& - lVelocityDirection) Mod 360&
        If bIsAtBorderBottom Then lVelocityDirection = (360& - lVelocityDirection) Mod 360&
        If Not bIsAtBorder Then lVelocityDirection = (lVelocityDirection + 180&) Mod 360&
    End If
End Sub

Public Property Get CenterX() As Long
'    With oBitMapDefinition.GetFrameDefinition(oSequencePlayer.CurrentBitMapFrame)
'        CenterX = fX + (.lXSize / 2!)
'    End With
    CenterX = fX
End Property

Public Property Get CenterY() As Long
'    With oBitMapDefinition.GetFrameDefinition(oSequencePlayer.CurrentBitMapFrame)
'        CenterY = fY + (.lYSize / 2!)
'    End With
    CenterY = fY
End Property

Public Sub GetCenter(ByRef rfX As Single, ByRef rfY As Single)
'    With oBitMapDefinition.GetFrameDefinition(oSequencePlayer.CurrentBitMapFrame)
'        rfX = fX + (.lXSize / 2!)
'        rfY = fY + (.lYSize / 2!)
'    End With
    rfX = fX
    rfY = fY
End Sub

Public Property Get GetLeft() As Single
    If oSequencePlayer.IsValid Then
        With oBitMapDefinition.GetFrameDefinition(oSequencePlayer.CurrentBitMapFrame)
            GetLeft = fX - .lXSizeOver2
        End With
    ElseIf Not oBitMapDefinition Is Nothing Then
        With oBitMapDefinition
            GetLeft = fX - (.lXFrameSize / 2!)
        End With
    Else
        GetLeft = fX
    End If
End Property

Public Property Get GetRight() As Single
    If oSequencePlayer.IsValid Then
        With oBitMapDefinition.GetFrameDefinition(oSequencePlayer.CurrentBitMapFrame)
            GetRight = fX + .lXSizeOver2
        End With
    ElseIf Not oBitMapDefinition Is Nothing Then
        With oBitMapDefinition
            GetRight = fX + (.lXFrameSize / 2!)
        End With
    Else
        GetRight = fX
    End If
End Property

Public Property Get GetTop() As Single
    If oSequencePlayer.IsValid Then
        With oBitMapDefinition.GetFrameDefinition(oSequencePlayer.CurrentBitMapFrame)
            GetTop = fY - .lYSizeOver2
        End With
    ElseIf Not oBitMapDefinition Is Nothing Then
        With oBitMapDefinition
            GetTop = fY - (.lYFrameSize / 2!)
        End With
    Else
        GetTop = fY
    End If
End Property

Public Property Get GetBottom() As Single
    If oSequencePlayer.IsValid Then
        With oBitMapDefinition.GetFrameDefinition(oSequencePlayer.CurrentBitMapFrame)
            GetBottom = fY + .lYSizeOver2
        End With
    ElseIf Not oBitMapDefinition Is Nothing Then
        With oBitMapDefinition
            GetBottom = fY + (.lYFrameSize / 2!)
        End With
    Else
        GetBottom = fY
    End If
End Property

Public Sub ResetState()
'STATE INDICATORS
    bDelete = False
    lWasHitByMissiles = 0
    bHitShields = False
    bHitPlayer = False
'position indicators
    bIsOffScreen = False
    bIsOffScreenTop = False
    bIsOffScreenBottom = False
    bIsOffScreenLeft = False
    bIsOffScreenRight = False
    bIsAtBorder = False
    bIsAtBorderTop = False
    bIsAtBorderBottom = False
    bIsAtBorderLeft = False
    bIsAtBorderRight = False
    
    Call oBrains.ResetState
End Sub

Private Sub Class_Initialize()
    Set oSequencePlayer = New SequencePlayer
    Set oBitMapDefinition = Nothing
    Set oBrains = Nothing
    fX = 0!
    fY = 0!

'INFO
    lCanBeHitByMissiles = 0
    bCanHitPlayer = False
    bMustBeDestroyed = False

'STATE INDICATORS
    bDelete = False
    lWasHitByMissiles = 0
    bHitShields = False
    bHitPlayer = False

'MOVEMENT
    eMovementType = movementNormal
'normal
    lVelocityDirection = 0
    lVelocity = 0
    lAccelerationDirection = 0
    lAcceleration = 0
'follow the leader
    Set oLeader = Nothing
    fXRelPos = 0
    fYRelPos = 0
'march
    lMarchingDistance = 0
    fDistanceMarched = 0
'radial
    Set oRadialMovementPoints = Nothing
'attack
    'Set oTargetActor = Nothing
'bounds
    bStopAtBorderTop = False
    bStopAtBorderBottom = False
    bStopAtBorderLeft = False
    bStopAtBorderRight = False
    bReverseAtBorderTop = False
    bReverseAtBorderBottom = False
    bReverseAtBorderLeft = False
    bReverseAtBorderRight = False

'position indicators
    bIsOffScreen = False
    bIsOffScreenTop = False
    bIsOffScreenBottom = False
    bIsOffScreenLeft = False
    bIsOffScreenRight = False
    bIsAtBorder = False
    bIsAtBorderTop = False
    bIsAtBorderBottom = False
    bIsAtBorderLeft = False
    bIsAtBorderRight = False
End Sub

Public Sub Terminate()
    If bTerminated Then Exit Sub
    bTerminated = True
'    If Not oBitMapDefinition Is Nothing Then Call oBitMapDefinition.Terminate
    Set oBitMapDefinition = Nothing
'    If Not oSequencePlayer Is Nothing Then Call oSequencePlayer.Terminate
    Set oSequencePlayer = Nothing
'    If Not oBrains Is Nothing Then
'        Call oBrains.Terminate
'    End If
    Set oBrains = Nothing
'radial
    Set oRadialMovementPoints = Nothing
End Sub

Public Sub Class_Terminate()
    Call Terminate
End Sub
