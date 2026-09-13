# 012 — Comprehensive Drag & Drop Tabletop Experience

**Status:** Approved  
**Author:** @gamedesign, @uiux & @gamedev  
**Date:** 2026-09-13  
**Variant / Game Mode:** All (Tabletop UI, Card Interactions & Game Feel)  
**Related Specs / Issues:** Extends Specs 003, 007, 008, 009 & 010  

---

## 1. Problem / Game Design Goal
In digital tabletop card games, Drag & Drop is the primary tactile metaphor connecting the player's physical intent to the digital cards. While basic click-to-select and basic drop targets were partially introduced in prior cycles, the overall drag & drop experience lacked tactile polish, comprehensive interaction coverage, and physical responsiveness:

1. **Hand Reordering (Organização Manual da Mão):** Players could not drag cards within their hand to reorder them manually according to personal strategy.
2. **Multi-Card Dragging (Arrasto Múltiplo):** Selecting multiple cards (e.g. 3 cards for a meld) and dragging one card only dragged that single card instead of the entire selected group.
3. **Direct Table Melding (Arrastar para Baixar na Mesa):** Players could not drag cards directly onto the table felt or player meld zone to play a new meld.
4. **Targeted Meld Insertion (Arrastar para Jogo Específico):** Hovering over existing melds lacked real-time visual validation feedback (glowing green if valid, rejecting if invalid).
5. **Discarding via Drag (Arrastar para o Lixo):** Discard pile needed reactive scale and glow feedback when hovering a valid discard card.
6. **Drawing via Drag (Arrastar do Monte/Lixo para a Mão):** Players should also be able to drag from the Stock or Discard pile directly into their hand to draw.
7. **Visual Feedback & "Juice":** Drag previews lacked proper styling (multi-card fan stack with count badge, rotation tilt, drop shadow), and source cards in hand lacked ghosting (`modulate.a = 0.35`) during in-flight drag.

---

## 2. Technical & Architecture Specifications

### 2.1 Standardized Drag Payload (`src/ui/card_view.gd` & `src/ui/pile_view.gd`)
```gdscript
# Hand Card Drag Payload
{
    "type": "CARD",
    "card_data": primary_card,
    "cards": Array[CardData], # Single card or all currently selected cards
    "source_view": CardView,
    "source_hand": HandView
}

# Pile Draw Drag Payload
{
    "type": "PILE_DRAW",
    "pile_type": "STOCK" | "DISCARD"
}
```

### 2.2 Visual Polish & Game Feel (`CardView.gd`)
- **Multi-Card Drag Preview:** Generates a staggered fan stack of up to 5 preview cards with subtle rotational spread (`-6°` to `+6°`), drop shadow, and a green badge indicator displaying the card count (e.g. `"3 cartas"`).
- **Source Ghosting:** When dragging begins, source cards in hand fade to `modulate.a = 0.35`. Upon `NOTIFICATION_DRAG_END`, opacity is smoothly tweened back to `1.0`.
- **Card-to-Card Forwarding:** `CardView` forwards `can_drop_data` and `drop_data` calls to `HandView` so dropping onto any card or between cards in the hand triggers seamless reordering.

### 2.3 Hand View Reordering & Pile Drawing (`src/ui/hand_view.gd`)
- `mouse_filter = Control.MOUSE_FILTER_PASS` allows the container to receive drops.
- `_can_drop_data()` accepts:
  1. Internal card reordering (`source_hand == self`).
  2. Drawing from piles (`type == "PILE_DRAW"`).
- `_drop_data()`:
  - Calculates target insertion index from `at_position.x`.
  - Removes dragged cards from their current slots and inserts them at target position.
  - Smoothly updates hand fan layout with `Tween.TRANS_CUBIC` and `Tween.EASE_OUT`.
  - Emits `draw_pile_requested(pile_type)` when a pile draw is dropped onto hand.

### 2.4 Tabletop & Meld Zone Drop System (`src/ui/tabletop.gd` & `src/ui/meld_group_view.gd`)
- **Direct Table Melding:** `CenterTable`, `PlayerMeldsScroll`, and `FeltBackground` accept card drops:
  - If 3+ cards: checks `MeldValidator.validate_meld()` and calls `play_new_meld()`.
  - If 1+ cards fit into an existing team meld: appends directly to the matching meld.
- **MeldGroupView Visual Validation:**
  - `_can_drop_data()` validates against team ownership and `MeldValidator.can_append_to_meld()`.
  - On valid hover: glows with emerald highlight (`Color(0.4, 1.2, 0.6)`) and slight expansion scale.
  - On exit/cancel: smoothly returns to normal.
- **Discard Pile Reactive Feedback:**
  - `PileView` validates turn phase (`TurnPhase.ACTION` and 1 card).
  - Highlights with emerald outline and scale pulse `1.12x` on hover.

---

## 3. Acceptance Criteria
- [ ] Dragging any card within `PlayerHand` smoothly reorders the card to the target index.
- [ ] Dragging selected cards drags the entire selection with a multi-card fan preview and count badge.
- [ ] Source card(s) in hand exhibit translucent ghosting (`modulate.a = 0.35`) during drag and restore opacity on drag end.
- [ ] Dragging 3+ valid meld cards to the table (`CenterTable` or `PlayerMeldsScroll`) plays the new meld.
- [ ] Dragging valid card(s) onto an existing team meld appends them, with emerald glow on hover.
- [ ] Hovering invalid cards over a meld displays the forbidden cursor (🚫) and refuses drop.
- [ ] Dragging 1 card onto `DiscardPile` during action phase discards and triggers bot turn, with hover pulse.
- [ ] Dragging from `StockPile` or `DiscardPile` into `PlayerHand` during draw phase draws the card(s).
- [ ] Click interactions (tap to select, click pile, click meld) continue to work seamlessly in parallel with drag & drop.
- [ ] All automated tests pass with 0 errors.
