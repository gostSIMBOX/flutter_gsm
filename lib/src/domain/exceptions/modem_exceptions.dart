/// Modem exceptions
class ModemException implements Exception {
  final String message;

  const ModemException(this.message);

  @override
  String toString() => 'ModemException: $message';
}

/// Modem driver not available on this platform yet
///
/// Distinct from an empty device list: the platform implementation exists
/// but has no real driver behind it (e.g. the Linux stub registered by
/// sdd-flutter_gsmsip-interface before sdd-flutter_gsmsip-channel lands).
/// `ModemRepositoryImpl` throws this instead of letting `UnimplementedError`
/// leak to callers, so UI code doesn't need to catch that directly.
class ModemDriverNotAvailableException extends ModemException {
  const ModemDriverNotAvailableException()
      : super('Modem driver is not available on this platform yet');
}

/// No modem found with the given id
class ModemNotFoundException extends ModemException {
  final String modemId;

  const ModemNotFoundException(this.modemId)
      : super('No modem found with id: $modemId');
}

/// Android: the app isn't the default dialer yet
///
/// Answering/holding/muting/hanging up calls via `flutter_tele`'s managed
/// call state requires default-dialer status (`InCallService`); dialing
/// out does not (it uses a plain `Intent.ACTION_CALL`) — see
/// flows/sdd-flutter_gsm/04-implementation-log.md Task 4 for why the two
/// are gated differently. Callers should prompt the user via
/// `flutter_dialer`'s `setDefaultDialer()` rather than retry blindly.
class ModemNotDefaultDialerException extends ModemException {
  const ModemNotDefaultDialerException()
      : super('App is not the default dialer — call setDefaultDialer() first');
}

/// No active SIM call found with the given call id
class ModemCallNotFoundException extends ModemException {
  final String callId;

  const ModemCallNotFoundException(this.callId)
      : super('No active call found with id: $callId');
}
