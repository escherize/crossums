extends Control
## How to Play tutorial overlay.
## Explains game mechanics to new players.

signal closed

@onready var close_button: Button = %CloseButton

func _ready() -> void:
	close_button.pressed.connect(_on_close_pressed)


func _on_close_pressed() -> void:
	closed.emit()
