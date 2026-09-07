class_name TestDeckManager
extends RefCounted

const CardData = preload("res://src/core/card_data.gd")
const DeckManager = preload("res://src/core/deck_manager.gd")

static func run(tester: Object) -> void:
	tester.describe("DeckManager Tests")
	
	var deck := DeckManager.new()
	tester.assert_equal(deck.cards_remaining(), 108, "Initial deck has exactly 108 cards (2 decks + 4 jokers)")
	
	# Count suits and ranks
	var jokers: int = 0
	var twos: int = 0
	for c in deck.cards:
		if c.is_joker():
			jokers += 1
		elif c.is_two():
			twos += 1
	tester.assert_equal(jokers, 4, "Deck contains exactly 4 Jokers")
	tester.assert_equal(twos, 8, "Deck contains exactly 8 Twos (2 per suit)")
	
	# Shuffle with seed
	var rng := RandomNumberGenerator.new()
	rng.seed = 12345
	deck.shuffle(rng)
	tester.assert_equal(deck.cards_remaining(), 108, "Shuffled deck still has 108 cards")
	
	# Deal round for 2 players
	var deal := deck.deal_round(2, 11, 11)
	var hands: Dictionary = deal["hands"]
	var mortos: Array = deal["mortos"]
	var discard_pile: Array = deal["discard_pile"]
	var stock: Array = deal["stock"]
	
	tester.assert_equal(hands[0].size(), 11, "Player 0 has 11 cards")
	tester.assert_equal(hands[1].size(), 11, "Player 1 has 11 cards")
	tester.assert_equal(mortos.size(), 2, "2 Mortos created")
	tester.assert_equal(mortos[0].size(), 11, "Morto 0 has 11 cards")
	tester.assert_equal(mortos[1].size(), 11, "Morto 1 has 11 cards")
	tester.assert_equal(discard_pile.size(), 1, "Discard pile has 1 initial card")
	tester.assert_equal(stock.size(), 63, "Stock pile has exactly 63 cards (108 - 22 - 22 - 1 = 63)")
