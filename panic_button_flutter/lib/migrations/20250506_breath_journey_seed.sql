BEGIN;

-- Ensure breathing goals exist
INSERT INTO breathing_goals (id, slug, display_name)
SELECT gen_random_uuid(), 'calming', 'Calma'
WHERE NOT EXISTS (SELECT 1 FROM breathing_goals WHERE slug = 'calming');

INSERT INTO breathing_goals (id, slug, display_name)
SELECT gen_random_uuid(), 'grounding', 'Equilibrio'
WHERE NOT EXISTS (SELECT 1 FROM breathing_goals WHERE slug = 'grounding');

INSERT INTO breathing_goals (id, slug, display_name)
SELECT gen_random_uuid(), 'energizing', 'Energía'
WHERE NOT EXISTS (SELECT 1 FROM breathing_goals WHERE slug = 'energizing');

-- Helper function to get or create a breathing step
CREATE OR REPLACE FUNCTION get_or_create_step(
  p_inhale_secs INT,
  p_inhale_method TEXT,
  p_hold_in_secs INT,
  p_exhale_secs INT,
  p_exhale_method TEXT,
  p_hold_out_secs INT,
  p_cue_text TEXT
)
RETURNS UUID AS $$
DECLARE
  v_step_id UUID;
BEGIN
  -- Try to find an existing step with these parameters
  SELECT id INTO v_step_id
  FROM breathing_steps
  WHERE inhale_secs = p_inhale_secs
    AND inhale_method = p_inhale_method
    AND hold_in_secs = p_hold_in_secs
    AND exhale_secs = p_exhale_secs
    AND exhale_method = p_exhale_method
    AND hold_out_secs = p_hold_out_secs
  LIMIT 1;
  
  -- If not found, create a new one
  IF v_step_id IS NULL THEN
    INSERT INTO breathing_steps (
      id, inhale_secs, inhale_method, hold_in_secs, 
      exhale_secs, exhale_method, hold_out_secs, cue_text
    ) 
    VALUES (
      gen_random_uuid(), p_inhale_secs, p_inhale_method, p_hold_in_secs,
      p_exhale_secs, p_exhale_method, p_hold_out_secs, p_cue_text
    )
    RETURNING id INTO v_step_id;
  END IF;
  
  RETURN v_step_id;
END;
$$ LANGUAGE plpgsql;

-- Helper function to get or create a breathing pattern
CREATE OR REPLACE FUNCTION get_or_create_pattern(
  p_name TEXT,
  p_description TEXT,
  p_goal_slug TEXT,
  p_recommended_minutes INT,
  p_cycle_secs INT
)
RETURNS UUID AS $$
DECLARE
  v_pattern_id UUID;
  v_goal_id UUID;
BEGIN
  -- Try to find an existing pattern with this name
  SELECT id INTO v_pattern_id
  FROM breathing_patterns
  WHERE name = p_name
  LIMIT 1;
  
  -- If not found, create a new one
  IF v_pattern_id IS NULL THEN
    -- Get the goal ID
    SELECT id INTO v_goal_id
    FROM breathing_goals
    WHERE slug = p_goal_slug;
    
    -- Insert the new pattern
    INSERT INTO breathing_patterns (
      id, name, description, goal_id, recommended_minutes, cycle_secs
    )
    VALUES (
      gen_random_uuid(), p_name, p_description, v_goal_id, 
      p_recommended_minutes, p_cycle_secs
    )
    RETURNING id INTO v_pattern_id;
  END IF;
  
  RETURN v_pattern_id;
END;
$$ LANGUAGE plpgsql;

-- Function to link a pattern to a step if it doesn't already exist
CREATE OR REPLACE FUNCTION link_pattern_step(
  p_pattern_id UUID,
  p_step_id UUID,
  p_position INT,
  p_repetitions INT
)
RETURNS VOID AS $$
BEGIN
  -- Check if the link already exists
  IF NOT EXISTS (
    SELECT 1 
    FROM breathing_pattern_steps 
    WHERE pattern_id = p_pattern_id AND position = p_position
  ) THEN
    -- Insert the new link
    INSERT INTO breathing_pattern_steps (
      pattern_id, step_id, position, repetitions
    )
    VALUES (
      p_pattern_id, p_step_id, p_position, p_repetitions
    );
  END IF;
END;
$$ LANGUAGE plpgsql;

-- Create all patterns
DO $$
DECLARE
  v_pattern_id UUID;
  v_step_id UUID;
BEGIN
  -- Conscious 4-4
  v_step_id := get_or_create_step(4, 'nose', 0, 4, 'nose', 0, 'Inhale 4s / Exhale 4s');
  v_pattern_id := get_or_create_pattern(
    'Respiración Consciente 4-4',
    'Respiración consciente con tiempos iguales',
    'calming',
    4,
    8  -- 4 + 0 + 4 + 0
  );
  PERFORM link_pattern_step(v_pattern_id, v_step_id, 1, 1);
  
  -- Conscious 5-5
  v_step_id := get_or_create_step(5, 'nose', 0, 5, 'nose', 0, 'Inhale 5s / Exhale 5s');
  v_pattern_id := get_or_create_pattern(
    'Respiración Consciente 5-5',
    'Respiración consciente con tiempos iguales más largos',
    'calming',
    4,
    10  -- 5 + 0 + 5 + 0
  );
  PERFORM link_pattern_step(v_pattern_id, v_step_id, 1, 1);
  
  -- Coherent 4-6
  v_step_id := get_or_create_step(4, 'nose', 0, 6, 'nose', 0, 'Inhale 4s / Exhale 6s');
  v_pattern_id := get_or_create_pattern(
    'Respiración Coherente 4-6',
    'Respiración de coherencia cardíaca con exhalación más larga',
    'calming',
    4,
    10  -- 4 + 0 + 6 + 0
  );
  PERFORM link_pattern_step(v_pattern_id, v_step_id, 1, 1);
  
  -- Coherent 3-7
  v_step_id := get_or_create_step(3, 'nose', 0, 7, 'nose', 0, 'Inhale 3s / Exhale 7s');
  v_pattern_id := get_or_create_pattern(
    'Respiración Coherente 3-7',
    'Respiración de coherencia cardíaca con exhalación prolongada',
    'calming',
    4,
    10  -- 3 + 0 + 7 + 0
  );
  PERFORM link_pattern_step(v_pattern_id, v_step_id, 1, 1);
  
  -- Box 4-4-4-4
  v_step_id := get_or_create_step(4, 'nose', 4, 4, 'nose', 4, 'Inhale 4s / Hold 4s / Exhale 4s / Hold 4s');
  v_pattern_id := get_or_create_pattern(
    'Caja 4-4-4-4',
    'Respiración cuadrada para equilibrio',
    'grounding',
    4,
    16  -- 4 + 4 + 4 + 4
  );
  PERFORM link_pattern_step(v_pattern_id, v_step_id, 1, 1);
  
  -- Triangle Inverted
  v_step_id := get_or_create_step(4, 'nose', 2, 6, 'nose', 0, 'Inhale 4s / Hold 2s / Exhale 6s');
  v_pattern_id := get_or_create_pattern(
    'Triángulo Invertido',
    'Respiración triangular con retención después de inhalar',
    'grounding',
    4,
    12  -- 4 + 2 + 6 + 0
  );
  PERFORM link_pattern_step(v_pattern_id, v_step_id, 1, 1);
  
  -- Pause 10s every 5
  v_step_id := get_or_create_step(4, 'nose', 0, 4, 'nose', 10, 'Inhale 4s / Exhale 4s / Pause 10s');
  v_pattern_id := get_or_create_pattern(
    'Pausa 10 s cada 5',
    'Respiración con pausa prolongada cada 5 ciclos',
    'grounding',
    4,
    18  -- 4 + 0 + 4 + 10
  );
  PERFORM link_pattern_step(v_pattern_id, v_step_id, 1, 1);
  
  -- Box 5-5-5-5
  v_step_id := get_or_create_step(5, 'nose', 5, 5, 'nose', 5, 'Inhale 5s / Hold 5s / Exhale 5s / Hold 5s');
  v_pattern_id := get_or_create_pattern(
    'Caja 5-5-5-5',
    'Respiración cuadrada con tiempos más prolongados',
    'grounding',
    4,
    20  -- 5 + 5 + 5 + 5
  );
  PERFORM link_pattern_step(v_pattern_id, v_step_id, 1, 1);
  
  -- Triangle Normal
  v_step_id := get_or_create_step(4, 'nose', 0, 4, 'nose', 2, 'Inhale 4s / Exhale 4s / Hold 2s');
  v_pattern_id := get_or_create_pattern(
    'Triángulo Normal',
    'Respiración triangular con retención después de exhalar',
    'grounding',
    4,
    10  -- 4 + 0 + 4 + 2
  );
  PERFORM link_pattern_step(v_pattern_id, v_step_id, 1, 1);
  
  -- Pause 15s every 4
  v_step_id := get_or_create_step(4, 'nose', 0, 4, 'nose', 15, 'Inhale 4s / Exhale 4s / Pause 15s');
  v_pattern_id := get_or_create_pattern(
    'Pausa 15 s cada 4',
    'Respiración con pausa prolongada cada 4 ciclos',
    'grounding',
    4,
    23  -- 4 + 0 + 4 + 15
  );
  PERFORM link_pattern_step(v_pattern_id, v_step_id, 1, 1);
  
  -- Box 6-6-6-6
  v_step_id := get_or_create_step(6, 'nose', 6, 6, 'nose', 6, 'Inhale 6s / Hold 6s / Exhale 6s / Hold 6s');
  v_pattern_id := get_or_create_pattern(
    'Caja 6-6-6-6',
    'Respiración cuadrada avanzada con tiempos extendidos',
    'grounding',
    4,
    24  -- 6 + 6 + 6 + 6
  );
  PERFORM link_pattern_step(v_pattern_id, v_step_id, 1, 1);
  
  -- Bhastrika Lite 2:3
  v_step_id := get_or_create_step(2, 'nose', 0, 3, 'nose', 0, 'Inhale 2s / Exhale 3s');
  v_pattern_id := get_or_create_pattern(
    'Bhastrika Lite 2:3',
    'Versión ligera de respiración energizante Bhastrika',
    'energizing',
    4,
    5  -- 2 + 0 + 3 + 0
  );
  PERFORM link_pattern_step(v_pattern_id, v_step_id, 1, 1);
  
  -- Catana
  v_step_id := get_or_create_step(4, 'nose', 5, 6, 'nose', 8, 'Inhale 4s / Hold 5s / Exhale 6s / Hold 8s');
  v_pattern_id := get_or_create_pattern(
    'Catana',
    'Patrón hormético con retenciones prolongadas',
    'energizing',
    4,
    23  -- 4 + 5 + 6 + 8
  );
  PERFORM link_pattern_step(v_pattern_id, v_step_id, 1, 1);
END;
$$;

-- Clean up our temporary functions
DROP FUNCTION IF EXISTS get_or_create_step;
DROP FUNCTION IF EXISTS get_or_create_pattern;
DROP FUNCTION IF EXISTS link_pattern_step;

COMMIT;

-- ✓ 2025-05-06 breath journey seed applied 