import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/app_constants.dart';

class OnboardingRepository {
  final SharedPreferences _prefs;

  OnboardingRepository(this._prefs);

  bool isCompleted() {
    return _prefs.getBool(AppConstants.keyOnboardingCompleted) ?? false;
  }

  Future<void> setCompleted() async {
    await _prefs.setBool(AppConstants.keyOnboardingCompleted, true);
  }

  Future<void> resetOnboarding() async {
    await _prefs.remove(AppConstants.keyOnboardingCompleted);
  }
}
