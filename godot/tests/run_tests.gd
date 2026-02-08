# run_tests.gd
# Main test runner that executes all tests

extends Node

func _ready():
print("╔════════════════════════════════════════╗")
print("║   Alien Invaders - Test Suite         ║")
print("╚════════════════════════════════════════╝")

# Run all tests
await run_test("res://tests/test_constants.gd")
await run_test("res://tests/test_actor.gd")
await run_test("res://tests/test_collision.gd")
await run_test("res://tests/test_game.gd")

print("\n╔════════════════════════════════════════╗")
print("║   All Test Suites Complete            ║")
print("╚════════════════════════════════════════╝")

get_tree().quit()

func run_test(test_path: String):
print("\n" + "="*50)
print("Running: " + test_path)
print("="*50)

var test_scene = load(test_path)
if test_scene:
var test_instance = test_scene.new()
add_child(test_instance)
await get_tree().create_timer(0.5).timeout
test_instance.queue_free()
else:
print("ERROR: Could not load test: " + test_path)
