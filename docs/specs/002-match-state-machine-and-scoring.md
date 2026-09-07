# 002 — Match State Machine, Turn Flow, Pot & Scoring Engine

**Status:** Approved  
**Author:** @gamedesign  
**Date:** 2026-09-07  
**Variant / Game Mode:** Buraco Aberto (2 Players: 1v1)  
**Related Specs / Issues:** Extends Spec 001  

---

## 1. Problem / Game Design Goal
Define the complete round lifecycle, player turn state transitions, discard pile acquisition, pot (*morto*) triggers (direct vs indirect), going out (*batida*) validation, stock depletion fallback, and end-of-round score calculation for the Canastra card game.

---

## 2. Round Flow & Turn Lifecycle

```
[ START ROUND ] ──► Deal 11 cards to 2 players, 2 Mortos, 1 initial discard card, 63 stock
       │
       ▼
[ TURN LOOP: Player 0 / Player 1 ]
       │
       ├──► 1. DRAW PHASE
       │       ├── Option A: Draw 1 card from Stock (Monte)
       │       └── Option B: Pick entire Discard Pile (Lixo)
       │
       ├──► 2. ACTION PHASE
       │       ├── Lay down new valid melds (Sequences / Sets)
       │       ├── Append valid cards to existing team melds
       │       └── [Check Direct Batida: If hand is empty without discarding]
       │               └── Pick Morto immediately & continue ACTION PHASE
       │
       ├──► 3. DISCARD PHASE
       │       ├── Player chooses 1 card from hand to discard
       │       ├── Card added to top of Discard Pile
       │       └── [Check Indirect Batida: If hand is empty after discarding]
       │               └── Pick Morto for next turn & end current turn
       │
       └──► 4. END TURN / CHECK WIN
               ├── Check Final Batida (Hand empty + Morto taken + at least 1 Clean Canasta)
               │       └── Round ends with Batida bonus (+100)
               ├── Check Stock Depletion (Stock == 0)
               │       ├── If unused Morto exists ──► Flip to become new Stock
               │       └── If no Mortos available ──► Round ends on exhaustion
               └── Pass turn to next player
```

---

## 3. Detailed Mechanics & Rules

### 3.1 Draw Phase (`DRAW`)
- Player must draw before doing any other action.
- Drawing from **Stock**: Takes 1 top card from stock into hand.
- Drawing from **Discard Pile (*Lixo*)**: Takes **all** cards currently in the discard pile into hand. (In Buraco Aberto, no justification is required).

### 3.2 Action Phase (`ACTION`)
- Player can make multiple meld actions in any order:
  - `play_new_meld(cards)`: Validated via `MeldValidator.validate_meld()`.
  - `append_to_meld(meld_id, cards)`: Validated via `MeldValidator.can_append_to_meld()`.
- **Direct Batida Check:**
  - If a player's hand reaches 0 cards during the Action phase (without discarding), AND the player's team has not yet taken a Morto:
    - Player receives Morto 1 (or Morto 2 if Morto 1 was taken).
    - Player's `has_taken_morto` becomes `true`.
    - Player **continues their current turn** in the Action phase with their new 11 cards.

### 3.3 Discard Phase (`DISCARD`)
- Player must discard exactly 1 card from hand.
- Discarded card is placed on top of the Discard Pile.
- **Indirect Batida Check:**
  - If discarding this card reduces the player's hand to 0 cards, AND the player's team has not yet taken a Morto:
    - Player receives the Morto into hand.
    - Player's `has_taken_morto` becomes `true`.
    - Player's turn **ends**; they will play with the Morto on their next turn.

### 3.4 Final Batida (Going Out & Winning Round)
- A player/team can execute a Final Batida if and only if:
  1. Hand size is 0 (by melding all cards or discarding the last card).
  2. Team has already taken their Morto (`has_taken_morto == true`).
  3. Team possesses at least one **Clean Canasta** (`CLEAN` or `REAL`).
- If criteria are met:
  - Round ends immediately.
  - Winner receives +100 points Batida bonus.

### 3.5 Stock Depletion Fallback
- If the Stock pile reaches 0 cards:
  - If an unpicked Morto is still available on the table:
    - That Morto is converted into the new Stock pile.
  - If all Mortos have already been taken:
    - Round ends immediately with Stock Exhaustion (no Batida bonus awarded).

---

## 4. Scoring Formula (`ScoreCalculator`)

For each team/player at round end:
$$\text{Total Score} = \text{Canasta Bonus} + \text{Meld Card Points} + \text{Batida Bonus} - \text{Hand Deductions} - \text{Morto Penalty}$$

| Scoring Item | Points |
|---|---|
| **Canasta Limpa (Clean)** | +200 points each |
| **Canasta Suja (Dirty)** | +100 points each |
| **Canasta Real (Ás a Ás)** | +500 points each |
| **Final Batida Bonus** | +100 points (to winner) |
| **Cards in Melds (Table)** | Face value (+20 for Joker, +15 for A, +10 for 2, 8..K, +5 for 3..7) |
| **Cards in Hand** | Negative face value deducted point-for-point |
| **Unpicked Morto Penalty** | -100 points (if team did not pick Morto) |

---

## 5. Acceptance Criteria

- [ ] Turn begins in `Phase.DRAW`. Player cannot meld or discard before drawing.
- [ ] Drawing from stock adds 1 card and transitions state to `Phase.ACTION`.
- [ ] Drawing from discard pile adds all discard pile cards to hand and empties discard pile.
- [ ] Direct Batida: melding all cards in `Phase.ACTION` awards Morto and keeps turn in `Phase.ACTION`.
- [ ] Indirect Batida: discarding last card awards Morto and advances turn to next player.
- [ ] Final Batida is rejected if team has no Clean Canasta or has not taken Morto.
- [ ] Final Batida with Clean Canasta ends round and awards +100 pts.
- [ ] `ScoreCalculator` computes exact round scores including positive table points, canastas, batida, negative hand points, and unpicked morto penalty.
- [ ] All tests run headlessly via `godot4 --headless` with 100% pass rate.
