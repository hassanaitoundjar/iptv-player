import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import '../../helpers/helpers.dart';

/// Service to handle parental control functionality
class ParentalControlService {
  // Singleton pattern
  static final ParentalControlService _instance =
      ParentalControlService._internal();
  factory ParentalControlService() => _instance;
  ParentalControlService._internal();

  // Constants for SharedPreferences keys
  static const String _pinKey = 'parental_control_pin';
  static const String _enabledKey = 'parental_control_enabled';

  // Adult content keywords for detection
  final List<String> adultKeywords = [
    'xxx',
    'adult',
    'porn',
    '18+',
    'sex',
    'erotic',
    'mature',
    'playboy',
    'hustler',
    'penthouse',
    'for adults',
    'adults only'
  ];

  /// Check if parental control is enabled
  Future<bool> isEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_enabledKey) ?? false;
  }

  /// Enable or disable parental control
  Future<void> setEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_enabledKey, enabled);
  }

  /// Check if PIN is set
  Future<bool> isPinSet() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_pinKey)?.isNotEmpty ?? false;
  }

  /// Set a new PIN
  Future<void> setPin(String pin) async {
    if (pin.length != 4 || int.tryParse(pin) == null) {
      throw Exception('PIN must be a 4-digit number');
    }

    final prefs = await SharedPreferences.getInstance();
    // Store hashed PIN for security
    final hashedPin = _hashPin(pin);
    await prefs.setString(_pinKey, hashedPin);
  }

  /// Verify if the provided PIN is correct
  Future<bool> verifyPin(String pin) async {
    final prefs = await SharedPreferences.getInstance();
    final storedHashedPin = prefs.getString(_pinKey);

    if (storedHashedPin == null) return false;

    final hashedInputPin = _hashPin(pin);
    return hashedInputPin == storedHashedPin;
  }

  /// Hash the PIN for secure storage
  String _hashPin(String pin) {
    final bytes = utf8.encode(pin + 'iptv_player_salt');
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Check if content should be blocked based on its name
  bool shouldBlockContent(String name) {
    if (name.isEmpty) return false;

    final lowercaseName = name.toLowerCase();
    return adultKeywords.any((keyword) => lowercaseName.contains(keyword));
  }

  // Temporary unlock functionality has been removed
  // Adult content now always requires PIN verification
  // when parental control is enabled

  /// Reset PIN (requires old PIN for verification)
  Future<bool> resetPin(String oldPin, String newPin) async {
    final isPinCorrect = await verifyPin(oldPin);

    if (!isPinCorrect) {
      return false;
    }

    await setPin(newPin);
    return true;
  }

  /// Show PIN entry dialog
  Future<bool> showPinEntryDialog(BuildContext context) async {
    final TextEditingController pinController = TextEditingController();
    bool isPinCorrect = false;

    await Get.dialog(
      Dialog(
        backgroundColor: kColorCardDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.lock,
                color: Colors.amber,
                size: 50,
              ),
              const SizedBox(height: 20),
              Text(
                'Enter Parental Control PIN',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: pinController,
                keyboardType: TextInputType.number,
                maxLength: 4,
                obscureText: true,
                style: TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  counterText: '',
                  hintText: '• • • •',
                  hintStyle: TextStyle(color: Colors.grey),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.amber),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 30),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  TextButton(
                    onPressed: () {
                      Get.back();
                    },
                    child: Text(
                      'Cancel',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 30, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: () async {
                      final isCorrect = await verifyPin(pinController.text);
                      if (isCorrect) {
                        // PIN is correct, allow access to this content
                        isPinCorrect = true;
                        Get.back();
                      } else {
                        Get.snackbar(
                          'Incorrect PIN',
                          'Please try again',
                          backgroundColor: Colors.red,
                          colorText: Colors.white,
                          snackPosition: SnackPosition.BOTTOM,
                        );
                      }
                    },
                    child: Text(
                      'Unlock',
                      style: TextStyle(color: Colors.black),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      barrierDismissible: false,
    );

    return isPinCorrect;
  }

  /// Show PIN setup dialog for first-time setup
  Future<bool> showPinSetupDialog(BuildContext context) async {
    final TextEditingController pinController = TextEditingController();
    final TextEditingController confirmPinController = TextEditingController();
    bool isPinVisible = false;
    bool isPinSet = false;

    await Get.dialog(
      Dialog(
        backgroundColor: kColorCardLight,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        child: StatefulBuilder(
          builder: (context, setState) => Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                Text(
                  'Set Parental Control PIN',
                  style: Get.textTheme.titleMedium!.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 15),
                // Description text
                Text(
                  'Create a 4-digit PIN to protect adult content. This PIN will be required to access restricted content.',
                  style: Get.textTheme.bodyMedium!.copyWith(
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 20),
                // PIN input field
                TextField(
                  controller: pinController,
                  keyboardType: TextInputType.number,
                  maxLength: 4,
                  obscureText: !isPinVisible,
                  style:
                      Get.textTheme.bodyMedium!.copyWith(color: Colors.white),
                  decoration: InputDecoration(
                    counterText: '',
                    hintText: '• • • •',
                    hintStyle: Get.textTheme.bodyMedium!.copyWith(
                      color: Colors.grey,
                    ),
                    counterStyle: Get.textTheme.bodySmall!.copyWith(
                      color: Colors.white70,
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        isPinVisible ? Icons.visibility_off : Icons.visibility,
                        size: 18,
                        color: kColorPrimary,
                      ),
                      onPressed: () {
                        setState(() {
                          isPinVisible = !isPinVisible;
                        });
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 15),
                // Confirm PIN field
                TextField(
                  controller: confirmPinController,
                  keyboardType: TextInputType.number,
                  maxLength: 4,
                  obscureText: !isPinVisible,
                  style:
                      Get.textTheme.bodyMedium!.copyWith(color: Colors.white),
                  decoration: InputDecoration(
                    counterText: '',
                    hintText: 'Confirm PIN',
                    hintStyle: Get.textTheme.bodyMedium!.copyWith(
                      color: Colors.grey,
                    ),
                    counterStyle: Get.textTheme.bodySmall!.copyWith(
                      color: Colors.white70,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                // Action buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () {
                        Get.back();
                      },
                      child: Text(
                        'CANCEL',
                        style: Get.textTheme.bodyMedium!.copyWith(
                          color: Colors.white70,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () async {
                        if (pinController.text.length != 4 ||
                            int.tryParse(pinController.text) == null) {
                          Get.snackbar(
                            'Invalid PIN',
                            'Please enter a 4-digit PIN.',
                            backgroundColor: Colors.red,
                            colorText: Colors.white,
                            snackPosition: SnackPosition.BOTTOM,
                          );
                          return;
                        }

                        if (pinController.text != confirmPinController.text) {
                          Get.snackbar(
                            'PIN Mismatch',
                            'The PINs you entered do not match.',
                            backgroundColor: Colors.red,
                            colorText: Colors.white,
                            snackPosition: SnackPosition.BOTTOM,
                          );
                          return;
                        }

                        try {
                          await setPin(pinController.text);
                          await setEnabled(true);
                          isPinSet = true;
                          Get.back();
                          Get.snackbar(
                            'PIN Set',
                            'Parental control is now enabled.',
                            backgroundColor: Colors.green,
                            colorText: Colors.white,
                            snackPosition: SnackPosition.BOTTOM,
                          );
                        } catch (e) {
                          Get.snackbar(
                            'Error',
                            'Failed to set PIN: ${e.toString()}',
                            backgroundColor: Colors.red,
                            colorText: Colors.white,
                            snackPosition: SnackPosition.BOTTOM,
                          );
                        }
                      },
                      child: Text(
                        'SAVE',
                        style: Get.textTheme.bodyMedium!.copyWith(
                          color: kColorPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      barrierDismissible: false,
    );

    return isPinSet;
  }
}
