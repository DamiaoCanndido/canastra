# 009 — Restore Hand Sorting Filters (By Suit & By Rank/Same Numbers)

**Status:** Approved  
**Author:** @gamedesign & @uiux  
**Date:** 2026-09-12  
**Variant / Game Mode:** All (Hand View & Tabletop UI)  
**Related Specs / Issues:** Extends Specs 003, 004, 006, 007 & 008  

---

## 1. Problem / Game Design Goal
In Canastra / Buraco, players need to quickly alternate between two mental models of their hand:
1. **Sequência (Runs):** Grouping cards by suit in ascending order (`♣ < ♦ < ♥ < ♠`) to identify potential straights (`[6♣, 7♣, 8♣]`).
2. **Trinca / Lavadeira (Sets / Same Numbers):** Grouping cards by rank/number together (e.g. all 7s together: `7♣, 7♦, 7♥`; all Kings together) to identify potential sets.

Previously, in Cycle 006 and 007, manual sort buttons were removed when the bottom `ActionBar` was eliminated. However, player feedback highlighted that having quick, accessible filter buttons to toggle between **Naipe** (Suits) and **Mesma Numeração** (Same Numbers / Rank) is an essential usability feature.

The goal of Cycle 009 is to:
1. Restore the two sorting filter buttons:
   - **`SortSuitButton` ("♣♦ Naipes"):** Sorts cards primarily by suit, secondarily by rank.
   - **`SortRankButton` ("🔢 Mesma Numeração"):** Sorts cards primarily by rank (grouping cards of the same number together), secondarily by suit.
2. Place the controls cleanly inside `PlayerArea/SortControls` on the left side of the player's hand fan, avoiding obstruction of cards, table melds, or piles.
3. Make the sort state persistent in `HandView` so that newly drawn cards (from Stock or Discard pile) or Morto cards integrate seamlessly in the player's chosen sorting order.
4. Provide visual feedback (highlighting the currently active sort filter) and HUD announcements upon switching sort modes.
5. Preserve card selection state across re-sorting so selected cards do not desync.

---

## 2. Technical & UI Specifications

### 2.1 Hand View Persistent Sort Mode (`hand_view.gd`)
- Add enum `SortMode { SUIT, RANK }`.
- Track `current_sort_mode: SortMode = SortMode.SUIT`.
- `sort_by_suit(animate: bool = true)`:
  - Sets `current_sort_mode = SortMode.SUIT`.
  - Sorts cards: `suit` ascending, then `rank` ascending.
  - Rebuilds card views, preserving selection state for any previously selected cards.
  - Updates hand layout with smooth Tween animation.
- `sort_by_rank(animate: bool = true)`:
  - Sets `current_sort_mode = SortMode.RANK`.
  - Sorts cards: `rank` ascending, then `suit` ascending (grouping identical ranks together).
  - Rebuilds card views, preserving selection state for any previously selected cards.
  - Updates hand layout with smooth Tween animation.
- `set_cards(p_cards: Array[CardData])`:
  - Applies sorting according to `current_sort_mode` so preference is remembered when new cards are drawn.

### 2.2 Tabletop Sort Controls (`tabletop.tscn`)
- Inside `PlayerArea`, create `SortControls` (`VBoxContainer` or `PanelContainer` with `VBoxContainer`):
  - Position: Left side of `PlayerArea`, offset `(40, 24)` to `(220, 114)`.
  - `SortSuitButton`:
    - Text: `"♣♦ Naipes"`
    - Tooltip: `"Ordenar mão por naipes e valores sequenciais"`
    - Custom minimum size: `Vector2(160, 38)`
  - `SortRankButton`:
    - Text: `"🔢 Numeração"`
    - Tooltip: `"Agrupar cartas com a mesma numeração (trincas)"`
    - Custom minimum size: `Vector2(160, 38)`
  - Styled with clean rounded translucent borders, hover glows, and active selection border highlight.

### 2.3 Controller Logic (`tabletop.gd`)
- Resolve nodes `$PlayerArea/SortControls/SortSuitButton` and `$PlayerArea/SortControls/SortRankButton`.
- Connect button signals to `_on_sort_suit_pressed()` and `_on_sort_rank_pressed()`.
- Public methods `sort_player_suit()` and `sort_player_rank()` maintained for test compatibility.
- `_update_sort_buttons_visuals()`:
  - Highlights active button border in gold `Color(1.0, 0.85, 0.2)` while inactive button remains subtle slate green.
  - HUD announcement: `"Mão ordenada por Naipes (♣ ♦ ♥ ♠)"` or `"Mão ordenada por Numeração (Cartas Iguais)"`.

---

## 3. Acceptance Criteria
- [ ] `SortSuitButton` and `SortRankButton` exist inside `PlayerArea/SortControls`.
- [ ] Clicking `SortSuitButton` sorts hand by suit (Clubs $\rightarrow$ Diamonds $\rightarrow$ Hearts $\rightarrow$ Spades $\rightarrow$ Jokers).
- [ ] Clicking `SortRankButton` sorts hand by rank (grouping cards of the same rank together).
- [ ] Active sort mode is visually highlighted on the buttons.
- [ ] Cards drawn after selecting "Numeração" maintain the rank-sorted order.
- [ ] Cards selected before clicking a sort button remain selected after re-ordering.
- [ ] All automated tests pass with 0 errors.
- [ ] Release packages export cleanly for Windows, Linux, and Web.
