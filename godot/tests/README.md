# Godot Tests

This directory contains unit tests for the Alien Invaders Godot port.

## Test Files

- `test_constants.gd` - Tests for game constants (screen size, velocities, scores)
- `test_actor.gd` - Tests for Actor base class (movement, state flags)
- `test_collision.gd` - Tests for CollisionManager (spatial partitioning)
- `test_game.gd` - Tests for Game class (state management, scoring, lives)

## Running Tests

### Method 1: Using Godot Editor (Recommended if Godot is installed)

1. Open the project in Godot 4.3+
2. Open any test file (e.g., `test_constants.gd`)
3. Click the "Run Current Scene" button (F6)
4. View test output in the console

### Method 2: Command Line (if godot is in PATH)

Run individual tests:
```bash
cd godot
godot --headless --script tests/test_constants.gd
godot --headless --script tests/test_actor.gd
godot --headless --script tests/test_collision.gd
godot --headless --script tests/test_game.gd
```

### Method 3: Manual Validation

Each test file can be opened and reviewed manually. The tests follow a simple pattern:
- Create the object being tested
- Call methods and check results
- Print pass/fail for each assertion

## Test Coverage

### Constants (test_constants.gd)
✓ Screen dimensions (640x480, borders)
✓ Player constants (velocity, recharge times)
✓ Alien scores (10-75 points)
✓ Timing constants (bomb intervals, attack intervals)

### Actor (test_actor.gd)
✓ Actor creation
✓ Movement properties
✓ Boundary constraints
✓ State flags (can_be_hit, is_deleted, etc.)

### Collision Manager (test_collision.gd)
✓ CollisionManager creation
✓ Grid initialization (8x6 quadrants)
✓ Actor quadrant assignment

### Game (test_game.gd)
✓ Game creation and initialization
✓ Game state machine (MENU, PLAYING, PAUSED)
✓ Score system with multipliers
✓ Lives system (add/lose lives)

## Test Results

All tests are designed to:
1. Print test names as they run
2. Show ✓ for passing tests
3. Show ✗ for failing tests with details
4. Print summary (X passed, Y failed)

Expected output: **All tests should pass** ✓
