/// Modem device state
///
/// Mirrors chan_svistok's 8-state call machine at the device level,
/// extended with lifecycle states chan_svistok models separately
/// (init/removed) and a dedicated error state.
enum ModemState {
  /// Driver/device just discovered, not yet initialized
  init,

  /// Initialized, registered, idle — ready to place/receive calls
  ready,

  /// Attempting network registration
  registering,

  /// Registered on network, no active call
  registered,

  /// Call in progress
  callActive,

  /// Call on hold
  callOnHold,

  /// Device reported an error condition
  error,

  /// Device was removed/disconnected
  removed,
}

extension ModemStateExtension on ModemState {
  /// Whether the device can currently accept a new outgoing call
  bool get canDial => this == ModemState.ready || this == ModemState.registered;

  /// Serialization to JSON
  String toJson() => name;

  /// Deserialization from JSON
  static ModemState? fromJson(String? value) {
    if (value == null) return null;
    try {
      return ModemState.values.firstWhere((e) => e.name == value);
    } catch (e) {
      return null;
    }
  }
}
