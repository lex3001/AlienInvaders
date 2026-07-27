Attribute VB_Name = "modFastArrayManager"
Option Explicit

#Const FAM_SAFEMODE = True

Type FastArrayManager
    lMax As Long
    lCount As Long
    lFirstElement As Long
    lFirstFreeElement As Long
    lNextElement() As Long 'Applies to Used and Free
    lPrevElement() As Long 'Applies only to Used
#If FAM_SAFEMODE Then
    bAllocated() As Boolean
#End If
    lNextInIteration As Long
End Type

Sub FAM_Initialize(rxManager As FastArrayManager, ByVal vlSize&)
    Dim llCtr As Long
    
    With rxManager
        .lCount = 0
        .lFirstElement = 0
        .lMax = vlSize
        
        ReDim .lNextElement(1 To vlSize)
        ReDim .lPrevElement(1 To vlSize)
#If FAM_SAFEMODE Then
        ReDim .bAllocated(1 To vlSize)
#End If

        'not circular!
        .lFirstFreeElement = 1
        For llCtr = 1 To vlSize
            .lNextElement(llCtr) = llCtr + 1
#If FAM_SAFEMODE Then
            .bAllocated(llCtr) = False
#End If
        Next llCtr
        .lNextElement(vlSize) = 0
    End With
End Sub

Function FAM_AddElement(rxManager As FastArrayManager) As Long
    Dim llIndex As Long
    
    llIndex = 0
    
    With rxManager
        If .lCount < rxManager.lMax Then
            llIndex = .lFirstFreeElement
            If llIndex > 0 Then
                'Remove from Free list -- always the first entry, no previous element
                .lFirstFreeElement = .lNextElement(llIndex)
                'Add to used list
                If 0 = .lFirstElement Then
                    .lNextElement(llIndex) = 0
                Else
                    .lNextElement(llIndex) = .lFirstElement
                    .lPrevElement(.lFirstElement) = llIndex
                End If
                .lFirstElement = llIndex
                .lPrevElement(llIndex) = 0

#If FAM_SAFEMODE Then
                'Mark as allocated
                .bAllocated(llIndex) = True
#End If
            End If
        End If
    End With

    FAM_AddElement = llIndex
End Function

Sub FAM_RemoveElement(rxManager As FastArrayManager, ByVal vlIndex&)
    With rxManager
#If FAM_SAFEMODE Then
            If Not .bAllocated(vlIndex) Then Exit Sub
            .bAllocated(vlIndex) = False
#End If
        'Patch up the Used list
        'if there is a previous, then previous element's next gets this element's next
        If Not 0 = .lPrevElement(vlIndex) Then
            .lNextElement(.lPrevElement(vlIndex)) = .lNextElement(vlIndex)
        End If
        'if there is a next, then next element's previous gets this element's previous
        If Not 0 = .lNextElement(vlIndex) Then
            .lPrevElement(.lNextElement(vlIndex)) = .lPrevElement(vlIndex)
        End If
        'if this was first, then the next is now first
        If .lFirstElement = vlIndex Then
            .lFirstElement = .lNextElement(vlIndex)
        End If
        
        'Add to Free list (note: Previous ignored in free list)
        .lNextElement(vlIndex) = .lFirstFreeElement
        .lFirstFreeElement = vlIndex
    End With
End Sub

Function FAM_StartIteration(rxManager As FastArrayManager) As Long
    With rxManager
        FAM_StartIteration = .lFirstElement
        If 0 <> .lFirstElement Then
            .lNextInIteration = .lNextElement(.lFirstElement)
        End If
    End With
End Function

Function FAM_NextIteration(rxManager As FastArrayManager) As Long
    With rxManager
        FAM_NextIteration = .lNextInIteration
        If 0 <> .lNextInIteration Then
            .lNextInIteration = .lNextElement(.lNextInIteration)
        End If
    End With
End Function
