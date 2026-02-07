VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
  Persistable = 0  'NotPersistable
  DataBindingBehavior = 0  'vbNone
  DataSourceBehavior  = 0  'vbNone
  MTSTransactionMode  = 0  'NotAnMTSObject
END
Attribute VB_Name = "SoundEffect"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = True
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = False
Option Explicit

' SoundEffect class 1.0 -- (c) 1999 Luther Ananda Miller
' luther@usa.net -- http://www.lanandam.com

'Use it for free for whatever you want.
'Let me know what you use it for. Let me know of ideas for improvements, etc.
'Leave these header comments in if you redistribute it. Thanks!
'This version calls routines in Jan Narawa's DirectSoundModule,
'but it works with other modules as well if you swap the right calls...

'SoundEffect is probably a misnomer. Could be music, streaming, etc.. not just effects!
'This is useful for loading multiple buffers of the same sound effect which could be played
'serveral times simultaneously. You just call the Play method and let the class handle
'choosing which buffer to actually play...

'sID does not need to be used.. but I use it to give loaded sounds a String "ID", like "EXPLOSION"...
'I like to load all the SoundEffect objects into a Collection indexed by the ID, then I can
'retrieve them by name during initialization (I wouldn't retrieve them by name during a game loop--
'Collections are slower than molasses in winter!)
Public sID As String

'number of copies actually loaded
Private lNumCopies As Long
'array of handles- one handle for each copy
'I use a long in case another sound module is used which uses Longs as handles..
Private lHandles() As Long
'index into the handles array of the last buffer played
Private lLastPlayedCopy As Long

Public Sub Initialize(rsID$, rsWaveFile$, ByVal vlCopiesRequested&)
    'If you know a sound will be played only once at a time, then request just one copy!
    'Allocate as many copies of the requested Wave file buffer as possible
    Dim llCtr As Long
    
    lNumCopies = 0
    sID = rsID
    'Start off assuming we will get the requested number of copies
    ReDim lHandles(1 To vlCopiesRequested)
    'Load the static sound buffer into copy 1
    'Call any routine to allocate a sound that returns a Long (or Integer) handle
    lHandles(1) = General_LoadStaticSound(rsWaveFile$, False)
    'My sounds seem to play loud.. you many not want to do this!
    'Call Buffer2D_SetVolume((lHandles(1)), -2000)
    'Call Buffer2D_SetVolume((lHandles(1)), 0)
    'Duplicate the first buffer for each copy.
    'Read up on DuplicateBuffer... it saves memory (compared to loading more copies)
    If lHandles(1) > 0 Then
        lNumCopies = lNumCopies + 1
        For llCtr = 2 To vlCopiesRequested
            'Call any routine to duplicate a sound that returns a Long (or Integer) handle
            lHandles(llCtr) = General_DuplicateOrLoadStaticSound((lHandles(1)))
            If lHandles(1) < 0 Then Exit For
            lNumCopies = lNumCopies + 1
        Next llCtr
    End If
    
    'Reallocate handle array based on actual copies loaded
    If lNumCopies = 0 Then
        Erase lHandles()
    ElseIf lNumCopies < vlCopiesRequested Then
        ReDim Preserve lHandles(1 To lNumCopies)
    End If

    'reset last copy played so next buffer played is the first
    lLastPlayedCopy = 0
End Sub

Public Sub Play(Optional ByVal vbLooping As Boolean = False)
    If lNumCopies <= 0 Then Exit Sub
    
    Dim llIndex As Long
    
    'Try the buffer after the previous one played
    llIndex = lLastPlayedCopy + 1
    'Loop to the first buffer at the end...
    If llIndex > lNumCopies Then llIndex = 1
    
    'Play it!
    'Call any routine to play that allocated Long (or Integer) handle!
    Call General_PlaySound((lHandles(llIndex)), vbLooping)
    
    lLastPlayedCopy = llIndex

    'Note: you probably could check to see which ones are done playing already,
    'but they are all the same length and this saves processing time anyway..
End Sub

Private Sub Class_Initialize()
    lNumCopies = 0
    lLastPlayedCopy = 0
End Sub

Private Sub Class_Terminate()
    'Free the sound buffers!
    Dim llCtr As Long
    
    For llCtr = 1 To lNumCopies
        Call General_DeleteSound((lHandles(llCtr)))
    Next llCtr
End Sub
