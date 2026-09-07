# 004 — Full HD Resolution (1920x1080) & Tabletop Layout Scaling

**Status:** Approved  
**Author:** @gamedesign & @uiux  
**Date:** 2026-09-07  
**Variant / Game Mode:** All (Tabletop UI & Engine Display)  
**Related Specs / Issues:** Extends Spec 003  

---

## 1. Problem / Game Design Goal
The previous default project display resolution was configured at 1280x720 (720p). On modern desktop monitors and web displays, Full HD (1920x1080) is the standard baseline resolution. Running at 720p stretched to modern screens leads to sub-optimal visual clarity, cramped hand fan spacing, and limited room for table melds and piles.

The goal of this cycle is to:
1. Transition the engine configuration (`project.godot`) baseline resolution to **1920x1080** with responsive canvas item scaling.
2. Re-architect the vertical zoning and container heights in `tabletop.tscn` so that all tabletop zones (Opponent Hand, Opponent Melds, Center Mesa Piles, Player Melds, Action Bar, and Player Hand) utilize the full 1080px vertical height with balanced proportions.
3. Enhance typography, button touch/click areas, and card fan spread to match the expanded canvas without regressions in gameplay flow or state machine behavior.

---

## 2. Display Configuration Specifications

### 2.1 Engine Display Settings (`project.godot`)
- **Viewport Width:** `1920`
- **Viewport Height:** `1080`
- **Window Width Override:** `1920`
- **Window Height Override:** `1080`
- **Stretch Mode:** `canvas_items` (renders 2D UI sharply and scales coordinate space responsively)
- **Stretch Aspect:** `expand` (allows flexible layout on ultrawide or varying aspect ratios)
- **Resizable:** `true`

---

## 3. Tabletop 1080p Vertical Layout Hierarchy

```
0px ────────────────────────────────────────────────────────────────────────
    [HUD TopBar] (y: 0 to 50, h: 50px)
    - Turn indicator & Scoreboard (font size: 16-17px)
50px ───────────────────────────────────────────────────────────────────────
    [Opponent Area] (y: 52 to 172, h: 120px)
    - Opponent Hand (11 face-down cards scaled 0.85, centered)
172px ──────────────────────────────────────────────────────────────────────
    [Opponent Melds Scroll] (y: 176 to 340, h: 164px)
    - Horizontal scroll container with opponent sequences/sets
340px ──────────────────────────────────────────────────────────────────────
    [Center Table / Mesa] (y: 346 to 576, h: 230px)
    - Centered Piles: Stock Pile (Monte), Discard Pile (Lixo), Mortos (2 montes)
    - Prompt panel positioned centrally with ample clearance
576px ──────────────────────────────────────────────────────────────────────
    [Player Melds Scroll] (y: 582 to 746, h: 164px)
    - Horizontal scroll container with player's sequences/sets
746px ──────────────────────────────────────────────────────────────────────
    [Action Bar] (y: 752 to 816, h: 64px)
    - Buttons: "Baixar Jogo" (min 150x42), "Descartar" (min 130x42),
      "Ordenar Naipe" (min 130x42), "Ordenar Valor" (min 130x42)
816px ──────────────────────────────────────────────────────────────────────
    [Player Area & Hand Arc] (y: 822 to 1068, h: 246px)
    - Dynamic card fan across up to 1400px width
    - Vertical clearance of 246px for card height (104px) + selection lift (-28px) + parabolic arc
1080px ─────────────────────────────────────────────────────────────────────
```

---

## 4. Component Refinements for 1080p

### 4.1 HUD View (`hud_view.tscn`)
- TopBar height increased from 44px to 50px.
- Labels updated with font size 16 for enhanced legibility at 1080p.
- PromptPanel resized to 560x42 with font size 15 for readable round instructions.

### 4.2 Action Bar (`tabletop.tscn`)
- Bar height increased from 48px to 64px.
- Buttons sized at minimum 140x40 to 150x42 with font size 14 for comfortable clicking.
- Enhanced contrast and separator spacing.

### 4.3 Hand Fan Layout (`hand_view.gd`)
- Dynamic spread calculation updated with `available_width` up to 1400px (accommodating up to 22+ cards when picking Morto).
- Card spacing clamped up to 54px for optimal overlap and readability.

### 4.4 Center Table & Piles (`pile_view.tscn`)
- Piles container centered with 40px spacing between Stock, Discard, and Morto.

---

## 5. Acceptance Criteria

- [ ] `project.godot` configured with `viewport_width = 1920` and `viewport_height = 1080`.
- [ ] Stretch mode configured as `canvas_items` with aspect `expand`.
- [ ] Tabletop scene nodes span the complete 1080px vertical height without dead space or clipping.
- [ ] Action Bar buttons and HUD labels scaled appropriately for 1080p readability.
- [ ] Player Hand arc renders comfortably within the 822-1068px zone with room for selected card elevation.
- [ ] All 114 existing unit and integration tests pass with zero regressions.
- [ ] Automated UI test added to verify 1920x1080 configuration and tabletop layout bounds.
- [ ] Project builds and PCK export packages cleanly via Godot CLI.

---

## 6. Edge Cases & Boundary Conditions
1. **Window Resizing:** When scaled above 1080p (e.g. 1440p, 4K) or resized to smaller windows, `stretch/mode = "canvas_items"` preserves proportional scaling and sharp UI elements.
2. **Hand Size Surge (Morto Pickup):** When picking up the 11-card Morto with cards in hand (up to 22 cards), the hand fan spreads across available width smoothly without spilling off the screen edges.
3. **Meld Stacking:** Melds with 7+ cards (Canastas) have 164px height in scroll containers, preventing vertical clipping.
