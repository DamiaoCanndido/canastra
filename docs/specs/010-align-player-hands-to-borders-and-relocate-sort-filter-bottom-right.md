# 010 — Align Player Hands to Screen Borders & Relocate Sort Filters to Bottom-Right

**Status:** Approved  
**Author:** @gamedesign & @uiux  
**Date:** 2026-09-12  
**Variant / Game Mode:** All (Hand Views, Tabletop UI & 1080p Layout)  
**Related Specs / Issues:** Extends Specs 003, 004, 007 & 009  

---

## 1. Problem / Game Design Goal
In digital Canastra / Buraco tabletop card games, natural spatial hierarchy requires the players' hands to be anchored directly against the viewport borders:
1. **Player Hand (Borda Inferior):** The human player's hand must be anchored along the bottom border of the screen, providing maximum visual connection to the cards, ample room for card fan selection lift, and eliminating the ~200px empty dead space that previously separated the hand from the bottom window edge.
2. **Opponent Hand (Borda Superior):** The opponent bot's hand must be anchored along the top border of the screen, horizontally centered, creating a symmetrical face-to-face card table dynamic.
3. **Sort Controls Relocation (Lado Inferior Direito):** The sorting filter buttons (`SortSuitButton` "♣♦ Naipes" and `SortRankButton` "🔢 Numeração") were previously placed on the left side of `PlayerArea`. To optimize player ergonomic reach and visual flow, these controls must be moved to the bottom-right corner (`PlayerArea/SortControls`), safely outside the card fan sweep and cleanly styled.

The goal of Cycle 010 is to:
1. Update `HandView` to support dynamic vertical alignment (`card_alignment: "BOTTOM"` vs `"TOP"`) with customizable margins, computing card Y coordinates relative to the designated edge.
2. Align `OpponentArea` and `OpponentHand` to the top border of the table, correcting horizontal centering pivot math (`pivot_offset = (960, 0)`).
3. Align `PlayerArea` and `PlayerHand` to the bottom border of the screen (`y = 1080`), positioning player cards flush with the bottom edge (leaving 16px border padding).
4. Relocate `SortControls` to the bottom-right of `PlayerArea` (`anchor_left = 1.0`, `anchor_right = 1.0`, `offset_left = -210`, `offset_right = -40`), maintaining active filter visual indicators and full test coverage.
5. Modernize `HUD`'s top bar so `TurnLabel` (left) and `ScoreLabel` (right) act as sleek status chips, keeping the top center clear for the opponent's cards.

---

## 2. Technical & UI Specifications

### 2.1 Hand View Vertical Alignment (`src/ui/hand_view.gd`)
- Add property `@export_enum("BOTTOM", "TOP") var card_alignment: String = "BOTTOM"`.
- Add property `@export var vertical_margin: float = 16.0`.
- In `update_hand_layout(animate: bool = true)`:
  - When `card_alignment == "BOTTOM"`:
    - Base card Y is calculated from container height: `base_y = effective_height - card_height - vertical_margin`.
    - Cards curve with positive arc offset: `target_y = base_y + arc_offset + elevation_y`.
    - At `effective_height = 210.0`, `card_height = 104.0`, `vertical_margin = 16.0`:
      `base_y = 90.0` (in `PlayerArea` from 870..1080 $\rightarrow$ global card Y is 960, bottom is 1064).
      Selected card elevates to $960 - 32 = 928$.
  - When `card_alignment == "TOP"`:
    - Base card Y is calculated from top edge: `base_y = vertical_margin`.
    - Cards curve down slightly: `target_y = base_y + arc_offset`.
    - In `OpponentArea` from 0..120 with `vertical_margin = 8.0`: global card Y is 8..96.

### 2.2 Symmetrical Tabletop Vertical Layout (`src/ui/tabletop.tscn`)
- **OpponentArea (Top Border):**
  - `anchors_preset = 10` (Top Wide)
  - `offset_top = 0.0`, `offset_bottom = 120.0`
  - `OpponentHand`: `card_alignment = "TOP"`, `vertical_margin = 8.0`, `scale = Vector2(0.85, 0.85)`, `pivot_offset = Vector2(960, 0)` (centered on 1920 width).
- **HUD Top Bar (`src/ui/hud_view.tscn`):**
  - Transparent top bar panel (`StyleBoxEmpty`) so green felt spans the top border.
  - `TurnLabel` on top-left in styled translucent status chip.
  - `ScoreLabel` on top-right in styled translucent status chip.
  - Top center (x: 500 to 1420) completely unobstructed for opponent cards.
- **OpponentMeldsScroll:**
  - `offset_left = 40.0`, `offset_right = -40.0`, `offset_top = 130.0`, `offset_bottom = 300.0` (height 170px).
- **CenterTable (Mesa & Piles):**
  - `offset_top = 310.0`, `offset_bottom = 560.0` (height 250px).
  - Piles remain on middle-right (`offset_left = -440`, `offset_right = -60`).
- **PlayerMeldsScroll:**
  - `offset_left = 40.0`, `offset_right = -40.0`, `offset_top = 570.0`, `offset_bottom = 750.0` (height 180px).
- **PlayerArea (Bottom Border):**
  - `anchors_preset = 12` (Bottom Wide)
  - `anchor_top = 1.0`, `anchor_bottom = 1.0`
  - `offset_top = -210.0`, `offset_bottom = 0.0` (y: 870 to 1080).
  - `PlayerHand`: `anchors_preset = 15`, `card_alignment = "BOTTOM"`, `vertical_margin = 16.0`.
- **SortControls (Bottom-Right Relocation):**
  - Parent: `PlayerArea`.
  - Anchors: `anchor_left = 1.0`, `anchor_top = 1.0`, `anchor_right = 1.0`, `anchor_bottom = 1.0`.
  - Offsets: `offset_left = -210.0`, `offset_top = -106.0`, `offset_right = -40.0`, `offset_bottom = -16.0`.
  - Contains `SortSuitButton` and `SortRankButton` (width 170px, height 38px each, 8px separation).

---

## 3. Acceptance Criteria
- [ ] `PlayerHand` cards are aligned to the bottom border of the window (`global_position.y >= 920.0` on 1080p).
- [ ] `OpponentHand` cards are aligned to the top border of the window (`global_position.y <= 60.0` on 1080p).
- [ ] `OpponentHand` is horizontally centered on the 1920 viewport (`pivot_offset = Vector2(960, 0)`).
- [ ] `SortControls` is anchored and positioned at the bottom-right corner of `PlayerArea`.
- [ ] Clicking `SortSuitButton` and `SortRankButton` functions without regression, preserving card selection.
- [ ] Both buttons display active (`●`) and inactive (`○`) state indicators with gold hover styling.
- [ ] HUD `TurnLabel` and `ScoreLabel` display legibly at top corners without colliding with the opponent hand.
- [ ] All automated tests pass with 0 errors.
- [ ] Release packages export cleanly for Windows, Linux, and Web.
