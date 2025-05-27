import 'dart:convert';
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

  SpaceApiService({http.Client? client}) : _client = client ?? http.Client();

  Future<SpaceApiResponse> getSpaceStatus() async {
    try {
      final response = await _client.get(
        Uri.parse(_apiUrl),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return SpaceApiResponse.fromJson(data);
      } else {
        throw Exception('Failed to load space status: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching space status: $e');
    }
  }

  Future<OpenUntilResponse> getOpenUntil() async {
    try {
      final response = await _client.get(
        Uri.parse(_openUntilUrl),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return OpenUntilResponse.fromJson(data);
      } else {
        throw Exception(
            'Failed to load open until data: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching open until data: $e');
    }
  }
}
