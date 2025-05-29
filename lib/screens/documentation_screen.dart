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
                      Text(
                        l10n.documentationDescription,
                        style: theme.textTheme.titleMedium,
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
          ..._documentationItems!.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Card(
                  child: ListTile(
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
                      style: theme.textTheme.titleMedium,
                    ),
                    subtitle: item.isNamespace
                        ? const Text('Category')
                        : const Text('Page'),
                    trailing: const Icon(Icons.open_in_new),
                    onTap: () => _openDocumentationUrl(item.url),
                  ),
                ),
              )),
        ],
      ),
    );
  }
}
