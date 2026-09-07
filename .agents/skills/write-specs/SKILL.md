---
name: write-specs
description: >-
  Defines the process and template the Game Designer agent (@gamedesign) uses to turn a game idea, rule variant, or feature request into a clear, actionable specification for Godot 4 Canastra card game development.
---

# Write Specs

**Skill for:** `@gamedesign` (or `@pm`)

## Purpose

Defines the process and template the Game Designer agent uses to turn a raw game idea, rule variant, gameplay mechanic, or card interaction into a precise, actionable specification before engineering and visual implementation begins.

## When to use

- A new game rule or variant is being introduced (e.g. Buraco Aberto, Fechado, STBL, Trincas/Lavadeiras).
- A core card mechanic is being designed or revised (e.g. Meld validation, Wildcard replacement, Pot/Morto pickup, Discard pile/Lixo rules).
- Turn flow, state transitions, or scoring formulas are being updated.
- Scope and acceptance criteria need to be locked down before `@gamedev` and `@uiux` start development.

## Process

1. **Clarify the Mechanic or Problem** — What is being added or changed? Which game mode or variant does it apply to?
2. **Define Game Rules & Constraints** — What are the exact card requirements (min cards, allowed wildcards, natural 2 vs joker, sequence ordering A-2-3..K-A)?
3. **Map State Transitions & Triggers** — How does this interact with the turn state machine (Draw Phase → Action Phase → Discard Phase)? What triggers pot pickup or going out (*batida*)?
4. **Specify Scoring Rules** — Exact points awarded or deducted (clean canasta: 200, dirty: 100, 500pt real canasta, card values, pot penalties).
5. **Detail Visual & Audio Feedback Requirements** — What animations, UI highlights, and audio cues should accompany this mechanic?
6. **Set Acceptance Criteria** — Concrete, testable conditions for "done" that feed directly into `@qa`'s test plan.
7. **Flag Edge Cases & Open Questions** — Unresolved scenarios (e.g., draw pile exhaustion, double pot scenarios, replacing a 2 with the natural card).
8. **Review before Handoff** — Confirm design integrity before handing off to `@gamedev`.

## Game Feature Spec Template

```markdown
# [Feature / Mechanic Name] — Spec

**Status:** Draft | In Review | Approved  
**Author:** @gamedesign  
**Date:** YYYY-MM-DD  
**Variant / Game Mode:** Buraco Aberto | Buraco Fechado | STBL | All  
**Related Specs / Issues:** [links]

## Problem / Game Design Goal
What player experience or rule requirement does this address? Why is it needed?

## Rule Overview & Mechanics
Detailed explanation of the card rule, sequence of events, and constraints:
- **Card Requirements:** (e.g., Minimum 3 cards of the same suit in sequence or same rank)
- **Wildcard Rules:** (e.g., Max 1 wildcard per meld; natural 2 allowed if in place)
- **Canasta Definition:** (e.g., 7+ cards; Clean = no wildcard, Dirty = 1 wildcard)

## State Machine & Flow
- **Preconditions:** (e.g., Player's turn, currently in Action Phase)
- **Trigger / Action:** (e.g., Player drags card group to table or clicks "Meld")
- **Postconditions / State Transition:** (e.g., Cards removed from hand, added to TableMelds, score updated)

## Scoring Rules & Penalties
- Meld Points: ...
- Canasta Bonus: ...
- Hand Deductions / Penalty: ...

## UI & Feedback Requirements
- Visual Animations: (e.g., Tween card move to table meld stack)
- Highlights / Drop Zones: (e.g., Glow green when hover over valid meld)
- Audio / SFX: (e.g., `card_slide.wav`, `canasta_fanfare.wav`)

## Out of Scope / Non-Goals
- What should NOT be implemented in this iteration?

## Acceptance Criteria
- [ ] Valid sequence [4♥, 5♥, 6♥] is accepted.
- [ ] Invalid sequence [4♥, 5♠, 6♥] is rejected with clear error.
- [ ] Adding Joker to [4♥, 5♥, 6♥] results in dirty meld [4♥, 5♥, 6♥, Joker].
- [ ] A 7-card run without wildcards is flagged as `CLEAN_CANASTA` (+200 pts).
- [ ] ...

## Edge Cases & Boundary Conditions
1. **Case 1:** What happens if the player tries to add a second wildcard to an existing dirty meld?
2. **Case 2:** How does a natural 2 shift when a joker is placed in the sequence?
3. **Case 3:** Player goes out (*bate*) by playing all cards without discarding — direct pot pickup.
```

## Guidelines

- **Zero Ambiguity:** Every card rule must have an exact logical condition; avoid subjective phrasing like "sensible move."
- **Keep Logic Testable:** Every acceptance criterion must be verifiable by `@qa` through pure data tests without requiring manual UI clicking.
- **Respect Variant Differences:** Always specify which variant rules apply (e.g., in Buraco Fechado, you cannot pick the discard pile without immediately playing a meld with the top card).
- **Separate Design from Code:** Specify what the rules and game states are, leaving the data structures and algorithms to `@gamedev`.
