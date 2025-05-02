-- Fix for the breathing pattern status table by adding proper RLS policies
-- This ensures users can only see and modify their own records

-- First, enable RLS on the table if not already enabled
ALTER TABLE breathing_pattern_status ENABLE ROW LEVEL SECURITY;

-- Create policy for users to insert their own records
DROP POLICY IF EXISTS "Users can insert their own pattern status" ON breathing_pattern_status;
CREATE POLICY "Users can insert their own pattern status" 
  ON breathing_pattern_status 
  FOR INSERT 
  TO authenticated 
  WITH CHECK (auth.uid() = user_id);

-- Create policy for users to update only their own records
DROP POLICY IF EXISTS "Users can update their own pattern status" ON breathing_pattern_status;
CREATE POLICY "Users can update their own pattern status" 
  ON breathing_pattern_status 
  FOR UPDATE 
  TO authenticated 
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- Create policy for users to select only their own records
DROP POLICY IF EXISTS "Users can view their own pattern status" ON breathing_pattern_status;
CREATE POLICY "Users can view their own pattern status" 
  ON breathing_pattern_status 
  FOR SELECT 
  TO authenticated 
  USING (auth.uid() = user_id);

-- No deletion policy is provided (records are only updated, not deleted)

-- Ensure the breathing_pattern_status table has the correct composite primary key
DO $$ 
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint 
    WHERE conname = 'breathing_pattern_status_pkey' 
  ) THEN
    ALTER TABLE breathing_pattern_status 
    ADD PRIMARY KEY (user_id, pattern_id);
  END IF;
EXCEPTION
  WHEN others THEN
    -- Do nothing if this fails, likely means primary key already exists
END;
$$; 