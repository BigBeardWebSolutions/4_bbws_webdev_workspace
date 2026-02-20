# Grade Calculator Skill

**Skill Type**: Assessment & Grading
**Version**: 1.0.0
**Parent Agent**: Teacher Agent

---

## Skill Overview

Advanced grade calculation, weighting, statistical analysis, and grading policy implementation for accurate and fair student assessment.

---

## Capabilities

### 1. Grade Calculation Methods
- **Simple Average**: Arithmetic mean of all assignments
- **Weighted Average**: Categories weighted by percentage (e.g., tests 40%, homework 20%, quizzes 20%, projects 20%)
- **Point-Based**: Total points earned / total points possible
- **Standards-Based**: Mastery level for each standard
- **Custom Weighting**: Flexible weighting schemes

### 2. Statistical Analysis
- Class average, median, mode
- Standard deviation
- Grade distribution
- Percentile rankings
- Trend analysis (improvement over time)

### 3. Grading Policies
- Drop lowest score(s)
- Extra credit handling
- Late work penalties
- Missing assignment policies
- Reassessment and retake policies

---

## Workflows

### Standard Grade Calculation
```
1. Gather all assignment scores for student
2. Identify grading method (weighted, point-based, etc.)
3. Apply category weights if applicable
4. Apply grading policies (drop lowest, late penalties)
5. Calculate final grade
6. Convert to letter grade based on scale
7. Round according to policy
8. Record in gradebook
```

### Class Performance Analysis
```
1. Calculate all student grades
2. Compute class statistics (mean, median, std dev)
3. Generate grade distribution histogram
4. Identify outliers (high/low performers)
5. Compare to previous assessments
6. Generate insights report
7. Recommend instructional adjustments
```

### Individual Student Grade Projection
```
1. Review current grade
2. Identify remaining assignments and weights
3. Calculate minimum scores needed for target grade
4. Generate "what-if" scenarios
5. Create grade improvement plan
6. Present to student/parent
```

---

## Grade Calculation Examples

### Example 1: Weighted Average
```python
Categories:
- Tests: 40%
- Quizzes: 20%
- Homework: 20%
- Projects: 20%

Student Scores:
- Tests: [85, 90, 78] → Average: 84.3
- Quizzes: [92, 88, 95, 90] → Average: 91.25
- Homework: [100, 95, 100, 90, 85] → Average: 94
- Projects: [88, 92] → Average: 90

Calculation:
(84.3 × 0.40) + (91.25 × 0.20) + (94 × 0.20) + (90 × 0.20)
= 33.72 + 18.25 + 18.8 + 18 = 88.77

Final Grade: 89% (B+)
```

### Example 2: Standards-Based Grading
```
Standards:
1. Solve linear equations: Proficient (3/4)
2. Graph functions: Advanced (4/4)
3. Word problems: Developing (2/4)
4. Systems of equations: Proficient (3/4)

Overall Mastery: (3 + 4 + 2 + 3) / 4 = 3.0 (Proficient)
```

---

## Grading Policies Implementation

### Drop Lowest Score
```python
Quiz scores: [75, 88, 92, 68, 85]
Policy: Drop lowest quiz
Adjusted scores: [88, 92, 85]  # Dropped 68
Average: 88.3
```

### Late Work Penalty
```python
Assignment score: 90
Days late: 2
Policy: 5% deduction per day, max 2 days
Penalty: 10%
Final score: 90 × 0.90 = 81
```

### Missing Assignment Handling
```python
Policy Options:
1. Zero (0 points)
2. Minimum score (50 points to avoid skewing average)
3. Incomplete (I) until submitted
4. Allow make-up with penalty

Recommendation: Use minimum score (50) to maintain grade accuracy
```

---

## Grade Scales

### Traditional Letter Grade Scale
```
A:  93-100%
A-: 90-92%
B+: 87-89%
B:  83-86%
B-: 80-82%
C+: 77-79%
C:  73-76%
C-: 70-72%
D+: 67-69%
D:  63-66%
D-: 60-62%
F:  0-59%
```

### Standards-Based Scale
```
4 - Advanced: Exceeds standard
3 - Proficient: Meets standard
2 - Developing: Approaching standard
1 - Beginning: Below standard
```

---

## Statistical Formulas

### Mean (Average)
```
Mean = Sum of all scores / Number of scores
```

### Median
```
Middle value when scores are arranged in order
If even number of scores, average of two middle values
```

### Standard Deviation
```
1. Calculate mean
2. Find deviation of each score from mean
3. Square each deviation
4. Calculate mean of squared deviations (variance)
5. Take square root of variance
```

---

## Best Practices

1. **Communicate grading policies clearly** at start of term
2. **Be consistent** in applying policies
3. **Record grades promptly** after assessment
4. **Verify accuracy** before publishing
5. **Provide grade breakdowns** to students
6. **Allow grace period** for grade disputes
7. **Use data to inform instruction**
8. **Maintain gradebook backups**

---

## Common Use Cases

### Use Case 1: Calculate Quarter Grade
```
Request: "Calculate quarter 2 grades for all students"

Process:
1. Load all assignments for quarter 2
2. Apply weighted grading scheme
3. Apply grading policies
4. Calculate grades for all students
5. Generate grade distribution
6. Identify students at risk (< 70%)
7. Export to SIS
```

### Use Case 2: What-If Scenario
```
Request: "Student has 76%, what does he need on final exam (30% of grade) to get a B (80%)?"

Calculation:
Current: 76% (70% of final grade)
Target: 80%
Needed: (80 - 76×0.70) / 0.30 = (80 - 53.2) / 0.30 = 89.3%

Answer: Student needs 89.3% on final exam to achieve 80% overall (B)
```

---

## Integration

- **Gradebook Software**: PowerSchool, Infinite Campus, Google Classroom
- **Spreadsheet Export**: Excel, Google Sheets
- **Reporting**: PDF, CSV formats
- **SIS Integration**: Automated grade posting

---

## Version History

| Version | Date | Changes |
|---------|------|---------|
| 1.0.0 | 2025-12-21 | Initial skill creation |

---

**Skill Status**: Active
**Last Updated**: 2025-12-21
