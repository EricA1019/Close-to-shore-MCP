# Interactive Apartment: DB-backed Layout

The main UI now attempts to load the apartment layout from the Resource DB before falling back to the built-in layout.

## How it works

- On startup, `InteractiveApartment._generate_apartment_layout()` calls `_try_load_layout_from_db()`.
- `_try_load_layout_from_db()` builds the DB index for roots `[res://data]` (and includes `res://tests/fixtures/resource_db` in dev if present).
- It looks up the entry `layouts.apartment` and reads its JSON at `entry.path`.
- When JSON is valid, it populates the grid and logs: `Loaded apartment layout from DB: <path>`.
- If the entry is missing or invalid, it logs a warning and uses the built-in layout to keep the game stable.

## JSON schema

- width: number (expected 28)
- height: number (expected 16)
- rows: string array of exactly `height` entries, each string length `width`.

Example file at `res://data/layouts/apartment.json`:

```
{
  "width": 28,
  "height": 16,
  "rows": [
    "████████████████████████████",
    "█.....π.......+..........+.█",
    "█.......................+..█",
    "█..........................█",
    "█..........................█",
    "█+...........+.......β.....█",
    "█............+.............█",
    "█..........................█",
    "█..π......+...╤.............█",
    "█.............Æ.......α....█",
    "█..........................█",
    "█..........................█",
    "█+............+......ε.....█",
    "█.............+.......δ....█",
    "█..........................█",
    "████████████████████████████"
  ]
}
```

## Notes

- The Resource DB runner and bridge include cache and timing metrics. See `docs/RESOURCE_DB.md`.
- You can override roots via the headless runner for testing, but the in-game loader defaults to `res://data`.
