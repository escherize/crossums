extends VBoxContainer
## Displays active operators during gameplay.

const OperatorCardScene = preload("res://scenes/ui/operator_card.tscn")

@onready var header_label: Label = $HeaderLabel
@onready var operator_list: VBoxContainer = $OperatorList

func _ready() -> void:
	# Connect to operator change signals
	EventBus.operator_acquired.connect(func(_op): _refresh_display())
	EventBus.operator_sold.connect(func(_op, _p): _refresh_display())
	EventBus.state_changed.connect(_refresh_display)
	EventBus.operator_triggered.connect(_on_operator_triggered)
	_refresh_display()


func _on_operator_triggered(operator_id: String, _value: int) -> void:
	# Find the card with this operator and trigger its animation
	for child in operator_list.get_children():
		if child is OperatorCard and child.operator_id == operator_id:
			child.play_trigger_animation()
			break


func _refresh_display() -> void:
	# Clear existing cards
	for child in operator_list.get_children():
		child.queue_free()

	var operators = GameState.operators
	var count = operators.size()
	var max_count = GameState.MAX_OPERATORS
	header_label.text = "Operators (%d/%d)" % [count, max_count]

	# Create cards for each operator
	for op in operators:
		var card = OperatorCardScene.instantiate()
		operator_list.add_child(card)
		card.setup(op)

	# Show empty slots indicator
	var empty_slots = max_count - count
	if empty_slots > 0 and count > 0:
		var empty_label = Label.new()
		empty_label.text = "(%d empty)" % empty_slots
		empty_label.add_theme_font_size_override("font_size", 11)
		empty_label.add_theme_color_override("font_color", Color(0.4, 0.45, 0.5))
		empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		operator_list.add_child(empty_label)
