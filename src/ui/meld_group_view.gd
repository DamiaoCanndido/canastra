class_name MeldGroupView
extends Control

## Visual representation of a single meld (Run or Set) on the tabletop with Clean/Dirty badges.

const CardData = preload("res://src/core/card_data.gd")
const MeldData = preload("res://src/core/meld_data.gd")
const CardView = preload("res://src/ui/card_view.gd")
const CardViewScene = preload("res://src/ui/card_view.tscn")

signal append_card_requested(meld_data: MeldData, card_data: CardData)
signal meld_clicked(meld_data: MeldData)

var meld_data: MeldData = null

@onready var cards_container: Control = $CardsContainer
@onready var badge_panel: PanelContainer = $BadgePanel
@onready var badge_label: Label = $BadgePanel/BadgeLabel

func _ready() -> void:
	gui_input.connect(_on_gui_input)

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
	if typeof(data) == TYPE_DICTIONARY and data.get("type") == "CARD":
		return meld_data != null
	return false

func _drop_data(_at_position: Vector2, data: Variant) -> void:
	if typeof(data) == TYPE_DICTIONARY and data.get("type") == "CARD":
		var dragged_card: CardData = data.get("card_data") as CardData
		if dragged_card != null:
			append_card_requested.emit(meld_data, dragged_card)

func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		meld_clicked.emit(meld_data)
