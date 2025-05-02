-- First, enable Row Level Security for the table if not already enabled
ALTER TABLE breathing_pattern_status ENABLE ROW LEVEL SECURITY;

-- Drop any existing policies
DROP POLICY IF EXISTS "Users can view their own pattern status" ON breathing_pattern_status;
DROP POLICY IF EXISTS "Users can insert their own pattern status" ON breathing_pattern_status;
DROP POLICY IF EXISTS "Users can update their own pattern status" ON breathing_pattern_status;

-- Create policies for breathing_pattern_status table
-- Allow users to read their own pattern status
CREATE POLICY "Users can view their own pattern status" 
ON breathing_pattern_status 
FOR SELECT 
USING (auth.uid() = user_id);

-- Allow users to insert their own pattern status
CREATE POLICY "Users can insert their own pattern status" 
ON breathing_pattern_status 
FOR INSERT 
WITH CHECK (auth.uid() = user_id);

-- Allow users to update their own pattern status
CREATE POLICY "Users can update their own pattern status" 
ON breathing_pattern_status 
FOR UPDATE 
USING (auth.uid() = user_id);

-- Update trigger function to properly increment total_runs on conflict
CREATE OR REPLACE FUNCTION increment_total_runs()
RETURNS TRIGGER AS $$
BEGIN
  -- Set the new total_runs value by adding 1 to the old value
  NEW.total_runs = COALESCE(OLD.total_runs, 0) + 1;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Drop the trigger if it exists
DROP TRIGGER IF EXISTS increment_total_runs_trigger ON breathing_pattern_status;

-- Create trigger to increment total_runs on update
CREATE TRIGGER increment_total_runs_trigger
BEFORE UPDATE ON breathing_pattern_status
FOR EACH ROW
WHEN (OLD.user_id = NEW.user_id AND OLD.pattern_id = NEW.pattern_id)
EXECUTE FUNCTION increment_total_runs(); 