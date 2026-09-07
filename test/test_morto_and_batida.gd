class_name TestMortoAndBatida
extends RefCounted

const CardData = preload("res://src/core/card_data.gd")
const MeldData = preload("res://src/core/meld_data.gd")
const RoundState = preload("res://src/core/round_state.gd")

static func card(rank: CardData.Rank, suit: CardData.Suit) -> CardData:
	return CardData.new(rank, suit)

static func run(tester: Object) -> void:
	tester.describe("Morto & Batida Tests")
	
	# 1. Test Direct Batida (Batida Direta)
	var round := RoundState.new()
	round.init_round(2)
	var p0 := round.get_current_player()
	
	# Give p0 exactly 3 cards that form a valid meld
	p0.hand = [
		card(CardData.Rank.THREE, CardData.Suit.HEARTS),
		card(CardData.Rank.FOUR, CardData.Suit.HEARTS),
		card(CardData.Rank.FIVE, CardData.Suit.HEARTS)
	]
	p0.has_taken_morto = false
	round.current_phase = RoundState.TurnPhase.ACTION
	
	# Melding all 3 cards empties hand
	var meld_res := round.play_new_meld(p0.hand.duplicate())
	tester.assert_true(meld_res.is_valid, "Meld of 3♥, 4♥, 5♥ is valid")
	tester.assert_true(p0.has_taken_morto, "Player 0 took Morto directly")
	tester.assert_equal(p0.hand.size(), 11, "Player 0 now has 11 cards from Morto")
	tester.assert_equal(round.current_phase, RoundState.TurnPhase.ACTION, "Turn remains in ACTION phase after direct batida")
	tester.assert_equal(round.current_player_index, 0, "Still Player 0's turn")
	
	# 2. Test Indirect Batida (Batida Indireta)
	var round2 := RoundState.new()
	round2.init_round(2)
	var p0_2 := round2.get_current_player()
	
	# Give p0_2 exactly 1 card to discard
	var discard_c := card(CardData.Rank.KING, CardData.Suit.CLUBS)
	p0_2.hand = [discard_c]
	p0_2.has_taken_morto = false
	round2.current_phase = RoundState.TurnPhase.ACTION
	
	var disc_res := round2.discard_card(discard_c)
	tester.assert_true(disc_res, "Discarded last card")
	tester.assert_true(p0_2.has_taken_morto, "Player 0 took Morto indirectly")
	tester.assert_equal(p0_2.hand.size(), 11, "Player 0 has 11 cards from Morto for next turn")
	tester.assert_equal(round2.current_player_index, 1, "Turn passed to Player 1 after indirect batida")
	
	# 3. Test Final Batida (Going out with Clean Canasta)
	var round3 := RoundState.new()
	round3.init_round(2)
	var p0_3 := round3.get_current_player()
	p0_3.has_taken_morto = true
	
	# Give player a clean canasta on table
	var clean_canasta := MeldData.new(MeldData.MeldType.RUN, CardData.Suit.DIAMONDS, 0)
	clean_canasta.cards = [
		card(CardData.Rank.THREE, CardData.Suit.DIAMONDS),
		card(CardData.Rank.FOUR, CardData.Suit.DIAMONDS),
		card(CardData.Rank.FIVE, CardData.Suit.DIAMONDS),
		card(CardData.Rank.SIX, CardData.Suit.DIAMONDS),
		card(CardData.Rank.SEVEN, CardData.Suit.DIAMONDS),
		card(CardData.Rank.EIGHT, CardData.Suit.DIAMONDS),
		card(CardData.Rank.NINE, CardData.Suit.DIAMONDS)
	]
	clean_canasta.canasta_type = MeldData.CanastaType.CLEAN
	p0_3.melds.append(clean_canasta)
	
	# Give player 1 last card to discard
	var final_card := card(CardData.Rank.ACE, CardData.Suit.SPADES)
	p0_3.hand = [final_card]
	round3.current_phase = RoundState.TurnPhase.ACTION
	
	var final_disc := round3.discard_card(final_card)
	tester.assert_true(final_disc, "Discarded final card")
	tester.assert_true(round3.is_round_over, "Round is over")
	tester.assert_equal(round3.end_reason, RoundState.EndReason.BATIDA, "End reason is BATIDA")
	tester.assert_equal(round3.winner_player_id, 0, "Player 0 is the round winner")
