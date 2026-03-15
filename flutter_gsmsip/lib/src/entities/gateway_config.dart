/// Gateway Config entity
import 'package:equatable/equatable.dart';
import 'sip_account.dart';

class GatewayConfig extends Equatable {
  final SipAccount sipAccount;
  final bool autoAnswer;
  final bool enableLogging;

  const GatewayConfig({
    required this.sipAccount,
    this.autoAnswer = false,
    this.enableLogging = true,
  });

  @override
  List<Object?> get props => [sipAccount, autoAnswer, enableLogging];
}
