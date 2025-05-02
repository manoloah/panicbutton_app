BEGIN;

-- 1) Rename your core tables
ALTER TABLE goals         RENAME TO breathing_goals;
ALTER TABLE steps         RENAME TO breathing_steps;
ALTER TABLE patterns      RENAME TO breathing_patterns;
ALTER TABLE pattern_steps RENAME TO breathing_pattern_steps;

-- 2) Rename each primary‐key constraint explicitly
ALTER TABLE breathing_goals         RENAME CONSTRAINT goals_pkey          TO breathing_goals_pkey;
ALTER TABLE breathing_steps         RENAME CONSTRAINT steps_pkey          TO breathing_steps_pkey;
ALTER TABLE breathing_patterns      RENAME CONSTRAINT patterns_pkey       TO breathing_patterns_pkey;
ALTER TABLE breathing_pattern_steps RENAME CONSTRAINT pattern_steps_pkey  TO breathing_pattern_steps_pkey;

-- 3) Add the helper columns
ALTER TABLE breathing_patterns
  ADD COLUMN IF NOT EXISTS recommended_minutes INT,
  ADD COLUMN IF NOT EXISTS cycle_secs           INT;

-- 3a) Back‑fill cycle_secs for existing patterns
UPDATE breathing_patterns bp
SET cycle_secs = sub.total
FROM (
  SELECT
    ps.pattern_id,
    SUM(
      (s.inhale_secs + s.hold_in_secs +
       s.exhale_secs + s.hold_out_secs) * ps.repetitions
    ) AS total
  FROM breathing_pattern_steps ps
  JOIN breathing_steps s ON s.id = ps.step_id
  GROUP BY ps.pattern_id
) AS sub
WHERE bp.id = sub.pattern_id
  AND bp.cycle_secs IS NULL;

-- 4) Drop the old routines/playlist tables
DROP TABLE IF EXISTS routines      CASCADE;
DROP TABLE IF EXISTS routine_items CASCADE;

COMMIT;
