import 'dart:io';
import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:news_temp_api/api.dart';
import 'package:news_temp_api/client.dart';

class NewsRemoteApiClient extends NewsTempApiClient {
  NewsRemoteApiClient({
    required String baseUrl,
    required TokenProvider tokenProvider,
    FirebaseFirestore? firestore,
    http.Client? httpClient,
  })  : _customBaseUrl = baseUrl,
        _firestore = firestore ?? FirebaseFirestore.instance,
        _tokenProvider = tokenProvider,
        super(
          tokenProvider: tokenProvider,
          httpClient: httpClient,
        );

  final String _customBaseUrl;
  final FirebaseFirestore _firestore;
  final TokenProvider _tokenProvider;

  String get baseUrl => _customBaseUrl;

  static const _categoriesCollection = 'categories';
  static const _feedCollection = 'feed';
  static const _articlesCollection = 'articles';
  static const _relatedArticlesCollection = 'related_articles';
  static const _popularSearchCollection = 'popular_search';
  static const _relevantSearchCollection = 'relevant_search';
  static const _subscriptionsCollection = 'subscriptions';
  static const _usersCollection = 'users';
  static const _newsletterCollection = 'newsletter_subscriptions';

  final NewsBlocksConverter _blocksConverter = const NewsBlocksConverter();

  @override
  Future<CategoriesResponse> getCategories() async {
    final snapshot = await _firestore.collection(_categoriesCollection).get();
    final categories = snapshot.docs.map((doc) {
      final data = doc.data();
      final name = data['name'] as String? ?? doc.id;
      return Category.fromString(name);
    }).toList();
    return CategoriesResponse(categories: categories);
  }

  @override
  Future<FeedResponse> getFeed({
    Category? category,
    int? limit,
    int? offset,
  }) async {
    final selectedCategory = category ?? Category.top;
    final doc = await _firestore
        .collection(_feedCollection)
        .doc(selectedCategory.name)
        .get();
    final data = doc.data();
    if (data == null) {
      return const FeedResponse(feed: [], totalCount: 0);
    }
    final blocks = _blocksFrom(data['blocks'] ?? data['feed']);
    final totalCount =
        _intFrom(data['totalCount'] ?? data['totalBlocks'], blocks.length);
    final paged = _paginateBlocks(blocks, limit, offset);
    return FeedResponse(feed: paged, totalCount: totalCount);
  }

  @override
  Future<ArticleResponse> getArticle({
    required String id,
    int? limit,
    int? offset,
    bool preview = false,
  }) async {
    final doc = await _firestore.collection(_articlesCollection).doc(id).get();
    final data = doc.data();
    if (data == null) {
      throw NewsTempApiRequestFailure(
        statusCode: HttpStatus.notFound,
        body: const <String, dynamic>{},
      );
    }

    final content = _blocksFrom(data['content'] ?? data['blocks']);
    final previewBlocks =
        _blocksFrom(data['contentPreview'] ?? data['preview']);
    final blocks =
        preview && previewBlocks.isNotEmpty ? previewBlocks : content;
    final totalCount = preview
        ? blocks.length
        : _intFrom(
            data['totalCount'] ?? data['totalBlocks'],
            content.length,
          );
    final paged = _paginateBlocks(blocks, limit, offset);

    final postBlock = _postFrom(data['post']);
    final title = data['title'] as String? ?? postBlock?.title ?? '';
    final url = _uriFrom(data['url']) ?? Uri();
    final isPremium =
        data['isPremium'] as bool? ?? postBlock?.isPremium ?? false;

    return ArticleResponse(
      title: title,
      content: paged,
      totalCount: totalCount,
      url: url,
      isPremium: isPremium,
      isPreview: preview,
    );
  }

  @override
  Future<RelatedArticlesResponse> getRelatedArticles({
    required String id,
    int? limit,
    int? offset,
  }) async {
    final relatedDoc =
        await _firestore.collection(_relatedArticlesCollection).doc(id).get();
    final relatedData = relatedDoc.data();
    final fallbackData = relatedData ??
        (await _firestore.collection(_articlesCollection).doc(id).get()).data();
    if (fallbackData == null) {
      return const RelatedArticlesResponse(
        relatedArticles: [],
        totalCount: 0,
      );
    }
    final blocks = _blocksFrom(
      fallbackData['blocks'] ??
          fallbackData['relatedArticles'] ??
          fallbackData['related_articles'],
    );
    final totalCount = _intFrom(
      fallbackData['totalCount'] ?? fallbackData['totalBlocks'],
      blocks.length,
    );
    final paged = _paginateBlocks(blocks, limit, offset);
    return RelatedArticlesResponse(
      relatedArticles: paged,
      totalCount: totalCount,
    );
  }

  @override
  Future<PopularSearchResponse> popularSearch() async {
    final currentDoc = await _firestore
        .collection(_popularSearchCollection)
        .doc('current')
        .get();
    final data = currentDoc.data();
    Map<String, dynamic>? fallbackData;
    if (data == null) {
      final fallbackSnapshot =
          await _firestore.collection(_popularSearchCollection).limit(1).get();
      fallbackData = fallbackSnapshot.docs.isNotEmpty
          ? fallbackSnapshot.docs.first.data()
          : null;
    }
    final searchData = data ?? fallbackData;
    if (searchData == null) {
      return const PopularSearchResponse(articles: [], topics: []);
    }
    return PopularSearchResponse(
      articles: _blocksFrom(searchData['articles']),
      topics: _stringListFrom(searchData['topics']),
    );
  }

  @override
  Future<RelevantSearchResponse> relevantSearch({required String term}) async {
    final query = await _firestore
        .collection(_relevantSearchCollection)
        .where('term', isEqualTo: term)
        .limit(1)
        .get();
    final data = query.docs.isNotEmpty
        ? query.docs.first.data()
        : (await _firestore
                .collection(_relevantSearchCollection)
                .doc(term)
                .get())
            .data();
    if (data == null) {
      return const RelevantSearchResponse(articles: [], topics: []);
    }
    return RelevantSearchResponse(
      articles: _blocksFrom(data['articles']),
      topics: _stringListFrom(data['topics']),
    );
  }

  @override
  Future<void> subscribeToNewsletter({required String email}) async {
    await _firestore.collection(_newsletterCollection).add(
      <String, dynamic>{
        'email': email,
        'createdAt': DateTime.now().toUtc(),
      },
    );
  }

  @override
  Future<void> createSubscription({required String subscriptionId}) async {
    final userId = await _tokenProvider();
    if (userId == null || userId.isEmpty) {
      throw NewsTempApiRequestFailure(
        statusCode: HttpStatus.unauthorized,
        body: const <String, dynamic>{},
      );
    }
    final planName = await _subscriptionPlanName(subscriptionId);
    if (planName == null) {
      throw NewsTempApiRequestFailure(
        statusCode: HttpStatus.notFound,
        body: const <String, dynamic>{},
      );
    }
    await _firestore.collection(_usersCollection).doc(userId).set(
      <String, dynamic>{
        'id': userId,
        'subscription': planName,
      },
      SetOptions(merge: true),
    );
  }

  @override
  Future<SubscriptionsResponse> getSubscriptions() async {
    final snapshot =
        await _firestore.collection(_subscriptionsCollection).get();
    final subscriptions = snapshot.docs.map((doc) {
      final data = <String, dynamic>{
        ...doc.data(),
        if (!doc.data().containsKey('id')) 'id': doc.id,
      };
      return Subscription.fromJson(data);
    }).toList();
    return SubscriptionsResponse(subscriptions: subscriptions);
  }

  @override
  Future<CurrentUserResponse> getCurrentUser() async {
    final userId = await _tokenProvider();
    if (userId == null || userId.isEmpty) {
      return const CurrentUserResponse(
        user: User(id: '', subscription: SubscriptionPlan.none),
      );
    }
    final doc = await _firestore.collection(_usersCollection).doc(userId).get();
    final data = doc.data();
    if (data == null) {
      return CurrentUserResponse(
        user: User(id: userId, subscription: SubscriptionPlan.none),
      );
    }
    final normalized = <String, dynamic>{
      ...data,
      if (!data.containsKey('id')) 'id': userId,
    };
    return CurrentUserResponse(user: User.fromJson(normalized));
  }

  List<NewsBlock> _blocksFrom(Object? raw) {
    if (raw is List) {
      return _blocksConverter.fromJson(raw);
    }
    return const <NewsBlock>[];
  }

  List<String> _stringListFrom(Object? raw) {
    if (raw is Iterable) {
      return raw.whereType<String>().toList();
    }
    return const <String>[];
  }

  int _intFrom(Object? raw, int fallback) {
    if (raw is int) return raw;
    if (raw is num) return raw.toInt();
    return fallback;
  }

  Uri? _uriFrom(Object? raw) {
    if (raw is Uri) return raw;
    if (raw is String && raw.isNotEmpty) return Uri.tryParse(raw);
    return null;
  }

  PostBlock? _postFrom(Object? raw) {
    if (raw is Map<String, dynamic>) {
      final block = NewsBlock.fromJson(raw);
      if (block is PostBlock) return block;
    }
    return null;
  }

  List<NewsBlock> _paginateBlocks(
    List<NewsBlock> blocks,
    int? limit,
    int? offset,
  ) {
    if (blocks.isEmpty) return const <NewsBlock>[];
    final start = math.min(offset ?? 0, blocks.length);
    final pageLimit = limit ?? blocks.length;
    return blocks.sublist(start).take(pageLimit).toList();
  }

  Future<String?> _subscriptionPlanName(String subscriptionId) async {
    final directDoc = await _firestore
        .collection(_subscriptionsCollection)
        .doc(subscriptionId)
        .get();
    if (directDoc.data() != null) {
      return directDoc.data()!['name'] as String?;
    }
    final query = await _firestore
        .collection(_subscriptionsCollection)
        .where('id', isEqualTo: subscriptionId)
        .limit(1)
        .get();
    if (query.docs.isNotEmpty) {
      return query.docs.first.data()['name'] as String?;
    }
    return null;
  }
}

// class FirebaseNewsDataSource implements NewsDataSource {
//   // @override  // @override
//   //   // Future<List<Category>> getCategories() async {
//   //   //   final snapshot = await _firestore.collection('categories').get();
//   //   //   return snapshot.docs
//   //   //       .map((doc) => Category.fromString(doc.get('name') as String))
//   //   //       .toList();
//   //   // }
//   // Future<List<Category>> getCategories() async {
//   //   final snapshot = await _firestore.collection('categories').get();
//   //   return snapshot.docs
//   //       .map((doc) => Category.fromString(doc.get('name') as String))
//   //       .toList();
//   // }
//
//   @override
//   Future<List<Category>> getCategories() {
//     // TODO: implement getCategories
//     throw UnimplementedError();
//   }
//
//   @override
//   Future<Feed> getFeed({
//     Category category = Category.top,
//     int limit = 20,
//     int offset = 0,
//   }) {
//     throw UnimplementedError();
//   }
//
//   @override
//   Future<Article?> getArticle({
//     required String id,
//     int limit = 20,
//     int offset = 0,
//     bool preview = false,
//   }) {
//     throw UnimplementedError();
//   }
//
//   @override
//   Future<bool?> isPremiumArticle({required String id}) {
//     throw UnimplementedError();
//   }
//
//   @override
//   Future<List<String>> getPopularTopics() {
//     throw UnimplementedError();
//   }
//
//   @override
//   Future<List<String>> getRelevantTopics({required String term}) {
//     throw UnimplementedError();
//   }
//
//   @override
//   Future<List<NewsBlock>> getPopularArticles() {
//     throw UnimplementedError();
//   }
//
//   @override
//   Future<List<NewsBlock>> getRelevantArticles({required String term}) {
//     throw UnimplementedError();
//   }
//
//   @override
//   Future<RelatedArticles> getRelatedArticles({
//     required String id,
//     int limit = 20,
//     int offset = 0,
//   }) {
//     throw UnimplementedError();
//   }
//
//   @override
//   Future<void> createSubscription({
//     required String userId,
//     required String subscriptionId,
//   }) {
//     throw UnimplementedError();
//   }
//
//   @override
//   Future<List<Subscription>> getSubscriptions() {
//     throw UnimplementedError();
//   }
//
//   @override
//   Future<User?> getUser({required String userId}) {
//     throw UnimplementedError();
//   }
// }
