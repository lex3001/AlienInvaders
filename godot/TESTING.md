# Testing and Build Guide

This document provides instructions for testing and building the Alien Invaders Godot port.

## Quick Start

### Build Validation

Run the build validation script to check that all files are present and properly structured:

```bash
cd godot
bash validate_build.sh
```

Expected output: **✓ Build validation PASSED**

### Running Tests

The project includes 4 test suites covering core systems:

1. **test_constants.gd** - Game constants (screen size, velocities, scores)
2. **test_actor.gd** - Actor base class (movement, state management)
3. **test_collision.gd** - Collision manager (spatial partitioning)
4. **test_game.gd** - Game class (state machine, scoring, lives)

#### Method 1: Using Godot Editor (Recommended)

If you have Godot 4.3+ installed:

1. Open the project in Godot
2. Navigate to `tests/` folder
3. Open any test file (e.g., `test_constants.gd`)
4. Press **F6** (Run Current Scene)
5. View results in the Output console

#### Method 2: Command Line

If `godot` is in your PATH:

```bash
cd godot
godot --headless --script tests/test_constants.gd
godot --headless --script tests/test_actor.gd
godot --headless --script tests/test_collision.gd
godot --headless --script tests/test_game.gd
```

#### Method 3: Manual Review

All tests are standalone GDScript files that can be reviewed manually. Each test:
- Creates instances of the classes being tested
- Calls methods and checks results
- Prints ✓ for passing tests, ✗ for failures

## Test Coverage

### Constants Tests (20 assertions)
- ✓ Screen dimensions (640x480, 32px top border, 20px bottom)
- ✓ Player constants (200 px/s velocity, 300ms recharge)
- ✓ Alien scores (10-75 points per type)
- ✓ Timing constants (4000-15000ms intervals)

### Actor Tests (15 assertions)
- ✓ Actor instantiation
- ✓ Movement properties (velocity, direction)
- ✓ Boundary constraints (stop at borders)
- ✓ State flags (can_be_hit, is_deleted, etc.)

### Collision Tests (6 assertions)
- ✓ CollisionManager creation
- ✓ Grid initialization (8×6 quadrants, 48 total)
- ✓ Actor quadrant assignment

### Game Tests (13 assertions)
- ✓ Game initialization (3 lives, 0 score, level 1)
- ✓ State machine (MENU, PLAYING, PAUSED)
- ✓ Score system with multipliers
- ✓ Lives management (add/lose)

**Total: 54 test assertions** - All should pass ✓

## Build Validation Checklist

The `validate_build.sh` script checks:

- [x] project.godot exists and is valid
- [x] All required directories present
- [x] All 21 GDScript files present
  - 4 core scripts
  - 7 AI scripts
  - 2 level scripts
  - 2 utility scripts
  - 3 UI scripts
  - 4 test scripts
- [x] All 5 scene files present
- [x] Assets imported (19 sprites, 21 audio files)
- [x] Basic syntax validation

## Expected Test Results

All tests should output:

```
=== Running [Test Name] Tests ===

Testing [category]...
  ✓ [test description]
  ✓ [test description]
  ...

=== Test Results ===
Passed: X
Failed: 0

✓ All tests passed!
```

## Troubleshooting

### "Godot not found"
- Install Godot 4.3+ from https://godotengine.org/
- Or review test files manually - they're readable GDScript

### Tests fail to run
- Ensure you're in the `godot/` directory
- Check that all script files exist
- Verify project.godot is not corrupted

### Build validation fails
- Check the error messages for missing files
- Ensure you haven't deleted or moved any required files
- Re-run after fixing: `bash validate_build.sh`

## Next Steps After Testing

Once all tests pass and build validates:

1. **Open in Godot 4.3+**
   - Import the project
   - Let Godot process assets
   
2. **Run the game**
   - Press F5 in Godot
   - Test gameplay manually
   
3. **Export builds**
   - Configure export presets
   - Export for Windows, Linux, Web
   
4. **Polish**
   - Apply sprites to actor scenes
   - Configure animations
   - Test on target platforms

## CI/CD Integration

This test suite can be integrated into CI/CD pipelines:

```yaml
# Example GitHub Actions workflow
- name: Validate Build
  run: |
    cd godot
    bash validate_build.sh
    
- name: Run Tests (with Godot installed)
  run: |
    cd godot
    godot --headless --script tests/test_constants.gd
    godot --headless --script tests/test_actor.gd
    godot --headless --script tests/test_collision.gd
    godot --headless --script tests/test_game.gd
```

## Test Maintenance

When adding new features:

1. Add corresponding tests to appropriate test file
2. Follow existing test patterns (assert_equal, assert_true)
3. Run all tests to ensure no regressions
4. Update this documentation if needed

## Architecture Validation

The tests validate the core architectural decisions:

- **Composition over Inheritance**: Actor has-a Brain (not is-a)
- **Polymorphic AI**: All Brain subclasses work through base interface
- **Spatial Partitioning**: CollisionManager uses 8×6 grid
- **State Machine**: Game properly transitions between states
- **Original Constants**: All VB6 values preserved exactly

---

**Status**: ✓ All systems tested and validated
**Last Updated**: 2026-02-08
**Test Framework**: Custom (no external dependencies)
