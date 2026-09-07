class_name MeldValidator
extends RefCounted

## Validates card groups for Canastra / Buraco (Sequences and Sets).

const CardData = preload("res://src/core/card_data.gd")
const MeldData = preload("res://src/core/meld_data.gd")

class ValidationResult:
	extends RefCounted
	var is_valid: bool = false
	var error_message: String = ""
	var meld_type: MeldData.MeldType = MeldData.MeldType.RUN
	var canasta_type: MeldData.CanastaType = MeldData.CanastaType.NONE
	var is_dirty: bool = false
	var suit: CardData.Suit = CardData.Suit.NONE
	var ordered_cards: Array[CardData] = []
	var wildcard_card: CardData = null
	
	static func valid_result(
		p_type: MeldData.MeldType,
		p_suit: CardData.Suit,
		p_ordered: Array[CardData],
		p_is_dirty: bool,
		p_canasta: MeldData.CanastaType,
		p_wildcard: CardData = null
	) -> ValidationResult:
		var r = ValidationResult.new()
		r.is_valid = true
		r.meld_type = p_type
		r.suit = p_suit
		r.ordered_cards = p_ordered
		r.is_dirty = p_is_dirty
		r.canasta_type = p_canasta
		r.wildcard_card = p_wildcard
		return r

	static func error_result(msg: String) -> ValidationResult:
		var r = ValidationResult.new()
		r.is_valid = false
		r.error_message = msg
		return r

static func validate_meld(cards: Array[CardData], allow_sets: bool = true) -> ValidationResult:
	if cards.size() < 3:
		return ValidationResult.error_result("Mínimo de 3 cartas necessárias para formar um jogo.")
		
	# Try sequence (RUN) first
	var run_res: ValidationResult = validate_sequence(cards)
	if run_res.is_valid:
		return run_res
		
	# If sets are allowed (Buraco Aberto standard), try SET (Trinca)
	if allow_sets:
		var set_res: ValidationResult = validate_set(cards)
		if set_res.is_valid:
			return set_res
			
	return run_res # Return the sequence error if both failed

static func validate_sequence(cards: Array[CardData]) -> ValidationResult:
	var count: int = cards.size()
	if count < 3:
		return ValidationResult.error_result("Uma sequência deve conter no mínimo 3 cartas.")
	if count > 14:
		return ValidationResult.error_result("Uma sequência não pode conter mais de 14 cartas.")

	# 1. Identify natural cards and potential suits
	var natural_cards: Array[CardData] = []
	var potential_wildcards: Array[CardData] = []
	var detected_suit: CardData.Suit = CardData.Suit.NONE

	for card in cards:
		if card.is_joker():
			potential_wildcards.append(card)
		elif card.is_two():
			# 2 can be natural or wildcard; handle during span matching
			potential_wildcards.append(card)
		else:
			natural_cards.append(card)
			if detected_suit == CardData.Suit.NONE:
				detected_suit = card.suit
			elif detected_suit != card.suit:
				return ValidationResult.error_result("Todas as cartas normais de uma sequência devem ter o mesmo naipe.")

	# If no natural cards (e.g. only 2s and Jokers), we need at least 1 suit reference from a 2
	if detected_suit == CardData.Suit.NONE:
		for card in potential_wildcards:
			if card.suit != CardData.Suit.NONE:
				detected_suit = card.suit
				break

	if detected_suit == CardData.Suit.NONE:
		return ValidationResult.error_result("Sequência não pode ser formada apenas por coringas.")

	# Check for suit consistency among non-jokers that are not wildcards
	for card in natural_cards:
		if card.suit != detected_suit:
			return ValidationResult.error_result("Cartas de naipes diferentes na mesma sequência.")

	# 2. Check each possible starting position S from 1 to (14 - count + 1)
	# Position 1 = Low Ace, Pos 2 = 2, Pos 3..13 = 3..K, Pos 14 = High Ace
	var best_result: ValidationResult = null

	for start_pos in range(1, 14 - count + 2):
		var end_pos: int = start_pos + count - 1
		var match_res := _test_sequence_span(cards, detected_suit, start_pos, end_pos)
		if match_res.is_valid:
			# If we find a clean match, prefer it immediately
			if not match_res.is_dirty:
				return match_res
			# Keep the best match found (first valid)
			if best_result == null:
				best_result = match_res

	if best_result != null:
		return best_result

	return ValidationResult.error_result("As cartas fornecidas não formam uma sequência contínua válida.")

static func _test_sequence_span(
	cards: Array[CardData],
	target_suit: CardData.Suit,
	start_pos: int,
	end_pos: int
) -> ValidationResult:
	var span_size: int = end_pos - start_pos + 1
	if span_size != cards.size():
		return ValidationResult.error_result("Tamanho do span incompatível.")

	# Map positions in span to CardData: slot_index 0 to span_size-1
	var slots: Array[CardData] = []
	slots.resize(span_size)
	for i in range(span_size):
		slots[i] = null

	var unassigned_cards: Array[CardData] = []
	var natural_2_used: bool = false

	# Step 1: Assign natural cards (Rank 3..K, and Aces)
	for card in cards:
		if card.is_joker():
			unassigned_cards.append(card)
			continue

		if card.rank == CardData.Rank.TWO:
			# If 2 has same suit and span covers position 2 (and pos 2 is empty)
			if card.suit == target_suit and start_pos <= 2 and end_pos >= 2 and not natural_2_used:
				var slot_idx: int = 2 - start_pos
				if slots[slot_idx] == null:
					slots[slot_idx] = card
					natural_2_used = true
					continue
			# Otherwise, it's a potential wildcard
			unassigned_cards.append(card)
			continue

		if card.rank == CardData.Rank.ACE:
			# Ace can go to Pos 1 (Low) or Pos 14 (High)
			var placed_ace: bool = false
			if start_pos <= 1 and end_pos >= 1 and slots[1 - start_pos] == null:
				slots[1 - start_pos] = card
				placed_ace = true
			elif start_pos <= 14 and end_pos >= 14 and slots[14 - start_pos] == null:
				slots[14 - start_pos] = card
				placed_ace = true
			
			if not placed_ace:
				return ValidationResult.error_result("Ás fora das posições permitidas (início ou fim).")
			continue

		# Standard rank 3..K
		var target_pos: int = int(card.rank)
		if target_pos < start_pos or target_pos > end_pos:
			return ValidationResult.error_result("Carta fora do intervalo da sequência.")
		var slot_idx: int = target_pos - start_pos
		if slots[slot_idx] != null:
			return ValidationResult.error_result("Carta duplicada na mesma posição da sequência.")
		slots[slot_idx] = card

	# Step 2: Fill empty slots with unassigned wildcards
	var wildcard_count: int = unassigned_cards.size()
	var empty_slots: int = 0
	for i in range(span_size):
		if slots[i] == null:
			empty_slots += 1

	if empty_slots != wildcard_count:
		return ValidationResult.error_result("Número de coringas não coincide com os espaços vazios.")

	# Rule: Max 1 wildcard per sequence!
	if wildcard_count > 1:
		return ValidationResult.error_result("Máximo de 1 coringa permitido por sequência.")

	var used_wildcard: CardData = null
	if wildcard_count == 1:
		used_wildcard = unassigned_cards[0]
		for i in range(span_size):
			if slots[i] == null:
				slots[i] = used_wildcard
				break

	var is_dirty: bool = (used_wildcard != null)
	var canasta: MeldData.CanastaType = MeldData.CanastaType.NONE

	if span_size >= 14 and not is_dirty:
		canasta = MeldData.CanastaType.REAL
	elif span_size >= 7:
		if is_dirty:
			canasta = MeldData.CanastaType.DIRTY
		else:
			canasta = MeldData.CanastaType.CLEAN

	return ValidationResult.valid_result(
		MeldData.MeldType.RUN,
		target_suit,
		slots,
		is_dirty,
		canasta,
		used_wildcard
	)

static func validate_set(cards: Array[CardData]) -> ValidationResult:
	var count: int = cards.size()
	if count < 3:
		return ValidationResult.error_result("Uma trinca deve conter no mínimo 3 cartas.")
	if count > 8:
		return ValidationResult.error_result("Uma trinca não pode conter mais de 8 cartas.")

	var target_rank: CardData.Rank = CardData.Rank.NONE
	var wildcards: Array[CardData] = []
	var natural_cards: Array[CardData] = []

	for card in cards:
		if card.is_wildcard():
			wildcards.append(card)
		else:
			natural_cards.append(card)
			if target_rank == CardData.Rank.NONE:
				target_rank = card.rank
			elif target_rank != card.rank:
				return ValidationResult.error_result("Todas as cartas normais de uma trinca devem ter o mesmo valor.")

	if target_rank == CardData.Rank.NONE:
		# All wildcards - check if pure set of 2s
		var all_twos: bool = true
		for card in cards:
			if not card.is_two():
				all_twos = false
				break
		if all_twos:
			target_rank = CardData.Rank.TWO
		else:
			return ValidationResult.error_result("Trinca não pode ser formada apenas por Jokers.")

	if wildcards.size() > 1 and target_rank != CardData.Rank.TWO:
		return ValidationResult.error_result("Máximo de 1 coringa permitido em uma trinca.")

	var is_dirty: bool = (wildcards.size() > 0 and target_rank != CardData.Rank.TWO)
	var canasta: MeldData.CanastaType = MeldData.CanastaType.NONE
	if count >= 7:
		canasta = MeldData.CanastaType.DIRTY if is_dirty else MeldData.CanastaType.CLEAN

	var ordered: Array[CardData] = []
	ordered.append_array(natural_cards)
	ordered.append_array(wildcards)

	return ValidationResult.valid_result(
		MeldData.MeldType.SET,
		CardData.Suit.NONE,
		ordered,
		is_dirty,
		canasta,
		wildcards[0] if wildcards.size() > 0 else null
	)

static func can_append_to_meld(existing_meld: MeldData, new_cards: Array[CardData]) -> ValidationResult:
	var combined: Array[CardData] = []
	combined.append_array(existing_meld.cards)
	combined.append_array(new_cards)
	
	var res: ValidationResult
	if existing_meld.meld_type == MeldData.MeldType.RUN:
		res = validate_sequence(combined)
	else:
		res = validate_set(combined)
		
	# Rule: Once dirty, a meld can never become clean!
	if existing_meld.is_dirty and res.is_valid:
		res.is_dirty = true
		if res.canasta_type == MeldData.CanastaType.CLEAN or res.canasta_type == MeldData.CanastaType.REAL:
			res.canasta_type = MeldData.CanastaType.DIRTY
			
	return res
