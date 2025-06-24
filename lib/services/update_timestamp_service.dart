import 'package:shared_preferences/shared_preferences.dart';

/// Service to manage last update timestamps for content types
class UpdateTimestampService {
  static const String _keyLiveUpdate = 'last_live_update';
  static const String _keyMoviesUpdate = 'last_movies_update';
  static const String _keySeriesUpdate = 'last_series_update';

  /// Save the last update timestamp for Live content
  static Future<void> saveLiveUpdateTime(DateTime time) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyLiveUpdate, time.millisecondsSinceEpoch);
  }

  /// Save the last update timestamp for Movies content
  static Future<void> saveMoviesUpdateTime(DateTime time) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyMoviesUpdate, time.millisecondsSinceEpoch);
  }

  /// Save the last update timestamp for Series content
  static Future<void> saveSeriesUpdateTime(DateTime time) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keySeriesUpdate, time.millisecondsSinceEpoch);
  }

  /// Get the last update timestamp for Live content
  static Future<DateTime?> getLiveUpdateTime() async {
    final prefs = await SharedPreferences.getInstance();
    final timestamp = prefs.getInt(_keyLiveUpdate);
    return timestamp != null ? DateTime.fromMillisecondsSinceEpoch(timestamp) : null;
  }

  /// Get the last update timestamp for Movies content
  static Future<DateTime?> getMoviesUpdateTime() async {
    final prefs = await SharedPreferences.getInstance();
    final timestamp = prefs.getInt(_keyMoviesUpdate);
    return timestamp != null ? DateTime.fromMillisecondsSinceEpoch(timestamp) : null;
  }

  /// Get the last update timestamp for Series content
  static Future<DateTime?> getSeriesUpdateTime() async {
    final prefs = await SharedPreferences.getInstance();
    final timestamp = prefs.getInt(_keySeriesUpdate);
    return timestamp != null ? DateTime.fromMillisecondsSinceEpoch(timestamp) : null;
  }
}
