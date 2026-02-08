# BrainAlienC.gd
# Alien Type C - Aggressive Attacker
# Detects player and attacks when in range
# Port from vb6/BrainsAlienC.cls

extends Brain

class_name BrainAlienC

enum State {
	NORMAL,
	EXPLODING
}

var state: State = State.NORMAL

# Attack behavior
var attack_range: int = GameConstants.ALIENC_ATTACK_RANGE
var attack_interval_ms: float = GameConstants.ALIENC_ATTACK_INTERVAL_MS
var ticks_since_last_attack_check: float = 0.0

func reset_state() -> void:
	state = State.NORMAL
	ticks_since_last_attack_check = 0.0
	
	if actor:
		actor.can_be_hit_by_missiles = true
		actor.can_hit_player = true
		actor.must_be_destroyed = true

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
	if actor.was_hit_by_missile:
		state = State.EXPLODING
		actor.can_be_hit_by_missiles = false
		actor.can_hit_player = false
		
		# Add score
		if level.has_method("add_score"):
			level.add_score(GameConstants.ALIENC_SCORE)
		
		_play_explosion()
		return
	
	# Update attack timer
	ticks_since_last_attack_check += ticks_passed
	
	# Check if time to consider attack
	if ticks_since_last_attack_check >= attack_interval_ms:
		ticks_since_last_attack_check = 0.0
		
		# Check if player is in range
		if _is_player_in_range():
			# Drop bomb with some probability
			if randf() < 0.1:  # 10% chance when in range
				if level.has_method("drop_alien_bomb"):
					level.drop_alien_bomb(actor)

func _is_player_in_range() -> bool:
	if not level.has_method("get_player_position"):
		return false
	
	var player_pos = level.get_player_position()
	var distance = abs(actor.position.x - player_pos.x)
	
	return distance <= attack_range

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
