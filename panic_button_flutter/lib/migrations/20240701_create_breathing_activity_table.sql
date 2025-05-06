-- Create a table to track detailed breathing activity
BEGIN;

-- Table for detailed breathing activity tracking
CREATE TABLE IF NOT EXISTS breathing_activity (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id) NOT NULL,
  pattern_id UUID REFERENCES breathing_patterns(id) NOT NULL,
  started_at TIMESTAMPTZ DEFAULT now() NOT NULL,
  duration_seconds INTEGER NOT NULL,
  completed BOOLEAN DEFAULT false,
  expected_duration_seconds INTEGER,
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT now() NOT NULL
);

-- Enable Row Level Security
ALTER TABLE breathing_activity ENABLE ROW LEVEL SECURITY;

-- Create policies for breathing_activity table
-- Allow users to read their own activity
CREATE POLICY "Users can view their own breathing activity" 
ON breathing_activity 
FOR SELECT 
USING (auth.uid() = user_id);

-- Allow users to insert their own activity
CREATE POLICY "Users can insert their own breathing activity" 
ON breathing_activity 
FOR INSERT 
WITH CHECK (auth.uid() = user_id AND duration_seconds >= 10);

-- Allow users to update their own activity
CREATE POLICY "Users can update their own breathing activity" 
ON breathing_activity 
FOR UPDATE 
USING (auth.uid() = user_id);

-- Create an index for faster queries
CREATE INDEX idx_breathing_activity_user_id ON breathing_activity(user_id);
CREATE INDEX idx_breathing_activity_pattern_id ON breathing_activity(pattern_id);
CREATE INDEX idx_breathing_activity_started_at ON breathing_activity(started_at);

-- Create a function to update the breathing_pattern_status table when a new activity is recorded
CREATE OR REPLACE FUNCTION update_breathing_pattern_status()
RETURNS TRIGGER AS $$
BEGIN
  -- Only process completed activities that lasted at least 10 seconds
  IF NEW.duration_seconds >= 10 THEN
    -- Insert or update the pattern status
    INSERT INTO breathing_pattern_status (user_id, pattern_id, last_run, total_runs)
    VALUES (NEW.user_id, NEW.pattern_id, NEW.started_at, 1)
    ON CONFLICT (user_id, pattern_id) DO UPDATE
    SET last_run = NEW.started_at,
        total_runs = breathing_pattern_status.total_runs + 1;
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create a trigger to update the pattern status when a new activity is inserted
CREATE TRIGGER update_breathing_pattern_status_trigger
AFTER INSERT ON breathing_activity
FOR EACH ROW
EXECUTE FUNCTION update_breathing_pattern_status();

COMMIT; 