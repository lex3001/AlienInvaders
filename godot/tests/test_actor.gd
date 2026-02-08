# test_actor.gd
# Tests for Actor class

extends Node

var tests_passed = 0
var tests_failed = 0

func _ready():
print("\n=== Running Actor Tests ===")

test_actor_creation()
test_actor_movement()
test_actor_boundaries()
test_actor_state_flags()

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

func test_actor_creation():
print("\nTesting actor creation...")
var actor = Actor.new()

assert_true(actor != null, "Actor can be created")
assert_equal(actor.velocity_magnitude, 0.0, "Initial velocity is 0")
assert_equal(actor.is_deleted, false, "Actor starts not deleted")
assert_equal(actor.movement_type, Actor.MovementType.NORMAL, "Default movement type is NORMAL")

actor.queue_free()

func test_actor_movement():
print("\nTesting actor movement...")
var actor = Actor.new()

actor.velocity_direction = 0.0
actor.velocity_magnitude = 100.0

assert_equal(actor.velocity_direction, 0.0, "Velocity direction set correctly")
assert_equal(actor.velocity_magnitude, 100.0, "Velocity magnitude set correctly")

actor.queue_free()

func test_actor_boundaries():
print("\nTesting actor boundaries...")
var actor = Actor.new()

actor.stop_at_border_left = true
actor.stop_at_border_right = true

assert_equal(actor.stop_at_border_left, true, "Left border constraint set")
assert_equal(actor.stop_at_border_right, true, "Right border constraint set")

actor.queue_free()

func test_actor_state_flags():
print("\nTesting actor state flags...")
var actor = Actor.new()

assert_equal(actor.can_be_hit_by_missiles, false, "Initial can_be_hit_by_missiles is false")
assert_equal(actor.can_hit_player, false, "Initial can_hit_player is false")
assert_equal(actor.was_hit_by_missile, false, "Initial was_hit_by_missile is false")

actor.can_be_hit_by_missiles = true
actor.must_be_destroyed = true

assert_equal(actor.can_be_hit_by_missiles, true, "can_be_hit_by_missiles can be set")
assert_equal(actor.must_be_destroyed, true, "must_be_destroyed can be set")

actor.queue_free()
