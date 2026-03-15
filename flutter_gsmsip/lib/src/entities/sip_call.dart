/// SIP Call entity
import 'package:equatable/equatable.dart';

enum SipCallState { connecting, active, held, terminated }

class SipCall extends Equatable {
  final String id;
  final String destination;
  final SipCallState state;

  const SipCall({
    required this.id,
    required this.destination,
    this.state = SipCallState.connecting,
  });

  @override
  List<Object?> get props => [id, destination, state];
}
