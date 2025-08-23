# Broken Divinity CP437 Index (Draft)

This defines how Broken Divinity uses the CP437 tileset. We inherit the community’s well‑trodden defaults for common items (walls, beds, doors, stockpiles, stairs) across the whole project and introduce a focused set of overrides for our religious‑horror colony and roguelike elements.

Credits
- CP437 conventions and documentation from the Dwarf Fortress community (Bay 12 Games + modders). Thank you for decades of iteration and guidance.
- Font: 16×16 CP437 bitmap (full 0–255). License: MIT. Place the font’s license file next to the asset and credit the author(s).

Goals
- Maintain compatibility with common CP437 expectations so seasoned players feel at home.
- Use color and a few tile overrides to convey themes (angels, demons, blessings, holy vs. infernal effects).
- Avoid remapping staples (walls, doors, furniture) unless there’s a strong need.

Inherit unchanged (community defaults)
- Terrain/structures: walls (█/▓/▒), floors (·/.), bridges, stairs (</>), ramps (▲/▼), channels (^/_), tracks (║/═/╬ family), doors (╬/+), grates (#), cages (‼), coffins (0), stockpiles (=), workshop frames ([/]).
- Furniture: beds, tables, chairs, containers, mechanisms — use standard CP437 glyphs and colors as documented.
- Items/markers: coins ($), rope (ƒ), levers (ò/ó), bins (X), floodgates (X¢), traffic indicators (H/R), etc.

Broken Divinity overrides (locked in)
- Factions and beings
  - Angels: Ä (142), color gold/yellow.
  - Demons: & (38), color red/orange family.
  - Mortals: @ (64) reserved for player only (important NPCs use other letters with faction tints).
- Status effects
  - Blessing: ☼ (15) aura overlay in gold; allow invert style for “active.”
  - Curse/Corruption: ~ (126) effect glyph with purple tint overlay.
- Holy vs. Infernal interactions
  - Holy effects/projectiles: * (42) gold/white (glyph shared).
  - Infernal effects/projectiles: * (42) red/orange (glyph shared).
- Colony affordances
  - Altars/Shrines: É (144) for altar; simple + and | compositions for shrines (gold/white).
  - Relics: § (21) or ¶ (20) for notable items; color by faction.
- UI hints (non‑lore)
  - Selection cursor: X (88) cyan/white.
  - Interactables: + (43) or » (175) accent; keep subtle.

Initial color palette guidance
- Angels/holy: gold/yellow (ffd66b–fff2b0), white accents.
- Demons/infernal: red/orange (b33a3a–ff6b35), shadow accents (4a2b2b).
- Neutral/colony: steel/copper/wood tones; ensure furniture vs. floor contrast.
- Status: healing/holy (gold/white), poison/curse (plum/purple), fire (orange), cold (ice‑blue).

Mapping notes (examples)
- Angels: Ä (142) in gold; add ☼ (15) aura for blessed.
- Demons: & (38) in strong reds; elites use deeper/bolder variants.
- Blessing: aura/overlay ☼ (15) or subtle color pulse.
- Holy projectile: * (42) gold; Infernal projectile: * (42) red.
- Altar: É (144) gold; Makeshift shrine: + with white/yellow.
- Brave militia: B (66) with subtle teal rim to stand out.

Materials & colors (expanded)
- Wood: brown (e.g., apartment wood floor uses . (46) with wood‑brown fg)
- Stone: neutral grays (walls/floors follow community glyphs, colored per material)
- Metal: steel/silver; Copper/Bronze richer oranges; Gold bright gold
- Water: blue; Foliage: green; Sand/Earth: tan; Blood: deep red; Ice: pale/icy blue

File/asset placement
- Font bitmap: `godot_project/assets/project/cp437_16x16.png` (added).
- Font license: `godot_project/assets/project/LICENSE_cp437_font.txt` (add in this hop or next; include MIT text from source).
- Config (CSV preferred): `godot_project/data/config/cp437_index.csv` is the maintained source (easier to edit/scan). Loader prefers CSV and falls back to JSON at `godot_project/data/config/cp437_index.json`. Both map keys → {codepoint, fg, bg, style} with optional `fg_from_material` and `rules`.

CSV schema header:
category,key,codepoint,fg,bg,style,fg_from_material,value,notes
Notes: `style` is pipe‑separated (e.g., overlay|active_invert_allowed). For rules, use `value` for booleans and `codepoint` for reserved entries (e.g., rules,reserved.player,64,...).

Implementation sketch (next hop)
- Registry (JSON or GDScript dictionary) mapping identities → {codepoint, fg, bg, style}.
- Adapter in the grid renderer to resolve game entities to CP437 tiles + colors at draw time.
- Fallback rule: if key missing, render with community default.

Decisions locked (from Y/N):
- Keep community defaults for walls/doors/furniture for the whole project.
- Angels: Ä (142) in gold; Demons: & (38) in red.
- Blessing: ☼ (15) aura overlay; allow invert for “active.”
- Curse/Corruption: purple‑tinted ~ (126) effects.
- Projectiles: * (42) shared glyph; color gold vs. red.
- @ (64) reserved for player only.
- Altars/Shrines: É (144) and + compositions.
- Add font MIT license file now; store mappings in JSON now.
- Expand palette beyond 4 groups to include general materials (wood, stone, metals, etc.).

Next steps
1) Fill `data/config/cp437_index.json` with initial entities and a material color palette (done in this hop).
2) Add a small loader/helper to resolve keys → {codepoint, fg, bg, style} at draw time (scoped for next hop integration into the grid renderer).
3) Keep a fallback to community defaults for any unmapped keys.

#EOF
