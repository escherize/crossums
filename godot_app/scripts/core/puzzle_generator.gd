class_name PuzzleGenerator
extends RefCounted
## Generates puzzles with two distinct strategies:
##
## 1. Single-solution (boss boards): Random values, ~1 answer, no shuffle
## 2. Multi-solution (normal): Exchange patterns + shuffle for player choice
##
## Exchange patterns use 2x2 regions with uniform rows:
##   [V][V]  where V != W
##   [W][W]  Player can keep {a,d} OR {b,c} - both give same row sums
##
## Pattern count = size - 2 (minimum 1):
##   3x3: 1 pattern → 2 solutions
##   4x4: 2 patterns → 4 solutions
##   5x5: 3 patterns → 8 solutions
##   6x6: 4 patterns → 16 solutions
##
## After creating patterns, shuffle disperses them across the board.

const MAX_SOLUTION_COUNT = 50
const MAX_GENERATION_ATTEMPTS = 100

# =============================================================================
# MAIN GENERATION API
# =============================================================================

static func generate(
	grid_size: Vector2i,
	target_solutions: int = 3,
	rng: RandomNumberGenerator = null
) -> PuzzleState:
	## Generate a puzzle. Uses single-solution for target<=1, multi-solution otherwise.

	if rng == null:
		rng = RandomNumberGenerator.new()
		rng.randomize()

	if target_solutions <= 1:
		return generate_single_solution(grid_size, rng)
	return generate_multi_solution(grid_size, rng)


static func generate_single_solution(
	grid_size: Vector2i,
	rng: RandomNumberGenerator
) -> PuzzleState:
	## Generate a puzzle with exactly 1 solution. Good for "boss boards".
	## No shuffle - patterns don't need hiding.

	for _attempt in range(MAX_GENERATION_ATTEMPTS):
		var state = PuzzleState.new(grid_size)

		# Fill with random diverse values
		for row in range(grid_size.y):
			for col in range(grid_size.x):
				state.get_cell(row, col).value = rng.randi_range(0, 9)

		# Find targets that give exactly 1 solution
		var result = _find_targets_with_solution_count(state, 1, 1, rng)
		if result != null:
			var analysis = analyze(result)
			print("[PuzzleGenerator] single_solution: %d solutions, diversity %.2f" % [
				analysis.solution_count, analysis.diversity
			])
			return result

	# Fallback: return any valid puzzle
	print("[PuzzleGenerator] single_solution failed, using fallback")
	return _generate_fallback(grid_size, rng)


static func generate_multi_solution(
	grid_size: Vector2i,
	rng: RandomNumberGenerator
) -> PuzzleState:
	## Generate a puzzle with multiple solutions using exchange patterns.
	## Creates 2x2 regions where both diagonals work, then shuffles.

	for _attempt in range(MAX_GENERATION_ATTEMPTS):
		var state = PuzzleState.new(grid_size)

		# Fill with random diverse values
		for row in range(grid_size.y):
			for col in range(grid_size.x):
				state.get_cell(row, col).value = rng.randi_range(0, 9)

		# Determine how many exchange patterns to create
		var num_patterns = _get_pattern_count(grid_size)

		# Create exchange patterns (modify values so diagonals are equal)
		var patterns_created = _create_exchange_patterns(state, num_patterns, rng)
		if patterns_created == 0:
			continue

		# Find valid targets
		var result = _find_targets_with_solution_count(state, 2, 20, rng)
		if result != null:
			# Shuffle to disperse the exchange patterns
			_shuffle_puzzle(result, rng)

			var analysis = analyze(result)
			print("[PuzzleGenerator] multi_solution: %d patterns, %d solutions, diversity %.2f" % [
				patterns_created, analysis.solution_count, analysis.diversity
			])
			return result

	# Fallback
	print("[PuzzleGenerator] multi_solution failed, using fallback")
	var fallback = _generate_fallback(grid_size, rng)
	_shuffle_puzzle(fallback, rng)
	return fallback


static func _get_pattern_count(grid_size: Vector2i) -> int:
	## Determine how many 2x2 exchange patterns to create based on grid size.
	## Formula: size - 2 (so 3x3=1, 4x4=2, 5x5=3, 6x6=4)
	var size = mini(grid_size.x, grid_size.y)
	return maxi(1, size - 2)


static func _create_exchange_patterns(
	state: PuzzleState,
	num_patterns: int,
	rng: RandomNumberGenerator
) -> int:
	## Create non-overlapping 2x2 exchange patterns with uniform rows.
	## Pattern: [V][V] / [W][W] - either diagonal gives same row/col sums.
	## Returns number of patterns successfully created.

	var used_cells: Dictionary = {}
	var patterns_created = 0
	var size = state.grid_size

	for _i in range(num_patterns):
		var found = false
		for _try in range(20):
			var r = rng.randi_range(0, size.y - 2)
			var c = rng.randi_range(0, size.x - 2)

			# Check if any cell is already used
			var overlaps = false
			for dr in range(2):
				for dc in range(2):
					if used_cells.has(Vector2i(c + dc, r + dr)):
						overlaps = true
						break
				if overlaps:
					break

			if overlaps:
				continue

			# Create exchange pattern: uniform values per row, different between rows
			# [V][V]
			# [W][W]  where V != W (diagonals are different)
			var v = rng.randi_range(0, 9)
			var w = rng.randi_range(0, 9)
			while w == v:
				w = rng.randi_range(0, 9)

			state.get_cell(r, c).value = v
			state.get_cell(r, c + 1).value = v
			state.get_cell(r + 1, c).value = w
			state.get_cell(r + 1, c + 1).value = w

			# Mark cells as used
			for dr in range(2):
				for dc in range(2):
					used_cells[Vector2i(c + dc, r + dr)] = true

			patterns_created += 1
			found = true
			break

		if not found:
			break

	return patterns_created


static func _find_targets_with_solution_count(
	state: PuzzleState,
	min_solutions: int,
	max_solutions: int,
	rng: RandomNumberGenerator
) -> PuzzleState:
	## Find targets that give solution count in [min, max] range.

	var grid_size = state.grid_size
	var total_cells = grid_size.x * grid_size.y

	# Ensure at least 35% of cells are deleted (prevent trivial puzzles)
	var min_delete = maxi(3, int(total_cells * 0.35))
	var max_keep = total_cells - min_delete
	var max_keep_ratio = float(max_keep) / total_cells

	for _attempt in range(50):
		# Pick a random valid keep-set (30% to max_keep_ratio)
		var keep_ratio = rng.randf_range(0.3, max_keep_ratio)
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

		# Count solutions
		var solution_count = count_solutions(state, max_solutions + 1)

		if solution_count >= min_solutions and solution_count <= max_solutions:
			state.puzzle_seed = rng.randi()
			return state

	return null


static func _generate_fallback(grid_size: Vector2i, rng: RandomNumberGenerator) -> PuzzleState:
	## Generate any valid puzzle as fallback.
	var config = PuzzleLogic.PuzzleConfig.new()
	config.grid_size = grid_size
	config.puzzle_seed = rng.randi()
	return PuzzleLogic.generate_puzzle(config)


# Legacy strategies moved to docs/LEGACY_PUZZLE_STRATEGIES.md


# Legacy strategies documented in docs/LEGACY_PUZZLE_STRATEGIES.md


# =============================================================================
# TARGET FINDING (used by legacy code, kept for _find_good_targets)
# =============================================================================

# =============================================================================
# SHARED UTILITIES
# =============================================================================

static func _find_good_targets(
	state: PuzzleState,
	min_solutions: int,
	max_solutions: int,
	rng: RandomNumberGenerator
) -> PuzzleState:
	## Try different target configurations for the given grid.
	## Returns the state with targets set, or null if no good targets found.

	var total_cells = state.grid_size.x * state.grid_size.y

	for _target_attempt in range(15):
		# Pick random cells to keep (30-70% of grid)
		var keep_ratio = rng.randf_range(0.3, 0.7)
		var cells_to_keep = int(total_cells * keep_ratio)
		cells_to_keep = clampi(cells_to_keep, state.grid_size.x, total_cells - state.grid_size.x)

		var keep_set = _sample_valid_keep_set(state, cells_to_keep, rng)
		if keep_set.is_empty():
			continue

		# Calculate targets from this keep set
		_set_targets_from_keep_set(state, keep_set)

		# Count actual solutions
		var solution_count = count_solutions(state, max_solutions + 1)

		if solution_count >= min_solutions and solution_count <= max_solutions:
			state.puzzle_seed = rng.randi()
			return state

	return null


static func _sample_valid_keep_set(
	state: PuzzleState,
	target_count: int,
	rng: RandomNumberGenerator
) -> Array:
	## Sample a random subset ensuring each row/col has at least one cell.

	var grid_size = state.grid_size
	var keep_set: Dictionary = {}

	# Guarantee at least 1 cell per row
	for row in range(grid_size.y):
		var col = rng.randi_range(0, grid_size.x - 1)
		keep_set[Vector2i(col, row)] = true

	# Guarantee at least 1 cell per column
	for col in range(grid_size.x):
		var has_cell = false
		for pos in keep_set.keys():
			if pos.x == col:
				has_cell = true
				break
		if not has_cell:
			var row = rng.randi_range(0, grid_size.y - 1)
			keep_set[Vector2i(col, row)] = true

	# Fill remaining
	var all_positions: Array[Vector2i] = []
	for row in range(grid_size.y):
		for col in range(grid_size.x):
			var pos = Vector2i(col, row)
			if not keep_set.has(pos):
				all_positions.append(pos)

	all_positions.shuffle()

	var remaining = target_count - keep_set.size()
	for i in range(mini(remaining, all_positions.size())):
		keep_set[all_positions[i]] = true

	return keep_set.keys()


static func _set_targets_from_keep_set(state: PuzzleState, keep_set: Array) -> void:
	## Set row/col targets based on sums of kept cells.

	var keep_dict: Dictionary = {}
	for pos in keep_set:
		keep_dict[pos] = true

	for row in range(state.grid_size.y):
		var row_sum = 0
		for col in range(state.grid_size.x):
			if keep_dict.has(Vector2i(col, row)):
				row_sum += state.get_cell(row, col).value
		state.row_targets[row] = row_sum

	for col in range(state.grid_size.x):
		var col_sum = 0
		for row in range(state.grid_size.y):
			if keep_dict.has(Vector2i(col, row)):
				col_sum += state.get_cell(row, col).value
		state.col_targets[col] = col_sum


# =============================================================================
# SINGLE SOLUTION FALLBACK
# =============================================================================

static func _generate_single_solution(
	grid_size: Vector2i,
	rng: RandomNumberGenerator
) -> PuzzleState:
	## Fallback: generate puzzle with exactly 1 solution.

	var config = PuzzleLogic.PuzzleConfig.new()
	config.grid_size = grid_size
	config.min_cell_value = 1
	config.max_cell_value = 9
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


# =============================================================================
# PUZZLE SHUFFLING
# =============================================================================

static func _shuffle_puzzle(state: PuzzleState, rng: RandomNumberGenerator) -> void:
	## Shuffle rows and columns to break up visual patterns.
	## This preserves the puzzle's mathematical properties because
	## permuting rows/columns with their targets is an invariant operation.

	var size = state.grid_size

	# Generate random row and column permutations
	var row_perm: Array[int] = []
	var col_perm: Array[int] = []
	for i in range(size.y):
		row_perm.append(i)
	for i in range(size.x):
		col_perm.append(i)

	# Fisher-Yates shuffle
	for i in range(size.y - 1, 0, -1):
		var j = rng.randi_range(0, i)
		var tmp = row_perm[i]
		row_perm[i] = row_perm[j]
		row_perm[j] = tmp

	for i in range(size.x - 1, 0, -1):
		var j = rng.randi_range(0, i)
		var tmp = col_perm[i]
		col_perm[i] = col_perm[j]
		col_perm[j] = tmp

	# Create new cell values array with shuffled positions
	var new_values: Array = []
	for _row in range(size.y):
		var row_vals: Array[int] = []
		row_vals.resize(size.x)
		new_values.append(row_vals)

	for old_row in range(size.y):
		for old_col in range(size.x):
			var new_row = row_perm[old_row]
			var new_col = col_perm[old_col]
			new_values[new_row][new_col] = state.get_cell(old_row, old_col).value

	# Apply new values
	for row in range(size.y):
		for col in range(size.x):
			state.get_cell(row, col).value = new_values[row][col]

	# Shuffle targets to match
	var new_row_targets: Array[int] = []
	var new_col_targets: Array[int] = []
	new_row_targets.resize(size.y)
	new_col_targets.resize(size.x)

	for old_idx in range(size.y):
		new_row_targets[row_perm[old_idx]] = state.row_targets[old_idx]
	for old_idx in range(size.x):
		new_col_targets[col_perm[old_idx]] = state.col_targets[old_idx]

	state.row_targets = new_row_targets
	state.col_targets = new_col_targets
