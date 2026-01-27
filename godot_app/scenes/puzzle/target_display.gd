class_name TargetDisplay
extends PanelContainer
## Displays a row or column target sum, with visual feedback on current progress.

# =============================================================================
# CONSTANTS (using const instead of enum to avoid type issues)
# =============================================================================

const ORIENTATION_ROW := 0
const ORIENTATION_COLUMN := 1

const STATUS_WRONG := 0   # Under OR over - doesn't match
const STATUS_EXACT := 1   # Matches target

# =============================================================================
# PROPERTIES
# =============================================================================

var orientation: int = ORIENTATION_ROW
var index: int = 0  ## Row or column index
var target: int = 0
var current_sum: int = 0
var status: int = STATUS_WRONG

# =============================================================================
# STYLE CONSTANTS
# =============================================================================

const COLOR_WRONG := Color(0.7, 0.25, 0.25)     # Red (doesn't match)
const COLOR_EXACT := Color(0.2, 0.6, 0.3)       # Green (matches!)

const TEXT_COLOR := Color(0.95, 0.95, 0.95)
const DEFAULT_SIZE := Vector2(96, 96)  # Default, can be overridden
const FONT_SIZE := 32

# =============================================================================
# NODES
# =============================================================================

var label: Label

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

	# Create label
	label = Label.new()
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", FONT_SIZE)
	label.add_theme_color_override("font_color", TEXT_COLOR)
	add_child(label)

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

# =============================================================================
# PRIVATE METHODS
# =============================================================================

func _update_status() -> void:
	if current_sum == target:
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
