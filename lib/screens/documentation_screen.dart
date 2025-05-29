import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';
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
  final Map<String, String> _pageContents = {}; // Cache for page contents
  final Map<String, bool> _showWebView = {}; // Track which items show WebView
  final Map<String, List<DocumentationItem>> _itemChildren =
      {}; // Cache for loaded children

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

  Future<void> _toggleNamespace(DocumentationItem item) async {
    if (!item.isNamespace) return;

    final isCurrentlyExpanded = _expandedItems[item.id] ?? false;

    if (isCurrentlyExpanded) {
      // Collapse
      setState(() {
        _expandedItems[item.id] = false;
        _showWebView[item.id] = false; // Also hide WebView when collapsing
      });
    } else {
      // Expand - load content if not already loaded
      setState(() {
        _loadingItems[item.id] = true;
      });

      try {
        // Always try to load both subcategories AND page content
        List<DocumentationItem> children = [];

        if (item.children.isEmpty && !_itemChildren.containsKey(item.id)) {
          children = await _documentationService.getNamespaceContent(item.id);

          // Store children in our cache instead of updating the original items
          _itemChildren[item.id] = children;
        }

        // Always try to load page content when expanding
        await _loadPageContentIfAvailable(item);

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
              content: Text('Error loading content: $e'),
            ),
          );
        }
      }
    }
  }

  /// Loads page content for a namespace if it has both children and page content
  Future<void> _loadPageContentIfAvailable(DocumentationItem item) async {
    // Load page content for any namespace, regardless of whether it has children
    if (!item.isNamespace) return;

    // Don't reload if we already have the content
    if (_pageContents.containsKey(item.id)) {
      setState(() {
        _showWebView[item.id] = true;
      });
      return;
    }

    try {
      debugPrint('Trying to load page content for namespace: ${item.id}');
      final pageContent =
          await _documentationService.getNamespacePageContent(item.id);

      if (pageContent != null) {
        debugPrint('✓ Page content found for ${item.id}');
        setState(() {
          _pageContents[item.id] = pageContent;
          _showWebView[item.id] = true;
        });
      } else {
        debugPrint('✗ No page content found for ${item.id}');
      }
    } catch (e) {
      debugPrint('Error loading page content for ${item.id}: $e');
      // Don't show error to user for page content, as it's optional
    }
  }

  IconData _getIconForItem(DocumentationItem item) {
    // Return appropriate icons based on the item ID/type
    switch (item.id) {
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
    final theme = Theme.of(context);

    switch (item.id) {
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
        return theme.colorScheme.primary;
    }
  }

  Widget _buildDocumentationItem(DocumentationItem item, int depth) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    final isExpanded = _expandedItems[item.id] ?? false;
    final isLoading = _loadingItems[item.id] ?? false;

    return Column(
      children: [
        // Main item card
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: SizedBox(
            width: double.infinity, // Ensure consistent width
            child: Card(
              elevation: 1, // Flat elevation for all items
              child: Column(
                children: [
                  ListTile(
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: _getColorForItem(item).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        _getIconForItem(item),
                        color: _getColorForItem(item),
                      ),
                    ),
                    title: Text(
                      item.title,
                      style: theme
                          .textTheme.titleMedium, // Same size for all levels
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.isNamespace
                              ? (depth == 0 ? l10n.category : l10n.subcategory)
                              : l10n.page,
                          style: theme.textTheme.bodySmall, // Consistent size
                        ),
                        Text(
                          'ID: ${item.id}',
                          style: TextStyle(
                            fontSize: 10,
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.6),
                            fontFamily: 'monospace',
                          ),
                        ),
                      ],
                    ),
                    trailing: _buildTrailing(item, isExpanded, isLoading),
                    onTap: () {
                      if (item.isNamespace) {
                        _toggleNamespace(item);
                      } else {
                        _openDocumentationUrl(item.url);
                      }
                    },
                  ),
                  // Show page content if available (within the same card)
                  if (isExpanded &&
                      _showWebView[item.id] == true &&
                      _pageContents[item.id] != null)
                    _buildWebViewContent(item),
                ],
              ),
            ),
          ),
        ),
        // Children items rendered at the same level (flat design)
        if (isExpanded) ...[
          ..._getItemChildren(item)
              .map((child) => _buildDocumentationItem(child, depth + 1)),
        ],
      ],
    );
  }

  Widget _buildWebViewContent(DocumentationItem item) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final pageContent = _pageContents[item.id];

    if (pageContent == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Divider between main content and WebView
        const Divider(height: 1),
        // Header for page content
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
          ),
          child: Row(
            children: [
              Icon(
                Icons.article,
                size: 20,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${item.title} - ${l10n.page}',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              // Toggle button to show/hide WebView content
              IconButton(
                icon: Icon(
                  Icons.close,
                  size: 20,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                onPressed: () {
                  setState(() {
                    _showWebView[item.id] = false;
                  });
                },
                tooltip: 'Hide page content',
              ),
            ],
          ),
        ),
        // WebView content
        SizedBox(
          height: 400, // Fixed height for the WebView
          child: WebViewWidget(
            controller: WebViewController()
              ..setJavaScriptMode(JavaScriptMode.unrestricted)
              ..setBackgroundColor(theme.colorScheme.surface)
              ..loadHtmlString(pageContent),
          ),
        ),
      ],
    );
  }

  /// Gets children for an item, either from the item itself or from the cache
  List<DocumentationItem> _getItemChildren(DocumentationItem item) {
    // First check if we have loaded children in the cache
    if (_itemChildren.containsKey(item.id)) {
      return _itemChildren[item.id]!;
    }
    // Otherwise return the original children
    return item.children;
  }

  Widget _buildTrailing(
      DocumentationItem item, bool isExpanded, bool isLoading) {
    if (isLoading) {
      return const SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }

    if (item.isNamespace) {
      // Check if this item has page content that can be shown
      final hasPageContent = _pageContents.containsKey(item.id);
      final showingWebView = _showWebView[item.id] == true;

      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Show page content button if available but hidden
          if (hasPageContent && !showingWebView && isExpanded)
            IconButton(
              icon: const Icon(Icons.article_outlined, size: 20),
              onPressed: () {
                setState(() {
                  _showWebView[item.id] = true;
                });
              },
              tooltip: 'Show page content',
            ),
          // Expand/collapse icon
          Icon(
            isExpanded ? Icons.expand_less : Icons.expand_more,
          ),
        ],
      );
    } else {
      return const Icon(Icons.open_in_new);
    }
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
                    'Access the EBK documentation with information about areas, tools, machines, processes and more.',
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Documentation sections
          ..._documentationItems!
              .map((item) => _buildDocumentationItem(item, 0)),
        ],
      ),
    );
  }
}
