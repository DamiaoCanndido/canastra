---
name: audit-code
description: >-
  Defines how the QA & Game Rules Auditor agent (@qa) verifies game logic, tests Canastra/Buraco rules, performs edge-case stress testing, and maintains automated GUT/headless test suites in Godot 4.
---

# Audit Code

**Skill for:** `@qa`

## Purpose

Defines how the QA & Game Rules Auditor agent verifies that implemented gameplay code, card mechanics, and UI interactions strictly meet the specification (from `@gamedesign`) and operate without regressions — through automated test suites (GUT / headless GDScript) and systematic rule edge-case auditing.

## When to use

- Code from `@gamedev` or `@uiux` is ready for verification before release.
- A rule violation, desync, or gameplay bug is reported and needs reproduction.
- Designing automated test suites for a new rule variant or feature.
- Performing regression checks after refactoring core card algorithms.

## Process

1. **Re-Read the Feature Spec** — Extract acceptance criteria and rule edge cases from `@gamedesign`'s spec; these are the strict pass/fail baseline.
2. **Run Automated Test Suite Headlessly** — Execute all unit and integration tests via Godot CLI (`godot --headless --script res://test/run_tests.gd`).
3. **Execute Rule Verification Checklist** — Test card combinations, meld mutations, wildcard replacements, pot pickup conditions, and scoring accuracy.
4. **Perform Stress & Boundary Testing** — Test boundary conditions:
   - Empty draw pile (*monte esgotado*).
   - Wildcard manipulation (moving natural 2 when a joker is added).
   - Dirty to Clean transition attempts (must always remain Dirty once contaminated).
   - Multiple melds placed in single turn.
   - Going out (*batida*) without meeting variant requirements.
5. **Reproduce & Isolate Bugs** — Capture exact card IDs, deck state, player hands, and table melds into a minimal reproducible scenario.
6. **File Bug Report or Sign-Off** — File structured bug report or issue official sign-off for release.

## Test Coverage Checklist for Canastra / Buraco

### 1. Unit Tests (`MeldValidator` & Pure Logic)
- [ ] **Valid Runs (*Sequências*):** Correctly identifies 3+ sequential cards of same suit (e.g. `[3♥, 4♥, 5♥]`, `[A♠, 2♠, 3♠, 4♠]`, `[J♦, Q♦, K♦, A♦]`).
- [ ] **Wildcard Rules:** Max 1 wildcard (Joker or 2 of any suit) allowed per meld in standard rules.
- [ ] **Natural 2 Position:** Natural 2 in its correct sequential position (`[A♠, 2♠, 3♠]`) does NOT dirty the meld unless another wildcard is added.
- [ ] **Canasta Detection:**
  - 7+ cards without wildcard = `CLEAN_CANASTA` (200 pts).
  - 7+ cards with wildcard = `DIRTY_CANASTA` (100 pts).
  - 500-pt Real Canasta (Ace to Ace without wildcard) if variant enabled.
- [ ] **Sets / Groups (*Trincas / Lavadeiras*):** Correctly validates 3+ cards of same rank (if allowed by variant; rejected in STBL/Buraco Fechado).

### 2. State & Turn Flow
- [ ] **Draw Phase Restriction:** Player cannot play cards or discard before drawing from stock or discard pile.
- [ ] **Buraco Fechado Discard Pile:** Discard pile (*lixo*) pickup is blocked unless player immediately melds using the top card.
- [ ] **Pot (*Morto*) Mechanics:**
  - *Direct Batida:* Player plays all cards without discarding → picks Morto immediately and continues playing.
  - *Indirect Batida:* Player discards last card → picks Morto and waits for next turn.
  - *No Double Morto:* Each team/player can only pick one Morto per round.
- [ ] **Final Batida (Going Out):** Blocked if player/team has not picked Morto or lacks required Clean Canasta.

### 3. Scoring Engine (`ScoreCalculator`)
- [ ] Positive points: Canastas (Clean 200, Dirty 100, Real 500), Batida bonus (100), individual card face values in melds.
- [ ] Negative deductions: Cards remaining in hand deducted point-for-point.
- [ ] Morto penalty: -100 points if the team did not pick up their Morto.

## Game Bug Report Template

```markdown
**Title:** [Short, specific summary, e.g. "MeldValidator: Adding natural 2 to dirty sequence cleans the canasta"]

**Severity:** Blocker | Major | Minor | Cosmetic

**Variant:** Buraco Aberto | Buraco Fechado | STBL | All

**Initial Game State:**
- Hand: `[3♥, 4♥, Joker, 6♥, 2♥]`
- Table Melds: Team 1: `[7♠, 8♠, 9♠]`
- Piles: Stock: 42 cards | Discard: `[K♣]` | Mortos remaining: 1

**Steps to Reproduce:**
1. Player melds `[3♥, 4♥, Joker, 6♥]` (marked as Dirty sequence).
2. Player plays `2♥` onto the meld aiming for position between `A♥` and `3♥`.
3. Observe meld state.

**Expected Behavior:**
The meld remains Dirty because the Joker is still present in the sequence.

**Actual Behavior:**
The meld incorrectly changed status to Clean Canasta upon adding `2♥`.

**Minimal Repro Code:**
```gdscript
var cards: Array[CardData] = [card(3, HEARTS), card(4, HEARTS), joker(), card(6, HEARTS), card(2, HEARTS)]
var result = MeldValidator.validate(cards)
assert_true(result.is_dirty, "Meld with joker must be dirty")
```
```

## Guidelines

- **Headless First:** Write tests that run headlessly via Godot CLI so they can execute in continuous integration without GPU display requirements.
- **Isolate Logic from Animation:** A test should verify the state transition, not wait for a 0.3s Tween to finish.
- **Deterministic Seeds:** Always use fixed seeds for testing shuffle, dealing, and bot decision algorithms.
