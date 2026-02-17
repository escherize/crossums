class_name TargetDisplay
extends PanelContainer
## Displays a row or column target sum, with visual feedback on current progress.

# =============================================================================
# CONSTANTS
# =============================================================================

const ORIENTATION_ROW := 0
const ORIENTATION_COLUMN := 1

const STATUS_WRONG := 0   # Under OR over - doesn't match
const STATUS_EXACT := 1   # Matches target

const COLOR_WRONG := Color(0.7, 0.25, 0.25)     # Red (doesn't match)
const COLOR_EXACT := Color(0.2, 0.6, 0.3)       # Green (matches!)
const TEXT_COLOR := Color(0.95, 0.95, 0.95)
const DEFAULT_SIZE := Vector2(96, 96)  # Default, can be overridden
const FONT_SIZE := 32
const CIRC_FONT_SIZE := 16  # Half of main font size
const CIRC_TEXT_COLOR := Color(0.6, 0.9, 0.95)  # Cyan to match circled cells

# =============================================================================
# PROPERTIES
# =============================================================================

var orientation: int = ORIENTATION_ROW
var index: int = 0  ## Row or column index
var target: int = 0
var current_sum: int = 0
var circle_solved: bool = false  ## True if circled cells alone sum to target
var status: int = STATUS_WRONG
var label: Label
var circ_label: Label  ## Shows sum of circled cells

# =============================================================================
# LIFECYCLE
# =============================================================================

func _ready() -> void:
	# Don't override custom_minimum_size - let puzzle_grid set it dynamically
	# Only set default if not already specified
	if custom_minimum_size == Vector2.ZERO:
		custom_minimum_size = DEFAULT_SIZE

	# Set pivot to center for scale animations (use actual size)
	pivot_offset = custom_minimum_size / 2

	# Create main target label (centered)
	label = Label.new()
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", FONT_SIZE)
	label.add_theme_color_override("font_color", TEXT_COLOR)
	add_child(label)

	# Create circled sum label (NE corner - top right)
	circ_label = Label.new()
	circ_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	circ_label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	circ_label.add_theme_font_size_override("font_size", CIRC_FONT_SIZE)
	circ_label.add_theme_color_override("font_color", CIRC_TEXT_COLOR)
	circ_label.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	circ_label.offset_left = -32
	circ_label.offset_right = -2
	circ_label.offset_top = 2
	circ_label.offset_bottom = 18
	add_child(circ_label)

	# Now we're in the tree, apply initial appearance
	_update_status()
	_update_appearance()

# =============================================================================
# PUBLIC METHODS
# =============================================================================

func setup(p_index: int, p_target: int, p_orientation: int = ORIENTATION_ROW) -> void:
	index = p_index
	target = p_target
	orientation = p_orientation
	current_sum = 0
	_update_appearance()


func update_current_sum(new_sum: int) -> void:
	current_sum = new_sum
	_update_status()
	_update_appearance()


func update_circled_sum(sum: int) -> void:
	if circ_label:
		circ_label.text = "" if sum == 0 else str(sum)


func update_circle_solved(is_circle_solved: bool) -> void:
	circle_solved = is_circle_solved
	_update_status()
	_update_appearance()

# =============================================================================
# PRIVATE METHODS
# =============================================================================

func _update_status() -> void:
	if current_sum == target or circle_solved:
		status = STATUS_EXACT
	else:
		status = STATUS_WRONG


func _update_appearance() -> void:
	# Update label text
	if label:
		label.text = str(target)

	# Only apply style if we're in the tree
	if not is_inside_tree():
		return

	# Determine background color based on status
	var bg_color: Color
	if status == STATUS_EXACT:
		bg_color = COLOR_EXACT
	else:
		bg_color = COLOR_WRONG

	# Apply style
	var style = StyleBoxFlat.new()
	style.bg_color = bg_color
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_left = 4
	style.corner_radius_bottom_right = 4
	style.content_margin_left = 4
	style.content_margin_right = 4
	style.content_margin_top = 4
	style.content_margin_bottom = 4

	add_theme_stylebox_override("panel", style)
	queue_redraw()  # Force visual update


func play_success_animation() -> void:
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector2(1.1, 1.1), 0.1)
	tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.1)
