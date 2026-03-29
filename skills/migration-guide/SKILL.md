---
name: migration-guide
description: Database migration, RLS, schema guide — performance patterns, anti-patterns, SECURITY DEFINER, safety checklist. Use when creating/modifying migration files, RLS policies, or DB schema.
---

# Database Migration & RLS Guide

Reference skill for writing migration files, designing RLS policies, and schema changes.
Based on official documentation, performance benchmarks, and production incident learnings.

---

## 1. Migration File Rules

### Timestamps — Never Duplicate
Always verify the next available timestamp before creating a new migration.

### File Naming
```
GOOD: 20260315000001_add-user-alerts.sql
BAD:  20260315000001_update.sql
```

### File Structure
```sql
-- ============================================================
-- Purpose: [what is being changed]
-- Reason: [why it is needed]
-- Impact: [which tables/policies are affected]
-- ============================================================
```

---

## 2. RLS Performance Patterns (Benchmarks on 100K-row tables)

### Pattern 1: `(select auth.uid())` Wrapping — 94-99.99% Improvement

```sql
-- BAD: auth.uid() called per-row (179ms)
CREATE POLICY "..." ON my_table
  USING (auth.uid() = user_id);

-- GOOD: initPlan executes once (9ms, 94.97% improvement)
CREATE POLICY "..." ON my_table
  TO authenticated
  USING ((select auth.uid()) = user_id);
```

### Pattern 2: Add Indexes — 99.94% Improvement
```sql
CREATE INDEX IF NOT EXISTS idx_{table}_{column}
  ON public.{table} USING btree ({column});
```

### Pattern 3: Specify TO Role — 99.78% Improvement
```sql
-- GOOD: anon skips instantly
CREATE POLICY "..." ON my_table
  TO authenticated
  USING ((select auth.uid()) = user_id);
```

### Pattern 4: JOIN Direction — 99.78% Improvement
```sql
-- GOOD: fixed-value join
CREATE POLICY "..." ON test_table TO authenticated
  USING (
    team_id IN (
      SELECT team_id FROM team_user
      WHERE user_id = (select auth.uid())
    )
  );
```

### Pattern 5: Client Filter Duplication — 94.74% Improvement
Add the same filter on the client side as RLS for better query plans.

---

## 3. RLS Policy Design

### Core Principles
1. Enable RLS on every table — no exceptions
2. Always specify `TO authenticated`
3. Always wrap `(select auth.uid())`
4. Minimum privilege — only needed operations

### RLS Policy Template
```sql
CREATE POLICY "{table}_select_own" ON public.{table}
  FOR SELECT TO authenticated
  USING ((select auth.uid()) = user_id);

CREATE POLICY "{table}_insert_own" ON public.{table}
  FOR INSERT TO authenticated
  WITH CHECK ((select auth.uid()) = user_id);

CREATE POLICY "{table}_update_own" ON public.{table}
  FOR UPDATE TO authenticated
  USING ((select auth.uid()) = user_id)
  WITH CHECK ((select auth.uid()) = user_id);
```

### FOR ALL Prohibited
Always separate into 4 operations with specific roles.

### Permissive vs Restrictive
PostgreSQL combines: `(permissive1 OR permissive2) AND restrictive1 AND restrictive2`

---

## 4. RLS Anti-Patterns

### Anti-Pattern 1: Self-Referencing Recursion (CRITICAL)
When a SELECT policy queries the same table → infinite recursion. Fix with SECURITY DEFINER function.

### Anti-Pattern 2: Under-Permissive RLS (HIGH)
Public data tables (profiles, availability) need `USING (true)` for cross-user reads.

### Anti-Pattern 3: Missing DELETE Policy (MEDIUM)
Review all 4 operations for every table.

### Anti-Pattern 4: auth.uid() NULL Handling (LOW)
Use `TO authenticated` to prevent anon execution.

---

## 5. SECURITY DEFINER Pattern

### Required Security Rules
```sql
CREATE FUNCTION private.has_role(role_name TEXT)
RETURNS BOOLEAN LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''  -- Required: prevents search_path injection
STABLE AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM public.roles_table
    WHERE user_id = auth.uid() AND role = role_name
  );
END; $$;
```

Must-haves:
- `SET search_path = ''`
- `REVOKE FROM PUBLIC` + `REVOKE FROM anon`
- `public.` prefix on all references
- Place in private schema (not exposed)
- Wrap with `(select function())` in policies

---

## 6. Zero-Downtime Migration Patterns

### NOT VALID + VALIDATE
```sql
-- Migration 1: instant (validates new rows only)
ALTER TABLE orders ADD CONSTRAINT fk_user
  FOREIGN KEY (user_id) REFERENCES users(id) NOT VALID;

-- Migration 2: validates existing rows with lightweight lock
ALTER TABLE orders VALIDATE CONSTRAINT fk_user;
```

### CONCURRENTLY Index
```sql
CREATE INDEX CONCURRENTLY idx_col ON public.{table}(col);
```

### DDL Lock Reference
| Operation | Lock | Blocks Reads? | Blocks Writes? |
|-----------|------|--------------|----------------|
| ADD COLUMN (nullable) | ACCESS EXCLUSIVE | Momentary | Momentary |
| ALTER COLUMN TYPE | ACCESS EXCLUSIVE | **Full** | **Full** |
| CREATE INDEX | SHARE | No | **Yes** |
| CREATE INDEX CONCURRENTLY | None | No | No |
| VALIDATE CONSTRAINT | SHARE UPDATE EXCLUSIVE | No | No |

---

## 7. Migration Safety Checklist

### Structure
- [ ] No timestamp duplicates
- [ ] Comment header with purpose/reason/impact
- [ ] `IF NOT EXISTS` / `IF EXISTS` for idempotency
- [ ] FK with ON DELETE CASCADE/RESTRICT specified

### RLS
- [ ] `ENABLE ROW LEVEL SECURITY` on new tables
- [ ] All 4 operations reviewed (UPDATE needs SELECT policy too)
- [ ] `TO authenticated` specified
- [ ] `(select auth.uid())` wrapped
- [ ] No self-referencing subqueries (recursion check)
- [ ] Index on RLS columns

### SECURITY DEFINER
- [ ] `SET search_path = ''`
- [ ] `REVOKE FROM PUBLIC` + `REVOKE FROM anon`
- [ ] `GRANT TO authenticated`
- [ ] `public.` prefix used
- [ ] Placed in private schema

### Compatibility
- [ ] NOT NULL additions have DEFAULT
- [ ] `DROP POLICY IF EXISTS` before recreate
- [ ] `CREATE OR REPLACE` for functions/triggers
- [ ] lock_timeout for large table ALTERs
