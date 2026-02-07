Attribute VB_Name = "modDirectSound"
Option Explicit

'DirectSound Object
Private mDirectSound As IDirectSound

'Host form
Private mFormHost As Form

'Custom sound effects manager
Type SoundEffect
    iNumCopies As Integer
    dsbDirectSoundBuffers() As IDirectSoundBuffer
    iLastIndexPlayed As Integer
End Type

Private mseSoundEffects() As SoundEffect
Private miSoundEffectsArraySize As Integer
Private miNumSoundEffects As Integer

Public Function DirectSound_Initialize() As Boolean
    On Error GoTo DirectSound_Initialize_ErrorHandler
        
    DirectSoundCreate ByVal 0&, mDirectSound, Nothing
    
    miSoundEffectsArraySize = 0
    miNumSoundEffects = 0
    
    DirectSound_Initialize = True
    Exit Function
        
DirectSound_Initialize_ErrorHandler:
    HandleError Err.Number, Err.Description, Err.LastDllError, Err.Source, "DirectSound_Initialize"
    DirectSound_Initialize = False
End Function

Public Sub DirectSound_Terminate()
    On Error Resume Next
    
    Dim liSEIndex As Integer
    
    For liSEIndex = 1 To miSoundEffectsArraySize
        Call DirectSound_ReleaseSoundEffect(liSEIndex)
    Next liSEIndex
    Erase mseSoundEffects()
    
    If Not (mDirectSound Is Nothing) Then
        'Return control to windows
        mDirectSound.SetCooperativeLevel mFormHost.hWnd, DDSCL_NORMAL
    End If
    
    Set mDirectSound = Nothing
    Set mFormHost = Nothing

    On Error GoTo 0
End Sub

Public Function DirectSound_SetCooperativeLevel(rForm As Form, rlLevel As Long) As Boolean
    On Error GoTo DirectSound_SetCooperativeLevel_ErrorHandler
    Set mFormHost = rForm
    mDirectSound.SetCooperativeLevel mFormHost.hWnd, rlLevel
    DirectSound_SetCooperativeLevel = True
    Exit Function
    
DirectSound_SetCooperativeLevel_ErrorHandler:
    HandleError Err.Number, Err.Description, Err.LastDllError, Err.Source, "DirectSound_SetCooperativeLevel"
    DirectSound_SetCooperativeLevel = False
End Function

'riHse returns SoundEffectHandle
Public Function DirectSound_LoadSoundEffect(ByRef riHse As Integer, _
        rsFileName As String, riNumCopiesRequested As Integer) As Boolean
    On Error GoTo DirectSound_LoadSoundEffect_ErrorHandler
    DirectSound_LoadSoundEffect = False
    
    Dim liSEIndex As Integer 'Sound Effect index
    Dim liDSBIndex  As Integer 'Direct Sound Buffer index
    Dim ldsbTempDSB As IDirectSoundBuffer
    
    'find an index to use for this sound effect
    If (miNumSoundEffects < miSoundEffectsArraySize) Then
        'there is space- find an empty index
        For liSEIndex = 1 To miSoundEffectsArraySize
            If mseSoundEffects(liSEIndex).iNumCopies <= 0 Then Exit For
        Next liSEIndex
    Else
        'add to the end
        liSEIndex = miSoundEffectsArraySize + 1
    End If
    
    'grow the sound effects array if necessary
    If (liSEIndex > miSoundEffectsArraySize) Then
        miSoundEffectsArraySize = miSoundEffectsArraySize + 1
        ReDim Preserve mseSoundEffects(1 To miSoundEffectsArraySize)
    End If
    
    With mseSoundEffects(liSEIndex)
        'initialize this effect
        .iNumCopies = 0
        .iLastIndexPlayed = 0
        Erase .dsbDirectSoundBuffers()
        
        'attempt to load first copy from .WAV file
        Call LoadWAVIntoDSB(mDirectSound, rsFileName, ldsbTempDSB)
        If Not (ldsbTempDSB Is Nothing) Then
            miNumSoundEffects = miNumSoundEffects + 1
            riHse = liSEIndex
            .iNumCopies = 1
            ReDim .dsbDirectSoundBuffers(1 To riNumCopiesRequested)
            Set .dsbDirectSoundBuffers(1) = ldsbTempDSB
            Set ldsbTempDSB = Nothing
            
            On Error Resume Next
            'attempt to load additional copies
            For liDSBIndex = 2 To riNumCopiesRequested
                'first try to duplicate the buffer- saves memory but not guaranteed
                Call mDirectSound.DuplicateSoundBuffer( _
                        .dsbDirectSoundBuffers(1), .dsbDirectSoundBuffers(liDSBIndex))
                'if that did not work, load a new copy
                If Not (0 = Err.Number) Then
                    Call LoadWAVIntoDSB(mDirectSound, rsFileName, _
                            .dsbDirectSoundBuffers(liDSBIndex))
                    'if that also failed, we have 1 copy so we will exit cleanly
'WIP ======== What happens if LoadWAVIntoDSB fails??? ==========
                    If Not (0 = Err.Number) Then Exit For
                End If

                'if we didn't exit the loop, that means we have next copy
                .iNumCopies = liDSBIndex
            Next liDSBIndex
            On Error GoTo 0
        
            'if we don't have as many copies as we expected, reduce the DSB array size
            If (.iNumCopies < riNumCopiesRequested) Then
                ReDim Preserve .dsbDirectSoundBuffers(1 To .iNumCopies)
            End If
            
            DirectSound_LoadSoundEffect = True
        End If
    End With
    
    Exit Function

DirectSound_LoadSoundEffect_ErrorHandler:
    HandleError Err.Number, Err.Description, Err.LastDllError, Err.Source, "DirectSound_LoadSoundEffect"
    Set ldsbTempDSB = Nothing
End Function

'riHse is SoundEffectHandle
Public Sub DirectSound_ReleaseSoundEffect(ByRef riHse As Integer)
    On Error GoTo DirectSound_ReleaseSoundEffect_ErrorHandler
    
    Dim liDSBIndex  As Integer 'Direct Sound Buffer index
    
    If (riHse < 1) Or (riHse > miNumSoundEffects) Then Exit Sub
        
    With mseSoundEffects(riHse)
        For liDSBIndex = 1 To .iNumCopies
            Set .dsbDirectSoundBuffers(liDSBIndex) = Nothing
        Next liDSBIndex
        Erase .dsbDirectSoundBuffers()
        .iNumCopies = 0
        .iLastIndexPlayed = 0
    End With
    
    Exit Sub

DirectSound_ReleaseSoundEffect_ErrorHandler:
    HandleError Err.Number, Err.Description, Err.LastDllError, Err.Source, "DirectSound_ReleaseSoundEffect"
End Sub

'riHse is SoundEffectHandle
'rvPan expected as -1.0 to 1.0 (left to right)
Public Sub DirectSound_PlaySoundEffect(riHse As Integer, Optional rvFlags, Optional rvPan)
    On Error GoTo DirectSound_PlaySoundEffect_ErrorHandler
    
    If (riHse < 1) Or (riHse > miNumSoundEffects) Then Exit Sub
        
    With mseSoundEffects(riHse)
        .iLastIndexPlayed = .iLastIndexPlayed + 1
        If (.iLastIndexPlayed > .iNumCopies) Then .iLastIndexPlayed = 1
        
        If IsMissing(rvFlags) Then rvFlags = 0&
        If IsMissing(rvPan) Then rvPan = 0#
        
        If (Abs(rvPan) > 1) Or (rvPan = 0) Then
            .dsbDirectSoundBuffers(.iLastIndexPlayed).SetPan DSBPAN_CENTER
        ElseIf rvPan < 0 Then
            .dsbDirectSoundBuffers(.iLastIndexPlayed).SetPan (DSBPAN_LEFT * Abs(rvPan)) / 10
        Else
            .dsbDirectSoundBuffers(.iLastIndexPlayed).SetPan (DSBPAN_RIGHT * rvPan) / 10
        End If
        
        Dim llPlayCursor As Long
        Dim llWriteCursor As Long
        Call .dsbDirectSoundBuffers(.iLastIndexPlayed).GetCurrentPosition(llPlayCursor, llWriteCursor)
        
        LogInfo "Playing Sound: " & riHse & "(" & .iLastIndexPlayed & _
        ") Pan=" & rvPan & " curpos=" & llPlayCursor, _
        "DirectSound_PlaySoundEffect"
        '.dsbDirectSoundBuffers(.iLastIndexPlayed).Play 0&, 0&, CLng(rvFlags)
        .dsbDirectSoundBuffers(.iLastIndexPlayed).Play 0&, 0&, 0&
    End With
    
    Exit Sub

DirectSound_PlaySoundEffect_ErrorHandler:
    HandleError Err.Number, Err.Description, Err.LastDllError, Err.Source, "DirectSound_PlaySoundEffect"
End Sub
