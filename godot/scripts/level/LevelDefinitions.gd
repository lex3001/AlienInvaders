# LevelDefinitions.gd
# Level data and configurations for all three levels
# Port from vb6/LevelDefinitions.bas

extends Node

class_name LevelDefinitions

# Level 1 - Basic Formation
static func get_level_1_data() -> Dictionary:
	return {
		"name": "Level 1 - The Beginning",
		"aliens_a_count": Constants.LEVEL1_ALIENSA,
		"aliens_b_count": Constants.LEVEL1_ALIENSB,
		"aliens_c_count": Constants.LEVEL1_ALIENSC,
		"aliens_d_count": Constants.LEVEL1_ALIENSD,
		"aliens_e_count": Constants.LEVEL1_ALIENSE,
		"formation_speed": 30.0,
		"formation_march_distance": 400,
		"alien_a_positions": [
			Vector2(1.5, 182), Vector2(14.5, 194), Vector2(27.5, 182),
			Vector2(40.5, 194), Vector2(53.5, 182), Vector2(66.5, 194),
			Vector2(79.5, 182), Vector2(92.5, 194), Vector2(105.5, 182),
			Vector2(118.5, 194), Vector2(131.5, 182), Vector2(144.5, 194),
			Vector2(157.5, 182), Vector2(170.5, 194), Vector2(183.5, 182),
			Vector2(196.5, 194), Vector2(209.5, 182), Vector2(222.5, 194),
			Vector2(235.5, 182), Vector2(248.5, 194)
		],
		"alien_b_positions": [
			Vector2(40, 144), Vector2(57, 144), Vector2(74, 144),
			Vector2(118, 144), Vector2(135, 144), Vector2(152, 144),
			Vector2(169, 144), Vector2(186, 144), Vector2(203, 144)
		],
		"alien_c_positions": [
			Vector2(91, 125), Vector2(112, 125)
		],
		"alien_d_positions": [
			Vector2(5, 40), Vector2(190, 40)
		],
		"alien_e_positions": [
			Vector2(20, 70), Vector2(170, 70),
			Vector2(20, 90), Vector2(170, 90),
			Vector2(70, 50), Vector2(140, 50)
		]
	}

# Level 2 - Advanced Formation
static func get_level_2_data() -> Dictionary:
	return {
		"name": "Level 2 - Rising Challenge",
		"aliens_a_count": Constants.LEVEL2_ALIENSA1 + Constants.LEVEL2_ALIENSA2,
		"aliens_b_count": Constants.LEVEL2_ALIENSB,
		"aliens_c_count": Constants.LEVEL2_ALIENSC,
		"aliens_d_count": Constants.LEVEL2_ALIENSD,
		"aliens_e_count": Constants.LEVEL2_ALIENSE,
		"formation_speed": 35.0,
		"formation_march_distance": 350,
		"alien_a_positions": [
			# Formation 1
			Vector2(10, 180), Vector2(25, 180), Vector2(40, 180),
			Vector2(55, 180), Vector2(70, 180), Vector2(85, 180),
			Vector2(100, 180), Vector2(115, 180), Vector2(130, 180),
			Vector2(145, 180), Vector2(160, 180), Vector2(175, 180),
			Vector2(190, 180), Vector2(205, 180),
			# Formation 2
			Vector2(10, 200), Vector2(30, 200), Vector2(50, 200),
			Vector2(70, 200), Vector2(90, 200), Vector2(110, 200),
			Vector2(130, 200), Vector2(150, 200), Vector2(170, 200),
			Vector2(190, 200)
		],
		"alien_b_positions": [
			Vector2(30, 150), Vector2(50, 150), Vector2(70, 150),
			Vector2(90, 150), Vector2(110, 150), Vector2(130, 150),
			Vector2(150, 150), Vector2(170, 150), Vector2(190, 150),
			Vector2(210, 150), Vector2(230, 150), Vector2(250, 150),
			Vector2(270, 150), Vector2(290, 150)
		],
		"alien_c_positions": [
			Vector2(80, 120), Vector2(140, 120)
		],
		"alien_d_positions": [
			Vector2(10, 50), Vector2(200, 50)
		],
		"alien_e_positions": [
			Vector2(40, 80), Vector2(160, 80),
			Vector2(100, 60), Vector2(120, 60)
		]
	}

# Level 3 - Maximum Difficulty
static func get_level_3_data() -> Dictionary:
	return {
		"name": "Level 3 - Ultimate Invasion",
		"aliens_a_count": 30,
		"aliens_b_count": 15,
		"aliens_c_count": 4,
		"aliens_d_count": 3,
		"aliens_e_count": 8,
		"formation_speed": 40.0,
		"formation_march_distance": 300,
		"alien_a_positions": [
			# Dense formation
			Vector2(5, 190), Vector2(18, 190), Vector2(31, 190),
			Vector2(44, 190), Vector2(57, 190), Vector2(70, 190),
			Vector2(83, 190), Vector2(96, 190), Vector2(109, 190),
			Vector2(122, 190), Vector2(135, 190), Vector2(148, 190),
			Vector2(161, 190), Vector2(174, 190), Vector2(187, 190),
			Vector2(5, 205), Vector2(18, 205), Vector2(31, 205),
			Vector2(44, 205), Vector2(57, 205), Vector2(70, 205),
			Vector2(83, 205), Vector2(96, 205), Vector2(109, 205),
			Vector2(122, 205), Vector2(135, 205), Vector2(148, 205),
			Vector2(161, 205), Vector2(174, 205), Vector2(187, 205)
		],
		"alien_b_positions": [
			Vector2(20, 160), Vector2(40, 160), Vector2(60, 160),
			Vector2(80, 160), Vector2(100, 160), Vector2(120, 160),
			Vector2(140, 160), Vector2(160, 160), Vector2(180, 160),
			Vector2(200, 160), Vector2(220, 160), Vector2(240, 160),
			Vector2(260, 160), Vector2(280, 160), Vector2(300, 160)
		],
		"alien_c_positions": [
			Vector2(60, 130), Vector2(100, 130),
			Vector2(140, 130), Vector2(180, 130)
		],
		"alien_d_positions": [
			Vector2(15, 40), Vector2(110, 40), Vector2(205, 40)
		],
		"alien_e_positions": [
			Vector2(30, 70), Vector2(80, 70),
			Vector2(130, 70), Vector2(180, 70),
			Vector2(55, 90), Vector2(105, 90),
			Vector2(155, 90), Vector2(205, 90)
		]
	}

# Get level data by number
static func get_level_data(level_number: int) -> Dictionary:
	match level_number:
		1:
			return get_level_1_data()
		2:
			return get_level_2_data()
		3:
			return get_level_3_data()
		_:
			push_warning("Unknown level: " + str(level_number))
			return get_level_1_data()

# Sound definitions
static func get_sound_definitions() -> Array[Dictionary]:
	return [
		{"name": "LASER", "file": "res://assets/audio/laser.wav", "copies": 5},
		{"name": "WHOOSH", "file": "res://assets/audio/whoosh.wav", "copies": 5},
		{"name": "BOOM1", "file": "res://assets/audio/boom1.wav", "copies": 2},
		{"name": "BOOM2", "file": "res://assets/audio/boom2.wav", "copies": 2},
		{"name": "SPLAT", "file": "res://assets/audio/Splat.wav", "copies": 1},
		{"name": "DOH2", "file": "res://assets/audio/doh2.wav", "copies": 1},
		{"name": "DOH3", "file": "res://assets/audio/doh3.wav", "copies": 1},
		{"name": "HEYHEYHEY", "file": "res://assets/audio/heyheyhey.wav", "copies": 1},
		{"name": "GRUNT1", "file": "res://assets/audio/grunt1.wav", "copies": 5},
		{"name": "TYPE", "file": "res://assets/audio/type.wav", "copies": 10},
		{"name": "APACHELOOP1", "file": "res://assets/audio/apacheloop1.wav", "copies": 1},
		{"name": "SLUDGE", "file": "res://assets/audio/Sludge.wav", "copies": 1},
		{"name": "PHONE", "file": "res://assets/audio/Phone.wav", "copies": 1}
	]
