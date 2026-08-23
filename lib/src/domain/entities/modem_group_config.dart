import 'package:equatable/equatable.dart';

/// Call-pacing algorithm for a modem group
enum PacingAlgorithm {
  /// No pacing — dial as fast as requested
  none,

  /// Slow down between consecutive calls
  diffSlow,

  /// No enforced difference between calls
  noDiff,
}

extension PacingAlgorithmExtension on PacingAlgorithm {
  String toJson() => name;

  static PacingAlgorithm? fromJson(String? value) {
    if (value == null) return null;
    try {
      return PacingAlgorithm.values.firstWhere((e) => e.name == value);
    } catch (e) {
      return null;
    }
  }
}

/// Per-group call limits and pacing configuration
///
/// Replaces simbox-desktop-v2015's flat per-plan files
/// (`<plan>.online_max`, `.limit_max.N` for 4 time buckets, `.priority`,
/// pacing settings) with a structured, typed entity.
class ModemGroupConfig extends Equatable {
  final String groupId;

  /// Maximum concurrent online/connected calls for this group
  final int onlineMax;

  /// Max calls per period, one entry per time bucket (4 buckets in the
  /// legacy system)
  final List<int> limitMaxByPeriod;

  /// Routing priority (lower = higher priority, matches legacy `pri`)
  final int priority;

  final PacingAlgorithm pacingAlgorithm;

  /// "Slow down" pacing parameter (legacy `diff_slow`)
  final int? pacingDiffSlow;

  /// "No difference" pacing parameter (legacy `nodiff`)
  final int? pacingNoDiff;

  const ModemGroupConfig({
    required this.groupId,
    this.onlineMax = 0,
    this.limitMaxByPeriod = const [0, 0, 0, 0],
    this.priority = 0,
    this.pacingAlgorithm = PacingAlgorithm.none,
    this.pacingDiffSlow,
    this.pacingNoDiff,
  });

  ModemGroupConfig copyWith({
    String? groupId,
    int? onlineMax,
    List<int>? limitMaxByPeriod,
    int? priority,
    PacingAlgorithm? pacingAlgorithm,
    int? pacingDiffSlow,
    int? pacingNoDiff,
  }) {
    return ModemGroupConfig(
      groupId: groupId ?? this.groupId,
      onlineMax: onlineMax ?? this.onlineMax,
      limitMaxByPeriod: limitMaxByPeriod ?? this.limitMaxByPeriod,
      priority: priority ?? this.priority,
      pacingAlgorithm: pacingAlgorithm ?? this.pacingAlgorithm,
      pacingDiffSlow: pacingDiffSlow ?? this.pacingDiffSlow,
      pacingNoDiff: pacingNoDiff ?? this.pacingNoDiff,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'groupId': groupId,
      'onlineMax': onlineMax,
      'limitMaxByPeriod': limitMaxByPeriod,
      'priority': priority,
      'pacingAlgorithm': pacingAlgorithm.toJson(),
      if (pacingDiffSlow != null) 'pacingDiffSlow': pacingDiffSlow,
      if (pacingNoDiff != null) 'pacingNoDiff': pacingNoDiff,
    };
  }

  factory ModemGroupConfig.fromJson(Map<String, dynamic> json) {
    return ModemGroupConfig(
      groupId: json['groupId'] as String? ?? '',
      onlineMax: json['onlineMax'] as int? ?? 0,
      limitMaxByPeriod: (json['limitMaxByPeriod'] as List?)
              ?.map((e) => e as int)
              .toList() ??
          const [0, 0, 0, 0],
      priority: json['priority'] as int? ?? 0,
      pacingAlgorithm: PacingAlgorithmExtension.fromJson(
              json['pacingAlgorithm'] as String?) ??
          PacingAlgorithm.none,
      pacingDiffSlow: json['pacingDiffSlow'] as int?,
      pacingNoDiff: json['pacingNoDiff'] as int?,
    );
  }

  @override
  List<Object?> get props => [
        groupId,
        onlineMax,
        limitMaxByPeriod,
        priority,
        pacingAlgorithm,
        pacingDiffSlow,
        pacingNoDiff,
      ];
}
