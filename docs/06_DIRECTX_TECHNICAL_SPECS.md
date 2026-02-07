# DirectX Technical Specifications

## DirectX Versions and Components

### Core DirectX Interfaces Used

```vb
' Main DirectX components from VB6 DirectX 7.0 SDK
IDirectDraw2              ' DirectDraw version 2 (display)
IDirectDrawSurface2       ' Surface management
IDirectDrawClipper        ' Window clipping (windowed mode)
IDirectSound              ' DirectSound (audio)
IDirectSoundBuffer        ' Sound buffer management
IDirectInputA             ' DirectInput version A (keyboard)
IDirectInputDeviceA       ' Input device interface
```

### Why DirectDraw2 Instead of DirectDraw7?

The game uses **IDirectDraw2** despite DirectX 7 SDK being available. Reasons:

1. **Compatibility**: DirectDraw2 widely supported across Windows 95/98/NT4
2. **Simplicity**: Fewer features = simpler API for 2D games
3. **Stability**: More mature, fewer bugs than newer versions
4. **Sufficient**: All needed features available (palettes, flipping, blitting)

### DirectX 7 SDK for VB6

```vb
' Type library reference required:
' "DirectX 7 for Visual Basic Type Library"
' File: dx7vb.dll (or msdxm.ocx)

' GUID constants module required for device creation
' GUID_SysKeyboard, etc.
```

---

## Surface Management

### Surface Types

#### Primary Surface
```vb
' DirectDraw.bas - DirectDraw_CreateFlippingBuffers()

Dim lDDSurfaceDescFront As DDSURFACEDESC

With lDDSurfaceDescFront
    .dwSize = Len(lDDSurfaceDescFront)
    .dwFlags = DDSD_CAPS Or DDSD_BACKBUFFERCOUNT
    
    ' Primary surface with flipping capability
    .DDSCAPS.dwCaps = DDSCAPS_PRIMARYSURFACE Or _
                      DDSCAPS_FLIP Or _
                      DDSCAPS_COMPLEX
    
    ' Use 2 back buffers for triple buffering
    .dwBackBufferCount = 2
End With

gDirectDraw.CreateSurface lDDSurfaceDescFront, gDDSFront, Nothing
```

**Primary Surface Properties:**
- Represents the visible display memory
- Fullscreen: Maps directly to video memory (typically)
- Windowed: Maps to desktop surface region
- Cannot be locked for direct pixel access while visible
- Supports hardware flipping (fullscreen)

#### Back Buffer Surface
```vb
' Get attached back buffer from primary
Dim lDDSCapsBack As DDSCAPS
lDDSCapsBack.dwCaps = DDSCAPS_BACKBUFFER
gDDSFront.GetAttachedSurface lDDSCapsBack, gDDSBack
```

**Back Buffer Properties:**
- Hidden surface for rendering
- All drawing operations target this surface
- Flipped/blitted to primary when frame complete
- Lockable for direct pixel manipulation (if needed)
- Size: 640×480 pixels (game resolution)

#### Sprite Surfaces
```vb
' DirectXUtils.bas - LoadBitmapIntoDXS()

Public Function LoadBitmapIntoDXS(rDD As IDirectDraw2, rsFilename$) As IDirectDrawSurface2
    Dim lddSurfaceDesc As DDSURFACEDESC
    Dim lddsTemp As IDirectDrawSurface2
    
    ' Configure offscreen surface
    With lddSurfaceDesc
        .dwSize = Len(lddSurfaceDesc)
        .dwFlags = DDSD_CAPS Or DDSD_HEIGHT Or DDSD_WIDTH
        .DDSCAPS.dwCaps = DDSCAPS_OFFSCREENPLAIN Or DDSCAPS_SYSTEMMEMORY
        .dwHeight = (bitmap height from file)
        .dwWidth = (bitmap width from file)
    End With
    
    rDD.CreateSurface lddSurfaceDesc, lddsTemp, Nothing
    
    ' Load BMP into surface
    lddsTemp.GetDC hDC
    LoadBitmapToHDC rsFilename, hDC
    lddsTemp.ReleaseDC hDC
    
    ' Set color key for transparency
    Dim lddColorKey As DDCOLORKEY
    lddColorKey.low = 0   ' Palette index 0 = transparent
    lddColorKey.high = 0
    lddsTemp.SetColorKey DDCKEY_SRCBLT, lddColorKey
    
    Set LoadBitmapIntoDXS = lddsTemp
End Function
```

**Sprite Surface Properties:**
- Offscreen surfaces (not visible)
- System memory location (DDSCAPS_SYSTEMMEMORY)
- Contains sprite sheets (multiple frames per surface)
- Color keyed for transparency (index 0)
- Persistent throughout level

### Surface Architecture Diagram

```
┌─────────────────────────────────────────────────────────┐
│ VIDEO MEMORY (Hardware)                                 │
│                                                           │
│  ┌─────────────────────┐                                │
│  │ PRIMARY SURFACE     │  ← Visible on screen           │
│  │ (640×480×8-bit)     │                                │
│  └─────────────────────┘                                │
│           ↑ Flip/Blt                                     │
│  ┌─────────────────────┐                                │
│  │ BACK BUFFER 1       │  ← Currently rendering         │
│  │ (640×480×8-bit)     │                                │
│  └─────────────────────┘                                │
│           ↑ (optional)                                   │
│  ┌─────────────────────┐                                │
│  │ BACK BUFFER 2       │  ← Next in queue               │
│  │ (640×480×8-bit)     │                                │
│  └─────────────────────┘                                │
└─────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────┐
│ SYSTEM MEMORY (RAM)                                     │
│                                                           │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐  │
│  │ AlienA.bmp   │  │ Ship.bmp     │  │ Missile.bmp  │  │
│  │ Sprite Sheet │  │ Sprite Sheet │  │ Sprite Sheet │  │
│  │ (256×72)     │  │ (128×72)     │  │ (32×8)       │  │
│  └──────────────┘  └──────────────┘  └──────────────┘  │
│         ↓ Blt              ↓ Blt             ↓ Blt      │
│         └──────────────────┴──────────────────┘         │
│                            ↓                              │
│                   To BACK BUFFER                         │
└─────────────────────────────────────────────────────────┘
```

### Memory Management

**Surface Allocation Strategy:**
```vb
' All surfaces created at level initialization
' Kept in memory throughout level
' Released only when level terminates

' Example surface lifecycle:
1. Level_Initialize()
   - Create primary/back buffers
   - Load all sprite surfaces
   
2. Game Loop (many iterations)
   - Blt from sprite surfaces to back buffer
   - Flip back to front
   
3. Level_Terminate()
   - Set all surface references to Nothing
   - Automatic COM cleanup
```

**Surface Sizes (Alien Invaders):**
```
Primary:     640 × 480 × 1 byte =  307,200 bytes
Back Buf 1:  640 × 480 × 1 byte =  307,200 bytes
Back Buf 2:  640 × 480 × 1 byte =  307,200 bytes
AlienA:      256 × 72 × 1 byte  =   18,432 bytes
AlienB:      128 × 128 × 1 byte =   16,384 bytes
AlienC:      128 × 64 × 1 byte  =    8,192 bytes
AlienD:      128 × 168 × 1 byte =   21,504 bytes
AlienE:      128 × 128 × 1 byte =   16,384 bytes
Ship:        128 × 72 × 1 byte  =    9,216 bytes
Missiles:    32 × 8 × 1 byte    =      256 bytes
Bombs:       Similar small sizes
Dashboard:   640 × 200 × 1 byte =  128,000 bytes (estimated)
Text:        640 × 128 × 1 byte =   81,920 bytes (estimated)

Total Video:    ~900 KB (primary + back buffers)
Total System:   ~300 KB (sprite sheets)
Total VRAM:     ~1.2 MB (reasonable for late 90s hardware)
```

---

## Blitting Operations and Rendering Pipeline

### Blt Method Signature
```vb
' IDirectDrawSurface2.Blt method
surface.Blt(destRect As RECT, _
            sourceSurface As IDirectDrawSurface2, _
            sourceRect As RECT, _
            flags As CONST_DDBLTFLAGS, _
            bltFX As DDBLTFX)
```

### Standard Sprite Blit
```vb
' Actor.cls - Draw()

Dim lrSource As RECT   ' Source rectangle on sprite sheet
Dim lrDest As RECT     ' Destination on back buffer

' Define source region (which frame from sprite sheet)
With lrSource
    .Left = loFrameDefinition.lXOffset
    .Top = loFrameDefinition.lYOffset
    .Right = .Left + loFrameDefinition.lXSize
    .Bottom = .Top + loFrameDefinition.lYSize
End With

' Define destination region (where to draw on screen)
With lrDest
    .Left = CInt(fX) + roLevel.iPlayXOffset
    .Top = CInt(fY) + roLevel.iPlayYOffset
    .Right = .Left + loFrameDefinition.lXSize
    .Bottom = .Top + loFrameDefinition.lYSize
End With

' Perform blit with transparency
roLevel.ddsBackBufferSurface.Blt lrDest, _
    SpriteSheetSurface, _
    lrSource, _
    DDBLT_KEYSRCOVERRIDE, _  ' Enable color key transparency
    mddfxNormalBlt
```

### Transparency via Color Key
```vb
' Set on sprite surface at load time
Dim lddColorKey As DDCOLORKEY
lddColorKey.low = 0    ' Palette index 0
lddColorKey.high = 0   ' (range for color key, usually same)

SpriteSurface.SetColorKey DDCKEY_SRCBLT, lddColorKey

' DDBLT_KEYSRCOVERRIDE flag makes Blt skip pixels matching color key
' Result: Only non-black (index ≠ 0) pixels drawn
```

### Fill Operations
```vb
' Clear back buffer to black
Dim lrFullScreen As RECT
With lrFullScreen
    .Left = 0
    .Top = 0
    .Right = SCREENWIDTH    ' 640
    .Bottom = SCREENHEIGHT  ' 480
End With

Dim lddfxBlack As DDBLTFX
With lddfxBlack
    .dwSize = Len(lddfxBlack)
    .dwFillColor = 0  ' Palette index 0 (black)
End With

gDDSBack.Blt lrFullScreen, Nothing, lrFullScreen, _
    DDBLT_COLORFILL Or DDBLT_WAIT, lddfxBlack
```

### Rendering Pipeline (Per Frame)

```
1. CLEAR
   ├─ Blt(back_buffer, null, full_rect, COLORFILL, black)
   └─ Duration: ~1-2ms (hardware accelerated)

2. DRAW BACKGROUND
   ├─ Draw parallax stars (50 stars × small rects)
   │  └─ Each star: Blt(back, null, pixel_rect, COLORFILL, star_color)
   └─ Duration: ~1ms

3. DRAW BORDERS
   ├─ Blt horizontal lines (top and bottom borders)
   └─ Duration: <1ms

4. DRAW MISSILES (up to 10)
   ├─ For each missile:
   │  └─ Blt(back, missile_sheet, frame_rect, KEYSRCOVERRIDE, fx)
   └─ Duration: ~0.5ms total

5. DRAW BOMBS (up to 22)
   ├─ For each bomb:
   │  └─ Blt(back, bomb_sheet, frame_rect, KEYSRCOVERRIDE, fx)
   └─ Duration: ~1ms total

6. DRAW ALIENS (up to 35)
   ├─ For each alien:
   │  └─ Blt(back, alien_sheet, frame_rect, KEYSRCOVERRIDE, fx)
   └─ Duration: ~3-5ms total (depends on count)

7. DRAW PLAYER
   ├─ Blt(back, ship_sheet, frame_rect, KEYSRCOVERRIDE, fx)
   └─ Duration: <1ms

8. DRAW HUD
   ├─ Blt dashboard graphics
   ├─ Blt score numbers (7 digits)
   ├─ Blt shield indicator
   ├─ Blt ship icons (lives remaining)
   └─ Duration: ~2ms

9. DRAW BONUSES (up to 20 score popups)
   ├─ For each active bonus:
   │  └─ Blt(back, bonus_sheet, value_frame, KEYSRCOVERRIDE, fx)
   └─ Duration: ~1ms

TOTAL RENDER TIME: 10-15ms typical (leaves 25-30ms for logic at 25 FPS)
```

### Blit Flags Explained

```vb
' DDBLT_WAIT
' Waits for blit to complete before returning
' Ensures synchronous operation (VB6 requirement)

' DDBLT_KEYSRCOVERRIDE  
' Uses source surface's color key for transparency
' Pixels matching color key are not copied

' DDBLT_COLORFILL
' Fills rectangle with solid color (no source surface)
' Used for clearing and drawing simple shapes

' DDBLT_ASYNC (not used in this game)
' Returns immediately, blit may still be in progress
' Dangerous in VB6 due to COM reference counting
```

### Fast Blit vs Slow Blit

**Hardware Accelerated (Fast):**
- Video memory → Video memory (primary/back buffers)
- Uses GPU/blitter hardware
- ~1-2ms for full screen clear
- ~0.1ms per typical sprite

**Software Emulated (Slow):**
- System memory → Video memory (sprite sheets → back buffer)
- CPU copies pixels
- ~5-10× slower than hardware
- Still acceptable for 30-50 sprites at 25 FPS

**Optimization: Pre-load to VRAM**
```vb
' NOT IMPLEMENTED in this game, but possible:
' Load sprite surfaces to video memory if space available
.DDSCAPS.dwCaps = DDSCAPS_OFFSCREENPLAIN Or DDSCAPS_VIDEOMEMORY

' Trade-off:
' + Faster blitting (VRAM → VRAM)
' - Uses precious VRAM (4-8 MB typical in 1998)
' - May fail if insufficient VRAM
```

---

## Palette Management for 8-bit Mode

### Palette Structure
```vb
' 256-color palette (8-bit indexed color)
Type PALETTEENTRY
    peRed As Byte     ' 0-255
    peGreen As Byte   ' 0-255
    peBlue As Byte    ' 0-255
    peFlags As Byte   ' Usually 0 or PC_NOCOLLAPSE
End Type

Dim Palette(0 To 255) As PALETTEENTRY
```

### Loading Palette Files
```vb
' Resource files:
' - ai.pal (primary game palette)
' - ai2.pal (alternate palette)

' Typical palette loading:
Open App.Path & "\Resource\ai.pal" For Binary As #1
For i = 0 To 255
    Get #1, , Palette(i).peRed
    Get #1, , Palette(i).peGreen
    Get #1, , Palette(i).peBlue
    Palette(i).peFlags = PC_NOCOLLAPSE
Next i
Close #1
```

### Palette Application
```vb
' Create DirectDraw palette
Dim ddPalette As IDirectDrawPalette
gDirectDraw.CreatePalette DDPCAPS_8BIT Or DDPCAPS_ALLOW256, _
    Palette(0), ddPalette, Nothing

' Attach to primary surface
gDDSFront.SetPalette ddPalette
```

### Color Key Entry
```vb
' Index 0 reserved for transparency
Palette(0).peRed = 0
Palette(0).peGreen = 0
Palette(0).peBlue = 0

' All sprites use index 0 as transparent background
' Bitmap files must have black (RGB 0,0,0) backgrounds
```

### Palette Constraints

**8-bit Limitations:**
- Only 256 colors simultaneously displayable
- All sprites share same palette
- Gradient effects limited
- Dithering used for smooth color transitions

**Palette Design Strategies:**
1. Reserve indices 0-15 for UI/HUD colors
2. Indices 16-31 for player ship colors
3. Indices 32-128 for alien sprite colors
4. Indices 129-255 for backgrounds and effects

**Nearest Color Matching:**
```vb
' GamePlay.bas - Getting palette index for specific RGB
llHPalette = CreatePalette256(GetSystemPaletteCopy(hDC))
lPaletteIndex = Win32.GetNearestPaletteIndex(llHPalette, RGB(96, 96, 192))

' Used for:
' - Setting fill colors (borders, shields)
' - Ensuring exact color matches across surfaces
```

### Performance Impact
- Palette changes expensive (avoid mid-frame)
- Palette animation possible (cycle indices)
- Single palette simplifies rendering
- No palette per-surface in 8-bit mode

---

## Sound Buffer Architecture

### DirectSound Initialization
```vb
' DirectSound.bas - DirectSound_Initialize()
DirectSoundCreate ByVal 0&, mDirectSound, Nothing

' Set cooperative level
mDirectSound.SetCooperativeLevel mFormHost.hWnd, DSSCL_NORMAL
' DSSCL_NORMAL: Shares with other applications, good for windowed mode
```

### Sound Effect Manager
```vb
' Multiple buffer copies per sound for overlapping playback
Type SoundEffect
    iNumCopies As Integer                       ' Number of buffers
    dsbDirectSoundBuffers() As IDirectSoundBuffer  ' Buffer array
    iLastIndexPlayed As Integer                 ' Round-robin tracker
End Type

Private mseSoundEffects() As SoundEffect
Private miNumSoundEffects As Integer
```

### Loading Sound Effects
```vb
' DirectSound.bas - DirectSound_LoadSoundEffect()
' rsFileName: Path to WAV file
' riNumCopiesRequested: Number of simultaneous playbacks supported

' Steps:
1. Load WAV file into temporary DirectSoundBuffer
2. Create specified number of duplicate buffers
3. Store in mseSoundEffects() array
4. Return handle (index) to caller

' Example from LevelDefinitions.bas:
Call roLevel.AddNewSoundEffect("LASER", App.Path & "\Resource\Laser.wav", 5)
'                                name    file path                            copies
' Creates 5 independent buffers for laser sound
```

### Sound Effect Playback
```vb
' DirectSound.bas - DirectSound_PlaySound()
Public Sub DirectSound_PlaySound(riHse As Integer)
    With mseSoundEffects(riHse)
        ' Round-robin to next buffer
        .iLastIndexPlayed = (.iLastIndexPlayed + 1) Mod .iNumCopies
        
        ' Stop if currently playing (reset position)
        .dsbDirectSoundBuffers(.iLastIndexPlayed).Stop
        .dsbDirectSoundBuffers(.iLastIndexPlayed).SetCurrentPosition 0
        
        ' Play from beginning
        .dsbDirectSoundBuffers(.iLastIndexPlayed).Play DSBPLAY_DEFAULT
    End With
End Sub

' DSBPLAY_DEFAULT: Play once, no looping
' DSBPLAY_LOOPING: Loop continuously (for background music)
```

### Sound Resources

| Sound File | Size | Copies | Usage |
|------------|------|--------|-------|
| Laser.wav | (small) | 5 | Player missile fire |
| Boom1.wav | 8.7K | 1 | Small explosion |
| Boom2.wav | 17K | 2 | Large explosion |
| Whoosh.wav | (small) | 5 | Alien movement/swoosh |
| Doh2.wav | 3.6K | 1 | Player hit (voice) |
| Doh3.wav | 6.0K | 1 | Player death (voice) |
| Grunt1.wav | 2.4K | 5 | Alien hit |
| HeyHeyHey.wav | 14K | 1 | Bonus collected (voice) |
| Sludge.wav | 6.4K | 1 | Alien destruction |
| Splat.wav | 11K | 1 | Collision effect |
| ApacheLoop1.wav | 23K | 1 | Background ambiance (looped) |
| Phone.wav | 27K | 1 | Special event |
| Yeah.wav | 9.3K | 1 | Victory/bonus (voice) |

### Buffer Management Strategy

**Why Multiple Copies?**
```
Single buffer limitation:
- Can only play one instance at a time
- Starting playback stops current playback
- Rapid fire would cut off previous shot sound

Multiple buffer solution:
- Each copy can play independently
- Round-robin through copies
- Up to N simultaneous sounds (N = number of copies)

Example:
Laser.wav with 5 copies:
- Player fires 5 shots rapidly
- Each uses different buffer
- All 5 sounds audible simultaneously
```

**Memory Cost:**
```
Per-sound overhead = WAV file size × number of copies

Laser.wav: ~2KB × 5 copies = 10KB
Grunt1.wav: 2.4KB × 5 copies = 12KB
Boom2.wav: 17KB × 2 copies = 34KB

Total sound memory: ~200KB (reasonable for era)
```

### Audio Format Specifications
```
Standard WAV format:
- Sample rate: 22050 Hz (typical for games)
- Bit depth: 8-bit or 16-bit
- Channels: Mono (1 channel)
- Compression: PCM (uncompressed)

DirectSound automatically handles:
- Format conversion
- Resampling
- Mixing multiple buffers
```

---

## Input Polling Mechanism

### DirectInput Setup
```vb
' DirectInput.bas - DirectInput_Initialize()
Const mlDIRECTINPUT_VERSION& = &H500  ' DirectInput 5.0

DirectInputCreateA ByVal App.hInstance&, mlDIRECTINPUT_VERSION&, gDirectInputA, Nothing
```

### Keyboard Device Setup
```vb
' DirectInput.bas - DirectInput_SetupKeyboard()

' Create keyboard device
gDirectInputA.CreateDevice GUID_SysKeyboard, mdidKeyboard, Nothing

' Set data format to standard keyboard
mdidKeyboard.SetDataFormat c_dfDIKeyboard

' Set cooperative level
mdidKeyboard.SetCooperativeLevel mFormHost.hWnd, _
    DISCL_BACKGROUND Or DISCL_NONEXCLUSIVE

' Acquire device for input
mdidKeyboard.Acquire
```

**Cooperative Level Flags:**
```vb
' DISCL_BACKGROUND: Get input even when not foreground app
' DISCL_NONEXCLUSIVE: Share keyboard with other apps
' Alternative: DISCL_FOREGROUND Or DISCL_EXCLUSIVE (game only)
```

### Input Polling (Per Frame)
```vb
' DirectInput.bas - DirectInput_GetKeyboardState()
Private mybufKeyboardState(0 To 255) As Byte

mdidKeyboard.GetDeviceState 256, mybufKeyboardState(0)

' mybufKeyboardState now contains state of all keys:
' - Bit 7 set (& &H80 = True): Key is down
' - Bit 7 clear (& &H80 = False): Key is up
```

### Key State Interpretation
```vb
' PlayerInput.cls - GetInputState()

' Check if key is pressed
bMoveLeftRequested = (mybufKeyboardState(DIK_LEFT) And &H80) <> 0
bMoveRightRequested = (mybufKeyboardState(DIK_RIGHT) And &H80) <> 0
bMissleRequested = (mybufKeyboardState(DIK_SPACE) And &H80) <> 0
bShieldsRequested = (mybufKeyboardState(DIK_LSHIFT) And &H80) <> 0
bStopMoveRequested = Not (bMoveLeftRequested Or bMoveRightRequested)

' Quit detection
If (mybufKeyboardState(DIK_ESCAPE) And &H80) Then
    RequestQuit()
End If
```

### DirectInput Key Constants
```vb
' Relevant keys for Alien Invaders:
DIK_LEFT = &HCB       ' Left arrow
DIK_RIGHT = &HCD      ' Right arrow  
DIK_UP = &HC8         ' Up arrow (unused)
DIK_DOWN = &HD0       ' Down arrow (unused)
DIK_SPACE = &H39      ' Space bar (fire)
DIK_LSHIFT = &H2A     ' Left shift (shields)
DIK_RSHIFT = &H36     ' Right shift (alternate shields)
DIK_ESCAPE = &H01     ' ESC (quit)
DIK_RETURN = &H1C     ' Enter (menu select)
```

### Polling Frequency
```
Per-frame polling (25 FPS):
- GetDeviceState called every 40ms
- Low latency: ~40ms input lag
- Sufficient for arcade-style gameplay

Higher polling (not implemented):
- Could poll at 60Hz or 100Hz
- Requires separate input thread
- Minimal benefit for this game type
```

### Input Buffering (Not Used)
```vb
' DirectInput supports buffered input (events):
' SetEventNotification() + GetDeviceData()
' Provides press/release events with timestamps
' 
' This game uses immediate mode instead:
' - Simpler implementation
' - Poll state each frame
' - Check if key down/up right now
' - No need for event queue
```

### Input State Machine
```
FRAME N:
1. Poll keyboard state
2. Store in mybufKeyboardState()

3. Interpret states:
   LEFT down AND RIGHT up → Move left
   RIGHT down AND LEFT up → Move right
   LEFT down AND RIGHT down → No movement (cancel)
   SPACE down → Fire (if recharged)
   SHIFT down → Shields (if available)

4. Apply actions to game state

FRAME N+1:
1. Poll again (new state)
2. Detect state changes:
   - KEY_WAS_UP and KEY_NOW_DOWN → Just pressed
   - KEY_WAS_DOWN and KEY_NOW_UP → Just released
   (Not explicitly implemented - uses immediate state only)
```

---

## Performance Considerations

### VB6 Limitations

**Interpreted P-Code:**
```
VB6 compiles to P-code (pseudo-code) by default
- Interpreted at runtime by MSVBVM60.DLL
- ~10-50× slower than native C++
- Function calls expensive (COM overhead)
- Loops slower than native code
```

**Native Compilation:**
```vb
' Project Properties → Compile tab:
' [✓] Compile to Native Code
' [✓] Optimize for Fast Code
' [ ] Favor Pentium Pro (optional)

' Results:
' - 2-5× faster than P-code
' - Still slower than C++ (VB runtime overhead)
' - Sufficient for 2D games at 25 FPS
```

**COM Overhead:**
```vb
' Every DirectX call crosses COM boundary:
Set oActor = New Actor2           ' ~1000 CPU cycles
oActor.Draw(Me)                    ' ~500 cycles overhead
surface.Blt(...)                   ' ~200 cycles + actual blit

' Mitigation:
' - Minimize object creation in main loop
' - Cache interface pointers
' - Batch operations where possible
```

### Bottlenecks Identified

**1. Object Iteration**
```vb
' Problem: VB6 For Each slow on collections
For Each alien In AlienCollection
    ' ...
Next

' Solution: Direct array indexing with FastArrayManager
For i = 1 To maxAliens
    If alienActive(i) Then
        ' process alien(i)
    End If
Next
```

**2. Floating Point Math**
```vb
' Problem: VB6 uses VARIANT for default types (slow)
Dim x  ' VARIANT (very slow)

' Solution: Explicit types
Dim fX As Single    ' 4-byte float (faster)
Dim lX As Long      ' 4-byte integer (fastest)

' Game uses:
' - Single for positions (sub-pixel accuracy)
' - Long for velocities, scores, ticks
```

**3. String Operations**
```vb
' Problem: String concatenation allocates memory
sMsg = sMsg & sNewText  ' Slow

' Solution: Minimize strings in game loop
' - Use numeric IDs instead of names
' - Cache string results
' - Avoid string building in inner loops
```

**4. Collision Detection**
```vb
' Naive: O(n²) all-pairs collision
For i = 1 To numAliens
    For j = 1 To numMissiles
        DetectCollision(alien(i), missile(j))
    Next
Next

' Optimized: Early-out via flags
For i = 1 To numAliens
    If alien(i).bCanBeHitByMissiles Then  ' Skip if already dead
        For j = 1 To numMissiles
            If DetectCollision(alien(i), missile(j)) Then
                ' Handle collision
                Exit For  ' Stop checking missiles for this alien
            End If
        Next
    End If
Next
```

### Memory Management

**VB6 Automatic Memory:**
```vb
' Objects reference-counted by COM
Set obj = New MyClass   ' RefCount = 1
Set obj2 = obj          ' RefCount = 2
Set obj = Nothing       ' RefCount = 1
Set obj2 = Nothing      ' RefCount = 0 → Freed

' Arrays grown/shrunk via ReDim
ReDim actors(1 To 50)         ' Allocate
ReDim Preserve actors(1 To 100)  ' Grow (expensive!)
Erase actors                   ' Deallocate
```

**Object Pooling Strategy:**
```vb
' Pre-allocate maximum arrays at level start
ReDim oAliens(1 To iMaxNumAliens)     ' 35 aliens
ReDim oMissiles(1 To iMaxNumMissiles) ' 10 missiles

' Use FastArrayManager to track active indices
' Recycle objects instead of create/destroy

' Benefits:
' - No allocation during gameplay
' - Deterministic memory usage
' - Avoid garbage collection pauses
```

**Surface Memory:**
```vb
' DirectDraw surfaces are COM objects
' Must explicitly release:
Set gDDSBack = Nothing
Set gDDSFront = Nothing
Set spriteSheet = Nothing

' Failure to release = memory leak
' VB6 IDE may hide leak (cleanup on END)
' Compiled EXE will leak if not careful
```

### Optimization Techniques Used

**1. FastArrayManager**
```vb
' Custom sparse array manager
' Tracks free/used indices without iteration
' GetFreeIndex(): O(1) instead of O(n) search
' ReleaseIndex(): O(1) instead of compacting array
```

**2. Fixed Timestep Option**
```vb
' bRealTime = False
' Fixed 40ms updates
' More consistent performance
' Easier to debug (deterministic)
```

**3. Spatial Coherence**
```vb
' Objects rendered back-to-front
' Missiles → Bombs → Aliens → Player → HUD
' Allows overdraw (no sorting needed)
' GPU handles overlapping sprites
```

**4. Minimal State Changes**
```vb
' Set color key once at load
' Set BLTFX once at init
' Reuse same RECT structures
' Cache frame definitions
```

### Frame Rate Analysis

**Target: 25 FPS (40ms budget)**
```
Time breakdown (typical frame):

Input polling:        1ms   (DirectInput)
Update logic:        10ms   (VB6 code execution)
├─ Player update:     1ms
├─ Missile update:    2ms
├─ Alien updates:     5ms  (30 aliens × 0.15ms each)
└─ Collision detect:  2ms
Rendering:           15ms   (DirectDraw blits)
├─ Clear buffer:      2ms
├─ Draw sprites:     10ms  (40 blits × 0.25ms each)
└─ Draw HUD:          3ms
Present (flip):       5ms   (VSync wait + flip)
DoEvents:             2ms   (Windows messages)
Slack:                7ms   (wait for next frame)
────────────────────────────
Total:               40ms   (25 FPS achieved)
```

**Performance Headroom:**
```
Best case: 15-20 FPS actual workload
Target:    25 FPS (40ms per frame)
Headroom:  15-25ms available

Allows for:
- Frame rate spikes (more aliens/bombs)
- Slower systems (Pentium 166MHz)
- Background tasks (Windows 98 multitasking)
```

### Hardware Requirements (1998)

**Minimum:**
- Pentium 166 MHz
- 32 MB RAM
- 2 MB VRAM (video card)
- DirectX 7 compatible video card
- Sound Blaster compatible sound card
- Windows 95/98/NT 4.0

**Recommended:**
- Pentium II 266 MHz  
- 64 MB RAM
- 4 MB VRAM
- 3D accelerator (optional, 2D only)

**Display Modes:**
- 640×480×8-bit (256 colors) - Primary
- Windowed or Fullscreen
- No 16-bit/32-bit color support

---

## Platform-Specific Issues

### Windows Version Compatibility

**Windows 95/98:**
- Full DirectX 7 support
- Hardware acceleration common
- VRAM mode works well
- Cooperative multitasking (DoEvents important)

**Windows NT 4.0:**
- DirectX 3 built-in (limited)
- DirectX 7 via service pack
- Less hardware acceleration
- Preemptive multitasking (more stable)

**Windows 2000/XP:**
- Full DirectX 7+ support
- Better driver support
- WHQL driver requirements (more stable)
- May need compatibility mode in later Windows

### Modern Compatibility (Windows 10/11)

**Issues:**
- DirectDraw deprecated (Vista+)
- Hardware acceleration removed
- Software emulation slow/buggy
- 8-bit palettized mode may not work
- VB6 runtime still supported (MSVBVM60.DLL)

**Solutions:**
- DxWnd wrapper (re-enable DirectDraw)
- DOSBox (extreme case)
- dgVoodoo2 (DirectDraw → Direct3D wrapper)
- Recompile for higher color depth
- Port to modern framework

### Windowed Mode Specifics
```vb
' DirectDraw.bas - DirectDraw_CreateFlippingBuffers_Window()

' No page flipping in windowed mode
' Uses Blt instead of Flip:
gDDSFront.Blt lrDest, gDDSBack, lrSource, DDBLT_WAIT, fx

' Clipper required to handle window boundaries:
gDirectDraw.CreateClipper 0&, mDDCWindow, Nothing
mDDCWindow.SetHWnd 0, rForm.hWnd
gDDSFront.SetClipper mDDCWindow

' Slower than fullscreen (no hardware flip)
' But more convenient for development/debugging
```

---

## Summary: Key Technical Points

### Architecture
- **DirectDraw2** for display (not DD7 - compatibility)
- **DirectSound** for audio (multi-buffer system)
- **DirectInput** for keyboard (immediate mode polling)
- **8-bit palettized** graphics (256 colors)
- **640×480** resolution (fixed)

### Performance
- **Target: 25 FPS** (40ms per frame)
- **VB6 native code** compilation
- **Object pooling** for actors
- **Sparse arrays** via FastArrayManager
- **~40 blits per frame** (sprites + HUD)

### Rendering
- **Back buffer rendering** (offscreen)
- **Page flipping** (fullscreen) or Blt (windowed)
- **Color key transparency** (index 0)
- **No alpha blending** (8-bit limitation)
- **Back-to-front drawing** order

### Audio
- **Multi-buffer** per sound (5× for common sounds)
- **Round-robin playback** (simultaneous instances)
- **~13 sound effects** total
- **22KHz mono WAV** files typical

### Input
- **DirectInput polling** (25Hz with game loop)
- **Immediate state** (not buffered events)
- **~40ms input latency** (one frame)
