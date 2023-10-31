import 'package:shared_preferences/shared_preferences.dart';

class UserPreferences {
  static late SharedPreferences _preferences;
  static const _keyLocale = 'locale';
  static const _keyBrightness = 'brightness';
  static const _keyAppsMax = 'appsMax';
  static const _keyMemPref = 'memPref';
  static const _keyCleanPref = 'cleanPref';
  static const _keyNoisePref = 'noisePref';
  static const _keyNightPref = 'nightPref';
  static const _keyYearPref = 'yearPref';
  static const _keyUni = 'Uni';
  static const _keyForeName = 'foreName';
  static const _keyFirstTime = 'firstTime';

  static Future<SharedPreferences?> init() async => _preferences = await SharedPreferences.getInstance();

  static Future setFirstTime(bool brightness) async =>
      await _preferences.setBool(_keyBrightness, brightness);

  static bool? getFirstTime() => _preferences.getBool(_keyBrightness) ?? true;

  static Future setAppsMax(int AppsMax)  async =>
      await _preferences.setInt(_keyAppsMax, AppsMax);

  static int getAppsMax() => _preferences.getInt(_keyAppsMax) ?? 2;

  static Future setLocale(String locale)  async =>
      await _preferences.setString(_keyLocale, locale);

  static String getLocale() => _preferences.getString(_keyLocale) ?? "en";

  static Future setUni(String uni)  async =>
      await _preferences.setString(_keyUni, uni);

  static String getUni() => _preferences.getString(_keyUni) ?? "NotLoggedInError";

  static Future setForeName(String foreName)  async =>
      await _preferences.setString(_keyForeName, foreName);

  static String getForeName() => _preferences.getString(_keyForeName) ?? "NotLoggedInError";

  static Future setBrightness(bool brightness) async =>
      await _preferences.setBool(_keyBrightness, brightness);

  static bool? getBrightness() => _preferences.getBool(_keyBrightness) ?? false;

  static Future setMemPref(int input)  async =>
      await _preferences.setInt(_keyMemPref, input);

  static int getMemPref() => _preferences.getInt(_keyMemPref) ?? 0;

  static Future setCleanPref(int input)  async =>
      await _preferences.setInt(_keyCleanPref, input);

  static int getCleanPref() => _preferences.getInt(_keyCleanPref) ?? 0;

  static Future setNoisePref(int input)  async =>
      await _preferences.setInt(_keyNoisePref, input);

  static int getNoisePref() => _preferences.getInt(_keyNoisePref) ?? 0;

  static Future setNightPref(int input)  async =>
      await _preferences.setInt(_keyNightPref, input);

  static int getNightPref() => _preferences.getInt(_keyNightPref) ?? 0;

  static Future setYearPref(int input)  async =>
      await _preferences.setInt(_keyYearPref, input);

  static int getYearPref() => _preferences.getInt(_keyYearPref) ?? 0;

}

