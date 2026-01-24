class_name ScoringEngine
extends RefCounted
## Calculates puzzle scores with Balatro-inspired breakdown.

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
	var final_score: int = 0

	func get_summary() -> String:
		return "Kept %d/%d | Base %d + Kept %d = %d × %.1fx" % [
			kept_count, total_cells, base_points, kept_bonus, subtotal, line_multiplier
		]

# =============================================================================
# CONSTANTS
# =============================================================================

const BASE_POINTS := {
	3: 100,
	4: 200,
	5: 350,
	6: 500,
}

const KEPT_BONUS_PER_CELL := 25
const LINE_MULT_PER_VALID := 0.2

# =============================================================================
# SCORING
# =============================================================================

static func calculate_score(puzzle: PuzzleState) -> ScoreBreakdown:
	var breakdown = ScoreBreakdown.new()
	var grid_size = puzzle.grid_size.x

	# Base points by grid size
	breakdown.base_points = BASE_POINTS.get(grid_size, 100)

	# Cell counts
	breakdown.total_cells = puzzle.grid_size.x * puzzle.grid_size.y
	breakdown.kept_count = puzzle.get_kept_count()
	breakdown.deleted_count = breakdown.total_cells - breakdown.kept_count

	# Kept bonus: +25 per kept number (rewards optimization)
	breakdown.kept_bonus = breakdown.kept_count * KEPT_BONUS_PER_CELL

	# Count valid lines (rows + columns)
	breakdown.total_lines = puzzle.grid_size.x + puzzle.grid_size.y
	breakdown.valid_lines = _count_valid_lines(puzzle)

	# Line multiplier: 1.0 + 0.2 per valid line
	breakdown.line_multiplier = 1.0 + (breakdown.valid_lines * LINE_MULT_PER_VALID)

	# Calculate final
	breakdown.subtotal = breakdown.base_points + breakdown.kept_bonus
	breakdown.final_score = int(breakdown.subtotal * breakdown.line_multiplier)

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
