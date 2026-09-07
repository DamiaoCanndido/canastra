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
	
	# Select 1 card in hand
	tabletop.player_hand.card_views[0].card_button.emit_signal("pressed")
	tester.assert_false(tabletop.discard_button.disabled, "Discard button is enabled when 1 card is selected in ACTION phase")
	
	tabletop.queue_free()
