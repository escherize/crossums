extends Node
## Manages game sound effects with configurable mappings.
## Sound files can be swapped by changing the paths in SOUND_MAP.

# =============================================================================
# CONSTANTS
# =============================================================================

const PLAYER_POOL_SIZE := 8

# Sound mapping - edit these paths to swap sound files
const SOUND_MAP := {
	# Core gameplay
	"cell_click": "res://assets/audio/sfx/click.wav",
	"cell_restore": "res://assets/audio/sfx/restore.wav",
	"row_complete": "res://assets/audio/sfx/ding.wav",
	"puzzle_complete": "res://assets/audio/sfx/fanfare.wav",

	# Feedback
	"mistake": "res://assets/audio/sfx/mistake.wav",
	"life_lost": "res://assets/audio/sfx/life_lost.wav",

	# Economy
	"coin_gain": "res://assets/audio/sfx/coin_gain.wav",
	"coin_spend": "res://assets/audio/sfx/coin_spend.wav",

	# Score animation
	"score_tick": "res://assets/audio/sfx/score_tick.wav",
	"multiplier_apply": "res://assets/audio/sfx/multiplier.wav",

	# UI
	"button_click": "res://assets/audio/sfx/button.wav",
	"menu_open": "res://assets/audio/sfx/menu_open.wav",
}

# =============================================================================
# VARIABLES
# =============================================================================

# Pool of AudioStreamPlayer nodes for concurrent sounds
var _players: Array[AudioStreamPlayer] = []
var _next_player := 0

# Preloaded sounds cache
var _sound_cache: Dictionary = {}

# Master volume (0.0 to 1.0)
var _master_volume := 1.0

# =============================================================================
# LIFECYCLE
# =============================================================================

func _ready() -> void:
	# Create audio player pool
	for i in range(PLAYER_POOL_SIZE):
		var player := AudioStreamPlayer.new()
		player.bus = "Master"
		add_child(player)
		_players.append(player)

	# Preload all sounds
	_preload_sounds()

	# Connect to EventBus signals
	_connect_events()


func _preload_sounds() -> void:
	for key in SOUND_MAP:
		var path: String = SOUND_MAP[key]
		if ResourceLoader.exists(path):
			_sound_cache[key] = load(path)
		else:
			push_warning("SoundManager: Sound file not found: %s" % path)


func _connect_events() -> void:
	# Cell interactions
	EventBus.cell_deleted.connect(_on_cell_deleted)
	EventBus.cell_restored.connect(_on_cell_restored)
	EventBus.cell_circled.connect(_on_cell_circled)

	# Mistakes and feedback
	EventBus.mistake_made.connect(_on_mistake_made)
	EventBus.life_lost.connect(_on_life_lost)

	# Puzzle state
	EventBus.puzzle_completed.connect(_on_puzzle_completed)

	# Economy
	EventBus.money_changed.connect(_on_money_changed)

	# Score animation
	EventBus.score_step.connect(_on_score_step)
	EventBus.operator_triggered.connect(_on_operator_triggered)

# =============================================================================
# PUBLIC API
# =============================================================================

func set_master_volume(value: float) -> void:
	## Set master volume (0.0 to 1.0)
	_master_volume = clampf(value, 0.0, 1.0)
	for player in _players:
		player.volume_db = linear_to_db(_master_volume)


func play(sound_key: String, volume_scale := 1.0) -> void:
	## Play a sound by its key from SOUND_MAP
	if not _sound_cache.has(sound_key):
		push_warning("SoundManager: Unknown sound key: %s" % sound_key)
		return

	var stream: AudioStream = _sound_cache[sound_key]
	if not stream:
		return

	# Get next available player (round-robin)
	var player := _players[_next_player]
	_next_player = (_next_player + 1) % PLAYER_POOL_SIZE

	player.stream = stream
	player.volume_db = linear_to_db(_master_volume * volume_scale)
	player.play()


func play_with_pitch(sound_key: String, pitch_scale := 1.0, volume_scale := 1.0) -> void:
	## Play a sound with pitch variation (useful for repeated sounds)
	if not _sound_cache.has(sound_key):
		return

	var stream: AudioStream = _sound_cache[sound_key]
	if not stream:
		return

	var player := _players[_next_player]
	_next_player = (_next_player + 1) % PLAYER_POOL_SIZE

	player.stream = stream
	player.pitch_scale = pitch_scale
	player.volume_db = linear_to_db(_master_volume * volume_scale)
	player.play()

	# Reset pitch after playing (via callback)
	player.finished.connect(func(): player.pitch_scale = 1.0, CONNECT_ONE_SHOT)

# =============================================================================
# EVENT HANDLERS
# =============================================================================

func _on_cell_deleted(_row: int, _col: int, _value: int) -> void:
	# Slight pitch variation for repeated clicks
	var pitch := randf_range(0.95, 1.05)
	play_with_pitch("cell_click", pitch)


func _on_cell_restored(_row: int, _col: int, _value: int) -> void:
	play("cell_restore")


func _on_cell_circled(_row: int, _col: int) -> void:
	play("cell_click", 0.7)  # Quieter click for circle


func _on_mistake_made(_row: int, _col: int) -> void:
	play("mistake")


func _on_life_lost(_remaining: int) -> void:
	play("life_lost")


func _on_puzzle_completed(success: bool, _score: int, _reward: int) -> void:
	if success:
		play("puzzle_complete")


func _on_money_changed(_new_amount: int, delta: int) -> void:
	if delta > 0:
		play("coin_gain")
	elif delta < 0:
		play("coin_spend")


func _on_score_step(_source: String, _value: Variant, step_type: String) -> void:
	if step_type == "multiplier":
		play("multiplier_apply", 0.6)
	else:
		play("score_tick", 0.4)


func _on_operator_triggered(_operator_id: String, _effect_value: Variant) -> void:
	play("multiplier_apply", 0.5)
