class_name GridCell
extends Button
## A single cell in the puzzle grid. Displays a number and handles click interactions.

# =============================================================================
# SIGNALS
# =============================================================================

signal cell_clicked(row: int, col: int)
signal cell_right_clicked(row: int, col: int)
signal cell_long_pressed(row: int, col: int)

# =============================================================================
# STYLE CONSTANTS (Minimal placeholder style)
# =============================================================================

const COLOR_ACTIVE := Color(0.2, 0.25, 0.35)       # Dark blue-gray
const COLOR_ACTIVE_HOVER := Color(0.3, 0.35, 0.45) # Lighter on hover
const COLOR_DELETED := Color(0.15, 0.15, 0.15)     # Dark gray
const COLOR_CIRCLED := Color(0.15, 0.32, 0.42)     # Teal-tinted background (distinct from active)
const COLOR_CIRCLED_BORDER := Color(0.4, 0.9, 1.0) # Bright cyan border
const COLOR_PROTECTED_TINT := Color(0.6, 1.0, 0.6) # Light green tint for safety net

const TEXT_COLOR_ACTIVE := Color(0.95, 0.95, 0.95) # White
const TEXT_COLOR_DELETED := Color(0.4, 0.4, 0.4)   # Gray
const TEXT_COLOR_CIRCLED := Color(0.85, 1.0, 1.0)  # Bright cyan-white

const DEFAULT_SIZE := Vector2(96, 96)
const FONT_SIZE := 36
const LONG_PRESS_TIME := 0.4  # 400ms for long press

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

## Protected state (Safety Net operator) - visual only, doesn't affect logic
var is_protected: bool = false

## Circle mode hint (shift-key button held) - visual only
var circle_mode_hint: bool = false

# Long press tracking
var _press_start_time: int = 0
var _is_pressing: bool = false
var _long_press_triggered: bool = false

# =============================================================================
# LIFECYCLE
# =============================================================================

func _ready() -> void:
	# Don't override custom_minimum_size - let puzzle_grid set it dynamically
	if custom_minimum_size == Vector2.ZERO:
		custom_minimum_size = DEFAULT_SIZE

	# Set pivot to center for scale animations (use actual size)
	pivot_offset = custom_minimum_size / 2

	# Connect signals - use button_up instead of pressed for reliable mobile support
	# (pressed signal has known issues with ACTION_MODE_BUTTON_RELEASE on mobile)
	button_up.connect(_on_button_up)

	_update_appearance()


func _gui_input(event: InputEvent) -> void:
	# Handle touch directly (bypasses unreliable button_up emulation on mobile web)
	if event is InputEventScreenTouch:
		var touch := event as InputEventScreenTouch
		if touch.index == 0:  # Primary touch only (multitouch handled by PuzzleGrid)
			if touch.pressed:
				_is_pressing = true
				_long_press_triggered = false
				_press_start_time = Time.get_ticks_msec()
			else:
				# Touch released - emit click if not long press
				if _is_pressing and not _long_press_triggered:
					cell_clicked.emit(row, col)
				_is_pressing = false
			accept_event()
			return

	if event is InputEventMouseButton:
		# Right-click = circle (mouse)
		if event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			cell_right_clicked.emit(row, col)
			accept_event()
		# Track left button for long press detection
		elif event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				_is_pressing = true
				_long_press_triggered = false
				_press_start_time = Time.get_ticks_msec()
			else:
				# Button released
				if _is_pressing and not _long_press_triggered:
					# Normal tap - let _on_pressed handle it
					pass
				_is_pressing = false


func _process(_delta: float) -> void:
	if _is_pressing and not _long_press_triggered:
		var elapsed := (Time.get_ticks_msec() - _press_start_time) / 1000.0
		if elapsed >= LONG_PRESS_TIME:
			_long_press_triggered = true
			_is_pressing = false
			cell_long_pressed.emit(row, col)

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


func set_protected(protected: bool) -> void:
	## Set protected visual state (Safety Net operator)
	if is_protected != protected:
		is_protected = protected
		_update_appearance()


func set_circle_mode_hint(active: bool) -> void:
	## Set circle mode visual hint (shift-key button held)
	if circle_mode_hint != active:
		circle_mode_hint = active
		_update_appearance()


func play_delete_animation() -> void:
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector2(0.8, 0.8), 0.1)
	tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.1)


func play_restore_animation() -> void:
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector2(1.2, 1.2), 0.1)
	tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.1)


func play_error_animation() -> void:
	## Flash red and shake to indicate mistake
	var original_modulate = modulate
	var tween = create_tween()
	# Flash red
	tween.tween_property(self, "modulate", Color.RED, 0.05)
	# Shake left-right
	tween.tween_property(self, "position:x", position.x - 5, 0.05)
	tween.tween_property(self, "position:x", position.x + 5, 0.05)
	tween.tween_property(self, "position:x", position.x - 5, 0.05)
	tween.tween_property(self, "position:x", position.x, 0.05)
	# Restore color
	tween.tween_property(self, "modulate", original_modulate, 0.1)


func play_circle_animation() -> void:
	## Brief pulse to confirm circle/uncircle
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector2(1.1, 1.1), 0.1)
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

	var border_color: Color = Color.TRANSPARENT
	var border_width: int = 0
	var corner_radius: int = 4

	match cell_state:
		PuzzleState.CellState.ACTIVE:
			bg_color = COLOR_ACTIVE
			text_color = TEXT_COLOR_ACTIVE
			disabled = false
		PuzzleState.CellState.DELETED:
			bg_color = COLOR_DELETED
			text_color = TEXT_COLOR_DELETED
			disabled = false  # Keep clickable for toggle (touch-friendly)
		PuzzleState.CellState.CIRCLED:
			bg_color = COLOR_CIRCLED
			text_color = TEXT_COLOR_CIRCLED
			border_color = COLOR_CIRCLED_BORDER
			border_width = 4
			corner_radius = 12  # Rounder corners for "keeper" cells
			disabled = false  # Clickable to uncircle

	# Apply protected tint (Safety Net operator)
	if is_protected and cell_state != PuzzleState.CellState.DELETED:
		bg_color = bg_color.lerp(COLOR_PROTECTED_TINT, 0.3)

	# Apply circle mode hint (shift-key button held)
	if circle_mode_hint and cell_state == PuzzleState.CellState.ACTIVE:
		bg_color = bg_color.lerp(COLOR_CIRCLED_BORDER, 0.2)

	# Apply colors using a StyleBoxFlat
	var style = StyleBoxFlat.new()
	style.bg_color = bg_color
	style.corner_radius_top_left = corner_radius
	style.corner_radius_top_right = corner_radius
	style.corner_radius_bottom_left = corner_radius
	style.corner_radius_bottom_right = corner_radius
	style.content_margin_left = 4
	style.content_margin_right = 4
	style.content_margin_top = 4
	style.content_margin_bottom = 4

	# Add border for circled state
	if border_width > 0:
		style.border_width_left = border_width
		style.border_width_right = border_width
		style.border_width_top = border_width
		style.border_width_bottom = border_width
		style.border_color = border_color

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

func _on_button_up() -> void:
	# Don't emit click if long press was triggered
	if _long_press_triggered:
		_long_press_triggered = false
		release_focus()
		return
	cell_clicked.emit(row, col)
	release_focus()  # Prevent "selected" look after click
