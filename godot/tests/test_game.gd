# test_game.gd
# Tests for Game class

extends Node

var tests_passed = 0
var tests_failed = 0

func _ready():
print("\n=== Running Game Tests ===")

test_game_creation()
test_game_state()
test_score_system()
test_lives_system()

print("\n=== Test Results ===")
print("Passed: ", tests_passed)
print("Failed: ", tests_failed)

if tests_failed == 0:
print("✓ All tests passed!")
else:
print("✗ Some tests failed")

await get_tree().create_timer(0.1).timeout
get_tree().quit()

func assert_equal(actual, expected, test_name: String):
if actual == expected:
print("  ✓ ", test_name)
tests_passed += 1
else:
print("  ✗ ", test_name, " - Expected: ", expected, ", Got: ", actual)
tests_failed += 1

func assert_true(condition: bool, test_name: String):
if condition:
print("  ✓ ", test_name)
tests_passed += 1
else:
print("  ✗ ", test_name)
tests_failed += 1

func test_game_creation():
print("\nTesting game creation...")
var game = Game.new()

assert_true(game != null, "Game can be created")
assert_equal(game.lives, 3, "Game starts with 3 lives")
assert_equal(game.score, 0, "Game starts with 0 score")
assert_equal(game.current_level, 1, "Game starts at level 1")

game.queue_free()

func test_game_state():
print("\nTesting game state...")
var game = Game.new()

assert_equal(game.game_state, GameConstants.GameState.MENU, "Initial state is MENU")

game.change_state(GameConstants.GameState.PLAYING)
assert_equal(game.game_state, GameConstants.GameState.PLAYING, "State can be changed to PLAYING")

game.change_state(GameConstants.GameState.PAUSED)
assert_equal(game.game_state, GameConstants.GameState.PAUSED, "State can be changed to PAUSED")

game.queue_free()

func test_score_system():
print("\nTesting score system...")
var game = Game.new()

game.add_score(100)
assert_equal(game.score, 100, "Score increases correctly")

game.add_score(50)
assert_equal(game.score, 150, "Score accumulates correctly")

game.score_multiplier = 2.0
game.add_score(100)
assert_equal(game.score, 350, "Score applies multiplier correctly")

game.queue_free()

func test_lives_system():
print("\nTesting lives system...")
var game = Game.new()

game.lose_life()
assert_equal(game.lives, 2, "Losing a life decrements correctly")

game.add_life()
assert_equal(game.lives, 3, "Adding a life increments correctly")

game.queue_free()
