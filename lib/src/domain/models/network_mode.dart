/// Radio network mode lock
///
/// Maps to chan_svistok's AT^SYSCFG-driven network mode lock (used by
/// simbox-desktop-v2015's network/frequency lock operations).
enum NetworkMode {
  /// Automatic network selection (no lock)
  auto,

  /// GSM (2G) only
  gsmOnly,

  /// WCDMA (3G) only
  wcdmaOnly,
}

extension NetworkModeExtension on NetworkMode {
  /// Serialization to JSON
  String toJson() => name;

  /// Deserialization from JSON
  static NetworkMode? fromJson(String? value) {
    if (value == null) return null;
    try {
      return NetworkMode.values.firstWhere((e) => e.name == value);
    } catch (e) {
      return null;
    }
  }
}
