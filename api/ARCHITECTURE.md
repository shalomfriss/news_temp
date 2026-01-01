# Architecture Documentation

## System Overview

News Temp API is a modular, layered application built on Dart Frog that follows clean architecture principles. The system is designed for maintainability, testability, and scalability.

## Architecture Layers

```
┌─────────────────────────────────────────────┐
│           Presentation Layer                │
│  (Routes - HTTP Request Handlers)           │
└──────────────┬──────────────────────────────┘
               │
               ▼
┌─────────────────────────────────────────────┐
│          Middleware Layer                   │
│  (Auth, Logging, Data Source Injection)     │
└──────────────┬──────────────────────────────┘
               │
               ▼
┌─────────────────────────────────────────────┐
│            Data Layer                        │
│  (NewsDataSource, Models, Repositories)     │
└──────────────┬──────────────────────────────┘
               │
               ▼
┌─────────────────────────────────────────────┐
│         Data Source Layer                   │
│  (InMemoryNewsDataSource, External APIs)    │
└─────────────────────────────────────────────┘
```

## Core Components

### 1. Presentation Layer (Routes)

**Location**: `routes/`

Routes are HTTP request handlers that map URLs to business logic. Each route follows the Dart Frog pattern:

```dart
Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.get) {
    return Response(statusCode: HttpStatus.methodNotAllowed);
  }

  // Extract query parameters
  final queryParams = context.request.url.queryParameters;

  // Use injected dependencies
  final dataSource = context.read<NewsDataSource>();

  // Execute business logic
  final result = await dataSource.getData();

  // Return response
  return Response.json(body: result);
}
```

**Route Structure**:
- `_middleware.dart`: Global middleware application
- `index.dart`: Root route (health check)
- `api/v1/*`: API endpoints organized by resource

**Key Principles**:
- Routes are thin - they only handle HTTP concerns
- Business logic is delegated to the data layer
- Dependencies are injected via the RequestContext
- Responses are typed using response models

### 2. Middleware Layer

**Location**: `lib/src/middleware/`

Middleware provides cross-cutting concerns for requests:

#### User Provider Middleware
**File**: `lib/src/middleware/user_provider.dart`

```dart
Middleware userProvider() {
  return (handler) {
    return handler.use(
      provider<RequestUser>((context) {
        final userId = _extractUserId(context.request);
        return userId != null
            ? RequestUser._(id: userId)
            : RequestUser.anonymous;
      }),
    );
  };
}
```

**Responsibilities**:
- Extracts user ID from Authorization Bearer token
- Provides `RequestUser` to the request context
- Supports anonymous users (no token)

**Token Format**: `Authorization: Bearer {userId}`

#### Data Source Provider Middleware
**File**: `lib/src/middleware/news_data_source_provider.dart`

```dart
Middleware newsDataSourceProvider() {
  return handler.use(
    provider<NewsDataSource>((_) => InMemoryNewsDataSource()),
  );
}
```

**Responsibilities**:
- Injects `NewsDataSource` implementation into request context
- Provides singleton instance of data source
- Enables easy swapping for testing or production

#### Request Logger Middleware
Built-in Dart Frog middleware that logs all incoming requests.

### 3. Data Layer

**Location**: `lib/src/data/`

#### NewsDataSource Interface
**File**: `lib/src/data/news_data_source.dart`

Abstract interface defining all data operations:

```dart
abstract class NewsDataSource {
  // Article operations
  Future<Article?> getArticle({required String id, int limit, int offset, bool preview});
  Future<bool?> isPremiumArticle({required String id});
  Future<RelatedArticles> getRelatedArticles({required String id, int limit, int offset});

  // Feed operations
  Future<Feed> getFeed({Category category, int limit, int offset});
  Future<List<Category>> getCategories();

  // Search operations
  Future<List<String>> getPopularTopics();
  Future<List<String>> getRelevantTopics({required String term});
  Future<List<NewsBlock>> getPopularArticles();
  Future<List<NewsBlock>> getRelevantArticles({required String term});

  // Subscription operations
  Future<void> createSubscription({required String userId, required String subscriptionId});
  Future<List<Subscription>> getSubscriptions();

  // User operations
  Future<User?> getUser({required String userId});
}
```

**Design Benefits**:
- Dependency inversion - depends on abstraction, not implementation
- Testability - easily mock for tests
- Flexibility - swap implementations without changing routes

#### InMemoryNewsDataSource Implementation
**File**: `lib/src/data/in_memory_news_data_source.dart`

Concrete implementation using static data:

```dart
class InMemoryNewsDataSource extends NewsDataSource {
  final Map<String, Article> _articles = {...};
  final Map<Category, List<NewsBlock>> _feed = {...};

  @override
  Future<Article?> getArticle({required String id, ...}) async {
    return _articles[id];
  }

  @override
  Future<Feed> getFeed({Category category, int limit, int offset}) async {
    final blocks = _feed[category] ?? [];
    final paginated = _paginate(blocks, limit, offset);
    return Feed(blocks: paginated, totalBlocks: blocks.length);
  }
}
```

**Features**:
- Pre-populated with static data for development
- Supports pagination (limit/offset)
- In-memory storage for fast access
- Thread-safe for concurrent requests

### 4. Models Layer

**Location**: `lib/src/data/models/` and `lib/src/models/`

#### Data Models (Internal)
Represent domain entities:

**Article**: News article with paginated blocks
```dart
class Article {
  final String title;
  final List<NewsBlock> blocks;
  final int totalBlocks;
  final Uri url;
}
```

**Feed**: News feed with paginated blocks
```dart
class Feed {
  final List<NewsBlock> blocks;
  final int totalBlocks;
}
```

**User**: User profile with subscription
```dart
class User {
  final String id;
  final SubscriptionPlan subscription;
}
```

**Subscription**: Subscription plan details
```dart
class Subscription {
  final String id;
  final String name;
  final SubscriptionCost cost;
  final List<String> benefits;
}
```

#### Response Models (API)
Shape of API responses:

**ArticleResponse**: API response for articles
```dart
class ArticleResponse {
  final List<NewsBlock> content;
  final int? totalCount;
  final String url;
}
```

**FeedResponse**: API response for feeds
```dart
class FeedResponse {
  final List<NewsBlock> feed;
  final int? totalCount;
}
```

All response models use `@JsonSerializable()` for automatic JSON serialization.

### 5. News Blocks Package

**Location**: `packages/news_blocks/`

A standalone Dart package providing reusable content blocks.

#### Block Hierarchy

All blocks implement `NewsBlock` interface:

```dart
abstract class NewsBlock {
  String get type;
}
```

#### Block Categories

**Post Blocks**: Article previews in different sizes
- `PostLargeBlock`: Full-width article with image, title, description
- `PostMediumBlock`: Medium article preview with category, author
- `PostSmallBlock`: Compact article preview

**Grid Blocks**: Multi-column layouts
- `PostGridGroupBlock`: Container for grid tiles
- `PostGridTileBlock`: Individual grid item

**Text Blocks**: Typography elements
- `SectionHeaderBlock`: Section title
- `TextHeadlineBlock`: Article headline
- `TextParagraphBlock`: Body text
- `TextLeadParagraphBlock`: Lead paragraph
- `TextCaptionBlock`: Caption text

**Media Blocks**: Rich content
- `ImageBlock`: Image with URL
- `VideoBlock`: Video with URL
- `SlideshowBlock`: Image gallery
- `SlideBlock`: Individual slide

**Layout Blocks**: Structural elements
- `DividerHorizontalBlock`: Horizontal separator
- `SpacerBlock`: Spacing with configurable size
- `ArticleIntroductionBlock`: Article header

**Interactive Blocks**: User actions
- `BannerAdBlock`: Advertisement
- `NewsletterBlock`: Newsletter subscription
- `TrendingStoryBlock`: Trending topic

#### Block Actions

Blocks can have associated actions:

```dart
abstract class BlockAction {
  BlockActionType get type;
}

class NavigateToArticleAction extends BlockAction {
  final String articleId;
}

class NavigateToFeedCategoryAction extends BlockAction {
  final Category category;
}
```

**Action Types**:
- `navigateToArticle`: Navigate to article detail
- `navigateToFeedCategory`: Filter feed by category
- `navigateToSlideshow`: Open slideshow
- `navigateToVideoArticle`: Open video article

#### Serialization

All blocks support JSON serialization using converters:

```dart
@NewsBlocksConverter()
final List<NewsBlock> blocks;
```

The `NewsBlocksConverter` handles polymorphic deserialization based on `type` field.

## Request Flow

### Typical Request Lifecycle

```
1. HTTP Request
   │
   ▼
2. Route Handler (onRequest)
   │
   ├─> Check HTTP method
   ├─> Extract query parameters
   │
   ▼
3. Read from RequestContext
   │
   ├─> context.read<RequestUser>() - Get authenticated user
   ├─> context.read<NewsDataSource>() - Get data source
   │
   ▼
4. Call Data Source
   │
   ├─> Fetch data (articles, feed, etc.)
   ├─> Apply pagination/filtering
   │
   ▼
5. Transform to Response Model
   │
   ├─> Map domain models to API responses
   ├─> Apply JSON serialization
   │
   ▼
6. Return HTTP Response
   │
   └─> Response.json(body: responseModel)
```

### Example: GET /api/v1/feed

```dart
// 1. Route Handler
Future<Response> onRequest(RequestContext context) async {
  // 2. Validate method
  if (context.request.method != HttpMethod.get) {
    return Response(statusCode: HttpStatus.methodNotAllowed);
  }

  // 3. Extract parameters
  final queryParams = context.request.url.queryParameters;
  final category = _parseCategory(queryParams['category']);
  final limit = int.tryParse(queryParams['limit'] ?? '') ?? 20;
  final offset = int.tryParse(queryParams['offset'] ?? '') ?? 0;

  // 4. Use injected dependencies
  final feed = await context.read<NewsDataSource>()
      .getFeed(category: category, limit: limit, offset: offset);

  // 5. Create response
  final response = FeedResponse(
    feed: feed.blocks,
    totalCount: feed.totalBlocks,
  );

  // 6. Return JSON response
  return Response.json(body: response);
}
```

## Data Access Patterns

### Pagination

All list-based endpoints support pagination:

```dart
Future<Feed> getFeed({Category category, int limit = 20, int offset = 0}) {
  final allBlocks = _feed[category] ?? [];
  final paginated = allBlocks.skip(offset).take(limit).toList();
  return Feed(blocks: paginated, totalBlocks: allBlocks.length);
}
```

**Query Parameters**:
- `limit`: Number of items to return (default: 20)
- `offset`: Zero-based offset (default: 0)

**Response**:
- Returns paginated items in `feed` or `content` array
- Returns `totalCount` for total available items

### Filtering

Feed endpoint supports category filtering:

```dart
final category = Category.values.firstWhere(
  (c) => c.name == categoryQueryParam,
  orElse: () => Category.top,
);
```

### Search

Search endpoints provide two modes:

**Popular Search**:
- Returns trending topics and articles
- No query parameters required

**Relevant Search**:
- Returns content matching search term
- Query parameter: `q={search term}`

## Authentication

### Token-Based Authentication

User is extracted from Authorization header:

```
Authorization: Bearer {userId}
```

### RequestUser Object

```dart
class RequestUser {
  final String id;
  static const anonymous = RequestUser._(id: '');

  bool get isAnonymous => this == RequestUser.anonymous;
}
```

### Accessing User in Routes

```dart
final user = context.read<RequestUser>();
if (user.isAnonymous) {
  return Response(statusCode: HttpStatus.unauthorized);
}
```

## Error Handling

### HTTP Status Codes

- `200 OK`: Successful GET request
- `201 Created`: Successful POST request
- `204 No Content`: Health check
- `400 Bad Request`: Invalid request parameters
- `401 Unauthorized`: Missing or invalid authentication
- `405 Method Not Allowed`: Unsupported HTTP method
- `404 Not Found`: Resource not found
- `500 Internal Server Error`: Server error

### Error Response Format

```json
{
  "error": "Error message",
  "statusCode": 400
}
```

### Client-Side Errors

The API client throws typed exceptions:

```dart
class NewsTempApiRequestFailure implements Exception {
  final int statusCode;
  final Map<String, dynamic> body;
}

class NewsTempApiMalformedResponse implements Exception {
  final Object error;
}
```

## Testing Strategy

### Unit Tests

**Models**: Test serialization/deserialization
**Data Source**: Test data access methods
**Middleware**: Test request/response transformations

### Integration Tests

**Routes**: Test full request/response cycle

```dart
test('returns 200 and feed on GET /api/v1/feed', () async {
  final response = await request.get('/api/v1/feed');
  expect(response.statusCode, equals(HttpStatus.ok));

  final body = await response.json();
  expect(body, containsPair('feed', isList));
  expect(body, containsPair('total_count', isPositive));
});
```

### Test Utilities

**Mock Data**: Use `MockNewsDataSource` for testing routes
**Test Context**: Use `TestRequestContext` for middleware testing

## Scalability Considerations

### Current State

- In-memory data source suitable for development
- Single-instance deployment
- No database persistence

### Future Enhancements

**Database Integration**:
- Replace `InMemoryNewsDataSource` with `PostgresNewsDataSource`
- Use ORM or query builder (Dart Frog supports database connections)
- Implement connection pooling

**Caching Layer**:
- Add Redis caching for frequently accessed content
- Cache popular articles and feeds
- Implement cache invalidation strategies

**Horizontal Scaling**:
- Stateless routes enable multiple instances
- Load balancer for request distribution
- Shared storage for user sessions

**API Gateway**:
- Rate limiting
- Request throttling
- Authentication offloading

## Security Considerations

### Current Implementation

- Token-based authentication (Bearer tokens)
- User ID extracted from token
- Anonymous access supported

### Recommendations

**Production Hardening**:
- Use JWT tokens with expiration
- Implement token refresh mechanism
- Add rate limiting
- Validate all input parameters
- Sanitize query parameters
- Use HTTPS only
- Add CORS configuration
- Implement request size limits

**Data Protection**:
- Encrypt sensitive data at rest
- Use secure connection strings
- Implement audit logging
- Add PII redaction from logs

## Performance Optimization

### Current Optimizations

- In-memory data access (fast reads)
- Pagination to reduce payload size
- Efficient block serialization
- Connection pooling in HTTP client

### Optimization Opportunities

**Response Compression**:
- Enable gzip compression
- Compress large block payloads

**Lazy Loading**:
- Load images/videos on demand
- Implement infinite scroll with pagination

**CDN Integration**:
- Serve static assets (images, videos) from CDN
- Cache API responses at edge

**Query Optimization**:
- Add database indexes (when using database)
- Implement query result caching
- Use connection pooling

## Deployment Architecture

### Development

```
Dart Frog Dev Server
  ├─> Hot Reload
  ├─> File Watching
  └─> Development Logging
```

### Production

```
Load Balancer
  ├─> Instance 1 (Dart Frog)
  ├─> Instance 2 (Dart Frog)
  └─> Instance N (Dart Frog)
        │
        ▼
  Shared Database / Cache
```

### Docker Deployment

```dockerfile
# Multi-stage build
FROM dart:stable AS build
WORKDIR /app
COPY . .
RUN dart pub get
RUN dart_frog build

FROM dart:stable-slim
COPY --from=build /app/build /app
EXPOSE 8080
CMD ["dart", "bin/server.dart"]
```

## Monitoring & Observability

### Current Monitoring

- Request logging via `requestLogger()`
- HTTP status code tracking
- Request timing (built into Dart Frog)

### Recommended Enhancements

**Metrics Collection**:
- Request rate
- Response times
- Error rates
- Database query times

**Logging**:
- Structured logging (JSON format)
- Log aggregation (ELK stack)
- Error tracking (Sentry)

**Tracing**:
- Distributed tracing
- Request correlation IDs
- Performance profiling

**Health Checks**:
- Database connectivity
- Cache connectivity
- External API status

## Maintenance & Evolution

### Versioning

API versioned via URL path: `/api/v1/`

Future versions: `/api/v2/`, etc.

### Deprecation Strategy

1. Add deprecation warning headers
2. Maintain old endpoint for N months
3. Announce sunset date
4. Remove endpoint

### Extending the API

**Adding New Endpoint**:
1. Add route file
2. Implement data source method (if needed)
3. Add response model
4. Write tests
5. Update documentation

**Adding New Block Type**:
1. Create block class in `news_blocks`
2. Implement `NewsBlock` interface
3. Add serialization
4. Write tests
5. Update documentation

### Code Quality

- Linting: `very_good_analysis`
- Code formatting: `dart format`
- Static analysis: `dart analyze`
- Test coverage: Aim for >80%

## Conclusion

The News Temp API architecture prioritizes:

- **Modularity**: Clear separation of concerns
- **Testability**: Easy to mock and test components
- **Maintainability**: Clean code patterns
- **Scalability**: Ready for horizontal scaling
- **Flexibility**: Easy to extend and modify

This architecture provides a solid foundation for growing the API from a prototype to a production-ready service.
