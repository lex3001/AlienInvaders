# BrainCargoShip.gd
# Cargo ship behavior
# Port from vb6/BrainsCargoShip.cls

extends Brain

class_name BrainCargoShip

enum State {
	IDLE,
	NORMAL,
	EXPLODING,
	RETIRED
}

enum Direction {
	LEFT,
	RIGHT
}

var state: State = State.IDLE
var direction: Direction = Direction.LEFT

var max_appearances: int = 1
var appearances: int = 0
var ticks_before_appearance: float = 0.0
var ticks_passed: float = 0.0

var velocity: float = Constants.CARGO_SHIP_VELOCITY
var longest_wait_ms: float = Constants.CARGO_SHIP_LONGEST_WAIT_MS

func reset_brain_state() -> void:
	state = State.IDLE
	appearances = 0
	ticks_passed = 0.0
	ticks_before_appearance = randf_range(0.0, longest_wait_ms)
	max_appearances = _roll_max_appearances()

	if actor:
		actor.visible = false
		actor.can_be_hit_by_missiles = false
		actor.can_hit_player = false
		actor.velocity_magnitude = 0.0
		actor.velocity_direction = 0.0
		var base_y = Constants.TOP_BORDER + 10.0
		if level and level is Level:
			base_y = level.play_y_offset + 10.0
		actor.position.y = base_y
		actor.was_hit_by_missile = 0

func update_state(delta: float) -> void:
	if not actor or not level:
		return

	var ticks_ms = delta * 1000.0

	match state:
		State.IDLE:
			_update_idle_state(ticks_ms)
		State.NORMAL:
			_update_normal_state()
		State.EXPLODING:
			_update_exploding_state()
		State.RETIRED:
			pass

func _update_idle_state(ticks_ms: float) -> void:
	ticks_passed += ticks_ms
	if ticks_passed < ticks_before_appearance and not Input.is_key_pressed(KEY_S):
		return

	direction = Direction.LEFT if randf() < 0.5 else Direction.RIGHT
	_start_run()

func _start_run() -> void:
	state = State.NORMAL
	appearances += 1
	ticks_passed = 0.0

	actor.visible = true
	actor.can_be_hit_by_missiles = true
	actor.can_hit_player = false
	actor.was_hit_by_missile = 0
	actor.velocity_magnitude = velocity

	var ship_width = _get_ship_width()
	if direction == Direction.LEFT:
		actor.velocity_direction = 180.0
		actor.position.x = Constants.SCREEN_WIDTH
		if actor.has_animation("go_left"):
			actor.play_animation("go_left")
	else:
		actor.velocity_direction = 0.0
		actor.position.x = -ship_width
		if actor.has_animation("go_right"):
			actor.play_animation("go_right")

	if level.has_method("play_sound"):
		level.play_sound("HEYHEYHEY")

func _update_normal_state() -> void:
	if actor.was_hit_by_missile > 0:
		actor.was_hit_by_missile = 0
		state = State.EXPLODING
		actor.can_be_hit_by_missiles = false
		actor.velocity_magnitude = 0.0
		if direction == Direction.LEFT:
			if actor.has_animation("explode_left"):
				actor.play_animation("explode_left")
		else:
			if actor.has_animation("explode_right"):
				actor.play_animation("explode_right")
		if level.has_method("drop_cargo_ship"):
			level.drop_cargo_ship(actor)
		if level.has_method("play_sound"):
			level.play_sound("BOOM1")
		return

	if (direction == Direction.LEFT and actor.is_off_screen_left) or (
		direction == Direction.RIGHT and actor.is_off_screen_right):
		_retire_or_idle()

func _update_exploding_state() -> void:
	if actor.is_animation_playing():
		return
	_retire_or_idle()

func _retire_or_idle() -> void:
	actor.visible = false
	actor.can_be_hit_by_missiles = false
	actor.was_hit_by_missile = false
	actor.velocity_magnitude = 0.0

	if appearances >= max_appearances:
		state = State.RETIRED
	else:
		state = State.IDLE
		ticks_passed = 0.0
		ticks_before_appearance = randf_range(5000.0, longest_wait_ms)

func _get_ship_width() -> float:
	if actor and actor.sprite and actor.sprite.region_enabled:
		return actor.sprite.region_rect.size.x
	return 32.0

func _roll_max_appearances() -> int:
	var roll = randi_range(0, 5)
	if roll == 5:
		return 3
	if roll >= 3:
		return 2
	return 1
