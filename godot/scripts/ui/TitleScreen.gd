extends Control

class_name TitleScreen

const HighScoresScript = preload("res://scripts/core/HighScores.gd")

var game: Game = null
var title_label: Label = null
var instruction_label: Label = null
var score_labels: Array[Label] = []
var last_score_label: Label = null
var high_scores = null
var name_entry_blink_ms: float = 0.0
var name_entry_blink_on: bool = true
var menu_font: Font = null

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
		if key == KEY_ESCAPE:
			get_tree().quit()
			return
		if key == KEY_ENTER or key == KEY_KP_ENTER:
			_start_level(1)
			return
		if key == KEY_1:
			_start_level(1)
			return
		if key == KEY_2:
			_start_level(2)
			return
		if key == KEY_3:
			_start_level(3)
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
	menu_font = _create_menu_font()
	var center_y = Constants.SCREEN_HEIGHT / 2.0
	var line_height = 18
	var score_base_y = 250

	title_label = Label.new()
	title_label.add_theme_font_override("font", menu_font)
	title_label.add_theme_color_override("font_color", Color(0.77, 0.77, 0.25))
	title_label.add_theme_font_size_override("font_size", 12)
	title_label.text = "Alien Invaders --- <ENTER> zu starten"
	var title_size = title_label.get_minimum_size()
	title_label.size = title_size
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.position = Vector2((Constants.SCREEN_WIDTH - title_size.x) / 2.0, center_y - title_size.y - 9)
	add_child(title_label)

	instruction_label = Label.new()
	instruction_label.add_theme_font_override("font", menu_font)
	instruction_label.add_theme_color_override("font_color", Color(0.0, 0.38, 0.75))
	instruction_label.add_theme_font_size_override("font_size", 12)
	instruction_label.text = "<linke/rechte Pfeile> links/rechts, <SHIFT> schiessen, <ALT> schuetzen, <Leertaste> stoppen"
	var instruction_size = instruction_label.get_minimum_size()
	instruction_label.size = instruction_size
	instruction_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	instruction_label.position = Vector2((Constants.SCREEN_WIDTH - instruction_size.x) / 2.0, center_y - instruction_size.y + 7)
	add_child(instruction_label)

	score_labels.clear()
	for i in range(10):
		var line = Label.new()
		line.position = Vector2(0, score_base_y + ((i + 1) * line_height))
		line.size = Vector2(Constants.SCREEN_WIDTH, line_height)
		line.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		line.add_theme_font_override("font", menu_font)
		line.add_theme_color_override("font_color", Color(0.38, 0.75, 0.38))
		line.add_theme_font_size_override("font_size", 14)
		add_child(line)
		score_labels.append(line)

	last_score_label = Label.new()
	last_score_label.position = Vector2(0, 450)
	last_score_label.size = Vector2(Constants.SCREEN_WIDTH, 24)
	last_score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	last_score_label.add_theme_font_override("font", menu_font)
	last_score_label.add_theme_color_override("font_color", Color(0.75, 0.38, 0.38))
	last_score_label.add_theme_font_size_override("font_size", 14)
	add_child(last_score_label)

func _create_menu_font() -> Font:
	var font = SystemFont.new()
	font.font_names = PackedStringArray(["MS Sans Serif", "Microsoft Sans Serif", "Tahoma", "Arial", "Helvetica", "Geneva"])
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
	_load_scores()
	_refresh_scores()

func _process(delta: float) -> void:
	if not visible:
		return
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
		var color = Color(0.38, 0.75, 0.38)
		if game and game.waiting_for_high_score_entry and game.high_score_entry_index == i:
			color = Color(0.75, 0.38, 0.38)
			name_text = _apply_entry_cursor(name_text, game.high_score_cursor_pos)
		score_labels[i].add_theme_color_override("font_color", color)
		score_labels[i].text = str(i + 1) + ". " + score_text + "  " + name_text

	if game and game.last_score > 0:
		last_score_label.text = "Last Score " + str(game.last_score).pad_zeros(8)
		last_score_label.visible = true
	else:
		last_score_label.visible = false

func _start_level(level_num: int) -> void:
	if game:
		game.start_game_at_level(level_num)

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

