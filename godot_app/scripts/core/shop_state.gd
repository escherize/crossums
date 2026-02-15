class_name ShopState
extends RefCounted
## Manages shop inventory and transactions.

const OPERATOR_SLOTS := 3
const REROLL_BASE_COST := 2

# =============================================================================
# STATE
# =============================================================================

var operator_slots: Array = []  # Array[Operator] - operators for sale
var reroll_cost: int = REROLL_BASE_COST
var reroll_count: int = 0

# =============================================================================
# INITIALIZATION
# =============================================================================

func generate() -> void:
	## Populate shop with operators (deterministic if run is seeded)
	var owned_ids: Array = []
	for op in GameState.operators:
		owned_ids.append(op.id)

	# Use seeded RNG if run has a seed, otherwise random
	var rng: RandomNumberGenerator = null
	if GameState.run:
		rng = GameState.run.get_shop_rng(reroll_count)

	operator_slots = OperatorRegistry.get_random_operators(OPERATOR_SLOTS, owned_ids, rng)


func reset_reroll() -> void:
	## Reset reroll state (called when entering shop)
	reroll_count = 0
	reroll_cost = REROLL_BASE_COST


func reroll() -> bool:
	## Reroll shop contents, costs money
	if GameState.run == null:
		return false
	if GameState.run.money < reroll_cost:
		return false

	GameState.run.spend_money(reroll_cost)
	reroll_count += 1
	reroll_cost = REROLL_BASE_COST + reroll_count  # Increases each time

	generate()
	return true

# =============================================================================
# TRANSACTIONS
# =============================================================================

func buy_operator(index: int) -> bool:
	## Buy operator at given slot index
	if index < 0 or index >= operator_slots.size():
		return false

	var op = operator_slots[index]
	if op == null:
		return false

	if GameState.run == null:
		return false

	if GameState.run.money < op.price:
		return false

	if GameState.operators.size() >= GameState.MAX_OPERATORS:
		return false

	# Execute purchase
	GameState.run.spend_money(op.price)
	GameState.add_operator(op)
	operator_slots[index] = null

	return true


func sell_operator(index: int) -> bool:
	## Sell owned operator at given index
	var op = GameState.remove_operator(index)
	if op == null:
		return false

	# Get half price back
	var sell_price = op.price / 2
	if GameState.run:
		GameState.run.add_money(sell_price)

	return true


func get_slot(index: int) -> Operator:
	if index < 0 or index >= operator_slots.size():
		return null
	return operator_slots[index]


func can_buy(index: int) -> bool:
	var op = get_slot(index)
	if op == null:
		return false
	if GameState.run == null:
		return false
	if GameState.run.money < op.price:
		return false
	if GameState.operators.size() >= GameState.MAX_OPERATORS:
		return false
	return true


func can_reroll() -> bool:
	if GameState.run == null:
		return false
	return GameState.run.money >= reroll_cost
