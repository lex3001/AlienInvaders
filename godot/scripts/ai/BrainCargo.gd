# BrainCargo.gd
# Cargo behavior
# Port from vb6/BrainsCargo.cls

extends Brain

class_name BrainCargo

enum CargoType {
	RANDOM = -1,
	ORANGE = 0,
	PINK = 1,
	YELLOW = 2,
	BLUE = 3,
	GREEN = 4,
	PURPLE = 5,
	RED = 6,
	NAVY = 7,
	RED_DOT = 8,
	GREEN_DOT = 9,
	BLUE_DOT = 10,
	PINK_DOT = 11,
	YELLOW_DOT = 12,
	COLOR_DOT = 13
}

var cargo_type: CargoType = CargoType.RANDOM
var selected_cargo_type: CargoType = CargoType.ORANGE
var b_go_away: bool = false
var ticks_passed: float = 0.0
var ticks_to_pass: float = 0.0
var go_away_ticks_passed: float = 0.0
var go_away_ticks_to_pass: float = 0.0

func reset_brain_state() -> void:
	if not actor or not level:
		return

	actor.can_hit_player = true
	actor.can_be_hit_by_missiles = randf() < 0.1
	actor.was_hit_by_missile = 0
	actor.is_deleted = false
	actor.hit_player = false

	if cargo_type == CargoType.RANDOM:
		selected_cargo_type = CargoType.values()[randi_range(1, 7)]
	else:
		selected_cargo_type = cargo_type

	actor.play_animation(_get_cargo_animation(selected_cargo_type))
	b_go_away = randf() < (1.0 / 15.0)
	ticks_passed = 0.0
	ticks_to_pass = 0.0
	go_away_ticks_passed = 0.0
	go_away_ticks_to_pass = float(randi_range(2000, 6999))

	actor.reverse_at_border_left = true
	actor.reverse_at_border_right = true
	actor.reverse_at_border_top = false
	actor.reverse_at_border_bottom = false

	actor.acceleration = 0.0
	actor.acceleration_direction = 0.0
	actor.set_movement_normal(actor.position, 0.0, 0.0)

func update_state(delta: float) -> void:
	if not actor or not level:
		return

	var ticks_ms = delta * 1000.0

	if actor.hit_player:
		_apply_cargo_effects()
		actor.is_deleted = true
		actor.can_be_hit_by_missiles = false
		actor.can_hit_player = false
		return

	if actor.is_off_screen:
		actor.can_be_hit_by_missiles = false
		actor.can_hit_player = false
		actor.is_deleted = true
		return

	if actor.was_hit_by_missile > 0:
		actor.reverse_at_border_top = false
		actor.reverse_at_border_left = false
		actor.reverse_at_border_right = false
		actor.can_be_hit_by_missiles = false
		if level.has_method("play_sound"):
			level.play_sound("DOH2")
		actor.velocity_magnitude = float(randi_range(180, 279))
		actor.velocity_direction = float(randi_range(0, 359))
		actor.was_hit_by_missile = 0
		ticks_to_pass = 10000.0

	if not actor.is_deleted:
		ticks_passed += ticks_ms
		if ticks_passed > ticks_to_pass:
			ticks_passed = 0.0
			ticks_to_pass = float(randi_range(500, 3499))
			actor.velocity_magnitude = float(randi_range(20, 99))
			actor.velocity_direction = float(randi_range(40, 139))
		if b_go_away:
			go_away_ticks_passed += ticks_ms
			if go_away_ticks_passed > go_away_ticks_to_pass:
				actor.reverse_at_border_top = false
				actor.reverse_at_border_left = false
				actor.reverse_at_border_right = false
				actor.acceleration = 100.0
				actor.acceleration_direction = 270.0


func _apply_cargo_effects() -> void:
	if not level:
		return

	if level.has_method("play_sound"):
		level.play_sound("CAMERA")

	match selected_cargo_type:
		CargoType.ORANGE:
			level.shields_left += 10000
		CargoType.PINK:
			if level.has_method("add_random_bonus"):
				level.add_random_bonus(actor.position)
		CargoType.YELLOW:
			level.has_double_shots = true
		CargoType.BLUE:
			level.has_multi_shots = true
		CargoType.GREEN:
			level.has_safety_pin = true
		CargoType.PURPLE:
			level.has_rapid_fire = true
		CargoType.RED:
			if level.game:
				level.game.add_life()
		_:
			pass


func _get_cargo_animation(c_type: CargoType) -> String:
	match c_type:
		CargoType.ORANGE:
			return "orange"
		CargoType.PINK:
			return "pink"
		CargoType.YELLOW:
			return "yellow"
		CargoType.BLUE:
			return "blue"
		CargoType.GREEN:
			return "green"
		CargoType.PURPLE:
			return "purple"
		CargoType.RED:
			return "red"
		CargoType.NAVY:
			return "navy"
		CargoType.RED_DOT:
			return "reddot"
		CargoType.GREEN_DOT:
			return "greendot"
		CargoType.BLUE_DOT:
			return "bluedot"
		CargoType.PINK_DOT:
			return "pinkdot"
		CargoType.YELLOW_DOT:
			return "yellowdot"
		CargoType.COLOR_DOT:
			return "colordot"
		_:
			return "orange"
