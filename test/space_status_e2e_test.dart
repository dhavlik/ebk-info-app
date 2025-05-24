import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

import 'package:ebk_app/services/space_api_service.dart';
import 'package:ebk_app/models/space_api_response.dart' as space_api;

// Mock HTTP client for testing
class MockHttpClient extends http.BaseClient {
  final Map<String, String> responses;
  final Map<String, int> statusCodes;

  MockHttpClient({
    required this.responses,
    this.statusCodes = const {},
  });

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final url = request.url.toString();
    final statusCode = statusCodes[url] ?? 200;
    final response = responses[url] ?? '';

    return http.StreamedResponse(
      Stream.fromIterable([response.codeUnits]),
      statusCode,
      headers: {'content-type': 'application/json'},
    );
  }
}

void main() {
  group('SpaceStatusCard E2E Tests', () {
    // Mock response for closed space
    const closedSpaceResponse = '''
    {
      "space": "Eigenbaukombinat Halle",
      "logo": "https://eigenbaukombinat.de/logo.png",
      "url": "https://eigenbaukombinat.de",
      "location": {
        "address": "Landsberger Str. 3, 06112 Halle (Saale), Germany",
        "lon": 11.9706,
        "lat": 51.4969
      },
      "contact": {
        "email": "info@eigenbaukombinat.de"
      },
      "state": {
        "open": false,
        "lastchange": 1716550800
      }
    }
    ''';

    // Mock response for open space
    const openSpaceResponse = '''
    {
      "space": "Eigenbaukombinat Halle",
      "logo": "https://eigenbaukombinat.de/logo.png", 
      "url": "https://eigenbaukombinat.de",
      "location": {
        "address": "Landsberger Str. 3, 06112 Halle (Saale), Germany",
        "lon": 11.9706,
        "lat": 51.4969
      },
      "contact": {
        "email": "info@eigenbaukombinat.de"
      },
      "state": {
        "open": true,
        "lastchange": 1716550800
      }
    }
    ''';

    // Mock response for openuntil endpoint with close time
    const openUntilWithTimeResponse = '''
    {
      "closetime": "18:30"
    }
    ''';

    // Mock response for openuntil endpoint with null close time
    const openUntilNullResponse = '''
    {
      "closetime": null
    }
    ''';

    Widget createTestApp(
        {required Map<String, String> mockResponses,
        Map<String, int>? statusCodes}) {
      final mockClient = MockHttpClient(
        responses: mockResponses,
        statusCodes: statusCodes ?? {},
      );

      return MaterialApp(
        home: Scaffold(
          body: TestSpaceStatusCard(client: mockClient),
        ),
      );
    }

    testWidgets('displays "Closed" when space is closed',
        (WidgetTester tester) async {
      await tester.pumpWidget(createTestApp(
        mockResponses: {
          'https://spaceapi.eigenbaukombinat.de/': closedSpaceResponse,
        },
      ));

      // Wait for the initial loading
      await tester.pump();

      // Wait for HTTP request completion
      await tester.pumpAndSettle();

      // Verify closed status is displayed
      expect(find.text('Space Status'), findsOneWidget);
      expect(find.text('Closed'), findsOneWidget);
      expect(find.byIcon(Icons.lock), findsOneWidget);

      // Verify space info is displayed
      expect(find.text('Eigenbaukombinat Halle'), findsOneWidget);
      expect(find.text('Landsberger Str. 3, 06112 Halle (Saale), Germany'),
          findsOneWidget);

      // Verify no "open until" text is shown
      expect(find.textContaining('Open until'), findsNothing);
    });

    testWidgets(
        'displays "Open" when space is open but no close time available',
        (WidgetTester tester) async {
      await tester.pumpWidget(createTestApp(
        mockResponses: {
          'https://spaceapi.eigenbaukombinat.de/': openSpaceResponse,
          'https://spaceapi.eigenbaukombinat.de/openuntil.json':
              openUntilNullResponse,
        },
      ));

      // Wait for all requests to complete
      await tester.pump();
      await tester.pumpAndSettle();

      // Verify open status is displayed
      expect(find.text('Open'), findsOneWidget);
      expect(find.byIcon(Icons.lock_open), findsOneWidget);

      // Verify no "open until" text is shown when close time is null
      expect(find.textContaining('Open until'), findsNothing);
    });

    testWidgets('displays "Open until X:XX" when space is open with close time',
        (WidgetTester tester) async {
      await tester.pumpWidget(createTestApp(
        mockResponses: {
          'https://spaceapi.eigenbaukombinat.de/': openSpaceResponse,
          'https://spaceapi.eigenbaukombinat.de/openuntil.json':
              openUntilWithTimeResponse,
        },
      ));

      // Wait for all requests to complete
      await tester.pump();
      await tester.pumpAndSettle();

      // Verify open status is displayed
      expect(find.text('Open'), findsOneWidget);
      expect(find.byIcon(Icons.lock_open), findsOneWidget);

      // Verify "open until" text is shown with the time
      expect(find.text('Open until 18:30'), findsOneWidget);
      expect(find.byIcon(Icons.schedule), findsOneWidget);
    });

    testWidgets('handles API errors gracefully', (WidgetTester tester) async {
      await tester.pumpWidget(createTestApp(
        mockResponses: {
          'https://spaceapi.eigenbaukombinat.de/': 'Server Error',
        },
        statusCodes: {
          'https://spaceapi.eigenbaukombinat.de/': 500,
        },
      ));

      // Wait for the request to complete
      await tester.pump();
      await tester.pumpAndSettle();

      // Verify error state is displayed
      expect(find.textContaining('Error loading status'), findsOneWidget);
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
    });

    testWidgets('handles openuntil API failure gracefully when space is open',
        (WidgetTester tester) async {
      await tester.pumpWidget(createTestApp(
        mockResponses: {
          'https://spaceapi.eigenbaukombinat.de/': openSpaceResponse,
          'https://spaceapi.eigenbaukombinat.de/openuntil.json': 'Not Found',
        },
        statusCodes: {
          'https://spaceapi.eigenbaukombinat.de/openuntil.json': 404,
        },
      ));

      // Wait for the requests to complete
      await tester.pump();
      await tester.pumpAndSettle();

      // Verify open status is still displayed (main API worked)
      expect(find.text('Open'), findsOneWidget);
      expect(find.byIcon(Icons.lock_open), findsOneWidget);

      // Verify no "open until" text is shown (openuntil API failed)
      expect(find.textContaining('Open until'), findsNothing);

      // Verify no error is shown (openuntil failure should be silent)
      expect(find.byIcon(Icons.error_outline), findsNothing);
    });
  });
}

// Test widget that accepts a custom HTTP client
class TestSpaceStatusCard extends StatefulWidget {
  final http.Client client;

  const TestSpaceStatusCard({super.key, required this.client});

  @override
  State<TestSpaceStatusCard> createState() => _TestSpaceStatusCardState();
}

class _TestSpaceStatusCardState extends State<TestSpaceStatusCard> {
  space_api.SpaceApiResponse? _spaceData;
  space_api.OpenUntilResponse? _openUntilData;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadSpaceData();
  }

  Future<void> _loadSpaceData() async {
    // Create a service with our test client
    final testService = SpaceApiService(client: widget.client);

    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final data = await testService.getSpaceStatus();

      // If space is open, also fetch the open until data
      space_api.OpenUntilResponse? openUntilData;
      if (data.state.open) {
        try {
          openUntilData = await testService.getOpenUntil();
        } catch (e) {
          // Don't fail the whole request if openuntil fails
          print('Failed to fetch open until data: $e');
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
                  onPressed: _isLoading ? null : _loadSpaceData,
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
    final statusColor = isOpen ? Colors.green : Colors.red;
    final statusText = isOpen ? 'Open' : 'Closed';
    final statusIcon = isOpen ? Icons.lock_open : Icons.lock;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: statusColor.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: statusColor.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
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
          if (isOpen && _openUntilData?.closeTime != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.schedule,
                  color: statusColor.shade600,
                  size: 16,
                ),
                const SizedBox(width: 6),
                Text(
                  'Open until ${_openUntilData!.closeTime}',
                  style: TextStyle(
                    fontSize: 14,
                    color: statusColor.shade700,
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
