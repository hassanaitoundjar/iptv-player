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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Saved Users',
          style: Get.textTheme.titleLarge!.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: kColorPrimary,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Get.back(),
        ),
      ),
      body: Ink(
        width: 100.w,
        height: 100.h,
        decoration: kDecorBackground,
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : usersList.isEmpty
                ? Center(
                    child: Text(
                      'No saved users found',
                      style: Get.textTheme.titleMedium!.copyWith(
                        color: Colors.white,
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: usersList.length,
                    itemBuilder: (context, index) {
                      final userId = usersList.keys.elementAt(index);
                      final userData = usersList[userId];
                      
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: kColorCardLight,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          title: Text(
                            userData['playlist_name'] ?? userData['username'] ?? 'Unknown',
                            style: Get.textTheme.titleMedium!.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Username: ${userData['username'] ?? 'N/A'}',
                                style: Get.textTheme.bodyMedium!.copyWith(
                                  color: Colors.white70,
                                ),
                              ),
                              Text(
                                'Server: ${userData['server_url'] ?? 'N/A'}',
                                style: Get.textTheme.bodyMedium!.copyWith(
                                  color: Colors.white70,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(
                                  Icons.login,
                                  color: kColorPrimary,
                                ),
                                onPressed: () => _loginWithUser(userData),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.delete,
                                  color: Colors.redAccent,
                                ),
                                onPressed: () => _deleteUser(userId),
                              ),
                            ],
                          ),
                          onTap: () => _loginWithUser(userData),
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}
