class_name PuzzleLogic
extends RefCounted
## Handles puzzle generation and validation logic.

const PuzzleGeneratorScript = preload("res://scripts/core/puzzle_generator.gd")

# =============================================================================
# PUZZLE CONFIGURATION
# =============================================================================

class PuzzleConfig:
	var grid_size: Vector2i = Vector2i(3, 3)
	var min_cell_value: int = 1
	var max_cell_value: int = 9
	var exclude_zero: bool = false  ## Note: 0 is always excluded by _random_nonzero
	var cells_to_delete_ratio: float = 0.4  ## Used by fallback generator only
	var puzzle_seed: int = 0  ## 0 = random seed

# =============================================================================
# VALIDATION RESULT
# =============================================================================

class ValidationResult:
	var is_valid: bool = false
	var row_results: Array[Dictionary] = []  ## {index, target, actual, valid}
	var col_results: Array[Dictionary] = []

	func get_valid_row_count() -> int:
		var count = 0
		for r in row_results:
			if r.valid:
				count += 1
		return count

	func get_valid_col_count() -> int:
		var count = 0
		for c in col_results:
			if c.valid:
				count += 1
		return count

# =============================================================================
# CACHE
# =============================================================================

# Cache for has_any_solution - keyed by deleted cell bitmask
static var _solution_cache: Dictionary = {}
static var _cache_puzzle_hash: int = -1

# =============================================================================
# PUZZLE GENERATION
# =============================================================================

static func generate_puzzle(config: PuzzleConfig) -> PuzzleState:
	var rng = RandomNumberGenerator.new()
	if config.puzzle_seed != 0:
		rng.seed = config.puzzle_seed
	else:
		rng.randomize()

	var grid_size = config.grid_size
	var state = PuzzleState.new(grid_size)
	state.puzzle_seed = rng.seed

	var total_cells = grid_size.x * grid_size.y
	var cells_to_delete = int(total_cells * config.cells_to_delete_ratio)
	# Ensure at least 1 cell to delete and at least 1 cell to keep per row/col
	cells_to_delete = clampi(cells_to_delete, grid_size.x, total_cells - grid_size.x)

	# Step 1: Decide which cells are part of the solution (will be kept)
	# IMPORTANT: Each row AND column must have at least 1 solution cell (prevents 0 targets)
	# AND at least 1 decoy cell (prevents winning at puzzle start)

	var solution_cells: Dictionary = {}  # Vector2i -> true
	var decoy_cells: Array[Vector2i] = []

	# First, guarantee at least 1 solution cell per row
	for row in range(grid_size.y):
		var col = rng.randi_range(0, grid_size.x - 1)
		solution_cells[Vector2i(col, row)] = true

	# Guarantee at least 1 solution cell per column (if not already covered)
	for col in range(grid_size.x):
		var has_solution = false
		for row in range(grid_size.y):
			if solution_cells.has(Vector2i(col, row)):
				has_solution = true
				break
		if not has_solution:
			var row = rng.randi_range(0, grid_size.y - 1)
			solution_cells[Vector2i(col, row)] = true

	# Guarantee at least 1 decoy cell per row
	for row in range(grid_size.y):
		var available_cols: Array[int] = []
		for col in range(grid_size.x):
			if not solution_cells.has(Vector2i(col, row)):
				available_cols.append(col)
		if available_cols.size() > 0:
			var col = available_cols[rng.randi_range(0, available_cols.size() - 1)]
			decoy_cells.append(Vector2i(col, row))

	# Guarantee at least 1 decoy cell per column (if not already covered)
	for col in range(grid_size.x):
		var has_decoy = false
		for decoy_pos in decoy_cells:
			if decoy_pos.x == col:
				has_decoy = true
				break
		if not has_decoy:
			var available_rows: Array[int] = []
			for row in range(grid_size.y):
				var pos = Vector2i(col, row)
				if not solution_cells.has(pos) and not decoy_cells.has(pos):
					available_rows.append(row)
			if available_rows.size() > 0:
				var row = available_rows[rng.randi_range(0, available_rows.size() - 1)]
				decoy_cells.append(Vector2i(col, row))

	# Fill remaining cells to reach target delete count
	var remaining_positions: Array[Vector2i] = []
	for row in range(grid_size.y):
		for col in range(grid_size.x):
			var pos = Vector2i(col, row)
			if not solution_cells.has(pos) and not decoy_cells.has(pos):
				remaining_positions.append(pos)

	remaining_positions.shuffle()

	# Add more decoys until we reach target
	var additional_decoys_needed = cells_to_delete - decoy_cells.size()
	for i in range(mini(additional_decoys_needed, remaining_positions.size())):
		decoy_cells.append(remaining_positions[i])

	# Remaining cells become solution cells
	for i in range(additional_decoys_needed, remaining_positions.size()):
		solution_cells[remaining_positions[i]] = true

	# Step 2: Fill ALL cells with random numbers (excluding zero)
	for row in range(grid_size.y):
		for col in range(grid_size.x):
			var value = _random_nonzero(rng, config.min_cell_value, config.max_cell_value)
			var cell = state.get_cell(row, col)
			cell.value = value

	# Step 3: Calculate targets from ONLY the solution cells
	for row in range(grid_size.y):
		var row_sum = 0
		for col in range(grid_size.x):
			var pos = Vector2i(col, row)
			if solution_cells.has(pos):
				row_sum += state.get_cell(row, col).value
		state.row_targets[row] = row_sum

	for col in range(grid_size.x):
		var col_sum = 0
		for row in range(grid_size.y):
			var pos = Vector2i(col, row)
			if solution_cells.has(pos):
				col_sum += state.get_cell(row, col).value
		state.col_targets[col] = col_sum

	# Store solution cell count for par score calculation
	state.solution_cell_count = solution_cells.size()

	return state


static func _random_nonzero(rng: RandomNumberGenerator, min_val: int, max_val: int) -> int:
	## Generate a random value in [min_val, max_val] but never 0.
	if min_val > 0 or max_val < 0:
		# Range doesn't include 0
		return rng.randi_range(min_val, max_val)

	# Range includes 0 - skip it
	var value = rng.randi_range(min_val, max_val - 1)
	if value >= 0:
		value += 1
	return value

# =============================================================================
# VALIDATION
# =============================================================================

static func validate(state: PuzzleState) -> ValidationResult:
	## Validates by checking actual sums against targets.
	## Any combination of kept cells that matches targets is valid.
	var result = ValidationResult.new()

	# Check each row's current sum against target
	for row in range(state.grid_size.y):
		var target = state.row_targets[row]
		var actual = state.get_current_row_sum(row)
		result.row_results.append({
			"index": row,
			"target": target,
			"actual": actual,
			"valid": actual == target
		})

	# Check each column's current sum against target
	for col in range(state.grid_size.x):
		var target = state.col_targets[col]
		var actual = state.get_current_col_sum(col)
		result.col_results.append({
			"index": col,
			"target": target,
			"actual": actual,
			"valid": actual == target
		})

	# Overall validity - all rows and columns must match
	result.is_valid = true
	for r in result.row_results:
		if not r.valid:
			result.is_valid = false
			break
	if result.is_valid:
		for c in result.col_results:
			if not c.valid:
				result.is_valid = false
				break

	return result


static func has_any_solution(state: PuzzleState) -> bool:
	## Check if ANY valid solution exists from current state.
	## Uses backtracking to find if any combination of active cells satisfies all constraints.
	## Results are cached based on which cells are deleted.

	# Clear cache if puzzle changed (use hash of values+targets for robustness)
	var puzzle_hash := _compute_puzzle_hash(state)
	if puzzle_hash != _cache_puzzle_hash:
		_solution_cache.clear()
		_cache_puzzle_hash = puzzle_hash

	# Build cache key from deleted cell positions (bitmask for small grids)
	var cache_key := _build_state_key(state)
	if _solution_cache.has(cache_key):
		return _solution_cache[cache_key]

	var result := _compute_has_any_solution(state)
	_solution_cache[cache_key] = result
	return result


static func _compute_puzzle_hash(state: PuzzleState) -> int:
	## Compute a hash of the puzzle's static properties (values and targets).
	## Used to detect when the puzzle changes and cache should be cleared.
	var hash_val := state.grid_size.x * 1000 + state.grid_size.y
	for row in range(state.grid_size.y):
		for col in range(state.grid_size.x):
			hash_val = hash_val * 31 + state.get_cell(row, col).value
	for t in state.row_targets:
		hash_val = hash_val * 31 + t
	for t in state.col_targets:
		hash_val = hash_val * 31 + t
	return hash_val


static func _build_state_key(state: PuzzleState) -> int:
	## Build a unique key representing current deleted cells.
	## Uses bitmask for grids up to 6x6 (36 bits fits in int).
	var key := 0
	var bit := 1
	for row in range(state.grid_size.y):
		for col in range(state.grid_size.x):
			if state.get_cell(row, col).state == PuzzleState.CellState.DELETED:
				key |= bit
			bit <<= 1
	return key


static func _compute_has_any_solution(state: PuzzleState, required_cell: Vector2i = Vector2i(-1, -1)) -> bool:
	## Actual solver implementation.
	## If required_cell is valid, only considers solutions that INCLUDE that cell.
	var grid_size = state.grid_size
	var row_targets = state.row_targets
	var col_targets = state.col_targets

	# Build list of active cells per row with their values and column indices
	var rows_cells: Array = []  # Array of Array of {col: int, value: int}
	for row in range(grid_size.y):
		var row_cells: Array = []
		for col in range(grid_size.x):
			var cell = state.get_cell(row, col)
			if cell.state != PuzzleState.CellState.DELETED:
				row_cells.append({"col": col, "value": cell.value})
		rows_cells.append(row_cells)

	# For each row, precompute all subsets that sum to the row target
	var row_valid_subsets: Array = []  # Array of Array of Array[int] (col indices)
	for row in range(grid_size.y):
		var subsets = PuzzleGeneratorScript._find_subsets_with_sum(rows_cells[row], row_targets[row])
		if subsets.is_empty():
			return false  # No way to satisfy this row

		# If this row contains the required cell, filter to subsets that include it
		if row == required_cell.y and required_cell.x >= 0:
			var filtered: Array = []
			for subset in subsets:
				if required_cell.x in subset:
					filtered.append(subset)
			if filtered.is_empty():
				return false  # No valid subset includes the required cell
			subsets = filtered

		row_valid_subsets.append(subsets)

	# Backtracking: try to find a combination where column sums also match
	var col_sums: Array[int] = []
	col_sums.resize(grid_size.x)
	col_sums.fill(0)

	return _backtrack_solve(state, row_valid_subsets, 0, col_sums, col_targets)


static func _backtrack_solve(state: PuzzleState, row_subsets: Array, row: int, col_sums: Array[int], col_targets: Array[int], memo: Dictionary = {}) -> bool:
	## Backtracking solver: try each valid subset for current row and recurse.
	## Uses memoization keyed by (row, col_sums) to avoid redundant work.
	if row >= state.grid_size.y:
		# All rows processed - check if column sums match
		for col in range(state.grid_size.x):
			if col_sums[col] != col_targets[col]:
				return false
		return true

	# Create memo key from row + column sums
	var memo_key := _col_sums_to_key(row, col_sums)
	if memo.has(memo_key):
		return memo[memo_key]

	# Try each valid subset for this row
	for subset in row_subsets[row]:
		# Add this subset's contribution to column sums
		for col in subset:
			var cell = state.get_cell(row, col)
			col_sums[col] += cell.value

		# Early pruning: if any column already exceeds target, skip
		var valid = true
		for col in range(state.grid_size.x):
			if col_sums[col] > col_targets[col]:
				valid = false
				break

		if valid and _backtrack_solve(state, row_subsets, row + 1, col_sums, col_targets, memo):
			memo[memo_key] = true
			return true

		# Backtrack: remove this subset's contribution
		for col in subset:
			var cell = state.get_cell(row, col)
			col_sums[col] -= cell.value

	memo[memo_key] = false
	return false


static func _col_sums_to_key(row: int, col_sums: Array[int]) -> String:
	## Convert row + column sums to a hashable key for memoization.
	var parts: PackedStringArray = [str(row)]
	for s in col_sums:
		parts.append(str(s))
	return ",".join(parts)


static func has_solution_including_cell(state: PuzzleState, row: int, col: int) -> bool:
	## Check if ANY valid solution exists that INCLUDES the cell at (row, col).
	## Used to validate circling: if no solution includes this cell, circling it is a mistake.
	return _compute_has_any_solution(state, Vector2i(col, row))
