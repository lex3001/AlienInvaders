VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
END
Attribute VB_Name = "Level"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = True
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = False
Option Explicit

Private iNumBitMapDefinitions As Integer
Private oBitMapDefinitions() As BitMapDefinition

Private iNumMovementDefinitions As Integer
Private oMovementDefinitions() As MovementDefinition

Private iNumActorBehaviors As Integer
Private oActorBehaviors() As ActorBehavior

Public Function AddNewBitMapDefinition(rsID$, rddsDirectDrawSurface As IDirectDrawSurface2, _
        ByVal viXFrameSize%, ByVal viYFrameSize%, viWidthInFrame%, ByVal viNumFrames)
    
    Dim loNewBitMapDefinition As New BitMapDefinition
    Call loNewBitMapDefinition.Initialize(rsID, rddsDirectDrawSurface, _
        viXFrameSize, viYFrameSize, viWidthInFrame, viNumFrames)
    
    iNumBitMapDefinitions = iNumBitMapDefinitions + 1
    ReDim Preserve oBitMapDefinitions(1 To iNumBitMapDefinitions)
    Set oBitMapDefinitions(iNumBitMapDefinitions) = loNewBitMapDefinition
    
    Set AddNewBitMapDefinition = loNewBitMapDefinition
End Function

Public Function AddNewMovementDefinition1(rsID$, ByVal viVelocityDirection%, ByVal viVelocity%, _
        ByVal viAccelerationDirection%, ByVal viAcceleration%, ByVal viMarchingDistance%)
        
    Dim loNewMovementDefinition As New MovementDefinition
    Call loNewMovementDefinition.Initialize1(rsID, viVelocityDirection, viVelocity, _
        viAccelerationDirection, viAcceleration, viMarchingDistance)
    
    iNumMovementDefinitions = iNumMovementDefinitions + 1
    ReDim Preserve oMovementDefinitions(1 To iNumMovementDefinitions)
    Set oMovementDefinitions(iNumMovementDefinitions) = loNewMovementDefinition
    
    Set AddNewMovementDefinition1 = loNewMovementDefinition
End Function

Public Function AddNewMovementDefinition2(rsID$, reMovementType As MovementTypes_Enum)
        
    Dim loNewMovementDefinition As New MovementDefinition
    Call loNewMovementDefinition.Initialize2(rsID, reMovementType)
    
    iNumMovementDefinitions = iNumMovementDefinitions + 1
    ReDim Preserve oMovementDefinitions(1 To iNumMovementDefinitions)
    Set oMovementDefinitions(iNumMovementDefinitions) = loNewMovementDefinition
    
    Set AddNewMovementDefinition2 = loNewMovementDefinition
End Function

Public Function AddNewActorBehavior(rsID$)
    Dim loNewActorBehavior As New ActorBehavior
    Call loNewActorBehavior.Initialize(rsID)
    
    iNumActorBehaviors = iNumActorBehaviors + 1
    ReDim Preserve oActorBehaviors(1 To iNumActorBehaviors)
    Set oActorBehaviors(iNumActorBehaviors) = loNewActorBehavior
    
    Set AddNewActorBehavior = loNewActorBehavior
End Function


