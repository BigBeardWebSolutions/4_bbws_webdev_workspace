# Enrollment Management Skill

**Skill Type**: School Administration
**Version**: 1.0.0
**Parent Agent**: School Learner Instructor (Headmaster Assistant)

---

## Skill Overview

Comprehensive student enrollment processing, registration management, records maintenance, and student information system (SIS) administration for efficient school operations.

---

## Capabilities

### 1. Enrollment Processing
- New student registration
- Returning student re-enrollment
- Transfer student intake
- Grade placement and assignment
- Document verification
- Eligibility determination

### 2. Records Management
- Student demographic data
- Academic history
- Health and immunization records
- Emergency contact information
- Special education documentation
- Discipline records

### 3. Student Information System (SIS)
- Data entry and updates
- Report generation
- Data validation
- System integration
- Access management
- Data archiving

---

## Enrollment Workflows

### New Student Enrollment Workflow

```
Step 1: Application Submission
├── Receive completed enrollment application
├── Verify required documents submitted
│   ├── Birth certificate
│   ├── Immunization records
│   ├── Previous school transcripts
│   ├── Proof of residency
│   └── Emergency contact form
└── Schedule registration appointment

Step 2: Registration Interview
├── Meet with parent/guardian
├── Review application and documents
├── Verify student eligibility
│   ├── Age requirements
│   ├── Residency verification
│   └── Immunization compliance
├── Discuss school policies and expectations
└── Collect additional information

Step 3: Student Placement
├── Review academic history
├── Assess grade level placement
├── Identify special needs or services
│   ├── Special education
│   ├── English language learner (ELL)
│   ├── Gifted and talented
│   └── 504 accommodations
└── Assign to appropriate grade/program

Step 4: System Entry
├── Create student record in SIS
├── Assign unique student ID
├── Enter demographic information
├── Upload scanned documents
├── Set up parent portal access
└── Generate enrollment confirmation

Step 5: Classroom Assignment
├── Review class rosters and capacity
├── Balance class sizes
├── Consider special needs
├── Assign homeroom teacher
├── Schedule appropriate classes
└── Notify teacher and parent

Step 6: Orientation
├── Schedule new student orientation
├── Provide school tour
├── Issue student materials (ID, handbook, etc.)
├── Explain school procedures
├── Answer parent questions
└── Set start date
```

---

### Transfer Student Workflow

```
1. Contact previous school
   ├── Request official transcripts
   ├── Request withdrawal documentation
   └── Verify attendance and discipline records

2. Review academic records
   ├── Determine appropriate grade placement
   ├── Identify credits earned
   ├── Review standardized test scores
   └── Assess graduation progress (high school)

3. Transition support
   ├── Schedule counselor meeting
   ├── Create academic plan
   ├── Identify support services needed
   └── Assign peer buddy if appropriate

4. Complete enrollment process
   (Same as new student enrollment Steps 4-6)
```

---

### Re-Enrollment Workflow (Returning Students)

```
1. Annual data verification
   ├── Confirm current contact information
   ├── Update emergency contacts
   ├── Verify address (residency)
   └── Review health information

2. Update immunization records
   ├── Check for required boosters
   ├── Request updated records if needed
   └── Ensure compliance with state requirements

3. Course selection (secondary)
   ├── Review transcript and credits
   ├── Plan course schedule
   ├── Check prerequisites
   └── Submit course requests

4. System updates
   ├── Promote to next grade level
   ├── Update SIS with current information
   ├── Generate new class schedules
   └── Confirm re-enrollment
```

---

## Document Checklist

### Required Documents

#### All Students
- [ ] Completed enrollment application
- [ ] Birth certificate (original or certified copy)
- [ ] Immunization records (state-required vaccinations)
- [ ] Proof of residency (utility bill, lease agreement, etc.)
- [ ] Emergency contact form
- [ ] Photo ID of parent/guardian
- [ ] Custody documentation (if applicable)

#### Transfer Students (Additional)
- [ ] Official transcripts from previous school
- [ ] Withdrawal letter from previous school
- [ ] Standardized test scores
- [ ] IEP or 504 plan (if applicable)
- [ ] Discipline records

#### Special Circumstances
- [ ] Special education evaluation (IEP students)
- [ ] English language proficiency assessment (ELL)
- [ ] Homeless student verification (McKinney-Vento)
- [ ] Foster care documentation
- [ ] Military family documentation

---

## Student Information System (SIS) Management

### Core SIS Functions

#### 1. Student Demographics
```
Required Fields:
- Legal name (first, middle, last)
- Date of birth
- Gender
- Race/ethnicity (for reporting)
- Primary language
- Home address
- Phone number(s)
- Email address (parent/guardian)
- Emergency contacts (min. 2)
```

#### 2. Enrollment Information
```
- Student ID number
- Grade level
- Homeroom/advisory
- Enrollment date
- Entry code (new, transfer, returning)
- Enrollment status (active, withdrawn, graduated)
- School of attendance
- Previous schools attended
```

#### 3. Academic Records
```
- Current schedule
- Course history
- Grades and transcripts
- Credits earned
- GPA (cumulative and term)
- Standardized test scores
- Attendance records
- Discipline incidents
```

#### 4. Health Information
```
- Immunization records
- Allergies and medical conditions
- Medications
- Special health needs
- Physician contact
- Health insurance information
```

#### 5. Program Participation
```
- Special education (IEP)
- 504 accommodations
- English language learner (ELL)
- Gifted and talented
- Free/reduced lunch
- Athletics and extracurriculars
```

---

## Data Validation Rules

### Critical Validations
1. **Unique Student ID**: No duplicates allowed
2. **Birth Date**: Must be logical for grade level
3. **Required Fields**: Cannot be blank
4. **Contact Information**: At least one valid phone/email
5. **Immunization Compliance**: Met before first day
6. **Residency**: Verified within district boundaries
7. **Parent/Guardian**: At least one on file

### Data Quality Checks
```
Run monthly:
- Missing or incomplete records
- Duplicate student records
- Invalid email/phone formats
- Students with no emergency contacts
- Inactive students still in active classes
- Students with incomplete immunizations
```

---

## Reporting

### Enrollment Reports

#### Daily/Weekly Reports
- New enrollments
- Withdrawals
- Transfers (in/out)
- Pending enrollments

#### Monthly Reports
- Enrollment by grade level
- Enrollment by program (SPED, ELL, etc.)
- Enrollment trends (YoY comparison)
- Projected enrollment vs. actual

#### Annual Reports
- October 1 enrollment count (state reporting)
- End-of-year enrollment
- Retention rates
- Demographic breakdown

---

## Withdrawal Process

### Student Withdrawal Workflow

```
1. Parent/guardian notification
   ├── Submit written withdrawal request
   ├── Specify reason for withdrawal
   ├── Provide forwarding school information
   └── Schedule exit interview (optional)

2. Records preparation
   ├── Generate unofficial transcript
   ├── Collect textbooks and materials
   ├── Clear library and cafeteria balances
   ├── Return student property
   └── Deactivate student ID card

3. Official records transfer
   ├── Wait for records request from new school
   ├── Prepare official transcript
   ├── Include immunization records
   ├── Include IEP/504 if applicable
   ├── Send via secure method
   └── Document transfer date

4. System updates
   ├── Change enrollment status to "withdrawn"
   ├── Set withdrawal date
   ├── Enter withdrawal code/reason
   ├── Remove from class rosters
   └── Deactivate parent portal access

5. Archival
   ├── Archive student records
   ├── Maintain per retention policy
   └── Update cumulative folder
```

---

## Residency Verification

### Acceptable Proof of Residency

#### Category 1: Property Ownership
- Property tax statement
- Mortgage statement
- Deed or settlement paperwork

#### Category 2: Rental/Lease
- Current lease agreement
- Rent receipt

#### Category 3: Utility Bills (Two required)
- Electric bill
- Gas bill
- Water/sewer bill
- Landline phone bill
- Cable/internet bill

**Note**: Cell phone bills typically NOT accepted

#### Special Circumstances
- **Homeless/McKinney-Vento**: No residency required
- **Foster Care**: Foster care placement documentation
- **Living with Relatives**: Affidavit of residence + host family proof
- **Military**: Military orders + temporary housing documentation

---

## Best Practices

### ✅ DO:
1. Verify all documents before enrollment
2. Maintain accurate, up-to-date records
3. Protect student privacy (FERPA)
4. Communicate clearly with families
5. Follow established enrollment procedures
6. Document all decisions and exceptions
7. Respond to enrollment inquiries promptly
8. Maintain organized filing system

### ❌ DON'T:
1. Enroll students without proper documentation
2. Share student information inappropriately
3. Make enrollment decisions based on discriminatory factors
4. Delay processing enrollments
5. Lose or misplace student records
6. Ignore data quality issues
7. Fail to update contact information

---

## Compliance & Legal

### FERPA (Family Educational Rights and Privacy Act)
- Protect student education records
- Obtain consent before releasing records
- Maintain secure storage
- Limit access to authorized personnel

### State Enrollment Requirements
- Age eligibility (typically 5 years old for kindergarten)
- Residency verification
- Immunization compliance
- Birth certificate verification

### Special Populations
- **Special Education**: IDEA compliance, timely IEP implementation
- **ELL Students**: Title III requirements, language assessment
- **Homeless Students**: McKinney-Vento immediate enrollment
- **Foster Care**: Education stability provisions

---

## Integration Points

### Systems Integration
- **Student Information System (SIS)**: PowerSchool, Infinite Campus, etc.
- **Parent Portal**: Family access to student information
- **State Reporting System**: Enrollment counts, demographics
- **Health Records System**: Immunization tracking
- **Transportation**: Bus routing based on address
- **Food Services**: Free/reduced lunch eligibility

---

## Common Scenarios

### Scenario 1: Mid-Year Transfer
```
Student transfers mid-year from another district.

Actions:
1. Complete enrollment application
2. Request records from previous school
3. Assign to appropriate grade/classes
4. Schedule counselor meeting
5. Create transition plan
6. Monitor adjustment first 30 days
```

### Scenario 2: Address Change (Boundary Transfer)
```
Family moves outside school boundary.

Actions:
1. Verify new address
2. Determine if boundary transfer required
3. Check new school capacity
4. Process transfer request
5. Update SIS with new address
6. Coordinate transition
```

### Scenario 3: Incomplete Immunizations
```
Student enrolls without complete immunizations.

Actions:
1. Allow conditional enrollment (per state law)
2. Provide immunization schedule
3. Set deadline for compliance (typically 30 days)
4. Track and follow up
5. Exclude from school if not compliant by deadline
6. Allow re-enrollment upon compliance
```

---

## Version History

| Version | Date | Changes |
|---------|------|---------|
| 1.0.0 | 2025-12-21 | Initial skill creation |

---

**Skill Status**: Active
**Last Updated**: 2025-12-21
