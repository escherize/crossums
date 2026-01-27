extends Control
## HUD displaying current run state: stage, puzzle, lives, money, score, target.

# =============================================================================
# NODE REFERENCES
# =============================================================================

@onready var stage_label: Label = %StageLabel
@onready var puzzle_label: Label = %PuzzleLabel
@onready var lives_label: Label = %LivesLabel
@onready var money_label: Label = %MoneyLabel
@onready var score_label: Label = %ScoreLabel
@onready var target_label: Label = %TargetLabel

# =============================================================================
# LIFECYCLE
# =============================================================================

func _ready() -> void:
	EventBus.state_changed.connect(_on_state_changed)
	EventBus.money_changed.connect(_on_money_changed)
	EventBus.life_lost.connect(_on_life_lost)
	refresh()


func _on_state_changed() -> void:
	refresh()


func _on_money_changed(_new_amount: int, _delta: int) -> void:
	refresh()


func _on_life_lost(_remaining: int) -> void:
	refresh()
	# Flash the lives label red briefly
	_flash_lives_label()

# =============================================================================
# DISPLAY
# =============================================================================

func refresh() -> void:
	if GameState.run == null:
		visible = false
		return

	visible = true
	var run = GameState.run

	stage_label.text = "Stage %d" % run.stage
	puzzle_label.text = "Puzzle %d/3" % (run.puzzle_index + 1)
	lives_label.text = _get_lives_display(run.lives)
	money_label.text = "$%d" % run.money
	score_label.text = "Score: %d" % run.total_score

	# Get target from current stage config
	var config = RunManager.get_current_stage_config()
	if config:
		target_label.text = "Target: %d" % config.score_target
	else:
		target_label.text = "Target: ---"


func _get_lives_display(lives: int) -> String:
	var max_lives: int = GameState.run.max_lives if GameState.run else 5
	return "Lives: %d/%d" % [lives, max_lives]


func _flash_lives_label() -> void:
	## Flash the lives label red to indicate life lost
	var original_color = lives_label.modulate
	lives_label.modulate = Color.RED
	var tween = create_tween()
	tween.tween_property(lives_label, "modulate", original_color, 0.3)
