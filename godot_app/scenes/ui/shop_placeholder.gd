extends Control
## Shop screen shown between stages.
## Allows buying/selling operators and rerolling.

signal continue_pressed

const ShopStateScript = preload("res://scripts/core/shop_state.gd")

var shop_state: ShopState = null

@onready var continue_button: Button = %ContinueButton
@onready var money_label: Label = %MoneyLabel
@onready var reroll_button: Button = %RerollButton
@onready var slots_container: HBoxContainer = %SlotsContainer
@onready var owned_container: HBoxContainer = %OwnedContainer
@onready var slots_label: Label = %SlotsLabel
@onready var time_bank_label: Label = %TimeBankLabel
@onready var buy_time_button: Button = %BuyTimeButton

func _ready() -> void:
	continue_button.pressed.connect(_on_continue_pressed)
	reroll_button.pressed.connect(_on_reroll_pressed)
	buy_time_button.pressed.connect(_on_buy_time_pressed)
	_setup_shop()


func _setup_shop() -> void:
	shop_state = ShopStateScript.new()
	shop_state.reset_reroll()
	shop_state.generate()
	_refresh_display()


func _refresh_display() -> void:
	# Update money
	if GameState.run:
		money_label.text = "$%d" % GameState.run.money
	else:
		money_label.text = "$0"

	# Update reroll button
	reroll_button.text = "Reroll ($%d)" % shop_state.reroll_cost
	reroll_button.disabled = not shop_state.can_reroll()

	# Update time pool display
	_update_time_pool_display()

	# Update slots label
	slots_label.text = "Operators (%d/%d)" % [GameState.operators.size(), GameState.MAX_OPERATORS]

	# Clear and rebuild operator slots
	for child in slots_container.get_children():
		child.queue_free()

	for i in range(shop_state.operator_slots.size()):
		var op = shop_state.get_slot(i)
		var slot = _create_shop_slot(i, op)
		slots_container.add_child(slot)

	# Clear and rebuild owned operators
	for child in owned_container.get_children():
		child.queue_free()

	for i in range(GameState.operators.size()):
		var op = GameState.operators[i]
		var slot = _create_owned_slot(i, op)
		owned_container.add_child(slot)


func _create_shop_slot(index: int, op: Operator) -> Control:
	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(140, 120)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)
	panel.add_child(vbox)

	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 8)
	margin.add_theme_constant_override("margin_right", 8)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_bottom", 8)
	panel.add_child(margin)

	var content = VBoxContainer.new()
	content.add_theme_constant_override("separation", 4)
	margin.add_child(content)

	if op == null:
		var empty_label = Label.new()
		empty_label.text = "SOLD"
		empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		empty_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
		content.add_child(empty_label)
	else:
		var name_label = Label.new()
		name_label.text = op.display_name
		name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		name_label.add_theme_font_size_override("font_size", 14)
		content.add_child(name_label)

		var desc_label = Label.new()
		desc_label.text = op.description
		desc_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		desc_label.add_theme_font_size_override("font_size", 11)
		desc_label.add_theme_color_override("font_color", Color(0.7, 0.75, 0.8))
		desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD
		content.add_child(desc_label)

		var spacer = Control.new()
		spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
		content.add_child(spacer)

		var buy_button = Button.new()
		buy_button.text = "Buy $%d" % op.price
		buy_button.custom_minimum_size = Vector2(0, 32)
		buy_button.add_theme_font_size_override("font_size", 16)
		buy_button.add_theme_color_override("font_color", Color.WHITE)
		# Green background for buy button
		var style = StyleBoxFlat.new()
		style.bg_color = Color(0.2, 0.6, 0.3)
		style.corner_radius_top_left = 4
		style.corner_radius_top_right = 4
		style.corner_radius_bottom_left = 4
		style.corner_radius_bottom_right = 4
		style.content_margin_left = 8
		style.content_margin_right = 8
		style.content_margin_top = 4
		style.content_margin_bottom = 4
		buy_button.add_theme_stylebox_override("normal", style)
		# Lighter green for hover
		var hover_style = style.duplicate()
		hover_style.bg_color = Color(0.25, 0.7, 0.35)
		buy_button.add_theme_stylebox_override("hover", hover_style)
		# Darker for pressed
		var pressed_style = style.duplicate()
		pressed_style.bg_color = Color(0.15, 0.5, 0.25)
		buy_button.add_theme_stylebox_override("pressed", pressed_style)
		# Grey when disabled
		var disabled_style = style.duplicate()
		disabled_style.bg_color = Color(0.3, 0.3, 0.3)
		buy_button.add_theme_stylebox_override("disabled", disabled_style)
		buy_button.add_theme_color_override("font_disabled_color", Color(0.5, 0.5, 0.5))
		buy_button.disabled = not shop_state.can_buy(index)
		# Add tooltip explaining why button is disabled
		if buy_button.disabled:
			if GameState.operators.size() >= GameState.MAX_OPERATORS:
				buy_button.tooltip_text = "Operators full, sell one first"
			else:
				buy_button.tooltip_text = "Can't afford"
		buy_button.pressed.connect(_on_buy_pressed.bind(index))
		content.add_child(buy_button)

	return panel


func _create_owned_slot(index: int, op: Operator) -> Control:
	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(120, 100)

	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 8)
	margin.add_theme_constant_override("margin_right", 8)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_bottom", 8)
	panel.add_child(margin)

	var content = VBoxContainer.new()
	content.add_theme_constant_override("separation", 4)
	margin.add_child(content)

	var name_label = Label.new()
	name_label.text = op.display_name
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_font_size_override("font_size", 12)
	content.add_child(name_label)

	var desc_label = Label.new()
	desc_label.text = op.description
	desc_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc_label.add_theme_font_size_override("font_size", 10)
	desc_label.add_theme_color_override("font_color", Color(0.6, 0.65, 0.7))
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	content.add_child(desc_label)

	var spacer = Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_child(spacer)

	var sell_button = Button.new()
	sell_button.text = "Sell $%d" % (op.price / 2)
	sell_button.pressed.connect(_on_sell_pressed.bind(index))
	content.add_child(sell_button)

	return panel


func _on_buy_pressed(index: int) -> void:
	if shop_state.buy_operator(index):
		_refresh_display()


func _on_sell_pressed(index: int) -> void:
	if shop_state.sell_operator(index):
		_refresh_display()


func _on_reroll_pressed() -> void:
	if shop_state.reroll():
		_refresh_display()


func _on_buy_time_pressed() -> void:
	if _buy_time_for_pool():
		_refresh_display()


func _buy_time_for_pool() -> bool:
	## Buy time to add to shared time pool. Price escalates: $1, $2, $3...
	if GameState.run == null:
		return false

	var price: int = GameConfig.get_time_purchase_price(GameState.run.time_purchases)
	if GameState.run.money < price:
		return false

	# Deduct money and add to pool (capped)
	GameState.run.spend_money(price)
	GameState.run.time_pool = minf(
		GameState.run.time_pool + float(GameConfig.TIME_PURCHASE_AMOUNT),
		GameConfig.TIME_POOL_CAP
	)
	GameState.run.time_purchases += 1

	SoundManager.play("coin_spend")
	return true


func _update_time_pool_display() -> void:
	if GameState.run == null:
		time_bank_label.text = "Time: 0:00"
		buy_time_button.disabled = true
		buy_time_button.text = "Buy +%ds ($1)" % GameConfig.TIME_PURCHASE_AMOUNT
		return

	var pool: int = int(GameState.run.time_pool)
	time_bank_label.text = "Time: %d:%02d" % [pool / 60, pool % 60]

	# Escalating price: $1, $2, $3... based on total purchases this run
	var price: int = GameConfig.get_time_purchase_price(GameState.run.time_purchases)
	var can_afford: bool = GameState.run.money >= price

	buy_time_button.disabled = not can_afford
	buy_time_button.text = "Buy +%ds ($%d)" % [GameConfig.TIME_PURCHASE_AMOUNT, price]


func _on_continue_pressed() -> void:
	continue_pressed.emit()
