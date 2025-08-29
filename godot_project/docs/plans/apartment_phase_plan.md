# Apartment Phase Plan (POIs, Entities, Inventory, Clock, Status)

This plan is organized into small, sequential hops. Each hop is independently testable and safe to merge. We use Resource Databases (Godot Resources, not JSON) for all content and index them through the existing Rust bridge.

## Standards (apply to all hops and future checklists)
- Checklist must include: Requirements, Contracts (inputs/outputs/signals), Tests (happy + edge), Definition of Done (DoD).
- IDs are stable, unique, and used for all cross-refs (see Global ID scheme).
- Resource Databases store canonical data as `.tres` files; indices expose lookup by collection and ID.
- No warnings/errors introduced in logs for affected areas; if unavoidable, documented in DoD.

## Guiding decisions (confirmed)
- Start with the Detective (no affix variant).
- Inventory actions available via ActionPanel; Inventory contents shown in Output/Feedback panel.
- Time advances 1s per step; GameClock broadcasts updates.
- Status system applies buffs/debuffs; also gates ability usability (e.g., Cleanse only on affected entities).
- POIs are components bound to grid positions; single source of truth for tile properties via a Tile DB.
- Planning docs live under `godot_project/docs/plans/`.
- Animation track errors are low priority, but fix before the apartment scene is considered done.
- Do Clock + Status first; then entities/inventory interactions; core stats follow D&D-ish baseline and are resource-driven/extensible.

---

## Data and DB Schemas (Resource Databases)

We store content as Godot Resources (`.tres/.res`) and index them via the Resource DB bridge (Rust GDExtension and CLI). Collections correspond to typed resource folders.

### Global ID scheme
- Entity IDs: `E-###` (Detective = `E-001`)
- Item IDs: `I-###` (Service Pistol = `I-001`, Whiskey = `I-002`, Leather Jacket = `I-003`)
- Ability IDs: `A-###` (Cleanse = `A-001`)
- Status IDs: `S-###` (Hungover = `S-001`, Steady Nerves = `S-002`)
- Tile IDs: `T-###` (e.g., Wood Floor = `T-001`)

### Collections and Folders
- `res://data/entities/*.tres` (collection: `entities`)
- `res://data/items/*.tres` (collection: `items`)
- `res://data/abilities/*.tres` (collection: `abilities`)
- `res://data/statuses/*.tres` (collection: `statuses`)
- `res://data/tiles/*.tres` (collection: `tiles`)
- `res://data/layouts/apartment.tres` (layout can still be `.json` for grid, but POI references use IDs; optional migration later)

### Resource Types (Godot)
- `EntityResource` (class_name): id: String, name: String, char: String, stat_block: `StatBlockResource`, ability_ids: Array[String], status_ids: Array[String], equipment_slots: Dictionary, affixes: Array[String]
- `StatBlockResource`: str, dex, con, int, wis, cha (ints) + derived getters
- `AbilityResource`: id, name, target, rules (requires_status/remove_status)
- `StatusResource`: id, name, mods (Dictionary), tags (Array[String])
- `ItemResource`: id, name, type (weapon/armor/consumable), stats/effects, uses, on_equip/on_use text
- `TileResource`: id, name, tags (walkable/lootable/etc.), spawn_rules (optional)

Indexing: The Resource DB bridge indexes `.tres` by collection and `id` field; validations ensure uniqueness and cross-ref integrity.

---

## Hops (Cts convention)

### Hop 1: Docs and Index Prep (Resource DB) ✅ COMPLETED
Requirements
- ✅ Add this plan under `docs/plans/` (done).
- ✅ Extend Resource DB index to include new collections: entities, items, abilities, statuses, tiles.
- ✅ Add validations DB006–DB010:
  - ✅ Unique IDs per collection (DB006).
  - ✅ Cross-ref existence checks: entity.ability_ids -> abilities, entity.status_ids -> statuses, equipment item IDs -> items (DB007).
  - ✅ Tile tags sanity (non-empty for tiles) (DB008).
  - ✅ ID format warnings for E-###, S-###, T-### (DB009).
- ✅ Create `MCP/TOOLS/doc_updater.py` and run it to standardize docs:
  - ✅ Replace Flask mentions with "Python stdlib HTTP server".
  - ✅ Prefer Resource Database (.tres/.res) terminology over JSON DB wording.
  - ✅ Ensure CTS sections have a `### Checklist` (Requirements/Contracts/Tests/DoD).
Contracts
- ✅ Bridge: list(collection), get_by_id(collection, id) for all new collections.
- ✅ CLI: cts db list/get for these collections; validate surfaces DB006–DB010.
Tests
- ✅ Validate shows counts per collection; bad refs are reported with ID and collection.
- ✅ Strict mode exits non-zero on warnings.
DoD
- ✅ New collections appear in index; `validate` passes with green output locally and in CI.
- ✅ Docs updated: CTS and Resource DB docs reflect checklist style and Resource Database-first approach.
- ✅ VS Code tasks exist to run the doc updater (dry-run and apply).
- ✅ Warnings counted and surfaced for strict validation.

### Hop 2: Core Status + Clock ✅ COMPLETED
Requirements
- ✅ `StatusSystem` (autoload): add/remove/has/get_mods; compute effective stat deltas from active statuses.
- ✅ `GameClock` (autoload): `advance(1)` on player step; signal `time_changed`.
- ✅ `TopStatus` displays time and active statuses.
Contracts
- ✅ StatusSystem: signals `status_changed(entity_id)`.
- ✅ GameClock: signal `time_changed(seconds_total)`.
Tests
- ✅ Moving one step -> time +1s; adding/removing statuses updates UI; accuracy mod reflected.
DoD
- ✅ No new warnings; tests pass; time visibly updates in UI during movement.

### Hop 3: Entities (Resource-driven) ✅ COMPLETED
Requirements
- ✅ Define `EntityResource`, `StatBlockResource`, `AbilityResource`, `StatusResource` classes.
- ✅ Create `E-001` Detective resource with base stats and links to abilities/statuses.
- ✅ Loader resolves Entity by ID via Resource DB.
Contracts
- ✅ EntityLoader: `get_entity("E-001") -> EntityResource` with resolved `stat_block` and helper accessors for abilities/statuses.
Tests
- ✅ Detective loads; `char` is '@'; stats present; no affixes.
- ✅ Abilities and statuses resolve via IDs (`A-001` Cleanse, `S-001` Hungover).
DoD
- ✅ Entity resources discoverable via index; inspector loads `.tres` without errors.

### Hop 4: Inventory System + Panels
Requirements
- `Inventory` (autoload): slots: weapon, armor; bag list; add/use/equip; emit `inventory_changed`.
- ActionPanel: add "Inventory" action; OutputPanel renders inventory list.
- Wire I-001/I-002/I-003 behaviors.
Contracts
- Inventory: `add_item(id)`, `equip(slot,id)`, `use(id)`; signals `inventory_changed`.
Tests
- Taking drawer items updates inventory; whiskey toggles statuses and decrements uses; equip pistol/jacket shows feedback text.
DoD
- Inventory visible via panel; actions functional without errors.

### Hop 5: POIs for Apartment
Requirements
- Place POIs per spec: Desk, Drawer, Fridge, Closet, Bed, Bedside, Chair, Door with grid positions.
- Each POI provides actions; some grant items (IDs) or trigger abilities.
- Gating: e.g., Cleanse only if status present.
Contracts
- POI: `get_actions() -> Array[Action]`, `perform(action_id)` emits result text and side effects.
Tests
- Each POI action sequence produces expected outcomes and logs.
DoD
- Apartment scene interactive with all listed POIs; regression tests pass.

### Hop 6: Tile DB (start index + code)
Requirements
- Create `TileResource` with tags and optional spawn_rules; seed T-001 Wood Floor.
- Add `tiles` collection to index; loader consults Tile DB for passability/lootability.
Contracts
- TileDB: `get_tile(id)`, `has_tag(id, tag)`.
Tests
- Wood Floor is walkable; example non-walkable tile blocks movement.
DoD
- Map rendering consults Tile DB tags for passability; basic tile lookups work.

### Hop 7: Animation Cleanup
Requirements
- Remove or fix invalid animation tracks in legacy menu scene.
Tests
- No "index out of bounds" animation errors in boot flow tests.
DoD
- Integration tests are clean of animation index errors.

---

## Minimal contracts
- StatusSystem: `add_status(entity_id, S-id)`, `remove_status(entity_id, S-id)`, `has_status(entity_id, S-id)`, `get_mods(entity_id)`.
- GameClock: `advance(seconds)`, `current_time()`, signal `time_changed`.
- Inventory: `add_item(I-id)`, `use(I-id)`, `equip(slot, I-id)`, `list_items()`, signal `inventory_changed`.
- EntityLoader: `get_entity(E-id)` returns EntityResource with computed effective stats.
- POI: `get_actions()`, `perform(action_id)`.
- TileDB: `get_tile(T-id)`, `has_tag(T-id, tag)`.

## Edge cases
- Using cleanse with no matching status -> no-op with feedback.
- Using whiskey with 0 uses -> no-op + feedback.
- Equipping weapon when one equipped -> swap or block; start with swap=false.

## Notes
- All canonical data in Resource Databases (`.tres/.res`), not JSON; indices expose collections and IDs.
- IDs must be unique; validations enforce this across collections.
- Start with Clock + Status (Hop 2), per priority.
