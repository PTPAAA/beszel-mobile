import 'package:shared_preferences/shared_preferences.dart';

class PinService {
  static const String _pinKey = 'user_pin';

  Future<bool> isPinSet() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(_pinKey);
  }

  Future<void> setPin(String pin) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_pinKey, pin);
  }

  Future<bool> verifyPin(String pin) async {
    final prefs = await SharedPreferences.getInstance();
    final storedPin = prefs.getString(_pinKey);
    return storedPin == pin;
  }

  Future<void> removePin() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_pinKey);
  }
}
