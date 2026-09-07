class_name PileView
extends Control

## Visual representation of a card pile (Stock / Monte, Discard / Lixo, or Mortos).

const CardData = preload("res://src/core/card_data.gd")
const CardView = preload("res://src/ui/card_view.gd")
const CardViewScene = preload("res://src/ui/card_view.tscn")

signal pile_clicked(pile_type: String)
signal card_dropped(pile_type: String, card_data: CardData)

@export var pile_type: String = "STOCK" # "STOCK", "DISCARD", "MORTO"
@export var is_drop_target: bool = false

var top_card: CardData = null
var card_count: int = 0

@onready var count_label: Label = $CountLabel
@onready var title_label: Label = $TitleLabel
@onready var card_container: Control = $CardContainer
@onready var pile_button: Button = $PileButton

func _resolve_nodes() -> void:
	if pile_button == null and has_node("PileButton"):
		pile_button = get_node("PileButton") as Button
	if count_label == null and has_node("CountLabel"):
		count_label = get_node("CountLabel") as Label
	if title_label == null and has_node("TitleLabel"):
		title_label = get_node("TitleLabel") as Label
	if card_container == null and has_node("CardContainer"):
		card_container = get_node("CardContainer") as Control

	if pile_button != null:
		if not pile_button.pressed.is_connected(_on_button_pressed):
			pile_button.pressed.connect(_on_button_pressed)
		if not pile_button.mouse_entered.is_connected(_on_mouse_entered):
			pile_button.mouse_entered.connect(_on_mouse_entered)
		if not pile_button.mouse_exited.is_connected(_on_mouse_exited):
			pile_button.mouse_exited.connect(_on_mouse_exited)
		if not pile_button.gui_input.is_connected(_on_button_gui_input):
			pile_button.gui_input.connect(_on_button_gui_input)

func _ready() -> void:
	_resolve_nodes()
	mouse_filter = Control.MOUSE_FILTER_PASS
	update_visuals()

func set_pile_state(p_count: int, p_top_card: CardData = null) -> void:
	_resolve_nodes()
	card_count = p_count
	top_card = p_top_card
	update_visuals()

func update_visuals() -> void:
	_resolve_nodes()
	if count_label == null or title_label == null or card_container == null:
		return
		
	count_label.text = str(card_count)
	
	match pile_type:
		"STOCK":
			title_label.text = "MONTE"
			if pile_button != null: pile_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		"DISCARD":
			title_label.text = "LIXO"
			if pile_button != null: pile_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		"MORTO":
			title_label.text = "MORTOS"
			if pile_button != null: pile_button.mouse_default_cursor_shape = Control.CURSOR_ARROW
			
	# Update card preview
	for child in card_container.get_children():
		child.queue_free()
		
	if card_count > 0:
		var cv: CardView = CardViewScene.instantiate() as CardView
		card_container.add_child(cv)
		if pile_type == "DISCARD" and top_card != null:
			cv.setup(top_card, true)
		else:
			cv.setup(top_card if top_card != null else CardData.new(), false) # Face down
		cv.set_interactive(false)
		cv.mouse_filter = Control.MOUSE_FILTER_IGNORE

func _on_button_pressed() -> void:
	pile_clicked.emit(pile_type)

func _on_button_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			accept_event()
			pile_clicked.emit(pile_type)

func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	if is_drop_target and typeof(data) == TYPE_DICTIONARY and data.get("type") == "CARD":
		return true
	return false

func _drop_data(_at_position: Vector2, data: Variant) -> void:
	if is_drop_target and typeof(data) == TYPE_DICTIONARY and data.get("type") == "CARD":
		var c_data: CardData = data.get("card_data") as CardData
		if c_data != null:
			card_dropped.emit(pile_type, c_data)

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			accept_event()
			pile_clicked.emit(pile_type)

func _on_mouse_entered() -> void:
	if is_inside_tree():
		var tween := create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		tween.tween_property(self, "scale", Vector2(1.08, 1.08), 0.1)

func _on_mouse_exited() -> void:
	if is_inside_tree():
		var tween := create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		tween.tween_property(self, "scale", Vector2.ONE, 0.1)
