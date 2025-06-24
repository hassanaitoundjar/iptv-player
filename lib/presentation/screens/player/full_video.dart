part of '../screens.dart';

class FullVideoScreen extends StatefulWidget {
  const FullVideoScreen({
    super.key,
    required this.link,
    required this.title,
    this.isLive = false,
    this.isLocalFile = false,
  });
  final String link;
  final String title;
  final bool isLive;
  final bool isLocalFile;

  @override
  State<FullVideoScreen> createState() => _FullVideoScreenState();
}

class _FullVideoScreenState extends State<FullVideoScreen> {
  late VlcPlayerController _videoPlayerController;
  bool isPlayed = true;
  bool progress = true;
  bool showControllersVideo = true;
  String position = '';
  String duration = '';
  double sliderValue = 0.0;
  bool validPosition = false;
  double _currentVolume = 0.0;
  double _currentBright = 0.0;
  late Timer timer;
  
  // Video speed control
  double _currentSpeed = 1.0;
  bool _showSpeedOptions = false;
  final List<double> _speedOptions = [0.5, 1.0, 1.5, 2.0];

  final ScreenBrightnessUtil _screenBrightnessUtil = ScreenBrightnessUtil();

  _settingPage() async {
    try {
      double brightness = await _screenBrightnessUtil.getBrightness();
      if (brightness == -1) {
        debugPrint("Oops... something wrong!");
      } else {
        _currentBright = brightness;
      }

      ///default volume is half
      VolumeController().listener((volume) {
        setState(() => _currentVolume = volume);
      });
      VolumeController().getVolume().then((volume) => _currentVolume = volume);

      setState(() {});
    } catch (e) {
      debugPrint("Error: setting: $e");
    }
  }

  @override
  void initState() {
    Wakelock.enable();
    
    // Initialize controller based on whether the file is local or from network
    if (widget.isLocalFile) {
      _videoPlayerController = VlcPlayerController.file(
        File(widget.link),
        hwAcc: HwAcc.auto,
        autoPlay: true,
        autoInitialize: true,
        options: VlcPlayerOptions(
          video: VlcVideoOptions([
            VlcVideoOptions.dropLateFrames(true),
            VlcVideoOptions.skipFrames(true),
          ]),
          advanced: VlcAdvancedOptions([
            VlcAdvancedOptions.networkCaching(1500),
            '--stats', // Enable statistics
          ]),
        ),
      );
    } else {
      _videoPlayerController = VlcPlayerController.network(
        widget.link,
        hwAcc: HwAcc.auto, // Changed from full to auto for better compatibility
        autoPlay: true,
        autoInitialize: true,
        options: VlcPlayerOptions(
          video: VlcVideoOptions([
            VlcVideoOptions.dropLateFrames(true),
            VlcVideoOptions.skipFrames(true),
            '--no-mediacodec-dr', // Disable direct rendering
            '--network-caching=1500', // Increase network buffer
            '--clock-jitter=0', // Reduce clock jitter
            '--clock-synchro=0', // Disable clock synchro for smoother playback
          ]),
          advanced: VlcAdvancedOptions([
            VlcAdvancedOptions.networkCaching(1500),
            '--stats', // Enable statistics
            '--adaptive-maxbuffer=1500', // Adjust buffer size
          ]),
        ),
      );
    }

    super.initState();
    _videoPlayerController.addListener(listener);
    _settingPage();

    timer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (showControllersVideo) {
        setState(() {
          showControllersVideo = false;
        });
      }
    });
  }

  void listener() async {
    if (!mounted) return;

    if (progress) {
      if (_videoPlayerController.value.isPlaying) {
        setState(() {
          progress = false;
        });
      }
    }

    if (_videoPlayerController.value.isInitialized) {
      var oPosition = _videoPlayerController.value.position;
      var oDuration = _videoPlayerController.value.duration;

      if (oDuration.inHours == 0) {
        var strPosition = oPosition.toString().split('.')[0];
        var strDuration = oDuration.toString().split('.')[0];
        position = "${strPosition.split(':')[1]}:${strPosition.split(':')[2]}";
        duration = "${strDuration.split(':')[1]}:${strDuration.split(':')[2]}";
      } else {
        position = oPosition.toString().split('.')[0];
        duration = oDuration.toString().split('.')[0];
      }
      validPosition = oDuration.compareTo(oPosition) >= 0;
      sliderValue = validPosition ? oPosition.inSeconds.toDouble() : 0;
      setState(() {});
    }
  }

  void _onSliderPositionChanged(double progress) {
    setState(() {
      sliderValue = progress.floor().toDouble();
    });
    //convert to Milliseconds since VLC requires MS to set time
    _videoPlayerController.setTime(sliderValue.toInt() * 1000);
  }

  @override
  void dispose() async {
    super.dispose();
    await _videoPlayerController.stopRendererScanning();
    await _videoPlayerController.dispose();
    timer.cancel();
    VolumeController().removeListener();
  }

  @override
  Widget build(BuildContext context) {
    debugPrint("SIZE: ${MediaQuery.of(context).size.width}");
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          Container(
            width: getSize(context).width,
            height: getSize(context).height,
            color: Colors.black,
            child: VlcPlayer(
              controller: _videoPlayerController,
              aspectRatio: 16 / 9,
              virtualDisplay: true,
              placeholder: const SizedBox(),
            ),
          ),

          if (progress)
            const Center(
                child: CircularProgressIndicator(
              color: kColorPrimary,
            )),

          ///Controllers
          GestureDetector(
            onTap: () {
              setState(() {
                showControllersVideo = !showControllersVideo;
              });
            },
            child: Container(
              width: getSize(context).width,
              height: getSize(context).height,
              color: Colors.transparent,
              child: AnimatedSize(
                duration: const Duration(milliseconds: 200),
                child: !showControllersVideo
                    ? const SizedBox()
                    : SafeArea(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            ///Back & Title
                            Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                IconButton(
                                  focusColor: kColorFocus,
                                  onPressed: () async {
                                    await Future.delayed(
                                            const Duration(milliseconds: 1000))
                                        .then((value) {
                                      Get.back(
                                          result: progress
                                              ? null
                                              : [
                                                  sliderValue,
                                                  _videoPlayerController
                                                      .value.duration.inSeconds
                                                      .toDouble()
                                                ]);
                                    });
                                  },
                                  icon: Icon(
                                    FontAwesomeIcons.chevronLeft,
                                    size: 19.sp,
                                  ),
                                ),
                                const SizedBox(width: 5),
                                Expanded(
                                  child: Text(
                                    widget.title,
                                    maxLines: 1,
                                    style: Get.textTheme.labelLarge!.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18.sp,
                                    ),
                                  ),
                                ),
                                const Spacer(),
                                // Speed control button - only show for VOD content (movies/series), not for live TV
                                if (!widget.isLive) // Only show for non-live content
                                  Padding(
                                    padding: const EdgeInsets.only(right: 16.0),
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
                              ],
                            ),
                            
                            // Speed options dropdown - only for VOD content
                            if (!widget.isLive && _showSpeedOptions)
                              Align(
                                alignment: Alignment.topRight,
                                child: Padding(
                                  padding: const EdgeInsets.only(right: 16.0, top: 50.0),
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
                                            _videoPlayerController.setPlaybackSpeed(speed);
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
                              ),

                            ///Slider & Play/Pause
                            if (!progress && !widget.isLive)
                              Align(
                                alignment: Alignment.bottomCenter,
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Slider(
                                        activeColor: kColorPrimary,
                                        inactiveColor: Colors.white,
                                        value: sliderValue,
                                        min: 0.0,
                                        max: (!validPosition)
                                            ? 1.0
                                            : _videoPlayerController
                                                .value.duration.inSeconds
                                                .toDouble(),
                                        onChanged: validPosition
                                            ? _onSliderPositionChanged
                                            : null,
                                      ),
                                    ),
                                    Text(
                                      "$position / $duration",
                                      style: Get.textTheme.titleSmall!.copyWith(
                                        fontSize: 15.sp,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
              ),
            ),
          ),

          if (!progress && showControllersVideo)

            ///Controllers Light, Lock...
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                if (!isTv(context))
                  FillingSlider(
                    direction: FillingSliderDirection.vertical,
                    initialValue: _currentVolume,
                    onFinish: (value) async {
                      VolumeController().setVolume(value);
                      setState(() {
                        _currentVolume = value;
                      });
                    },
                    fillColor: Colors.white54,
                    height: 40.h,
                    width: 30,
                    child: Icon(
                      _currentVolume < .1
                          ? FontAwesomeIcons.volumeXmark
                          : _currentVolume < .7
                              ? FontAwesomeIcons.volumeLow
                              : FontAwesomeIcons.volumeHigh,
                      color: Colors.black,
                      size: 13,
                    ),
                  ),
                Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Skip backward 10 seconds button
                      if (!widget.isLive) // Only show for non-live content
                        IconButton(
                          focusColor: kColorFocus,
                          onPressed: () {
                            // Get current position
                            final currentPos = _videoPlayerController.value.position.inMilliseconds;
                            // Calculate new position (10 seconds back)
                            final newPos = max(currentPos - 10000, 0);
                            // Seek to new position
                            _videoPlayerController.seekTo(Duration(milliseconds: newPos));
                          },
                          icon: Icon(
                            FontAwesomeIcons.backward,
                            size: 20.sp,
                            color: Colors.white,
                          ),
                          tooltip: 'Back 10s',
                        ),
                      
                      // Play/Pause button
                      IconButton(
                        onPressed: () {
                          setState(() {
                            if (isPlayed) {
                              _videoPlayerController.pause();
                              isPlayed = false;
                            } else {
                              _videoPlayerController.play();
                              isPlayed = true;
                            }
                          });
                        },
                        icon: Icon(
                          isPlayed ? FontAwesomeIcons.pause : FontAwesomeIcons.play,
                          size: 24.sp,
                          color: Colors.white,
                        ),
                      ),
                      
                      // Skip forward 10 seconds button
                      if (!widget.isLive) // Only show for non-live content
                        IconButton(
                          focusColor: kColorFocus,
                          onPressed: () {
                            // Get current position
                            final currentPos = _videoPlayerController.value.position.inMilliseconds;
                            // Calculate new position (10 seconds forward)
                            final newPos = currentPos + 10000;
                            // Seek to new position
                            _videoPlayerController.seekTo(Duration(milliseconds: newPos));
                          },
                          icon: Icon(
                            FontAwesomeIcons.forward,
                            size: 20.sp,
                            color: Colors.white,
                          ),
                          tooltip: 'Forward 10s',
                        ),
                    ],
                  ),
                ),
                if (!isTv(context))
                  FillingSlider(
                    initialValue: _currentBright,
                    direction: FillingSliderDirection.vertical,
                    fillColor: Colors.white54,
                    height: 40.h,
                    width: 30,
                    onFinish: (value) async {
                      bool success =
                          await _screenBrightnessUtil.setBrightness(value);

                      setState(() {
                        _currentBright = value;
                      });
                    },
                    child: Icon(
                      _currentBright < .1
                          ? FontAwesomeIcons.moon
                          : _currentVolume < .7
                              ? FontAwesomeIcons.sun
                              : FontAwesomeIcons.solidSun,
                      color: Colors.black,
                      size: 13,
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}
