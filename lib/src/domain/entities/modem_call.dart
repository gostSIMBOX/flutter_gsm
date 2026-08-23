import 'package:equatable/equatable.dart';
import 'call_state.dart' show CallDirection, CallState;

/// A call placed or received on a modem line
///
/// Kept as its own entity rather than a generic "Call" shared with
/// flutter_gsmsip's SIP domain because a modem call has no SIP
/// account/URI concept. `CallDirection`/`CallState` (`call_state.dart`)
/// are generic enough to be shared, though.
class ModemCall extends Equatable {
  final String id;
  final String modemId;
  final String number;
  final CallDirection direction;
  final CallState state;
  final DateTime? startTime;
  final DateTime? connectTime;
  final DateTime? endTime;
  final bool isOnHold;

  const ModemCall({
    required this.id,
    required this.modemId,
    required this.number,
    required this.direction,
    this.state = CallState.initiated,
    this.startTime,
    this.connectTime,
    this.endTime,
    this.isOnHold = false,
  });

  /// Call duration in seconds
  int get durationSeconds {
    if (startTime == null) return 0;
    final end = endTime ?? DateTime.now();
    final start = connectTime ?? startTime!;
    return end.difference(start).inSeconds;
  }

  bool get isActive =>
      state == CallState.active ||
      state == CallState.held ||
      state == CallState.initiated ||
      state == CallState.incoming;

  ModemCall copyWith({
    String? id,
    String? modemId,
    String? number,
    CallDirection? direction,
    CallState? state,
    DateTime? startTime,
    DateTime? connectTime,
    DateTime? endTime,
    bool? isOnHold,
  }) {
    return ModemCall(
      id: id ?? this.id,
      modemId: modemId ?? this.modemId,
      number: number ?? this.number,
      direction: direction ?? this.direction,
      state: state ?? this.state,
      startTime: startTime ?? this.startTime,
      connectTime: connectTime ?? this.connectTime,
      endTime: endTime ?? this.endTime,
      isOnHold: isOnHold ?? this.isOnHold,
    );
  }

  @override
  List<Object?> get props => [
        id,
        modemId,
        number,
        direction,
        state,
        startTime,
        connectTime,
        endTime,
        isOnHold,
      ];

  @override
  String toString() =>
      'ModemCall(id: $id, modemId: $modemId, number: $number, state: $state)';
}
