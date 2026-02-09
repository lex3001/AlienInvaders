# PowerUp.gd
# Power-up cargo drops and pickups
# Port from VB6 cargo system

extends Actor

class_name PowerUp

# Power-up type
var power_up_type: Constants.PowerUpType = Constants.PowerUpType.NONE

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
		Constants.PowerUpType.DOUBLE_SHOT:
			target_level.has_double_shots = true
		Constants.PowerUpType.RAPID_FIRE:
			target_level.has_rapid_fire = true
		Constants.PowerUpType.MULTI_SHOT:
			target_level.has_multi_shots = true
		Constants.PowerUpType.SHIELD_RECHARGE:
			target_level.shields_left += int(Constants.STARTING_SHIELDS_TICKS / 2.0)
			if target_level.shields_left > Constants.MAX_SHIELDS_TICKS:
				target_level.shields_left = Constants.MAX_SHIELDS_TICKS
		Constants.PowerUpType.EXTRA_LIFE:
			if target_level.game:
				target_level.game.add_life()
		Constants.PowerUpType.SCORE_BONUS:
			if target_level.game:
				target_level.game.add_score(value)
		Constants.PowerUpType.CARGO_DROP:
			# Cargo drop gives random bonus
			if target_level.game:
				target_level.game.add_score(randi_range(Constants.BONUS_MIN, Constants.BONUS_MAX))

static func create_random_powerup() -> Constants.PowerUpType:
	var types = [
		Constants.PowerUpType.DOUBLE_SHOT,
		Constants.PowerUpType.RAPID_FIRE,
		Constants.PowerUpType.MULTI_SHOT,
		Constants.PowerUpType.SHIELD_RECHARGE,
		Constants.PowerUpType.EXTRA_LIFE,
		Constants.PowerUpType.SCORE_BONUS,
		Constants.PowerUpType.CARGO_DROP
	]
	return types[randi() % types.size()]
