import 'package:camera/camera.dart' as cam;
import 'package:flutter/foundation.dart';

/// CameraService manages physical device camera lifecycle, controller initialization,
/// flash modes, camera switching, and photo capture for YAAD "Point & Remember".
class CameraService extends ChangeNotifier {
  List<cam.CameraDescription> _availableCameras = [];
  cam.CameraController? _controller;
  int _selectedCameraIndex = 0;
  cam.FlashMode _currentFlashMode = cam.FlashMode.off;
  bool _isInitializing = false;
  bool _isCapturing = false;
  String? _errorMessage;

  /// Set to true only after [dispose] is called (i.e., Riverpod tears down the
  /// provider). Guards against notifyListeners() being called on a dead notifier.
  bool _isDisposed = false;

  List<cam.CameraDescription> get cameras => _availableCameras;
  cam.CameraController? get controller => _controller;
  bool get isInitialized => _controller != null && _controller!.value.isInitialized;
  bool get isInitializing => _isInitializing;
  bool get isCapturing => _isCapturing;
  cam.FlashMode get currentFlashMode => _currentFlashMode;
  String? get errorMessage => _errorMessage;
  bool get hasMultipleCameras => _availableCameras.length > 1;

  /// Initializes available cameras on device and selects rear camera by default.
  ///
  /// Safe to call after [releaseController] — re-opens the camera hardware and
  /// creates a fresh [CameraController] without affecting the ChangeNotifier
  /// lifecycle. Silently no-ops if [dispose] has already been called.
  Future<void> initialize() async {
    if (_isDisposed) return;
    if (_isInitializing) return;
    _isInitializing = true;
    _errorMessage = null;
    _safeNotify();

    try {
      _availableCameras = await cam.availableCameras();
      if (_availableCameras.isEmpty) {
        _errorMessage = 'Camera isn\'t available on this device.';
        _isInitializing = false;
        _safeNotify();
        return;
      }

      // Select rear camera by default if available
      int defaultIndex = _availableCameras.indexWhere(
        (c) => c.lensDirection == cam.CameraLensDirection.back,
      );
      _selectedCameraIndex = defaultIndex != -1 ? defaultIndex : 0;

      await _initController(_availableCameras[_selectedCameraIndex]);
    } on cam.CameraException catch (e) {
      _errorMessage = _mapCameraExceptionMessage(e);
    } catch (e) {
      _errorMessage = 'Camera initialization failed: ${e.toString()}';
    } finally {
      _isInitializing = false;
      _safeNotify();
    }
  }

  Future<void> _initController(cam.CameraDescription description) async {
    if (_controller != null) {
      await _controller!.dispose();
      _controller = null;
    }

    final newController = cam.CameraController(
      description,
      cam.ResolutionPreset.max,
      enableAudio: false,
      imageFormatGroup: cam.ImageFormatGroup.jpeg,
    );

    _controller = newController;
    await newController.initialize();

    // Default flash mode
    try {
      await newController.setFlashMode(_currentFlashMode);
    } catch (_) {
      // Ignore if device flash mode isn't supported
    }
  }

  /// Releases the underlying camera controller and hardware WITHOUT affecting
  /// the ChangeNotifier lifecycle.
  ///
  /// Call this when the camera screen is paused or the app is backgrounded.
  /// After this returns, [initialize] can safely re-open the camera without
  /// any "used after being disposed" errors.
  Future<void> releaseController() async {
    if (_isDisposed) return;
    if (_controller != null) {
      await _controller!.dispose();
      _controller = null;
    }
    _isInitializing = false;
    _isCapturing = false;
    _safeNotify();
  }

  /// Cycles through Flash Modes: off -> auto -> always/on -> off
  Future<void> toggleFlashMode() async {
    if (!isInitialized) return;

    cam.FlashMode nextMode;
    switch (_currentFlashMode) {
      case cam.FlashMode.off:
        nextMode = cam.FlashMode.auto;
        break;
      case cam.FlashMode.auto:
        nextMode = cam.FlashMode.always;
        break;
      case cam.FlashMode.always:
      case cam.FlashMode.torch:
        nextMode = cam.FlashMode.off;
        break;
    }

    try {
      await _controller!.setFlashMode(nextMode);
      _currentFlashMode = nextMode;
      _safeNotify();
    } catch (e) {
      debugPrint('Failed to set flash mode: $e');
    }
  }

  /// Switches camera lens direction (e.g., Rear <-> Front)
  Future<void> switchCamera() async {
    if (!hasMultipleCameras || _isInitializing) return;

    _selectedCameraIndex = (_selectedCameraIndex + 1) % _availableCameras.length;
    _isInitializing = true;
    _safeNotify();

    try {
      await _initController(_availableCameras[_selectedCameraIndex]);
    } catch (e) {
      _errorMessage = 'Failed to switch camera.';
    } finally {
      _isInitializing = false;
      _safeNotify();
    }
  }

  /// Captures a photo using the active camera controller.
  Future<cam.XFile?> capturePhoto() async {
    if (!isInitialized || _isCapturing) return null;

    _isCapturing = true;
    _safeNotify();

    try {
      final xFile = await _controller!.takePicture();
      return xFile;
    } on cam.CameraException catch (e) {
      _errorMessage = _mapCameraExceptionMessage(e);
      return null;
    } catch (e) {
      _errorMessage = 'We couldn\'t capture that. Try again.';
      return null;
    } finally {
      _isCapturing = false;
      _safeNotify();
    }
  }

  String _mapCameraExceptionMessage(cam.CameraException e) {
    switch (e.code) {
      case 'CameraAccessDenied':
      case 'CameraAccessDeniedWithoutPrompt':
      case 'CameraAccessRestricted':
        return 'Camera access is needed to remember something.';
      default:
        return 'Camera error (${e.code}): ${e.description ?? "Unknown error"}';
    }
  }

  /// Calls [notifyListeners] only when the notifier has not been finally disposed.
  void _safeNotify() {
    if (!_isDisposed) notifyListeners();
  }

  /// Final teardown called by Riverpod when the provider scope is destroyed.
  ///
  /// Releases camera hardware, marks the notifier as permanently disposed, then
  /// calls [super.dispose]. Do NOT call this for app-lifecycle pausing — use
  /// [releaseController] instead.
  @override
  void dispose() {
    _isDisposed = true;
    _controller?.dispose();
    _controller = null;
    super.dispose();
  }
}
