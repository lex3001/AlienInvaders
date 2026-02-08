# BrainPlayer.gd
# Player input handling and control
# Port from vb6/BrainsPlayer.cls

extends Brain

class_name BrainPlayer

# Player states
enum State {
	NORMAL,
	SHIELDS,
	EXPLODING
}

var state: State = State.NORMAL

# Movement
var velocity: float = GameConstants.PLAYER_VELOCITY

# Firing system
var missile_recharge_ticks: float = GameConstants.PLAYER_MISSILE_RECHARGE_MS
var ticks_since_last_missile: float = 0.0

# Input flags
var move_left_requested: bool = false
var move_right_requested: bool = false
var stop_move_requested: bool = false
var missile_requested: bool = false
var shields_requested: bool = false

func reset_state() -> void:
	state = State.NORMAL
	ticks_since_last_missile = missile_recharge_ticks
	
	if actor:
		actor.stop_at_border_left = true
		actor.stop_at_border_right = true
		actor.stop_at_border_top = true
		actor.stop_at_border_bottom = true
		actor.can_be_hit_by_missiles = false  # Player hit by bombs, not missiles
		actor.velocity_magnitude = 0.0

func update_state(delta: float) -> void:
	if not actor or not level:
		return
	
	var ticks_passed = delta * 1000.0  # Convert to milliseconds
	
	# Process input
	_process_input()
	
	# State machine
	match state:
		State.NORMAL:
			_update_normal_state(ticks_passed)
		State.SHIELDS:
			_update_shields_state(ticks_passed)
		State.EXPLODING:
			_update_exploding_state(ticks_passed)
	
	# Movement and firing (when alive)
	if state == State.NORMAL or state == State.SHIELDS:
		_update_movement()
		_update_firing(ticks_passed)

func _process_input() -> void:
	# Get input state
	move_left_requested = Input.is_action_pressed("move_left")
	move_right_requested = Input.is_action_pressed("move_right")
	stop_move_requested = not (move_left_requested or move_right_requested)
	missile_requested = Input.is_action_pressed("fire_missile")
	shields_requested = Input.is_action_pressed("activate_shields")

func _update_normal_state(ticks_passed: float) -> void:
	# Check for hit
	if actor.was_hit_by_missile:
		state = State.EXPLODING
		actor.velocity_magnitude = 0
		actor.can_be_hit_by_missiles = false
		# Play explosion sound and animation
		_play_explosion()
		return
	
	# Check for shield activation
	if shields_requested and level.has_method("get_shields_left"):
		var shields_left = level.get_shields_left() if level.has_method("get_shields_left") else 0
		if shields_left > 0:
			state = State.SHIELDS
			if level.has_method("set_shields_on"):
				level.set_shields_on(true)
			# Play shields animation
			_play_shields_animation()

func _update_shields_state(ticks_passed: float) -> void:
	# Drain shields
	if level.has_method("drain_shields"):
		level.drain_shields(ticks_passed)
	
	# Check for shield deactivation
	var shields_left = level.get_shields_left() if level.has_method("get_shields_left") else 0
	if not shields_requested or shields_left <= 0:
		state = State.NORMAL
		if level.has_method("set_shields_on"):
			level.set_shields_on(false)
		# Play normal animation
		_play_normal_animation()

func _update_exploding_state(ticks_passed: float) -> void:
	# Check if explosion animation is complete
	if actor.animation_player and actor.animation_player.is_playing():
		return
	
	# Mark for deletion
	actor.is_deleted = true
	if level.has_method("on_player_death"):
		level.on_player_death()

func _update_movement() -> void:
	# Player movement
	if move_left_requested:
		actor.velocity_direction = 180.0  # Left
		actor.velocity_magnitude = velocity
	elif move_right_requested:
		actor.velocity_direction = 0.0  # Right
		actor.velocity_magnitude = velocity
	elif stop_move_requested:
		actor.velocity_magnitude = 0.0

func _update_firing(ticks_passed: float) -> void:
	# Update missile recharge timer
	ticks_since_last_missile += ticks_passed
	
	# Calculate recharge time needed (rapid fire halves recharge time)
	var recharge_needed = missile_recharge_ticks
	if level.has_method("has_rapid_fire") and level.has_rapid_fire():
		recharge_needed = missile_recharge_ticks / 2.0
	
	# Fire missile if requested and recharged
	if missile_requested and ticks_since_last_missile >= recharge_needed:
		if level.has_method("fire_player_missile"):
			if level.fire_player_missile(actor):
				# Play fire sound
				_play_fire_sound()
				ticks_since_last_missile = 0.0

func _play_normal_animation() -> void:
	# Play normal player animation
	if actor.animation_player and actor.animation_player.has_animation("normal"):
		actor.animation_player.play("normal")

func _play_shields_animation() -> void:
	# Play shields animation
	if actor.animation_player and actor.animation_player.has_animation("shields"):
		actor.animation_player.play("shields")

func _play_explosion() -> void:
	# Play explosion animation and sound
	if actor.animation_player and actor.animation_player.has_animation("explode"):
		actor.animation_player.play("explode")

func _play_fire_sound() -> void:
	# Play laser sound effect
	if level.has_method("play_sound"):
		level.play_sound("LASER")
