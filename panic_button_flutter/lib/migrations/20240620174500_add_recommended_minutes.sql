BEGIN;
ALTER TABLE routines
ADD COLUMN IF NOT EXISTS recommended_minutes int;
UPDATE routines
SET recommended_minutes = total_minutes
WHERE recommended_minutes IS NULL;
COMMIT; 