import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as html_parser;
import 'package:html/dom.dart' as dom;
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
      debugPrint('Fetching documentation index from: $_baseUrl$_indexEndpoint');
      final response = await _client.get(
        Uri.parse('$_baseUrl$_indexEndpoint'),
        headers: {'User-Agent': 'EBK-App/1.0'},
      );

      debugPrint('Documentation index response status: ${response.statusCode}');
      debugPrint(
          'Documentation index response length: ${response.body.length} characters');

      if (response.statusCode != 200) {
        throw Exception(
            'Failed to fetch documentation index: ${response.statusCode}');
      }

      return _parseIndexHtml(response.body);
    } catch (e) {
      debugPrint('Error fetching documentation structure: $e');
      throw Exception('Error fetching documentation structure: $e');
    }
  }

  /// Parses the DokuWiki HTML index page into DocumentationItems
  List<DocumentationItem> _parseIndexHtml(String htmlContent) {
    final List<DocumentationItem> items = [];

    debugPrint('Parsing HTML index with ${htmlContent.length} characters');

    // Parse HTML using proper DOM parser
    final document = html_parser.parse(htmlContent);

    // Find the main index list
    final indexList = document.querySelector('ul.idx');
    if (indexList == null) {
      debugPrint('No index list found in HTML');
      return items;
    }

    debugPrint(
        'Found index list with ${indexList.outerHtml.length} characters');

    // Find all directory links (namespaces)
    final dirLinks = indexList.querySelectorAll('a.idx_dir');
    debugPrint('Found ${dirLinks.length} directories');

    for (final link in dirLinks) {
      final href = link.attributes['href'];
      if (href == null) continue;

      // Extract namespace from href: /doku.php?id=start&idx=namespace
      final idxMatch = RegExp(r'idx=([^&]+)').firstMatch(href);
      if (idxMatch == null) continue;

      final namespace = Uri.decodeComponent(idxMatch.group(1)!);
      final strongElement = link.querySelector('strong');
      final title = strongElement?.text ?? namespace;

      debugPrint('Processing directory: $namespace -> $title');

      if (_shouldIncludeNamespace(namespace)) {
        final item = DocumentationItem.fromIndexHtml(
          id: namespace,
          title: _formatTitle(title),
          url: '$_baseUrl/doku.php?id=start&idx=$namespace',
          type: DocumentationItemType.namespace,
        );

        items.add(item);
        debugPrint('Added namespace: ${item.title}');
      }
    }

    // Find all page links
    final pageLinks = indexList.querySelectorAll('a.wikilink1');
    debugPrint('Found ${pageLinks.length} pages');

    for (final link in pageLinks) {
      final href = link.attributes['href'];
      final wikiId = link.attributes['data-wiki-id'];
      if (href == null || wikiId == null) continue;

      // Extract page ID from href: /doku.php?id=pageid
      final idMatch = RegExp(r'id=([^&]+)').firstMatch(href);
      if (idMatch == null) continue;

      final pageId = idMatch.group(1)!;
      final title = link.text;

      debugPrint('Processing page: $pageId -> $title');

      if (_shouldIncludePage(pageId)) {
        final item = DocumentationItem.fromIndexHtml(
          id: wikiId,
          title: title,
          url: '$_baseUrl/doku.php?id=$pageId',
          type: DocumentationItemType.page,
        );

        items.add(item);
        debugPrint('Added page: ${item.title}');
      }
    }

    debugPrint('Total items parsed: ${items.length}');
    return _organizeDocumentationItems(items);
  }

  /// Fetches subcategories for a specific namespace
  Future<List<DocumentationItem>> getNamespaceContent(String namespace) async {
    try {
      final url = '$_baseUrl/doku.php?id=start&idx=$namespace';
      debugPrint('=== FETCHING NAMESPACE CONTENT ===');
      debugPrint('Namespace ID: $namespace');
      debugPrint('Fetching from URL: $url');

      final response = await _client.get(
        Uri.parse(url),
        headers: {'User-Agent': 'EBK-App/1.0'},
      );

      debugPrint('Response status: ${response.statusCode}');
      debugPrint('Response length: ${response.body.length} characters');

      if (response.statusCode != 200) {
        throw Exception(
            'Failed to fetch namespace content: ${response.statusCode}');
      }

      final result = _parseNamespaceHtml(response.body, namespace);

      // Check if there's a root-level page with the same ID as this namespace
      final rootLevelPage = await _findRootLevelPageForNamespace(namespace);
      if (rootLevelPage != null) {
        debugPrint(
            'Found root-level page for namespace "$namespace": ${rootLevelPage.title}');
        // Insert as first item
        result.insert(0, rootLevelPage);
      }

      debugPrint('Found ${result.length} items in namespace "$namespace"');
      debugPrint('=== END NAMESPACE CONTENT ===\n');

      return result;
    } catch (e) {
      debugPrint('Error fetching namespace content for "$namespace": $e');
      return [];
    }
  }

  /// Parses HTML for a specific namespace to extract its content
  List<DocumentationItem> _parseNamespaceHtml(
      String htmlContent, String namespace) {
    final List<DocumentationItem> items = [];

    debugPrint(
        'Parsing namespace HTML for $namespace with ${htmlContent.length} characters');

    // Parse HTML using proper DOM parser
    final document = html_parser.parse(htmlContent);

    // Try to find the main index list first
    final indexList = document.querySelector('ul.idx');

    dom.Element searchElement;
    if (indexList != null) {
      searchElement = indexList;
      debugPrint(
          'Found index list with ${indexList.outerHtml.length} characters');
    } else {
      // If no index list found, search in the entire document
      debugPrint('No index list found, searching entire document');
      searchElement = document.documentElement!;
    }

    // Find sub-directories (sub-namespaces) within this namespace
    final subDirLinks = searchElement.querySelectorAll('a.idx_dir');
    debugPrint('Found ${subDirLinks.length} sub-directories');

    for (final link in subDirLinks) {
      final href = link.attributes['href'];
      if (href == null) continue;

      // Extract namespace from href
      final idxMatch = RegExp(r'idx=([^&]+)').firstMatch(href);
      if (idxMatch == null) continue;

      final subNamespace = Uri.decodeComponent(idxMatch.group(1)!);
      final strongElement = link.querySelector('strong');
      final title = strongElement?.text ?? subNamespace;

      debugPrint('Found sub-directory: "$subNamespace" -> "$title"');

      // Only include sub-namespaces that belong to the current namespace
      if (subNamespace.startsWith('$namespace:')) {
        debugPrint(
            '✓ Including sub-directory: $subNamespace (belongs to $namespace)');

        final item = DocumentationItem.fromIndexHtml(
          id: subNamespace,
          title: _formatTitle(title),
          url: '$_baseUrl/doku.php?id=start&idx=$subNamespace',
          type: DocumentationItemType.namespace,
        );

        items.add(item);
      } else {
        debugPrint(
            '✗ Excluding sub-directory: $subNamespace (does not belong to $namespace)');
      }
    }

    // Create a set of subcategory IDs for quick lookup
    final subcategoryIds =
        items.where((item) => item.isNamespace).map((item) => item.id).toSet();
    debugPrint('Subcategory IDs found: $subcategoryIds');

    // Find pages within this namespace
    final pageLinks = searchElement.querySelectorAll('a.wikilink1');
    debugPrint('Found ${pageLinks.length} pages');

    for (final link in pageLinks) {
      final href = link.attributes['href'];
      final wikiId = link.attributes['data-wiki-id'];
      if (href == null || wikiId == null) continue;

      // Extract page ID from href
      final idMatch = RegExp(r'id=([^&]+)').firstMatch(href);
      if (idMatch == null) continue;

      final pageId = idMatch.group(1)!;
      final title = link.text;

      debugPrint('Found page: "$pageId" (wikiId: "$wikiId") -> "$title"');

      // Only include pages that belong to this namespace
      if (pageId.startsWith('$namespace:') || pageId == namespace) {
        debugPrint('✓ Page belongs to namespace "$namespace"');

        // Prevent circular references: don't add a page with the same ID as the namespace
        if (pageId == namespace) {
          debugPrint(
              '✗ Skipping page with same ID as namespace to prevent circular reference');
          continue;
        }

        // Skip pages that have the same ID as a subcategory
        if (subcategoryIds.contains(pageId)) {
          debugPrint(
              '✗ Skipping page "$pageId" because a subcategory with the same ID exists');
          continue;
        }

        if (_shouldIncludePage(pageId)) {
          debugPrint('✓ Including page: $pageId');
          final item = DocumentationItem.fromIndexHtml(
            id: wikiId,
            title: title,
            url: '$_baseUrl/doku.php?id=$pageId',
            type: DocumentationItemType.page,
          );

          items.add(item);
        } else {
          debugPrint('✗ Excluding page: $pageId (filtered out)');
        }
      } else {
        debugPrint('✗ Page does not belong to namespace "$namespace"');
      }
    }

    debugPrint('Total sub-items parsed for $namespace: ${items.length}');
    return items;
  }

  /// Looks for a root-level page that matches the namespace ID
  Future<DocumentationItem?> _findRootLevelPageForNamespace(
      String namespace) async {
    try {
      // Try to fetch the root index again to look for pages
      final response = await _client.get(
        Uri.parse('$_baseUrl$_indexEndpoint'),
        headers: {'User-Agent': 'EBK-App/1.0'},
      );

      if (response.statusCode != 200) {
        return null;
      }

      // Parse HTML using proper DOM parser
      final document = html_parser.parse(response.body);
      final indexList = document.querySelector('ul.idx');
      if (indexList == null) {
        return null;
      }

      // Find all page links
      final pageLinks = indexList.querySelectorAll('a.wikilink1');
      debugPrint(
          'Looking for root-level page with ID "$namespace" in ${pageLinks.length} pages');

      for (final link in pageLinks) {
        final href = link.attributes['href'];
        final wikiId = link.attributes['data-wiki-id'];
        if (href == null || wikiId == null) continue;

        // Extract page ID from href: /doku.php?id=pageid
        final idMatch = RegExp(r'id=([^&]+)').firstMatch(href);
        if (idMatch == null) continue;

        final pageId = idMatch.group(1)!;
        final title = link.text;

        debugPrint('Checking root page: "$pageId" -> "$title"');

        // Check if this page ID matches the namespace
        if (pageId == namespace && _shouldIncludePage(pageId)) {
          debugPrint('✓ Found matching root-level page: $pageId');
          return DocumentationItem.fromIndexHtml(
            id: wikiId,
            title: title,
            url: '$_baseUrl/doku.php?id=$pageId',
            type: DocumentationItemType.page,
          );
        }
      }

      debugPrint('✗ No root-level page found for namespace "$namespace"');
      return null;
    } catch (e) {
      debugPrint('Error looking for root-level page for "$namespace": $e');
      return null;
    }
  }

  /// Checks if a namespace also has a corresponding page and fetches its content
  Future<String?> getNamespacePageContent(String namespace) async {
    try {
      final url = '$_baseUrl/doku.php?id=$namespace';
      debugPrint('=== CHECKING NAMESPACE PAGE CONTENT ===');
      debugPrint('Namespace: $namespace');
      debugPrint('Fetching page from: $url');

      final response = await _client.get(
        Uri.parse(url),
        headers: {'User-Agent': 'EBK-App/1.0'},
      );

      debugPrint('Page response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final pageContent = _extractPageContent(response.body);
        debugPrint(
            'Page content extracted: ${pageContent != null ? "YES" : "NO"}');
        debugPrint('=== END NAMESPACE PAGE CONTENT ===\n');
        return pageContent;
      } else {
        debugPrint('No page found for namespace: $namespace');
        debugPrint('=== END NAMESPACE PAGE CONTENT ===\n');
        return null;
      }
    } catch (e) {
      debugPrint('Error fetching page content for namespace "$namespace": $e');
      return null;
    }
  }

  /// Extracts the main content from a DokuWiki page HTML
  String? _extractPageContent(String htmlContent) {
    // Parse HTML using proper DOM parser
    final document = html_parser.parse(htmlContent);

    // Look for <div class="page group">
    final pageDiv = document.querySelector('div.page.group');
    if (pageDiv == null) {
      debugPrint('No div.page.group found in HTML');
      return null;
    }

    debugPrint('Found div.page.group with content');

    // Remove the table of contents div (dw__toc) if present
    final tocDiv = pageDiv.querySelector('#dw__toc');
    if (tocDiv != null) {
      debugPrint('Removing table of contents (dw__toc)');
      tocDiv.remove();
    }

    // Get the inner HTML content
    String content = pageDiv.innerHtml;

    // Clean up the content for better mobile display
    content = _cleanUpHtmlContent(content);

    return '''
<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <style>
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
            line-height: 1.6;
            margin: 16px;
            color: #333;
            transform: scale(0.5);
            transform-origin: top left;
            width: 200%;
        }
        img {
            max-width: 100%;
            height: auto;
        }
        table {
            width: 100%;
            border-collapse: collapse;
        }
        th, td {
            border: 1px solid #ddd;
            padding: 8px;
            text-align: left;
        }
        th {
            background-color: #f5f5f5;
        }
        pre {
            background-color: #f5f5f5;
            padding: 12px;
            border-radius: 4px;
            overflow-x: auto;
        }
        code {
            background-color: #f5f5f5;
            padding: 2px 4px;
            border-radius: 2px;
        }
        .level1, .level2, .level3 {
            margin-top: 24px;
            margin-bottom: 16px;
        }
        .level1 { font-size: 1.5em; font-weight: bold; }
        .level2 { font-size: 1.3em; font-weight: bold; }
        .level3 { font-size: 1.1em; font-weight: bold; }
        a {
            color: #2196F3;
            text-decoration: none;
        }
        a:hover {
            text-decoration: underline;
        }
    </style>
</head>
<body>
$content
</body>
</html>
''';
  }

  /// Cleans up HTML content for better mobile display
  String _cleanUpHtmlContent(String content) {
    // Parse the content as HTML fragment
    final fragment = html_parser.parseFragment(content);

    // Convert relative URLs to absolute URLs
    final links = fragment.querySelectorAll('a[href]');
    for (final link in links) {
      final href = link.attributes['href'];
      if (href != null && href.startsWith('/')) {
        link.attributes['href'] = '$_baseUrl$href';
      }
    }

    final images = fragment.querySelectorAll('img[src]');
    for (final img in images) {
      final src = img.attributes['src'];
      if (src != null && src.startsWith('/')) {
        img.attributes['src'] = '$_baseUrl$src';
      }
    }

    // Remove edit links and other UI elements
    final editLinks = fragment.querySelectorAll('a[class*="edit"]');
    for (final editLink in editLinks) {
      editLink.remove();
    }

    final secEditDivs = fragment.querySelectorAll('div[class*="secedit"]');
    for (final div in secEditDivs) {
      div.remove();
    }

    // Convert fragment nodes to HTML string
    final buffer = StringBuffer();
    for (final node in fragment.nodes) {
      if (node is dom.Element) {
        buffer.write(node.outerHtml);
      } else {
        buffer.write(node.text);
      }
    }

    return buffer.toString();
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
    // https://doku.eigenbaukombinat.de/doku.php?id=start&idx=bereiche
    // to: https://doku.eigenbaukombinat.de/doku.php?id=bereiche
    // for better mobile viewing

    // First check for idx parameter and convert it to id
    if (dokuWikiUrl.contains('idx=')) {
      final idxMatch = RegExp(r'idx=([^&]+)').firstMatch(dokuWikiUrl);
      if (idxMatch != null) {
        final namespaceId = idxMatch.group(1)!;
        return '$_baseUrl/doku.php?id=$namespaceId';
      }
    }

    // If no idx parameter, check for existing id parameter
    if (dokuWikiUrl.contains('id=')) {
      final idMatch = RegExp(r'id=([^&]+)').firstMatch(dokuWikiUrl);
      if (idMatch != null) {
        final pageId = idMatch.group(1)!;
        return '$_baseUrl/doku.php?id=$pageId';
      }
    }

    return dokuWikiUrl;
  }

  void dispose() {
    _client.close();
  }
}
