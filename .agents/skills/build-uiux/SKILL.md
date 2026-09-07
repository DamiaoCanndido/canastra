---
name: build-uiux
description: >-
  Defines how the UI/UX & Card Layout Specialist agent (@uiux) designs and builds responsive card game interfaces, drag-and-drop interactions, card fan math, and fluid Tween animations in Godot 4.
---

# Build UI/UX

**Skill for:** `@uiux`

## Purpose

Defines how the UI/UX & Card Layout Specialist agent creates intuitive, responsive, and tactile 2D card game interfaces in Godot Engine 4 — including dynamic hand fan layouts, Drag & Drop interactions, fluid `Tween` animations, and audio-visual game feel.

## When to use

- Building or updating tabletop layout scenes (`Tabletop.tscn`, `HandView.tscn`, `MeldArea.tscn`).
- Implementing card interaction mechanics: tap-to-select, multi-card selection, Drag & Drop.
- Creating animation sequences using `Tween` (card dealing, drawing, discarding, meld placement, pot pickup).
- Designing HUD elements: scoreboards, turn timers, player avatars, canasta celebratory banners.
- Ensuring responsive layouts across desktop and mobile aspect ratios.

## Process

1. **Plan Visual Hierarchy & Anchor Setup** — Structure the tabletop with responsive Godot 4 containers (`MarginContainer`, `AspectRatioContainer`, `HBoxContainer`, `GridContainer`). Use Anchor Presets properly (Full Rect, Bottom Wide, Center).
2. **Build the `CardView` Component** — Create a modular `CardView.tscn` (`Control` node) representing a single visual card with front/back textures, rank/suit labels, shadow effects, and highlight outlines.
3. **Implement Dynamic Hand Fan Math** — Dynamically position and rotate cards in the player's hand along an arc based on the number of cards in hand.
4. **Implement Drag & Drop System** — Implement Godot's native `_get_drag_data()`, `_can_drop_data()`, and `_drop_data()` methods with clear visual drag previews and drop-target highlights.
5. **Program Fluid `Tween` Animations** — Use Godot 4 `create_tween()` with cubic/quad easing for dealing cards, drawing from piles, and snapping melds onto the table.
6. **Connect to Game Signals** — Listen to signals from the game manager (`card_drawn`, `turn_started`, `canasta_completed`) to trigger animations and UI updates.
7. **Add Audio & Haptic Feedback** — Play sound effects (`card_slide.wav`, `card_snap.wav`, `fanfare.wav`) synchronized with animation keyframes.
8. **Test Responsiveness** — Verify layout behavior across 16:9, 18:9, and 4:3 aspect ratios under window resizing.

## UI & Animation Conventions

### 1. Card Fan Layout Mathematics
Calculate card rotation and vertical arc offsets dynamically in `HandView.gd`:
```gdscript
func update_hand_layout() -> void:
    var card_count: int = cards.size()
    if card_count == 0:
        return
        
    var max_spread_angle: float = 30.0 # Total arc in degrees
    var angle_step: float = 0.0
    if card_count > 1:
        angle_step = max_spread_angle / float(card_count - 1)
        
    var start_angle: float = -max_spread_angle / 2.0
    var center_x: float = size.x / 2.0
    var card_spacing: float = min(60.0, (size.x - 120.0) / float(max(1, card_count)))

    for i in range(card_count):
        var card_view: CardView = cards[i]
        var angle_deg: float = start_angle + (i * angle_step)
        var offset_x: float = center_x + (i - (card_count - 1) / 2.0) * card_spacing
        var arc_offset_y: float = abs(angle_deg) * 0.8 # Slight curve downward at edges
        
        var target_pos: Vector2 = Vector2(offset_x, arc_offset_y)
        var target_rot: float = deg_to_rad(angle_deg)
        
        var tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
        tween.tween_property(card_view, "position", target_pos, 0.25)
        tween.tween_property(card_view, "rotation", target_rot, 0.25)
```

### 2. Native Godot Drag & Drop Contract
Standardize the Drag & Drop payload dictionary:
```gdscript
# In CardView.gd:
func _get_drag_data(at_position: Vector2) -> Variant:
    var preview = create_drag_preview()
    set_drag_preview(preview)
    return {
        "type": "CARD_DATA",
        "cards": [card_data],
        "source_view": self
    }

# In MeldArea.gd:
func _can_drop_data(at_position: Vector2, data: Variant) -> bool:
    if typeof(data) == TYPE_DICTIONARY and data.get("type") == "CARD_DATA":
        var dragged_cards: Array = data.get("cards", [])
        return MeldValidator.can_add_to_meld(dragged_cards, current_meld)
    return false

func _drop_data(at_position: Vector2, data: Variant) -> void:
    var dragged_cards: Array = data.get("cards", [])
    EventBus.request_play_cards.emit(dragged_cards, meld_id)
```

### 3. Tweening Standards
- Always use `Tween.TRANS_CUBIC` or `Tween.TRANS_QUAD` with `Tween.EASE_OUT` for organic, snappy card movement.
- Keep animation durations between `0.15s` (card hover/tap) and `0.4s` (dealing / pot pickup) so game pacing remains fast and engaging.
- Never block user input unnecessarily; allow fast clicks by queueing or completing in-flight tweens gracefully.

## Guidelines

- **Touch and Mouse Parity:** Ensure drag-and-drop works seamlessly with touch screens (large enough touch targets: minimum 48x48 dp for buttons, cards scaled appropriately).
- **Clear Visual Feedback:** Selected cards must raise slightly (`position.y -= 20`); invalid drop zones must show subtle red tint or refuse to highlight.
- **Canasta Celebration:** Creating a 7-card Canasta should have high visual impact (particle burst, ribbon/badge banner, distinct sound for Clean vs Dirty).
- **Clean Scene Hierarchy:** Keep UI scenes modular (`Tabletop.tscn` aggregates `PlayerHand.tscn`, `MeldContainer.tscn`, `DiscardPileView.tscn`, `ScoreHud.tscn`).
