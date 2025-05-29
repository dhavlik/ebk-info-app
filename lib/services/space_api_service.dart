import 'dart:convert';
import 'dart:developer';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/space_api_response.dart';

class SpaceApiService {
  // Production endpoints
  static const String _prodApiUrl = 'https://spaceapi.eigenbaukombinat.de/';
  static const String _prodOpenUntilUrl =
      'https://spaceapi.eigenbaukombinat.de/openuntil.json';

  // Debug endpoints for testing
  static const String _debugApiUrl = 'https://team-tfm.com/status.json';
  static const String _debugOpenUntilUrl =
      'https://team-tfm.com/openuntil.json';

  // Use debug endpoints when in debug mode
  static String get _apiUrl => kDebugMode ? _debugApiUrl : _prodApiUrl;
  static String get _openUntilUrl =>
      kDebugMode ? _debugOpenUntilUrl : _prodOpenUntilUrl;

  final http.Client _client;

  SpaceApiService({http.Client? client}) : _client = client ?? http.Client() {
    log('🏗️ SpaceApiService: Initialized with endpoints:');
    log('   - API URL: $_apiUrl');
    log('   - OpenUntil URL: $_openUntilUrl');
    log('   - Debug Mode: $kDebugMode');
  }

  Future<SpaceApiResponse> getSpaceStatus() async {
    log('🌐 SpaceApiService: Getting space status from $_apiUrl');

    try {
      final response = await _client.get(
        Uri.parse(_apiUrl),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      );

      log('📡 SpaceApiService: Response status code: ${response.statusCode}');
      log('📡 SpaceApiService: Response headers: ${response.headers}');

      if (response.statusCode == 200) {
        log('📡 SpaceApiService: Response body length: ${response.body.length}');
        log('📡 SpaceApiService: Response body: ${response.body}');

        final Map<String, dynamic> data = json.decode(response.body);
        final spaceResponse = SpaceApiResponse.fromJson(data);

        log('✅ SpaceApiService: Space status parsed successfully - Open: ${spaceResponse.state.open}');
        return spaceResponse;
      } else {
        log('❌ SpaceApiService: Failed with status code: ${response.statusCode}');
        log('❌ SpaceApiService: Error response body: ${response.body}');
        throw Exception('Failed to load space status: ${response.statusCode}');
      }
    } catch (e) {
      log('❌ SpaceApiService: Exception occurred: $e');
      throw Exception('Error fetching space status: $e');
    }
  }

  Future<OpenUntilResponse> getOpenUntil() async {
    log('🕒 SpaceApiService: Getting openUntil data from $_openUntilUrl');

    try {
      final response = await _client.get(
        Uri.parse(_openUntilUrl),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      );

      log('📡 SpaceApiService: OpenUntil response status code: ${response.statusCode}');

      if (response.statusCode == 200) {
        log('📡 SpaceApiService: OpenUntil response body: ${response.body}');

        final Map<String, dynamic> data = json.decode(response.body);
        final openUntilResponse = OpenUntilResponse.fromJson(data);

        log('✅ SpaceApiService: OpenUntil parsed successfully - CloseTime: ${openUntilResponse.closeTime}');
        return openUntilResponse;
      } else {
        log('❌ SpaceApiService: OpenUntil failed with status code: ${response.statusCode}');
        log('❌ SpaceApiService: OpenUntil error response body: ${response.body}');
        throw Exception(
            'Failed to load open until data: ${response.statusCode}');
      }
    } catch (e) {
      log('❌ SpaceApiService: OpenUntil exception occurred: $e');
      throw Exception('Error fetching open until data: $e');
    }
  }
}
