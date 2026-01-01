# Cheatsheet - Common Usage Patterns

Quick reference for common tasks when working with News Temp API.

## Table of Contents

- [Server Operations](#server-operations)
- [Client Usage](#client-usage)
- [Data Operations](#data-operations)
- [Block Operations](#block-operations)
- [Testing Patterns](#testing-patterns)
- [Common Patterns](#common-patterns)

## Server Operations

### Starting the Server

```bash
# Development mode (with hot reload)
dart_frog dev

# Production mode
dart_frog build
cd build
dart bin/server.dart
```

### Running Tests

```bash
# All tests
dart test

# Specific test file
dart test test/routes/feed/index_test.dart

# With coverage
dart test --coverage=coverage

# Watch mode
dart test --watch
```

### Code Generation

```bash
# Generate .g.dart files
dart run build_runner build --delete-conflicting-outputs

# Watch mode
dart run build_runner watch --delete-conflicting-outputs
```

### Running API Documentation

```bash
# Preview API documentation
apiary preview --path docs/api.apib --watch
```

### Linting and Formatting

```bash
# Analyze code
dart analyze

# Format code
dart format .

# Fix lint issues (auto-fix)
dart fix --apply
```

## Client Usage

### Initialize API Client

```dart
import 'package:news_temp_api/client.dart';

// Localhost (development)
final client = NewsTempApiClient.localhost(
  tokenProvider: () async => 'user-token-here',
);

// Production
final client = NewsTempApiClient(
  tokenProvider: () async => 'user-token-here',
);
```

### Get Feed

```dart
// Default feed (top news)
final feed = await client.getFeed();

// Category-specific feed
final techFeed = await client.getFeed(category: Category.technology);

// With pagination
final feedPage2 = await client.getFeed(
  category: Category.sports,
  limit: 20,
  offset: 20,
);

// Access results
print('Total items: ${feed.totalCount}');
for (final block in feed.feed) {
  print(block.type);
}
```

### Get Article

```dart
// Get article by ID
final article = await client.getArticle(id: 'article-123');

// With pagination
final articlePartial = await client.getArticle(
  id: 'article-123',
  limit: 10,
  offset: 0,
);

// Access content
print('Article URL: ${article.url}');
for (final block in article.content) {
  print(block.type);
}
```

### Get Related Articles

```dart
// Get related articles
final related = await client.getRelatedArticles(id: 'article-123');

// With pagination
final relatedPaginated = await client.getRelatedArticles(
  id: 'article-123',
  limit: 10,
  offset: 0,
);

// Access results
for (final block in related.relatedArticles) {
  print(block.type);
}
```

### Get Categories

```dart
// Get all categories
final categories = await client.getCategories();

for (final category in categories.categories) {
  print(category.name);
}
```

### Search

```dart
// Popular search
final popular = await client.popularSearch();

print('Popular topics: ${popular.topics}');
for (final article in popular.articles) {
  print(article.type);
}

// Relevant search
final relevant = await client.relevantSearch(term: 'technology');

print('Relevant topics: ${relevant.topics}');
for (final article in relevant.articles) {
  print(article.type);
}
```

### User Operations

```dart
// Get current user
final userResponse = await client.getCurrentUser();
print('User ID: ${userResponse.user.id}');
print('Subscription: ${userResponse.user.subscription}');
```

### Subscription Operations

```dart
// Get available subscriptions
final subscriptions = await client.getSubscriptions();

for (final sub in subscriptions.subscriptions) {
  print('${sub.name}: \$${sub.cost.monthly / 100}/month');
}

// Create subscription
await client.createSubscription(subscriptionId: 'premium-plan-id');
```

### Newsletter Subscription

```dart
// Subscribe to newsletter
await client.subscribeToNewsletter(email: 'user@example.com');
```

### Error Handling

```dart
import 'dart:io';

try {
  final feed = await client.getFeed();
} on NewsTempApiRequestFailure catch (e) {
  print('API Error (${e.statusCode}): ${e.body}');
} on NewsTempApiMalformedResponse catch (e) {
  print('Malformed Response: ${e.error}');
} on SocketException catch (e) {
  print('Network Error: $e');
}
```

## Data Operations

### Working with NewsDataSource

```dart
import 'package:news_temp_api/api.dart';

// Create data source
final dataSource = InMemoryNewsDataSource();

// Get article
final article = await dataSource.getArticle(
  id: 'article-123',
  limit: 20,
  offset: 0,
  preview: false,
);

// Get feed
final feed = await dataSource.getFeed(
  category: Category.technology,
  limit: 20,
  offset: 0,
);

// Check if premium
final isPremium = await dataSource.isPremiumArticle(id: 'article-123');

// Get categories
final categories = await dataSource.getCategories();

// Search
final popularTopics = await dataSource.getPopularTopics();
final relevantTopics = await dataSource.getRelevantTopics(term: 'tech');
final popularArticles = await dataSource.getPopularArticles();
final relevantArticles = await dataSource.getRelevantArticles(term: 'tech');

// User operations
final user = await dataSource.getUser(userId: 'user-123');

// Subscription operations
await dataSource.createSubscription(
  userId: 'user-123',
  subscriptionId: 'premium-plan-id',
);
final subscriptions = await dataSource.getSubscriptions();
```

### Pagination Pattern

```dart
Future<void> fetchAllFeeds() async {
  final dataSource = InMemoryNewsDataSource();
  int offset = 0;
  const limit = 20;
  List<NewsBlock> allBlocks = [];

  while (true) {
    final feed = await dataSource.getFeed(
      category: Category.technology,
      limit: limit,
      offset: offset,
    );

    allBlocks.addAll(feed.blocks);

    if (allBlocks.length >= feed.totalBlocks) {
      break;
    }

    offset += limit;
  }

  print('Total blocks fetched: ${allBlocks.length}');
}
```

## Block Operations

### Create Post Blocks

```dart
import 'package:news_blocks/news_blocks.dart';

// Large post block
final largePost = PostLargeBlock(
  id: 'article-123',
  category: Category.technology,
  author: 'John Doe',
  publishedAt: DateTime.parse('2022-03-09T00:00:00.000'),
  imageUrl: 'https://example.com/image.jpg',
  title: 'Breaking News',
  isPremium: false,
  action: NavigateToArticleAction(articleId: 'article-123'),
);

// Medium post block
final mediumPost = PostMediumBlock(
  id: 'article-456',
  category: Category.science,
  author: 'Jane Smith',
  publishedAt: DateTime.parse('2022-03-10T00:00:00.000'),
  imageUrl: 'https://example.com/image2.jpg',
  title: 'Science Update',
  description: 'A brief description',
  isPremium: false,
  action: NavigateToArticleAction(articleId: 'article-456'),
);

// Small post block
final smallPost = PostSmallBlock(
  id: 'article-789',
  category: Category.health,
  author: 'Dr. Health',
  publishedAt: DateTime.parse('2022-03-11T00:00:00.000'),
  imageUrl: 'https://example.com/image3.jpg',
  title: 'Health Tips',
  description: 'Stay healthy',
  isPremium: false,
);
```

### Create Text Blocks

```dart
// Section header
final header = SectionHeaderBlock(
  title: 'Breaking News',
);

// Text headline
final headline = TextHeadlineBlock(
  content: 'Major Announcement',
);

// Text paragraph
final paragraph = TextParagraphBlock(
  content: 'Lorem ipsum dolor sit amet...',
);

// Text caption
final caption = TextCaptionBlock(
  content: 'Image caption',
  color: TextCaptionColor.darkGrey,
);
```

### Create Media Blocks

```dart
// Image block
final image = ImageBlock(
  url: 'https://example.com/image.jpg',
  caption: 'A beautiful image',
);

// Video block
final video = VideoBlock(
  url: 'https://example.com/video.mp4',
  caption: 'A video',
);

// Slideshow block
final slideshow = SlideshowBlock(
  slides: [
    SlideBlock(
      url: 'https://example.com/slide1.jpg',
      caption: 'Slide 1',
    ),
    SlideBlock(
      url: 'https://example.com/slide2.jpg',
      caption: 'Slide 2',
    ),
  ],
  introduction: SlideshowIntroductionBlock(
    title: 'Gallery Title',
    description: 'Gallery description',
  ),
);
```

### Create Layout Blocks

```dart
// Divider
final divider = DividerHorizontalBlock();

// Spacer
final spacerSmall = SpacerBlock(spacing: Spacing.small);
final spacerMedium = SpacerBlock(spacing: Spacing.medium);
final spacerLarge = SpacerBlock(spacing: Spacing.large);

// Article introduction
final intro = ArticleIntroductionBlock(
  author: 'John Doe',
  publishedAt: DateTime.parse('2022-03-09T00:00:00.000'),
);
```

### Create Grid Blocks

```dart
// Grid tiles
final tile1 = PostGridTileBlock(
  id: 'article-1',
  category: Category.technology,
  imageUrl: 'https://example.com/image1.jpg',
  title: 'Article 1',
  isPremium: false,
  action: NavigateToArticleAction(articleId: 'article-1'),
);

final tile2 = PostGridTileBlock(
  id: 'article-2',
  category: Category.science,
  imageUrl: 'https://example.com/image2.jpg',
  title: 'Article 2',
  isPremium: false,
  action: NavigateToArticleAction(articleId: 'article-2'),
);

// Grid group
final gridGroup = PostGridGroupBlock(
  category: Category.technology,
  tiles: [tile1, tile2],
);
```

### Serialize/Deserialize Blocks

```dart
import 'dart:convert';

// Serialize
final block = PostLargeBlock(...);
final json = block.toJson();

// Deserialize
final block = NewsBlocksConverter().fromJson(json);
```

### Filter Blocks by Type

```dart
List<NewsBlock> blocks = [...];

// Filter for post blocks
final postBlocks = blocks.whereType<PostBlock>().toList();

// Filter for specific block type
final largePosts = blocks.whereType<PostLargeBlock>().toList();

// Filter by type string
final posts = blocks.where((b) => b.type == '__post_large__').toList();
```

### Find Blocks with Actions

```dart
List<NewsBlock> blocks = [...];

// Find blocks with navigate to article action
final articleLinks = blocks.where((block) {
  if (block is PostBlock) {
    return block.action is NavigateToArticleAction;
  }
  return false;
}).toList();

// Extract article IDs
final articleIds = articleLinks
    .whereType<PostBlock>()
    .map((b) => (b.action as NavigateToArticleAction).articleId)
    .toList();
```

## Testing Patterns

### Test Route

```dart
import 'package:dart_frog/dart_frog.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

class MockNewsDataSource extends Mock implements NewsDataSource {}

void main() {
  late NewsDataSource dataSource;

  setUp(() {
    dataSource = MockNewsDataSource();
  });

  test('returns feed on GET /api/v1/feed', () async {
    // Arrange
    final feed = Feed(blocks: [], totalBlocks: 0);
    when(() => dataSource.getFeed(any()))
        .thenAnswer((_) async => feed);

    final handler = createHandler(dataSource);

    // Act
    final response = await handler(RequestContext()).get('/api/v1/feed');

    // Assert
    expect(response.statusCode, equals(HttpStatus.ok));
    final body = await response.json();
    expect(body, containsPair('feed', isEmpty));
  });
}
```

### Test Data Source

```dart
void main() {
  late InMemoryNewsDataSource dataSource;

  setUp(() {
    dataSource = InMemoryNewsDataSource();
  });

  test('returns article by ID', () async {
    final article = await dataSource.getArticle(id: 'valid-id');
    expect(article, isNotNull);
    expect(article?.title, isNotEmpty);
  });

  test('returns null for non-existent article', () async {
    final article = await dataSource.getArticle(id: 'invalid-id');
    expect(article, isNull);
  });
}
```

### Test Block Serialization

```dart
void main() {
  test('serializes and deserializes PostLargeBlock', () {
    final block = PostLargeBlock(
      id: '123',
      category: Category.technology,
      author: 'Author',
      publishedAt: DateTime.now(),
      imageUrl: 'https://example.com/image.jpg',
      title: 'Title',
      isPremium: false,
      action: NavigateToArticleAction(articleId: '123'),
    );

    final json = block.toJson();
    final deserialized = PostLargeBlock.fromJson(json);

    expect(deserialized, equals(block));
  });
}
```

### Mock Data Source in Tests

```dart
import 'package:mocktail/mocktail.dart';

class MockNewsDataSource extends Mock implements NewsDataSource {}

void main() {
  late MockNewsDataSource mockDataSource;

  setUp(() {
    mockDataSource = MockNewsDataSource();
    registerFallbackValue(Category.top);
  });

  test('fetches feed from data source', () async {
    when(() => mockDataSource.getFeed(
      category: any(named: 'category'),
      limit: any(named: 'limit'),
      offset: any(named: 'offset'),
    )).thenAnswer((_) async => Feed(blocks: [], totalBlocks: 0));

    final feed = await mockDataSource.getFeed();
    verify(() => mockDataSource.getFeed()).called(1);
  });
}
```

## Common Patterns

### Create Custom Route Handler

```dart
import 'dart:io';
import 'package:dart_frog/dart_frog.dart';

Future<Response> onRequest(RequestContext context) async {
  // 1. Validate HTTP method
  if (context.request.method != HttpMethod.get) {
    return Response(statusCode: HttpStatus.methodNotAllowed);
  }

  // 2. Extract query parameters
  final params = context.request.url.queryParameters;
  final id = params['id'];

  // 3. Validate required parameters
  if (id == null || id.isEmpty) {
    return Response.json(
      statusCode: HttpStatus.badRequest,
      body: {'error': 'Missing required parameter: id'},
    );
  }

  // 4. Use injected dependencies
  final dataSource = context.read<NewsDataSource>();
  final article = await dataSource.getArticle(id: id);

  // 5. Handle not found
  if (article == null) {
    return Response(statusCode: HttpStatus.notFound);
  }

  // 6. Create response
  final response = ArticleResponse(
    content: article.blocks,
    totalCount: article.totalBlocks,
    url: article.url.toString(),
  );

  return Response.json(body: response);
}
```

### Add Custom Middleware

```dart
import 'package:dart_frog/dart_frog.dart';

Middleware customMiddleware() {
  return (handler) {
    return handler.use(
      provider<String>((context) => 'custom-value'),
    );
  };
}

// Apply in routes/_middleware.dart
Handler middleware(Handler handler) {
  return handler
      .use(requestLogger())
      .use(userProvider())
      .use(newsDataSourceProvider())
      .use(customMiddleware());
}
```

### Handle CORS

```dart
Middleware corsProvider() {
  return (handler) {
    return handler.use((request) async {
      final response = await handler(request);
      return response.change(
        headers: {
          'Access-Control-Allow-Origin': '*',
          'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
          'Access-Control-Allow-Headers': 'Content-Type, Authorization',
        },
      );
    });
  };
}
```

### Validate Query Parameters

```dart
// Parse integer with default
final limit = int.tryParse(params['limit'] ?? '') ?? 20;

// Parse category with default
final category = Category.values.firstWhere(
  (c) => c.name == params['category'],
  orElse: () => Category.top,
);

// Parse boolean
final preview = params['preview']?.toLowerCase() == 'true';

// Validate range
if (limit < 1 || limit > 100) {
  return Response.json(
    statusCode: HttpStatus.badRequest,
    body: {'error': 'limit must be between 1 and 100'},
  );
}
```

### Create Response Models

```dart
import 'package:json_annotation/json_annotation.dart';

part 'custom_response.g.dart';

@JsonSerializable()
class CustomResponse {
  const CustomResponse({
    required this.data,
    this.metadata,
  });

  factory CustomResponse.fromJson(Map<String, dynamic> json) =>
      _$CustomResponseFromJson(json);

  final String data;
  final Map<String, dynamic>? metadata;

  Map<String, dynamic> toJson() => _$CustomResponseToJson(this);
}

// Use in route
final response = CustomResponse(
  data: 'result',
  metadata: {'count': 42},
);
return Response.json(body: response);
```

### Implement Custom Data Source

```dart
import 'package:news_temp_api/api.dart';

class CustomNewsDataSource extends NewsDataSource {
  final CustomDatabase _database;

  CustomNewsDataSource(this._database);

  @override
  Future<Article?> getArticle({
    required String id,
    int limit = 20,
    int offset = 0,
    bool preview = false,
  }) async {
    final articleData = await _database.fetchArticle(id);
    if (articleData == null) return null;

    return Article(
      title: articleData['title'],
      blocks: _parseBlocks(articleData['blocks'], limit, offset),
      totalBlocks: articleData['blocks'].length,
      url: Uri.parse(articleData['url']),
    );
  }

  // Implement other methods...
}

// Use in middleware
Middleware customDataSourceProvider() {
  return (handler) {
    return handler.use(
      provider<NewsDataSource>(
        (_) => CustomNewsDataSource(CustomDatabase()),
      ),
    );
  };
}
```

### Handle Authentication

```dart
Future<Response> onRequest(RequestContext context) async {
  final user = context.read<RequestUser>();

  // Check authentication
  if (user.isAnonymous) {
    return Response(statusCode: HttpStatus.unauthorized);
  }

  // Access user data
  final userId = user.id;

  // Continue with request...
}
```

### Error Handling in Routes

```dart
Future<Response> onRequest(RequestContext context) async {
  try {
    final dataSource = context.read<NewsDataSource>();
    final data = await dataSource.getArticle(id: '123');

    if (data == null) {
      return Response(statusCode: HttpStatus.notFound);
    }

    return Response.json(body: data);
  } on FormatException catch (e) {
    return Response.json(
      statusCode: HttpStatus.badRequest,
      body: {'error': 'Invalid format: ${e.message}'},
    );
  } catch (e) {
    return Response.json(
      statusCode: HttpStatus.internalServerError,
      body: {'error': 'Internal server error'},
    );
  }
}
```

### Log Requests with Custom Format

```dart
Middleware customRequestLogger() {
  return (handler) {
    return handler.use((request) async {
      final startTime = DateTime.now();
      final response = await handler(request);
      final duration = DateTime.now().difference(startTime);

      print(
        '[${DateTime.now().toIso8601String()}] '
        '${request.method.value} ${request.url.path} '
        '${response.statusCode} ${duration.inMilliseconds}ms',
      );

      return response;
    });
  };
}
```

### Validate JSON Request Body

```dart
Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.post) {
    return Response(statusCode: HttpStatus.methodNotAllowed);
  }

  // Parse body
  final body = await context.request.json() as Map<String, dynamic>;

  // Validate required fields
  if (!body.containsKey('email')) {
    return Response.json(
      statusCode: HttpStatus.badRequest,
      body: {'error': 'Missing required field: email'},
    );
  }

  final email = body['email'] as String;

  // Validate email format
  if (!email.contains('@')) {
    return Response.json(
      statusCode: HttpStatus.badRequest,
      body: {'error': 'Invalid email format'},
    );
  }

  // Process request...
}
```

### Paginate Results

```dart
List<T> paginate<T>(List<T> items, int limit, int offset) {
  return items.skip(offset).take(limit).toList();
}

// Use in data source
@override
Future<Feed> getFeed({
  Category category = Category.top,
  int limit = 20,
  int offset = 0,
}) async {
  final allBlocks = _feed[category] ?? [];
  final paginated = paginate(allBlocks, limit, offset);

  return Feed(
    blocks: paginated,
    totalBlocks: allBlocks.length,
  );
}
```

### Transform Blocks

```dart
List<NewsBlock> transformBlocks(List<NewsBlock> blocks) {
  return blocks.map((block) {
    if (block is PostLargeBlock) {
      return PostMediumBlock(
        id: block.id,
        category: block.category,
        author: block.author,
        publishedAt: block.publishedAt,
        imageUrl: block.imageUrl,
        title: block.title,
        description: block.title.substring(0, 100),
        isPremium: block.isPremium,
        action: block.action,
      );
    }
    return block;
  }).toList();
}
```

### Filter Premium Content

```dart
Future<Feed> getNonPremiumFeed({
  Category category = Category.top,
  int limit = 20,
  int offset = 0,
}) async {
  final feed = await getFeed(category: category);
  final nonPremium = feed.blocks.where((block) {
    if (block is PostBlock) {
      return !block.isPremium;
    }
    return true;
  }).toList();

  return Feed(
    blocks: nonPremium.skip(offset).take(limit).toList(),
    totalBlocks: feed.totalBlocks,
  );
}
```

## Quick Reference

### HTTP Methods

```dart
HttpMethod.get      // GET /api/v1/feed
HttpMethod.post     // POST /api/v1/newsletter/subscription
HttpMethod.put      // PUT /api/v1/resource/:id
HttpMethod.delete   // DELETE /api/v1/resource/:id
```

### Status Codes

```dart
HttpStatus.ok                    // 200
HttpStatus.created               // 201
HttpStatus.noContent             // 204
HttpStatus.badRequest            // 400
HttpStatus.unauthorized          // 401
HttpStatus.forbidden             // 403
HttpStatus.notFound              // 404
HttpStatus.methodNotAllowed      // 405
HttpStatus.internalServerError   // 500
```

### Categories

```dart
Category.top           // Breaking news
Category.business      // Business news
Category.entertainment // Entertainment news
Category.general       // General news
Category.health        // Health news
Category.science       // Science news
Category.sports        // Sports news
Category.technology    // Technology news
```

### Subscription Plans

```dart
SubscriptionPlan.none    // No subscription
SubscriptionPlan.basic   // Basic plan
SubscriptionPlan.plus    // Plus plan
SubscriptionPlan.premium // Premium plan
```

### Spacing Values

```dart
Spacing.extraSmall
Spacing.small
Spacing.medium
Spacing.large
Spacing.extraLarge
```

### Text Caption Colors

```dart
TextCaptionColor.darkGrey
TextCaptionColor.lightGrey
```

## Common Tasks

### Add new endpoint
1. Create route file in `routes/api/v1/`
2. Implement `onRequest` handler
3. Add tests in `test/routes/`
4. Update `docs/api.apib`

### Add new block type
1. Create block class in `packages/news_blocks/lib/src/`
2. Implement `NewsBlock` interface
3. Add to `packages/news_blocks/lib/news_blocks.dart`
4. Create tests in `packages/news_blocks/test/`
5. Run `dart run build_runner build`

### Update data source
1. Add method to `NewsDataSource` interface
2. Implement in `InMemoryNewsDataSource`
3. Add tests
4. Use in routes

### Add authentication
1. Extract token in middleware
2. Create `RequestUser` object
3. Check authentication in routes
4. Handle unauthorized requests

For more detailed documentation, see:
- [README.md](README.md) - Project overview
- [ARCHITECTURE.md](ARCHITECTURE.md) - Architecture details
- [docs/api.apib](docs/api.apib) - API Blueprint documentation
