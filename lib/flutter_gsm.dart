/// Flutter GSM Library
///
/// Cross-platform GSM/UMTS modem hardware abstraction: ttyUSB
/// AT-command modems (Linux/Windows/macOS) and native telephony
/// (Android). See flows/sdd-flutter_gsm for the split from flutter_gsmsip
/// (which now owns SIP<->GSM voice-gateway bridging on top of this
/// package).
///
/// Scoped to Modem-layer types only — this package used to also carry a
/// full leftover copy of flutter_gsmsip's SIP/Gateway/Dongle/Voice-line/
/// Analytics/Settings domain (an artifact of flutter_gsm having started
/// as a filesystem copy of flutter_gsmsip), removed as dead weight. See
/// flows/sdd-flutter_gsm/04-implementation-log.md for what was cut.
library flutter_gsm;

// Domain - Entities
export 'src/domain/entities/call_state.dart';
export 'src/domain/entities/carrier_profile.dart';
export 'src/domain/entities/modem_call.dart';
export 'src/domain/entities/modem_device.dart';
export 'src/domain/entities/modem_group_config.dart';

// Domain - Repositories (interfaces)
export 'src/domain/repositories/modem_repository.dart';

// Domain - Exceptions
export 'src/domain/exceptions/modem_exceptions.dart';

// Domain - Models
export 'src/domain/models/at_command_result.dart';
export 'src/domain/models/modem_event.dart';
export 'src/domain/models/modem_state.dart';
export 'src/domain/models/network_mode.dart';
export 'src/domain/models/restart_mode.dart';

// Data - Repositories (implementations)
export 'src/data/repositories/modem_repository_impl.dart';

// Platform implementations — must be exported from this library, not just
// present under src/, so Flutter's generated plugin registrant
// (.dart_tool/flutter_build/dart_plugin_registrant.dart, which calls
// `flutter_gsm.<PlatformClass>.registerWith()` through this package's
// public import) can resolve them. Their absence broke every native
// build (Android/Linux/macOS/Windows) with "Undefined name" errors —
// found while attempting a real `flutter build macos` manual-verification
// run for flows/simbox-app/vdd-simbox-app-navbar-uiux; unrelated to that
// flow's own scope, fixed here since it's a pure, low-risk export
// addition (no behavior change) blocking every UI flow's ability to
// actually run the app.
export 'src/android/android_flutter_gsm.dart';
export 'src/linux/linux_flutter_gsm.dart';
export 'src/macos/macos_flutter_gsm.dart';
export 'src/windows/windows_flutter_gsm.dart';
