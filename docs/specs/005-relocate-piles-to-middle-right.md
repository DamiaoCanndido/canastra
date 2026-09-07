# 005 — Relocate Table Piles (Monte, Lixo, Mortos) to Middle-Right

**Status:** Approved  
**Author:** @gamedesign & @uiux  
**Date:** 2026-09-07  
**Variant / Game Mode:** All (Tabletop UI Layout)  
**Related Specs / Issues:** Extends Specs 003 & 004  

---

## 1. Problem / Game Design Goal
In traditional digital card games and Buraco/Canastra tabletops, placing draw and discard piles centrally across the horizontal axis divides the player's view and limits horizontal area for card melds and status banners. Furthermore, right-side placement provides superior ergonomics for right-handed desktop mouse users and mobile/touch players when drawing from the Stock (Monte) or dropping cards to Discard (Lixo).

The goal of this cycle is to:
1. Relocate the `PilesContainer` (comprising StockPile, DiscardPile, and MortoPile) from horizontal center (`anchor_left = 0.5`) to the middle-right zone of the table (`anchor_left = 1.0, anchor_right = 1.0`).
2. Maintain consistent spacing, pile sizes (80x130), and clear visual labeling.
3. Keep the central horizontal mesa clear for announcements, prompt banners, and unobstructed meld inspection.

---

## 2. Layout Specification

### 2.1 Center Mesa Coordinates (`CenterTable`)
- **Vertical bounds:** `offset_top = 346.0`, `offset_bottom = 576.0` (height 230px, centered vertically on the 1080p canvas).
- **Horizontal bounds:** `anchor_left = 0.0`, `anchor_right = 1.0` (full 1920px width).

### 2.2 Piles Container Positioning (`PilesContainer`)
- **Anchor Preset:** `6` (Center Right).
- **Anchors:** `anchor_left = 1.0`, `anchor_right = 1.0`, `anchor_top = 0.5`, `anchor_bottom = 0.5`.
- **Offsets:**
  - `offset_left = -440.0` (starts at $x = 1480$ on 1920px canvas).
  - `offset_top = -75.0` ($y = 386$).
  - `offset_right = -60.0` (ends at $x = 1860$, leaving a clean 60px right padding).
  - `offset_bottom = 75.0` ($y = 536$).
- **Arrangement:** `HBoxContainer`, `theme_override_constants/separation = 30`, `alignment = 1` (center).
- **Contents (Left to Right):**
  1. `StockPile` (Monte — 80x130)
  2. `DiscardPile` (Lixo — 80x130, Drop Target)
  3. `MortoPile` (Mortos — 80x130)

### 2.3 Mesa Center & Prompt Alignment
- The center zone ($x \in [680, 1240]$) accommodates the HUD `PromptPanel` and round announcements without visual overlap or occlusion of the piles.

---

## 3. State Machine & Gameplay Contract
- **No changes to game logic:** Drawing from Stock, drawing from Discard, Morto triggers, and card drag-and-drop mechanics retain identical signal contracts and validation rules.
- **Drop Target:** `DiscardPile` remains the drop target for discarding cards during `TurnPhase.ACTION`.

---

## 4. Acceptance Criteria
- [ ] `PilesContainer` is anchored to the right side of `CenterTable` (`anchor_left = 1.0`, `anchor_right = 1.0`).
- [ ] `PilesContainer` right edge has comfortable padding (`offset_right = -60.0`) from the screen edge.
- [ ] StockPile, DiscardPile, and MortoPile render cleanly in order from left to right within the middle-right area.
- [ ] Prompt panel and center announcements do not intersect with the piles.
- [ ] Clicking Stock Pile draws card; clicking Discard Pile draws discard; dragging card to Discard Pile completes discard.
- [ ] Automated tests verify the new middle-right layout anchors and offsets.
- [ ] All 124+ automated test assertions pass with zero regressions.
- [ ] Release packages export cleanly for Windows, Linux, and Web.
