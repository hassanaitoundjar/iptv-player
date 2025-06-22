part of '../screens.dart';

class UsersListScreen extends StatefulWidget {
  const UsersListScreen({super.key});

  @override
  State<UsersListScreen> createState() => _UsersListScreenState();
}

class _UsersListScreenState extends State<UsersListScreen> {
  Map<String, dynamic> usersList = {};
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() {
      isLoading = true;
    });
    
    final users = await LocaleApi.getSavedUsers();
    
    setState(() {
      usersList = users;
      isLoading = false;
    });
  }

  Future<void> _loginWithUser(Map<String, dynamic> userData) async {
    if (userData['username'] != null && 
        userData['password'] != null && 
        userData['server_url'] != null) {
      
      String playlistName = userData['playlist_name'] ?? userData['username'];
      
      // Check if this playlist is PIN protected
      bool isPinProtected = await LocaleApi.isPlaylistPinProtected(playlistName);
      
      if (isPinProtected) {
        // Create a temporary user model for PIN verification
        UserModel tempUser = UserModel.fromJson({
          'user_info': {
            'username': userData['username'],
            'password': userData['password'],
            'playlist_name': playlistName,
          },
          'server_info': {
            'url': userData['server_url'],
          }
        }, userData['server_url']);
        
        // Show PIN verification screen
        bool verified = await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => PinVerificationScreen(
            user: tempUser,
            onVerificationComplete: (success) {
              Navigator.pop(context, success);
            },
          ),
        ) ?? false;
        
        if (!verified) {
          // PIN verification failed or was cancelled
          return;
        }
      }
      
      // PIN verification passed or not required, proceed with login
      context.read<AuthBloc>().add(AuthRegister(
        userData['username'],
        userData['password'],
        userData['server_url'],
        playlistName: playlistName,
      ));
      
      // Navigate back to welcome screen after login
      Get.offAllNamed(screenWelcome);
    }
  }

  Future<void> _deleteUser(String userId) async {
    await LocaleApi.removeUserFromList(userId);
    _loadUsers();
  }

  Widget _buildUserCard({
    required Map<String, dynamic> userData,
    required String userId,
    required bool isTV,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: isTV ? 20 : 12),
      decoration: BoxDecoration(
        color: kColorCardLight,
        borderRadius: BorderRadius.circular(isTV ? 12 : 8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => _loginWithUser(userData),
        borderRadius: BorderRadius.circular(isTV ? 12 : 8),
        child: Padding(
          padding: EdgeInsets.all(isTV ? 20 : 16),
          child: Row(
            children: [
              // User icon
              Container(
                width: isTV ? 70 : 50,
                height: isTV ? 70 : 50,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: kColorPrimary.withOpacity(0.2),
                ),
                child: Icon(
                  Icons.person,
                  color: kColorPrimary,
                  size: isTV ? 40 : 30,
                ),
              ),
              SizedBox(width: isTV ? 20 : 12),
              // User info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      userData['playlist_name'] ?? userData['username'] ?? 'Unknown',
                      style: Get.textTheme.titleMedium!.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: isTV ? 22 : null,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Username: ${userData['username'] ?? 'N/A'}',
                      style: Get.textTheme.bodyMedium!.copyWith(
                        color: Colors.white70,
                        fontSize: isTV ? 16 : null,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Server: ${userData['server_url'] ?? 'N/A'}',
                      style: Get.textTheme.bodyMedium!.copyWith(
                        color: Colors.white70,
                        fontSize: isTV ? 16 : null,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              // Action buttons
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildActionButton(
                    icon: Icons.login,
                    color: kColorPrimary,
                    onTap: () => _loginWithUser(userData),
                    isTV: isTV,
                  ),
                  SizedBox(width: isTV ? 16 : 8),
                  _buildActionButton(
                    icon: Icons.delete,
                    color: Colors.redAccent,
                    onTap: () => _deleteUser(userId),
                    isTV: isTV,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    required bool isTV,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(isTV ? 12 : 8),
      child: Container(
        padding: EdgeInsets.all(isTV ? 12 : 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(isTV ? 12 : 8),
        ),
        child: Icon(
          icon,
          color: color,
          size: isTV ? 28 : 24,
        ),
      ),
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
                          'Saved Users',
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
                    child: isLoading
                      ? Center(
                          child: CircularProgressIndicator(
                            color: Colors.purpleAccent,
                          ),
                        )
                      : usersList.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.people_outline,
                                  size: isTV ? 80 : 60,
                                  color: Colors.white.withOpacity(0.5),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No saved users found',
                                  style: Get.textTheme.titleLarge!.copyWith(
                                    color: Colors.white,
                                    fontSize: isTV ? 24 : null,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Register or login to add users',
                                  style: Get.textTheme.bodyLarge!.copyWith(
                                    color: Colors.white70,
                                    fontSize: isTV ? 18 : null,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : SingleChildScrollView(
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
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Header
                                    if (usersList.isNotEmpty) ...[
                                      Text(
                                        'Select a User to Login',
                                        style: Get.textTheme.headlineSmall!.copyWith(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: isTV ? 26 : null,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Tap on a user card to login or use the action buttons',
                                        style: Get.textTheme.bodyLarge!.copyWith(
                                          color: Colors.white70,
                                          fontSize: isTV ? 18 : null,
                                        ),
                                      ),
                                      SizedBox(height: isTV ? 30 : 20),
                                    ],
                                    
                                    // User cards
                                    ...usersList.entries.map((entry) {
                                      final userId = entry.key;
                                      final userData = entry.value;
                                      
                                      return _buildUserCard(
                                        userData: userData,
                                        userId: userId,
                                        isTV: isTV,
                                      );
                                    }).toList(),
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
}
