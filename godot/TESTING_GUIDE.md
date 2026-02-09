# Testing Guide for VB6 Logic Port

This guide provides step-by-step instructions for testing the three main features that were mentioned as potentially missing or broken.

## Prerequisites

1. Open the project in Godot 4.3+
2. Press F5 to run the game
3. Use arrow keys or WASD to move
4. Use Space or Enter to fire missiles
5. Use Shift to activate shields

## Test 1: Player Death Handling

### What to Test
Verify that when the player dies, the game responds correctly with animations, sounds, and respawn logic.

### Steps
1. **Start the game** (F5)
2. **Let an enemy bomb hit you** (avoid moving for a moment)
3. **Observe:**
   - ✅ Player ship should play explosion animation (red/orange expanding circle)
   - ✅ "DOH3" sound should play
   - ✅ Player ship disappears after animation completes
   - ✅ Game pauses for about 500ms
   - ✅ Level reloads with player respawned at starting position
   - ✅ Lives indicator in bottom-left shows one less ship icon
   - ✅ Power-ups (yellow/blue/purple icons) should disappear from HUD unless you had green "safety pin"

4. **Test with safety pin:**
   - Shoot a **green cargo** to get safety pin (green icon appears in HUD)
   - Get hit by enemy bomb
   - ✅ After respawn, power-ups should be retained
   - ✅ Safety pin icon should disappear

5. **Test game over:**
   - Lose all 3 lives
   - ✅ Game over screen should appear
   - ✅ If score is high enough, name entry dialog appears

### Expected Behavior
- Player death is clearly visible with animation and sound
- Respawn happens automatically after brief pause
- Lives decrement and game ends when reaching 0
- Power-ups are stripped on death (unless safety pin active)

---

## Test 2: Multi-Missile Cargo Activation

### What to Test
Verify that picking up blue and yellow cargo enables multi-missile firing modes.

### Steps

#### Test 2A: Normal Firing (Baseline)
1. **Start the game** (F5)
2. **Fire missiles** (Space/Enter)
3. **Observe:**
   - ✅ Only 1 missile fires at a time
   - ✅ Can only have 2 missiles on-screen at once
   - ✅ "LASER" sound plays on each fire

#### Test 2B: Yellow Cargo (Double Shot)
1. **Shoot a yellow cargo** (look for yellow box falling down)
2. **Fly into the cargo to collect it**
3. **Check HUD:** ✅ Yellow "double shot" icon appears in bottom-left area
4. **Fire missiles**
5. **Observe:**
   - ✅ Two missiles fire side-by-side (offset left and right)
   - ✅ Can have up to 4 missiles on-screen at once
   - ✅ Both missiles travel straight up

#### Test 2C: Blue Cargo (Multi Shot)
1. **Start new game** or **wait for power-ups to be stripped**
2. **Shoot a blue cargo** (look for blue box)
3. **Fly into the cargo to collect it**
4. **Check HUD:** ✅ Blue "multi shot" icon appears in bottom-left area
5. **Fire missiles**
6. **Observe:**
   - ✅ Single missile fires straight up (center)
   - ✅ Can fire unlimited missiles (no 2-missile limit)
   - ✅ Screen can fill with many missiles

#### Test 2D: Yellow + Blue Cargo (Double + Multi)
1. **Collect both yellow and blue cargo**
2. **Check HUD:** ✅ Both yellow and blue icons visible
3. **Fire missiles rapidly**
4. **Observe:**
   - ✅ Two missiles fire side-by-side (like double shot)
   - ✅ Can fire unlimited missiles (no 4-missile limit)
   - ✅ This is the most powerful weapon mode!

#### Test 2E: Purple Cargo (Rapid Fire)
1. **Shoot a purple cargo**
2. **Collect it**
3. **Check HUD:** ✅ Purple "rapid fire" icon appears
4. **Hold down fire button**
5. **Observe:**
   - ✅ Missiles fire twice as fast as normal
   - ✅ Works with all other power-up combinations

### Expected Behavior
- Yellow cargo enables double-shot (2 missiles, max 4 on screen)
- Blue cargo enables multi-shot (unlimited missiles)
- Yellow + Blue = double-shot with unlimited missiles
- Purple cargo doubles firing rate
- HUD icons clearly show which power-ups are active

---

## Test 3: High Score Name Entry

### What to Test
Verify that achieving a high score allows the player to enter their name, and that scores persist between game sessions.

### Steps

#### Test 3A: First High Score
1. **Start the game** (F5)
2. **Play and earn points** (destroy aliens = points)
3. **Lose all lives** (let enemies hit you 3 times)
4. **Observe:**
   - ✅ If your score > 0, a dialog box appears
   - ✅ Dialog shows "NEW HIGH SCORE!"
   - ✅ Dialog shows your score
   - ✅ Dialog has text input field
   - ✅ Dialog has "Submit" button

5. **Enter your name** (type text)
6. **Press Enter** or **click Submit**
7. **Observe:**
   - ✅ Dialog closes
   - ✅ Game returns to game over screen
   - ✅ Can press Enter to return to menu

#### Test 3B: Score Persistence
1. **Exit the game** (Alt+F4 or close window)
2. **Restart the game** (F5)
3. **Check title screen:**
   - ✅ Your high score should be displayed
   - ✅ (If implemented) High score table shows your name

4. **Play again with lower score**
5. **Lose all lives**
6. **Observe:**
   - ✅ Name entry dialog does NOT appear (score too low)
   - ✅ Game goes directly to game over screen

#### Test 3C: Multiple High Scores
1. **Play and beat your previous high score**
2. **Enter a different name**
3. **Restart game**
4. **Observe:**
   - ✅ New high score is saved
   - ✅ Previous scores are preserved in table

#### Test 3D: File Format Compatibility
1. **Navigate to user data folder:**
   - Windows: `%APPDATA%\Godot\app_userdata\AlienInvaders\`
   - Linux: `~/.local/share/godot/app_userdata/AlienInvaders/`
   - macOS: `~/Library/Application Support/Godot/app_userdata/AlienInvaders/`
2. **Find file:** `AI.HS`
3. **Observe:**
   - ✅ File exists
   - ✅ File is binary encrypted (not readable as text)
   - ✅ File size = 5120 bytes (10 records × 128 integers × 4 bytes)

### Expected Behavior
- High score dialog appears only when score qualifies for top 10
- Player can enter name (max 20 characters)
- Scores persist between game sessions
- File format is VB6-compatible with XOR encryption
- Can have up to 10 high scores

---

## Troubleshooting

### Player Death Not Working
- **Check:** Are animations loading? Look for sprite sheets in `assets/sprites/`
- **Check:** Is sound playing? Check audio files in `assets/audio/`
- **Try:** Press F1 in Godot editor to check for error messages

### Multi-Missile Not Firing
- **Check:** Did cargo actually hit player? (collision detection)
- **Check:** Are HUD icons appearing? (indicates power-up active)
- **Try:** Use debug print to verify `has_multi_shots` flag is set

### High Score Entry Not Appearing
- **Check:** Is your score > 0? (must have points)
- **Check:** Does `user://` directory exist? (Godot creates automatically)
- **Check:** Console output for any file I/O errors

---

## Success Criteria

All three features should work as described:

✅ **Player Death:**
- Explosion animation plays
- Sound effect plays
- Respawn after delay
- Life counter decrements
- Power-ups stripped (unless safety pin)

✅ **Multi-Missile:**
- Cargo collection activates power-ups
- HUD shows active power-ups
- Firing behavior changes based on active power-ups
- On-screen missile limits work correctly

✅ **High Score Entry:**
- Dialog appears for qualifying scores
- Name can be entered
- Scores persist across sessions
- File format is VB6-compatible

If all criteria are met, the Godot port is feature-complete! 🎉
