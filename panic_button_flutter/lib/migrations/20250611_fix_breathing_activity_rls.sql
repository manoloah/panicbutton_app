-- Fix RLS policy for breathing_activity table to allow initial creation with 0 duration
BEGIN;

-- Drop and recreate the INSERT policy to allow 0 duration for initial creation
DROP POLICY IF EXISTS "Users can insert their own breathing activity" ON breathing_activity;

CREATE POLICY "Users can insert their own breathing activity" 
ON breathing_activity 
FOR INSERT 
WITH CHECK (auth.uid() = user_id AND duration_seconds >= 0);

-- Also ensure the trigger only processes completed activities with at least 10 seconds
-- This prevents status updates for incomplete or very short activities
CREATE OR REPLACE FUNCTION update_breathing_pattern_status()
RETURNS TRIGGER AS $$
BEGIN
  -- Only process activities that lasted at least 10 seconds and are completed or being updated
  IF NEW.duration_seconds >= 10 AND (TG_OP = 'UPDATE' OR NEW.completed = true) THEN
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