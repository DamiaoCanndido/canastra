# 001 — Core Card Models & Meld Validation Engine

**Status:** Approved  
**Author:** @gamedesign  
**Date:** 2026-09-07  
**Variant / Game Mode:** Buraco Aberto / Buraco Fechado / STBL (Universal Foundation)  
**Related Specs / Issues:** Initial MVP Foundation  

---

## 1. Problem / Game Design Goal
Establish the core data structures and deterministic rule validation engine for the Canastra / Buraco card game in Godot 4. The system must represent cards, 108-card double decks, dealing distributions (hands and mortos), and evaluate meld validity (runs and sets), wildcard substitutions (2s and Jokers), and canasta classifications (Clean, Dirty, Real) headlessly without any dependency on UI nodes.

---

## 2. Rule Overview & Mechanics

### 2.1 Card Representation
- **Suits:** `CLUBS` (♣), `DIAMONDS` (♦), `HEARTS` (♥), `SPADES` (♠), `NONE`.
- **Ranks:** `2` through `10`, `JACK`, `QUEEN`, `KING`, `ACE`, `JOKER`.
- **Points:**
  - `JOKER`: 20 points
  - `TWO` (any suit): 10 points
  - `ACE`: 15 points
  - `EIGHT` through `KING`: 10 points each
  - `THREE` through `SEVEN`: 5 points each
- **Wildcards:**
  - `JOKER` is always a wildcard.
  - `TWO` of any suit can act as a wildcard (*coringa*) OR as a natural 2 in its own suit.

### 2.2 Deck & Dealing
- **Total Cards:** 108 cards (2 decks of 52 standard cards + 4 Jokers).
- **Dealing Distribution:**
  - 11 cards to Player 1 hand.
  - 11 cards to Player 2 hand.
  - 11 cards to Morto 1 (Pot 1).
  - 11 cards to Morto 2 (Pot 2).
  - Remainder (64 cards) form the Stock pile (*Monte*).
  - Initial top card flipped to form the Discard Pile (*Lixo*).

### 2.3 Meld Rules (Sequences / Runs)
- **Minimum Size:** 3 consecutive cards of the same suit.
- **Ace Wrapping:**
  - Low Ace: `[A, 2, 3...]`
  - High Ace: `[...Q, K, A]`
  - Ace cannot be placed in the middle (`[K, A, 2]` is illegal).
- **Wildcard Limit:** Maximum 1 wildcard allowed per sequence.
- **Natural 2 vs Wildcard 2:**
  - A 2 of the matching suit in its natural slot (`[A♥, 2♥, 3♥]` or `[2♥, 3♥, 4♥]`) is a **Natural 2** and does **not** dirty the meld.
  - A 2 used in place of another card (e.g. `[4♥, 2♠, 6♥]` or `[4♥, 2♥, 6♥]`) is a **Wildcard** and dirties the meld.
- **Canasta Classification:**
  - **Canasta Limpa (Clean):** 7+ sequential cards with **no wildcards**.
  - **Canasta Suja (Dirty):** 7+ sequential cards containing **1 wildcard**.
  - **Canasta de Ás a Ás (Real / 500-pt):** 14 sequential cards from Ace to Ace without wildcards (or 13/14 card complete run).

### 2.4 Sets / Groups (*Trincas / Lavadeiras*)
- 3 or more cards of the same rank with different suits (or duplicate suits from double deck).
- May contain 1 wildcard or no wildcards.
- Configurable per variant (allowed in Aberto standard, disallowed in STBL / Fechado).

---

## 3. Architecture & Data Contracts

### 3.1 Data Structures (`RefCounted`)
- `CardData`: Represents a single card with suit, rank, deck_id, unique UID, and helper methods (`is_wildcard()`, `get_point_value()`).
- `MeldData`: Represents a group of cards on the table, tracking meld type (RUN / SET), suit, cards array, clean/dirty status, and canasta status.
- `DeckManager`: Manages 108-card instantiation, Fisher-Yates deterministic shuffling with RNG seeds, dealing hands and mortos.
- `MeldValidator`: Static pure evaluation methods returning a `MeldValidationResult` struct/class.

---

## 4. Acceptance Criteria

- [ ] `DeckManager` initializes exactly 108 cards (52 x 2 + 4 Jokers).
- [ ] `DeckManager.deal_round()` distributes exactly 11 cards to 2 players, two 11-card mortos, flips 1 card to discard pile, and leaves 63 cards in stock.
- [ ] `MeldValidator.validate_sequence([3♥, 4♥, 5♥])` is valid, clean, not canasta.
- [ ] `MeldValidator.validate_sequence([3♥, 4♥, 5♥, 6♥, 7♥, 8♥, 9♥])` is valid, clean, `CLEAN_CANASTA`.
- [ ] `MeldValidator.validate_sequence([3♥, Joker, 5♥])` is valid, dirty, not canasta.
- [ ] `MeldValidator.validate_sequence([3♥, 2♠, 5♥, 6♥, 7♥, 8♥, 9♥])` is valid, dirty, `DIRTY_CANASTA`.
- [ ] `MeldValidator.validate_sequence([A♥, 2♥, 3♥, 4♥, 5♥, 6♥, 7♥])` (with natural 2♥) is valid, clean, `CLEAN_CANASTA`.
- [ ] `MeldValidator.validate_sequence([3♥, Joker, 2♠, 6♥])` (2 wildcards) is rejected as `INVALID_TOO_MANY_WILDCARDS`.
- [ ] `MeldValidator.validate_sequence([3♥, 4♠, 5♥])` (mixed suits) is rejected as `INVALID_SUIT_MISMATCH`.
- [ ] `MeldValidator.validate_sequence([K♥, A♥, 2♥])` is rejected as `INVALID_ACE_POSITION`.
- [ ] All code is statically typed GDScript 4 and passes automated headless tests via `godot4 --headless`.
