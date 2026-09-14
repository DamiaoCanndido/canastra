class_name TestUIComponents
extends RefCounted

const CardData = preload("res://src/core/card_data.gd")
const CardView = preload("res://src/ui/card_view.gd")
const CardViewScene = preload("res://src/ui/card_view.tscn")
const HandView = preload("res://src/ui/hand_view.gd")
const HandViewScene = preload("res://src/ui/hand_view.tscn")
const Tabletop = preload("res://src/ui/tabletop.gd")
const TabletopScene = preload("res://src/ui/tabletop.tscn")
const MeldGroupView = preload("res://src/ui/meld_group_view.gd")
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
	
	tester.assert_true(opp_area.offset_top <= 10.0 and opp_area.offset_bottom <= 130.0, "OpponentArea aligned to top border within bounds")
	tester.assert_true(opp_melds.offset_top >= 120.0 and opp_melds.offset_bottom <= 320.0, "OpponentMeldsScroll within 1080p vertical bounds")
	tester.assert_true(center_tbl.offset_top >= 300.0 and center_tbl.offset_bottom <= 570.0, "CenterTable within 1080p vertical bounds")
	tester.assert_true(ply_melds.offset_top >= 560.0 and ply_melds.offset_bottom <= 760.0, "PlayerMeldsScroll within expanded vertical bounds")
	tester.assert_true(ply_area.offset_top >= 850.0 and ply_area.offset_bottom >= 1060.0 and ply_area.offset_bottom <= 1080.0, "PlayerArea expanded to 870-1080 aligned to bottom border on 1080p screen")
	
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

	# 7. Spec 008: Direct Meld Click to append card
	var card_7s := CardData.new(CardData.Rank.SEVEN, CardData.Suit.SPADES)
	tabletop.current_round.players[0].hand = [card_7s]
	tabletop.player_hand.set_cards([card_7s])
	tabletop.player_hand.card_views[0].card_button.emit_signal("pressed")
	tester.assert_equal(tabletop.player_hand.get_selected_cards().size(), 1, "Selected 7♠ in hand")
	
	var existing_meld: MeldData = tabletop.current_round.players[0].melds[0]
	tabletop._on_meld_clicked(existing_meld)
	tester.assert_equal(existing_meld.cards.size(), 4, "Clicking meld appended 7♠ to [4♠, 5♠, 6♠]")
	tester.assert_equal(tabletop.player_hand.cards.size(), 0, "Hand empty after appending card")
	tester.assert_equal(tabletop.player_hand.get_selected_cards().size(), 0, "Selection cleared after appending")

	# 8. Spec 008: Smart Table Click Auto-Append
	var card_8s := CardData.new(CardData.Rank.EIGHT, CardData.Suit.SPADES)
	tabletop.current_round.players[0].hand = [card_8s]
	tabletop.player_hand.set_cards([card_8s])
	tabletop.player_hand.card_views[0].card_button.emit_signal("pressed")
	tester.assert_equal(tabletop.player_hand.get_selected_cards().size(), 1, "Selected 8♠ in hand")
	
	tabletop._on_table_clicked()
	tester.assert_equal(existing_meld.cards.size(), 5, "Smart table click auto-appended 8♠ to existing meld")
	tester.assert_equal(tabletop.player_hand.cards.size(), 0, "Hand empty after auto-append")

	# 9. Spec 008: CardView Drag Data
	var sample_cv: CardView = CardViewScene.instantiate() as CardView
	root.add_child(sample_cv)
	sample_cv.setup(card_7s, true)
	var drag_val: Variant = sample_cv._get_drag_data(Vector2.ZERO)
	tester.assert_true(typeof(drag_val) == TYPE_DICTIONARY, "CardView _get_drag_data returns dictionary")
	if typeof(drag_val) == TYPE_DICTIONARY:
		tester.assert_equal(drag_val.get("type"), "CARD", "Drag data type is CARD")
		tester.assert_equal(drag_val.get("card_data"), card_7s, "Drag data contains CardData")
	sample_cv.queue_free()

	# 10. Spec 008: Bot AI Appends to Existing Meld
	tabletop.current_round.current_player_index = 1
	tabletop.current_round.current_phase = RoundState.TurnPhase.ACTION
	var bot: PlayerState = tabletop.current_round.players[1]
	var bot_meld := MeldData.new(MeldData.MeldType.RUN, CardData.Suit.DIAMONDS, 1)
	var b_cards: Array[CardData] = [
		CardData.new(CardData.Rank.TEN, CardData.Suit.DIAMONDS),
		CardData.new(CardData.Rank.JACK, CardData.Suit.DIAMONDS),
		CardData.new(CardData.Rank.QUEEN, CardData.Suit.DIAMONDS)
	]
	bot_meld.cards = b_cards
	bot.melds.append(bot_meld)
	var bot_append_card := CardData.new(CardData.Rank.KING, CardData.Suit.DIAMONDS)
	var b_hand: Array[CardData] = [bot_append_card]
	bot.hand = b_hand
	tabletop._bot_try_melds(bot)
	tester.assert_equal(bot_meld.cards.size(), 4, "Bot AI successfully appended K♦ to [10♦, J♦, Q♦]")
	tester.assert_true(bot.has_taken_morto, "Bot took Morto directly upon emptying hand via append")
	tester.assert_equal(bot.hand.size(), 11, "Bot hand refreshed with 11 cards from Morto")

	# 11. Spec 009: Sort Controls (SortSuitButton and SortRankButton)
	tester.assert_true(tabletop.sort_suit_button != null, "SortSuitButton exists in PlayerArea/SortControls")
	tester.assert_true(tabletop.sort_rank_button != null, "SortRankButton exists in PlayerArea/SortControls")
	tester.assert_equal(tabletop.player_hand.current_sort_mode, HandView.SortMode.SUIT, "Initial sort mode is SUIT")
	tester.assert_true(tabletop.sort_suit_button.text.begins_with("●"), "SortSuitButton has active indicator ●")
	tester.assert_true(tabletop.sort_rank_button.text.begins_with("○"), "SortRankButton has inactive indicator ○")

	# Populate player hand with mixed cards
	var mix_cards: Array[CardData] = [
		CardData.new(CardData.Rank.SEVEN, CardData.Suit.SPADES),
		CardData.new(CardData.Rank.FOUR, CardData.Suit.HEARTS),
		CardData.new(CardData.Rank.SEVEN, CardData.Suit.CLUBS),
		CardData.new(CardData.Rank.FOUR, CardData.Suit.CLUBS)
	]
	tabletop.player_hand.set_cards(mix_cards)
	
	# Select a card before sorting
	tabletop.player_hand.card_views[0].card_button.emit_signal("pressed")
	tester.assert_equal(tabletop.player_hand.get_selected_cards().size(), 1, "Selected 1 card before sort")
	var sel_uid: String = tabletop.player_hand.get_selected_cards()[0].uid

	# Switch to RANK (Mesma Numeração) sort mode
	tabletop.sort_rank_button.emit_signal("pressed")
	tester.assert_equal(tabletop.player_hand.current_sort_mode, HandView.SortMode.RANK, "Sort mode switched to RANK")
	tester.assert_true(tabletop.sort_rank_button.text.begins_with("●"), "SortRankButton has active indicator ●")
	tester.assert_true(tabletop.sort_suit_button.text.begins_with("○"), "SortSuitButton has inactive indicator ○")
	# In RANK mode: Rank 4s first (4♣, 4♥), then Rank 7s (7♣, 7♠)
	tester.assert_equal(tabletop.player_hand.cards[0].rank, CardData.Rank.FOUR, "Rank 4 cards grouped first")
	tester.assert_equal(tabletop.player_hand.cards[1].rank, CardData.Rank.FOUR, "Rank 4 cards grouped together")
	tester.assert_equal(tabletop.player_hand.cards[2].rank, CardData.Rank.SEVEN, "Rank 7 cards grouped next")
	tester.assert_equal(tabletop.player_hand.cards[3].rank, CardData.Rank.SEVEN, "Rank 7 cards grouped together")
	# Selection preserved across sort
	tester.assert_equal(tabletop.player_hand.get_selected_cards().size(), 1, "Card selection preserved after sort")
	tester.assert_equal(tabletop.player_hand.get_selected_cards()[0].uid, sel_uid, "Same card remains selected")

	# Switch back to SUIT sort mode
	tabletop.sort_suit_button.emit_signal("pressed")
	tester.assert_equal(tabletop.player_hand.current_sort_mode, HandView.SortMode.SUIT, "Sort mode switched back to SUIT")
	tester.assert_equal(tabletop.player_hand.cards[0].suit, CardData.Suit.CLUBS, "Suit Clubs grouped first")
	tester.assert_equal(tabletop.player_hand.get_selected_cards().size(), 1, "Card selection still preserved")
	
	# 12. Spec 010: Hands Border Alignment & Relocated Sort Controls (Bottom-Right)
	var sort_controls: VBoxContainer = tabletop.get_node("PlayerArea/SortControls") as VBoxContainer
	tester.assert_true(sort_controls != null, "SortControls exists in PlayerArea")
	tester.assert_equal(sort_controls.anchor_left, 1.0, "SortControls anchor_left is 1.0 (Right side)")
	tester.assert_equal(sort_controls.anchor_right, 1.0, "SortControls anchor_right is 1.0 (Right side)")
	tester.assert_equal(sort_controls.anchor_top, 1.0, "SortControls anchor_top is 1.0 (Bottom side)")
	tester.assert_equal(sort_controls.anchor_bottom, 1.0, "SortControls anchor_bottom is 1.0 (Bottom side)")
	tester.assert_true(sort_controls.offset_right <= -30.0, "SortControls has right margin padding")
	tester.assert_true(sort_controls.offset_bottom <= -10.0, "SortControls has bottom margin padding")
	
	tester.assert_equal(tabletop.player_hand.card_alignment, "BOTTOM", "PlayerHand card_alignment is BOTTOM")
	tester.assert_equal(tabletop.opponent_hand.card_alignment, "TOP", "OpponentHand card_alignment is TOP")
	tester.assert_equal(tabletop.opponent_hand.pivot_offset, Vector2(960, 0), "OpponentHand pivot_offset centered at 960 width")
	
	# Verify card positions along borders
	tester.assert_true(tabletop.opponent_hand.card_views.size() > 0, "Opponent hand has cards")
	tester.assert_true(tabletop.opponent_hand.card_views[0].position.y <= 30.0, "Opponent card Y is aligned to top border")
	
	tester.assert_true(tabletop.player_hand.card_views.size() > 0, "Player hand has cards")
	tester.assert_true(tabletop.player_hand.card_views[0].position.y >= 0.0, "Player card Y is aligned to bottom border")
	
	# 13. Spec 011: Fullscreen Mode & TopBar Debug Elements Removal
	var win_mode: String = ProjectSettings.get_setting("display/window/size/mode")
	var borderless: bool = ProjectSettings.get_setting("display/window/size/borderless")
	tester.assert_equal(win_mode, "fullscreen", "Window mode is set to fullscreen")
	tester.assert_true(borderless, "Borderless window is enabled")
	tester.assert_false(tabletop.hud.has_node("TopBar"), "TopBar panel completely removed from HUD")
	tester.assert_true(tabletop.hud.turn_label == null, "TurnLabel is null in HudView")
	tester.assert_true(tabletop.hud.score_label == null, "ScoreLabel is null in HudView")
	tester.assert_true(tabletop.hud.get_node_or_null("PromptPanel/PromptLabel") != null or tabletop.hud.prompt_label != null, "PromptLabel is preserved in HudView")
	
	# 14. Spec 012: Comprehensive Drag & Drop Tabletop Experience
	# A. Hand Reordering via Drag & Drop
	var c0: CardData = tabletop.player_hand.cards[0]
	var reorder_payload: Dictionary = {
		"type": "CARD",
		"card_data": c0,
		"cards": [c0],
		"source_hand": tabletop.player_hand
	}
	tester.assert_true(tabletop.player_hand._can_drop_data(Vector2(200, 50), reorder_payload), "HandView can drop card for internal reordering")
	tabletop.player_hand._drop_data(Vector2(9999, 50), reorder_payload)
	tester.assert_equal(tabletop.player_hand.cards.back().uid, c0.uid, "Card dropped at far right moved to end of hand")
	
	# B. Multi-Card Drag Payload
	tabletop.player_hand.clear_selection()
	tabletop.player_hand.card_views[0].card_button.emit_signal("pressed")
	tabletop.player_hand.card_views[1].card_button.emit_signal("pressed")
	tester.assert_equal(tabletop.player_hand.get_selected_cards().size(), 2, "Selected 2 cards in hand")
	var multi_drag = tabletop.player_hand.card_views[0]._get_drag_data(Vector2.ZERO)
	tester.assert_true(typeof(multi_drag) == TYPE_DICTIONARY, "Drag payload returned valid dictionary")
	tester.assert_equal((multi_drag["cards"] as Array).size(), 2, "Multi-drag payload contains both selected cards")
	
	# C. Ghosting & Notification
	tabletop.player_hand.set_cards_ghosting([c0], true)
	for card_view_item in tabletop.player_hand.card_views:
		if card_view_item.card_data.uid == c0.uid:
			tester.assert_true(is_equal_approx(card_view_item.modulate.a, 0.35), "Dragged card has ghosting opacity 0.35")
	tabletop.player_hand.reset_drag_ghosting()
	for card_view_item in tabletop.player_hand.card_views:
		if card_view_item.card_data.uid == c0.uid:
			tester.assert_equal(card_view_item.modulate.a, 1.0, "Ghosting reset restored card opacity to 1.0")
			
	# D. Table Drag-to-Meld
	tabletop.current_round.current_player_index = 0
	tabletop.current_round.current_phase = RoundState.TurnPhase.ACTION
	var drag_meld_cards: Array[CardData] = [
		CardData.new(CardData.Rank.SEVEN, CardData.Suit.HEARTS),
		CardData.new(CardData.Rank.EIGHT, CardData.Suit.HEARTS),
		CardData.new(CardData.Rank.NINE, CardData.Suit.HEARTS)
	]
	tabletop.current_round.players[0].hand.append_array(drag_meld_cards)
	var meld_drag_payload: Dictionary = {
		"type": "CARD",
		"card_data": drag_meld_cards[0],
		"cards": drag_meld_cards,
		"source_hand": tabletop.player_hand
	}
	tester.assert_true(tabletop._can_drop_table_forward(Vector2(500, 400), meld_drag_payload), "Table accepts 3 valid cards dropped to meld")
	var initial_melds_count: int = tabletop.current_round.players[0].melds.size()
	tabletop._drop_table_forward(Vector2(500, 400), meld_drag_payload)
	tester.assert_equal(tabletop.current_round.players[0].melds.size(), initial_melds_count + 1, "Dropping valid cards on table melded them successfully")
	
	# E. MeldGroupView Drop Validation
	var new_meld_view: MeldGroupView = tabletop.player_melds_container.get_children().back() as MeldGroupView
	tester.assert_true(new_meld_view != null, "New MeldGroupView exists in player melds")
	var invalid_payload: Dictionary = {
		"type": "CARD",
		"card_data": CardData.new(CardData.Rank.KING, CardData.Suit.CLUBS),
		"cards": [CardData.new(CardData.Rank.KING, CardData.Suit.CLUBS)]
	}
	tester.assert_false(new_meld_view._can_drop_data(Vector2.ZERO, invalid_payload), "MeldGroupView rejects invalid card drop")
	var valid_append_card: CardData = CardData.new(CardData.Rank.TEN, CardData.Suit.HEARTS)
	var valid_payload: Dictionary = {
		"type": "CARD",
		"card_data": valid_append_card,
		"cards": [valid_append_card]
	}
	tester.assert_true(new_meld_view._can_drop_data(Vector2.ZERO, valid_payload), "MeldGroupView accepts valid 10♥ drop")
	
	# F. Drag from Pile to Draw
	var pile_drag = tabletop.stock_pile._get_drag_data(Vector2.ZERO)
	tester.assert_true(typeof(pile_drag) == TYPE_DICTIONARY, "Stock pile generates PILE_DRAW drag payload")
	tester.assert_equal(pile_drag["type"], "PILE_DRAW", "Payload type is PILE_DRAW")
	tester.assert_true(tabletop.player_hand._can_drop_data(Vector2.ZERO, pile_drag), "PlayerHand accepts PILE_DRAW drop")
	
	# 15. Spec 014: Four-Quadrant Card Layout & 50% Horizontal Overlap
	var quad_cv: CardView = CardViewScene.instantiate() as CardView
	root.add_child(quad_cv)
	var ten_hearts := CardData.new(CardData.Rank.TEN, CardData.Suit.HEARTS)
	quad_cv.setup(ten_hearts, true)
	
	tester.assert_true(quad_cv.rank_label != null, "RankLabel exists in CardView")
	tester.assert_true(quad_cv.suit_label != null, "SuitLabel exists in CardView")
	tester.assert_equal(quad_cv.rank_label.anchor_left, 0.0, "RankLabel anchor_left is 0.0")
	tester.assert_equal(quad_cv.rank_label.anchor_top, 0.0, "RankLabel anchor_top is 0.0")
	tester.assert_equal(quad_cv.rank_label.anchor_right, 0.5, "RankLabel in Top-Left Quadrant (anchor_right = 0.5)")
	tester.assert_equal(quad_cv.rank_label.anchor_bottom, 0.5, "RankLabel in Top-Left Quadrant (anchor_bottom = 0.5)")
	tester.assert_equal(quad_cv.suit_label.anchor_left, 0.0, "SuitLabel anchor_left is 0.0")
	tester.assert_equal(quad_cv.suit_label.anchor_top, 0.5, "SuitLabel in Bottom-Left Quadrant (anchor_top = 0.5)")
	tester.assert_equal(quad_cv.suit_label.anchor_right, 0.5, "SuitLabel in Bottom-Left Quadrant (anchor_right = 0.5)")
	tester.assert_equal(quad_cv.suit_label.anchor_bottom, 1.0, "SuitLabel in Bottom-Left Quadrant (anchor_bottom = 1.0)")
	tester.assert_equal(quad_cv.rank_label.text, "10", "RankLabel displays '10'")
	tester.assert_equal(quad_cv.suit_label.text, "♥", "SuitLabel displays '♥'")
	tester.assert_equal(quad_cv.rank_label.get_theme_font_size("font_size"), 38, "RankLabel font size is 38 for 2-character rank '10'")
	tester.assert_equal(quad_cv.suit_label.get_theme_font_size("font_size"), 48, "SuitLabel font size is 48 occupying maximum space")
	
	# Test single character rank font size
	var ace_spades := CardData.new(CardData.Rank.ACE, CardData.Suit.SPADES)
	quad_cv.setup(ace_spades, true)
	tester.assert_equal(quad_cv.rank_label.text, "A", "RankLabel displays 'A'")
	tester.assert_equal(quad_cv.suit_label.text, "♠", "SuitLabel displays '♠'")
	tester.assert_equal(quad_cv.rank_label.get_theme_font_size("font_size"), 44, "RankLabel font size is 44 for 1-character rank")
	
	# Test Joker
	var joker_card := CardData.new(CardData.Rank.JOKER, CardData.Suit.SPADES)
	quad_cv.setup(joker_card, true)
	tester.assert_equal(quad_cv.rank_label.text, "JK", "Joker rank is 'JK'")
	tester.assert_equal(quad_cv.suit_label.text, "★", "Joker suit is '★'")
	
	quad_cv.queue_free()
	
	# Test HandView 50% overlap spacing (50.0px)
	var quad_hand: HandView = HandViewScene.instantiate() as HandView
	root.add_child(quad_hand)
	var sample_cards: Array[CardData] = [
		CardData.new(CardData.Rank.FOUR, CardData.Suit.HEARTS),
		CardData.new(CardData.Rank.FIVE, CardData.Suit.HEARTS),
		CardData.new(CardData.Rank.SIX, CardData.Suit.HEARTS)
	]
	quad_hand.set_cards(sample_cards)
	quad_hand.update_hand_layout(false)
	var spacing_diff: float = quad_hand.card_views[1].position.x - quad_hand.card_views[0].position.x
	tester.assert_true(is_equal_approx(spacing_diff, 50.0), "Hand cards overlap with 50.0px spacing, covering right quadrants")
	quad_hand.queue_free()

	tabletop.queue_free()



