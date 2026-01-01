# News Temp API

A modern, scalable news API built with Dart and Dart Frog, designed to serve news content with a block-based architecture for flexible content rendering.

## Overview

News Temp API is a RESTful API that provides news articles, feeds, categories, and subscription management. It uses a block-based content system where each piece of content is represented as a typed block, enabling flexible rendering across different platforms.

## Key Features

- **Block-Based Content Architecture**: Content is composed of typed blocks (articles, images, videos, text, etc.)
- **RESTful API Design**: Clean, intuitive endpoints following REST principles
- **Category-Based Feeds**: Organize content by business, entertainment, health, science, sports, technology
- **User & Subscription Management**: Support for user profiles and subscription plans
- **Search Functionality**: Popular and relevance-based search capabilities
- **Newsletter Subscriptions**: Email newsletter subscription management
- **Middleware-First Design**: Request logging, user authentication, data source injection
- **In-Memory Data Source**: Built-in static data for development and testing
- **Comprehensive Testing**: Unit and integration tests for routes, models, and data sources

## Technology Stack

- **Language**: Dart (>=3.0.0)
- **Framework**: Dart Frog (server-side framework)
- **Serialization**: json_annotation + json_serializable
- **HTTP Client**: http package
- **Testing**: mocktail + test
- **Code Quality**: very_good_analysis

## Project Structure

```
api/
├── docs/                    # API Blueprint documentation
├── lib/                     # Server-side library
│   ├── src/
│   │   ├── client/         # API client for consuming the API
│   │   ├── data/           # Data models and sources
│   │   ├── middleware/     # Request middleware (auth, logging)
│   │   └── models/         # Response models
│   ├── api.dart            # Server-side library exports
│   └── client.dart         # Client-side library exports
├── packages/
│   └── news_blocks/        # Reusable content block types
├── routes/                 # Route handlers
│   ├── _middleware.dart   # Global middleware
│   └── api/v1/            # API endpoints
└── test/                  # Test suite
```

## Getting Started

### Prerequisites

- Dart SDK (>=3.0.0)
- Dart Frog CLI

### Installation

```bash
# Install Dart Frog globally
dart pub global activate dart_frog_cli

# Install dependencies
dart pub get
```

### Running the Server

```bash
# Development mode (with hot reload)
dart_frog dev

# Production build
dart_frog build
cd build
dart bin/server.dart
```

The server will start on [http://localhost:8080](http://localhost:8080)

### Running Tests

```bash
# Run all tests
dart test

# Run tests with coverage
dart test --coverage=coverage

# Generate code (for .g.dart files)
dart run build_runner build --delete-conflicting-outputs
```

## API Documentation

Interactive API documentation is available using API Blueprint:

```bash
# Install Apiary Client
gem install apiaryio

# Run documentation preview
apiary preview --path docs/api.apib --watch
```

Documentation available at [http://localhost:8080](http://localhost:8080)

## Architecture

### Data Layer

The API uses an abstract `NewsDataSource` interface, implemented by `InMemoryNewsDataSource` for static data:

```dart
abstract class NewsDataSource {
  Future<Article?> getArticle({required String id, ...});
  Future<Feed> getFeed({Category category, ...});
  Future<List<Category>> getCategories();
  Future<List<String>> getPopularTopics();
  // ... more methods
}
```

### Middleware

Request middleware is applied at the route level:

- **userProvider**: Extracts and provides the authenticated user from Bearer token
- **newsDataSourceProvider**: Injects the data source into the request context
- **requestLogger**: Logs incoming requests

### Routes

Routes follow a RESTful structure under `/api/v1/`:

- `GET /` - Health check (204 No Content)
- `GET /api/v1/articles/:id` - Get article content
- `GET /api/v1/articles/:id/related` - Get related articles
- `GET /api/v1/feed` - Get news feed
- `GET /api/v1/categories` - Get all categories
- `GET /api/v1/search/popular` - Get popular content
- `GET /api/v1/search/relevant` - Search relevant content
- `POST /api/v1/newsletter/subscription` - Subscribe to newsletter
- `GET /api/v1/subscriptions` - Get available subscriptions
- `POST /api/v1/subscriptions` - Create subscription
- `GET /api/v1/users/me` - Get current user

## News Blocks Package

The `news_blocks` package provides a reusable, type-safe system for representing content blocks:

### Block Types

- **Post Blocks**: `PostLargeBlock`, `PostMediumBlock`, `PostSmallBlock`
- **Grid Blocks**: `PostGridGroupBlock`, `PostGridTileBlock`
- **Text Blocks**: `SectionHeaderBlock`, `TextHeadlineBlock`, `TextParagraphBlock`, etc.
- **Media Blocks**: `ImageBlock`, `VideoBlock`, `SlideshowBlock`
- **Layout Blocks**: `DividerHorizontalBlock`, `SpacerBlock`, `ArticleIntroductionBlock`
- **Action Blocks**: `BlockAction` with navigation types

All blocks implement the `NewsBlock` interface and support JSON serialization via `NewsBlocksConverter`.

## Response Models

The API provides typed response models for all endpoints:

- `ArticleResponse`: Article content with blocks and URL
- `FeedResponse`: Feed blocks with pagination
- `CategoriesResponse`: Available categories
- `PopularSearchResponse`: Popular topics and articles
- `RelevantSearchResponse`: Relevant search results
- `SubscriptionsResponse`: Available subscription plans
- `CurrentUserResponse`: Current user profile
- `RelatedArticlesResponse`: Related article blocks

## Client Usage

Use the `NewsTempApiClient` to consume the API:

```dart
import 'package:news_temp_api/client.dart';

final client = NewsTempApiClient.localhost(
  tokenProvider: () async => 'your-token-here',
);

final feed = await client.getFeed(category: Category.technology);
final article = await client.getArticle(id: 'article-id');
```

See [CHEATSHEET.md](CHEATSHEET.md) for common usage patterns.

## Development

### Code Generation

The project uses code generation for JSON serialization:

```bash
# Generate serialization code
dart run build_runner build --delete-conflicting-outputs

# Watch for changes
dart run build_runner watch --delete-conflicting-outputs
```

### Adding a New Endpoint

1. Create the route file in `routes/api/v1/`
2. Implement `onRequest` handler
3. Add tests in `test/routes/`
4. Update API documentation in `docs/api.apib`
5. Run tests to verify

### Adding a New Block Type

1. Add block class to `packages/news_blocks/lib/src/`
2. Implement `NewsBlock` interface
3. Add to `news_blocks.dart` exports
4. Create tests in `packages/news_blocks/test/`
5. Run `build_runner` for serialization

## Docker Deployment

```bash
# Build production version
dart_frog build

# Build Docker image
cd build
docker build -t news-temp-api .

# Run container
docker run -d -p 8080:8080 news-temp-api
```

## License

See LICENSE file for details.

## Contributing

See [ARCHITECTURE.md](ARCHITECTURE.md) for detailed architecture documentation and [CHEATSHEET.md](CHEATSHEET.md) for usage examples.

## Support

For issues and questions, please open a GitHub issue.
