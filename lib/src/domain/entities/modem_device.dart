import 'package:equatable/equatable.dart';
import '../models/modem_state.dart';

/// Network registration state
enum RegistrationState {
  /// Not registered, not currently searching
  notRegistered,

  /// Registered on home network
  registered,

  /// Registered while roaming
  roaming,

  /// Searching for a network to register on
  searching,
}

extension RegistrationStateExtension on RegistrationState {
  /// Serialization to JSON
  String toJson() => name;

  /// Deserialization from JSON
  static RegistrationState? fromJson(String? value) {
    if (value == null) return null;
    try {
      return RegistrationState.values.firstWhere((e) => e.name == value);
    } catch (e) {
      return null;
    }
  }
}

/// A GSM/UMTS modem device reachable over a serial/AT-command interface
///
/// Distinct from the Android audio-passthrough "Dongle" concept
/// (`DongleType`/`DongleInterfaceType`) — this models a real modem talking
/// AT commands over a port (e.g. `/dev/ttyUSB0` on Linux), the chan_svistok
/// equivalent of a device entry.
class ModemDevice extends Equatable {
  /// Stable identifier — a tty path on Linux, or an opaque
  /// platform-assigned handle on other platforms
  final String id;

  /// Serial port path, when applicable (e.g. `/dev/ttyUSB0` on Linux)
  final String? portPath;

  final String? displayName;
  final String? manufacturer;
  final String? model;
  final String? imei;
  final String? imsi;
  final String? iccid;

  /// Group this device is assigned to (see `ModemGroupConfig`)
  final String? groupId;

  final ModemState state;

  /// Signal strength, CSQ-style 0-31 RSSI scale; null = unknown
  final int? signal;

  final RegistrationState registration;

  /// Last-known balance, carrier-formatted display string
  final String? balance;

  const ModemDevice({
    required this.id,
    this.portPath,
    this.displayName,
    this.manufacturer,
    this.model,
    this.imei,
    this.imsi,
    this.iccid,
    this.groupId,
    this.state = ModemState.init,
    this.signal,
    this.registration = RegistrationState.notRegistered,
    this.balance,
  });

  ModemDevice copyWith({
    String? id,
    String? portPath,
    String? displayName,
    String? manufacturer,
    String? model,
    String? imei,
    String? imsi,
    String? iccid,
    String? groupId,
    ModemState? state,
    int? signal,
    RegistrationState? registration,
    String? balance,
  }) {
    return ModemDevice(
      id: id ?? this.id,
      portPath: portPath ?? this.portPath,
      displayName: displayName ?? this.displayName,
      manufacturer: manufacturer ?? this.manufacturer,
      model: model ?? this.model,
      imei: imei ?? this.imei,
      imsi: imsi ?? this.imsi,
      iccid: iccid ?? this.iccid,
      groupId: groupId ?? this.groupId,
      state: state ?? this.state,
      signal: signal ?? this.signal,
      registration: registration ?? this.registration,
      balance: balance ?? this.balance,
    );
  }

  /// Serialization to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      if (portPath != null) 'portPath': portPath,
      if (displayName != null) 'displayName': displayName,
      if (manufacturer != null) 'manufacturer': manufacturer,
      if (model != null) 'model': model,
      if (imei != null) 'imei': imei,
      if (imsi != null) 'imsi': imsi,
      if (iccid != null) 'iccid': iccid,
      if (groupId != null) 'groupId': groupId,
      'state': state.toJson(),
      if (signal != null) 'signal': signal,
      'registration': registration.toJson(),
      if (balance != null) 'balance': balance,
    };
  }

  /// Deserialization from JSON
  factory ModemDevice.fromJson(Map<String, dynamic> json) {
    return ModemDevice(
      id: json['id'] as String? ?? '',
      portPath: json['portPath'] as String?,
      displayName: json['displayName'] as String?,
      manufacturer: json['manufacturer'] as String?,
      model: json['model'] as String?,
      imei: json['imei'] as String?,
      imsi: json['imsi'] as String?,
      iccid: json['iccid'] as String?,
      groupId: json['groupId'] as String?,
      state: ModemStateExtension.fromJson(json['state'] as String?) ??
          ModemState.init,
      signal: json['signal'] as int?,
      registration: RegistrationStateExtension.fromJson(
              json['registration'] as String?) ??
          RegistrationState.notRegistered,
      balance: json['balance'] as String?,
    );
  }

  @override
  List<Object?> get props => [
        id,
        portPath,
        displayName,
        manufacturer,
        model,
        imei,
        imsi,
        iccid,
        groupId,
        state,
        signal,
        registration,
        balance,
      ];

  @override
  String toString() =>
      'ModemDevice(id: $id, portPath: $portPath, state: $state)';
}
