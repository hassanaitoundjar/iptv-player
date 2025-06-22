import 'package:flutter/material.dart';

import '../../repository/services/parental_control_service.dart';

/// A widget that wraps content that might need parental control protection
class ParentalControlWrapper extends StatefulWidget {
  final Widget child;
  final String contentName;
  final bool isCategory;

  const ParentalControlWrapper({
    Key? key,
    required this.child,
    required this.contentName,
    this.isCategory = false,
  }) : super(key: key);

  @override
  State<ParentalControlWrapper> createState() => _ParentalControlWrapperState();
}

class _ParentalControlWrapperState extends State<ParentalControlWrapper> {
  bool _isLoading = true;
  bool _shouldBlock = false;
  bool _pinVerifiedForThisInteraction = false;

  @override
  void initState() {
    super.initState();
    _checkParentalControl();
  }

  Future<void> _checkParentalControl() async {
    final shouldBlock = await _shouldApplyParentalControl(widget.contentName);

    if (mounted) {
      setState(() {
        _shouldBlock = shouldBlock;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // If still loading, show a placeholder
    if (_isLoading) {
      return widget.child; // Show content while checking
    }

    // If not blocked or PIN was verified for this specific interaction, show content
    if (!_shouldBlock || _pinVerifiedForThisInteraction) {
      return widget.child;
    }

    // Apply parental control
    return InkWell(
      onTap: () => _handleProtectedContent(context),
      child: Stack(
        children: [
          // Blur or dim the content
          ColorFiltered(
            colorFilter: ColorFilter.mode(
              Colors.black.withOpacity(0.7),
              BlendMode.srcOver,
            ),
            child: widget.child,
          ),

          // Lock icon and text overlay
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.lock,
                  color: Colors.amber,
                  size: widget.isCategory ? 30 : 20,
                ),
                const SizedBox(height: 5),
                Text(
                  'Age Restricted',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: widget.isCategory ? 14 : 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Check if parental control should be applied to this content
  Future<bool> _shouldApplyParentalControl(String name) async {
    final parentalService = ParentalControlService();

    // First check if parental control is enabled at all
    final isEnabled = await parentalService.isEnabled();
    if (!isEnabled) return false;

    // Check if content should be blocked based on name
    return parentalService.shouldBlockContent(name);
  }

  /// Handle user interaction with protected content
  Future<void> _handleProtectedContent(BuildContext context) async {
    final parentalService = ParentalControlService();

    // Show PIN entry dialog
    final isCorrect = await parentalService.showPinEntryDialog(context);

    if (isCorrect && mounted) {
      // PIN is correct, allow one-time access to this specific content only
      setState(() {
        _pinVerifiedForThisInteraction = true;
      });
    }
  }
}
