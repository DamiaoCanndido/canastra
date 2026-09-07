---
name: startcycle
description: Standard end-to-end development cycle for game features and mechanics in Godot 4
---

# Start Cycle

**Type:** Workflow (orchestrates `@gamedesign`, `@gamedev`, `@uiux`, `@qa`, `@devops`)

## Purpose

Defines the standard end-to-end cycle for taking a game feature, card rule variant, visual mechanic, or engine component from concept to release in Godot Engine 4, running each specialized agent and its corresponding skill in sequence, with defined handoffs and feedback loops.

## Invocation

```
/startcycle <idea>
```

- `<idea>` — a short description of the game mechanic, rule variant, UI component, or system to develop (e.g. "Implement MeldValidator for sequences and wildcard replacements" or "Create responsive player hand component with drag-and-drop card fan").
- Running this command starts the cycle at **Phase 1**, passing `<idea>` to `@gamedesign` as raw input for the `write-specs` skill.
- The cycle then proceeds systematically through Phases 2–5 unless a feedback loop sends it backward or the process is explicitly paused.

**Example:**

```
/startcycle Add support for Buraco Fechado rules with closed discard pile and mandatory meld justify
```

## Cycle Overview

```
@gamedesign (write-specs)
   → @gamedev (generate-code)
   → @uiux (build-uiux)
   → @qa (audit-code)
   → @devops (export-game)
   → Released
```

---

## Phase 1 — Specify (`@gamedesign` → `write-specs`)

**Trigger:** `/startcycle <idea>` is executed.

**Runs:** `@gamedesign` executes the `write-specs` skill.

**Output:** An approved Game Feature Specification (Problem/Goal, Rule Variant context, Card Data & State transitions, Move validation criteria, Scoring rules, Edge cases, Acceptance Criteria).

**Exit condition:** Spec is marked "Approved." All rule ambiguities (e.g. wildcard rules, pot pickup criteria, scoring penalties) must be explicitly resolved.

**Handoff to:** `@gamedev`

---

## Phase 2 — Core Gameplay & Architecture (`@gamedev` → `generate-code`)

**Trigger:** Approved specification from Phase 1.

**Runs:** `@gamedev` executes the `generate-code` skill.

**Output:** Implemented GDScript 4 models (`RefCounted`/`Resource`), state machines, card algorithms, and signal interfaces with accompanying unit tests.

**Exit condition:** Code compiles cleanly with static typing, headless unit tests pass, and self-review is complete.

**Handoff to:** `@uiux` (if visual/UI work is required) or `@qa` (if pure logic/headless feature).

**Feedback loop:** If rule edge cases or state transitions turn out ambiguous or contradictory during coding, return to `@gamedesign` before proceeding — do not guess game rules.

---

## Phase 3 — Visuals & UI Interaction (`@uiux` → `build-uiux`)

**Trigger:** Implemented gameplay logic/signals from Phase 2.

**Runs:** `@uiux` executes the `build-uiux` skill.

**Output:** Godot 4 scenes (`.tscn`), responsive `Control` layouts, card drag-and-drop mechanics, fluid `Tween` animations, and audio/haptic triggers connected to model signals.

**Exit condition:** Visual components render responsively across resolutions, card animations run without frame drops or state desync, and drag-and-drop flows are verified.

**Handoff to:** `@qa`

**Feedback loop:** If the UI reveals missing signals or rigid model APIs, return to `@gamedev` to refine the interface contract.

---

## Phase 4 — Rule Audit & Quality Assurance (`@qa` → `audit-code`)

**Trigger:** Implemented logic and UI from Phases 2 and 3.

**Runs:** `@qa` executes the `audit-code` skill.

**Output:** Sign-off (ready for export) or structured bug reports covering rule edge cases, card state desyncs, or UI glitches.

**Exit condition:** All acceptance criteria verified; automated GUT/headless tests pass; edge cases (pot triggers, wildcard swaps, empty stock, invalid melds) thoroughly tested.

**Handoff to:** `@devops`

**Feedback loop:** Rule violations or game-breaking bugs send the cycle back to Phase 2 (`@gamedev`) or Phase 3 (`@uiux`). If the issue reveals an unhandled rule ambiguity, return to Phase 1 (`@gamedesign`).

---

## Phase 5 — Export & Release (`@devops` → `export-game`)

**Trigger:** QA sign-off from Phase 4.

**Runs:** `@devops` executes the `export-game` skill.

**Output:** Exported game builds (Web HTML5/WASM, Linux, Windows, Mobile), verified via headless build checks, optimized asset bundles, and release checksums.

**Exit condition:** Build exported successfully without errors, assets optimized, and release artifacts generated.

**Feedback loop:** Build or export template failures send the cycle back to Phase 2 or Phase 5 for packaging adjustments.

---

## Cycle Tracker

```markdown
## Cycle: [Feature Name / Issue #]

- [ ] Phase 1 — Spec approved by @gamedesign (link)
- [ ] Phase 2 — Core logic implemented by @gamedev (link/branch)
- [ ] Phase 3 — Visuals & UI built by @uiux (scenes/animations)
- [ ] Phase 4 — Verified by @qa (sign-off or bug report)
- [ ] Phase 5 — Exported by @devops (build/release)

**Current phase:**
**Blocked on:**
**Notes:**
```

## Guidelines

- Each phase has exactly one owner agent at a time — no phase starts before the previous one's exit condition is met.
- Feedback loops go backward only as far as necessary — a visual animation bug doesn't restart the rule spec, but a rule contradiction does.
- Always ensure game logic remains decoupled from visual nodes so `@qa` can test rules headlessly without opening the Godot editor GUI.
- The cycle scales from a small bugfix in minutes to a full game system over days — the sequence remains consistent.
