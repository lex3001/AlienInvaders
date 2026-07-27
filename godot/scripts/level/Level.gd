# Level.gd
# Level manager - handles spawning, updating, and managing all actors
# Port from vb6/Level.cls

extends Node2D

class_name Level

# Game reference
var game: Game = null

# Player
var player: Actor = null
var planet: Actor = null
var xbonus: Actor = null

# Actor arrays
var aliens: Array[Actor] = []
var missiles: Array[Actor] = []
var bombs: Array[Actor] = []
var cargo: Array[Actor] = []
var powerups: Array[Actor] = []
var cargo_ships: Array[Actor] = []
var alien_f: Actor = null

# Visual bonuses (floating score text)
var display_bonuses: Array[Dictionary] = []

# Level state
var level_number: int = 1
var is_level_complete: bool = false
var is_player_dead: bool = false
var death_sequence_id: int = 0
var num_aliens_must_be_destroyed: int = 0
var aliens_destroyed: int = 0

# Play area dimensions
var play_width: float = Constants.SCREEN_WIDTH
var play_height: float = Constants.PLAY_HEIGHT
var play_x_offset: float = 0.0
var play_y_offset: float = Constants.TOP_BORDER

# Timing
var ticks_passed: float = 0.0
var game_speed_multiplier: float = 1.0

# Shields
var shields_left: int = Constants.STARTING_SHIELDS_TICKS
var shields_on: bool = false

# Power-ups
var has_double_shots: bool = false
var has_rapid_fire: bool = false
var has_multi_shots: bool = false
var has_safety_pin: bool = false

# Score and bonus
var score: int = 0
var bonus: int = 0
var bonus_multiplier: int = 1
var starting_bonus: int = 2500
var bonus_ticks: float = 0.0

# Formation leader (for alien formations)
var formation_leader: Actor = null

# Wave movement parameters (for Level 2)
var wave_enabled: bool = false
var wave_amplitude: float = 25.0  # Height of the wave (adjustable)
var wave_period: float = 3.0  # Time for one complete oscillation (seconds)
var wave_time: float = 0.0  # Elapsed time for wave calculation
var alien_wave_offsets: Dictionary = {}  # Track previous wave offsets per alien

# Collision manager
var collision_manager: CollisionManager = null

# Sound manager
var sound_manager: SoundManager = null
var alienf_loop_attempted: bool = false
var alienf_loop_playing: bool = false

# Sprite textures
const TEX_PLAYER = preload("res://assets/sprites/Ship.bmp")
const TEX_ALIEN_A = preload("res://assets/sprites/AlienA.bmp")
const TEX_ALIEN_B = preload("res://assets/sprites/AlienB.bmp")
const TEX_ALIEN_C = preload("res://assets/sprites/AlienC.bmp")
const TEX_ALIEN_D = preload("res://assets/sprites/AlienD.bmp")
const TEX_ALIEN_E = preload("res://assets/sprites/AlienE2.bmp")
const TEX_ALIEN_F_PATH = "res://assets/sprites/AlienF.png"
const ALIENF_LOOP_PATH = "res://assets/audio/mixkit-sci-fi-spaceship-in-cosmos-2734.wav"
const TEX_MISSILE = preload("res://assets/sprites/Missle.bmp")
const TEX_BOMB_A = preload("res://assets/sprites/BombA.bmp")
const TEX_BOMB_D = preload("res://assets/sprites/BombD.bmp")
const TEX_POWERUP = preload("res://assets/sprites/Cargo.bmp")
const TEX_ROCKET = preload("res://assets/sprites/Rocket.bmp")
const TEX_PLANET = preload("res://assets/sprites/Planet.bmp")
const TEX_XBONUS = preload("res://assets/sprites/XBonus.bmp")
const TEX_BONUSES = preload("res://assets/sprites/Bonuses.bmp")
const BrainCargoShipScript = preload("res://scripts/ai/BrainCargoShip.gd")
const BrainPlanetScript = preload("res://scripts/ai/BrainPlanet.gd")
const BrainXBonusScript = preload("res://scripts/ai/BrainXBonus.gd")
const BrainCargoScript = preload("res://scripts/ai/BrainCargo.gd")
const BrainAlienAScript = preload("res://scripts/ai/BrainAlienA.gd")
const BrainAlienCScript = preload("res://scripts/ai/BrainAlienC.gd")
const BrainAlienDScript = preload("res://scripts/ai/BrainAlienD.gd")
const BrainAlienEScript = preload("res://scripts/ai/BrainAlienE.gd")
const BrainAlienFScript = preload("res://scripts/ai/BrainAlienF.gd")
const SIZE_PLAYER = Vector2i(26, 18)
const SIZE_ALIEN_A = Vector2i(23, 8)
const SIZE_ALIEN_B = Vector2i(16, 16)
const SIZE_ALIEN_C = Vector2i(10, 16)
const SIZE_ALIEN_D = Vector2i(20, 20)
const SIZE_ALIEN_E = Vector2i(13, 8)
const SIZE_ALIEN_F = Vector2i(16, 14)
const SIZE_MISSILE = Vector2i(2, 8)
const SIZE_BOMB_A = Vector2i(2, 8)
const SIZE_BOMB_D = Vector2i(5, 5)
const SIZE_CARGO = Vector2i(11, 7)
const SIZE_ROCKET = Vector2i(32, 12)
const SIZE_PLANET = Vector2i(24, 12)
const SIZE_XBONUS = Vector2i(12, 12)
const BONUS_FRAME_W = 24
const BONUS_FRAME_H = 7

func _ready():
	# Initialize collision manager
	collision_manager = CollisionManager.new()
	collision_manager.play_width = play_width
	collision_manager.play_height = play_height
	collision_manager.play_y_offset = play_y_offset
	collision_manager._initialize_grid()
	add_child(collision_manager)
	
	# Initialize sound manager
	sound_manager = SoundManager.new()
	add_child(sound_manager)
	sound_manager.load_all_game_sounds()
	
	# Create black mask to cover area below play area (below blue line)
	var bottom_mask = ColorRect.new()
	bottom_mask.color = Color.BLACK
	bottom_mask.position = Vector2(0, play_y_offset + play_height)
	bottom_mask.size = Vector2(Constants.SCREEN_WIDTH, Constants.BOTTOM_BORDER)
	bottom_mask.z_index = 100  # Above actors, below HUD
	add_child(bottom_mask)

func _assign_sprite(actor: Actor, texture: Texture2D, frame_size: Vector2i = Vector2i.ZERO) -> void:
	if not actor:
		return
	if actor.sprite == null:
		actor.sprite = Sprite2D.new()
		actor.add_child(actor.sprite)
	actor.sprite.texture = texture
	actor.sprite.centered = true
	if frame_size.x > 0 and frame_size.y > 0:
		actor.sprite.region_enabled = true
		actor.sprite.region_rect = Rect2(Vector2.ZERO, Vector2(frame_size.x, frame_size.y))

func initialize_level(p_level_number: int, p_game: Game) -> void:
	level_number = p_level_number
	game = p_game
	is_player_dead = false
	is_level_complete = false
	bonus_multiplier = 1
	bonus_ticks = 0.0
	bonus = starting_bonus
	if game:
		game.score_multiplier = 1.0
	
	# Clear existing actors
	_clear_actors()
	
	# Load level based on number
	match level_number:
		1:
			_load_level_1()
		2:
			_load_level_2()
		3:
			_load_level_3()
		4:
			_load_level_4()
		_:
			push_warning("Unknown level number: " + str(level_number))
			_load_level_1()

func apply_game_speed(multiplier: float) -> void:
	"""Apply game speed multiplier to affect all timing in the level."""
	game_speed_multiplier = multiplier
	
	# Apply to formation leader movement
	if formation_leader:
		formation_leader.velocity_magnitude = 30.0 * multiplier
	
	# Note: Actor brains will automatically use scaled delta from update_level()


func _clear_actors() -> void:
	# Remove all existing actors
	for alien in aliens:
		if alien and is_instance_valid(alien):
			alien.queue_free()
	aliens.clear()
	
	for missile in missiles:
		if missile and is_instance_valid(missile):
			missile.queue_free()
	missiles.clear()
	
	for bomb in bombs:
		if bomb and is_instance_valid(bomb):
			bomb.queue_free()
	bombs.clear()
	
	for c in cargo:
		if c and is_instance_valid(c):
			c.queue_free()
	cargo.clear()
	
	for p in powerups:
		if p and is_instance_valid(p):
			p.queue_free()
	powerups.clear()

	for ship in cargo_ships:
		if ship and is_instance_valid(ship):
			ship.queue_free()
	cargo_ships.clear()
	
	display_bonuses.clear()
	
	if player and is_instance_valid(player):
		player.queue_free()
		player = null

	if planet and is_instance_valid(planet):
		planet.queue_free()
		planet = null

	if xbonus and is_instance_valid(xbonus):
		xbonus.queue_free()
		xbonus = null
	alien_f = null
	
	# Clear wave effect data
	wave_enabled = false
	wave_time = 0.0
	alien_wave_offsets.clear()
	
	if formation_leader and is_instance_valid(formation_leader):
		formation_leader.queue_free()
		formation_leader = null

	for entry in display_bonuses:
		if entry.has("sprite"):
			var sprite = entry["sprite"] as Sprite2D
			if sprite and is_instance_valid(sprite):
				sprite.queue_free()
	display_bonuses.clear()

func _load_level_1() -> void:
	# Create formation leader (invisible, drives formation movement)
	formation_leader = Actor.new()
	formation_leader.name = "FormationLeader"
	formation_leader.movement_type = Actor.MovementType.MARCHING
	formation_leader.velocity_magnitude = 30.0
	formation_leader.velocity_direction = 0.0  # Moving right
	formation_leader.marching_distance = play_width - 240.0
	formation_leader.position = Vector2(0, play_y_offset)
	add_child(formation_leader)
	
	# Create player
	player = _create_player()
	
	# Create AlienA formation (15 aliens)
	var alien_a_positions = [
		Vector2(1.5, 182), Vector2(14.5, 194), Vector2(27.5, 182),
		Vector2(40.5, 194), Vector2(53.5, 182), Vector2(66.5, 194),
		Vector2(79.5, 182), Vector2(92.5, 194), Vector2(105.5, 182),
		Vector2(118.5, 194), Vector2(131.5, 182), Vector2(144.5, 194),
		Vector2(157.5, 182), Vector2(170.5, 194), Vector2(183.5, 182)
	]
	
	for pos in alien_a_positions:
		var alien_a = _create_alien_a(pos)
		aliens.append(alien_a)
	
	# Create AlienB formation (6 aliens - decorative tanks)
	var alien_b_positions = [
		Vector2(40, 144), Vector2(57, 144), Vector2(74, 144),
		Vector2(118, 144), Vector2(135, 144), Vector2(152, 144)
	]
	
	for pos in alien_b_positions:
		var alien_b = _create_alien_b(pos)
		aliens.append(alien_b)
	
	# Create AlienC (2 aggressive attackers)
	var alien = _create_alien_c(Vector2(57, 162))
	aliens.append(alien)
	alien = _create_alien_c(Vector2(135, 162))
	aliens.append(alien)
	
	# Create AlienD (2 orbital bombers)
	alien = _create_alien_d(Vector2(57, 122))
	aliens.append(alien)
	alien = _create_alien_d(Vector2(135, 122))
	aliens.append(alien)
	
	# Create AlienE (4 advanced enemies)
	alien = _create_alien_e(Vector2(32.5, 170))
	aliens.append(alien)
	alien = _create_alien_e(Vector2(84.5, 170))
	aliens.append(alien)
	alien = _create_alien_e(Vector2(110.5, 170))
	aliens.append(alien)
	alien = _create_alien_e(Vector2(162.5, 170))
	aliens.append(alien)

	# Create Planet and XBonus
	planet = _create_planet()
	xbonus = _create_xbonus()

	# Create cargo ship (rocket)
	var cargo_ship = _create_cargo_ship()
	cargo_ships.append(cargo_ship)

	# Create AlienF special roamer (spawns itself when unlocked)
	alien_f = _create_alien_f()
	aliens.append(alien_f)
	
	# Set aliens that must be destroyed
	num_aliens_must_be_destroyed = 15 + 2 + 2 + 4  # A + C + D + E
	aliens_destroyed = 0

func _load_level_2() -> void:
	# Create player
	player = _create_player()

	# AlienA formation (20) - flat line at the bottom
	var bottom_y = 220.0
	var start_x = 50.0
	var spacing = 27.0
	for i in range(20):
		var x_pos = start_x + float(i) * spacing
		var alien_a = _create_alien_a(Vector2.ZERO)
		alien_a.set_movement_normal(Vector2(x_pos, _play_y(bottom_y)), 0.0, 0.0)
		aliens.append(alien_a)

	# AlienB formation (9) - moved up slightly
	for i in range(9):
		var x_b = 320.0 - (float(9 - 1) * 18.0 / 2.0) + float(i) * 18.0
		var alien_b = _create_alien_b(Vector2.ZERO)
		alien_b.set_movement_normal(Vector2(x_b, _play_y(170.0)), 0.0, 0.0)
		aliens.append(alien_b)

	# AlienC (2) - positioned above the bottom line
	var alien = _create_alien_c(Vector2.ZERO)
	alien.set_movement_normal(Vector2(110.0, _play_y(190.0)), 0.0, 0.0)
	aliens.append(alien)
	alien = _create_alien_c(Vector2.ZERO)
	alien.set_movement_normal(Vector2(530.0, _play_y(190.0)), 0.0, 0.0)
	aliens.append(alien)

	# AlienD (2) radial points - centered higher up
	var d_points = _create_radial_points(65.0, 20.0, 320.0, _play_y(130.0))
	for i in range(2):
		alien = _create_alien_d(Vector2.ZERO)
		alien.set_movement_radial_points(d_points, 4000.0, float(i) * 180.0)
		aliens.append(alien)

	# AlienE (6) radial points - positioned near AlienC
	var e_points_left = _create_radial_points(20.0, 20.0, 110.0, _play_y(190.0))
	var e_points_right = _create_radial_points(20.0, 20.0, 530.0, _play_y(190.0))
	for i in range(6):
		alien = _create_alien_e(Vector2.ZERO)
		if i < 3:
			alien.set_movement_radial_points(e_points_left, 3000.0, float(i) * 120.0)
		else:
			alien.set_movement_radial_points(e_points_right, -3000.0, float(i - 3) * 120.0)
		alien.always_update_radial_position = true
		aliens.append(alien)

	# Create Planet and XBonus
	planet = _create_planet()
	xbonus = _create_xbonus()

	# Create cargo ship
	var cargo_ship = _create_cargo_ship()
	cargo_ships.append(cargo_ship)

	# Create AlienF special roamer (spawns itself when unlocked)
	alien_f = _create_alien_f()
	aliens.append(alien_f)

	# Enable wave effect for Level 2
	wave_enabled = true
	wave_time = 0.0

	num_aliens_must_be_destroyed = 20 + 2 + 2 + 6
	aliens_destroyed = 0

func _load_level_3() -> void:
	# Create player
	player = _create_player()

	# AlienA set 1 (14) radial points
	var a_points1 = _create_radial_points(65.0, 65.0, 320.0, _play_y(150.0))
	for i in range(14):
		var alien_a1 = _create_alien_a(Vector2.ZERO)
		alien_a1.set_movement_radial_points(a_points1, -10000.0, float(i) * (360.0 / 14.0))
		aliens.append(alien_a1)

	# AlienA set 2 (10) radial points
	var a_points2 = _create_radial_points(40.0, 40.0, 320.0, _play_y(150.0))
	for i in range(10):
		var alien_a2 = _create_alien_a(Vector2.ZERO)
		alien_a2.set_movement_radial_points(a_points2, 8000.0, float(i) * (360.0 / 10.0))
		aliens.append(alien_a2)

	# AlienB (14) radial points
	var b_points_left = _create_radial_points(25.0, 25.0, 180.0, _play_y(200.0))
	var b_points_right = _create_radial_points(25.0, 25.0, 460.0, _play_y(200.0))
	var b_degrees = [0.0, 51.0, 103.0, 154.0, 206.0, 257.0, 309.0]
	for i in range(14):
		var alien_b = _create_alien_b(Vector2.ZERO)
		if i < 7:
			alien_b.set_movement_radial_points(b_points_left, 4000.0, b_degrees[i])
		else:
			alien_b.set_movement_radial_points(b_points_right, -4000.0, b_degrees[i - 7])
		aliens.append(alien_b)

	# AlienC (2) radial points
	var c_points = _create_radial_points(10.0, 10.0, 320.0, _play_y(150.0))
	for i in range(2):
		var alien_c = _create_alien_c(Vector2.ZERO)
		alien_c.set_movement_radial_points(c_points, 3000.0, float(i) * 180.0)
		aliens.append(alien_c)

	# AlienD (2) normal positions
	var alien_d = _create_alien_d(Vector2.ZERO)
	alien_d.set_movement_normal(Vector2(180.0, _play_y(200.0)), 0.0, 0.0)
	aliens.append(alien_d)
	alien_d = _create_alien_d(Vector2.ZERO)
	alien_d.set_movement_normal(Vector2(460.0, _play_y(200.0)), 0.0, 0.0)
	aliens.append(alien_d)

	# AlienE (4) radial points
	var e_points = _create_radial_points(20.0, 20.0, 320.0, _play_y(150.0))
	for i in range(4):
		var alien_e = _create_alien_e(Vector2.ZERO)
		alien_e.set_movement_radial_points(e_points, -6000.0, float(i) * 90.0)
		alien_e.always_update_radial_position = true
		aliens.append(alien_e)

	# Create Planet and XBonus
	planet = _create_planet()
	xbonus = _create_xbonus()

	# Create cargo ship
	var cargo_ship = _create_cargo_ship()
	cargo_ships.append(cargo_ship)

	# Create AlienF special roamer (spawns itself when unlocked)
	alien_f = _create_alien_f()
	aliens.append(alien_f)

	num_aliens_must_be_destroyed = 14 + 10 + 2 + 2 + 4
	aliens_destroyed = 0

func _load_level_4() -> void:
	# Level 4 - "The Breathing Fortress"
	# A living fortress that breathes in and out from center point
	# Dangerous aliens (C, D, E) at top, shields (A, B) at bottom
	
	# Create formation leader (center point for breathing and marching)
	formation_leader = Actor.new()
	formation_leader.name = "FormationLeader"
	formation_leader.movement_type = Actor.MovementType.MARCHING
	formation_leader.velocity_magnitude = 20.0  # Slow deliberate march
	formation_leader.velocity_direction = 0.0
	formation_leader.marching_distance = 150.0  # Moderate march range
	formation_leader.position = Vector2(320, play_y_offset + 150)  # Center of formation
	add_child(formation_leader)
	
	# Create player
	player = _create_player()
	
	# Breathing parameters (will be applied in update function)
	var breath_amplitude = 25.0  # How far aliens move during breath
	var breath_amplitude_shields = 15.0  # Less dramatic for A and B
	
	# === LAYER 1: AlienD Top Bombers (2) ===
	var alien_d = _create_alien_d(Vector2(-80, -50))
	aliens.append(alien_d)
	alien_d = _create_alien_d(Vector2(80, -50))
	aliens.append(alien_d)
	
	# === LAYER 2 & 3: AlienC Diamond Core (4) ===
	var alien_c = _create_alien_c(Vector2(0, -50))  # Top
	aliens.append(alien_c)
	alien_c = _create_alien_c(Vector2(-40, -25))  # Left
	aliens.append(alien_c)
	alien_c = _create_alien_c(Vector2(40, -25))  # Right
	aliens.append(alien_c)
	alien_c = _create_alien_c(Vector2(0, -10))  # Bottom
	aliens.append(alien_c)
	
	# === LAYER 2 & 3: AlienE Wing Squadron (16) ===
	# Left wing - upper row (4)
	var e_left_upper_x = [-120, -100, -80, -60]
	for x in e_left_upper_x:
		var alien_e = _create_alien_e(Vector2(x, -25))
		aliens.append(alien_e)
	
	# Left wing - lower row (4)
	var e_left_lower_x = [-120, -100, -80, -60]
	for x in e_left_lower_x:
		var alien_e = _create_alien_e(Vector2(x, -10))
		aliens.append(alien_e)
	
	# Right wing - upper row (4)
	var e_right_upper_x = [60, 80, 100, 120]
	for x in e_right_upper_x:
		var alien_e = _create_alien_e(Vector2(x, -25))
		aliens.append(alien_e)
	
	# Right wing - lower row (4)
	var e_right_lower_x = [60, 80, 100, 120]
	for x in e_right_lower_x:
		var alien_e = _create_alien_e(Vector2(x, -10))
		aliens.append(alien_e)
	
	# === LAYER 4: AlienB Blocker Wall (5) ===
	var b_x_positions = [-80, -40, 0, 40, 80]
	for x in b_x_positions:
		var alien_b = _create_alien_b(Vector2(x, 25))
		alien_b.must_be_destroyed = false
		aliens.append(alien_b)
	
	# === LAYER 5 & 6: AlienA Bottom Shields (23) ===
	# Row 1 - 12 aliens
	var a_row1_x = [-110, -90, -70, -50, -30, -10, 10, 30, 50, 70, 90, 110]
	for x in a_row1_x:
		var alien_a = _create_alien_a(Vector2(x, 60))
		alien_a.must_be_destroyed = false
		aliens.append(alien_a)
	
	# Row 2 - 11 aliens (offset, with center alien)
	var a_row2_x = [-100, -80, -60, -40, -20, 0, 20, 40, 60, 80, 100]
	for x in a_row2_x:
		var alien_a = _create_alien_a(Vector2(x, 75))
		alien_a.must_be_destroyed = false
		aliens.append(alien_a)
	
	# Store breathing metadata for each alien
	# We'll use a custom property to track home position and breathing behavior
	for alien in aliens:
		if alien and alien.leader != null:
			# Store the home offset from formation leader
			alien.set_meta("breath_home_offset", alien.relative_position)
			
			# Determine breath amplitude based on type
			var is_shield = alien.brain is BrainAlienA or alien.brain is BrainAlienB
			alien.set_meta("breath_amplitude", breath_amplitude_shields if is_shield else breath_amplitude)
			
			# Calculate breathe direction (normalized vector from center to home position)
			var breath_dir = alien.relative_position.normalized()
			if alien.relative_position.length() < 0.1:
				breath_dir = Vector2.ZERO  # Center alien doesn't breathe
			alien.set_meta("breath_direction", breath_dir)
	
	# Enable custom breathing effect (we'll implement this in the update function)
	# Using wave_enabled as a flag, but we'll implement custom breathing logic
	wave_enabled = false  # Don't use the standard wave effect
	
	# Store breathing parameters on the level
	set_meta("breathing_enabled", true)
	set_meta("breath_period", 4.0)
	set_meta("breath_time", 0.0)
	
	# Create Planet and XBonus
	planet = _create_planet()
	xbonus = _create_xbonus()
	
	# Create cargo ship
	var cargo_ship = _create_cargo_ship()
	cargo_ships.append(cargo_ship)

	# Create AlienF special roamer (spawns itself when unlocked)
	alien_f = _create_alien_f()
	aliens.append(alien_f)
	
	# Set aliens that must be destroyed: C + D + E (NOT A or B)
	num_aliens_must_be_destroyed = 4 + 2 + 16  # C + D + E
	aliens_destroyed = 0

func _create_radial_points(radius_x: float, radius_y: float, center_x: float, center_y: float,
		x_factor: float = 1.0, y_factor: float = 1.0) -> Array[Vector2]:
	var points: Array[Vector2] = []
	points.resize(360)
	for i in range(360):
		var radians = deg_to_rad(float(i))
		var x = center_x + cos(radians * x_factor) * radius_x
		var y = center_y + sin(radians * y_factor) * radius_y
		points[i] = Vector2(x, y)
	return points

func _play_y(y: float) -> float:
	return y + play_y_offset

func _create_player() -> Actor:
	var p = Actor.new()
	p.name = "Player"
	var player_size = Vector2(SIZE_PLAYER.x, SIZE_PLAYER.y)
	p.position = Vector2(play_width / 2, play_y_offset + play_height - (player_size.y / 2.0) - 16.0)
	p.brain = BrainPlayer.new()
	p.brain.initialize(p, self)
	p.level = self
	_assign_sprite(p, TEX_PLAYER, SIZE_PLAYER)
	_setup_player_animation(p)
	add_child(p)
	return p

func _create_alien_a(relative_pos: Vector2) -> Actor:
	var alien = Actor.new()
	alien.name = "AlienA"
	alien.brain = BrainAlienA.new()
	alien.set_movement_relative_position(formation_leader, relative_pos)
	alien.brain.initialize(alien, self)
	alien.level = self
	alien.can_be_hit_by_missiles = true
	alien.must_be_destroyed = true
	_assign_sprite(alien, TEX_ALIEN_A, SIZE_ALIEN_A)
	_setup_alien_a_animation(alien)
	add_child(alien)
	return alien

func _create_alien_b(relative_pos: Vector2) -> Actor:
	var alien = Actor.new()
	alien.name = "AlienB"
	alien.brain = BrainAlienB.new()
	alien.set_movement_relative_position(formation_leader, relative_pos)
	alien.brain.initialize(alien, self)
	alien.level = self
	alien.can_be_hit_by_missiles = true
	alien.must_be_destroyed = false  # Decorative
	_assign_sprite(alien, TEX_ALIEN_B, SIZE_ALIEN_B)
	_setup_alien_b_animation(alien)
	add_child(alien)
	return alien

func _create_alien_c(relative_pos: Vector2) -> Actor:
	var alien = Actor.new()
	alien.name = "AlienC"
	alien.brain = BrainAlienC.new()
	alien.set_movement_relative_position(formation_leader, relative_pos)
	alien.brain.initialize(alien, self)
	alien.level = self
	alien.can_be_hit_by_missiles = true
	alien.must_be_destroyed = true
	_assign_sprite(alien, TEX_ALIEN_C, SIZE_ALIEN_C)
	_setup_alien_c_animation(alien)
	add_child(alien)
	return alien

func _create_alien_d(relative_pos: Vector2) -> Actor:
	var alien = Actor.new()
	alien.name = "AlienD"
	alien.brain = BrainAlienD.new()
	alien.set_movement_relative_position(formation_leader, relative_pos)
	alien.brain.initialize(alien, self)
	alien.level = self
	alien.can_be_hit_by_missiles = true
	alien.must_be_destroyed = true
	_assign_sprite(alien, TEX_ALIEN_D, SIZE_ALIEN_D)
	_setup_alien_d_animation(alien)
	add_child(alien)
	return alien

func _create_alien_e(relative_pos: Vector2) -> Actor:
	var alien = Actor.new()
	alien.name = "AlienE"
	alien.brain = BrainAlienE.new()
	alien.set_movement_relative_position(formation_leader, relative_pos)
	alien.brain.initialize(alien, self)
	alien.level = self
	alien.can_be_hit_by_missiles = true
	alien.must_be_destroyed = true
	_assign_sprite(alien, TEX_ALIEN_E, SIZE_ALIEN_E)
	_setup_alien_e_animation(alien)
	add_child(alien)
	return alien

func _create_alien_f() -> Actor:
	var alien = Actor.new()
	alien.name = "AlienF"
	alien.brain = BrainAlienFScript.new()
	alien.brain.initialize(alien, self)
	alien.level = self
	alien.can_be_hit_by_missiles = false
	alien.must_be_destroyed = false
	
	# Try multiple texture loading methods
	var alien_f_texture: Texture2D = null
	if ResourceLoader.exists(TEX_ALIEN_F_PATH):
		alien_f_texture = ResourceLoader.load(TEX_ALIEN_F_PATH, "Texture2D") as Texture2D
	
	if alien_f_texture == null:
		push_warning("AlienF texture not found, using placeholder: " + TEX_ALIEN_F_PATH)
		# Use a visible placeholder - the ship sprite temporarily
		_assign_sprite(alien, TEX_PLAYER, SIZE_ALIEN_F)
	else:
		_assign_sprite(alien, alien_f_texture, SIZE_ALIEN_F)
	
	# Verify sprite was created
	if alien.sprite:
		alien.sprite.z_index = 10  # Render above most other actors
	
	_setup_alien_f_animation(alien)
	alien.brain.reset_brain_state()
	alien.visible = false
	alien.z_index = 10  # Ensure actor renders above background
	add_child(alien)
	return alien

func _create_cargo_ship() -> Actor:
	var ship = Actor.new()
	ship.name = "CargoShip"
	ship.brain = BrainCargoShipScript.new()
	ship.brain.initialize(ship, self)
	ship.level = self
	ship.can_be_hit_by_missiles = false
	ship.must_be_destroyed = false
	_assign_sprite(ship, TEX_ROCKET, SIZE_ROCKET)
	_setup_cargo_ship_animation(ship)
	ship.brain.reset_brain_state()
	ship.visible = false
	add_child(ship)
	return ship

func _create_planet() -> Actor:
	var p = Actor.new()
	p.name = "Planet"
	p.brain = BrainPlanetScript.new()
	p.brain.initialize(p, self)
	p.level = self
	_assign_sprite(p, TEX_PLANET, SIZE_PLANET)
	_setup_planet_animation(p)
	p.brain.reset_brain_state()
	add_child(p)
	return p

func _create_xbonus() -> Actor:
	var x = Actor.new()
	x.name = "XBonus"
	x.brain = BrainXBonusScript.new()
	x.brain.initialize(x, self)
	x.level = self
	_assign_sprite(x, TEX_XBONUS, SIZE_XBONUS)
	_setup_xbonus_animation(x)
	x.brain.reset_brain_state()
	add_child(x)
	return x

func _create_cargo() -> Actor:
	var c = Actor.new()
	c.name = "Cargo"
	c.brain = BrainCargoScript.new()
	c.brain.initialize(c, self)
	c.level = self
	_assign_sprite(c, TEX_POWERUP, SIZE_CARGO)
	_setup_cargo_animation(c)
	add_child(c)
	return c

func update_level(delta: float) -> void:
	# Apply game speed multiplier to delta time
	var scaled_delta = delta * game_speed_multiplier
	ticks_passed = scaled_delta * 1000.0  # Convert to milliseconds
	_update_bonus(scaled_delta)
	
	# Update all actors  
	_update_actors(scaled_delta)
	
	# Remove deleted actors
	_cleanup_deleted_actors()
	
	# Check for collisions
	_check_collisions()
	
	# Check level completion
	_check_level_complete()

func _update_bonus(delta: float) -> void:
	bonus_ticks += delta * 1000.0
	if bonus_ticks > 500.0:
		bonus_ticks = 0.0
		bonus -= 10

func _update_actors(delta: float) -> void:
	# Update formation leader
	if formation_leader:
		formation_leader._process(delta)
	
	# Update player
	if player and not player.is_deleted:
		player._process(delta)
	
	# Update aliens
	for alien in aliens:
		if alien and not alien.is_deleted:
			alien._process(delta)
	_update_alien_f_loop_sound()
	
	# Apply special effects based on level
	if get_meta("breathing_enabled", false):
		_apply_breathing_effect(delta)
	elif wave_enabled:
		_apply_wave_effect(delta)
	
	# Update missiles
	for missile in missiles:
		if missile and not missile.is_deleted:
			missile._process(delta)
			if missile.is_off_screen:
				missile.is_deleted = true
	
	# Update bombs
	for bomb in bombs:
		if bomb and not bomb.is_deleted:
			bomb._process(delta)
			if bomb.is_off_screen:
				bomb.is_deleted = true
	
	# Update power-ups
	for powerup in powerups:
		if powerup and not powerup.is_deleted:
			powerup._process(delta)

	# Update cargo
	for c in cargo:
		if c and not c.is_deleted:
			c._process(delta)

	# Update planet and xbonus
	if planet and not planet.is_deleted:
		planet._process(delta)
	if xbonus and not xbonus.is_deleted:
		xbonus._process(delta)

	# Update cargo ships
	for ship in cargo_ships:
		if ship and not ship.is_deleted:
			ship._process(delta)
	
	# Update display bonuses
	_update_display_bonuses(delta)

func _update_alien_f_loop_sound() -> void:
	if not sound_manager:
		return
	if not sound_manager.sound_pools.has("ALIENF_LOOP") and not alienf_loop_attempted:
		alienf_loop_attempted = true
		sound_manager.load_sound("ALIENF_LOOP", ALIENF_LOOP_PATH, 1, true)
	var should_play = false
	for alien in aliens:
		if alien and not alien.is_deleted and alien.visible and alien.brain is BrainAlienF:
			should_play = true
			break
	if should_play:
		if not alienf_loop_playing:
			print("[AlienF] Loop sound start")
			sound_manager.play_loop_sound("ALIENF_LOOP")
			alienf_loop_playing = true
	else:
		if alienf_loop_playing:
			print("[AlienF] Loop sound stop")
			sound_manager.stop_loop_sound("ALIENF_LOOP")
			alienf_loop_playing = false

func _apply_wave_effect(delta: float) -> void:
	# Update wave time
	wave_time += delta
	
	# Calculate time-based amplitude oscillation
	# This makes the wave invert over the period
	var time_amplitude = sin(2.0 * PI * wave_time / wave_period)
	
	# Apply wave offset to all aliens
	for alien in aliens:
		if alien and not alien.is_deleted:
			# Skip aliens that are in attack mode (AlienC and AlienE)
			if _is_alien_attacking(alien):
				continue
			if _is_alien_exploding(alien):
				if alien_wave_offsets.has(alien):
					alien_wave_offsets.erase(alien)
				continue
			
			# Calculate new wave offset based on alien's X position
			# Center-anchored cosine with half the old horizontal wavelength:
			# center stays at peak while sides now move with larger vertical range
			var centered_x = alien.position.x - (play_width * 0.5)
			var x_phase = (3.0 * PI * centered_x) / play_width
			var new_offset = wave_amplitude * time_amplitude * cos(x_phase)
			var prev_offset = alien_wave_offsets.get(alien, 0.0)
			
			# For aliens with continuous movement patterns (radial, circular)
			# their position is recalculated each frame, so we just add the wave offset
			if alien.always_update_radial_position or alien.movement_type == Actor.MovementType.RADIAL:
				alien.position.y += new_offset
			else:
				# For static or relative position aliens, we need to track and remove
				# the previous wave offset to avoid accumulation
				alien.position.y -= prev_offset
				alien.position.y += new_offset
			alien_wave_offsets[alien] = new_offset

func _is_alien_attacking(alien: Actor) -> bool:
	# Check if alien is in attack state
	# Exclude from wave effect so attack animations are stable
	if not alien.brain:
		return false
	
	# Note: AlienB doesn't have state enum, handles explosions differently
	
	# Check AlienC
	if alien.brain is BrainAlienC:
		var brain_c = alien.brain as BrainAlienC
		return brain_c.state == BrainAlienC.State.ATTACKING
	
	# Check AlienD
	if alien.brain is BrainAlienD:
		return false
	
	# Check AlienE
	if alien.brain is BrainAlienE:
		var brain_e = alien.brain as BrainAlienE
		return brain_e.state == BrainAlienE.State.ATTACKING or brain_e.state == BrainAlienE.State.BOMBING

	# AlienF should not be affected by level wave motion
	if alien.brain and alien.brain.get_script() == BrainAlienFScript:
		return true
	
	return false

func _is_alien_exploding(alien: Actor) -> bool:
	# Check if alien is in exploding state
	if not alien.brain:
		return false

	if alien.brain is BrainAlienA:
		var brain_a = alien.brain as BrainAlienA
		return brain_a.state == BrainAlienA.State.EXPLODING

	if alien.brain is BrainAlienC:
		var brain_c = alien.brain as BrainAlienC
		return brain_c.state == BrainAlienC.State.EXPLODING

	if alien.brain is BrainAlienD:
		var brain_d = alien.brain as BrainAlienD
		return brain_d.state == BrainAlienD.State.EXPLODING

	if alien.brain is BrainAlienE:
		var brain_e = alien.brain as BrainAlienE
		return brain_e.state == BrainAlienE.State.EXPLODING

	return false

func _apply_breathing_effect(delta: float) -> void:
	# Only apply if breathing is enabled (Level 4)
	if not get_meta("breathing_enabled", false):
		return
	
	# Update breath time
	var breath_time = get_meta("breath_time", 0.0)
	breath_time += delta
	set_meta("breath_time", breath_time)
	
	# Get breathing parameters
	var breath_period = get_meta("breath_period", 4.0)
	
	# Calculate breathing phase (0 to 1 and back)
	# sin gives smooth oscillation: -1 to +1
	var breath_phase = sin(2.0 * PI * breath_time / breath_period)
	
	# Apply breathing to all aliens
	for alien in aliens:
		if alien and not alien.is_deleted and alien.leader != null:
			# Skip aliens in attack/exploding states
			if _is_alien_attacking(alien) or _is_alien_exploding(alien):
				continue
			
			# Get breathing metadata
			if not alien.has_meta("breath_home_offset"):
				continue
			
			var home_offset = alien.get_meta("breath_home_offset") as Vector2
			var breath_dir = alien.get_meta("breath_direction") as Vector2
			var breath_amp = alien.get_meta("breath_amplitude", 25.0)
			
			# Calculate breathing offset
			var breath_offset = breath_dir * breath_amp * breath_phase
			
			# Update relative position (home position + breathing offset)
			alien.relative_position = home_offset + breath_offset
			
			# The actor's update will handle converting relative position to world position

func _cleanup_deleted_actors() -> void:
	# Remove deleted actors
	for alien in aliens:
		if alien and alien.is_deleted and alien.must_be_destroyed:
			aliens_destroyed += 1
			alien.must_be_destroyed = false
		# Clean up wave offset tracking for deleted aliens
		if alien and alien.is_deleted and alien_wave_offsets.has(alien):
			alien_wave_offsets.erase(alien)
	if player and player.is_deleted and is_instance_valid(player):
		player.queue_free()
		player = null
	_free_deleted(aliens)
	_free_deleted(missiles)
	_free_deleted(bombs)
	_free_deleted(cargo)
	_free_deleted(powerups)
	_free_deleted(cargo_ships)
	if planet and planet.is_deleted and is_instance_valid(planet):
		planet.queue_free()
		planet = null
	if xbonus and xbonus.is_deleted and is_instance_valid(xbonus):
		xbonus.queue_free()
		xbonus = null

	aliens = aliens.filter(func(a): return a != null and not a.is_deleted)
	missiles = missiles.filter(func(m): return m != null and not m.is_deleted)
	bombs = bombs.filter(func(b): return b != null and not b.is_deleted)
	cargo = cargo.filter(func(c): return c != null and not c.is_deleted)
	powerups = powerups.filter(func(p): return p != null and not p.is_deleted)
	cargo_ships = cargo_ships.filter(func(s): return s != null and not s.is_deleted)

func _free_deleted(list: Array) -> void:
	for entry in list:
		var actor = entry as Actor
		if actor and actor.is_deleted and is_instance_valid(actor):
			actor.queue_free()

func _check_collisions() -> void:
	# Use spatial partitioning collision manager for optimized detection
	
	if not collision_manager:
		return
	
	# Filter out deleted aliens that can be hit
	var hittable_aliens = aliens.filter(func(a): 
		return a != null and not a.is_deleted and a.can_be_hit_by_missiles)
	
	# Check missile-alien collisions using spatial partitioning
	var missile_alien_collisions = collision_manager.check_collisions_for_actors(missiles, hittable_aliens)
	for collision_pair in missile_alien_collisions:
		var missile = collision_pair[0]
		var alien = collision_pair[1]
		
		if not missile.is_deleted and not alien.is_deleted:
			missile.is_deleted = true
			alien.set_meta("hit_position", alien.position)
			alien.was_hit_by_missile += 1
			# Only process first collision per missile
			break

	# Check missile-cargo ship collisions
	var hittable_ships = cargo_ships.filter(func(s):
		return s != null and not s.is_deleted and s.can_be_hit_by_missiles)
	var missile_ship_collisions = collision_manager.check_collisions_for_actors(missiles, hittable_ships)
	for collision_pair in missile_ship_collisions:
		var missile = collision_pair[0]
		var ship = collision_pair[1]
		if not missile.is_deleted and not ship.is_deleted:
			missile.is_deleted = true
			ship.set_meta("hit_position", ship.position)
			ship.was_hit_by_missile += 1
			break

	# Check missile-cargo collisions
	var hittable_cargo = cargo.filter(func(c):
		return c != null and not c.is_deleted and c.can_be_hit_by_missiles)
	var missile_cargo_collisions = collision_manager.check_collisions_for_actors(missiles, hittable_cargo)
	for collision_pair in missile_cargo_collisions:
		var missile = collision_pair[0]
		var c = collision_pair[1]
		if not missile.is_deleted and not c.is_deleted:
			missile.is_deleted = true
			c.set_meta("hit_position", c.position)
			c.was_hit_by_missile += 1
			break

	# Check missile-planet collisions
	if planet and not planet.is_deleted and planet.can_be_hit_by_missiles:
		var planet_collisions = collision_manager.check_collisions_for_actors(missiles, [planet])
		for collision_pair in planet_collisions:
			var missile = collision_pair[0]
			if not missile.is_deleted:
				missile.is_deleted = true
				planet.set_meta("hit_position", planet.position)
				planet.was_hit_by_missile += 1
				break

	# Check missile-xbonus collisions
	if xbonus and not xbonus.is_deleted and xbonus.can_be_hit_by_missiles:
		var xbonus_collisions = collision_manager.check_collisions_for_actors(missiles, [xbonus])
		for collision_pair in xbonus_collisions:
			var missile = collision_pair[0]
			if not missile.is_deleted:
				missile.is_deleted = true
				xbonus.set_meta("hit_position", xbonus.position)
				xbonus.was_hit_by_missile += 1
				break
	
	# Check bomb-player collisions
	if player and not player.is_deleted:
		var player_array = [player]
		var bomb_player_collisions = collision_manager.check_collisions_for_actors(bombs, player_array)
		for collision_pair in bomb_player_collisions:
			var bomb = collision_pair[0]
			
			if not bomb.is_deleted:
				bomb.is_deleted = true
				if not shields_on:
					player.set_meta("hit_position", player.position)
					player.was_hit_by_missile += 1
				else:
					# Hit shields - destroy bomb but not player
					play_sound("BOOM1")
				# Only process first collision
				break
	
	# Check alien-player collisions
	if player and not player.is_deleted:
		var player_array = [player]
		var alien_player_collisions = collision_manager.check_collisions_for_actors(aliens, player_array)
		for collision_pair in alien_player_collisions:
			var alien = collision_pair[0]
			
			if not alien.is_deleted and alien.can_hit_player:
				if not shields_on:
					player.was_hit_by_missile += 1
					alien.is_deleted = true  # Alien also destroyed
				else:
					# Hit shields - destroy alien but not player
					alien.is_deleted = true
					play_sound("BOOM2")
				# Only process first collision
				break
	
	# Check power-up collection by player
	if player and not player.is_deleted:
		var player_array = [player]
		var powerup_player_collisions = collision_manager.check_collisions_for_actors(powerups, player_array)
		for collision_pair in powerup_player_collisions:
			var powerup = collision_pair[0] as PowerUp
		
			if powerup and not powerup.is_deleted:
				powerup.is_deleted = true
				powerup.apply_to_level(self)
				play_sound("TYPE")
				# Show bonus
				_show_bonus(powerup.position, 0)  # Visual indicator
				break

	# Check cargo collection by player
	if player and not player.is_deleted:
		var player_array = [player]
		var cargo_player_collisions = collision_manager.check_collisions_for_actors(cargo, player_array)
		for collision_pair in cargo_player_collisions:
			var c = collision_pair[0]
			if c and not c.is_deleted and c.can_hit_player:
				c.hit_player = true
				break

func _check_level_complete() -> void:
	if aliens_destroyed >= num_aliens_must_be_destroyed:
		is_level_complete = true

func is_level_complete_state() -> bool:
	return is_level_complete

func is_player_dead_state() -> bool:
	return is_player_dead

func fire_player_missile(from_actor: Actor) -> bool:
	if not from_actor:
		return false

	if has_double_shots:
		if has_multi_shots:
			if not _can_spawn_missiles(2, -1):
				return false
			_spawn_player_missile(from_actor, -4.0)
			_spawn_player_missile(from_actor, 4.0)
			return true
		else:
			if not _can_spawn_missiles(2, 4):
				return false
			_spawn_player_missile(from_actor, -4.0)
			_spawn_player_missile(from_actor, 4.0)
			return true

	if has_multi_shots:
		if not _can_spawn_missiles(1, -1):
			return false
		_spawn_player_missile(from_actor, 0.0)
		return true

	if not _can_spawn_missiles(1, 2):
		return false
	_spawn_player_missile(from_actor, 0.0)
	return true

func _can_spawn_missiles(count: int, on_screen_limit: int) -> bool:
	var active_missiles = missiles.filter(func(m): return m != null and not m.is_deleted and not m.is_off_screen).size()
	if on_screen_limit >= 0 and (active_missiles + count) > on_screen_limit:
		return false
	if (active_missiles + count) > Constants.MAX_MISSILES:
		return false
	return true

func _spawn_player_missile(from_actor: Actor, x_offset: float) -> void:
	var missile = Actor.new()
	missile.name = "Missile"
	var bounds = from_actor.get_bounds()
	var start_pos = Vector2(from_actor.get_center().x + x_offset, bounds.position.y)
	missile.position = start_pos
	missile.velocity_direction = 270.0  # Straight up
	missile.velocity_magnitude = Constants.PLAYER_MISSILE_VELOCITY
	missile.level = self
	_assign_sprite(missile, TEX_MISSILE, SIZE_MISSILE)
	_setup_missile_animation(missile)
	add_child(missile)
	missiles.append(missile)

func drop_alien_bomb(from_actor: Actor) -> bool:
	# Check if we can drop bomb
	var max_bombs = Constants.MAX_ALIENA_BOMBS
	var bomb_speed = Constants.ABOMB_VELOCITY
	var is_d_bomb = false
	if from_actor and from_actor.brain is BrainAlienD:
		max_bombs = Constants.MAX_ALIEND_BOMBS
		bomb_speed = Constants.DBOMB_VELOCITY
		is_d_bomb = true
	if bombs.size() >= max_bombs:
		return false
	
	# Create bomb
	var bomb = Actor.new()
	bomb.name = "Bomb"
	bomb.position = from_actor.get_center()
	if from_actor and from_actor.brain is BrainAlienD and player:
		var target_dir = (player.position - bomb.position).normalized()
		bomb.velocity_direction = rad_to_deg(atan2(target_dir.y, target_dir.x))
	else:
		bomb.velocity_direction = 90.0  # Straight down
	bomb.velocity_magnitude = bomb_speed
	bomb.level = self
	if is_d_bomb:
		_assign_sprite(bomb, TEX_BOMB_D, SIZE_BOMB_D)
		_setup_dbomb_animation(bomb)
	else:
		_assign_sprite(bomb, TEX_BOMB_A, SIZE_BOMB_A)
		_setup_abomb_animation(bomb)
	add_child(bomb)
	bombs.append(bomb)
	
	return true

func fire_alien_f_laser(from_actor: Actor, target_position: Vector2) -> bool:
	if not from_actor:
		return false
	if bombs.size() >= Constants.MAX_ALIEND_BOMBS:
		return false

	var laser = Actor.new()
	laser.name = "Laser"
	laser.position = from_actor.get_center()
	var to_target = target_position - laser.position
	if to_target.length() < 0.001:
		to_target = Vector2(0, 1)
	laser.velocity_direction = rad_to_deg(atan2(to_target.y, to_target.x))
	laser.velocity_magnitude = max(Constants.DBOMB_VELOCITY * 1.2, 120.0)
	laser.level = self
	# Use D-bomb sprite for visual distinction
	_assign_sprite(laser, TEX_BOMB_D, SIZE_BOMB_D)
	_setup_dbomb_animation(laser)
	add_child(laser)
	bombs.append(laser)

	play_sound("LASER")
	return true


func spawn_alien_f_test() -> void:
	# Always create a new AlienF instance
	var new_alien_f = _create_alien_f()
	aliens.append(new_alien_f)
	
	# Force spawn immediately
	if new_alien_f.brain and new_alien_f.brain.has_method("force_spawn"):
		new_alien_f.brain.force_spawn()
	
	# Also track as the primary alien_f if there isn't one
	if not alien_f or alien_f.is_deleted:
		alien_f = new_alien_f

func get_player_position() -> Vector2:
	if player:
		return player.position
	return Vector2.ZERO

func get_player() -> Actor:
	return player

func get_shields_left() -> int:
	return shields_left

func set_shields_on(value: bool) -> void:
	shields_on = value

func is_shields_on() -> bool:
	return shields_on

func drain_shields(amount: float) -> void:
	shields_left -= int(amount)
	if shields_left < 0:
		shields_left = 0
		shields_on = false

func is_rapid_fire_enabled() -> bool:
	return has_rapid_fire

func add_score(points: int) -> void:
	if game:
		game.add_score(points)

func add_bonus(points: int, pos: Vector2) -> void:
	bonus += points
	var frame = _bonus_frame_for_points(points)
	if frame >= 0:
		_show_bonus(pos, frame)

func add_random_bonus(pos: Vector2) -> int:
	var frame = randi_range(0, 10)
	var points = _bonus_points_for_frame(frame)
	_add_bonus_with_frame(points, pos, frame)
	return points

func set_bonus_multiplier(value: int) -> void:
	bonus_multiplier = clampi(value, 1, 10)
	if game:
		game.score_multiplier = float(bonus_multiplier)

func on_player_death() -> void:
	if is_player_dead:
		return
	is_player_dead = true
	death_sequence_id += 1

func get_death_sequence_id() -> int:
	return death_sequence_id

func play_sound(sound_name: String) -> void:
	if sound_manager:
		sound_manager.play_sound(sound_name)

func _get_alien_score(alien: Actor) -> int:
	# Determine score based on alien brain type
	if alien.brain is BrainAlienA:
		return Constants.ALIENA_SCORE
	elif alien.brain is BrainAlienB:
		return Constants.ALIENB_SCORE
	elif alien.brain is BrainAlienC:
		return Constants.ALIENC_SCORE
	elif alien.brain is BrainAlienD:
		return Constants.ALIEND_SCORE
	elif alien.brain is BrainAlienE:
		return Constants.ALIENE_SCORE
	return 10  # Default

func _spawn_powerup(pos: Vector2) -> void:
	var powerup = PowerUp.new()
	powerup.position = pos
	powerup.power_up_type = PowerUp.create_random_powerup()
	powerup.value = randi_range(Constants.BONUS_MIN, Constants.BONUS_MAX)
	powerup.level = self
	_assign_sprite(powerup, TEX_POWERUP, SIZE_CARGO)
	_setup_cargo_animation(powerup)
	add_child(powerup)
	powerups.append(powerup)

func drop_cargo_ship(from_actor: Actor) -> void:
	if not from_actor:
		return
	var c = _create_cargo()
	c.position = from_actor.position
	var cargo_brain = c.brain
	if cargo_brain:
		cargo_brain.cargo_type = -1
		cargo_brain.reset_brain_state()
	cargo.append(c)

func _setup_player_animation(actor: Actor) -> void:
	var frame_defs = [
		{"start": 1, "end": 24, "offset": Vector2.ZERO, "size": Vector2(26, 18)}
	]
	var sequences = {
		"normal": {"start": 1, "count": 1, "loop": Constants.ANIM_LOOP_ONE_WAY, "ticks": 120},
		"shields": {"start": 5, "count": 4, "loop": Constants.ANIM_LOOP_ONE_WAY, "ticks": 120},
		"explode": {"start": 9, "count": 16, "loop": Constants.ANIM_LOOP_NONE, "ticks": 40}
	}
	actor.configure_animation(Vector2i(32, 18), 4, frame_defs, sequences, "normal")

func _setup_alien_a_animation(actor: Actor) -> void:
	var frame_defs = [
		{"start": 1, "end": 36, "offset": Vector2.ZERO, "size": Vector2(23, 8)}
	]
	var sequences = {
		"normal": {"start": 1, "count": 20, "loop": Constants.ANIM_LOOP_ONE_WAY, "ticks": 50},
		"explode": {"start": 21, "count": 16, "loop": Constants.ANIM_LOOP_NONE, "ticks": 10}
	}
	actor.configure_animation(Vector2i(32, 8), 4, frame_defs, sequences, "normal", true)

func _setup_alien_b_animation(actor: Actor) -> void:
	var frame_defs = [
		{"start": 1, "end": 64, "offset": Vector2.ZERO, "size": Vector2(16, 16)}
	]
	var sequences = {
		"normal_3legs": {"start": 1, "count": 8, "loop": Constants.ANIM_LOOP_ONE_WAY, "ticks": 80},
		"hit_3legs": {"start": 9, "count": 8, "loop": Constants.ANIM_LOOP_NONE, "ticks": 80},
		"normal_2legs": {"start": 17, "count": 8, "loop": Constants.ANIM_LOOP_ONE_WAY, "ticks": 80},
		"hit_2legs": {"start": 25, "count": 8, "loop": Constants.ANIM_LOOP_NONE, "ticks": 80},
		"normal_1leg": {"start": 33, "count": 8, "loop": Constants.ANIM_LOOP_ONE_WAY, "ticks": 80},
		"hit_1leg": {"start": 41, "count": 8, "loop": Constants.ANIM_LOOP_NONE, "ticks": 80},
		"normal_0legs": {"start": 49, "count": 8, "loop": Constants.ANIM_LOOP_ONE_WAY, "ticks": 80},
		"explode": {"start": 57, "count": 8, "loop": Constants.ANIM_LOOP_NONE, "ticks": 40}
	}
	actor.configure_animation(Vector2i(16, 16), 8, frame_defs, sequences, "normal_3legs", true)

func _setup_alien_c_animation(actor: Actor) -> void:
	var frame_defs = [
		{"start": 1, "end": 32, "offset": Vector2.ZERO, "size": Vector2(10, 16)}
	]
	var sequences = {
		"normal": {"start": 1, "count": 8, "loop": Constants.ANIM_LOOP_ONE_WAY, "ticks": 125},
		"attack_left": {"start": 9, "count": 8, "loop": Constants.ANIM_LOOP_ONE_WAY, "ticks": 125},
		"attack_right": {"start": 17, "count": 8, "loop": Constants.ANIM_LOOP_ONE_WAY, "ticks": 125},
		"explode": {"start": 25, "count": 8, "loop": Constants.ANIM_LOOP_NONE, "ticks": 40}
	}
	actor.configure_animation(Vector2i(16, 16), 8, frame_defs, sequences, "normal", true)

func _setup_alien_d_animation(actor: Actor) -> void:
	var frame_defs = [
		{"start": 1, "end": 28, "offset": Vector2.ZERO, "size": Vector2(20, 20)}
	]
	var sequences = {
		"normal": {"start": 1, "count": 20, "loop": Constants.ANIM_LOOP_ONE_WAY, "ticks": 25},
		"explode": {"start": 21, "count": 8, "loop": Constants.ANIM_LOOP_NONE, "ticks": 40}
	}
	actor.configure_animation(Vector2i(32, 24), 4, frame_defs, sequences, "normal", true)

func _setup_alien_e_animation(actor: Actor) -> void:
	var frame_defs = [
		{"start": 1, "end": 24, "offset": Vector2.ZERO, "size": Vector2(13, 8)},
		{"start": 25, "end": 64, "offset": Vector2.ZERO, "size": Vector2(14, 13)}
	]
	var sequences = {
		"formation": {"start": 1, "count": 8, "loop": Constants.ANIM_LOOP_ONE_WAY, "ticks": 75},
		"leave_formation": {"start": 9, "count": 8, "loop": Constants.ANIM_LOOP_NONE_REVERSE, "ticks": 75},
		"enter_formation": {"start": 9, "count": 8, "loop": Constants.ANIM_LOOP_NONE, "ticks": 75},
		"formation_explode": {"start": 17, "count": 8, "loop": Constants.ANIM_LOOP_NONE, "ticks": 40},
		"attack_left": {"start": 25, "count": 8, "loop": Constants.ANIM_LOOP_ONE_WAY, "ticks": 75},
		"attack_right": {"start": 33, "count": 8, "loop": Constants.ANIM_LOOP_ONE_WAY, "ticks": 75},
		"turn_right": {"start": 41, "count": 4, "loop": Constants.ANIM_LOOP_NONE, "ticks": 75},
		"turn_left": {"start": 45, "count": 4, "loop": Constants.ANIM_LOOP_NONE, "ticks": 75},
		"attack_left_explode": {"start": 49, "count": 8, "loop": Constants.ANIM_LOOP_NONE, "ticks": 40},
		"attack_right_explode": {"start": 57, "count": 8, "loop": Constants.ANIM_LOOP_NONE, "ticks": 40}
	}
	actor.configure_animation(Vector2i(16, 16), 8, frame_defs, sequences, "formation", true)

func _setup_alien_f_animation(actor: Actor) -> void:
	var frame_defs = [
		{"start": 1, "end": 40, "offset": Vector2.ZERO, "size": Vector2(16, 14)}
	]
	var sequences = {
		"normal": {"start": 1, "count": 8, "loop": Constants.ANIM_LOOP_ONE_WAY, "ticks": 80},
		"hot_set2": {"start": 9, "count": 8, "loop": Constants.ANIM_LOOP_NONE, "ticks": 70},
		"hot_set3": {"start": 17, "count": 8, "loop": Constants.ANIM_LOOP_NONE, "ticks": 70},
		"explode": {"start": 25, "count": 16, "loop": Constants.ANIM_LOOP_NONE, "ticks": 40}
	}
	actor.configure_animation(Vector2i(16, 16), 8, frame_defs, sequences, "normal", true)

func _setup_missile_animation(actor: Actor) -> void:
	var frame_defs = [
		{"start": 1, "end": 1, "offset": Vector2.ZERO, "size": Vector2(2, 8)}
	]
	var sequences = {
		"normal": {"start": 1, "count": 1, "loop": Constants.ANIM_LOOP_ONE_WAY, "ticks": 40}
	}
	actor.configure_animation(Vector2i(2, 16), 1, frame_defs, sequences, "normal")

func _setup_abomb_animation(actor: Actor) -> void:
	var frame_defs = [
		{"start": 1, "end": 1, "offset": Vector2.ZERO, "size": Vector2(2, 8)}
	]
	var sequences = {
		"normal": {"start": 1, "count": 1, "loop": Constants.ANIM_LOOP_ONE_WAY, "ticks": 40}
	}
	actor.configure_animation(Vector2i(2, 8), 1, frame_defs, sequences, "normal")

func _setup_dbomb_animation(actor: Actor) -> void:
	var frame_defs = [
		{"start": 1, "end": 20, "offset": Vector2.ZERO, "size": Vector2(5, 5)}
	]
	var sequences = {
		"normal": {"start": 1, "count": 20, "loop": Constants.ANIM_LOOP_ONE_WAY, "ticks": 40}
	}
	actor.configure_animation(Vector2i(6, 6), 4, frame_defs, sequences, "normal")

func _setup_cargo_animation(actor: Actor) -> void:
	var frame_defs = [
		{"start": 1, "end": 32, "offset": Vector2.ZERO, "size": Vector2(11, 7)}
	]
	var sequences = {
		"orange": {"start": 1, "count": 1, "loop": Constants.ANIM_LOOP_ONE_WAY, "ticks": 40},
		"pink": {"start": 2, "count": 1, "loop": Constants.ANIM_LOOP_ONE_WAY, "ticks": 40},
		"yellow": {"start": 3, "count": 1, "loop": Constants.ANIM_LOOP_ONE_WAY, "ticks": 40},
		"blue": {"start": 4, "count": 1, "loop": Constants.ANIM_LOOP_ONE_WAY, "ticks": 40},
		"green": {"start": 5, "count": 1, "loop": Constants.ANIM_LOOP_ONE_WAY, "ticks": 40},
		"purple": {"start": 6, "count": 1, "loop": Constants.ANIM_LOOP_ONE_WAY, "ticks": 40},
		"red": {"start": 7, "count": 1, "loop": Constants.ANIM_LOOP_ONE_WAY, "ticks": 40},
		"navy": {"start": 8, "count": 1, "loop": Constants.ANIM_LOOP_ONE_WAY, "ticks": 40},
		"reddot": {"start": 9, "count": 4, "loop": Constants.ANIM_LOOP_ONE_WAY, "ticks": 80},
		"greendot": {"start": 13, "count": 4, "loop": Constants.ANIM_LOOP_ONE_WAY, "ticks": 80},
		"bluedot": {"start": 17, "count": 4, "loop": Constants.ANIM_LOOP_ONE_WAY, "ticks": 80},
		"pinkdot": {"start": 21, "count": 4, "loop": Constants.ANIM_LOOP_ONE_WAY, "ticks": 80},
		"yellowdot": {"start": 25, "count": 4, "loop": Constants.ANIM_LOOP_ONE_WAY, "ticks": 80},
		"colordot": {"start": 29, "count": 4, "loop": Constants.ANIM_LOOP_ONE_WAY, "ticks": 40}
	}
	actor.configure_animation(Vector2i(16, 8), 4, frame_defs, sequences, "orange")

func _setup_cargo_ship_animation(actor: Actor) -> void:
	var frame_defs = [
		{"start": 1, "end": 48, "offset": Vector2.ZERO, "size": Vector2(32, 12)}
	]
	var sequences = {
		"go_left": {"start": 1, "count": 16, "loop": Constants.ANIM_LOOP_ONE_WAY, "ticks": 40},
		"explode_left": {"start": 17, "count": 8, "loop": Constants.ANIM_LOOP_NONE, "ticks": 10},
		"go_right": {"start": 25, "count": 16, "loop": Constants.ANIM_LOOP_ONE_WAY, "ticks": 40},
		"explode_right": {"start": 41, "count": 8, "loop": Constants.ANIM_LOOP_NONE, "ticks": 10}
	}
	actor.configure_animation(Vector2i(32, 12), 4, frame_defs, sequences, "go_left")

func _setup_planet_animation(actor: Actor) -> void:
	var frame_defs = [
		{"start": 1, "end": 28, "offset": Vector2.ZERO, "size": Vector2(24, 12)}
	]
	var sequences = {
		"entering": {"start": 1, "count": 4, "loop": Constants.ANIM_LOOP_NONE, "ticks": 80},
		"normal": {"start": 5, "count": 19, "loop": Constants.ANIM_LOOP_ONE_WAY, "ticks": 80},
		"leaving": {"start": 25, "count": 4, "loop": Constants.ANIM_LOOP_NONE, "ticks": 80}
	}
	actor.configure_animation(Vector2i(24, 12), 4, frame_defs, sequences, "normal")

func _setup_xbonus_animation(actor: Actor) -> void:
	var frame_defs = [
		{"start": 1, "end": 4, "offset": Vector2.ZERO, "size": Vector2(12, 12)}
	]
	var sequences = {
		"2xbonus": {"start": 1, "count": 1, "loop": Constants.ANIM_LOOP_ONE_WAY, "ticks": 80},
		"3xbonus": {"start": 2, "count": 1, "loop": Constants.ANIM_LOOP_ONE_WAY, "ticks": 80},
		"4xbonus": {"start": 3, "count": 1, "loop": Constants.ANIM_LOOP_ONE_WAY, "ticks": 80},
		"5xbonus": {"start": 4, "count": 1, "loop": Constants.ANIM_LOOP_ONE_WAY, "ticks": 80}
	}
	actor.configure_animation(Vector2i(12, 12), 4, frame_defs, sequences, "2xbonus")

func _add_bonus_with_frame(points: int, pos: Vector2, frame: int) -> void:
	bonus += points
	_show_bonus(pos, frame)

func _show_bonus(pos: Vector2, frame: int) -> void:
	var clamped_x = clampf(pos.x, 0.0, play_width - BONUS_FRAME_W)
	var clamped_y = clampf(pos.y, play_y_offset, play_y_offset + play_height - BONUS_FRAME_H)
	var sprite = Sprite2D.new()
	sprite.texture = TEX_BONUSES
	sprite.centered = false
	sprite.region_enabled = true
	var col = frame % 2
	var row = int(frame / 2.0)
	sprite.region_rect = Rect2(col * BONUS_FRAME_W, row * BONUS_FRAME_H, BONUS_FRAME_W, BONUS_FRAME_H)
	sprite.position = Vector2(clamped_x, clamped_y)
	add_child(sprite)
	var bonus_entry = {
		"sprite": sprite,
		"time": 0.0,
		"lifetime": 1.5
	}
	display_bonuses.append(bonus_entry)

func _update_display_bonuses(delta: float) -> void:
	var to_remove = []
	for i in range(display_bonuses.size()):
		var entry = display_bonuses[i]
		entry["time"] += delta
		if entry["time"] >= entry["lifetime"]:
			to_remove.append(i)
			display_bonuses[i] = entry

	for i in range(to_remove.size() - 1, -1, -1):
		var entry = display_bonuses[to_remove[i]]
		if entry.has("sprite"):
			var sprite = entry["sprite"] as Sprite2D
			if sprite and is_instance_valid(sprite):
				sprite.queue_free()
		display_bonuses.remove_at(to_remove[i])

func _bonus_points_for_frame(frame: int) -> int:
	match frame:
		10:
			return 25
		11:
			return 50
		12:
			return 75
		13:
			return 100
		_:
			if frame >= 0 and frame <= 9:
				return (frame + 1) * 100
	return 0

func _bonus_frame_for_points(points: int) -> int:
	match points:
		25:
			return 10
		50:
			return 11
		75:
			return 12
		100:
			return 13
		200:
			return 1
		300:
			return 2
		400:
			return 3
		500:
			return 4
		600:
			return 5
		700:
			return 6
		800:
			return 7
		900:
			return 8
		1000:
			return 9
		_:
			return 0 if points == 100 else -1
