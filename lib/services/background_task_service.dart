import 'dart:async';
import 'dart:developer';
import 'package:flutter/foundation.dart';
import 'package:workmanager/workmanager.dart';
import 'package:flutter_background/flutter_background.dart';
import '../models/space_api_response.dart';
import 'space_api_service.dart';
import 'notification_service.dart';

/// Background task service for reliable background processing
/// Uses WorkManager for Android and periodic tasks for other platforms
class BackgroundTaskService {
  static const String _taskName = "space_status_check";
  static const String _uniqueTaskName = "space_status_periodic_check";

  static SpaceApiResponse? _lastResponse;
  static String? _lastOpenUntil;
  static Timer? _timer;
  static bool _isInitialized = false;
  static bool _isRunning = false;

  // Callback functions for localized strings
  static String Function()? _getStatusChangedTitle;
  static String Function(String status)? _getStatusChangedBody;
  static String Function()? _getOpenUntilChangedTitle;
  static String Function(String time)? _getOpenUntilChangedBody;

  /// Initialize WorkManager and background tasks
  static Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      await Workmanager().initialize(
        callbackDispatcher,
        isInDebugMode: kDebugMode,
      );
      _isInitialized = true;
      log('BackgroundTaskService initialized successfully');
    } catch (e) {
      log('Failed to initialize BackgroundTaskService: $e');
    }
  }

  /// Start background processing
  static Future<void> startBackgroundTasks() async {
    if (!_isInitialized) {
      await initialize();
    }

    if (_isRunning) return;

    // Try to enable background execution on Android
    if (defaultTargetPlatform == TargetPlatform.android) {
      await _enableBackgroundExecution();
    }

    _isRunning = true;

    // For Android: Use WorkManager for reliable background execution
    if (defaultTargetPlatform == TargetPlatform.android) {
      await _startAndroidBackgroundTask();
    } else {
      // For other platforms: Use timer (iOS background processing is limited anyway)
      await _startTimerBasedTask();
    }

    // Immediate check
    await _performStatusCheck();

    log('Background tasks started');
  }

  /// Enable background execution using flutter_background
  static Future<void> _enableBackgroundExecution() async {
    try {
      // Configure background execution with minimal configuration
      const androidConfig = FlutterBackgroundAndroidConfig(
        notificationTitle: "EBK Status Monitor",
        notificationText: "Monitoring space status in background",
      );

      bool hasPermissions = await FlutterBackground.hasPermissions;

      if (!hasPermissions) {
        log('Requesting background execution permissions...');
        hasPermissions =
            await FlutterBackground.initialize(androidConfig: androidConfig);
      }

      if (hasPermissions) {
        bool success = await FlutterBackground.enableBackgroundExecution();
        if (success) {
          log('✅ Background execution enabled successfully');
        } else {
          log('❌ Failed to enable background execution');
        }
      } else {
        log('❌ Background execution permissions not granted');
      }
    } catch (e) {
      log('❌ Error enabling background execution: $e');
    }
  }

  /// Start Android WorkManager background task
  static Future<void> _startAndroidBackgroundTask() async {
    try {
      // Cancel any existing tasks
      await Workmanager().cancelByUniqueName(_uniqueTaskName);

      // Register periodic task (minimum interval is 15 minutes for WorkManager)
      await Workmanager().registerPeriodicTask(
        _uniqueTaskName,
        _taskName,
        frequency: kDebugMode
            ? const Duration(minutes: 15) // Minimum allowed by WorkManager
            : const Duration(minutes: 15), // Production: check every hour
        constraints: Constraints(
          networkType: NetworkType.connected,
          requiresBatteryNotLow: false,
          requiresCharging: false,
          requiresDeviceIdle: false,
          requiresStorageNotLow: false,
        ),
        backoffPolicy: BackoffPolicy.linear,
        backoffPolicyDelay: const Duration(minutes: 5),
      );

      // For debug mode, also start a timer for faster checks when app is active
      if (kDebugMode) {
        _startTimerBasedTask();
      }

      log('Android WorkManager background task registered');
    } catch (e) {
      log('Failed to start Android background task: $e');
      // Fallback to timer-based approach
      await _startTimerBasedTask();
    }
  }

  /// Start timer-based background task (fallback for non-Android or when WorkManager fails)
  static Future<void> _startTimerBasedTask() async {
    _timer?.cancel();

    const interval = kDebugMode
        ? Duration(seconds: 30) // Debug: 30 seconds
        : Duration(minutes: 5); // Production: 5 minutes

    _timer = Timer.periodic(interval, (timer) {
      _performStatusCheck();
    });

    log('Timer-based background task started (interval: ${interval.inSeconds}s)');
  }

  /// Stop all background tasks
  static Future<void> stopBackgroundTasks() async {
    if (!_isRunning) return;

    _isRunning = false;
    _timer?.cancel();
    _timer = null;

    if (_isInitialized && defaultTargetPlatform == TargetPlatform.android) {
      try {
        await Workmanager().cancelByUniqueName(_uniqueTaskName);
        log('Android WorkManager task cancelled');

        // Disable flutter_background if it was enabled
        if (await FlutterBackground.isBackgroundExecutionEnabled) {
          await FlutterBackground.disableBackgroundExecution();
          log('Background execution disabled');
        }
      } catch (e) {
        log('Failed to cancel Android background task: $e');
      }
    }

    log('Background tasks stopped');
  }

  /// Perform a manual status check
  static Future<void> checkNow() async {
    await _performStatusCheck();
  }

  /// The actual status checking logic
  static Future<void> _performStatusCheck() async {
    try {
      log('Performing space status check...');

      final spaceApiService = SpaceApiService();
      final response = await spaceApiService.getSpaceStatus();
      String? openUntil;

      // Check if status changed
      bool statusChanged = false;
      bool statusChangedToOpen = false;

      if (_lastResponse != null) {
        statusChanged = _lastResponse!.state.open != response.state.open;
        statusChangedToOpen = !_lastResponse!.state.open && response.state.open;
      }

      // Reset openUntil data when space changes to open
      if (statusChangedToOpen) {
        _lastOpenUntil = null;
        log('Space status changed to OPEN - OpenUntil data reset');
      }

      // Get openUntil time if space is open
      if (response.state.open) {
        try {
          final openUntilResponse = await spaceApiService.getOpenUntil();
          openUntil = openUntilResponse.closeTime;
        } catch (e) {
          log('Error fetching OpenUntil time: $e');
        }
      }

      // Check for openUntil changes (after possible reset)
      bool openUntilChanged = _lastOpenUntil != openUntil;

      // Send status change notification
      if (statusChanged &&
          _getStatusChangedTitle != null &&
          _getStatusChangedBody != null) {
        final status = response.state.open ? 'OPEN' : 'CLOSED';
        await NotificationService.showStatusChangeNotification(
          title: _getStatusChangedTitle!(),
          body: _getStatusChangedBody!(status),
        );
        log('Status change notification sent: $status');
      }

      // Send openUntil change notification (only if open and not during status change to open)
      if (openUntilChanged &&
          response.state.open &&
          openUntil != null &&
          !statusChangedToOpen &&
          _getOpenUntilChangedTitle != null &&
          _getOpenUntilChangedBody != null) {
        await NotificationService.showStatusChangeNotification(
          title: _getOpenUntilChangedTitle!(),
          body: _getOpenUntilChangedBody!(openUntil),
        );
        log('OpenUntil change notification sent: $openUntil');
      }

      // Special openUntil notification when first opening (if time is available)
      if (statusChangedToOpen &&
          openUntil != null &&
          _getOpenUntilChangedTitle != null &&
          _getOpenUntilChangedBody != null) {
        await NotificationService.showStatusChangeNotification(
          title: _getOpenUntilChangedTitle!(),
          body: _getOpenUntilChangedBody!(openUntil),
        );
        log('First openUntil notification when opening sent: $openUntil');
      }

      // Save current status
      _lastResponse = response;
      _lastOpenUntil = openUntil;

      log('Status check completed: ${response.state.open ? "open" : "closed"}');
    } catch (e) {
      log('Error during status check: $e');
    }
  }

  /// Set localization callbacks for notifications
  static void setLocalizationCallbacks({
    required String Function() getStatusChangedTitle,
    required String Function(String status) getStatusChangedBody,
    required String Function() getOpenUntilChangedTitle,
    required String Function(String time) getOpenUntilChangedBody,
  }) {
    _getStatusChangedTitle = getStatusChangedTitle;
    _getStatusChangedBody = getStatusChangedBody;
    _getOpenUntilChangedTitle = getOpenUntilChangedTitle;
    _getOpenUntilChangedBody = getOpenUntilChangedBody;
  }

  /// Reset internal state (for testing)
  static void reset() {
    stopBackgroundTasks();
    _lastResponse = null;
    _lastOpenUntil = null;
  }

  /// Check if background tasks are running
  static bool get isRunning => _isRunning;
}

/// The callback dispatcher for WorkManager
/// This function runs in a separate isolate
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      log('WorkManager task executing: $task');

      // Perform the background status check
      await BackgroundTaskService._performStatusCheck();

      return Future.value(true);
    } catch (e) {
      log('WorkManager task failed: $e');
      return Future.value(false);
    }
  });
}
