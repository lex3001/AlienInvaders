Attribute VB_Name = "DirectSoundModule"
Option Explicit
'DirectSound Module
'Written by Jan Nawara [redacted]
'Version 1.21
'Released on Sept 12, 1998

'This module is Freeware and can be used by you for
'any purpose without prior permission.

'Revisions
'1999-03-09 by Luther Ananda Miller [redacted]
'1) Implemented General_DuplicateOrLoadStaticSound() to duplicate a static sound buffer (loads if dup fails)
'2) No longer a hardcoded MaxBuffers limit (defaults to 32, allocates in chunks of 8)

'===============================================
'Declarations
'===============================================

'Memory Copy.
Private Declare Sub CopyMemory Lib "kernel32" Alias "RtlMoveMemory" (ByVal Destination As Long, ByVal source As Long, ByVal Length As Long)

'Timer
Private Declare Function SetTimer Lib "user32" (ByVal hwnd As Long, ByVal nIDEvent As Long, ByVal uElapse As Long, ByVal lpTimerFunc As Long) As Long
Private Declare Function KillTimer Lib "user32" (ByVal hwnd As Long, ByVal nIDEvent As Long) As Long

'===============================================
'Class Constants
'===============================================

Const UpdateInterval = 500 'Update interval for streaming buffers

'CHANGED 1999-03-09 Luther Ananda Miller [redacted]
'Const MaxBuffers = 32 'Maximum number of sound buffers
Private Const ALLOCATE_CHUNK% = 8
Private Const DEFAULT_MAX_BUFFERS% = ALLOCATE_CHUNK * 4
Private MaxBuffers As Integer 'Maximum number of sound buffers
Private BuffersUsed As Integer 'Number of sound buffers currently used


'===============================================
'Class Variables
'===============================================

Dim Scrap As Variant 'Scrap holder for discardable values

Dim Initialized As Boolean 'Stops repeated initialization
Dim SoundOK As Boolean 'Is true if sound is available
Dim UseForm As Form 'Refrence to the owning form

Dim DirectSound As IDirectSound 'General DirectSound

'Primary sound buffer
Dim DirectSoundPrimaryBuffer As IDirectSoundBuffer
Dim DirectSoundPrimary3DBuffer As IDirectSound3DListener
Dim DirectSoundBufferDesc As DSBUFFERDESC
Dim SetWaveFormat As WAVEFORMATEX

'CHANGED 1999-03-09 Luther Ananda Miller [redacted]
'Main sound buffer data variables
Dim DirectSoundBuffer() As IDirectSoundBuffer
Dim DirectSound3DBuffer() As IDirectSound3DBuffer
Dim DirectSoundBufferDescription() As DSBUFFERDESC
Dim DirectSoundWaveFormat() As WAVEFORMATEX
Dim SoundAvailable() As Boolean
Dim DirectSoundBufferFileName() As String
Dim DirectSoundBufferFileOffset() As Long
Dim Is3D() As Boolean
Dim IsLooping() As Boolean
Dim IsPlaying() As Boolean
Dim IsStreaming() As Boolean
Dim IsUpdating() As Boolean
Dim PlayingStreams As Integer
Dim StreamStartPos() As Long
Dim StreamRestartPos() As Long
Dim StreamLength() As Long
Dim StreamWriteCursor() As Long
Dim StreamPlayCursor() As Long
Dim StreamPosition() As Long
Dim StreamOldPosition() As Long
Dim StreamOldWriteCursor() As Long
Dim StreamFileNum() As Integer

'ADDED 1999-03-09 Luther Ananda Miller [redacted]
Dim DataLengths() As Long

Private Sub Private_ReAllocateArrays(NewMaxBuffers As Integer)
    Dim liCtr As Integer
    
    'Only if the array is shrinking, set DirectSound objects to nothing (just to be safe)
    If NewMaxBuffers < MaxBuffers Then
        For liCtr = NewMaxBuffers To MaxBuffers + 1 Step -1
            Set DirectSoundBuffer(liCtr) = Nothing
            Set DirectSound3DBuffer(liCtr) = Nothing
        Next liCtr
    End If
    
    If NewMaxBuffers > 0 Then
        ReDim Preserve DirectSoundBuffer(1 To NewMaxBuffers)
        ReDim Preserve DirectSound3DBuffer(1 To NewMaxBuffers)
        ReDim Preserve DirectSoundBufferDescription(1 To NewMaxBuffers)
        ReDim Preserve DirectSoundWaveFormat(1 To NewMaxBuffers)
        ReDim Preserve SoundAvailable(1 To NewMaxBuffers)
        ReDim Preserve DirectSoundBufferFileName(1 To NewMaxBuffers)
        ReDim Preserve DirectSoundBufferFileOffset(1 To NewMaxBuffers)
        ReDim Preserve Is3D(1 To NewMaxBuffers)
        ReDim Preserve IsLooping(1 To NewMaxBuffers)
        ReDim Preserve IsPlaying(1 To NewMaxBuffers)
        ReDim Preserve IsStreaming(1 To NewMaxBuffers)
        ReDim Preserve IsUpdating(1 To NewMaxBuffers)
        ReDim Preserve StreamStartPos(1 To NewMaxBuffers)
        ReDim Preserve StreamRestartPos(1 To NewMaxBuffers)
        ReDim Preserve StreamLength(1 To NewMaxBuffers)
        ReDim Preserve StreamWriteCursor(1 To NewMaxBuffers)
        ReDim Preserve StreamPlayCursor(1 To NewMaxBuffers)
        ReDim Preserve StreamPosition(1 To NewMaxBuffers)
        ReDim Preserve StreamOldPosition(1 To NewMaxBuffers)
        ReDim Preserve StreamOldWriteCursor(1 To NewMaxBuffers)
        ReDim Preserve StreamFileNum(1 To NewMaxBuffers)
        'ADDED 1999-03-09 Luther Ananda Miller [redacted]
        ReDim Preserve DataLengths(1 To NewMaxBuffers)
    Else
        NewMaxBuffers = 0 'just in case someone gave us a negative number
        Erase DirectSoundBuffer()
        Erase DirectSound3DBuffer()
        Erase DirectSoundBufferDescription()
        Erase DirectSoundWaveFormat()
        Erase SoundAvailable()
        Erase DirectSoundBufferFileName()
        Erase DirectSoundBufferFileOffset()
        Erase Is3D()
        Erase IsLooping()
        Erase IsPlaying()
        Erase IsStreaming()
        Erase IsUpdating()
        Erase StreamStartPos()
        Erase StreamRestartPos()
        Erase StreamLength()
        Erase StreamWriteCursor()
        Erase StreamPlayCursor()
        Erase StreamPosition()
        Erase StreamOldPosition()
        Erase StreamOldWriteCursor()
        Erase StreamFileNum()
        'ADDED 1999-03-09 Luther Ananda Miller [redacted]
        Erase DataLengths()
    End If
    
    'Only if the array is growing, reset new enties to be Available (free)
    If NewMaxBuffers > MaxBuffers Then
        For liCtr = MaxBuffers + 1 To NewMaxBuffers
            SoundAvailable(liCtr) = True
        Next liCtr
    End If
    
    MaxBuffers = NewMaxBuffers

'for debugging...
'Debug.Print "DirectSoundModule: Arrays reallocated to " & MaxBuffers
End Sub

Public Function Listener_GetAllParameters() As DS3DLISTENER

If SoundOK = False Then

    Exit Function

End If

On Error Resume Next

Listener_GetAllParameters.dwSize = Len(Listener_GetAllParameters)
DirectSoundPrimary3DBuffer.GetAllParameters Listener_GetAllParameters

End Function
Public Sub Listener_SetAllParameters(Params As DS3DLISTENER, Wait As Boolean)

If SoundOK = False Then

    Exit Sub

End If

On Error Resume Next

DirectSoundPrimary3DBuffer.SetAllParameters Params, IIf(Wait = True, DS3D_DEFERRED, DS3D_IMMEDIATE)

End Sub
Public Sub Listener_CommitDeferredSettings()

If SoundOK = False Then

    Exit Sub
    
End If

On Error Resume Next

DirectSoundPrimary3DBuffer.CommitDeferredSettings

End Sub
Public Function Listener_GetDistanceFactor() As Single

Listener_GetDistanceFactor = 1

If SoundOK = False Then

    Exit Function
    
End If

On Error Resume Next

DirectSoundPrimary3DBuffer.GetDistanceFactor Listener_GetDistanceFactor

End Function
Public Sub Listener_SetDistanceFactor(Factor As Single, Wait As Boolean)

If SoundOK = False Then

    Exit Sub
    
End If

On Error Resume Next

DirectSoundPrimary3DBuffer.SetDistanceFactor Factor, IIf(Wait = True, DS3D_DEFERRED, DS3D_IMMEDIATE)

End Sub
Public Function Listener_GetDopplerFactor() As Single

Listener_GetDopplerFactor = 1

If SoundOK = False Then

    Exit Function
    
End If

On Error Resume Next

DirectSoundPrimary3DBuffer.GetDopplerFactor Listener_GetDopplerFactor

End Function
Public Sub Listener_SetDopplerFactor(Factor As Single, Wait As Boolean)

If SoundOK = False Then

    Exit Sub
    
End If

On Error Resume Next

If Factor >= 0 And Factor <= 10 Then

    DirectSoundPrimary3DBuffer.SetDopplerFactor Factor, IIf(Wait = True, DS3D_DEFERRED, DS3D_IMMEDIATE)

End If

End Sub
Public Sub Listener_GetOrientation(ByRef FrontOrientation As D3DVECTOR, ByRef TopOrientation As D3DVECTOR)

FrontOrientation.X = 0
FrontOrientation.Y = 0
FrontOrientation.Z = 1
TopOrientation.X = 0
TopOrientation.Y = 1
TopOrientation.Z = 0

If SoundOK = False Then

    Exit Sub
    
End If

On Error Resume Next

DirectSoundPrimary3DBuffer.GetOrientation FrontOrientation, TopOrientation

End Sub
Public Sub Listener_SetOrientation(XFront As Single, YFront As Single, ZFront As Single, XTop As Single, YTop As Single, ZTop As Single, Wait As Boolean)

If SoundOK = False Then

    Exit Sub
    
End If

On Error Resume Next

DirectSoundPrimary3DBuffer.SetOrientation XFront, YFront, ZFront, XTop, YTop, ZTop, IIf(Wait = True, DS3D_DEFERRED, DS3D_IMMEDIATE)

End Sub
Public Function Listener_GetPosition() As D3DVECTOR

Listener_GetPosition.X = 0
Listener_GetPosition.Y = 0
Listener_GetPosition.Z = 0

If SoundOK = False Then

    Exit Function

End If

On Error Resume Next

DirectSoundPrimary3DBuffer.GetPosition Listener_GetPosition

End Function
Public Sub Listener_SetPosition(X As Single, Y As Single, Z As Single, Wait As Boolean)

If SoundOK = False Then

    Exit Sub

End If

On Error Resume Next

DirectSoundPrimary3DBuffer.SetPosition X, Y, Z, IIf(Wait = True, DS3D_DEFERRED, DS3D_IMMEDIATE)

End Sub
Public Function Listener_GetRolloffFactor() As Single

Listener_GetRolloffFactor = 1

If SoundOK = False Then

    Exit Function
    
End If

On Error Resume Next

DirectSoundPrimary3DBuffer.GetRolloffFactor Listener_GetRolloffFactor

End Function
Public Sub Listener_SetRolloffFactor(Factor As Single, Wait As Boolean)

If SoundOK = False Then

    Exit Sub
    
End If

On Error Resume Next

If Factor >= 0 And Factor <= 10 Then

    DirectSoundPrimary3DBuffer.SetRolloffFactor Factor, IIf(Wait = True, DS3D_DEFERRED, DS3D_IMMEDIATE)

End If

End Sub
Public Function Listener_GetVelocity() As D3DVECTOR

Listener_GetVelocity.X = 0
Listener_GetVelocity.Y = 0
Listener_GetVelocity.Z = 0

If SoundOK = False Then

    Exit Function

End If

On Error Resume Next

DirectSoundPrimary3DBuffer.GetVelocity Listener_GetVelocity

End Function
Public Sub Listener_SetVelocity(X As Single, Y As Single, Z As Single, Wait As Boolean)

If SoundOK = False Then

    Exit Sub

End If

On Error Resume Next

DirectSoundPrimary3DBuffer.SetVelocity X, Y, Z, IIf(Wait = True, DS3D_DEFERRED, DS3D_IMMEDIATE)

End Sub
Public Function Buffer2D_GetFormat(SoundNumber As Integer) As WAVEFORMATEX

If SoundOK = False Then

    Exit Function

End If

On Error Resume Next

If SoundNumber <= MaxBuffers And SoundNumber >= 1 And SoundAvailable(SoundNumber) = False Then

    Buffer2D_GetFormat = DirectSoundWaveFormat(SoundNumber)

End If

End Function
Public Function Buffer2D_GetCaps(SoundNumber As Integer) As DSBCAPS

If SoundOK = False Then

    Exit Function

End If

On Error Resume Next

If SoundNumber <= MaxBuffers And SoundNumber >= 1 And SoundAvailable(SoundNumber) = False Then

    Buffer2D_GetCaps.dwSize = Len(Buffer2D_GetCaps)
    DirectSoundBuffer(SoundNumber).GetCaps Buffer2D_GetCaps

End If

End Function
Public Sub DSound_Compact()

If SoundOK = False Then

    Exit Sub

End If

On Error Resume Next

DirectSound.Compact

End Sub
Public Function DSound_GetCaps() As DSCAPS

If SoundOK = False Then

    Exit Function

End If

On Error Resume Next

DSound_GetCaps.dwSize = Len(DSound_GetCaps)
DirectSound.GetCaps DSound_GetCaps

End Function
Public Sub Buffer2D_SetStreamRestartPosition(SoundNumber As Integer, RestartPosition As Long)

If SoundOK = False Then

    Exit Sub

End If

On Error Resume Next

If SoundNumber <= MaxBuffers And SoundNumber >= 1 And SoundAvailable(SoundNumber) = False And IsStreaming(SoundNumber) = True And RestartPosition >= 0 And RestartPosition <= StreamLength(SoundNumber) Then

    StreamRestartPos(SoundNumber) = Fix(RestartPosition / DirectSoundWaveFormat(SoundNumber).nBlockAlign) * DirectSoundWaveFormat(SoundNumber).nBlockAlign

End If

End Sub
Public Function Buffer2D_GetStreamRestartPosition(SoundNumber As Integer) As Long

Buffer2D_GetStreamRestartPosition = 0

If SoundOK = False Then

    Exit Function

End If

On Error Resume Next

If SoundNumber <= MaxBuffers And SoundNumber >= 1 And SoundAvailable(SoundNumber) = False And IsStreaming(SoundNumber) = True Then

    Buffer2D_GetStreamRestartPosition = StreamRestartPos(SoundNumber)

End If

End Function
Public Function Buffer3D_GetAllParameters(SoundNumber As Integer) As DS3DBUFFER
 
If SoundOK = False Then

    Exit Function

End If

On Error Resume Next

If SoundNumber <= MaxBuffers And SoundNumber >= 1 And SoundAvailable(SoundNumber) = False And Is3D(SoundNumber) = True Then

    Buffer3D_GetAllParameters.dwSize = Len(Buffer3D_GetAllParameters)
    DirectSound3DBuffer(SoundNumber).GetAllParameters Buffer3D_GetAllParameters
    
End If

End Function
Public Sub Buffer3D_SetAllParameters(SoundNumber As Integer, Parameters As DS3DBUFFER, Wait As Boolean)

If SoundOK = False Then

    Exit Sub

End If

On Error Resume Next

If SoundNumber <= MaxBuffers And SoundNumber >= 1 And SoundAvailable(SoundNumber) = False And Is3D(SoundNumber) = True Then

    DirectSound3DBuffer(SoundNumber).SetAllParameters Parameters, IIf(Wait = True, DS3D_DEFERRED, DS3D_IMMEDIATE)

End If

End Sub
Public Function Buffer3D_GetConeOutsideVolume(SoundNumber As Integer) As Long
 
Buffer3D_GetConeOutsideVolume = 0

If SoundOK = False Then

    Exit Function

End If

On Error Resume Next

If SoundNumber <= MaxBuffers And SoundNumber >= 1 And SoundAvailable(SoundNumber) = False And Is3D(SoundNumber) = True Then

    DirectSound3DBuffer(SoundNumber).GetConeOutsideVolume Buffer3D_GetConeOutsideVolume

End If

End Function
Public Sub Buffer3D_SetConeOutsideVolume(SoundNumber As Integer, Volume As Long, Wait As Boolean)

If SoundOK = False Then

    Exit Sub

End If

On Error Resume Next

If SoundNumber <= MaxBuffers And SoundNumber >= 1 And SoundAvailable(SoundNumber) = False And Is3D(SoundNumber) = True And Volume <= DSBVOLUME_MAX And Volume >= DSBVOLUME_MIN Then

    DirectSound3DBuffer(SoundNumber).SetConeOutsideVolume Volume, IIf(Wait = True, DS3D_DEFERRED, DS3D_IMMEDIATE)

End If

End Sub
Public Function Buffer3D_GetConeOrientation(SoundNumber As Integer) As D3DVECTOR

Buffer3D_GetConeOrientation.X = 0
Buffer3D_GetConeOrientation.Y = 0
Buffer3D_GetConeOrientation.Z = 0

If SoundOK = False Then

    Exit Function

End If


On Error Resume Next

If SoundNumber <= MaxBuffers And SoundNumber >= 1 And SoundAvailable(SoundNumber) = False And Is3D(SoundNumber) = True Then

    DirectSound3DBuffer(SoundNumber).GetConeOrientation Buffer3D_GetConeOrientation

End If

End Function
Public Sub Buffer3D_SetConeOrientation(SoundNumber As Integer, X As Single, Y As Single, Z As Single, Wait As Boolean)

If SoundOK = False Then

    Exit Sub

End If

On Error Resume Next

If SoundNumber <= MaxBuffers And SoundNumber >= 1 And SoundAvailable(SoundNumber) = False And Is3D(SoundNumber) = True Then

    DirectSound3DBuffer(SoundNumber).SetConeOrientation X, Y, Z, IIf(Wait = True, DS3D_DEFERRED, DS3D_IMMEDIATE)

End If

End Sub
Public Sub Buffer3D_GetConeAngles(SoundNumber As Integer, ByRef InsideCone As Long, ByRef OutsideCone As Long)

InsideCone = 0
OutsideCone = 0

If SoundOK = False Then

    Exit Sub

End If

On Error Resume Next

If SoundNumber <= MaxBuffers And SoundNumber >= 1 And SoundAvailable(SoundNumber) = False And Is3D(SoundNumber) = True Then

    DirectSound3DBuffer(SoundNumber).GetConeAngles InsideCone, OutsideCone

End If

End Sub
Public Sub Buffer3D_SetConeAngles(SoundNumber As Integer, InsideCone As Long, OutsideCone As Long, Wait As Boolean)

If SoundOK = False Then

    Exit Sub

End If

On Error Resume Next

If SoundNumber <= MaxBuffers And SoundNumber >= 1 And SoundAvailable(SoundNumber) = False And Is3D(SoundNumber) = True And InsideCone >= DS3D_MINCONEANGLE And InsideCone <= DS3D_MAXCONEANGLE And OutsideCone >= DS3D_MINCONEANGLE And OutsideCone <= DS3D_MAXCONEANGLE Then

    DirectSound3DBuffer(SoundNumber).SetConeAngles InsideCone, OutsideCone, IIf(Wait = True, DS3D_DEFERRED, DS3D_IMMEDIATE)

End If

End Sub
Public Function Buffer3D_GetVelocity(SoundNumber As Integer) As D3DVECTOR

Buffer3D_GetVelocity.X = 0
Buffer3D_GetVelocity.Y = 0
Buffer3D_GetVelocity.Z = 0

If SoundOK = False Then

    Exit Function

End If

On Error Resume Next

If SoundNumber <= MaxBuffers And SoundNumber >= 1 And SoundAvailable(SoundNumber) = False And Is3D(SoundNumber) = True Then

    DirectSound3DBuffer(SoundNumber).GetVelocity Buffer3D_GetVelocity

End If

End Function
Public Sub Buffer3D_SetVelocity(SoundNumber As Integer, X As Single, Y As Single, Z As Single, Wait As Boolean)

If SoundOK = False Then

    Exit Sub

End If

On Error Resume Next

If SoundNumber <= MaxBuffers And SoundNumber >= 1 And SoundAvailable(SoundNumber) = False And Is3D(SoundNumber) = True Then

    DirectSound3DBuffer(SoundNumber).SetVelocity X, Y, Z, IIf(Wait = True, DS3D_DEFERRED, DS3D_IMMEDIATE)

End If

End Sub
Public Function Buffer3D_GetPosition(SoundNumber As Integer) As D3DVECTOR

Buffer3D_GetPosition.X = 0
Buffer3D_GetPosition.Y = 0
Buffer3D_GetPosition.Z = 0

If SoundOK = False Then

    Exit Function

End If

On Error Resume Next

If SoundNumber <= MaxBuffers And SoundNumber >= 1 And SoundAvailable(SoundNumber) = False And Is3D(SoundNumber) = True Then

    DirectSound3DBuffer(SoundNumber).GetPosition Buffer3D_GetPosition

End If

End Function
Public Sub Buffer3D_SetPosition(SoundNumber As Integer, X As Single, Y As Single, Z As Single, Wait As Boolean)

If SoundOK = False Then

    Exit Sub

End If

On Error Resume Next

If SoundNumber <= MaxBuffers And SoundNumber >= 1 And SoundAvailable(SoundNumber) = False And Is3D(SoundNumber) = True Then

    DirectSound3DBuffer(SoundNumber).SetPosition X, Y, Z, IIf(Wait = True, DS3D_DEFERRED, DS3D_IMMEDIATE)

End If

End Sub
Public Function Buffer3D_GetMode(SoundNumber As Integer) As Long

Buffer3D_GetMode = DS3DMODE_DISABLE

If SoundOK = False Then

    Exit Function

End If

On Error Resume Next

If SoundNumber <= MaxBuffers And SoundNumber >= 1 And SoundAvailable(SoundNumber) = False And Is3D(SoundNumber) = True Then

    DirectSound3DBuffer(SoundNumber).GetMode Buffer3D_GetMode

End If

End Function
Public Sub Buffer3D_SetMode(SoundNumber As Integer, Mode As Long, Wait As Boolean)

If SoundOK = False Then

    Exit Sub

End If

On Error Resume Next

If SoundNumber <= MaxBuffers And SoundNumber >= 1 And SoundAvailable(SoundNumber) = False And Is3D(SoundNumber) = True And (Mode = DS3DMODE_NORMAL Or Mode = DS3DMODE_HEADRELATIVE Or Mode = DS3DMODE_DISABLE) Then

    DirectSound3DBuffer(SoundNumber).SetMode Mode, IIf(Wait = True, DS3D_DEFERRED, DS3D_IMMEDIATE)

End If

End Sub
Public Sub Buffer3D_SetMaxDistance(SoundNumber As Integer, Distance As Single, Wait As Boolean)

If SoundOK = False Then

    Exit Sub

End If

On Error Resume Next

If SoundNumber <= MaxBuffers And SoundNumber >= 1 And SoundAvailable(SoundNumber) = False And Is3D(SoundNumber) = True Then

    DirectSound3DBuffer(SoundNumber).SetMaxDistance Distance, IIf(Wait = True, DS3D_DEFERRED, DS3D_IMMEDIATE)

End If

End Sub
Public Function Buffer3D_GetMaxDistance(SoundNumber As Integer) As Single

Buffer3D_GetMaxDistance = 0

If SoundOK = False Then

    Exit Function

End If

On Error Resume Next

If SoundNumber <= MaxBuffers And SoundNumber >= 1 And SoundAvailable(SoundNumber) = False And Is3D(SoundNumber) = True Then

    DirectSound3DBuffer(SoundNumber).GetMaxDistance Buffer3D_GetMaxDistance

End If

End Function
Public Sub Buffer3D_SetMinDistance(SoundNumber As Integer, Distance As Single, Wait As Boolean)

If SoundOK = False Then

    Exit Sub

End If

On Error Resume Next

If SoundNumber <= MaxBuffers And SoundNumber >= 1 And SoundAvailable(SoundNumber) = False And Is3D(SoundNumber) = True Then

    DirectSound3DBuffer(SoundNumber).SetMinDistance Distance, IIf(Wait = True, DS3D_DEFERRED, DS3D_IMMEDIATE)

End If

End Sub
Public Function Buffer3D_GetMinDistance(SoundNumber As Integer) As Single

Buffer3D_GetMinDistance = 0

If SoundOK = False Then

    Exit Function

End If

On Error Resume Next

If SoundNumber <= MaxBuffers And SoundNumber >= 1 And SoundAvailable(SoundNumber) = False And Is3D(SoundNumber) = True Then

    DirectSound3DBuffer(SoundNumber).GetMinDistance Buffer3D_GetMinDistance

End If

End Function
Public Function Primary_GetVolume() As Long

Primary_GetVolume = 0

If SoundOK = False Then

    Exit Function

End If

On Error Resume Next

DirectSoundPrimaryBuffer.GetVolume Primary_GetVolume

End Function
Public Sub Primary_SetVolume(Volume As Long)

If SoundOK = False Then

    Exit Sub

End If

On Error Resume Next

If Volume <= DSBVOLUME_MAX And Volume >= DSBVOLUME_MIN Then

    DirectSoundPrimaryBuffer.SetVolume Volume
    
End If

End Sub
Public Function Buffer2D_GetPosition(SoundNumber As Integer) As Long

Buffer2D_GetPosition = 0

If SoundOK = False Then

    Exit Function

End If

Dim NewPos As Long

On Error Resume Next

If SoundNumber <= MaxBuffers And SoundNumber >= 1 And SoundAvailable(SoundNumber) = False Then

    If IsStreaming(SoundNumber) Then
    
        Dim PlayCursor As Long
        
        DirectSoundBuffer(SoundNumber).GetCurrentPosition PlayCursor, CLng(Scrap)
        
        If StreamOldPosition(SoundNumber) > 0 Then
        
            If StreamOldWriteCursor(SoundNumber) >= PlayCursor Then

                NewPos = StreamOldPosition(SoundNumber) - (StreamOldWriteCursor(SoundNumber) - PlayCursor)
                
                If NewPos > StreamLength(SoundNumber) Then
                    
                    StreamOldPosition(SoundNumber) = 0
                    StreamOldWriteCursor(SoundNumber) = 0
                    
                End If
                
            ElseIf StreamOldWriteCursor(SoundNumber) < PlayCursor Then
            
                NewPos = StreamOldPosition(SoundNumber) - (StreamOldWriteCursor(SoundNumber) + (DirectSoundBufferDescription(SoundNumber).dwBufferBytes - PlayCursor))
                
                If NewPos > StreamLength(SoundNumber) Then
                
                    StreamOldPosition(SoundNumber) = 0
                    StreamOldWriteCursor(SoundNumber) = 0
                
                End If
            
            End If
        
        End If
        
        If StreamOldPosition(SoundNumber) = 0 Then
        
            If StreamWriteCursor(SoundNumber) >= PlayCursor Then
            
                NewPos = StreamPosition(SoundNumber) - (StreamWriteCursor(SoundNumber) - PlayCursor)
                
            ElseIf StreamWriteCursor(SoundNumber) < PlayCursor Then
            
                NewPos = StreamPosition(SoundNumber) - (StreamWriteCursor(SoundNumber) + (DirectSoundBufferDescription(SoundNumber).dwBufferBytes - PlayCursor))
            
            End If
        
        End If
        
        If IsPlaying(SoundNumber) = False And StreamPosition(SoundNumber) = DirectSoundBufferDescription(SoundNumber).dwBufferBytes Then NewPos = 0
            
    Else
    
        DirectSoundBuffer(SoundNumber).GetCurrentPosition NewPos, CLng(Scrap)

    End If
    
    Buffer2D_GetPosition = NewPos
    
End If

End Function
Public Sub Buffer2D_SetPosition(SoundNumber As Integer, Position As Long)

If SoundOK = False Then

    Exit Sub

End If

On Error Resume Next

Dim J As Long
Dim WaveData() As Byte
Dim WaveDataTemp() As Byte
Dim Ptr1 As Long
Dim Lng1 As Long
Dim Ptr2 As Long
Dim Lng2 As Long
Dim Status As Long
Dim BufferOK As Boolean
Dim Playing As Boolean

If SoundNumber <= MaxBuffers And SoundNumber >= 0 And Position >= 0 And Position <= IIf(IsStreaming(SoundNumber) = True, StreamLength(SoundNumber), DirectSoundBufferDescription(SoundNumber).dwBufferBytes) And SoundAvailable(SoundNumber) = False Then

    If IsStreaming(SoundNumber) And IsUpdating(SoundNumber) = False Then
    
        StreamPosition(SoundNumber) = Fix(Position / DirectSoundWaveFormat(SoundNumber).nBlockAlign) * DirectSoundWaveFormat(SoundNumber).nBlockAlign
        
        DirectSoundBuffer(SoundNumber).GetStatus Status
        
        If Status = DSBSTATUS_BUFFERLOST Then
        
            BufferOK = Private_RestoreStreamingBuffer(SoundNumber)
            
            If BufferOK = False Then
                
                ReDim WaveData(1 To 1)
                Exit Sub
            
            End If
            
        End If
        
        Playing = IsPlaying(SoundNumber)
        IsPlaying(SoundNumber) = False
        DirectSoundBuffer(SoundNumber).Stop
        DirectSoundBuffer(SoundNumber).SetCurrentPosition 0
        
        Call DirectSoundBuffer(SoundNumber).Lock(0&, DirectSoundBufferDescription(SoundNumber).dwBufferBytes, Ptr1, Lng1, Ptr2, Lng2, 0&)
            
        If IsLooping(SoundNumber) = True And StreamPosition(SoundNumber) + Lng1 + Lng2 >= StreamLength(SoundNumber) Then
        
            'Seek to next data block
            Seek #StreamFileNum(SoundNumber), StreamStartPos(SoundNumber) + StreamPosition(SoundNumber)
            
            'Get last data block in file
            ReDim WaveData(1 To (StreamLength(SoundNumber) - StreamPosition(SoundNumber) - 1))
            Get #StreamFileNum(SoundNumber), , WaveData
                            
            ReDim Preserve WaveData(1 To Lng1 + Lng2)
            
            'Seek to start of file (or restart pos)
            Seek #StreamFileNum(SoundNumber), StreamStartPos(SoundNumber) + StreamRestartPos(SoundNumber)
            
            'Get first data block
            ReDim WaveDataTemp(StreamLength(SoundNumber) - StreamPosition(SoundNumber) To Lng1 + Lng2)
            Get #StreamFileNum(SoundNumber), , WaveDataTemp
            
            'Combine last and first blocks
            For J = StreamLength(SoundNumber) - StreamPosition(SoundNumber) To Lng1 + Lng2
            
                WaveData(J) = WaveDataTemp(J)
                
            Next
            
            'Set new stream position
            StreamOldWriteCursor(SoundNumber) = IIf(Lng2 = 0, StreamWriteCursor(SoundNumber) + Lng1, Lng2)
            StreamOldPosition(SoundNumber) = StreamPosition(SoundNumber) + Lng1 + Lng2
            StreamPosition(SoundNumber) = StreamRestartPos(SoundNumber) + ((Lng1 + Lng2) - (StreamLength(SoundNumber) - StreamPosition(SoundNumber) - 1))
        
        ElseIf IsLooping(SoundNumber) = False And StreamPosition(SoundNumber) + Lng1 + Lng2 >= StreamLength(SoundNumber) Then
        
            If StreamPosition(SoundNumber) < StreamLength(SoundNumber) Then
            
                'Seek to next data block
                Seek #StreamFileNum(SoundNumber), StreamStartPos(SoundNumber) + StreamPosition(SoundNumber)
                
                'Get last data block in file
                ReDim WaveData(1 To (StreamLength(SoundNumber) - StreamPosition(SoundNumber) - 1))
                Get #StreamFileNum(SoundNumber), , WaveData
                                
                ReDim Preserve WaveData(1 To Lng1 + Lng2)
                
                'Combine empty and first block
                For J = StreamLength(SoundNumber) - StreamPosition(SoundNumber) To Lng1 + Lng2
                
                    WaveData(J) = 0
                    
                Next
            
            Else
            
                ReDim WaveData(1 To Lng1 + Lng2)
                
                'Combine empty and first block
                For J = 1 To Lng1 + Lng2
                
                    WaveData(J) = 0
                    
                Next

            End If
            
            'Set new stream position
            StreamOldWriteCursor(SoundNumber) = IIf(Lng2 = 0, StreamWriteCursor(SoundNumber) + Lng1, Lng2)
            StreamOldPosition(SoundNumber) = StreamPosition(SoundNumber) + Lng1 + Lng2
            StreamPosition(SoundNumber) = StreamPosition(SoundNumber) + Lng1 + Lng2
        
        Else
                   
            'Seek to next block
            Seek #StreamFileNum(SoundNumber), StreamStartPos(SoundNumber) + StreamPosition(SoundNumber)
        
            ReDim WaveData(1 To (Lng1 + Lng2))
            Get #StreamFileNum(SoundNumber), , WaveData
            
            StreamPosition(SoundNumber) = StreamPosition(SoundNumber) + Lng1 + Lng2
         
        End If
        
        If Err.Number = DSERR_BUFFERLOST Then
            
            BufferOK = Private_RestoreStreamingBuffer(SoundNumber)
            
            If BufferOK = False Then
                
                ReDim WaveData(1 To 1)
                Exit Sub
            
            End If
        
        End If

        Call CopyMemory(Ptr1, VarPtr(WaveData(1)), Lng1)
        
        If Lng2 <> 0 Then
        
            Call CopyMemory(Ptr2, VarPtr(WaveData(Lng1 + 1)), Lng2)
        
        End If
        
        StreamWriteCursor(SoundNumber) = 0
                
        Call DirectSoundBuffer(SoundNumber).Unlock(Ptr1, Lng1, Ptr2, Lng2)
        
        If Playing = True Then
        
            DirectSoundBuffer(SoundNumber).Play 0, 0, DSBPLAY_LOOPING
            IsPlaying(SoundNumber) = True
        
        End If
        
    Else
        
        DirectSoundBuffer(SoundNumber).SetCurrentPosition Fix(Position / DirectSoundWaveFormat(SoundNumber).nBlockAlign) * DirectSoundWaveFormat(SoundNumber).nBlockAlign
    
    End If
    
End If

End Sub
Public Sub Buffer2D_SeekBufferToStart(SoundNumber As Integer)

If SoundOK = False Then

    Exit Sub

End If

On Error Resume Next

If SoundNumber <= MaxBuffers And SoundNumber >= 1 And SoundAvailable(SoundNumber) = False Then

    If IsStreaming(SoundNumber) Then
    
        Call Buffer2D_SetPosition(SoundNumber, 0)
    
    Else
    
        DirectSoundBuffer(SoundNumber).SetCurrentPosition 0
            
    End If
    
End If

End Sub
Public Function Buffer2D_GetStatus(SoundNumber As Integer) As Long

Buffer2D_GetStatus = 0

If SoundOK = False Then

    Exit Function

End If

On Error Resume Next

If SoundNumber <= MaxBuffers And SoundNumber >= 1 And SoundAvailable(SoundNumber) = False Then

    DirectSoundBuffer(SoundNumber).GetStatus Buffer2D_GetStatus

End If

End Function
Public Function Buffer2D_IsBufferStreaming(SoundNumber As Integer) As Boolean

Buffer2D_IsBufferStreaming = False

If SoundOK = False Then

    Exit Function

End If

If SoundNumber <= MaxBuffers And SoundNumber >= 1 And SoundAvailable(SoundNumber) = False Then

    Buffer2D_IsBufferStreaming = IsStreaming(SoundNumber)

End If

End Function
Public Function Buffer2D_GetFrequency(SoundNumber As Integer) As Long

Buffer2D_GetFrequency = 0

If SoundOK = False Then
    
    Exit Function

End If

On Error Resume Next

If SoundNumber <= MaxBuffers And SoundNumber >= 1 And SoundAvailable(SoundNumber) = False Then

    DirectSoundBuffer(SoundNumber).GetFrequency Buffer2D_GetFrequency

End If

End Function
Public Function Buffer2D_GetVolume(SoundNumber As Integer) As Long

Buffer2D_GetVolume = 0

If SoundOK = False Then
   
    Exit Function

End If

On Error Resume Next

If SoundNumber <= MaxBuffers And SoundNumber >= 1 And SoundAvailable(SoundNumber) = False Then

    DirectSoundBuffer(SoundNumber).GetVolume Buffer2D_GetVolume

End If

End Function
Public Function Buffer2D_GetPan(SoundNumber As Integer) As Long

Buffer2D_GetPan = 0

If SoundOK = False Then
   
    Exit Function

End If

On Error Resume Next

If SoundNumber <= MaxBuffers And SoundNumber >= 1 And SoundAvailable(SoundNumber) = False And Is3D(SoundNumber) = False Then

    DirectSoundBuffer(SoundNumber).GetPan Buffer2D_GetPan

End If

End Function
Public Sub Buffer2D_SetFrequency(SoundNumber As Integer, Frequency As Long)

If SoundOK = False Then

    Exit Sub

End If

On Error Resume Next

If SoundNumber <= MaxBuffers And SoundNumber >= 1 And SoundAvailable(SoundNumber) = False And (Frequency >= DSBFREQUENCY_MIN And Frequency <= DSBFREQUENCY_MAX) Or Frequency = DSBFREQUENCY_ORIGINAL Then

    DirectSoundBuffer(SoundNumber).SetFrequency Frequency
    
End If

End Sub
Public Function Init_UninitializeDirectSound() As Boolean

Init_UninitializeDirectSound = True

If SoundOK = False Then
    
    Exit Function

End If

Dim A As Integer

If Initialized = True Then

    For A = 1 To MaxBuffers
    
        If IsStreaming(A) = True And IsPlaying(A) = True Then
        
            PlayingStreams = PlayingStreams - 1
            
            If PlayingStreams <= 0 Then
            
                Scrap = KillTimer(UseForm.hwnd, 0)
        
            End If
        
        End If
            
        If SoundAvailable(A) = False And IsStreaming(A) = True Then Close #StreamFileNum(A)
        If SoundAvailable(A) = False Then Set DirectSoundBuffer(A) = Nothing
        If SoundAvailable(A) = False Then Set DirectSound3DBuffer(A) = Nothing
        SoundAvailable(A) = True
'ADDED 1999-03-09 by Luther Ananda Miller [redacted]
'        Call Private_FreeSoundNum(A)
        BuffersUsed = BuffersUsed - 1
'Note: do not call Private_FreeSoundNum here because it may change the number of array elements,
'and we are in a For loop already. Not sure if VB will look at MaxBuffers each time through the loop, or
'only once at the beginning.. also, no reason to deallocate the arrays in the loop... we will do it at the end.
        IsStreaming(A) = False
        IsPlaying(A) = False
        Is3D(A) = False
        IsLooping(A) = False
        StreamStartPos(A) = 0
        StreamLength(A) = 0
        StreamPlayCursor(A) = 0
        StreamWriteCursor(A) = 0
        StreamPosition(A) = 0
        StreamFileNum(A) = 0
    Next
    
'ADDED 1999-03-09 by Luther Ananda Miller [redacted]
    Call Private_ReAllocateArrays(0)
    
    'Clear primary buffer
    Set DirectSoundPrimaryBuffer = Nothing
    Set DirectSoundPrimary3DBuffer = Nothing
    
    Set DirectSound = Nothing 'Clear directsound
    Set UseForm = Nothing 'Clear the form reference
    
    Initialized = False
    SoundOK = False

End If

Init_UninitializeDirectSound = True
    
End Function
Public Function Init_InitializeDirectSound(ThisForm As Form) As Boolean

Dim DirectSoundGUID As GUID
Dim B As Integer

Init_InitializeDirectSound = False

On Error GoTo InitError

If Not Initialized Then
    
    'Create DirectSound
    On Error Resume Next
    
    Set UseForm = ThisForm

    Call DirectSoundCreate(DirectSoundGUID, DirectSound, Nothing)
     
'CHANGED 1999-03-09 Luther Ananda Miller [redacted]
    Call DirectSound.SetCooperativeLevel(UseForm.hwnd, DSSCL_PRIORITY)
'    Call DirectSound.SetCooperativeLevel(UseForm.hwnd, DSSCL_NORMAL)
    If Err.Number <> DS_OK Then GoTo InitError
    
    'Create Primary Sound Buffer
    DirectSoundBufferDesc.dwSize = Len(DirectSoundBufferDesc)
    DirectSoundBufferDesc.dwBufferBytes = 0
    DirectSoundBufferDesc.lpwfxFormat = 0
    DirectSoundBufferDesc.dwFlags = DSBCAPS_CTRLVOLUME Or DSBCAPS_CTRL3D Or DSBCAPS_PRIMARYBUFFER

    DirectSound.CreateSoundBuffer DirectSoundBufferDesc, DirectSoundPrimaryBuffer, Nothing
    If Err.Number <> DS_OK Then GoTo InitError

    Set DirectSoundPrimary3DBuffer = DirectSoundPrimaryBuffer

    DirectSoundPrimary3DBuffer.SetVelocity 0, 0, 0, DS3D_IMMEDIATE
    DirectSoundPrimary3DBuffer.SetPosition 0, 0, 0, DS3D_IMMEDIATE
    DirectSoundPrimary3DBuffer.SetDopplerFactor 1, DS3D_IMMEDIATE
    DirectSoundPrimary3DBuffer.SetRolloffFactor 1, DS3D_IMMEDIATE
    DirectSoundPrimary3DBuffer.SetOrientation 0, 0, 1#, 0, 1#, 0, DS3D_IMMEDIATE
    If Err.Number <> DS_OK Then GoTo InitError

'CHANGED 1999-03-09 Luther Ananda Miller [redacted]
    MaxBuffers = 0
    Call Private_ReAllocateArrays(DEFAULT_MAX_BUFFERS)
    
'LAM -- this is now done in ReAllocateArrays
'    For B = 1 To MaxBuffers
'
'        SoundAvailable(B) = True
'
'    Next
    
    'Set initialization settings
    SoundOK = True
    Initialized = True
    
End If

Init_InitializeDirectSound = True
Exit Function

InitError:

'Unable to initialize DirectSound error
Set DirectSound = Nothing
Set DirectSoundPrimaryBuffer = Nothing
Set DirectSoundPrimary3DBuffer = Nothing
SoundOK = False
Init_InitializeDirectSound = False
Initialized = False
Exit Function

End Function
Public Function General_LoadStreamSound(FileName As String, Use3D As Boolean, BufferTime As Long, Optional DataOffset As Variant, Optional DataLength As Variant) As Integer

General_LoadStreamSound = -1

If SoundOK = False Then
    
    Exit Function

End If

On Error Resume Next

Dim NextBuffer As Integer
Dim SoundNum As Integer
Dim Pos As Integer
Dim WaveData() As Byte
Dim Ptr1 As Long
Dim Lng1 As Long
Dim Ptr2 As Long
Dim Lng2 As Long
Dim TempBuffer As IDirectSoundBuffer
Dim WaveF As WAVEFORMATEX
Dim DSBuffer As DSBUFFERDESC
Dim LoadSize As Integer
Dim Times As Integer
Dim Status As Long

NextBuffer = Private_NextAvailableBuffer

If NextBuffer = -1 Then

    'No valid buffer available, exit function
    General_LoadStreamSound = NextBuffer
    Exit Function
    
Else

    SoundNum = NextBuffer
    
End If

'Data load values
Times = 1
LoadSize = 16384 'Size of data blocks to get from file

RetryLoad:

StreamFileNum(SoundNum) = FreeFile

'Open wav file
Open FileName For Binary As #StreamFileNum(SoundNum)
    
    If IsMissing(DataOffset) = False Then Seek #StreamFileNum(SoundNum), DataOffset
    ReDim WaveData(1 To LoadSize * Times)
    Get #StreamFileNum(SoundNum), , WaveData

Pos = 1
    
While Chr$(WaveData(Pos)) + Chr$(WaveData(Pos + 1)) + Chr$(WaveData(Pos + 2)) <> "fmt"
    
    Pos = Pos + 1
    
    If Pos >= LoadSize - 16 - Len(WaveF) Then  'If insuficient data resize block and reload data
        
        Times = Times + 1
        Close #StreamFileNum(SoundNum)
        GoTo RetryLoad
    
    End If
    
Wend

Call CopyMemory(VarPtr(WaveF), VarPtr(WaveData(Pos + 8)), Len(WaveF))

If (WaveF.nAvgBytesPerSec * BufferTime) > DSBSIZE_MAX Or (WaveF.nAvgBytesPerSec * BufferTime) < DSBSIZE_MIN Then Exit Function

'If wave data is not larger than the buffer, create static buffer instead
If (WaveF.nAvgBytesPerSec * BufferTime) >= LOF(StreamFileNum(SoundNum)) Then

    Close #StreamFileNum(SoundNum)
    ReDim WaveData(1 To 1)
    General_LoadStreamSound = General_LoadStaticSound(FileName, Use3D, DataOffset, DataLength)
    Exit Function

End If

While Chr$(WaveData(Pos)) + Chr$(WaveData(Pos + 1)) + Chr$(WaveData(Pos + 2)) + Chr$(WaveData(Pos + 3)) <> "data"
    
    Pos = Pos + 1
    
    'If insufficient data to find wav data start try again
    If Pos >= LoadSize - 8 Then
        
        Times = Times + 1
        Close #StreamFileNum(SoundNum)
        GoTo RetryLoad
    
    End If
    
Wend

'Set Stream info
If IsMissing(DataLength) = True And IsMissing(DataOffset) = True Then

    StreamStartPos(SoundNum) = Pos + 8
    StreamRestartPos(SoundNum) = 0
    
    StreamLength(SoundNum) = LOF(StreamFileNum(SoundNum)) - StreamStartPos(SoundNum)

ElseIf IsMissing(DataOffset) = True And IsMissing(DataLength) = False Then

    StreamStartPos(SoundNum) = Pos + 8
    StreamRestartPos(SoundNum) = 0
    
    StreamLength(SoundNum) = DataLength - (StreamStartPos(SoundNum) - DataOffset)

ElseIf IsMissing(DataOffset) = False And IsMissing(DataLength) = True Then

    StreamStartPos(SoundNum) = DataOffset + Pos + 8 + 1
    StreamRestartPos(SoundNum) = 0
    
    StreamLength(SoundNum) = LOF(StreamFileNum(SoundNum)) - StreamStartPos(SoundNum)

Else

    StreamStartPos(SoundNum) = DataOffset + Pos + 8 + 1
    StreamRestartPos(SoundNum) = 0
    
    StreamLength(SoundNum) = DataLength - (StreamStartPos(SoundNum) - DataOffset)

End If

'Setup buffer info
DSBuffer.dwSize = Len(DSBuffer)
DSBuffer.dwFlags = IIf(Use3D = True, DSBCAPS_CTRL3D, DSBCAPS_CTRLPAN) Or DSBCAPS_CTRLVOLUME Or DSBCAPS_CTRLFREQUENCY Or DSBCAPS_GETCURRENTPOSITION2 Or DSBCAPS_GLOBALFOCUS Or DSBCAPS_STICKYFOCUS Or DSBCAPS_CTRLPOSITIONNOTIFY
DSBuffer.dwBufferBytes = WaveF.nAvgBytesPerSec * BufferTime
DSBuffer.lpwfxFormat = VarPtr(WaveF)

DirectSound.CreateSoundBuffer DSBuffer, TempBuffer, Nothing 'Create buffer
If Err.Number <> DS_OK Then Exit Function

'Set buffer info
DirectSoundBufferDescription(SoundNum) = DSBuffer
DirectSoundWaveFormat(SoundNum) = WaveF
DirectSoundBufferFileName(SoundNum) = FileName

TempBuffer.SetCurrentPosition 0
If Err.Number <> DS_OK Then Exit Function

'Read initial data into buffer
Seek #StreamFileNum(SoundNum), StreamStartPos(SoundNum)
ReDim WaveData(1 To DirectSoundBufferDescription(SoundNum).dwBufferBytes)
Get #StreamFileNum(SoundNum), , WaveData

TempBuffer.GetStatus Status
If Err.Number <> DS_OK Then Exit Function

If Status = DSBSTATUS_BUFFERLOST Then

    Set TempBuffer = Nothing
    Exit Function

End If

Call TempBuffer.Lock(0&, DirectSoundBufferDescription(SoundNum).dwBufferBytes, Ptr1, Lng1, Ptr2, Lng2, 0&)

Call CopyMemory(Ptr1, VarPtr(WaveData(1)), Lng1)

If Lng2 <> 0 Then

    Call CopyMemory(Ptr2, VarPtr(WaveData(Lng1 + 1)), Lng2)

End If

StreamPosition(SoundNum) = Lng1 + Lng2
StreamWriteCursor(SoundNum) = 0

Call TempBuffer.Unlock(Ptr1, Lng1, Ptr2, Lng2)

'Set actual buffer from temp buffer
Set DirectSoundBuffer(SoundNum) = TempBuffer

If Use3D = True Then 'If 3D is used set 3D buffer

    Set DirectSound3DBuffer(SoundNum) = TempBuffer
            
End If

'Clear sound resource
ReDim WaveData(1 To 1)

'Set sound settings
Is3D(SoundNum) = Use3D
IsPlaying(SoundNum) = False
IsStreaming(SoundNum) = True
IsUpdating(SoundNum) = False
SoundAvailable(SoundNum) = False
'ADDED 1999-03-09 by Luther Ananda Miller [redacted]
BuffersUsed = BuffersUsed + 1

General_LoadStreamSound = SoundNum

End Function
Public Function General_LoadStaticSound(FileName As String, Use3D As Boolean, Optional DataOffset As Variant, Optional DataLength As Variant) As Integer

General_LoadStaticSound = -1

If SoundOK = False Then
    
    Exit Function

End If

On Error Resume Next

Dim NextBuffer As Integer
Dim SoundNum As Integer
Dim N As Integer
Dim Pos As Integer
Dim WaveData() As Byte
Dim Ptr1 As Long
Dim Lng1 As Long
Dim Ptr2 As Long
Dim Lng2 As Long
Dim TempBuffer As IDirectSoundBuffer
Dim WaveF As WAVEFORMATEX
Dim DSBuffer As DSBUFFERDESC
Dim Status As Long

NextBuffer = Private_NextAvailableBuffer

If NextBuffer = -1 Then

    'No valid buffer available, exit function
    General_LoadStaticSound = NextBuffer
    Exit Function
    
Else

    SoundNum = NextBuffer
    
End If

N = FreeFile

'ADDED 1999-03-09 Luther Ananda Miller [redacted]
DataLengths(SoundNum) = IIf(IsMissing(DataLength), -1, DataLength)

'Open wav file
Open FileName For Binary As #N

    If LOF(N) > DSBSIZE_MAX Or LOF(N) < DSBSIZE_MIN Then
    
        Close #N
        Exit Function
        
    End If
    
    If IsMissing(DataOffset) = False Then Seek #N, DataOffset
    ReDim WaveData(1 To IIf(IsMissing(DataLength) = True, LOF(N) - IIf(IsMissing(DataOffset) = True, 0, DataOffset), DataLength))
    Get #N, , WaveData

Close #N

'This info used only to restore lost buffers
If IsMissing(DataOffset) = True Then

    StreamStartPos(SoundNum) = 0
    
Else

    StreamStartPos(SoundNum) = DataOffset
    
End If

StreamLength(SoundNum) = UBound(WaveData)
DirectSoundBufferFileOffset(SoundNum) = IIf(IsMissing(DataOffset) = True, 0, DataOffset)

Pos = 1
    
While Chr$(WaveData(Pos)) + Chr$(WaveData(Pos + 1)) + Chr$(WaveData(Pos + 2)) <> "fmt"
    
    Pos = Pos + 1
    
Wend

'Extract wav format from data
Call CopyMemory(VarPtr(WaveF), VarPtr(WaveData(Pos + 8)), Len(WaveF))

While Chr$(WaveData(Pos)) + Chr$(WaveData(Pos + 1)) + Chr$(WaveData(Pos + 2)) + Chr$(WaveData(Pos + 3)) <> "data"
    
    Pos = Pos + 1

Wend

'Setup buffer info
DSBuffer.dwSize = Len(DSBuffer)
DSBuffer.dwFlags = IIf(Use3D = True, DSBCAPS_CTRL3D, DSBCAPS_CTRLPAN) Or DSBCAPS_CTRLVOLUME Or DSBCAPS_CTRLFREQUENCY Or DSBCAPS_STATIC Or DSBCAPS_GETCURRENTPOSITION2 Or DSBCAPS_GLOBALFOCUS Or DSBCAPS_STICKYFOCUS
DSBuffer.dwBufferBytes = UBound(WaveData) - (Pos + 8)
DSBuffer.lpwfxFormat = VarPtr(WaveF)

DirectSound.Compact
DirectSound.CreateSoundBuffer DSBuffer, TempBuffer, Nothing 'Create buffer
If Err.Number <> DS_OK Then Exit Function

'Lock buffer, copy wav data into buffer, unlock buffer
TempBuffer.GetStatus Status
If Err.Number <> DS_OK Then Exit Function

If Status = DSBSTATUS_BUFFERLOST Then

    Set TempBuffer = Nothing
    Exit Function

End If

Call TempBuffer.Lock(0&, DSBuffer.dwBufferBytes, Ptr1, Lng1, Ptr2, Lng2, 0&)
If Err.Number <> DS_OK Then Exit Function

Call CopyMemory(Ptr1, VarPtr(WaveData(Pos + 8)), Lng1)

If Lng2 <> 0 Then

    Call CopyMemory(Ptr2, VarPtr(WaveData(Pos + 8 + Lng1 + 1)), Lng2)

End If

Call TempBuffer.Unlock(Ptr1, Lng1, Ptr2, Lng2)

Set DirectSoundBuffer(SoundNum) = TempBuffer 'Set main buffer

If Use3D = True Then 'If 3D wanted set 3D buffer and set position

    Set DirectSound3DBuffer(SoundNum) = TempBuffer
            
End If

'Set buffer info
DirectSoundBufferDescription(SoundNum) = DSBuffer
DirectSoundWaveFormat(SoundNum) = WaveF
DirectSoundBufferFileName(SoundNum) = FileName

DirectSound.Compact
If Err.Number <> DS_OK Then Exit Function

'Clear sound resource
ReDim WaveData(1 To 1)

'Set sound settings
Is3D(SoundNum) = Use3D
IsPlaying(SoundNum) = False
IsStreaming(SoundNum) = False
SoundAvailable(SoundNum) = False
'ADDED 1999-03-09 by Luther Ananda Miller [redacted]
BuffersUsed = BuffersUsed + 1

General_LoadStaticSound = SoundNum

End Function

'ADDED 1999-03-09 Luther Ananda Miller [redacted]
'Attempts to duplicate existing buffer (so sound can play twice or more simultaneously)
'If that fails, calls LoadStaticSound
Public Function General_DuplicateOrLoadStaticSound(SoundNum1 As Integer, _
        Optional ByVal LoadIfDuplicateFails As Boolean = True) As Integer

General_DuplicateOrLoadStaticSound = -1

If SoundOK = False Then
    
    Exit Function

End If

On Error Resume Next

Dim NextBuffer As Integer
Dim SoundNum As Integer
Dim TempBuffer As IDirectSoundBuffer
Dim Use3D As Boolean

NextBuffer = Private_NextAvailableBuffer

If NextBuffer = -1 Then

    'No valid buffer available, exit function
    General_DuplicateOrLoadStaticSound = NextBuffer
    Exit Function
    
Else

    SoundNum = NextBuffer
    
End If

DirectSound.DuplicateSoundBuffer DirectSoundBuffer(SoundNum1), TempBuffer 'Create buffer
If Err.Number = DS_OK Then
    Set DirectSoundBuffer(SoundNum) = TempBuffer 'Set main buffer
    If Is3D(SoundNum1) Then
        Set DirectSound3DBuffer(SoundNum) = TempBuffer
    End If
    StreamStartPos(SoundNum) = StreamStartPos(SoundNum1)
    StreamLength(SoundNum) = StreamLength(SoundNum1)
    DirectSoundBufferFileOffset(SoundNum) = DirectSoundBufferFileOffset(SoundNum1)
    
    'Set buffer info
    DirectSoundBufferDescription(SoundNum) = DirectSoundBufferDescription(SoundNum1)
    DirectSoundWaveFormat(SoundNum) = DirectSoundWaveFormat(SoundNum1)
    DirectSoundBufferFileName(SoundNum) = DirectSoundBufferFileName(SoundNum1)
    
    'Set sound settings
    Is3D(SoundNum) = Is3D(SoundNum1)
    IsPlaying(SoundNum) = False
    IsStreaming(SoundNum) = False
    SoundAvailable(SoundNum) = False
'ADDED 1999-03-09 by Luther Ananda Miller [redacted]
    BuffersUsed = BuffersUsed + 1
    General_DuplicateOrLoadStaticSound = SoundNum

ElseIf LoadIfDuplicateFails Then
    'call the loader to create a new buffer
    If DataLengths(SoundNum1) > -1 Then
        General_DuplicateOrLoadStaticSound = General_LoadStaticSound( _
            DirectSoundBufferFileName(SoundNum1), Is3D(SoundNum1), _
            DirectSoundBufferFileOffset(SoundNum1), _
            DataLengths(SoundNum1))
    Else
        General_DuplicateOrLoadStaticSound = General_LoadStaticSound( _
            DirectSoundBufferFileName(SoundNum1), Is3D(SoundNum1), _
            DirectSoundBufferFileOffset(SoundNum1))
    End If
End If

End Function


Public Sub General_DeleteSound(SoundNumber As Integer)

If SoundOK = False Then

    Exit Sub

End If

If SoundNumber <= MaxBuffers And SoundNumber >= 1 And SoundAvailable(SoundNumber) = False Then
    
    'Clear Settings and ram
    If IsStreaming(SoundNumber) = True And IsPlaying(SoundNumber) = True Then
    
        PlayingStreams = PlayingStreams - 1
        
        If PlayingStreams <= 0 Then
        
            Scrap = KillTimer(UseForm.hwnd, 0)
    
        End If
    
    End If
    
    If SoundAvailable(SoundNumber) = False And IsStreaming(SoundNumber) = True Then Close #StreamFileNum(SoundNumber)
    If SoundAvailable(SoundNumber) = False Then Set DirectSoundBuffer(SoundNumber) = Nothing
    If SoundAvailable(SoundNumber) = False Then Set DirectSound3DBuffer(SoundNumber) = Nothing
'CHANGED 1999-03-09 by Luther Ananda Miller [redacted]
'taken care of below in Private_FreeSoundNum --- must not be True before that call!
'    SoundAvailable(SoundNumber) = True
    Is3D(SoundNumber) = False
    IsLooping(SoundNumber) = False
    IsStreaming(SoundNumber) = False
    StreamStartPos(SoundNumber) = 0
    StreamLength(SoundNumber) = 0
    StreamPlayCursor(SoundNumber) = 0
    StreamWriteCursor(SoundNumber) = 0
    StreamPosition(SoundNumber) = 0
    StreamFileNum(SoundNumber) = 0
    IsPlaying(SoundNumber) = False
'ADDED 1999-03-09 by Luther Ananda Miller [redacted]
    Call Private_FreeSoundNum(SoundNumber)
    
End If

End Sub
Public Sub Primary_SetFormat(Frequency As Long, Bits As Byte, Channels As Byte)

If SoundOK = False Then

    Exit Sub

End If

On Error Resume Next

If (Frequency = 44100 Or Frequency = 22050 Or Frequency = 11025) And (Bits = 8 Or Bits = 16) And (Channels = 1 Or Channels = 2) Then

    SetWaveFormat.wFormatTag = WAVE_FORMAT_PCM
    SetWaveFormat.wBitsPerSample = Bits
    SetWaveFormat.nSamplesPerSec = Frequency
    SetWaveFormat.nChannels = Channels
    SetWaveFormat.nBlockAlign = (Channels * Bits) / 8
    SetWaveFormat.nAvgBytesPerSec = SetWaveFormat.nBlockAlign * Frequency
    
    DirectSoundPrimaryBuffer.SetFormat SetWaveFormat
    
End If

End Sub
Public Function DSound_GetSpeakerConfig() As Long

DSound_GetSpeakerConfig = DSSPEAKER_STEREO

If SoundOK = False Then

    Exit Function

End If

On Error Resume Next

DirectSound.GetSpeakerConfig DSound_GetSpeakerConfig

End Function
Public Sub DSound_SetSpeakerConfig(Speaker As Long)

If SoundOK = False Then

    Exit Sub

End If

On Error Resume Next

DirectSound.SetSpeakerConfig Speaker

End Sub
Public Sub Buffer2D_SetPan(SoundNumber As Integer, Pan As Long)

If SoundOK = False Then

    Exit Sub

End If

On Error Resume Next

If SoundNumber <= MaxBuffers And SoundNumber >= 1 And SoundAvailable(SoundNumber) = False And Is3D(SoundNumber) = False And Pan >= DSBPAN_LEFT And Pan <= DSBPAN_RIGHT Then

    DirectSoundBuffer(SoundNumber).SetPan Pan

End If

End Sub
Public Sub Buffer2D_SetVolume(SoundNumber As Integer, Volume As Long)

If SoundOK = False Then

    Exit Sub

End If

On Error Resume Next

If SoundNumber <= MaxBuffers And SoundNumber >= 1 And SoundAvailable(SoundNumber) = False And Volume <= DSBVOLUME_MAX And Volume >= DSBVOLUME_MIN Then

    DirectSoundBuffer(SoundNumber).SetVolume Volume

End If

End Sub
Public Sub General_PlaySound(SoundNumber As Integer, Looping As Boolean)

If SoundOK = False Then

    Exit Sub

End If

On Error Resume Next

Dim Status As Long
Dim BufferOK As Boolean

If SoundNumber <= MaxBuffers And SoundNumber >= 1 And SoundAvailable(SoundNumber) = False Then

    If IsStreaming(SoundNumber) = True Then 'Streaming buffers

        DirectSoundBuffer(SoundNumber).GetStatus Status
        
        If Status = DSBSTATUS_BUFFERLOST Then
        
            BufferOK = Private_RestoreStreamingBuffer(SoundNumber)
            If BufferOK = False Then Exit Sub

        End If
        
        PlayingStreams = PlayingStreams + 1
        
        If PlayingStreams <= 1 Then
        
            Scrap = SetTimer(UseForm.hwnd, 0, UpdateInterval, AddressOf Private_UpdateStreams)

        End If
        
        IsLooping(SoundNumber) = Looping

        DirectSoundBuffer(SoundNumber).Play 0, 0, DSBPLAY_LOOPING
        
        If Err.Number = DSERR_BUFFERLOST Then
            
            BufferOK = Private_RestoreStreamingBuffer(SoundNumber)
            If BufferOK = False Then Exit Sub
        
        End If
        
        IsPlaying(SoundNumber) = True
    
    Else 'Static buffers
            
        DirectSoundBuffer(SoundNumber).GetStatus Status
        
        If Status = DSBSTATUS_BUFFERLOST Then
        
            BufferOK = Private_RestoreStaticBuffer(SoundNumber)
            If BufferOK = False Then Exit Sub

        End If
        
        DirectSoundBuffer(SoundNumber).Play 0, 0, IIf(Looping = True, DSBPLAY_LOOPING, 0)
                
        If Err.Number = DSERR_BUFFERLOST Then
            
            BufferOK = Private_RestoreStreamingBuffer(SoundNumber)
            If BufferOK = False Then Exit Sub
        
        End If

        IsPlaying(SoundNumber) = True
        
    End If
    
End If

End Sub
Public Sub General_PauseSound(SoundNumber As Integer)

If SoundOK = False Then

    Exit Sub

End If

On Error Resume Next

If SoundNumber <= MaxBuffers And SoundNumber >= 1 And SoundAvailable(SoundNumber) = False Then

    If IsStreaming(SoundNumber) = True Then 'Streaming buffer
    
        DirectSoundBuffer(SoundNumber).Stop
        
        If IsPlaying(SoundNumber) Then
        
            PlayingStreams = PlayingStreams - 1

            If PlayingStreams <= 0 Then

                Scrap = KillTimer(UseForm.hwnd, 0)

            End If
            
        End If
        
        IsPlaying(SoundNumber) = False
        
    Else 'Static buffer
    
        DirectSoundBuffer(SoundNumber).Stop
        IsPlaying(SoundNumber) = False
        
    End If
    
End If

End Sub
Public Sub General_StopSound(SoundNumber As Integer)

If SoundOK = False Then

    Exit Sub

End If

On Error Resume Next

Dim WaveData() As Byte
Dim Ptr1 As Long
Dim Lng1 As Long
Dim Ptr2 As Long
Dim Lng2 As Long
Dim Status As Long
Dim BufferOK As Boolean

If SoundNumber <= MaxBuffers And SoundNumber >= 1 And SoundAvailable(SoundNumber) = False Then

    If IsStreaming(SoundNumber) = True Then 'Streaming buffer
    
        DirectSoundBuffer(SoundNumber).Stop
        DirectSoundBuffer(SoundNumber).SetCurrentPosition 0
        
        If IsPlaying(SoundNumber) Then
        
            PlayingStreams = PlayingStreams - 1
            
            If PlayingStreams <= 0 Then
            
                Scrap = KillTimer(UseForm.hwnd, 0)
    
            End If
        
        End If
        
        'Load initial buffer data
        Seek #StreamFileNum(SoundNumber), StreamStartPos(SoundNumber)
        ReDim WaveData(1 To DirectSoundBufferDescription(SoundNumber).dwBufferBytes)
        Get #StreamFileNum(SoundNumber), , WaveData
        
        DirectSoundBuffer(SoundNumber).GetStatus Status
        
        If Status = DSBSTATUS_BUFFERLOST Then
        
            BufferOK = Private_RestoreStreamingBuffer(SoundNumber)
            
            If BufferOK = False Then
                
                ReDim WaveData(1 To 1)
                Exit Sub
            
            End If
            
        End If
        
        Call DirectSoundBuffer(SoundNumber).Lock(0&, DirectSoundBufferDescription(SoundNumber).dwBufferBytes, Ptr1, Lng1, Ptr2, Lng2, 0&)
        
        If Err.Number = DSERR_BUFFERLOST Then
            
            BufferOK = Private_RestoreStreamingBuffer(SoundNumber)
            
            If BufferOK = False Then
                
                ReDim WaveData(1 To 1)
                Exit Sub
            
            End If
        
        End If

        Call CopyMemory(Ptr1, VarPtr(WaveData(1)), Lng1)
        
        If Lng2 <> 0 Then
        
            Call CopyMemory(Ptr2, VarPtr(WaveData(Lng1 + 1)), Lng2)
        
        End If
        
        StreamPosition(SoundNumber) = Lng1 + Lng2
        StreamWriteCursor(SoundNumber) = 0
                
        Call DirectSoundBuffer(SoundNumber).Unlock(Ptr1, Lng1, Ptr2, Lng2)
        
        IsPlaying(SoundNumber) = False
    
    Else 'Static buffers
    
        DirectSoundBuffer(SoundNumber).Stop
        DirectSoundBuffer(SoundNumber).SetCurrentPosition 0
        IsPlaying(SoundNumber) = False
        
    End If
    
End If

End Sub
Private Function Private_NextAvailableBuffer() As Integer

Private_NextAvailableBuffer = -1

If SoundOK = False Then
    
    Exit Function

End If

Dim A As Integer
Dim SoundNum As Integer

SoundNum = -1 'Value returned if no available buffers exist

'ADDED 1999-03-09 by Luther Ananda Miller [redacted]
'allocate more space in the arrays if we need to! no hardcoded limits!
If BuffersUsed >= MaxBuffers Then

    Call Private_ReAllocateArrays(MaxBuffers + ALLOCATE_CHUNK%)

End If


For A = 1 To MaxBuffers 'Check for free buffers

    If SoundAvailable(A) = True Then
    
        SoundNum = A
        Exit For
    
    End If
    
Next

Private_NextAvailableBuffer = SoundNum

End Function

'ADDED 1999-03-09 by Luther Ananda Miller [redacted]
'free buffers in one place and allow to reduce the array size
Private Sub Private_FreeSoundNum(SoundNum As Integer)
    
    If SoundOK = False Then
        
        Exit Sub
    
    End If
    
    If Not SoundAvailable(SoundNum) Then
        BuffersUsed = BuffersUsed - 1
        SoundAvailable(SoundNum) = True
    End If
    
    'If we only have ALLOCATE_CHUNK or less buffers allocated, then don't bother deallocating
    If MaxBuffers <= ALLOCATE_CHUNK Then
        Exit Sub
    End If
    
    'Now check to see if we can deallocate....
    
    Dim liCtr As Integer
    Dim liDeallocateBufferCount As Integer
    Dim liNumberToDeallocate As Integer
    
    liDeallocateBufferCount = 0
    'We can't change the SoundNum of any allocated buffers--
    'therefore we can only deallocate the arrays if there are free
    'entries on the end.
    For liCtr = MaxBuffers To (ALLOCATE_CHUNK% + 1) Step -1
        If SoundAvailable(liCtr) = True Then
            liDeallocateBufferCount = liDeallocateBufferCount + 1
        Else
            Exit For
        End If
    Next liCtr
    
    'Only deallocate if there are at least ALLOCATE_CHUNK free buffers at the end of the arrays
    If liDeallocateBufferCount >= ALLOCATE_CHUNK Then
        'Deallocate in whole chunks only
        liNumberToDeallocate = Int(liDeallocateBufferCount / ALLOCATE_CHUNK) * ALLOCATE_CHUNK
        'Deallocate! (MaxBuffers is changed inside the call- do not change here!)
        Call Private_ReAllocateArrays(MaxBuffers - liNumberToDeallocate)
    End If
    
End Sub

Public Sub Private_UpdateStreams()

If SoundOK = False Then

    Exit Sub

End If

On Error Resume Next

Dim Status As Long
Dim BufferOK As Boolean
Dim F As Integer
Dim J As Long
Dim WaveData() As Byte
Dim WaveDataTemp() As Byte
Dim Ptr1 As Long
Dim Lng1 As Long
Dim Ptr2 As Long
Dim Lng2 As Long

For F = 1 To MaxBuffers
    
    BufferOK = True
    'Do update only on playing streaming buffers
    If IsStreaming(F) And IsPlaying(F) Then
        
        IsUpdating(F) = True
        
        'Get current position in stream
        DirectSoundBuffer(F).GetCurrentPosition StreamPlayCursor(F), CLng(Scrap)
        
        'Lock buffer
        DirectSoundBuffer(F).GetStatus Status
        
        If Status = DSBSTATUS_BUFFERLOST Then BufferOK = Private_RestoreStreamingBuffer(F)
            
        If BufferOK = True Then

            Call DirectSoundBuffer(F).Lock(StreamWriteCursor(F), IIf(StreamWriteCursor(F) < StreamPlayCursor(F), StreamPlayCursor(F) - StreamWriteCursor(F), (DirectSoundBufferDescription(F).dwBufferBytes - StreamWriteCursor(F)) + StreamPlayCursor(F)), Ptr1, Lng1, Ptr2, Lng2, 0&)
            If Err.Number <> DS_OK Then GoTo EndFor
            
            If IsLooping(F) = True And StreamPosition(F) + Lng1 + Lng2 >= StreamLength(F) Then
            
                'Seek to next data block
                Seek #StreamFileNum(F), StreamStartPos(F) + StreamPosition(F)
                
                'Get last data block in file
                ReDim WaveData(1 To (StreamLength(F) - StreamPosition(F) - 1))
                Get #StreamFileNum(F), , WaveData
                                
                ReDim Preserve WaveData(1 To Lng1 + Lng2)
                
                'Seek to start of file (or restart pos)
                Seek #StreamFileNum(F), StreamStartPos(F) + StreamRestartPos(F)
                
                'Get first data block
                ReDim WaveDataTemp(StreamLength(F) - StreamPosition(F) To Lng1 + Lng2)
                Get #StreamFileNum(F), , WaveDataTemp
                
                'Combine last and first blocks
                For J = StreamLength(F) - StreamPosition(F) To Lng1 + Lng2
                
                    WaveData(J) = WaveDataTemp(J)
                    
                Next
                
                'Set new stream position
                StreamOldWriteCursor(F) = IIf(Lng2 = 0, StreamWriteCursor(F) + Lng1, Lng2)
                StreamOldPosition(F) = StreamPosition(F) + Lng1 + Lng2
                StreamPosition(F) = StreamRestartPos(F) + ((Lng1 + Lng2) - (StreamLength(F) - StreamPosition(F) - 1))
            
            ElseIf IsLooping(F) = False And StreamPosition(F) + Lng1 + Lng2 >= StreamLength(F) Then
            
                If StreamPosition(F) < StreamLength(F) Then
                
                    'Seek to next data block
                    Seek #StreamFileNum(F), StreamStartPos(F) + StreamPosition(F)
                    
                    'Get last data block in file
                    ReDim WaveData(1 To (StreamLength(F) - StreamPosition(F) - 1))
                    Get #StreamFileNum(F), , WaveData
                                    
                    ReDim Preserve WaveData(1 To Lng1 + Lng2)
                    
                    'Combine empty and first block
                    For J = StreamLength(F) - StreamPosition(F) To Lng1 + Lng2
                    
                        WaveData(J) = 0
                        
                    Next
                
                Else
                
                    ReDim WaveData(1 To Lng1 + Lng2)
                    
                    'Combine empty and first block
                    For J = 1 To Lng1 + Lng2
                    
                        WaveData(J) = 0
                        
                    Next

                End If
                
                'Set new stream position
                StreamOldWriteCursor(F) = IIf(Lng2 = 0, StreamWriteCursor(F) + Lng1, Lng2)
                StreamOldPosition(F) = StreamPosition(F) + Lng1 + Lng2
                StreamPosition(F) = StreamPosition(F) + Lng1 + Lng2
            
            Else 'For data that does not exced end of stream
                       
                    'Seek to next block
                    Seek #StreamFileNum(F), StreamStartPos(F) + StreamPosition(F)
                
                    ReDim WaveData(1 To (Lng1 + Lng2))
                    Get #StreamFileNum(F), , WaveData
             
                    'Set new stream position
                    StreamPosition(F) = StreamPosition(F) + Lng1 + Lng2
                    
            End If
            
            'Copy data to buffer
            Call CopyMemory(Ptr1, VarPtr(WaveData(1)), Lng1)
            
            'Copy extra data if buffer wraps around
            If Lng2 <> 0 Then
                
                Call CopyMemory(Ptr2, VarPtr(WaveData(Lng1 + 1)), Lng2)
                
            End If
            
            'Set new write cursor position
            StreamWriteCursor(F) = IIf(Lng2 = 0, StreamWriteCursor(F) + Lng1, Lng2)

            'Unlock buffer
            Call DirectSoundBuffer(F).Unlock(Ptr1, Lng1, Ptr2, Lng2)
            
            'Clear memory
            ReDim WaveData(1 To 1)
            ReDim WaveDataTemp(1 To 1)

            'If buffer is not looping and at the end of wav data
            If IsLooping(F) = False And StreamPosition(F) > StreamLength(F) + DirectSoundBufferDescription(F).dwBufferBytes Then
                                
                General_StopSound (F)
                
            End If

        End If
        
    IsUpdating(F) = False
    
    End If
    
EndFor:

Next

End Sub
Private Function Private_RestoreStaticBuffer(SoundNum As Integer) As Boolean

Private_RestoreStaticBuffer = False

If SoundOK = False Then
    
    Exit Function

End If

On Error Resume Next

Dim N As Integer
Dim Pos As Integer
Dim WaveData() As Byte
Dim Ptr1 As Long
Dim Lng1 As Long
Dim Ptr2 As Long
Dim Lng2 As Long
Dim Status As Long

DirectSoundBuffer(SoundNum).Restore

DirectSoundBuffer(SoundNum).GetStatus Status

If Status = DSBSTATUS_BUFFERLOST Then

    Exit Function
    
End If

'Open sound file
N = FreeFile

Open DirectSoundBufferFileName(SoundNum) For Binary As #N

Seek #N, StreamStartPos(SoundNum) + DirectSoundBufferFileOffset(SoundNum)
ReDim WaveData(1 To StreamLength(SoundNum))
Get #N, , WaveData

Close #N

Pos = 1

While Chr$(WaveData(Pos)) + Chr$(WaveData(Pos + 1)) + Chr$(WaveData(Pos + 2)) + Chr$(WaveData(Pos + 3)) <> "data"

    Pos = Pos + 1

Wend

DirectSound.Compact

'Lock buffer, copy wav data into buffer, unlock buffer
DirectSoundBuffer(SoundNum).GetStatus Status

If Status = DSBSTATUS_BUFFERLOST Then
        
    Exit Function
    
End If

Call DirectSoundBuffer(SoundNum).Lock(0&, DirectSoundBufferDescription(SoundNum).dwBufferBytes, Ptr1, Lng1, Ptr2, Lng2, 0&)
If Err.Number <> DS_OK Then Exit Function

Call CopyMemory(Ptr1, VarPtr(WaveData(Pos + 8)), Lng1)

If Lng2 <> 0 Then

    Call CopyMemory(Ptr2, VarPtr(WaveData(Pos + 8 + Lng1 + 1)), Lng2)

End If

Call DirectSoundBuffer(SoundNum).Unlock(Ptr1, Lng1, Ptr2, Lng2)

ReDim WaveData(1 To 1)

Private_RestoreStaticBuffer = True

End Function
Private Function Private_RestoreStreamingBuffer(SoundNum As Integer) As Boolean

Private_RestoreStreamingBuffer = False

If SoundOK = False Then
    
    Exit Function

End If

On Error Resume Next

Dim WaveData() As Byte
Dim Ptr1 As Long
Dim Lng1 As Long
Dim Ptr2 As Long
Dim Lng2 As Long
Dim Status As Long

If PlayingStreams >= 1 Then Scrap = KillTimer(UseForm.hwnd, 0)

DirectSoundBuffer(SoundNum).Restore

DirectSoundBuffer(SoundNum).GetStatus Status
        
If Status = DSBSTATUS_BUFFERLOST Then
                
    Exit Function

End If

DirectSoundBuffer(SoundNum).SetCurrentPosition 0

'Load initial buffer data
Seek #StreamFileNum(SoundNum), StreamStartPos(SoundNum)
ReDim WaveData(1 To DirectSoundBufferDescription(SoundNum).dwBufferBytes)
Get #StreamFileNum(SoundNum), , WaveData

DirectSoundBuffer(SoundNum).GetStatus Status
        
If Status = DSBSTATUS_BUFFERLOST Then
                
    Exit Function

End If

Call DirectSoundBuffer(SoundNum).Lock(0&, DirectSoundBufferDescription(SoundNum).dwBufferBytes, Ptr1, Lng1, Ptr2, Lng2, 0&)
If Err.Number <> DS_OK Then Exit Function

Call CopyMemory(Ptr1, VarPtr(WaveData(1)), Lng1)

If Lng2 <> 0 Then

    Call CopyMemory(Ptr2, VarPtr(WaveData(Lng1 + 1)), Lng2)

End If

StreamPosition(SoundNum) = Lng1 + Lng2
StreamWriteCursor(SoundNum) = 0
        
Call DirectSoundBuffer(SoundNum).Unlock(Ptr1, Lng1, Ptr2, Lng2)
      
If IsPlaying(SoundNum) = True Then DirectSoundBuffer(SoundNum).Play 0, 0, DSBPLAY_LOOPING

If PlayingStreams >= 1 Then Scrap = SetTimer(UseForm.hwnd, 0, UpdateInterval, AddressOf Private_UpdateStreams)

Private_RestoreStreamingBuffer = True

End Function
