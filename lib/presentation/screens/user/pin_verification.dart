part of '../screens.dart';

class PinVerificationScreen extends StatefulWidget {
  final UserModel user;
  final Function(bool) onVerificationComplete;

  const PinVerificationScreen({
    Key? key,
    required this.user,
    required this.onVerificationComplete,
  }) : super(key: key);

  @override
  State<PinVerificationScreen> createState() => _PinVerificationScreenState();
}

class _PinVerificationScreenState extends State<PinVerificationScreen> {
  final TextEditingController _pinController = TextEditingController();
  bool _isPinVisible = false;
  bool _isError = false;
  int _attempts = 0;

  @override
  void initState() {
    super.initState();
    _loadPlaylistPin();
  }
  
  Future<void> _loadPlaylistPin() async {
    if (widget.user.userInfo?.playlistName != null) {
      // For testing/debugging purposes only - normally we wouldn't pre-fill the PIN
      String pin = await LocaleApi.getPlaylistPin(widget.user.userInfo!.playlistName!);
      // We're not setting the pin in the controller as this is a verification screen
      // Just keeping this method for future use if needed
    }
  }
  
  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  Future<void> _verifyPin() async {
    String enteredPin = _pinController.text.trim();
    String playlistName = widget.user.userInfo?.playlistName ?? '';
    
    // Verify PIN for this specific playlist
    bool isCorrect = await LocaleApi.verifyPlaylistPin(playlistName, enteredPin);
    
    if (isCorrect) {
      widget.onVerificationComplete(true);
    } else {
      setState(() {
        _isError = true;
        _attempts++;
      });
      
      // After 3 failed attempts, go back
      if (_attempts >= 3) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Too many failed attempts. Please try again later.'),
            backgroundColor: Colors.red,
          ),
        );
        Future.delayed(const Duration(seconds: 1), () {
          widget.onVerificationComplete(false);
        });
      }
    }
  }
  
  // Build the PIN verification content widget
  Widget _buildPinVerificationContent() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Enter PIN',
          style: Get.textTheme.titleLarge!.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'This playlist is protected by a PIN',
          style: Get.textTheme.bodyMedium!.copyWith(
            color: Colors.white70,
          ),
        ),
        const SizedBox(height: 30),
        TextField(
          controller: _pinController,
          keyboardType: TextInputType.number,
          maxLength: 6,
          obscureText: !_isPinVisible,
          autofocus: true,
          style: Get.textTheme.bodyMedium!.copyWith(
            color: Colors.white,
          ),
          decoration: InputDecoration(
            hintText: "Enter PIN",
            hintStyle: Get.textTheme.bodyMedium!.copyWith(
              color: Colors.grey,
            ),
            errorText: _isError ? "Incorrect PIN" : null,
            counterStyle: Get.textTheme.bodySmall!.copyWith(
              color: Colors.white70,
            ),
            suffixIcon: IconButton(
              icon: Icon(
                _isPinVisible ? FontAwesomeIcons.eyeSlash : FontAwesomeIcons.eye,
                size: 18,
                color: Colors.blue,
              ),
              onPressed: () {
                setState(() {
                  _isPinVisible = !_isPinVisible;
                });
              },
            ),
          ),
          onSubmitted: (_) => _verifyPin(),
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            TextButton(
              onPressed: () => widget.onVerificationComplete(false),
              child: Text(
                'CANCEL',
                style: Get.textTheme.bodyMedium!.copyWith(
                  color: Colors.white70,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 10),
              ),
              onPressed: _verifyPin,
              child: Text(
                'VERIFY',
                style: Get.textTheme.bodyMedium!.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    // If used as a full screen
    if (Navigator.of(context).widget.pages.isNotEmpty && 
        Navigator.of(context).widget.pages.last.name != null) {
      return Scaffold(
        body: Container(
          width: 100.w,
          height: 100.h,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.black.withOpacity(0.8),
                Colors.black.withOpacity(0.9),
              ],
            ),
          ),
          child: Center(
            child: _buildPinVerificationContent(),
          ),
        ),
      );
    } 
    // If used as a dialog
    else {
      return Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          width: 80.w,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.grey[900],
            borderRadius: BorderRadius.circular(10),
          ),
          child: _buildPinVerificationContent(),
        ),
      );
    }
  }
}
