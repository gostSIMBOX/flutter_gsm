import '../domain/entities/call_state.dart';
import '../domain/entities/modem_device.dart' show RegistrationState;
import '../domain/models/modem_state.dart';
import '../ffi/simbox_bindings.dart' show simbox_device_state_t;

/// `simbox_device_state_t` -> `ModemState` mapping — see
/// flows/sdd-flutter_gsm-ffi/02-specifications.md "Event Bridging".
///
/// `ModemState` has no dedicated "ringing"/"dialing"/"diagnostic" value
/// (only init/registering/registered/ready/callActive/callOnHold/error/
/// removed exist) — `RINGING`/`DIALING` both map to `callActive` (a call
/// is in progress either way), `DIAGNOSTIC` maps to `error` (closest
/// existing value; adding finer-grained states is a separate enum
/// addition to propose if a UI ever needs it, not smuggled in here).
ModemState simboxDeviceStateToModemState(simbox_device_state_t state) {
  return switch (state) {
    simbox_device_state_t.SIMBOX_STATE_DISCONNECTED => ModemState.removed,
    simbox_device_state_t.SIMBOX_STATE_CONNECTING => ModemState.init,
    simbox_device_state_t.SIMBOX_STATE_IDLE => ModemState.registered,
    simbox_device_state_t.SIMBOX_STATE_RINGING => ModemState.callActive,
    simbox_device_state_t.SIMBOX_STATE_DIALING => ModemState.callActive,
    simbox_device_state_t.SIMBOX_STATE_ACTIVE_CALL => ModemState.callActive,
    simbox_device_state_t.SIMBOX_STATE_HOLD => ModemState.callOnHold,
    simbox_device_state_t.SIMBOX_STATE_ERROR => ModemState.error,
    simbox_device_state_t.SIMBOX_STATE_DIAGNOSTIC => ModemState.error,
  };
}

/// `simbox_device_state_t` -> `CallState` mapping, used to interpret
/// `SIMBOX_EVENT_CALL_STATE_CHANGED`'s `new_state` (an `int` in the C
/// union, reinterpreted as `simbox_device_state_t`) into `ModemCall`'s
/// terminal/in-progress states. `IDLE`/`DISCONNECTED` both mean "the
/// call is over, device is back to idle or gone" -> `terminated`;
/// `ERROR` -> `failed`. `CONNECTING`/`DIAGNOSTIC` have no call-state
/// equivalent (not call-related device states) and return null — a
/// `CALL_STATE_CHANGED` event landing on one of those would be a
/// malformed/unexpected payload, not a real transition, so the caller
/// should drop it rather than fabricate a `CallState`.
CallState? simboxDeviceStateToCallState(simbox_device_state_t state) {
  return switch (state) {
    simbox_device_state_t.SIMBOX_STATE_DISCONNECTED => CallState.terminated,
    simbox_device_state_t.SIMBOX_STATE_CONNECTING => null,
    simbox_device_state_t.SIMBOX_STATE_IDLE => CallState.terminated,
    simbox_device_state_t.SIMBOX_STATE_RINGING => CallState.incoming,
    simbox_device_state_t.SIMBOX_STATE_DIALING => CallState.initiated,
    simbox_device_state_t.SIMBOX_STATE_ACTIVE_CALL => CallState.active,
    simbox_device_state_t.SIMBOX_STATE_HOLD => CallState.held,
    simbox_device_state_t.SIMBOX_STATE_ERROR => CallState.failed,
    simbox_device_state_t.SIMBOX_STATE_DIAGNOSTIC => null,
  };
}

/// `simbox_device_state_t` -> `RegistrationState` mapping.
///
/// Not given directly by `simbox_api.h` (it only models a single
/// combined device-lifecycle-and-call state) — inferred: any state that
/// implies the device can ring/dial/hold/be-in-a-call also implies it's
/// registered on a network, since none of those are possible otherwise.
/// No native signal distinguishes home registration from roaming, so
/// `roaming`/`searching` are never produced here.
RegistrationState simboxDeviceStateToRegistrationState(
  simbox_device_state_t state,
) {
  return switch (state) {
    simbox_device_state_t.SIMBOX_STATE_DISCONNECTED =>
      RegistrationState.notRegistered,
    simbox_device_state_t.SIMBOX_STATE_CONNECTING =>
      RegistrationState.notRegistered,
    simbox_device_state_t.SIMBOX_STATE_IDLE => RegistrationState.registered,
    simbox_device_state_t.SIMBOX_STATE_RINGING =>
      RegistrationState.registered,
    simbox_device_state_t.SIMBOX_STATE_DIALING =>
      RegistrationState.registered,
    simbox_device_state_t.SIMBOX_STATE_ACTIVE_CALL =>
      RegistrationState.registered,
    simbox_device_state_t.SIMBOX_STATE_HOLD => RegistrationState.registered,
    simbox_device_state_t.SIMBOX_STATE_ERROR =>
      RegistrationState.notRegistered,
    simbox_device_state_t.SIMBOX_STATE_DIAGNOSTIC =>
      RegistrationState.notRegistered,
  };
}
