# BrainXBonus.gd
# XBonus behavior
# Port from vb6/BrainsXBonus.cls

extends Brain

class_name BrainXBonus

enum State {
	HAS_NOT_APPEARED,
	VISIBLE,
	GONE
}

var state: State = State.HAS_NOT_APPEARED
var ticks_passed: float = 0.0
var ticks_before_appearance: float = 0.0
var longest_wait_ms: float = Constants.XBONUS_INTERVAL_MS
var appearance_length_ms: float = Constants.XBONUS_DURATION_MS
var multiplier: int = 2

func reset_brain_state() -> void:
	state = State.HAS_NOT_APPEARED
	ticks_passed = 0.0
	ticks_before_appearance = randf_range(0.0, longest_wait_ms)
	multiplier = randi_range(2, 5)

	if actor and level:
		actor.visible = false
		actor.anim_playing = false
		actor.can_be_hit_by_missiles = false
		actor.was_hit_by_missile = 0
		# Add buffer on sides so galaxy is fully visible and reachable by player
		var buffer = 40.0
		var x_pos = randf_range(buffer, level.play_width - SIZE_XBONUS().x - buffer)
		actor.set_movement_normal(Vector2(x_pos, level.play_y_offset + level.play_height - 96.0), 0.0, 0.0)

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
			if level.has_method("play_sound"):
				level.play_sound("SLUDGE")
			var anim_name = "%dxbonus" % multiplier
			if actor.has_animation(anim_name):
				actor.play_animation(anim_name)

	if state == State.VISIBLE:
		if actor.was_hit_by_missile > 0:
			actor.was_hit_by_missile = 0
			if level.has_method("play_sound"):
				level.play_sound("PHONE")
			if level.has_method("set_bonus_multiplier"):
				level.set_bonus_multiplier(multiplier)
			state = State.GONE
			actor.can_be_hit_by_missiles = false
			actor.is_deleted = true
			actor.visible = false
			return

		ticks_passed += ticks_ms
		if ticks_passed > appearance_length_ms:
			state = State.GONE
			actor.can_be_hit_by_missiles = false
			actor.is_deleted = true
			actor.visible = false

func SIZE_XBONUS() -> Vector2:
	return Vector2(12.0, 12.0)
