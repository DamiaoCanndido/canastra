class_name HandView
extends Control

## Displays the player's hand in a dynamic, responsive fan layout.

const CardData = preload("res://src/core/card_data.gd")
const CardView = preload("res://src/ui/card_view.gd")
const CardViewScene = preload("res://src/ui/card_view.tscn")

signal card_selection_changed(selected_cards: Array[CardData])
signal card_clicked_event(card_data: CardData)

var cards: Array[CardData] = []
var card_views: Array[CardView] = []
var selected_cards: Array[CardData] = []

@export var is_interactive: bool = true
@export var is_face_up: bool = true

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(_on_resized)

func set_cards(p_cards: Array[CardData]) -> void:
	cards = p_cards.duplicate()
	selected_cards.clear()
	_rebuild_card_views()
	update_hand_layout(false)

func get_selected_cards() -> Array[CardData]:
	return selected_cards.duplicate()

func clear_selection() -> void:
	selected_cards.clear()
	for cv in card_views:
		cv.set_selected(false)
	update_hand_layout(true)
	card_selection_changed.emit(selected_cards)

func sort_by_suit() -> void:
	cards.sort_custom(func(a: CardData, b: CardData) -> bool:
		if a.suit != b.suit:
			return int(a.suit) < int(b.suit)
		return int(a.rank) < int(b.rank)
	)
	_rebuild_card_views()
	update_hand_layout(true)

func sort_by_rank() -> void:
	cards.sort_custom(func(a: CardData, b: CardData) -> bool:
		if a.rank != b.rank:
			return int(a.rank) < int(b.rank)
		return int(a.suit) < int(b.suit)
	)
	_rebuild_card_views()
	update_hand_layout(true)

func _rebuild_card_views() -> void:
	for cv in card_views:
		cv.queue_free()
	card_views.clear()

	for card_data in cards:
		var cv: CardView = CardViewScene.instantiate() as CardView
		add_child(cv)
		cv.setup(card_data, is_face_up)
		cv.set_interactive(is_interactive)
		cv.card_clicked.connect(_on_card_clicked)
		card_views.append(cv)

func update_hand_layout(animate: bool = true) -> void:
	var count: int = card_views.size()
	if count == 0:
		return

	var available_width: float = max(size.x, 700.0)
	var max_spread_angle: float = min(28.0, float(count) * 2.2) # Dynamic spread
	var angle_step: float = 0.0
	if count > 1:
		angle_step = max_spread_angle / float(count - 1)

	var start_angle: float = -max_spread_angle / 2.0
	var center_x: float = size.x / 2.0
	var card_width: float = 72.0
	var card_spacing: float = min(46.0, (available_width - card_width) / float(max(1, count)))

	for i in range(count):
		var cv: CardView = card_views[i]
		cv.base_z_index = i
		cv.z_index = 50 if cv.is_selected else i # Selected cards render in front
		
		var angle_deg: float = start_angle + (i * angle_step)
		var offset_x: float = center_x + (i - (count - 1) / 2.0) * card_spacing - (card_width / 2.0)
		var base_arc_y: float = abs(angle_deg) * 0.6 # Parabola curve
		var elevation_y: float = -28.0 if cv.is_selected else 0.0 # Raise selected card up
		
		var target_pos := Vector2(offset_x, base_arc_y + elevation_y)
		var target_rot := deg_to_rad(angle_deg)

		if animate and is_inside_tree():
			var tween := create_tween().set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
			tween.tween_property(cv, "position", target_pos, 0.18)
			tween.tween_property(cv, "rotation", target_rot, 0.18)
		else:
			cv.position = target_pos
			cv.rotation = target_rot

func _on_card_clicked(card_view: CardView, card_data: CardData) -> void:
	if not is_interactive:
		return

	if card_view.is_selected:
		card_view.set_selected(false)
		selected_cards.erase(card_data)
	else:
		card_view.set_selected(true)
		selected_cards.append(card_data)

	update_hand_layout(true)
	card_clicked_event.emit(card_data)
	card_selection_changed.emit(selected_cards)

func _on_resized() -> void:
	update_hand_layout(false)
