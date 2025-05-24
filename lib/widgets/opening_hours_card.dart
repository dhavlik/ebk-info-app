import 'package:flutter/material.dart';
import '../services/opening_status_service.dart';
import '../models/space_api_response.dart' as space_api;

class OpeningHoursCard extends StatefulWidget {
  const OpeningHoursCard({super.key});

  @override
  State<OpeningHoursCard> createState() => _OpeningHoursCardState();
}

class _OpeningHoursCardState extends State<OpeningHoursCard> {
  final OpeningStatusService _statusService = OpeningStatusService();
  space_api.SpaceApiResponse? _spaceData;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadSpaceData();
  }

  Future<void> _loadSpaceData() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final data = await _statusService.getSpaceStatus();
      setState(() {
        _spaceData = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Fehler beim Laden des Status: $e';
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
                  'Status',
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
                  tooltip: 'Aktualisieren',
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_error != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: Colors.red.shade600),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _error!,
                        style: TextStyle(color: Colors.red.shade800),
                      ),
                    ),
                  ],
                ),
              )
            else if (_spaceData != null) ...[
              _buildStatusRow(),
              const SizedBox(height: 12),
              _buildSpaceInfo(),
              const SizedBox(height: 12),
              _buildLastUpdate(),
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
    final isOpen = _spaceData?.state.open ?? false;
    final statusColor = isOpen ? Colors.green : Colors.red;
    final statusText = isOpen ? 'Geöffnet' : 'Geschlossen';
    final statusIcon = isOpen ? Icons.lock_open : Icons.lock;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: statusColor.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: statusColor.shade200),
      ),
      child: Row(
        children: [
          Icon(
            statusIcon,
            color: statusColor.shade700,
            size: 24,
          ),
          const SizedBox(width: 12),
          Text(
            statusText,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: statusColor.shade800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpaceInfo() {
    if (_spaceData == null) return const SizedBox.shrink();

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
    if (_spaceData?.state.lastchange == null) return const SizedBox.shrink();

    final lastUpdate = DateTime.fromMillisecondsSinceEpoch(
      _spaceData!.state.lastchange! * 1000,
    );
    final formattedTime =
        '${lastUpdate.day}.${lastUpdate.month}.${lastUpdate.year} ${lastUpdate.hour.toString().padLeft(2, '0')}:${lastUpdate.minute.toString().padLeft(2, '0')}';

    return Row(
      children: [
        const Icon(Icons.access_time, size: 16, color: Colors.grey),
        const SizedBox(width: 6),
        Text(
          'Letzte Änderung: $formattedTime',
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }
}
