extends Control
## Shop placeholder shown between stages.
## Will be replaced with actual shop in Sprint 5.

signal continue_pressed

@onready var continue_button: Button = %ContinueButton

func _ready() -> void:
	continue_button.pressed.connect(_on_continue_pressed)


func _on_continue_pressed() -> void:
	continue_pressed.emit()
