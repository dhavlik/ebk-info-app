class DocumentationItem {
  final String id;
  final String title;
  final String url;
  final DocumentationItemType type;
  final List<DocumentationItem> children;

  const DocumentationItem({
    required this.id,
    required this.title,
    required this.url,
    required this.type,
    this.children = const [],
  });

  factory DocumentationItem.fromDokuWikiEntry(String entry) {
    // Parse entries like:
    // • [bereiche](https://doku.eigenbaukombinat.de/doku.php?idx=bereiche)
    // • [Bereiche und Arbeitsgruppen](https://doku.eigenbaukombinat.de/doku.php?id=bereiche)

    final linkRegex = RegExp(r'\[([^\]]+)\]\(([^)]+)\)');
    final match = linkRegex.firstMatch(entry);

    if (match == null) {
      throw ArgumentError('Invalid DokuWiki entry format: $entry');
    }

    final title = match.group(1)!;
    final url = match.group(2)!;

    return _createFromTitleAndUrl(title, url);
  }

  factory DocumentationItem.fromDokuWikiHtml({
    required String title,
    required String url,
  }) {
    return _createFromTitleAndUrl(title, url);
  }

  factory DocumentationItem.fromSitemapEntry({
    required String pageId,
    required String url,
  }) {
    // Create title from page ID by converting underscores to spaces and capitalizing
    String title = pageId
        .split(':')
        .last
        .replaceAll('_', ' ')
        .split(' ')
        .map((word) => word.isNotEmpty
            ? '${word[0].toUpperCase()}${word.substring(1)}'
            : word)
        .join(' ');

    // Determine type based on page structure
    // Namespaces typically have shorter IDs and represent categories
    final parts = pageId.split(':');
    final isNamespace = parts.length == 1 ||
        _isKnownNamespace(parts.first) ||
        parts.last == 'start'; // namespace start pages

    final type = isNamespace
        ? DocumentationItemType.namespace
        : DocumentationItemType.page;

    return DocumentationItem(
      id: pageId,
      title: title,
      url: url,
      type: type,
    );
  }

  static bool _isKnownNamespace(String id) {
    const knownNamespaces = {
      'bereiche',
      'geraete',
      'howtos',
      'infrastruktur',
      'veranstaltungen',
      'mitgliederbereich',
      'vorstand',
      'wiki'
    };
    return knownNamespaces.contains(id);
  }

  static DocumentationItem _createFromTitleAndUrl(String title, String url) {
    // Determine if it's a namespace (has idx parameter) or page (has id parameter)
    final isNamespace = url.contains('idx=');
    final type = isNamespace
        ? DocumentationItemType.namespace
        : DocumentationItemType.page;

    // Extract ID from URL
    String id;
    if (isNamespace) {
      final idxMatch = RegExp(r'idx=([^&]+)').firstMatch(url);
      id = idxMatch?.group(1) ?? title.toLowerCase();
    } else {
      final idMatch = RegExp(r'id=([^&]+)').firstMatch(url);
      id = idMatch?.group(1) ?? title.toLowerCase();
    }

    return DocumentationItem(
      id: id,
      title: title,
      url: url,
      type: type,
    );
  }

  bool get isNamespace => type == DocumentationItemType.namespace;
  bool get isPage => type == DocumentationItemType.page;
}

enum DocumentationItemType {
  namespace,
  page,
}
