extends Control
## Victory screen shown when player completes all 9 stages.

signal play_again_pressed

const TITLE_SCENE_PATH := "res://scenes/title/title_screen.tscn"

@onready var score_label: Label = %ScoreLabel
@onready var play_again_button: Button = %PlayAgainButton

func _ready() -> void:
	play_again_button.pressed.connect(_on_play_again_pressed)


func show_victory(total_score: int) -> void:
	score_label.text = "Final Score: %d" % total_score
	visible = true


func _on_play_again_pressed() -> void:
	play_again_pressed.emit()
	RunManager.return_to_title()
	# Use change_scene_to_file to avoid ERR_CANT_CREATE when returning to starting scene
	get_tree().change_scene_to_file(TITLE_SCENE_PATH)
