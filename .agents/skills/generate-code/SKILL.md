---
name: generate-code
description: >-
  Defines how the Gameplay & Systems Engineer agent (@gamedev) turns a game spec into clean, statically typed GDScript 4 code, decoupled data models, state machines, and card game algorithms.
---

# Generate Code

**Skill for:** `@gamedev` (or `@engeneer`)

## Purpose

Defines how the Gameplay & Systems Engineer agent turns a game design spec (from `@gamedesign`) into working, statically typed, modular, and thoroughly tested GDScript 4 code for the Canastra card game.

## When to use

- Implementing a new game feature, rule engine component, or variant from an approved spec.
- Building or refactoring card data structures (`CardData`, `DeckData`, `MeldData`, `RoundState`).
- Creating state machines for matches, rounds, turns, and player actions.
- Implementing bot AI decision heuristics.
- Fixing gameplay bugs or refactoring game logic.

## Process

1. **Read & Validate the Spec** — Confirm rule requirements, state transitions, scoring, and acceptance criteria from `@gamedesign`. Flag any rule ambiguities immediately.
2. **Model Pure Data Structures First** — Create data classes inheriting `RefCounted` or `Resource` (e.g. `CardData`, `MeldData`, `PileData`). Keep logic 100% decoupled from `Node` / GUI hierarchy for headless testability.
3. **Implement Core Rule Engine & Validators** — Build domain logic (e.g. `MeldValidator.gd`, `ScoreCalculator.gd`, `DeckManager.gd`) with strict static typing.
4. **Implement State Machines** — Structure match and turn flow using deterministic states (`DrawState`, `ActionState`, `DiscardState`, `PotPickupState`, `RoundEndState`).
5. **Connect via Signal Bus** — Expose state changes and game events through a decoupled `SignalBus` / `EventBus` (`card_drawn`, `meld_placed`, `canasta_formed`, `turn_ended`).
6. **Write Unit Tests alongside Code** — Ship code with automated unit test scripts verifying the happy path and all edge cases.
7. **Self-Review** — Re-read code for type safety, memory leaks (unfreed objects/nodes), cyclic references, and clear naming.
8. **Hand off** — Provide a clear summary of classes, methods, and signal contracts for `@uiux` and `@qa`.

## GDScript 4 & Godot Stack Conventions

### 1. Strict Static Typing & Enums
- Every variable, parameter, and function return must be explicitly typed:
```gdscript
class_name CardData
extends RefCounted

enum Suit { CLUBS, DIAMONDS, HEARTS, SPADES, NONE }
enum Rank { NONE, TWO = 2, THREE, FOUR, FIVE, SIX, SEVEN, EIGHT, NINE, TEN, JACK, QUEEN, KING, ACE, JOKER }

@export var suit: Suit = Suit.NONE
@export var rank: Rank = Rank.NONE
@export var deck_id: int = 1 # 1 or 2 (double deck)

func is_wildcard() -> bool:
    return rank == Rank.TWO or rank == Rank.JOKER

func get_point_value() -> int:
    match rank:
        Rank.JOKER:
            return 20
        Rank.TWO:
            return 10
        Rank.ACE:
            return 15
        Rank.EIGHT, Rank.NINE, Rank.TEN, Rank.JACK, Rank.QUEEN, Rank.KING:
            return 10
        Rank.THREE, Rank.FOUR, Rank.FIVE, Rank.SIX, Rank.SEVEN:
            return 5
        _:
            return 0
```

### 2. Pure Logic Decoupling (Signals Up, Calls Down)
- **Data & Rules:** Inherit `RefCounted` or `Resource` — never import UI nodes into rule files.
- **Controllers / Managers:** Inherit `Node` to manage game loop and player turns.
- **Signals:** Emit signals on state changes; never call upwards directly from model to view.
```gdscript
# Good: Pure domain validator
class_name MeldValidator
extends RefCounted

static func validate_sequence(cards: Array[CardData], variant: GameVariant) -> MeldValidationResult:
    # Deterministic calculation, zero UI dependencies
    ...
```

### 3. State Machine Architecture
- Use explicit State classes or cleanly defined Enums to manage round and turn flow:
```gdscript
enum TurnPhase {
    WAITING_FOR_DRAW,   # Player must draw from Stock or Discard Pile
    PLAYING_ACTIONS,    # Player can meld, append to existing melds
    DISCARDING,         # Player must select a card to discard
    TAKING_POT,         # Player triggered pot pickup (direct or indirect)
    TURN_OVER           # Next player's turn
}
```

### 4. Deterministic Randomness
- Use `RandomNumberGenerator.new()` with a controllable `seed` for deck shuffling to enable deterministic testing and replay capability:
```gdscript
func shuffle_deck(rng: RandomNumberGenerator = null) -> void:
    if rng == null:
        rng = RandomNumberGenerator.new()
        rng.randomize()
    # Fisher-Yates or Array.shuffle with seed
```

## Guidelines

- **Never Hardcode Magic Numbers:** Use constants or config resources for scoring values, deck sizes (108 cards), hand sizes (11 cards), and pot sizes (11 cards).
- **Zero UI in Model Layer:** If a script in `core/` or `models/` uses `get_node()`, `Control`, or `Sprite2D`, refactor it immediately.
- **Document Edge Cases in Code:** Complex wildcard repositioning rules must have clear comments explaining the rule justification.
- **Fail Gracefully with Typed Results:** Return structured result objects (`Result.ok()`, `Result.error("Reason")`) rather than crashing or printing silent errors.
