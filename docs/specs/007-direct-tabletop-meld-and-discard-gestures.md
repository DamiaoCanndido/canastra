# 007 — Direct Tabletop Meld & Discard Gestures (Action Bar Elimination)

**Status:** Approved  
**Author:** @gamedesign & @uiux  
**Date:** 2026-09-07  
**Variant / Game Mode:** All (Tabletop UI & Input Interaction)  
**Related Specs / Issues:** Extends Specs 003, 004, 005 & 006  

---

## 1. Problem / Game Design Goal
Traditional digital card games often rely on artificial button bars (such as "Baixar Jogo" and "Descartar") that disconnect players from the physical metaphor of a card table. In physical Canastra, players interact directly with the table: they place valid melds onto the felt, and they throw discards directly into the discard pile (*lixo*).

The goal of this cycle is to:
1. **Eliminate the "Baixar Jogo" button:** When a player has selected cards in hand ($\ge 3$ cards) during the `ACTION` phase, clicking directly on the table (mesa / melds zone) automatically validates and places the meld onto the table.
2. **Eliminate the "Descartar" button:** To discard, the player selects 1 card in hand and clicks directly on the Discard Pile (Lixo).
3. **Eliminate the `ActionBar` panel:** With both buttons discarded, the entire bottom Action Bar is eliminated, allocating the reclaimed vertical space to the table melds and the player's dynamic hand fan.
4. Maintain dual support for Drag & Drop onto the Discard Pile.

---

## 2. Interaction Specifications

### 2.1 Direct Meld on Table Click
- **Trigger:** Player clicks the mesa felt (`FeltBackground`), `CenterTable`, or `PlayerMeldsScroll` area with mouse left click.
- **Preconditions:**
  - `current_player_index == 0` (Player's turn)
  - `current_phase == TurnPhase.ACTION`
  - Selected cards in `player_hand` $\ge 3$
- **Behavior:**
  - If the combination is valid: calls `play_new_meld(selected_cards)`, clears selection, refreshes UI, and triggers canasta celebration if applicable.
  - If invalid: shows clear error announcement via HUD (e.g. "Erro: O jogo precisa de pelo menos 3 cartas sequenciais do mesmo naipe ou trinca.").
  - If $< 3$ cards selected: shows guidance announcement ("Selecione pelo menos 3 cartas para formar um jogo na mesa.").

### 2.2 Direct Discard on Discard Pile Click
- **Trigger:** Player clicks `discard_pile` (`CenterTable/PilesContainer/DiscardPile/PileButton`).
- **Preconditions & Context Switching:**
  - **In `TurnPhase.DRAW`:**
    - Player draws the entire discard pile as before.
  - **In `TurnPhase.ACTION`:**
    - If exactly 1 card is selected in `player_hand`: calls `discard_card(selected_card)`, completes the discard, and advances the turn to the opponent.
    - If 0 cards are selected: HUD prompts "Selecione 1 carta na mão para descartar no Lixo."
    - If $> 1$ cards are selected: HUD prompts "Selecione apenas 1 carta para descartar no Lixo."

### 2.3 Layout Redistribution (`tabletop.tscn`)
- Remove `ActionBar` panel entirely.
- Expand `PlayerMeldsScroll` height: `offset_top = 582.0`, `offset_bottom = 766.0` (height 184px).
- Expand `PlayerArea` height: `offset_top = 780.0`, `offset_bottom = 1068.0` (height 288px), providing optimal clearance for the card fan and selection elevation.
- Enable mouse input handling on table felt / meld container to detect board clicks.

---

## 3. Acceptance Criteria
- [ ] `MeldButton` and `DiscardButton` are removed from `tabletop.tscn` and `tabletop.gd`.
- [ ] `ActionBar` is eliminated from `tabletop.tscn`.
- [ ] Selecting $\ge 3$ valid cards and clicking on the table successfully melds the cards.
- [ ] Selecting 1 card and clicking on the Discard Pile (`discard_pile`) discards the card and advances the turn.
- [ ] Clicking the Discard Pile during `TurnPhase.DRAW` still draws all cards from the discard pile.
- [ ] Drag-and-drop to the Discard Pile remains fully functional.
- [ ] All automated unit and integration tests pass without regression.
- [ ] Release packages export cleanly for Windows, Linux, and Web.
