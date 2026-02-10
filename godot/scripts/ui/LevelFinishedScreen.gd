extends CanvasLayer

class_name LevelFinishedScreen

const TEX_DASH = preload("res://assets/sprites/Dash.bmp")

const DIGIT_SRC_Y = 48
const DIGIT_W = 8
const DIGIT_H = 10
const XBONUS_W = 12
const XBONUS_H = 12

var title_label: Label = null
var bonus_label: Label = null
var total_label: Label = null
var equals_label: Label = null

var bonus_digits: Array[Sprite2D] = []
var total_bonus_digits: Array[Sprite2D] = []
var score_digits: Array[Sprite2D] = []
var xbonus_sprite: Sprite2D = null

func _ready() -> void:
	visible = false
	_build_ui()

func update_display(state: int, level_num: int, bonus: int, multiplier: int,
		total_bonus: int, score: int) -> void:
	visible = true

	var show_title = state > 0
	var show_bonus = state > 1
	var show_multiplier = state > 2
	var show_total_bonus = state > 3
	var show_score = state > 4

	title_label.visible = show_title
	bonus_label.visible = show_bonus
	total_label.visible = show_score
	equals_label.visible = show_total_bonus

	if show_title:
		title_label.text = "Level " + str(level_num) + " Complete"
	if show_bonus:
		_set_digits(bonus_digits, bonus, 7, true)
	else:
		_hide_digits(bonus_digits)

	xbonus_sprite.visible = show_multiplier and multiplier > 1
	if xbonus_sprite.visible:
		var clamped = clampi(multiplier, 2, 5)
		var src_x = 270 + ((clamped - 2) * XBONUS_W)
		xbonus_sprite.region_rect = Rect2(src_x, 0, XBONUS_W, XBONUS_H)

	if show_total_bonus:
		_set_digits(total_bonus_digits, total_bonus, 7, true)
	else:
		_hide_digits(total_bonus_digits)

	if show_score:
		_set_digits(score_digits, score, 7, false)
	else:
		_hide_digits(score_digits)

func _build_ui() -> void:
	title_label = _create_label(Vector2(220, 200), Color(0.75, 0.75, 0.0))
	add_child(title_label)

	bonus_label = _create_label(Vector2(220, 220), Color(0.75, 0.5, 0.25))
	bonus_label.text = "Bonus:"
	add_child(bonus_label)

	equals_label = _create_label(Vector2(347, 220), Color(0.75, 0.5, 0.25))
	equals_label.text = "="
	add_child(equals_label)

	total_label = _create_label(Vector2(220, 240), Color(0.75, 0.12, 0.12))
	total_label.text = "Total Score:"
	add_child(total_label)

	bonus_digits = _create_digits(7, Vector2(275, 225))
	total_bonus_digits = _create_digits(7, Vector2(360, 225))
	score_digits = _create_digits(7, Vector2(360, 245))

	xbonus_sprite = _create_dash_sprite(Rect2(270, 0, XBONUS_W, XBONUS_H))
	xbonus_sprite.position = Vector2(332, 225)
	xbonus_sprite.visible = false
	add_child(xbonus_sprite)

func _create_label(pos: Vector2, color: Color) -> Label:
	var label = Label.new()
	label.position = pos
	label.add_theme_color_override("font_color", color)
	label.add_theme_font_size_override("font_size", 14)
	return label

func _create_dash_sprite(src_rect: Rect2) -> Sprite2D:
	var sprite = Sprite2D.new()
	sprite.texture = TEX_DASH
	sprite.centered = false
	sprite.region_enabled = true
	sprite.region_rect = src_rect
	return sprite

func _create_digits(count: int, start_pos: Vector2) -> Array[Sprite2D]:
	var digits: Array[Sprite2D] = []
	for i in range(count):
		var digit = _create_dash_sprite(Rect2(0, DIGIT_SRC_Y, DIGIT_W, DIGIT_H))
		digit.position = Vector2(start_pos.x + (i * DIGIT_W), start_pos.y)
		add_child(digit)
		digits.append(digit)
	return digits

func _set_digits(digits: Array[Sprite2D], value: int, count: int, leading_zeros: bool) -> void:
	var raw = str(max(value, 0))
	if raw.length() > count:
		raw = raw.substr(raw.length() - count, count)
	var start = count - raw.length()
	for i in range(count):
		var sprite = digits[i]
		var digit_visible = true
		var digit_value = 0
		if i < start:
			if leading_zeros:
				digit_value = 0
			else:
				digit_visible = false
		else:
			digit_value = int(raw[i - start])
		sprite.visible = digit_visible
		if digit_visible:
			sprite.region_rect = Rect2(digit_value * DIGIT_W, DIGIT_SRC_Y, DIGIT_W, DIGIT_H)

func _hide_digits(digits: Array[Sprite2D]) -> void:
	for sprite in digits:
		sprite.visible = false
