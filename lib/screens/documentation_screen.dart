import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/documentation_service.dart';
import '../models/documentation_item.dart';
import '../l10n/app_localizations.dart';

class DocumentationScreen extends StatefulWidget {
  const DocumentationScreen({super.key});

  @override
  State<DocumentationScreen> createState() => _DocumentationScreenState();
}

class _DocumentationScreenState extends State<DocumentationScreen> {
  final DocumentationService _documentationService = DocumentationService();
  List<DocumentationItem>? _documentationItems;
  bool _isLoading = true;
  String? _errorMessage;
  final Map<String, bool> _expandedItems = {};
  final Map<String, bool> _loadingItems = {};
  final Map<String, List<DocumentationItem>> _itemChildren = {};

  @override
  void initState() {
    super.initState();
    _loadDocumentation();
  }

  @override
  void dispose() {
    _documentationService.dispose();
    super.dispose();
  }

  Future<void> _loadDocumentation() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final items = await _documentationService.getDocumentationStructure();

      setState(() {
        _documentationItems = items;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _openDocumentationUrl(String url) async {
    try {
      final directUrl = _documentationService.getDirectPageUrl(url);
      final uri = Uri.parse(directUrl);

      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)!.errorOpeningLink),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.errorOpeningLink),
          ),
        );
      }
    }
  }

  Future<void> _openExternalUrl(String url) async {
    try {
      final uri = Uri.parse(url);

      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)!.errorOpeningLink),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.errorOpeningLink),
          ),
        );
      }
    }
  }

  Future<void> _toggleCategory(DocumentationItem item) async {
    if (!item.isNamespace) return;

    final isCurrentlyExpanded = _expandedItems[item.id] ?? false;

    if (isCurrentlyExpanded) {
      // Collapse
      setState(() {
        _expandedItems[item.id] = false;
      });
    } else {
      // Expand - load subcategories if not already loaded
      setState(() {
        _loadingItems[item.id] = true;
      });

      try {
        List<DocumentationItem> children = [];

        if (item.children.isEmpty && !_itemChildren.containsKey(item.id)) {
          children = await _documentationService.getNamespaceContent(item.id);
          _itemChildren[item.id] = children;
        }

        setState(() {
          _expandedItems[item.id] = true;
          _loadingItems[item.id] = false;
        });
      } catch (e) {
        setState(() {
          _loadingItems[item.id] = false;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error loading subcategories: $e'),
            ),
          );
        }
      }
    }
  }

  IconData _getIconForItem(DocumentationItem item) {
    // Extract main category from ID (e.g., "bereiche:werkstatt" -> "bereiche")
    String mainCategory = item.id.split(':').first;

    switch (mainCategory) {
      case 'bereiche':
        return Icons.groups;
      case 'geraete':
        return Icons.build;
      case 'howtos':
        return Icons.help_outline;
      case 'infrastruktur':
        return Icons.settings;
      case 'veranstaltungen':
        return Icons.event;
      case 'mitgliederbereich':
        return Icons.people;
      case 'vorstand':
        return Icons.admin_panel_settings;
      default:
        return item.isNamespace ? Icons.folder : Icons.description;
    }
  }

  Color _getColorForItem(DocumentationItem item) {
    // Extract main category from ID (e.g., "bereiche:werkstatt" -> "bereiche")
    String mainCategory = item.id.split(':').first;

    switch (mainCategory) {
      case 'bereiche':
        return Colors.blue;
      case 'geraete':
        return Colors.orange;
      case 'howtos':
        return Colors.green;
      case 'infrastruktur':
        return Colors.purple;
      case 'veranstaltungen':
        return Colors.red;
      case 'mitgliederbereich':
        return Colors.teal;
      case 'vorstand':
        return Colors.indigo;
      default:
        return Theme.of(context).colorScheme.primary;
    }
  }

  Widget _buildCategoryCard(DocumentationItem item) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final isExpanded = _expandedItems[item.id] ?? false;
    final isLoading = _loadingItems[item.id] ?? false;

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        children: [
          // Category header
          ListTile(
            leading: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: _getColorForItem(item).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                _getIconForItem(item),
                color: _getColorForItem(item),
                size: 28,
              ),
            ),
            title: Text(
              item.title,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Text(
              l10n.category,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
            trailing: isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(
                    isExpanded ? Icons.expand_less : Icons.expand_more,
                    size: 32,
                  ),
            onTap: () => _toggleCategory(item),
          ),

          // Subcategory links (shown when expanded)
          if (isExpanded) ...[
            const Divider(height: 1),
            _buildSubcategoryLinks(item),
          ],
        ],
      ),
    );
  }

  Widget _buildSubcategoryLinks(DocumentationItem item) {
    final children = _getItemChildren(item);
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    if (children.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          'No subcategories available',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            fontStyle: FontStyle.italic,
          ),
        ),
      );
    }

    // Separate overview page from subcategories
    DocumentationItem? overviewPage;
    List<DocumentationItem> subcategories = [];

    for (final child in children) {
      if (_isOverviewPage(child, item)) {
        overviewPage = child;
      } else {
        subcategories.add(child);
      }
    }

    return Padding(
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Overview section
          if (overviewPage != null) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Text(
                l10n.overview.toUpperCase(),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
            ),
            _buildSubcategoryLink(overviewPage, item),
            if (subcategories.isNotEmpty) const SizedBox(height: 16),
          ],

          // Subcategories section
          if (subcategories.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Text(
                l10n.subcategory.toUpperCase(),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
            ),
            ...subcategories.map((child) => _buildSubcategoryLink(child, item)),
          ],
        ],
      ),
    );
  }

  /// Determines if a child item is an overview page for the parent category
  bool _isOverviewPage(DocumentationItem child, DocumentationItem parent) {
    // Overview pages are pages (not namespaces) and have the same base ID as the parent
    if (!child.isPage) return false;

    // Extract page ID from the child's URL
    final urlMatch = RegExp(r'id=([^&]+)').firstMatch(child.url);
    if (urlMatch == null) return false;

    final pageId = urlMatch.group(1)!;
    return pageId == parent.id;
  }

  Widget _buildSubcategoryLink(
      DocumentationItem item, DocumentationItem parentCategory) {
    final theme = Theme.of(context);

    // Use parent category's icon and color
    final parentIcon = _getIconForItem(parentCategory);
    final parentColor = _getColorForItem(parentCategory);

    return InkWell(
      onTap: () => _openDocumentationUrl(item.url),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        child: Row(
          children: [
            Icon(
              parentIcon,
              size: 20,
              color: parentColor,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                item.title,
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Icon(
              Icons.open_in_new,
              size: 16,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ],
        ),
      ),
    );
  }

  List<DocumentationItem> _getItemChildren(DocumentationItem item) {
    if (_itemChildren.containsKey(item.id)) {
      return _itemChildren[item.id]!;
    }
    return item.children;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.documentation),
        backgroundColor: theme.colorScheme.inversePrimary,
      ),
      body: _buildBody(l10n, theme),
    );
  }

  Widget _buildBody(AppLocalizations l10n, ThemeData theme) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: theme.colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              l10n.errorLoadingData,
              style: theme.textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage!,
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadDocumentation,
              child: Text(l10n.retry),
            ),
          ],
        ),
      );
    }

    if (_documentationItems == null || _documentationItems!.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.description,
              size: 64,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No documentation available',
              style: theme.textTheme.headlineSmall,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadDocumentation,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Welcome section
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          l10n.documentationDescription,
                          style: theme.textTheme.titleMedium,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tap on a category to view its subcategories as direct links.',
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Documentation categories
          ..._documentationItems!.map((item) => _buildCategoryCard(item)),
        ],
      ),
    );
  }
}
