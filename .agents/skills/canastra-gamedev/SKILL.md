---
name: canastra-gamedev
description: >-
  Comprehensive game development guide and rule encyclopedia for Canastra / Buraco (Aberto, Fechado, STBL) in Godot Engine 4 with GDScript. Covers core models, meld validation algorithms, state machines, scoring matrices, and UI architecture.
---

# Canastra & Buraco GameDev Guide (Godot 4)

Comprehensive technical reference and rule encyclopedia for developing **Canastra / Buraco** card games in **Godot Engine 4** with **GDScript**.

---

## 1. Card & Deck System

### Deck Composition (108 Cards)
- **2 Standard 52-Card Decks:** 2 × (13 ranks × 4 suits) = 104 cards.
- **4 Jokers (*Coringões*):** 2 per physical deck.
- **Suits:** `CLUBS` (♣ Paus), `DIAMONDS` (♦ Ouros), `HEARTS` (♥ Copas), `SPADES` (♠ Espadas).
- **Ranks:** `2`, `3`, `4`, `5`, `6`, `7`, `8`, `9`, `10`, `J`, `Q`, `K`, `A`, `JOKER`.

### Card Data Structure (`CardData.gd`)
```gdscript
class_name CardData
extends RefCounted

enum Suit { CLUBS, DIAMONDS, HEARTS, SPADES, NONE }
enum Rank {
    NONE = 0,
    TWO = 2, THREE, FOUR, FIVE, SIX, SEVEN, EIGHT, NINE, TEN,
    JACK, QUEEN, KING, ACE, JOKER
}

var suit: Suit = Suit.NONE
var rank: Rank = Rank.NONE
var deck_id: int = 1 # 1 or 2
var uid: String = "" # Unique identifier (e.g. "D1_HEARTS_A")

func is_joker() -> bool:
    return rank == Rank.JOKER

func is_two() -> bool:
    return rank == Rank.TWO

func is_wildcard() -> bool:
    return is_joker() or is_two()

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
```

---

## 2. Rules & Variants Encyclopedia

| Variant | Discard Pile (*Lixo*) | Trincas / Lavadeiras | Canasta to Go Out | Notes |
|---|---|---|---|---|
| **Buraco Aberto** | Open (All visible) | Allowed or Disallowed by table config | 1 Clean Canasta minimum | Anyone can buy discard pile anytime |
| **Buraco Fechado** | Closed (Top card visible) | Prohibited (Runs only) | 1 Clean Canasta minimum | Must justify discard pile with immediate meld |
| **STBL** | Open | Prohibited (Sem Trinca) | 1 Clean Canasta minimum | Standard Brazilian competitive tournament rule |

### Sequence & Run Rules
- Minimum **3 consecutive cards** of the same suit.
- Valid sequences wrap Ace: `[A, 2, 3...]` (Ace as low) or `[...Q, K, A]` (Ace as high). Ace cannot sit in the middle (`K-A-2` is invalid).
- **Maximum 1 wildcard** (Joker or 2) per sequence.
- **Natural 2:** A 2 of the same suit in its natural position `[A♠, 2♠, 3♠]` is considered natural (clean). If another wildcard is added `[A♠, 2♠, Joker, 4♠]`, the 2 acts as a regular 2, but the Joker makes the meld dirty.

### Canasta Types
1. **Canasta Limpa (Clean Canasta):** 7 or more sequential cards with **no wildcards** (200 points).
2. **Canasta Suja (Dirty Canasta):** 7 or more sequential cards containing **1 wildcard** (100 points).
3. **Canasta de Ás a Ás (Real Canasta):** Complete run from Ace to Ace without wildcards (500 or 1000 points, if variant enabled).
4. **Canasta de 500 (Clean with Natural 2):** 7+ cards without wildcard where the 2 is present in its natural position.

---

## 3. Match & Turn State Machine

```
               [ DEAL (11 cards to players, 2 Pots of 11) ]
                                    │
                                    ▼
                     ┌──► [ TURN: DRAW PHASE ]
                     │     ├── Draw from Stock (Monte)
                     │     └── Pick Discard Pile (Lixo)
                     │              │
                     │              ▼
                     │    [ TURN: ACTION PHASE ]
                     │     ├── Place new Melds (Sequences/Sets)
                     │     └── Append cards to existing Melds
                     │              │
                     │              ▼
                     │    [ TURN: DISCARD PHASE ]
                     │     └── Discard 1 card to Discard Pile
                     │              │
                     │              ▼
                     │    [ CHECK POT / BATIDA ]
                     │     ├── Hand Empty (no discard)? ──► Pick Pot Directly & Continue Turn
                     │     ├── Hand Empty (after discard)? ──► Pick Pot Indirectly (Next Turn)
                     │     └── Hand Empty + Pot Taken + Clean Canasta? ──► [ ROUND OVER / SCORE ]
                     │              │
                     └──────────────┴── (Next Player Turn)
```

---

## 4. Scoring Matrix (`ScoreCalculator.gd`)

```gdscript
class_name ScoreCalculator
extends RefCounted

static func calculate_round_score(
    melds: Array[MeldData],
    cards_in_hand: Array[CardData],
    took_pot: bool,
    went_out: bool
) -> int:
    var total_score: int = 0
    
    # 1. Canastas bonuses
    for meld in melds:
        if meld.cards.size() >= 7:
            if meld.is_real_canasta:
                total_score += 500
            elif meld.is_clean:
                total_score += 200
            else:
                total_score += 100
                
        # 2. Individual card values in melds
        for card in meld.cards:
            total_score += card.get_point_value()
            
    # 3. Batida bonus
    if went_out:
        total_score += 100
        
    # 4. Pot penalty
    if not took_pot:
        total_score -= 100
        
    # 5. Hand deduction
    for card in cards_in_hand:
        total_score -= card.get_point_value()
        
    return total_score
```

---

## 5. Godot 4 Architectural Patterns

### 1. Decoupled Model Layer
- All rules and data structures exist in pure GDScript classes (`RefCounted`) with no dependency on `Node`, `CanvasItem`, or visual elements.
- Allows running 1,000 automated test matches headlessly in < 1 second.

### 2. Global Event / Signal Bus (`EventBus.gd`)
```gdscript
# EventBus.gd (Autoload Singleton)
extends Node

signal card_drawn(player_id: int, source: String)
signal meld_placed(player_id: int, meld_data: MeldData)
signal card_discarded(player_id: int, card: CardData)
signal pot_taken(player_id: int, is_direct: bool)
signal canasta_formed(player_id: int, canasta_type: String)
signal turn_changed(player_id: int)
signal round_ended(winner_team_id: int, scores: Dictionary)
```

### 3. Smooth Card Tweening (`CardAnimator.gd`)
```gdscript
class_name CardAnimator
extends RefCounted

static func animate_deal(card_view: Control, target_pos: Vector2, delay: float = 0.0) -> Tween:
    var tween = card_view.create_tween()
    card_view.scale = Vector2(0.5, 0.5)
    tween.tween_property(card_view, "position", target_pos, 0.35)\
        .set_delay(delay)\
        .set_trans(Tween.TRANS_CUBIC)\
        .set_ease(Tween.EASE_OUT)
    tween.parallel().tween_property(card_view, "scale", Vector2.ONE, 0.35)\
        .set_delay(delay)\
        .set_trans(Tween.TRANS_BACK)\
        .set_ease(Tween.EASE_OUT)
    return tween
```
