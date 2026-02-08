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

# Movement type and restrictions
enum MovementType {
	NORMAL,
	FOLLOW_LEADER,
	MARCHING,
	CIRCULAR
}

var movement_type: MovementType = MovementType.NORMAL
var leader: Actor = null  # For follow-the-leader movement
var relative_position: Vector2 = Vector2.ZERO

# Border constraints
var stop_at_border_left: bool = false
var stop_at_border_right: bool = false
var stop_at_border_top: bool = false
var stop_at_border_bottom: bool = false

# State flags
var can_be_hit_by_missiles: bool = false
var can_hit_player: bool = false
var must_be_destroyed: bool = false
var is_deleted: bool = false
var was_hit_by_missile: bool = false
var hit_shields: bool = false
var hit_player: bool = false

# Position indicators
var is_off_screen: bool = false
var is_at_border: bool = false

# Animation
var current_animation: String = ""
var animation_player: AnimationPlayer = null

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
	match movement_type:
		MovementType.NORMAL:
			_move_normal(delta)
		MovementType.FOLLOW_LEADER:
			_move_follow_leader(delta)
		MovementType.MARCHING:
			_move_marching(delta)
		MovementType.CIRCULAR:
			_move_circular(delta)

func _move_normal(delta: float) -> void:
	# Calculate velocity vector from direction and magnitude
	var rad = GameConstants.degrees_to_radians(velocity_direction)
	velocity = Vector2(cos(rad), sin(rad)) * velocity_magnitude
	
	# Apply movement
	var new_pos = position + velocity * delta
	
	# Apply border constraints
	new_pos = apply_border_constraints(new_pos)
	
	position = new_pos

func _move_follow_leader(delta: float) -> void:
	if leader != null:
		position = leader.position + relative_position

func _move_marching(delta: float) -> void:
	# Similar to normal movement but with additional marching logic
	_move_normal(delta)

func _move_circular(delta: float) -> void:
	# Circular movement pattern (for specific alien types)
	pass

func apply_border_constraints(new_pos: Vector2) -> Vector2:
	var play_width = GameConstants.SCREEN_WIDTH
	var play_height = GameConstants.PLAY_HEIGHT
	var top = GameConstants.TOP_BORDER
	var bottom = GameConstants.SCREEN_HEIGHT - GameConstants.BOTTOM_BORDER
	
	if stop_at_border_left and new_pos.x < 0:
		new_pos.x = 0
	if stop_at_border_right and new_pos.x > play_width:
		new_pos.x = play_width
	if stop_at_border_top and new_pos.y < top:
		new_pos.y = top
	if stop_at_border_bottom and new_pos.y > bottom:
		new_pos.y = bottom
	
	return new_pos

func check_boundaries() -> void:
	var screen_width = GameConstants.SCREEN_WIDTH
	var screen_height = GameConstants.SCREEN_HEIGHT
	var top = GameConstants.TOP_BORDER
	var bottom = screen_height - GameConstants.BOTTOM_BORDER
	
	# Check if off screen
	is_off_screen = (position.x < 0 or position.x > screen_width or 
					 position.y < 0 or position.y > screen_height)
	
	# Check if at border
	is_at_border = (position.x <= 0 or position.x >= screen_width or
					position.y <= top or position.y >= bottom)

func update_animation(delta: float) -> void:
	# Animation update logic - to be overridden or managed by specific actor types
	pass

func take_damage(amount: int = 1) -> void:
	# Base damage logic
	was_hit_by_missile = true
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

func set_movement_marching(start_pos: Vector2, vel_dir: float, vel_mag: float) -> void:
	movement_type = MovementType.MARCHING
	position = start_pos
	velocity_direction = vel_dir
	velocity_magnitude = vel_mag

func get_center() -> Vector2:
	return position + (sprite.texture.get_size() / 2 if sprite and sprite.texture else Vector2.ZERO)

func get_bounds() -> Rect2:
	if sprite and sprite.texture:
		var size = sprite.texture.get_size()
		return Rect2(position, size)
	return Rect2(position, Vector2.ZERO)
