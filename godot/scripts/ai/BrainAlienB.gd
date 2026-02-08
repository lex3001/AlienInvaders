# BrainAlienB.gd  
# Alien Type B - Tank (Multi-hit decorative)
# Takes multiple hits to destroy, no attack patterns
# Port from vb6/BrainsAlienB.cls

extends Brain

class_name BrainAlienB

enum State {
	NORMAL_3_LEGS,
	HIT_3_LEGS,
	NORMAL_2_LEGS,
	HIT_2_LEGS,
	NORMAL_1_LEG,
	HIT_1_LEG,
	EXPLODING
}

var state: State = State.NORMAL_3_LEGS
var hits_remaining: int = 4  # Takes 4 hits to destroy

func reset_state() -> void:
	state = State.NORMAL_3_LEGS
	hits_remaining = 4
	
	if actor:
		actor.can_be_hit_by_missiles = true
		actor.can_hit_player = false
		actor.must_be_destroyed = true

func update_state(delta: float) -> void:
	if not actor or not level:
		return
	
	var ticks_passed = delta * 1000.0
	
	match state:
		State.NORMAL_3_LEGS, State.NORMAL_2_LEGS, State.NORMAL_1_LEG:
			_update_normal_state(ticks_passed)
		State.HIT_3_LEGS, State.HIT_2_LEGS, State.HIT_1_LEG:
			_update_hit_state(ticks_passed)
		State.EXPLODING:
			_update_exploding_state(ticks_passed)

func _update_normal_state(ticks_passed: float) -> void:
	# Check for hit
	if actor.was_hit_by_missile:
		actor.was_hit_by_missile = false
		hits_remaining -= 1
		
		# Transition to hit state
		match state:
			State.NORMAL_3_LEGS:
				state = State.HIT_3_LEGS
			State.NORMAL_2_LEGS:
				state = State.HIT_2_LEGS
			State.NORMAL_1_LEG:
				state = State.HIT_1_LEG
		
		# Check if destroyed
		if hits_remaining <= 0:
			state = State.EXPLODING
			actor.can_be_hit_by_missiles = false
			
			# Add score
			if level.has_method("add_score"):
				level.add_score(GameConstants.ALIENB_SCORE)
			
			_play_explosion()
		else:
			_play_hit_animation()

func _update_hit_state(ticks_passed: float) -> void:
	# Wait for hit animation to complete, then return to normal
	if actor.animation_player and actor.animation_player.is_playing():
		return
	
	# Transition back to normal with fewer legs
	match state:
		State.HIT_3_LEGS:
			state = State.NORMAL_2_LEGS
			_play_normal_2legs_animation()
		State.HIT_2_LEGS:
			state = State.NORMAL_1_LEG
			_play_normal_1leg_animation()
		State.HIT_1_LEG:
			state = State.EXPLODING
			_play_explosion()

func _update_exploding_state(ticks_passed: float) -> void:
	# Check if explosion animation is complete
	if actor.animation_player and actor.animation_player.is_playing():
		return
	
	# Mark for deletion
	actor.is_deleted = true

func _play_hit_animation() -> void:
	var anim_name = "hit"
	match state:
		State.HIT_3_LEGS:
			anim_name = "hit_3legs"
		State.HIT_2_LEGS:
			anim_name = "hit_2legs"
		State.HIT_1_LEG:
			anim_name = "hit_1leg"
	
	if actor.animation_player and actor.animation_player.has_animation(anim_name):
		actor.animation_player.play(anim_name)

func _play_normal_2legs_animation() -> void:
	if actor.animation_player and actor.animation_player.has_animation("normal_2legs"):
		actor.animation_player.play("normal_2legs")

func _play_normal_1leg_animation() -> void:
	if actor.animation_player and actor.animation_player.has_animation("normal_1leg"):
		actor.animation_player.play("normal_1leg")

func _play_explosion() -> void:
	if actor.animation_player and actor.animation_player.has_animation("explode"):
		actor.animation_player.play("explode")
	
	if level.has_method("play_sound"):
		level.play_sound("BOOM1")
