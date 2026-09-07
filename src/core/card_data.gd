class_name CardData
extends RefCounted

## Represents a single playing card in Canastra / Buraco.

enum Suit {
	CLUBS,     ## ♣ Paus
	DIAMONDS,  ## ♦ Ouros
	HEARTS,    ## ♥ Copas
	SPADES,    ## ♠ Espadas
	NONE       ## Jokers / None
}

enum Rank {
	NONE = 0,
	TWO = 2,
	THREE = 3,
	FOUR = 4,
	FIVE = 5,
	SIX = 6,
	SEVEN = 7,
	EIGHT = 8,
	NINE = 9,
	TEN = 10,
	JACK = 11,
	QUEEN = 12,
	KING = 13,
	ACE = 14,
	JOKER = 15
}

var suit: Suit = Suit.NONE
var rank: Rank = Rank.NONE
var deck_id: int = 1
var uid: String = ""

func _init(p_rank: Rank = Rank.NONE, p_suit: Suit = Suit.NONE, p_deck_id: int = 1) -> void:
	rank = p_rank
	suit = p_suit
	deck_id = p_deck_id
	uid = generate_uid()

func generate_uid() -> String:
	var s_name: String = suit_to_string(suit)
	var r_name: String = rank_to_string(rank)
	return "D%d_%s_%s" % [deck_id, s_name, r_name]

func is_joker() -> bool:
	return rank == Rank.JOKER

func is_two() -> bool:
	return rank == Rank.TWO

func is_wildcard() -> bool:
	return is_joker() or is_two()

func is_natural_two_for_suit(target_suit: Suit) -> bool:
	return rank == Rank.TWO and suit == target_suit

func get_point_value() -> int:
	match rank:
		Rank.JOKER:
			return 20
		Rank.TWO:
			return 10
		Rank.ACE:
			return 15
		Rank.EIGHT, Rank.NINE, Rank.TEN, Rank.JACK, Rank.QUEEN, Rank.KING:
			return 10
		Rank.THREE, Rank.FOUR, Rank.FIVE, Rank.SIX, Rank.SEVEN:
			return 5
		_:
			return 0

func get_display_name() -> String:
	if is_joker():
		return "Joker"
	return "%s of %s" % [rank_to_string(rank), suit_to_string(suit)]

func get_short_name() -> String:
	if is_joker():
		return "JK"
	var r_str: String
	match rank:
		Rank.ACE: r_str = "A"
		Rank.JACK: r_str = "J"
		Rank.QUEEN: r_str = "Q"
		Rank.KING: r_str = "K"
		_: r_str = str(int(rank))
	var s_sym: String
	match suit:
		Suit.CLUBS: s_sym = "♣"
		Suit.DIAMONDS: s_sym = "♦"
		Suit.HEARTS: s_sym = "♥"
		Suit.SPADES: s_sym = "♠"
		_: s_sym = ""
	return "%s%s" % [r_str, s_sym]

static func suit_to_string(p_suit: Suit) -> String:
	match p_suit:
		Suit.CLUBS: return "CLUBS"
		Suit.DIAMONDS: return "DIAMONDS"
		Suit.HEARTS: return "HEARTS"
		Suit.SPADES: return "SPADES"
		_: return "NONE"

static func rank_to_string(p_rank: Rank) -> String:
	match p_rank:
		Rank.JOKER: return "JOKER"
		Rank.ACE: return "ACE"
		Rank.KING: return "KING"
		Rank.QUEEN: return "QUEEN"
		Rank.JACK: return "JACK"
		Rank.TEN: return "10"
		Rank.NINE: return "9"
		Rank.EIGHT: return "8"
		Rank.SEVEN: return "7"
		Rank.SIX: return "6"
		Rank.FIVE: return "5"
		Rank.FOUR: return "4"
		Rank.THREE: return "3"
		Rank.TWO: return "2"
		_: return "NONE"

func duplicate_card() -> RefCounted:
	var script: GDScript = get_script() as GDScript
	var copy = script.new(rank, suit, deck_id)
	copy.uid = uid
	return copy
