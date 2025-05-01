-- Insert initial goals
INSERT INTO goals (id, slug, display_name, description)
VALUES 
  ('9b3fbdb6-fae9-4db6-94d4-d8f29ab68ca4', 'calming', 'Calma', 'Respira para reducir la ansiedad y encontrar la calma'),
  ('4e6f2b0a-3d8e-456a-9e21-7d83bf337a23', 'focusing', 'Enfoque', 'Respira para mejorar la concentración y claridad mental'),
  ('d72c32e5-42b7-47d1-9f73-e8f1b458d4c6', 'energizing', 'Energía', 'Respira para despertar el cuerpo y recargar energía'),
  ('1a5b3c7d-63e4-482f-b12d-fc8e94a6b702', 'grounding', 'Equilibrio', 'Respira para centrarte y reconectar con el presente');

-- Insert sample breathwork step (4-6 Resonance)
INSERT INTO steps (id, inhale_secs, inhale_method, hold_in_secs, exhale_secs, exhale_method, hold_out_secs, cue_text)
VALUES 
  ('a1b2c3d4-e5f6-4a5b-9c8d-1e2f3a4b5c6d', 4, 'nose', 0, 6, 'nose', 0, 'Respira con calma y equilibrio');

-- Create pattern linking step to calming goal
INSERT INTO patterns (id, name, description, goal_id)
VALUES 
  ('f7e6d5c4-b3a2-4d5e-8f9a-1b2c3d4e5f6a', '4-6 Resonance', 'Patrón de resonancia cardíaca para calmar el sistema nervioso', '9b3fbdb6-fae9-4db6-94d4-d8f29ab68ca4');

-- Link step to pattern
INSERT INTO pattern_steps (pattern_id, step_id, position, repetitions)
VALUES 
  ('f7e6d5c4-b3a2-4d5e-8f9a-1b2c3d4e5f6a', 'a1b2c3d4-e5f6-4a5b-9c8d-1e2f3a4b5c6d', 1, 1);

-- Create routine using pattern
INSERT INTO routines (id, name, goal_id, total_minutes, is_public)
VALUES 
  ('e1d2c3b4-a5f6-7e8d-9c0b-1a2b3c4d5e6f', 'Calma Rápida 4 min', '9b3fbdb6-fae9-4db6-94d4-d8f29ab68ca4', 4, true);

-- Link pattern to routine with repetitions
INSERT INTO routine_items (routine_id, position, pattern_id, repetitions)
VALUES 
  ('e1d2c3b4-a5f6-7e8d-9c0b-1a2b3c4d5e6f', 1, 'f7e6d5c4-b3a2-4d5e-8f9a-1b2c3d4e5f6a', 24); 