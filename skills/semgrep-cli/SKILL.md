---
name: semgrep-cli
description: Run Semgrep code scanning via CLI. Use when needing to "scan code", "security scan", "find vulnerabilities", "code scan".
---

## Semgrep CLI Operations

Run Semgrep security scanning directly via CLI.

### Operations

1. **Full Scan**: `npx semgrep scan --config auto src/`
2. **Specific Rules**: `npx semgrep scan --config p/typescript --config p/react src/`
3. **Single File**: `npx semgrep scan --config auto path/to/file.ts`
4. **Supply Chain**: `npx semgrep scan --config p/supply-chain .`
5. **JSON Output**: `npx semgrep scan --config auto --json src/ | jq '.results[]'`

### Common Rule Packs

| Pack | Purpose |
|------|---------|
| `p/typescript` | TypeScript general |
| `p/react` | React patterns |
| `p/nextjs` | Next.js specific |
| `p/owasp-top-ten` | OWASP Top 10 |
| `p/supply-chain` | Dependency vulnerabilities |
| `p/secrets` | Hardcoded secrets |
