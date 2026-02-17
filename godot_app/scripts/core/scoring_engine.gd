class_name ScoringEngine
extends RefCounted
## Calculates puzzle ratings with pace-based formula.
## Formula: rating = (12 - time/cells) + clean_bonus + operators
## Money = rating³ / 100 × streak_mult

# =============================================================================
# RATING BREAKDOWN (new pace-based system)
# =============================================================================

class RatingBreakdown:
	# Time & pace
	var time_used: float = 0.0
	var cell_count: int = 0
	var pace: float = 0.0  # seconds per cell
	var pace_rating: float = 0.0  # RATING_BASE - pace

	# Clean solve bonus
	var misstep_count: int = 0
	var clean_bonus: float = 0.0

	# Operators
	var operator_score_total: int = 0  # Raw score from operators
	var operator_rating_bonus: float = 0.0  # Converted to rating
	var operator_details: Array = []  # [{name: String, bonus: int}]

	# Final rating & grade
	var total_rating: float = 0.0
	var grade: String = "D"

	# Money calculation
	var base_money: int = 0  # rating³ / 100
	var streak: int = 0
	var streak_mult: float = 1.0
	var final_money: int = 0

	func get_summary() -> String:
		return "Pace %.1fs/cell | Rating %.1f | %s | $%d" % [pace, total_rating, grade, final_money]


# Legacy class for backwards compatibility
class ScoreBreakdown:
	var base_points: int = 0
	var kept_bonus: int = 0
	var kept_count: int = 0
	var total_cells: int = 0
	var deleted_count: int = 0
	var subtotal: int = 0
	var time_multiplier: float = 1.0
	var final_score: int = 0
	var operator_bonus: int = 0
	var operator_mult: float = 1.0
	var money_bonus: int = 0
	var operator_details: Array = []
	var par_score: int = 0
	var grade: String = "D"
	var grade_mult: float = 1.0
	var grade_bonus: int = 0

	func get_summary() -> String:
		return "Score %d [%s]" % [final_score, grade]

# =============================================================================
# PACE RATING CALCULATION
# =============================================================================

static func calculate_rating(
	puzzle: PuzzleState,
	time_used: float,
	operators: Array,
	streak: int
) -> RatingBreakdown:
	var breakdown = RatingBreakdown.new()

	# Time & pace
	breakdown.time_used = time_used
	breakdown.cell_count = puzzle.grid_size.x * puzzle.grid_size.y
	breakdown.pace = time_used / breakdown.cell_count if breakdown.cell_count > 0 else 0.0
	breakdown.pace_rating = GameConfig.RATING_BASE - breakdown.pace

	# Clean bonus (missteps reduce it)
	breakdown.misstep_count = puzzle.misstep_count
	breakdown.clean_bonus = GameConfig.get_clean_bonus(breakdown.misstep_count)

	# Process operators (same hooks as before, but convert to rating)
	var op_score_total := 0
	for op in operators:
		var op_bonus := 0

		# Cell hooks
		for row in range(puzzle.grid_size.y):
			for col in range(puzzle.grid_size.x):
				var cell = puzzle.get_cell(row, col)
				if cell.state != PuzzleState.CellState.DELETED:
					var result = op.on_cell_kept(row, col, cell.value, puzzle)
					op_bonus += result.get("score_bonus", 0)

		# Row hooks
		for row in range(puzzle.grid_size.y):
			if puzzle.get_current_row_sum(row) == puzzle.row_targets[row]:
				var result = op.on_row_complete(row, puzzle)
				op_bonus += result.get("score_bonus", 0)

		# Column hooks
		for col in range(puzzle.grid_size.x):
			if puzzle.get_current_col_sum(col) == puzzle.col_targets[col]:
				var result = op.on_col_complete(col, puzzle)
				op_bonus += result.get("score_bonus", 0)

		# End hook
		var end_result = op.on_puzzle_end(puzzle)
		op_bonus += end_result.get("score_bonus", 0)

		if op_bonus > 0:
			breakdown.operator_details.append({
				"name": op.display_name,
				"bonus": op_bonus
			})
			EventBus.operator_triggered.emit(op.id, op_bonus)

		op_score_total += op_bonus

	breakdown.operator_score_total = op_score_total
	breakdown.operator_rating_bonus = op_score_total / GameConfig.OPERATOR_RATING_DIVISOR

	# Total rating
	breakdown.total_rating = breakdown.pace_rating + breakdown.clean_bonus + breakdown.operator_rating_bonus

	# Grade from rating
	breakdown.grade = GameConfig.get_grade_from_rating(breakdown.total_rating)

	# Money calculation: rating³ / 100
	breakdown.base_money = int(round(pow(maxf(0.0, breakdown.total_rating), 3) / 100.0))

	# Streak multiplier
	breakdown.streak = streak
	breakdown.streak_mult = GameConfig.get_streak_multiplier(streak)
	breakdown.final_money = int(round(breakdown.base_money * breakdown.streak_mult))

	return breakdown


# =============================================================================
# LEGACY SCORING (kept for backwards compatibility)
# =============================================================================

## Calculate the "par score" - expected score for perfect solve.
static func calculate_par_score(puzzle: PuzzleState) -> int:
	var dim = puzzle.grid_size.x
	var solution_cells = puzzle.get_solution_cell_count()
	var base = dim * dim * GameConfig.BASE_POINTS_PER_CELL
	var kept = solution_cells * GameConfig.KEPT_BONUS_PER_CELL
	return base + kept

# =============================================================================
# LEGACY SCORE CALCULATION (deprecated, use calculate_rating instead)
# =============================================================================

static func calculate_score(
	puzzle: PuzzleState,
	time_mult: float = 1.0,
	operators: Array = []
) -> ScoreBreakdown:
	## Deprecated: Use calculate_rating() for new code.
	## Kept for backwards compatibility with tests.
	var breakdown = ScoreBreakdown.new()
	var dim = puzzle.grid_size.x

	breakdown.base_points = dim * dim * GameConfig.BASE_POINTS_PER_CELL
	breakdown.total_cells = puzzle.grid_size.x * puzzle.grid_size.y
	breakdown.kept_count = puzzle.get_kept_count()
	breakdown.deleted_count = breakdown.total_cells - breakdown.kept_count
	breakdown.kept_bonus = breakdown.kept_count * GameConfig.KEPT_BONUS_PER_CELL
	breakdown.subtotal = breakdown.base_points + breakdown.kept_bonus
	breakdown.time_multiplier = time_mult

	# Process operators
	var op_score_bonus := 0
	var op_mult_bonus := 0.0
	var op_money_bonus := 0

	for op in operators:
		var op_total := 0
		for row in range(puzzle.grid_size.y):
			for col in range(puzzle.grid_size.x):
				var cell = puzzle.get_cell(row, col)
				if cell.state != PuzzleState.CellState.DELETED:
					var result = op.on_cell_kept(row, col, cell.value, puzzle)
					op_total += result.get("score_bonus", 0)
					op_mult_bonus += result.get("mult_bonus", 0.0)
		for row in range(puzzle.grid_size.y):
			if puzzle.get_current_row_sum(row) == puzzle.row_targets[row]:
				var result = op.on_row_complete(row, puzzle)
				op_total += result.get("score_bonus", 0)
				op_mult_bonus += result.get("mult_bonus", 0.0)
		for col in range(puzzle.grid_size.x):
			if puzzle.get_current_col_sum(col) == puzzle.col_targets[col]:
				var result = op.on_col_complete(col, puzzle)
				op_total += result.get("score_bonus", 0)
				op_mult_bonus += result.get("mult_bonus", 0.0)
		var end_result = op.on_puzzle_end(puzzle)
		op_total += end_result.get("score_bonus", 0)
		op_mult_bonus += end_result.get("mult_bonus", 0.0)
		op_money_bonus += end_result.get("money_bonus", 0)
		if op_total > 0:
			breakdown.operator_details.append({"name": op.display_name, "bonus": op_total})
			EventBus.operator_triggered.emit(op.id, op_total)
		op_score_bonus += op_total

	breakdown.operator_bonus = op_score_bonus
	breakdown.operator_mult = 1.0 + op_mult_bonus
	breakdown.money_bonus = op_money_bonus

	var score_before_mult = breakdown.subtotal + breakdown.operator_bonus
	var total_mult = breakdown.time_multiplier * breakdown.operator_mult
	breakdown.final_score = int(score_before_mult * total_mult)
	breakdown.par_score = calculate_par_score(puzzle)

	# Use rating-based grade for backwards compatibility
	var time_used = 30.0  # Estimate, doesn't matter much for legacy
	var cell_count = breakdown.total_cells
	var estimated_rating = GameConfig.RATING_BASE - (time_used / cell_count)
	breakdown.grade = GameConfig.get_grade_from_rating(estimated_rating)
	breakdown.grade_mult = 1.0
	breakdown.grade_bonus = 0

	return breakdown
