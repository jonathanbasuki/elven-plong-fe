# API contract — crowd broadcast POC

See `erd.md` for entities/diagrams and `schema.sql` for the tables these endpoints
read and write. Conventions below are deliberately minimal (see README.md for what's
explicitly out of scope — there's no auth here).

## Conventions

| Item | Rule |
|---|---|
| Base path | Not specified — pick whatever this gets mounted under in the real service |
| Format | JSON |
| IDs | `zone_id` is a plain string (matches the CCTV zone id); `staff_id` / `broadcast_id` are UUID strings |
| Time | ISO 8601 UTC |
| Auth | **None.** Every request trusts `staffId`/role as given in the body. Not safe to ship as-is. |

### Error shape

```json
{ "error": { "code": "slots_full", "message": "This broadcast already has enough staff." } }
```

| HTTP | `code` | When |
|---|---|---|
| 404 | `not_found` | Zone, broadcast, or staff id doesn't exist |
| 409 | `broadcast_open` | `POST /broadcasts` while one is already `open` for that zone |
| 409 | `expired` | `POST /broadcasts/{id}/respond` after `expires_at` has passed |
| 409 | `slots_full` | `POST /broadcasts/{id}/respond` once `staff_needed` has already been reached |
| 403 | `not_your_response` | `POST /broadcasts/{id}/complete` by a staff member who never accepted this broadcast |
| 409 | `not_all_done` | `POST /broadcasts/{id}/finish` while any accepted staff member hasn't completed yet, or nobody accepted at all |

---

## GET

### `GET /zones/{zoneId}`

Manager page 1 — zone stat + status.

```json
// 200
{
  "zoneId": "z1",
  "name": "Main Lobby",
  "currentCount": 7,
  "status": "warning",
  "mapImageUrl": "https://.../main-lobby.png",
  "polygon": [[0.1677, 0.5065], [0.4682, 0.437], "..."]
}
```

`currentCount` and `status` are **not read from this schema** — fetch the live count
from the existing `elven-plong-be` detection pipeline for the matching `camera_id`
(same string as `zoneId`), then compute `status` as:
- `currentCount < warning_threshold` → `"safe"`
- `warning_threshold <= currentCount < crowded_threshold` → `"warning"`
- `currentCount >= crowded_threshold` → `"crowded"`

### `GET /broadcasts/current?zoneId=`

Manager pages 3 & 4 — poll this. Same response shape serves both screens; the
client just reads different fields depending on where it is.

```json
// 200 — while open
{
  "broadcastId": "b1...",
  "zoneId": "z1",
  "status": "open",
  "staffNeeded": 3,
  "expiresAt": "2026-10-23T18:00:20Z",
  "acceptedCount": 1,
  "completedCount": 0,
  "acceptedStaff": [
    { "staffId": "a1...", "name": "Aldi", "completedAt": null }
  ]
}
```

```json
// 200 — closed, nobody accepted (page 3 shows "try again")
{ "broadcastId": "b1...", "zoneId": "z1", "status": "closed", "staffNeeded": 3,
  "expiresAt": "2026-10-23T18:00:20Z", "acceptedCount": 0, "completedCount": 0,
  "acceptedStaff": [] }
```

```json
// 404 — no broadcast has ever been created for this zone yet
{ "error": { "code": "not_found", "message": "no broadcast for zone z1" } }
```

### `GET /staff/{staffId}`

Staff page 1 — whether "Done delegation" should be enabled, including after an app
relaunch.

```json
// 200
{ "staffId": "a1...", "name": "Aldi", "status": "delegating" }
```

---

## POST

### `POST /broadcasts`

Manager page 2 "confirm broadcast" **and** page 3 "try again" — same call, same
body, both just create a new broadcast row.

```json
// request
{ "zoneId": "z1", "staffNeeded": 3 }
```
```json
// 201
{ "broadcastId": "b1...", "zoneId": "z1", "status": "open", "staffNeeded": 3,
  "expiresAt": "2026-10-23T18:00:20Z", "acceptedCount": 0, "completedCount": 0,
  "acceptedStaff": [] }
```

Server, in order:
1. `409 broadcast_open` if a broadcast with `status = 'open'` already exists for this
   `zoneId` (the partial unique index in `schema.sql` is the actual backstop here).
2. Insert the row, `expiresAt = now() + 20s`.
3. Push a notification to **every** staff member's registered device (not specified
   in this package — see README.md).

### `POST /broadcasts/{broadcastId}/respond`

Staff's accept tap.

```json
// request
{ "staffId": "a1..." }
```
```json
// 200
{ "status": "ok" }
```

Server, in order:
1. `404 not_found` if the broadcast doesn't exist.
2. `409 expired` if `now() > expires_at`.
3. `409 slots_full` if `COUNT(broadcast_responses WHERE broadcast_id = ?) >= staff_needed`.
4. Insert the `broadcast_responses` row (`responded_at = now()`), set
   `staff.status = 'delegating'`.

### `POST /broadcasts/{broadcastId}/complete`

Staff's "Done delegation" tap (their page 1's only button).

```json
// request
{ "staffId": "a1..." }
```
```json
// 200
{ "status": "ok" }
```

Server: `403 not_your_response` if no `broadcast_responses` row exists for this
`(broadcastId, staffId)`. Otherwise set `completed_at = now()`, set
`staff.status = 'idle'`.

### `POST /broadcasts/{broadcastId}/finish`

Manager page 4 "Finish" tap — ends the broadcast and sends the manager back to
page 1.

```json
// 200
{ "broadcastId": "b1...", "status": "finished", "finishedAt": "2026-10-23T18:05:00Z" }
```

Server: `409 not_all_done` unless `acceptedCount >= 1` **and**
`completedCount == acceptedCount`. Otherwise set `status = 'finished'`,
`finished_at = now()`.

---

## iOS screen → request map

| App | Screen | Request | When |
|---|---|---|---|
| Manager | Page 1 (zone stat + map) | `GET /zones/{zoneId}` | Poll every ~2-3s while visible |
| Manager | Page 2 (staff count + confirm) | `POST /broadcasts` | Tap **Confirm broadcast** |
| Manager | Page 3 (looking for staff) | `GET /broadcasts/current` | Poll every ~1-2s while visible |
| Manager | Page 3 | `POST /broadcasts` | Tap **Try again** (only shown once `status = closed` and `acceptedCount == 0`) |
| Manager | Page 4 (accepted staff list) | `GET /broadcasts/current` | Poll every ~1-2s while visible |
| Manager | Page 4 | `POST /broadcasts/{id}/finish` | Tap **Finish** (enabled once `completedCount == acceptedCount >= 1`) |
| Staff | Broadcast received screen | `POST /broadcasts/{id}/respond` | Tap **Accept** before the local countdown (from the push payload's `expiresAt`) reaches zero |
| Staff | Page 1 (done delegation button) | `GET /staff/{staffId}` | On open / app relaunch, to set button enabled state |
| Staff | Page 1 | `POST /broadcasts/{id}/complete` | Tap **Done delegation** |
