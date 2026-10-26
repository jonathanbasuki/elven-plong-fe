# Crowd broadcast — delegation POC

Handoff package for the manager/staff broadcast-delegation flow worked out in chat.
Scope: **single zone, one active broadcast at a time, broadcast to every staff member
(no selection), hard cap at `staff_needed`, one shared 20-second deadline, manual
manager progression through every step.** This is a deliberately small POC, not the
full "Crowd Dispatch" system described in `crowd-dispatch-api.md` — that one has
multi-round dispatch, Apple Watch GPS, auth, and three client apps. This doesn't.

## What's in here

- [`erd.md`](erd.md) — entities, relationships, and the broadcast lifecycle, as diagrams
- [`schema.sql`](schema.sql) — Postgres schema matching the ERD, ready to run
- [`seed.sql`](seed.sql) — one zone + five staff rows to develop against
- [`api-contract.md`](api-contract.md) — the full REST contract: every endpoint,
  request/response shapes, validation rules, error codes, and which iOS screen calls what

## Explicitly out of scope (don't build these as part of this POC)

- **Auth** — every request trusts `staffId`/role as given in the body; no login, no
  token. Fine for a POC on a private network, not fine to ship.
- **Push device registration** — delivering the broadcast to staff phones needs APNs
  device-token registration (see `crowd-dispatch-api.md`'s `PUT /devices` for the
  shape). That's a hard prerequisite for the "staff gets notified" step but isn't
  specified in this package — assumed to exist, or build it alongside this.
- **Multi-zone** — the `zones` table supports more than one row, but the flow/UI this
  was designed against is explicitly one zone.
- **Detection history / persistence of counts** — `current_count` and `status` are
  **not stored** in this schema at all (see next section).

## Where the live people-count comes from

`zones.current_count` and `zones.status` (safe/warning/crowded) are computed **live**,
at request time, from the existing `elven-plong-be` CCTV detection pipeline
(`POST /detections`) — not persisted in this schema. The convention is: this
system's `zone_id` is the **same string** as the `camera_id`/zone id already used in
`elven-plong-be`'s `zones.json`, so the two systems line up without a separate
mapping table. This schema only owns the delegation workflow (broadcasts and
responses), not the counting pipeline.

## Transport decisions (already settled, see api-contract.md for detail)

| Need | Transport | Why |
|---|---|---|
| Manager's live zone count (page 1) | Polling, `GET /zones/{zoneId}` every ~2-3s | Matches the rest of this contract; a few seconds of staleness on a headcount is invisible |
| Manager's live accepted/completed count (pages 3-4) | Polling, `GET /broadcasts/current` | Same reasoning, same endpoint style |
| Staff being told "you've been broadcast to" | Push notification (APNs) | The one case that needs instant delivery to a backgrounded phone — not polling |
| Live CCTV feed | Not part of this package | Already built in `elven-plong-be` (`GET /stream/{cameraId}`) |

## How to use this package

1. Run `schema.sql` against a fresh Postgres database.
2. Run `seed.sql` to get one working zone and some staff to test against.
3. Build the five endpoints in `api-contract.md` against that schema.
4. Wire up push notifications separately (see "out of scope" above) — without it,
   staff will never learn a broadcast happened.
