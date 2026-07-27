# BrainAlienF.gd
# Alien Type F - roaming special enemy

extends Brain

class_name BrainAlienF

enum State {
	DISABLED,
	IDLE,
	NORMAL,
	HOT_SEQUENCE,
	EXPLODING
}

enum HotPhase {
	SET2,  # Sequence 2
	SET3   # Sequence 3
}

var state: State = State.DISABLED
var unlocked: bool = false
var moving_left: bool = true
var has_entered_screen: bool = false

var wait_ticks_ms: float = 0.0
var wait_target_ms: float = 0.0

var normal_ticks_ms: float = 0.0
var hot_phase: HotPhase = HotPhase.SET2
var hot_cycle_count: int = 0  # Track how many set2/set3 pairs completed
var hot_target_position: Vector2 = Vector2.ZERO
var hot_was_moving: bool = true
var laser_active: bool = false
var laser_preview_active: bool = false
var laser_color_time: float = 0.0

var horizontal_speed: float = 72.0
var vertical_speed: float = 0.0
var vertical_change_ticks_ms: float = 0.0
var vertical_change_target_ms: float = 0.0

const HOT_TRIGGER_MS: float = 3000.0

func reset_brain_state() -> void:
	unlocked = false
	state = State.DISABLED
	wait_ticks_ms = 0.0
	wait_target_ms = _roll_wait_ms()
	normal_ticks_ms = 0.0
	hot_phase = HotPhase.SET2
	hot_cycle_count = 0
	hot_target_position = Vector2.ZERO
	hot_was_moving = true
	laser_active = false
	laser_preview_active = false
	laser_color_time = 0.0
	vertical_speed = 0.0
	vertical_change_ticks_ms = 0.0
	vertical_change_target_ms = _roll_vertical_change_ms()

	if actor:
		actor.visible = false
		actor.can_be_hit_by_missiles = false
		actor.can_hit_player = false
		actor.must_be_destroyed = false
		actor.velocity_magnitude = 0.0
		actor.velocity_direction = 0.0
		actor.was_hit_by_missile = 0

func update_state(delta: float) -> void:
	if not actor or not level:
		return

	if not unlocked and _is_unlocked_by_progress():
		unlocked = true
		_enter_idle()

	if actor.was_hit_by_missile > 0 and state != State.EXPLODING and state != State.DISABLED:
		actor.was_hit_by_missile = 0
		_enter_exploding()
		return

	var ticks_ms = delta * 1000.0

	match state:
		State.DISABLED:
			pass
		State.IDLE:
			_update_idle_state(ticks_ms)
		State.NORMAL:
			_update_normal_state(ticks_ms)
		State.HOT_SEQUENCE:
			_update_hot_sequence_state(ticks_ms)
		State.EXPLODING:
			_update_exploding_state()

func force_spawn() -> void:
	if not actor:
		return
	unlocked = true
	# Force re-spawn even if already active (for testing)
	if state == State.EXPLODING:
		return
	_start_run()

func _update_idle_state(ticks_ms: float) -> void:
	wait_ticks_ms += ticks_ms
	if wait_ticks_ms < wait_target_ms:
		return
	_start_run()

func _update_normal_state(ticks_ms: float) -> void:
	_update_motion(ticks_ms)

	if int(normal_ticks_ms / 1000.0) != int((normal_ticks_ms + ticks_ms) / 1000.0):
		if actor.sprite:
			# Force visibility if not visible
			if not actor.visible or not actor.sprite.visible:
				actor.show()
				actor.sprite.show()

	normal_ticks_ms += ticks_ms
	if normal_ticks_ms >= HOT_TRIGGER_MS:
		normal_ticks_ms = 0.0
		_enter_hot_sequence()
		return

	# Check if alien has entered the screen based on direction
	if not has_entered_screen:
		var entered = false
		if moving_left:
			# Spawned on right, entering when moving past right edge into view
			entered = actor.position.x < Constants.SCREEN_WIDTH
		else:
			# Spawned on left, entering when moving past left edge into view
			entered = actor.position.x > 0
		
		if entered:
			has_entered_screen = true

	# Only check for screen crossing after entering
	if has_entered_screen and _has_crossed_screen():
		_enter_idle()

func _enter_hot_sequence() -> void:
	state = State.HOT_SEQUENCE
	hot_phase = HotPhase.SET2
	hot_cycle_count = 0
	hot_was_moving = true
	laser_active = false
	# Lock player position at START of hot sequence
	hot_target_position = _get_player_position_snapshot()
	# Stop moving
	actor.velocity_magnitude = 0.0
	# One-frame preview of laser path
	laser_preview_active = true
	actor.queue_redraw()
	if actor.has_animation("hot_set2"):
		actor.play_animation("hot_set2")

func _update_hot_sequence_state(ticks_ms: float) -> void:
	# Update laser color oscillation if active
	if laser_active:
		laser_color_time += ticks_ms
		actor.queue_redraw()  # Trigger _draw callback every frame
	
	# Don't move during hot sequence
	
	# Wait for animation to finish
	if actor.is_animation_playing():
		# Check if we left screen during hot sequence
		if _has_crossed_screen():
			_enter_idle()
		return
	
	# Animation finished, process phase transition
	if hot_phase == HotPhase.SET2:
		# Just finished set2, move to set3
		if hot_cycle_count < 1:
			# Not the final cycle, just play set3
			hot_phase = HotPhase.SET3
			if actor.has_animation("hot_set3"):
				actor.play_animation("hot_set3")
		else:
			# Final cycle (2nd set2 done), play set3 with laser
			hot_phase = HotPhase.SET3
			laser_active = true
			if actor.has_animation("hot_set3"):
				actor.play_animation("hot_set3")
	elif hot_phase == HotPhase.SET3:
		# Just finished set3
		if laser_active:
			# Was the final cycle with laser, return to normal
			laser_active = false
			state = State.NORMAL
			normal_ticks_ms = 0.0
			# Resume movement
			if hot_was_moving:
				var x_speed = -horizontal_speed if moving_left else horizontal_speed
				var move_vec = Vector2(x_speed, vertical_speed)
				actor.velocity_magnitude = move_vec.length()
				if move_vec.length() > 0.001:
					actor.velocity_direction = rad_to_deg(atan2(move_vec.y, move_vec.x))
			if actor.has_animation("normal"):
				actor.play_animation("normal")
			actor.queue_redraw()  # Clear laser
		else:
			# Not final cycle, increment and go back to set2
			hot_cycle_count += 1
			hot_phase = HotPhase.SET2
			if actor.has_animation("hot_set2"):
				actor.play_animation("hot_set2")

func _update_exploding_state() -> void:
	if actor.is_animation_playing():
		return
	_enter_idle()

func _start_run() -> void:
	state = State.NORMAL
	normal_ticks_ms = 0.0
	vertical_speed = randf_range(-18.0, 18.0)
	vertical_change_ticks_ms = 0.0
	vertical_change_target_ms = _roll_vertical_change_ms()
	moving_left = randf() < 0.5
	has_entered_screen = false  # Reset flag for new run

	actor.visible = true
	actor.can_be_hit_by_missiles = true
	actor.can_hit_player = false
	actor.was_hit_by_missile = 0
	print("[AlienF] Spawned - visible: ", actor.visible, " pos: ", actor.position)
	
	# Explicitly ensure sprite is visible
	if actor.sprite:
		actor.sprite.visible = true
		actor.sprite.modulate = Color(1, 1, 1, 1)  # Full opacity

	# Always spawn off-screen (left or right edge)
	# Only spawn in top 33% of play area
	var spawn_y_min = Constants.TOP_BORDER + 36.0
	if level is Level:
		spawn_y_min = (level as Level).play_y_offset + 24.0
	var play_area_height = Constants.SCREEN_HEIGHT - Constants.BOTTOM_BORDER - spawn_y_min
	var top_third_height = play_area_height * 0.33
	var spawn_y_max = spawn_y_min + top_third_height
	actor.position.y = randf_range(spawn_y_min, spawn_y_max)

	var half_w = _get_width() * 0.5
	if moving_left:
		actor.position.x = Constants.SCREEN_WIDTH + half_w + 2.0
	else:
		actor.position.x = -half_w - 2.0

	if actor.sprite:
		# Force sprite visibility and ensure it's on screen
		actor.sprite.show()
		actor.sprite.z_index = 10
	
	# Ensure actor shows
	actor.show()
	
	if actor.has_animation("normal"):
		actor.play_animation("normal", true)
	

func _enter_idle() -> void:
	state = State.IDLE
	wait_ticks_ms = 0.0
	wait_target_ms = _roll_wait_ms()
	normal_ticks_ms = 0.0
	hot_cycle_count = 0
	laser_active = false
	laser_preview_active = false

	if actor:
		print("[AlienF] Exiting - entering idle")
		actor.visible = false
		actor.can_be_hit_by_missiles = false
		actor.can_hit_player = false
		actor.velocity_magnitude = 0.0
		actor.velocity_direction = 0.0
		actor.queue_redraw()  # Clear any laser

func _enter_exploding() -> void:
	state = State.EXPLODING
	actor.can_be_hit_by_missiles = false
	actor.can_hit_player = false
	actor.velocity_magnitude = 0.0
	actor.velocity_direction = 0.0
	if actor.has_animation("explode"):
		actor.play_animation("explode")

	if level.has_method("add_random_bonus"):
		var points = level.add_random_bonus(actor.position)
		if level.has_method("add_score"):
			level.add_score(points)
	if level.has_method("play_sound"):
		level.play_sound("BOOM2")

func _update_motion(ticks_ms: float) -> void:
	vertical_change_ticks_ms += ticks_ms
	if vertical_change_ticks_ms >= vertical_change_target_ms:
		vertical_change_ticks_ms = 0.0
		vertical_change_target_ms = _roll_vertical_change_ms()
		vertical_speed = clampf(vertical_speed + randf_range(-16.0, 16.0), -36.0, 36.0)

	var x_speed = -horizontal_speed if moving_left else horizontal_speed
	var move_vec = Vector2(x_speed, vertical_speed)
	if move_vec.length() > 0.001:
		actor.velocity_direction = rad_to_deg(atan2(move_vec.y, move_vec.x))
		actor.velocity_magnitude = move_vec.length()

	var top_limit = Constants.TOP_BORDER + 20.0
	if level is Level:
		top_limit = (level as Level).play_y_offset + 10.0
	var bottom_limit = Constants.SCREEN_HEIGHT - Constants.BOTTOM_BORDER - 80.0
	if actor.position.y < top_limit:
		actor.position.y = top_limit
		vertical_speed = abs(vertical_speed)
	elif actor.position.y > bottom_limit:
		actor.position.y = bottom_limit
		vertical_speed = -abs(vertical_speed)

func _has_crossed_screen() -> bool:
	if moving_left:
		return actor.is_off_screen_left
	return actor.is_off_screen_right

func _get_width() -> float:
	if actor and actor.sprite and actor.sprite.region_enabled:
		return actor.sprite.region_rect.size.x
	return 16.0

func _roll_wait_ms() -> float:
	return randf_range(6000.0, 18000.0)

func _roll_vertical_change_ms() -> float:
	return randf_range(450.0, 1300.0)

func _is_unlocked_by_progress() -> bool:
	if not level:
		return false
	if level is Level and (level as Level).game:
		var game = (level as Level).game
		# Unlock after first complete loop through all levels
		return game.actual_level_number > game.NUM_LEVELS
	return false

func _get_player_position_snapshot() -> Vector2:
	if level and level.has_method("get_player_position"):
		return level.get_player_position()
	return Vector2(actor.position.x, Constants.SCREEN_HEIGHT)

func draw_custom(drawing_actor: Actor) -> void:
	if not drawing_actor:
		return
	if not laser_active and not laser_preview_active:
		return
	
	# Calculate laser start position (bottom-middle of AlienF)
	var laser_start = Vector2.ZERO  # Local coordinates (relative to actor)
	if drawing_actor.sprite and drawing_actor.sprite.region_enabled:
		var sprite_height = drawing_actor.sprite.region_rect.size.y
		laser_start.y = sprite_height * 0.5  # Bottom of sprite
	
	# Calculate laser end position (target in world space, convert to local)
	var laser_end_world = hot_target_position
	
	# Laser goes all the way to bottom of screen before HUD
	var screen_bottom = Constants.SCREEN_HEIGHT - Constants.BOTTOM_BORDER
	laser_end_world.y = screen_bottom
	laser_end_world.x = clampf(laser_end_world.x, 0, Constants.SCREEN_WIDTH)
	
	# Convert to local coordinates
	var laser_end = laser_end_world - drawing_actor.global_position

	# Draw one-frame preview (grey, 75% transparent)
	if laser_preview_active:
		drawing_actor.draw_line(laser_start, laser_end, Color(0.6, 0.6, 0.6, 0.25), 2.5, true)
		laser_preview_active = false
		return
	
	# Calculate oscillating color (ultraviolet/blue spectrum)
	var color_phase = sin(laser_color_time * 0.01)  # Oscillate
	var light_amt = (color_phase + 1.0) * 0.5  # 0 to 1
	# Ultraviolet: bright blue to deep purple
	var r = 0.4 + (light_amt * 0.6)  # 0.4 to 1.0 (purple to white-ish)
	var g = 0.0 + (light_amt * 0.4)  # 0.0 to 0.4 (add some for lighter blue)
	var b = 1.0  # Full blue always
	var laser_color = Color(r, g, b, 0.6)  # 60% transparency
	
	# Draw the laser line with antialiasing
	drawing_actor.draw_line(laser_start, laser_end, laser_color, 2.5, true)
	
	if level and level.has_method("get_player"):
		var player = level.get_player()
		if player and not player.is_deleted:
			# Check if shields are on
			var shields_active = false
			if level.has_method("is_shields_on"):
				shields_active = level.is_shields_on()
			
			if shields_active:
				return  # Shields protect from laser
			
			# Check if laser intersects with player
			if _check_laser_player_collision(laser_start + drawing_actor.global_position, laser_end_world, player):
				# Hit the player
				player.was_hit_by_missile += 1

func _check_laser_player_collision(laser_start_world: Vector2, laser_end_world: Vector2, player: Actor) -> bool:
	if not player or not player.sprite:
		return false
	
	# Get player bounds
	var player_pos = player.global_position
	var player_rect = Rect2()
	if player.sprite.region_enabled:
		var half_size = player.sprite.region_rect.size * 0.5
		player_rect = Rect2(player_pos - half_size, player.sprite.region_rect.size)
	else:
		player_rect = Rect2(player_pos - Vector2(8, 8), Vector2(16, 16))
	
	# Check if laser line intersects player rectangle using line-rect intersection
	# Simple approach: check if laser crosses the player's bounding box
	var laser_length = laser_start_world.distance_to(laser_end_world)
	
	# Check multiple points along the laser
	var steps = int(laser_length / 2.0)  # Check every 2 pixels
	for i in range(steps + 1):
		var t = float(i) / float(steps) if steps > 0 else 0.0
		var point = laser_start_world.lerp(laser_end_world, t)
		if player_rect.has_point(point):
			return true
	
	return false