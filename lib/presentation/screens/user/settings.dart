part of '../screens.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final TextEditingController _pinController = TextEditingController();
  final ParentalControlService _parentalControlService =
      ParentalControlService();
  bool _isParentalControlEnabled = false;
  bool _isParentalPinSet = false;
  bool _isPinVisible = false;

  @override
  void initState() {
    super.initState();
    _loadParentalControlSettings();
  }

  Future<void> _loadParentalControlSettings() async {
    _isParentalControlEnabled = await _parentalControlService.isEnabled();
    _isParentalPinSet = await _parentalControlService.isPinSet();
    setState(() {});
  }

  // Helper method to build settings card with icon and title
  Widget _buildSettingsCard({
    required String title,
    required IconData icon,
    required Function() onTap,
    bool isFocused = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(15),
      focusColor: kColorFocus,
      autofocus: isFocused,
      child: Ink(
        decoration: BoxDecoration(
          color: kColorCardLight,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 30,
              color: Colors.white,
            ),
            const SizedBox(height: 15),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Get.textTheme.titleMedium!.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper for detail row in dialog
  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "$label: ",
            style: Get.textTheme.bodyMedium!.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Get.textTheme.bodyMedium!.copyWith(color: Colors.white70),
            ),
          ),
        ],
      ),
    );
  }

  // Show parental control dialog
  void _showParentalControlDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: kColorCardDark,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: Row(
            children: [
              Icon(
                FontAwesomeIcons.shieldAlt,
                color: kColorPrimary,
                size: 24,
              ),
              SizedBox(width: 10),
              Text(
                "Parental Controls",
                style: Get.textTheme.titleLarge!.copyWith(color: Colors.white),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Enable or disable parental controls to restrict access to adult content.',
                style: Get.textTheme.bodyMedium!.copyWith(
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 20),
              // Enable/Disable Parental Control
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Enable Parental Control",
                    style:
                        Get.textTheme.bodyMedium!.copyWith(color: Colors.white),
                  ),
                  Switch(
                    value: _isParentalControlEnabled,
                    onChanged: (value) async {
                      if (value && !_isParentalPinSet) {
                        // Show PIN setup dialog if enabling and PIN not set
                        final pinSet = await _parentalControlService
                            .showPinSetupDialog(context);
                        if (pinSet) {
                          setState(() {
                            _isParentalControlEnabled = true;
                            _isParentalPinSet = true;
                          });
                          // Also update the parent state
                          this.setState(() {
                            _isParentalControlEnabled = true;
                            _isParentalPinSet = true;
                          });
                        }
                      } else {
                        await _parentalControlService.setEnabled(value);
                        setState(() {
                          _isParentalControlEnabled = value;
                        });
                        // Also update the parent state
                        this.setState(() {
                          _isParentalControlEnabled = value;
                        });
                      }
                    },
                    activeColor: kColorPrimary,
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // Change PIN section
              if (_isParentalPinSet)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Change Parental PIN',
                      style: Get.textTheme.bodyMedium!.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: () {
                        Get.back();
                        _showChangeParentalPinDialog();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kColorPrimary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        minimumSize: Size(double.infinity, 45),
                      ),
                      child: Text(
                        "Change Parental PIN",
                        style: Get.textTheme.bodyMedium!
                            .copyWith(color: Colors.white),
                      ),
                    ),
                  ],
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Get.back(),
              child: Text(
                "CANCEL",
                style: Get.textTheme.bodyMedium!.copyWith(
                  color: Colors.white70,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            TextButton(
              onPressed: () => Get.back(),
              child: Text(
                "SAVE",
                style: Get.textTheme.bodyMedium!.copyWith(
                  color: kColorPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // This method was removed as it was a duplicate of the existing _showChangeParentalPinDialog method

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Ink(
        width: 100.w,
        height: 100.h,
        decoration: kDecorBackground,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        child: BlocBuilder<AuthBloc, AuthState>(
          builder: (context, state) {
            if (state is AuthSuccess) {
              final userInfo = state.user;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // App Bar with title and date
                  Row(
                    children: [
                      const AppBarSettings(),
                      const Spacer(),
                      Text(
                        dateNowWelcome(),
                        style: Get.textTheme.titleSmall!
                            .copyWith(color: Colors.white),
                      ),
                      const SizedBox(width: 20),
                    ],
                  ),

                  // Settings cards grid
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        // Determine number of cards per row based on screen width
                        final double screenWidth = constraints.maxWidth;
                        final int cardsPerRow =
                            screenWidth > 600 ? 4 : (screenWidth > 400 ? 3 : 2);

                        return GridView(
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: cardsPerRow,
                            childAspectRatio: 1.0,
                            crossAxisSpacing: 10,
                            mainAxisSpacing: 10,
                          ),
                          children: [
                            // General Settings Card
                            _buildSettingsCard(
                              title: "General Settings",
                              icon: FontAwesomeIcons.cog,
                              onTap: () {
                                Get.toNamed(screenUserInfo);
                              },
                            ),

                            // Refresh Data Card
                            _buildSettingsCard(
                              title: "Refresh Data",
                              icon: FontAwesomeIcons.sync,
                              onTap: () {
                                context
                                    .read<LiveCatyBloc>()
                                    .add(GetLiveCategories());
                                context
                                    .read<MovieCatyBloc>()
                                    .add(GetMovieCategories());
                                context
                                    .read<SeriesCatyBloc>()
                                    .add(GetSeriesCategories());
                                Get.back(); // Return to welcome screen after refreshing data
                              },
                            ),

                            // Parental Control Card
                            _buildSettingsCard(
                              title: "Parental Control",
                              icon: FontAwesomeIcons.shieldAlt,
                              onTap: () {
                                _showParentalControlDialog(context);
                              },
                            ),

                            // PIN Protection Card
                            _buildSettingsCard(
                              title: "Playlist PIN",
                              icon: FontAwesomeIcons.lock,
                              onTap: () {
                                _showPinDialog(context, userInfo);
                              },
                            ),

                            // User List Card
                            _buildSettingsCard(
                              title: "User List",
                              icon: FontAwesomeIcons.users,
                              onTap: () {
                                Get.toNamed(screenUsersList);
                              },
                            ),

                            // Add New User Card
                            _buildSettingsCard(
                              title: "Add New User",
                              icon: FontAwesomeIcons.userPlus,
                              onTap: () {
                                context.read<AuthBloc>().add(AuthLogOut());
                                Get.offAllNamed("/");
                              },
                            ),

                            // Logout Card
                            _buildSettingsCard(
                              title: "Logout",
                              icon: FontAwesomeIcons.signOutAlt,
                              onTap: () {
                                context.read<AuthBloc>().add(AuthLogOut());
                                Get.offAllNamed(screenIntro);
                                Get.reload();
                              },
                            ),
                          ],
                        );
                      },
                    ),
                  ),

                  // Footer
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'CreatedBy:',
                        style: Get.textTheme.titleSmall!.copyWith(
                          fontSize: 12.sp,
                          color: Colors.grey,
                        ),
                      ),
                      InkWell(
                        onTap: () async {
                          await launchUrlString(
                            "https://mouadzizi.me",
                            mode: LaunchMode.externalApplication,
                          );
                        },
                        child: Text(
                          ' @Azul Mouad',
                          style: Get.textTheme.titleSmall!.copyWith(
                            fontSize: 12.sp,
                            color: Colors.blue,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              );
            }
            return const SizedBox();
          },
        ),
      ),
    );
  }

  void _showPinDialog(BuildContext context, UserModel user) async {
    // Get the playlist name
    String playlistName = user.userInfo?.playlistName ?? '';

    // Pre-fill with existing PIN for this specific playlist
    String pin = await LocaleApi.getPlaylistPin(playlistName);
    _pinController.text = pin;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            backgroundColor: kColorCardLight,
            title: Text(
              'Playlist PIN Lock',
              style: Get.textTheme.titleMedium!.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Set a PIN to protect your playlist. Leave empty to disable PIN protection.',
                  style: Get.textTheme.bodyMedium!.copyWith(
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _pinController,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  obscureText: !_isPinVisible,
                  style:
                      Get.textTheme.bodyMedium!.copyWith(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: "Enter PIN (numbers only)",
                    hintStyle: Get.textTheme.bodyMedium!.copyWith(
                      color: Colors.grey,
                    ),
                    counterStyle: Get.textTheme.bodySmall!.copyWith(
                      color: Colors.white70,
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _isPinVisible
                            ? FontAwesomeIcons.eyeSlash
                            : FontAwesomeIcons.eye,
                        size: 18,
                        color: kColorPrimary,
                      ),
                      onPressed: () {
                        setState(() {
                          _isPinVisible = !_isPinVisible;
                        });
                      },
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
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
                  // Validate PIN (only numbers allowed)
                  String pin = _pinController.text.trim();
                  if (pin.isNotEmpty && !RegExp(r'^\d+$').hasMatch(pin)) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('PIN must contain only numbers')),
                    );
                    return;
                  }

                  // Get playlist name
                  String playlistName = user.userInfo?.playlistName ?? '';

                  // Save PIN for this specific playlist
                  bool success =
                      await LocaleApi.updatePlaylistPin(pin, playlistName);
                  if (success) {
                    // Update the bloc state to reflect changes
                    context.read<AuthBloc>().add(AuthGetUser());

                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          pin.isEmpty
                              ? 'PIN protection disabled'
                              : 'Playlist PIN updated successfully',
                        ),
                        backgroundColor: kColorPrimary,
                      ),
                    );
                  } else {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Failed to update PIN'),
                        backgroundColor: Colors.red,
                      ),
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
          );
        },
      ),
    );
  }

  // Show dialog to change parental control PIN
  void _showChangeParentalPinDialog() {
    final TextEditingController oldPinController = TextEditingController();
    final TextEditingController newPinController = TextEditingController();
    final TextEditingController confirmPinController = TextEditingController();
    bool oldPinVisible = false;
    bool newPinVisible = false;

    Get.dialog(
      Dialog(
        backgroundColor: kColorCardLight,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        child: StatefulBuilder(
          builder: (context, setState) {
            return Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    'Change Parental Control PIN',
                    style: Get.textTheme.titleMedium!.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 15),
                  // Description
                  Text(
                    'Update your parental control PIN to protect restricted content.',
                    style: Get.textTheme.bodyMedium!.copyWith(
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Old PIN
                  TextField(
                    controller: oldPinController,
                    keyboardType: TextInputType.number,
                    maxLength: 4,
                    obscureText: !oldPinVisible,
                    style:
                        Get.textTheme.bodyMedium!.copyWith(color: Colors.white),
                    decoration: InputDecoration(
                      counterText: '',
                      hintText: 'Current PIN',
                      hintStyle: Get.textTheme.bodyMedium!.copyWith(
                        color: Colors.grey,
                      ),
                      counterStyle: Get.textTheme.bodySmall!.copyWith(
                        color: Colors.white70,
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          oldPinVisible
                              ? Icons.visibility_off
                              : Icons.visibility,
                          size: 18,
                          color: kColorPrimary,
                        ),
                        onPressed: () {
                          setState(() {
                            oldPinVisible = !oldPinVisible;
                          });
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),
                  // New PIN
                  TextField(
                    controller: newPinController,
                    keyboardType: TextInputType.number,
                    maxLength: 4,
                    obscureText: !newPinVisible,
                    style:
                        Get.textTheme.bodyMedium!.copyWith(color: Colors.white),
                    decoration: InputDecoration(
                      counterText: '',
                      hintText: 'New PIN',
                      hintStyle: Get.textTheme.bodyMedium!.copyWith(
                        color: Colors.grey,
                      ),
                      counterStyle: Get.textTheme.bodySmall!.copyWith(
                        color: Colors.white70,
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          newPinVisible
                              ? Icons.visibility_off
                              : Icons.visibility,
                          size: 18,
                          color: kColorPrimary,
                        ),
                        onPressed: () {
                          setState(() {
                            newPinVisible = !newPinVisible;
                          });
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),
                  // Confirm PIN
                  TextField(
                    controller: confirmPinController,
                    keyboardType: TextInputType.number,
                    maxLength: 4,
                    obscureText: !newPinVisible,
                    style:
                        Get.textTheme.bodyMedium!.copyWith(color: Colors.white),
                    decoration: InputDecoration(
                      counterText: '',
                      hintText: 'Confirm New PIN',
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
                          // Validate inputs
                          if (oldPinController.text.length != 4 ||
                              newPinController.text.length != 4 ||
                              confirmPinController.text.length != 4) {
                            Get.snackbar(
                              'Invalid PIN',
                              'All PINs must be 4 digits.',
                              backgroundColor: Colors.red,
                              colorText: Colors.white,
                              snackPosition: SnackPosition.BOTTOM,
                            );
                            return;
                          }

                          if (newPinController.text !=
                              confirmPinController.text) {
                            Get.snackbar(
                              'PIN Mismatch',
                              'New PIN and confirmation do not match.',
                              backgroundColor: Colors.red,
                              colorText: Colors.white,
                              snackPosition: SnackPosition.BOTTOM,
                            );
                            return;
                          }

                          // Try to reset PIN
                          final success =
                              await _parentalControlService.resetPin(
                                  oldPinController.text, newPinController.text);

                          if (success) {
                            Get.back();
                            Get.snackbar(
                              'PIN Changed',
                              'Your parental control PIN has been updated.',
                              backgroundColor: Colors.green,
                              colorText: Colors.white,
                              snackPosition: SnackPosition.BOTTOM,
                            );
                          } else {
                            Get.snackbar(
                              'Incorrect PIN',
                              'The current PIN you entered is incorrect.',
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
            );
          },
        ),
      ),
      barrierDismissible: false,
    );
  }
}
