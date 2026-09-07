class_name TestUIComponents
extends RefCounted

const CardData = preload("res://src/core/card_data.gd")
const CardView = preload("res://src/ui/card_view.gd")
const CardViewScene = preload("res://src/ui/card_view.tscn")
const HandView = preload("res://src/ui/hand_view.gd")
const HandViewScene = preload("res://src/ui/hand_view.tscn")
const Tabletop = preload("res://src/ui/tabletop.gd")
const TabletopScene = preload("res://src/ui/tabletop.tscn")
const RoundState = preload("res://src/core/round_state.gd")

static func run(tester: Object) -> void:
	tester.describe("UI Components Tests")
	var root: Node = (tester as SceneTree).root
	
	# 1. CardView
	var cv: CardView = CardViewScene.instantiate() as CardView
	root.add_child(cv)
	var test_card := CardData.new(CardData.Rank.ACE, CardData.Suit.HEARTS)
	cv.setup(test_card, true)
	tester.assert_true(cv != null, "CardView instantiated successfully")
	tester.assert_equal(cv.card_data.rank, CardData.Rank.ACE, "CardView has Ace rank")
	tester.assert_equal(cv.card_data.suit, CardData.Suit.HEARTS, "CardView has Hearts suit")
	
	var card_clicked_fired: Array = [false]
	cv.card_clicked.connect(func(_view, _data): card_clicked_fired[0] = true)
	cv.card_button.emit_signal("pressed")
	tester.assert_true(card_clicked_fired[0], "CardView button press emits card_clicked signal")
	
	cv.set_selected(true)
	tester.assert_true(cv.is_selected, "CardView selection set to true")
	cv.set_selected(false)
	tester.assert_false(cv.is_selected, "CardView selection set to false")
	cv.queue_free()
	
	# 2. HandView
	var hand: HandView = HandViewScene.instantiate() as HandView
	root.add_child(hand)
	var test_cards: Array[CardData] = [
		CardData.new(CardData.Rank.TEN, CardData.Suit.SPADES),
		CardData.new(CardData.Rank.THREE, CardData.Suit.HEARTS),
		CardData.new(CardData.Rank.KING, CardData.Suit.HEARTS),
		CardData.new(CardData.Rank.FOUR, CardData.Suit.CLUBS)
	]
	hand.set_cards(test_cards)
	tester.assert_equal(hand.cards.size(), 4, "HandView holds 4 cards")
	tester.assert_equal(hand.card_views.size(), 4, "HandView created 4 CardView instances")
	tester.assert_equal(hand.cards[0].suit, CardData.Suit.CLUBS, "Auto-sorted on set_cards: Clubs first")
	
	hand.sort_by_suit()
	tester.assert_equal(hand.cards[0].suit, CardData.Suit.CLUBS, "Sorted by suit: Clubs first")
	
	hand.sort_by_rank()
	tester.assert_equal(hand.cards[0].rank, CardData.Rank.THREE, "Sorted by rank: 3 first")
	
	# Click card 0 in hand
	hand.card_views[0].card_button.emit_signal("pressed")
	tester.assert_equal(hand.get_selected_cards().size(), 1, "Clicking card 0 in HandView selects it")
	tester.assert_true(hand.card_views[0].is_selected, "Card 0 is_selected is true")
	
	# Click again to deselect
	hand.card_views[0].card_button.emit_signal("pressed")
	tester.assert_equal(hand.get_selected_cards().size(), 0, "Clicking card 0 again deselects it")
	
	hand.queue_free()
	
	# 3. Tabletop
	var tabletop: Tabletop = TabletopScene.instantiate() as Tabletop
	root.add_child(tabletop)
	tabletop._ready()
	tester.assert_true(tabletop != null, "Tabletop scene instantiated successfully")
	tester.assert_equal(Engine.max_fps, 30, "Tabletop sets Engine.max_fps to 30")
	tester.assert_true(tabletop.current_round != null, "Tabletop initialized active RoundState")
	tester.assert_equal(tabletop.player_hand.cards.size(), 11, "Player hand initialized with 11 cards")
	tester.assert_equal(tabletop.opponent_hand.cards.size(), 11, "Opponent hand initialized with 11 cards")
	tester.assert_equal(tabletop.current_round.stock_pile.size(), 63, "Stock pile has 63 cards on tabletop")
	
	# Click stock pile to draw
	tester.assert_equal(tabletop.current_round.current_phase, RoundState.TurnPhase.DRAW, "Starts in DRAW phase")
	tabletop.stock_pile.pile_button.emit_signal("pressed")
	tester.assert_equal(tabletop.current_round.current_phase, RoundState.TurnPhase.ACTION, "Stock pile click transitions phase to ACTION")
	tester.assert_equal(tabletop.player_hand.cards.size(), 12, "Player hand increased to 12 cards after drawing")
	
	# Select 1 card in hand and click Discard Pile to discard (Spec 007)
	tabletop.player_hand.card_views[0].card_button.emit_signal("pressed")
	tester.assert_equal(tabletop.player_hand.get_selected_cards().size(), 1, "1 card selected in hand")
	
	# Click discard pile to discard selected card
	var initial_hand_count: int = tabletop.player_hand.cards.size()
	tabletop.discard_pile.pile_button.emit_signal("pressed")
	tester.assert_equal(tabletop.player_hand.cards.size(), initial_hand_count - 1, "Discarding via Discard Pile click reduced hand by 1")
	
	# 4. Display Settings & 1080p Tabletop Layout (Spec 004)
	var vp_w: int = ProjectSettings.get_setting("display/window/size/viewport_width")
	var vp_h: int = ProjectSettings.get_setting("display/window/size/viewport_height")
	var stretch_mode: String = ProjectSettings.get_setting("display/window/stretch/mode")
	var stretch_aspect: String = ProjectSettings.get_setting("display/window/stretch/aspect")
	
	tester.assert_equal(vp_w, 1920, "Project viewport width is 1920")
	tester.assert_equal(vp_h, 1080, "Project viewport height is 1080")
	tester.assert_equal(stretch_mode, "canvas_items", "Stretch mode is canvas_items")
	tester.assert_equal(stretch_aspect, "expand", "Stretch aspect is expand")
	
	var opp_area: Control = tabletop.get_node("OpponentArea") as Control
	var opp_melds: Control = tabletop.get_node("OpponentMeldsScroll") as Control
	var center_tbl: Control = tabletop.get_node("CenterTable") as Control
	var ply_melds: Control = tabletop.get_node("PlayerMeldsScroll") as Control
	var ply_area: Control = tabletop.get_node("PlayerArea") as Control
	
	tester.assert_true(opp_area.offset_top >= 50.0 and opp_area.offset_bottom <= 180.0, "OpponentArea within 1080p vertical bounds")
	tester.assert_true(opp_melds.offset_top >= 170.0 and opp_melds.offset_bottom <= 350.0, "OpponentMeldsScroll within 1080p vertical bounds")
	tester.assert_true(center_tbl.offset_top >= 340.0 and center_tbl.offset_bottom <= 580.0, "CenterTable within 1080p vertical bounds")
	tester.assert_true(ply_melds.offset_top >= 580.0 and ply_melds.offset_bottom <= 770.0, "PlayerMeldsScroll within expanded vertical bounds")
	tester.assert_true(ply_area.offset_top >= 770.0 and ply_area.offset_bottom >= 1060.0 and ply_area.offset_bottom <= 1080.0, "PlayerArea expanded to 776-1068 on 1080p screen")
	
	# 5. PilesContainer Layout (Spec 005 - Middle-Right Placement)
	var piles_cont: HBoxContainer = tabletop.get_node("CenterTable/PilesContainer") as HBoxContainer
	tester.assert_true(piles_cont != null, "PilesContainer exists in CenterTable")
	tester.assert_equal(piles_cont.anchor_left, 1.0, "PilesContainer anchor_left is 1.0 (Right side)")
	tester.assert_equal(piles_cont.anchor_right, 1.0, "PilesContainer anchor_right is 1.0 (Right side)")
	tester.assert_equal(piles_cont.anchor_top, 0.5, "PilesContainer anchor_top is 0.5 (Middle vertical)")
	tester.assert_equal(piles_cont.anchor_bottom, 0.5, "PilesContainer anchor_bottom is 0.5 (Middle vertical)")
	tester.assert_true(piles_cont.offset_right <= -50.0, "PilesContainer has right padding from window edge")
	tester.assert_equal(piles_cont.get_child_count(), 3, "PilesContainer has exactly 3 piles (Stock, Discard, Morto)")
	
	# 6. Direct Table Gestures & Action Bar Elimination (Spec 007)
	tester.assert_false(tabletop.has_node("ActionBar"), "ActionBar panel completely eliminated")
	tester.assert_false(tabletop.has_node("ActionBar/HBox/MeldButton"), "MeldButton eliminated")
	tester.assert_false(tabletop.has_node("ActionBar/HBox/DiscardButton"), "DiscardButton eliminated")
	
	# Test table click with valid meld
	tabletop.current_round.current_player_index = 0
	tabletop.current_round.current_phase = RoundState.TurnPhase.ACTION
	var valid_meld_cards: Array[CardData] = [
		CardData.new(CardData.Rank.FOUR, CardData.Suit.SPADES),
		CardData.new(CardData.Rank.FIVE, CardData.Suit.SPADES),
		CardData.new(CardData.Rank.SIX, CardData.Suit.SPADES)
	]
	tabletop.current_round.players[0].hand = valid_meld_cards.duplicate()
	tabletop.player_hand.set_cards(valid_meld_cards)
	for card_view in tabletop.player_hand.card_views:
		card_view.card_button.emit_signal("pressed")
	tester.assert_equal(tabletop.player_hand.get_selected_cards().size(), 3, "Selected 3 cards for meld")
	
	tabletop._on_table_clicked()
	tester.assert_equal(tabletop.current_round.players[0].melds.size(), 1, "Clicking table melded 3 valid cards onto mesa")
	tester.assert_equal(tabletop.player_hand.get_selected_cards().size(), 0, "Hand selection cleared after successful meld")
	
	tabletop.queue_free()
