// test/core/camera_service_lifecycle_test.dart
//
// Unit tests for the CameraService lifecycle fix.
//
// These tests verify that releaseController() does NOT permanently destroy the
// ChangeNotifier, that initialize() can safely be called again after release,
// and that the final dispose() correctly prevents further use.
//
// The camera plugin itself is not exercised (requires a device). Camera
// hardware behaviour is covered by the physical-device verification.

import 'package:flutter_test/flutter_test.dart';
import 'package:yadd/core/services/camera_service.dart';

void main() {
  group('CameraService — ChangeNotifier lifecycle', () {
    late CameraService service;

    setUp(() {
      service = CameraService();
    });

    tearDown(() {
      try {
        service.dispose();
      } catch (_) {}
    });

    // -------------------------------------------------------------------------
    // Initial state
    // -------------------------------------------------------------------------
    test('starts with sensible defaults', () {
      expect(service.isInitialized, isFalse);
      expect(service.isInitializing, isFalse);
      expect(service.isCapturing, isFalse);
      expect(service.hasMultipleCameras, isFalse);
      expect(service.errorMessage, isNull);
      expect(service.controller, isNull);
    });

    // -------------------------------------------------------------------------
    // releaseController() must NOT call super.dispose()
    // -------------------------------------------------------------------------
    test('releaseController() leaves the ChangeNotifier alive', () async {
      await service.releaseController();

      bool listenerCalled = false;
      service.addListener(() => listenerCalled = true);

      // A second releaseController() must notify without throwing.
      await service.releaseController();
      expect(listenerCalled, isTrue,
          reason:
              'releaseController() should call notifyListeners() without '
              'throwing "used after being disposed"');
    });

    test('releaseController() resets in-progress flags', () async {
      await service.releaseController();
      expect(service.isInitializing, isFalse);
      expect(service.isCapturing, isFalse);
      expect(service.controller, isNull);
    });

    // -------------------------------------------------------------------------
    // initialize() after releaseController() — core regression guard
    // -------------------------------------------------------------------------
    test(
        'initialize() after releaseController() does not throw '
        '"CameraService was used after being disposed"', () async {
      await service.releaseController();

      // initialize() will fail with a camera plugin error in the test
      // environment (no real device), but must NOT throw an AssertionError
      // about ChangeNotifier disposal.
      try {
        await service.initialize();
      } on AssertionError catch (e) {
        fail(
            'initialize() after releaseController() threw AssertionError '
            '(ChangeNotifier disposed): $e');
      } catch (_) {
        // Camera plugin / MissingPluginException in test env — acceptable.
      }
    });

    test(
        'initialize → releaseController → initialize lifecycle '
        'does not throw ChangeNotifier disposed assertion', () async {
      try {
        await service.initialize();
      } catch (_) {}

      await service.releaseController();

      // Second initialize — this is where the original device crash occurred.
      try {
        await service.initialize();
      } on AssertionError catch (e) {
        fail('Second initialize() threw AssertionError: $e');
      } catch (_) {}
    });

    // -------------------------------------------------------------------------
    // Final dispose() permanently prevents further use
    // -------------------------------------------------------------------------
    test('releaseController() after dispose() is silently ignored', () async {
      service.dispose();
      // Must not throw.
      await expectLater(service.releaseController(), completes);
    });

    test('initialize() after dispose() is silently ignored', () async {
      service.dispose();
      try {
        await service.initialize();
      } on AssertionError catch (e) {
        fail('initialize() after dispose() threw AssertionError: $e');
      } catch (_) {}
    });

    // -------------------------------------------------------------------------
    // Idempotency
    // -------------------------------------------------------------------------
    test('calling releaseController() multiple times is safe', () async {
      await service.releaseController();
      await service.releaseController();
      await service.releaseController();

      expect(service.controller, isNull);
      expect(service.isInitializing, isFalse);
    });

    // -------------------------------------------------------------------------
    // Listener notification
    // -------------------------------------------------------------------------
    test('listeners are notified by releaseController()', () async {
      int notifyCount = 0;
      service.addListener(() => notifyCount++);

      await service.releaseController();

      expect(notifyCount, greaterThan(0),
          reason: 'releaseController() must call notifyListeners()');
    });
  });
}
