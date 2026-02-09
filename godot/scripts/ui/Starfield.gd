# Starfield.gd
# VB6-style starfield renderer

extends Node2D

class_name Starfield

const DEFAULT_STARS = 50
const MIN_VELOCITY = 0.25
const MAX_VELOCITY = 10.0

var num_stars: int = DEFAULT_STARS
var play_rect: Rect2 = Rect2(0, Constants.TOP_BORDER, Constants.SCREEN_WIDTH, Constants.PLAY_HEIGHT)

var stars: Array[Dictionary] = []

func _ready() -> void:
	_init_stars()
	queue_redraw()

func _process(delta: float) -> void:
	_update_stars(delta)
	queue_redraw()

func _init_stars() -> void:
	stars.clear()
	for _i in range(num_stars):
		stars.append(_create_star())

func _create_star() -> Dictionary:
	var velocity = randf_range(MIN_VELOCITY, MAX_VELOCITY)
	var brightness = (randf() * velocity * 9.6 + 32.0) / 255.0
	brightness = clamp(brightness, 0.0, 1.0)
	return {
		"x": play_rect.position.x + randf() * (play_rect.size.x - 1.0),
		"y": play_rect.position.y + randf() * (play_rect.size.y - 1.0),
		"velocity": velocity,
		"color": Color(brightness, brightness, brightness, 1.0)
	}

func _update_stars(delta: float) -> void:
	for star in stars:
		star["y"] -= delta * star["velocity"]
		if star["y"] < play_rect.position.y:
			star["y"] = play_rect.position.y + play_rect.size.y - 1.0
			star["x"] = play_rect.position.x + randf() * (play_rect.size.x - 1.0)

func _draw() -> void:
	for star in stars:
		draw_rect(Rect2(Vector2(star["x"], star["y"]), Vector2(1, 1)), star["color"])
