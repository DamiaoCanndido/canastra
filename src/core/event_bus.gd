class_name EventBus
extends Node

## Global Signal Bus for decoupling game events, networking, and UI layers.

# Deck & Hand Signals
signal card_drawn(player_id: int, source: String, card: CardData)
signal card_discarded(player_id: int, card: CardData)
signal hand_updated(player_id: int, card_count: int)

# Table & Meld Signals
signal meld_placed(player_id: int, meld_data: MeldData)
signal meld_updated(player_id: int, meld_data: MeldData)
signal canasta_formed(player_id: int, canasta_type: MeldData.CanastaType)

# Turn & Round State Signals
signal turn_started(player_id: int)
signal turn_phase_changed(player_id: int, new_phase: String)
signal pot_taken(player_id: int, is_direct: bool)
signal round_ended(winner_team_id: int, round_scores: Dictionary)
signal match_ended(winner_team_id: int, total_scores: Dictionary)
