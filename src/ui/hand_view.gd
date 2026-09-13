class_name HandView
extends Control

## Displays the player's hand in a dynamic, responsive fan layout.

const CardData = preload("res://src/core/card_data.gd")
const CardView = preload("res://src/ui/card_view.gd")
const CardViewScene = preload("res://src/ui/card_view.tscn")

signal card_selection_changed(selected_cards: Array[CardData])
signal card_clicked_event(card_data: CardData)
signal cards_reordered(cards: Array[CardData])
signal pile_draw_dropped(pile_type: String)

var cards: Array[CardData] = []
var card_views: Array[CardView] = []
var selected_cards: Array[CardData] = []

@export var is_interactive: bool = true
@export var is_face_up: bool = true
@export_enum("BOTTOM", "TOP") var card_alignment: String = "BOTTOM"
@export var vertical_margin: float = 16.0

enum SortMode {
	SUIT,
	RANK
}

var current_sort_mode: SortMode = SortMode.SUIT

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_PASS if is_interactive else Control.MOUSE_FILTER_IGNORE
	resized.connect(_on_resized)

func set_cards(p_cards: Array[CardData]) -> void:
	cards = p_cards.duplicate()
	if current_sort_mode == SortMode.RANK:
		_sort_cards_by_rank()
	else:
		_sort_cards_by_suit()
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

func _sort_cards_by_suit() -> void:
	cards.sort_custom(func(a: CardData, b: CardData) -> bool:
		if a.suit != b.suit:
			return int(a.suit) < int(b.suit)
		return int(a.rank) < int(b.rank)
	)

func _sort_cards_by_rank() -> void:
	cards.sort_custom(func(a: CardData, b: CardData) -> bool:
		if a.rank != b.rank:
			return int(a.rank) < int(b.rank)
		return int(a.suit) < int(b.suit)
	)

func sort_by_suit(animate: bool = true) -> void:
	current_sort_mode = SortMode.SUIT
	_sort_cards_by_suit()
	_rebuild_card_views()
	update_hand_layout(animate)

func sort_by_rank(animate: bool = true) -> void:
	current_sort_mode = SortMode.RANK
	_sort_cards_by_rank()
	_rebuild_card_views()
	update_hand_layout(animate)

func _rebuild_card_views() -> void:
	for cv in card_views:
		cv.queue_free()
	card_views.clear()

	for card_data in cards:
		var cv: CardView = CardViewScene.instantiate() as CardView
		add_child(cv)
		cv.setup(card_data, is_face_up)
		cv.set_interactive(is_interactive)
		var is_sel: bool = false
		for sc in selected_cards:
			if sc.uid == card_data.uid:
				is_sel = true
				break
		cv.set_selected(is_sel)
		cv.card_clicked.connect(_on_card_clicked)
		card_views.append(cv)

func update_hand_layout(animate: bool = true) -> void:
	var count: int = card_views.size()
	if count == 0:
		return

	var effective_width: float = size.x if size.x > 0 else 1920.0
	var effective_height: float = size.y if size.y > 0 else 210.0
	var available_width: float = clamp(effective_width - 200.0, 700.0, 1400.0)
	var max_spread_angle: float = min(30.0, float(count) * 2.2) # Dynamic spread
	var angle_step: float = 0.0
	if count > 1:
		angle_step = max_spread_angle / float(count - 1)

	var start_angle: float = -max_spread_angle / 2.0
	var center_x: float = effective_width / 2.0
	var card_width: float = 72.0
	var card_height: float = 104.0
	var card_spacing: float = min(54.0, (available_width - card_width) / float(max(1, count)))

	var base_y: float = 0.0
	if card_alignment == "BOTTOM":
		base_y = effective_height - card_height - vertical_margin
	else:
		base_y = vertical_margin

	for i in range(count):
		var cv: CardView = card_views[i]
		cv.base_z_index = i
		cv.z_index = 50 if cv.is_selected else i # Selected cards render in front
		
		var angle_deg: float = start_angle + (i * angle_step)
		var offset_x: float = center_x + (i - (count - 1) / 2.0) * card_spacing - (card_width / 2.0)
		
		var arc_y: float = 0.0
		var elevation_y: float = 0.0
		if card_alignment == "BOTTOM":
			arc_y = abs(angle_deg) * 0.7 # Parabola curve downward at edges
			elevation_y = -32.0 if cv.is_selected else 0.0 # Raise selected card up
		else:
			arc_y = abs(angle_deg) * 0.4 # Gentle arc for opponent cards
			
		var target_pos := Vector2(offset_x, base_y + arc_y + elevation_y)
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

func set_cards_ghosting(ghost_cards: Array[CardData], is_ghost: bool) -> void:
	for cv in card_views:
		var match_found: bool = false
		for gc in ghost_cards:
			if cv.card_data != null and cv.card_data.uid == gc.uid:
				match_found = true
				break
		if match_found:
			cv.modulate.a = 0.35 if is_ghost else 1.0
		else:
			cv.modulate.a = 1.0

func reset_drag_ghosting() -> void:
	for cv in card_views:
		if is_inside_tree():
			var tween := create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
			tween.tween_property(cv, "modulate:a", 1.0, 0.15)
		else:
			cv.modulate.a = 1.0

func _notification(what: int) -> void:
	if what == NOTIFICATION_DRAG_END:
		reset_drag_ghosting()

func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	if not is_interactive:
		return false
	if typeof(data) != TYPE_DICTIONARY:
		return false
	var type_str: String = data.get("type", "")
	if type_str == "CARD":
		return data.get("source_hand") == self
	elif type_str == "PILE_DRAW":
		return true
	return false

func _drop_data(at_position: Vector2, data: Variant) -> void:
	if typeof(data) != TYPE_DICTIONARY:
		return
	var type_str: String = data.get("type", "")
	if type_str == "CARD" and data.get("source_hand") == self:
		var dragged_cards: Array[CardData] = []
		if data.has("cards") and not (data["cards"] as Array).is_empty():
			for c in data["cards"]:
				if c is CardData:
					dragged_cards.append(c as CardData)
		elif data.has("card_data") and data["card_data"] is CardData:
			dragged_cards.append(data["card_data"] as CardData)
			
		if not dragged_cards.is_empty():
			_reorder_cards(dragged_cards, at_position.x)
	elif type_str == "PILE_DRAW":
		var p_type: String = str(data.get("pile_type", ""))
		if not p_type.is_empty():
			pile_draw_dropped.emit(p_type)

func _reorder_cards(dragged_cards: Array[CardData], drop_x: float) -> void:
	var target_idx: int = cards.size()
	for i in range(card_views.size()):
		var cv: CardView = card_views[i]
		var center_x: float = cv.position.x + (cv.size.x / 2.0)
		if drop_x < center_x:
			target_idx = i
			break
			
	var uids_to_move: Dictionary = {}
	for dc in dragged_cards:
		uids_to_move[dc.uid] = true
		
	var new_cards: Array[CardData] = []
	var before_target_count: int = 0
	for i in range(min(target_idx, cards.size())):
		if uids_to_move.has(cards[i].uid):
			before_target_count += 1
			
	var adjusted_target_idx: int = max(0, target_idx - before_target_count)
	
	for c in cards:
		if not uids_to_move.has(c.uid):
			new_cards.append(c)
			
	adjusted_target_idx = clamp(adjusted_target_idx, 0, new_cards.size())
	
	for i in range(dragged_cards.size()):
		new_cards.insert(adjusted_target_idx + i, dragged_cards[i])
		
	cards = new_cards
	_rebuild_card_views()
	update_hand_layout(true)
	reset_drag_ghosting()
	cards_reordered.emit(cards)

