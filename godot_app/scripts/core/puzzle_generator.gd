class_name PuzzleGenerator
extends RefCounted
## Generates deterministic single-solution puzzles.
##
## Multi-solution generation was removed because the game is highly
## deterministic about which cells must be deleted, making "choice"
## operators (keep corners, keep 7s, etc.) frustrating rather than fun.

# Maximum solutions to count before giving up (for performance).
# Higher = more accurate solution counting but slower generation.
const MAX_SOLUTION_COUNT = 50

# How many times to retry generating a valid puzzle before falling back.
# Higher = better chance of ideal puzzle but slower worst-case generation.
const MAX_GENERATION_ATTEMPTS = 100

# Default deletion ratios - what percentage of cells must be deleted to solve.
# MIN_DELETE_RATIO: Lower = easier puzzles (fewer cells to delete)
# MAX_DELETE_RATIO: Higher = harder puzzles (more cells to delete)
# Range creates variety: some puzzles easy (40% deleted), some hard (80% deleted)
const DEFAULT_MIN_DELETE_RATIO = 0.4  # At least 40% of cells must be deleted
const DEFAULT_MAX_DELETE_RATIO = 0.8  # At most 80% of cells must be deleted

# =============================================================================
# MAIN GENERATION API
# =============================================================================

static func generate_single_solution(
	grid_size: Vector2i,
	rng: RandomNumberGenerator,
	min_value: int = 1,
	max_value: int = 9,
	min_delete_ratio: float = DEFAULT_MIN_DELETE_RATIO,
	max_delete_ratio: float = DEFAULT_MAX_DELETE_RATIO
) -> PuzzleState:
	## Generate a puzzle with exactly 1 solution.
	## Cell values will be in range [min_value, max_value], excluding 0.
	## Deletion ratio controls how many cells must be deleted (0.4-0.8 = 40%-80%).

	for _attempt in range(MAX_GENERATION_ATTEMPTS):
		var state = PuzzleState.new(grid_size)

		# Fill with random values in configured range (no zeros)
		for row in range(grid_size.y):
			for col in range(grid_size.x):
				var value = _random_nonzero(rng, min_value, max_value)
				state.get_cell(row, col).value = value

		# Find targets that give exactly 1 solution
		var result = _find_targets_with_solution_count(
			state, 1, 1, rng, min_delete_ratio, max_delete_ratio
		)
		if result != null:
			var analysis = analyze(result)
			print("[PuzzleGenerator] single_solution: %d solutions, diversity %.2f" % [
				analysis.solution_count, analysis.diversity
			])
			return result

	# Fallback: return any valid puzzle
	print("[PuzzleGenerator] single_solution failed, using fallback")
	return _generate_fallback(grid_size, rng, min_value, max_value)


static func _random_nonzero(rng: RandomNumberGenerator, min_val: int, max_val: int) -> int:
	## Generate a random value in [min_val, max_val] but never 0.
	## If range includes 0, skip it.
	if min_val > 0 or max_val < 0:
		# Range doesn't include 0, just return random
		return rng.randi_range(min_val, max_val)

	# Range includes 0 - need to skip it
	# e.g. [-3, 5] has 9 values, we want 8 (excluding 0)
	var value = rng.randi_range(min_val, max_val - 1)
	if value >= 0:
		value += 1  # Shift positive values up to skip 0
	return value


# Multi-solution generation removed - all puzzles are now deterministic.
# See design notes: operators that rewarded keeping specific cells conflicted
# with the deterministic nature of puzzle solving.
#
# static func generate_multi_solution(grid_size, rng) -> PuzzleState:
#     ... removed ...


# Exchange pattern helpers removed (were only used by multi-solution generation)


static func _find_targets_with_solution_count(
	state: PuzzleState,
	min_solutions: int,
	max_solutions: int,
	rng: RandomNumberGenerator,
	min_delete_ratio: float = DEFAULT_MIN_DELETE_RATIO,
	max_delete_ratio: float = DEFAULT_MAX_DELETE_RATIO
) -> PuzzleState:
	## Find targets that give solution count in [min, max] range.

	var grid_size = state.grid_size

	# Convert delete ratios to keep ratios
	var min_keep_ratio = 1.0 - max_delete_ratio  # 0.2 (keep 20% = delete 80%)
	var max_keep_ratio = 1.0 - min_delete_ratio  # 0.6 (keep 60% = delete 40%)

	for _attempt in range(50):
		# Pick a random keep ratio within the configured range
		var keep_ratio = rng.randf_range(min_keep_ratio, max_keep_ratio)
		var keep_set: Dictionary = {}

		for row in range(grid_size.y):
			for col in range(grid_size.x):
				if rng.randf() < keep_ratio:
					keep_set[Vector2i(col, row)] = true

		# Ensure at least one cell per row and column
		for row in range(grid_size.y):
			var has_cell = false
			for col in range(grid_size.x):
				if keep_set.has(Vector2i(col, row)):
					has_cell = true
					break
			if not has_cell:
				keep_set[Vector2i(rng.randi_range(0, grid_size.x - 1), row)] = true

		for col in range(grid_size.x):
			var has_cell = false
			for row in range(grid_size.y):
				if keep_set.has(Vector2i(col, row)):
					has_cell = true
					break
			if not has_cell:
				keep_set[Vector2i(col, rng.randi_range(0, grid_size.y - 1))] = true

		# Calculate targets from keep-set
		for row in range(grid_size.y):
			var row_sum = 0
			for col in range(grid_size.x):
				if keep_set.has(Vector2i(col, row)):
					row_sum += state.get_cell(row, col).value
			state.row_targets[row] = row_sum

		for col in range(grid_size.x):
			var col_sum = 0
			for row in range(grid_size.y):
				if keep_set.has(Vector2i(col, row)):
					col_sum += state.get_cell(row, col).value
			state.col_targets[col] = col_sum

		# Reject if any row/column starts satisfied (trivial puzzle)
		if _has_satisfied_target_at_start(state):
			continue

		# Count solutions
		var solution_count = count_solutions(state, max_solutions + 1)

		if solution_count >= min_solutions and solution_count <= max_solutions:
			state.puzzle_seed = rng.randi()
			return state

	return null


static func _has_satisfied_target_at_start(state: PuzzleState) -> bool:
	## Check if any row or column has its target already satisfied
	## when all cells are ACTIVE. This would make the puzzle trivial.

	# Check rows
	for row in range(state.grid_size.y):
		var row_sum = 0
		for col in range(state.grid_size.x):
			row_sum += state.get_cell(row, col).value
		if row_sum == state.row_targets[row]:
			return true

	# Check columns
	for col in range(state.grid_size.x):
		var col_sum = 0
		for row in range(state.grid_size.y):
			col_sum += state.get_cell(row, col).value
		if col_sum == state.col_targets[col]:
			return true

	return false


static func _generate_fallback(
	grid_size: Vector2i,
	rng: RandomNumberGenerator,
	min_value: int = 1,
	max_value: int = 9
) -> PuzzleState:
	## Generate any valid puzzle as fallback.
	var config = PuzzleLogic.PuzzleConfig.new()
	config.grid_size = grid_size
	config.min_cell_value = min_value
	config.max_cell_value = max_value
	config.puzzle_seed = rng.randi()
	return PuzzleLogic.generate_puzzle(config)


# =============================================================================
# SOLUTION COUNTING
# =============================================================================

static func count_solutions(state: PuzzleState, max_count: int = MAX_SOLUTION_COUNT) -> int:
	## Count valid solutions. Stops early if exceeding max_count.

	var grid_size = state.grid_size

	# Build list of non-deleted cells per row
	var rows_cells: Array = []
	for row in range(grid_size.y):
		var row_cells: Array = []
		for col in range(grid_size.x):
			var cell = state.get_cell(row, col)
			if cell.state != PuzzleState.CellState.DELETED:
				row_cells.append({"col": col, "value": cell.value})
		rows_cells.append(row_cells)

	# Precompute valid subsets per row
	var row_valid_subsets: Array = []
	for row in range(grid_size.y):
		var subsets = _find_subsets_with_sum(rows_cells[row], state.row_targets[row])
		if subsets.is_empty():
			return 0
		row_valid_subsets.append(subsets)

	# Count via backtracking
	var col_sums: Array[int] = []
	col_sums.resize(grid_size.x)
	col_sums.fill(0)

	var count_ref = {"count": 0, "max": max_count}
	_count_backtrack(state, row_valid_subsets, 0, col_sums, count_ref)
	return count_ref.count


static func _find_subsets_with_sum(cells: Array, target: int) -> Array:
	## Find all subsets of cells that sum to exactly target.

	var results: Array = []
	_find_subsets_recursive(cells, target, 0, [], 0, results)
	return results


static func _find_subsets_recursive(
	cells: Array, target: int, index: int,
	current: Array, current_sum: int, results: Array
) -> void:
	if current_sum == target:
		results.append(current.duplicate())
		return  # Values are 1-9, no point continuing

	if index >= cells.size() or current_sum > target:
		return

	# Include cell
	var cell = cells[index]
	current.append(cell.col)
	_find_subsets_recursive(cells, target, index + 1, current, current_sum + cell.value, results)
	current.pop_back()

	# Exclude cell
	_find_subsets_recursive(cells, target, index + 1, current, current_sum, results)


static func _count_backtrack(
	state: PuzzleState, row_subsets: Array, row: int,
	col_sums: Array[int], count_ref: Dictionary
) -> void:

	if count_ref.count >= count_ref.max:
		return

	if row >= state.grid_size.y:
		for col in range(state.grid_size.x):
			if col_sums[col] != state.col_targets[col]:
				return
		count_ref.count += 1
		return

	for subset in row_subsets[row]:
		# Add subset to column sums
		for col in subset:
			col_sums[col] += state.get_cell(row, col).value

		# Prune if any column exceeds target
		var valid = true
		for col in range(state.grid_size.x):
			if col_sums[col] > state.col_targets[col]:
				valid = false
				break

		if valid:
			_count_backtrack(state, row_subsets, row + 1, col_sums, count_ref)

		# Backtrack
		for col in subset:
			col_sums[col] -= state.get_cell(row, col).value

		if count_ref.count >= count_ref.max:
			return


# =============================================================================
# ANALYSIS UTILITIES
# =============================================================================

static func analyze(state: PuzzleState) -> Dictionary:
	## Analyze a puzzle's solution count and properties.

	var solution_count = count_solutions(state, MAX_SOLUTION_COUNT)

	# Calculate value diversity
	var value_counts: Dictionary = {}
	var total = state.grid_size.x * state.grid_size.y
	for row in range(state.grid_size.y):
		for col in range(state.grid_size.x):
			var v = state.get_cell(row, col).value
			value_counts[v] = value_counts.get(v, 0) + 1

	var unique_values = value_counts.size()
	var diversity = float(unique_values) / mini(total, 9)

	return {
		"solution_count": solution_count,
		"capped": solution_count >= MAX_SOLUTION_COUNT,
		"diversity": diversity,
		"unique_values": unique_values,
		"grid_size": state.grid_size,
	}


static func find_all_solutions(state: PuzzleState, max_solutions: int = 10) -> Array:
	## Find and return all solutions (up to max_solutions).

	var solutions: Array = []
	var grid_size = state.grid_size

	var rows_cells: Array = []
	for row in range(grid_size.y):
		var row_cells: Array = []
		for col in range(grid_size.x):
			var cell = state.get_cell(row, col)
			if cell.state != PuzzleState.CellState.DELETED:
				row_cells.append({"col": col, "value": cell.value})
		rows_cells.append(row_cells)

	var row_valid_subsets: Array = []
	for row in range(grid_size.y):
		var subsets = _find_subsets_with_sum(rows_cells[row], state.row_targets[row])
		if subsets.is_empty():
			return solutions
		row_valid_subsets.append(subsets)

	var col_sums: Array[int] = []
	col_sums.resize(grid_size.x)
	col_sums.fill(0)

	var current_solution: Array = []
	_find_all_backtrack(
		state, row_valid_subsets, 0, col_sums,
		current_solution, solutions, max_solutions
	)

	# Convert to position arrays
	var result: Array = []
	for solution in solutions:
		var positions: Array[Vector2i] = []
		for row in range(solution.size()):
			for col in solution[row]:
				positions.append(Vector2i(col, row))
		result.append(positions)

	return result


static func _find_all_backtrack(
	state: PuzzleState, row_subsets: Array, row: int,
	col_sums: Array[int], current_solution: Array,
	solutions: Array, max_solutions: int
) -> void:

	if solutions.size() >= max_solutions:
		return

	if row >= state.grid_size.y:
		for col in range(state.grid_size.x):
			if col_sums[col] != state.col_targets[col]:
				return
		solutions.append(current_solution.duplicate(true))
		return

	for subset in row_subsets[row]:
		for col in subset:
			col_sums[col] += state.get_cell(row, col).value

		var valid = true
		for col in range(state.grid_size.x):
			if col_sums[col] > state.col_targets[col]:
				valid = false
				break

		if valid:
			current_solution.append(subset)
			_find_all_backtrack(
				state, row_subsets, row + 1, col_sums,
				current_solution, solutions, max_solutions
			)
			current_solution.pop_back()

		for col in subset:
			col_sums[col] -= state.get_cell(row, col).value

		if solutions.size() >= max_solutions:
			return
