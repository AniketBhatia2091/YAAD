import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Platform Security & Hardening Configuration Tests', () {
    test('Android Manifest disables backup and does not request INTERNET permission', () async {
      final manifestFile = File('android/app/src/main/AndroidManifest.xml');
      expect(manifestFile.existsSync(), isTrue);

      final content = await manifestFile.readAsString();

      // android:allowBackup="false" must be explicitly set
      expect(
        content.contains('android:allowBackup="false"'),
        isTrue,
        reason: 'AndroidManifest.xml must set android:allowBackup="false"',
      );

      // android.permission.INTERNET must NOT be requested
      expect(
        content.contains('android.permission.INTERNET'),
        isFalse,
        reason: 'AndroidManifest.xml must not declare android.permission.INTERNET for an offline app',
      );

      // Camera permission must be present
      expect(
        content.contains('android.permission.CAMERA'),
        isTrue,
        reason: 'AndroidManifest.xml must declare android.permission.CAMERA',
      );
    });

    test('macOS Release entitlements include sandbox and camera access', () async {
      final releaseEntitlements = File('macos/Runner/Release.entitlements');
      expect(releaseEntitlements.existsSync(), isTrue);

      final content = await releaseEntitlements.readAsString();

      expect(
        content.contains('com.apple.security.app-sandbox'),
        isTrue,
        reason: 'macOS Release.entitlements must have com.apple.security.app-sandbox',
      );

      expect(
        content.contains('com.apple.security.device.camera'),
        isTrue,
        reason: 'macOS Release.entitlements must have com.apple.security.device.camera',
      );
    });

    test('macOS Info.plist contains camera usage description', () async {
      final plistFile = File('macos/Runner/Info.plist');
      expect(plistFile.existsSync(), isTrue);

      final content = await plistFile.readAsString();

      expect(
        content.contains('NSCameraUsageDescription'),
        isTrue,
        reason: 'macos/Runner/Info.plist must provide NSCameraUsageDescription',
      );
    });

    test('iOS Info.plist contains camera and photo library usage descriptions', () async {
      final plistFile = File('ios/Runner/Info.plist');
      expect(plistFile.existsSync(), isTrue);

      final content = await plistFile.readAsString();

      expect(
        content.contains('NSCameraUsageDescription'),
        isTrue,
        reason: 'ios/Runner/Info.plist must provide NSCameraUsageDescription',
      );

      expect(
        content.contains('NSPhotoLibraryUsageDescription'),
        isTrue,
        reason: 'ios/Runner/Info.plist must provide NSPhotoLibraryUsageDescription',
      );
    });

    test('Root .gitignore protects sensitive databases, keystores, and credentials', () async {
      final gitignoreFile = File('.gitignore');
      expect(gitignoreFile.existsSync(), isTrue);

      final content = await gitignoreFile.readAsString();

      expect(content.contains('.env'), isTrue);
      expect(content.contains('*.sqlite'), isTrue);
      expect(content.contains('*.db'), isTrue);
      expect(content.contains('*.jks'), isTrue);
      expect(content.contains('*.keystore'), isTrue);
    });
  });
}
