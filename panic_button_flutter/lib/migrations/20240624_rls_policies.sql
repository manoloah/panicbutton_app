-- Enable Row Level Security on all tables
ALTER TABLE goals ENABLE ROW LEVEL SECURITY;
ALTER TABLE steps ENABLE ROW LEVEL SECURITY;
ALTER TABLE patterns ENABLE ROW LEVEL SECURITY;
ALTER TABLE pattern_steps ENABLE ROW LEVEL SECURITY;
ALTER TABLE routines ENABLE ROW LEVEL SECURITY;
ALTER TABLE routine_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_routine_status ENABLE ROW LEVEL SECURITY;

-- Any authenticated user can SELECT from all tables
CREATE POLICY goals_select_policy ON goals
  FOR SELECT USING (auth.role() <> 'anon');

CREATE POLICY steps_select_policy ON steps
  FOR SELECT USING (auth.role() <> 'anon');

CREATE POLICY patterns_select_policy ON patterns
  FOR SELECT USING (auth.role() <> 'anon');

CREATE POLICY pattern_steps_select_policy ON pattern_steps
  FOR SELECT USING (auth.role() <> 'anon');

CREATE POLICY routines_select_policy ON routines
  FOR SELECT USING (auth.role() <> 'anon');

CREATE POLICY routine_items_select_policy ON routine_items
  FOR SELECT USING (auth.role() <> 'anon');

CREATE POLICY user_routine_status_select_policy ON user_routine_status
  FOR SELECT USING (auth.role() <> 'anon');

-- coach or service_role can fully manage core tables
CREATE POLICY goals_insert_policy ON goals
  FOR INSERT WITH CHECK (auth.role() IN ('coach', 'service_role'));

CREATE POLICY goals_update_policy ON goals
  FOR UPDATE USING (auth.role() IN ('coach', 'service_role'));

CREATE POLICY goals_delete_policy ON goals
  FOR DELETE USING (auth.role() IN ('coach', 'service_role'));

CREATE POLICY steps_insert_policy ON steps
  FOR INSERT WITH CHECK (auth.role() IN ('coach', 'service_role'));

CREATE POLICY steps_update_policy ON steps
  FOR UPDATE USING (auth.role() IN ('coach', 'service_role'));

CREATE POLICY steps_delete_policy ON steps
  FOR DELETE USING (auth.role() IN ('coach', 'service_role'));

CREATE POLICY patterns_insert_policy ON patterns
  FOR INSERT WITH CHECK (auth.role() IN ('coach', 'service_role'));

CREATE POLICY patterns_update_policy ON patterns
  FOR UPDATE USING (auth.role() IN ('coach', 'service_role'));

CREATE POLICY patterns_delete_policy ON patterns
  FOR DELETE USING (auth.role() IN ('coach', 'service_role'));

CREATE POLICY pattern_steps_insert_policy ON pattern_steps
  FOR INSERT WITH CHECK (auth.role() IN ('coach', 'service_role'));

CREATE POLICY pattern_steps_update_policy ON pattern_steps
  FOR UPDATE USING (auth.role() IN ('coach', 'service_role'));

CREATE POLICY pattern_steps_delete_policy ON pattern_steps
  FOR DELETE USING (auth.role() IN ('coach', 'service_role'));

CREATE POLICY routines_insert_policy ON routines
  FOR INSERT WITH CHECK (auth.role() IN ('coach', 'service_role'));

CREATE POLICY routines_update_policy ON routines
  FOR UPDATE USING (auth.role() IN ('coach', 'service_role'));

CREATE POLICY routines_delete_policy ON routines
  FOR DELETE USING (auth.role() IN ('coach', 'service_role'));

CREATE POLICY routine_items_insert_policy ON routine_items
  FOR INSERT WITH CHECK (auth.role() IN ('coach', 'service_role'));

CREATE POLICY routine_items_update_policy ON routine_items
  FOR UPDATE USING (auth.role() IN ('coach', 'service_role'));

CREATE POLICY routine_items_delete_policy ON routine_items
  FOR DELETE USING (auth.role() IN ('coach', 'service_role'));

-- Any authenticated user can manage their own user_routine_status
CREATE POLICY user_routine_status_insert_policy ON user_routine_status
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY user_routine_status_update_policy ON user_routine_status
  FOR UPDATE USING (auth.uid() = user_id); 
