part of '../screens.dart';

class UserInfoScreen extends StatefulWidget {
  const UserInfoScreen({Key? key}) : super(key: key);

  @override
  State<UserInfoScreen> createState() => _UserInfoScreenState();
}

class _UserInfoScreenState extends State<UserInfoScreen> {
  bool isLoading = true;
  UserModel? user;
  int? daysRemaining;
  bool isExpiringSoon = false;

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    final authState = context.read<AuthBloc>().state;

    if (authState is AuthSuccess) {
      setState(() {
        user = authState.user;
        daysRemaining = getDaysRemaining(user!);
        isExpiringSoon = isSubscriptionExpiringSoon(user!);
        isLoading = false;
      });
    } else {
      setState(() => isLoading = false);
    }
  }

  // Helper method to check if subscription is expiring soon (within 3 days)
  bool isSubscriptionExpiringSoon(UserModel user, {int daysThreshold = 3}) {
    if (user.userInfo?.expDate == null) return false;

    try {
      final int? unixTime = int.tryParse(user.userInfo!.expDate!);
      if (unixTime == null) return false;

      final DateTime expirationDate =
          DateTime.fromMillisecondsSinceEpoch(unixTime * 1000);
      final DateTime now = DateTime.now();
      final int daysRemaining = expirationDate.difference(now).inDays;
      return daysRemaining <= daysThreshold && daysRemaining >= 0;
    } catch (e) {
      print('Error checking subscription expiration: $e');
      return false;
    }
  }

  // Helper method to get days remaining until subscription expires
  int? getDaysRemaining(UserModel user) {
    if (user.userInfo?.expDate == null) return null;

    try {
      final int? unixTime = int.tryParse(user.userInfo!.expDate!);
      if (unixTime == null) return null;

      final DateTime expirationDate =
          DateTime.fromMillisecondsSinceEpoch(unixTime * 1000);
      final DateTime now = DateTime.now();
      return expirationDate.difference(now).inDays;
    } catch (e) {
      print('Error calculating days remaining: $e');
      return null;
    }
  }

  Widget _buildInfoRow(String label, String? value,
      {bool isImportant = false}) {
    if (value == null || value.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: Get.textTheme.bodyMedium!.copyWith(
                color: Colors.white70,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: Get.textTheme.bodyLarge!.copyWith(
                color: isImportant ? kColorPrimary : Colors.white,
                fontWeight: isImportant ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(child: LoadingWidget()),
      );
    }

    if (user == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Account Information'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Center(
          child: Text(
            'No user information available',
            style: Get.textTheme.titleMedium!.copyWith(color: Colors.white70),
          ),
        ),
      );
    }

    final userInfo = user!.userInfo;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Account Information'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Container(
        decoration: kDecorBackground,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Account Section
              Card(
                color: kColorCardLight,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.person, color: kColorPrimary),
                          const SizedBox(width: 8),
                          Text(
                            'Account Details',
                            style: Get.textTheme.titleLarge!.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Spacer(),
                          // Refresh button to update live, VOD, and series data
                          IconButton(
                            icon: const Icon(Icons.refresh, color: kColorPrimary),
                            onPressed: () {
                              // Show loading indicator
                              Get.snackbar(
                                'Refreshing',
                                'Updating live, VOD, and series data...',
                                snackPosition: SnackPosition.BOTTOM,
                                duration: const Duration(seconds: 2),
                              );
                              
                              // Update live categories
                              context.read<LiveCatyBloc>().add(GetLiveCategories());
                              
                              // Update movie categories
                              context.read<MovieCatyBloc>().add(GetMovieCategories());
                              
                              // Update series categories
                              context.read<SeriesCatyBloc>().add(GetSeriesCategories());
                              
                              // Show success message after a short delay
                              Future.delayed(const Duration(seconds: 2), () {
                                Get.snackbar(
                                  'Success',
                                  'Data refreshed successfully',
                                  snackPosition: SnackPosition.BOTTOM,
                                  backgroundColor: Colors.green.withOpacity(0.7),
                                  colorText: Colors.white,
                                );
                              });
                            },
                            tooltip: 'Refresh Data',
                          ),
                        ],
                      ),
                      const Divider(color: Colors.white24),
                      const SizedBox(height: 8),
                      _buildInfoRow("Username", userInfo?.username),
                      _buildInfoRow('Status', userInfo?.status),
                      _buildInfoRow(
                          'Max Connections', userInfo?.maxConnections),
                      _buildInfoRow(
                          'Expiration', expirationDate(userInfo?.expDate)),
                      if (userInfo?.playlistName != null)
                        _buildInfoRow('Playlist_Name', userInfo?.playlistName),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Subscription Section
              Card(
                color: kColorCardLight,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.calendar_today,
                              color: kColorPrimary),
                          const SizedBox(width: 8),
                          Text(
                            'Subscription',
                            style: Get.textTheme.titleLarge!.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Spacer(),
                          if (isExpiringSoon && daysRemaining != null)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: daysRemaining! <= 1
                                    ? Colors.red
                                    : Colors.orange,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                daysRemaining == 0
                                    ? 'Expires Today!'
                                    : 'Expires in $daysRemaining days',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const Divider(color: Colors.white24),
                      const SizedBox(height: 8),
                      _buildInfoRow(
                        'Expiration Date',
                        userInfo?.expDate != null
                            ? expirationDate(userInfo!.expDate!)
                            : 'N/A',
                        isImportant: true,
                      ),
                      _buildInfoRow('Trial Account',
                          userInfo?.isTrial == '1' ? 'Yes' : 'No'),
                    ],
                  ),
                ),
              ),

              // Server Info section removed as requested

              const SizedBox(height: 24),

              // Help/Support Section
              Center(
                child: TextButton.icon(
                  onPressed: () {
                    // Contact support functionality
                    Get.snackbar(
                      'Contact Support',
                      'Support feature will be implemented soon.',
                      snackPosition: SnackPosition.BOTTOM,
                    );
                  },
                  icon: const Icon(Icons.help_outline, color: kColorPrimary),
                  label: Text(
                    'Need Help? Contact Support',
                    style: Get.textTheme.bodyMedium!
                        .copyWith(color: kColorPrimary),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
