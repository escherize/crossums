class_name CircleModeButton
extends Button
## Shift-key style button for circle mode on touchscreen.
## Hold to activate circle mode, release to return to delete mode.
## Hidden on web/desktop (use right-click instead).

signal circle_mode_changed(active: bool)

# =============================================================================
# CONSTANTS
# =============================================================================

const COLOR_INACTIVE := Color(0.3, 0.35, 0.4)
const COLOR_ACTIVE := Color(0.3, 0.7, 0.9)
const ICON_INACTIVE := "○"
const ICON_ACTIVE := "◉"

# =============================================================================
# STATE
# =============================================================================

var is_active: bool = false

# =============================================================================
# LIFECYCLE
# =============================================================================

func _ready() -> void:
	# Hide on web/desktop - they use right-click
	if _is_desktop_platform():
		hide()
		return

	# Configure button appearance
	custom_minimum_size = Vector2(70, 90)
	text = ICON_INACTIVE

	# Use press and release, not toggle
	toggle_mode = false
	action_mode = BaseButton.ACTION_MODE_BUTTON_PRESS

	_update_appearance()


func _input(event: InputEvent) -> void:
	# Skip if hidden (desktop)
	if not visible:
		return

	# Track touch/mouse press state for this button
	if event is InputEventScreenTouch or event is InputEventMouseButton:
		var pressed_now: bool = event.pressed if event is InputEventScreenTouch \
			else (event as InputEventMouseButton).pressed

		# Check if event is within our rect
		var local_pos = get_local_mouse_position()
		var in_bounds = Rect2(Vector2.ZERO, size).has_point(local_pos)

		if pressed_now and in_bounds and not is_active:
			_activate()
		elif not pressed_now and is_active:
			_deactivate()

# =============================================================================
# PRIVATE METHODS
# =============================================================================

func _is_desktop_platform() -> bool:
	## Returns true for platforms where right-click is available
	var os_name := OS.get_name()
	# Web, Windows, macOS, Linux = desktop (right-click available)
	return os_name in ["Web", "Windows", "macOS", "Linux", "FreeBSD"]


func _activate() -> void:
	is_active = true
	text = ICON_ACTIVE
	_update_appearance()
	circle_mode_changed.emit(true)


func _deactivate() -> void:
	is_active = false
	text = ICON_INACTIVE
	_update_appearance()
	circle_mode_changed.emit(false)


func _update_appearance() -> void:
	var bg_color := COLOR_ACTIVE if is_active else COLOR_INACTIVE
	var text_color := Color.WHITE if is_active else Color(0.7, 0.75, 0.8)

	# Create stylebox
	var style := StyleBoxFlat.new()
	style.bg_color = bg_color
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	style.content_margin_left = 8
	style.content_margin_right = 8
	style.content_margin_top = 8
	style.content_margin_bottom = 8

	add_theme_stylebox_override("normal", style)
	add_theme_stylebox_override("hover", style)
	add_theme_stylebox_override("pressed", style)
	add_theme_stylebox_override("disabled", style)

	# Remove focus outline
	var focus_style := StyleBoxEmpty.new()
	add_theme_stylebox_override("focus", focus_style)

	# Text styling
	add_theme_color_override("font_color", text_color)
	add_theme_color_override("font_hover_color", text_color)
	add_theme_color_override("font_pressed_color", text_color)
	add_theme_font_size_override("font_size", 32)
