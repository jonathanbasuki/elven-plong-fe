-- Sample data for local development. Run after schema.sql.
-- Staff UUIDs are hardcoded (not gen_random_uuid()) so they're stable and easy to
-- reference by hand while testing against this seed.

INSERT INTO zones (zone_id, name, map_image_url, polygon, warning_threshold, crowded_threshold)
VALUES (
    'z1',
    'Main Lobby',
    'https://example.com/media/maps/main-lobby.png',
    '[[0.1677, 0.5065], [0.4682, 0.437], [0.9917, 0.6481], [0.9958, 0.9435], [0.1682, 0.512]]',
    5,
    10
);
-- Placeholder thresholds (5 / 10) — tune against real detection counts once the
-- cctv worker is pointed at this zone.

INSERT INTO staff (staff_id, name, status) VALUES
    ('a1111111-0000-0000-0000-000000000001', 'Aldi',  'idle'),
    ('a1111111-0000-0000-0000-000000000002', 'Bunga', 'idle'),
    ('a1111111-0000-0000-0000-000000000003', 'Citra', 'idle'),
    ('a1111111-0000-0000-0000-000000000004', 'Dedi',  'idle'),
    ('a1111111-0000-0000-0000-000000000005', 'Eka',   'idle');
