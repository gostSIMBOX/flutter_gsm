/// Modem restart mode
///
/// Mirrors chan_svistok's 3-stage restart options
/// (`restart now` / `restart gracefully` / `restart when convenient`).
enum RestartMode {
  /// Restart immediately, dropping any active call
  now,

  /// Wait for the active call to complete, then restart
  graceful,

  /// Wait until no active channels at all, then restart
  whenConvenient,
}

extension RestartModeExtension on RestartMode {
  /// Serialization to JSON
  String toJson() => name;

  /// Deserialization from JSON
  static RestartMode? fromJson(String? value) {
    if (value == null) return null;
    try {
      return RestartMode.values.firstWhere((e) => e.name == value);
    } catch (e) {
      return null;
    }
  }
}
