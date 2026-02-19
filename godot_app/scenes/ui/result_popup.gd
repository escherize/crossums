extends Control
## Result popup shown after completing a puzzle.
## Shows animated score breakdown in Balatro style.

signal continue_pressed

# =============================================================================
# CONSTANTS
# =============================================================================

const STEP_DELAY := 1.2  # Seconds between breakdown steps
const COUNTUP_DURATION := 0.8  # Seconds for number countup animation

# Grade colors
const GRADE_COLORS := {
	"D": Color(0.53, 0.53, 0.53),     # Gray
	"C": Color(1.0, 1.0, 1.0),         # White
	"B": Color(0.53, 1.0, 0.53),       # Green
	"A": Color(0.53, 0.8, 1.0),        # Blue
	"S": Color(1.0, 0.84, 0.0),        # Gold
	"SS": Color(1.0, 0.4, 0.8)         # Pink/magenta (rainbow effect would need shader)
}

# =============================================================================
# STATE
# =============================================================================

var _breakdown = null  # ScoringEngine.ScoreBreakdown or RatingBreakdown
var _animation_complete := false
var _skip_requested := false
var _current_tween: Tween = null
var _is_rating_mode := false  # true for new rating system, false for legacy

# =============================================================================
# NODE REFERENCES
# =============================================================================

@onready var result_label: Label = %ResultLabel
@onready var grade_label: Label = %GradeLabel
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
		if _is_rating_mode:
			_show_final_rating_state(_breakdown)
		else:
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
	_is_rating_mode = false

	# Setup header
	if won:
		result_label.text = "PASS!"
		result_label.add_theme_color_override("font_color", Color(0.4, 0.9, 0.4))
	else:
		result_label.text = "FAIL"
		result_label.add_theme_color_override("font_color", Color(0.9, 0.4, 0.4))

	# Setup grade display
	var grade: String = breakdown.grade if breakdown else "B"
	grade_label.text = grade
	var grade_color = GRADE_COLORS.get(grade, Color.WHITE)
	grade_label.add_theme_color_override("font_color", grade_color)
	grade_label.visible = won  # Only show grade on win

	# Hide par score - grade now includes time, so grade IS the comparison
	target_label.visible = false

	# Build reward text showing super-linear formula: (base + bonus) × mult = total
	if reward > 0 and breakdown:
		var base_money: int = int(breakdown.final_score / GameConfig.SCORE_TO_MONEY_DIVISOR)
		var grade_mult: float = breakdown.grade_mult
		var grade_bonus: int = breakdown.grade_bonus
		var grade_str: String = breakdown.grade

		# Super-linear format: ($1 + $2) × 2.5 = +$7
		if grade_mult != 1.0 or grade_bonus > 0:
			if grade_bonus > 0:
				reward_label.text = "($%d + $%d) × %.1f = +$%d" % [base_money, grade_bonus, grade_mult, reward]
			else:
				reward_label.text = "$%d × %.1f = +$%d" % [base_money, grade_mult, reward]
		else:
			reward_label.text = "+$%d" % reward
	else:
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
	## Reveal pre-created breakdown lines one by one.
	## Uses pre-calculated display values to match actual scoring formula.
	var display_values = _calculate_display_values()
	var children = breakdown_container.get_children()

	for i in range(steps.size()):
		if _skip_requested:
			break

		var step = steps[i]
		var line = children[i] if i < children.size() else null

		# Trigger operator card animation if this step has an operator_id
		var op_id: String = step.get("operator_id", "")
		if op_id:
			EventBus.operator_triggered.emit(op_id, step.get("value", 0))

		if line:
			# Animate the line appearing
			_current_tween = create_tween()
			_current_tween.tween_property(line, "modulate:a", 1.0, 0.2)

		# Animate to the correct display value for this step
		if i < display_values.size():
			_animate_total(display_values[i])

		await get_tree().create_timer(STEP_DELAY).timeout

		if _skip_requested:
			break

	if not _skip_requested:
		_show_final_state()


func _calculate_display_values() -> Array[int]:
	## Pre-calculate correct display values at each animation step.
	## Must match the actual scoring formula in ScoringEngine.
	var b = _breakdown
	var values: Array[int] = []

	# Phase 1: Base and kept bonus
	var subtotal = b.base_points
	values.append(subtotal)  # After base

	if b.kept_bonus > 0:
		subtotal += b.kept_bonus
		values.append(subtotal)  # After kept bonus

	# Phase 2: Operator bonuses added
	var score_with_ops = subtotal
	for op_detail in b.operator_details:
		score_with_ops += op_detail.bonus
		values.append(score_with_ops)  # After each operator bonus

	# Phase 3: Operator multiplier (if not 1.0)
	var current_mult = 1.0
	if b.operator_mult != 1.0:
		current_mult *= b.operator_mult
		values.append(int(score_with_ops * current_mult))

	# Phase 4: Time multiplier
	if b.time_multiplier != 1.0:
		current_mult *= b.time_multiplier
		values.append(int(score_with_ops * current_mult))

	return values


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
			"text": "+%d kept bonus" % b.kept_bonus,
			"type": "add",
			"value": b.kept_bonus,
			"apply_mult": false,
			"color": Color(0.5, 0.8, 1.0)  # Light blue
		})

	# 3. Operator bonuses (show each individually)
	for op_detail in b.operator_details:
		steps.append({
			"text": "+%d %s" % [op_detail.bonus, op_detail.name],
			"type": "add",
			"value": op_detail.bonus,
			"apply_mult": true,
			"color": Color(0.8, 0.5, 1.0),  # Purple
			"operator_id": op_detail.get("operator_id", "")
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

	# 6. Time multiplier (speed bonus)
	if b.time_multiplier != 1.0:
		var time_color = Color(0.4, 0.9, 0.9) if b.time_multiplier >= 1.5 else Color(0.7, 0.7, 0.7)
		var speed_label: String
		if b.time_multiplier >= 1.8:
			speed_label = "×%.2f speed (fast!)" % b.time_multiplier
		elif b.time_multiplier >= 1.5:
			speed_label = "×%.2f speed (good)" % b.time_multiplier
		else:
			speed_label = "×%.2f speed" % b.time_multiplier
		steps.append({
			"text": speed_label,
			"type": "mult",
			"value": b.time_multiplier,
			"apply_mult": true,
			"color": time_color
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

	# Color based on perfect score
	var target_val = int(target_label.text.replace("Perfect: ", ""))
	if _breakdown.final_score >= target_val:
		running_total_label.add_theme_color_override("font_color", Color(0.4, 0.9, 0.4))
	else:
		running_total_label.add_theme_color_override("font_color", Color(0.9, 0.4, 0.4))

	# Show reward
	reward_label.visible = true

	# Update button
	continue_button.text = "Continue"


# =============================================================================
# PACE RATING DISPLAY (new system)
# =============================================================================

func show_result_rating(won: bool, breakdown) -> void:
	## Show result popup with pace rating breakdown.
	## breakdown: ScoringEngine.RatingBreakdown
	_breakdown = breakdown
	_animation_complete = false
	_skip_requested = false
	_is_rating_mode = true

	# Setup header
	if won:
		result_label.text = "PASS!"
		result_label.add_theme_color_override("font_color", Color(0.4, 0.9, 0.4))
	else:
		result_label.text = "FAIL"
		result_label.add_theme_color_override("font_color", Color(0.9, 0.4, 0.4))

	# Setup grade display
	var grade: String = breakdown.grade
	grade_label.text = grade
	var grade_color = GRADE_COLORS.get(grade, Color.WHITE)
	grade_label.add_theme_color_override("font_color", grade_color)
	grade_label.visible = won

	# Hide old target label
	target_label.visible = false

	# Hide reward label initially (shown at end with streak if applicable)
	reward_label.visible = false

	# Clear previous breakdown
	for child in breakdown_container.get_children():
		child.queue_free()

	# Build and show pace rating breakdown
	var steps = _build_rating_steps(breakdown)
	_precreate_breakdown_lines(steps)

	# Initialize running total with rating
	running_total_label.text = "0.0"
	running_total_label.add_theme_color_override("font_color", Color.WHITE)

	continue_button.text = "Skip"
	visible = true

	# Animate the breakdown
	_animate_rating_reveal(breakdown, steps)


func _build_rating_steps(b) -> Array:
	## Build breakdown steps for pace rating display (educational format)
	var steps: Array = []

	# 1. Pace and base rating
	steps.append({
		"text": "PACE: %.2f sec/cell" % b.pace,
		"color": Color(0.4, 0.9, 0.9) if b.pace < 1.5 else Color.WHITE
	})
	steps.append({
		"text": "Rating: %.1f" % b.pace_rating,
		"color": Color.WHITE
	})
	steps.append({"text": "───────────", "color": Color(0.5, 0.5, 0.5)})

	# 2. Missteps and clean bonus
	if b.misstep_count == 0:
		steps.append({"text": "Zero missteps!", "color": Color(0.5, 1.0, 0.5)})
		steps.append({"text": "Clean bonus: + 2", "color": Color(0.5, 1.0, 0.5)})
	else:
		steps.append({
			"text": "%d misstep%s" % [b.misstep_count, "s" if b.misstep_count > 1 else ""],
			"color": Color(0.8, 0.8, 0.5) if b.misstep_count <= 2 else Color(0.6, 0.6, 0.6)
		})
		if b.clean_bonus > 0:
			steps.append({
				"text": "Clean bonus: + %.1f" % b.clean_bonus,
				"color": Color(0.8, 0.8, 0.5)
			})
		else:
			steps.append({"text": "Clean bonus: 0", "color": Color(0.6, 0.6, 0.6)})
	steps.append({"text": "───────────", "color": Color(0.5, 0.5, 0.5)})

	# 3. Operator bonus
	if b.operator_rating_bonus > 0:
		for op_detail in b.operator_details:
			steps.append({
				"text": "%s: + %.1f" % [op_detail.name, op_detail.bonus / 50.0],
				"color": Color(0.8, 0.5, 1.0),
				"operator_id": op_detail.get("operator_id", "")
			})
	else:
		steps.append({"text": "Operator bonus: 0", "color": Color(0.6, 0.6, 0.6)})
	steps.append({"text": "───────────", "color": Color(0.5, 0.5, 0.5)})

	# 4. Total rating calculation
	var parts: Array[String] = []
	parts.append("%.1f" % b.pace_rating)
	if b.clean_bonus > 0:
		parts.append("%.1f" % b.clean_bonus)
	if b.operator_rating_bonus > 0:
		parts.append("%.1f" % b.operator_rating_bonus)
	var formula: String = " + ".join(parts) + " = %.1f" % b.total_rating
	steps.append({"text": "Total Rating:", "color": Color.WHITE})
	steps.append({"text": formula, "color": Color(1.0, 0.9, 0.4)})
	steps.append({"text": "───────────", "color": Color(0.5, 0.5, 0.5)})

	# 5. Money calculation
	var money_formula: String = "round(%.1f³ / %d) = $%d" % [b.total_rating, int(GameConfig.MONEY_DIVISOR), b.base_money]
	steps.append({"text": money_formula, "color": Color(0.4, 0.9, 0.4)})

	return steps


func _get_pace_stars(pace: float) -> String:
	## Convert pace to star rating (0-10 stars)
	var rating := clampf(10.0 - pace, 0.0, 10.0)
	var full_stars := int(rating)
	var stars := "★".repeat(full_stars) + "☆".repeat(10 - full_stars)
	return stars


func _animate_rating_reveal(b, steps: Array) -> void:
	## Animate the pace rating breakdown reveal
	var children = breakdown_container.get_children()

	# Hide running total during animation (we show full breakdown instead)
	running_total_label.visible = false

	for i in range(steps.size()):
		if _skip_requested:
			break

		var step = steps[i]
		var line = children[i] if i < children.size() else null

		# Trigger operator card animation if this step has an operator_id
		var op_id: String = step.get("operator_id", "")
		if op_id:
			EventBus.operator_triggered.emit(op_id, 0)

		if line:
			_current_tween = create_tween()
			_current_tween.tween_property(line, "modulate:a", 1.0, 0.2)

		# Faster reveal for separator lines
		var is_separator: bool = step.text.begins_with("───")
		var delay: float = STEP_DELAY * 0.3 if is_separator else STEP_DELAY * 0.5

		await get_tree().create_timer(delay).timeout

		if _skip_requested:
			break

	if not _skip_requested:
		_show_final_rating_state(b)


func _animate_rating_total(target: float) -> void:
	## Animate the rating number
	var current_text := running_total_label.text
	var current := float(current_text) if current_text.is_valid_float() else 0.0

	if _skip_requested:
		running_total_label.text = "%.1f" % target
		return

	_current_tween = create_tween()
	_current_tween.tween_method(
		func(val: float): running_total_label.text = "%.1f" % val,
		current,
		target,
		COUNTUP_DURATION
	).set_ease(Tween.EASE_OUT)


func _show_final_rating_state(b) -> void:
	## Show final rating state
	_animation_complete = true

	# Clear and rebuild
	for child in breakdown_container.get_children():
		child.queue_free()

	var steps = _build_rating_steps(b)
	for step in steps:
		var line = _create_breakdown_line(step.text, step.color)
		breakdown_container.add_child(line)

	# Show final money as the BIG number
	running_total_label.visible = true
	var streak_broken: bool = b.misstep_count >= GameConfig.STREAK_MISSTEP_THRESHOLD

	if streak_broken:
		# Streak broken due to missteps - show warning
		running_total_label.text = "+$%d" % b.final_money
		reward_label.text = "Streak broken!"
		reward_label.add_theme_color_override("font_color", Color(0.9, 0.5, 0.5))
		reward_label.visible = true
	elif b.streak_mult > 1.0:
		# With streak: show multiplied result
		var streak_flames: String = "🔥".repeat(mini(b.streak, 5))
		running_total_label.text = "+$%d" % b.final_money
		reward_label.text = "$%d × %.1f %s" % [b.base_money, b.streak_mult, streak_flames]
		reward_label.add_theme_color_override("font_color", Color(1.0, 0.6, 0.2))
		reward_label.visible = true
	else:
		# No streak: just show the money
		running_total_label.text = "+$%d" % b.final_money
		reward_label.visible = false

	# Color based on grade
	var grade_color = GRADE_COLORS.get(b.grade, Color.WHITE)
	running_total_label.add_theme_color_override("font_color", grade_color)

	continue_button.text = "Continue"
