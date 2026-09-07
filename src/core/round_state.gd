class_name RoundState
extends RefCounted

## State machine and match logic for a single round of Canastra / Buraco.

const CardData = preload("res://src/core/card_data.gd")
const DeckManager = preload("res://src/core/deck_manager.gd")
const MeldData = preload("res://src/core/meld_data.gd")
const MeldValidator = preload("res://src/core/meld_validator.gd")
const PlayerState = preload("res://src/core/player_state.gd")
const ScoreCalculator = preload("res://src/core/score_calculator.gd")

enum TurnPhase {
	DRAW,        ## Jogador deve comprar do Monte ou recolher o Lixo
	ACTION,      ## Jogador pode baixar novos jogos ou adicionar a jogos existentes
	DISCARD,     ## Jogador deve descartar uma carta para encerrar o turno
	ROUND_OVER   ## A rodada terminou (por batida ou esgotamento do monte)
}

enum EndReason {
	NONE,
	BATIDA,
	STOCK_EXHAUSTED
}

var players: Array[PlayerState] = []
var mortos: Array[Array] = []
var stock_pile: Array[CardData] = []
var discard_pile: Array[CardData] = []

var current_player_index: int = 0
var current_phase: TurnPhase = TurnPhase.DRAW
var is_round_over: bool = false
var end_reason: EndReason = EndReason.NONE
var winner_player_id: int = -1

func init_round(num_players: int = 2, rng: RandomNumberGenerator = null) -> void:
	var deck_mgr := DeckManager.new()
	deck_mgr.shuffle(rng)
	
	var deal := deck_mgr.deal_round(num_players, 11, 11)
	
	players.clear()
	for p in range(num_players):
		var p_state := PlayerState.new(p, p)
		var hand_cards: Array = deal["hands"][p]
		for c in hand_cards:
			p_state.add_card(c)
		players.append(p_state)
		
	mortos = deal["mortos"]
	discard_pile.clear()
	for c in deal["discard_pile"]:
		discard_pile.append(c)
		
	stock_pile.clear()
	for c in deal["stock"]:
		stock_pile.append(c)
		
	current_player_index = 0
	current_phase = TurnPhase.DRAW
	is_round_over = false
	end_reason = EndReason.NONE
	winner_player_id = -1

func get_current_player() -> PlayerState:
	if players.is_empty() or current_player_index >= players.size():
		return null
	return players[current_player_index]

func draw_from_stock() -> CardData:
	if is_round_over or current_phase != TurnPhase.DRAW:
		return null
		
	if stock_pile.is_empty():
		_handle_stock_exhaustion()
		if stock_pile.is_empty():
			return null
			
	var drawn_card: CardData = stock_pile.pop_back()
	var player := get_current_player()
	player.add_card(drawn_card)
	
	current_phase = TurnPhase.ACTION
	return drawn_card

func draw_from_discard_pile() -> Array[CardData]:
	if is_round_over or current_phase != TurnPhase.DRAW or discard_pile.is_empty():
		return []
		
	var drawn_cards: Array[CardData] = []
	drawn_cards.append_array(discard_pile)
	discard_pile.clear()
	
	var player := get_current_player()
	player.add_cards(drawn_cards)
	
	current_phase = TurnPhase.ACTION
	return drawn_cards

func play_new_meld(cards_to_meld: Array[CardData]) -> MeldValidator.ValidationResult:
	if is_round_over or current_phase != TurnPhase.ACTION:
		return MeldValidator.ValidationResult.error_result("Ação permitida apenas na fase de AÇÃO.")
		
	var player := get_current_player()
	
	# Verify player has the cards
	var valid_hand: bool = true
	for c in cards_to_meld:
		var count_in_meld: int = 0
		for mc in cards_to_meld:
			if mc.uid == c.uid: count_in_meld += 1
		var count_in_hand: int = 0
		for hc in player.hand:
			if hc.uid == c.uid: count_in_hand += 1
		if count_in_meld > count_in_hand:
			valid_hand = false
			break
			
	if not valid_hand:
		return MeldValidator.ValidationResult.error_result("Você não possui todas essas cartas na mão.")
		
	var result := MeldValidator.validate_meld(cards_to_meld, true)
	if not result.is_valid:
		return result
		
	# Remove cards from hand
	player.remove_cards(cards_to_meld)
	
	# Create and register MeldData
	var meld := MeldData.new(result.meld_type, result.suit, player.team_id)
	meld.cards = result.ordered_cards
	meld.is_dirty = result.is_dirty
	meld.canasta_type = result.canasta_type
	player.melds.append(meld)
	
	# Check Direct Batida
	_check_action_phase_batida()
	
	return result

func append_to_meld(meld_uid: String, cards_to_append: Array[CardData]) -> MeldValidator.ValidationResult:
	if is_round_over or current_phase != TurnPhase.ACTION:
		return MeldValidator.ValidationResult.error_result("Ação permitida apenas na fase de AÇÃO.")
		
	var player := get_current_player()
	var meld := player.find_meld_by_uid(meld_uid)
	if meld == null:
		return MeldValidator.ValidationResult.error_result("Jogo não encontrado na mesa.")
		
	# Verify player has the cards
	var valid_hand: bool = true
	for c in cards_to_append:
		var count_in_meld: int = 0
		for mc in cards_to_append:
			if mc.uid == c.uid: count_in_meld += 1
		var count_in_hand: int = 0
		for hc in player.hand:
			if hc.uid == c.uid: count_in_hand += 1
		if count_in_meld > count_in_hand:
			valid_hand = false
			break
			
	if not valid_hand:
		return MeldValidator.ValidationResult.error_result("Você não possui todas essas cartas na mão.")
		
	var result := MeldValidator.can_append_to_meld(meld, cards_to_append)
	if not result.is_valid:
		return result
		
	# Remove cards from hand
	player.remove_cards(cards_to_append)
	
	# Update meld
	meld.cards = result.ordered_cards
	meld.is_dirty = result.is_dirty
	meld.canasta_type = result.canasta_type
	
	# Check Direct Batida
	_check_action_phase_batida()
	
	return result

func discard_card(card: CardData) -> bool:
	if is_round_over or current_phase != TurnPhase.ACTION:
		return false
		
	var player := get_current_player()
	var removed := player.remove_card(card)
	if not removed:
		return false
		
	discard_pile.append(card)
	
	# Check Indirect Batida or Final Batida after discard
	if player.hand.is_empty():
		if not player.has_taken_morto:
			# Indirect Batida: Take Morto and end turn
			var morto: Array = _take_next_morto()
			if not morto.is_empty():
				for mc in morto:
					player.add_card(mc)
				player.has_taken_morto = true
		else:
			# Final Batida check
			if player.has_clean_canasta():
				_end_round(EndReason.BATIDA, player.player_id)
				return true
				
	if not is_round_over:
		_advance_turn()
		
	return true

func _check_action_phase_batida() -> void:
	var player := get_current_player()
	if player.hand.is_empty():
		if not player.has_taken_morto:
			# Direct Batida: Pick Morto immediately and continue Action phase
			var morto: Array = _take_next_morto()
			if not morto.is_empty():
				for mc in morto:
					player.add_card(mc)
				player.has_taken_morto = true
				# Turn remains in ACTION phase!
		else:
			# Final Batida directly by melding all cards
			if player.has_clean_canasta():
				_end_round(EndReason.BATIDA, player.player_id)

func _take_next_morto() -> Array:
	if mortos.is_empty():
		return []
	return mortos.pop_front()

func _handle_stock_exhaustion() -> void:
	if not mortos.is_empty():
		var unused_morto: Array = mortos.pop_front()
		for c in unused_morto:
			stock_pile.append(c)
	else:
		_end_round(EndReason.STOCK_EXHAUSTED)

func _advance_turn() -> void:
	current_player_index = (current_player_index + 1) % players.size()
	current_phase = TurnPhase.DRAW
	
	# Check if stock is exhausted before new turn draws
	if stock_pile.is_empty():
		_handle_stock_exhaustion()

func _end_round(reason: EndReason, winner_id: int = -1) -> void:
	is_round_over = true
	end_reason = reason
	winner_player_id = winner_id
	current_phase = TurnPhase.ROUND_OVER
