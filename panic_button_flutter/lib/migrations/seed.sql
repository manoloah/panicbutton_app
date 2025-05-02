-- Insert initial goals
INSERT INTO breathing_goals (id, slug, display_name, description)
VALUES 
  ('9b3fbdb6-fae9-4db6-94d4-d8f29ab68ca4', 'calming', 'Calma', 'Respira para reducir la ansiedad y encontrar la calma'),
  ('4e6f2b0a-3d8e-456a-9e21-7d83bf337a23', 'focusing', 'Enfoque', 'Respira para mejorar la concentración y claridad mental'),
  ('d72c32e5-42b7-47d1-9f73-e8f1b458d4c6', 'energizing', 'Energía', 'Respira para despertar el cuerpo y recargar energía'),
  ('1a5b3c7d-63e4-482f-b12d-fc8e94a6b702', 'grounding', 'Equilibrio', 'Respira para centrarte y reconectar con el presente');

-- Insert sample breathwork steps
INSERT INTO breathing_steps (id, inhale_secs, inhale_method, hold_in_secs, exhale_secs, exhale_method, hold_out_secs, cue_text)
VALUES 
  ('a1b2c3d4-e5f6-4a5b-9c8d-1e2f3a4b5c6d', 4, 'nose', 0, 6, 'nose', 0, 'Respira con calma y equilibrio'),
  ('b2c3d4e5-f6a7-5b6c-0d1e-2f3a4b5c6d7e', 4, 'nose', 4, 4, 'nose', 4, 'Box breathing para equilibrar'),
  ('c3d4e5f6-a7b8-6c7d-1e2f-3a4b5c6d7e8f', 6, 'nose', 0, 2, 'mouth', 0, 'Activación rápida');

-- Create patterns with cycle_secs and recommended_minutes
INSERT INTO breathing_patterns (id, name, goal_id, cycle_secs, recommended_minutes)
VALUES 
  ('f7e6d5c4-b3a2-4d5e-8f9a-1b2c3d4e5f6a', '4-6 Resonance', '9b3fbdb6-fae9-4db6-94d4-d8f29ab68ca4', 10, 3),
  ('e6d5c4b3-a2f7-4e5d-8f9a-2c3d4e5f6a7b', 'Box Breathing', '1a5b3c7d-63e4-482f-b12d-fc8e94a6b702', 16, 5),
  ('d5c4b3a2-f7e6-5d4c-9a8b-3d4e5f6a7b8c', 'Energizing Breath', 'd72c32e5-42b7-47d1-9f73-e8f1b458d4c6', 8, 3);

-- Link steps to patterns
INSERT INTO breathing_pattern_steps (id, pattern_id, step_id, position, repetitions)
VALUES 
  (gen_random_uuid(), 'f7e6d5c4-b3a2-4d5e-8f9a-1b2c3d4e5f6a', 'a1b2c3d4-e5f6-4a5b-9c8d-1e2f3a4b5c6d', 1, 1),
  (gen_random_uuid(), 'e6d5c4b3-a2f7-4e5d-8f9a-2c3d4e5f6a7b', 'b2c3d4e5-f6a7-5b6c-0d1e-2f3a4b5c6d7e', 1, 1),
  (gen_random_uuid(), 'd5c4b3a2-f7e6-5d4c-9a8b-3d4e5f6a7b8c', 'c3d4e5f6-a7b8-6c7d-1e2f-3a4b5c6d7e8f', 1, 1); 
