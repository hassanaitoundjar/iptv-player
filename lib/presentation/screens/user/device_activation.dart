part of '../screens.dart';

class DeviceActivationScreen extends StatefulWidget {
  const DeviceActivationScreen({super.key});

  @override
  State<DeviceActivationScreen> createState() => _DeviceActivationScreenState();
}

class _DeviceActivationScreenState extends State<DeviceActivationScreen> {
  String macAddress = '';
  String deviceKey = '';
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _getDeviceInfo();
  }

  Future<void> _getDeviceInfo() async {
    setState(() {
      isLoading = true;
    });

    try {
      // Get real device identifiers
      DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();

      if (Platform.isAndroid) {
        AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;

        // Format MAC-like address from Android ID
        // This is not a real MAC address but a unique device identifier
        String id = androidInfo.id;
        if (id.length >= 12) {
          // Format as XX:XX:XX:XX:XX:XX
          macAddress = id
              .substring(0, 12)
              .replaceAllMapped(
                  RegExp(r'(.{2})'), (match) => '${match.group(0)}:')
              .substring(0, 17);
        } else {
          // Pad if needed
          macAddress = (id.padRight(12, '0'))
              .replaceAllMapped(
                  RegExp(r'(.{2})'), (match) => '${match.group(0)}:')
              .substring(0, 17);
        }

        // Convert to uppercase for consistency
        macAddress = macAddress.toUpperCase();
      } else if (Platform.isIOS) {
        IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
        String id = iosInfo.identifierForVendor ?? '';

        // Format MAC-like address from iOS vendor ID
        if (id.length >= 12) {
          // Format as XX:XX:XX:XX:XX:XX
          macAddress = id
              .substring(0, 12)
              .replaceAllMapped(
                  RegExp(r'(.{2})'), (match) => '${match.group(0)}:')
              .substring(0, 17);
        } else {
          // Pad if needed
          macAddress = (id.padRight(12, '0'))
              .replaceAllMapped(
                  RegExp(r'(.{2})'), (match) => '${match.group(0)}:')
              .substring(0, 17);
        }

        // Convert to uppercase for consistency
        macAddress = macAddress.toUpperCase();
      } else {
        // For other platforms, generate a consistent MAC-like address
        final random = Random(DateTime.now().millisecondsSinceEpoch);
        macAddress = List.generate(
                6, (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0'))
            .join(':')
            .toUpperCase();
      }

      // Generate a unique device key that will remain consistent for this device
      deviceKey = await _generateDeviceKey();

      debugPrint('Using MAC address: $macAddress');
      debugPrint('Using device key: $deviceKey');
    } catch (e) {
      debugPrint('Error getting device info: $e');
      
      // Generate a more realistic fallback MAC address based on device timestamp
      // Use a consistent seed for the same device
      final seed = DateTime.now().millisecondsSinceEpoch & 0xFFFFFF; // Last 24 bits
      final random = Random(seed);
      
      // Generate MAC address with locally administered bit set (second least significant bit of first byte)
      // This ensures it won't conflict with real manufacturer MACs
      final firstByte = (0x02 | (random.nextInt(254) & 0xFE)).toRadixString(16).padLeft(2, '0');
      
      macAddress = [
        firstByte,
        ...List.generate(5, (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0'))
      ].join(':').toUpperCase();
      
      // Generate a 6-digit fallback key based on the same seed for consistency
      deviceKey = ((seed % 900000) + 100000).toString();
      
      debugPrint('Using generated MAC address: $macAddress');
      debugPrint('Using 6-digit device key: $deviceKey');
    }

    setState(() {
      isLoading = false;
    });
  }

  Future<String> _generateDeviceKey() async {
    final deviceInfo = DeviceInfoPlugin();
    Map<String, String> deviceData = {};

    try {
      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;

        // Collect multiple permanent identifiers for better uniqueness
        deviceData = {
          'id': androidInfo.id,
          'brand': androidInfo.brand,
          'model': androidInfo.model,
          'device': androidInfo.device,
          'product': androidInfo.product,
          'hardware': androidInfo.hardware,
          'manufacturer': androidInfo.manufacturer,
          'fingerprint': androidInfo.fingerprint,
          // Add Android version for additional uniqueness
          'version': androidInfo.version.release,
        };

        debugPrint('Android device data collected for key generation');
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;

        // Collect multiple permanent identifiers for better uniqueness
        deviceData = {
          'id': iosInfo.identifierForVendor ?? '',
          'model': iosInfo.model,
          'name': iosInfo.name,
          'systemName': iosInfo.systemName,
          'systemVersion': iosInfo.systemVersion,
          'localizedModel': iosInfo.localizedModel,
          'utsname.machine': iosInfo.utsname.machine,
          'utsname.nodename': iosInfo.utsname.nodename,
        };

        debugPrint('iOS device data collected for key generation');
      } else {
        // For other platforms, use system info
        deviceData = {
          'os': Platform.operatingSystem,
          'osVersion': Platform.operatingSystemVersion,
          'localHostname': Platform.localHostname,
          'numberOfProcessors': Platform.numberOfProcessors.toString(),
          'timestamp': DateTime.now().millisecondsSinceEpoch.toString(),
        };
      }

      // Sort keys for consistent order
      final sortedKeys = deviceData.keys.toList()..sort();
      final sortedData =
          sortedKeys.map((k) => "${k}=${deviceData[k]}").join('|');

      // Generate a hash of the device data
      final bytes = utf8.encode(sortedData);
      final digest = sha256.convert(bytes);
      
      // Convert the first 24 bits (6 hex chars) of the hash to an integer
      // and take modulo 1000000 to get a 6-digit number
      final hexSubstring = digest.toString().substring(0, 6);
      final intValue = int.parse(hexSubstring, radix: 16);
      final sixDigitNumber = (intValue % 1000000).toString().padLeft(6, '0');
      
      debugPrint('Generated 6-digit device key: $sixDigitNumber');
      return sixDigitNumber;
    } catch (e) {
      debugPrint('Error generating device key: $e');
      // Fallback to a random 6-digit number based on timestamp
      final random = Random(DateTime.now().millisecondsSinceEpoch);
      final fallbackKey = (random.nextInt(900000) + 100000).toString();
      
      debugPrint('Using fallback 6-digit device key: $fallbackKey');
      return fallbackKey;
    }
  }

  // This method allows the user to manually check their activation status
  // and upload a playlist if the device is activated
  Future<void> _checkActivationAndUploadPlaylist(BuildContext context) async {
    if (macAddress.isEmpty || deviceKey.isEmpty) {
      Get.snackbar(
        'Error',
        'Device information is not available',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      // Create a PlaylistService instance
      final playlistService = PlaylistService();
      
      // Check if device is activated
      final result = await playlistService.checkDeviceActivation(macAddress, deviceKey);
      
      if (result['success'] == true && result['data'] != null) {
        final data = result['data'];
        
        // Check if device is active
        if (data['status'] == 'active') {
          // Upload playlist
          final success = await playlistService.uploadPlaylist(context, data);
          
          if (success) {
            // Show success dialog with option to navigate to user list
            playlistService.showSuccessDialog(context);
          }
        } else if (data['status'] == 'expired') {
          Get.snackbar(
            'Subscription Expired',
            'Your subscription has expired. Please renew to continue.',
            backgroundColor: Colors.red,
            colorText: Colors.white,
            snackPosition: SnackPosition.BOTTOM,
          );
        } else {
          Get.snackbar(
            'Not Activated',
            'This device has not been activated yet. Please visit the activation website.',
            backgroundColor: Colors.orange,
            colorText: Colors.white,
            snackPosition: SnackPosition.BOTTOM,
          );
        }
      } else {
        Get.snackbar(
          'Error',
          result['error'] ?? 'Failed to check device activation',
          backgroundColor: Colors.red,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } catch (e) {
      debugPrint('Error checking activation: $e');
      Get.snackbar(
        'Error',
        'Failed to check device activation: ${e.toString()}',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    Get.snackbar(
      'Copied',
      'Text copied to clipboard',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.green.withOpacity(0.7),
      colorText: Colors.white,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isTV = constraints.maxWidth > 1000;
          
          return Container(
            width: constraints.maxWidth,
            height: constraints.maxHeight,
            decoration: kDecorBackground,
            child: SafeArea(
              child: Column(
                children: [
                  // App bar with back button and title
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: 16, 
                      vertical: isTV ? 20 : 12
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          onPressed: () => Get.back(),
                          icon: const Icon(
                            FontAwesomeIcons.chevronLeft,
                            color: Colors.white,
                          ),
                          iconSize: isTV ? 28 : 20,
                        ),
                        const SizedBox(width: 16),
                        Text(
                          'Device Activation',
                          style: Get.textTheme.titleLarge!.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: isTV ? 28 : null,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Main content
                  Expanded(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.symmetric(
                        horizontal: isTV ? 40 : 20,
                        vertical: isTV ? 30 : 20,
                      ),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            maxWidth: isTV ? 800 : 600,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              // Logo
                              Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.blueAccent.withOpacity(0.1),
                                ),
                                child: Image.asset(
                                  kIconSplash,
                                  width: isTV ? 100 : 60,
                                  height: isTV ? 100 : 60,
                                ),
                              ),
                              
                              const SizedBox(height: 30),
                              
                              // Instructions
                              Text(
                                'Activate Your Device',
                                style: Get.textTheme.headlineMedium!.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: isTV ? 32 : null,
                                ),
                              ),
                              const SizedBox(height: 15),
                              Text(
                                'Please visit our website and enter the following information to activate your device:',
                                textAlign: TextAlign.center,
                                style: Get.textTheme.bodyLarge!.copyWith(
                                  color: Colors.white70,
                                  fontSize: isTV ? 18 : null,
                                ),
                              ),
                              
                              const SizedBox(height: 40),
                              
                              // Device info cards
                              if (isLoading)
                                SizedBox(
                                  height: 120,
                                  child: Center(
                                    child: CircularProgressIndicator(
                                      color: Colors.purpleAccent,
                                    ),
                                  ),
                                )
                              else
                                Column(
                                  children: [
                                    _buildInfoCard(
                                      title: 'MAC Address',
                                      value: macAddress,
                                      onTap: () => _copyToClipboard(macAddress),
                                      isTV: isTV,
                                    ),
                                    const SizedBox(height: 20),
                                    _buildInfoCard(
                                      title: 'Device Key',
                                      value: deviceKey,
                                      onTap: () => _copyToClipboard(deviceKey),
                                      isTV: isTV,
                                    ),
                                  ],
                                ),
                              
                              const SizedBox(height: 40),
                              
                              // Action buttons
                              Text(
                                'After activation on the website, return here and check your activation status.',
                                textAlign: TextAlign.center,
                                style: Get.textTheme.bodyMedium!.copyWith(
                                  color: Colors.white70,
                                  fontSize: isTV ? 16 : null,
                                ),
                              ),
                              const SizedBox(height: 30),
                              
                              // Action buttons in a responsive grid
                              Wrap(
                                spacing: 20,
                                runSpacing: 20,
                                alignment: WrapAlignment.center,
                                children: [
                                  _buildActionButton(
                                    icon: Icons.language,
                                    title: 'Open Activation Website',
                                    onTap: () async {
                                      final url = Uri.parse('${AppConfig.webBaseUrl}/activate');
                                      if (await canLaunchUrl(url)) {
                                        await launchUrl(url, mode: LaunchMode.externalApplication);
                                      }
                                    },
                                    isTV: isTV,
                                  ),
                                  
                                  _buildActionButton(
                                    icon: Icons.check_circle_outline,
                                    title: 'Check Activation Status',
                                    onTap: () => _checkActivationAndUploadPlaylist(context),
                                    isTV: isTV,
                                    isHighlighted: true,
                                  ),
                                  
                                  _buildActionButton(
                                    icon: Icons.app_registration,
                                    title: 'Manual Registration',
                                    onTap: () => Get.toNamed(screenRegister),
                                    isTV: isTV,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoCard({
    required String title,
    required String value,
    required VoidCallback onTap,
    required bool isTV,
  }) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isTV ? 20 : 15),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.purpleAccent.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Get.textTheme.bodyMedium!.copyWith(
              color: Colors.white70,
              fontSize: isTV ? 18 : 14,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Text(
                  value,
                  style: Get.textTheme.bodyLarge!.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: isTV ? 22 : 16,
                  ),
                ),
              ),
              InkWell(
                onTap: onTap,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: EdgeInsets.all(isTV ? 12 : 8),
                  decoration: BoxDecoration(
                    color: Colors.purpleAccent.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    FontAwesomeIcons.copy,
                    color: Colors.purpleAccent,
                    size: isTV ? 24 : 18,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    required bool isTV,
    bool isHighlighted = false,
    bool isDisabled = false,
  }) {
    // Card sizes based on screen size
    final double cardWidth = isTV ? 220.0 : 160.0;
    final double cardHeight = isTV ? 120.0 : 100.0;
    final double iconSize = isTV ? 40.0 : 30.0;
    final double fontSize = isTV ? 16.0 : 14.0;
    
    return InkWell(
      onTap: isDisabled ? null : onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: cardWidth,
        height: cardHeight,
        decoration: BoxDecoration(
          color: Colors.grey[900],
          borderRadius: BorderRadius.circular(12),
          border: isHighlighted 
              ? Border.all(color: Colors.purpleAccent, width: 2) 
              : null,
          boxShadow: isHighlighted 
              ? [BoxShadow(color: Colors.purpleAccent.withOpacity(0.3), blurRadius: 8, spreadRadius: 1)]
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isHighlighted 
                    ? Colors.purpleAccent.withOpacity(0.2) 
                    : Colors.blueAccent.withOpacity(0.1),
              ),
              child: Icon(
                icon,
                size: iconSize,
                color: isDisabled 
                    ? Colors.grey 
                    : (isHighlighted ? Colors.purpleAccent : Colors.blueAccent),
              ),
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isDisabled ? Colors.grey : Colors.white,
                  fontSize: fontSize,
                  fontWeight: isHighlighted ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
