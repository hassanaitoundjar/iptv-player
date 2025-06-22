part of '../screens.dart';

class IntroScreen extends StatefulWidget {
  const IntroScreen({super.key});

  @override
  State<IntroScreen> createState() => _IntroScreenState();
}

class _IntroScreenState extends State<IntroScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isTV = constraints.maxWidth > 1000;
          final buttonWidth = isTV ? 500.0 : constraints.maxWidth * 0.8;
          final fontSize = isTV ? 20.0 : 15.0;

          return Container(
            width: constraints.maxWidth,
            height: constraints.maxHeight,
            decoration: kDecorBackground,
            child: SafeArea(
              child: Column(
                children: [
                  const SizedBox(height: 30),

                  // Logo and title
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset(kIconSplash, width: 60, height: 60),
                      const SizedBox(width: 10),
                      Text(
                        'SMARTERS PRO',
                        style: Get.textTheme.headlineSmall!.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: isTV ? 28 : null,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),
                  Text(
                    'Choose Your Playlist Type',
                    style: Get.textTheme.titleMedium!.copyWith(
                      color: Colors.white70,
                      fontSize: isTV ? 22 : 18,
                    ),
                  ),
                  const SizedBox(height: 40),

                  // Login options
                  Expanded(
                    child: Center(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.of(context).size.width < 600
                              ? 350
                              : MediaQuery.of(context).size.width < 1000
                                  ? 600
                                  : 800, // ⬅️ TV screens
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // First row: options grid
                            Wrap(
                              spacing: 20,
                              runSpacing: 20,
                              alignment: WrapAlignment.center,
                              children: [
                                // Device Activation Button
                                _buildOptionCard(
                                  icon: Icons.play_circle_outline,
                                  title: 'ACTIVATE DEVICE',
                                  onTap: () =>
                                      Get.toNamed(screenDeviceActivation),
                                  isTV: isTV,
                                ),

                                // Player API (Xtream Codes)
                                _buildOptionCard(
                                  icon: Icons.api,
                                  title: 'Xtream Codes API',
                                  onTap: () => Get.toNamed(screenRegister),
                                  isTV: isTV,
                                  isHighlighted: true,
                                ),
                                // Play Local Audio & Video
                                _buildOptionCard(
                                  icon: Icons.folder_open,
                                  title: 'M3U/File',
                                  onTap: () => Get.toNamed(screenRegister),
                                  isTV: isTV,
                                ),

                                // M3U/File (Coming soon)
                                _buildOptionCard(
                                  icon: Icons.playlist_play,
                                  title: 'User Playlist',
                                  onTap: () => Get.toNamed(screenUsersList),
                                  isTV: isTV,
                                  // isDisabled: true,
                                ),
                              ],
                            ),

                            const SizedBox(height: 30),

                            const SizedBox(height: 30),

                            // Footer text
                            _buildFooterText(isTV),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Terms of Service
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'By using this application, you agree to the',
                          style: Get.textTheme.titleSmall!.copyWith(
                            fontSize: fontSize - 3,
                            color: Colors.grey,
                          ),
                        ),
                        InkWell(
                          onTap: () async => await launchUrlString(kPrivacy),
                          child: Text(
                            ' Terms of Services.',
                            style: Get.textTheme.titleSmall!.copyWith(
                              fontSize: fontSize - 3,
                              color: Colors.blue,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildOptionCard({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    required bool isTV,
    bool isHighlighted = false,
    bool isDisabled = false,
  }) {
    // Card sizes based on screen size
    final double cardSize = isTV ? 180.0 : 140.0;
    final double iconSize = isTV ? 50.0 : 36.0;
    final double fontSize = isTV ? 16.0 : 14.0;

    return InkWell(
      onTap: isDisabled ? null : onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: cardSize,
        height: cardSize,
        decoration: BoxDecoration(
          color: Colors.grey[900],
          borderRadius: BorderRadius.circular(12),
          border: isHighlighted
              ? Border.all(color: Colors.purpleAccent, width: 2)
              : null,
          boxShadow: isHighlighted
              ? [
                  BoxShadow(
                      color: Colors.purpleAccent.withOpacity(0.3),
                      blurRadius: 8,
                      spreadRadius: 1)
                ]
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
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isDisabled ? Colors.grey : Colors.white,
                  fontSize: fontSize,
                  fontWeight:
                      isHighlighted ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Footer text for additional information
  Widget _buildFooterText(bool isTV) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Column(
        children: [
          Text(
            'Play Network Stream(Audio/Video) with a direct URL',
            style: TextStyle(
              color: Colors.white70,
              fontSize: isTV ? 16 : 14,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'By using this application, you agree to the',
                style: TextStyle(
                  fontSize: isTV ? 14 : 12,
                  color: Colors.grey,
                ),
              ),
              InkWell(
                onTap: () async => await launchUrlString(kPrivacy),
                child: Text(
                  ' Terms of Services.',
                  style: TextStyle(
                    fontSize: isTV ? 14 : 12,
                    color: Colors.blue,
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
