part of 'api.dart';

class AuthApi {
  /// Attempts to login with Xtream Codes API
  /// 
  /// This method handles URL formatting, protocol detection, and error handling
  /// to ensure maximum compatibility with different IPTV providers
  Future<UserModel?> registerUser(
    String username,
    String password,
    String link,
    String name,
    String playlistName,
    {String? playlistPin,}
  ) async {
    try {
      // Normalize the URL to ensure proper formatting
      String baseUrl = link.trim();
      
      // Ensure URL has a protocol
      if (!baseUrl.startsWith('http://') && !baseUrl.startsWith('https://')) {
        baseUrl = 'http://$baseUrl'; // Default to HTTP if no protocol specified
      }
      
      // Remove trailing slash if present
      if (baseUrl.endsWith('/')) {
        baseUrl = baseUrl.substring(0, baseUrl.length - 1);
      }
      
      // Try with the current protocol first
      Response<String>? response;
      String? errorMessage;
      
      try {
        // Construct the API URL
        final apiUrl = "$baseUrl/player_api.php?username=$username&password=$password";
        debugPrint("Attempting login with URL: $apiUrl");
        
        // Make the request with additional headers
        response = await _dio.get(
          apiUrl,
          options: Options(
            headers: {
              'User-Agent': 'IPTV Player/1.0',
              'Accept': '*/*',
            },
          ),
        );
      } catch (firstAttemptError) {
        // If first attempt fails and we used HTTP, try HTTPS
        errorMessage = firstAttemptError.toString();
        debugPrint("First attempt failed: $errorMessage");
        
        if (baseUrl.startsWith('http://')) {
          try {
            // Switch to HTTPS and try again
            String httpsUrl = 'https://' + baseUrl.substring(7);
            final apiUrl = "$httpsUrl/player_api.php?username=$username&password=$password";
            debugPrint("Retrying with HTTPS: $apiUrl");
            
            response = await _dio.get(
              apiUrl,
              options: Options(
                headers: {
                  'User-Agent': 'IPTV Player/1.0',
                  'Accept': '*/*',
                },
              ),
            );
            
            // If successful, update the baseUrl to use HTTPS
            baseUrl = httpsUrl;
          } catch (secondAttemptError) {
            // Both attempts failed
            throw Exception("Failed to connect with both HTTP and HTTPS: $errorMessage, then: $secondAttemptError");
          }
        } else {
          // If we already tried with HTTPS, just rethrow the original error
          throw firstAttemptError;
        }
      }
      
      // At this point, response should never be null due to our try-catch structure
      debugPrint("Response status: ${response.statusCode}");
      debugPrint("Response headers: ${response.headers}");
      
      // Check for successful response
      if (response.statusCode == 200) {
        // Check if response data is not empty
        if (response.data == null || response.data!.isEmpty) {
          debugPrint("Error: Empty response data");
          return null;
        }
        
        try {
          var json = jsonDecode(response.data!);
          
          // Check if the response contains an error message
          if (json is Map && json.containsKey('user_info') == false) {
            debugPrint("API Error: ${json['message'] ?? 'Unknown error'}");
            return null;
          }
          
          // Add playlist name and pin to the json data
          if (json['user_info'] != null) {
            if (playlistName.isNotEmpty) {
              json['user_info']['playlist_name'] = playlistName;
            }
            if (playlistPin != null && playlistPin.isNotEmpty) {
              json['user_info']['playlist_pin'] = playlistPin;
            }
          }
          
          final user = UserModel.fromJson(json, baseUrl);
          //save to locale
          await LocaleApi.saveUser(user);
          return user;
        } catch (parseError) {
          debugPrint("JSON Parse Error: $parseError");
          debugPrint("Response data: ${response.data}");
          return null;
        }
      } else {
        debugPrint("HTTP Error: ${response.statusCode} - ${response.statusMessage}");
        return null;
      }
    } catch (e) {
      debugPrint("Network Error: $e");
      return null;
    }
  }
}
