VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
END
Attribute VB_Name = "FastArrayManager2"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = True
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = False
Option Explicit

#Const FAM_SAFEMODE = True

Private lMax As Long
Private lCount As Long
Private lFirstElement As Long
Private lFirstFreeElement As Long
Private lNextElement() As Long 'Applies to Used and Free
Private lPrevElement() As Long 'Applies only to Used
#If FAM_SAFEMODE Then
Private bAllocated() As Boolean
#End If
Private lNextInIteration As Long

Public Property Get Count() As Long
    Count = lCount
End Property

Public Property Get Max() As Long
    Max = lMax
End Property

Public Sub Initialize(ByVal vlSize&)
    Dim llCtr As Long
    
    lCount = 0
    lFirstElement = 0
    lMax = vlSize
    
    ReDim lNextElement(1 To vlSize)
    ReDim lPrevElement(1 To vlSize)
#If FAM_SAFEMODE Then
    ReDim bAllocated(1 To vlSize)
#End If

    'not circular!
    lFirstFreeElement = 1
    For llCtr = 1 To vlSize
        lNextElement(llCtr) = llCtr + 1
#If FAM_SAFEMODE Then
        bAllocated(llCtr) = False
#End If
    Next llCtr
    lNextElement(vlSize) = 0
End Sub

Public Function GetFreeIndex() As Long
    Dim llIndex As Long
    
    llIndex = 0
    
    If lCount < lMax Then
        llIndex = lFirstFreeElement
        If llIndex > 0 Then
            'Remove from Free list -- always the first entry, no previous element
            lFirstFreeElement = lNextElement(llIndex)
            'Add to used list
            If 0 = lFirstElement Then
                lNextElement(llIndex) = 0
            Else
                lNextElement(llIndex) = lFirstElement
                lPrevElement(lFirstElement) = llIndex
            End If
            lFirstElement = llIndex
            lPrevElement(llIndex) = 0

            lCount = lCount + 1
#If FAM_SAFEMODE Then
            'Mark as allocated
            bAllocated(llIndex) = True
#End If
        End If
    End If

    GetFreeIndex = llIndex
End Function

Sub ReleaseIndex(ByVal vlIndex&)
#If FAM_SAFEMODE Then
        If Not bAllocated(vlIndex) Then Exit Sub
        bAllocated(vlIndex) = False
#End If
    'Patch up the Used list
    'if there is a previous, then previous element's next gets this element's next
    If Not 0 = lPrevElement(vlIndex) Then
        lNextElement(lPrevElement(vlIndex)) = lNextElement(vlIndex)
    End If
    'if there is a next, then next element's previous gets this element's previous
    If Not 0 = lNextElement(vlIndex) Then
        lPrevElement(lNextElement(vlIndex)) = lPrevElement(vlIndex)
    End If
    'if this was first, then the next is now first
    If lFirstElement = vlIndex Then
        lFirstElement = lNextElement(vlIndex)
    End If
    
    'Add to Free list (note: Previous ignored in free list)
    lNextElement(vlIndex) = lFirstFreeElement
    lFirstFreeElement = vlIndex
    
    lCount = lCount - 1
End Sub

Public Function StartIteration() As Long
    StartIteration = lFirstElement
    If 0 <> lFirstElement Then
        lNextInIteration = lNextElement(lFirstElement)
    End If
End Function

Public Function NextIteration() As Long
    NextIteration = lNextInIteration
    If 0 <> lNextInIteration Then
        lNextInIteration = lNextElement(lNextInIteration)
    End If
End Function
