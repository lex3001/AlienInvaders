# BrainAlienA.gd
# Alien Type A - Formation Flyer (Swarmer)
# Simple formation follower, drops bombs periodically
# Port from vb6/BrainsAlienA.cls

extends Brain

class_name BrainAlienA

enum State {
	NORMAL,
	EXPLODING
}

var state: State = State.NORMAL


func reset_brain_state() -> void:
	state = State.NORMAL
	
	if actor:
		actor.can_be_hit_by_missiles = true
		actor.can_hit_player = false
		actor.must_be_destroyed = true
		if actor.has_animation("normal"):
			actor.play_animation("normal", true)

func update_state(delta: float) -> void:
	if not actor or not level:
		return
	
	var ticks_passed = delta * 1000.0  # Convert to milliseconds
	
	match state:
		State.NORMAL:
			_update_normal_state(ticks_passed)
		State.EXPLODING:
			_update_exploding_state(ticks_passed)

func _update_normal_state(_ticks_passed: float) -> void:
	# Check for hit
	if actor.was_hit_by_missile > 0:
		actor.was_hit_by_missile = 0
		state = State.EXPLODING
		actor.can_be_hit_by_missiles = false
		
		# Add score
		if level.has_method("add_score"):
			level.add_score(Constants.ALIENA_SCORE)
		
		# Play explosion
		_play_explosion()
		return
	
	# VB6 AlienA does not drop bombs in Level1.

func _update_exploding_state(_ticks_passed: float) -> void:
	# Check if explosion animation is complete
	if actor.is_animation_playing():
		return
	
	# Mark for deletion
	actor.is_deleted = true

func _play_explosion() -> void:
	# Play explosion animation and sound
	if actor.has_animation("explode"):
		actor.play_animation("explode")
	
	if level.has_method("play_sound"):
		level.play_sound("WHOOSH")
