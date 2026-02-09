# Brain.gd
# Base class for all AI behaviors
# Port from vb6/Brains.cls
# Uses Resource instead of Node for lightweight composition

extends Resource

class_name Brain

# References
var actor: Actor = null
var level: Node = null

# Base initialization - called when brain is attached to an actor
func initialize(p_actor: Actor, p_level: Node) -> void:
	actor = p_actor
	level = p_level
	reset_brain_state()

# Reset brain to initial state
func reset_brain_state() -> void:
	# Virtual method - override in derived classes
	pass

# Main update loop - called every frame
func update_state(_delta: float) -> void:
	# Virtual method - override in derived classes
	pass

# Cleanup
func terminate() -> void:
	# Virtual method - override in derived classes
	pass
