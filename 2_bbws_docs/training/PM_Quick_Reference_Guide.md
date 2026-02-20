# Project Management Quick Reference Guide
## For Junior Engineers - One-Page Cheat Sheet

**Keep this handy for your daily work!**

---

## The 5-Minute PM Checklist

Before starting ANY task (even small ones):

- [ ] **What** needs to be done? (Clear objective)
- [ ] **Why** are we doing this? (Business value)
- [ ] **Who** is involved? (Stakeholders, team)
- [ ] **When** is it due? (Deadline, milestones)
- [ ] **How** will we know it's done? (Acceptance criteria)
- [ ] **What** could go wrong? (Top 3 risks)

**5 minutes of planning saves hours of rework!**

---

## WBS: Breaking Down Work

```
1. Start with the END GOAL
   ↓
2. What are the MAJOR PHASES?
   ↓
3. What DELIVERABLES per phase?
   ↓
4. What TASKS create each deliverable?
   ↓
5. Stop when tasks are 4-40 hours
```

**Example**:
```
Fix Login Bug
├── 1. Investigate
│   ├── 1.1 Reproduce bug
│   ├── 1.2 Review logs
│   └── 1.3 Identify root cause
├── 2. Fix
│   ├── 2.1 Code fix
│   └── 2.2 Write unit test
└── 3. Deploy
    ├── 3.1 Code review
    ├── 3.2 Test in staging
    └── 3.3 Deploy to prod
```

---

## RACI: Who Does What?

| Role | What They Do | Example |
|------|--------------|---------|
| **R**esponsible | Does the work | Developer writes code |
| **A**ccountable | Final approval (only ONE) | Tech Lead approves merge |
| **C**onsulted | Provides input | Security team reviews design |
| **I**nformed | Kept in the loop | PM notified when deployed |

**Golden Rules**:
- Every task needs exactly **ONE A**
- Every task needs at least **ONE R**
- Too many Cs = slow decisions
- Too many Is = email spam

---

## Risk Management in 3 Steps

### Step 1: Identify Risks
Ask: "What could go wrong?"
- Technical risks (bugs, performance)
- Resource risks (people unavailable)
- External risks (vendor delays)

### Step 2: Score Risks
```
Score = Probability (1-3) × Impact (1-3)

9 🔴 CRITICAL → Escalate now
7-8 🟠 HIGH → Mitigate actively
4-6 🟡 MEDIUM → Have a plan
1-3 🟢 LOW → Monitor only
```

### Step 3: Mitigate
- **Avoid**: Change plan to eliminate
- **Mitigate**: Reduce probability or impact
- **Accept**: Monitor, but no action
- **Transfer**: Insurance, outsource

**Example**:
- Risk: "Database export might fail" (Prob: Med, Impact: High = 6 🟡)
- Mitigation: "Test export in dev first, have backup plan"

---

## Status Tracking Made Easy

### Daily:
Update your task status:
- ⏳ NOT STARTED → 🟡 IN PROGRESS → 🟢 COMPLETE
- If blocked: 🔴 BLOCKED (and tell someone!)

### Weekly:
Answer these 3 questions:
1. **What did I complete this week?**
2. **What am I working on next week?**
3. **Any blockers or risks?**

### Traffic Lights:
- 🟢 **GREEN**: On track, no issues
- 🟡 **YELLOW**: Minor issue, monitoring
- 🔴 **RED**: Major issue, need help

**When to escalate**: Red status, or 2+ weeks yellow

---

## Communication Rules

### Choose the Right Channel:

| Urgency | Channel | Response Time |
|---------|---------|---------------|
| **NOW** | Call/Slack DM | Immediate |
| **Today** | Slack message | <4 hours |
| **This week** | Email | <24 hours |
| **FYI** | Weekly report | No response needed |

### Status Update Template:
```
Subject: [Project] Weekly Update - [GREEN/YELLOW/RED]

This week:
✅ Completed: Task A, Task B
🔄 In progress: Task C (60% done)
🚧 Blocked: Task D (waiting for X)

Next week:
📅 Task E, Task F

Risks:
⚠️ Risk 1 - Mitigation: ABC
```

---

## Testing Priorities

### Test Case Priority:
- **P0 (Critical)**: Must work for launch
  - Core features (login, payment, forms)
  - Data integrity, security

- **P1 (High)**: Must work for release
  - All main features
  - Performance targets

- **P2 (Medium)**: Should work, can defer
  - Edge cases
  - Non-critical features

- **P3 (Low)**: Nice to have
  - Enhancements
  - Cosmetic issues

### Go/No-Go Criteria:
✅ **GO**: Zero P0 defects, <3 P1 defects
❌ **NO-GO**: Any P0 defect

---

## Estimation Tips

### Estimation Checklist:
- [ ] Break task into subtasks (easier to estimate small things)
- [ ] Compare to similar past work ("like X, which took Y")
- [ ] Add buffer for unknowns (+20% known, +50% unknown, +100% very unknown)
- [ ] Track actual vs estimate (learn and improve)

### Common Pitfalls:
- ❌ Forgetting testing time (add 30-50% for testing)
- ❌ Forgetting review/approval time (add 10-20%)
- ❌ Assuming perfect conditions (add buffer for interruptions)
- ❌ Not accounting for dependencies (waiting time)

### Get Better:
Track every task:
```
Task: Fix login bug
Estimated: 4 hours
Actual: 6 hours
Variance: +50%
Why: Underestimated debugging time
Next time: Add +50% for debugging
```

---

## Meeting Types

### Daily Standup (15 min):
- **Purpose**: Sync, identify blockers
- **Format**: Each person: Yesterday, Today, Blockers
- **Rule**: No problem-solving (take offline)

### Weekly Status (30 min):
- **Purpose**: Progress update, risk review
- **Format**: What's done, what's next, issues
- **Attendees**: Team + PM

### Sprint Planning (2 hours):
- **Purpose**: Plan next sprint
- **Format**: Review backlog, estimate, commit
- **Attendees**: Full team

### Retrospective (1 hour):
- **Purpose**: Learn and improve
- **Format**: What went well, what didn't, actions
- **Rule**: Blameless, focus on process

---

## Quality Gates

### Before Starting:
- [ ] Requirements clear and documented
- [ ] Design reviewed and approved
- [ ] Dependencies identified

### During Development:
- [ ] Code follows standards
- [ ] Unit tests written (>80% coverage)
- [ ] Code reviewed by peer

### Before Deployment:
- [ ] All P0 tests passed
- [ ] Performance meets targets
- [ ] Security scan passed
- [ ] Stakeholder sign-off received

**Don't skip quality gates!** They catch issues early when they're cheap to fix.

---

## Common PM Mistakes to Avoid

### ❌ Mistake: "I'll just start coding"
**✅ Fix**: Spend 5-10 min planning first

### ❌ Mistake: "I'll update status later"
**✅ Fix**: Update task status immediately when you start/finish

### ❌ Mistake: "I don't want to bother people"
**✅ Fix**: Communicate blockers ASAP (they'd rather know early)

### ❌ Mistake: "It's mostly working, ship it"
**✅ Fix**: Follow testing checklist, meet quality criteria

### ❌ Mistake: "I can do everything"
**✅ Fix**: Ask for help when stuck >2 hours

### ❌ Mistake: "This will be quick" (famous last words)
**✅ Fix**: Estimate realistically, add buffer

---

## PM Vocabulary

**Must-Know Terms**:

| Term | Definition | Example |
|------|------------|---------|
| **Scope** | What's included in the project | "Migrate database and files" |
| **Deliverable** | Tangible output | "Migrated website" |
| **Milestone** | Key event, zero duration | "Go-live date" |
| **Dependency** | Task B needs Task A first | "Can't deploy before testing" |
| **Blocker** | Something preventing progress | "Waiting for API key" |
| **Stakeholder** | Anyone affected by project | "Business owner, users" |
| **Acceptance Criteria** | How we know it's done | "All forms submit successfully" |
| **Critical Path** | Longest chain of tasks | Determines minimum duration |
| **Buffer** | Extra time for unknowns | +20% for uncertainty |
| **Scope Creep** | Uncontrolled scope growth | "Can we also add...?" |

---

## PM Principles for Daily Work

### 1. Plan Before You Execute
"Measure twice, cut once"
- 10 min planning > 1 hour fixing

### 2. Make Work Visible
"If it's not tracked, it doesn't exist"
- Update Jira/task status daily

### 3. Communicate Proactively
"No surprises"
- Share blockers immediately
- Regular status updates

### 4. Manage Risks Early
"Hope is not a strategy"
- Identify what could go wrong
- Have a plan B

### 5. Define Done
"What does success look like?"
- Clear acceptance criteria
- Quality standards

### 6. Learn and Improve
"Fail fast, learn faster"
- Document lessons learned
- Adjust process based on data

---

## Your PM Toolkit

### Templates:
- [ ] WBS template (hierarchical task breakdown)
- [ ] RACI matrix template (responsibility assignment)
- [ ] Risk register template (risk tracking)
- [ ] Status report template (weekly update)
- [ ] Testing checklist template (quality gates)

**All available**: `PM_Migration_Plan_AuPairHive.md`

### Tools:
- **Jira/GitHub Projects**: Task tracking
- **Confluence/Notion**: Documentation
- **Slack**: Team communication
- **Google Sheets**: Simple tracking
- **Miro**: Visual planning

### Resources:
- **PMBOK Guide**: PM bible (PMI.org)
- **Atlassian PM Hub**: Free templates and guides
- **ProjectManagement.com**: Articles and forums
- **#project-management** Slack: Ask questions

---

## Quick Decision Tree

### "Should I create a full PM plan?"

```
Is task >1 week? ──YES──> Full PM plan (WBS, RACI, risks, schedule)
     │
     NO
     ↓
Is task >1 day? ──YES──> Simple plan (task list, timeline, risks)
     │
     NO
     ↓
Is task >1 hour? ──YES──> Quick plan (objective, steps, done criteria)
     │
     NO
     ↓
Just do it (but track in Jira)
```

### "Should I escalate?"

```
Is it blocking critical path? ──YES──> Escalate NOW
     │
     NO
     ↓
Is it delayed >1 day? ──YES──> Escalate to PM
     │
     NO
     ↓
Is it >10% over budget? ──YES──> Escalate to PM
     │
     NO
     ↓
Monitor and update in next status report
```

---

## Personal PM Habits

### Daily:
- [ ] Update task statuses (morning)
- [ ] Attend standup (if applicable)
- [ ] Communicate blockers immediately
- [ ] Review tomorrow's tasks (end of day)

### Weekly:
- [ ] Send status update (Friday)
- [ ] Review upcoming milestones
- [ ] Update risk register
- [ ] Plan next week's tasks

### Monthly:
- [ ] Review estimation accuracy (actual vs planned)
- [ ] Update personal lessons learned
- [ ] Read 1 PM article/chapter
- [ ] Share 1 PM tip with team

### Quarterly:
- [ ] Retrospective on completed projects
- [ ] Update PM toolkit/templates
- [ ] Set PM skill development goals

---

## Remember

### The 80/20 Rule:
- 20% of planning prevents 80% of problems
- 20% of risks cause 80% of issues
- 20% of features deliver 80% of value

### The Golden Triangle:
```
    Scope
      △
     /|\
    / | \
   /  |  \
  /   |   \
 /____|____\
Time    Budget
```
**Change one, affects the others**

### PM is a Journey:
- ✅ Start small (apply one technique at a time)
- ✅ Practice continuously (every project is learning)
- ✅ Track and improve (measure, adjust)
- ✅ Share knowledge (teach others)
- ✅ Be patient (mastery takes time)

---

## Your PM Action Plan

### This Week:
1. Read full PM plan (`PM_Migration_Plan_AuPairHive.md`)
2. Create WBS for current task
3. Update task status daily
4. Ask one PM question in Slack

### This Month:
1. Use RACI for team project
2. Create risk register for upcoming work
3. Write weekly status updates
4. Track estimation accuracy

### This Quarter:
1. Lead small project with PM principles
2. Mentor another junior
3. Document lessons learned
4. Improve planning accuracy by 20%

---

## Quick Help

### Stuck? Ask Yourself:
- What's the **objective**? (Am I solving the right problem?)
- What's the **plan**? (Do I know the steps?)
- What's **blocking** me? (Can I remove it or escalate?)
- Who **needs to know**? (Should I communicate this?)
- Is this **good enough**? (Does it meet acceptance criteria?)

### Need Help?
1. **Jira comment**: Tag relevant person
2. **Slack**: #project-management channel
3. **PM/Tech Lead**: 1-on-1 or standup
4. **This guide**: Re-read relevant section

### Before Asking:
- What have I tried?
- What specifically am I stuck on?
- What do I need to proceed?

---

**Keep this guide handy!**
**Print it, bookmark it, refer to it often.**

**PM is a skill you build one project at a time.** 🚀

---

**Questions?**
- Slack: #project-management
- Email: [pm-email]
- Office Hours: [schedule]

**Good luck!**
