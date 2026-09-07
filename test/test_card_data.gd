class_name TestCardData
extends RefCounted

const CardData = preload("res://src/core/card_data.gd")

static func run(tester: Object) -> void:
	tester.describe("CardData Tests")
	
	# Points calculation
	var joker := CardData.new(CardData.Rank.JOKER, CardData.Suit.NONE)
	tester.assert_true(joker.is_joker(), "Joker rank recognized")
	tester.assert_true(joker.is_wildcard(), "Joker is wildcard")
	tester.assert_equal(joker.get_point_value(), 20, "Joker value is 20 pts")
	
	var two_hearts := CardData.new(CardData.Rank.TWO, CardData.Suit.HEARTS)
	tester.assert_true(two_hearts.is_two(), "2 rank recognized")
	tester.assert_true(two_hearts.is_wildcard(), "2 is wildcard")
	tester.assert_true(two_hearts.is_natural_two_for_suit(CardData.Suit.HEARTS), "2♥ is natural for Hearts")
	tester.assert_false(two_hearts.is_natural_two_for_suit(CardData.Suit.SPADES), "2♥ is not natural for Spades")
	tester.assert_equal(two_hearts.get_point_value(), 10, "2 value is 10 pts")
	
	var ace_spades := CardData.new(CardData.Rank.ACE, CardData.Suit.SPADES)
	tester.assert_false(ace_spades.is_wildcard(), "Ace is not wildcard")
	tester.assert_equal(ace_spades.get_point_value(), 15, "Ace value is 15 pts")
	
	var king_diamonds := CardData.new(CardData.Rank.KING, CardData.Suit.DIAMONDS)
	tester.assert_equal(king_diamonds.get_point_value(), 10, "King value is 10 pts")
	
	var seven_clubs := CardData.new(CardData.Rank.SEVEN, CardData.Suit.CLUBS)
	tester.assert_equal(seven_clubs.get_point_value(), 5, "7 value is 5 pts")
