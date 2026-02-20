# Project Management Exercise Workbook
## Hands-On Practice for Junior Engineers

**Name**: _______________________
**Date**: _______________________
**Group**: ______________________

---

## Exercise 1: Create a Work Breakdown Structure (WBS)

### Scenario:
You need to migrate a simple blog from WordPress.com to a self-hosted WordPress installation on AWS.

**Given Information**:
- Blog has 50 posts, 200 images (total ~500 MB)
- 1,000 visitors/month
- Uses contact form plugin (Contact Form 7)
- Custom theme (no premium theme)
- Current host: WordPress.com (shared hosting)
- Target host: AWS EC2 with WordPress
- Constraint: Maximum 1 hour downtime allowed

### Your Task:
Create a WBS with at least 3 levels (Project → Phases → Tasks)

**WBS Template**:
```
Blog Migration Project
│
├── 1.0 ________________________
│   ├── 1.1 ________________________
│   ├── 1.2 ________________________
│   └── 1.3 ________________________
│
├── 2.0 ________________________
│   ├── 2.1 ________________________
│   ├── 2.2 ________________________
│   └── 2.3 ________________________
│
├── 3.0 ________________________
│   ├── 3.1 ________________________
│   ├── 3.2 ________________________
│   └── 3.3 ________________________
│
├── 4.0 ________________________
│   ├── 4.1 ________________________
│   └── 4.2 ________________________
│
└── 5.0 ________________________
    ├── 5.1 ________________________
    └── 5.2 ________________________
```

**Hints**:
- What needs to happen before migration? (Planning, preparation)
- What needs to be exported from WordPress.com?
- What needs to be set up on AWS?
- How will you test before going live?
- What happens during the actual cutover?

**Time**: 10 minutes

---

### WBS Self-Check:

After completing your WBS, check:
- [ ] Did I include planning/preparation phase?
- [ ] Did I include data export tasks?
- [ ] Did I include AWS infrastructure setup?
- [ ] Did I include testing tasks?
- [ ] Did I include cutover/go-live tasks?
- [ ] Are tasks small enough (4-40 hours each)?
- [ ] Did I number tasks hierarchically?
- [ ] Did I include documentation?

**Discussion Questions**:
1. Which phase do you think will take the longest?
2. Which tasks are on the critical path?
3. What did you forget to include (if anything)?

---

## Exercise 2: Build a RACI Matrix

### Scenario (continued):
For the blog migration, assign RACI roles for key tasks.

**Team Members**:
- **You** (Junior Engineer): Will do the technical work
- **Tech Lead**: Senior engineer who reviews and approves
- **Blog Owner**: The person who owns the blog (your "client")
- **AWS Support**: External AWS technical support

### Your Task:
Fill in the RACI matrix below

| Task | You | Tech Lead | Blog Owner | AWS Support |
|------|-----|-----------|------------|-------------|
| **Define migration requirements** | | | | |
| **Export blog data from WordPress.com** | | | | |
| **Set up AWS EC2 instance** | | | | |
| **Install WordPress on AWS** | | | | |
| **Import blog data** | | | | |
| **Configure DNS** | | | | |
| **Test migrated site** | | | | |
| **Get approval to go live** | | | | |
| **Update DNS to point to AWS** | | | | |
| **Monitor post-migration** | | | | |

**Remember**:
- **R** = Responsible (does the work)
- **A** = Accountable (final approval) - only ONE per task!
- **C** = Consulted (provides input)
- **I** = Informed (kept in the loop)

**Time**: 8 minutes

---

### RACI Self-Check:

After completing your RACI matrix, check:
- [ ] Every task has exactly ONE "A"
- [ ] Every task has at least ONE "R"
- [ ] Did I use "C" sparingly (not everyone needs to be consulted on everything)?
- [ ] Did I use "I" appropriately (who really needs to be informed)?

**Discussion Questions**:
1. Who has the most "R" assignments? Does that make sense?
2. Who has the most "A" assignments? Is it appropriate?
3. For which tasks did you struggle to assign roles?

---

## Exercise 3: Identify and Score Risks

### Scenario (continued):
What could go wrong with the blog migration?

### Your Task:
Identify at least 5 risks and score them

**Risk Register Template**:

| # | Risk Description | Probability (1-3) | Impact (1-3) | Score | Priority |
|---|------------------|-------------------|--------------|-------|----------|
| R1 | | | | | |
| R2 | | | | | |
| R3 | | | | | |
| R4 | | | | | |
| R5 | | | | | |

**Probability Scale**:
- 1 = Low (10-30% chance)
- 2 = Medium (40-60% chance)
- 3 = High (70-90% chance)

**Impact Scale**:
- 1 = Low (minimal impact, easy recovery)
- 2 = Medium (moderate impact, some delay/cost)
- 3 = High (major impact, significant delay/cost)

**Score = Probability × Impact**

**Priority Legend**:
- 1-3 = 🟢 LOW (Monitor)
- 4-6 = 🟡 MEDIUM (Mitigation plan needed)
- 7-8 = 🟠 HIGH (Active mitigation)
- 9 = 🔴 CRITICAL (Escalate)

**Hints**: Think about:
- Data loss during export/import?
- Plugin compatibility issues?
- DNS propagation delays?
- Performance degradation?
- Downtime exceeding 1 hour?

**Time**: 10 minutes

---

### Risk Mitigation Planning:

Pick your **highest-scoring risk** and create a mitigation plan:

**Risk ID**: R___

**Risk Statement**:
_________________________________________________________________
_________________________________________________________________

**Mitigation Strategy** (How to reduce probability or impact):
_________________________________________________________________
_________________________________________________________________
_________________________________________________________________

**Contingency Plan** (What to do if it happens anyway):
_________________________________________________________________
_________________________________________________________________
_________________________________________________________________

**Owner** (Who's responsible for this risk): ______________________

---

## Exercise 4: Create a Testing Checklist

### Scenario (continued):
Before you can go live, what needs to be tested?

### Your Task:
Create a testing checklist with at least 15 test cases, prioritized as P0, P1, P2, or P3.

**Testing Checklist Template**:

### P0 (Critical - Must Pass for Go-Live):
- [ ] 1. _____________________________________________________
- [ ] 2. _____________________________________________________
- [ ] 3. _____________________________________________________
- [ ] 4. _____________________________________________________
- [ ] 5. _____________________________________________________

### P1 (High - Must Pass for Release):
- [ ] 6. _____________________________________________________
- [ ] 7. _____________________________________________________
- [ ] 8. _____________________________________________________
- [ ] 9. _____________________________________________________
- [ ] 10. ____________________________________________________

### P2 (Medium - Should Pass, Can Defer):
- [ ] 11. ____________________________________________________
- [ ] 12. ____________________________________________________
- [ ] 13. ____________________________________________________

### P3 (Low - Nice to Have):
- [ ] 14. ____________________________________________________
- [ ] 15. ____________________________________________________

**Hints**: Consider testing:
- Basic functionality (page loads, navigation)
- Content integrity (all posts, images)
- Contact form functionality
- Performance (page load times)
- SEO (URLs, meta tags)
- Mobile responsiveness

**Time**: 8 minutes

---

### Testing Self-Check:

- [ ] Did I include basic functionality tests (homepage, navigation)?
- [ ] Did I include data integrity tests (all posts, images present)?
- [ ] Did I include form testing (contact form submits)?
- [ ] Did I include performance tests (page load time)?
- [ ] Did I include security tests (HTTPS, SSL)?
- [ ] Are my P0 tests truly critical for go-live?
- [ ] Did I over-prioritize (not everything can be P0)?

**Discussion Question**:
If you only had time to run 5 tests before go-live, which would they be?

---

## Exercise 5: Build a Project Timeline

### Scenario (continued):
You have **2 weeks (10 working days)** to complete the blog migration.

### Your Task:
Create a high-level timeline showing what happens when.

**Timeline Template**:

```
Week 1:
┌─────┬─────┬─────┬─────┬─────┐
│ Mon │ Tue │ Wed │ Thu │ Fri │
├─────┼─────┼─────┼─────┼─────┤
│     │     │     │     │     │
│     │     │     │     │     │
│     │     │     │     │     │
└─────┴─────┴─────┴─────┴─────┘

Week 2:
┌─────┬─────┬─────┬─────┬─────┐
│ Mon │ Tue │ Wed │ Thu │ Fri │
├─────┼─────┼─────┼─────┼─────┤
│     │     │     │     │     │
│     │     │     │     │     │
│     │     │     │     │     │
└─────┴─────┴─────┴─────┴─────┘
```

**Fill in each day with 1-3 tasks from your WBS**

**Key Milestones** (mark with ⭐):
- Planning complete: Day _____
- AWS setup complete: Day _____
- Data migrated: Day _____
- Testing complete: Day _____
- Go-live: Day _____

**Time**: 10 minutes

---

### Timeline Self-Check:

- [ ] Did I allocate time for planning?
- [ ] Did I sequence tasks logically (can't import before export)?
- [ ] Did I include testing time (don't skip this!)?
- [ ] Did I buffer time for issues (not everything goes smoothly)?
- [ ] Did I identify the critical path?
- [ ] Is go-live scheduled for the last day? (Risky!)

**Discussion Questions**:
1. What's your critical path (longest chain of dependent tasks)?
2. Where did you add buffer time?
3. What happens if something takes longer than expected?

---

## Exercise 6: Write a Status Update

### Scenario:
It's Friday of Week 1. You've completed some tasks, but hit a blocker.

**Situation**:
- ✅ Completed: Planning, WBS, Risk assessment
- ✅ Completed: Exported blog data from WordPress.com
- 🔄 In Progress: Setting up AWS EC2 instance (70% complete)
- 🚧 Blocked: Cannot install WordPress on AWS because EC2 instance won't start (permission issue)
- 📅 Upcoming: Import data, configure DNS, testing

**Your Task**:
Write a status update email to your Tech Lead

**Email Template**:

```
To: tech-lead@company.com
Subject: [Blog Migration] Week 1 Status Update - [GREEN/YELLOW/RED]

Hi [Tech Lead Name],

[One sentence summary of the week]

Progress This Week:
✅ Completed:
-
-

🔄 In Progress:
-

🚧 Blocked:
-

Planned for Next Week:
📅
-
-

Risks & Issues:
⚠️
-

Next Milestone: _________________ (Target: ______)

[Your name]
```

**Fill in the email above**

**Time**: 5 minutes

---

### Status Update Self-Check:

- [ ] Did I clearly state overall status (GREEN/YELLOW/RED)?
- [ ] Did I list completed work (celebrate progress!)?
- [ ] Did I highlight the blocker prominently?
- [ ] Did I state what I need to unblock?
- [ ] Did I outline next week's plan?
- [ ] Is it concise (can be read in <2 minutes)?
- [ ] Did I avoid jargon (would a non-technical person understand)?

**Discussion Questions**:
1. What status color did you choose (GREEN/YELLOW/RED)? Why?
2. How urgent is the blocker? Should you escalate?
3. What could you have done to avoid the blocker?

---

## Exercise 7: Go/No-Go Decision

### Scenario:
It's Friday of Week 2 (go-live day). Time to decide: Do we go live or not?

**Situation**:

**Testing Results**:
- ✅ P0 Tests: 4/5 passed (1 failed: contact form not working)
- ✅ P1 Tests: 8/10 passed (2 failed: minor layout issues)
- ⚠️ P2 Tests: 2/5 passed (3 failed: mobile responsive issues)

**Performance**:
- Homepage load time: 3.5 seconds (target was <3s)
- AWS instance is stable

**Risks**:
- Contact form plugin may have compatibility issue (investigating)
- DNS propagation may take 2-4 hours (expected)

**Stakeholder Input**:
- Blog Owner: "Contact form is critical, we get 10-20 submissions per week"
- Tech Lead: "We can fix the form issue, but it might take another day"

### Your Task:
Make a Go/No-Go decision and justify it.

**Decision**: [ ] GO  [ ] NO-GO

**Justification** (Why did you make this decision?):
_________________________________________________________________
_________________________________________________________________
_________________________________________________________________
_________________________________________________________________

**If NO-GO, what needs to be fixed before we can go live?**:
_________________________________________________________________
_________________________________________________________________

**If GO, what's the plan for the contact form issue?**:
_________________________________________________________________
_________________________________________________________________

**Time**: 5 minutes

---

### Go/No-Go Discussion:

**Standard Criteria**:
- ✅ GO if: Zero P0 defects, <3 P1 defects (with workarounds)
- ❌ NO-GO if: Any P0 defect, >3 P1 defects, critical functionality broken

**In this scenario**:
- **P0 failure**: Contact form (business-critical)
- **P1 failures**: Layout issues (can live with temporarily)
- **P2 failures**: Mobile (not ideal but not blocking)

**Discussion Questions**:
1. What did you decide?
2. What's the risk of going live with a broken contact form?
3. What's the cost of delaying go-live by 1 day?
4. How would you communicate your decision to the Blog Owner?

---

## Exercise 8: Lessons Learned

### Scenario:
The migration is complete! Time to reflect and learn.

**What Happened**:
- Actual duration: 11 days (1 day over)
- Main delay: Contact form compatibility issue (took 1 extra day)
- Unexpected issue: DNS propagation was faster than expected (1 hour vs 4 hours)
- Go-live went smoothly, no downtime issues

### Your Task:
Complete a lessons learned reflection

**What Went Well**:
1. _____________________________________________________________
2. _____________________________________________________________
3. _____________________________________________________________

**What Didn't Go Well**:
1. _____________________________________________________________
2. _____________________________________________________________
3. _____________________________________________________________

**Root Causes** (Why did things go wrong?):
_________________________________________________________________
_________________________________________________________________

**What Would You Do Differently Next Time?**:
1. _____________________________________________________________
2. _____________________________________________________________
3. _____________________________________________________________

**Key Takeaways** (1-2 sentences):
_________________________________________________________________
_________________________________________________________________

**Time**: 5 minutes

---

## Bonus Exercise: Estimation Practice

### Scenario:
You're asked to estimate how long it would take to add a **newsletter signup form** to the migrated blog.

**Requirements**:
- Add a simple email signup form to the blog sidebar
- Integrate with Mailchimp API
- Add confirmation email functionality
- Test on desktop and mobile

### Your Task:
Estimate the effort using three different methods

**Method 1: Analogous (Compare to Similar Work)**
"This is similar to ___________________ which took _____ hours"
My estimate: _____ hours

**Method 2: Three-Point Estimate**
- Optimistic (best case): _____ hours
- Most Likely: _____ hours
- Pessimistic (worst case): _____ hours
- Formula: (Optimistic + 4×Most Likely + Pessimistic) ÷ 6 = _____ hours

**Method 3: Bottom-Up (Break Down and Sum)**
- Design form HTML/CSS: _____ hours
- Mailchimp API integration: _____ hours
- Confirmation email setup: _____ hours
- Testing (desktop): _____ hours
- Testing (mobile): _____ hours
- Documentation: _____ hours
- **Total**: _____ hours

**Final Estimate** (with 20% buffer): _____ hours

**Time**: 7 minutes

---

## Exercise Summary & Reflection

### What did you learn from these exercises?

**Most Challenging Exercise**: _____________________________________
**Why**: _________________________________________________________

**Most Useful Skill Learned**: ______________________________________
**How will you apply it**: __________________________________________

**Key Insight** (1 sentence):
_________________________________________________________________

**One PM Practice You'll Start Using This Week**:
_________________________________________________________________

---

## Answer Key & Discussion Notes

*To be filled in during the group discussion*

### Exercise 1: WBS - Sample Answer
**Instructor Notes**:
_________________________________________________________________
_________________________________________________________________

### Exercise 2: RACI - Sample Answer
**Instructor Notes**:
_________________________________________________________________
_________________________________________________________________

### Exercise 3: Risks - Sample Answer
**Common risks identified by group**:
_________________________________________________________________
_________________________________________________________________

### Exercise 4: Testing - Sample Answer
**Critical P0 tests**:
_________________________________________________________________
_________________________________________________________________

### Exercise 5: Timeline - Sample Answer
**Typical timeline**:
_________________________________________________________________
_________________________________________________________________

### Exercise 6: Status Update - Sample Answer
**Good example**:
_________________________________________________________________
_________________________________________________________________

### Exercise 7: Go/No-Go - Sample Answer
**Recommended decision**:
_________________________________________________________________
_________________________________________________________________

### Exercise 8: Lessons Learned - Sample Answer
**Key themes**:
_________________________________________________________________
_________________________________________________________________

---

## Post-Exercise Action Plan

### This Week, I will:
- [ ] _________________________________________________________
- [ ] _________________________________________________________
- [ ] _________________________________________________________

### This Month, I will:
- [ ] _________________________________________________________
- [ ] _________________________________________________________

### Questions to Ask My Mentor:
1. _____________________________________________________________
2. _____________________________________________________________
3. _____________________________________________________________

---

## Feedback on This Workbook

**What worked well**:
_________________________________________________________________

**What could be improved**:
_________________________________________________________________

**Additional exercises you'd like to see**:
_________________________________________________________________

---

**Thank you for participating!**

**Remember**: PM is a skill you build through practice. Use these exercises as templates for your real projects.

**Questions? Reach out!**
- Slack: #project-management
- Email: [instructor-email]
