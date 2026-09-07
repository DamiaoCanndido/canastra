class_name MatchManager
extends RefCounted

## Orchestrates multi-round matches, score targets, and round transitions.

const CardData = preload("res://src/core/card_data.gd")
const PlayerState = preload("res://src/core/player_state.gd")
const RoundState = preload("res://src/core/round_state.gd")
const ScoreCalculator = preload("res://src/core/score_calculator.gd")

var target_score: int = 2000
var num_players: int = 2
var cumulative_scores: Dictionary = {} # { player_id: int }
var round_history: Array[Dictionary] = []
var current_round: RoundState = null
var is_match_over: bool = false
var match_winner_id: int = -1

func _init(p_target: int = 2000, p_num_players: int = 2) -> void:
	target_score = p_target
	num_players = p_num_players
	reset_match()

func reset_match() -> void:
	cumulative_scores.clear()
	for p in range(num_players):
		cumulative_scores[p] = 0
	round_history.clear()
	is_match_over = false
	match_winner_id = -1
	current_round = null

func start_new_round(rng: RandomNumberGenerator = null) -> RoundState:
	if is_match_over:
		return null
		
	current_round = RoundState.new()
	current_round.init_round(num_players, rng)
	return current_round

func finish_current_round() -> Dictionary:
	if current_round == null or not current_round.is_round_over:
		return {}
		
	var round_results: Dictionary = {
		"end_reason": current_round.end_reason,
		"winner_player_id": current_round.winner_player_id,
		"scores": {},
		"breakdowns": {}
	}
	
	for p in current_round.players:
		var went_out: bool = (p.player_id == current_round.winner_player_id)
		var breakdown := ScoreCalculator.calculate_player_score(p, went_out)
		
		round_results["breakdowns"][p.player_id] = breakdown.to_dict()
		round_results["scores"][p.player_id] = breakdown.total_score
		
		cumulative_scores[p.player_id] += breakdown.total_score
		
	round_history.append(round_results)
	
	# Check for Match Winner
	var max_score: int = -999999
	var leader_id: int = -1
	for p_id in cumulative_scores.keys():
		var score: int = cumulative_scores[p_id]
		if score >= target_score and score > max_score:
			max_score = score
			leader_id = p_id
			
	if leader_id != -1:
		is_match_over = true
		match_winner_id = leader_id
		
	return round_results
