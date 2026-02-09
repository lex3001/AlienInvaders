# Game.gd
# Main game orchestration and state management
# Port from vb6/Game.cls

extends Node

class_name Game

# Game state
var game_state: Constants.GameState = Constants.GameState.MENU
var current_level: int = 1
var score: int = 0
var lives: int = 3
var high_score: int = 0
var last_score: int = 0

# Shield system
var shields_left: int = Constants.STARTING_SHIELDS_TICKS
var shields_on: bool = false

# Multiplier system
var score_multiplier: float = 1.0
var multiplier_timer: float = 0.0

# Power-ups
var has_double_shot: bool = false
var has_rapid_fire: bool = false
var has_multi_shot: bool = false

# Frame timing
var accumulated_time: float = 0.0
var ticks_passed: float = 0.0  # milliseconds since last frame
var frame_count: int = 0

# Player death delay handling
var death_wait_ms: float = 0.0
var waiting_for_respawn: bool = false

# Level reference
var level: Node = null

# Background and title screen
var background_layer: CanvasLayer = null
const StarfieldScript = preload("res://scripts/ui/Starfield.gd")

var starfield = null
var title_screen: Node = null
var hud: Node = null

# High scores
var high_scores: HighScores = null
var high_score_entry: Node = null
var waiting_for_high_score_entry: bool = false

# Signals
signal score_changed(new_score: int)
signal lives_changed(new_lives: int)
signal game_over()
signal level_complete()
signal state_changed(new_state: Constants.GameState)

func _ready():
	# Initialize game
	_setup_background()
	_find_title_screen()
	_find_hud()
	_setup_high_score_entry()
	_sync_title_screen_visibility()
	_apply_initial_window_scale()
	load_high_scores()
	reset_game()

func _process(delta: float) -> void:
	# Track frame timing
	ticks_passed = delta * 1000.0  # Convert to milliseconds
	accumulated_time += delta
	frame_count += 1
	
	# Update based on game state
	match game_state:
		Constants.GameState.MENU:
			_process_menu(delta)
		Constants.GameState.PLAYING:
			_process_playing(delta)
		Constants.GameState.PAUSED:
			_process_paused(delta)
		Constants.GameState.GAME_OVER:
			_process_game_over(delta)
		Constants.GameState.LEVEL_COMPLETE:
			_process_level_complete(delta)

func _process_menu(_delta: float) -> void:
	pass

func _process_playing(delta: float) -> void:
	# Update shields
	if shields_on:
		shields_left -= int(ticks_passed)
		if shields_left <= 0:
			shields_left = 0
			shields_on = false
	
	# Update multiplier timer
	if multiplier_timer > 0:
		multiplier_timer -= delta
		if multiplier_timer <= 0:
			score_multiplier = 1.0
	
	# Update level
	if level != null:
		level.update_level(delta)
		if level.is_player_dead_state():
			_handle_player_death(delta)
			return
		
		# Check for level completion
		if level.is_level_complete_state():
			complete_level()
	
	# Handle pause input
	if Input.is_action_just_pressed("ui_cancel"):
		pause_game()

func _process_paused(_delta: float) -> void:
	# Handle pause menu
	if Input.is_action_just_pressed("ui_cancel"):
		resume_game()

func _process_game_over(_delta: float) -> void:
	# Handle game over screen
	if waiting_for_high_score_entry:
		return  # Wait for high score entry to complete
	
	if Input.is_action_just_pressed("ui_accept"):
		reset_game()
		change_state(Constants.GameState.MENU)

func _process_level_complete(_delta: float) -> void:
	# Wait for input to continue to next level
	if Input.is_action_just_pressed("ui_accept"):
		next_level()

func reset_game() -> void:
	score = 0
	lives = 3
	current_level = 1
	shields_left = Constants.STARTING_SHIELDS_TICKS
	shields_on = false
	score_multiplier = 1.0
	has_double_shot = false
	has_rapid_fire = false
	has_multi_shot = false
	
	emit_signal("score_changed", score)
	emit_signal("lives_changed", lives)

func start_game() -> void:
	start_game_at_level(1)

func start_game_at_level(level_num: int) -> void:
	current_level = clampi(level_num, 1, 3)
	reset_game()
	change_state(Constants.GameState.PLAYING)
	load_level(current_level)

func load_level(level_num: int) -> void:
	# Clean up existing level
	if level != null:
		level.queue_free()
		level = null
	waiting_for_respawn = false
	death_wait_ms = 0.0
	
	# Load level scene
	var level_scene = load("res://scenes/Level.tscn")
	if level_scene:
		level = level_scene.instantiate()
		add_child(level)
		level.initialize_level(level_num, self)

func complete_level() -> void:
	change_state(Constants.GameState.LEVEL_COMPLETE)
	emit_signal("level_complete")

func next_level() -> void:
	current_level += 1
	if current_level > 3:  # Assuming 3 levels
		# Game complete - show victory screen
		change_state(Constants.GameState.GAME_OVER)
	else:
		change_state(Constants.GameState.PLAYING)
		load_level(current_level)

func add_score(points: int) -> void:
	var adjusted_points = int(points * score_multiplier)
	score += adjusted_points
	
	if score > high_score:
		high_score = score
		save_high_score()
	
	emit_signal("score_changed", score)

func lose_life() -> void:
	lives -= 1
	emit_signal("lives_changed", lives)
	
	if lives <= 0:
		end_game()

func add_life() -> void:
	lives += 1
	emit_signal("lives_changed", lives)

func end_game() -> void:
	last_score = score
	change_state(Constants.GameState.GAME_OVER)
	emit_signal("game_over")
	if level != null:
		level.queue_free()
		level = null
	
	# Check if score qualifies for high score table
	if high_scores and high_scores.is_high_score(score):
		_show_high_score_entry()
	else:
		waiting_for_high_score_entry = false

func _handle_player_death(delta: float) -> void:
	if not waiting_for_respawn:
		waiting_for_respawn = true
		death_wait_ms = 0.0
		return

	death_wait_ms += delta * 1000.0
	if death_wait_ms < float(Constants.END_LEVEL_PAUSE_MS):
		return

	waiting_for_respawn = false
	death_wait_ms = 0.0

	var level_node = level as Level
	if level_node:
		level_node.is_player_dead = false
		if level_node.has_safety_pin:
			level_node.has_safety_pin = false
		else:
			level_node.has_double_shots = false
			level_node.has_multi_shots = false
			level_node.has_rapid_fire = false

	lose_life()
	if lives <= 0:
		return
	load_level(current_level)

func pause_game() -> void:
	if game_state == Constants.GameState.PLAYING:
		change_state(Constants.GameState.PAUSED)

func resume_game() -> void:
	if game_state == Constants.GameState.PAUSED:
		change_state(Constants.GameState.PLAYING)

func change_state(new_state: Constants.GameState) -> void:
	game_state = new_state
	emit_signal("state_changed", new_state)
	_sync_title_screen_visibility()

func _setup_background() -> void:
	background_layer = CanvasLayer.new()
	background_layer.layer = -100

	var bg = ColorRect.new()
	bg.color = Color.BLACK
	bg.size = Vector2(Constants.SCREEN_WIDTH, Constants.SCREEN_HEIGHT)
	background_layer.add_child(bg)

	starfield = StarfieldScript.new()
	starfield.play_rect = Rect2(0, Constants.TOP_BORDER, Constants.SCREEN_WIDTH, Constants.PLAY_HEIGHT)
	background_layer.add_child(starfield)

	add_child(background_layer)

func _find_title_screen() -> void:
	if get_parent() == null:
		return
	title_screen = get_parent().get_node_or_null("TitleScreen")

func _find_hud() -> void:
	if get_parent() == null:
		return
	hud = get_parent().get_node_or_null("HUD")
	if hud and hud.has_method("set_game"):
		hud.set_game(self)

func _sync_title_screen_visibility() -> void:
	if title_screen:
		var show_menu = game_state == Constants.GameState.MENU or game_state == Constants.GameState.GAME_OVER
		title_screen.visible = show_menu
		if show_menu and title_screen.has_method("refresh_from_game"):
			title_screen.refresh_from_game()
	if starfield:
		starfield.visible = game_state != Constants.GameState.MENU

func _apply_initial_window_scale() -> void:
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)

func activate_shields() -> void:
	if shields_left > 0:
		shields_on = true

func deactivate_shields() -> void:
	shields_on = false

func add_shields(amount: int) -> void:
	shields_left += amount
	if shields_left > Constants.MAX_SHIELDS_TICKS:
		shields_left = Constants.MAX_SHIELDS_TICKS

func set_multiplier(multiplier: float, duration: float) -> void:
	score_multiplier = multiplier
	multiplier_timer = duration

func load_high_scores() -> void:
	# Load high scores from file
	if not high_scores:
		high_scores = HighScores.new()
	high_scores.load_default()
	
	# Set high_score to the top score
	if high_scores.scores.size() > 0:
		high_score = high_scores.scores[0].score

func save_high_scores() -> void:
	if high_scores:
		high_scores.save_to_file("user://AI.HS")

func load_high_score() -> void:
	# Legacy method retained for backwards compatibility with existing code that calls load_high_score()
	# Delegates to the new load_high_scores() method
	load_high_scores()

func save_high_score() -> void:
	# Legacy method retained for backwards compatibility with existing code that calls save_high_score()
	# Delegates to the new save_high_scores() method
	save_high_scores()

func _setup_high_score_entry() -> void:
	# Create high score entry UI
	const HighScoreEntryScript = preload("res://scripts/ui/HighScoreEntry.gd")
	high_score_entry = HighScoreEntryScript.new()
	high_score_entry.name_entered.connect(_on_high_score_name_entered)
	add_child(high_score_entry)

func _show_high_score_entry() -> void:
	waiting_for_high_score_entry = true
	if high_score_entry and high_score_entry.has_method("show_entry"):
		high_score_entry.show_entry(score)

func _on_high_score_name_entered(player_name: String) -> void:
	if high_scores:
		high_scores.add_score(player_name, score)
		save_high_scores()
		if score > high_score:
			high_score = score
	waiting_for_high_score_entry = false
