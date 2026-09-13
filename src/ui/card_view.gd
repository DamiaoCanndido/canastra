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

var base_size: Vector2 = Vector2(100, 145)

@onready var background_panel: Panel = $Background
@onready var front_texture: TextureRect = get_node_or_null("Background/FrontTexture") as TextureRect
@onready var back_texture: TextureRect = get_node_or_null("Background/BackTexture") as TextureRect
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
	if front_texture == null and has_node("Background/FrontTexture"):
		front_texture = get_node("Background/FrontTexture") as TextureRect
	if back_texture == null and has_node("Background/BackTexture"):
		back_texture = get_node("Background/BackTexture") as TextureRect
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
		card_button.set_drag_forwarding(_get_drag_data, _can_drop_on_card, _drop_on_card)

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
	if front_texture != null: front_texture.visible = true
	if back_texture != null: back_texture.visible = false
	
	var s_sym: String = _get_suit_symbol()
	var r_str: String = _get_rank_string()
	var color: Color = _get_card_color()
	
	if top_label != null: top_label.visible = true
	if center_label != null: center_label.visible = true
	if bottom_label != null: bottom_label.visible = true
	
	if card_data.is_joker():
		if top_label != null:
			top_label.text = "JK"
			top_label.add_theme_color_override("font_color", Color(0.65, 0.22, 0.15))
		if center_label != null:
			center_label.text = "★\nCORINGA"
			center_label.add_theme_color_override("font_color", Color(0.65, 0.22, 0.15))
		if bottom_label != null:
			bottom_label.text = "JK"
			bottom_label.add_theme_color_override("font_color", Color(0.65, 0.22, 0.15))
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
	if front_texture != null: front_texture.visible = false
	if back_texture != null: back_texture.visible = true
	if top_label != null: top_label.visible = false
	if bottom_label != null: bottom_label.visible = false
	if center_label != null: center_label.visible = false

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
	if card_data == null: return Color(0.12, 0.10, 0.12)
	match card_data.suit:
		CardData.Suit.HEARTS, CardData.Suit.DIAMONDS:
			return Color(0.72, 0.12, 0.12) # Crimson blood ink
		CardData.Suit.CLUBS, CardData.Suit.SPADES:
			return Color(0.12, 0.10, 0.12) # Dark charcoal ink
		_:
			return Color(0.65, 0.22, 0.15) # Warm rust / amber for Joker

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

func _notification(what: int) -> void:
	if what == NOTIFICATION_DRAG_END:
		var p: Node = get_parent()
		if p != null and p.has_method("reset_drag_ghosting"):
			p.reset_drag_ghosting()

func _get_drag_data(_at_position: Vector2) -> Variant:
	if not is_interactive or card_data == null:
		return null
		
	var parent_hand: Node = get_parent()
	var dragged_cards: Array[CardData] = []
	
	if is_selected and parent_hand != null and parent_hand.has_method("get_selected_cards"):
		dragged_cards = parent_hand.get_selected_cards()
		if not dragged_cards.has(card_data):
			dragged_cards.append(card_data)
	else:
		dragged_cards = [card_data]
		
	var drag_data: Dictionary = {
		"type": "CARD",
		"card_data": card_data,
		"cards": dragged_cards,
		"source_view": self,
		"source_hand": parent_hand
	}
	
	if parent_hand != null and parent_hand.has_method("set_cards_ghosting"):
		parent_hand.set_cards_ghosting(dragged_cards, true)
	
	var preview: Control = _create_drag_preview(dragged_cards)
	if is_inside_tree():
		set_drag_preview(preview)
	
	return drag_data

func _create_drag_preview(dragged_cards: Array[CardData]) -> Control:
	var preview_root := Control.new()
	preview_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	var card_scene := load("res://src/ui/card_view.tscn") as PackedScene
	if card_scene == null:
		return preview_root
		
	var count: int = dragged_cards.size()
	if count <= 1:
		var preview_cv: CardView = card_scene.instantiate() as CardView
		preview_root.add_child(preview_cv)
		preview_cv.setup(card_data, is_face_up)
		preview_cv.position = -base_size / 2.0
		preview_cv.rotation = deg_to_rad(4.0)
		preview_cv.modulate = Color(1.0, 1.0, 1.0, 0.9)
	else:
		var max_cards_to_show: int = min(count, 5)
		var offset_step := Vector2(18.0, -8.0)
		var total_offset: Vector2 = offset_step * float(max_cards_to_show - 1)
		var base_pos: Vector2 = (-base_size / 2.0) - (total_offset / 2.0)
		
		for i in range(max_cards_to_show):
			var cv: CardView = card_scene.instantiate() as CardView
			preview_root.add_child(cv)
			cv.setup(dragged_cards[i], true)
			cv.position = base_pos + (offset_step * float(i))
			cv.rotation = deg_to_rad(-6.0 + (float(i) * 3.5))
			cv.z_index = i
			cv.modulate = Color(1.0, 1.0, 1.0, 0.92)
			
		var badge := PanelContainer.new()
		var badge_style := StyleBoxFlat.new()
		badge_style.bg_color = Color(0.08, 0.4, 0.22, 0.95)
		badge_style.border_color = Color(0.4, 0.9, 0.6, 1.0)
		badge_style.set_border_width_all(1)
		badge_style.set_corner_radius_all(8)
		badge_style.content_margin_left = 8
		badge_style.content_margin_right = 8
		badge_style.content_margin_top = 3
		badge_style.content_margin_bottom = 3
		badge.add_theme_stylebox_override("panel", badge_style)
		
		var lbl := Label.new()
		lbl.text = "%d cartas" % count
		lbl.add_theme_font_size_override("font_size", 12)
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		badge.add_child(lbl)
		
		preview_root.add_child(badge)
		badge.position = Vector2(-20, 40)
		badge.z_index = 10
		
	return preview_root

func _can_drop_on_card(at_position: Vector2, data: Variant) -> bool:
	var p: Node = get_parent()
	if p != null and p.has_method("_can_drop_data"):
		return p._can_drop_data(position + at_position, data)
	return false

func _drop_on_card(at_position: Vector2, data: Variant) -> void:
	var p: Node = get_parent()
	if p != null and p.has_method("_drop_data"):
		p._drop_data(position + at_position, data)

func _gui_input(event: InputEvent) -> void:
	if not is_interactive:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			accept_event()
			card_clicked.emit(self, card_data)
