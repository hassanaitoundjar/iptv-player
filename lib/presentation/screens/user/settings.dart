part of '../screens.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final TextEditingController _pinController = TextEditingController();
  bool _isPinVisible = false;
  
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
                              SizedBox(height: 5.h),
                              SizedBox(
                                width: 30.w,
                                child: CardButtonWatchMovie(
                                  title: "Set Playlist PIN",
                                  onTap: () {
                                    _showPinDialog(context, userInfo);
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
                                    Get.offAllNamed("/");
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
                  style: Get.textTheme.bodyMedium!.copyWith(color: Colors.white),
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
                        _isPinVisible ? FontAwesomeIcons.eyeSlash : FontAwesomeIcons.eye,
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
                      const SnackBar(content: Text('PIN must contain only numbers')),
                    );
                    return;
                  }
                  
                  // Get playlist name
                  String playlistName = user.userInfo?.playlistName ?? '';
                  
                  // Save PIN for this specific playlist
                  bool success = await LocaleApi.updatePlaylistPin(pin, playlistName);
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
}
