
# Breath‑work Database Reference

This document explains what each table in the Supabase schema does and gives a step‑by‑step guide for adding new breathing exercises.  
Copy–paste or append it to your project **README.md**.

---

## Table Glossary

| Table | Purpose | Example Row |
|-------|---------|-------------|
| **goals** | Master tags like *Calming*, *Energizing*. Powers filter chips. | `{ slug: "calming", display_name: "Calming" }` |
| **steps** | **Smallest unit**: one inhale/hold/exhale cycle + breathing method. | `4 s inhale nose → 0 s hold → 6 s exhale nose` |
| **patterns** | Named bundle of one or more *steps* (e.g. “4‑7‑8”). | `"Box 4‑4‑4‑4"` |
| **pattern_steps** | Orders steps inside a pattern and sets **repetitions**. | pattern = *Box*, step = *boxStep*, position 1, reps 1 |
| **routines** | Playlist the user runs. Mixes patterns and/or single steps. | `"Morning Quick Calm (4 min)"` |
| **routine_items** | Ordered items inside a routine (pattern **or** step). | position 1 → pattern “Box”; position 2 → step “Long Hold” |
| **user_routine_status** | Per‑user log: last run & total runs of a routine. | `{ user_id, routine_id, total_runs: 4 }` |

---

## Adding a New Breathing Exercise

### 1 — Plan

1. **Just a timing variant?** → add a **pattern** row that reuses existing *steps*.  
2. **Needs brand‑new timing?** → add new *step* rows first, then create the pattern.  
3. **Standalone or part of a longer flow?** → create/modify a **routine** accordingly.

### 2 — Two Ways to Insert Data

#### A. Supabase Dashboard (no SQL)

1. **Insert Step** in **steps** table.  
2. **Insert Pattern** in **patterns** table (link to a goal).  
3. **Insert Row** in **pattern_steps** to connect step + pattern.  
4. *(Optional)* Create **routine** and link via **routine_items**.

#### B. SQL Example

```sql
-- 1️⃣ Step
INSERT INTO steps (inhale_secs, inhale_method, hold_in_secs,
                   exhale_secs, exhale_method, hold_out_secs, cue_text)
VALUES (2,'nose',0,2,'nose',0,'Quick 2‑2 cycle')
RETURNING id;  -- save uuid

-- 2️⃣ Pattern with that step
WITH goal_row AS (
  SELECT id FROM goals WHERE slug = 'energizing'
), new_pattern AS (
  INSERT INTO patterns (name, description, goal_id)
  VALUES ('2‑2 Sprint','Fast biphasic breath',(SELECT id FROM goal_row))
  RETURNING id
)
INSERT INTO pattern_steps (pattern_id, step_id, position, repetitions)
VALUES ((SELECT id FROM new_pattern),
        (SELECT id FROM steps WHERE cue_text = 'Quick 2‑2 cycle'),
        1, 1);

-- 3️⃣ 60‑second routine (30 cycles)
INSERT INTO routines (name, goal_id, total_minutes)
VALUES ('60‑s Sprint',(SELECT id FROM goals WHERE slug='energizing'),1)
RETURNING id \gset

INSERT INTO routine_items (routine_id, position, pattern_id, repetitions)
VALUES (:'id',1,(SELECT id FROM patterns WHERE name='2‑2 Sprint'),30);
```

### 3 — Pro Tips

| Need | Tactic |
|------|--------|
| **Custom audio/visual** | Add `sound_id` or `animation_preset` in **steps**. |
| **User‑tunable timings** | Let users clone into a `user_patterns` table. |
| **Bulk import** | `COPY steps FROM …` inside a migration. |
| **Avoid name clashes** | `UNIQUE (name, created_by)` on **patterns**. |

---

### Mental Model

> **Step** = musical note  
> **Pattern** = riff  
> **Routine** = full song / playlist

Edit the right layer and everything clicks.
