import 'dart:ffi';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_gsm/src/ffi/simbox_native_library.dart';
import 'package:flutter_gsm/src/domain/exceptions/modem_exceptions.dart';

void main() {
  // A real, always-openable DynamicLibrary (the current process's own
  // symbols) — used as a stand-in "successfully opened" result so these
  // tests don't need a real libsimbox on disk.
  final fakeOpened = DynamicLibrary.process();

  test('env var override is tried directly, no fallback', () {
    final calls = <String>[];
    final result = resolveSimboxLibrary(
      envValue: '/custom/path/libsimbox.so',
      open: (path) {
        calls.add(path);
        return fakeOpened;
      },
    );

    expect(result, same(fakeOpened));
    expect(calls, ['/custom/path/libsimbox.so']);
  });

  test('env var override failing does not fall through to candidates', () {
    final calls = <String>[];
    expect(
      () => resolveSimboxLibrary(
        envValue: '/bad/path.so',
        open: (path) {
          calls.add(path);
          throw ArgumentError('not found: $path');
        },
      ),
      throwsArgumentError,
    );
    expect(calls, ['/bad/path.so']);
  });

  test('no env var: tries candidates in order, stops at first success', () {
    final calls = <String>[];
    final result = resolveSimboxLibrary(
      envValue: null,
      open: (path) {
        calls.add(path);
        if (path == simboxLibCandidates[2]) return fakeOpened;
        throw ArgumentError('not found: $path');
      },
    );

    expect(result, same(fakeOpened));
    expect(calls, simboxLibCandidates.sublist(0, 3));
  });

  test('no env var: all candidates fail throws ModemDriverNotAvailableException', () {
    final calls = <String>[];
    expect(
      () => resolveSimboxLibrary(
        envValue: null,
        open: (path) {
          calls.add(path);
          throw ArgumentError('not found: $path');
        },
      ),
      throwsA(isA<ModemDriverNotAvailableException>()),
    );
    expect(calls, simboxLibCandidates);
  });
}
