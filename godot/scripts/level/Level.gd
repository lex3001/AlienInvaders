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

# Visual bonuses (floating score text)
var display_bonuses: Array[Dictionary] = []

# Level state
var level_number: int = 1
var is_level_complete: bool = false
var is_player_dead: bool = false
var num_aliens_must_be_destroyed: int = 0
var aliens_destroyed: int = 0

# Play area dimensions
var play_width: float = Constants.SCREEN_WIDTH
var play_height: float = Constants.PLAY_HEIGHT
var play_x_offset: float = 0.0
var play_y_offset: float = Constants.TOP_BORDER

# Timing
var ticks_passed: float = 0.0

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

# Collision manager
var collision_manager: CollisionManager = null

# Sound manager
var sound_manager: SoundManager = null

# Sprite textures
const TEX_PLAYER = preload("res://assets/sprites/Ship.bmp")
const TEX_ALIEN_A = preload("res://assets/sprites/AlienA.bmp")
const TEX_ALIEN_B = preload("res://assets/sprites/AlienB.bmp")
const TEX_ALIEN_C = preload("res://assets/sprites/AlienC.bmp")
const TEX_ALIEN_D = preload("res://assets/sprites/AlienD.bmp")
const TEX_ALIEN_E = preload("res://assets/sprites/AlienE2.bmp")
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
const SIZE_PLAYER = Vector2i(26, 18)
const SIZE_ALIEN_A = Vector2i(23, 8)
const SIZE_ALIEN_B = Vector2i(16, 16)
const SIZE_ALIEN_C = Vector2i(10, 16)
const SIZE_ALIEN_D = Vector2i(20, 20)
const SIZE_ALIEN_E = Vector2i(13, 8)
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
	collision_manager._initialize_grid()
	add_child(collision_manager)
	
	# Initialize sound manager
	sound_manager = SoundManager.new()
	add_child(sound_manager)
	sound_manager.load_all_game_sounds()

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
		_:
			push_warning("Unknown level number: " + str(level_number))
			_load_level_1()


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
	formation_leader.movement_type = Actor.MovementType.MARCHING
	formation_leader.velocity_magnitude = 30.0
	formation_leader.velocity_direction = 0.0  # Moving right
	formation_leader.marching_distance = play_width - 240.0
	formation_leader.position = Vector2(0, 0)
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
	
	# Set aliens that must be destroyed
	num_aliens_must_be_destroyed = 15 + 2 + 2 + 4  # A + C + D + E
	aliens_destroyed = 0

func _load_level_2() -> void:
	# Create player
	player = _create_player()

	# AlienA formation (20)
	for i in range(20):
		var x_pos: float
		var y_pos: float
		if i < 10:
			x_pos = 85.0 + float(i) * 15.0
			y_pos = 300.0 - 100.0 * sin(deg_to_rad(float(i) * 10.0))
		else:
			var idx = i - 10
			x_pos = 555.0 - float(idx) * 15.0
			y_pos = 300.0 - 100.0 * sin(deg_to_rad(float(idx) * 10.0))
		var alien_a = _create_alien_a(Vector2.ZERO)
		alien_a.set_movement_normal(Vector2(x_pos, y_pos), 0.0, 0.0)
		aliens.append(alien_a)

	# AlienB formation (9)
	for i in range(9):
		var x_b = 320.0 - (float(9 - 1) * 18.0 / 2.0) + float(i) * 18.0
		var alien_b = _create_alien_b(Vector2.ZERO)
		alien_b.set_movement_normal(Vector2(x_b, 200.0), 0.0, 0.0)
		aliens.append(alien_b)

	# AlienC (2)
	var alien = _create_alien_c(Vector2.ZERO)
	alien.set_movement_normal(Vector2(110.0, 210.0), 0.0, 0.0)
	aliens.append(alien)
	alien = _create_alien_c(Vector2.ZERO)
	alien.set_movement_normal(Vector2(530.0, 210.0), 0.0, 0.0)
	aliens.append(alien)

	# AlienD (2) radial points
	var d_points = _create_radial_points(65.0, 20.0, 320.0, 150.0)
	for i in range(2):
		alien = _create_alien_d(Vector2.ZERO)
		alien.set_movement_radial_points(d_points, 4000.0, float(i) * 180.0)
		aliens.append(alien)

	# AlienE (6) radial points
	var e_points_left = _create_radial_points(20.0, 20.0, 110.0, 210.0)
	var e_points_right = _create_radial_points(20.0, 20.0, 530.0, 210.0)
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

	num_aliens_must_be_destroyed = 20 + 2 + 2 + 6
	aliens_destroyed = 0

func _load_level_3() -> void:
	# Create player
	player = _create_player()

	# AlienA set 1 (14) radial points
	var a_points1 = _create_radial_points(65.0, 65.0, 320.0, 150.0)
	for i in range(14):
		var alien_a1 = _create_alien_a(Vector2.ZERO)
		alien_a1.set_movement_radial_points(a_points1, -10000.0, float(i) * (360.0 / 14.0))
		aliens.append(alien_a1)

	# AlienA set 2 (10) radial points
	var a_points2 = _create_radial_points(40.0, 40.0, 320.0, 150.0)
	for i in range(10):
		var alien_a2 = _create_alien_a(Vector2.ZERO)
		alien_a2.set_movement_radial_points(a_points2, 8000.0, float(i) * (360.0 / 10.0))
		aliens.append(alien_a2)

	# AlienB (14) radial points
	var b_points_left = _create_radial_points(25.0, 25.0, 180.0, 200.0)
	var b_points_right = _create_radial_points(25.0, 25.0, 460.0, 200.0)
	var b_degrees = [0.0, 51.0, 103.0, 154.0, 206.0, 257.0, 309.0]
	for i in range(14):
		var alien_b = _create_alien_b(Vector2.ZERO)
		if i < 7:
			alien_b.set_movement_radial_points(b_points_left, 4000.0, b_degrees[i])
		else:
			alien_b.set_movement_radial_points(b_points_right, -4000.0, b_degrees[i - 7])
		aliens.append(alien_b)

	# AlienC (2) radial points
	var c_points = _create_radial_points(10.0, 10.0, 320.0, 150.0)
	for i in range(2):
		var alien_c = _create_alien_c(Vector2.ZERO)
		alien_c.set_movement_radial_points(c_points, 3000.0, float(i) * 180.0)
		aliens.append(alien_c)

	# AlienD (2) normal positions
	var alien_d = _create_alien_d(Vector2.ZERO)
	alien_d.set_movement_normal(Vector2(180.0, 200.0), 0.0, 0.0)
	aliens.append(alien_d)
	alien_d = _create_alien_d(Vector2.ZERO)
	alien_d.set_movement_normal(Vector2(460.0, 200.0), 0.0, 0.0)
	aliens.append(alien_d)

	# AlienE (4) radial points
	var e_points = _create_radial_points(20.0, 20.0, 320.0, 150.0)
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

	num_aliens_must_be_destroyed = 14 + 10 + 2 + 2 + 4
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

func _create_player() -> Actor:
	var p = Actor.new()
	var player_size = Vector2(SIZE_PLAYER.x, SIZE_PLAYER.y)
	p.position = Vector2(play_width / 2, play_height - (player_size.y / 2.0) - 16.0)
	p.brain = BrainPlayer.new()
	p.brain.initialize(p, self)
	p.level = self
	_assign_sprite(p, TEX_PLAYER, SIZE_PLAYER)
	_setup_player_animation(p)
	add_child(p)
	return p

func _create_alien_a(relative_pos: Vector2) -> Actor:
	var alien = Actor.new()
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

func _create_cargo_ship() -> Actor:
	var ship = Actor.new()
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
	c.brain = BrainCargoScript.new()
	c.brain.initialize(c, self)
	c.level = self
	_assign_sprite(c, TEX_POWERUP, SIZE_CARGO)
	_setup_cargo_animation(c)
	add_child(c)
	return c

func update_level(delta: float) -> void:
	ticks_passed = delta * 1000.0  # Convert to milliseconds
	_update_bonus(delta)
	
	# Update all actors
	_update_actors(delta)
	
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

func _cleanup_deleted_actors() -> void:
	# Remove deleted actors
	for alien in aliens:
		if alien and alien.is_deleted and alien.must_be_destroyed:
			aliens_destroyed += 1
			alien.must_be_destroyed = false
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
			c.was_hit_by_missile += 1
			break

	# Check missile-planet collisions
	if planet and not planet.is_deleted and planet.can_be_hit_by_missiles:
		var planet_collisions = collision_manager.check_collisions_for_actors(missiles, [planet])
		for collision_pair in planet_collisions:
			var missile = collision_pair[0]
			if not missile.is_deleted:
				missile.is_deleted = true
				planet.was_hit_by_missile += 1
				break

	# Check missile-xbonus collisions
	if xbonus and not xbonus.is_deleted and xbonus.can_be_hit_by_missiles:
		var xbonus_collisions = collision_manager.check_collisions_for_actors(missiles, [xbonus])
		for collision_pair in xbonus_collisions:
			var missile = collision_pair[0]
			if not missile.is_deleted:
				missile.is_deleted = true
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

func get_player_position() -> Vector2:
	if player:
		return player.position
	return Vector2.ZERO

func get_shields_left() -> int:
	return shields_left

func set_shields_on(value: bool) -> void:
	shields_on = value

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
	var clamped_y = clampf(pos.y, 0.0, play_height - BONUS_FRAME_H)
	var sprite = Sprite2D.new()
	sprite.texture = TEX_BONUSES
	sprite.centered = false
	sprite.region_enabled = true
	var col = frame % 2
	var row = int(frame / 2)
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
