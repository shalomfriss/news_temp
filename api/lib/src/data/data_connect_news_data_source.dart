import 'dart:convert';
import 'dart:math' as math;

import 'package:http/http.dart' as http;
import 'package:news_blocks/news_blocks.dart';
import 'package:news_temp_api/api.dart';

/// An exception thrown when a Data Connect request fails.
class DataConnectRequestFailure implements Exception {
  const DataConnectRequestFailure({
    required this.statusCode,
    required this.body,
  });

  final int statusCode;
  final Map<String, dynamic> body;
}

/// A lightweight client for Firebase Data Connect GraphQL endpoints.
class DataConnectClient {
  DataConnectClient({
    required String endpoint,
    http.Client? httpClient,
    this.apiKey,
    this.authTokenProvider,
  })  : _endpoint = endpoint,
        _httpClient = httpClient ?? http.Client();

  final String _endpoint;
  final http.Client _httpClient;
  final String? apiKey;
  final Future<String?> Function()? authTokenProvider;

  Future<Map<String, dynamic>> query(
    String query, {
    Map<String, dynamic>? variables,
  }) async {
    final uri = _endpointUri();
    final token = await authTokenProvider?.call();
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
    final response = await _httpClient.post(
      uri,
      headers: headers,
      body: jsonEncode(<String, dynamic>{
        'query': query,
        'variables': variables ?? <String, dynamic>{},
      }),
    );

    final decoded = _decodeBody(response.body);
    if (response.statusCode != 200) {
      throw DataConnectRequestFailure(
        statusCode: response.statusCode,
        body: decoded,
      );
    }
    if (decoded['errors'] != null) {
      throw DataConnectRequestFailure(
        statusCode: response.statusCode,
        body: decoded,
      );
    }
    return decoded['data'] as Map<String, dynamic>? ??
        const <String, dynamic>{};
  }

  Uri _endpointUri() {
    final parsed = Uri.parse(_endpoint);
    if (apiKey == null || apiKey!.isEmpty) return parsed;
    return parsed.replace(
      queryParameters: <String, String>{
        ...parsed.queryParameters,
        'key': apiKey!,
      },
    );
  }

  Map<String, dynamic> _decodeBody(String body) {
    if (body.isEmpty) return const <String, dynamic>{};
    return jsonDecode(body) as Map<String, dynamic>;
  }
}

/// A [NewsDataSource] backed by Firebase Data Connect.
class DataConnectNewsDataSource implements NewsDataSource {
  DataConnectNewsDataSource({
    required String endpoint,
    String? apiKey,
    http.Client? httpClient,
    Future<String?> Function()? authTokenProvider,
  }) : _client = DataConnectClient(
          endpoint: endpoint,
          apiKey: apiKey,
          httpClient: httpClient,
          authTokenProvider: authTokenProvider,
        );

  final DataConnectClient _client;
  final NewsBlocksConverter _blocksConverter = const NewsBlocksConverter();

  static const _getCategoriesQuery = r'''
    query GetCategories {
      categories {
        name
      }
    }
  ''';

  static const _getFeedQuery = r'''
    query GetFeed($category: String!) {
      feeds_by_pk(category: $category) {
        blocks_json
        total_count
      }
    }
  ''';

  static const _getArticleQuery = r'''
    query GetArticle($id: String!) {
      articles_by_pk(id: $id) {
        id
        title
        url
        is_premium
        total_count
        content_json
        content_preview_json
        post_json
      }
    }
  ''';

  static const _getArticleMetaQuery = r'''
    query GetArticleMeta($id: String!) {
      articles_by_pk(id: $id) {
        is_premium
      }
    }
  ''';

  static const _getRelatedArticlesQuery = r'''
    query GetRelatedArticles($id: String!) {
      related_articles_by_pk(article_id: $id) {
        blocks_json
        total_count
      }
    }
  ''';

  static const _getPopularSearchQuery = r'''
    query GetPopularSearch {
      popular_search_by_pk(id: "current") {
        topics_json
        articles_json
      }
    }
  ''';

  static const _getRelevantSearchQuery = r'''
    query GetRelevantSearch($term: String!) {
      relevant_search_by_pk(term: $term) {
        topics_json
        articles_json
      }
    }
  ''';

  static const _getSubscriptionsQuery = r'''
    query GetSubscriptions {
      subscriptions {
        id
        name
        monthly
        annual
        benefits_json
      }
    }
  ''';

  static const _getSubscriptionPlanQuery = r'''
    query GetSubscriptionPlan($id: String!) {
      subscriptions_by_pk(id: $id) {
        name
      }
    }
  ''';

  static const _getUserQuery = r'''
    query GetUser($id: String!) {
      users_by_pk(id: $id) {
        id
        subscription
      }
    }
  ''';

  static const _upsertUserSubscriptionMutation = r'''
    mutation UpsertUserSubscription($id: String!, $subscription: String!) {
      insert_users_one(
        object: { id: $id, subscription: $subscription }
        on_conflict: { constraint: users_pkey, update_columns: [subscription] }
      ) {
        id
        subscription
      }
    }
  ''';

  @override
  Future<List<Category>> getCategories() async {
    final data = await _client.query(_getCategoriesQuery);
    final items = (data['categories'] as List<dynamic>? ?? const <dynamic>[]);
    return items
        .map((item) => item as Map<String, dynamic>)
        .map((item) => Category.fromString(item['name'] as String))
        .toList();
  }

  @override
  Future<Feed> getFeed({
    Category category = Category.top,
    int limit = 20,
    int offset = 0,
  }) async {
    final data = await _client.query(
      _getFeedQuery,
      variables: <String, dynamic>{'category': category.name},
    );
    final feed = data['feeds_by_pk'] as Map<String, dynamic>?;
    if (feed == null) return const Feed(blocks: [], totalBlocks: 0);
    final blocks = _decodeBlocks(feed['blocks_json'] as String?);
    final totalBlocks = _intFrom(feed['total_count'], blocks.length);
    final paged = _paginateBlocks(blocks, limit, offset);
    return Feed(blocks: paged, totalBlocks: totalBlocks);
  }

  @override
  Future<Article?> getArticle({
    required String id,
    int limit = 20,
    int offset = 0,
    bool preview = false,
  }) async {
    final data = await _client.query(
      _getArticleQuery,
      variables: <String, dynamic>{'id': id},
    );
    final article = data['articles_by_pk'] as Map<String, dynamic>?;
    if (article == null) return null;

    final content = _decodeBlocks(article['content_json'] as String?);
    final contentPreview =
        _decodeBlocks(article['content_preview_json'] as String?);
    final blocks = preview && contentPreview.isNotEmpty
        ? contentPreview
        : content;

    final totalBlocks = preview
        ? blocks.length
        : _intFrom(article['total_count'], content.length);
    final paged = _paginateBlocks(blocks, limit, offset);

    final title = article['title'] as String? ?? '';
    final url = Uri.tryParse(article['url'] as String? ?? '') ?? Uri();

    return Article(
      title: title,
      blocks: paged,
      totalBlocks: totalBlocks,
      url: url,
    );
  }

  @override
  Future<bool?> isPremiumArticle({required String id}) async {
    final data = await _client.query(
      _getArticleMetaQuery,
      variables: <String, dynamic>{'id': id},
    );
    final article = data['articles_by_pk'] as Map<String, dynamic>?;
    return article?['is_premium'] as bool?;
  }

  @override
  Future<List<String>> getPopularTopics() async {
    final data = await _client.query(_getPopularSearchQuery);
    final payload = data['popular_search_by_pk'] as Map<String, dynamic>?;
    return _decodeStringList(payload?['topics_json'] as String?);
  }

  @override
  Future<List<String>> getRelevantTopics({required String term}) async {
    final data = await _client.query(
      _getRelevantSearchQuery,
      variables: <String, dynamic>{'term': term},
    );
    final payload = data['relevant_search_by_pk'] as Map<String, dynamic>?;
    return _decodeStringList(payload?['topics_json'] as String?);
  }

  @override
  Future<List<NewsBlock>> getPopularArticles() async {
    final data = await _client.query(_getPopularSearchQuery);
    final payload = data['popular_search_by_pk'] as Map<String, dynamic>?;
    return _decodeBlocks(payload?['articles_json'] as String?);
  }

  @override
  Future<List<NewsBlock>> getRelevantArticles({required String term}) async {
    final data = await _client.query(
      _getRelevantSearchQuery,
      variables: <String, dynamic>{'term': term},
    );
    final payload = data['relevant_search_by_pk'] as Map<String, dynamic>?;
    return _decodeBlocks(payload?['articles_json'] as String?);
  }

  @override
  Future<RelatedArticles> getRelatedArticles({
    required String id,
    int limit = 20,
    int offset = 0,
  }) async {
    final data = await _client.query(
      _getRelatedArticlesQuery,
      variables: <String, dynamic>{'id': id},
    );
    final related = data['related_articles_by_pk'] as Map<String, dynamic>?;
    if (related == null) return const RelatedArticles.empty();
    final blocks = _decodeBlocks(related['blocks_json'] as String?);
    final totalBlocks = _intFrom(related['total_count'], blocks.length);
    final paged = _paginateBlocks(blocks, limit, offset);
    return RelatedArticles(blocks: paged, totalBlocks: totalBlocks);
  }

  @override
  Future<void> createSubscription({
    required String userId,
    required String subscriptionId,
  }) async {
    final data = await _client.query(
      _getSubscriptionPlanQuery,
      variables: <String, dynamic>{'id': subscriptionId},
    );
    final subscription = data['subscriptions_by_pk'] as Map<String, dynamic>?;
    final planName = subscription?['name'] as String?;
    if (planName == null || planName.isEmpty) return;

    await _client.query(
      _upsertUserSubscriptionMutation,
      variables: <String, dynamic>{
        'id': userId,
        'subscription': planName,
      },
    );
  }

  @override
  Future<List<Subscription>> getSubscriptions() async {
    final data = await _client.query(_getSubscriptionsQuery);
    final items = data['subscriptions'] as List<dynamic>? ?? const <dynamic>[];
    return items
        .map((item) => item as Map<String, dynamic>)
        .map(_toSubscription)
        .toList();
  }

  @override
  Future<User?> getUser({required String userId}) async {
    final data = await _client.query(
      _getUserQuery,
      variables: <String, dynamic>{'id': userId},
    );
    final user = data['users_by_pk'] as Map<String, dynamic>?;
    if (user == null) return null;
    final subscription = _subscriptionPlanFrom(user['subscription'] as String?);
    return User(id: user['id'] as String, subscription: subscription);
  }

  Subscription _toSubscription(Map<String, dynamic> data) {
    return Subscription(
      id: data['id'] as String,
      name: _subscriptionPlanFrom(data['name'] as String?),
      cost: SubscriptionCost(
        monthly: _intFrom(data['monthly'], 0),
        annual: _intFrom(data['annual'], 0),
      ),
      benefits: _decodeStringList(data['benefits_json'] as String?),
    );
  }

  SubscriptionPlan _subscriptionPlanFrom(String? value) {
    if (value == null) return SubscriptionPlan.none;
    return SubscriptionPlan.values.firstWhere(
      (plan) => plan.name == value,
      orElse: () => SubscriptionPlan.none,
    );
  }

  List<NewsBlock> _decodeBlocks(String? raw) {
    if (raw == null || raw.isEmpty) return const <NewsBlock>[];
    final decoded = jsonDecode(raw);
    if (decoded is! List) return const <NewsBlock>[];
    return _blocksConverter.fromJson(decoded);
  }

  List<String> _decodeStringList(String? raw) {
    if (raw == null || raw.isEmpty) return const <String>[];
    final decoded = jsonDecode(raw);
    if (decoded is! List) return const <String>[];
    return decoded.whereType<String>().toList();
  }

  List<NewsBlock> _paginateBlocks(
    List<NewsBlock> blocks,
    int limit,
    int offset,
  ) {
    if (blocks.isEmpty) return const <NewsBlock>[];
    final start = math.min(offset, blocks.length);
    return blocks.sublist(start).take(limit).toList();
  }

  int _intFrom(Object? raw, int fallback) {
    if (raw is int) return raw;
    if (raw is num) return raw.toInt();
    return fallback;
  }
}
