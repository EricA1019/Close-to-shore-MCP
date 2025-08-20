# Broken Divinity CP437 Index (Draft)

This defines how Broken Divinity uses the CP437 tileset. We inherit the community’s well‑trodden defaults for common items (walls, beds, doors, stockpiles, stairs) and introduce a focused set of overrides for our religious‑horror colony and roguelike elements.

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

Broken Divinity override areas (proposed)
- Factions and beings
  - Angels: bright gold/yellow on A or Ä (142) for key figures; lighter highlights for blessed status.
  - Demons: red on & (38); deeper reds/browns for infernal elites.
  - Mortals (player/recruits): @ (64) primary; rim color indicates allegiance/status.
- Status effects
  - Blessing: ☼ (15) aura or gold overlay; optional invert for “active.”
  - Curse/Corruption: ~ (126) effect glyph with purple tint overlay.
- Holy vs. Infernal interactions
  - Holy effects/projectiles: * (42) gold/white.
  - Infernal effects/projectiles: * (42) red/orange.
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
- Angels: Ä (142) or A with gold tint; add ☼ (15) aura for blessed.
- Demons: & (38) in strong reds; elites use deeper/bolder variants.
- Blessing: aura/overlay ☼ (15) or subtle color pulse.
- Holy projectile: * (42) gold; Infernal projectile: * (42) red.
- Altar: É (144) gold; Makeshift shrine: + with white/yellow.
- Brave militia: B (66) with subtle teal rim to stand out.

File/asset placement
- Font bitmap: `godot_project/assets/project/cp437_16x16.png` (added).
- Font license: `godot_project/assets/project/LICENSE_cp437_font.txt` (add in this hop or next; include MIT text from source).
- Optional config next hop: `godot_project/data/config/cp437_index.json` mapping entity keys → {codepoint, fg, bg, style}.

Implementation sketch (next hop)
- Registry (JSON or GDScript dictionary) mapping identities → {codepoint, fg, bg, style}.
- Adapter in the grid renderer to resolve game entities to CP437 tiles + colors at draw time.
- Fallback rule: if key missing, render with community default.

Open questions (answer Y/N)
1) Keep community defaults for walls/doors/furniture entirely for the next hop? (Y keeps them unchanged; N propose remaps.)
2) Use Ä (142) for Angels by default? (Y=Ä; N=plain ‘A’ with gold.)
3) Use & (38) for Demons? (Y=&; N=alternate glyph.)
4) Represent Blessing with a ☼ (15) aura overlay? (Y=☼ overlay; N=color‑only.)
5) Represent Curse/Corruption with purple‑tinted ~ (126) effects? (Y=~ purple; N=other.)
6) Distinguish holy/infernal projectiles via color on * (42) only? (Y=color‑only; N=different glyphs.)
7) Reserve @ (64) for player/important mortals, with faction rim‑color? (Y=@; N=alternate.)
8) Use É (144) for Altars and + compositions for shrines? (Y=É/+; N=alternate.)
9) Allow inverse style for “active” states (e.g., active blessing)? (Y=invert OK; N=avoid inversion.)
10) Add the font’s MIT license file to assets in this hop? (Y=add now; N=defer.)
11) Store mappings in JSON (`data/config/cp437_index.json`) in this hop? (Y=JSON now; N=doc‑only this hop.)
12) Limit palette to the four theme groups above initially? (Y=limit; N=expand now.)

Once confirmed, we’ll lock this index and wire a small registry loader for the grid renderer.

#EOF
