/// Event Streaming Module
/// Provides EventChannel integration for Android→Flutter event broadcasting
/// 
/// Source: sdd-event-streaming specification
/// Tasks: event-001, event-002, event-003, event-004

import 'dart:async';
import 'package:flutter/services.dart';
import 'package:logger/logger.dart';

/// Event types supported by the streaming system
class TeleEventType {
  static const String serviceStarted = 'service_started';
  static const String callReceived = 'call_received';
  static const String callChanged = 'call_changed';
  static const String callTerminated = 'call_terminated';
  static const String callError = 'call_error';
  static const String connectivityChanged = 'connectivity_changed';
  static const String registrationChanged = 'registration_changed';
}

/// TeleEndpoint - EventChannel integration for telephony events
/// 
/// Receives events from Android native code via EventChannel
/// Routes events to separate broadcast streams by event type
/// 
/// Usage:
/// ```dart
/// final endpoint = TeleEndpoint();
/// endpoint.on(TeleEventType.callReceived).listen((call) {
///   print('Incoming call: ${call['remoteNumber']}');
/// });
/// ```
class TeleEndpoint {
  static const EventChannel _eventChannel = EventChannel('flutter_tele_events');
  
  final Logger _logger = Logger();
  
  StreamSubscription<dynamic>? _eventSubscription;
  final Map<String, StreamController<dynamic>> _eventControllers = {};
  
  bool _isInitialized = false;
  
  /// Initialize the event channel
  Future<void> initialize() async {
    if (_isInitialized) {
      _logger.w('TeleEndpoint already initialized');
      return;
    }
    
    try {
      _logger.i('TeleEndpoint: Setting up event channel');
      _setupEventChannel();
      _isInitialized = true;
      _logger.i('TeleEndpoint: Event channel initialized successfully');
    } catch (error, stackTrace) {
      _logger.e('TeleEndpoint: Failed to initialize event channel', 
                error: error, stackTrace: stackTrace);
      rethrow;
    }
  }
  
  /// Setup EventChannel listener
  void _setupEventChannel() {
    _logger.d('TeleEndpoint: Subscribing to event channel');
    
    _eventSubscription = _eventChannel.receiveBroadcastStream().listen(
      (dynamic event) {
        _logger.d('TeleEndpoint: Received event from native: $event');
        _handleEvent(event);
      },
      onError: (dynamic error) {
        _logger.e('TeleEndpoint: EventChannel error', error: error);
        _handleError('channel_error', error.toString());
      },
      onDone: () {
        _logger.w('TeleEndpoint: EventChannel stream closed');
        _isInitialized = false;
      },
      cancelOnError: false,
    );
  }
  
  /// Handle incoming event from native code
  void _handleEvent(dynamic event) {
    try {
      if (event is Map) {
        // Convert all keys to strings for consistency
        final eventMap = event.map<String, dynamic>(
          (key, value) => MapEntry(key.toString(), value),
        );
        
        final eventType = eventMap['type'] as String?;
        final eventData = eventMap['data'] as dynamic;
        
        _logger.d('TeleEndpoint: Event type: $eventType, data: $eventData');
        
        if (eventType == null) {
          _logger.w('TeleEndpoint: Event missing type field');
          return;
        }
        
        // Route event to appropriate controller
        _routeEvent(eventType, eventData);
      } else {
        _logger.w('TeleEndpoint: Event is not a Map: ${event.runtimeType}');
      }
    } catch (error, stackTrace) {
      _logger.e('TeleEndpoint: Error handling event', error: error, stackTrace: stackTrace);
    }
  }
  
  /// Route event to the appropriate stream controller
  void _routeEvent(String eventType, dynamic eventData) {
    // Ensure controller exists for this event type
    if (!_eventControllers.containsKey(eventType)) {
      _logger.d('TeleEndpoint: Creating controller for event type: $eventType');
      _eventControllers[eventType] = StreamController<dynamic>.broadcast(
        onCancel: () {
          _logger.d('TeleEndpoint: All listeners unsubscribed from $eventType');
        },
      );
    }
    
    // Send event to controller
    final controller = _eventControllers[eventType];
    if (controller != null && !controller.isClosed) {
      controller.add(eventData);
      _logger.d('TeleEndpoint: Event routed to $eventType controller');
    } else {
      _logger.w('TeleEndpoint: Controller for $eventType is closed');
    }
  }
  
  /// Handle error events
  void _handleError(String errorType, String errorMessage) {
    final errorData = {
      'type': errorType,
      'message': errorMessage,
      'timestamp': DateTime.now().toIso8601String(),
    };
    
    // Route to call_error controller if exists
    if (_eventControllers.containsKey(TeleEventType.callError)) {
      _eventControllers[TeleEventType.callError]!.add(errorData);
    }
    
    _logger.e('TeleEndpoint: Error event', error: errorData);
  }
  
  /// Subscribe to events of a specific type
  /// 
  /// Returns a broadcast stream that multiple listeners can subscribe to
  /// 
  /// Example:
  /// ```dart
  /// endpoint.on(TeleEventType.callReceived).listen((call) {
  ///   // Handle incoming call
  /// });
  /// ```
  Stream<dynamic> on(String eventType) {
    _logger.d('TeleEndpoint: Creating event stream for type: $eventType');
    
    // Create controller if it doesn't exist
    if (!_eventControllers.containsKey(eventType)) {
      _logger.d('TeleEndpoint: Creating new controller for event type: $eventType');
      _eventControllers[eventType] = StreamController<dynamic>.broadcast(
        onCancel: () {
          _logger.d('TeleEndpoint: All listeners unsubscribed from $eventType');
        },
      );
    }
    
    return _eventControllers[eventType]!.stream;
  }
  
  /// Check if endpoint is initialized
  bool get isInitialized => _isInitialized;
  
  /// Get count of active event controllers
  int get controllerCount => _eventControllers.length;
  
  /// Dispose resources and close all streams
  void dispose() {
    _logger.i('TeleEndpoint: Disposing event channel');
    
    // Cancel event subscription
    _eventSubscription?.cancel();
    _eventSubscription = null;
    
    // Close all event controllers
    for (final entry in _eventControllers.entries) {
      if (!entry.value.isClosed) {
        entry.value.close();
        _logger.d('TeleEndpoint: Closed controller for ${entry.key}');
      }
    }
    _eventControllers.clear();
    
    _isInitialized = false;
    _logger.i('TeleEndpoint: Disposed successfully');
  }
}

/// Extension for convenient event listening
extension TeleEndpointExtension on TeleEndpoint {
  /// Subscribe to call received events
  Stream<dynamic> get callReceived => on(TeleEventType.callReceived);
  
  /// Subscribe to call changed events
  Stream<dynamic> get callChanged => on(TeleEventType.callChanged);
  
  /// Subscribe to call terminated events
  Stream<dynamic> get callTerminated => on(TeleEventType.callTerminated);
  
  /// Subscribe to call error events
  Stream<dynamic> get callError => on(TeleEventType.callError);
  
  /// Subscribe to service started events
  Stream<dynamic> get serviceStarted => on(TeleEventType.serviceStarted);
  
  /// Subscribe to connectivity changed events
  Stream<dynamic> get connectivityChanged => on(TeleEventType.connectivityChanged);
  
  /// Subscribe to registration changed events
  Stream<dynamic> get registrationChanged => on(TeleEventType.registrationChanged);
}
