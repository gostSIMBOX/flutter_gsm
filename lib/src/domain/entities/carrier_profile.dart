import 'package:equatable/equatable.dart';

/// Per-operator USSD recipe profile
///
/// Replaces simbox-desktop-v2015's `nabor/<operator_region>/` shell-script
/// recipes (`get_balance.sh`, `get_tarif.sh`, `get_number.sh`, ...) with a
/// structured, in-process equivalent. `responseParser` names a parsing
/// strategy registered elsewhere (kept as a string id here rather than a
/// function reference, so profiles stay serializable).
class CarrierProfile extends Equatable {
  final String operatorId;
  final String displayName;
  final String regionCode;

  final String? balanceUssdTemplate;
  final String? tariffUssdTemplate;
  final String? numberUssdTemplate;

  /// Identifier of the response-parsing strategy for this operator
  final String? responseParser;

  const CarrierProfile({
    required this.operatorId,
    required this.displayName,
    required this.regionCode,
    this.balanceUssdTemplate,
    this.tariffUssdTemplate,
    this.numberUssdTemplate,
    this.responseParser,
  });

  CarrierProfile copyWith({
    String? operatorId,
    String? displayName,
    String? regionCode,
    String? balanceUssdTemplate,
    String? tariffUssdTemplate,
    String? numberUssdTemplate,
    String? responseParser,
  }) {
    return CarrierProfile(
      operatorId: operatorId ?? this.operatorId,
      displayName: displayName ?? this.displayName,
      regionCode: regionCode ?? this.regionCode,
      balanceUssdTemplate: balanceUssdTemplate ?? this.balanceUssdTemplate,
      tariffUssdTemplate: tariffUssdTemplate ?? this.tariffUssdTemplate,
      numberUssdTemplate: numberUssdTemplate ?? this.numberUssdTemplate,
      responseParser: responseParser ?? this.responseParser,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'operatorId': operatorId,
      'displayName': displayName,
      'regionCode': regionCode,
      if (balanceUssdTemplate != null)
        'balanceUssdTemplate': balanceUssdTemplate,
      if (tariffUssdTemplate != null)
        'tariffUssdTemplate': tariffUssdTemplate,
      if (numberUssdTemplate != null)
        'numberUssdTemplate': numberUssdTemplate,
      if (responseParser != null) 'responseParser': responseParser,
    };
  }

  factory CarrierProfile.fromJson(Map<String, dynamic> json) {
    return CarrierProfile(
      operatorId: json['operatorId'] as String? ?? '',
      displayName: json['displayName'] as String? ?? '',
      regionCode: json['regionCode'] as String? ?? '',
      balanceUssdTemplate: json['balanceUssdTemplate'] as String?,
      tariffUssdTemplate: json['tariffUssdTemplate'] as String?,
      numberUssdTemplate: json['numberUssdTemplate'] as String?,
      responseParser: json['responseParser'] as String?,
    );
  }

  @override
  List<Object?> get props => [
        operatorId,
        displayName,
        regionCode,
        balanceUssdTemplate,
        tariffUssdTemplate,
        numberUssdTemplate,
        responseParser,
      ];
}

/// In-memory registry of `CarrierProfile`s
///
/// Ships with no built-in profiles — the app supplies/overrides profiles
/// at runtime via [register], so operator recipes aren't hardcoded into
/// the plugin (per sdd-flutter_gsmsip-interface specifications).
class CarrierProfileRegistry {
  final Map<String, CarrierProfile> _profiles = {};

  void register(CarrierProfile profile) {
    _profiles[profile.operatorId] = profile;
  }

  void unregister(String operatorId) {
    _profiles.remove(operatorId);
  }

  CarrierProfile? operator [](String operatorId) => _profiles[operatorId];

  List<CarrierProfile> get all => List.unmodifiable(_profiles.values);
}
