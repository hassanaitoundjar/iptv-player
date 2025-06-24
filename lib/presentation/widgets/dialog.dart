part of 'widgets.dart';

class DialogTrailerYoutube extends StatefulWidget {
  const DialogTrailerYoutube({super.key, required this.trailer, this.thumb});
  final String trailer;
  final String? thumb;

  @override
  State<DialogTrailerYoutube> createState() => _DialogTrailerYoutubeState();
}

class _DialogTrailerYoutubeState extends State<DialogTrailerYoutube> {
  late PodPlayerController controller;
  bool _hasError = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }
  
  void _initializePlayer() {
    try {
      // Print the YouTube trailer ID for debugging
      print('YouTube Trailer ID: ${widget.trailer}');
      
      // Check if the trailer ID is valid
      if (widget.trailer.isEmpty) {
        setState(() {
          _hasError = true;
          _errorMessage = 'Invalid YouTube trailer ID';
        });
        return;
      }
      
      controller = PodPlayerController(
        playVideoFrom: PlayVideoFrom.youtube(
          'https://youtu.be/${widget.trailer}',
        ),
        podPlayerConfig: const PodPlayerConfig(
          autoPlay: true, // Enable autoplay
          isLooping: false,
        ),
      );
      
      controller.initialise().catchError((error) {
        print('YouTube player initialization error: $error');
        setState(() {
          _hasError = true;
          _errorMessage = 'Failed to load YouTube video: $error';
        });
      });
    } catch (e) {
      print('Exception in _initializePlayer: $e');
      setState(() {
        _hasError = true;
        _errorMessage = 'Error initializing player: $e';
      });
    }
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      contentPadding: const EdgeInsets.all(0),
      content: Ink(
        decoration: kDecorBackground,
        padding: const EdgeInsets.all(5),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _hasError
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.error_outline,
                            color: Colors.red,
                            size: 48,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Error playing YouTube video',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Text(_errorMessage),
                        ],
                      ),
                    )
                  : PodVideoPlayer(
                controller: controller,
                //onToggleFullScreen: (value) async {},
                alwaysShowProgressBar: false,
                onToggleFullScreen: (value) async {
                  if (!value) {
                    SystemChrome.setPreferredOrientations([
                      DeviceOrientation.landscapeLeft,
                      DeviceOrientation.landscapeRight,
                    ]);
                  }
                  return;
                },
                podProgressBarConfig: const PodProgressBarConfig(
                  alwaysVisibleCircleHandler: false,
                  circleHandlerColor: kColorPrimary,
                  playingBarColor: kColorPrimary,
                ),
                videoThumbnail: widget.thumb == null
                    ? null
                    : DecorationImage(
                        image: NetworkImage(widget.thumb ?? ""),
                        fit: BoxFit.cover,
                      ),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CardButtonWatchMovie(
                  isFocused: true,
                  title: "Exit",
                  onTap: () => Get.back(),
                ),
                const SizedBox(width: 15),
                if (!_hasError)
                  CardButtonWatchMovie(
                    title: controller.isVideoPlaying ? "Pause" : "Play",
                    onTap: () {
                      setState(() {
                        if (controller.isVideoPlaying) {
                          controller.pause();
                        } else {
                          controller.play();
                        }
                      });
                    },
                  ),
              ],
            ),
            const SizedBox(height: 5),
          ],
        ),
      ),
    );
  }
}
