extends Node
## Global event bus for decoupled communication between game systems.
## All game events flow through this singleton.

# =============================================================================
# PUZZLE EVENTS
# =============================================================================

## Emitted when a cell is deleted from the grid
signal cell_deleted(row: int, col: int, value: int)

## Emitted when a cell is circled (marked as keeper)
signal cell_circled(row: int, col: int)

## Emitted when a cell is uncircled (returned to active)
signal cell_uncircled(row: int, col: int)

## Emitted when cell deletion is undone
signal cell_restored(row: int, col: int, value: int)

## Emitted when the player submits their solution
signal puzzle_submitted()

## Emitted after validation with results
signal puzzle_validated(success: bool, row_results: Array, col_results: Array)

## Emitted when a new puzzle is loaded
signal puzzle_loaded(puzzle_state: Resource)

# =============================================================================
# SCORING EVENTS
# =============================================================================

## Emitted when score calculation begins (for animation sequencing)
signal score_calculation_started()

## Emitted for each step of the score breakdown
signal score_step(source: String, value: Variant, step_type: String)

## Emitted when final score is calculated
signal score_finalized(total: int, breakdown: Array)

## Emitted when an operator triggers during scoring
signal operator_triggered(operator_id: String, effect_value: Variant)

# =============================================================================
# RUN EVENTS
# =============================================================================

## Emitted when a new run begins
signal run_started(grid_type: String, difficulty: int)

## Emitted when stage changes
signal stage_started(stage_num: int)

## Emitted when puzzle within stage starts
signal puzzle_started(puzzle_num: int, is_boss: bool)

## Emitted when puzzle is completed (passed or failed)
signal puzzle_completed(success: bool, score: int, reward: int)

## Emitted when run ends (victory or defeat)
signal run_ended(victory: bool, final_score: int)

## Emitted when a life is lost
signal life_lost(remaining: int)

## Emitted when player makes a mistake (deletes a solution cell)
signal mistake_made(row: int, col: int)

## Emitted when game over occurs
signal game_over()

# =============================================================================
# ECONOMY EVENTS
# =============================================================================

## Emitted when money changes
signal money_changed(new_amount: int, delta: int)

## Emitted when an operator is acquired
signal operator_acquired(operator: Resource)

## Emitted when an operator is sold
signal operator_sold(operator: Resource, sell_price: int)

## Emitted when a function (consumable) is used
signal function_used(function_id: String)

# =============================================================================
# UI EVENTS
# =============================================================================

## Request to show a tooltip
signal tooltip_requested(content: Dictionary, global_position: Vector2)

## Request to hide tooltip
signal tooltip_hidden()

## Request screen transition
signal screen_transition_requested(to_screen: String, params: Dictionary)

## Emitted when screen transition completes
signal screen_transition_completed(screen_name: String)

# =============================================================================
# GAME STATE EVENTS
# =============================================================================

## Emitted when game state changes (phase transitions)
signal game_state_changed(old_state: int, new_state: int)

## Emitted when any state data changes (for UI refresh)
signal state_changed()

## Emitted when run ends (victory or defeat) - aliased for Sprint 1 compatibility
signal run_ended_with_result(won: bool)
