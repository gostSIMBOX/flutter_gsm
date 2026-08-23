import 'dart:ffi';
import 'dart:io';

import '../domain/exceptions/modem_exceptions.dart';
import 'simbox_bindings.dart';

/// Env var name checked before any candidate path — see [resolveSimboxLibraryPath].
const simboxLibEnvVar = 'FLUTTER_GSM_SIMBOX_LIB';

/// Env var name for chan_dongle's config-file directory override — see
/// `SimboxModemRepository`'s factory (`configDir` param) and
/// `simbox_config_bridge_set_dir()` (native side,
/// `libsCpp/asterisk_chan_simbox/adapters/src/shim_config.c`). Unlike
/// [simboxLibEnvVar] (which picks which `.so`/`.dylib` to load), this
/// tells chan_dongle's real, unmodified config loader where to find
/// `dongle.conf` — unrelated concerns, read independently.
const simboxConfigDirEnvVar = 'FLUTTER_GSM_SIMBOX_CONFIG_DIR';

/// Candidate library paths tried, in order, when [simboxLibEnvVar] isn't
/// set. System-installed names first, then a monorepo-relative dev path
/// (works when running from within this workspace via `flutter run`/
/// `flutter test`, not reliable across arbitrary build outputs).
const simboxLibCandidates = [
  'libsimbox.so',
  'libsimbox.dylib',
  '../../libsCpp/asterisk_chan_simbox/libsimbox.so',
  '../../libsCpp/asterisk_chan_simbox/libsimbox.dylib',
];

/// Loads `libsimbox` and returns bound [SimboxBindings].
///
/// Path-resolution strategy (see
/// flows/sdd-flutter_gsm-ffi/02-specifications.md "Native Library
/// Loading"): this is a pragmatic dev-mode strategy, not a packaged/
/// redistributable one — a real `linux/CMakeLists.txt` build-and-bundle
/// step is a flagged follow-up, not implemented here.
///
/// Throws [ModemDriverNotAvailableException] if none of the candidates
/// load — callers should catch this the same way they already handle
/// `UnimplementedError` on unimplemented platforms (see
/// `ModemRepositoryImpl._guard`), so library-not-found and
/// platform-not-implemented present one consistent failure mode.
SimboxBindings loadSimboxBindings() {
  return loadSimboxBindingsWithPath().bindings;
}

/// Like [loadSimboxBindings], but also returns the winning path string.
///
/// `SimboxModemRepository` needs this in addition to the bound
/// [SimboxBindings]: its `Isolate.run`-based threading (see
/// specifications' "Threading") spawns a fresh isolate per blocking
/// native call, and a `DynamicLibrary`/`SimboxBindings` opened on this
/// isolate cannot be captured by a closure sent to another one — Dart
/// rejects it at runtime ("Illegal argument in isolate message: (object
/// is a DynamicLibrary)"), confirming empirically what specifications
/// flagged as needing verification. The fix is to re-open the library
/// fresh inside each spawned isolate from its path (a plain sendable
/// `String`) rather than reusing the already-open instance.
({SimboxBindings bindings, String path}) loadSimboxBindingsWithPath() {
  final envValue = Platform.environment[simboxLibEnvVar];
  final path = resolveSimboxLibraryPath(envValue: envValue);
  return (bindings: SimboxBindings(DynamicLibrary.open(path)), path: path);
}

/// Resolves the winning candidate path without opening bound
/// [SimboxBindings] — same env-var/candidate-list strategy as
/// [resolveSimboxLibrary], but returns the path string so it can be
/// reopened independently later (see [loadSimboxBindingsWithPath]).
String resolveSimboxLibraryPath({required String? envValue}) {
  if (envValue != null) {
    DynamicLibrary.open(envValue); // fail fast on a bad explicit override
    return envValue;
  }

  for (final path in simboxLibCandidates) {
    try {
      DynamicLibrary.open(path);
      return path;
    } on ArgumentError {
      continue;
    }
  }

  throw const ModemDriverNotAvailableException();
}

/// Pure resolution logic, separated from [Platform.environment]/
/// [DynamicLibrary.open] so it's unit-testable without a real
/// `libsimbox` or real environment variables — see
/// `test/simbox_native_library_test.dart`.
///
/// If [envValue] is non-null, it is tried directly with no fallback (an
/// explicit override that fails should surface loudly, not silently
/// fall through to a different library). Otherwise tries
/// [simboxLibCandidates] in order, returning the first that opens.
DynamicLibrary resolveSimboxLibrary({
  required String? envValue,
  required DynamicLibrary Function(String path) open,
}) {
  if (envValue != null) {
    return open(envValue);
  }

  for (final path in simboxLibCandidates) {
    try {
      return open(path);
    } on ArgumentError {
      continue;
    }
  }

  throw const ModemDriverNotAvailableException();
}
