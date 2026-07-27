# BrainAlienB.gd  
# Alien Type B - Tank (Multi-hit decorative)
# Takes multiple hits to destroy, no attack patterns
# Port from vb6/BrainsAlienB.cls

extends Brain

class_name BrainAlienB

var legs_remaining: int = 3

func reset_brain_state() -> void:
	legs_remaining = 3
	
	if actor:
		actor.can_be_hit_by_missiles = true
		actor.can_hit_player = false
		actor.must_be_destroyed = false
		_play_normal_animation()

func update_state(_delta: float) -> void:
	if not actor or not level:
		return
	_update_normal_state()

func _update_normal_state() -> void:
	if actor.was_hit_by_missile <= 0:
		return

	legs_remaining -= actor.was_hit_by_missile
	actor.was_hit_by_missile = 0

	if legs_remaining < 0:
		actor.can_be_hit_by_missiles = false
		if level.has_method("add_score"):
			level.add_score(10)
		_play_explosion()
		return

	actor.can_be_hit_by_missiles = true
	if level.has_method("add_score"):
		level.add_score(5)
	_play_hit_animation()

func _play_hit_animation() -> void:
	var anim_name = ""
	var next_anim = ""
	match legs_remaining:
		2:
			anim_name = "hit_3legs"
			next_anim = "normal_2legs"
		1:
			anim_name = "hit_2legs"
			next_anim = "normal_1leg"
		0:
			anim_name = "hit_1leg"
			next_anim = "normal_0legs"

	if actor.has_animation(anim_name):
		actor.play_animation(anim_name, false, next_anim)
	if level.has_method("play_sound"):
		level.play_sound("GRUNT1")

func _play_normal_animation() -> void:
	var anim_name = "normal_3legs"
	match legs_remaining:
		3:
			anim_name = "normal_3legs"
		2:
			anim_name = "normal_2legs"
		1:
			anim_name = "normal_1leg"
		0:
			anim_name = "normal_0legs"
	if actor.has_animation(anim_name):
		actor.play_animation(anim_name)

func _play_explosion() -> void:
	if actor.has_animation("explode"):
		actor.play_animation("explode")
	
	if level.has_method("play_sound"):
		level.play_sound("WHOOSH")
	actor.is_deleted = true
