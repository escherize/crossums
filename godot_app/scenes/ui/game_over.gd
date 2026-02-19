extends Control
## Game over screen shown when player runs out of lives.

signal try_again_pressed

const TITLE_SCENE_PATH := "res://scenes/title/title_screen.tscn"

@onready var score_label: Label = %ScoreLabel
@onready var stages_label: Label = %StagesLabel
@onready var try_again_button: Button = %TryAgainButton

func _ready() -> void:
	try_again_button.pressed.connect(_on_try_again_pressed)


func show_game_over(total_score: int, stages_cleared: int) -> void:
	score_label.text = "Final Score: %d" % total_score
	stages_label.text = "Stages Cleared: %d / 9" % stages_cleared
	visible = true


func _on_try_again_pressed() -> void:
	try_again_pressed.emit()
	RunManager.return_to_title()
	# Use change_scene_to_file to avoid ERR_CANT_CREATE when returning to starting scene
	get_tree().change_scene_to_file(TITLE_SCENE_PATH)
