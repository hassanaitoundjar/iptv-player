import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

import '../../config/app_config.dart';
import '../../logic/blocs/auth/auth_bloc.dart';
import '../models/user.dart';
import 'expiration_service.dart';

class PlaylistService {
  final ExpirationService _expirationService = ExpirationService();
  
  /// Checks if a device is activated and retrieves its playlist information
  /// 
  /// Returns a Map with status and data or error information
  Future<Map<String, dynamic>> checkDeviceActivation(String macAddress, String deviceKey) async {
    try {
      debugPrint('Checking activation status for MAC: $macAddress, Key: $deviceKey');
      
      // Use the API endpoint format: /api/device/{mac}/{key}
      final url = '${AppConfig.apiBaseUrl}/api/device/$macAddress/$deviceKey';
      debugPrint('API URL: $url');

      final response = await http.get(Uri.parse(url));
      debugPrint('API Response Status: ${response.statusCode}');
      debugPrint('API Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'data': data,
        };
      } else {
        return {
          'success': false,
          'error': 'Server returned status code ${response.statusCode}',
        };
      }
    } catch (e) {
      debugPrint('Error checking device activation: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// Uploads a playlist to the device using the AuthBloc
  /// 
  /// Returns a Future<bool> indicating success or failure
  Future<bool> uploadPlaylist(BuildContext context, Map<String, dynamic> data) async {
    try {
      // Get Xtream credentials from response
      String username = data['username'] ?? '';
      String password = data['password'] ?? '';
      String url = data['server_url'] ?? '';
      String playlistName = data['playlist_name'] ?? 'IPTV Subscription';
      
      debugPrint('Using Xtream credentials - Username: $username, Server: $url');
      debugPrint('Playlist name: $playlistName');

      // Check for subscription expiration
      DateTime? expiryDate;
      if (data['expires'] != null) {
        expiryDate = DateTime.tryParse(data['expires']);
        debugPrint('Subscription expires on: ${expiryDate?.toString() ?? 'unknown'}');
      }

      // Validate credentials before registering
      debugPrint('Validating credentials before registration...');
      if (username.isEmpty || password.isEmpty || url.isEmpty) {
        debugPrint('Error: Missing required credentials');
        _showErrorSnackbar('Invalid credentials received from server');
        return false;
      }

      // Use the same AuthRegister event as the register screen
      context.read<AuthBloc>().add(AuthRegister(
        username,
        password,
        url,
        playlistName: playlistName,
      ));

      // Create a temporary user model to use with ExpirationService
      final UserModel tempUser = UserModel(
        userInfo: UserInfo(
          username: username,
          password: password,
          expDate: expiryDate?.millisecondsSinceEpoch.toString(),
          createdAt: DateTime.now().millisecondsSinceEpoch.toString(),
        ),
        serverInfo: ServerInfo(
          url: url,
        ),
      );
      
      // Check if subscription is expiring soon
      int? daysRemaining;
      bool isExpiringSoon = false;

      if (expiryDate != null) {
        final now = DateTime.now();
        daysRemaining = expiryDate.difference(now).inDays;
        isExpiringSoon = daysRemaining <= 3 && daysRemaining >= 0;
        debugPrint('Days remaining: $daysRemaining, Expiring soon: $isExpiringSoon');
      }
      
      // Show appropriate notification based on expiration status
      if (isExpiringSoon && daysRemaining != null) {
        // Show expiration warning using ExpirationService
        _expirationService.showExpirationNotification(tempUser);
      }
      
      return true;
    } catch (e) {
      debugPrint('Error uploading playlist: $e');
      _showErrorSnackbar('Failed to upload playlist: ${e.toString()}');
      return false;
    }
  }
  
  /// Shows a success dialog with an option to navigate to the User List screen
  void showSuccessDialog(BuildContext context) {
    Get.dialog(
      Dialog(
        backgroundColor: Colors.grey[900],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.check_circle,
                color: Colors.green,
                size: 60,
              ),
              const SizedBox(height: 20),
              Text(
                'Playlist uploaded successfully.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: () {
                  Get.back(); // Close dialog
                  Get.toNamed('/user-list'); // Navigate to User List screen
                },
                child: Text(
                  'Go to User List',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      barrierDismissible: false,
    );
  }
  
  /// Shows an error snackbar with the provided message
  void _showErrorSnackbar(String message) {
    Get.snackbar(
      'Error',
      message,
      backgroundColor: Colors.red,
      colorText: Colors.white,
      snackPosition: SnackPosition.BOTTOM,
    );
  }
}
