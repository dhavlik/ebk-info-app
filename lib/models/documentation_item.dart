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
