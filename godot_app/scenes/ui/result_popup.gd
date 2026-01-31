extends Control
## Result popup shown after completing a puzzle.
## Shows animated score breakdown in Balatro style.

signal continue_pressed

# =============================================================================
# CONSTANTS
# =============================================================================

const STEP_DELAY := 1.2  # Seconds between breakdown steps
const COUNTUP_DURATION := 0.8  # Seconds for number countup animation

# =============================================================================
# STATE
# =============================================================================

var _breakdown = null  # ScoringEngine.ScoreBreakdown
var _animation_complete := false
var _skip_requested := false
var _current_tween: Tween = null

# =============================================================================
# NODE REFERENCES
# =============================================================================

@onready var result_label: Label = %ResultLabel
@onready var breakdown_container: VBoxContainer = %BreakdownContainer
@onready var running_total_label: Label = %RunningTotalLabel
@onready var target_label: Label = %TargetLabel
@onready var reward_label: Label = %RewardLabel
@onready var continue_button: Button = %ContinueButton

# =============================================================================
# LIFECYCLE
# =============================================================================

func _ready() -> void:
	continue_button.pressed.connect(_on_continue_pressed)


func _on_continue_pressed() -> void:
	if not _animation_complete:
		# Skip animation
		_skip_requested = true
		if _current_tween:
			_current_tween.kill()
		_show_final_state()
	else:
		continue_pressed.emit()

# =============================================================================
# DISPLAY
# =============================================================================

func show_result(won: bool, breakdown, target: int, reward: int) -> void:
	_breakdown = breakdown
	_animation_complete = false
	_skip_requested = false

	# Setup header
	if won:
		result_label.text = "PASS!"
		result_label.add_theme_color_override("font_color", Color(0.4, 0.9, 0.4))
	else:
		result_label.text = "FAIL"
		result_label.add_theme_color_override("font_color", Color(0.9, 0.4, 0.4))

	# Setup target and reward
	target_label.text = "Target: %d" % target
	reward_label.text = "+$%d" % reward if reward > 0 else ""
	reward_label.visible = false  # Show at end

	# Clear previous breakdown
	for child in breakdown_container.get_children():
		child.queue_free()

	# Pre-create all breakdown lines (hidden) to reserve space
	var steps = _build_breakdown_steps()
	_precreate_breakdown_lines(steps)

	# Initialize running total
	running_total_label.text = "0"
	running_total_label.add_theme_color_override("font_color", Color.WHITE)

	# Button shows "Skip" during animation
	continue_button.text = "Skip"

	visible = true

	# Start breakdown animation
	_animate_breakdown_reveal(steps)


func _precreate_breakdown_lines(steps: Array) -> void:
	## Pre-create all breakdown lines (invisible) to reserve layout space
	for step in steps:
		var line = _create_breakdown_line(step.text, step.color)
		line.modulate.a = 0.0  # Start invisible
		breakdown_container.add_child(line)


func _animate_breakdown_reveal(steps: Array) -> void:
	## Reveal pre-created breakdown lines one by one
	var running_total := 0
	var running_mult := 1.0
	var children = breakdown_container.get_children()

	for i in range(steps.size()):
		if _skip_requested:
			break

		var step = steps[i]
		var line = children[i] if i < children.size() else null

		if line:
			# Animate the line appearing
			_current_tween = create_tween()
			_current_tween.tween_property(line, "modulate:a", 1.0, 0.2)

		# Update running total based on step type
		if step.type == "add":
			running_total += step.value
		elif step.type == "mult":
			running_mult *= step.value
		elif step.type == "set":
			running_total = step.value

		# Animate running total countup
		var display_total: int
		if step.apply_mult:
			display_total = int(running_total * running_mult)
		else:
			display_total = running_total
		_animate_total(display_total)

		await get_tree().create_timer(STEP_DELAY).timeout

		if _skip_requested:
			break

	if not _skip_requested:
		_show_final_state()


func _build_breakdown_steps() -> Array:
	## Build the list of breakdown steps to animate
	var steps: Array = []
	var b = _breakdown

	# 1. Base points
	steps.append({
		"text": "Base: %d" % b.base_points,
		"type": "set",
		"value": b.base_points,
		"apply_mult": false,
		"color": Color.WHITE
	})

	# 2. Kept bonus
	if b.kept_bonus > 0:
		steps.append({
			"text": "+%d cells kept (%d × %d)" % [b.kept_bonus, b.kept_count, GameConfig.KEPT_BONUS_PER_CELL],
			"type": "add",
			"value": b.kept_bonus,
			"apply_mult": false,
			"color": Color(0.5, 0.8, 1.0)  # Light blue
		})

	# 3. Line multiplier
	if b.line_multiplier != 1.0:
		steps.append({
			"text": "×%.1f lines solved (%d/%d)" % [b.line_multiplier, b.valid_lines, b.total_lines],
			"type": "mult",
			"value": b.line_multiplier,
			"apply_mult": true,
			"color": Color(1.0, 0.9, 0.4)  # Gold
		})

	# 4. Operator bonuses (show each individually)
	for op_detail in b.operator_details:
		steps.append({
			"text": "+%d %s" % [op_detail.bonus, op_detail.name],
			"type": "add",
			"value": op_detail.bonus,
			"apply_mult": true,
			"color": Color(0.8, 0.5, 1.0)  # Purple
		})

	# 5. Operator multiplier (if not 1.0)
	if b.operator_mult != 1.0:
		steps.append({
			"text": "×%.1f operators" % b.operator_mult,
			"type": "mult",
			"value": b.operator_mult,
			"apply_mult": true,
			"color": Color(0.8, 0.5, 1.0)  # Purple
		})

	# 6. Time multiplier
	if b.time_multiplier != 1.0:
		var time_color = Color(0.4, 0.9, 0.9) if b.time_multiplier >= 1.5 else Color(0.7, 0.7, 0.7)
		steps.append({
			"text": "×%.2f time" % b.time_multiplier,
			"type": "mult",
			"value": b.time_multiplier,
			"apply_mult": true,
			"color": time_color
		})

	# 7. Precision multiplier
	if b.precision_multiplier != 1.0:
		var precision_text = "×%.2f precision" % b.precision_multiplier
		if b.restore_count == 0:
			precision_text += " (perfect!)"
		var precision_color = Color(0.4, 1.0, 0.4) if b.precision_multiplier >= 1.25 else Color.WHITE
		steps.append({
			"text": precision_text,
			"type": "mult",
			"value": b.precision_multiplier,
			"apply_mult": true,
			"color": precision_color
		})

	return steps


func _create_breakdown_line(text: String, color: Color) -> Label:
	var label = Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 16)
	label.add_theme_color_override("font_color", color)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return label


func _animate_total(target_value: int) -> void:
	## Animate the running total countup
	var current = int(running_total_label.text.replace(",", ""))

	if _skip_requested:
		running_total_label.text = str(target_value)
		return

	_current_tween = create_tween()
	_current_tween.tween_method(
		func(val: int): running_total_label.text = str(val),
		current,
		target_value,
		COUNTUP_DURATION
	).set_ease(Tween.EASE_OUT)


func _show_final_state() -> void:
	## Show the final state immediately (used for skip and end of animation)
	_animation_complete = true

	# Clear and rebuild breakdown instantly
	for child in breakdown_container.get_children():
		child.queue_free()

	var steps = _build_breakdown_steps()
	for step in steps:
		var line = _create_breakdown_line(step.text, step.color)
		breakdown_container.add_child(line)

	# Show final score
	running_total_label.text = str(_breakdown.final_score)

	# Color based on target
	var target_val = int(target_label.text.replace("Target: ", ""))
	if _breakdown.final_score >= target_val:
		running_total_label.add_theme_color_override("font_color", Color(0.4, 0.9, 0.4))
	else:
		running_total_label.add_theme_color_override("font_color", Color(0.9, 0.4, 0.4))

	# Show reward
	reward_label.visible = true

	# Update button
	continue_button.text = "Continue"
