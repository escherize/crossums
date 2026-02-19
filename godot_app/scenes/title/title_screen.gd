extends Control
## Title screen - landing page for the game.
## Shows game title, Start Run button, How to Play, and Options (grayed out).

# =============================================================================
# SCENE REFERENCES
# =============================================================================

const MainScene = preload("res://scenes/main.tscn")
const HowToPlayScene = preload("res://scenes/title/how_to_play.tscn")

# =============================================================================
# STATE
# =============================================================================

var _how_to_play_instance: Control = null

# =============================================================================
# NODE REFERENCES
# =============================================================================

@onready var continue_button: Button = %ContinueButton
@onready var start_button: Button = %StartButton
@onready var how_to_play_button: Button = %HowToPlayButton
@onready var options_button: Button = %OptionsButton
@onready var overlay_container: CanvasLayer = %OverlayContainer
@onready var subtitle_label: Label = %SubtitleLabel

# =============================================================================
# LIFECYCLE
# =============================================================================

func _ready() -> void:
	_connect_signals()
	# Set version from GameConfig
	subtitle_label.text = "A Number Puzzle Roguelike  v%s" % GameConfig.VERSION
	# Ensure RunManager is in IDLE state
	RunManager.return_to_title()
	# Show/hide continue button based on save existence
	continue_button.visible = SaveManager.save_exists()


func _connect_signals() -> void:
	continue_button.pressed.connect(_on_continue_pressed)
	start_button.pressed.connect(_on_start_pressed)
	how_to_play_button.pressed.connect(_on_how_to_play_pressed)
	options_button.pressed.connect(_on_options_pressed)

# =============================================================================
# BUTTON HANDLERS
# =============================================================================

func _on_continue_pressed() -> void:
	# Load saved run and continue
	if SaveManager.load_run():
		RunManager.current_state = RunManager.State.PUZZLE_ACTIVE
		get_tree().change_scene_to_packed(MainScene)
	else:
		# Save failed to load, hide button
		continue_button.visible = false


func _on_start_pressed() -> void:
	# Start a new run (delete any existing save)
	SaveManager.delete_save()
	RunManager.start_run()
	# Transition to main scene
	get_tree().change_scene_to_packed(MainScene)


func _on_how_to_play_pressed() -> void:
	if _how_to_play_instance != null:
		return  # Already showing

	_how_to_play_instance = HowToPlayScene.instantiate()
	_how_to_play_instance.closed.connect(_on_how_to_play_closed)
	overlay_container.add_child(_how_to_play_instance)


func _on_how_to_play_closed() -> void:
	if _how_to_play_instance:
		_how_to_play_instance.queue_free()
		_how_to_play_instance = null


func _on_options_pressed() -> void:
	# Options not yet implemented
	pass
