# BrainAlienE.gd
# Alien Type E - Advanced Enemy
# Complex AI with multiple attack patterns and states
# Port from vb6/BrainsAlienE.cls

extends Brain

class_name BrainAlienE

enum State {
	IDLE,
	ATTACKING,
	BOMBING,
	EXPLODING
}

var state: State = State.IDLE

# Attack behavior
var attack_interval_ms: float = Constants.ALIENE_ATTACK_INTERVAL_MS
var attack_turn_interval_ms: float = 0.0
var ticks_since_last_turn: float = 0.0

# Bomb dropping
var idle_bomb_interval_ms: float = Constants.ALIENE_IDLE_BOMB_INTERVAL_MS
var attack_bomb_interval_ms: float = Constants.ALIENE_ATTACK_BOMB_INTERVAL_MS

var saved_movement_type: Actor.MovementType = Actor.MovementType.NORMAL
var explode_animation: String = "formation_explode"

func reset_brain_state() -> void:
	state = State.IDLE
	ticks_since_last_turn = 0.0
	_reset_attack_turn_interval()
	
	if actor:
		actor.can_be_hit_by_missiles = true
		actor.can_hit_player = false
		actor.must_be_destroyed = true
		if actor.has_animation("formation"):
			actor.play_animation("formation", true)

func update_state(delta: float) -> void:
	if not actor or not level:
		return
	
	var ticks_passed = delta * 1000.0
	
	match state:
		State.IDLE:
			_update_idle_state(ticks_passed)
		State.ATTACKING:
			_update_attacking_state(ticks_passed)
		State.BOMBING:
			_update_attacking_state(ticks_passed)
		State.EXPLODING:
			_update_exploding_state(ticks_passed)

func _update_idle_state(ticks_passed: float) -> void:
	# Check for hit
	if actor.was_hit_by_missile > 0:
		var was_attacking = state != State.IDLE
		actor.was_hit_by_missile = 0
		state = State.EXPLODING
		actor.can_be_hit_by_missiles = false
		actor.can_hit_player = false
		
		# Add score
		if level.has_method("add_score"):
			level.add_score(10)
		if was_attacking and level.has_method("add_bonus"):
			level.add_bonus(25, actor.position)
		
		_play_explosion()
		return
	
	# Drop bomb while idle (VB6 probability per tick)
	if randf() < (ticks_passed / idle_bomb_interval_ms):
		if level.has_method("drop_alien_bomb"):
			level.drop_alien_bomb(actor)

	# Check if time to attack (VB6 probability per tick)
	if randf() < (ticks_passed / attack_interval_ms):
		state = State.ATTACKING
		saved_movement_type = actor.movement_type
		actor.movement_type = Actor.MovementType.NORMAL
		actor.velocity_magnitude = 30.0
		ticks_since_last_turn = 0.0
		_reset_attack_turn_interval()
		if randf() < 0.5:
			actor.velocity_direction = 135.0
			explode_animation = "attack_left_explode"
			if actor.has_animation("attack_left"):
				actor.play_animation("attack_left")
		else:
			actor.velocity_direction = 45.0
			explode_animation = "attack_right_explode"
			if actor.has_animation("attack_right"):
				actor.play_animation("attack_right")
		actor.can_hit_player = true
		return

func _update_attacking_state(ticks_passed: float) -> void:
	# Check for hit
	if actor.was_hit_by_missile > 0:
		var was_attacking = state != State.IDLE
		actor.was_hit_by_missile = 0
		state = State.EXPLODING
		actor.can_be_hit_by_missiles = false
		actor.can_hit_player = false
		
		# Add score
		if level.has_method("add_score"):
			level.add_score(10)
		if was_attacking and level.has_method("add_bonus"):
			level.add_bonus(25, actor.position)
		
		_play_explosion()
		return
	
	# Drop bombs during attack (VB6 probability per tick)
	if randf() < (ticks_passed / attack_bomb_interval_ms):
		if level.has_method("drop_alien_bomb"):
			level.drop_alien_bomb(actor)

	# Turn at random intervals
	ticks_since_last_turn += ticks_passed
	if ticks_since_last_turn >= attack_turn_interval_ms:
		ticks_since_last_turn = 0.0
		_reset_attack_turn_interval()
		if actor.velocity_direction == 45.0:
			actor.velocity_direction = 135.0
			explode_animation = "attack_left_explode"
			if actor.has_animation("turn_left"):
				actor.play_animation("turn_left", false, "attack_left")
			elif actor.has_animation("attack_left"):
				actor.play_animation("attack_left")
		else:
			actor.velocity_direction = 45.0
			explode_animation = "attack_right_explode"
			if actor.has_animation("turn_right"):
				actor.play_animation("turn_right", false, "attack_right")
			elif actor.has_animation("attack_right"):
				actor.play_animation("attack_right")

	# Return to formation after leaving the play area
	if actor.is_off_screen_bottom:
		actor.can_hit_player = false
		actor.movement_type = saved_movement_type
		actor.velocity_magnitude = 0.0
		explode_animation = "formation_explode"
		state = State.IDLE
		if actor.has_animation("enter_formation"):
			actor.play_animation("enter_formation", false, "formation")
		elif actor.has_animation("formation"):
			actor.play_animation("formation")

func _update_bombing_state(ticks_passed: float) -> void:
	_update_attacking_state(ticks_passed)

func _update_exploding_state(_ticks_passed: float) -> void:
	# Check if explosion animation is complete
	if actor.is_animation_playing():
		return
	
	# Mark for deletion
	actor.is_deleted = true

func _play_explosion() -> void:
	if actor.has_animation(explode_animation):
		actor.play_animation(explode_animation)
	
	if level.has_method("play_sound"):
		level.play_sound("WHOOSH")

func _reset_attack_turn_interval() -> void:
	attack_turn_interval_ms = randf_range(Constants.ALIENE_ATTACK_TURN_MIN_MS, Constants.ALIENE_ATTACK_TURN_MAX_MS)
