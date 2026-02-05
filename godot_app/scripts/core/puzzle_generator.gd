class_name PuzzleGenerator
extends RefCounted
## Generates puzzles with configurable solution counts.
##
## Primary strategy: Coincidental Sums (preserves math challenge)
## - Fill grid with diverse values (1-9)
## - Find targets where different number combinations happen to sum to the same value
## - Example: Row [1,7,3,5] with target 8 allows {1,7} OR {3,5}
## - Player must recognize BOTH pairs sum to 8 - math preserved, choice introduced
##
## Fallback strategies when coincidental sums are rare:
## - Exchange patterns: 2x2 regions where both diagonals work
## - Controlled diversity: Reduce value diversity (sacrifices math challenge)

const MAX_SOLUTION_COUNT = 50
const MAX_GENERATION_ATTEMPTS = 50
const COINCIDENTAL_ATTEMPTS = 100  # More attempts since coincidences are rarer

# =============================================================================
# MAIN GENERATION API
# =============================================================================

static func generate(
	grid_size: Vector2i,
	target_solutions: int = 3,
	rng: RandomNumberGenerator = null
) -> PuzzleState:
	## Generate a puzzle targeting approximately `target_solutions` solutions.
	## Returns puzzle with solution_count in range [max(1, target-2), target+2].

	if rng == null:
		rng = RandomNumberGenerator.new()
		rng.randomize()

	var min_solutions = maxi(1, target_solutions - 2)
	var max_solutions = target_solutions + 3

	# Try generation strategies in order of preference
	# Coincidental sums first (best math challenge), then fallbacks
	var strategies = [
		_strategy_coincidental_sums,
		_strategy_exchange_patterns,
		_strategy_controlled_diversity,
		_strategy_random_sampling,
	]

	for strategy in strategies:
		var result = strategy.call(grid_size, min_solutions, max_solutions, rng)
		if result != null:
			return result

	# Fallback: single-solution puzzle
	return _generate_single_solution(grid_size, rng)


# =============================================================================
# STRATEGY 1: Coincidental Sums (Primary - preserves math challenge)
# =============================================================================

static func _strategy_coincidental_sums(
	grid_size: Vector2i,
	min_solutions: int,
	max_solutions: int,
	rng: RandomNumberGenerator
) -> PuzzleState:
	## Find puzzles where different number combinations coincidentally sum to the same targets.
	## Preserves full value diversity (1-9) so math challenge remains.

	for _attempt in range(COINCIDENTAL_ATTEMPTS):
		var state = PuzzleState.new(grid_size)

		# Fill grid with diverse values (1-9)
		for row in range(grid_size.y):
			for col in range(grid_size.x):
				state.get_cell(row, col).value = rng.randi_range(1, 9)

		# Try to find good targets using sum partners
		var result = _find_coincidental_targets(state, min_solutions, max_solutions, rng)
		if result != null:
			return result

	return null


static func _find_coincidental_targets(
	state: PuzzleState,
	min_solutions: int,
	max_solutions: int,
	rng: RandomNumberGenerator
) -> PuzzleState:
	## Find targets that allow multiple solutions via coincidental sums.
	## Strategy: identify targets where rows/cols have "sum partners" (different subsets → same sum).

	var grid_size = state.grid_size

	# Analyze sum partners for each row
	var row_partners: Array = []  # Array of {sum: [[indices], ...]} per row
	for row in range(grid_size.y):
		var values: Array = []
		for col in range(grid_size.x):
			values.append({"col": col, "value": state.get_cell(row, col).value})
		row_partners.append(_find_sum_partners(values))

	# Analyze sum partners for each column
	var col_partners: Array = []
	for col in range(grid_size.x):
		var values: Array = []
		for row in range(grid_size.y):
			values.append({"col": row, "value": state.get_cell(row, col).value})
		col_partners.append(_find_sum_partners(values))

	# Score candidate target sums by how many alternatives they provide
	# Higher score = more subsets can achieve this sum
	var row_target_candidates: Array = []  # Array of Array of {target, score}
	for row in range(grid_size.y):
		var candidates: Array = []
		for target_sum in row_partners[row].keys():
			var subsets = row_partners[row][target_sum]
			# Score based on number of alternative subsets
			candidates.append({"target": target_sum, "score": subsets.size(), "subsets": subsets})
		# Sort by score (more alternatives = better)
		candidates.sort_custom(func(a, b): return a.score > b.score)
		row_target_candidates.append(candidates)

	# Try different combinations of row targets, prioritizing those with more alternatives
	for _target_attempt in range(30):
		# For each row, pick a target (weighted towards those with more alternatives)
		var row_targets: Array[int] = []
		var row_keep_sets: Array = []  # One possible keep-set per row

		var valid_config = true
		for row in range(grid_size.y):
			var candidates = row_target_candidates[row]
			if candidates.is_empty():
				valid_config = false
				break

			# Weighted selection: prefer targets with more alternatives
			var total_score = 0
			for c in candidates:
				total_score += c.score
			var pick = rng.randi() % total_score
			var running = 0
			var chosen = candidates[0]
			for c in candidates:
				running += c.score
				if pick < running:
					chosen = c
					break

			row_targets.append(chosen.target)
			# Pick a random subset from the alternatives
			var subset_idx = rng.randi() % chosen.subsets.size()
			row_keep_sets.append(chosen.subsets[subset_idx])

		if not valid_config:
			continue

		# Set row targets
		for row in range(grid_size.y):
			state.row_targets[row] = row_targets[row]

		# Calculate column targets from chosen keep-set
		var keep_dict: Dictionary = {}
		for row in range(grid_size.y):
			for col in row_keep_sets[row]:
				keep_dict[Vector2i(col, row)] = true

		for col in range(grid_size.x):
			var col_sum = 0
			for row in range(grid_size.y):
				if keep_dict.has(Vector2i(col, row)):
					col_sum += state.get_cell(row, col).value
			state.col_targets[col] = col_sum

		# Count actual solutions
		var solution_count = count_solutions(state, max_solutions + 1)

		if solution_count >= min_solutions and solution_count <= max_solutions:
			state.puzzle_seed = rng.randi()
			return state

	return null


static func _find_sum_partners(cells: Array) -> Dictionary:
	## Find all subsets that sum to each possible total.
	## Returns {sum: [[indices that produce it], ...]}
	## "Sum partners" are sums with multiple ways to achieve them.

	var sum_groups: Dictionary = {}

	# Generate all non-empty subsets
	var n = cells.size()
	var total_subsets = 1 << n  # 2^n

	for mask in range(1, total_subsets):  # Skip empty subset
		var subset_indices: Array = []
		var subset_sum = 0

		for i in range(n):
			if mask & (1 << i):
				subset_indices.append(cells[i].col)
				subset_sum += cells[i].value

		if not sum_groups.has(subset_sum):
			sum_groups[subset_sum] = []
		sum_groups[subset_sum].append(subset_indices)

	return sum_groups


# =============================================================================
# STRATEGY 2: Controlled Value Diversity (Fallback - reduces math challenge)
# =============================================================================

static func _strategy_controlled_diversity(
	grid_size: Vector2i,
	min_solutions: int,
	max_solutions: int,
	rng: RandomNumberGenerator
) -> PuzzleState:
	## Control solution count by controlling value diversity.
	## More repeated values → more solutions.

	var total_cells = grid_size.x * grid_size.y

	# Map target solution range to diversity level
	# diversity 0.0 = all same value, 1.0 = all different
	var target_mid = (min_solutions + max_solutions) / 2.0
	var diversity = _solutions_to_diversity(target_mid, total_cells)

	for _attempt in range(MAX_GENERATION_ATTEMPTS):
		var state = PuzzleState.new(grid_size)

		# Generate values with controlled diversity
		_fill_with_diversity(state, diversity, rng)

		# Try to find targets that give solutions in range
		var result = _find_good_targets(state, min_solutions, max_solutions, rng)
		if result != null:
			return result

	return null


static func _solutions_to_diversity(target_solutions: float, total_cells: int) -> float:
	## Map target solution count to diversity level.
	## Based on empirical observation:
	## - All 1s with n×n grid, targets n-1 per row/col → ~n! solutions
	## - Higher diversity → fewer solutions

	# For a 3×3: all 1s can give 6 solutions, all different gives ~1
	# For a 4×4: all 1s can give 24+ solutions
	# For a 5×5: all 1s can give 120+ solutions

	# Rough formula: diversity ≈ 1 - log(target) / log(max_possible)
	var max_possible = mini(120, total_cells * total_cells)  # Cap estimate

	if target_solutions <= 1:
		return 0.9  # High diversity for single solution
	if target_solutions >= max_possible:
		return 0.0  # No diversity for max solutions

	# Logarithmic mapping
	var log_target = log(target_solutions)
	var log_max = log(max_possible)
	return clampf(1.0 - (log_target / log_max), 0.1, 0.9)


static func _fill_with_diversity(
	state: PuzzleState,
	diversity: float,
	rng: RandomNumberGenerator
) -> void:
	## Fill grid with values at specified diversity level.
	## diversity 0 = all same, 1 = all different

	var size = state.grid_size
	var total = size.x * size.y

	if diversity < 0.2:
		# Very low diversity: mostly same value with slight variation
		var base_value = rng.randi_range(1, 3)
		for row in range(size.y):
			for col in range(size.x):
				var value = base_value
				if rng.randf() < diversity * 2:
					value = rng.randi_range(1, 4)
				state.get_cell(row, col).value = value

	elif diversity < 0.5:
		# Medium-low diversity: 2-3 distinct values
		var values = [rng.randi_range(1, 3), rng.randi_range(2, 5)]
		if rng.randf() < diversity:
			values.append(rng.randi_range(3, 6))
		for row in range(size.y):
			for col in range(size.x):
				state.get_cell(row, col).value = values[rng.randi() % values.size()]

	elif diversity < 0.7:
		# Medium diversity: 3-5 distinct values
		var values = []
		for i in range(rng.randi_range(3, 5)):
			values.append(rng.randi_range(1, 7))
		for row in range(size.y):
			for col in range(size.x):
				state.get_cell(row, col).value = values[rng.randi() % values.size()]

	else:
		# High diversity: mostly different values
		for row in range(size.y):
			for col in range(size.x):
				state.get_cell(row, col).value = rng.randi_range(1, 9)


# =============================================================================
# STRATEGY 3: Exchange Patterns (Fallback)
# =============================================================================

static func _strategy_exchange_patterns(
	grid_size: Vector2i,
	min_solutions: int,
	max_solutions: int,
	rng: RandomNumberGenerator
) -> PuzzleState:
	## Create puzzles with explicit exchange patterns.
	## Each 2×2 with equal diagonals doubles solution count.

	if grid_size.x < 3 or grid_size.y < 3:
		return null

	# Calculate how many exchange patterns we need
	# 2^k solutions for k independent patterns
	var target_mid = (min_solutions + max_solutions) / 2.0
	var num_patterns = maxi(1, int(log(target_mid) / log(2)))
	num_patterns = mini(num_patterns, (grid_size.x - 1) * (grid_size.y - 1) / 2)

	for _attempt in range(MAX_GENERATION_ATTEMPTS / 2):
		var state = PuzzleState.new(grid_size)

		# Fill with base values
		for row in range(grid_size.y):
			for col in range(grid_size.x):
				state.get_cell(row, col).value = rng.randi_range(1, 5)

		# Create exchange patterns at random positions
		var used_cells: Dictionary = {}
		var patterns_created = 0

		for _p in range(num_patterns * 3):  # Try more times than needed
			if patterns_created >= num_patterns:
				break

			var r = rng.randi_range(0, grid_size.y - 2)
			var c = rng.randi_range(0, grid_size.x - 2)

			# Check cells not already used
			var key = Vector2i(c, r)
			if used_cells.has(key):
				continue

			# Create exchange pattern: make diagonals equal
			var a = state.get_cell(r, c).value
			var d = state.get_cell(r + 1, c + 1).value
			var diag_sum = a + d

			# Set b and c so b + c = a + d
			var b = rng.randi_range(1, mini(diag_sum - 1, 9))
			var c_val = diag_sum - b
			if c_val >= 1 and c_val <= 9:
				state.get_cell(r, c + 1).value = b
				state.get_cell(r + 1, c).value = c_val
				used_cells[key] = true
				used_cells[Vector2i(c + 1, r)] = true
				used_cells[Vector2i(c, r + 1)] = true
				used_cells[Vector2i(c + 1, r + 1)] = true
				patterns_created += 1

		# Find targets
		var result = _find_good_targets(state, min_solutions, max_solutions, rng)
		if result != null:
			return result

	return null


# =============================================================================
# STRATEGY 4: Random Sampling (Last resort)
# =============================================================================

static func _strategy_random_sampling(
	grid_size: Vector2i,
	min_solutions: int,
	max_solutions: int,
	rng: RandomNumberGenerator
) -> PuzzleState:
	## Original algorithm: random values, sample keep-sets as targets.

	for _attempt in range(MAX_GENERATION_ATTEMPTS):
		var state = PuzzleState.new(grid_size)

		# Fill with random values
		for row in range(grid_size.y):
			for col in range(grid_size.x):
				state.get_cell(row, col).value = rng.randi_range(1, 9)

		var result = _find_good_targets(state, min_solutions, max_solutions, rng)
		if result != null:
			return result

	return null


# =============================================================================
# TARGET FINDING (Shared by all strategies)
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
