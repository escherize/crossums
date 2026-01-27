extends Control
## Result popup shown after completing a puzzle.
## Shows PASS/FAIL, score vs target, and Continue button.

signal continue_pressed

# =============================================================================
# NODE REFERENCES
# =============================================================================

@onready var result_label: Label = %ResultLabel
@onready var score_label: Label = %ScoreLabel
@onready var target_label: Label = %TargetLabel
@onready var reward_label: Label = %RewardLabel
@onready var continue_button: Button = %ContinueButton

# =============================================================================
# LIFECYCLE
# =============================================================================

func _ready() -> void:
	continue_button.pressed.connect(_on_continue_pressed)


func _on_continue_pressed() -> void:
	continue_pressed.emit()

# =============================================================================
# DISPLAY
# =============================================================================

func show_result(won: bool, score: int, target: int, reward: int) -> void:
	if won:
		result_label.text = "PASS!"
		result_label.add_theme_color_override("font_color", Color(0.4, 0.9, 0.4))
		reward_label.text = "+$%d" % reward
		reward_label.visible = true
	else:
		result_label.text = "FAIL"
		result_label.add_theme_color_override("font_color", Color(0.9, 0.4, 0.4))
		reward_label.text = "-1 ♥"
		reward_label.visible = true

	score_label.text = "Score: %d" % score
	target_label.text = "Target: %d" % target

	# Color score based on pass/fail
	if score >= target:
		score_label.add_theme_color_override("font_color", Color(0.4, 0.9, 0.4))
	else:
		score_label.add_theme_color_override("font_color", Color(0.9, 0.4, 0.4))

	visible = true
