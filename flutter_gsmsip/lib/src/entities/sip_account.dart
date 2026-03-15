/// SIP Account entity
import 'package:equatable/equatable.dart';

class SipAccount extends Equatable {
  final String id;
  final String username;
  final String password;
  final String domain;
  final int port;

  const SipAccount({
    required this.id,
    required this.username,
    required this.password,
    required this.domain,
    this.port = 5060,
  });

  @override
  List<Object?> get props => [id, username, password, domain, port];
}
