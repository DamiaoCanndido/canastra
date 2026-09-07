class_name PlayerState
extends RefCounted

## Holds the runtime state for a single player or team in Canastra.

const CardData = preload("res://src/core/card_data.gd")
const MeldData = preload("res://src/core/meld_data.gd")

var player_id: int = 0
var team_id: int = 0
var hand: Array[CardData] = []
var melds: Array[MeldData] = []
var has_taken_morto: bool = false

func _init(p_id: int = 0, p_team: int = 0) -> void:
	player_id = p_id
	team_id = p_team

func add_card(card: CardData) -> void:
	if card != null:
		hand.append(card)

func add_cards(new_cards: Array[CardData]) -> void:
	for c in new_cards:
		add_card(c)

func remove_card(card: CardData) -> bool:
	for i in range(hand.size()):
		if hand[i].uid == card.uid:
			hand.remove_at(i)
			return true
	return false

func remove_cards(cards_to_remove: Array[CardData]) -> bool:
	# Verify all cards exist in hand first
	for c in cards_to_remove:
		var found: bool = false
		for hc in hand:
			if hc.uid == c.uid:
				found = true
				break
		if not found:
			return false
			
	# Remove cards
	for c in cards_to_remove:
		remove_card(c)
	return true

func has_clean_canasta() -> bool:
	for m in melds:
		if m.canasta_type == MeldData.CanastaType.CLEAN or m.canasta_type == MeldData.CanastaType.REAL:
			return true
	return false

func get_hand_points() -> int:
	var total: int = 0
	for c in hand:
		total += c.get_point_value()
	return total

func get_table_points() -> int:
	var total: int = 0
	for m in melds:
		total += m.calculate_points()
	return total

func find_meld_by_uid(p_uid: String) -> MeldData:
	for m in melds:
		if m.uid == p_uid:
			return m
	return null
