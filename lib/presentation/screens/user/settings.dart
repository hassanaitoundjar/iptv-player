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
  bool _isPinVisible = false;
  bool _isParentalControlEnabled = false;
  bool _isParentalPinSet = false;

  @override
  void initState() {
    super.initState();
    _loadParentalControlSettings();
  }

  Future<void> _loadParentalControlSettings() async {
    final isEnabled = await _parentalControlService.isEnabled();
    final isPinSet = await _parentalControlService.isPinSet();

    setState(() {
      _isParentalControlEnabled = isEnabled;
      _isParentalPinSet = isPinSet;
    });
  }

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
                  const AppBarSettings(),
                  SizedBox(height: 5.h),
                  Expanded(
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            children: [
                              Expanded(
                                child: Container(
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    color: kColorCardLight,
                                    borderRadius: BorderRadius.circular(5),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 20,
                                    horizontal: 20,
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        dateNowWelcome(),
                                        style: Get.textTheme.titleSmall,
                                      ),
                                      const SizedBox(height: 5),
                                      if (userInfo.userInfo!.expDate != null)
                                        Text(
                                          "Expiration: ${expirationDate(userInfo.userInfo!.expDate)}",
                                          style: Get.textTheme.titleSmall!
                                              .copyWith(
                                            color: kColorHint,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10),
                              Expanded(
                                child: Container(
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    color: kColorCardLight,
                                    borderRadius: BorderRadius.circular(5),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 20,
                                    horizontal: 20,
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        "name: ${userInfo.userInfo!.username}",
                                        style: Get.textTheme.titleSmall,
                                      ),
                                      const SizedBox(height: 5),
                                      Text(
                                        "password: ${userInfo.userInfo!.password}",
                                        style: Get.textTheme.titleSmall,
                                      ),
                                      const SizedBox(height: 5),
                                      if (userInfo.serverInfo != null)
                                        Text(
                                          "Url: ${userInfo.serverInfo!.serverUrl}",
                                          style: Get.textTheme.titleSmall,
                                        ),
                                      const SizedBox(height: 5),
                                      Text(
                                        "Playlist: ${userInfo.userInfo!.playlistName ?? userInfo.userInfo!.username}",
                                        style: Get.textTheme.titleSmall,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 30.w,
                                child: CardButtonWatchMovie(
                                  isFocused: true,
                                  title: "Refresh all data",
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
                                    Get.back();
                                  },
                                ),
                              ),
                              SizedBox(height: 5.h),
                              SizedBox(
                                width: 30.w,
                                child: CardButtonWatchMovie(
                                  title: "Add New User",
                                  onTap: () {
                                    context.read<AuthBloc>().add(AuthLogOut());
                                    Get.offAllNamed("/");
                                  },
                                ),
                              ),
                              const SizedBox(height: 10),
                              SizedBox(
                                width: 30.w,
                                child: CardButtonWatchMovie(
                                  title: "Set Playlist PIN",
                                  onTap: () {
                                    _showPinDialog(context, userInfo);
                                  },
                                ),
                              ),
                              SizedBox(height: 2.h),
                              // Parental Control Section
                              Container(
                                width: 30.w,
                                decoration: BoxDecoration(
                                  color: kColorCardDark,
                                  borderRadius: BorderRadius.circular(5),
                                ),
                                padding: const EdgeInsets.all(15),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "Parental Controls",
                                      style:
                                          Get.textTheme.titleMedium!.copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 15),
                                    // Enable/Disable Parental Control
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          "Enable Parental Control",
                                          style: Get.textTheme.bodyMedium!
                                              .copyWith(
                                            color: Colors.white,
                                          ),
                                        ),
                                        Switch(
                                          value: _isParentalControlEnabled,
                                          onChanged: (value) async {
                                            if (value && !_isParentalPinSet) {
                                              // Show PIN setup dialog if enabling and PIN not set
                                              final pinSet =
                                                  await _parentalControlService
                                                      .showPinSetupDialog(
                                                          context);
                                              if (pinSet) {
                                                setState(() {
                                                  _isParentalControlEnabled =
                                                      true;
                                                  _isParentalPinSet = true;
                                                });
                                              }
                                            } else {
                                              await _parentalControlService
                                                  .setEnabled(value);
                                              setState(() {
                                                _isParentalControlEnabled =
                                                    value;
                                              });
                                            }
                                          },
                                          activeColor: kColorPrimary,
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 15),
                                    // Change PIN Button
                                    if (_isParentalPinSet)
                                      InkWell(
                                        onTap: () =>
                                            _showChangeParentalPinDialog(),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 10, horizontal: 15),
                                          decoration: BoxDecoration(
                                            color: kColorCardLight,
                                            borderRadius:
                                                BorderRadius.circular(5),
                                          ),
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                "Change Parental PIN",
                                                style: Get.textTheme.bodyMedium!
                                                    .copyWith(
                                                  color: Colors.white,
                                                ),
                                              ),
                                              const Icon(
                                                Icons.arrow_forward_ios,
                                                color: kColorPrimary,
                                                size: 16,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    const SizedBox(height: 15),
                                    // Note: Temporary unlock duration section removed
                                    // We now require PIN verification every time for adult content
                                  ],
                                ),
                              ),
                              SizedBox(height: 5.h),
                              SizedBox(
                                width: 30.w,
                                child: CardButtonWatchMovie(
                                  title: "user-list",
                                  onTap: () {
                                    Get.toNamed(screenUsersList);
                                  },
                                ),
                              ),
                              SizedBox(height: 5.h),
                              SizedBox(
                                width: 30.w,
                                child: CardButtonWatchMovie(
                                  title: "LogOut",
                                  onTap: () {
                                    context.read<AuthBloc>().add(AuthLogOut());
                                    Get.offAllNamed(screenIntro);

                                    Get.reload();
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
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
        backgroundColor: Colors.grey[900],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        child: StatefulBuilder(
          builder: (context, setState) {
            return Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.security,
                    color: Colors.amber,
                    size: 50,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Change Parental Control PIN',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Old PIN
                  TextField(
                    controller: oldPinController,
                    keyboardType: TextInputType.number,
                    maxLength: 4,
                    obscureText: !oldPinVisible,
                    style: TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      counterText: '',
                      labelText: 'Current PIN',
                      labelStyle: TextStyle(color: Colors.grey),
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
                      suffixIcon: IconButton(
                        icon: Icon(
                          oldPinVisible
                              ? Icons.visibility_off
                              : Icons.visibility,
                          color: Colors.grey,
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
                    style: TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      counterText: '',
                      labelText: 'New PIN',
                      labelStyle: TextStyle(color: Colors.grey),
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
                      suffixIcon: IconButton(
                        icon: Icon(
                          newPinVisible
                              ? Icons.visibility_off
                              : Icons.visibility,
                          color: Colors.grey,
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
                    style: TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      counterText: '',
                      labelText: 'Confirm New PIN',
                      labelStyle: TextStyle(color: Colors.grey),
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
                          'Change PIN',
                          style: TextStyle(color: Colors.black),
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
