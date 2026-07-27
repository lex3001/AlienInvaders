extends CanvasLayer

class_name HUD

const TEX_DASH = preload("res://assets/sprites/Dash.bmp")

const DASH_STRIP_EN_Y = 64
const DASH_STRIP_DE_Y = 80
const DASH_STRIP_W = 640
const DASH_STRIP_H = 16
const DIGIT_SRC_Y = 48
const DIGIT_W = 8
const DIGIT_H = 10
const SHIP_W = 13
const SHIP_H = 12
const GADGET_W = 12
const GADGET_H = 12
const XBONUS_W = 12
const XBONUS_H = 12

# Flag to show/hide level display (shows actual level number and speed multiplier)
const SHOW_LEVEL_DISPLAY: bool = false

var game = null

var dash_sprite: Sprite2D = null
var ships_sprite: Sprite2D = null
var xbonus_sprite: Sprite2D = null
var gadget_double: Sprite2D = null
var gadget_rapid: Sprite2D = null
var gadget_multi: Sprite2D = null
var gadget_safety: Sprite2D = null
var title_label: Label = null
var level_label: Label = null
var top_border_line: ColorRect = null
var bottom_border_line: ColorRect = null
var score_digits: Array[Sprite2D] = []
var bonus_digits: Array[Sprite2D] = []
var shields_bar: ColorRect = null
var dash_language_code: String = "en"

func _ready() -> void:
	_apply_dash_language_from_locale()
	_build_dashboard()

func set_game(p_game) -> void:
	game = p_game

func _process(_delta: float) -> void:
	if not game:
		return
	visible = game.game_state == Constants.GameState.PLAYING
	if level_label:
		level_label.visible = visible and SHOW_LEVEL_DISPLAY
		if visible and SHOW_LEVEL_DISPLAY:
			_update_level_display(game.actual_level_number, game.current_level, game.game_speed_multiplier)
	if bottom_border_line:
		bottom_border_line.visible = visible
	if not visible:
		return

	_apply_dash_language_from_locale()

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
	_build_level_label()
	var base_y = Constants.SCREEN_HEIGHT - Constants.BOTTOM_BORDER + 2

	dash_sprite = _create_dash_sprite(Rect2(0, _dash_strip_y_for_language(dash_language_code), DASH_STRIP_W, DASH_STRIP_H))
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

	_build_bottom_border_line()

func _apply_dash_language_from_locale() -> void:
	var locale = TranslationServer.get_locale().to_lower()
	var language_code = "de" if locale.begins_with("de") else "en"
	if language_code == dash_language_code and dash_sprite:
		return
	dash_language_code = language_code
	if dash_sprite:
		dash_sprite.region_rect = Rect2(0, _dash_strip_y_for_language(dash_language_code), DASH_STRIP_W, DASH_STRIP_H)

func _dash_strip_y_for_language(language_code: String) -> int:
	return DASH_STRIP_DE_Y if language_code == "de" else DASH_STRIP_EN_Y

func _build_title_label() -> void:
	var font = _create_title_font()
	title_label = Label.new()
	title_label.add_theme_font_override("font", font)
	title_label.add_theme_font_size_override("font_size", 12)
	title_label.add_theme_color_override("font_color", Color(0.25, 0.25, 1.0))
	title_label.text = _build_title_text()
	var text_size = title_label.get_minimum_size()
	title_label.size = text_size
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.position = Vector2((Constants.SCREEN_WIDTH - text_size.x) / 2.0, Constants.TOP_BORDER - text_size.y - 1)
	add_child(title_label)

func _build_bottom_border_line() -> void:
	bottom_border_line = ColorRect.new()
	bottom_border_line.position = Vector2(0, Constants.SCREEN_HEIGHT - Constants.BOTTOM_BORDER)
	bottom_border_line.size = Vector2(Constants.SCREEN_WIDTH, 1)
	bottom_border_line.color = Color(0.0, 0.0, 1.0)
	add_child(bottom_border_line)

func _build_level_label() -> void:
	var font = _create_title_font()
	level_label = Label.new()
	level_label.add_theme_font_override("font", font)
	level_label.add_theme_font_size_override("font_size", 12)
	level_label.add_theme_color_override("font_color", Color(0.25, 1.0, 0.25))
	level_label.text = "Level 1"
	var text_size = level_label.get_minimum_size()
	level_label.size = text_size
	level_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	level_label.position = Vector2(5, Constants.TOP_BORDER - text_size.y - 1)
	add_child(level_label)

func _update_level_display(actual_level: int, visual_level: int, speed_mult: float) -> void:
	if not level_label:
		return
	if actual_level > 4:
		level_label.text = "Level %d-%d (x%.2f)" % [actual_level, visual_level, speed_mult]
	else:
		level_label.text = "Level %d" % actual_level

func _create_title_font() -> Font:
	var font = SystemFont.new()
	font.font_names = PackedStringArray(["MS Sans Serif", "Microsoft Sans Serif", "Tahoma", "Arial", "Helvetica", "Geneva"])
	return font

func _build_title_text() -> String:
	var game_name = str(ProjectSettings.get_setting("application/config/name", "Alien Invaders"))
	var version = ""
	var build = ""
	if ProjectSettings.has_setting("application/config/version"):
		version = str(ProjectSettings.get_setting("application/config/version"))
	if ProjectSettings.has_setting("application/config/build"):
		build = str(ProjectSettings.get_setting("application/config/build"))
	if version != "":
		if build != "":
			return "%s %s build %s (c) 1998 Luther Ananda Miller" % [game_name, version, build]
		return "%s %s (c) 1998 Luther Ananda Miller" % [game_name, version]
	return "%s (c) 1998 Luther Ananda Miller" % game_name

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
	if lives <= 1:
		ships_sprite.visible = false
		return
	ships_sprite.visible = true
	var ship_count = clampi(lives - 1, 0, 4)
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
