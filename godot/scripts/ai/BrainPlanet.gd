# BrainPlanet.gd
# Planet behavior
# Port from vb6/BrainsPlanet.cls

extends Brain

class_name BrainPlanet

enum State {
	HAS_NOT_APPEARED,
	VISIBLE,
	GOING,
	GONE
}

var state: State = State.HAS_NOT_APPEARED
var ticks_passed: float = 0.0
var ticks_before_appearance: float = 0.0
var longest_wait_ms: float = Constants.PLANET_INTERVAL_MS
var appearance_length_ms: float = Constants.PLANET_DURATION_MS

func reset_brain_state() -> void:
	state = State.HAS_NOT_APPEARED
	ticks_passed = 0.0
	ticks_before_appearance = randf_range(0.0, longest_wait_ms)

	if actor and level:
		actor.visible = false
		actor.anim_playing = false
		actor.can_be_hit_by_missiles = false
		actor.was_hit_by_missile = 0
		var x_pos = randf_range(0.0, level.play_width - SIZE_PLANET().x)
		actor.set_movement_normal(Vector2(x_pos, level.play_height - 96.0), 0.0, 0.0)

func update_state(delta: float) -> void:
	if not actor or not level:
		return

	var ticks_ms = delta * 1000.0

	if state == State.HAS_NOT_APPEARED and ticks_ms > 0.0:
		ticks_passed += ticks_ms
		if ticks_passed >= ticks_before_appearance:
			state = State.VISIBLE
			ticks_passed = 0.0
			actor.can_be_hit_by_missiles = true
			actor.visible = true
			if actor.has_animation("entering"):
				actor.play_animation("entering", false, "normal")
			elif actor.has_animation("normal"):
				actor.play_animation("normal")

	if state == State.VISIBLE or state == State.GOING:
		if actor.was_hit_by_missile > 0:
			actor.was_hit_by_missile = 0
			if level.has_method("play_sound"):
				level.play_sound("SPLAT")
			if level.has_method("add_random_bonus"):
				var points = level.add_random_bonus(actor.position)
				if level.has_method("add_score"):
					level.add_score(points)
			if state != State.GOING and actor.has_animation("leaving"):
				actor.play_animation("leaving")
			state = State.GONE
			actor.can_be_hit_by_missiles = false

	if state == State.VISIBLE:
		ticks_passed += ticks_ms
		if ticks_passed > appearance_length_ms:
			if actor.has_animation("leaving"):
				actor.play_animation("leaving")
			state = State.GOING

	if state == State.GOING or state == State.GONE:
		if actor.is_animation_playing():
			return
		actor.is_deleted = true
		actor.can_be_hit_by_missiles = false
		actor.visible = false

func SIZE_PLANET() -> Vector2:
	return Vector2(24.0, 12.0)
