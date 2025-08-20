# Demo Spec — Broken Divinity: New Babylon

Author: Eric — Date: 2025-08-18

## Hop 1: Boot, Menu, and UI Restoration

- Main scene: opening_with_logo.tscn (routes to animated main menu)
- Main menu: all buttons (New Game, Options, Credits, Exit) now fully wired
- New Game launches five-panel Main UI (main_ui.tscn)
- Options menu restored (tabs: Controls, Audio, Video)
- Credits and Exit function as expected
- All broken/empty scenes/scripts restored from template
- Headless and editor boot confirmed

This document specifies the prototype/demo flow and required systems. It aligns with the Close-to-Shore MCP workflow and will be referenced by hops and tests.

## Style & Presentation
- Door-in-the-Woods inspired, top-down ASCII rendered via AsciiPanel
- Four-panel layout: TopBar (date/time/currency), StatusPanel (player/follower stats), LogPanel (narration/combat log), ActionBar (contextual actions)
- Monospaced CP437-like baseline font; faction-styled variants (Angels: flowing gold; Demons: angular red)

## Data & Persistence
- SQLite database for content: suffix tables, large text assets, ASCII art
- JSON save system with 3 slots; metadata stored alongside saves

## Turn & Combat
- TurnEngine: initiative per round; 2 actions per turn; movement/attack interchangeable
- CombatManager: damage types (ballistic, infernal, holy); blessing status converts outgoing damage → holy for N rounds

## Demo Narrative Beats
1) Apartment exploration: default UI scene; simple room to move around
2) Mirror → character creation scene (name, background: homicide/narcotics/organized crime; personal traits: veteran/lost loved one/estranged sibling)
3) Equip gear; show inventory and stat mods; leave apartment
4) Meet Dona Margarita; escort through alley while creatures fall (text)
5) Combat: 2 imps with semi-random suffixes; Detective shoots .38 (low damage), Dona prays → blessing converts ballistic→holy; subsequent shot does high damage and wins
6) Unwinnable angel fight; both slain; demonstrate NPC permadeath
7) Voice in the dark: Lucifer explains shattering; offer near-immortality for investigation
8) Wake at New Babylon; badge of the Morning Star; angels/demons react accordingly
9) Build basic shanty and production facilities; resource loop continues if maintained
10) Recruit militia: yields two units; one always “brave” (higher courage); suffix system features
11) Travel to ruin with a branching “random” event; with enough charm, reconcile both sides; grants recruits and a .357 magnum with random affix if both agree
12) Procgen ruin: central panel grid; exploration and loot; assign gear to followers
13) Return to settlement; Lucy signs off; splash and credits

## Minimal Viable Content for Demo
- Suffix table (sample entries including “brave”)
- Angel/demon reaction flavor text and basic behavior flags
- Base gear: Model 10 (.38), Rosary (blessing), .357 Magnum (+affix)
- Procgen: small set of room/corridor templates sufficient for traversal

## Tests to Cover (by Hop)
- Smoke: project boots; UI panels exist
- Unit: TurnEngine ordering; action budget; CombatManager blessing conversion
- Integration: Save round-trip; SQLite read; character creation data persisted
- Game-flow: Apartment → Mirror → Alley fight → Scripted loss → Settlement → Ruin → Credits

## Out of Scope (Demo)
- Full dialog trees; advanced AI; complex economy balancing; large dungeons; full faction diplomacy

---
Use this spec to guide hop plans and tests. Keep it updated as scope evolves.

#EOF
