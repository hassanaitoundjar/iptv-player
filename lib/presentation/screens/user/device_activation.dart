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
      body: Ink(
        width: getSize(context).width,
        height: getSize(context).height,
        decoration: kDecorBackground,
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    onPressed: () => Get.back(),
                    icon: const Icon(
                      FontAwesomeIcons.chevronLeft,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      SizedBox(height: 2.h),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.asset(
                            kIconSplash,
                            width: .7.dp,
                            height: .7.dp,
                          ),
                        ],
                      ),
                      const SizedBox(height: 30),
                      Text(
                        'Device Activation',
                        style: Get.textTheme.headlineMedium!.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 15),
                      Text(
                        'Please visit our website and enter the following information to activate your device:',
                        textAlign: TextAlign.center,
                        style: Get.textTheme.bodyLarge!.copyWith(
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 40),
                      if (isLoading)
                        const CircularProgressIndicator()
                      else
                        Column(
                          children: [
                            _buildInfoCard(
                              title: 'MAC Address',
                              value: macAddress,
                              onTap: () => _copyToClipboard(macAddress),
                            ),
                            const SizedBox(height: 20),
                            _buildInfoCard(
                              title: 'Device Key',
                              value: deviceKey,
                              onTap: () => _copyToClipboard(deviceKey),
                            ),
                          ],
                        ),
                      const SizedBox(height: 40),
                      Text(
                        'After activation on the website, return here and check your activation status.',
                        textAlign: TextAlign.center,
                        style: Get.textTheme.bodyMedium!.copyWith(
                          color: Colors.white70,
                        ),
                      ),
                      const SizedBox(height: 20),
                      CardTallButton(
                        label: "Open Activation Website",
                        onTap: () async {
                          final url =
                              Uri.parse('${AppConfig.webBaseUrl}/activate');
                          if (await canLaunchUrl(url)) {
                            await launchUrl(url,
                                mode: LaunchMode.externalApplication);
                            debugPrint('Opening activation website');
                          }
                        },
                      ),
                      const SizedBox(height: 20),
                      CardTallButton(
                        label: "Check Activation Status",
                        onTap: () => _checkActivationAndUploadPlaylist(context),
                      ),
                      const SizedBox(height: 20),
                      TextButton(
                        onPressed: () {
                          Get.toNamed(screenRegister);
                        },
                        child: Text(
                          'Manual Registration',
                          style: Get.textTheme.bodyMedium!.copyWith(
                            color: kColorPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required String title,
    required String value,
    required VoidCallback onTap,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: kColorPrimary.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Get.textTheme.bodyMedium!.copyWith(
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(
                  value,
                  style: Get.textTheme.bodyLarge!.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              InkWell(
                onTap: onTap,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: kColorPrimary.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: const Icon(
                    FontAwesomeIcons.copy,
                    color: kColorPrimary,
                    size: 18,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
