import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/documentation_item.dart';

class DocumentationService {
  static const String _baseUrl = 'https://doku.eigenbaukombinat.de';
  static const String _sitemapEndpoint = '/?do=sitemap';

  final http.Client _client;

  DocumentationService({http.Client? client})
      : _client = client ?? http.Client();

  /// Fetches the main documentation structure from DokuWiki Sitemap
  Future<List<DocumentationItem>> getDocumentationStructure() async {
    try {
      print('Fetching documentation sitemap from: $_baseUrl$_sitemapEndpoint');
      final response = await _client.get(
        Uri.parse('$_baseUrl$_sitemapEndpoint'),
        headers: {'User-Agent': 'EBK-App/1.0'},
      );

      print('Documentation sitemap response status: ${response.statusCode}');
      print(
          'Documentation sitemap response length: ${response.bodyBytes.length} bytes');

      if (response.statusCode != 200) {
        throw Exception(
            'Failed to fetch documentation sitemap: ${response.statusCode}');
      }

      // Decompress gzipped content
      final decompressedBytes = gzip.decode(response.bodyBytes);
      final xmlContent = utf8.decode(decompressedBytes);

      print('Decompressed XML length: ${xmlContent.length} characters');
      print(
          'XML preview: ${xmlContent.substring(0, xmlContent.length > 300 ? 300 : xmlContent.length)}');

      return _parseSitemapXml(xmlContent);
    } catch (e) {
      print('Error fetching documentation structure: $e');
      throw Exception('Error fetching documentation structure: $e');
    }
  }

  /// Parses the DokuWiki XML sitemap into DocumentationItems
  List<DocumentationItem> _parseSitemapXml(String xmlContent) {
    final List<DocumentationItem> items = [];

    print('Parsing XML sitemap with ${xmlContent.length} characters');

    // Extract all URL entries from the XML sitemap
    final urlRegex = RegExp(
        r'<loc>(https://doku\.eigenbaukombinat\.de/doku\.php\?id=([^<]+))</loc>');
    final matches = urlRegex.allMatches(xmlContent);

    print('Found ${matches.length} documentation pages in sitemap');

    for (final match in matches) {
      final url = match.group(1)!;
      final pageId = match.group(2)!;

      print('Processing page: $pageId -> $url');

      try {
        final item = DocumentationItem.fromSitemapEntry(
          pageId: pageId,
          url: url,
        );

        // Filter out certain items we don't want to show in the app
        if (_shouldIncludeItem(item)) {
          items.add(item);
          print('Added item: ${item.title} (${item.type})');
        } else {
          print('Excluded item: ${item.title}');
        }
      } catch (e) {
        // Skip malformed entries
        print(
            'Warning: Could not parse documentation entry: $pageId -> $url - Error: $e');
      }
    }

    print('Total items parsed: ${items.length}');
    return _organizeDocumentationItems(items);
  }

  /// Determines if an item should be included in the app
  bool _shouldIncludeItem(DocumentationItem item) {
    // Exclude technical/admin sections
    final excludedIds = [
      'wiki:welcome', 'wiki:dokuwiki', 'wiki:syntax',
      'sidebar', 'dell_venue_8_pro', 'templates',
      'start', // main start page
    ];

    // Exclude any pages that start with excluded prefixes
    final excludedPrefixes = ['wiki:', 'playground:'];

    for (final prefix in excludedPrefixes) {
      if (item.id.startsWith(prefix)) {
        return false;
      }
    }

    if (excludedIds.contains(item.id)) {
      return false;
    }

    return true;
  }

  /// Organizes items by separating namespaces and pages
  List<DocumentationItem> _organizeDocumentationItems(
      List<DocumentationItem> items) {
    final List<DocumentationItem> organized = [];

    // Group items by type and priority
    final namespaces = items.where((item) => item.isNamespace).toList();
    final pages = items.where((item) => item.isPage).toList();

    // Sort namespaces by priority
    namespaces.sort((a, b) =>
        _getNamespacePriority(a.id).compareTo(_getNamespacePriority(b.id)));

    // Add namespaces first
    organized.addAll(namespaces);

    // Add standalone pages
    organized.addAll(pages);

    return organized;
  }

  /// Returns priority order for namespaces (lower = higher priority)
  int _getNamespacePriority(String id) {
    // Extract the main namespace from colon-separated IDs
    final mainNamespace = id.split(':').first;

    const priorityOrder = {
      'bereiche': 1, // Areas and Working Groups
      'geraete': 2, // Equipment and Tools
      'howtos': 3, // How-Tos and Processes
      'infrastruktur': 4, // Technical Infrastructure
      'veranstaltungen': 5, // Events
      'mitgliederbereich': 6, // Member Area
      'vorstand': 7, // Board Area
    };

    return priorityOrder[mainNamespace] ?? 999;
  }

  /// Converts a DokuWiki URL to direct page URL for web viewing
  String getDirectPageUrl(String dokuWikiUrl) {
    // Convert URLs like:
    // https://doku.eigenbaukombinat.de/doku.php?id=bereiche
    // to direct access URLs for better mobile viewing

    if (dokuWikiUrl.contains('id=')) {
      final idMatch = RegExp(r'id=([^&]+)').firstMatch(dokuWikiUrl);
      if (idMatch != null) {
        final pageId = idMatch.group(1)!;
        return '$_baseUrl/doku.php?id=$pageId';
      }
    }

    if (dokuWikiUrl.contains('idx=')) {
      final idxMatch = RegExp(r'idx=([^&]+)').firstMatch(dokuWikiUrl);
      if (idxMatch != null) {
        final namespaceId = idxMatch.group(1)!;
        return '$_baseUrl/doku.php?id=$namespaceId';
      }
    }

    return dokuWikiUrl;
  }

  void dispose() {
    _client.close();
  }
}
