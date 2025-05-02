BEGIN;

-- 1️⃣ Rename core tables
ALTER TABLE goals            RENAME TO breathing_goals;
ALTER TABLE steps            RENAME TO breathing_steps;
ALTER TABLE patterns         RENAME TO breathing_patterns;
ALTER TABLE pattern_steps    RENAME TO breathing_pattern_steps;

-- 2️⃣ Prefix FK constraints manually if needed
-- (Supabase auto-renames indexes but NOT fkeys; safest is drop/re-add)
DO $$
DECLARE
  r RECORD;
BEGIN
  FOR r IN
    SELECT conname
    FROM pg_constraint
    WHERE conname LIKE '%patterns%'   -- old name fragment
  LOOP
    EXECUTE format('ALTER TABLE %I RENAME CONSTRAINT %I TO %s',
                   r.conname::regclass,
                   r.conname,
                   replace(r.conname,'patterns','breathing_patterns'));
  END LOOP;
END$$;

-- 3️⃣ Add helper columns to patterns (now songs)
ALTER TABLE breathing_patterns
  ADD COLUMN IF NOT EXISTS recommended_minutes INT,
  ADD COLUMN IF NOT EXISTS cycle_secs INT;

-- 3a.  Back-fill cycle_secs for existing rows
UPDATE breathing_patterns bp
SET cycle_secs = sub.total
FROM (
  SELECT pattern_id,
         SUM((s.inhale_secs + s.hold_in_secs +
              s.exhale_secs + s.hold_out_secs) * ps.repetitions) AS total
  FROM breathing_pattern_steps ps
  JOIN breathing_steps s ON s.id = ps.step_id
  GROUP BY pattern_id
) AS sub
WHERE sub.pattern_id = bp.id
  AND bp.cycle_secs IS NULL;

-- 4️⃣ Drop playlist layer (cascade removes routine_items too)
DROP TABLE IF EXISTS routines      CASCADE;
DROP TABLE IF EXISTS routine_items CASCADE;

COMMIT;