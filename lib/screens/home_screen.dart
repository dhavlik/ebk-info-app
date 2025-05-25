import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../models/event.dart';
import '../services/event_service.dart';
import '../services/background_polling_service.dart';
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
        // App ist wieder im Vordergrund - manuellen Check durchführen
        BackgroundPollingService.checkNow();
        break;
      case AppLifecycleState.paused:
        // App in den Hintergrund - Polling läuft weiter
        break;
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        // App inaktiv oder beendet
        break;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _setupLocalizationCallbacks();
  }

  void _setupLocalizationCallbacks() {
    final l10n = AppLocalizations.of(context);
    if (l10n != null) {
      BackgroundPollingService.setLocalizationCallbacks(
        getStatusChangedTitle: () => l10n.ebkStatusChanged,
        getStatusChangedBody: (status) => l10n.eigenbaukombinatIsNow(status),
        getOpenUntilChangedTitle: () => l10n.ebkOpeningTimeChanged,
        getOpenUntilChangedBody: (time) => l10n.openUntil(time),
      );
    }
  }

  Future<void> _loadEvents() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final loadedEvents = await _eventService.getEvents(
        limit: showAllEvents ? null : 5,
      );

      setState(() {
        events = loadedEvents;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage =
            'Could not reach calendar endpoint'; // Keep hardcoded as fallback
        events = EventService.getSampleEvents(); // Fallback to sample events
        isLoading = false;
      });
    }
  }

  Future<void> _refreshData() async {
    // Manuelle Aktualisierung des Space-Status
    await BackgroundPollingService.checkNow();
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
            Container(
              margin: const EdgeInsets.only(right: 8),
              child: Tooltip(
                message:
                    'Debug Mode: Using team-tfm.com endpoints, 15s polling',
                child: Icon(
                  Icons.bug_report,
                  size: 18,
                  color: Colors.orange,
                ),
              ),
            ),
          // Status-Indikator für Background-Polling
          Container(
            margin: const EdgeInsets.only(right: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  BackgroundPollingService.isRunning
                      ? Icons.sync
                      : Icons.sync_disabled,
                  size: 18,
                  color: BackgroundPollingService.isRunning
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
            tooltip: l10n.refresh,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshData,
        child: isLoading
            ? const Center(
                child: CircularProgressIndicator(),
              )
            : CustomScrollView(
                slivers: [
                  // Space Status
                  const SliverToBoxAdapter(
                    child: SpaceStatusCard(),
                  ),

                  // Veranstaltungen Header
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
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
                                      .titleLarge
                                      ?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                ),
                              ),
                              if (events.isNotEmpty)
                                TextButton(
                                  onPressed: _toggleShowAllEvents,
                                  child: Text(showAllEvents
                                      ? l10n.showLess
                                      : l10n.showAll),
                                ),
                            ],
                          ),
                          if (errorMessage != null)
                            Container(
                              margin: const EdgeInsets.only(top: 8),
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Theme.of(context)
                                    .colorScheme
                                    .errorContainer,
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(
                                    color: Theme.of(context).colorScheme.error),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.warning_amber,
                                      size: 16,
                                      color:
                                          Theme.of(context).colorScheme.error),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      l10n.couldNotReachCalendarEndpoint,
                                      style: TextStyle(
                                        fontSize: 12,
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

                  // Veranstaltungsliste
                  events.isEmpty
                      ? SliverToBoxAdapter(
                          child: Container(
                            padding: const EdgeInsets.all(32),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.event_busy,
                                  size: 64,
                                  color: Colors.grey[400],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Keine kommenden Veranstaltungen',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(
                                        color: Colors.grey[600],
                                      ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Schauen Sie später wieder vorbei oder ziehen Sie zum Aktualisieren nach unten.',
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(
                                        color: Colors.grey[500],
                                      ),
                                ),
                              ],
                            ),
                          ),
                        )
                      : SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              return EventCard(event: events[index]);
                            },
                            childCount: events.length,
                          ),
                        ),

                  // Bottom Padding
                  const SliverToBoxAdapter(
                    child: SizedBox(height: 20),
                  ),

                  // Wichtige Links
                  const SliverToBoxAdapter(
                    child: ImportantLinksCard(),
                  ),
                ],
              ),
      ),
    );
  }
}
