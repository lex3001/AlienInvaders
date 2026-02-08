# SoundManager.gd
# Multi-channel audio management system
# Port from VB6 DirectSound system with multiple buffer copies per sound

extends Node

class_name SoundManager

# Sound effect pools - multiple instances per sound for simultaneous playback
var sound_pools: Dictionary = {}

# Music player
var music_player: AudioStreamPlayer = null

# Configuration
const MAX_SOUND_INSTANCES = 5  # Max simultaneous instances per sound

func _ready():
	# Create music player
	music_player = AudioStreamPlayer.new()
	music_player.bus = "Music"
	add_child(music_player)

func load_sound(sound_name: String, file_path: String, num_copies: int = 1) -> bool:
	# Load audio file
	var stream = load(file_path)
	if not stream:
		push_warning("Failed to load sound: " + file_path)
		return false
	
	# Create pool of players for this sound
	var pool = []
	for i in range(min(num_copies, MAX_SOUND_INSTANCES)):
		var player = AudioStreamPlayer.new()
		player.stream = stream
		player.bus = "SFX"
		add_child(player)
		pool.append(player)
	
	sound_pools[sound_name] = {
		"players": pool,
		"current_index": 0
	}
	
	return true

func play_sound(sound_name: String, volume_db: float = 0.0) -> void:
	if not sound_pools.has(sound_name):
		push_warning("Sound not loaded: " + sound_name)
		return
	
	var pool_data = sound_pools[sound_name]
	var players = pool_data["players"]
	var index = pool_data["current_index"]
	
	# Get next available player
	var player = players[index]
	player.volume_db = volume_db
	player.play()
	
	# Move to next player in pool (round-robin)
	pool_data["current_index"] = (index + 1) % players.size()

func stop_sound(sound_name: String) -> void:
	if not sound_pools.has(sound_name):
		return
	
	var pool_data = sound_pools[sound_name]
	for player in pool_data["players"]:
		if player.playing:
			player.stop()

func play_music(file_path: String, loop: bool = true) -> void:
	if not music_player:
		return
	
	var stream = load(file_path)
	if not stream:
		push_warning("Failed to load music: " + file_path)
		return
	
	music_player.stream = stream
	music_player.stream.loop = loop
	music_player.play()

func stop_music() -> void:
	if music_player and music_player.playing:
		music_player.stop()

func set_music_volume(volume_db: float) -> void:
	if music_player:
		music_player.volume_db = volume_db

func set_sfx_volume(volume_db: float) -> void:
	# Set volume for all SFX players
	for sound_name in sound_pools:
		var pool_data = sound_pools[sound_name]
		for player in pool_data["players"]:
			player.volume_db = volume_db

func load_all_game_sounds() -> void:
	# Load all game sounds based on LevelDefinitions
	var sound_defs = LevelDefinitions.get_sound_definitions()
	for sound_def in sound_defs:
		load_sound(sound_def["name"], sound_def["file"], sound_def["copies"])

func unload_all_sounds() -> void:
	# Stop and remove all sound players
	for sound_name in sound_pools:
		var pool_data = sound_pools[sound_name]
		for player in pool_data["players"]:
			if player.playing:
				player.stop()
			player.queue_free()
	
	sound_pools.clear()
