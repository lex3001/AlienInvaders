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
var attack_interval_ms: float = GameConstants.ALIENE_ATTACK_INTERVAL_MS
var attack_turn_interval_ms: float = GameConstants.ALIENE_ATTACK_TURN_INTERVAL_MS
var ticks_since_last_attack: float = 0.0
var ticks_in_attack: float = 0.0

# Bomb dropping
var idle_bomb_interval_ms: float = GameConstants.ALIENE_IDLE_BOMB_INTERVAL_MS
var attack_bomb_interval_ms: float = GameConstants.ALIENE_ATTACK_BOMB_INTERVAL_MS
var ticks_since_last_bomb: float = 0.0

func reset_state() -> void:
	state = State.IDLE
	ticks_since_last_attack = 0.0
	ticks_since_last_bomb = 0.0
	ticks_in_attack = 0.0
	
	if actor:
		actor.can_be_hit_by_missiles = true
		actor.can_hit_player = true
		actor.must_be_destroyed = true

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
			_update_bombing_state(ticks_passed)
		State.EXPLODING:
			_update_exploding_state(ticks_passed)

func _update_idle_state(ticks_passed: float) -> void:
	# Check for hit
	if actor.was_hit_by_missile:
		state = State.EXPLODING
		actor.can_be_hit_by_missiles = false
		actor.can_hit_player = false
		
		# Add score
		if level.has_method("add_score"):
			level.add_score(GameConstants.ALIENE_SCORE)
		
		_play_explosion()
		return
	
	# Update attack timer
	ticks_since_last_attack += ticks_passed
	
	# Check if time to attack
	if ticks_since_last_attack >= attack_interval_ms:
		ticks_since_last_attack = 0.0
		state = State.ATTACKING
		ticks_in_attack = 0.0
		return
	
	# Update idle bomb timer
	ticks_since_last_bomb += ticks_passed
	
	# Drop bomb while idle
	if ticks_since_last_bomb >= idle_bomb_interval_ms:
		if level.has_method("drop_alien_bomb"):
			if level.drop_alien_bomb(actor):
				ticks_since_last_bomb = 0.0

func _update_attacking_state(ticks_passed: float) -> void:
	# Check for hit
	if actor.was_hit_by_missile:
		state = State.EXPLODING
		actor.can_be_hit_by_missiles = false
		actor.can_hit_player = false
		
		# Add score
		if level.has_method("add_score"):
			level.add_score(GameConstants.ALIENE_SCORE)
		
		_play_explosion()
		return
	
	# Update attack time
	ticks_in_attack += ticks_passed
	
	# Check if attack phase is over
	if ticks_in_attack >= attack_turn_interval_ms:
		state = State.BOMBING
		ticks_since_last_bomb = 0.0
		return
	
	# Move toward player during attack
	if level.has_method("get_player_position"):
		var player_pos = level.get_player_position()
		var direction = (player_pos - actor.position).normalized()
		actor.velocity_direction = rad_to_deg(atan2(direction.y, direction.x))
		actor.velocity_magnitude = 150.0  # Attack speed

func _update_bombing_state(ticks_passed: float) -> void:
	# Check for hit
	if actor.was_hit_by_missile:
		state = State.EXPLODING
		actor.can_be_hit_by_missiles = false
		actor.can_hit_player = false
		
		# Add score
		if level.has_method("add_score"):
			level.add_score(GameConstants.ALIENE_SCORE)
		
		_play_explosion()
		return
	
	# Update bomb timer
	ticks_since_last_bomb += ticks_passed
	
	# Drop bombs rapidly
	if ticks_since_last_bomb >= attack_bomb_interval_ms:
		if level.has_method("drop_alien_bomb"):
			if level.drop_alien_bomb(actor):
				ticks_since_last_bomb = 0.0
	
	# Return to idle after some time
	ticks_in_attack += ticks_passed
	if ticks_in_attack >= attack_turn_interval_ms * 2:
		state = State.IDLE
		ticks_since_last_attack = 0.0
		actor.velocity_magnitude = 0.0

func _update_exploding_state(ticks_passed: float) -> void:
	# Check if explosion animation is complete
	if actor.animation_player and actor.animation_player.is_playing():
		return
	
	# Mark for deletion
	actor.is_deleted = true

func _play_explosion() -> void:
	if actor.animation_player and actor.animation_player.has_animation("explode"):
		actor.animation_player.play("explode")
	
	if level.has_method("play_sound"):
		level.play_sound("BOOM2")
