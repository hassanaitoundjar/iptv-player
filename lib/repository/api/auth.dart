part of 'api.dart';

class AuthApi {
  Future<UserModel?> registerUser(
    String username,
    String password,
    String link,
    String name,
    String playlistName,
    {String? playlistPin,}
  ) async {
    try {
      debugPrint("$link/player_api.php?username=$username&password=$password");
      Response<String> response = await _dio
          .get("$link/player_api.php?username=$username&password=$password");

      if (response.statusCode == 200) {
        var json = jsonDecode(response.data ?? "");
        // Add playlist name and pin to the json data
        if (json['user_info'] != null) {
          if (playlistName.isNotEmpty) {
            json['user_info']['playlist_name'] = playlistName;
          }
          if (playlistPin != null && playlistPin.isNotEmpty) {
            json['user_info']['playlist_pin'] = playlistPin;
          }
        }
        final user = UserModel.fromJson(json, link);
        //save to locale
        await LocaleApi.saveUser(user);
        return user;
      } else {
        return null;
      }
    } catch (e) {
      debugPrint("Error: $e");
      return null;
    }
  }
}
