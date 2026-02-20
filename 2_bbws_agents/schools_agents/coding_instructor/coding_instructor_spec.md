# Coding Instructor Agent - Technical Specification

**Version**: 1.0.0
**Created**: 2025-12-21
**Document Type**: Agent Specification
**Parent Agent**: Coding Instructor

---

## 1. Agent Architecture

### 1.1 Agent Identity
```yaml
agent_id: coding_instructor_v1
agent_name: Coding Instructor
agent_type: technical_education
version: 1.0.0
status: active
primary_role: multi_technology_instructor
```

### 1.2 Core Components
```
Coding Instructor
├── Curriculum Manager
│   ├── Level Progression Engine
│   ├── Technology Modules (10)
│   └── Learning Path Generator
├── Code Evaluation Engine
│   ├── Automated Testing
│   ├── Code Quality Analyzer
│   └── Rubric Processor
├── Project Assessment System
│   ├── Project Validator
│   ├── Code Review Bot
│   └── Feedback Generator
├── Practice Platform
│   ├── Exercise Generator
│   ├── Sandbox Environment Manager
│   └── Progress Tracker
├── Certification Manager
│   ├── Mock Exam Generator (PCEP, OCP)
│   ├── Exam Grader
│   └── Certificate Issuer
└── Content Delivery
    ├── Lesson Renderer
    ├── Code Example Manager
    └── Video/Resource Linker
```

---

## 2. Technical Requirements

### 2.1 System Requirements
```yaml
runtime: Python 3.12+
memory: 2GB minimum (for code execution environments)
storage: 5GB for curriculum content and student projects
network: Required for external APIs, sandboxes
```

### 2.2 Dependencies
```python
# Core dependencies
fastapi>=0.109.0        # API framework
uvicorn>=0.27.0         # ASGI server
pydantic>=2.5.0         # Data validation

# Code execution and testing
docker>=7.0.0           # Containerized code execution
pytest>=7.4.0           # Testing framework
pylint>=3.0.0           # Code quality (Python)
eslint>=8.0.0           # Code quality (JavaScript)

# Database and storage
sqlalchemy>=2.0.0       # ORM
redis>=5.0.0            # Caching and session
boto3>=1.28.0           # AWS S3 for project storage

# Content and assessment
nbconvert>=7.12.0       # Jupyter notebook conversion
markdown>=3.5.0         # Markdown rendering
prism>=0.1.0            # Syntax highlighting

# Integration
requests>=2.31.0        # API calls
boto3>=1.28.0           # AWS services
```

### 2.3 Technology-Specific Requirements
```yaml
wordpress:
  - PHP 8.2+
  - WordPress 6.4+
  - MySQL 8.0+
  - Local development: Local, XAMPP, or Docker

react:
  - Node.js 20+
  - npm/yarn
  - Create React App or Vite
  - React Developer Tools

python:
  - Python 3.12+
  - Virtual environments (venv)
  - Jupyter notebooks

java:
  - JDK 17+
  - Maven or Gradle
  - IDE: IntelliJ or Eclipse

aws:
  - AWS CLI
  - AWS SAM CLI
  - Terraform 1.6+
  - Boto3

databases:
  - DynamoDB Local
  - MySQL 8.0+
  - DBeaver or MySQL Workbench
```

---

## 3. Data Models

### 3.1 Student Model
```python
class CodingStudent:
    """Coding student entity"""

    student_id: str
    first_name: str
    last_name: str
    email: str
    github_username: str         # Optional

    # Enrollments
    enrolled_technologies: list[str]  # ['react', 'python', 'aws']
    current_levels: dict[str, int]    # {'react': 2, 'python': 3}

    # Progress
    completed_lessons: list[str]
    completed_projects: list[str]
    certification_status: dict[str, str]  # {'PCEP': 'passed'}

    # Performance
    overall_score: float
    code_quality_score: float
    project_completion_rate: float

    # Metadata
    active: bool = True
    date_enrolled: datetime
    date_last_active: datetime
```

### 3.2 Technology Module Model
```python
class TechnologyModule:
    """Technology curriculum module"""

    module_id: str               # 'react', 'python', 'aws', etc.
    name: str                    # 'React Development'
    description: str
    icon: str                    # URL to icon

    # Structure
    levels: list[Level]          # Beginner, Intermediate, Advanced
    total_duration_weeks: int

    # Prerequisites
    prerequisites: list[str]     # ['javascript', 'html']
    recommended_order: int

    # Assessment
    has_certification: bool
    certification_exam: str      # 'PCEP', 'OCP', or None

    # Content
    lessons: list[Lesson]
    projects: list[Project]
    exercises: list[Exercise]

    # Metadata
    active: bool = True
    version: str
    last_updated: datetime
```

### 3.3 Project Model
```python
class Project:
    """Student coding project"""

    project_id: str
    student_id: str
    technology: str              # 'react', 'python', etc.
    level: int                   # 1, 2, or 3
    title: str
    description: str

    # Requirements
    requirements: list[str]
    rubric: dict                 # Grading criteria

    # Submission
    github_repo_url: str
    live_demo_url: str          # Optional
    submission_date: datetime
    submitted: bool = False

    # Grading
    automated_tests_passed: int
    automated_tests_total: int
    code_quality_score: float   # 0-100
    functionality_score: float  # 0-100
    instructor_comments: str
    final_grade: float          # 0-100
    graded: bool = False
    graded_date: datetime
    graded_by: str

    # Metadata
    active: bool = True
    date_created: datetime
```

### 3.4 Code Submission Model
```python
class CodeSubmission:
    """Code exercise submission"""

    submission_id: str
    student_id: str
    exercise_id: str
    technology: str

    # Code
    source_code: str
    language: str               # 'python', 'javascript', 'java'
    files: dict[str, str]       # filename -> content

    # Execution results
    test_results: list[TestResult]
    tests_passed: int
    tests_failed: int
    execution_time_ms: float
    memory_used_mb: float

    # Quality metrics
    pylint_score: float         # For Python
    eslint_errors: int          # For JavaScript
    code_smells: list[str]

    # Feedback
    automated_feedback: str
    instructor_feedback: str

    # Metadata
    submission_date: datetime
    graded: bool = False
```

---

## 4. API Specifications

### 4.1 Curriculum API

#### Get Learning Path
```python
GET /api/v1/curriculum/{technology}/path
Authorization: Bearer <token>

Response (200 OK):
{
  "technology": "react",
  "levels": [
    {
      "level": 1,
      "name": "Beginner - React Fundamentals",
      "duration_weeks": 6,
      "lessons": [
        {
          "lesson_id": "react-l1-1",
          "title": "JavaScript ES6+ Review",
          "duration_hours": 2,
          "topics": ["arrow functions", "destructuring", "promises"]
        }
      ],
      "projects": [
        {
          "project_id": "react-p1-1",
          "title": "Build a Todo App",
          "difficulty": "beginner",
          "estimated_hours": 8
        }
      ]
    }
  ]
}
```

### 4.2 Code Submission API

#### Submit Code for Evaluation
```python
POST /api/v1/submissions/evaluate
Content-Type: application/json
Authorization: Bearer <token>

Request:
{
  "student_id": "STU123",
  "exercise_id": "python-ex-001",
  "source_code": "def fibonacci(n):\n    if n <= 1:\n        return n\n    return fibonacci(n-1) + fibonacci(n-2)",
  "language": "python"
}

Response (200 OK):
{
  "submission_id": "SUB456",
  "evaluation": {
    "tests_passed": 8,
    "tests_failed": 2,
    "test_results": [
      {"test": "test_fibonacci_zero", "passed": true, "time_ms": 0.5},
      {"test": "test_fibonacci_large", "passed": false, "error": "RecursionError"}
    ],
    "code_quality": {
      "pylint_score": 7.5,
      "issues": [
        {"line": 1, "message": "Missing docstring", "severity": "convention"}
      ]
    },
    "performance": {
      "execution_time_ms": 125.3,
      "memory_used_mb": 2.1
    },
    "feedback": "Good implementation! Consider using memoization to improve performance for large inputs.",
    "score": 80
  }
}
```

### 4.3 Project Submission API

#### Submit Project
```python
POST /api/v1/projects/submit
Content-Type: application/json
Authorization: Bearer <token>

Request:
{
  "student_id": "STU123",
  "project_id": "react-p2-1",
  "github_repo_url": "https://github.com/student/react-todo-app",
  "live_demo_url": "https://student-todo.netlify.app",
  "notes": "Implemented all required features plus dark mode"
}

Response (200 OK):
{
  "submission_id": "PROJ789",
  "project_id": "react-p2-1",
  "status": "submitted",
  "automated_checks": {
    "repo_accessible": true,
    "demo_live": true,
    "required_files_present": true,
    "build_successful": true,
    "tests_run": {
      "passed": 12,
      "failed": 0,
      "coverage": 85.5
    }
  },
  "next_steps": "Project submitted successfully. Instructor will review within 3 business days.",
  "submitted_at": "2025-12-21T10:30:00Z"
}
```

### 4.4 Certification API

#### Take Mock Exam
```python
POST /api/v1/certification/mock-exam/{exam_type}
Content-Type: application/json
Authorization: Bearer <token>

Request:
{
  "student_id": "STU123",
  "exam_type": "PCEP"
}

Response (200 OK):
{
  "exam_id": "EXAM123",
  "exam_type": "PCEP",
  "questions": [
    {
      "question_id": "Q1",
      "question": "What is the output of: print(type([]))?",
      "type": "multiple_choice",
      "options": [
        "<class 'list'>",
        "<class 'dict'>",
        "<class 'tuple'>",
        "None"
      ]
    }
  ],
  "total_questions": 40,
  "time_limit_minutes": 60,
  "passing_score": 70,
  "started_at": "2025-12-21T10:30:00Z",
  "expires_at": "2025-12-21T11:30:00Z"
}
```

---

## 5. Code Execution Environment

### 5.1 Sandboxed Execution
```python
class CodeExecutor:
    """Secure code execution in isolated container"""

    def execute_code(
        self,
        code: str,
        language: str,
        test_cases: list,
        timeout_seconds: int = 5
    ) -> ExecutionResult:
        """
        Execute code in Docker container

        Security:
        - No network access
        - Limited CPU and memory
        - Timeout enforcement
        - Read-only file system (except /tmp)
        """

        # Create container
        container_config = {
            'image': f'coding-instructor/{language}:latest',
            'network_disabled': True,
            'mem_limit': '256m',
            'cpu_quota': 50000,
            'read_only': True,
            'tmpfs': {'/tmp': 'size=10m'},
            'timeout': timeout_seconds
        }

        # Execute code
        result = self.run_in_container(
            code=code,
            config=container_config,
            test_cases=test_cases
        )

        return result
```

### 5.2 Docker Images
```dockerfile
# Python execution environment
FROM python:3.12-slim
RUN pip install pytest pylint numpy pandas
WORKDIR /code
CMD ["python"]

# JavaScript/React execution environment
FROM node:20-slim
RUN npm install -g jest eslint
WORKDIR /code
CMD ["node"]

# Java execution environment
FROM openjdk:17-slim
RUN apt-get update && apt-get install -y maven
WORKDIR /code
CMD ["java"]
```

---

## 6. Assessment & Grading

### 6.1 Automated Testing
```python
class AutomatedGrader:
    """Automated code grading system"""

    def grade_submission(self, submission: CodeSubmission) -> GradeResult:
        """
        Grade code submission

        Components:
        1. Functionality (50%): Pass automated tests
        2. Code Quality (30%): Pylint/ESLint score
        3. Performance (10%): Execution time and memory
        4. Best Practices (10%): Following conventions
        """

        # Run tests
        test_score = self.run_tests(submission)

        # Check code quality
        quality_score = self.analyze_code_quality(submission)

        # Measure performance
        performance_score = self.measure_performance(submission)

        # Check best practices
        practices_score = self.check_best_practices(submission)

        # Calculate final grade
        final_grade = (
            test_score * 0.5 +
            quality_score * 0.3 +
            performance_score * 0.1 +
            practices_score * 0.1
        )

        return GradeResult(
            final_grade=final_grade,
            breakdown={
                'functionality': test_score,
                'quality': quality_score,
                'performance': performance_score,
                'practices': practices_score
            }
        )
```

### 6.2 Project Grading Rubric
```yaml
project_rubric:
  functionality:
    weight: 40%
    criteria:
      - All requirements implemented
      - Features work as specified
      - Edge cases handled
      - Error handling present

  code_quality:
    weight: 30%
    criteria:
      - Clean, readable code
      - Proper naming conventions
      - DRY principle followed
      - No code smells

  testing:
    weight: 15%
    criteria:
      - Unit tests present
      - Test coverage >80%
      - Tests pass
      - Edge cases tested

  documentation:
    weight: 10%
    criteria:
      - README with setup instructions
      - Code comments where needed
      - API documentation (if applicable)

  best_practices:
    weight: 5%
    criteria:
      - Follows language conventions
      - Proper error handling
      - Security considerations
      - Performance optimization
```

---

## 7. Learning Analytics

### 7.1 Progress Tracking
```python
class ProgressTracker:
    """Track student learning progress"""

    def calculate_mastery_level(
        self,
        student_id: str,
        technology: str
    ) -> MasteryReport:
        """
        Calculate mastery level for technology

        Factors:
        - Lessons completed
        - Exercise scores
        - Project grades
        - Time to completion
        - Code quality trends
        """

        data = self.get_student_data(student_id, technology)

        mastery_score = (
            data.lessons_completed / data.total_lessons * 0.2 +
            data.avg_exercise_score * 0.3 +
            data.avg_project_score * 0.4 +
            data.code_quality_trend * 0.1
        )

        level = self.determine_level(mastery_score)

        return MasteryReport(
            technology=technology,
            mastery_score=mastery_score,
            current_level=level,
            ready_for_next_level=mastery_score >= 80,
            strengths=data.strengths,
            areas_for_improvement=data.weaknesses
        )
```

### 7.2 Adaptive Learning
```python
class AdaptiveLearning:
    """Personalized learning path adjustment"""

    def adjust_learning_path(
        self,
        student_id: str,
        technology: str
    ) -> LearningPath:
        """
        Adjust learning path based on performance

        Adaptations:
        - Recommend additional practice for weak areas
        - Skip topics already mastered
        - Adjust difficulty of exercises
        - Suggest prerequisite review if struggling
        """

        performance = self.analyze_performance(student_id, technology)

        if performance.struggling_areas:
            # Recommend remedial content
            path = self.add_remedial_exercises(
                student_id,
                performance.struggling_areas
            )
        elif performance.excelling:
            # Fast-track to advanced content
            path = self.accelerate_path(student_id, technology)
        else:
            # Standard progression
            path = self.get_standard_path(technology)

        return path
```

---

## 8. Performance Specifications

### 8.1 Response Time Requirements
```yaml
code_execution:
  simple_code: <2s
  complex_code: <5s
  full_test_suite: <10s

api_endpoints:
  get_curriculum: <200ms
  submit_code: <3s (including execution)
  get_progress: <300ms

grading:
  automated_grade: <5s
  project_review: <30s (initial automated checks)
```

### 8.2 Scalability
```yaml
concurrent_users: 500 students
code_executions_per_minute: 1000
max_execution_time: 30s
container_pool_size: 100

storage:
  student_projects: 10GB per student
  curriculum_content: 50GB total
  execution_logs: 100GB rolling
```

---

## 9. Security

### 9.1 Code Execution Security
```yaml
container_security:
  - No network access
  - Limited CPU and memory
  - Timeout enforcement
  - Read-only file system
  - No privilege escalation
  - Resource quotas enforced

code_analysis:
  - Scan for malicious patterns
  - Block dangerous imports (os, subprocess, etc.)
  - Detect infinite loops
  - Prevent file system access
```

### 9.2 Student Data Protection
```yaml
data_security:
  - Encrypt student code at rest
  - Encrypt in transit (TLS 1.3)
  - Access control per student
  - Audit logging
  - GDPR compliance

intellectual_property:
  - Student code ownership respected
  - GitHub integration with student accounts
  - No unauthorized code sharing
  - Plagiarism detection
```

---

## 10. Deployment

### 10.1 Infrastructure
```yaml
compute:
  api_server:
    type: AWS ECS Fargate
    cpu: 2 vCPU
    memory: 4GB
    auto_scaling: enabled

  code_execution:
    type: AWS ECS Fargate (spot)
    containers: 100 pool
    cpu: 1 vCPU per container
    memory: 512MB per container

storage:
  database: PostgreSQL (RDS)
  student_projects: S3
  curriculum_content: S3 + CloudFront
  cache: Redis (ElastiCache)

networking:
  vpc: Dedicated VPC
  subnets: Private for execution, public for API
  load_balancer: ALB with WAF
```

---

## Version History

| Version | Date | Changes |
|---------|------|---------|
| 1.0.0 | 2025-12-21 | Initial specification |

---

**Spec Status**: Active
**Last Updated**: 2025-12-21
**Owner**: Technical Education Team
