class_name TestMeldValidator
extends RefCounted

const CardData = preload("res://src/core/card_data.gd")
const MeldData = preload("res://src/core/meld_data.gd")
const MeldValidator = preload("res://src/core/meld_validator.gd")

static func card(rank: CardData.Rank, suit: CardData.Suit, deck_id: int = 1) -> CardData:
	return CardData.new(rank, suit, deck_id)

static func joker(deck_id: int = 1) -> CardData:
	return CardData.new(CardData.Rank.JOKER, CardData.Suit.NONE, deck_id)

static func run(tester: Object) -> void:
	tester.describe("MeldValidator Tests")
	
	# 1. Valid clean sequence (3♥, 4♥, 5♥)
	var seq_clean: Array[CardData] = [
		card(CardData.Rank.THREE, CardData.Suit.HEARTS),
		card(CardData.Rank.FOUR, CardData.Suit.HEARTS),
		card(CardData.Rank.FIVE, CardData.Suit.HEARTS)
	]
	var res1: MeldValidator.ValidationResult = MeldValidator.validate_sequence(seq_clean)
	tester.assert_true(res1.is_valid, "3♥, 4♥, 5♥ is a valid sequence")
	tester.assert_false(res1.is_dirty, "3♥, 4♥, 5♥ is clean")
	tester.assert_equal(res1.canasta_type, MeldData.CanastaType.NONE, "3 cards is not a canasta")
	
	# 2. Clean Canasta (7 cards: 3♥ to 9♥)
	var seq_canasta_clean: Array[CardData] = [
		card(CardData.Rank.THREE, CardData.Suit.HEARTS),
		card(CardData.Rank.FOUR, CardData.Suit.HEARTS),
		card(CardData.Rank.FIVE, CardData.Suit.HEARTS),
		card(CardData.Rank.SIX, CardData.Suit.HEARTS),
		card(CardData.Rank.SEVEN, CardData.Suit.HEARTS),
		card(CardData.Rank.EIGHT, CardData.Suit.HEARTS),
		card(CardData.Rank.NINE, CardData.Suit.HEARTS)
	]
	var res2: MeldValidator.ValidationResult = MeldValidator.validate_sequence(seq_canasta_clean)
	tester.assert_true(res2.is_valid, "7-card run is valid")
	tester.assert_false(res2.is_dirty, "7-card run without wildcards is clean")
	tester.assert_equal(res2.canasta_type, MeldData.CanastaType.CLEAN, "7-card clean run is CLEAN_CANASTA")
	
	# 3. Dirty Sequence with Joker (3♥, Joker, 5♥)
	var seq_joker: Array[CardData] = [
		card(CardData.Rank.THREE, CardData.Suit.HEARTS),
		joker(),
		card(CardData.Rank.FIVE, CardData.Suit.HEARTS)
	]
	var res3: MeldValidator.ValidationResult = MeldValidator.validate_sequence(seq_joker)
	tester.assert_true(res3.is_valid, "3♥, Joker, 5♥ is valid")
	tester.assert_true(res3.is_dirty, "3♥, Joker, 5♥ is dirty")
	tester.assert_equal(res3.canasta_type, MeldData.CanastaType.NONE, "3-card dirty is not canasta")
	
	# 4. Dirty Canasta with Wildcard 2 (3♥, 2♠, 5♥, 6♥, 7♥, 8♥, 9♥)
	var seq_canasta_dirty: Array[CardData] = [
		card(CardData.Rank.THREE, CardData.Suit.HEARTS),
		card(CardData.Rank.TWO, CardData.Suit.SPADES), # Wildcard 2
		card(CardData.Rank.FIVE, CardData.Suit.HEARTS),
		card(CardData.Rank.SIX, CardData.Suit.HEARTS),
		card(CardData.Rank.SEVEN, CardData.Suit.HEARTS),
		card(CardData.Rank.EIGHT, CardData.Suit.HEARTS),
		card(CardData.Rank.NINE, CardData.Suit.HEARTS)
	]
	var res4: MeldValidator.ValidationResult = MeldValidator.validate_sequence(seq_canasta_dirty)
	tester.assert_true(res4.is_valid, "7-card run with 2♠ wildcard is valid")
	tester.assert_true(res4.is_dirty, "Run with 2♠ is dirty")
	tester.assert_equal(res4.canasta_type, MeldData.CanastaType.DIRTY, "7-card run with wildcard is DIRTY_CANASTA")
	
	# 5. Natural 2 in its own suit position (A♥, 2♥, 3♥, 4♥, 5♥, 6♥, 7♥)
	var seq_nat_two: Array[CardData] = [
		card(CardData.Rank.ACE, CardData.Suit.HEARTS),
		card(CardData.Rank.TWO, CardData.Suit.HEARTS), # Natural 2
		card(CardData.Rank.THREE, CardData.Suit.HEARTS),
		card(CardData.Rank.FOUR, CardData.Suit.HEARTS),
		card(CardData.Rank.FIVE, CardData.Suit.HEARTS),
		card(CardData.Rank.SIX, CardData.Suit.HEARTS),
		card(CardData.Rank.SEVEN, CardData.Suit.HEARTS)
	]
	var res5: MeldValidator.ValidationResult = MeldValidator.validate_sequence(seq_nat_two)
	tester.assert_true(res5.is_valid, "Run with natural 2♥ in position is valid")
	tester.assert_false(res5.is_dirty, "Run with natural 2♥ in rank 2 slot is clean")
	tester.assert_equal(res5.canasta_type, MeldData.CanastaType.CLEAN, "Run with natural 2♥ is CLEAN_CANASTA")
	
	# 6. Invalid: 2 Wildcards in sequence (3♥, Joker, 2♠, 6♥)
	var seq_two_wild: Array[CardData] = [
		card(CardData.Rank.THREE, CardData.Suit.HEARTS),
		joker(),
		card(CardData.Rank.TWO, CardData.Suit.SPADES),
		card(CardData.Rank.SIX, CardData.Suit.HEARTS)
	]
	var res6: MeldValidator.ValidationResult = MeldValidator.validate_sequence(seq_two_wild)
	tester.assert_false(res6.is_valid, "Sequence with 2 wildcards is rejected")
	
	# 7. Invalid: Suit Mismatch (3♥, 4♠, 5♥)
	var seq_mismatch: Array[CardData] = [
		card(CardData.Rank.THREE, CardData.Suit.HEARTS),
		card(CardData.Rank.FOUR, CardData.Suit.SPADES),
		card(CardData.Rank.FIVE, CardData.Suit.HEARTS)
	]
	var res7: MeldValidator.ValidationResult = MeldValidator.validate_sequence(seq_mismatch)
	tester.assert_false(res7.is_valid, "Sequence with mixed suits is rejected")
	
	# 8. High Ace sequence (J♣, Q♣, K♣, A♣)
	var seq_high_ace: Array[CardData] = [
		card(CardData.Rank.JACK, CardData.Suit.CLUBS),
		card(CardData.Rank.QUEEN, CardData.Suit.CLUBS),
		card(CardData.Rank.KING, CardData.Suit.CLUBS),
		card(CardData.Rank.ACE, CardData.Suit.CLUBS)
	]
	var res8: MeldValidator.ValidationResult = MeldValidator.validate_sequence(seq_high_ace)
	tester.assert_true(res8.is_valid, "High Ace sequence J-Q-K-A is valid")
	tester.assert_false(res8.is_dirty, "High Ace sequence is clean")
	
	# 9. Low Ace sequence (A♦, 2♦, 3♦)
	var seq_low_ace: Array[CardData] = [
		card(CardData.Rank.ACE, CardData.Suit.DIAMONDS),
		card(CardData.Rank.TWO, CardData.Suit.DIAMONDS),
		card(CardData.Rank.THREE, CardData.Suit.DIAMONDS)
	]
	var res9: MeldValidator.ValidationResult = MeldValidator.validate_sequence(seq_low_ace)
	tester.assert_true(res9.is_valid, "Low Ace sequence A-2-3 is valid")
	tester.assert_false(res9.is_dirty, "Low Ace sequence with natural 2 is clean")
	
	# 10. Invalid Ace in middle (Q♦, K♦, A♦, 2♦, 3♦)
	var seq_mid_ace: Array[CardData] = [
		card(CardData.Rank.QUEEN, CardData.Suit.DIAMONDS),
		card(CardData.Rank.KING, CardData.Suit.DIAMONDS),
		card(CardData.Rank.ACE, CardData.Suit.DIAMONDS),
		card(CardData.Rank.TWO, CardData.Suit.DIAMONDS),
		card(CardData.Rank.THREE, CardData.Suit.DIAMONDS)
	]
	var res10: MeldValidator.ValidationResult = MeldValidator.validate_sequence(seq_mid_ace)
	tester.assert_false(res10.is_valid, "Ace cannot wrap in the middle Q-K-A-2-3")
	
	# 11. Valid Set / Trinca (7♣, 7♦, 7♥)
	var set_clean: Array[CardData] = [
		card(CardData.Rank.SEVEN, CardData.Suit.CLUBS),
		card(CardData.Rank.SEVEN, CardData.Suit.DIAMONDS),
		card(CardData.Rank.SEVEN, CardData.Suit.HEARTS)
	]
	var res11: MeldValidator.ValidationResult = MeldValidator.validate_set(set_clean)
	tester.assert_true(res11.is_valid, "7♣, 7♦, 7♥ is a valid set")
	tester.assert_false(res11.is_dirty, "Set without wildcards is clean")
	
	# 12. Valid Dirty Set with Joker (7♣, Joker, 7♥)
	var set_dirty: Array[CardData] = [
		card(CardData.Rank.SEVEN, CardData.Suit.CLUBS),
		joker(),
		card(CardData.Rank.SEVEN, CardData.Suit.HEARTS)
	]
	var res12: MeldValidator.ValidationResult = MeldValidator.validate_set(set_dirty)
	tester.assert_true(res12.is_valid, "7♣, Joker, 7♥ is a valid set")
	tester.assert_true(res12.is_dirty, "Set with Joker is dirty")
	
	# 13. Appending to existing meld
	var meld := MeldData.new(MeldData.MeldType.RUN, CardData.Suit.HEARTS)
	meld.cards = [
		card(CardData.Rank.THREE, CardData.Suit.HEARTS),
		card(CardData.Rank.FOUR, CardData.Suit.HEARTS),
		joker(),
		card(CardData.Rank.SIX, CardData.Suit.HEARTS),
		card(CardData.Rank.SEVEN, CardData.Suit.HEARTS),
		card(CardData.Rank.EIGHT, CardData.Suit.HEARTS)
	]
	meld.is_dirty = true
	var append_card: Array[CardData] = [card(CardData.Rank.NINE, CardData.Suit.HEARTS)]
	var res13: MeldValidator.ValidationResult = MeldValidator.can_append_to_meld(meld, append_card)
	tester.assert_true(res13.is_valid, "Appending 9♥ to dirty 6-card run is valid")
	tester.assert_true(res13.is_dirty, "Meld remains dirty")
	tester.assert_equal(res13.canasta_type, MeldData.CanastaType.DIRTY, "Becomes DIRTY_CANASTA upon reaching 7 cards")
