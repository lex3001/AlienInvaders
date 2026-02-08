# PowerUp.gd
# Power-up cargo drops and pickups
# Port from VB6 cargo system

extends Actor

class_name PowerUp

# Power-up type
var power_up_type: GameConstants.PowerUpType = GameConstants.PowerUpType.NONE

# Power-up value (for score bonuses)
var value: int = 0

# Lifetime
var lifetime: float = 10.0  # Seconds before disappearing
var time_alive: float = 0.0

func _ready():
	super._ready()
	
	# Fall downward
	velocity_direction = 90.0  # Down
	velocity_magnitude = 100.0  # Slow fall

func _process(delta: float) -> void:
	super._process(delta)
	
	# Update lifetime
	time_alive += delta
	
	# Remove if too old or off screen
	if time_alive >= lifetime or is_off_screen:
		is_deleted = true

func apply_to_level(target_level: Level) -> void:
	if not target_level:
		return
	
	match power_up_type:
		GameConstants.PowerUpType.DOUBLE_SHOT:
			target_level.has_double_shots = true
		GameConstants.PowerUpType.RAPID_FIRE:
			target_level.has_rapid_fire = true
		GameConstants.PowerUpType.MULTI_SHOT:
			target_level.has_multi_shots = true
		GameConstants.PowerUpType.SHIELD_RECHARGE:
			target_level.shields_left += GameConstants.STARTING_SHIELDS_TICKS / 2
			if target_level.shields_left > GameConstants.MAX_SHIELDS_TICKS:
				target_level.shields_left = GameConstants.MAX_SHIELDS_TICKS
		GameConstants.PowerUpType.EXTRA_LIFE:
			if target_level.game:
				target_level.game.add_life()
		GameConstants.PowerUpType.SCORE_BONUS:
			if target_level.game:
				target_level.game.add_score(value)
		GameConstants.PowerUpType.CARGO_DROP:
			# Cargo drop gives random bonus
			if target_level.game:
				target_level.game.add_score(randi_range(GameConstants.BONUS_MIN, GameConstants.BONUS_MAX))

static func create_random_powerup() -> GameConstants.PowerUpType:
	var types = [
		GameConstants.PowerUpType.DOUBLE_SHOT,
		GameConstants.PowerUpType.RAPID_FIRE,
		GameConstants.PowerUpType.MULTI_SHOT,
		GameConstants.PowerUpType.SHIELD_RECHARGE,
		GameConstants.PowerUpType.EXTRA_LIFE,
		GameConstants.PowerUpType.SCORE_BONUS,
		GameConstants.PowerUpType.CARGO_DROP
	]
	return types[randi() % types.size()]
