import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:news_temp_api/api.dart';

final _newsDataSource = _buildNewsDataSource();

NewsDataSource _buildNewsDataSource() {
  final endpoint = Platform.environment['DATA_CONNECT_ENDPOINT'];
  if (endpoint == null || endpoint.isEmpty) {
    return InMemoryNewsDataSource();
  }
  final authToken = Platform.environment['DATA_CONNECT_AUTH_TOKEN'];
  return DataConnectNewsDataSource(
    endpoint: endpoint,
    apiKey: Platform.environment['DATA_CONNECT_API_KEY'],
    authTokenProvider:
        authToken == null ? null : () async => authToken,
  );
}

/// Provider a [NewsDataSource] to the current [RequestContext].
Middleware newsDataSourceProvider() {
  return (handler) {
    return handler.use(provider<NewsDataSource>((_) => _newsDataSource));
  };
}
