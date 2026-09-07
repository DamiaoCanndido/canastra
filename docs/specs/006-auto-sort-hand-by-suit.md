# 006 — Auto-Sort Hand by Suit & Removal of Manual Sort Buttons

**Status:** Approved  
**Author:** @gamedesign & @uiux  
**Date:** 2026-09-07  
**Variant / Game Mode:** All (Hand View & Tabletop UI)  
**Related Specs / Issues:** Extends Specs 003, 004 & 005  

---

## 1. Problem / Game Design Goal
Players in Canastra / Buraco almost universally organize their hands grouped by suit in ascending rank (Clubs ♣, Diamonds ♦, Hearts ♥, Spades ♠, followed by Jokers) to readily identify potential sequential runs (*sequências*) and evaluate meld opportunities.

Having manual buttons for "Ordenar Naipe" and "Ordenar Valor" in the bottom Action Bar:
1. Clutters the interface with secondary configuration controls that compete with primary turn actions ("Baixar Jogo" and "Descartar").
2. Creates unnecessary friction requiring the player to press a button each time cards are dealt or drawn.

The goal of this cycle is to:
1. Remove `SortSuitButton`, `SortRankButton`, and their separator from the `ActionBar`.
2. Ensure the player's hand is **always automatically sorted by suit and ascending rank** whenever cards are received (dealing, drawing from Stock or Discard, taking Morto).
3. Clean up the Action Bar layout to prominently display the primary action buttons.

---

## 2. Technical & UI Specifications

### 2.1 Hand Automatic Sorting (`hand_view.gd`)
- `set_cards(p_cards: Array[CardData])` automatically sorts cards prior to view reconstruction using the primary suit ordering:
  - Suits ordered: `CLUBS (0) < DIAMONDS (1) < HEARTS (2) < SPADES (3) < NONE/JOKER (4)`
  - Cards within the same suit ordered by ascending rank: `2 < 3 < 4 < ... < 10 < J < Q < K < A`
- The auto-sorting occurs silently during hand population without displacing selected cards.

### 2.2 Action Bar Simplification (`tabletop.tscn`)
- Nodes removed from `ActionBar/HBox`:
  - `VSeparator`
  - `SortSuitButton`
  - `SortRankButton`
- Remaining buttons in `ActionBar/HBox`:
  - `MeldButton` ("Baixar Jogo")
  - `DiscardButton` ("Descartar")
- Centralized alignment with clean spacing.

### 2.3 Controller Cleanup (`tabletop.gd`)
- Remove references and signal bindings for `sort_suit_button` and `sort_rank_button`.

---

## 3. Acceptance Criteria
- [ ] `SortSuitButton` and `SortRankButton` are removed from `tabletop.tscn` and `tabletop.gd`.
- [ ] `HandView.set_cards()` automatically sorts all cards by suit then rank.
- [ ] Dealing a round populates the hand in sorted order (Clubs $\rightarrow$ Diamonds $\rightarrow$ Hearts $\rightarrow$ Spades $\rightarrow$ Jokers).
- [ ] Drawing a card from Stock or Discard pile automatically integrates into the hand in sorted suit order.
- [ ] Action Bar cleanly displays only "Baixar Jogo" and "Descartar".
- [ ] All automated tests pass with 0 errors.
- [ ] Release packages export cleanly for Windows, Linux, and Web.
