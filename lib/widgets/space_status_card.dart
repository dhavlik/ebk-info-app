import 'package:flutter/material.dart';
import 'dart:async';
import '../services/space_api_service.dart';
import '../services/background_task_service.dart';
import '../models/space_api_response.dart' as space_api;
import '../l10n/app_localizations.dart';

class SpaceStatusCard extends StatefulWidget {
  const SpaceStatusCard({super.key});

  @override
  State<SpaceStatusCard> createState() => _SpaceStatusCardState();
}

class _SpaceStatusCardState extends State<SpaceStatusCard> {
  final SpaceApiService _spaceApiService = SpaceApiService();
  space_api.SpaceApiResponse? _spaceData;
  space_api.OpenUntilResponse? _openUntilData;
  bool _isLoading = true;
  String? _error;
  StreamSubscription<SpaceStatusUpdate>? _statusSubscription;

  @override
  void initState() {
    super.initState();
    _loadSpaceData();
    _subscribeToStatusUpdates();
  }

  @override
  void dispose() {
    _statusSubscription?.cancel();
    super.dispose();
  }

  /// Horcht auf Status-Updates vom BackgroundTaskService
  void _subscribeToStatusUpdates() {
    _statusSubscription = BackgroundTaskService.statusUpdates.listen((update) {
      if (mounted) {
        setState(() {
          _spaceData = update.spaceData;
          _openUntilData = update.openUntil != null
              ? space_api.OpenUntilResponse(closeTime: update.openUntil!)
              : null;
          _isLoading = false;
          _error = null;
        });
      }
    });
  }

  Future<void> _loadSpaceData() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final data = await _spaceApiService.getSpaceStatus();

      // If space is open, also fetch the open until data
      space_api.OpenUntilResponse? openUntilData;
      if (data.state.open) {
        try {
          openUntilData = await _spaceApiService.getOpenUntil();
        } catch (e) {
          // Don't fail the whole request if openuntil fails
          debugPrint('Failed to fetch open until data: $e');
        }
      }

      setState(() {
        _spaceData = data;
        _openUntilData = openUntilData;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Error loading status: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _refreshData() async {
    await _loadSpaceData();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Space Status',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                IconButton(
                  onPressed: _isLoading ? null : _refreshData,
                  icon: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.refresh),
                  tooltip: 'Refresh',
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_error != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(8),
                  border:
                      Border.all(color: Theme.of(context).colorScheme.error),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline,
                        color: Theme.of(context).colorScheme.error),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _error!,
                        style: TextStyle(
                            color:
                                Theme.of(context).colorScheme.onErrorContainer),
                      ),
                    ),
                  ],
                ),
              )
            else if (_spaceData != null) ...[
              _buildStatusRow(),
              const SizedBox(height: 12),
              _buildSpaceInfo(),
              if (_spaceData!.state.lastchange != null) ...[
                const SizedBox(height: 12),
                _buildLastUpdate(),
              ],
            ] else if (_isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: CircularProgressIndicator(),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusRow() {
    final isOpen = _spaceData!.state.open;
    final l10n = AppLocalizations.of(context)!;
    final statusText = isOpen ? l10n.open : l10n.closed;
    final statusIcon = isOpen ? Icons.lock_open : Icons.lock;

    // Use theme colors for better dark mode support
    final containerColor = isOpen
        ? (Theme.of(context).brightness == Brightness.dark
            ? Colors.green.withValues(alpha: 0.2)
            : Colors.green.shade50)
        : (Theme.of(context).brightness == Brightness.dark
            ? Colors.red.withValues(alpha: 0.2)
            : Colors.red.shade50);
    final borderColor = isOpen
        ? (Theme.of(context).brightness == Brightness.dark
            ? Colors.green.withValues(alpha: 0.5)
            : Colors.green.shade200)
        : (Theme.of(context).brightness == Brightness.dark
            ? Colors.red.withValues(alpha: 0.5)
            : Colors.red.shade200);
    final textIconColor = isOpen
        ? (Theme.of(context).brightness == Brightness.dark
            ? Colors.green.shade300
            : Colors.green.shade800)
        : (Theme.of(context).brightness == Brightness.dark
            ? Colors.red.shade300
            : Colors.red.shade800);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: containerColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                statusIcon,
                color: textIconColor,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                statusText,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: textIconColor,
                ),
              ),
            ],
          ),
          if (isOpen && _openUntilData?.closeTime != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.schedule,
                  color: textIconColor,
                  size: 16,
                ),
                const SizedBox(width: 6),
                Text(
                  '${l10n.openUntilLabel} ${_openUntilData!.closeTime}',
                  style: TextStyle(
                    fontSize: 14,
                    color: textIconColor,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSpaceInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_spaceData!.space.isNotEmpty) ...[
          Row(
            children: [
              const Icon(Icons.place, size: 20, color: Colors.grey),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _spaceData!.space,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
        ],
        if (_spaceData!.location?.address?.isNotEmpty == true) ...[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.location_on, size: 20, color: Colors.grey),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _spaceData!.location!.address!,
                  style: const TextStyle(fontSize: 14),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildLastUpdate() {
    final lastUpdate = DateTime.fromMillisecondsSinceEpoch(
      _spaceData!.state.lastchange! * 1000,
    );
    final now = DateTime.now();
    final difference = now.difference(lastUpdate);

    String timeAgo;
    if (difference.inMinutes < 60) {
      timeAgo = '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      timeAgo = '${difference.inHours}h ago';
    } else {
      timeAgo = '${difference.inDays}d ago';
    }

    return Row(
      children: [
        const Icon(Icons.access_time, size: 16, color: Colors.grey),
        const SizedBox(width: 6),
        Text(
          'Last update: $timeAgo',
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }
}
