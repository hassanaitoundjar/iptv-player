import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:player/repository/models/user.dart';

/// Service for handling Firebase operations related to user data
class FirebaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Singleton pattern to ensure only one instance exists
  static final FirebaseService _instance = FirebaseService._internal();
  
  /// Factory constructor that returns the singleton instance
  factory FirebaseService() => _instance;
  
  /// Private constructor used by the singleton pattern
  FirebaseService._internal();

  /// Stores essential user data in Firebase Firestore
  /// 
  /// Takes a [UserModel] and extracts only the username, password and server URL
  /// Returns true if successful, false otherwise
  Future<bool> storeUserData(UserModel user) async {
    try {
      // Validate required fields
      final username = user.userInfo?.username;
      if (username == null || username.isEmpty) {
        print('Cannot store user: username is null or empty');
        return false;
      }
      
      // Extract the essential data we need
      final Map<String, dynamic> userData = {
        'username': username,
        'password': user.userInfo?.password,
        'serverUrl': user.serverInfo?.url,
        
        // Store both original timestamp string and converted DateTime for createdAt
        'createdAt': user.userInfo?.createdAt,
        'createdAtFormatted': _formatTimestamp(user.userInfo?.createdAt),
        
        // Store both original timestamp string and converted DateTime for expDate
        'expDate': user.userInfo?.expDate,
        'expDateFormatted': _formatTimestamp(user.userInfo?.expDate),
        
        'timestamp': FieldValue.serverTimestamp(),
      };
      
      // Store in Firestore under the users collection
      await _firestore.collection('users').doc(username).set(userData);
      print('User data stored successfully in Firebase');
      return true;
    } catch (e) {
      print('Error storing user data in Firebase: $e');
      return false;
    }
  }
  
  /// Updates the last login timestamp for a user
  Future<void> updateLastLogin(String username) async {
    if (username.isEmpty) return;
    
    try {
      await _firestore.collection('users').doc(username).update({
        'lastLogin': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error updating last login: $e');
    }
  }
  
  /// Converts a Unix timestamp string to a formatted date string
  /// Returns null if the input is null or invalid
  String? _formatTimestamp(String? timestamp) {
    if (timestamp == null || timestamp.isEmpty) {
      return null;
    }
    
    try {
      // Parse the Unix timestamp (in seconds)
      final int? unixTime = int.tryParse(timestamp);
      if (unixTime == null) return null;
      
      // Convert to DateTime
      final DateTime dateTime = DateTime.fromMillisecondsSinceEpoch(unixTime * 1000);
      
      // Format the date as a readable string (YYYY-MM-DD HH:MM:SS)
      return '${dateTime.year}-${_twoDigits(dateTime.month)}-${_twoDigits(dateTime.day)} '
          '${_twoDigits(dateTime.hour)}:${_twoDigits(dateTime.minute)}:${_twoDigits(dateTime.second)}';
    } catch (e) {
      print('Error formatting timestamp: $e');
      return null;
    }
  }
  
  /// Helper method to ensure two digits in date/time components
  String _twoDigits(int n) {
    if (n >= 10) return '$n';
    return '0$n';
  }
  
  // Store playlist PIN in Firestore
  Future<void> updatePlaylistPin(String username, String playlistName, String pin) async {
    try {
      await _firestore.collection('users').doc(username).collection('playlists').doc(playlistName).set({
        'pinProtected': pin.isNotEmpty,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      print('Error updating playlist PIN: $e');
    }
  }
}
