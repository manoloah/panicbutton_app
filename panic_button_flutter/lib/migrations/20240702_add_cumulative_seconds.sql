-- Add cumulative seconds to breathing_pattern_status table
BEGIN;

-- Add column for tracking total seconds spent on each pattern
ALTER TABLE breathing_pattern_status
ADD COLUMN total_seconds INTEGER DEFAULT 0;

-- Update the trigger function to also accumulate seconds and change minimum time to 10 seconds
CREATE OR REPLACE FUNCTION update_breathing_pattern_status()
RETURNS TRIGGER AS $$
BEGIN
  -- Only process activities that lasted at least 10 seconds (changed from 15)
  IF NEW.duration_seconds >= 10 THEN
    -- Insert or update the pattern status
    INSERT INTO breathing_pattern_status (user_id, pattern_id, last_run, total_runs, total_seconds)
    VALUES (NEW.user_id, NEW.pattern_id, NEW.started_at, 1, NEW.duration_seconds)
    ON CONFLICT (user_id, pattern_id) DO UPDATE
    SET last_run = NEW.started_at,
        total_runs = breathing_pattern_status.total_runs + 1,
        total_seconds = breathing_pattern_status.total_seconds + NEW.duration_seconds;
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

COMMIT; 