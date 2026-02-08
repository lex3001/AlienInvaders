# Game.gd
# Main game orchestration and state management
# Port from vb6/Game.cls

extends Node

class_name Game

# Game state
var game_state: GameConstants.GameState = GameConstants.GameState.MENU
var current_level: int = 1
var score: int = 0
var lives: int = 3
var high_score: int = 0

# Shield system
var shields_left: int = GameConstants.STARTING_SHIELDS_TICKS
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

# Level reference
var level: Node = null

# Signals
signal score_changed(new_score: int)
signal lives_changed(new_lives: int)
signal game_over()
signal level_complete()
signal state_changed(new_state: GameConstants.GameState)

func _ready():
	# Initialize game
	load_high_score()
	reset_game()

func _process(delta: float) -> void:
	# Track frame timing
	ticks_passed = delta * 1000.0  # Convert to milliseconds
	accumulated_time += delta
	frame_count += 1
	
	# Update based on game state
	match game_state:
		GameConstants.GameState.MENU:
			_process_menu(delta)
		GameConstants.GameState.PLAYING:
			_process_playing(delta)
		GameConstants.GameState.PAUSED:
			_process_paused(delta)
		GameConstants.GameState.GAME_OVER:
			_process_game_over(delta)
		GameConstants.GameState.LEVEL_COMPLETE:
			_process_level_complete(delta)

func _process_menu(delta: float) -> void:
	# Handle menu input
	if Input.is_action_just_pressed("ui_accept"):
		start_game()

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
		
		# Check for level completion
		if level.is_level_complete():
			complete_level()
	
	# Handle pause input
	if Input.is_action_just_pressed("ui_cancel"):
		pause_game()

func _process_paused(delta: float) -> void:
	# Handle pause menu
	if Input.is_action_just_pressed("ui_cancel"):
		resume_game()

func _process_game_over(delta: float) -> void:
	# Handle game over screen
	if Input.is_action_just_pressed("ui_accept"):
		reset_game()
		change_state(GameConstants.GameState.MENU)

func _process_level_complete(delta: float) -> void:
	# Wait for input to continue to next level
	if Input.is_action_just_pressed("ui_accept"):
		next_level()

func reset_game() -> void:
	score = 0
	lives = 3
	current_level = 1
	shields_left = GameConstants.STARTING_SHIELDS_TICKS
	shields_on = false
	score_multiplier = 1.0
	has_double_shot = false
	has_rapid_fire = false
	has_multi_shot = false
	
	emit_signal("score_changed", score)
	emit_signal("lives_changed", lives)

func start_game() -> void:
	reset_game()
	change_state(GameConstants.GameState.PLAYING)
	load_level(current_level)

func load_level(level_num: int) -> void:
	# Clean up existing level
	if level != null:
		level.queue_free()
		level = null
	
	# Load level scene
	var level_scene = load("res://scenes/Level.tscn")
	if level_scene:
		level = level_scene.instantiate()
		add_child(level)
		level.initialize_level(level_num, self)

func complete_level() -> void:
	change_state(GameConstants.GameState.LEVEL_COMPLETE)
	emit_signal("level_complete")

func next_level() -> void:
	current_level += 1
	if current_level > 3:  # Assuming 3 levels
		# Game complete - show victory screen
		change_state(GameConstants.GameState.GAME_OVER)
	else:
		change_state(GameConstants.GameState.PLAYING)
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
	change_state(GameConstants.GameState.GAME_OVER)
	emit_signal("game_over")
	
	if score > high_score:
		high_score = score
		save_high_score()

func pause_game() -> void:
	if game_state == GameConstants.GameState.PLAYING:
		change_state(GameConstants.GameState.PAUSED)

func resume_game() -> void:
	if game_state == GameConstants.GameState.PAUSED:
		change_state(GameConstants.GameState.PLAYING)

func change_state(new_state: GameConstants.GameState) -> void:
	game_state = new_state
	emit_signal("state_changed", new_state)

func activate_shields() -> void:
	if shields_left > 0:
		shields_on = true

func deactivate_shields() -> void:
	shields_on = false

func add_shields(amount: int) -> void:
	shields_left += amount
	if shields_left > GameConstants.MAX_SHIELDS_TICKS:
		shields_left = GameConstants.MAX_SHIELDS_TICKS

func set_multiplier(multiplier: float, duration: float) -> void:
	score_multiplier = multiplier
	multiplier_timer = duration

func load_high_score() -> void:
	# Load from file or settings
	var save_file = "user://highscore.save"
	if FileAccess.file_exists(save_file):
		var file = FileAccess.open(save_file, FileAccess.READ)
		if file:
			high_score = file.get_32()
			file.close()

func save_high_score() -> void:
	# Save to file
	var save_file = "user://highscore.save"
	var file = FileAccess.open(save_file, FileAccess.WRITE)
	if file:
		file.store_32(high_score)
		file.close()
