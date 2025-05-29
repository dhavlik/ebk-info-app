import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/documentation_item.dart';

class DocumentationService {
  static const String _baseUrl = 'https://doku.eigenbaukombinat.de';
  static const String _indexEndpoint = '/doku.php?do=index';

  final http.Client _client;

  DocumentationService({http.Client? client})
      : _client = client ?? http.Client();

  /// Fetches the main documentation structure from DokuWiki Index page
  Future<List<DocumentationItem>> getDocumentationStructure() async {
    try {
      print('Fetching documentation index from: $_baseUrl$_indexEndpoint');
      final response = await _client.get(
        Uri.parse('$_baseUrl$_indexEndpoint'),
        headers: {'User-Agent': 'EBK-App/1.0'},
      );

      print('Documentation index response status: ${response.statusCode}');
      print(
          'Documentation index response length: ${response.body.length} characters');

      if (response.statusCode != 200) {
        throw Exception(
            'Failed to fetch documentation index: ${response.statusCode}');
      }

      return _parseIndexHtml(response.body);
    } catch (e) {
      print('Error fetching documentation structure: $e');
      throw Exception('Error fetching documentation structure: $e');
    }
  }

  /// Parses the DokuWiki HTML index page into DocumentationItems
  List<DocumentationItem> _parseIndexHtml(String htmlContent) {
    final List<DocumentationItem> items = [];

    print('Parsing HTML index with ${htmlContent.length} characters');

    // Extract the main index list
    final indexListMatch = RegExp(r'<ul class="idx">(.*?)</ul>', dotAll: true)
        .firstMatch(htmlContent);

    if (indexListMatch == null) {
      print('No index list found in HTML');
      return items;
    }

    final indexListHtml = indexListMatch.group(1)!;
    print('Found index list with ${indexListHtml.length} characters');

    // Parse directories (namespaces) - these have idx_dir class
    final dirRegex = RegExp(
        r'<a href="/doku\.php\?id=start&amp;idx=([^"]+)"[^>]*class="idx_dir"[^>]*><strong>([^<]+)</strong></a>',
        multiLine: true);

    final dirMatches = dirRegex.allMatches(indexListHtml);
    print('Found ${dirMatches.length} directories');

    for (final match in dirMatches) {
      final namespace = Uri.decodeComponent(match.group(1)!);
      final title = match.group(2)!;

      print('Processing directory: $namespace -> $title');

      if (_shouldIncludeNamespace(namespace)) {
        final item = DocumentationItem.fromIndexHtml(
          id: namespace,
          title: _formatTitle(title),
          url: '$_baseUrl/doku.php?id=start&idx=$namespace',
          type: DocumentationItemType.namespace,
        );

        items.add(item);
        print('Added namespace: ${item.title}');
      }
    }

    // Parse individual pages - these have wikilink1 class
    final pageRegex = RegExp(
        r'<a href="/doku\.php\?id=([^"]+)"[^>]*class="wikilink1"[^>]*data-wiki-id="([^"]+)">([^<]+)</a>',
        multiLine: true);

    final pageMatches = pageRegex.allMatches(indexListHtml);
    print('Found ${pageMatches.length} pages');

    for (final match in pageMatches) {
      final pageId = match.group(1)!;
      final wikiId = match.group(2)!;
      final title = match.group(3)!;

      print('Processing page: $pageId -> $title');

      if (_shouldIncludePage(pageId)) {
        final item = DocumentationItem.fromIndexHtml(
          id: wikiId,
          title: title,
          url: '$_baseUrl/doku.php?id=$pageId',
          type: DocumentationItemType.page,
        );

        items.add(item);
        print('Added page: ${item.title}');
      }
    }

    print('Total items parsed: ${items.length}');
    return _organizeDocumentationItems(items);
  }

  /// Determines if a namespace should be included in the app
  bool _shouldIncludeNamespace(String namespace) {
    // Exclude technical/admin sections
    final excludedNamespaces = ['templates', 'wiki'];
    return !excludedNamespaces.contains(namespace);
  }

  /// Determines if a page should be included in the app
  bool _shouldIncludePage(String pageId) {
    // Exclude technical/admin pages
    final excludedPages = [
      'sidebar',
      'dell_venue_8_pro',
      'start',
    ];

    // Exclude any pages that start with excluded prefixes
    final excludedPrefixes = ['wiki:', 'playground:'];

    for (final prefix in excludedPrefixes) {
      if (pageId.startsWith(prefix)) {
        return false;
      }
    }

    return !excludedPages.contains(pageId);
  }

  /// Formats a title by capitalizing words properly
  String _formatTitle(String title) {
    return title
        .split(' ')
        .map((word) => word.isNotEmpty
            ? '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}'
            : word)
        .join(' ');
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
