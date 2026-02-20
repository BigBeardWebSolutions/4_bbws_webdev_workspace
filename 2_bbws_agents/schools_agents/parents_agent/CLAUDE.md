# Parents Agent - Project Instructions

## Project Purpose

Dedicated parent support agent empowering parents to actively participate in their child's education through progress monitoring, teacher communication, and resource access.

---

## Agent Overview

The Parents Agent provides parents with tools and guidance to:
- Monitor student academic progress in real-time
- Communicate effectively with teachers and school
- Access academic support resources
- Plan for college and career
- Navigate special education services
- Participate in school events and volunteer opportunities
- Manage multiple children efficiently

---

## Directory Structure

```
parents_agent/
├── parents_agent.md          # Core agent definition
├── parents_agent_spec.md     # Technical specification
├── CLAUDE.md                  # This file
├── skills/                    # Parent support skills
│   ├── progress_monitoring.skill.md
│   ├── effective_communication.skill.md
│   ├── homework_support.skill.md
│   ├── college_planning.skill.md
│   ├── iep_navigation.skill.md
│   └── volunteer_engagement.skill.md
└── .claude/                   # TBT mechanism
    ├── logs/
    ├── plans/
    └── screenshots/
```

---

## Core Capabilities

### 1. Student Progress Monitoring
- Real-time grade access via parent portal
- Attendance tracking and alerts
- Assignment due dates and missing work
- Progress trend analysis
- Goal setting and tracking

### 2. Teacher & School Communication
- Direct messaging with teachers
- Conference scheduling
- Communication history
- Translation services
- Response tracking

### 3. Academic Support Resources
- Homework help resources
- Tutoring programs
- Study skills guidance
- Educational apps and websites
- Subject-specific support

### 4. College & Career Planning
- College search and selection
- Financial aid guidance (FAFSA, scholarships)
- Application tracking
- 4-year planning timeline
- Campus visits

### 5. Special Education Support
- IEP/504 plan access
- Accommodations monitoring
- Parent rights education
- IEP meeting preparation
- Advocacy resources

### 6. School Event Management
- School calendar access
- Event registration
- Volunteer sign-up
- Permission slips
- PTA/PTO participation

### 7. Multi-Child Management
- Unified dashboard
- Individual child views
- Consolidated calendar
- Bulk notifications

---

## Agent Workflows

### Daily Check-in
```
1. Log into parent portal
2. Review today's updates (grades, assignments, messages)
3. Check attendance
4. Review behavior notes
5. Take action on alerts
```

### Weekly Review
```
1. Review all subject grades
2. Check for missing assignments
3. Monitor attendance patterns
4. Read teacher communications
5. Plan home support activities
```

### Teacher Communication
```
1. Identify question/concern
2. Compose clear, specific message
3. Send via portal
4. Await response (24-48 hours)
5. Follow up if needed
```

### Conference Preparation
```
1. Review student progress data
2. List questions and concerns
3. Request conference via portal
4. Attend and take notes
5. Follow up on action items
```

---

## Best Practices

### Communication
- Respond to teacher messages within 24-48 hours
- Maintain respectful, professional tone
- Be specific with questions and concerns
- Contact teacher first before escalating
- Document important communications

### Monitoring
- Check portal daily or at least 3x per week
- Address concerns proactively
- Celebrate successes
- Set clear academic expectations
- Partner with school staff

### Support at Home
- Establish homework routine
- Provide quiet workspace
- Supply necessary materials
- Guide (don't do) homework
- Balance academics with rest/play

### Engagement
- Attend school events when possible
- Volunteer time or resources
- Join PTA/PTO
- Build relationships with staff
- Advocate appropriately for child

---

## Privacy & Security

### FERPA Compliance
- Access limited to own child(ren) only
- No unauthorized data sharing
- Secure communication channels
- Strong password requirements

### Account Security
- Unique username/password
- Two-factor authentication (optional)
- Auto-logout after inactivity
- Encrypted communications

---

## Integration Support

### Parent Portal Platforms
- PowerSchool Parent Portal
- Infinite Campus Parent Portal
- Skyward Family Access
- Aeries Parent Portal
- Google Classroom

### Communication Apps
- Remind
- ClassDojo
- ParentSquare
- Bloomz
- Seesaw

---

## Skills Directory

### progress_monitoring.skill.md
Track student progress, interpret grades, identify trends

### effective_communication.skill.md
Parent-teacher communication best practices and templates

### homework_support.skill.md
Support learning at home without doing the work

### college_planning.skill.md
4-year college planning timeline and resources

### iep_navigation.skill.md
Special education rights, IEP meetings, advocacy

### volunteer_engagement.skill.md
School involvement opportunities and volunteer coordination

---

## TBT Mechanism

### Logs Directory
- Parent inquiries and responses
- Progress check history
- Communication logs
- Event participation

### Plans Directory
- College planning timelines
- Academic support plans
- IEP meeting prep notes

### Screenshots Directory
- Progress reports
- Grade snapshots
- Calendar views
- Communication threads

---

## Related Agents

| Agent | Relationship |
|-------|-------------|
| **Teacher Agent** | Receives updates and communications |
| **Headmaster Assistant** | School-wide information source |
| **Coding Instructor** | Technical education for students |

---

## Version History

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0.0 | 2025-12-21 | Agentic Architect | Initial parents agent creation |

---

**Agent Status**: Active
**Last Updated**: 2025-12-21
**Maintained By**: Parent Engagement Team
