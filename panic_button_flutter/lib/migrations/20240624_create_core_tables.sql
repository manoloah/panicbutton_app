create extension if not exists "pgcrypto";

-- 1. Breathwork goals
CREATE TABLE goals (
  id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  slug          text UNIQUE NOT NULL,
  display_name  text NOT NULL,
  description   text
);

-- 2. Atomic step
CREATE TABLE steps (
  id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  inhale_secs   int  NOT NULL,
  inhale_method text NOT NULL,           -- 'nose' | 'mouth' | 'nose+mouth'
  hold_in_secs  int  NOT NULL,
  exhale_secs   int  NOT NULL,
  exhale_method text NOT NULL,
  hold_out_secs int  NOT NULL,
  cue_text      text,
  created_at    timestamptz DEFAULT now()
);

-- 3. Pattern
CREATE TABLE patterns (
  id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name          text NOT NULL,
  description   text,
  goal_id       uuid REFERENCES goals(id),
  created_by    uuid,
  created_at    timestamptz DEFAULT now()
);

CREATE TABLE pattern_steps (
  pattern_id    uuid REFERENCES patterns(id) ON DELETE CASCADE,
  step_id       uuid REFERENCES steps(id),
  position      int  NOT NULL,
  repetitions   int  DEFAULT 1,
  PRIMARY KEY (pattern_id, position)
);

-- 4. Routine
CREATE TABLE routines (
  id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name          text,
  goal_id       uuid REFERENCES goals(id),
  total_minutes int,
  created_by    uuid,
  is_public     boolean DEFAULT true,
  created_at    timestamptz DEFAULT now()
);

CREATE TABLE routine_items (
  routine_id    uuid REFERENCES routines(id) ON DELETE CASCADE,
  position      int NOT NULL,
  pattern_id    uuid REFERENCES patterns(id),
  step_id       uuid REFERENCES steps(id),
  repetitions   int DEFAULT 1,
  PRIMARY KEY (routine_id, position),
  CHECK (
    (pattern_id IS NOT NULL AND step_id IS NULL) OR
    (pattern_id IS NULL AND step_id IS NOT NULL)
  )
);

-- 5. User progress
CREATE TABLE user_routine_status (
  user_id       uuid REFERENCES auth.users(id),
  routine_id    uuid REFERENCES routines(id),
  last_run      timestamptz,
  total_runs    int DEFAULT 0,
  PRIMARY KEY (user_id, routine_id)
);

-- Helper function for incrementing total_runs
CREATE OR REPLACE FUNCTION increment_total_runs(p_user_id uuid, p_routine_id uuid)
RETURNS int
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  current_total int;
BEGIN
  SELECT total_runs INTO current_total
  FROM user_routine_status
  WHERE user_id = p_user_id AND routine_id = p_routine_id;
  
  RETURN COALESCE(current_total, 0) + 1;
END;
$$; 