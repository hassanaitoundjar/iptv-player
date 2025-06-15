import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:player/repository/models/user.dart';

/// Service to handle subscription expiration notifications
class ExpirationService {
  // Singleton pattern
  static final ExpirationService _instance = ExpirationService._internal();
  factory ExpirationService() => _instance;
  ExpirationService._internal();
  
  /// Check if the subscription is about to expire
  /// Returns true if the subscription expires in [daysThreshold] days or less
  bool isSubscriptionExpiringSoon(UserModel user, {int daysThreshold = 3}) {
    if (user.userInfo?.expDate == null) return false;
    
    try {
      // Parse the expiration date from Unix timestamp
      final int? unixTime = int.tryParse(user.userInfo!.expDate!);
      if (unixTime == null) return false;
      
      // Convert to DateTime
      final DateTime expirationDate = DateTime.fromMillisecondsSinceEpoch(unixTime * 1000);
      
      // Get current date
      final DateTime now = DateTime.now();
      
      // Calculate days remaining
      final int daysRemaining = expirationDate.difference(now).inDays;
      
      // Return true if days remaining is less than or equal to threshold
      return daysRemaining <= daysThreshold && daysRemaining >= 0;
    } catch (e) {
      print('Error checking subscription expiration: $e');
      return false;
    }
  }
  
  /// Get the number of days remaining until subscription expires
  int? getDaysRemaining(UserModel user) {
    if (user.userInfo?.expDate == null) return null;
    
    try {
      // Parse the expiration date from Unix timestamp
      final int? unixTime = int.tryParse(user.userInfo!.expDate!);
      if (unixTime == null) return null;
      
      // Convert to DateTime
      final DateTime expirationDate = DateTime.fromMillisecondsSinceEpoch(unixTime * 1000);
      
      // Get current date
      final DateTime now = DateTime.now();
      
      // Calculate days remaining
      return expirationDate.difference(now).inDays;
    } catch (e) {
      print('Error calculating days remaining: $e');
      return null;
    }
  }
  
  /// Show an in-app notification for subscription expiration
  void showExpirationNotification(UserModel user) {
    final int? daysRemaining = getDaysRemaining(user);
    
    if (daysRemaining == null) return;
    
    if (daysRemaining <= 3 && daysRemaining >= 0) {
      String message;
      Color backgroundColor;
      
      if (daysRemaining == 0) {
        message = 'Your subscription expires today!';
        backgroundColor = Colors.red;
      } else if (daysRemaining == 1) {
        message = 'Your subscription expires tomorrow!';
        backgroundColor = Colors.orange;
      } else {
        message = 'Your subscription expires in $daysRemaining days!';
        backgroundColor = Colors.orange;
      }
      
      // Show a GetX snackbar notification
      Get.snackbar(
        'Subscription Expiring',
        message,
        snackPosition: SnackPosition.TOP,
        backgroundColor: backgroundColor,
        colorText: Colors.white,
        duration: const Duration(seconds: 5),
        margin: const EdgeInsets.all(10),
        borderRadius: 10,
        icon: const Icon(Icons.warning_amber_rounded, color: Colors.white),
      );
    }
  }
}
