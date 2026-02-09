# Actor.gd
# Base class for all game entities (player, aliens, projectiles)
# Port from vb6/Actor2.cls

extends Node2D

class_name Actor

# Brain reference - AI behavior controller
var brain: Brain = null

# Visual components
var sprite: Sprite2D = null
var collision_shape: CollisionShape2D = null

# Position and movement
var velocity: Vector2 = Vector2.ZERO
var velocity_direction: float = 0.0  # in degrees
var velocity_magnitude: float = 0.0  # pixels per second
var acceleration: float = 0.0
var acceleration_direction: float = 0.0  # in degrees

# Movement type and restrictions
enum MovementType {
	NORMAL,
	FOLLOW_LEADER,
	MARCHING,
	CIRCULAR,
	RADIAL
}

var movement_type: MovementType = MovementType.NORMAL
var leader: Actor = null  # For follow-the-leader movement
var relative_position: Vector2 = Vector2.ZERO

# Marching movement
var marching_distance: float = 0.0
var distance_marched: float = 0.0

# Radial movement
var radial_points: Array[Vector2] = []
var radial_ticks_per_rotation: float = 0.0
var radial_position: float = 0.0
var always_update_radial_position: bool = false

# Border constraints
var stop_at_border_left: bool = false
var stop_at_border_right: bool = false
var stop_at_border_top: bool = false
var stop_at_border_bottom: bool = false
var reverse_at_border_left: bool = false
var reverse_at_border_right: bool = false
var reverse_at_border_top: bool = false
var reverse_at_border_bottom: bool = false

# State flags
var can_be_hit_by_missiles: bool = false
var can_hit_player: bool = false
var must_be_destroyed: bool = false
var is_deleted: bool = false
var was_hit_by_missile: int = 0
var hit_shields: bool = false
var hit_player: bool = false

# Position indicators
var is_off_screen: bool = false
var is_at_border: bool = false
var is_off_screen_top: bool = false
var is_off_screen_bottom: bool = false
var is_off_screen_left: bool = false
var is_off_screen_right: bool = false
var is_at_border_top: bool = false
var is_at_border_bottom: bool = false
var is_at_border_left: bool = false
var is_at_border_right: bool = false

# Animation
var current_animation: String = ""
var animation_player: AnimationPlayer = null


var anim_frame_size: Vector2i = Vector2i.ZERO
var anim_sheet_width: int = 1
var anim_frame_defs: Array[Dictionary] = []
var anim_sequences: Dictionary = {}
var anim_current_name: String = ""
var anim_next_name: String = ""
var anim_current_frame: int = 1
var anim_direction: int = 1
var anim_ticks_since_frame: float = 0.0
var anim_finished: bool = false
var anim_playing: bool = false

# Reference to game level
var level: Node = null

func _ready():
	# Initialize sprite if not already set
	if sprite == null:
		sprite = Sprite2D.new()
		add_child(sprite)
	
	# Initialize collision shape if not already set
	if collision_shape == null:
		collision_shape = CollisionShape2D.new()
		add_child(collision_shape)
	
	# Initialize brain if set
	if brain != null:
		brain.initialize(self, level)

func _process(delta: float) -> void:
	if is_deleted:
		return
	
	# Update brain AI
	if brain != null:
		brain.update_state(delta)
	
	# Update movement
	move(delta)
	
	# Check boundaries
	check_boundaries()
	
	# Update animation
	update_animation(delta)

func move(delta: float) -> void:
	if always_update_radial_position or movement_type == MovementType.RADIAL:
		_update_radial_position(delta)
	match movement_type:
		MovementType.NORMAL:
			_move_normal(delta)
		MovementType.FOLLOW_LEADER:
			_move_follow_leader(delta)
		MovementType.MARCHING:
			_move_marching(delta)
		MovementType.CIRCULAR:
			_move_circular(delta)
		MovementType.RADIAL:
			_move_radial(delta)

func _move_normal(delta: float) -> void:
	_apply_acceleration(delta)
	# Calculate velocity vector from direction and magnitude
	var rad = deg_to_rad(velocity_direction)
	velocity = Vector2(cos(rad), sin(rad)) * velocity_magnitude
	
	# Apply movement
	var new_pos = position + velocity * delta
	
	# Apply border constraints
	new_pos = apply_border_constraints(new_pos)
	
	position = new_pos
	_apply_border_reversal()

func _move_follow_leader(_delta: float) -> void:
	if leader != null:
		position = leader.position + relative_position

func _move_marching(delta: float) -> void:
	_apply_acceleration(delta)
	var rad = deg_to_rad(velocity_direction)
	velocity = Vector2(cos(rad), sin(rad)) * velocity_magnitude
	var pixels = velocity_magnitude * delta
	var reverse_direction = false
	if marching_distance > 0.0:
		if distance_marched + pixels > marching_distance:
			pixels = marching_distance - distance_marched
			distance_marched = 0.0
			reverse_direction = true
		else:
			distance_marched += pixels

	var new_pos = position + velocity.normalized() * pixels
	new_pos = apply_border_constraints(new_pos)
	position = new_pos

	if reverse_direction:
		velocity_direction = fmod(velocity_direction + 180.0, 360.0)
	_apply_border_reversal()

func _move_circular(_delta: float) -> void:
	# Circular movement pattern (for specific alien types)
	pass

func _move_radial(delta: float) -> void:
	if radial_points.is_empty():
		return
	var index = int(radial_position) % 360
	if index < 0:
		index += 360
	position = radial_points[index]
	_apply_border_reversal()

func _update_radial_position(delta: float) -> void:
	if radial_ticks_per_rotation == 0.0:
		return
	var ticks_ms = delta * 1000.0
	var delta_degrees = 360.0 * ticks_ms / radial_ticks_per_rotation
	radial_position += delta_degrees
	if radial_position >= 360.0 or radial_position <= -360.0:
		radial_position = fmod(radial_position, 360.0)

func _apply_acceleration(delta: float) -> void:
	if acceleration == 0.0:
		return
	var vel_rad = deg_to_rad(velocity_direction)
	var vel_vec = Vector2(cos(vel_rad), sin(vel_rad)) * velocity_magnitude
	var accel_rad = deg_to_rad(acceleration_direction)
	var accel_vec = Vector2(cos(accel_rad), sin(accel_rad)) * acceleration
	vel_vec += accel_vec * delta
	velocity_magnitude = vel_vec.length()
	if velocity_magnitude > 0.001:
		velocity_direction = rad_to_deg(atan2(vel_vec.y, vel_vec.x))

func apply_border_constraints(new_pos: Vector2) -> Vector2:
	var play_width = Constants.SCREEN_WIDTH
	var top = Constants.TOP_BORDER
	var bottom = Constants.SCREEN_HEIGHT - Constants.BOTTOM_BORDER
	var size = _get_sprite_size()
	var half_size = size / 2.0
	var left_limit = 0.0 + half_size.x
	var right_limit = play_width - half_size.x
	var top_limit = top + half_size.y
	var bottom_limit = bottom - half_size.y
	
	if stop_at_border_left and new_pos.x < left_limit:
		new_pos.x = left_limit
	if stop_at_border_right and new_pos.x > right_limit:
		new_pos.x = right_limit
	if stop_at_border_top and new_pos.y < top_limit:
		new_pos.y = top_limit
	if stop_at_border_bottom and new_pos.y > bottom_limit:
		new_pos.y = bottom_limit
	
	return new_pos

func _apply_border_reversal() -> void:
	var play_width = Constants.SCREEN_WIDTH
	var top = Constants.TOP_BORDER
	var bottom = Constants.SCREEN_HEIGHT - Constants.BOTTOM_BORDER
	var size = _get_sprite_size()
	var half_size = size / 2.0
	var left_limit = 0.0 + half_size.x
	var right_limit = play_width - half_size.x
	var top_limit = top + half_size.y
	var bottom_limit = bottom - half_size.y
	var reversed = false

	if reverse_at_border_left and position.x < left_limit:
		position.x = left_limit
		velocity_direction = fmod(180.0 - velocity_direction + 360.0, 360.0)
		reversed = true
	if reverse_at_border_right and position.x > right_limit:
		position.x = right_limit
		velocity_direction = fmod(180.0 - velocity_direction + 360.0, 360.0)
		reversed = true
	if reverse_at_border_top and position.y < top_limit:
		position.y = top_limit
		velocity_direction = fmod(360.0 - velocity_direction, 360.0)
		reversed = true
	if reverse_at_border_bottom and position.y > bottom_limit:
		position.y = bottom_limit
		velocity_direction = fmod(360.0 - velocity_direction, 360.0)
		reversed = true

	if reversed:
		velocity = Vector2.ZERO

func check_boundaries() -> void:
	var screen_width = Constants.SCREEN_WIDTH
	var screen_height = Constants.SCREEN_HEIGHT
	var top = Constants.TOP_BORDER
	var bottom = screen_height - Constants.BOTTOM_BORDER
	var size = _get_sprite_size()
	var half_size = size / 2.0
	var left_edge = position.x - half_size.x
	var right_edge = position.x + half_size.x
	var top_edge = position.y - half_size.y
	var bottom_edge = position.y + half_size.y
	
	# Check if off screen
	is_off_screen_left = right_edge < 0
	is_off_screen_right = left_edge > screen_width
	is_off_screen_top = bottom_edge < 0
	is_off_screen_bottom = top_edge > screen_height
	is_off_screen = (is_off_screen_left or is_off_screen_right or
					 is_off_screen_top or is_off_screen_bottom)
	
	# Check if at border
	is_at_border_left = left_edge <= 0
	is_at_border_right = right_edge >= screen_width
	is_at_border_top = top_edge <= top
	is_at_border_bottom = bottom_edge >= bottom
	is_at_border = (is_at_border_left or is_at_border_right or
					 is_at_border_top or is_at_border_bottom)

func update_animation(_delta: float) -> void:
	if not anim_playing or anim_current_name.is_empty():
		return
	if not anim_sequences.has(anim_current_name):
		return
	if anim_frame_size == Vector2i.ZERO:
		return

	anim_ticks_since_frame += _delta * 1000.0
	var seq = anim_sequences[anim_current_name]
	if anim_ticks_since_frame > float(seq["ticks"]):
		anim_ticks_since_frame = 0.0
		_advance_animation(seq)

	_apply_animation_frame(seq)

func configure_animation(frame_size: Vector2i, sheet_width: int, frame_defs: Array,
		sequences: Dictionary, default_sequence: String, start_random: bool = false) -> void:
	anim_frame_size = frame_size
	anim_sheet_width = max(sheet_width, 1)
	var typed_defs: Array[Dictionary] = []
	for entry in frame_defs:
		typed_defs.append(entry)
	anim_frame_defs = typed_defs
	anim_sequences = sequences
	if sprite:
		sprite.region_enabled = true
	play_animation(default_sequence, start_random)

func has_animation(anim_name: String) -> bool:
	return anim_sequences.has(anim_name)

func play_animation(anim_name: String, start_random: bool = false, next_name: String = "") -> void:
	if not anim_sequences.has(anim_name):
		return
	anim_current_name = anim_name
	anim_next_name = next_name
	anim_finished = false
	anim_playing = true
	anim_ticks_since_frame = 0.0
	var seq = anim_sequences[anim_name]
	var loop_type = int(seq["loop"])
	var num_frames = int(seq["count"])
	var start_at_end = loop_type == Constants.ANIM_LOOP_NONE_REVERSE or loop_type == Constants.ANIM_LOOP_ONE_WAY_REVERSE
	anim_direction = -1 if start_at_end else 1
	if start_random:
		anim_current_frame = randi_range(1, num_frames)
	else:
		anim_current_frame = num_frames if start_at_end else 1

func is_animation_playing() -> bool:
	return anim_playing and not anim_finished

func _advance_animation(seq: Dictionary) -> void:
	var loop_type = int(seq["loop"])
	var num_frames = int(seq["count"])
	if anim_direction > 0:
		if anim_current_frame >= num_frames:
			if loop_type == Constants.ANIM_LOOP_NONE:
				anim_finished = true
				anim_playing = false
				if not anim_next_name.is_empty():
					play_animation(anim_next_name)
				return
			elif loop_type == Constants.ANIM_LOOP_ONE_WAY:
				anim_current_frame = 1
			elif loop_type == Constants.ANIM_LOOP_TWO_WAY:
				anim_direction = -1
			else:
				anim_current_frame = 1
		else:
			anim_current_frame += 1
	else:
		if anim_current_frame <= 1:
			if loop_type == Constants.ANIM_LOOP_NONE_REVERSE:
				anim_finished = true
				anim_playing = false
				if not anim_next_name.is_empty():
					play_animation(anim_next_name)
				return
			elif loop_type == Constants.ANIM_LOOP_ONE_WAY_REVERSE:
				anim_current_frame = num_frames
			elif loop_type == Constants.ANIM_LOOP_TWO_WAY:
				anim_direction = 1
			else:
				anim_current_frame = num_frames
		else:
			anim_current_frame -= 1

func _apply_animation_frame(seq: Dictionary) -> void:
	if sprite == null:
		return
	var frame_number = int(seq["start"]) + anim_current_frame - 1
	var global_index = frame_number - 1
	var frame_def = _get_frame_def(frame_number)
	var col = global_index % anim_sheet_width
	var row = int(float(global_index) / float(anim_sheet_width))
	var origin = Vector2(col * anim_frame_size.x, row * anim_frame_size.y) + frame_def["offset"]
	var size = frame_def["size"]
	sprite.region_rect = Rect2(origin, size)

func _get_frame_def(frame_number: int) -> Dictionary:
	for def in anim_frame_defs:
		if frame_number >= int(def["start"]) and frame_number <= int(def["end"]):
			return def
	return {
		"offset": Vector2.ZERO,
		"size": Vector2(anim_frame_size.x, anim_frame_size.y),
		"start": 1,
		"end": 1
	}

func take_damage(_amount: int = 1) -> void:
	# Base damage logic
	was_hit_by_missile += _amount
	destroy()

func destroy() -> void:
	# Mark for deletion
	is_deleted = true
	
	# Play destruction animation/effects
	play_explosion()
	
	# Queue for removal
	queue_free()

func play_explosion() -> void:
	# Explosion effect - to be implemented
	pass

func set_movement_relative_position(p_leader: Actor, rel_pos: Vector2) -> void:
	movement_type = MovementType.FOLLOW_LEADER
	leader = p_leader
	relative_position = rel_pos
	if leader != null:
		position = leader.position + relative_position

func set_movement_normal(start_pos: Vector2, vel_mag: float, vel_dir: float) -> void:
	movement_type = MovementType.NORMAL
	position = start_pos
	velocity_magnitude = vel_mag
	velocity_direction = vel_dir

func set_movement_radial_points(points: Array[Vector2], ticks_per_rotation: float, initial_degrees: float) -> void:
	movement_type = MovementType.RADIAL
	radial_points = points
	radial_ticks_per_rotation = ticks_per_rotation
	radial_position = initial_degrees
	if not radial_points.is_empty():
		var index = int(radial_position) % 360
		if index < 0:
			index += 360
		position = radial_points[index]

func set_movement_marching(start_pos: Vector2, vel_dir: float, vel_mag: float) -> void:
	movement_type = MovementType.MARCHING
	position = start_pos
	velocity_direction = vel_dir
	velocity_magnitude = vel_mag

func get_center() -> Vector2:
	if sprite and sprite.centered:
		return position
	return position + (_get_sprite_size() / 2.0)

func get_bounds() -> Rect2:
	var size = _get_sprite_size()
	if sprite and sprite.centered:
		return Rect2(position - (size / 2.0), size)
	return Rect2(position, size)

func _get_sprite_size() -> Vector2:
	if sprite:
		if sprite.region_enabled:
			return sprite.region_rect.size
		if sprite.texture:
			return sprite.texture.get_size()
	return Vector2.ZERO
