class_name MeldData
extends RefCounted

## Represents a group of melded cards placed on the table by a player/team.

const CardData = preload("res://src/core/card_data.gd")

enum MeldType {
	RUN, ## Sequência do mesmo naipe (ex: 3♥, 4♥, 5♥)
	SET  ## Trinca / Lavadeira do mesmo valor (ex: 7♣, 7♦, 7♥)
}

enum CanastaType {
	NONE,  ## Menos de 7 cartas
	DIRTY, ## 7+ cartas contendo coringa (100 pts)
	CLEAN, ## 7+ cartas sem coringa (200 pts)
	REAL   ## De Ás a Ás sem coringa (500 pts)
}

var uid: String = ""
var meld_type: MeldType = MeldType.RUN
var suit: CardData.Suit = CardData.Suit.NONE
var cards: Array[CardData] = []
var is_dirty: bool = false
var canasta_type: CanastaType = CanastaType.NONE
var owner_team_id: int = 0

func _init(p_type: MeldType = MeldType.RUN, p_suit: CardData.Suit = CardData.Suit.NONE, p_team: int = 0) -> void:
	meld_type = p_type
	suit = p_suit
	owner_team_id = p_team
	uid = str(randi())

func is_canasta() -> bool:
	return canasta_type != CanastaType.NONE

func get_card_count() -> int:
	return cards.size()

func calculate_points() -> int:
	var pts: int = 0
	
	# Canasta bonus
	match canasta_type:
		CanastaType.REAL:
			pts += 500
		CanastaType.CLEAN:
			pts += 200
		CanastaType.DIRTY:
			pts += 100
			
	# Face value of cards in the meld
	for card in cards:
		pts += card.get_point_value()
		
	return pts

func update_status(p_is_dirty: bool, p_canasta_type: CanastaType) -> void:
	is_dirty = p_is_dirty
	canasta_type = p_canasta_type
