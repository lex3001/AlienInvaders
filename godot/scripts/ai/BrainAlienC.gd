# BrainAlienC.gd
# Alien Type C - Aggressive Attacker
# Detects player and attacks when in range
# Port from vb6/BrainsAlienC.cls

extends Brain

class_name BrainAlienC

enum State {
	NORMAL,
	ATTACKING,
	EXPLODING
}

var state: State = State.NORMAL

enum AttackDirection {
	NONE,
	LEFT,
	RIGHT
}

var last_attack_direction: AttackDirection = AttackDirection.NONE

# Attack behavior
var attack_range: int = Constants.ALIENC_ATTACK_RANGE
var attack_interval_ms: float = Constants.ALIENC_ATTACK_INTERVAL_MS

func reset_brain_state() -> void:
	state = State.NORMAL
	last_attack_direction = AttackDirection.NONE
	
	if actor:
		actor.can_be_hit_by_missiles = true
		actor.can_hit_player = false
		actor.must_be_destroyed = true
		if actor.has_animation("normal"):
			actor.play_animation("normal")

func update_state(delta: float) -> void:
	if not actor or not level:
		return
	
	var ticks_passed = delta * 1000.0
	
	match state:
		State.NORMAL:
			_update_normal_state(ticks_passed)
		State.ATTACKING:
			_update_attacking_state(ticks_passed)
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
			level.add_score(10)
		
		_play_explosion()
		return
	
	# VB6 uses a per-tick probability for attacking when in range.
	if _is_player_in_range() and randf() < (ticks_passed / attack_interval_ms):
		state = State.ATTACKING
		actor.can_hit_player = true
		actor.movement_type = Actor.MovementType.NORMAL
		actor.velocity_direction = 90.0
		actor.velocity_magnitude = 80.0
		actor.acceleration = 500.0
		actor.stop_at_border_bottom = true
		actor.stop_at_border_left = false
		actor.stop_at_border_right = false

		var player_pos = level.get_player_position()
		var attack_dir = AttackDirection.RIGHT if player_pos.x > actor.position.x else AttackDirection.LEFT
		_apply_attack_direction(attack_dir)
		return

func _update_attacking_state(_ticks_passed: float) -> void:
	if actor.was_hit_by_missile > 0 or actor.is_at_border_bottom:
		var bonus_points = 50
		if actor.was_hit_by_missile > 0:
			bonus_points = 75
		actor.was_hit_by_missile = 0
		state = State.EXPLODING
		actor.can_be_hit_by_missiles = false
		actor.can_hit_player = true
		if level.has_method("add_score"):
			level.add_score(10)
		if level.has_method("add_bonus"):
			level.add_bonus(bonus_points, actor.position)
		actor.acceleration = 0.0
		_play_explosion()
		return

	var player_pos = level.get_player_position()
	var attack_dir = AttackDirection.RIGHT if player_pos.x > actor.position.x else AttackDirection.LEFT
	_apply_attack_direction(attack_dir)

	if actor.is_at_border_bottom:
		actor.velocity_magnitude = 0.0
		actor.acceleration = 0.0

func _is_player_in_range() -> bool:
	if not level.has_method("get_player_position"):
		return false
	
	var player_pos = level.get_player_position()
	var distance = abs(actor.position.x - player_pos.x)
	
	return distance <= attack_range

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
		level.play_sound("WHOOSH")

func _apply_attack_direction(direction: AttackDirection) -> void:
	if last_attack_direction == direction:
		return
	if direction == AttackDirection.RIGHT:
		if actor.has_animation("attack_right"):
			actor.play_animation("attack_right")
		actor.acceleration_direction = 0.0
		last_attack_direction = AttackDirection.RIGHT
	elif direction == AttackDirection.LEFT:
		if actor.has_animation("attack_left"):
			actor.play_animation("attack_left")
		actor.acceleration_direction = 180.0
		last_attack_direction = AttackDirection.LEFT
