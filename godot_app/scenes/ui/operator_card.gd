class_name OperatorCard
extends PanelContainer
## Displays a single operator card with rarity indicator.

const RARITY_COLORS := {
	0: Color(0.5, 0.6, 0.7),    # Common - Gray-blue
	1: Color(0.3, 0.7, 0.4),    # Uncommon - Green
	2: Color(0.3, 0.6, 0.9),    # Rare - Blue
	3: Color(0.9, 0.7, 0.2),    # Legendary - Gold
}

var operator: Operator = null
var operator_id: String = ""

@onready var rarity_strip: ColorRect = $VBox/RarityStrip
@onready var name_label: Label = $VBox/Content/NameLabel
@onready var desc_label: Label = $VBox/Content/DescLabel


func setup(op: Operator) -> void:
	operator = op
	operator_id = op.id

	if is_node_ready():
		_update_display()
	else:
		ready.connect(_update_display, CONNECT_ONE_SHOT)


func _update_display() -> void:
	if operator == null:
		return
	name_label.text = operator.display_name
	desc_label.text = operator.description
	rarity_strip.color = RARITY_COLORS.get(operator.rarity, RARITY_COLORS[0])


func play_trigger_animation() -> void:
	var tween = create_tween()
	var glow_color = RARITY_COLORS.get(operator.rarity, RARITY_COLORS[0])

	# Brief scale pulse with glow
	tween.tween_property(self, "scale", Vector2(1.05, 1.05), 0.1)
	tween.parallel().tween_property(self, "modulate", glow_color.lightened(0.4), 0.1)
	tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.15)
	tween.parallel().tween_property(self, "modulate", Color.WHITE, 0.15)
