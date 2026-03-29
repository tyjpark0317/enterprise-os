---
name: supabase-cli
description: Execute Supabase operations via CLI — SQL queries, migrations, security advisor, inspect, storage, functions, secrets, auth/network/SSL config
---

# Supabase CLI Operations

Supabase CLI(`npx supabase`)와 Management API로 DB·인프라 작업을 수행합니다.

## 1. SQL Execution

### Primary: `db query --linked` (권장)

```bash
# 단일 쿼리
npx supabase db query "SELECT * FROM profiles LIMIT 5" --linked -o table

# JSON 출력 (기본값, AI 에이전트용)
npx supabase db query "SELECT * FROM profiles LIMIT 5" --linked

# CSV 출력
npx supabase db query "SELECT * FROM profiles LIMIT 5" --linked -o csv

# SQL 파일 실행
npx supabase db query -f path/to/query.sql --linked -o table
```

### Fallback: Management API (db query 실패 시)

```bash
# 인증 + 프로젝트 ref 설정
RAW_TOKEN=$(security find-generic-password -s "Supabase CLI" -w 2>/dev/null)
TOKEN=$(echo "$RAW_TOKEN" | sed 's/go-keyring-base64://' | base64 -d 2>/dev/null)
REF=$(cat supabase/.temp/project-ref 2>/dev/null || grep NEXT_PUBLIC_SUPABASE_URL apps/web/.env.local | sed 's|.*//||;s|\.supabase.*||')

# SQL 실행
curl -s -X POST "https://api.supabase.com/v1/projects/$REF/database/query" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d "$(python3 -c "import json,sys; print(json.dumps({'query': sys.argv[1]}))" "SELECT * FROM profiles LIMIT 5")" \
  | python3 -m json.tool
```

## 2. Security Advisor

Supabase Dashboard의 Security Advisor와 동일한 검사를 SQL로 수행합니다.

### 2a. RLS 전체 점검

```bash
# 테이블별 RLS 활성화 + 정책 수
npx supabase db query "
SELECT c.relname as table_name,
       c.relrowsecurity as rls_enabled,
       count(p.polname) as policy_count
FROM pg_class c
LEFT JOIN pg_policy p ON c.oid = p.polrelid
WHERE c.relnamespace = (SELECT oid FROM pg_namespace WHERE nspname = 'public')
  AND c.relkind = 'r'
GROUP BY c.relname, c.relrowsecurity
ORDER BY policy_count ASC, c.relname
" --linked -o table
```

### 2b. RLS 비활성 테이블 (CRITICAL)

```bash
npx supabase db query "
SELECT schemaname, tablename
FROM pg_tables
WHERE schemaname = 'public' AND NOT rowsecurity
ORDER BY tablename
" --linked -o table
```

### 2c. RLS 활성이지만 정책 없는 테이블 (deny-all 상태)

```bash
npx supabase db query "
SELECT c.relname as table_name
FROM pg_class c
LEFT JOIN pg_policy p ON c.oid = p.polrelid
WHERE c.relnamespace = (SELECT oid FROM pg_namespace WHERE nspname = 'public')
  AND c.relkind = 'r' AND c.relrowsecurity = true
GROUP BY c.relname
HAVING count(p.polname) = 0
" --linked -o table
```

### 2d. 과도한 권한 가진 역할

```bash
npx supabase db query "
SELECT rolname, rolsuper, rolcreatedb, rolcreaterole, rolbypassrls
FROM pg_roles
WHERE rolname NOT LIKE 'pg_%'
  AND rolname NOT IN ('postgres', 'supabase_admin', 'supabase_auth_admin',
    'supabase_storage_admin', 'supabase_replication_admin',
    'supabase_read_only_user', 'supabase_realtime_admin',
    'supabase_functions_admin')
ORDER BY rolname
" --linked -o table
```

### 2e. 외래키 없는 참조 관계 검사

```bash
npx supabase db query "
SELECT tc.table_name, kcu.column_name, ccu.table_name AS foreign_table
FROM information_schema.table_constraints tc
JOIN information_schema.key_column_usage kcu ON tc.constraint_name = kcu.constraint_name
JOIN information_schema.constraint_column_usage ccu ON ccu.constraint_name = tc.constraint_name
WHERE tc.constraint_type = 'FOREIGN KEY' AND tc.table_schema = 'public'
ORDER BY tc.table_name
" --linked -o table
```

### 2f. 공개 접근 가능한 함수 (Security Definer)

```bash
npx supabase db query "
SELECT n.nspname as schema, p.proname as function_name, p.prosecdef as security_definer
FROM pg_proc p
JOIN pg_namespace n ON p.pronamespace = n.oid
WHERE n.nspname = 'public' AND p.prosecdef = true
ORDER BY p.proname
" --linked -o table
```

### 2g. 인덱스 없는 외래키

```bash
npx supabase db query "
SELECT c.conrelid::regclass AS table_name,
       a.attname AS fk_column,
       c.conname AS constraint_name
FROM pg_constraint c
JOIN pg_attribute a ON a.attrelid = c.conrelid AND a.attnum = ANY(c.conkey)
WHERE c.contype = 'f'
  AND NOT EXISTS (
    SELECT 1 FROM pg_index i
    WHERE i.indrelid = c.conrelid
      AND a.attnum = ANY(i.indkey)
  )
ORDER BY table_name, fk_column
" --linked -o table
```

### 2h. Auth 설정 점검

```bash
RAW_TOKEN=$(security find-generic-password -s "Supabase CLI" -w 2>/dev/null)
TOKEN=$(echo "$RAW_TOKEN" | sed 's/go-keyring-base64://' | base64 -d 2>/dev/null)
REF=$(cat supabase/.temp/project-ref 2>/dev/null)

curl -s "https://api.supabase.com/v1/projects/$REF/config/auth" \
  -H "Authorization: Bearer $TOKEN" | python3 -c "
import json,sys
c = json.load(sys.stdin)
checks = [
  ('disable_signup', c.get('disable_signup'), 'Open signup enabled'),
  ('refresh_token_rotation', c.get('refresh_token_rotation_enabled'), 'Token rotation'),
  ('mfa_max_factors', c.get('mfa_max_enrolled_factors'), 'MFA max factors'),
  ('session_timebox', c.get('sessions_timebox', 0), 'Session timebox (0=unlimited)'),
  ('session_inactivity', c.get('sessions_inactivity_timeout', 0), 'Inactivity timeout (0=unlimited)'),
]
for name, val, desc in checks:
  status = '⚠️' if val in (False, 0, None) else '✅'
  print(f'{status} {desc}: {val}')
"
```

### 2i. Network / SSL 점검

```bash
RAW_TOKEN=$(security find-generic-password -s "Supabase CLI" -w 2>/dev/null)
TOKEN=$(echo "$RAW_TOKEN" | sed 's/go-keyring-base64://' | base64 -d 2>/dev/null)
REF=$(cat supabase/.temp/project-ref 2>/dev/null)

echo "=== Network Restrictions ==="
curl -s "https://api.supabase.com/v1/projects/$REF/network-restrictions" \
  -H "Authorization: Bearer $TOKEN" | python3 -m json.tool

echo "=== SSL Enforcement ==="
curl -s "https://api.supabase.com/v1/projects/$REF/ssl-enforcement" \
  -H "Authorization: Bearer $TOKEN" | python3 -m json.tool
```

### 2j. 전체 Security Advisor 실행 (one-shot)

위 2a-2g 검사를 한 번에 실행:

```bash
npx supabase db query "
-- 1) RLS 비활성 테이블
SELECT 'NO_RLS' as check_type, tablename as item, '' as detail
FROM pg_tables WHERE schemaname = 'public' AND NOT rowsecurity
UNION ALL
-- 2) RLS 활성 + 정책 0개
SELECT 'NO_POLICIES', c.relname, ''
FROM pg_class c LEFT JOIN pg_policy p ON c.oid = p.polrelid
WHERE c.relnamespace = (SELECT oid FROM pg_namespace WHERE nspname = 'public')
  AND c.relkind = 'r' AND c.relrowsecurity = true
GROUP BY c.relname HAVING count(p.polname) = 0
UNION ALL
-- 3) Security Definer 함수
SELECT 'SEC_DEFINER', p.proname, n.nspname
FROM pg_proc p JOIN pg_namespace n ON p.pronamespace = n.oid
WHERE n.nspname = 'public' AND p.prosecdef = true
UNION ALL
-- 4) Superuser 역할
SELECT 'SUPERUSER', rolname, ''
FROM pg_roles WHERE rolsuper = true AND rolname NOT LIKE 'pg_%' AND rolname != 'supabase_admin'
UNION ALL
-- 5) FK without index
SELECT 'FK_NO_INDEX', c.conrelid::regclass::text, a.attname
FROM pg_constraint c
JOIN pg_attribute a ON a.attrelid = c.conrelid AND a.attnum = ANY(c.conkey)
WHERE c.contype = 'f'
  AND NOT EXISTS (SELECT 1 FROM pg_index i WHERE i.indrelid = c.conrelid AND a.attnum = ANY(i.indkey))
ORDER BY check_type, item
" --linked -o table
```

## 3. Database Inspection

```bash
# 테이블 통계 (크기, 인덱스, 행수)
npx supabase inspect db table-stats --linked

# 인덱스 통계 (사용률, 스캔 횟수)
npx supabase inspect db index-stats --linked

# DB 전체 통계 (캐시 히트율, 크기, WAL)
npx supabase inspect db db-stats --linked

# 느린 쿼리 (5분 이상)
npx supabase inspect db long-running-queries --linked

# 쿼리 실행 시간 순위 (pg_stat_statements)
npx supabase inspect db outliers --linked

# 호출 횟수 순위
npx supabase inspect db calls --linked

# 테이블 I/O 프로파일 (읽기/쓰기 비율)
npx supabase inspect db traffic-profile --linked

# 테이블 bloat (dead tuple)
npx supabase inspect db bloat --linked

# Vacuum 통계
npx supabase inspect db vacuum-stats --linked

# 역할 통계
npx supabase inspect db role-stats --linked

# Lock 상태
npx supabase inspect db locks --linked
npx supabase inspect db blocking --linked

# Replication slots
npx supabase inspect db replication-slots --linked

# 전체 보고서 (CSV로 저장)
npx supabase inspect report --linked --output-dir /tmp/supabase-report
```

## 4. Migrations

```bash
# 목록
npx supabase migration list --linked

# 새 migration 생성
npx supabase migration new <name>

# Push (dry-run 먼저!)
npx supabase db push --linked --dry-run
npx supabase db push --linked

# Pull (원격 → 로컬)
npx supabase db pull --linked

# Repair (불일치 수정)
npx supabase migration repair --status applied <version> --linked
npx supabase migration repair --status reverted <version> --linked

# Schema lint (plpgsql 검사)
npx supabase db lint --linked
npx supabase db lint --linked --level error  # 에러만

# Schema dump
npx supabase db dump --linked
```

### Migration 타임스탬프 규칙 (MANDATORY)

```bash
# 중복 확인
ls supabase/migrations/ | cut -d'_' -f1 | sort | uniq -d

# 안전한 다음 타임스탬프
LAST=$(ls supabase/migrations/ | cut -d'_' -f1 | sort -n | tail -1)
echo "다음 사용 가능: $((LAST + 1))"
```

**사고 경위 (2026-03-14)**: 같은 타임스탬프 파일 2개 → push 실패. 파일 rename + repair로 복구.

## 5. Type Generation

```bash
npx supabase gen types typescript --linked > packages/shared/src/types/database.ts
```

## 6. Edge Functions

```bash
npx supabase functions list --project-ref $(cat supabase/.temp/project-ref)
npx supabase functions deploy <function-name> --project-ref $(cat supabase/.temp/project-ref)
npx supabase functions delete <function-name> --project-ref $(cat supabase/.temp/project-ref)
npx supabase functions new <function-name>
```

## 7. Secrets

```bash
npx supabase secrets list --project-ref $(cat supabase/.temp/project-ref)
npx supabase secrets set KEY=VALUE --project-ref $(cat supabase/.temp/project-ref)
npx supabase secrets unset KEY --project-ref $(cat supabase/.temp/project-ref)
```

## 8. Storage

```bash
npx supabase storage ls --linked
npx supabase storage ls ss:///bucket-name --linked
npx supabase storage cp local-file ss:///bucket/path --linked
npx supabase storage rm ss:///bucket/path --linked
```

## 9. Infrastructure Config (Management API)

```bash
RAW_TOKEN=$(security find-generic-password -s "Supabase CLI" -w 2>/dev/null)
TOKEN=$(echo "$RAW_TOKEN" | sed 's/go-keyring-base64://' | base64 -d 2>/dev/null)
REF=$(cat supabase/.temp/project-ref 2>/dev/null)

# Auth 설정
curl -s "https://api.supabase.com/v1/projects/$REF/config/auth" \
  -H "Authorization: Bearer $TOKEN" | python3 -m json.tool

# Network restrictions
curl -s "https://api.supabase.com/v1/projects/$REF/network-restrictions" \
  -H "Authorization: Bearer $TOKEN" | python3 -m json.tool

# SSL enforcement
curl -s "https://api.supabase.com/v1/projects/$REF/ssl-enforcement" \
  -H "Authorization: Bearer $TOKEN" | python3 -m json.tool

# Postgres config
curl -s "https://api.supabase.com/v1/projects/$REF/config/database/postgres" \
  -H "Authorization: Bearer $TOKEN" | python3 -m json.tool

# Project info
npx supabase projects list
```

## 10. Project Info

| 항목 | 값 |
|------|------|
| Project ref | `supabase/.temp/project-ref` 또는 `.env.local`의 URL에서 추출 |
| Access token | macOS Keychain `Supabase CLI` 항목 (go-keyring-base64 인코딩) |
| SQL API | `https://api.supabase.com/v1/projects/{ref}/database/query` |
| Auth | `npx supabase login` 으로 최초 인증 |

## Troubleshooting

| 문제 | 해결 |
|------|------|
| `Cannot connect to Docker daemon` | `--linked` 사용 (원격 DB 직접 접근) |
| `unknown flag: --project-ref` | `--linked` 사용 또는 Management API |
| `Remote migration versions not found` | `supabase migration repair` |
| Token expired | `npx supabase login` 재실행 |
| Empty result `[]` | DDL 성공 (결과 없는 것이 정상) |
| `db query` 없음 | CLI 업데이트: `npm i -g supabase@latest` |

## Safety

- **DDL (ALTER, DROP, CREATE)**: 프로덕션 실행 전 반드시 확인 프롬프트
- **Migration 파일 기반**: 가능하면 `supabase/migrations/` 파일의 SQL을 그대로 실행
- **결과 검증**: DDL 실행 후 반드시 `information_schema` 조회로 적용 확인
- **Security Advisor**: 프로덕션 변경 없이 읽기 전용 검사
