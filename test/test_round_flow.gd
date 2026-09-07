class_name TestRoundFlow
extends RefCounted

const CardData = preload("res://src/core/card_data.gd")
const RoundState = preload("res://src/core/round_state.gd")

static func run(tester: Object) -> void:
	tester.describe("RoundFlow Tests")
	
	var round := RoundState.new()
	var rng := RandomNumberGenerator.new()
	rng.seed = 42
	round.init_round(2, rng)
	
	tester.assert_equal(round.current_player_index, 0, "Turn starts with Player 0")
	tester.assert_equal(round.current_phase, RoundState.TurnPhase.DRAW, "Turn starts in DRAW phase")
	
	# Attempt action before drawing -> should be rejected
	var p0 := round.get_current_player()
	var meld_attempt := round.play_new_meld([p0.hand[0], p0.hand[1], p0.hand[2]])
	tester.assert_false(meld_attempt.is_valid, "Cannot play meld during DRAW phase")
	
	# Draw from stock
	var initial_hand_size: int = p0.hand.size() # 11
	var initial_stock_size: int = round.stock_pile.size() # 63
	var drawn := round.draw_from_stock()
	tester.assert_true(drawn != null, "Card drawn from stock")
	tester.assert_equal(p0.hand.size(), initial_hand_size + 1, "Player hand increased by 1 (12 cards)")
	tester.assert_equal(round.stock_pile.size(), initial_stock_size - 1, "Stock decreased by 1")
	tester.assert_equal(round.current_phase, RoundState.TurnPhase.ACTION, "Phase transitioned to ACTION")
	
	# Discard a card to end turn
	var card_to_discard := p0.hand[0]
	var discarded := round.discard_card(card_to_discard)
	tester.assert_true(discarded, "Card discarded successfully")
	tester.assert_equal(p0.hand.size(), 11, "Player hand back to 11 cards")
	tester.assert_equal(round.discard_pile.size(), 2, "Discard pile now has 2 cards (initial + discarded)")
	
	# Check Player 1's turn
	tester.assert_equal(round.current_player_index, 1, "Turn advanced to Player 1")
	tester.assert_equal(round.current_phase, RoundState.TurnPhase.DRAW, "Player 1 starts in DRAW phase")
	
	# Player 1 draws from Discard Pile (Lixo)
	var p1 := round.get_current_player()
	var p1_initial_hand: int = p1.hand.size() # 11
	var lixo_cards := round.draw_from_discard_pile()
	tester.assert_equal(lixo_cards.size(), 2, "Player 1 took all 2 cards from discard pile")
	tester.assert_equal(p1.hand.size(), p1_initial_hand + 2, "Player 1 hand size is now 13")
	tester.assert_equal(round.discard_pile.size(), 0, "Discard pile is now empty")
	tester.assert_equal(round.current_phase, RoundState.TurnPhase.ACTION, "Phase transitioned to ACTION")
