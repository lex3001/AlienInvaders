extends Control

class_name TitleScreen

const HighScoresScript = preload("res://scripts/core/HighScores.gd")

var game: Game = null
var background_texture: TextureRect = null
var instruction_panel: ColorRect = null
var score_panel: ColorRect = null
var score_text_root: Control = null
var instruction_top_label: Label = null
var instruction_bottom_label: Label = null
var score_title_label: Label = null
var score_labels: Array[Label] = []
var last_score_label: Label = null
var high_scores = null
var name_entry_blink_ms: float = 0.0
var name_entry_blink_on: bool = true
var title_font: Font = null
var instruction_font: Font = null
var score_font: Font = null
var ui_visible: bool = false
var delay_timer: float = 0.0
var delay_duration: float = 2.0
var fade_timer: float = 0.0
var fade_duration: float = 2.0
var instruction_cycle_hue: float = 0.0
var instruction_cycle_speed: float = 3.0
var instruction_bottom_color: Color = Color(1.0, 1.0, 0.5, 1.0)
var score_title_color: Color = Color(1.0, 1.0, 0.5, 1.0)
var score_normal_color: Color = Color(0.2, 1.0, 0.2, 1.0)
var score_highlight_color: Color = Color(1.0, 0.2, 0.2, 1.0)
var last_score_color: Color = Color(1.0, 0.7, 0.0, 1.0)
var score_pulse_phase: float = 0.0
var score_pulse_speed: float = 5.5

func _ready():
	_set_full_rect()
	game = _find_game()
	_build_ui()
	refresh_from_game()

func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if game and game.waiting_for_high_score_entry:
			_handle_high_score_input(event)
			return
		var key = event.keycode
		if key == KEY_L:
			_toggle_language()
			return
		if key == KEY_ESCAPE:
			get_tree().quit()
			return
		if key == KEY_ENTER or key == KEY_KP_ENTER:
			_start_level(1)
			return
		if key == KEY_1 or key == KEY_KP_1:
			_start_level(1)
			return
		# Levels 2-5 only available in test mode
		if Constants.TEST_MODE:
			if key == KEY_2 or key == KEY_KP_2:
				_start_level(2)
				return
			if key == KEY_3 or key == KEY_KP_3:
				_start_level(3)
				return
			if key == KEY_4 or key == KEY_KP_4:
				_start_level(4)
				return
			if key == KEY_5 or key == KEY_KP_5:
				_start_level(5)
				return

func _set_full_rect() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	offset_left = 0
	offset_top = 0
	offset_right = 0
	offset_bottom = 0

func _find_game() -> Game:
	if get_parent() == null:
		return null
	return get_parent().get_node_or_null("Game")

func _build_ui() -> void:
	title_font = _create_title_font()
	instruction_font = _create_instruction_font()
	score_font = _create_score_font()
	
	# Load and display background image
	background_texture = TextureRect.new()
	var texture = load("res://assets/TitleScreen.png")
	if texture:
		background_texture.texture = texture
	background_texture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background_texture.stretch_mode = TextureRect.STRETCH_SCALE
	background_texture.size = Vector2(Constants.SCREEN_WIDTH, Constants.SCREEN_HEIGHT)
	background_texture.position = Vector2.ZERO
	add_child(background_texture)
	
	# Instructions panel at bottom (75% opacity black background)
	var instructions_y = Constants.SCREEN_HEIGHT - 55
	var instructions_height = 55
	instruction_panel = ColorRect.new()
	instruction_panel.color = Color(0, 0, 0, 0)
	instruction_panel.position = Vector2(0, instructions_y)
	instruction_panel.size = Vector2(Constants.SCREEN_WIDTH, instructions_height)
	instruction_panel.visible = true
	add_child(instruction_panel)
	
	# Instructions text (two lines)
	var instruction_width = Constants.SCREEN_WIDTH - 40
	var instruction_line_height = instructions_height * 0.5

	instruction_top_label = Label.new()
	instruction_top_label.add_theme_font_override("font", score_font)
	instruction_top_label.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 1.0))
	instruction_top_label.add_theme_font_size_override("font_size", 16)
	instruction_top_label.text = ""
	instruction_top_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	instruction_top_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	instruction_top_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	instruction_top_label.size = Vector2(instruction_width, instruction_line_height)
	instruction_top_label.position = Vector2(20, 4)
	instruction_panel.add_child(instruction_top_label)

	instruction_bottom_label = Label.new()
	instruction_bottom_label.add_theme_font_override("font", score_font)
	instruction_bottom_label.add_theme_color_override("font_color", instruction_bottom_color)
	instruction_bottom_label.add_theme_font_size_override("font_size", 16)
	instruction_bottom_label.text = ""
	instruction_bottom_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	instruction_bottom_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	instruction_bottom_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	instruction_bottom_label.size = Vector2(instruction_width, instruction_line_height)
	instruction_bottom_label.position = Vector2(20, instruction_line_height)
	instruction_panel.add_child(instruction_bottom_label)
	_update_instruction_texts_for_locale()
	
	# High scores panel on right side (align bottom to instruction panel top)
	var score_panel_height = Constants.SCREEN_HEIGHT * 0.43
	var score_panel_bottom = instructions_y
	var score_panel_y = score_panel_bottom - score_panel_height
	var score_panel_width = Constants.SCREEN_WIDTH * 0.28
	var score_panel_x = Constants.SCREEN_WIDTH - score_panel_width
	
	score_panel = ColorRect.new()
	score_panel.color = Color(0, 0, 0, 0)
	score_panel.position = Vector2(score_panel_x, score_panel_y)
	score_panel.size = Vector2(score_panel_width, score_panel_height)
	score_panel.visible = true
	score_panel.z_index = 1
	add_child(score_panel)

	# High score text is drawn in a separate sibling layer so panel alpha never affects text opacity
	score_text_root = Control.new()
	score_text_root.position = Vector2(score_panel_x, score_panel_y)
	score_text_root.size = Vector2(score_panel_width, score_panel_height)
	score_text_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	score_text_root.visible = true
	score_text_root.z_index = 2
	add_child(score_text_root)
	
	# High scores title
	score_title_label = Label.new()
	score_title_label.add_theme_font_override("font", score_font)
	score_title_label.add_theme_color_override("font_color", score_title_color)
	score_title_label.add_theme_font_size_override("font_size", 16)
	score_title_label.text = "HIGH SCORES"
	score_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	score_title_label.size = Vector2(score_panel_width, 24)
	score_title_label.position = Vector2(0, 8)
	score_text_root.add_child(score_title_label)
	
	# High score entries
	score_labels.clear()
	var line_height = 15
	var start_y = 32
	for i in range(10):
		var line = Label.new()
		line.position = Vector2(10, start_y + (i * line_height))
		line.size = Vector2(score_panel_width - 20, line_height)
		line.add_theme_font_override("font", score_font)
		line.add_theme_color_override("font_color", score_normal_color)
		line.add_theme_font_size_override("font_size", 13)
		score_text_root.add_child(line)
		score_labels.append(line)
	
	# Last score label (at bottom of panel)
	last_score_label = Label.new()
	last_score_label.position = Vector2(10, score_panel_height - 24)
	last_score_label.size = Vector2(score_panel_width - 20, 20)
	last_score_label.add_theme_font_override("font", score_font)
	last_score_label.add_theme_color_override("font_color", last_score_color)
	last_score_label.add_theme_font_size_override("font_size", 13)
	last_score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	score_text_root.add_child(last_score_label)

func _create_title_font() -> Font:
	var font = SystemFont.new()
	font.font_names = PackedStringArray(["Arial", "Helvetica", "Liberation Sans"])
	font.antialiasing = TextServer.FONT_ANTIALIASING_LCD
	return font

func _create_instruction_font() -> Font:
	var font = SystemFont.new()
	font.font_names = PackedStringArray(["Tahoma", "Verdana", "MS Sans Serif", "Arial", "Helvetica", "Liberation Sans"])
	font.antialiasing = TextServer.FONT_ANTIALIASING_LCD
	return font

func _create_score_font() -> Font:
	var font = SystemFont.new()
	font.font_names = PackedStringArray(["Lucida Console", "Courier New", "Courier", "Monaco", "Menlo", "Consolas", "Liberation Mono"])
	font.antialiasing = TextServer.FONT_ANTIALIASING_LCD
	return font

func _load_scores() -> void:
	if game is Game and (game as Game).high_scores:
		high_scores = (game as Game).high_scores
	else:
		high_scores = HighScoresScript.new()
		high_scores.load_default()

func refresh_from_game() -> void:
	if score_labels.is_empty():
		call_deferred("refresh_from_game")
		return
	# Reset delay and fade timers when returning to title screen
	delay_timer = 0.0
	fade_timer = 0.0
	ui_visible = false
	# Reset UI opacity
	if instruction_panel:
		instruction_panel.color = Color(0, 0, 0, 0)
		_set_instruction_labels_visible(false)
	if score_panel:
		score_panel.color = Color(0, 0, 0, 0)
		_set_score_labels_visible(false)
	if score_text_root:
		score_text_root.visible = false
	_load_scores()
	_refresh_scores()
	_force_score_label_opacity()

func _process(delta: float) -> void:
	if not visible:
		return
	
	# Handle 2 second delay before showing UI
	if not ui_visible:
		delay_timer += delta
		if delay_timer >= delay_duration:
			ui_visible = true
			_set_instruction_labels_visible(true)
			_set_score_labels_visible(true)
			if score_text_root:
				score_text_root.visible = true
			fade_timer = 0.0
		return
	
	# Handle fade-in animation over 2 seconds
	if fade_timer < fade_duration:
		fade_timer += delta
		var alpha = clamp(fade_timer / fade_duration, 0.0, 1.0)
		
		# Fade in instruction panel and text
		if instruction_panel:
			instruction_panel.color = Color(0, 0, 0, alpha * 0.75)
		
		# Fade in score panel and all labels
		if score_panel:
			score_panel.color = Color(0, 0, 0, alpha * 0.75)

	# Cycle instruction top line color rapidly
	if ui_visible and instruction_top_label:
		instruction_cycle_hue = fmod(instruction_cycle_hue + (delta * instruction_cycle_speed), 1.0)
		instruction_top_label.add_theme_color_override("font_color", Color.from_hsv(instruction_cycle_hue, 1.0, 1.0, 1.0))

	# Pulse last score and matching high score entry when visible
	if ui_visible:
		_force_score_label_opacity()
		score_pulse_phase = fmod(score_pulse_phase + (delta * score_pulse_speed), TAU)
		_apply_score_pulse()
	
	if game and game.waiting_for_high_score_entry:
		name_entry_blink_ms += delta * 1000.0
		if name_entry_blink_ms > 500.0:
			name_entry_blink_ms = 0.0
			name_entry_blink_on = not name_entry_blink_on
		_refresh_scores()

func _refresh_scores() -> void:
	if high_scores == null or score_labels.size() < 10:
		return
	for i in range(10):
		var entry = high_scores.scores[i]
		var score_text = str(entry["score"]).pad_zeros(8)
		var name_text = entry["name"]
		var color = score_normal_color
		if game and game.waiting_for_high_score_entry and game.high_score_entry_index == i:
			color = score_highlight_color
			name_text = _apply_entry_cursor(name_text, game.high_score_cursor_pos)
		score_labels[i].add_theme_color_override("font_color", color)
		var rank_text = str(i + 1).pad_zeros(2) if (i + 1) >= 10 else " " + str(i + 1)
		score_labels[i].text = rank_text + ". " + score_text + " " + name_text

	if game and game.last_score > 0:
		last_score_label.text = "Last Score " + str(game.last_score).pad_zeros(8)
		last_score_label.visible = true
	else:
		last_score_label.visible = false

func _apply_score_pulse() -> void:
	if not score_panel:
		return
	var pulse = 0.85 + (0.15 * (sin(score_pulse_phase) * 0.5 + 0.5))
	if last_score_label and last_score_label.visible:
		last_score_label.add_theme_color_override(
			"font_color",
			Color(last_score_color.r * pulse, last_score_color.g * pulse, last_score_color.b * pulse, 1.0)
		)
	var pulse_index = _get_last_score_high_score_index()
	if pulse_index >= 0 and pulse_index < score_labels.size():
		var base_color = score_highlight_color if (game and game.waiting_for_high_score_entry and game.high_score_entry_index == pulse_index) else score_normal_color
		score_labels[pulse_index].add_theme_color_override(
			"font_color",
			Color(base_color.r * pulse, base_color.g * pulse, base_color.b * pulse, 1.0)
		)

func _get_last_score_high_score_index() -> int:
	if not game:
		return -1
	if game.last_score <= 0:
		return -1
	if game.high_score_entry_index < 0:
		return -1
	return game.high_score_entry_index

func _set_instruction_labels_visible(make_visible: bool) -> void:
	if instruction_top_label:
		instruction_top_label.visible = make_visible
	if instruction_bottom_label:
		instruction_bottom_label.visible = make_visible

func _set_score_labels_visible(make_visible: bool) -> void:
	if score_title_label:
		score_title_label.visible = make_visible
		if make_visible:
			_force_score_label_opacity()
	for label in score_labels:
		if label:
			label.visible = make_visible
	if last_score_label:
		last_score_label.visible = make_visible
	if make_visible:
		_force_score_label_opacity()

func _force_score_label_opacity() -> void:
	if score_panel:
		score_panel.modulate = Color(1.0, 1.0, 1.0, 1.0)
	if score_text_root:
		score_text_root.self_modulate = Color(1.0, 1.0, 1.0, 1.0)
		score_text_root.modulate = Color(1.0, 1.0, 1.0, 1.0)
	if score_title_label:
		score_title_label.self_modulate = Color(1.0, 1.0, 1.0, 1.0)
		score_title_label.modulate = Color(1.0, 1.0, 1.0, 1.0)
		score_title_label.add_theme_color_override("font_color", score_title_color)
	for label in score_labels:
		if label:
			label.self_modulate = Color(1.0, 1.0, 1.0, 1.0)
			label.modulate = Color(1.0, 1.0, 1.0, 1.0)
			var label_color = label.get_theme_color("font_color", "")
			label.add_theme_color_override("font_color", Color(label_color.r, label_color.g, label_color.b, 1.0))
	if last_score_label:
		last_score_label.self_modulate = Color(1.0, 1.0, 1.0, 1.0)
		last_score_label.modulate = Color(1.0, 1.0, 1.0, 1.0)
		var last_color = last_score_label.get_theme_color("font_color", "")
		last_score_label.add_theme_color_override("font_color", Color(last_color.r, last_color.g, last_color.b, 1.0))

func _start_level(level_num: int) -> void:
	if game:
		game.start_game_at_level(level_num)

func _toggle_language() -> void:
	var locale = TranslationServer.get_locale().to_lower()
	if locale.begins_with("de"):
		TranslationServer.set_locale("en")
	else:
		TranslationServer.set_locale("de")
	_update_instruction_texts_for_locale()

func _update_instruction_texts_for_locale() -> void:
	if not instruction_top_label or not instruction_bottom_label:
		return
	var locale = TranslationServer.get_locale().to_lower()
	if locale.begins_with("de"):
		if Constants.TEST_MODE:
			instruction_top_label.text = "ENTER Start  ESC Ende  L Sprache  1-5 Level"
		else:
			instruction_top_label.text = "ENTER Start  ESC Ende  L Sprache"
		instruction_bottom_label.text = "Pfeile/A-D Bewegen  LEERTASTE/ENTER Feuer  SHIFT Schild"
		return
	if Constants.TEST_MODE:
		instruction_top_label.text = "ENTER Start  ESC Quit  L Language  1-5 Level"
	else:
		instruction_top_label.text = "ENTER Start  ESC Quit  L Language"
	instruction_bottom_label.text = "Arrows/A-D Move  SPACE/ENTER Fire  SHIFT Shields"

func _apply_entry_cursor(name_text: String, cursor_pos: int) -> String:
	var padded = name_text.rpad(max(cursor_pos, name_text.length()), " ")
	if name_entry_blink_on:
		return padded.substr(0, cursor_pos) + "|" + padded.substr(cursor_pos)
	return padded.substr(0, cursor_pos) + " " + padded.substr(cursor_pos)

func _handle_high_score_input(event: InputEventKey) -> void:
	if not game or not high_scores:
		return
	var entry_name = game.high_score_entry_name
	var cursor = game.high_score_cursor_pos
	var key = event.keycode

	if key == KEY_ENTER or key == KEY_KP_ENTER:
		game.finish_high_score_entry()
		return
	if key == KEY_LEFT:
		cursor = max(cursor - 1, 0)
		game.update_high_score_entry_name(entry_name, cursor)
		return
	if key == KEY_RIGHT:
		cursor = min(cursor + 1, entry_name.length())
		game.update_high_score_entry_name(entry_name, cursor)
		return
	if key == KEY_BACKSPACE:
		if cursor > 0 and entry_name.length() > 0:
			entry_name = entry_name.substr(0, cursor - 1) + entry_name.substr(cursor)
			cursor -= 1
			game.update_high_score_entry_name(entry_name, cursor)
		return
	if key == KEY_DELETE:
		if cursor < entry_name.length():
			entry_name = entry_name.substr(0, cursor) + entry_name.substr(cursor + 1)
			game.update_high_score_entry_name(entry_name, cursor)
		return

	if event.unicode <= 0:
		return
	var ch = char(event.unicode)
	if not _is_allowed_name_char(ch):
		return
	if entry_name.length() >= 50:
		return
	entry_name = entry_name.substr(0, cursor) + ch + entry_name.substr(cursor)
	cursor += 1
	game.update_high_score_entry_name(entry_name, cursor)

func _is_allowed_name_char(ch: String) -> bool:
	if ch == " ":
		return true
	var code = ch.unicode_at(0)
	return (code >= 48 and code <= 57) or (code >= 65 and code <= 90) or (code >= 97 and code <= 122)

