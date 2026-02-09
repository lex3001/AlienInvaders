# BrainAlienD.gd
# Alien Type D - Orbital Bomber
# Moves in circular/orbital patterns and drops bombs
# Port from vb6/BrainsAlienD.cls

extends Brain

class_name BrainAlienD

enum State {
	NORMAL,
	EXPLODING
}

var state: State = State.NORMAL

# Bomb dropping
var bomb_interval_ms: float = Constants.ALIEND_BOMB_INTERVAL_MS
var ticks_since_last_bomb: float = 0.0

func reset_brain_state() -> void:
	state = State.NORMAL
	ticks_since_last_bomb = bomb_interval_ms - 500.0
	
	if actor:
		actor.can_be_hit_by_missiles = true
		actor.can_hit_player = true
		actor.must_be_destroyed = true
		if actor.has_animation("normal"):
			actor.play_animation("normal", true)

func update_state(delta: float) -> void:
	if not actor or not level:
		return
	
	var ticks_passed = delta * 1000.0
	
	match state:
		State.NORMAL:
			_update_normal_state(ticks_passed)
		State.EXPLODING:
			_update_exploding_state(ticks_passed)

func _update_normal_state(ticks_passed: float) -> void:
	# Check for hit
	if actor.was_hit_by_missile > 0:
		actor.was_hit_by_missile = 0
		state = State.EXPLODING
		actor.can_be_hit_by_missiles = false
		actor.can_hit_player = false
		
		# Add score
		if level.has_method("add_score"):
			level.add_score(25)
		
		_play_explosion()
		return
	
	# Update bomb timer
	ticks_since_last_bomb += ticks_passed
	
	# Drop bomb at fixed interval (VB6)
	if ticks_since_last_bomb > bomb_interval_ms:
		if level.has_method("drop_alien_bomb"):
			if level.drop_alien_bomb(actor):
				ticks_since_last_bomb = 0.0

func _update_exploding_state(_ticks_passed: float) -> void:
	# Check if explosion animation is complete
	if actor.is_animation_playing():
		return
	
	# Mark for deletion
	actor.is_deleted = true

func _play_explosion() -> void:
	if actor.has_animation("explode"):
		actor.play_animation("explode")
	
	if level.has_method("play_sound"):
		level.play_sound("BOOM2")
