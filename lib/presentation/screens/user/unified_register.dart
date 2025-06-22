part of '../screens.dart';

/// A unified registration screen that works for both TV and mobile interfaces
class UnifiedRegisterScreen extends StatefulWidget {
  const UnifiedRegisterScreen({super.key});

  @override
  State<UnifiedRegisterScreen> createState() => _UnifiedRegisterScreenState();
}

class _UnifiedRegisterScreenState extends State<UnifiedRegisterScreen> {
  // Controllers for all input fields
  final _username = TextEditingController();
  final _password = TextEditingController();
  final _domain = TextEditingController();
  final _playlistName = TextEditingController();
  final _fullUrl = TextEditingController(); // For M3U conversion

  // Focus management
  int _focusedIndex = 0;
  final List<FocusNode> _focusNodes = List.generate(4, (_) => FocusNode());
  final FocusNode _remoteFocus = FocusNode();
  
  // Platform detection - detect if we're on TV or mobile
  // For now, we'll use a simple flag that can be toggled for testing
  bool get _isTvMode => false; // Default to mobile UI

  @override
  void initState() {
    super.initState();
    // Request focus on first field for TV mode
    if (_isTvMode) {
      _focusNodes[0].requestFocus();
    }
  }

  @override
  void dispose() {
    // Dispose all controllers
    _username.dispose();
    _password.dispose();
    _domain.dispose();
    _playlistName.dispose();
    _fullUrl.dispose();
    
    // Dispose all focus nodes
    for (var node in _focusNodes) {
      node.dispose();
    }
    _remoteFocus.dispose();
    
    super.dispose();
  }

  // Handle keyboard navigation for TV mode
  void _handleKeyEvent(RawKeyEvent event) {
    if (!_isTvMode) return;
    
    if (event.isKeyPressed(LogicalKeyboardKey.arrowDown)) {
      setState(() {
        _focusedIndex = (_focusedIndex + 1).clamp(0, 4);
        if (_focusedIndex < 4) {
          _focusNodes[_focusedIndex].requestFocus();
        }
      });
    } else if (event.isKeyPressed(LogicalKeyboardKey.arrowUp)) {
      setState(() {
        _focusedIndex = (_focusedIndex - 1).clamp(0, 4);
        if (_focusedIndex < 4) {
          _focusNodes[_focusedIndex].requestFocus();
        }
      });
    } else if (event.isKeyPressed(LogicalKeyboardKey.select) && _focusedIndex == 4) {
      _login();
    }
  }

  // Convert M3U to Xtream format
  void _convertM3uToXtream() {
    showDialog(
      context: context,
      builder: (_) => CupertinoAlertDialog(
        title: const Text('Paste your M3U Link'),
        content: Material(
          color: Colors.transparent,
          child: TextField(
            controller: _fullUrl,
            decoration: InputDecoration(
              hintText: "http://domain.tr:8080?get.php/username=test&password=123",
              hintStyle: Get.textTheme.bodyMedium!.copyWith(
                color: Colors.grey,
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              _fullUrl.clear();
              Get.back();
            },
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (_fullUrl.text.isNotEmpty) {
                try {
                  final uri = Uri.parse(_fullUrl.text);
                  final username = uri.queryParameters['username'] ?? '';
                  final password = uri.queryParameters['password'] ?? '';
                  final host = '${uri.scheme}://${uri.host}:${uri.port}';
                  
                  _username.text = username;
                  _password.text = password;
                  _domain.text = host;
                }
                catch (e) {
                  debugPrint('Error parsing URL: $e');
                }
              }
              Get.back();
            },
            child: const Text('Convert'),
          ),
        ],
      ),
    );
  }

  // Login with provided credentials
  void _login() {
    if (_username.text.isNotEmpty &&
        _password.text.isNotEmpty &&
        _domain.text.isNotEmpty) {
      context.read<AuthBloc>().add(AuthRegister(
            _username.text,
            _password.text,
            _domain.text,
            playlistName: _playlistName.text,
          ));
    } else {
      showWarningToast(
        context,
        'Missing information',
        'Please fill in all required fields',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Wrap with RawKeyboardListener for TV mode
    Widget content = Scaffold(
      body: Container(
        width: getSize(context).width,
        height: getSize(context).height,
        decoration: kDecorBackground,
        child: BlocBuilder<SettingsCubit, SettingsState>(
          builder: (context, stateSetting) {
            return SafeArea(
              child: BlocConsumer<AuthBloc, AuthState>(
                listener: (context, state) {
                  if (state is AuthFailed) {
                    showWarningToast(
                      context,
                      'Login failed.',
                      'Please check your IPTV credentials and try again.',
                    );
                  } else if (state is AuthSuccess) {
                    context.read<LiveCatyBloc>().add(GetLiveCategories());
                    context.read<MovieCatyBloc>().add(GetMovieCategories());
                    context.read<SeriesCatyBloc>().add(GetSeriesCategories());
                    Get.offAndToNamed(screenWelcome);
                  }
                },
                builder: (context, state) {
                  final isLoading = state is AuthLoading;

                  return IgnorePointer(
                    ignoring: isLoading,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header with back button (only for mobile)
                        if (!_isTvMode)
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
                              Row(
                                children: [
                                  TextButton.icon(
                                    onPressed: _convertM3uToXtream,
                                    icon: const Icon(
                                      FontAwesomeIcons.fileImport,
                                      color: Colors.white,
                                      size: 18,
                                    ),
                                    label: Text(
                                      'Import M3U',
                                      style: Get.textTheme.bodyMedium!.copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        
                        // Main content
                        Expanded(
                          child: Center(
                            child: SingleChildScrollView(
                              padding: EdgeInsets.symmetric(
                                horizontal: _isTvMode ? 40 : 20,
                              ),
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(maxWidth: 700),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    // Logo
                                    Image.asset(
                                      kIconSplash,
                                      width: _isTvMode ? 120 : 80,
                                      height: _isTvMode ? 120 : 80,
                                    ),
                                    SizedBox(height: _isTvMode ? 30 : 20),
                                    
                                    // Title
                                    Text(
                                      'Sign In to IPTV',
                                      style: Get.textTheme.headlineMedium!.copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    
                                    // Subtitle
                                    Text(
                                      'Enter your IPTV credentials to access all content',
                                      textAlign: TextAlign.center,
                                      style: Get.textTheme.bodyLarge!.copyWith(
                                        color: Colors.white70,
                                      ),
                                    ),
                                    SizedBox(height: _isTvMode ? 40 : 30),
                                    
                                    // Form fields
                                    _buildInputField(
                                      controller: _username,
                                      hintText: "Username",
                                      icon: FontAwesomeIcons.solidUser,
                                      focusNode: _focusNodes[0],
                                      index: 0,
                                    ),
                                    SizedBox(height: _isTvMode ? 20 : 15),
                                    
                                    _buildInputField(
                                      controller: _password,
                                      hintText: "Password",
                                      icon: FontAwesomeIcons.lock,
                                      focusNode: _focusNodes[1],
                                      index: 1,
                                      isPassword: true,
                                    ),
                                    SizedBox(height: _isTvMode ? 20 : 15),
                                    
                                    _buildInputField(
                                      controller: _domain,
                                      hintText: "http://url.domain.net:8080",
                                      icon: FontAwesomeIcons.link,
                                      focusNode: _focusNodes[2],
                                      index: 2,
                                    ),
                                    SizedBox(height: _isTvMode ? 20 : 15),
                                    
                                    _buildInputField(
                                      controller: _playlistName,
                                      hintText: "Playlist Name",
                                      icon: FontAwesomeIcons.list,
                                      focusNode: _focusNodes[3],
                                      index: 3,
                                    ),
                                    SizedBox(height: _isTvMode ? 40 : 30),
                                    
                                    // Login button
                                    _buildLoginButton(),
                                    
                                    // Loading indicator
                                    if (isLoading)
                                      const Padding(
                                        padding: EdgeInsets.only(top: 20),
                                        child: CircularProgressIndicator(),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            );
          },
        ),
      ),
    );

    // Wrap with RawKeyboardListener for TV mode
    if (_isTvMode) {
      return RawKeyboardListener(
        focusNode: _remoteFocus,
        onKey: _handleKeyEvent,
        child: content,
      );
    }

    return content;
  }

  // Build responsive input field that works for both TV and mobile
  Widget _buildInputField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    required FocusNode focusNode,
    required int index,
    bool isPassword = false,
  }) {
    final bool isFocused = _focusedIndex == index;
    
    if (_isTvMode) {
      // TV-style input with focus highlight
      // TV-style input with focus highlight
      return Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isFocused ? kColorPrimary : Colors.transparent,
            width: 2,
          ),
          color: Colors.grey.shade900,
        ),
        child: TextField(
          controller: controller,
          focusNode: focusNode,
          obscureText: isPassword,
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: TextStyle(color: Colors.grey.shade600),
            prefixIcon: Icon(icon, color: isFocused ? kColorPrimary : Colors.grey),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 16),
          ),
          style: const TextStyle(color: Colors.white, fontSize: 18),
          onTap: () {
            setState(() {
              _focusedIndex = index;
            });
          },
        ),
      );
    } else {
      // Mobile-style input
      return TextField(
        controller: controller,
        focusNode: focusNode,
        obscureText: isPassword,
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: Get.textTheme.bodyMedium!.copyWith(color: Colors.grey),
          suffixIcon: Icon(icon, size: 18, color: kColorPrimary),
          enabledBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: Colors.grey.shade700),
          ),
          focusedBorder: const UnderlineInputBorder(
            borderSide: BorderSide(color: kColorPrimary, width: 2),
          ),
        ),
        style: Get.textTheme.bodyMedium!.copyWith(
          color: Colors.white,
          fontSize: 16.sp,
          fontWeight: FontWeight.bold,
        ),
      );
    }
  }

  // Build login button that works for both TV and mobile
  Widget _buildLoginButton() {
    final bool isFocused = _focusedIndex == 4;
    
    return GestureDetector(
      onTap: _login,
      child: Container(
        width: _isTvMode ? 300 : double.infinity,
        height: _isTvMode ? 60 : 50,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF5F72BE), Color(0xFF9921E8)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(10),
          border: _isTvMode && isFocused
              ? Border.all(color: Colors.white, width: 2)
              : null,
        ),
        child: Center(
          child: Text(
            'SIGN IN',
            style: TextStyle(
              color: Colors.white,
              fontSize: _isTvMode ? 18 : 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}
