# AWS Java Development Skill

**Version**: 1.0
**Created**: 2025-12-17
**Type**: Language-Specific AWS Patterns
**Purpose**: Java-specific patterns for AWS Lambda, SnapStart, and serverless development

---

## Purpose

Provide Java-specific best practices for AWS serverless development including SnapStart optimization, Spring Boot integration, AWS SDK v2, and production patterns.

---

## Research Summary

### Research Questions
- How does SnapStart work for Java Lambda?
- What are Spring Boot best practices for Lambda?
- How to optimize cold starts with priming?
- What are AWS SDK v2 best practices?

### Key Findings
- SnapStart reduces Spring Boot cold starts from 6.1s to 1.4s (4.3x improvement)
- Java 21 + SnapStart enables sub-500ms cold starts
- Priming techniques pre-warm code paths before snapshot
- CRaC (Coordinated Restore at Checkpoint) underlies SnapStart

### Sources
- [Optimizing cold start with SnapStart priming - AWS](https://aws.amazon.com/blogs/compute/optimizing-cold-start-performance-of-aws-lambda-using-advanced-priming-strategies-with-snapstart/)
- [Improving startup performance with Lambda SnapStart - AWS Docs](https://docs.aws.amazon.com/lambda/latest/dg/snapstart.html)
- [Running Java Apps on Lambda with SnapStart 2025 - JavaCodeGeeks](https://www.javacodegeeks.com/2025/05/running-java-apps-on-aws-lambda-with-snapstart-is-it-production-ready-yet.html)
- [Java on Lambda with Spring Boot 3 - DEV Community](https://dev.to/jmontagne/java-is-back-on-lambda-building-a-sub-second-genai-api-with-spring-boot-3-snapstart-and-bedrock-ebo)
- [Reduce SDK startup time - AWS SDK for Java 2.x](https://docs.aws.amazon.com/sdk-for-java/latest/developer-guide/lambda-optimize-starttime.html)

---

## Project Structure

### Recommended Layout
```
lambda-function/
├── src/
│   ├── main/
│   │   ├── java/
│   │   │   └── com/example/
│   │   │       ├── Application.java
│   │   │       ├── handler/
│   │   │       │   └── OrderHandler.java
│   │   │       ├── domain/
│   │   │       │   ├── entity/
│   │   │       │   ├── service/
│   │   │       │   └── repository/
│   │   │       └── infrastructure/
│   │   │           ├── DynamoDbConfig.java
│   │   │           └── AwsClientConfig.java
│   │   └── resources/
│   │       └── application.yaml
│   └── test/
│       └── java/
├── pom.xml
├── template.yaml
└── Makefile
```

---

## SnapStart Configuration

### Enabling SnapStart

```yaml
# template.yaml (SAM)
Resources:
  OrderFunction:
    Type: AWS::Serverless::Function
    Properties:
      Handler: com.example.handler.OrderHandler::handleRequest
      Runtime: java21
      MemorySize: 1024
      Timeout: 30
      SnapStart:
        ApplyOn: PublishedVersions
      AutoPublishAlias: live
```

### Terraform Configuration

```hcl
resource "aws_lambda_function" "order_function" {
  function_name    = "order-function"
  runtime          = "java21"
  handler          = "com.example.handler.OrderHandler::handleRequest"
  memory_size      = 1024
  timeout          = 30

  snap_start {
    apply_on = "PublishedVersions"
  }
}

resource "aws_lambda_alias" "live" {
  name             = "live"
  function_name    = aws_lambda_function.order_function.function_name
  function_version = aws_lambda_function.order_function.version
}
```

### Important SnapStart Limitations
- **No provisioned concurrency**
- **No EFS support**
- **Max 512 MB ephemeral storage**
- **Only works with published versions** (not $LATEST)
- **Snapshot expires after 14 days of inactivity**

---

## Cold Start Optimization

### Constructor Initialization Pattern

**Critical**: Move heavy initialization to constructor (pre-snapshot).

```java
public class OrderHandler implements RequestHandler<APIGatewayProxyRequestEvent, APIGatewayProxyResponseEvent> {

    // Heavy clients initialized in constructor - snapshotted!
    private final DynamoDbEnhancedClient dynamoDbClient;
    private final ObjectMapper objectMapper;
    private final OrderService orderService;

    public OrderHandler() {
        // This runs BEFORE snapshot - cost paid at deployment
        this.dynamoDbClient = DynamoDbEnhancedClient.builder()
            .dynamoDbClient(DynamoDbClient.builder()
                .httpClient(AwsCrtHttpClient.create())  // Faster HTTP client
                .build())
            .build();

        this.objectMapper = new ObjectMapper()
            .registerModule(new JavaTimeModule())
            .disable(SerializationFeature.WRITE_DATES_AS_TIMESTAMPS);

        this.orderService = new OrderService(dynamoDbClient);
    }

    @Override
    public APIGatewayProxyResponseEvent handleRequest(
            APIGatewayProxyRequestEvent event,
            Context context) {
        // Handler code - runs on every invocation
        return processRequest(event);
    }
}
```

### 2025 Performance Benchmarks
- Without SnapStart: 6.1s cold start (Spring Boot)
- With SnapStart: 1.4s cold start (4.3x improvement)
- With SnapStart + Priming: sub-500ms achievable
- Java 21 + GraalVM: even faster for specific cases

---

## Priming Techniques

### CRaC Runtime Hooks

```java
import org.crac.Context;
import org.crac.Core;
import org.crac.Resource;

public class OrderHandler implements RequestHandler<...>, Resource {

    private final DynamoDbEnhancedClient dynamoDbClient;
    private final DynamoDbTable<Order> orderTable;

    public OrderHandler() {
        // Register for CRaC callbacks
        Core.getGlobalContext().register(this);

        this.dynamoDbClient = DynamoDbEnhancedClient.create();
        this.orderTable = dynamoDbClient.table("Orders",
            TableSchema.fromBean(Order.class));
    }

    @Override
    public void beforeCheckpoint(Context<? extends Resource> context) {
        // Run BEFORE snapshot is taken
        // Prime code paths that will be JIT-compiled
        primeDatabase();
        primeJsonSerialization();
    }

    @Override
    public void afterRestore(Context<? extends Resource> context) {
        // Run AFTER restore from snapshot
        // Refresh credentials, re-establish connections
        refreshCredentials();
    }

    private void primeDatabase() {
        // Execute a read to prime DynamoDB client code paths
        try {
            orderTable.getItem(Key.builder()
                .partitionValue("PRIME")
                .build());
        } catch (Exception ignored) {
            // Expected to fail - we just want to prime the code
        }
    }

    private void primeJsonSerialization() {
        // Prime Jackson serialization
        objectMapper.writeValueAsString(new Order());
        objectMapper.readValue("{}", Order.class);
    }
}
```

### Priming Best Practices
1. **Prime SDK clients**: Make dummy calls to DynamoDB, S3, etc.
2. **Prime serialization**: Serialize/deserialize sample objects
3. **Prime validation**: Run validators on sample data
4. **Catch and ignore errors**: Priming calls may fail

---

## Spring Boot Integration

### Serverless Java Container

```xml
<!-- pom.xml -->
<dependency>
    <groupId>com.amazonaws.serverless</groupId>
    <artifactId>aws-serverless-java-container-springboot3</artifactId>
    <version>2.0.0</version>
</dependency>
```

### Stream Handler Pattern

```java
@SpringBootApplication
public class Application implements RequestStreamHandler {

    private static final SpringBootLambdaContainerHandler<
        APIGatewayProxyRequestEvent,
        APIGatewayProxyResponseEvent> handler;

    static {
        try {
            handler = SpringBootLambdaContainerHandler
                .getAwsProxyHandler(Application.class);
        } catch (ContainerInitializationException e) {
            throw new RuntimeException("Could not initialize Spring Boot", e);
        }
    }

    @Override
    public void handleRequest(InputStream input, OutputStream output, Context context)
            throws IOException {
        handler.proxyStream(input, output, context);
    }
}
```

### Spring Boot Configuration

```yaml
# application.yaml
spring:
  main:
    banner-mode: off
    lazy-initialization: true  # Faster startup
  jackson:
    serialization:
      write-dates-as-timestamps: false
```

---

## AWS SDK v2 Best Practices

### HTTP Client Selection

```java
// For synchronous operations - fastest option
DynamoDbClient client = DynamoDbClient.builder()
    .httpClient(AwsCrtHttpClient.create())
    .build();

// For asynchronous operations
DynamoDbAsyncClient asyncClient = DynamoDbAsyncClient.builder()
    .httpClient(AwsCrtAsyncHttpClient.create())
    .build();
```

### Credentials Provider

```java
// CORRECT - Works with SnapStart
DynamoDbClient client = DynamoDbClient.builder()
    .credentialsProvider(DefaultCredentialsProvider.create())
    .build();

// WRONG - Fails after SnapStart restore
DynamoDbClient client = DynamoDbClient.builder()
    .credentialsProvider(EnvironmentVariableCredentialsProvider.create())
    .build();
```

### Client Singleton Pattern

```java
@Configuration
public class AwsClientConfig {

    @Bean
    @Singleton
    public DynamoDbEnhancedClient dynamoDbEnhancedClient() {
        return DynamoDbEnhancedClient.builder()
            .dynamoDbClient(DynamoDbClient.builder()
                .httpClient(AwsCrtHttpClient.create())
                .credentialsProvider(DefaultCredentialsProvider.create())
                .build())
            .build();
    }

    @Bean
    @Singleton
    public S3Client s3Client() {
        return S3Client.builder()
            .httpClient(AwsCrtHttpClient.create())
            .credentialsProvider(DefaultCredentialsProvider.create())
            .build();
    }
}
```

---

## Testing Patterns

### Unit Testing with DynamoDBLocal

```java
@ExtendWith(DynamoDBLocalExtension.class)
class OrderRepositoryTest {

    @DynamoDBLocal
    private DynamoDbClient client;

    private OrderRepository repository;

    @BeforeEach
    void setUp() {
        repository = new OrderRepository(
            DynamoDbEnhancedClient.builder()
                .dynamoDbClient(client)
                .build()
        );
    }

    @Test
    void shouldSaveAndRetrieveOrder() {
        Order order = new Order("ORD-123", "PENDING");

        repository.save(order);
        Optional<Order> retrieved = repository.findById("ORD-123");

        assertThat(retrieved).isPresent();
        assertThat(retrieved.get().getStatus()).isEqualTo("PENDING");
    }
}
```

### Integration Testing with LocalStack

```java
@Testcontainers
class OrderHandlerIntegrationTest {

    @Container
    static LocalStackContainer localstack = new LocalStackContainer(
        DockerImageName.parse("localstack/localstack:3.0"))
        .withServices(Service.DYNAMODB, Service.S3);

    @Test
    void shouldProcessOrderSuccessfully() {
        // Configure SDK to use LocalStack
        DynamoDbClient client = DynamoDbClient.builder()
            .endpointOverride(localstack.getEndpointOverride(Service.DYNAMODB))
            .credentialsProvider(StaticCredentialsProvider.create(
                AwsBasicCredentials.create("test", "test")))
            .region(Region.of(localstack.getRegion()))
            .build();

        // Test against LocalStack
    }
}
```

---

## Error Handling

### Structured Exception Hierarchy

```java
public abstract class ApiException extends RuntimeException {
    private final int statusCode;
    private final String errorCode;

    protected ApiException(int statusCode, String errorCode, String message) {
        super(message);
        this.statusCode = statusCode;
        this.errorCode = errorCode;
    }

    public APIGatewayProxyResponseEvent toResponse() {
        return new APIGatewayProxyResponseEvent()
            .withStatusCode(statusCode)
            .withBody(toJson());
    }
}

public class ValidationException extends ApiException {
    public ValidationException(String message) {
        super(400, "VALIDATION_ERROR", message);
    }
}

public class NotFoundException extends ApiException {
    public NotFoundException(String resource, String id) {
        super(404, "NOT_FOUND", resource + " not found: " + id);
    }
}
```

---

## Dependencies

### pom.xml (Core Dependencies)

```xml
<properties>
    <java.version>21</java.version>
    <aws.sdk.version>2.25.0</aws.sdk.version>
</properties>

<dependencies>
    <!-- AWS Lambda -->
    <dependency>
        <groupId>com.amazonaws</groupId>
        <artifactId>aws-lambda-java-core</artifactId>
        <version>1.2.3</version>
    </dependency>
    <dependency>
        <groupId>com.amazonaws</groupId>
        <artifactId>aws-lambda-java-events</artifactId>
        <version>3.11.0</version>
    </dependency>

    <!-- AWS SDK v2 -->
    <dependency>
        <groupId>software.amazon.awssdk</groupId>
        <artifactId>dynamodb-enhanced</artifactId>
        <version>${aws.sdk.version}</version>
    </dependency>
    <dependency>
        <groupId>software.amazon.awssdk</groupId>
        <artifactId>aws-crt-client</artifactId>
        <version>${aws.sdk.version}</version>
    </dependency>

    <!-- CRaC for SnapStart -->
    <dependency>
        <groupId>io.github.crac</groupId>
        <artifactId>org-crac</artifactId>
        <version>0.1.3</version>
    </dependency>

    <!-- JSON Processing -->
    <dependency>
        <groupId>com.fasterxml.jackson.core</groupId>
        <artifactId>jackson-databind</artifactId>
        <version>2.17.0</version>
    </dependency>
</dependencies>
```

---

## SnapStart Gotchas

### Static State Warning
```java
// WRONG - Same UUID for all restored instances!
public class Handler {
    private static final String INSTANCE_ID = UUID.randomUUID().toString();
}

// CORRECT - Generate at runtime
public class Handler {
    private String getInstanceId(Context context) {
        return context.getAwsRequestId();
    }
}
```

### Credential Refresh
```java
// Credentials snapshotted may expire after restore
@Override
public void afterRestore(Context<? extends Resource> context) {
    // Force credential refresh
    DefaultCredentialsProvider.create().resolveCredentials();
}
```

---

## Version History

- **v1.0** (2025-12-17): Initial skill with embedded research on AWS Lambda Java patterns and SnapStart
