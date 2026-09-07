# 003 — Tabletop UI, Card Layout & Tactile Interactions

**Status:** Approved  
**Author:** @gamedesign & @uiux  
**Date:** 2026-09-07  
**Variant / Game Mode:** Buraco Aberto (2 Players: 1v1 Tabletop)  
**Related Specs / Issues:** Extends Specs 001 & 002  

---

## 1. Problem / UX Goal
Create a responsive, intuitive, and tactile 2D tabletop interface in Godot 4 that connects seamlessly to `RoundState`. Players must be able to view their hand in a dynamic curved fan, interact via native Drag & Drop or tap-to-select, see table melds organized with Clean/Dirty indicators, and receive clear visual feedback through fluid `Tween` animations.

---

## 2. Visual Layout Architecture

```
┌─────────────────────────────────────────────────────────────────────────────┐
│ [TOP BAR] Turn Indicator: "Sua Vez" | Round: 1 | Placar: Humano 0 x 0 Bot   │
├─────────────────────────────────────────────────────────────────────────────┤
│ [OPPONENT ZONE]                                                             │
│   - Opponent Hand (Card Backs Counter: 11 cartas | Morto: [Pendente])       │
│   - Opponent Melds Area (Sequences / Sets placed on table)                  │
├─────────────────────────────────────────────────────────────────────────────┤
│ [CENTER MESA]                                                               │
│   ┌───────────────┐     ┌───────────────┐     ┌────────────────────────┐    │
│   │  STOCK PILE   │     │ DISCARD PILE  │     │    MORTOS (2 montes)   │    │
│   │ (Monte: 63)   │     │ (Lixo: 1)     │     │   [Morto 1] [Morto 2]  │    │
│   └───────────────┘     └───────────────┘     └────────────────────────┘    │
├─────────────────────────────────────────────────────────────────────────────┤
│ [PLAYER MELDS ZONE]                                                         │
│   - Player Team Melds (Organized columns with Clean / Dirty badges)         │
├─────────────────────────────────────────────────────────────────────────────┤
│ [PLAYER ACTION BAR & HAND ZONE]                                             │
│   [ Botão: Baixar Jogo ]   [ Botão: Descartar ]   [ Botão: Organizar Mão ]  │
│                                                                             │
│                    ( Player Dynamic Card Fan / Arc )                        │
│                     [🂡] [🂢] [🂣] [🂤] [🂥] [🂦] [🂧] [🂨]                     │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## 3. Core UI Components

### 3.1 Card View Component (`CardView.tscn` / `card_view.gd`)
- Visual representation of a card (standard poker ratio ~64x96 dp or responsive vector).
- Procedural/styled vector card background (white rounded rect with subtle drop shadow).
- Clear rank text (A, 2..10, J, Q, K, Joker) and suit symbols (♣, ♦, ♥, ♠) in correct colors:
  - Red: Hearts (♥) and Diamonds (♦)
  - Dark Blue/Black: Clubs (♣) and Spades (♠)
  - Gold/Purple: Joker
- States:
  - `NORMAL`: Resting in hand or table.
  - `HOVER`: Slight elevation (`position.y -= 10`) and brighter outline.
  - `SELECTED`: Elevated (`position.y -= 25`) with bright border highlight.
  - `DRAGGING`: Semi-transparent with drag preview.

### 3.2 Dynamic Hand Fan Layout (`HandView.tscn` / `hand_view.gd`)
- Calculates card spacing, rotation angle, and vertical parabolic arc based on hand card count.
- Multi-selection support: Click cards to toggle selection.
- Auto-sort button: Sort by suit or sort by rank.

### 3.3 Meld View Area (`MeldAreaView.tscn` / `meld_area_view.gd`)
- Displays all melds placed on the table for each player/team.
- Overlapping vertical cascade layout showing all card ranks in the sequence.
- Badge indicators:
  - **Canastra Limpa:** Golden border + "Limpa (200)" badge.
  - **Canastra Suja:** Silver border + "Suja (100)" badge.
  - **Canastra Real:** Emerald border + "Real (500)" badge.

### 3.4 Tabletop Controller (`Tabletop.tscn` / `tabletop.gd`)
- Connects `RoundState` and UI events.
- Handles user inputs:
  - Click Stock $\rightarrow$ Draw card.
  - Click Discard Pile $\rightarrow$ Draw all discard cards.
  - Drag cards to Mesa or Click "Baixar Jogo" $\rightarrow$ Meld validation and placement.
  - Drag card to Discard Pile or Click "Descartar" $\rightarrow$ Discard and end turn.

---

## 4. Animation & Game Feel ("Juice")
- **Card Deal:** Staggered `Tween` distribution from Stock to player hands.
- **Card Draw:** Smooth fly-in animation from Stock/Lixo to Hand.
- **Card Discard:** Card slides smoothly into the Discard Pile.
- **Canasta Celebration:** Screen pulse and celebratory label when a 7-card Canasta is formed.

---

## 5. Acceptance Criteria
- [ ] `CardView` displays rank, suit, color, and selection states correctly.
- [ ] `HandView` arranges any number of cards (1 to 22) in a responsive curved fan.
- [ ] Clicking stock draws a card during `TurnPhase.DRAW`.
- [ ] Clicking discard pile draws all discard cards during `TurnPhase.DRAW`.
- [ ] Selected valid cards can be melded to table with instant visual update.
- [ ] Discarding a card moves it to the discard pile and advances the turn.
- [ ] Tabletop runs responsively on standard window resolutions (1280x720 and resizable).
- [ ] All UI scenes instantiate and run cleanly in Godot 4.
