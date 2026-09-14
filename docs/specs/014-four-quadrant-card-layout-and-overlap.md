# 014 — Four-Quadrant Card Layout & 50% Horizontal Overlap

**Status:** Approved  
**Author:** @gamedesign & @uiux  
**Date:** 2026-09-14  
**Variant / Game Mode:** All (CardView, HandView, Tabletop Melds)  
**Related Specs / Issues:** Extends Specs 003, 004, 010 & 012  

---

## 1. Problem / Game Design Goal
In digital card games like Canastra / Buraco, card readability in large hands (11 to 22+ cards) and tabletop sequences is critical:
1. **Old Layout Limitations:** Previously, cards used traditional playing card corners (tiny rank + suit crammed into a 34x58 box) and a large suit in the dead center. When cards overlapped horizontally in the hand, the center symbol was awkwardly truncated and the bottom-right corner was completely hidden.
2. **Four-Quadrant Mental Model:** By dividing the card into 4 distinct quadrants (2x2 grid):
   - **Quadrant 1 (Top-Left / Superior Esquerdo):** Dedicated entirely to the card **NUMBER / RANK** (A, 2..10, J, Q, K, JK), filling the maximum space of the quadrant.
   - **Quadrant 3 (Bottom-Left / Inferior Esquerdo):** Dedicated entirely to the card **SUIT / NAIPE** (♣, ♦, ♥, ♠, ★), filling the maximum space of the quadrant.
   - **Quadrants 2 & 4 (Top-Right & Bottom-Right / Superior e Inferior Direito):** Dedicated to being covered by the adjacent card to the right.
3. **50% Overlap Geometry:** Each card to the right (`i + 1`) is placed with a 50px horizontal offset (`card_width * 0.5`), covering exactly the right 50% of card `i` (both right quadrants) while keeping the left 50% (number at top, suit at bottom) 100% visible, bold, and instantly readable.

---

## 2. Technical & UI Specifications

### 2.1 Card View Component (`src/ui/card_view.tscn` & `src/ui/card_view.gd`)
- **Card Dimensions:** Standard 100x145 px (`base_size = Vector2(100, 145)`).
- **Quadrant Top-Left (`RankLabel`):**
  - Anchors: `anchor_left = 0.0, anchor_top = 0.0, anchor_right = 0.5, anchor_bottom = 0.5`.
  - Dimensions: 50x72.5 px.
  - Alignment: Horizontal Center, Vertical Center.
  - Typography: Dynamic font size — 38px for 2-character ranks ("10", "JK"), 44px for single characters ("A", "2".."9", "J", "Q", "K").
  - Drop shadow for crisp legibility over parchment texture.
- **Quadrant Bottom-Left (`SuitLabel`):**
  - Anchors: `anchor_left = 0.0, anchor_top = 0.5, anchor_right = 0.5, anchor_bottom = 1.0`.
  - Dimensions: 50x72.5 px.
  - Alignment: Horizontal Center, Vertical Center.
  - Typography: 48px bold unicode suit symbol (♣, ♦, ♥, ♠) or 44px star (★) for Joker.
  - Colors: Crimson Red `Color(0.72, 0.12, 0.12)` for Hearts/Diamonds, Dark Charcoal `Color(0.12, 0.10, 0.12)` for Clubs/Spades, Warm Rust `Color(0.65, 0.22, 0.15)` for Joker.
- **Quadrants Right Half (Top-Right & Bottom-Right):**
  - Kept clear of text/index labels so no awkward half-cut symbols appear when covered by adjacent cards.

### 2.2 Hand View Dynamic Layout (`src/ui/hand_view.gd`)
- **Horizontal Overlap Spacing:**
  - `var target_spacing: float = card_width * 0.5 # 50.0 px`.
  - `var card_spacing: float = min(target_spacing, (available_width - card_width) / float(max(1, count - 1)))`.
- **Card Overlap Order:**
  - Card `i + 1` renders on top of card `i` (`z_index = i`), cleanly covering the right 50% (Quadrants 2 & 4) of card `i`.
  - Each card exposes its 50px left strip: Number in top-left, Suit in bottom-left.

### 2.3 Tabletop Meld Cascades (`src/ui/meld_group_view.gd`)
- Horizontal card arrangement with 50.0px step matching reference layout (`layout_exemplo.png`).
- Card `i + 1` covers the right half of card `i`, allowing the full meld sequence to be read left-to-right with clear numbers and suits along the table.

---

## 3. Acceptance Criteria
- [ ] `CardView` displays rank in top-left quadrant (`anchor_right = 0.5, anchor_bottom = 0.5`) filling the quadrant with font size >= 38.
- [ ] `CardView` displays suit in bottom-left quadrant (`anchor_top = 0.5, anchor_bottom = 1.0`) filling the quadrant with font size >= 48.
- [ ] Right quadrants of `CardView` have no overlapping labels.
- [ ] Joker displays "JK" in top-left and "★" in bottom-left in rust/amber color.
- [ ] `HandView` sets standard card spacing to 50.0 px (`card_width * 0.5`), covering the right 2 quadrants of each preceding card.
- [ ] Selected cards in hand elevate (`y -= 32`) and scale (`1.08x`), popping above adjacent cards with gold highlight border.
- [ ] `MeldGroupView` displays cards horizontally with 50px overlap matching the tabletop reference layout.
- [ ] All automated tests pass with 0 regressions.
