class_name ScoringEngine
extends RefCounted
## Calculates puzzle scores with Balatro-inspired breakdown.
## All tunable constants are in GameConfig for easy modification by operators.

# =============================================================================
# SCORE BREAKDOWN
# =============================================================================

class ScoreBreakdown:
	var base_points: int = 0
	var kept_bonus: int = 0
	var kept_count: int = 0
	var total_cells: int = 0
	var deleted_count: int = 0
	var valid_lines: int = 0  # Rows + columns that hit target
	var total_lines: int = 0
	var line_multiplier: float = 1.0
	var subtotal: int = 0  # Before multiplier
	var line_score: int = 0  # After line multiplier, before time/precision
	var time_multiplier: float = 1.0
	var precision_multiplier: float = 1.0
	var restore_count: int = 0
	var final_score: int = 0
	# Operator bonuses (Sprint 2)
	var operator_bonus: int = 0
	var operator_mult: float = 1.0
	var operator_details: Array = []  # [{name: String, bonus: int}]

	func get_summary() -> String:
		var parts: Array[String] = []
		parts.append("Kept %d/%d" % [kept_count, total_cells])
		parts.append("%.1fx line" % line_multiplier)
		if operator_bonus > 0:
			parts.append("+%d ops" % operator_bonus)
		if operator_mult != 1.0:
			parts.append("%.1fx ops" % operator_mult)
		if time_multiplier != 1.0:
			parts.append("%.1fx time" % time_multiplier)
		if precision_multiplier != 1.0:
			parts.append("%.1fx precision" % precision_multiplier)
		return " | ".join(parts)

# =============================================================================
# CONSTANTS (all values come from GameConfig for easy tuning)
# =============================================================================

# =============================================================================
# SCORING
# =============================================================================

static func calculate_score(
	puzzle: PuzzleState,
	time_mult: float = 1.0,
	restore_count: int = 0,
	operators: Array = []
) -> ScoreBreakdown:
	var breakdown = ScoreBreakdown.new()
	var grid_size = puzzle.grid_size.x

	# Base points by grid size
	breakdown.base_points = GameConfig.BASE_POINTS.get(grid_size, 100)

	# Cell counts
	breakdown.total_cells = puzzle.grid_size.x * puzzle.grid_size.y
	breakdown.kept_count = puzzle.get_kept_count()
	breakdown.deleted_count = breakdown.total_cells - breakdown.kept_count

	# Kept bonus: per kept number (rewards optimization)
	breakdown.kept_bonus = breakdown.kept_count * GameConfig.KEPT_BONUS_PER_CELL

	# Count valid lines (rows + columns)
	breakdown.total_lines = puzzle.grid_size.x + puzzle.grid_size.y
	breakdown.valid_lines = _count_valid_lines(puzzle)

	# Line multiplier: 1.0 + X per valid line
	breakdown.line_multiplier = 1.0 + (breakdown.valid_lines * GameConfig.LINE_MULT_PER_VALID)

	# Calculate score after line multiplier
	breakdown.subtotal = breakdown.base_points + breakdown.kept_bonus
	breakdown.line_score = int(breakdown.subtotal * breakdown.line_multiplier)

	# Time multiplier (passed in from timer)
	breakdown.time_multiplier = time_mult

	# Precision multiplier based on restore count
	breakdown.restore_count = restore_count
	if restore_count == 0:
		breakdown.precision_multiplier = GameConfig.PRECISION_PERFECT
	elif restore_count <= GameConfig.PRECISION_GOOD_THRESHOLD:
		breakdown.precision_multiplier = GameConfig.PRECISION_GOOD
	else:
		breakdown.precision_multiplier = GameConfig.PRECISION_BASE

	# Process operators (Sprint 2)
	var op_score_bonus := 0
	var op_mult_bonus := 0.0

	for op in operators:
		var op_total := 0

		# Cell hooks - for each kept cell
		for row in range(puzzle.grid_size.y):
			for col in range(puzzle.grid_size.x):
				var cell = puzzle.get_cell(row, col)
				if cell.state != PuzzleState.CellState.DELETED:
					var result = op.on_cell_kept(row, col, cell.value, puzzle)
					op_total += result.get("score_bonus", 0)
					op_mult_bonus += result.get("mult_bonus", 0.0)

		# Row hooks - for each valid row
		for row in range(puzzle.grid_size.y):
			if puzzle.get_current_row_sum(row) == puzzle.row_targets[row]:
				var result = op.on_row_complete(row, puzzle)
				op_total += result.get("score_bonus", 0)
				op_mult_bonus += result.get("mult_bonus", 0.0)

		# Column hooks - for each valid column
		for col in range(puzzle.grid_size.x):
			if puzzle.get_current_col_sum(col) == puzzle.col_targets[col]:
				var result = op.on_col_complete(col, puzzle)
				op_total += result.get("score_bonus", 0)
				op_mult_bonus += result.get("mult_bonus", 0.0)

		# End hook - once per puzzle
		var end_result = op.on_puzzle_end(puzzle)
		op_total += end_result.get("score_bonus", 0)
		op_mult_bonus += end_result.get("mult_bonus", 0.0)

		if op_total > 0:
			breakdown.operator_details.append({
				"name": op.display_name,
				"bonus": op_total
			})
			# Emit trigger signal for UI feedback
			EventBus.operator_triggered.emit(op.id, op_total)

		op_score_bonus += op_total

	breakdown.operator_bonus = op_score_bonus
	breakdown.operator_mult = 1.0 + op_mult_bonus

	# Final score with all multipliers (now including operators)
	var score_before_mult = breakdown.line_score + breakdown.operator_bonus
	var total_mult = breakdown.time_multiplier * breakdown.precision_multiplier * breakdown.operator_mult
	breakdown.final_score = int(score_before_mult * total_mult)

	return breakdown


static func _count_valid_lines(puzzle: PuzzleState) -> int:
	var count := 0

	# Check rows
	for row in range(puzzle.grid_size.y):
		if puzzle.get_current_row_sum(row) == puzzle.row_targets[row]:
			count += 1

	# Check columns
	for col in range(puzzle.grid_size.x):
		if puzzle.get_current_col_sum(col) == puzzle.col_targets[col]:
			count += 1

	return count
