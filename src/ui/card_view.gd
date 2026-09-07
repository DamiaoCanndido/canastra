class_name CardView
extends Control

## Visual representation of a single card with dynamic suit/rank rendering and interaction states.

const CardData = preload("res://src/core/card_data.gd")

signal card_clicked(card_view: CardView, card_data: CardData)

var card_data: CardData = null
var is_face_up: bool = true
var is_selected: bool = false
var is_hovered: bool = false
var is_interactive: bool = true
var base_z_index: int = 0

var base_size: Vector2 = Vector2(72, 104)

@onready var background_panel: Panel = $Background
@onready var top_label: Label = $Background/TopLabel
@onready var center_label: Label = $Background/CenterLabel
@onready var bottom_label: Label = $Background/BottomLabel
@onready var selection_indicator: Panel = $Background/SelectionHighlight
@onready var card_button: Button = $CardButton

func _resolve_nodes() -> void:
	if card_button == null and has_node("CardButton"):
		card_button = get_node("CardButton") as Button
	if background_panel == null and has_node("Background"):
		background_panel = get_node("Background") as Panel
	if top_label == null and has_node("Background/TopLabel"):
		top_label = get_node("Background/TopLabel") as Label
	if center_label == null and has_node("Background/CenterLabel"):
		center_label = get_node("Background/CenterLabel") as Label
	if bottom_label == null and has_node("Background/BottomLabel"):
		bottom_label = get_node("Background/BottomLabel") as Label
	if selection_indicator == null and has_node("Background/SelectionHighlight"):
		selection_indicator = get_node("Background/SelectionHighlight") as Panel

	if card_button != null:
		if not card_button.pressed.is_connected(_on_button_pressed):
			card_button.pressed.connect(_on_button_pressed)
		if not card_button.mouse_entered.is_connected(_on_mouse_entered):
			card_button.mouse_entered.connect(_on_mouse_entered)
		if not card_button.mouse_exited.is_connected(_on_mouse_exited):
			card_button.mouse_exited.connect(_on_mouse_exited)
		if not card_button.gui_input.is_connected(_on_button_gui_input):
			card_button.gui_input.connect(_on_button_gui_input)

func _ready() -> void:
	_resolve_nodes()
	custom_minimum_size = base_size
	size = base_size
	pivot_offset = base_size / 2.0
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	update_visuals()

func setup(p_data: CardData, p_face_up: bool = true) -> void:
	_resolve_nodes()
	card_data = p_data
	is_face_up = p_face_up
	update_visuals()

func set_interactive(p_interactive: bool) -> void:
	_resolve_nodes()
	is_interactive = p_interactive
	if card_button != null:
		card_button.mouse_filter = Control.MOUSE_FILTER_STOP if is_interactive else Control.MOUSE_FILTER_IGNORE
		card_button.disabled = not is_interactive
		card_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND if is_interactive else Control.CURSOR_ARROW

func set_selected(p_selected: bool) -> void:
	_resolve_nodes()
	is_selected = p_selected
	z_index = 50 if is_selected else base_z_index
	
	if selection_indicator != null:
		selection_indicator.visible = is_selected
		
	if is_inside_tree():
		var target_scale: Vector2 = Vector2(1.08, 1.08) if is_selected else (Vector2(1.04, 1.04) if is_hovered else Vector2.ONE)
		var tween := create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		tween.tween_property(self, "scale", target_scale, 0.15)

func update_visuals() -> void:
	_resolve_nodes()
	if background_panel == null:
		return
		
	if selection_indicator != null:
		selection_indicator.visible = is_selected

	if not is_face_up or card_data == null:
		_render_card_back()
	else:
		_render_card_front()

func _render_card_front() -> void:
	var s_sym: String = _get_suit_symbol()
	var r_str: String = _get_rank_string()
	var color: Color = _get_card_color()
	
	if top_label != null: top_label.visible = true
	if center_label != null: center_label.visible = true
	if bottom_label != null: bottom_label.visible = true
	
	if card_data.is_joker():
		if top_label != null:
			top_label.text = "JK"
			top_label.add_theme_color_override("font_color", Color(0.6, 0.2, 0.8))
		if center_label != null:
			center_label.text = "★\nJOKER"
			center_label.add_theme_color_override("font_color", Color(0.6, 0.2, 0.8))
		if bottom_label != null:
			bottom_label.text = "JK"
			bottom_label.add_theme_color_override("font_color", Color(0.6, 0.2, 0.8))
	else:
		if top_label != null:
			top_label.text = "%s\n%s" % [r_str, s_sym]
			top_label.add_theme_color_override("font_color", color)
		if center_label != null:
			center_label.text = s_sym
			center_label.add_theme_color_override("font_color", color)
		if bottom_label != null:
			bottom_label.text = "%s\n%s" % [s_sym, r_str]
			bottom_label.add_theme_color_override("font_color", color)

func _render_card_back() -> void:
	if top_label != null: top_label.visible = false
	if bottom_label != null: bottom_label.visible = false
	if center_label != null:
		center_label.visible = true
		center_label.text = "🂠"
		center_label.add_theme_color_override("font_color", Color(0.2, 0.3, 0.6))

func _get_suit_symbol() -> String:
	if card_data == null: return ""
	match card_data.suit:
		CardData.Suit.CLUBS: return "♣"
		CardData.Suit.DIAMONDS: return "♦"
		CardData.Suit.HEARTS: return "♥"
		CardData.Suit.SPADES: return "♠"
		_: return ""

func _get_rank_string() -> String:
	if card_data == null: return ""
	match card_data.rank:
		CardData.Rank.ACE: return "A"
		CardData.Rank.JACK: return "J"
		CardData.Rank.QUEEN: return "Q"
		CardData.Rank.KING: return "K"
		CardData.Rank.JOKER: return "JK"
		_: return str(int(card_data.rank))

func _get_card_color() -> Color:
	if card_data == null: return Color.BLACK
	match card_data.suit:
		CardData.Suit.HEARTS, CardData.Suit.DIAMONDS:
			return Color(0.85, 0.15, 0.15) # Red
		CardData.Suit.CLUBS, CardData.Suit.SPADES:
			return Color(0.1, 0.1, 0.15) # Dark Charcoal
		_:
			return Color(0.6, 0.2, 0.8) # Joker Purple

func _on_button_pressed() -> void:
	if not is_interactive:
		return
	card_clicked.emit(self, card_data)

func _on_mouse_entered() -> void:
	if not is_interactive:
		return
	is_hovered = true
	if not is_selected and is_inside_tree():
		z_index = 30
		var tween := create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		tween.tween_property(self, "scale", Vector2(1.04, 1.04), 0.12)

func _on_mouse_exited() -> void:
	if not is_interactive:
		return
	is_hovered = false
	if not is_selected and is_inside_tree():
		z_index = base_z_index
		var tween := create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		tween.tween_property(self, "scale", Vector2.ONE, 0.12)

func _on_button_gui_input(event: InputEvent) -> void:
	if not is_interactive:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			accept_event()
			card_clicked.emit(self, card_data)

func _gui_input(event: InputEvent) -> void:
	if not is_interactive:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			accept_event()
			card_clicked.emit(self, card_data)
