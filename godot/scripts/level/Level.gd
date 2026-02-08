# Level.gd
# Level manager - handles spawning, updating, and managing all actors
# Port from vb6/Level.cls

extends Node2D

class_name Level

# Game reference
var game: Game = null

# Player
var player: Actor = null

# Actor arrays
var aliens: Array[Actor] = []
var missiles: Array[Actor] = []
var bombs: Array[Actor] = []
var cargo: Array[Actor] = []

# Level state
var level_number: int = 1
var is_level_complete: bool = false
var is_player_dead: bool = false
var num_aliens_must_be_destroyed: int = 0
var aliens_destroyed: int = 0

# Play area dimensions
var play_width: float = GameConstants.SCREEN_WIDTH
var play_height: float = GameConstants.PLAY_HEIGHT
var play_x_offset: float = 0.0
var play_y_offset: float = GameConstants.TOP_BORDER

# Timing
var ticks_passed: float = 0.0

# Shields
var shields_left: int = GameConstants.STARTING_SHIELDS_TICKS
var shields_on: bool = false

# Power-ups
var has_double_shots: bool = false
var has_rapid_fire: bool = false
var has_multi_shots: bool = false

# Score and bonus
var score: int = 0
var bonus: int = 0

# Formation leader (for alien formations)
var formation_leader: Actor = null

# Collision manager
var collision_manager: CollisionManager = null

func _ready():
	# Initialize collision manager
	collision_manager = CollisionManager.new()
	collision_manager.play_width = play_width
	collision_manager.play_height = play_height
	collision_manager._initialize_grid()
	add_child(collision_manager)

func initialize_level(p_level_number: int, p_game: Game) -> void:
	level_number = p_level_number
	game = p_game
	
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
	
	if player and is_instance_valid(player):
		player.queue_free()
		player = null
	
	if formation_leader and is_instance_valid(formation_leader):
		formation_leader.queue_free()
		formation_leader = null

func _load_level_1() -> void:
	# Create formation leader (invisible, drives formation movement)
	formation_leader = Actor.new()
	formation_leader.movement_type = Actor.MovementType.MARCHING
	formation_leader.velocity_magnitude = 30.0
	formation_leader.velocity_direction = 0.0  # Moving right
	formation_leader.position = Vector2(0, 100)
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
		var alien = _create_alien_a(pos)
		aliens.append(alien)
	
	# Create AlienB formation (6 aliens - decorative tanks)
	var alien_b_positions = [
		Vector2(40, 144), Vector2(57, 144), Vector2(74, 144),
		Vector2(118, 144), Vector2(135, 144), Vector2(152, 144)
	]
	
	for pos in alien_b_positions:
		var alien = _create_alien_b(pos)
		aliens.append(alien)
	
	# Create AlienC (2 aggressive attackers)
	var alien = _create_alien_c(Vector2(91, 125))
	aliens.append(alien)
	alien = _create_alien_c(Vector2(112, 125))
	aliens.append(alien)
	
	# Create AlienD (2 orbital bombers)
	alien = _create_alien_d(Vector2(5, 40))
	aliens.append(alien)
	alien = _create_alien_d(Vector2(190, 40))
	aliens.append(alien)
	
	# Create AlienE (4 advanced enemies)
	alien = _create_alien_e(Vector2(20, 70))
	aliens.append(alien)
	alien = _create_alien_e(Vector2(170, 70))
	aliens.append(alien)
	alien = _create_alien_e(Vector2(20, 90))
	aliens.append(alien)
	alien = _create_alien_e(Vector2(170, 90))
	aliens.append(alien)
	
	# Set aliens that must be destroyed
	num_aliens_must_be_destroyed = 15 + 2 + 2 + 4  # A + C + D + E
	aliens_destroyed = 0

func _load_level_2() -> void:
	# Similar to level 1 but with different formations
	# TODO: Implement level 2 specific layout
	_load_level_1()  # Placeholder

func _load_level_3() -> void:
	# Similar to level 1 but with different formations
	# TODO: Implement level 3 specific layout
	_load_level_1()  # Placeholder

func _create_player() -> Actor:
	var p = Actor.new()
	p.position = Vector2(play_width / 2, play_height - 50)
	p.brain = BrainPlayer.new()
	p.brain.initialize(p, self)
	p.level = self
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
	add_child(alien)
	return alien

func update_level(delta: float) -> void:
	ticks_passed = delta * 1000.0  # Convert to milliseconds
	
	# Update all actors
	_update_actors(delta)
	
	# Remove deleted actors
	_cleanup_deleted_actors()
	
	# Check for collisions
	_check_collisions()
	
	# Check level completion
	_check_level_complete()

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
	
	# Update bombs
	for bomb in bombs:
		if bomb and not bomb.is_deleted:
			bomb._process(delta)

func _cleanup_deleted_actors() -> void:
	# Remove deleted actors
	aliens = aliens.filter(func(a): return a != null and not a.is_deleted)
	missiles = missiles.filter(func(m): return m != null and not m.is_deleted)
	bombs = bombs.filter(func(b): return b != null and not b.is_deleted)
	cargo = cargo.filter(func(c): return c != null and not c.is_deleted)

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
			alien.was_hit_by_missile = true
			if alien.must_be_destroyed:
				aliens_destroyed += 1
			# Only process first collision per missile
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
					player.was_hit_by_missile = true
					on_player_death()
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
					player.was_hit_by_missile = true
					on_player_death()
					alien.is_deleted = true  # Alien also destroyed
				else:
					# Hit shields - destroy alien but not player
					alien.is_deleted = true
					play_sound("BOOM2")
				# Only process first collision
				break

func _check_level_complete() -> void:
	if aliens_destroyed >= num_aliens_must_be_destroyed:
		is_level_complete = true

func is_level_complete() -> bool:
	return is_level_complete

func fire_player_missile(from_actor: Actor) -> bool:
	# Check if we can fire (max missiles)
	if missiles.size() >= GameConstants.MAX_MISSILES:
		return false
	
	# Create missile
	var missile = Actor.new()
	missile.position = from_actor.get_center()
	missile.velocity_direction = 270.0  # Straight up
	missile.velocity_magnitude = GameConstants.PLAYER_MISSILE_VELOCITY
	missile.level = self
	add_child(missile)
	missiles.append(missile)
	
	return true

func drop_alien_bomb(from_actor: Actor) -> bool:
	# Check if we can drop bomb
	if bombs.size() >= GameConstants.MAX_ALIENA_BOMBS:
		return false
	
	# Create bomb
	var bomb = Actor.new()
	bomb.position = from_actor.get_center()
	bomb.velocity_direction = 90.0  # Straight down
	bomb.velocity_magnitude = 200.0  # Bomb speed
	bomb.level = self
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

func has_rapid_fire() -> bool:
	return has_rapid_fire

func add_score(points: int) -> void:
	if game:
		game.add_score(points)

func on_player_death() -> void:
	is_player_dead = true
	if game:
		game.lose_life()

func play_sound(sound_name: String) -> void:
	# TODO: Implement sound playback
	pass
