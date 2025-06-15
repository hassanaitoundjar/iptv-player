part of '../api/api.dart';

class LocaleApi {
  static Future<bool> saveUser(UserModel user) async {
    try {
      // Save current user
      await locale.write("user", user.toJson());
      
      // Save to users list for easy login
      Map<String, dynamic> usersList = await locale.read("users_list") ?? {};
      String userId = user.userInfo?.username ?? DateTime.now().millisecondsSinceEpoch.toString();
      
      // Create a simplified user object with just the necessary login info
      Map<String, dynamic> savedUser = {
        'username': user.userInfo?.username,
        'password': user.userInfo?.password,
        'server_url': user.serverInfo?.serverUrl,
        'playlist_name': user.userInfo?.playlistName ?? user.userInfo?.username,
        'playlist_pin': user.userInfo?.playlistPin,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };
      
      usersList[userId] = savedUser;
      await locale.write("users_list", usersList);
      
      return true;
    } catch (e) {
      debugPrint("Error save User: $e");
      return false;
    }
  }

  static Future<UserModel?> getUser() async {
    try {
      final user = await locale.read("user");

      if (user != null) {
        return UserModel.fromJson(user, user['server_info']['server_url']);
      }
      return null;
    } catch (e) {
      debugPrint("Error save User: $e");
      return null;
    }
  }

  static Future<bool> logOut() async {
    try {
      await locale.remove("user");

      return true;
    } catch (e) {
      debugPrint("Error LogOut User: $e");
      return false;
    }
  }
  
  static Future<Map<String, dynamic>> getSavedUsers() async {
    try {
      final usersList = await locale.read("users_list") ?? {};
      return usersList;
    } catch (e) {
      debugPrint("Error getting saved users: $e");
      return {};
    }
  }
  
  static Future<bool> removeUserFromList(String userId) async {
    try {
      Map<String, dynamic> usersList = await locale.read("users_list") ?? {};
      usersList.remove(userId);
      await locale.write("users_list", usersList);
      return true;
    } catch (e) {
      debugPrint("Error removing user: $e");
      return false;
    }
  }
  
  static Future<bool> updatePlaylistPin(String pin, String playlistName) async {
    try {
      // Get current user
      final userData = await locale.read("user");
      if (userData == null) return false;
      
      // Create or get playlists map
      Map<String, dynamic> playlists = await locale.read("playlists") ?? {};
      
      // Update PIN for the specific playlist
      if (playlistName.isNotEmpty) {
        // If playlist doesn't exist in the map, create it
        if (!playlists.containsKey(playlistName)) {
          playlists[playlistName] = {};
        }
        
        // Set the PIN for this playlist
        playlists[playlistName]['pin'] = pin;
        await locale.write("playlists", playlists);
        
        // For backward compatibility, also update in user data
        if (userData['user_info'] != null && 
            userData['user_info']['playlist_name'] == playlistName) {
          userData['user_info']['playlist_pin'] = pin;
          await locale.write("user", userData);
          
          // Also update in users list for consistency
          String userId = userData['user_info']['username'] ?? '';
          if (userId.isNotEmpty) {
            Map<String, dynamic> usersList = await locale.read("users_list") ?? {};
            if (usersList.containsKey(userId)) {
              usersList[userId]['playlist_pin'] = pin;
              await locale.write("users_list", usersList);
            }
          }
        }
      }
      return true;
    } catch (e) {
      debugPrint("Error updating playlist PIN: $e");
      return false;
    }
  }
  
  // Get PIN for a specific playlist
  static Future<String> getPlaylistPin(String playlistName) async {
    try {
      Map<String, dynamic> playlists = await locale.read("playlists") ?? {};
      if (playlists.containsKey(playlistName) && playlists[playlistName]['pin'] != null) {
        return playlists[playlistName]['pin'];
      }
      
      // Fallback to user data for backward compatibility
      final userData = await locale.read("user");
      if (userData != null && userData['user_info'] != null && 
          userData['user_info']['playlist_name'] == playlistName && 
          userData['user_info']['playlist_pin'] != null) {
        return userData['user_info']['playlist_pin'];
      }
      
      return '';
    } catch (e) {
      debugPrint("Error getting playlist PIN: $e");
      return '';
    }
  }
  
  // Check if a playlist is PIN-protected
  static Future<bool> isPlaylistPinProtected(String playlistName) async {
    String pin = await getPlaylistPin(playlistName);
    return pin.isNotEmpty;
  }
  
  // Verify PIN for a playlist
  static Future<bool> verifyPlaylistPin(String playlistName, String enteredPin) async {
    String correctPin = await getPlaylistPin(playlistName);
    return correctPin == enteredPin;
  }
}
