# Constants.gd
# Port of all game constants from VB6 source code and documentation
# Reference: vb6/docs/05_FEATURE_DOCUMENTATION.md and VB6 source files

extends Node

# Test mode flag - enables debug features
const TEST_MODE: bool = false

# Screen dimensions
const SCREEN_WIDTH: int = 640
const SCREEN_HEIGHT: int = 480
const TOP_BORDER: int = 0
const BOTTOM_BORDER: int = 20
const PLAY_HEIGHT: int = SCREEN_HEIGHT - TOP_BORDER - BOTTOM_BORDER  # 428

# Player constants
const PLAYER_VELOCITY: float = 90.0  # pixels per second
const PLAYER_MISSILE_RECHARGE_MS: int = 750  # milliseconds
const PLAYER_MISSILE_VELOCITY: float = 200.0  # pixels per second
const MAX_MISSILES: int = 10

# Bomb velocities (pixels per second)
const ABOMB_VELOCITY: float = 80.0
const DBOMB_VELOCITY: float = 100.0

# Shield constants
const MAX_SHIELDS_TICKS: int = 50000  # 50 seconds worth
const STARTING_SHIELDS_TICKS: int = 25000  # Start with half max (25 seconds)

# Alien Type A - Swarmer (formation follower)
const ALIENA_BOMB_INTERVAL_MS: int = 4000
const MAX_ALIENA_BOMBS: int = 25
const ALIENA_SCORE: int = 10

# Alien Type B - Tank (multi-hit, decorative)
const ALIENB_SCORE: int = 10

# Alien Type C - Aggressive attacker
const ALIENC_ATTACK_RANGE: int = 48  # pixels
const ALIENC_ATTACK_INTERVAL_MS: int = 8000
const ALIENC_SCORE: int = 10

# Alien Type D - Orbital bomber
const ALIEND_BOMB_INTERVAL_MS: int = 4000
const MAX_ALIEND_BOMBS: int = 25
const ALIEND_SCORE: int = 25

# Alien Type E - Advanced enemy
const ALIENE_ATTACK_INTERVAL_MS: int = 15000
const ALIENE_ATTACK_TURN_MIN_MS: int = 2500
const ALIENE_ATTACK_TURN_MAX_MS: int = 4500
const ALIENE_IDLE_BOMB_INTERVAL_MS: int = 10000
const ALIENE_ATTACK_BOMB_INTERVAL_MS: int = 2000
const ALIENE_SCORE: int = 10

# Scoring multipliers
const MULTIPLIER_2X: float = 2.0
const MULTIPLIER_3X: float = 3.0
const MULTIPLIER_4X: float = 4.0
const MULTIPLIER_5X: float = 5.0
const MULTIPLIER_10X: float = 10.0

# Bonus values
const BONUS_MIN: int = 10
const BONUS_MAX: int = 200

# Power-up types
enum PowerUpType {
	DOUBLE_SHOT,
	RAPID_FIRE,
	MULTI_SHOT,
	SHIELD_RECHARGE,
	EXTRA_LIFE,
	SCORE_BONUS,
	CARGO_DROP,
	NONE
}

# Game states
enum GameState {
	MENU,
	PLAYING,
	PAUSED,
	GAME_OVER,
	LEVEL_COMPLETE
}

# Frame timing
const TARGET_FPS: float = 25.0  # Original VB6 game target
const FRAME_TIME: float = 1.0 / TARGET_FPS  # ~0.04 seconds per frame

# Level progression
const END_LEVEL_PAUSE_MS: int = 500

# Animation timing (milliseconds per frame)
const ALIENA_ANIM_MS: int = 50
const ALIENA_EXPLOSION_MS: int = 10
const MISSILE_ANIM_MS: int = 100

# Animation loop types (VB6 compatible)
const ANIM_LOOP_NONE: int = 0
const ANIM_LOOP_ONE_WAY: int = 1
const ANIM_LOOP_TWO_WAY: int = 2
const ANIM_LOOP_NONE_REVERSE: int = 3
const ANIM_LOOP_ONE_WAY_REVERSE: int = 4

# Collision constants
const DONT_MARCH: int = -1

# Math constants
const PI: float = 3.14159265358979

# Stars/background
const NUM_STARS: int = 50

# Max bonuses
const MAX_BONUSES: int = 20

# Planet timing
const PLANET_INTERVAL_MS: int = 30000
const PLANET_DURATION_MS: int = 5000

# XBonus timing
const XBONUS_INTERVAL_MS: int = 30000
const XBONUS_DURATION_MS: int = 4500

# Cargo ship timing
const CARGO_SHIP_LONGEST_WAIT_MS: int = 30000
const CARGO_SHIP_VELOCITY: float = 50.0

# Level 1 alien counts
const LEVEL1_ALIENSA: int = 20
const LEVEL1_ALIENSB: int = 9
const LEVEL1_ALIENSC: int = 2
const LEVEL1_ALIENSD: int = 2
const LEVEL1_ALIENSE: int = 6

# Level 2 alien counts  
const LEVEL2_ALIENSA1: int = 14
const LEVEL2_ALIENSA2: int = 10
const LEVEL2_ALIENSB: int = 14
const LEVEL2_ALIENSC: int = 2
const LEVEL2_ALIENSD: int = 2
const LEVEL2_ALIENSE: int = 4

# Level 4 alien counts
const LEVEL4_ALIENSA: int = 23
const LEVEL4_ALIENSB: int = 5
const LEVEL4_ALIENSC: int = 4
const LEVEL4_ALIENSD: int = 2
const LEVEL4_ALIENSE: int = 16

# Helper functions
static func degrees_to_radians(degrees: float) -> float:
	return degrees * PI / 180.0

static func radians_to_degrees(radians: float) -> float:
	return radians * 180.0 / PI
