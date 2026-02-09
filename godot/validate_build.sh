#!/bin/bash
# validate_build.sh
# Validates the Godot project structure and code

set -e

echo "╔════════════════════════════════════════╗"
echo "║  Alien Invaders - Build Validation    ║"
echo "╚════════════════════════════════════════╝"
echo ""

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="${PROJECT_DIR:-$SCRIPT_DIR}"
cd "$PROJECT_DIR"

ERRORS=0
WARNINGS=0

# Check project file
echo "▶ Checking project configuration..."
if [ -f "project.godot" ]; then
    echo "  ✓ project.godot exists"
else
    echo "  ✗ project.godot missing"
    ((ERRORS++))
fi

# Check required directories
echo ""
echo "▶ Checking directory structure..."
for dir in "scripts/core" "scripts/ai" "scripts/level" "scripts/utils" "scripts/ui" "scenes" "scenes/actors" "assets/sprites" "assets/audio" "tests"; do
    if [ -d "$dir" ]; then
        echo "  ✓ $dir/"
    else
        echo "  ✗ $dir/ missing"
        ((ERRORS++))
    fi
done

# Check core script files
echo ""
echo "▶ Checking core scripts..."
CORE_SCRIPTS=(
    "scripts/core/Constants.gd"
    "scripts/core/Actor.gd"
    "scripts/core/Game.gd"
    "scripts/core/PowerUp.gd"
)

for script in "${CORE_SCRIPTS[@]}"; do
    if [ -f "$script" ]; then
        echo "  ✓ $script"
    else
        echo "  ✗ $script missing"
        ((ERRORS++))
    fi
done

# Check AI scripts
echo ""
echo "▶ Checking AI scripts..."
AI_SCRIPTS=(
    "scripts/ai/Brain.gd"
    "scripts/ai/BrainPlayer.gd"
    "scripts/ai/BrainAlienA.gd"
    "scripts/ai/BrainAlienB.gd"
    "scripts/ai/BrainAlienC.gd"
    "scripts/ai/BrainAlienD.gd"
    "scripts/ai/BrainAlienE.gd"
)

for script in "${AI_SCRIPTS[@]}"; do
    if [ -f "$script" ]; then
        echo "  ✓ $script"
    else
        echo "  ✗ $script missing"
        ((ERRORS++))
    fi
done

# Check test files
echo ""
echo "▶ Checking test files..."
TEST_FILES=(
    "tests/test_constants.gd"
    "tests/test_actor.gd"
    "tests/test_collision.gd"
    "tests/test_game.gd"
)

for test in "${TEST_FILES[@]}"; do
    if [ -f "$test" ]; then
        echo "  ✓ $test"
    else
        echo "  ✗ $test missing"
        ((ERRORS++))
    fi
done

# Check scene files
echo ""
echo "▶ Checking scene files..."
SCENE_FILES=(
    "scenes/Main.tscn"
    "scenes/Level.tscn"
    "scenes/actors/Player.tscn"
    "scenes/actors/Missile.tscn"
    "scenes/actors/Bomb.tscn"
)

for scene in "${SCENE_FILES[@]}"; do
    if [ -f "$scene" ]; then
        echo "  ✓ $scene"
    else
        echo "  ✗ $scene missing"
        ((ERRORS++))
    fi
done

# Count assets
echo ""
echo "▶ Checking assets..."
SPRITE_COUNT=$(find assets/sprites -name "*.bmp" 2>/dev/null | wc -l)
AUDIO_COUNT=$(find assets/audio -name "*.wav" -o -name "*.WAV" 2>/dev/null | wc -l)

echo "  ✓ Found $SPRITE_COUNT sprite files"
echo "  ✓ Found $AUDIO_COUNT audio files"

if [ $SPRITE_COUNT -lt 10 ]; then
    echo "  ⚠ Warning: Expected ~19 sprite files"
    ((WARNINGS++))
fi

if [ $AUDIO_COUNT -lt 10 ]; then
    echo "  ⚠ Warning: Expected ~21 audio files"
    ((WARNINGS++))
fi

# Syntax check for GDScript files (basic)
echo ""
echo "▶ Checking GDScript syntax..."
SYNTAX_ERRORS=0

find scripts -name "*.gd" -type f | while read -r file; do
    # Check for common syntax issues
    if grep -q "^[[:space:]]*func.*:" "$file" && ! grep -q "^[[:space:]]*func.*:$" "$file"; then
        echo "  ⚠ $file: Possible syntax issue"
        ((WARNINGS++))
    fi
done

echo "  ✓ Basic syntax check complete"

# Summary
echo ""
echo "╔════════════════════════════════════════╗"
echo "║         Validation Summary             ║"
echo "╚════════════════════════════════════════╝"
echo ""
echo "Errors: $ERRORS"
echo "Warnings: $WARNINGS"
echo ""

if [ $ERRORS -eq 0 ]; then
    echo "✓ Build validation PASSED"
    echo ""
    echo "Next steps:"
    echo "  1. Open project in Godot 4.3+"
    echo "  2. Run tests: F6 on any test file"
    echo "  3. Run game: F5"
    exit 0
else
    echo "✗ Build validation FAILED"
    echo "Fix the errors above before proceeding"
    exit 1
fi
