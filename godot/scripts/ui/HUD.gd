extends CanvasLayer

class_name HUD

const TEX_DASH = preload("res://assets/sprites/Dash.bmp")

const DASH_SRC_RECT = Rect2(0, 80, 640, 16)
const DIGIT_SRC_Y = 48
const DIGIT_W = 8
const DIGIT_H = 10
const SHIP_W = 13
const SHIP_H = 12
const GADGET_W = 12
const GADGET_H = 12
const XBONUS_W = 12
const XBONUS_H = 12

var game = null

var dash_sprite: Sprite2D = null
var ships_sprite: Sprite2D = null
var xbonus_sprite: Sprite2D = null
var gadget_double: Sprite2D = null
var gadget_rapid: Sprite2D = null
var gadget_multi: Sprite2D = null
var gadget_safety: Sprite2D = null
var score_digits: Array[Sprite2D] = []
var bonus_digits: Array[Sprite2D] = []
var shields_bar: ColorRect = null

func _ready() -> void:
	_build_dashboard()

func set_game(p_game) -> void:
	game = p_game

func _process(_delta: float) -> void:
	if not game:
		return
	visible = game.game_state == Constants.GameState.PLAYING
	if not visible:
		return

	var level = game.level
	_update_ships(game.lives)
	_update_score(game.score)

	if level:
		_update_bonus(level.bonus)
		_update_multiplier(level.bonus_multiplier)
		_update_gadgets(level)
		_update_shields(level.shields_left)
	else:
		_update_bonus(0)
		_update_multiplier(1)
		_update_gadgets(null)
		_update_shields(0)

func _build_dashboard() -> void:
	var base_y = Constants.SCREEN_HEIGHT - Constants.BOTTOM_BORDER + 2

	dash_sprite = _create_dash_sprite(DASH_SRC_RECT)
	dash_sprite.position = Vector2(0, base_y)
	add_child(dash_sprite)

	ships_sprite = _create_dash_sprite(Rect2(0, 0, 0, SHIP_H))
	ships_sprite.position = Vector2(0, base_y)
	add_child(ships_sprite)

	xbonus_sprite = _create_dash_sprite(Rect2(270, 0, XBONUS_W, XBONUS_H))
	xbonus_sprite.position = Vector2(516, base_y + 2)
	xbonus_sprite.visible = false
	add_child(xbonus_sprite)

	gadget_double = _create_dash_sprite(Rect2(80, 0, GADGET_W, GADGET_H))
	gadget_double.position = Vector2(80, base_y)
	gadget_double.visible = false
	add_child(gadget_double)

	gadget_rapid = _create_dash_sprite(Rect2(92, 0, GADGET_W, GADGET_H))
	gadget_rapid.position = Vector2(92, base_y)
	gadget_rapid.visible = false
	add_child(gadget_rapid)

	gadget_multi = _create_dash_sprite(Rect2(104, 0, GADGET_W, GADGET_H))
	gadget_multi.position = Vector2(104, base_y)
	gadget_multi.visible = false
	add_child(gadget_multi)

	gadget_safety = _create_dash_sprite(Rect2(116, 0, GADGET_W, GADGET_H))
	gadget_safety.position = Vector2(116, base_y)
	gadget_safety.visible = false
	add_child(gadget_safety)

	score_digits = _create_digits(7, Vector2(582, base_y + 3))
	bonus_digits = _create_digits(5, Vector2(472, base_y + 3))

	var shield_top = Constants.SCREEN_HEIGHT - Constants.BOTTOM_BORDER - 2 + 8
	shields_bar = ColorRect.new()
	shields_bar.position = Vector2(320, shield_top)
	shields_bar.size = Vector2(100, 7)
	shields_bar.color = Color(0.38, 0.38, 0.75)
	add_child(shields_bar)

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

func _update_score(value: int) -> void:
	_set_digits(score_digits, value, 7, true)

func _update_bonus(value: int) -> void:
	_set_digits(bonus_digits, value, 5, false)

func _set_digits(digits: Array[Sprite2D], value: int, count: int, leading_zeros: bool) -> void:
	var raw = str(max(value, 0))
	if raw.length() > count:
		raw = raw.substr(raw.length() - count, count)
	var start = count - raw.length()
	for i in range(count):
		var sprite = digits[i]
		var visible = true
		var digit_value = 0
		if i < start:
			if leading_zeros:
				digit_value = 0
			else:
				visible = false
		else:
			digit_value = int(raw[i - start])
		sprite.visible = visible
		if visible:
			sprite.region_rect = Rect2(digit_value * DIGIT_W, DIGIT_SRC_Y, DIGIT_W, DIGIT_H)

func _update_multiplier(multiplier: int) -> void:
	if multiplier <= 1:
		xbonus_sprite.visible = false
		return
	var clamped = clampi(multiplier, 2, 5)
	var src_x = 270 + ((clamped - 2) * XBONUS_W)
	xbonus_sprite.region_rect = Rect2(src_x, 0, XBONUS_W, XBONUS_H)
	xbonus_sprite.visible = true

func _update_gadgets(level: Node) -> void:
	if level:
		gadget_double.visible = level.has_double_shots
		gadget_rapid.visible = level.has_rapid_fire
		gadget_multi.visible = level.has_multi_shots
		gadget_safety.visible = level.has_safety_pin
	else:
		gadget_double.visible = false
		gadget_rapid.visible = false
		gadget_multi.visible = false
		gadget_safety.visible = false

func _update_ships(lives: int) -> void:
	if lives <= 0:
		ships_sprite.visible = false
		return
	ships_sprite.visible = true
	var ship_count = clampi(lives, 0, 6)
	ships_sprite.region_rect = Rect2(0, 0, ship_count * SHIP_W, SHIP_H)

func _update_shields(shields_left: int) -> void:
	var percent = float(shields_left) / float(Constants.MAX_SHIELDS_TICKS)
	var length = clampf(percent * 100.0, 0.0, 100.0)
	shields_bar.size.x = length
	if length > 40.0:
		shields_bar.color = Color(0.38, 0.38, 0.75)
	elif length > 20.0:
		shields_bar.color = Color(0.75, 0.75, 0.38)
	else:
		shields_bar.color = Color(0.75, 0.38, 0.38)
