# COO Operational Decision-Making Frameworks

> Comprehensive reference for the COO agent. Each framework includes origin, core principle, generic application, decision template, and anti-pattern.
> Sources: Tim Cook (Apple), Keith Rabois (Square/Opendoor), Jeff Wilke (Amazon), Sheryl Sandberg (Meta), Elad Gil (High Growth Handbook), Eli Goldratt (Theory of Constraints), Taiichi Ohno (Toyota)
> Target path in project: docs/executive/shared/frameworks/coo-frameworks.md

---

## 1. "Barrels and Ammunition" -- Keith Rabois

**Origin:** Rabois's most famous operational concept, developed across PayPal, LinkedIn, Square, and Opendoor. Taught at Stanford CS183.

**Core Principle:** An organization's output is limited by its number of barrels, NOT its total headcount. A barrel is someone (or an agent) that can take an idea from concept to shipped product end-to-end. Ammunition is someone who executes well on defined tasks but needs direction. Adding more ammunition to a barrel-constrained system does not increase output -- it increases coordination overhead.

**Agent System Mapping:**

```
BARRELS (limit throughput):
  Pipeline orchestrator   -- owns full feature pipeline end-to-end
  Wave orchestrator       -- owns parallel execution pipeline
  Grade orchestrator      -- owns full grading pipeline

AMMUNITION (execute within barrel scope):
  Feature developer       -- writes code within orchestrator direction
  QA agent                -- runs tests within validation stage
  Security reviewer       -- audits security within validation stage
  Code reviewer           -- reviews code within validation stage
```

**Application:**
- System throughput = number of active barrels. To ship more, create more barrels.
- Every new pipeline (with its own barrel agent) multiplies capacity.
- Diagnostic question: "Is the bottleneck a barrel shortage or an ammunition quality problem?"
- Barrel identification test: Give an agent an ambiguous task. If it defines scope, coordinates, and ships without clarification requests -- it is a barrel.

**Anti-Patterns:**
- Adding more developers when the orchestrator is the bottleneck
- Creating ammunition agents without a barrel to direct them
- Confusing "busy" (high utilization) with "productive" (high throughput)

---

## 2. "Inventory is Evil" -- Tim Cook

**Origin:** Tim Cook's operational philosophy at Apple. When he joined in 1998, Apple had months of inventory. He reduced it to 5-7 days (vs. industry average 25-30 days).

**Core Principle:** Inventory is a depreciating asset. In tech, products lose ~1-2% of value per week sitting unsold. Applied to software: undeployed code is inventory. Open PRs are inventory. WIP branches are inventory. Every moment code sits unmerged, it accrues merge conflict risk, becomes stale against main, and blocks dependent work.

**Agent System Mapping:**

```
MANUFACTURING INVENTORY        AGENT SYSTEM INVENTORY
-------------------------------  --------------------------------
Raw materials in warehouse     Unstarted backlog tasks
Work-in-progress on floor      Open branches / uncommitted code
Finished goods unsold          Open PRs awaiting review or merge
Channel inventory in stores    Deployed but unmonitored features

METRIC                         TARGET
Open PRs > 3 days old          0 (WARNING at 1, CRITICAL at 3)
WIP branches per developer     <= 1
Backlog-to-deployment cycle    < 5 days for STANDARD tasks
Unmerged worktree branches     0 after wave completion
```

**Just-In-Time Applied to Branches (Cook):**
- Create branches only when work begins (not "just in case")
- Merge branches within hours of completion, not days
- Delete branches immediately after merge
- Worktree branches are factory floor WIP -- clear them aggressively

**Application:**
- Weekly inventory audit: count open PRs, WIP branches, stale worktrees
- Treat any PR > 3 days old as a blocked constraint requiring intervention
- "Close the books in hours" -- wave completion should produce merged, verified, deployed code, not lingering branches

**Anti-Patterns:**
- "We'll merge it later" mentality
- Creating speculative branches for work not yet started
- Keeping worktree branches alive after completion "just in case"
- Batching merges instead of continuous flow

---

## 3. Theory of Constraints (TOC) -- Eliyahu Goldratt

**Origin:** Eli Goldratt's "The Goal" (1984). The most widely applied operational optimization framework.

**Core Principle:** Every system has exactly one constraint (bottleneck) that limits total throughput. Optimizing anything other than the constraint is waste. The 5-step cycle runs continuously; fixing one bottleneck immediately reveals the next.

**5-Step Cycle:**

```
Step 1: IDENTIFY the constraint
  What single factor limits system throughput right now?
  Diagnostic: Where does work pile up? Where do agents wait?

Step 2: EXPLOIT the constraint
  Maximize output of the bottleneck WITHOUT adding resources.
  Example: If BUILD is the bottleneck, ensure the developer never waits
  for task context. Pre-load manuals, patterns, plan before spawning.
  Example: If QA is the bottleneck, ensure every PR that reaches QA
  has already passed lint + typecheck (pre-filter waste).

Step 3: SUBORDINATE everything to the constraint
  Align all non-bottleneck processes to serve the bottleneck.
  If BUILD is the bottleneck, DON'T push more PRs into VALIDATE --
  that just creates inventory (Cook's principle). Slow PR creation
  to match build capacity.

Step 4: ELEVATE the constraint
  Add capacity to the bottleneck. This is the expensive step.
  Example: Run parallel developers in worktrees.
  Example: Upgrade agent model for the bottleneck stage.
  Only do this AFTER Steps 2-3 are exhausted.

Step 5: REPEAT
  The old constraint is resolved. A new one appears. Find it.
  Common sequence: BUILD -> QA -> REVIEW -> MERGE -> DEPLOY
```

**Application:**
- Run constraint analysis before every wave execution
- Parallel execution IS an elevation of the BUILD constraint
- Monitor where work queues form between pipeline stages
- Never invest in non-bottleneck optimization

**Anti-Patterns:**
- Optimizing QA speed when BUILD is the bottleneck (waste)
- Adding more validators when there is nothing to validate (barrel shortage)
- Skipping Steps 2-3 and jumping directly to Step 4 (throwing resources at problems)

---

## 4. "Mechanisms > Good Intentions" -- Jeff Wilke / Amazon

**Origin:** Jeff Wilke's operational insight at Amazon. Good intentions fail at scale. Mechanisms automatically produce good outcomes without relying on individual judgment or memory.

**Core Principle:** If a behavior is important enough to write in an agent's instructions, it is important enough to enforce with a hook. Agent instructions are "good intentions." Hooks are "mechanisms." The system's true rules are defined by what is enforced, not what is written.

**Mechanism Taxonomy (Agent System):**

```
MECHANISM TYPE          EXAMPLE                              ENFORCEMENT
----------------------  -----------------------------------  ----------------
Pre-check gate          QA must pass before validation        PreToolUse hook
Automated validation    TypeScript strict, lint, build        CI pipeline
Isolation boundary      Worktree per team, storage per role   Hook + git
Emergency stop          Andon cord -- halt wave on failure    Wave supervisor
Post-mortem trigger     COE document after every failure      SubagentStop hook
Reporting protocol      Mandatory report sections             SubagentStop hook
Layer discipline        Agents cannot spawn outside layer     PreToolUse hook
```

**Andon Cord (Amazon/Toyota) Applied:**
- Any monitoring agent observation of a failing team can trigger wave halt
- Wave supervisor can pause a team without waiting for approval
- Hotfix developer can be spawned immediately on critical failure
- Decision rule: If the cost of stopping (delayed feature) < cost of continuing (broken code merged to main), pull the cord. Almost always, stopping is cheaper.

**COE (Correction of Error) Process:**

```
After every significant operational failure:
1. Write the COE document (Five Whys)
2. Identify root cause (not proximate cause)
3. Propose a MECHANISM to prevent recurrence
4. "We'll try harder" is NOT a valid mechanism
5. The mechanism must be a hook, a pipeline change, or an agent modification
6. Track implementation of the mechanism
```

**Application:**
- Audit: For every rule in CLAUDE.md, is there a hook enforcing it?
- Gap analysis: Rules without hooks are aspirational, not enforced
- Every post-mortem produces a mechanism, not a promise
- Mechanisms are the COO's primary output (not reports, not plans)

**Anti-Patterns:**
- Adding agent instructions without hooks ("good intentions")
- Responding to failures with "agents should be more careful"
- Creating processes that require agents to remember multi-step sequences
- Manual quality gates that depend on an agent choosing to check

---

## 5. Editing Model -- Keith Rabois

**Origin:** Rabois's framework for the COO's management style. The COO is an editor, not a writer.

**Core Principle:** Agents (teams) write the first draft. The COO edits: simplifies, clarifies, ensures consistency with strategy. Editing levels indicate organizational maturity.

**Editing Levels (most to least intervention):**

```
LEVEL        WHEN                    COO ACTION                    HEALTH SIGNAL
--------     ----------------------  ----------------------------  ----------------
Rewrite      Draft is fundamentally  Reject and re-brief with     Hiring problem
             wrong                   full context                 (wrong agent)

Structural   Ideas right, approach   Reorganize pipeline stages,  Early-stage team
             wrong                   change agent composition     or new pipeline

Line Edit    Approach right, details Adjust parameters, fix edge  Growth mode
             need refinement         cases, tune thresholds       (healthy)

Copy Edit    Minor corrections only  Grammar-level fixes to       Mature pipeline
                                     reports, formatting          (ideal state)
```

**Application:**
- Track editing level per pipeline over time. Should trend toward Copy Edit.
- If a pipeline requires Rewrite-level edits more than twice, the barrel agent needs replacement or fundamental redesign.
- If COO is doing Line Edits on every wave, the pipeline is not learning -- create a mechanism (skill or hook) to encode the repeated edit.

**Anti-Patterns:**
- COO writing the first draft (doing agents' work)
- Staying at Rewrite level without changing the agent
- Editing every detail instead of creating mechanisms to handle recurring patterns
- Not tracking the editing trend (no learning feedback loop)

---

## 6. Lean Principles -- Toyota Production System

**Origin:** Taiichi Ohno's Toyota Production System, adapted by Wilke at Amazon, applied to software by Lean Startup methodology.

**5 Principles Applied to Agent Operations:**

```
PRINCIPLE       DEFINITION                           APPLICATION
-----------     ---------------------------------    ------------------------------------------
1. Value        Define value from customer            User-facing features that work correctly
                perspective                           = value. Infrastructure, refactoring,
                                                      agent improvements = enabling, not value.

2. Value Stream Map entire process from idea           Idea -> Task doc -> Agent assignment
                to delivery                           -> Code -> Test -> Review -> Deploy
                                                      -> Monitor. Map every step.

3. Flow         Work flows continuously               CI pipeline has no flaky tests blocking.
                without interruption                  Agent handoffs are clean. No "waiting
                                                      for approval" bottlenecks. Pull-based.

4. Pull         Produce only what is needed,           Agents pull work from backlog based on
                when needed                           priority. No pre-built features "we
                                                      might need." WIP limits enforced.

5. Perfection   Continuously improve toward            Regular retrospectives. Track and reduce
                zero waste                            failure rates. Improve skill definitions
                                                      from observed outcomes. Kaizen cycle.
```

**Value Stream Map Template:**

```
Idea -> PLAN -> BUILD -> QA -> VALIDATE -> UX POLISH -> MERGE -> DEPLOY
 |       |       |       |       |           |           |         |
 v       v       v       v       v           v           v         v
Wait   Write   Code    Test    Review      Browse      Git       Deploy
time   time    time    time    time        time        time      time

MEASURE: Lead Time = sum of all step durations
MEASURE: Process Time = sum of only value-adding steps
MEASURE: Efficiency = Process Time / Lead Time
TARGET: Efficiency > 60% (< 40% of time is wait/waste)
```

**Application:**
- Map the value stream for each pipeline at least quarterly
- Identify the step with the longest wait time (that is the constraint)
- Enforce WIP limits: no more than 2 active tasks per agent
- Pull-based scheduling: agents pull from prioritized backlog, not pushed

---

## 7. Weekly Business Review (WBR) -- Jeff Wilke / Amazon

**Origin:** Amazon's Weekly Business Review, the operational heartbeat of the company. Every team reviews metrics against plan every Monday. This is a mechanism, not a meeting.

**Core Principle:** Variance from plan must be explained with root cause analysis weekly. The WBR forces accountability by making performance visible. No team can hide declining metrics for more than 7 days.

**WBR Structure:**

```
SECTION 1: Metrics vs. Plan
  | Metric                  | Plan  | Actual | Variance | Root Cause |
  |-------------------------|-------|--------|----------|------------|
  | Build success rate      | >95%  |        |          |            |
  | Test pass rate          | >98%  |        |          |            |
  | Deployment frequency    | daily |        |          |            |
  | PR merge time (median)  | <24h  |        |          |            |
  | Agent task completion   | >90%  |        |          |            |
  | Wave success rate       | >80%  |        |          |            |

SECTION 2: Andon Events
  List of emergency stops, their cause, and resolution status.

SECTION 3: Constraint Analysis
  Current bottleneck, exploitation status, subordination actions.

SECTION 4: Inventory Check
  Open PRs, WIP branches, stale worktrees, unmerged code.

SECTION 5: Action Items
  Specific actions from this WBR, owner, deadline.
```

**Application:**
- Produce WBR data as part of every operational report
- Variance > 10% from plan requires root cause + proposed mechanism
- Track WBR metrics over time to detect trends before they become crises

---

## 8. "Measure Output Not Input" -- Keith Rabois

**Origin:** Rabois's measurement philosophy. Don't measure hours worked, lines of code, meetings attended. Measure features shipped, bugs fixed, value generated.

**Core Principle:** Every team (and every agent) should have 3-5 key output metrics visible in real-time. If you cannot define the output metric for a team, you do not understand what that team does. Fix that first.

**Dashboard Design:**

```
COMPANY-LEVEL (CEO Dashboard):
  Features shipped this week
  Build success rate
  Test pass rate
  Deployment count
  Active bugs (P0/P1)

PIPELINE-LEVEL (Pipeline Dashboard):
  Cycle time: task start -> merge
  QA pass rate (first attempt)
  Security review pass rate
  UX approval rate
  Rework ratio (fix cycles / total cycles)

WAVE-LEVEL (Parallel Execution Dashboard):
  Teams spawned vs. completed
  Merge conflict count
  Monitoring alert count
  Hotfix deployments
  Total wave duration
  Resources consumed

AGENT-LEVEL (per agent):
  Tasks assigned vs. completed
  Average task duration
  Rework count (re-spawn count)
  Report quality (sections present vs. required)
```

**Application:**
- Define output metrics for every agent before creating it
- Dashboard data drives WBR analysis
- Trend lines matter more than absolute numbers

---

## 9. Supply Chain as Competitive Advantage -- Tim Cook

**Origin:** Cook's transformation of Apple's supply chain from cost center to strategic weapon.

**Agent System Mapping:**

```
SUPPLY CHAIN                    AGENT OPERATIONS
------------------------------  --------------------------------
Suppliers (components)          Vendors (database, payments, hosting)
Component sourcing              Dependency management (packages, APIs)
Factory floor                   CI/CD pipeline
Quality control                 QA + security review + code review
Distribution                    Deployment platform
Retail channel                  Production application

COOK'S PRINCIPLES               APPLICATION
------------------------------  --------------------------------
"Never depend on 1 supplier"    Monitor all vendor health; have fallback plans
"Own what differentiates"       Build core domain logic (matching, domain rules)
"Outsource commodities"         Use managed services (auth, payments, hosting)
"Inventory is evil"             Minimize WIP code, merge fast
"Weekly operational reviews"    WBR mechanism
```

**Vendor Health Monitoring:**

```
VENDOR     DEPENDENCY LEVEL   MONITOR                    FALLBACK
---------  ----------------   -------------------------  ---------------
Database   CRITICAL           API latency, auth uptime   Document exit plan
Payments   CRITICAL           Success rate, latency      Document exit plan
Hosting    HIGH               Deploy success, CDN        Self-host option
Packages   MEDIUM             Audit, lockfile            Pin versions
```

**Application:**
- Classify every external dependency by criticality
- For CRITICAL dependencies with no fallback: monitor aggressively, alert on degradation
- Track vendor costs monthly; flag unexpected spikes

---

## 10. Just-In-Time Applied to Branches -- Tim Cook

**Origin:** Cook's JIT manufacturing philosophy applied to git branching strategy.

**Core Principle:** Branches are factory floor WIP. They depreciate every moment they exist (merge conflicts accumulate, main branch drifts). Create late, merge early, delete immediately.

**Branch Lifecycle Targets:**

```
BRANCH TYPE        CREATE WHEN              MERGE WITHIN     DELETE WITHIN
--------------     ----------------------   ---------------  ---------------
Feature branch     Task starts BUILD        24 hours of      Immediately
                                            validation pass  after merge
Worktree branch    Wave assigns team        Wave completion   Wave cleanup
Hotfix branch      Critical failure found   2 hours           Immediately
```

---

## 11. Platform Engineering -- Internal Developer Platform Concepts

**Origin:** Modern platform engineering practices (Team Topologies, CNCF Platform Engineering WG).

**Core Principle:** The agent system is an Internal Developer Platform (IDP). Development teams are the "developers" consuming the platform. COO is the "platform team" building and maintaining it.

**Four Pillars:**

```
PILLAR             IMPLEMENTATION
-----------------  ---------------------------------------------------
Golden Paths       Feature pipeline is the golden path for development.
                   Parallel pipeline for multi-feature execution.
                   Follow the path and you get quality by default.

Self-Service       Direct coding allows bypassing full pipeline.
                   Escape hatches exist but are monitored.

Guardrails         Hooks are the guardrails. PreToolUse hooks prevent
                   violations. SubagentStop hooks enforce reporting.
                   Guardrails enable speed by removing fear.

Observability      Monitoring agents provide runtime observability.
                   WBR mechanism provides weekly observability.
                   Grade system provides periodic deep observability.
```

**Application:**
- Treat every new hook as a guardrail investment (enables speed, not slows it)
- Treat every new pipeline as a golden path (reduces decision cost)
- Self-service principle: agents should be able to operate without asking COO for help
- Observability principle: COO should know system health at a glance

---

## 12. RACI Matrix for Agent Lifecycle

**Origin:** Standard organizational responsibility model, adapted for agent operations.

**Agent Creation Lifecycle:**

| Activity | CEO | CTO | COO | CHRO |
|---|---|---|---|---|
| Identify need for new agent | I | C | **C** (analyze gap) | **R** |
| Write agent spec | I | C | **C** (recommend metrics) | **R/A** |
| Implement agent file | - | - | - | **R** |
| Review agent quality (grade) | - | - | I | **R/A** |
| Deploy (add to agents/) | - | - | - | **R** |
| Approve team with agent | **A** | I | I | R |
| Post-deployment evaluation | - | I | **C** (metrics analysis) | **R/A** |

**Hook Creation Lifecycle:**

| Activity | CEO | CTO | COO | CHRO |
|---|---|---|---|---|
| Identify enforcement gap | I | I | **R** (analyze) | C |
| Design hook logic | - | C | **C** (recommend mechanism) | **R/A** |
| Implement hook | - | - | - | **R** |
| Verify no workflow breakage | - | C | **C** (metrics impact) | **R/A** |
| Audit hook coverage | - | I | **C** (operational analysis) | **R/A** |

**Key:** R=Responsible, A=Accountable, C=Consulted, I=Informed

---

## 13. COE (Correction of Error) Protocol -- Amazon

**Origin:** Amazon's mandatory post-mortem mechanism, championed by Wilke. Every significant failure produces a COE document.

**Five Whys Structure:**

```
INCIDENT: {description of what went wrong}

WHY 1: {immediate cause}
  WHY 2: {cause of the cause}
    WHY 3: {deeper systemic cause}
      WHY 4: {root organizational cause}
        WHY 5: {fundamental structural cause}

ROOT CAUSE: {the deepest why that, if fixed, prevents recurrence}

MECHANISM: {specific hook, pipeline change, or agent modification}
  NOT ACCEPTABLE: "We'll be more careful"
  NOT ACCEPTABLE: "Agent will remember next time"
  ACCEPTABLE: "Add PreToolUse hook that checks X before Y"
  ACCEPTABLE: "Add QA phase that validates Z"
  ACCEPTABLE: "Modify agent file to include constraint W"

OWNER: {who implements the mechanism}
DEADLINE: {when the mechanism ships}
VERIFICATION: {how we know the mechanism works}
```

**Application:**
- Every wave failure produces a COE
- Every agent re-spawn (indicating first attempt failed) is logged
- Recurring patterns (same failure 3+ times) get escalated to mechanism creation
- COE documents stored in `docs/executive/coo/coe/`

---

## 14. Operational Metrics -- 4-Tier System

**Origin:** Synthesized from Rabois (output measurement), Cook (operational reviews), Wilke (WBR), and DORA (software delivery metrics).

**Tier 1 -- Leading Indicators (measure weekly):**

| Metric | Target | Source | Action if Miss |
|---|---|---|---|
| Build success rate | > 95% | CI pipeline | Fix flaky builds |
| Test pass rate | > 98% | QA reports | Fix flaky tests |
| Deployment frequency | > daily | Deploy log | Unblock pipeline |
| MTTR | < 1 hour | Incident log | Improve hotfix path |
| PR merge time (median) | < 24h | Git log | Clear review backlog |

**Tier 2 -- Quality Indicators (measure weekly):**

| Metric | Target | Source | Action if Miss |
|---|---|---|---|
| Bugs per deployment | < 0.5 | Post-deploy monitor | Strengthen QA stage |
| Agent task completion | > 90% | Task reports | Agent re-brief or fix |
| Code review rejection rate | < 20% | Review reports | Improve BUILD quality |
| Security findings per audit | < 2 | Security reports | Pre-validate patterns |
| Rework ratio | < 15% | Re-spawn / total spawns | Identify root cause |

**Tier 3 -- Efficiency Indicators (measure monthly):**

| Metric | Target | Source | Action if Miss |
|---|---|---|---|
| Resources per feature | Trending down | Usage logs | Optimize prompts |
| Task-to-PR time | < 2 days | Task + git log | Unblock pipeline |
| PR-to-merge time | < 1 day | Git log | Unblock review |
| Wave throughput | Trending up | Wave reports | Optimize grouping |
| Infrastructure cost/feature | Trending down | Vendor billing | Optimize usage |

**Tier 4 -- Strategic Indicators (measure quarterly):**

| Metric | Target | Source | Action if Miss |
|---|---|---|---|
| Features delivered vs. planned | > 80% | OKR tracking | Improve estimation |
| Technical debt trend | Stable or decreasing | CTO reports | Allocate debt sprints |
| Agent system ROI | Positive | Value / cost | Reassess architecture |
| Pipeline maturity (edit level) | Trending toward Copy | Edit level trend | Invest in weakest |

---

## 15. "Predictability Beats Heroics" -- Synthesis

**Origin:** Universal COO principle, expressed differently by every great operations leader.

```
Cook:    "No surprises. Weekly reviews. Real-time dashboards."
Rabois:  "If you need a hero, the system is broken."
Wilke:   "Mechanisms remove the need for heroic individual action."
Sandberg: "Scalable processes work at 10x. Heroics don't."
Gil:     "Great operations are boring."
```

**Core Principle:** A system that requires extraordinary effort to produce ordinary results is a failing system. The COO's job is to make extraordinary results ordinary.

**Diagnostic Questions:**
1. Can a new agent be added to the pipeline without the COO personally supervising?
2. Can a wave run successfully while the COO is not monitoring?
3. Do failures get caught by mechanisms, or only by human observation?
4. Is the system getting better over time without manual intervention?

If any answer is "no," there is a mechanism gap. Fill it.

---

## Summary: The COO's Decision Checklist

For every operational decision, apply in order:

1. **Constraint Check:** "Is this addressing the current bottleneck, or a non-bottleneck?" (TOC)
2. **Inventory Check:** "Does this create WIP? Can we minimize it?" (Cook)
3. **Barrel Check:** "Do we have a barrel for this work, or are we adding ammunition without direction?" (Rabois)
4. **Mechanism Check:** "Is this enforced by a hook/pipeline, or does it rely on agent memory?" (Wilke)
5. **Edit Level Check:** "What editing level does this require? Is that trending in the right direction?" (Rabois)
6. **Output Check:** "What is the measurable output metric? If I can't define it, I don't understand the work." (Rabois)
7. **Predictability Check:** "Does this require heroics, or does it run reliably at scale?" (Synthesis)
