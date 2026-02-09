extends Control

class_name TitleScreen

const HighScoresScript = preload("res://scripts/core/HighScores.gd")

var game: Game = null
var title_label: Label = null
var instruction_label: Label = null
var score_labels: Array[Label] = []
var last_score_label: Label = null
var high_scores = null

func _ready():
	_set_full_rect()
	game = _find_game()
	_build_ui()
	refresh_from_game()

func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventKey and event.pressed and not event.echo:
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
	var center_y = Constants.SCREEN_HEIGHT / 2.0
	var line_height = 18
	var score_base_y = 250

	title_label = Label.new()
	title_label.size = Vector2(Constants.SCREEN_WIDTH, 24)
	title_label.position = Vector2(0, center_y - title_label.size.y - 9)
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.add_theme_color_override("font_color", Color(0.77, 0.77, 0.25))
	title_label.add_theme_font_size_override("font_size", 18)
	title_label.text = "Alien Invaders --- <ENTER> zu starten"
	add_child(title_label)

	instruction_label = Label.new()
	instruction_label.size = Vector2(Constants.SCREEN_WIDTH, 24)
	instruction_label.position = Vector2(0, center_y - instruction_label.size.y + 7)
	instruction_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	instruction_label.add_theme_color_override("font_color", Color(0.0, 0.38, 0.75))
	instruction_label.add_theme_font_size_override("font_size", 14)
	instruction_label.text = "<linke/rechte Pfeile> links/rechts, <SHIFT> schiessen, <ALT> schuetzen, <Leertaste> stoppen"
	add_child(instruction_label)

	score_labels.clear()
	for i in range(10):
		var line = Label.new()
		line.position = Vector2(0, score_base_y + ((i + 1) * line_height))
		line.size = Vector2(Constants.SCREEN_WIDTH, line_height)
		line.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		line.add_theme_color_override("font_color", Color(0.38, 0.75, 0.38))
		line.add_theme_font_size_override("font_size", 14)
		add_child(line)
		score_labels.append(line)

	last_score_label = Label.new()
	last_score_label.position = Vector2(0, 450)
	last_score_label.size = Vector2(Constants.SCREEN_WIDTH, 24)
	last_score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	last_score_label.add_theme_color_override("font_color", Color(0.75, 0.38, 0.38))
	last_score_label.add_theme_font_size_override("font_size", 14)
	add_child(last_score_label)

func _load_scores() -> void:
	high_scores = HighScoresScript.new()
	high_scores.load_default()

func refresh_from_game() -> void:
	if score_labels.is_empty():
		call_deferred("refresh_from_game")
		return
	_load_scores()
	_refresh_scores()

func _refresh_scores() -> void:
	if high_scores == null or score_labels.size() < 10:
		return
	for i in range(10):
		var entry = high_scores.scores[i]
		var score_text = str(entry["score"]).pad_zeros(8)
		var name_text = entry["name"]
		score_labels[i].text = str(i + 1) + ". " + score_text + "  " + name_text

	if game and game.last_score > 0:
		last_score_label.text = "Last Score " + str(game.last_score).pad_zeros(8)
		last_score_label.visible = true
	else:
		last_score_label.visible = false

func _start_level(level_num: int) -> void:
	if game:
		game.start_game_at_level(level_num)

