# Development Best Practices Skill

**Version**: 1.0
**Created**: 2025-12-17
**Type**: Software Engineering Patterns
**Purpose**: Language-agnostic development best practices for Abstract_Developer.md

---

## Purpose

Provide a comprehensive reference of software development best practices including SOLID principles, design patterns, TDD, architectural patterns, and API design. This skill enables developers to write maintainable, scalable, and robust code.

---

## Research Summary

### Research Questions
- What are the core SOLID principles and when to apply each?
- Which design patterns are most universally applicable?
- What are modern TDD best practices?
- What are the key microservices architectural patterns?

### Key Findings
- SOLID principles (Robert C. Martin, 2000) remain foundational for modern software architecture
- Gang of Four design patterns (1994) are still incredibly relevant in modern frameworks
- TDD follows the Red-Green-Refactor cycle for incremental development
- Microservices patterns (CQRS, Saga, Circuit Breaker) enable distributed system resilience

### Sources
- [SOLID Design Principles - DigitalOcean](https://www.digitalocean.com/community/conceptual-articles/s-o-l-i-d-the-first-five-principles-of-object-oriented-design)
- [Why SOLID principles are still the foundation - Stack Overflow](https://stackoverflow.blog/2021/11/01/why-solid-principles-are-still-the-foundation-for-modern-software-architecture/)
- [Gang of Four Design Patterns - DigitalOcean](https://www.digitalocean.com/community/tutorials/gangs-of-four-gof-design-patterns)
- [Mastering Design Principles - ByteByteGo](https://blog.bytebytego.com/p/mastering-design-principles-solid)

---

## Core Principles

### SOLID Principles

#### Single Responsibility Principle (SRP)
**Definition**: A class should have only one reason to change.

**When to Apply**:
- Class is doing more than one thing
- Changes to one feature require modifying multiple classes
- Class has many dependencies

**Example**:
```python
# Wrong - Multiple responsibilities
class UserService:
    def create_user(self, data): ...
    def send_email(self, user): ...
    def generate_report(self, users): ...

# Correct - Single responsibility
class UserService:
    def create_user(self, data): ...

class EmailService:
    def send_email(self, user): ...

class ReportService:
    def generate_report(self, users): ...
```

#### Open-Closed Principle (OCP)
**Definition**: Software entities should be open for extension, but closed for modification.

**When to Apply**:
- Adding new features requires modifying existing code
- Conditional logic based on types/variants
- Risk of breaking existing functionality when adding features

**Example**:
```python
# Wrong - Requires modification for new shapes
def calculate_area(shape):
    if shape.type == "circle":
        return 3.14 * shape.radius ** 2
    elif shape.type == "rectangle":
        return shape.width * shape.height

# Correct - Open for extension
from abc import ABC, abstractmethod

class Shape(ABC):
    @abstractmethod
    def area(self): pass

class Circle(Shape):
    def area(self): return 3.14 * self.radius ** 2

class Rectangle(Shape):
    def area(self): return self.width * self.height
```

#### Liskov Substitution Principle (LSP)
**Definition**: Objects of a superclass should be replaceable with objects of subclasses without affecting correctness.

**When to Apply**:
- Subclass overrides parent behavior unexpectedly
- Subclass throws exceptions parent doesn't
- Subclass has preconditions parent doesn't have

#### Interface Segregation Principle (ISP)
**Definition**: Clients should not be forced to depend on interfaces they don't use.

**When to Apply**:
- Interface has many methods
- Classes implement interfaces with unused methods
- Different clients need different subsets of functionality

#### Dependency Inversion Principle (DIP)
**Definition**: High-level modules should not depend on low-level modules. Both should depend on abstractions.

**When to Apply**:
- Testing is difficult due to concrete dependencies
- Changing one module requires changing many others
- Code is tightly coupled

---

### Additional Principles

#### DRY (Don't Repeat Yourself)
- Avoid code duplication
- Extract common logic into reusable functions/classes
- Use inheritance and composition appropriately

#### KISS (Keep It Simple, Stupid)
- Prefer simple solutions over complex ones
- Avoid premature optimization
- Write readable code over clever code

#### YAGNI (You Aren't Gonna Need It)
- Don't implement features until needed
- Avoid speculative generality
- Focus on current requirements

---

## Design Patterns

### Creational Patterns

#### Factory Method
**Purpose**: Define interface for creating objects, let subclasses decide which class to instantiate.

**When to Use**:
- Class doesn't know what objects it needs to create
- Class wants subclasses to specify created objects
- Need to delegate creation logic

#### Builder
**Purpose**: Separate construction of complex objects from representation.

**When to Use**:
- Object has many optional parameters
- Need to construct objects step by step
- Want to create different representations

#### Singleton
**Purpose**: Ensure a class has only one instance with global access.

**When to Use**:
- Exactly one instance needed (e.g., configuration, logging)
- Controlled access to a shared resource

**Caution**: Often overused; consider dependency injection instead.

### Structural Patterns

#### Adapter
**Purpose**: Convert interface of a class into another interface clients expect.

**When to Use**:
- Integrating incompatible interfaces
- Wrapping legacy code
- Working with third-party libraries

#### Facade
**Purpose**: Provide unified interface to a set of interfaces in a subsystem.

**When to Use**:
- Simplifying complex subsystem access
- Reducing dependencies on subsystem
- Layering subsystems

#### Decorator
**Purpose**: Attach additional responsibilities to objects dynamically.

**When to Use**:
- Adding responsibilities without subclassing
- Responsibilities can be withdrawn
- Extension by subclassing is impractical

### Behavioral Patterns

#### Strategy
**Purpose**: Define family of algorithms, encapsulate each, make them interchangeable.

**When to Use**:
- Multiple algorithms for a task
- Need to switch algorithms at runtime
- Avoid conditional logic for algorithm selection

#### Observer
**Purpose**: Define one-to-many dependency so when one object changes, dependents are notified.

**When to Use**:
- Changes to one object require changing others
- Object should notify others without knowing who
- Decoupling subjects from observers

#### Command
**Purpose**: Encapsulate request as object, allowing parameterization and queuing.

**When to Use**:
- Parameterize objects with operations
- Queue, log, or support undo operations
- Decouple invoker from receiver

---

## Testing Practices

### TDD (Test-Driven Development)

#### Red-Green-Refactor Cycle
1. **Red**: Write a failing test
2. **Green**: Write minimum code to pass
3. **Refactor**: Improve code while keeping tests green

#### FIRST Principles
- **Fast**: Tests should run quickly
- **Independent**: Tests shouldn't depend on each other
- **Repeatable**: Same result every time
- **Self-validating**: Pass or fail, no manual inspection
- **Timely**: Write tests at the right time (before code in TDD)

#### Test Pyramid
```
        /\        E2E Tests (few, slow, expensive)
       /  \
      /----\      Integration Tests (some)
     /      \
    /--------\    Unit Tests (many, fast, cheap)
```

#### Best Practices
- Test behavior, not implementation
- Use descriptive test names
- Keep tests readable and maintainable
- Use test doubles (mocks, stubs) appropriately
- Don't over-mock - test real behavior when possible

---

## Architectural Patterns

### CQRS (Command Query Responsibility Segregation)

**Definition**: Separate read and write operations into different models.

**Components**:
- **Commands**: Modify state (write operations)
- **Queries**: Read state (read operations)
- **Separate models**: Optimized for each concern

**When to Use**:
- Read and write workloads differ significantly
- Need to scale reads and writes independently
- Complex domain with distinct read/write patterns

### Saga Pattern

**Definition**: Manage distributed transactions across multiple services.

**Approaches**:
1. **Choreography**: Services emit and react to events
2. **Orchestration**: Central coordinator directs saga flow

**Key Concepts**:
- Compensating transactions for rollback
- Eventual consistency (not ACID)
- Idempotent operations

**When to Use**:
- Transactions span multiple services
- Need consistency without distributed locks
- Long-running business processes

### Circuit Breaker

**Definition**: Prevent cascading failures by failing fast when service is degraded.

**States**:
1. **Closed**: Normal operation, requests pass through
2. **Open**: Service failing, requests fail immediately
3. **Half-Open**: Testing if service recovered

**Configuration**:
- Failure threshold (e.g., 5 failures)
- Timeout duration (e.g., 30 seconds)
- Reset interval (e.g., 60 seconds)

**When to Use**:
- Calling external services
- Preventing cascade failures
- Degraded service scenarios

---

## API Design

### RESTful Conventions

**URL Structure**:
```
GET    /resources           # List resources
GET    /resources/{id}      # Get single resource
POST   /resources           # Create resource
PUT    /resources/{id}      # Update resource
DELETE /resources/{id}      # Delete resource
```

**HTTP Status Codes**:
- 2xx: Success (200 OK, 201 Created, 204 No Content)
- 4xx: Client Error (400 Bad Request, 401 Unauthorized, 404 Not Found)
- 5xx: Server Error (500 Internal Server Error, 503 Service Unavailable)

### Versioning Strategies
- URL path: `/v1/resources`
- Query parameter: `/resources?version=1`
- Header: `Accept: application/vnd.api.v1+json`

### Error Handling
```json
{
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "Invalid input",
    "details": [
      {"field": "email", "message": "Invalid format"}
    ]
  }
}
```

---

## Domain-Driven Design (DDD)

### Core Concepts

#### Bounded Context
**Definition**: Explicit boundary within which a domain model applies.

**Key Principles**:
- Each context has its own ubiquitous language
- Contains its own domain model
- Typically aligns with a microservice
- Communicates via well-defined interfaces (Context Maps)

#### Aggregates
**Definition**: Cluster of domain objects treated as a single unit.

**Rules**:
- **Aggregate Root**: Single entry point controlling access
- **Consistency Boundary**: All invariants satisfied after transactions
- **Reference by Identity**: Reference other aggregates by ID only
- **Keep Small**: Reduces contention, improves performance

#### Key Patterns

| Pattern | Purpose |
|---------|---------|
| **Entities** | Objects with distinct identity |
| **Value Objects** | Immutable objects defined by attributes |
| **Domain Events** | Capture domain occurrences |
| **Repositories** | Collection-like access to aggregates |
| **Domain Services** | Operations not fitting entities |
| **Application Services** | Orchestrate use cases |

#### Example Structure
```
order-service/
├── domain/
│   ├── entities/
│   │   └── Order.py
│   ├── value_objects/
│   │   └── Money.py
│   ├── events/
│   │   └── OrderCreated.py
│   └── services/
│       └── PricingService.py
├── application/
│   └── OrderApplicationService.py
└── infrastructure/
    └── OrderRepository.py
```

---

## Behavior-Driven Development (BDD)

### Gherkin Syntax

**Structure**:
```gherkin
Feature: [Feature name]
  As a [role]
  I want [feature]
  So that [benefit]

  Scenario: [Scenario name]
    Given [precondition]
    When [action]
    Then [expected outcome]
```

### Best Practices

#### Writing Scenarios
- **One behavior per scenario**: Keep focused
- **Declarative style**: Describe *what*, not *how*
- **Business language**: Avoid technical details
- **Single When step**: Multiple Whens indicate complexity

#### Given/When/Then Guidelines
- **Given**: Setup preconditions (arrange)
- **When**: Single action or event (act)
- **Then**: Verify outcomes (assert)

#### Example - Good vs Bad

**Bad (imperative)**:
```gherkin
Scenario: User login
  Given I navigate to login page
  When I enter "user@test.com" in email field
  And I enter "password123" in password field
  And I click the login button
  Then I should see the dashboard heading
```

**Good (declarative)**:
```gherkin
Scenario: Successful login with valid credentials
  Given a registered user exists
  When the user logs in with valid credentials
  Then they should see their dashboard
```

### Scenario Outline (Data-Driven)
```gherkin
Scenario Outline: Login validation
  Given a user with <status> account
  When they attempt to login
  Then they should see <message>

  Examples:
    | status   | message              |
    | active   | Welcome back         |
    | locked   | Account is locked    |
    | expired  | Please renew account |
```

---

## Anti-Patterns to Avoid

### Premature Optimization
- Don't optimize until you have evidence of performance issues
- Profile before optimizing
- Clarity over cleverness

### Over-Engineering
- Don't add features you don't need
- Don't create abstractions for one-time operations
- Don't design for hypothetical future requirements

### Distributed Monolith
- Don't create microservices that are tightly coupled
- Avoid shared databases across services
- Ensure services can be deployed independently

### God Class / God Object
- Don't let classes grow too large
- Watch for classes with many responsibilities
- Split when class becomes hard to understand

---

## Decision Rules

### When to Use Microservices
**Do**:
- Large team (>10 developers)
- Independent scaling requirements
- Different technology needs per component
- High availability requirements

**Don't**:
- Small team or startup
- Simple application
- Tight budget/timeline
- Shared database requirements

### When to Use Single Table DynamoDB
**Do**:
- Access patterns well-defined
- Need single-digit millisecond latency
- High read/write throughput

**Don't**:
- Unknown access patterns
- Heavy analytical queries
- Frequent schema changes

---

## Version History

- **v1.0** (2025-12-17): Initial skill with embedded research on SOLID, design patterns, TDD, architectural patterns
