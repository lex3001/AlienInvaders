# CollisionManager.gd
# Spatial partitioning collision detection system
# Port from vb6/PlayQuadrantManager.cls
# Uses quadrant-based optimization to reduce collision checks from O(n*m) to O(n*m/k)

extends Node

class_name CollisionManager

# Quadrant grid
var grid_width: int = 8
var grid_height: int = 6
var quadrant_width: float
var quadrant_height: float
var quadrants: Array = []

# Play area dimensions
var play_width: float = Constants.SCREEN_WIDTH
var play_height: float = Constants.PLAY_HEIGHT

func _ready():
	_initialize_grid()

func _initialize_grid() -> void:
	quadrant_width = play_width / float(grid_width)
	quadrant_height = play_height / float(grid_height)
	
	# Create quadrant grid
	quadrants.clear()
	for y in range(grid_height):
		for x in range(grid_width):
			quadrants.append({
				"actors": []
			})

func clear_all_quadrants() -> void:
	for quadrant in quadrants:
		quadrant["actors"].clear()

func add_actor_to_quadrants(actor: Actor) -> void:
	if not actor:
		return
	
	var bounds = actor.get_bounds()
	
	# Calculate which quadrants this actor overlaps
	var min_x = int(bounds.position.x / quadrant_width)
	var max_x = int((bounds.position.x + bounds.size.x) / quadrant_width)
	var min_y = int(bounds.position.y / quadrant_height)
	var max_y = int((bounds.position.y + bounds.size.y) / quadrant_height)
	
	# Clamp to grid bounds
	min_x = clampi(min_x, 0, grid_width - 1)
	max_x = clampi(max_x, 0, grid_width - 1)
	min_y = clampi(min_y, 0, grid_height - 1)
	max_y = clampi(max_y, 0, grid_height - 1)
	
	# Add actor to all overlapping quadrants
	for y in range(min_y, max_y + 1):
		for x in range(min_x, max_x + 1):
			var index = y * grid_width + x
			if index >= 0 and index < quadrants.size():
				quadrants[index]["actors"].append(actor)

func get_nearby_actors(actor: Actor) -> Array[Actor]:
	if not actor:
		return []
	
	var nearby: Array[Actor] = []
	var bounds = actor.get_bounds()
	
	# Calculate which quadrants this actor overlaps
	var min_x = int(bounds.position.x / quadrant_width)
	var max_x = int((bounds.position.x + bounds.size.x) / quadrant_width)
	var min_y = int(bounds.position.y / quadrant_height)
	var max_y = int((bounds.position.y + bounds.size.y) / quadrant_height)
	
	# Clamp to grid bounds
	min_x = clampi(min_x, 0, grid_width - 1)
	max_x = clampi(max_x, 0, grid_width - 1)
	min_y = clampi(min_y, 0, grid_height - 1)
	max_y = clampi(max_y, 0, grid_height - 1)
	
	# Collect all actors from overlapping quadrants
	for y in range(min_y, max_y + 1):
		for x in range(min_x, max_x + 1):
			var index = y * grid_width + x
			if index >= 0 and index < quadrants.size():
				for other in quadrants[index]["actors"]:
					if other != actor and other not in nearby:
						nearby.append(other)
	
	return nearby

func check_collision(actor1: Actor, actor2: Actor) -> bool:
	if not actor1 or not actor2:
		return false
	
	var bounds1 = actor1.get_bounds()
	var bounds2 = actor2.get_bounds()
	
	return bounds1.intersects(bounds2)

func check_collisions_for_actors(group1: Array, group2: Array) -> Array:
	# Returns array of collision pairs: [[actor1, actor2], ...]
	var collisions = []
	
	# Clear and rebuild quadrant grid
	clear_all_quadrants()
	
	# Add all actors from group2 to quadrants
	for entry in group2:
		var actor = entry as Actor
		if actor and not actor.is_deleted:
			add_actor_to_quadrants(actor)
	
	# Check each actor in group1 against nearby actors in group2
	for entry1 in group1:
		var actor1 = entry1 as Actor
		if actor1 and not actor1.is_deleted:
			var nearby = get_nearby_actors(actor1)
			for actor2 in nearby:
				if actor2 and not actor2.is_deleted:
					if check_collision(actor1, actor2):
						collisions.append([actor1, actor2])
	
	return collisions
