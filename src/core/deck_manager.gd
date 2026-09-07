class_name DeckManager
extends RefCounted

## Manages 108-card double deck generation, shuffling, dealing, and drawing.

const CardData = preload("res://src/core/card_data.gd")

var cards: Array[CardData] = []

func _init() -> void:
	reset_deck()

func reset_deck() -> void:
	cards.clear()
	# 2 Decks of 52 standard cards + 2 Jokers each = 108 total cards
	for deck_id in [1, 2]:
		for suit in [CardData.Suit.CLUBS, CardData.Suit.DIAMONDS, CardData.Suit.HEARTS, CardData.Suit.SPADES]:
			for rank in range(CardData.Rank.TWO, CardData.Rank.ACE + 1):
				var card := CardData.new(rank as CardData.Rank, suit, deck_id)
				cards.append(card)
		# 2 Jokers per deck
		cards.append(CardData.new(CardData.Rank.JOKER, CardData.Suit.NONE, deck_id))
		cards.append(CardData.new(CardData.Rank.JOKER, CardData.Suit.NONE, deck_id))

func shuffle(rng: RandomNumberGenerator = null) -> void:
	var n: int = cards.size()
	if rng == null:
		rng = RandomNumberGenerator.new()
		rng.randomize()
		
	# Fisher-Yates shuffle
	for i in range(n - 1, 0, -1):
		var j: int = rng.randi_range(0, i)
		var temp: CardData = cards[i]
		cards[i] = cards[j]
		cards[j] = temp

func draw_card() -> CardData:
	if cards.is_empty():
		return null
	return cards.pop_back()

func draw_cards(count: int) -> Array[CardData]:
	var drawn: Array[CardData] = []
	for i in range(count):
		var card := draw_card()
		if card != null:
			drawn.append(card)
		else:
			break
	return drawn

func deal_round(num_players: int = 2, hand_size: int = 11, morto_size: int = 11) -> Dictionary:
	var hands: Dictionary = {}
	for p in range(num_players):
		hands[p] = draw_cards(hand_size)
		
	var mortos: Array[Array] = []
	mortos.append(draw_cards(morto_size)) # Morto 1
	mortos.append(draw_cards(morto_size)) # Morto 2
	
	var initial_discard: CardData = draw_card()
	var discard_pile: Array[CardData] = []
	if initial_discard != null:
		discard_pile.append(initial_discard)
		
	var stock_pile: Array[CardData] = []
	while not cards.is_empty():
		stock_pile.append(draw_card())
		
	return {
		"hands": hands,
		"mortos": mortos,
		"discard_pile": discard_pile,
		"stock": stock_pile
	}

func cards_remaining() -> int:
	return cards.size()

func is_empty() -> bool:
	return cards.is_empty()
