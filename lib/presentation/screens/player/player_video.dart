part of '../screens.dart';

class StreamPlayerPage extends StatefulWidget {
  const StreamPlayerPage({
    super.key, 
    required this.controller,
    this.isLive = true, // Default to true since this is primarily used for live TV
  });
  final VlcPlayerController? controller;
  final bool isLive; // Flag to indicate if this is live content

  @override
  State<StreamPlayerPage> createState() => _StreamPlayerPageState();
}

class _StreamPlayerPageState extends State<StreamPlayerPage> {
  bool isPlayed = true;

  bool showControllersVideo = true;
  late Timer timer;
  
  // Video speed control
  double _currentSpeed = 1.0;
  bool _showSpeedOptions = false;
  final List<double> _speedOptions = [0.5, 1.0, 1.5, 2.0];

  @override
  void initState() {
    Wakelock.enable();
    super.initState();
    timer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (showControllersVideo) {
        setState(() {
          showControllersVideo = false;
        });
      }
    });
  }

  @override
  void dispose() {
    timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.controller == null) {
      return const Center(
        child: Text(
          'Select a player...',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }
    return Ink(
      color: Colors.black,
      width: getSize(context).width,
      height: getSize(context).height,
      child: Stack(
        alignment: Alignment.center,
        children: [
          VlcPlayer(
            controller: widget.controller!,
            aspectRatio: 16 / 9,
            placeholder: const Center(child: CircularProgressIndicator()),
          ),

          GestureDetector(
            onTap: () {
              debugPrint("click");
              setState(() {
                showControllersVideo = !showControllersVideo;
              });
            },
            child: Container(
              width: getSize(context).width,
              height: getSize(context).height,
              color: Colors.transparent,
            ),
          ),

          ///Controllers
          BlocBuilder<VideoCubit, VideoState>(
            builder: (context, state) {
              if (!state.isFull) {
                return const SizedBox();
              }

              return SizedBox(
                width: getSize(context).width,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 400),
                  child: !showControllersVideo
                      ? const SizedBox()
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                // Speed control button - only show for VOD content, not for live TV
                                if (!widget.isLive) // Only show speed controls for non-live content
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 20,
                                      vertical: 10,
                                    ),
                                    child: InkWell(
                                      onTap: () {
                                        setState(() {
                                          _showSpeedOptions = !_showSpeedOptions;
                                        });
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: Colors.black54,
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(FontAwesomeIcons.gauge, size: 14),
                                            const SizedBox(width: 4),
                                            Text(
                                              '${_currentSpeed}x',
                                              style: const TextStyle(color: Colors.white),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                
                                // Speed options dropdown - only show for VOD content
                                if (!widget.isLive && _showSpeedOptions)
                                  Positioned(
                                    left: 20,
                                    top: 50,
                                    child: Container(
                                      width: 80,
                                      decoration: BoxDecoration(
                                        color: Colors.black87,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: _speedOptions.map((speed) => InkWell(
                                          onTap: () {
                                            setState(() {
                                              _currentSpeed = speed;
                                              _showSpeedOptions = false;
                                              // Apply the selected speed
                                              widget.controller!.setPlaybackSpeed(speed);
                                            });
                                          },
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(vertical: 8),
                                            decoration: BoxDecoration(
                                              color: _currentSpeed == speed ? Colors.grey[800] : null,
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: Center(
                                              child: Text(
                                                '${speed}x',
                                                style: TextStyle(
                                                  color: _currentSpeed == speed ? Colors.white : Colors.grey[400],
                                                  fontWeight: _currentSpeed == speed ? FontWeight.bold : FontWeight.normal,
                                                ),
                                              ),
                                            ),
                                          ),
                                        )).toList(),
                                      ),
                                    ),
                                  ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 10,
                                  ),
                                  child: IconButton(
                                    focusColor: kColorFocus,
                                    onPressed: () {
                                      context
                                          .read<VideoCubit>()
                                          .changeUrlVideo(false);
                                      //Get.back();
                                    },
                                    icon: const Icon(
                                        FontAwesomeIcons.chevronRight),
                                  ),
                                ),
                              ],
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                // Skip backward 10 seconds button
                                if (!widget.isLive) // Only show for non-live content
                                  IconButton(
                                    focusColor: kColorFocus,
                                    onPressed: () {
                                      if (widget.controller != null) {
                                        // Get current position
                                        final currentPos = widget.controller!.value.position.inMilliseconds;
                                        // Calculate new position (10 seconds back)
                                        final newPos = max(currentPos - 10000, 0);
                                        // Seek to new position
                                        widget.controller!.seekTo(Duration(milliseconds: newPos));
                                      }
                                    },
                                    icon: Icon(
                                      FontAwesomeIcons.backward,
                                      size: 20.sp,
                                      color: Colors.white,
                                    ),
                                  ),
                                
                                // Play/Pause button
                                IconButton(
                                  focusColor: kColorFocus,
                                  onPressed: () {
                                    if (isPlayed) {
                                      widget.controller!.pause();
                                      isPlayed = false;
                                    } else {
                                      widget.controller!.play();
                                      isPlayed = true;
                                    }
                                    setState(() {});
                                  },
                                  icon: Icon(
                                    isPlayed
                                        ? FontAwesomeIcons.pause
                                        : FontAwesomeIcons.play,
                                    size: 24.sp,
                                    color: Colors.white,
                                  ),
                                ),
                                
                                // Skip forward 10 seconds button
                                if (!widget.isLive) // Only show for non-live content
                                  IconButton(
                                    focusColor: kColorFocus,
                                    onPressed: () {
                                      if (widget.controller != null) {
                                        // Get current position
                                        final currentPos = widget.controller!.value.position.inMilliseconds;
                                        // Calculate new position (10 seconds forward)
                                        final newPos = currentPos + 10000;
                                        // Seek to new position
                                        widget.controller!.seekTo(Duration(milliseconds: newPos));
                                      }
                                    },
                                    icon: Icon(
                                      FontAwesomeIcons.forward,
                                      size: 20.sp,
                                      color: Colors.white,
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 30),
                          ],
                        ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
