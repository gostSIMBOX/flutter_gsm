import 'package:equatable/equatable.dart';

/// Result of a raw AT command execution against a modem
class AtCommandResult extends Equatable {
  /// Full raw response text from the modem
  final String raw;

  /// Whether the command completed successfully (terminal `OK`)
  final bool ok;

  /// CME/CMS error text, if the command failed
  final String? error;

  /// Round-trip duration in milliseconds
  final int durationMs;

  const AtCommandResult({
    required this.raw,
    required this.ok,
    this.error,
    required this.durationMs,
  });

  /// Serialization to JSON
  Map<String, dynamic> toJson() {
    return {
      'raw': raw,
      'ok': ok,
      if (error != null) 'error': error,
      'durationMs': durationMs,
    };
  }

  /// Deserialization from JSON
  factory AtCommandResult.fromJson(Map<String, dynamic> json) {
    return AtCommandResult(
      raw: json['raw'] as String? ?? '',
      ok: json['ok'] as bool? ?? false,
      error: json['error'] as String?,
      durationMs: json['durationMs'] as int? ?? 0,
    );
  }

  @override
  List<Object?> get props => [raw, ok, error, durationMs];

  @override
  String toString() =>
      'AtCommandResult(ok: $ok, durationMs: $durationMs, raw: $raw)';
}
