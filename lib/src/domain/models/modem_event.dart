import 'package:equatable/equatable.dart';
import '../entities/modem_device.dart';
import '../entities/modem_call.dart';
import 'modem_state.dart';

/// Push-style event emitted by a modem platform implementation
///
/// Modem/call/SMS/USSD state changes are inherently push-driven (RING,
/// +CMTI, disconnects, ...), so `FlutterGsmPlatform.modemEvents`
/// exposes a `Stream<ModemEvent>` rather than requiring callers to poll.
/// This is a Dart 3 sealed class hierarchy — switch/pattern-match
/// exhaustively on the subtype.
sealed class ModemEvent extends Equatable {
  final String modemId;
  final DateTime timestamp;

  const ModemEvent({required this.modemId, required this.timestamp});

  @override
  List<Object?> get props => [modemId, timestamp];
}

/// A modem was discovered/attached
class ModemAttached extends ModemEvent {
  final ModemDevice device;

  const ModemAttached({
    required super.modemId,
    required super.timestamp,
    required this.device,
  });

  @override
  List<Object?> get props => [...super.props, device];
}

/// A modem was removed/disconnected
class ModemDetached extends ModemEvent {
  const ModemDetached({required super.modemId, required super.timestamp});
}

/// A modem's lifecycle state changed
class ModemStateChanged extends ModemEvent {
  final ModemState previous;
  final ModemState current;

  const ModemStateChanged({
    required super.modemId,
    required super.timestamp,
    required this.previous,
    required this.current,
  });

  @override
  List<Object?> get props => [...super.props, previous, current];
}

/// A modem's signal strength changed
class ModemSignalChanged extends ModemEvent {
  /// CSQ-style 0-31 RSSI
  final int signal;

  const ModemSignalChanged({
    required super.modemId,
    required super.timestamp,
    required this.signal,
  });

  @override
  List<Object?> get props => [...super.props, signal];
}

/// A modem's network registration state changed
class ModemRegistrationChanged extends ModemEvent {
  final RegistrationState state;

  const ModemRegistrationChanged({
    required super.modemId,
    required super.timestamp,
    required this.state,
  });

  @override
  List<Object?> get props => [...super.props, state];
}

/// A call on this modem changed state
class ModemCallStateChanged extends ModemEvent {
  final ModemCall call;

  const ModemCallStateChanged({
    required super.modemId,
    required super.timestamp,
    required this.call,
  });

  @override
  List<Object?> get props => [...super.props, call];
}

/// An SMS was received on this modem
class ModemSmsReceived extends ModemEvent {
  final String from;
  final String text;
  final DateTime receivedAt;

  const ModemSmsReceived({
    required super.modemId,
    required super.timestamp,
    required this.from,
    required this.text,
    required this.receivedAt,
  });

  @override
  List<Object?> get props => [...super.props, from, text, receivedAt];
}

/// An unsolicited USSD message was pushed by the network
class ModemUssdReceived extends ModemEvent {
  final String text;

  const ModemUssdReceived({
    required super.modemId,
    required super.timestamp,
    required this.text,
  });

  @override
  List<Object?> get props => [...super.props, text];
}

/// The modem reported an error condition
class ModemErrorOccurred extends ModemEvent {
  final String code;
  final String message;

  const ModemErrorOccurred({
    required super.modemId,
    required super.timestamp,
    required this.code,
    required this.message,
  });

  @override
  List<Object?> get props => [...super.props, code, message];
}
