---
name: e2e-test-guide
description: Use when writing Playwright E2E tests, integration tests, or browser-based tests. Also use when testing user flows like login, checkout, or search. Triggers on "E2E test", "Playwright test", "integration test", "end-to-end test", "browser test", or "user flow test".
---

## Playwright E2E Test Guide

## Step 1: Project Setup — verify playwright config and test accounts

### Installation

```bash
# Install (if not already)
npm install -D @playwright/test   # or pnpm/yarn
npx playwright install chromium

# Config: playwright.config.ts (or apps/web/playwright.config.ts in monorepos)
# Env vars loaded from .env.local automatically by config
```

### Test Accounts

Configure test accounts for your application roles:

| Role | Email | Notes |
|------|-------|-------|
| Admin | admin-test@example.com | Has admin permissions |
| User | user-test@example.com | Standard user profile |

### Directory Structure

```
e2e/
├── auth.setup.ts       # Global auth setup (cookie-based)
├── fixtures/
│   └── auth.ts         # Role-specific page fixtures (adminPage, userPage)
├── pages/
│   ├── home.page.ts
│   ├── dashboard.page.ts
│   └── settings.page.ts
├── user-journey.spec.ts
├── admin-journey.spec.ts
├── edge-cases.spec.ts
└── .auth/              # Stored auth state (gitignored)
```

## Step 2: Auth Fixtures — create cookie-based auth helpers

The auth setup creates authenticated browser contexts per role:
1. Sign in via your auth provider (Supabase, NextAuth, etc.)
2. Store auth state (cookies, localStorage) per role
3. Provide role-specific page fixtures for tests

Never use `localStorage` alone for auth — server components read cookies.

## Step 3: Page Objects — create page object classes

### Page Object Pattern

```typescript
// pages/dashboard.page.ts
import { type Page, type Locator } from '@playwright/test';

export class DashboardPage {
  readonly heading: Locator;

  constructor(private page: Page) {
    this.heading = page.getByRole('heading', { name: 'Dashboard' });
  }

  async goto() {
    await this.page.goto('/dashboard');
    await this.page.waitForLoadState('networkidle');
  }
}
```

## Step 4: Write Tests — implement critical user journey tests

### Critical User Journeys

**Primary User Journey** (highest priority):
1. Home -> Browse items -> Apply filters
2. Click item -> View details
3. Take action (purchase, submit, etc.)
4. Confirmation flow
5. View history -> Manage items

**Admin Journey**:
1. Dashboard -> View statistics
2. Manage content -> CRUD operations
3. User management -> View details
4. Settings -> Configuration

**Edge Cases**:
1. Duplicate action prevention (expect 409)
2. Cancellation within policy period
3. Expired session handling
4. Empty state pages (no items, no history)
5. Mobile viewport responsiveness

### Test Template

```typescript
import { test, expect } from './fixtures/auth';
import { DashboardPage } from './pages/dashboard.page';

test.describe('User Dashboard Journey', () => {
  test('can view dashboard after login', async ({ userPage }) => {
    const dashboard = new DashboardPage(userPage);
    await dashboard.goto();
    await expect(dashboard.heading).toBeVisible();
  });
});
```

## Step 5: Run and Report — execute tests and generate reports

### Running Tests

```bash
# All E2E tests
npx playwright test

# Specific test file
npx playwright test e2e/user-journey.spec.ts

# With UI mode (debugging)
npx playwright test --ui

# Generate report
npx playwright show-report
```

### Best Practices

- Use `networkidle` wait for page loads
- Prefer `getByRole`, `getByLabel`, `getByText` over CSS selectors
- Use `axe-core` for accessibility testing (via `@axe-core/playwright`)
- Avoid `page.waitForTimeout()` — use explicit waits (`waitForSelector`, `waitForResponse`)
- Set reasonable timeouts (30s default, 60s for slow operations)
- Use `test.describe.configure({ mode: 'serial' })` only when tests must run in order

## Checklist

- [ ] Verify project setup and config
- [ ] Configure auth fixtures (cookie-based)
- [ ] Create page objects
- [ ] Write test cases for critical user journeys
- [ ] Run tests and generate report
