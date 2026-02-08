# test_collision.gd
# Tests for CollisionManager

extends Node

var tests_passed = 0
var tests_failed = 0

func _ready():
print("\n=== Running Collision Manager Tests ===")

test_collision_manager_creation()
test_grid_initialization()
test_actor_quadrant_assignment()

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

func test_collision_manager_creation():
print("\nTesting collision manager creation...")
var cm = CollisionManager.new()

assert_true(cm != null, "CollisionManager can be created")
assert_equal(cm.grid_width, 8, "Grid width is 8")
assert_equal(cm.grid_height, 6, "Grid height is 6")

cm.queue_free()

func test_grid_initialization():
print("\nTesting grid initialization...")
var cm = CollisionManager.new()
cm._initialize_grid()

var expected_quadrants = 8 * 6
assert_equal(cm.quadrants.size(), expected_quadrants, "Correct number of quadrants created")
assert_true(cm.quadrant_width > 0, "Quadrant width calculated")
assert_true(cm.quadrant_height > 0, "Quadrant height calculated")

cm.queue_free()

func test_actor_quadrant_assignment():
print("\nTesting actor quadrant assignment...")
var cm = CollisionManager.new()
cm._initialize_grid()

var actor = Actor.new()
actor.position = Vector2(100, 100)

cm.clear_all_quadrants()
cm.add_actor_to_quadrants(actor)

var found = false
for quadrant in cm.quadrants:
if quadrant["actors"].size() > 0:
found = true
break

assert_true(found, "Actor added to at least one quadrant")

actor.queue_free()
cm.queue_free()
