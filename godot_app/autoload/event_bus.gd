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

## Emitted for each step of the score breakdown
signal score_step(source: String, value: Variant, step_type: String)

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

## Emitted when puzzle timer expires
signal puzzle_timeout()

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

## Emitted when player buys time during puzzle
signal time_purchased(seconds_added: float)

## Emitted when interest is earned on savings
signal interest_earned(amount: int)

## Emitted when player achieves a grade
signal grade_achieved(grade: String, score: int)

# =============================================================================
# UI EVENTS
# =============================================================================

## Request to show a tooltip
signal tooltip_requested(content: Dictionary, global_position: Vector2)

## Request to hide tooltip
signal tooltip_hidden()

# =============================================================================
# GAME STATE EVENTS
# =============================================================================

## Emitted when game state changes (phase transitions)
signal game_state_changed(old_state: int, new_state: int)

## Emitted when any state data changes (for UI refresh)
signal state_changed()
