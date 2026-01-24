class_name GridCell
extends Button
## A single cell in the puzzle grid. Displays a number and handles click interactions.

# =============================================================================
# SIGNALS
# =============================================================================

signal cell_clicked(row: int, col: int)
signal cell_right_clicked(row: int, col: int)
signal cell_hovered(row: int, col: int)
signal cell_unhovered(row: int, col: int)

# =============================================================================
# PROPERTIES
# =============================================================================

## Cell position in the grid
var row: int = 0
var col: int = 0

## The numeric value displayed
var value: int = 0

## Current visual state
var cell_state: PuzzleState.CellState = PuzzleState.CellState.ACTIVE

# =============================================================================
# STYLE CONSTANTS (Minimal placeholder style)
# =============================================================================

const COLOR_ACTIVE := Color(0.2, 0.25, 0.35)       # Dark blue-gray
const COLOR_ACTIVE_HOVER := Color(0.3, 0.35, 0.45) # Lighter on hover
const COLOR_DELETED := Color(0.15, 0.15, 0.15)     # Dark gray
const COLOR_KEPT := Color(0.2, 0.4, 0.3)           # Dark green
const COLOR_LOCKED := Color(0.35, 0.25, 0.2)       # Dark brown

const TEXT_COLOR_ACTIVE := Color(0.95, 0.95, 0.95) # White
const TEXT_COLOR_DELETED := Color(0.4, 0.4, 0.4)   # Gray
const TEXT_COLOR_KEPT := Color(0.7, 1.0, 0.8)      # Light green

const CELL_SIZE := Vector2(96, 96)
const FONT_SIZE := 36

# =============================================================================
# LIFECYCLE
# =============================================================================

func _ready() -> void:
	custom_minimum_size = CELL_SIZE

	# Set pivot to center for scale animations
	pivot_offset = CELL_SIZE / 2

	# Connect signals
	pressed.connect(_on_pressed)
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)

	# Trigger on release (standard touch behavior - can drag out to cancel)
	action_mode = BaseButton.ACTION_MODE_BUTTON_RELEASE

	_update_appearance()


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			cell_right_clicked.emit(row, col)
			accept_event()

# =============================================================================
# PUBLIC METHODS
# =============================================================================

func setup(p_row: int, p_col: int, p_value: int) -> void:
	row = p_row
	col = p_col
	value = p_value
	cell_state = PuzzleState.CellState.ACTIVE
	_update_appearance()


func set_cell_state(new_state: PuzzleState.CellState) -> void:
	cell_state = new_state
	_update_appearance()


func set_value(new_value: int) -> void:
	value = new_value
	_update_appearance()


func play_delete_animation() -> void:
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector2(0.8, 0.8), 0.1)
	tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.1)


func play_restore_animation() -> void:
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector2(1.2, 1.2), 0.1)
	tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.1)

# =============================================================================
# PRIVATE METHODS
# =============================================================================

func _update_appearance() -> void:
	# Set text
	text = str(value)

	# Apply styling based on state
	var bg_color: Color
	var text_color: Color

	match cell_state:
		PuzzleState.CellState.ACTIVE:
			bg_color = COLOR_ACTIVE
			text_color = TEXT_COLOR_ACTIVE
			disabled = false
		PuzzleState.CellState.DELETED:
			bg_color = COLOR_DELETED
			text_color = TEXT_COLOR_DELETED
			disabled = false  # Keep clickable for toggle (touch-friendly)
		PuzzleState.CellState.KEPT:
			bg_color = COLOR_KEPT
			text_color = TEXT_COLOR_KEPT
			disabled = true
		PuzzleState.CellState.LOCKED:
			bg_color = COLOR_LOCKED
			text_color = TEXT_COLOR_ACTIVE
			disabled = true

	# Apply colors using a StyleBoxFlat
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

	add_theme_stylebox_override("normal", style)

	# Hover style
	var hover_style = style.duplicate()
	hover_style.bg_color = bg_color.lightened(0.15)
	add_theme_stylebox_override("hover", hover_style)

	# Pressed style
	var pressed_style = style.duplicate()
	pressed_style.bg_color = bg_color.darkened(0.1)
	add_theme_stylebox_override("pressed", pressed_style)

	# Disabled style
	var disabled_style = style.duplicate()
	add_theme_stylebox_override("disabled", disabled_style)

	# Focus style - no outline (touch-friendly)
	var focus_style = StyleBoxEmpty.new()
	add_theme_stylebox_override("focus", focus_style)

	# Text color
	add_theme_color_override("font_color", text_color)
	add_theme_color_override("font_hover_color", text_color)
	add_theme_color_override("font_pressed_color", text_color)
	add_theme_color_override("font_disabled_color", text_color)

	# Font size
	add_theme_font_size_override("font_size", FONT_SIZE)

# =============================================================================
# SIGNAL HANDLERS
# =============================================================================

func _on_pressed() -> void:
	cell_clicked.emit(row, col)
	release_focus()  # Prevent "selected" look after click


func _on_mouse_entered() -> void:
	cell_hovered.emit(row, col)


func _on_mouse_exited() -> void:
	cell_unhovered.emit(row, col)
