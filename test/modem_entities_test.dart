import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_gsm/flutter_gsm.dart';

void main() {
  group('ModemDevice', () {
    test('toJson/fromJson round-trip', () {
      const device = ModemDevice(
        id: '/dev/ttyUSB0',
        portPath: '/dev/ttyUSB0',
        displayName: 'Huawei E173',
        imei: '358920XXXXXXXXX',
        imsi: '250012345678901',
        groupId: 'g1',
        state: ModemState.registered,
        signal: 22,
        registration: RegistrationState.registered,
        balance: '84.20',
      );

      final restored = ModemDevice.fromJson(device.toJson());

      expect(restored, device);
    });

    test('copyWith overrides only given fields', () {
      const device = ModemDevice(id: 'a', state: ModemState.init);
      final updated = device.copyWith(state: ModemState.ready);

      expect(updated.id, 'a');
      expect(updated.state, ModemState.ready);
    });
  });

  group('ModemCall', () {
    test('durationSeconds is 0 before start', () {
      const call = ModemCall(
        id: 'c1',
        modemId: 'm1',
        number: '79123456789',
        direction: CallDirection.outgoing,
      );

      expect(call.durationSeconds, 0);
    });

    test('isActive reflects state', () {
      const call = ModemCall(
        id: 'c1',
        modemId: 'm1',
        number: '79123456789',
        direction: CallDirection.outgoing,
        state: CallState.active,
      );

      expect(call.isActive, isTrue);
    });
  });

  group('CarrierProfile', () {
    test('toJson/fromJson round-trip', () {
      const profile = CarrierProfile(
        operatorId: 'beeline_spb',
        displayName: 'Билайн СПб',
        regionCode: 'spb',
        balanceUssdTemplate: '*102#',
      );

      final restored = CarrierProfile.fromJson(profile.toJson());

      expect(restored, profile);
    });
  });

  group('CarrierProfileRegistry', () {
    test('register/unregister/lookup', () {
      final registry = CarrierProfileRegistry();
      const profile = CarrierProfile(
        operatorId: 'megafon_msk',
        displayName: 'МегаФон Москва',
        regionCode: 'msk',
      );

      registry.register(profile);
      expect(registry['megafon_msk'], profile);
      expect(registry.all, [profile]);

      registry.unregister('megafon_msk');
      expect(registry['megafon_msk'], isNull);
    });
  });

  group('ModemGroupConfig', () {
    test('toJson/fromJson round-trip', () {
      const config = ModemGroupConfig(
        groupId: 'g1',
        onlineMax: 4,
        limitMaxByPeriod: [10, 20, 30, 40],
        priority: 8,
        pacingAlgorithm: PacingAlgorithm.diffSlow,
        pacingDiffSlow: 5,
      );

      final restored = ModemGroupConfig.fromJson(config.toJson());

      expect(restored, config);
    });
  });

  group('AtCommandResult', () {
    test('toJson/fromJson round-trip', () {
      const result = AtCommandResult(
        raw: 'OK',
        ok: true,
        durationMs: 42,
      );

      final restored = AtCommandResult.fromJson(result.toJson());

      expect(restored, result);
    });
  });

  group('ModemEvent', () {
    test('ModemAttached carries device and props include it', () {
      const device = ModemDevice(id: 'm1');
      final event = ModemAttached(
        modemId: 'm1',
        timestamp: DateTime(2026, 8, 20),
        device: device,
      );

      expect(event.device, device);
      expect(event.props, contains(device));
    });

    test('sealed hierarchy is exhaustively switchable', () {
      final ModemEvent event = ModemDetached(
        modemId: 'm1',
        timestamp: DateTime(2026, 8, 20),
      );

      final description = switch (event) {
        ModemAttached() => 'attached',
        ModemDetached() => 'detached',
        ModemStateChanged() => 'state',
        ModemSignalChanged() => 'signal',
        ModemRegistrationChanged() => 'registration',
        ModemCallStateChanged() => 'call',
        ModemSmsReceived() => 'sms',
        ModemUssdReceived() => 'ussd',
        ModemErrorOccurred() => 'error',
      };

      expect(description, 'detached');
    });
  });
}
