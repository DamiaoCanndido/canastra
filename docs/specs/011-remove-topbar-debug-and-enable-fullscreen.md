# 011 — Remove TopBar Debug Elements & Enable Fullscreen Display

**Status:** Approved  
**Author:** @gamedesign & @uiux  
**Date:** 2026-09-13  
**Variant / Game Mode:** All (Tabletop UI & Display Configuration)  
**Related Specs / Issues:** Extends Specs 003, 004 & 010  

---

## 1. Problem / UX Goal
1. **TopBar Debug Elements:** The top bar previously held textual labels (`TurnLabel` "Vez do Jogador (Humano)" and `ScoreLabel` "Placar: Humano 0 x 0 Bot") displayed in chip containers. These elements clutter the upper screen border, feel like development/debug instrumentation rather than polished gameplay, and distract from the opponent's hand. Essential gameplay prompts and alerts are already prominently presented through `PromptPanel` at table center.
2. **Window Mode to Full Screen:** The game was running in windowed mode with OS title bars and window decorations visible. The game must run completely borderless full screen (`fullscreen` / `exclusive_fullscreen`) across target displays to provide an immersive digital tabletop experience, while allowing quick toggle via F11 or Alt+Enter.

---

## 2. Technical & UI Specifications

### 2.1 HUD View Modernization (`src/ui/hud_view.tscn` & `src/ui/hud_view.gd`)
- Remove the `TopBar` panel and its child elements (`Margin`, `HBox`, `TurnLabel`, `ScoreLabel`) from `hud_view.tscn`.
- In `hud_view.gd`, update node resolutions to use `get_node_or_null` so removing the top bar does not produce null reference exceptions.
- Maintain `PromptPanel` for turn guidance, action prompts, and round victory announcements.

### 2.2 Fullscreen Display Configuration (`project.godot` & `src/ui/tabletop.gd`)
- In `project.godot`:
  - `display/window/size/mode="fullscreen"`
  - `display/window/size/borderless=true`
- In `src/ui/tabletop.gd`:
  - Enforce fullscreen on startup via `DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)`.
  - Add hotkey handling in `_unhandled_input` for `F11` and `Alt+Enter` to toggle between fullscreen and windowed mode ergonomically.

---

## 3. Acceptance Criteria
- [ ] `TopBar` is eliminated from `hud_view.tscn`, removing the debug status chips from the top border.
- [ ] `hud_view.gd` safely handles absence of `turn_label` and `score_label` without errors.
- [ ] Central `PromptPanel` continues to display turn prompts and announcements.
- [ ] Display configuration is set to `fullscreen` and `borderless=true` in `project.godot`.
- [ ] Game initializes in fullscreen mode on startup.
- [ ] Pressing `F11` or `Alt+Enter` toggles fullscreen mode cleanly.
- [ ] All automated unit and UI component tests pass with 0 errors.
