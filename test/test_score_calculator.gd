class_name TestScoreCalculator
extends RefCounted

const CardData = preload("res://src/core/card_data.gd")
const MeldData = preload("res://src/core/meld_data.gd")
const PlayerState = preload("res://src/core/player_state.gd")
const ScoreCalculator = preload("res://src/core/score_calculator.gd")

static func card(rank: CardData.Rank, suit: CardData.Suit) -> CardData:
	return CardData.new(rank, suit)

static func run(tester: Object) -> void:
	tester.describe("ScoreCalculator Tests")
	
	var player := PlayerState.new(0, 0)
	player.has_taken_morto = true
	
	# Create Clean Canasta (7 cards: 3♥ to 9♥)
	# Values: 3(5) + 4(5) + 5(5) + 6(5) + 7(5) + 8(10) + 9(10) = 45 card pts + 200 clean canasta = 245
	var clean_meld := MeldData.new(MeldData.MeldType.RUN, CardData.Suit.HEARTS)
	clean_meld.cards = [
		card(CardData.Rank.THREE, CardData.Suit.HEARTS),
		card(CardData.Rank.FOUR, CardData.Suit.HEARTS),
		card(CardData.Rank.FIVE, CardData.Suit.HEARTS),
		card(CardData.Rank.SIX, CardData.Suit.HEARTS),
		card(CardData.Rank.SEVEN, CardData.Suit.HEARTS),
		card(CardData.Rank.EIGHT, CardData.Suit.HEARTS),
		card(CardData.Rank.NINE, CardData.Suit.HEARTS)
	]
	clean_meld.canasta_type = MeldData.CanastaType.CLEAN
	player.melds.append(clean_meld)
	
	# Hand has 1 card: King (10 pts deduction)
	player.hand.append(card(CardData.Rank.KING, CardData.Suit.SPADES))
	
	var breakdown := ScoreCalculator.calculate_player_score(player, false)
	tester.assert_equal(breakdown.canasta_points, 200, "Clean canasta awarded 200 pts")
	tester.assert_equal(breakdown.table_card_points, 45, "Table cards sum to 45 pts")
	tester.assert_equal(breakdown.hand_penalty, 10, "Hand penalty is 10 pts")
	tester.assert_equal(breakdown.morto_penalty, 0, "No morto penalty since morto was taken")
	tester.assert_equal(breakdown.total_score, 235, "Total score is 200 + 45 - 10 = 235 pts")
	
	# Test winner going out (Batida)
	var winner := PlayerState.new(1, 1)
	winner.has_taken_morto = true
	winner.melds.append(clean_meld)
	var win_breakdown := ScoreCalculator.calculate_player_score(winner, true)
	tester.assert_equal(win_breakdown.batida_points, 100, "Winner receives 100 pts batida bonus")
	tester.assert_equal(win_breakdown.total_score, 345, "Winner total is 200 + 45 + 100 = 345 pts")
	
	# Test unpicked morto penalty (-100 pts)
	var loser := PlayerState.new(2, 2)
	loser.has_taken_morto = false
	loser.hand.append(card(CardData.Rank.ACE, CardData.Suit.HEARTS)) # 15 pts
	var lose_breakdown := ScoreCalculator.calculate_player_score(loser, false)
	tester.assert_equal(lose_breakdown.morto_penalty, 100, "Unpicked morto incurs 100 pts penalty")
	tester.assert_equal(lose_breakdown.hand_penalty, 15, "Hand penalty 15 pts")
	tester.assert_equal(lose_breakdown.total_score, -115, "Total score is -100 - 15 = -115 pts (negative score allowed)")
