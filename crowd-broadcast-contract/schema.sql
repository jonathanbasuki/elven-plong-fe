-- Crowd broadcast POC schema. Postgres 13+ (uses built-in gen_random_uuid(), no
-- extension needed). See erd.md for the diagram and field-by-field notes, and
-- README.md for why there's no current_count/status column on zones.

CREATE TABLE zones (
    zone_id            TEXT PRIMARY KEY,  -- same id as the camera_id in elven-plong-be's zones.json
    name               TEXT NOT NULL,
    map_image_url      TEXT NOT NULL,
    polygon            JSONB NOT NULL,     -- [[x,y], ...] normalized 0..1, same shape as zones.json
    warning_threshold  INT NOT NULL CHECK (warning_threshold > 0),
    crowded_threshold  INT NOT NULL CHECK (crowded_threshold > warning_threshold),
    created_at         TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE staff (
    staff_id    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name        TEXT NOT NULL,
    status      TEXT NOT NULL DEFAULT 'idle' CHECK (status IN ('idle', 'delegating')),
    push_token  TEXT,  -- APNs device token; NULL until the device registers (out of scope here)
    created_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE broadcasts (
    broadcast_id  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    zone_id       TEXT NOT NULL REFERENCES zones(zone_id),
    staff_needed  INT NOT NULL CHECK (staff_needed > 0),
    status        TEXT NOT NULL DEFAULT 'open' CHECK (status IN ('open', 'closed', 'finished')),
    created_at    TIMESTAMPTZ NOT NULL DEFAULT now(),
    expires_at    TIMESTAMPTZ NOT NULL,  -- app sets this to created_at + 20s
    finished_at   TIMESTAMPTZ
);

-- Only one open broadcast per zone at a time. This is what POST /broadcasts'
-- 409 broadcast_open maps to — enforced here, not just in application code.
CREATE UNIQUE INDEX one_open_broadcast_per_zone
    ON broadcasts (zone_id)
    WHERE status = 'open';

CREATE TABLE broadcast_responses (
    broadcast_id   UUID NOT NULL REFERENCES broadcasts(broadcast_id),
    staff_id       UUID NOT NULL REFERENCES staff(staff_id),
    responded_at   TIMESTAMPTZ NOT NULL DEFAULT now(),
    completed_at   TIMESTAMPTZ,
    PRIMARY KEY (broadcast_id, staff_id),
    CHECK (completed_at IS NULL OR completed_at >= responded_at)
);

-- NOTE on the hard cap (staff_needed): intentionally NOT enforced with a trigger
-- here. The app must check COUNT(*) FROM broadcast_responses WHERE broadcast_id = ?
-- against broadcasts.staff_needed before inserting a response row, and return
-- 409 slots_full if it's already full. A DB-level trigger would close the race
-- condition more tightly, but isn't needed for this POC's traffic — add one if
-- this ever needs to be airtight under real concurrency.

CREATE INDEX idx_broadcast_responses_broadcast ON broadcast_responses (broadcast_id);
