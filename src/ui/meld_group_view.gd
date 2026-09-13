class_name MeldGroupView
extends Control

## Visual representation of a single meld (Run or Set) on the tabletop with Clean/Dirty badges.

const CardData = preload("res://src/core/card_data.gd")
const MeldData = preload("res://src/core/meld_data.gd")
const MeldValidator = preload("res://src/core/meld_validator.gd")
const CardView = preload("res://src/ui/card_view.gd")
const CardViewScene = preload("res://src/ui/card_view.tscn")

signal append_card_requested(meld_data: MeldData, card_data: CardData)
signal append_cards_requested(meld_data: MeldData, cards: Array[CardData])
signal meld_clicked(meld_data: MeldData)

var meld_data: MeldData = null

@onready var cards_container: Control = $CardsContainer
@onready var badge_panel: PanelContainer = $BadgePanel
@onready var badge_label: Label = $BadgePanel/BadgeLabel

func _ready() -> void:
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	gui_input.connect(_on_gui_input)
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)

func _on_mouse_entered() -> void:
	if is_inside_tree():
		var tween := create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		tween.tween_property(self, "modulate", Color(1.15, 1.15, 1.05), 0.12)

func _on_mouse_exited() -> void:
	if is_inside_tree():
		var tween := create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		tween.tween_property(self, "modulate", Color.WHITE, 0.12)

func setup(p_meld: MeldData) -> void:
	meld_data = p_meld
	update_visuals()

func update_visuals() -> void:
	if not is_inside_tree() or meld_data == null:
		return
		
	# Clear old card views
	for child in cards_container.get_children():
		child.queue_free()
		
	var card_count: int = meld_data.cards.size()
	var vertical_step: float = 18.0 # Overlap step in pixels
	var total_height: float = 104.0 + float(max(0, card_count - 1)) * vertical_step
	
	custom_minimum_size = Vector2(80, total_height + 30.0)
	size = custom_minimum_size
	
	for i in range(card_count):
		var c_data: CardData = meld_data.cards[i]
		var cv: CardView = CardViewScene.instantiate() as CardView
		cards_container.add_child(cv)
		cv.setup(c_data, true)
		cv.position = Vector2(4, i * vertical_step)
		cv.z_index = i
		cv.mouse_filter = Control.MOUSE_FILTER_IGNORE # Let the meld group handle drag & drop
		
	# Update Canasta badge
	if meld_data.is_canasta():
		badge_panel.visible = true
		match meld_data.canasta_type:
			MeldData.CanastaType.REAL:
				badge_label.text = "REAL (500)"
				badge_panel.modulate = Color(0.2, 0.9, 0.4)
			MeldData.CanastaType.CLEAN:
				badge_label.text = "LIMPA (200)"
				badge_panel.modulate = Color(1.0, 0.85, 0.2)
			MeldData.CanastaType.DIRTY:
				badge_label.text = "SUJA (100)"
				badge_panel.modulate = Color(0.8, 0.8, 0.85)
	else:
		badge_panel.visible = false

func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	if meld_data == null or typeof(data) != TYPE_DICTIONARY or data.get("type") != "CARD":
		return false
	var cards_to_check: Array[CardData] = []
	if data.has("cards") and not (data["cards"] as Array).is_empty():
		for c in data["cards"]:
			if c is CardData:
				cards_to_check.append(c as CardData)
	elif data.has("card_data") and data["card_data"] is CardData:
		cards_to_check.append(data["card_data"] as CardData)
	if cards_to_check.is_empty():
		return false
	var res := MeldValidator.can_append_to_meld(meld_data, cards_to_check)
	if res.is_valid:
		_set_drop_hover_highlight(true)
		return true
	return false

func _drop_data(_at_position: Vector2, data: Variant) -> void:
	_set_drop_hover_highlight(false)
	if typeof(data) == TYPE_DICTIONARY and data.get("type") == "CARD":
		var cards_to_add: Array[CardData] = []
		if data.has("cards") and not (data["cards"] as Array).is_empty():
			for c in data["cards"]:
				if c is CardData:
					cards_to_add.append(c as CardData)
		elif data.has("card_data") and data["card_data"] is CardData:
			cards_to_add.append(data["card_data"] as CardData)
			
		if not cards_to_add.is_empty():
			if cards_to_add.size() == 1:
				append_card_requested.emit(meld_data, cards_to_add[0])
			append_cards_requested.emit(meld_data, cards_to_add)

func _set_drop_hover_highlight(active: bool) -> void:
	if is_inside_tree():
		var tween := create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		if active:
			tween.tween_property(self, "modulate", Color(0.45, 1.25, 0.65), 0.1)
			tween.parallel().tween_property(self, "scale", Vector2(1.05, 1.05), 0.1)
		else:
			tween.tween_property(self, "modulate", Color.WHITE, 0.1)
			tween.parallel().tween_property(self, "scale", Vector2.ONE, 0.1)

func _notification(what: int) -> void:
	if what == NOTIFICATION_DRAG_END:
		_set_drop_hover_highlight(false)

func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		meld_clicked.emit(meld_data)
