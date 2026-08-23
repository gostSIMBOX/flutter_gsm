# flutter_gsm

[![Pub Version](https://img.shields.io/pub/v/flutter_gsm.svg)](https://pub.dev/packages/flutter_gsm)
[![License: NativeMindNONC](https://img.shields.io/badge/license-NativeMindNONC-blue.svg)](LICENSE)

Cross-platform GSM/UMTS modem hardware abstraction for Flutter: ttyUSB
AT-command modems (Linux/Windows/macOS) and native telephony (Android).
Split out of `flutter_gsmsip` (see [`flows/sdd-flutter_gsm`](flows/sdd-flutter_gsm/))
so raw GSM hardware access doesn't require pulling in SIP/SMPP bridging
logic — `flutter_gsmsip` now depends on this package for its GSM leg,
alongside `flutter_nmsip` for its SIP leg.

## 🖥️ Platform Support

| Platform | Status |
|---|---|
| Android | Real call control via `flutter_dialer`+`flutter_tele` (dial/answer/hangup/hold/mute/speaker); AT-command/firmware/diagnostic methods correctly unsupported (no Android equivalent) |
| Linux | Real ttyUSB/AT-command driver — `LinuxFlutterGsm` delegates via `dart:ffi` to `libsimbox` (built by [`sdd-asterisk-chan-simbox`](../../libsCpp/asterisk_chan_simbox/flows/sdd-asterisk-chan-simbox/)), which drives chan_svistok's real, unmodified AT-command logic without a running Asterisk instance. See [`flows/sdd-flutter_gsm-ffi`](flows/sdd-flutter_gsm-ffi/) for the binding design and [Native Library Loading](#native-library-loading-linux) below for how `libsimbox` is located at runtime. `setNetworkMode`'s `auto`/`wcdmaOnly` modes and `setDiagMode(enabled: false)`/`changeImei` are flagged gaps — see Known Issues |
| Windows / macOS | Interface registered, stub — `dart:ffi` binding is Linux-only this iteration (see `sdd-flutter_gsm-ffi`'s Non-Goals); `libsimbox`'s own Makefile already has a Darwin build branch, so a similar binding is a smaller follow-up than starting from scratch |
| OpenWRT | Native-core cross-compile target (embedded Linux, headless — not a Flutter UI platform) — tracked in `sdd-asterisk-chan-simbox` |

Linux/Windows/macOS telephony is modem-based (direct AT-command
communication with USB GSM/UMTS dongles over `/dev/ttyUSBx` or
platform-equivalent serial ports, chan_svistok-derived logic re-hosted
without Asterisk), architecturally distinct from Android's native
telecom path — see `flows/sdd-flutter_gsmsip-interface/` and
`flows/sdd-flutter_gsm/` for the full design rationale.

## 📱 Features

- **Modem Discovery & State** — cross-platform `ModemDevice`/`ModemRepository` abstraction, push-style `ModemEvent` stream
- **Calls & SMS** — dial/answer/hangup/hold/mute/speaker, SMS send (Android via `flutter_smsussd`)
- **AT-Command / Diagnostics** — raw AT command passthrough, diag mode (real on Linux via `libsimbox`; Windows/macOS pending)
- **Firmware / Recovery** — Huawei DIAG-mode firmware flashing and bricked-modem recovery (real on Linux via `libsimbox`; Windows/macOS pending)
- **Error Handling** — typed `ModemException` hierarchy, distinguishes "no device" from "driver not available yet"

SIP↔GSM call routing, SMPP SMS gateway, and voice-bridging logic live in
[`flutter_gsmsip`](../flutter_gsmsip/), which depends on this package.

## 📦 Installation

Add this to your Flutter project's `pubspec.yaml`:

```yaml
dependencies:
  flutter_gsm: ^0.1.0
```

Or use a local path for development:

```yaml
dependencies:
  flutter_gsm:
    path: ../flutter_gsm
```

Then run:

```bash
flutter pub get
```

### Android Configuration

Ensure your `AndroidManifest.xml` includes the required permissions:

```xml
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.CALL_PHONE"/>
<uses-permission android:name="android.permission.SEND_SMS"/>
<uses-permission android:name="android.permission.RECEIVE_SMS"/>
<uses-permission android:name="android.permission.READ_PHONE_STATE"/>
<uses-permission android:name="android.permission.FOREGROUND_SERVICE"/>
<uses-permission android:name="android.permission.RECORD_AUDIO"/>
```

## 🚀 Quick Start

### 1. Discover modems and listen for events

```dart
import 'package:flutter_gsm/flutter_gsm.dart';

final ModemRepository modems = ModemRepositoryImpl();

final devices = await modems.listModems();
for (final device in devices) {
  print('${device.id}: ${device.portPath ?? device.displayName} — ${device.state}');
}

modems.modemEvents.listen((event) {
  switch (event) {
    case ModemAttached(:final device):
      print('Modem attached: ${device.id}');
    case ModemDetached(:final modemId):
      print('Modem detached: $modemId');
    case ModemCallStateChanged(:final call):
      print('Call ${call.id}: ${call.state}');
    case ModemSmsReceived(:final from, :final text):
      print('SMS from $from: $text');
    default:
      break;
  }
});
```

### 2. Dial, answer, hang up

```dart
final call = await modems.dial(device.id, '+1234567890');
await modems.answerCall(call.id);
// ...
await modems.hangupCall(call.id);
```

### 3. SMS / USSD (desktop — see Platform Support)

```dart
await modems.sendSms(device.id, '+1234567890', 'Hello from flutter_gsm');
final response = await modems.sendUssd(device.id, '*100#');
```

### 4. Handle "driver not available yet" vs. "no device"

```dart
try {
  final devices = await modems.listModems();
  if (devices.isEmpty) {
    print('No modems attached.');
  }
} on ModemDriverNotAvailableException {
  print('Modem driver not available on this platform yet.');
}
```

## 📚 API Reference

### `ModemRepository` (main entry point)

| Method | Description |
|---|---|
| `listModems()` / `getModem(id)` | Discovery & lookup |
| `modemEvents` | `Stream<ModemEvent>` — attach/detach, state/signal/registration changes, call state, SMS/USSD, errors |
| `sendAtCommand(modemId, command)` | Raw AT command passthrough (desktop) |
| `setPower(modemId, on:)` / `restartModem(modemId, mode:)` | Power / lifecycle |
| `changeImei(modemId, imei)` / `setNetworkMode(modemId, mode)` / `setGroup(modemId, groupId)` | Identity / network |
| `dial(modemId, number)` / `hangupCall(callId)` / `answerCall(callId)` | Calling |
| `sendSms(modemId, number, text)` / `sendUssd(modemId, code)` | SMS / USSD |
| `setDiagMode(modemId, enabled)` | Diagnostics (desktop, firmware-adjacent) |

See platform support above for which methods are real vs. `UnsupportedError`/`UnimplementedError` per platform.

### Key entities

`ModemDevice`, `ModemCall`, `ModemEvent` (sealed: `ModemAttached`, `ModemDetached`, `ModemStateChanged`, `ModemSignalChanged`, `ModemRegistrationChanged`, `ModemCallStateChanged`, `ModemSmsReceived`, `ModemUssdReceived`, `ModemErrorOccurred`), `CarrierProfile` + `CarrierProfileRegistry`, `ModemGroupConfig`, `AtCommandResult`, `ModemState`, `NetworkMode`, `RestartMode`, `RegistrationState`.

### Error handling

Typed exceptions (`implements Exception`), not `Either`/`Failure`:

- `ModemDriverNotAvailableException` — platform implementation exists but has no real driver yet (distinct from an empty device list)
- `ModemNotFoundException` — no modem with the given id
- `ModemNotDefaultDialerException` (Android) — app isn't the default dialer yet, needed before call control works

---

## 🏗️ Architecture

### Library Structure

```
flutter_gsm/
├── lib/
│   ├── flutter_gsm.dart                  # Main export
│   ├── flutter_gsm_platform_interface.dart
│   ├── flutter_gsm_method_channel.dart   # Android (method-channel fallback)
│   └── src/
│       ├── domain/
│       │   ├── entities/                 # ModemDevice, ModemCall, CarrierProfile, ModemGroupConfig
│       │   ├── models/                   # ModemEvent, ModemState, AtCommandResult, ...
│       │   ├── repositories/             # ModemRepository (interface)
│       │   └── exceptions/               # ModemException hierarchy
│       ├── data/repositories/            # ModemRepositoryImpl
│       ├── android/                      # AndroidFlutterGsm (flutter_dialer/flutter_tele backed)
│       ├── ffi/                          # ffigen SimboxBindings, DynamicLibrary loader
│       └── linux/                        # LinuxFlutterGsm + SimboxModemRepository (libsimbox via dart:ffi)
├── android/                              # Native Kotlin plugin code
│   └── src/main/kotlin/org/telon/flutter_gsm/
└── pubspec.yaml
```

SIP↔GSM call routing, SMPP SMS gateway, and voice-bridging orchestration
live in [`flutter_gsmsip`](../flutter_gsmsip/), which depends on this
package for its GSM leg and on
[`flutter_nmsip`](../flutter_nmsip/) for its SIP leg.

---

## 🔌 Native Library Loading (Linux)

`LinuxFlutterGsm` binds to `libsimbox` (built by `libsCpp/asterisk_chan_simbox`)
via `dart:ffi`. This is a pragmatic dev-mode loading strategy, **not** a
packaged/redistributable one yet — a real `linux/CMakeLists.txt`
build-and-bundle step is a flagged follow-up (`flutter_gsm`'s `linux:`
pubspec entry is currently pure-Dart, `dartPluginClass`-registered, with
no native CMake scaffold). Resolution order:

1. `FLUTTER_GSM_SIMBOX_LIB` environment variable, if set — tried
   directly with no fallback (an explicit override that fails to load
   surfaces loudly, not silently).
2. `libsimbox.so` / `libsimbox.dylib` (system-installed names).
3. `../../libsCpp/asterisk_chan_simbox/libsimbox.so` /
   `.dylib` (monorepo-relative dev path — works when running from
   within this workspace, not reliable across arbitrary build outputs).

If none load, `SimboxModemRepository`/`LinuxFlutterGsm` throw
`ModemDriverNotAvailableException` at first use (not at plugin
registration), matching this package's existing "driver not available"
convention elsewhere — so a dev machine without `libsimbox` built still
starts up normally, it just can't list/control modems.

---

## 📖 Example App

The `example/` directory contains a working app demonstrating modem
discovery, event streaming, and call control against `ModemRepository`.

To run the example:

```bash
cd example
flutter pub get
flutter run
```

---

## 📋 Requirements

- **Flutter**: >=3.3.0
- **Dart**: ^3.10.8
- **Android**: API level 21+ (Android 5.0)
- **Kotlin**: 1.7.0+

## 🐛 Known Issues

See the [GitHub Issues](https://github.com/telon/flutter_gsm/issues) for known issues and roadmap.

### Current Limitations

- **Windows/macOS driver pending**: only Linux is bound to `libsimbox` via `dart:ffi` so far — see [`sdd-flutter_gsm-ffi`](flows/sdd-flutter_gsm-ffi/). Windows/macOS stay stubbed.
- **Linux `setNetworkMode`**: only `NetworkMode.gsmOnly` (`AT^SYSCFG=13,...`) is confirmed from chan_svistok's own reference source — `auto`/`wcdmaOnly` throw `UnsupportedError` rather than guessing an `AT^SYSCFG` code that could lock a real modem to an unreachable network. Confirm the real codes against attached hardware/vendor AT reference to wire them up.
- **Linux `setDiagMode(enabled: false)`**: no "exit DIAG mode" function exists in `libsimbox` — throws `UnsupportedError`, matching this package's existing "no equivalent exists" convention.
- **Linux `changeImei`**: genuinely blocked upstream, not an adapter gap — chan_svistok's real IMEI-change path (`ttyprog_changeimei`) is called in three places across its source but defined nowhere in the checked-in tree. Surfaces as a `ModemException` explaining the gap rather than a fabricated success.
- **Linux native library loading is dev-mode only**: see [Native Library Loading](#native-library-loading-linux) above — no packaged/bundled distribution yet.
- **Android AT-command/firmware surface**: correctly unsupported — no Android equivalent exists (use the modem-hardware path via desktop platforms for those operations).
- **iOS**: not implemented.

---

## 📄 License

This project is licensed under the **NativeMindNONC License** — see the [LICENSE](LICENSE) file for details.

**Key Terms:**
- ✅ **Free for non-commercial use** (education, research, personal learning)
- ⚠️ **Commercial use requires written permission** from the copyright holder
- 🔄 **ShareAlike**: Derivative works must be published as GitHub Forks under the same license
- 📝 **Attribution required**: Credit the original authors with link to repository

---

**Package**: `flutter_gsm`  
**Version**: 0.1.0  
**License**: NativeMindNONC  
**Homepage**: <https://github.com/telon/flutter_gsm>  
**Issues**: <https://github.com/telon/flutter_gsm/issues>
