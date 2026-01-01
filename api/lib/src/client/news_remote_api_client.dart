import 'package:http/http.dart' as http;
import 'package:news_temp_api/client.dart';

class NewsRemoteApiClient extends NewsTempApiClient {
  NewsRemoteApiClient({
    required String baseUrl,
    required TokenProvider tokenProvider,
    http.Client? httpClient,
  })  : _customBaseUrl = baseUrl,
        super(
          tokenProvider: tokenProvider,
          httpClient: httpClient,
        );

  final String _customBaseUrl;

  @override
  String get _baseUrl => _customBaseUrl; // This won't work - see below
}
