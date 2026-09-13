# 013 — Combat Core Architecture & Dueling System

**Status:** Draft / Ready for Review  
**Author:** @gamedesign (Game Designer & Product Lead)  
**Date:** 2026-09-13  
**Variant / Game Mode:** Roguelike Deckbuilder — Dueling Combat Mode  
**Related Specs / Issues:** Builds upon Specs 001 (Core Models), 002 (Match State Machine), 008 (Meld Insertion), and 012 (Drag & Drop)

---

## 1. Problem & Game Design Goal

Traditional Canastra / Buraco is played as an accumulative 4-player team game over multiple hands until a team hits 3,000 to 5,000 points. While mathematically deep, this classic structure does not fit the high-tension, fast-paced single-player roguelike format popularized by *Slay the Spire*, *Inscryption*, *Balatro*, and *Black Jacket*.

This specification defines the **Combat Core Architecture & Dueling System** for *Canastra Roguelike*. In this mode:
1. The player faces off in 1-on-1 duels against varied NPC opponents (e.g. *Bêbado Fanfarrão*, *Agiota do Baralho*, *Rainha da Canastra*).
2. Melds (*sequências* and *trincas*) played on the table become the player's **active combat engine**, generating persistent Damage, Block, and Status effects every turn.
3. The **Morto (Pot)** becomes a dramatic **Second Wind / Burst** comeback mechanic.
4. The **Lixo (Discard Pile)** becomes a **contested tactical zone** shared between the player and the enemy.
5. The **Batida (Going Out)** serves as an **Instant Decapitation / Execution** finisher.
6. The entire combat system is decoupled from visuals, running purely on headless `RefCounted` data models testable via GUT.

---

## 2. Core Combat Flow & Turn State Machine

```
                  [ COMBAT INITIALIZATION ]
   (Load Player Deck, Shuffle, Deal 11 Hand, 11 Morto, Enemy HP & Intent)
                             │
                             ▼
              ┌──► [ TURN: DRAW PHASE ]
              │     ├── Draw 1 from Stock (Monte) OR
              │     └── Buy full Discard Pile (Lixo)
              │              │
              │              ▼
              │    [ TURN: ACTION PHASE ]
              │     ├── Place new Melds (Sequences/Sets) onto the table
              │     ├── Append cards to existing Melds
              │     └── Use Consumables (Drinks/Simpatias)
              │              │
              │              ▼
              │    [ TURN: DISCARD PHASE ]
              │     └── Discard 1 card from hand into Lixo
              │              │
              │              ▼
              │    [ COMBAT RESOLUTION PHASE ]
              │     ├── 1. Active Melds trigger Turn-End Effects (Damage & Block)
              │     ├── 2. Apply Player Damage to Enemy (Check HP <= 0 ──► VICTORY)
              │     ├── 3. Check MORTO Trigger (Hand empty? ──► Take Morto + Burst Buff)
              │     └── 4. Check BATIDA Trigger (Hand empty + Morto taken + Clean Canasta? ──► EXECUTION)
              │              │
              │              ▼
              │    [ ENEMY TURN PHASE ]
              │     ├── 1. Enemy executes telegraphed Intent (Attack, Debuff, Sabotage, Steal Lixo)
              │     ├── 2. Apply Enemy Damage to Player Block/HP (Check Player HP <= 0 ──► DEFEAT)
              │     ├── 3. Enemy discards or interacts with Lixo
              │     └── 4. Enemy telegraphs next turn's Intent
              │              │
              └──────────────┴── (Next Turn Loop)
```

---

## 3. Meld-to-Combat Conversion Engine (`CombatResolver`)

Every turn, when the player completes their Discard Phase, all active melds currently sitting on the player's side of the table resolve their combat values.

### 3.1 Suit Affinities (Naipes de Combate)
Cards generate base stats proportional to their rank value (`3-7 = 5`, `8-K = 10`, `A = 15`, `2 = 10`, `Joker = 20`) modulated by their suit:

| Suit | Name | Primary Effect | Secondary Trigger / Status |
|---|---|---|---|
| ♠ **Spades** (*Espadas*) | **Aço & Lâmina** | **Direct Damage (Ataque)**: Deals damage equal to card value to enemy HP. | If meld contains 4+ Spades, applies **Vulnerable** (Enemy takes +50% damage next turn). |
| ♥ **Hearts** (*Copas*) | **Vitalidade** | **Block (Escudo)**: Generates shield equal to card value to absorb enemy attacks. | If meld contains 4+ Hearts, heals player for **3 HP**. |
| ♣ **Clubs** (*Paus*) | **Impacto & Porrete** | **Shield Break & Disruption**: Deals double damage to enemy Block/Shield. | If meld contains 4+ Clubs, applies **Weaken** (Enemy attacks deal 25% less damage). |
| ♦ **Diamonds** (*Ouros*) | **Fortuna & Ouro** | **Economy & Crit Multiplier**: Generates +1 Gold ($) per 10 points of meld. | Grants +0.2x **Crit Chance** to all Spades attacks this turn. |

*Note on Multi-suit Melds (Trincas/Sets):* Trincas trigger the affinity of each individual card in the set, allowing hybrid damage + block combinations.

### 3.2 The Canasta Finishers (7+ Cards)
When a sequence reaches 7 or more cards on the table, it triggers a powerful instantaneous burst and permanently upgrades the meld's per-turn output:

1. **Canasta Suja (Dirty Canasta — contains 1 Wildcard):**
   - **Instant Burst:** Deals **80 Poison Damage** immediately and inflicts 3 stacks of **Poison** (deals damage at start of enemy turn).
   - **Per-Turn Bonus:** +15 Damage every turn thereafter.

2. **Canasta Limpa (Clean Canasta — no Wildcards):**
   - **Instant Burst:** Deals **180 True Damage** (bypasses enemy Shield) and grants the player **+30 Retained Block** (persists between turns).
   - **Per-Turn Bonus:** +30 Damage and +15 Block every turn thereafter.
   - **Pre-requisite:** Required condition to achieve a Batida (Execution).

3. **Canasta Real / Ás a Ás (13-14 Cards Run from Ace to Ace):**
   - **Instant Burst:** **500 Grand Slam Damage**. Executes any non-boss enemy instantly, and deals massive critical blow to bosses.

---

## 4. The Three Pillars of Buraco in Combat

### 4.1 O Morto (The Pot) — Second Wind Mechanic
- Each combat starts with **1 Morto (11 cards)** locked in the player's reserve.
- **Trigger:** When the player plays or discards the final card of their initial 11-card hand.
- **Immediate Combat Effects:**
  - The Morto opens immediately: player draws 11 fresh cards into hand.
  - **Second Wind Buff:** Player heals for **20% Max HP**.
  - **Adrenaline Surge:** All damage dealt on the next turn is doubled (**2.0x Critical Damage**).
- **Direct vs Indirect Morto:**
  - *Direct Morto (No Discard needed):* If player places all hand cards into melds, they pick up the Morto and **continue their current turn** immediately with the 11 new cards!
  - *Indirect Morto (On Discard):* If the last card was discarded, the turn ends, enemy acts, and player starts their next turn with the Morto in hand.

### 4.2 O Lixo (The Discard Pile) — Contested Tactical Zone
The Discard Pile is **shared between the Player and the Enemy**:
- Every card the player discards enters the Lixo.
- Enemies also discard cards into the Lixo according to their AI routines.
- **Player Tactical Choice:**
  - Buy the Lixo: Take **all cards** in the pile. If the pile has 6 cards, you get all 6.
  - Risk/Reward: Expands hand options to build massive melds, but clutters the hand.
- **Enemy Lixo Interactions:**
  - Certain enemies have intents to **"Burn the Lixo"** (removes all cards from combat) or **"Steal the Lixo"** (heals or buffs the enemy based on card count).
  - Players must time their Lixo pickups to starve the enemy or seize valuable cards before they are destroyed.

### 4.3 A Batida (Going Out) — Combat Finisher
- **Conditions:**
  1. Player has already claimed their Morto.
  2. Player has at least **1 Clean Canasta** on the table.
  3. Player plays all cards from their hand (with or without final discard).
- **Effect:** **INSTANT KNOCKOUT (BATIDA EXECUTION)**.
  - The enemy's remaining HP is immediately wiped out.
  - Grants a **"Perfect Knockout"** bonus reward (+50 Gold and high-tier card draft).

---

## 5. Enemy Architecture & Intent System

### 5.1 Enemy Data Model (`EnemyData.gd`)
Each enemy has:
- `enemy_name: String`
- `max_hp: int` and `current_hp: int`
- `block: int` (clears at start of enemy turn unless retained)
- `status_effects: Dictionary` (Vulnerable, Weaken, Poison, Stunned)
- `archetype: EnemyArchetype` (`BRAWLER`, `SWINDLER`, `CANASTA_MASTER`, `BOSS`)
- `action_deck: Array[EnemyAction]` (Pattern or AI weighted pool)

### 5.2 Enemy Intents (`EnemyIntent.gd`)
At the start of the Player's turn, the Enemy's upcoming action is explicitly telegraphed above their sprite/avatar:

| Intent Icon | Type | Description | Player Counter-Strategy |
|---|---|---|---|
| 🗡️ **Attack** | Direct Strike | Will deal `X` damage to player. | Build ♥ Hearts melds for Block. |
| 🛡️ **Defend** | Fortify | Will gain `Y` block. | Build ♣ Clubs melds to break shields. |
| ☠️ **Debuff** | Sabotage | Freezes cards in hand or adds Cursed cards to deck. | Rush hand depletion to trigger Morto. |
| 🗑️ **Steal Lixo** | Scavenge | Will consume all cards in the Lixo to heal `5 * Count` HP. | Buy the Lixo before the enemy turn! |
| 🔥 **Burn Lixo** | Incinerate | Destroys all cards currently in the Lixo. | Take the cards if you need them. |
| 🃏 **Counter-Meld** | Master Move | Places a rival meld that drains player score/HP. | Focus on building a Clean Canasta. |

---

## 6. Combat State & Signal Bus Contract

### 6.1 `CombatState.gd` (`RefCounted`)
```gdscript
class_name CombatState
extends RefCounted

var player_hp: int = 80
var player_max_hp: int = 80
var player_block: int = 0
var player_gold: int = 0

var enemy_data: EnemyData = null
var current_turn: int = 1
var is_player_turn: bool = true
var took_morto: bool = false

var stock_pile: Array[CardData] = []
var discard_pile: Array[CardData] = []
var player_hand: Array[CardData] = []
var morto_pile: Array[CardData] = []
var player_melds: Array[MeldData] = []
```

### 6.2 New Combat Signals (`EventBus.gd`)
```gdscript
# Combat Signals
signal combat_started(enemy: EnemyData)
signal combat_ended(victory: bool, rewards: Dictionary)
signal intent_telegraphed(enemy_intent: EnemyIntent)
signal combat_stat_applied(target: String, stat_type: String, amount: int)
signal block_changed(target: String, new_block: int)
signal hp_changed(target: String, current_hp: int, max_hp: int)
signal morto_burst_triggered(player_id: int)
signal batida_executed(enemy: EnemyData)
signal lixo_stolen(by_who: String, cards_stolen: int)
```

---

## 7. Out of Scope for this Spec (Future Iterations)
- Map node procedural generation (Slay the Spire branching map will be Spec 014).
- Shop / Merchant UI and economy balancing (Spec 015).
- Relic / Talisman inventory and trigger matrix (Spec 016).
- Enemy animated 2D rigs and visual juice (Spec 017).

---

## 8. Acceptance Criteria (For @qa & @gamedev verification)

### Combat Math & Melds
- [ ] Playing a ♠ Spades sequence `[4♠, 5♠, 6♠]` (values: 5+5+5 = 15) inflicts exactly 15 damage to enemy on discard.
- [ ] Playing a ♥ Hearts sequence `[8♥, 9♥, 10♥]` (values: 10+10+10 = 30) generates exactly 30 Block for the player.
- [ ] Hybrid sets/trincas calculate stats per card (e.g. `[7♠, 7♥, 7♣]` = 5 Dmg + 5 Block + 5 Shield Break).
- [ ] Achieving a Clean Canasta (7+ cards no wildcard) deals 180 true damage and sets `has_clean_canasta = true`.
- [ ] Achieving a Dirty Canasta deals 80 damage and applies 3 stacks of Poison.

### Morto & Batida Triggers
- [ ] When player hand size reaches 0 before discard, Morto is picked directly, hand becomes 11 cards, turn continues.
- [ ] When player hand size reaches 0 via discard, Morto is picked indirectly, next turn starts with 11 cards.
- [ ] Picking the Morto heals player for 20% Max HP and sets critical multiplier to 2.0x for next turn.
- [ ] When player hand reaches 0, `took_morto == true`, and player has a Clean Canasta, `batida_executed` fires and enemy HP drops to 0 immediately.

### Lixo & Enemy Intent
- [ ] Player can draw from either Stock or the entire Discard Pile.
- [ ] Enemy with `STEAL_LIXO` intent consumes all cards in `discard_pile` and heals proportionally.
- [ ] Enemy with `ATTACK` intent deals damage to player Block first, overflow damage hits HP.

---

## 9. Edge Cases & Boundary Conditions

1. **Empty Stock Pile (Monte Esgotado):** If the draw pile empties before combat finishes, all cards in Lixo (except top card) are shuffled back into the Stock pile. If both are exhausted, sudden death fatigue takes 5 HP per turn.
2. **Double Wildcard Rejection:** Melds with more than 1 wildcard are rejected by `MeldValidator`, preventing invalid damage exploit.
3. **Overkill Damage on Batida:** A Batida triggers regardless of remaining enemy Block or HP.
4. **Enemy Lethal during Morto Turn:** If an enemy intent is lethal before the player can claim the Morto, combat ends in defeat (Morto does not prevent lethal damage unless already claimed).
