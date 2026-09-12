# 008 — Append Cards to Existing Melds & Drag-and-Drop Card Support

**Status:** Approved  
**Author:** @gamedesign, @gamedev & @uiux  
**Date:** 2026-09-12  
**Variant / Game Mode:** All (Buraco Aberto, Fechado, STBL)  
**Related Specs / Issues:** Extends Specs 001, 002, 003 & 007  

---

## 1. Problem / Game Design Goal
In physical Canastra / Buraco, a core tactical element is extending existing melds on the table (both runs/*sequências* and sets/*trincas*). For example, if a team has placed `[6♣, 7♣, 8♣]` on the table, a player can later add:
- A `9♣` or `5♣` to extend the sequence.
- A wildcard (Joker or 2) to turn it into a dirty sequence.
- A natural `2♣` (if sequence reaches 2) keeping it clean.
- Multiple cards simultaneously (e.g. `[9♣, 10♣]` or `[5♣, 9♣]`).
- Additional cards to a set (e.g. adding another `7♠` to `[7♣, 7♦, 7♥]`).

Currently in the tabletop interface:
1. `MeldGroupView` emitted `meld_clicked`, but `Tabletop` never connected this signal. Clicking on an existing meld had zero effect.
2. Clicking the table felt (`_on_table_clicked`) strictly enforced selecting $\ge 3$ cards to create a *new* meld; selecting 1 or 2 cards resulted in an error rejection (`"Selecione pelo menos 3 cartas para formar um jogo na mesa!"`).
3. Godot drag-and-drop was non-functional because `_get_drag_data` was never implemented in `CardView`.

The goal of Cycle 008 is to eliminate these barriers and make appending cards to existing melds seamless, tactile, and intuitive via both direct clicks and drag-and-drop.

---

## 2. Rule & Interaction Specifications

### 2.1 Direct Meld Click Interaction
- **Trigger:** Player selects 1 or more cards in hand, and clicks directly on a meld in their meld area (`MeldGroupView`).
- **Preconditions:**
  - `current_player_index == 0` (Player's turn).
  - `current_phase == TurnPhase.ACTION`.
  - The meld belongs to the player (`player.find_meld_by_uid(meld.uid) != null`).
  - Player has 1 or more cards selected in `player_hand`.
- **Validation & Execution:**
  - Invokes `current_round.append_to_meld(meld.uid, selected_cards)`.
  - If valid:
    - Cards are removed from player's hand.
    - Meld is updated on table with new card order, dirty flag, and canasta status.
    - Selection is cleared and UI refreshed.
    - HUD shows announcement:
      - If meld achieved Canasta status (7+ cards) on this move: `"CANASTRA FORMADA! (LIMPA/SUJA)"`.
      - If already a canasta or < 7 cards: `"Carta(s) adicionada(s) ao jogo na mesa!"`.
    - Checks for Batida (direct Morto pickup or winning the round).
  - If invalid:
    - HUD displays error explaining why the selected cards cannot be appended to that meld.
  - If no cards selected:
    - HUD displays helpful tip: `"Selecione a(s) carta(s) na sua mão antes de clicar no jogo para adicioná-la(s)."`.

### 2.2 Smart Table Felt Click Auto-Append
- **Trigger:** Player selects 1 or more cards in hand and clicks the table felt (`FeltBackground` / `_on_table_clicked`).
- **Behavior:**
  - If selected cards $\ge 3$ and valid for a new meld: creates a new meld on the table as before.
  - If selected cards do NOT form a valid new meld (or $< 3$ cards):
    - System checks player's existing melds on the table to see if the selected cards can cleanly append to one of them.
    - **Unique Match:** If exactly ONE existing meld accepts the selected cards, automatically appends to that meld!
    - **Ambiguous Match:** If more than one existing meld can accept the cards, prompts: `"Mais de um jogo pode receber esta(s) carta(s). Clique diretamente no jogo desejado!"`.
    - **No Match:** If $< 3$ cards selected and no existing meld accepts them, displays guidance: `"Para um novo jogo, selecione ao menos 3 cartas. Para adicionar a um jogo existente, clique diretamente sobre ele."`.

### 2.3 Drag and Drop Support
- `CardView` implements `_get_drag_data(at_position)`:
  - Generates drag dictionary `{ "type": "CARD", "card_data": card_data, "card_view": self }`.
  - Sets visual drag preview centered on cursor with slight opacity.
  - `card_button.set_drag_forwarding` forwards drag events to `_get_drag_data`.
- Dropping onto `MeldGroupView`:
  - If dropped on a meld during ACTION phase, appends the card to that meld.
- Dropping onto `PileView` (Discard Pile):
  - If dropped on the discard pile during ACTION phase, discards the card and advances the turn.

### 2.4 Bot AI Enhancement
- `_bot_try_melds(bot)` is enhanced so the bot also evaluates its hand against its existing table melds, appending valid cards before discarding.

---

## 3. Acceptance Criteria
- [ ] Clicking on an existing meld with 1 or more valid cards selected appends them to that meld.
- [ ] Appending 9♣ to `[6♣, 7♣, 8♣]` increases the meld to `[6♣, 7♣, 8♣, 9♣]`.
- [ ] Appending 5♣ to `[6♣, 7♣, 8♣]` increases the meld to `[5♣, 6♣, 7♣, 8♣]`.
- [ ] Appending a Joker or 2 wildcard to `[6♣, 7♣, 8♣]` marks the meld as dirty and inserts the wildcard correctly.
- [ ] Appending multiple cards at once (e.g. `[9♣, 10♣]` or `[5♣, 9♣]`) works smoothly.
- [ ] Appending the 7th card promotes the meld to Canasta and triggers HUD celebration.
- [ ] Clicking the table felt with 1-2 cards that uniquely match an existing meld auto-appends them.
- [ ] Clicking an opponent's meld informs the player that cards can only be added to their own team's melds.
- [ ] Dragging a card to a meld or the discard pile works via Godot's drag-and-drop system.
- [ ] All automated tests pass with 0 failures.
- [ ] Release packages export cleanly for Windows, Linux, and Web.
