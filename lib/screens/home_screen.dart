import 'dart:developer';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_background/flutter_background.dart';
import '../models/event.dart';
import '../services/event_service.dart';
import '../services/background_task_service.dart';
import '../services/notification_service.dart';
import '../widgets/event_card.dart';
import '../widgets/space_status_card.dart';
import '../widgets/important_links_card.dart';
import '../l10n/app_localizations.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  List<Event> events = [];
  bool isLoading = true;
  bool showAllEvents = false;
  String? errorMessage;
  final EventService _eventService = EventService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadEvents();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    switch (state) {
      case AppLifecycleState.resumed:
        // App in den Vordergrund - manuelle Aktualisierung
        _refreshData();
        break;
      case AppLifecycleState.paused:
        // App in den Hintergrund - Polling läuft weiter
        break;
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        break;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _setupLocalizationCallbacks();

    // Start background tasks after localization is ready
    _startBackgroundTasksIfReady();
  }

  void _setupLocalizationCallbacks() {
    final l10n = AppLocalizations.of(context);
    if (l10n != null) {
      BackgroundTaskService.setLocalizationCallbacks(
        getStatusChangedTitle: () => l10n.ebkStatusChanged,
        getStatusChangedBody: (status) => l10n.eigenbaukombinatIsNow(status),
        getOpenUntilChangedTitle: () => l10n.ebkOpeningTimeChanged,
        getOpenUntilChangedBody: (time) => l10n.openUntil(time),
        getOpenUntilAndStatusChangedTitle: () =>
            l10n.ebkOpenUntilAndStatusChanged,
        getOpenUntilAndStatusChangedBody: (time, status) =>
            l10n.openUntilAndStatus(time, status),
      );
    }
  }

  void _startBackgroundTasksIfReady() async {
    try {
      // Start background tasks now that localization callbacks are set
      await BackgroundTaskService.startBackgroundTasks();
      log('Background tasks started successfully from home screen');
    } catch (e) {
      log('Failed to start background tasks from home screen: $e');
    }
  }

  Future<void> _loadEvents() async {
    try {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });

      final loadedEvents = await _eventService.getEvents();
      setState(() {
        events = showAllEvents ? loadedEvents : loadedEvents.take(3).toList();
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = e.toString();
        isLoading = false;
        events = EventService.getSampleEvents(); // Fallback to sample events
      });
    }
  }

  Future<void> _refreshData() async {
    // Background-Service manuell triggern
    await BackgroundTaskService.checkNow();
    // Events neu laden
    await _loadEvents();
  }

  void _showNotificationSettings() {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.notifications),
        content: Text(l10n.notificationsDescription),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.ok),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await NotificationService.requestPermissions();
              setState(() {}); // UI aktualisieren
            },
            child: Text(l10n.requestPermission),
          ),
        ],
      ),
    );
  }

  void _toggleShowAllEvents() {
    setState(() {
      showAllEvents = !showAllEvents;
    });
    _loadEvents();
  }

  Future<bool> _checkBackgroundPermissions() async {
    try {
      final hasNotifications =
          await NotificationService.areNotificationsEnabled();
      final hasBackground = await FlutterBackground.hasPermissions;
      return hasNotifications && hasBackground;
    } catch (e) {
      return false;
    }
  }

  Future<void> _requestBackgroundPermissions() async {
    try {
      // Request notification permissions
      await NotificationService.requestPermissions();

      // Request background permissions
      await BackgroundTaskService.requestBackgroundPermissions();

      // Restart background tasks with new permissions
      await BackgroundTaskService.stopBackgroundTasks();
      await BackgroundTaskService.startBackgroundTasks();

      setState(() {}); // Refresh the permission warning
    } catch (e) {
      log('Error requesting permissions: $e');
    }
  }

  Widget _buildPermissionWarning() {
    return FutureBuilder<bool>(
      future: _checkBackgroundPermissions(),
      builder: (context, snapshot) {
        if (snapshot.data == false) {
          final l10n = AppLocalizations.of(context)!;
          return Card(
            margin: const EdgeInsets.all(16),
            color: Colors.orange.withValues(alpha: 0.1),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const Icon(Icons.warning, color: Colors.orange),
                  const SizedBox(height: 8),
                  Text(
                    'Background notifications require additional permissions',
                    style: Theme.of(context).textTheme.titleMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'To receive notifications when the app is closed, please enable background app refresh.',
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: _requestBackgroundPermissions,
                    child: Text(l10n.requestPermission),
                  ),
                ],
              ),
            ),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Image.asset(
          'assets/images/ebk_logo.png',
          height: 32,
          fit: BoxFit.contain,
        ),
        centerTitle: true,
        actions: [
          // Debug-Modus Indikator
          if (kDebugMode)
            const Tooltip(
              message: 'Debug Mode',
              child: Icon(
                Icons.bug_report,
                size: 18,
                color: Colors.orange,
              ),
            ),
          // Status-Indikator für Background-Tasks
          Container(
            margin: const EdgeInsets.only(right: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  BackgroundTaskService.isRunning
                      ? Icons.sync
                      : Icons.sync_disabled,
                  size: 18,
                  color: BackgroundTaskService.isRunning
                      ? Colors.green
                      : Colors.grey,
                ),
                const SizedBox(width: 4),
                FutureBuilder<bool>(
                  future: NotificationService.areNotificationsEnabled(),
                  builder: (context, snapshot) {
                    final enabled = snapshot.data ?? false;
                    return GestureDetector(
                      onTap: () => _showNotificationSettings(),
                      child: Icon(
                        enabled ? Icons.notifications : Icons.notifications_off,
                        size: 18,
                        color: enabled ? Colors.blue : Colors.grey,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshData,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshData,
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : CustomScrollView(
                slivers: [
                  // Permission warning (if needed)
                  SliverToBoxAdapter(
                    child: _buildPermissionWarning(),
                  ),

                  // Space Status
                  const SliverToBoxAdapter(
                    child: SpaceStatusCard(),
                  ),

                  // Events Section
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.event, color: Colors.blue),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  l10n.events,
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineSmall
                                      ?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                ),
                              ),
                              if (events.isNotEmpty)
                                TextButton(
                                  onPressed: _toggleShowAllEvents,
                                  child: Text(
                                    showAllEvents
                                        ? l10n.showLess
                                        : l10n.showAll,
                                  ),
                                ),
                            ],
                          ),
                          if (errorMessage != null)
                            Container(
                              margin: const EdgeInsets.only(top: 8),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Theme.of(context)
                                    .colorScheme
                                    .errorContainer,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                    color: Theme.of(context).colorScheme.error),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.error_outline,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onErrorContainer,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      errorMessage!,
                                      style: TextStyle(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onErrorContainer,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),

                  // Events List
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => EventCard(event: events[index]),
                      childCount: events.length,
                    ),
                  ),

                  // Important Links
                  const SliverToBoxAdapter(
                    child: ImportantLinksCard(),
                  ),

                  // Bottom Padding
                  const SliverToBoxAdapter(
                    child: SizedBox(height: 20),
                  ),
                ],
              ),
      ),
    );
  }
}
