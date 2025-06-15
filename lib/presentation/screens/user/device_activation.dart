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
  Timer? _checkActivationTimer;

  // Configuration for activation polling
  static const int pollingIntervalSeconds = 5;

  @override
  void initState() {
    super.initState();
    _getDeviceInfo();
    _startPollingForActivation();
  }

  @override
  void dispose() {
    _checkActivationTimer?.cancel();
    super.dispose();
  }

  Future<void> _getDeviceInfo() async {
    setState(() {
      isLoading = true;
    });

    try {
      // Get device information to create a unique MAC-like address
      DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
      String uniqueId = '';
      String deviceModel = '';
      String deviceName = '';
      
      if (Platform.isAndroid) {
        AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
        uniqueId = androidInfo.id;
        deviceModel = androidInfo.model;
        deviceName = androidInfo.device;
        
        // Format as MAC address (XX:XX:XX:XX:XX:XX)
        final bytes = utf8.encode('$uniqueId$deviceModel$deviceName');
        final digest = sha256.convert(bytes);
        final hexString = digest.toString().substring(0, 12).toUpperCase(); // Take first 12 chars
        
        // Format as XX:XX:XX:XX:XX:XX
        macAddress = _formatAsMacAddress(hexString);
        debugPrint('Generated Android MAC address: $macAddress');
      } else if (Platform.isIOS) {
        IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
        uniqueId = iosInfo.identifierForVendor ?? '';
        deviceModel = iosInfo.model;
        deviceName = iosInfo.name;
        
        // Format as MAC address (XX:XX:XX:XX:XX:XX)
        final bytes = utf8.encode('$uniqueId$deviceModel$deviceName');
        final digest = sha256.convert(bytes);
        final hexString = digest.toString().substring(0, 12).toUpperCase(); // Take first 12 chars
        
        // Format as XX:XX:XX:XX:XX:XX
        macAddress = _formatAsMacAddress(hexString);
        debugPrint('Generated iOS MAC address: $macAddress');
      }

      // Generate a device key that will remain consistent for this device
      deviceKey = await _generateDeviceKey();
      debugPrint('Using device key: $deviceKey');
    } catch (e) {
      debugPrint('Error getting device info: $e');
      // Fallback to random values for testing
      macAddress = '00:11:22:33:44:55';
      deviceKey = 'TEST_DEVICE_KEY_8100';
    }

    setState(() {
      isLoading = false;
    });
  }
  
  // Format a hex string as a MAC address (XX:XX:XX:XX:XX:XX)
  String _formatAsMacAddress(String hexString) {
    final List<String> pairs = [];
    for (int i = 0; i < hexString.length; i += 2) {
      if (i + 2 <= hexString.length) {
        pairs.add(hexString.substring(i, i + 2));
      }
    }
    return pairs.join(':');
  }

  Future<String> _generateDeviceKey() async {
    final deviceInfo = DeviceInfoPlugin();
    String deviceData = '';

    if (Platform.isAndroid) {
      final androidInfo = await deviceInfo.androidInfo;
      // Use only permanent device identifiers that won't change
      deviceData = '${androidInfo.brand}_${androidInfo.id}_${androidInfo.model}_${androidInfo.device}_${androidInfo.hardware}';
      debugPrint('Android device data for key: $deviceData');
    } else if (Platform.isIOS) {
      final iosInfo = await deviceInfo.iosInfo;
      // Use only permanent device identifiers that won't change
      deviceData = '${iosInfo.identifierForVendor}_${iosInfo.model}_${iosInfo.name}_${iosInfo.systemName}_${iosInfo.systemVersion}';
      debugPrint('iOS device data for key: $deviceData');
    }

    // Add a salt to make the key more unique
    final salt = 'IPTV_PLAYER_UNIQUE_SALT_2025';
    deviceData = '$deviceData$salt$macAddress';
    
    // Generate a hash of the device data
    final bytes = utf8.encode(deviceData);
    final digest = sha256.convert(bytes);
    
    // Create a key with 16 characters (alphanumeric)
    final fullHash = digest.toString().toUpperCase();
    final key = fullHash.substring(0, 16);
    
    debugPrint('Generated consistent device key: $key');
    return key;
  }

  void _startPollingForActivation() {
    // Check every few seconds if the device has been activated
    _checkActivationTimer =
        Timer.periodic(Duration(seconds: pollingIntervalSeconds), (_) {
      _checkActivationStatus();
    });

    // Also check immediately
    _checkActivationStatus();
  }

  Future<void> _checkActivationStatus() async {
    if (macAddress.isEmpty || deviceKey.isEmpty) return;

    debugPrint(
        'Checking activation status for MAC: $macAddress, Key: $deviceKey');

    try {
      // Use the simple API endpoint format like iboPlayer: /api/device/{mac}/{key}
      final url = '${AppConfig.apiBaseUrl}/api/device/$macAddress/$deviceKey';
      debugPrint('API URL: $url');

      final response = await http.get(Uri.parse(url));

      debugPrint('API Response Status: ${response.statusCode}');
      debugPrint('API Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        debugPrint('Parsed data: $data');

        // Check if device is active based on status field (iboPlayer format)
        if (data['status'] == 'active') {
          debugPrint('Device is activated! Preparing to navigate...');

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
            debugPrint(
                'Subscription expires on: ${expiryDate?.toString() ?? 'unknown'}');
          }

          int? daysRemaining;
          bool isExpiringSoon = false;

          if (expiryDate != null) {
            final now = DateTime.now();
            daysRemaining = expiryDate.difference(now).inDays;
            isExpiringSoon = daysRemaining <= 3 && daysRemaining >= 0;
            debugPrint(
                'Days remaining: $daysRemaining, Expiring soon: $isExpiringSoon');
          }

          // Validate credentials before registering
          debugPrint('Validating credentials before registration...');
          if (username.isNotEmpty && password.isNotEmpty && url.isNotEmpty) {
            debugPrint('Registering user with AuthBloc...');
            debugPrint('Username: $username, Password: $password, URL: $url');
            debugPrint('Playlist Name: $playlistName');
            
            // Use the same AuthRegister event as the register screen
            context.read<AuthBloc>().add(AuthRegister(
                  username,
                  password,
                  url,
                  playlistName: playlistName,
                ));
          } else {
            debugPrint('Error: Missing required credentials');
            // Show error message to user
            Get.snackbar(
              'Activation Error',
              'Invalid credentials received from server',
              backgroundColor: Colors.red,
              colorText: Colors.white,
              snackPosition: SnackPosition.BOTTOM,
            );
          }

          // Cancel the timer as we're navigating away
          _checkActivationTimer?.cancel();
          debugPrint('Activation polling timer cancelled');

          // Store activation data in Firebase if available

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
          
          // Use ExpirationService for consistent notification handling
          final ExpirationService expirationService = ExpirationService();
          
          // Show appropriate notification based on expiration status
          if (isExpiringSoon && daysRemaining != null) {
            // Show expiration warning using ExpirationService
            expirationService.showExpirationNotification(tempUser);
          } else {
            // Show success notification
            Get.snackbar(
              'Activation Successful!',
              'Your device has been activated successfully.',
              snackPosition: SnackPosition.TOP,
              backgroundColor: Colors.green.withOpacity(0.7),
              colorText: Colors.white,
              duration: const Duration(seconds: 3),
            );
          }

          // Add a small delay before navigation to ensure the snackbar is shown
          await Future.delayed(const Duration(milliseconds: 800));

          // Navigate to welcome screen using direct navigation to ensure it works
          debugPrint('Navigating to welcome screen...');
          // Force navigation to welcome screen
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Get.offAll(
              () => const WelcomeScreen(),
              // No specific transition to avoid conflicts
            );
          });
          
          // Log successful navigation
          debugPrint('Navigation to welcome screen completed');
        } else if (data['status'] == 'expired') {
          // Show expired notification
          Get.snackbar(
            'Subscription Expired',
            'Your subscription has expired. Please renew to continue using the service.',
            snackPosition: SnackPosition.TOP,
            backgroundColor: Colors.red.withOpacity(0.7),
            colorText: Colors.white,
            duration: const Duration(seconds: 5),
          );
          debugPrint(
              'Device subscription expired: ${data['message'] ?? 'No message provided'}');
        } else {
          debugPrint(
              'Device not activated yet: ${data['message'] ?? 'No message provided'}');
        }
      } else {
        debugPrint('API request failed with status: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error checking activation status: $e');
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
                        'After activation on the website, your device will automatically connect to your IPTV service.',
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
                            debugPrint('Device activated successfully');
                          }
                        },
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
