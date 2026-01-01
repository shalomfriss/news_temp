# News Temp API ☁️

A modern, scalable news API built with Dart and Dart Frog, designed to serve news content with a block-based architecture for flexible content rendering.

## Quick Start

```bash
# Install dependencies
dart pub get

# Run development server
dart_frog dev

# Run tests
dart test
```

Server starts at [http://localhost:8080](http://localhost:8080)

## Documentation

| Document | Description |
|----------|-------------|
| [DOCUMENTATION.md](DOCUMENTATION.md) | Comprehensive project documentation, setup, and usage guide |
| [ARCHITECTURE.md](ARCHITECTURE.md) | Detailed architecture, design patterns, and system design |
| [CHEATSHEET.md](CHEATSHEET.md) | Quick reference for common usage patterns and code examples |
| [docs/api.apib](docs/api.apib) | Interactive API Blueprint specification |

## Overview

News Temp API is a RESTful API that provides:

- **Block-Based Content Architecture**: Flexible content rendering with typed blocks
- **Category-Based Feeds**: News organized by topic (business, tech, health, etc.)
- **User & Subscription Management**: Profile and subscription plan support
- **Search Functionality**: Popular and relevance-based search
- **Newsletter Subscriptions**: Email newsletter management
- **Comprehensive Testing**: Full test coverage

## Key Features

- 🔧 Built with Dart Frog (>=3.0.0)
- 📦 Modular architecture with news_blocks package
- 🧪 Extensive test suite
- 📚 Type-safe models with code generation
- 🔑 Token-based authentication
- 📊 Pagination support
- 🎯 Clean RESTful API design

## API Endpoints

### Articles
- `GET /api/v1/articles/:id` - Get article content
- `GET /api/v1/articles/:id/related` - Get related articles

### Feed
- `GET /api/v1/feed` - Get news feed (with category filter)

### Categories
- `GET /api/v1/categories` - Get all categories

### Search
- `GET /api/v1/search/popular` - Get popular content
- `GET /api/v1/search/relevant` - Search relevant content

### Newsletter
- `POST /api/v1/newsletter/subscription` - Subscribe to newsletter

### Subscriptions
- `GET /api/v1/subscriptions` - Get available subscriptions
- `POST /api/v1/subscriptions` - Create subscription

### Users
- `GET /api/v1/users/me` - Get current user

## Running the Server

### Development Mode
```bash
dart_frog dev
```

### Production Mode
```bash
dart_frog build
cd build
dart bin/server.dart
```

### Docker
```bash
dart_frog build
cd build
docker build -t news-temp-api .
docker run -d -p 8080:8080 news-temp-api
```

## Running Tests

```bash
# All tests
dart test

# With coverage
dart test --coverage=coverage

# Specific test file
dart test test/routes/feed/index_test.dart
```

## Code Generation

```bash
# Generate .g.dart files
dart run build_runner build --delete-conflicting-outputs

# Watch mode
dart run build_runner watch --delete-conflicting-outputs
```

## Interactive API Documentation

```bash
# Install Apiary Client
gem install apiaryio

# Preview documentation
apiary preview --path docs/api.apib --watch
```

Documentation available at [http://localhost:8080](http://localhost:8080)

## Project Structure

```
api/
├── docs/                    # API Blueprint documentation
├── lib/                     # Server-side library
│   ├── src/
│   │   ├── client/         # API client
│   │   ├── data/           # Data models & sources
│   │   ├── middleware/     # Request middleware
│   │   └── models/         # Response models
│   ├── api.dart            # Server-side exports
│   └── client.dart         # Client-side exports
├── packages/
│   └── news_blocks/        # Reusable content blocks
├── routes/                 # Route handlers
└── test/                  # Test suite
```

## Client Usage Example

```dart
import 'package:news_temp_api/client.dart';

final client = NewsTempApiClient.localhost(
  tokenProvider: () async => 'your-token',
);

// Get feed
final feed = await client.getFeed(category: Category.technology);
print('Articles: ${feed.feed.length}');

// Get article
final article = await client.getArticle(id: 'article-123');
print('Title: ${article.content.first}');
```

See [CHEATSHEET.md](CHEATSHEET.md) for more examples.

## Adding New Features

### Add New Endpoint
1. Create route file in `routes/api/v1/`
2. Implement `onRequest` handler
3. Add tests in `test/routes/`
4. Update `docs/api.apib`

### Add New Block Type
1. Create block class in `packages/news_blocks/lib/src/`
2. Implement `NewsBlock` interface
3. Add to exports
4. Create tests
5. Run code generation

## Technology Stack

- **Language**: Dart (>=3.0.0)
- **Framework**: Dart Frog
- **Serialization**: json_annotation + json_serializable
- **HTTP**: http package
- **Testing**: mocktail + test
- **Linting**: very_good_analysis

## Architecture

The API follows a layered architecture:

```
Presentation (Routes) → Middleware → Data Layer → Data Source
```

See [ARCHITECTURE.md](ARCHITECTURE.md) for detailed design.

## Common Tasks

| Task | Command |
|------|---------|
| Start dev server | `dart_frog dev` |
| Run tests | `dart test` |
| Generate code | `dart run build_runner build` |
| Format code | `dart format .` |
| Analyze code | `dart analyze` |
| Preview docs | `apiary preview --path docs/api.apib --watch` |

See [CHEATSHEET.md](CHEATSHEET.md) for comprehensive usage patterns.

## License

See LICENSE file for details.

## Contributing

Contributions are welcome! Please see the documentation for details on:
- Architecture and design patterns ([ARCHITECTURE.md](ARCHITECTURE.md))
- Common usage patterns ([CHEATSHEET.md](CHEATSHEET.md))
- API specification ([docs/api.apib](docs/api.apib))
