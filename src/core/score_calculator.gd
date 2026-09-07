class_name ScoreCalculator
extends RefCounted

## Calculates exact round scores and breakdowns for players and teams.

const CardData = preload("res://src/core/card_data.gd")
const MeldData = preload("res://src/core/meld_data.gd")
const PlayerState = preload("res://src/core/player_state.gd")

class ScoreBreakdown:
	extends RefCounted
	var canasta_points: int = 0
	var table_card_points: int = 0
	var batida_points: int = 0
	var hand_penalty: int = 0
	var morto_penalty: int = 0
	var total_score: int = 0
	
	var clean_canastas_count: int = 0
	var dirty_canastas_count: int = 0
	var real_canastas_count: int = 0

	func to_dict() -> Dictionary:
		return {
			"canasta_points": canasta_points,
			"table_card_points": table_card_points,
			"batida_points": batida_points,
			"hand_penalty": hand_penalty,
			"morto_penalty": morto_penalty,
			"total_score": total_score,
			"clean_canastas": clean_canastas_count,
			"dirty_canastas": dirty_canastas_count,
			"real_canastas": real_canastas_count
		}

static func calculate_player_score(player: PlayerState, went_out: bool) -> ScoreBreakdown:
	var breakdown := ScoreBreakdown.new()
	
	# 1. Melds & Canastas
	for meld in player.melds:
		match meld.canasta_type:
			MeldData.CanastaType.REAL:
				breakdown.canasta_points += 500
				breakdown.real_canastas_count += 1
			MeldData.CanastaType.CLEAN:
				breakdown.canasta_points += 200
				breakdown.clean_canastas_count += 1
			MeldData.CanastaType.DIRTY:
				breakdown.canasta_points += 100
				breakdown.dirty_canastas_count += 1
				
		for card in meld.cards:
			breakdown.table_card_points += card.get_point_value()
			
	# 2. Batida bonus (+100)
	if went_out:
		breakdown.batida_points = 100
		
	# 3. Morto penalty (-100 if not taken)
	if not player.has_taken_morto:
		breakdown.morto_penalty = 100
		
	# 4. Hand penalty (points of remaining cards in hand)
	breakdown.hand_penalty = player.get_hand_points()
	
	# 5. Total calculation
	breakdown.total_score = (
		breakdown.canasta_points
		+ breakdown.table_card_points
		+ breakdown.batida_points
		- breakdown.morto_penalty
		- breakdown.hand_penalty
	)
	
	return breakdown
