part of 'screens.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  // Track last update times for each content type
  DateTime? _lastLiveUpdate;
  DateTime? _lastMoviesUpdate;
  DateTime? _lastSeriesUpdate;

  @override
  void initState() {
    context.read<FavoritesCubit>().initialData();
    context.read<WatchingCubit>().initialData();
    _loadTimestamps();
    super.initState();
  }

  /// Load saved timestamps from shared preferences
  Future<void> _loadTimestamps() async {
    _lastLiveUpdate = await UpdateTimestampService.getLiveUpdateTime();
    _lastMoviesUpdate = await UpdateTimestampService.getMoviesUpdateTime();
    _lastSeriesUpdate = await UpdateTimestampService.getSeriesUpdateTime();

    // Update UI if timestamps were loaded
    if (mounted) {
      setState(() {});
    }
  }

  /// Save live update timestamp and update state
  void _updateLiveTimestamp() {
    final now = DateTime.now();
    setState(() {
      _lastLiveUpdate = now;
    });
    UpdateTimestampService.saveLiveUpdateTime(now);
  }

  /// Save movies update timestamp and update state
  void _updateMoviesTimestamp() {
    final now = DateTime.now();
    setState(() {
      _lastMoviesUpdate = now;
    });
    UpdateTimestampService.saveMoviesUpdateTime(now);
  }

  /// Save series update timestamp and update state
  void _updateSeriesTimestamp() {
    final now = DateTime.now();
    setState(() {
      _lastSeriesUpdate = now;
    });
    UpdateTimestampService.saveSeriesUpdateTime(now);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Ink(
        width: getSize(context).width,
        height: getSize(context).height,
        decoration: kDecorBackground,
        padding: const EdgeInsets.only(left: 10, right: 10, top: 15),
        child: Column(
          children: [
            const AppBarWelcome(),
            const SizedBox(height: 10),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(10.0),
                child: Row(
                  children: [
                    Expanded(
                      child: BlocBuilder<LiveCatyBloc, LiveCatyState>(
                        builder: (context, state) {
                          if (state is LiveCatyLoading) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          }
                          if (state is LiveCatySuccess) {
                            return CardWelcomeTv(
                              title: "LIVE TV",
                              autoFocus: true,
                              subTitle: "${state.categories.length} Channels",
                              icon: kIconLive,
                              onTap: () {
                                Get.toNamed(screenLiveCategories)!;
                              },
                              lastUpdate: _lastLiveUpdate,
                              onRefresh: () {
                                // Show loading indicator
                                Get.snackbar(
                                  'Refreshing',
                                  'Updating Live TV data...',
                                  snackPosition: SnackPosition.BOTTOM,
                                  duration: const Duration(seconds: 2),
                                );

                                // Update live categories
                                context
                                    .read<LiveCatyBloc>()
                                    .add(GetLiveCategories());

                                // Update last refresh time and show success message
                                Future.delayed(const Duration(seconds: 2), () {
                                  _updateLiveTimestamp();
                                  
                                  Get.snackbar(
                                    'Success',
                                    'Live TV data refreshed successfully',
                                    snackPosition: SnackPosition.BOTTOM,
                                    backgroundColor: Colors.green.withOpacity(0.7),
                                    colorText: Colors.white,
                                  );
                                });
                              },
                            );
                          }

                          return const Text('error live caty');
                        },
                      ),
                    ),
                    SizedBox(width: 2.w),
                    Expanded(
                      child: BlocBuilder<MovieCatyBloc, MovieCatyState>(
                        builder: (context, state) {
                          if (state is MovieCatyLoading) {
                            return const Center(
                                child: CircularProgressIndicator());
                          } else if (state is MovieCatySuccess) {
                            return CardWelcomeTv(
                              title: "Movies",
                              subTitle: "${state.categories.length} Channels",
                              icon: kIconMovies,
                              onTap: () {
                                Get.toNamed(screenMovieCategories)!;
                              },
                              lastUpdate: _lastMoviesUpdate,
                              onRefresh: () {
                                // Show loading indicator
                                Get.snackbar(
                                  'Refreshing',
                                  'Updating Movies data...',
                                  snackPosition: SnackPosition.BOTTOM,
                                  duration: const Duration(seconds: 2),
                                );

                                // Update movie categories
                                context
                                    .read<MovieCatyBloc>()
                                    .add(GetMovieCategories());

                                // Update last refresh time and show success message
                                Future.delayed(const Duration(seconds: 2), () {
                                  _updateMoviesTimestamp();
                                  
                                  Get.snackbar(
                                    'Success',
                                    'Movies data refreshed successfully',
                                    snackPosition: SnackPosition.BOTTOM,
                                    backgroundColor: Colors.green.withOpacity(0.7),
                                    colorText: Colors.white,
                                  );
                                });
                              },
                            );
                          }

                          return const Text('error movie caty');
                        },
                      ),
                    ),
                    SizedBox(width: 2.w),
                    Expanded(
                      child: BlocBuilder<SeriesCatyBloc, SeriesCatyState>(
                        builder: (context, state) {
                          if (state is SeriesCatyLoading) {
                            return const Center(
                                child: CircularProgressIndicator());
                          } else if (state is SeriesCatySuccess) {
                            return CardWelcomeTv(
                              title: "Series",
                              subTitle: "${state.categories.length} Channels",
                              icon: kIconSeries,
                              onTap: () {
                                Get.toNamed(screenSeriesCategories)!;
                              },
                              lastUpdate: _lastSeriesUpdate,
                              onRefresh: () {
                                // Show loading indicator
                                Get.snackbar(
                                  'Refreshing',
                                  'Updating Series data...',
                                  snackPosition: SnackPosition.BOTTOM,
                                  duration: const Duration(seconds: 2),
                                );

                                // Update series categories
                                context
                                    .read<SeriesCatyBloc>()
                                    .add(GetSeriesCategories());

                                // Update last refresh time and show success message
                                Future.delayed(const Duration(seconds: 2), () {
                                  _updateSeriesTimestamp();
                                  
                                  Get.snackbar(
                                    'Success',
                                    'Series data refreshed successfully',
                                    snackPosition: SnackPosition.BOTTOM,
                                    backgroundColor: Colors.green.withOpacity(0.7),
                                    colorText: Colors.white,
                                  );
                                });
                              },
                            );
                          }

                          return const Text('could not load series');
                        },
                      ),
                    ),
                    SizedBox(width: 2.w),
                    SizedBox(
                      width: 20.w,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          CardWelcomeSetting(
                            title: 'Catch up',
                            icon: FontAwesomeIcons.rotate,
                            onTap: () {
                              Get.toNamed(screenCatchUp);
                            },
                          ),
                          CardWelcomeSetting(
                            title: 'Favourites',
                            icon: FontAwesomeIcons.heart,
                            onTap: () {
                              Get.toNamed(screenFavourite);
                            },
                          ),
                          CardWelcomeSetting(
                            title: 'Settings',
                            icon: FontAwesomeIcons.gear,
                            onTap: () {
                              Get.toNamed(screenSettings);
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'By using this application, you agree to the',
                        style: Get.textTheme.titleSmall!.copyWith(
                          fontSize: 12.sp,
                          color: Colors.grey,
                        ),
                      ),
                      InkWell(
                        onTap: () async {
                          await launchUrlString(kPrivacy);
                        },
                        child: Text(
                          ' Terms of Services.',
                          style: Get.textTheme.titleSmall!.copyWith(
                            fontSize: 12.sp,
                            color: Colors.blue,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                BlocBuilder<AuthBloc, AuthState>(
                  builder: (context, state) {
                    if (state is AuthSuccess) {
                      final playlistName = state.user.userInfo?.playlistName ??
                          state.user.userInfo?.username ??
                          '';
                      return Text(
                        'Playlist: $playlistName',
                        style: Get.textTheme.titleSmall!.copyWith(
                          fontSize: 12.sp,
                          color: Colors.grey[400],
                          fontWeight: FontWeight.w500,
                        ),
                      );
                    }
                    return const SizedBox();
                  },
                ),
                const SizedBox(width: 10), // Add some padding on the right
              ],
            ),
          ],
        ),
      ),
    );
  }
}
