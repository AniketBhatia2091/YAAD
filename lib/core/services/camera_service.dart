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

  List<cam.CameraDescription> get cameras => _availableCameras;
  cam.CameraController? get controller => _controller;
  bool get isInitialized => _controller != null && _controller!.value.isInitialized;
  bool get isInitializing => _isInitializing;
  bool get isCapturing => _isCapturing;
  cam.FlashMode get currentFlashMode => _currentFlashMode;
  String? get errorMessage => _errorMessage;
  bool get hasMultipleCameras => _availableCameras.length > 1;

  /// Initializes available cameras on device and selects rear camera by default.
  Future<void> initialize() async {
    if (_isInitializing) return;
    _isInitializing = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _availableCameras = await cam.availableCameras();
      if (_availableCameras.isEmpty) {
        _errorMessage = 'Camera isn\'t available on this device.';
        _isInitializing = false;
        notifyListeners();
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
      notifyListeners();
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
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to set flash mode: $e');
    }
  }

  /// Switches camera lens direction (e.g., Rear <-> Front)
  Future<void> switchCamera() async {
    if (!hasMultipleCameras || _isInitializing) return;

    _selectedCameraIndex = (_selectedCameraIndex + 1) % _availableCameras.length;
    _isInitializing = true;
    notifyListeners();

    try {
      await _initController(_availableCameras[_selectedCameraIndex]);
    } catch (e) {
      _errorMessage = 'Failed to switch camera.';
    } finally {
      _isInitializing = false;
      notifyListeners();
    }
  }

  /// Captures a photo using the active camera controller.
  Future<cam.XFile?> capturePhoto() async {
    if (!isInitialized || _isCapturing) return null;

    _isCapturing = true;
    notifyListeners();

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
      notifyListeners();
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

  @override
  void dispose() {
    _controller?.dispose();
    _controller = null;
    super.dispose();
  }
}
