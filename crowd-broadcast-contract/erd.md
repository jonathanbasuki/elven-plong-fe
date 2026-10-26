# Entity relationship diagram

Four tables. `zones` and `staff` are the nouns; `broadcasts` and `broadcast_responses`
are the workflow. See `README.md` for why `current_count`/`status` aren't columns here.

```mermaid
erDiagram
  ZONES ||--o{ BROADCASTS : "has"
  BROADCASTS ||--o{ BROADCAST_RESPONSES : "has"
  STAFF ||--o{ BROADCAST_RESPONSES : "responds via"

  ZONES {
    text zone_id PK
    text name
    text map_image_url
    jsonb polygon
    int warning_threshold
    int crowded_threshold
    timestamptz created_at
  }
  STAFF {
    uuid staff_id PK
    text name
    text status
    text push_token
    timestamptz created_at
  }
  BROADCASTS {
    uuid broadcast_id PK
    text zone_id FK
    int staff_needed
    text status
    timestamptz created_at
    timestamptz expires_at
    timestamptz finished_at
  }
  BROADCAST_RESPONSES {
    uuid broadcast_id PK_FK
    uuid staff_id PK_FK
    timestamptz responded_at
    timestamptz completed_at
  }
```

## Field notes

- `zones.zone_id` is **text**, not a generated UUID — it must match the `camera_id`
  already used in `elven-plong-be`'s `zones.json` (e.g. `"z1"`), so the two systems
  refer to the same zone without a mapping table.
- `zones.warning_threshold` / `crowded_threshold` are the two numbers that turn a raw
  `current_count` into the safe/warning/crowded status shown on manager page 1. Not
  derived from anything else — just configured per zone.
- `staff.status` is `idle | delegating`. It flips to `delegating` the moment a staff
  member accepts a broadcast, and back to `idle` the moment they tap "done
  delegation." It's the single source of truth the staff app's page 1 button
  (enabled/disabled) reads from.
- A row in `broadcast_responses` only exists for staff who **accepted**. A staff
  member who never responded, or whose accept arrived after the cap/deadline, simply
  has no row — there's no `response = 'ignored'` state to track, because this POC's
  flow has no consequence for not responding beyond "you weren't part of it."
- `broadcast_responses.completed_at` is `NULL` while that staff member is still
  actively delegating, and set the moment they tap "done delegation."

## Broadcast lifecycle

```mermaid
stateDiagram-v2
  [*] --> open : manager confirms broadcast\n(POST /broadcasts)
  open --> closed : expires_at reached (20s)
  closed --> finished : manager taps Finish\n(all responses completed, >=1 accepted)
  closed --> [*] : 0 accepted — manager taps "try again"\n(creates a brand-new broadcast row)
  finished --> [*]
```

Two things worth calling out because they're easy to get wrong when implementing:

1. **"Try again" is not a state transition** — it doesn't reopen the same
   `broadcast_id`. It's a fresh `POST /broadcasts` with the same `zone_id` /
   `staff_needed`, producing a brand-new row. The old, zero-accepted broadcast just
   stays `closed` forever as a dead record.
2. **Only one `open` broadcast per `zone_id` at a time** — enforced at the DB level
   with a partial unique index (see `schema.sql`), not just application logic. This
   is what `POST /broadcasts` returning `409 broadcast_open` actually maps to.

## A staff member's response, as derived state

There's no explicit `status` column on `broadcast_responses` — the state is implied
by which timestamps are set. Useful to have written out plainly once:

```mermaid
stateDiagram-v2
  [*] --> no_row : broadcast created, nobody responded yet
  no_row --> no_row : expires_at passes — stays this way forever (no row ever created)
  no_row --> accepted : POST /broadcasts/{id}/respond (before expires_at, before cap)
  accepted --> completed : POST /broadcasts/{id}/complete
```

`no_row` isn't a real database state — it's just "no `broadcast_responses` row for
this `(broadcast_id, staff_id)` pair exists." Shown here because the staff app needs
to represent it as a real UI state (the broadcast screen where nothing has happened
yet) even though the database has nothing to query for it.
