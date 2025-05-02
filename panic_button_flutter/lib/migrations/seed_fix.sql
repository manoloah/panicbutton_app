-- Clear existing data to avoid conflicts
DELETE FROM breathing_pattern_status;
DELETE FROM breathing_pattern_steps;
DELETE FROM breathing_patterns;
DELETE FROM breathing_steps;
DELETE FROM breathing_goals;

-- Insert goals with correct slugs
INSERT INTO breathing_goals (id, slug, display_name, description)
VALUES 
  ('9b3fbdb6-fae9-4db6-94d4-d8f29ab68ca4', 'calming', 'Cálmate', 'Respira para reducir la ansiedad y encontrar la calma'),
  ('4e6f2b0a-3d8e-456a-9e21-7d83bf337a23', 'focusing', 'Enfoque', 'Respira para mejorar la concentración y claridad mental'),
  ('d72c32e5-42b7-47d1-9f73-e8f1b458d4c6', 'energizing', 'Energízate', 'Respira para despertar el cuerpo y recargar energía'),
  ('1a5b3c7d-63e4-482f-b12d-fc8e94a6b702', 'grounding', 'Equilibrio', 'Respira para centrarte y reconectar con el presente');

-- Insert breathing steps
INSERT INTO breathing_steps (id, inhale_secs, inhale_method, hold_in_secs, exhale_secs, exhale_method, hold_out_secs, cue_text)
VALUES 
  ('a1b2c3d4-e5f6-4a5b-9c8d-1e2f3a4b5c6d', 4, 'nose', 0, 6, 'nose', 0, 'Respira con calma y equilibrio'),
  ('b2c3d4e5-f6a7-5b6c-0d1e-2f3a4b5c6d7e', 4, 'nose', 4, 4, 'nose', 4, 'Box breathing para equilibrio'),
  ('c3d4e5f6-a7b8-6c7d-1e2f-3a4b5c6d7e8f', 6, 'nose', 0, 2, 'mouth', 0, 'Activación rápida'),
  ('d4e5f6a7-b8c9-7d8e-2f3a-4b5c6d7e8f9a', 3, 'nose', 0, 6, 'nose', 0, 'Respiración para calmar'),
  ('e5f6a7b8-c9d0-8e9f-3a4b-5c6d7e8f9a0b', 5, 'nose', 2, 5, 'nose', 0, 'Respiración para enfocar');

-- Create patterns with cycle_secs and recommended_minutes
INSERT INTO breathing_patterns (id, name, goal_id, cycle_secs, recommended_minutes)
VALUES 
  ('f7e6d5c4-b3a2-4d5e-8f9a-1b2c3d4e5f6a', 'Respiración 4-6', '9b3fbdb6-fae9-4db6-94d4-d8f29ab68ca4', 10, 3),
  ('e6d5c4b3-a2f7-4e5d-8f9a-2c3d4e5f6a7b', 'Box Breathing', '1a5b3c7d-63e4-482f-b12d-fc8e94a6b702', 16, 5),
  ('d5c4b3a2-f7e6-5d4c-9a8b-3d4e5f6a7b8c', 'Respiración Energizante', 'd72c32e5-42b7-47d1-9f73-e8f1b458d4c6', 8, 3),
  ('c4b3a2f7-e6d5-4c3b-8a7b-9c8d7e6f5a4b', 'Calmante Profunda', '9b3fbdb6-fae9-4db6-94d4-d8f29ab68ca4', 9, 5),
  ('b3a2f7e6-d5c4-3b2a-7a6b-8c7d6e5f4a3b', 'Enfoque Mental', '4e6f2b0a-3d8e-456a-9e21-7d83bf337a23', 12, 4),
  ('a2f7e6d5-c4b3-2a1f-6a5b-7c6d5e4f3a2b', 'Energía Rápida', 'd72c32e5-42b7-47d1-9f73-e8f1b458d4c6', 8, 2),
  ('9ab8c7d6-e5f4-1a2b-5a4b-3c2d1e0f9a8b', 'Equilibrio Total', '1a5b3c7d-63e4-482f-b12d-fc8e94a6b702', 14, 6);

-- Link steps to patterns
INSERT INTO breathing_pattern_steps (id, pattern_id, step_id, position, repetitions)
VALUES 
  ('f8e7d6c5-b4a3-5e6f-9a8b-7c6d5e4f3a2b', 'f7e6d5c4-b3a2-4d5e-8f9a-1b2c3d4e5f6a', 'a1b2c3d4-e5f6-4a5b-9c8d-1e2f3a4b5c6d', 1, 1),
  ('e7d6c5b4-a3f8-6e7d-8b9a-6c5d4e3f2a1b', 'e6d5c4b3-a2f7-4e5d-8f9a-2c3d4e5f6a7b', 'b2c3d4e5-f6a7-5b6c-0d1e-2f3a4b5c6d7e', 1, 1),
  ('d6c5b4a3-f8e7-7d8e-9a0b-5c4d3e2f1a0b', 'd5c4b3a2-f7e6-5d4c-9a8b-3d4e5f6a7b8c', 'c3d4e5f6-a7b8-6c7d-1e2f-3a4b5c6d7e8f', 1, 1),
  ('c5b4a3f8-e7d6-8e9f-0a1b-4d3c2b1a0f9e', 'c4b3a2f7-e6d5-4c3b-8a7b-9c8d7e6f5a4b', 'd4e5f6a7-b8c9-7d8e-2f3a-4b5c6d7e8f9a', 1, 1),
  ('b4a3f8e7-d6c5-9f0a-1b2c-3d4e5f6a7b8c', 'b3a2f7e6-d5c4-3b2a-7a6b-8c7d6e5f4a3b', 'e5f6a7b8-c9d0-8e9f-3a4b-5c6d7e8f9a0b', 1, 1),
  ('a3f8e7d6-c5b4-0a1b-2c3d-4e5f6a7b8c9d', 'a2f7e6d5-c4b3-2a1f-6a5b-7c6d5e4f3a2b', 'c3d4e5f6-a7b8-6c7d-1e2f-3a4b5c6d7e8f', 1, 1),
  ('9f8e7d6c-5b4a-1b2c-3d4e-5f6a7b8c9d0e', '9ab8c7d6-e5f4-1a2b-5a4b-3c2d1e0f9a8b', 'b2c3d4e5-f6a7-5b6c-0d1e-2f3a4b5c6d7e', 1, 1); 