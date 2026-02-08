# test_constants.gd
# Tests for game constants

extends Node

var tests_passed = 0
var tests_failed = 0

func _ready():
print("\n=== Running Constants Tests ===")

test_screen_dimensions()
test_player_constants()
test_alien_scores()
test_timing_constants()

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

func test_screen_dimensions():
print("\nTesting screen dimensions...")
assert_equal(GameConstants.SCREEN_WIDTH, 640, "Screen width is 640")
assert_equal(GameConstants.SCREEN_HEIGHT, 480, "Screen height is 480")
assert_equal(GameConstants.TOP_BORDER, 32, "Top border is 32")
assert_equal(GameConstants.BOTTOM_BORDER, 20, "Bottom border is 20")
assert_equal(GameConstants.PLAY_HEIGHT, 428, "Play height is calculated correctly")

func test_player_constants():
print("\nTesting player constants...")
assert_equal(GameConstants.PLAYER_VELOCITY, 200.0, "Player velocity is 200")
assert_equal(GameConstants.PLAYER_MISSILE_RECHARGE_MS, 300, "Missile recharge is 300ms")
assert_equal(GameConstants.PLAYER_MISSILE_VELOCITY, 400.0, "Missile velocity is 400")
assert_equal(GameConstants.MAX_MISSILES, 10, "Max missiles is 10")

func test_alien_scores():
print("\nTesting alien scores...")
assert_equal(GameConstants.ALIENA_SCORE, 10, "Alien A score is 10")
assert_equal(GameConstants.ALIENB_SCORE, 25, "Alien B score is 25")
assert_equal(GameConstants.ALIENC_SCORE, 50, "Alien C score is 50")
assert_equal(GameConstants.ALIEND_SCORE, 50, "Alien D score is 50")
assert_equal(GameConstants.ALIENE_SCORE, 75, "Alien E score is 75")

func test_timing_constants():
print("\nTesting timing constants...")
assert_equal(GameConstants.ALIENA_BOMB_INTERVAL_MS, 4000, "Alien A bomb interval is 4000ms")
assert_equal(GameConstants.ALIEND_BOMB_INTERVAL_MS, 5000, "Alien D bomb interval is 5000ms")
assert_equal(GameConstants.ALIENC_ATTACK_INTERVAL_MS, 8000, "Alien C attack interval is 8000ms")
assert_equal(GameConstants.ALIENE_ATTACK_INTERVAL_MS, 15000, "Alien E attack interval is 15000ms")
