class_name GridCell
extends TextureButton
## A single cell in the puzzle grid. Displays a number and handles click interactions.

# =============================================================================
# SIGNALS
# =============================================================================

signal cell_clicked(row: int, col: int)
signal cell_right_clicked(row: int, col: int)
signal cell_long_pressed(row: int, col: int)

# =============================================================================
# STYLE CONSTANTS
# =============================================================================

const TILE_TEXTURE = preload("res://assets/textures/wood_tile.png")

const MODULATE_ACTIVE := Color(1.0, 1.0, 1.0)
const MODULATE_DELETED := Color(0.55, 0.5, 0.45, 0.4)
const MODULATE_CIRCLED := Color(0.7, 0.9, 1.0)
const MODULATE_PROTECTED := Color(0.8, 1.0, 0.8)
const MODULATE_CIRCLE_HINT := Color(0.85, 0.95, 1.0)

const TEXT_COLOR_ACTIVE := Color(0.15, 0.1, 0.05)
const TEXT_COLOR_DELETED := Color(0.4, 0.35, 0.3, 0.5)
const TEXT_COLOR_CIRCLED := Color(0.05, 0.2, 0.35)

const DEFAULT_SIZE := Vector2(96, 96)
const FONT_SIZE := 36
const LONG_PRESS_TIME := 0.4

# =============================================================================
# PROPERTIES
# =============================================================================

var row: int = 0
var col: int = 0
var value: int = 0
var cell_state: PuzzleState.CellState = PuzzleState.CellState.ACTIVE
var is_protected: bool = false
var circle_mode_hint: bool = false

var _label: Label
var _press_start_time: int = 0
var _is_pressing: bool = false
var _long_press_triggered: bool = false

# =============================================================================
# LIFECYCLE
# =============================================================================

func _ready() -> void:
	if custom_minimum_size == Vector2.ZERO:
		custom_minimum_size = DEFAULT_SIZE

	pivot_offset = custom_minimum_size / 2

	# Expand to fill GridContainer cell
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	size_flags_vertical = Control.SIZE_EXPAND_FILL

	# TextureButton setup — texture fills the button
	texture_normal = TILE_TEXTURE
	ignore_texture_size = true
	stretch_mode = TextureButton.STRETCH_SCALE

	# Create a centered label for the number
	_label = Label.new()
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	_label.set_offsets_preset(Control.PRESET_FULL_RECT)
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_label.add_theme_font_size_override("font_size", FONT_SIZE)
	add_child(_label)

	resized.connect(_on_resized)
	button_up.connect(_on_button_up)

	_update_appearance()


func _gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		var touch := event as InputEventScreenTouch
		if touch.index == 0:
			if touch.pressed:
				_is_pressing = true
				_long_press_triggered = false
				_press_start_time = Time.get_ticks_msec()
			else:
				if _is_pressing and not _long_press_triggered:
					cell_clicked.emit(row, col)
				_is_pressing = false
			accept_event()
			return

	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			cell_right_clicked.emit(row, col)
			accept_event()
		elif event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				_is_pressing = true
				_long_press_triggered = false
				_press_start_time = Time.get_ticks_msec()
			else:
				if _is_pressing and not _long_press_triggered:
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
	if is_protected != protected:
		is_protected = protected
		_update_appearance()


func set_circle_mode_hint(active: bool) -> void:
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
	var original_modulate = modulate
	var tween = create_tween()
	tween.tween_property(self, "modulate", Color.RED, 0.05)
	tween.tween_property(self, "position:x", position.x - 5, 0.05)
	tween.tween_property(self, "position:x", position.x + 5, 0.05)
	tween.tween_property(self, "position:x", position.x - 5, 0.05)
	tween.tween_property(self, "position:x", position.x, 0.05)
	tween.tween_property(self, "modulate", original_modulate, 0.1)


func play_circle_animation() -> void:
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector2(1.1, 1.1), 0.1)
	tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.1)

# =============================================================================
# PRIVATE METHODS
# =============================================================================

func _update_appearance() -> void:
	var tile_mod: Color
	var text_color: Color

	match cell_state:
		PuzzleState.CellState.ACTIVE:
			tile_mod = MODULATE_ACTIVE
			text_color = TEXT_COLOR_ACTIVE
		PuzzleState.CellState.DELETED:
			tile_mod = MODULATE_DELETED
			text_color = TEXT_COLOR_DELETED
		PuzzleState.CellState.CIRCLED:
			tile_mod = MODULATE_CIRCLED
			text_color = TEXT_COLOR_CIRCLED

	if is_protected and cell_state != PuzzleState.CellState.DELETED:
		tile_mod = tile_mod.lerp(MODULATE_PROTECTED, 0.4)

	if circle_mode_hint and cell_state == PuzzleState.CellState.ACTIVE:
		tile_mod = tile_mod.lerp(MODULATE_CIRCLE_HINT, 0.3)

	self_modulate = tile_mod

	if _label:
		_label.text = str(value)
		_label.add_theme_color_override("font_color", text_color)

# =============================================================================
# SIGNAL HANDLERS
# =============================================================================

func _on_resized() -> void:
	pivot_offset = size / 2


func _on_button_up() -> void:
	if _long_press_triggered:
		_long_press_triggered = false
		release_focus()
		return
	cell_clicked.emit(row, col)
	release_focus()
