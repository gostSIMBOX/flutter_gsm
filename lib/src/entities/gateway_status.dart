/// Gateway Status entity
import 'package:equatable/equatable.dart';

enum GatewayState { stopped, starting, running, error }

class GatewayStatus extends Equatable {
  final GatewayState state;
  final bool isConnected;
  final String? errorMessage;

  const GatewayStatus({
    this.state = GatewayState.stopped,
    this.isConnected = false,
    this.errorMessage,
  });

  @override
  List<Object?> get props => [state, isConnected, errorMessage];
}
