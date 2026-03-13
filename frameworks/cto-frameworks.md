# CTO Decision-Making Frameworks

> Comprehensive reference for the CTO agent. Each framework includes origin, core principle, generic application, decision template, and anti-pattern.
> Sources: Werner Vogels (Amazon CTO), Martin Fowler, Jeff Bezos, Michael Nygard, Ward Cunningham, Don Roberts, Simon Brown, Thoughtworks, DORA Team
> Target path in project: docs/executive/shared/frameworks/cto-frameworks.md

---

## 1. "Everything Fails All the Time"

**Origin:** Werner Vogels (Amazon CTO, Communications of the ACM)

**Full Quote:** "Everything fails, all the time. Plan for failure, and nothing will fail." The second half is almost always omitted -- and that omission is the point. This is not pessimism; it is a design mandate. In distributed systems at scale, the probability of every component being healthy simultaneously approaches zero. Failure is the normal operating mode.

**Three Failure Categories:**

| Category | Example | Design Response |
|---|---|---|
| **Transient** | Network timeout, database momentary spike | Retry with exponential backoff + jitter |
| **Partial** | One database replica down, one API region degraded | Circuit breaker, graceful degradation |
| **Total** | Full vendor outage (database, payment provider unreachable) | Fallback state, cached reads, queue writes for replay |

**Application:**

*Database failure:*
- Server-side rendering: catch DB error, return cached/stale data with a staleness banner rather than a 500 page
- Auth routes: if auth service is unreachable, middleware must fail closed (deny access), not fail open
- Webhook handlers: write incoming events to a dead-letter mechanism so they can be replayed when the database recovers

*Payment provider failure:*
- Never assume a charge succeeded because the request returned no error -- wait for the webhook confirmation
- Idempotency keys on every payment API call
- Display "payment is processing" state until webhook confirms -- never show success prematurely
- API call creation: timeout + retry with exponential backoff (1s, 2s, 4s, max 8s, with jitter)

*Deployment platform failure:*
- Never deploy all environments simultaneously; validate with preview deploys before promoting to production
- Keep previous deployment hash documented; rollback = platform dashboard action
- Protect production branch: require passing CI before merging

*Agent system failure:*
- Pipeline orchestrator must write state to a checkpoint file before spawning sub-agents -- recovery point
- Sub-agent returns no report -> re-spawn up to 3 times -> orchestrator runs build/lint/test directly as fallback
- Pipeline checkpoints (QA gate, validation gate) are explicit recovery points

**Decision Template:** "What does this code do when the external service returns a 503? What does the user see when the database is down at 3 AM? If the answer is 'unhandled error,' this does not ship."

**Anti-pattern:** Shipping code that only handles the happy path. Every external call without failure handling is a production incident waiting to happen.

---

## 2. "You Build It, You Run It"

**Origin:** Werner Vogels (ACM Queue interview, May 2006)

**Core Principle:** "Giving developers operational responsibilities has greatly enhanced the quality of the services." Developers who know they will be paged at 3 AM write dramatically different code -- they add observability, handle edge cases, and write the runbook because they are the ones who will read it.

**The Feedback Loop:**
```
Write code -> Ship to production -> Get paged when it breaks
         ^                                    |
         +------------------------------------+
         Fix the root cause, not just the symptom
```

**Application:**
- The developer who writes the feature owns: the code, the tests, the migration, the error paths, and the fix when QA finds issues
- The developer who writes the API owns the database migration that goes with it
- The developer who integrates payments owns the webhook handler and its error paths
- QA is the second set of eyes, not the safety net. The developer is the first.
- No file is "someone else's problem" once you touch it

**Decision Template:** "Who is the DRI (Directly Responsible Individual) for this code in production? Not a team -- one name."

**Anti-pattern:** Treating QA as the safety net instead of the second reviewer. Handing off code and forgetting about it.

---

## 3. Two-Pizza Teams

**Origin:** Jeff Bezos / Werner Vogels (Amazon organizational principle)

**Core Principle:** If a team requires more than two pizzas to feed, it is too large. Communication channels scale as N(N-1)/2. At 5 people: 10 channels. At 10 people: 45 channels. At 20 people: 190 channels. Large teams slow down not because people are lazy, but because coordination cost grows faster than output capacity.

**Agent Team Sizing:**

| Team Size | Appropriate For |
|---|---|
| 1 agent | TRIVIAL tasks (3 files or fewer), single-domain changes |
| 2-3 agents | STANDARD tasks, cross-layer work (developer + qa) |
| 3-5 agents | MAJOR tasks, parallel validation (compliance + code review + security review) |
| Never >5 | Communication overhead exceeds coordination benefit |

**When to Split vs. Keep Together:**
- Split: agents have different tools, different domains, and zero blocking dependencies
- Keep together: strong sequential dependency (QA must complete before validators run)
- Parallel validation (3 validators simultaneously) is the two-pizza principle in action

**Decision Template:** "How many agents are involved? If more than 5, which dependency can we remove to split into two smaller teams?"

**Anti-pattern:** Spawning large agent teams where communication overhead exceeds output. Adding ammunition (more workers) without barrels (capable orchestrators).

---

## 4. Working Backwards / PR-FAQ

**Origin:** Werner Vogels + Amazon product process (2006, allthingsdistributed.com)

**Core Principle:** Start with the press release for the finished product, not with the technology. Write the announcement as if the feature shipped today. Who is it for? What does it do? Why does it matter? If the press release cannot be written clearly, the feature is not ready to build.

**PR Template for Features:**
```
FOR [target user segment]
WHO WANT [the problem they have]
THE [feature name]
IS A [what type of thing it is]
THAT [what it does]
UNLIKE [the current alternative]
OUR PRODUCT [what makes it specifically better]
```

**FAQ Layers:**
1. External FAQ: What questions would users ask?
2. Internal FAQ: What are the hard technical constraints? What are the failure modes?

**Application:**
- Before starting any feature pipeline, ask: "Can you write a two-sentence press release? Who uses it and what does it do?"
- Plan section in task memory serves as the internal FAQ
- Context section documents why decisions were made (the alternatives considered)

**Decision Template:** "Write a two-sentence press release for this feature. If you cannot, the feature is not defined enough to build."

**Anti-pattern:** Starting with technology ("we should use real-time subscriptions for X") instead of user outcome ("a user knows their action was confirmed in real time").

---

## 5. Undifferentiated Heavy Lifting -- Buy vs Build

**Origin:** Werner Vogels (the insight that led to AWS)

**Core Principle:** Work that is necessary but identical across every company is "undifferentiated heavy lifting." Building your own auth, payment processing, or server infrastructure creates no competitive advantage. Your infrastructure is someone else's product.

**Decision Framework:**
```
Does building this ourselves create differentiated user value?
  YES -> Build it. This is your competitive moat.
  NO  -> Buy it. This is undifferentiated heavy lifting.
```

**Vendor Evaluation Matrix:**

| Criterion | Buy Signal | Build Signal |
|---|---|---|
| Commodity function? | Yes -> Buy | No -> Build |
| Time to first value? | <1 week -> Buy | Requires months -> Buy anyway |
| Touches core domain model? | No -> Buy | Yes -> Build |
| Proven managed service exists? | Yes -> Buy | No -> Build |
| Lock-in risk? | Acceptable -> Buy | Dangerous -> Evaluate |

**Decision Template:** "Is this undifferentiated heavy lifting? If a mature managed service exists and it is not our core domain, buy it and document the ADR."

**Anti-pattern:** NIH (Not Invented Here) syndrome -- building everything yourself. Also: outsourcing core domain logic to a vendor.

---

## 6. Reduce Blast Radius

**Origin:** Werner Vogels (2024 keynote, cell-based architecture)

**Core Principle:** When something goes wrong, minimize how much breaks. A ship uses bulkheads -- watertight compartments -- so a breach in one section does not sink the entire ship.

**Blast Radius Reduction Techniques:**

**1. Small, frequent deployments:**
- Each PR = single focused change
- Never bundle schema migration + API change + UI change in one deployment
- Rule: if the PR title requires "and," split it into two PRs

**2. Feature flags:**
- New features ship behind a flag, enable for a small percentage of users first
- Roll back by flipping the flag, not reverting a deployment

**3. Database migrations -- maximum blast radius risk:**
- Never modify a column in one migration (add new -> migrate data -> drop old = three separate migrations)
- Never drop a column until code referencing it has been removed and deployed
- Additive-only in production: expand then contract

**4. Agent system blast radius:**
- Test one agent change at a time, never batch agent file changes
- QA gate is a blast-radius control: broken code cannot reach validators
- When modifying hooks: test on a trivial change before using on a major feature

**Rollback Strategy:**
```bash
# Document in every PR:
# Code rollback: git revert HEAD, push to main, auto-deploy
# DB rollback: only if migration is reversible -- document in Context BEFORE merging
# Feature flag rollback: flip the flag, no deployment needed
```

**Decision Template:** "If this deployment fails, what is the blast radius? Can we contain it to one feature? One page? One user segment?"

**Anti-pattern:** Bundling schema + API + UI in one PR. Deploying without a rollback plan documented.

---

## 7. DORA Metrics

**Origin:** DORA Team (dora.dev), validated across thousands of organizations

**Four Metrics with Targets:**

| Metric | Measures | Elite Benchmark | Recommended Target |
|---|---|---|---|
| **Deployment Frequency** | How often code ships | Multiple times/day | 1x per feature (weekly minimum) |
| **Lead Time for Changes** | Commit -> production | <1 day | <1 week (PR -> merge -> deploy) |
| **Change Failure Rate** | % deployments requiring hotfix/rollback | <5% | <10% |
| **MTTR** | Time to recover from failed deployment | <1 hour | <2 hours |

**Why These Resist Gaming:** Teams that optimize one metric at the expense of others show up immediately. Ship more without tests -> Change Failure Rate spikes. Require 5-day reviews -> Lead Time degrades.

**Decision Template:** "After this feature ships, log DORA metrics. Are we trending toward elite or away from it?"

**Anti-pattern:** Optimizing one DORA metric at the expense of others (e.g., skipping tests to increase deployment frequency).

---

## 8. C4 Model -- Architectural Documentation

**Origin:** Simon Brown (c4model.com)

**Four Levels:**

| Level | Shows | Audience | When to Write |
|---|---|---|---|
| **L1 -- System Context** | Your system + external systems | Non-technical stakeholders | Once for the project |
| **L2 -- Container** | Major runtime containers (app, DB, external APIs) | Architects, new developers | Per major subsystem |
| **L3 -- Component** | Internal modules/flows within a container | Developers | Per feature in Context docs |
| **L4 -- Code** | Class/function diagrams | Complex algorithm owners | Only for genuinely complex paths |

**Application Rule:** New features get L3 documentation in Context docs. Major architectural decisions get L2. L4 only when the algorithm is genuinely complex (concurrency, distributed state, complex computation).

**Decision Template:** "What level of architectural documentation does this feature need? Default to L3 in Context docs."

**Anti-pattern:** Writing L4 documentation for simple CRUD. Writing no documentation for complex multi-service interactions.

---

## 9. Architecture Decision Records (ADRs)

**Origin:** Michael Nygard (the canonical ADR template)

**When to Write an ADR:**
- Decision is hard to reverse (database choice, auth pattern, payment provider)
- Multiple reasonable alternatives exist and reasoning matters later
- Decision will confuse a developer reading the code in 6 months

**Template:**
```markdown
# ADR-{number}: {Title}

**Date**: {YYYY-MM-DD}
**Status**: {Proposed | Accepted | Rejected | Deprecated | Superseded by ADR-N}

## Context
{Situation forcing this decision. Constraints. Business pressure. Alternatives considered.}

## Decision
{What was decided. Clear and direct.}

## Consequences
**Positive:** {What becomes easier or better}
**Negative:** {What becomes harder. What debt is incurred. What doors close.}
**Neutral:** {Side effects neither good nor bad}
```

**CTO Rule:** Every decision with a non-obvious alternative (someone could reasonably have chosen differently) gets an ADR. Context section in task memory serves this purpose for feature-level decisions.

---

## 10. Technical Debt Financial Metaphor

**Origin:** Ward Cunningham (1992, coined "technical debt")

**Financial Mapping:**

| Financial Term | Technical Equivalent |
|---|---|
| **Principal** | Cost to implement the correct solution today |
| **Interest** | Extra time every feature takes because of the incorrect solution |
| **Compound interest** | Debt accumulating on debt -- features built on bad abstractions inherit problems |
| **Default** | System becomes unmaintainable -- forced rewrite |

**When Debt is Acceptable:**

| Context | Acceptable? | Reason |
|---|---|---|
| Prototype / spike | Yes | Code will be discarded or rewritten |
| MVP under time pressure | Yes, documented | Fast to market; schedule explicit payback |
| Core domain model | No | Interest compounds with every feature |
| Security-critical paths | Never | Interest is a breach |
| Database schema | Never without migration plan | Reversing bad schemas is extremely costly |

**Prioritization Formula:**

Priority = Impact x Frequency x Risk of Deferral

| Factor | Low (1) | Medium (2) | High (3) |
|---|---|---|---|
| **Impact** | <5% users or non-critical path | Moderate traffic or one key feature | All users or critical path |
| **Frequency** | Encountered rarely | Encountered in multiple features | Encountered in every new feature |
| **Risk of Deferral** | Gets harder slowly | Gets harder over time | Each week of delay makes it exponentially harder |

Score 1-3: Low (cleanup sprint). 4-6: Medium (next 2-3 features). 7-9: High (before next major feature). 10-27: Critical (stop and fix now).

---

## 11. Three Strikes Rule

**Origin:** Don Roberts (via Martin Fowler's "Refactoring")

**Core Principle:** "The first time you do something, just do it. The second time, wince at the duplication but do it anyway. The third time, refactor." Three occurrences of the same pattern causing issues = platform fix needed.

**Application:**
- Same auth bug in 3 routes -> extract shared `requireAuth` middleware
- Same error handling copy-pasted in 3 handlers -> extract shared error handler
- Same database access pattern in 3 tables -> extract shared policy template
- Same agent failure pattern 3 times -> hook or agent file modification

**Decision Template:** "Is this the third time we have seen this pattern? If yes, the fix is not in this feature -- it is a platform change."

**Anti-pattern:** Ignoring repeated patterns. Also: premature abstraction before 3 occurrences (extracting after 1 occurrence = over-engineering).

---

## 12. Simplexity Framework

**Origin:** Werner Vogels (AWS re:Invent 2024 keynote)

**Distinction:**
- **Intentional complexity**: Accepted knowingly because it enables capability (e.g., multi-tenant RLS is complex but necessary for data isolation)
- **Unintentional complexity**: Crept in through oversight, inconsistency, or accumulated shortcuts

**Six Principles for Managing Complexity:**

1. **Make evolvability a requirement** -- systems must accommodate future changes without breaking their foundation. Use expand-then-contract migration patterns. Avoid tight coupling.

2. **Break complexity into pieces** -- modularity prevents cascading failures. Each API route handles one concern. Each component has one responsibility.

3. **Organize into cells** -- isolate failures. One feature failing should not affect another. External service failing should queue, not block.

4. **Build guardrails, not walls** -- automation as the standard; human judgment only where required. Hooks enforce standards automatically.

5. **Automate complexity away** -- repeated manual processes are automation candidates. The pipeline automates the entire code review and validation process.

6. **Observe everything** -- unobserved systems lead to unknown costs and unknown failures. Every external call gets a log entry. Every error boundary reports.

**The Frugal Architect's 7 Laws (Vogels 2023):**

| Phase | Law | Application |
|---|---|---|
| Design | Cost is a non-functional requirement | Database query costs, API fees, compute limits are design inputs |
| Design | Systems that last align cost to business | Revenue must exceed infrastructure costs |
| Design | Architecting is a series of trade-offs | Document trade-offs in ADRs explicitly |
| Measure | Unobserved systems lead to unknown costs | Track vendor usage, API call volume |
| Measure | Cost awareness per tier | Auth calls cheap; storage per-GB; compute per-invocation |
| Optimize | Cost optimization is incremental | Optimize the bottleneck first, not everything |
| Optimize | Question assumptions | "We need real-time updates" -- do we? Polling may be 95% cheaper |

---

## 13. Testing Pyramid

**Origin:** Mike Cohn (Succeeding with Agile), adapted by Martin Fowler

**Ratio: 60% Unit / 30% Integration / 10% E2E**

```
                    +---------------------+
                    |   E2E (Playwright)  |  <- 10%, critical user journeys
                   +------------------------+
                   | Integration (test + DB) |  <- 30%, API routes + DB
                  +---------------------------+
                  |         Unit (test)        |  <- 60%, business logic
                  +---------------------------+
```

**Layer Contents:**

*Unit (60%):*
- Business logic calculations
- Policy/rule validation
- Data transformation utilities
- Date/time utilities
- All pure functions with no external dependencies

*Integration (30%):*
- API route handlers (mocked or test database)
- Webhook handlers (mocked provider events)
- Auth middleware
- Database query functions

*E2E (10%):*
- User onboarding flow
- Core transaction flow (search -> select -> action -> payment)
- Session/lifecycle management
- Critical failure paths (what users see when payment fails)

**Decision Template:** "Where does this new test belong? If it tests pure logic, unit. If it tests an API boundary, integration. If it tests a user journey, E2E."

**Anti-pattern:** Inverted pyramid (mostly E2E, few units). Flaky E2E tests treated as acceptable.

---

## 14. Technology Radar

**Origin:** Thoughtworks Technology Radar (quarterly publication)

**Four Categories:**

**Adopt** (use now -- proven and mature):
- Your core stack technologies

**Trial** (evaluate on a real feature -- promising):
- Technologies with evidence of benefit but not yet proven in your context

**Assess** (research, not production):
- Technologies worth watching but not ready for real features

**Hold** (not now -- over-engineering for current scale):
- Technologies that solve problems you do not yet have

**Hold Criteria:** Technology goes to Hold when: (a) it solves a problem not yet at scale, (b) operational burden exceeds benefit at current traffic, or (c) a simpler alternative handles 95% of the need.

---

## 15. Circuit Breaker Pattern

**Origin:** Michael Nygard (Release It!, 2007)

**State Machine:**
```
CLOSED --(failures exceed threshold)--> OPEN
   ^                                       |
   +--(probe succeeds)-- HALF_OPEN <--(timeout expires)--+
```

- **CLOSED**: Normal operation, requests pass through
- **OPEN**: Too many failures, requests short-circuit immediately with fallback
- **HALF_OPEN**: Probe state -- one request allowed through to test recovery

**Application:**
- Database connection failures -> circuit breaker -> return cached data
- Payment API failures -> circuit breaker -> show "temporarily unavailable"
- External API failures -> circuit breaker -> fall back to alternative view
- Agent re-spawn loop -> 3 failures = circuit open, escalate

**Decision Template:** "How many consecutive failures before we stop trying? What does the user see in OPEN state?"

---

## 16. Exponential Backoff with Jitter

**Origin:** AWS Builder's Library (Timeouts, Retries, and Backoff with Jitter)

**Pattern:**
```typescript
async function retryWithBackoff<T>(
  fn: () => Promise<T>,
  maxRetries = 3,
  baseDelay = 1000
): Promise<T> {
  for (let attempt = 0; attempt <= maxRetries; attempt++) {
    try {
      return await fn();
    } catch (error) {
      if (attempt === maxRetries) throw error;
      const jitter = Math.random() * 0.3; // +/-30% jitter
      const delay = baseDelay * Math.pow(2, attempt) * (0.85 + jitter);
      await new Promise(resolve => setTimeout(resolve, delay));
    }
  }
  throw new Error('Unreachable');
}
```

**Why Jitter Matters:** Without jitter, all clients that failed at the same time retry at the same time, creating a thundering herd that takes the service down again. Jitter spreads retries across time.

**Application:**
- All payment API calls: retry with backoff on 5xx errors
- Database queries on transient connection errors
- Webhook delivery retries
- Agent re-spawn delays between attempts

---

## Code Quality Standards

### TypeScript Strict Mode

`tsconfig.json` with `"strict": true` enables:

| Check | Why It Matters |
|---|---|
| `strictNullChecks` | Prevents `null` from queries being passed to non-null functions -- most common runtime error source |
| `noImplicitAny` | Forces explicit typing on all external data (API responses, database rows) |
| `strictFunctionTypes` | Prevents unsafe callback type widening -- catches event handler bugs |
| `noUncheckedIndexedAccess` | Forces checking before array/object access -- prevents `undefined.field` crashes |

### Zod Validation Placement

**Rule:** Validate at API boundaries, not at internal function boundaries.

```
External data enters -> [Zod schema.parse()] -> Typed domain objects -> [No Zod needed]
```

**Where Zod goes:**
- All API route handlers: validate request body before database access
- Webhook handlers: validate after signature verification before database writes
- Real-time event handlers: validate payload before processing

**Where Zod does NOT go:**
- Internal service functions between trusted boundaries
- Data already validated at the entry point

### RLS as Security Primitive

**The CTO security review question:** "If I remove all authorization checks from this API route, what database policies still protect the data?" If the answer is "nothing," that route is dangerous regardless of application-layer checks.

RLS is the architectural decision that makes multi-tenant security tractable. Without it, every API route must implement its own authorization check. With it, the database enforces authorization regardless of application code bugs.

---

## VP Evaluation Rubric

**How CTO evaluates pipeline output:**

| Dimension | Green | Yellow | Red |
|---|---|---|---|
| Feature definition | PR/FAQ clear, user value obvious | Described technically, not by user need | No clear user benefit |
| Architecture fit | Follows existing patterns | Minor deviation with explanation | New unintentional complexity |
| Failure handling | All external calls handle failure | Some cases handled, others TODO | No failure handling |
| Test coverage | Unit + integration + E2E for new journeys | Unit only, integration missing | No tests |
| Technical debt | No new debt, or explicitly documented | Undocumented shortcuts | Hidden complexity that compounds |
| Security | RLS + validation + no hardcoded secrets | One category missing | RLS bypass or hardcoded secrets |

**"Werner Vogels Would Ship This" Test:**
1. Is every external call handled for failure?
2. Is there observability (can you know when this breaks in production)?
3. Does the code own its production behavior (monitoring, runbook, rollback)?
4. Is the blast radius of a failure contained?

All four yes -> ship it.

---

## CTO Escalation to CEO

**Escalation required when:**

| Trigger | Example |
|---|---|
| Security breach or data loss risk | Authorization misconfiguration exposing user data |
| Vendor failure with business impact | Payment provider blocking all payouts |
| Architecture decision with significant budget impact | Migrating database providers |
| Technology affecting product positioning | Adding AI capabilities that change product category |
| Infrastructure affecting data residency | Moving servers to different jurisdiction |

**Escalation Template:**
```
SITUATION: {what happened or what decision is needed}
IMPACT: {what breaks or costs if we don't act}
OPTIONS: {2-3 concrete options with cost/risk}
RECOMMENDATION: {what I recommend and why}
DECISION NEEDED BY: {date -- technical urgency}
```

---

## Sources

- [Everything Fails All the Time -- Communications of the ACM](https://cacm.acm.org/opinion/everything-fails-all-the-time/)
- [You Build It, You Run It -- ACM Queue (Vogels, 2006)](https://queue.acm.org/detail.cfm?id=1142065)
- [Working Backwards -- All Things Distributed (Vogels, 2006)](https://www.allthingsdistributed.com/2006/11/working_backwards.html)
- [Amazon Two-Pizza Teams -- AWS Executive Insights](https://aws.amazon.com/executive-insights/content/amazon-two-pizza-team/)
- [Undifferentiated Heavy Lifting -- Vogels](https://www.linkedin.com/pulse/eliminating-undifferentiated-heavy-lifting-jimmy-ray)
- [The Frugal Architect -- thefrugalarchitect.com](https://thefrugalarchitect.com/)
- [Simplexity: Vogels AWS re:Invent 2024](https://www.rackspace.com/blog/highlights-aws-reinvent-keynote-dr-werner-vogels-2024)
- [DORA Metrics Guide -- dora.dev](https://dora.dev/guides/dora-metrics/)
- [ADR Templates -- adr.github.io](https://adr.github.io/adr-templates/)
- [Technical Debt -- Martin Fowler's bliki](https://martinfowler.com/bliki/TechnicalDebt.html)
- [Rule of Three -- Wikipedia](https://en.wikipedia.org/wiki/Rule_of_three_(computer_programming))
- [Timeouts, Retries and Backoff with Jitter -- AWS Builder's Library](https://aws.amazon.com/builders-library/timeouts-retries-and-backoff-with-jitter/)
- [Cell-Based Architecture -- AWS Well-Architected](https://docs.aws.amazon.com/wellarchitected/latest/reducing-scope-of-impact-with-cell-based-architecture/what-is-a-cell-based-architecture.html)
- [Thoughtworks Technology Radar FAQ](https://www.thoughtworks.com/en-us/radar/faq)
