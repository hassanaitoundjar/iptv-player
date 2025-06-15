import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

import 'package:player/repository/api/api.dart';
import 'package:player/repository/services/firebase_service.dart';
import 'package:player/repository/services/expiration_service.dart';
import 'package:responsive_sizer/responsive_sizer.dart';
import 'helpers/helpers.dart';
import 'logic/blocs/auth/auth_bloc.dart';
import 'logic/blocs/categories/channels/channels_bloc.dart';
import 'logic/blocs/categories/live_caty/live_caty_bloc.dart';
import 'logic/blocs/categories/movie_caty/movie_caty_bloc.dart';
import 'logic/blocs/categories/series_caty/series_caty_bloc.dart';
import 'logic/cubits/favorites/favorites_cubit.dart';
import 'logic/cubits/settings/settings_cubit.dart';
import 'logic/cubits/video/video_cubit.dart';
import 'logic/cubits/watch/watching_cubit.dart';
import 'presentation/screens/screens.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await GetStorage.init();
  await GetStorage.init("favorites");
  
  // Initialize Firebase with configuration
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('Firebase initialized successfully');
  } catch (e) {
    print('Failed to initialize Firebase: $e');
  }
  
  // Create service instances
  final firebaseService = FirebaseService();
  final expirationService = ExpirationService();
  final iptv = IpTvApi();
  final authApi = AuthApi();
  final watchingLocale = WatchingLocale();
  final favoriteLocale = FavoriteLocale();
  
  // Check for subscription expiration on app startup
  try {
    final localeUser = await LocaleApi.getUser();
    if (localeUser != null) {
      // Schedule the notification check for after the UI is built
      Future.delayed(const Duration(seconds: 2), () {
        expirationService.showExpirationNotification(localeUser);
      });
    }
  } catch (e) {
    print('Error checking subscription on startup: $e');
  }

  runApp(MyApp(
    iptv: iptv,
    authApi: authApi,
    firebaseService: firebaseService,
    watchingLocale: watchingLocale,
    favoriteLocale: favoriteLocale,
  ));
}

class MyApp extends StatefulWidget {
  final IpTvApi iptv;
  final AuthApi authApi;
  final FirebaseService firebaseService;
  final WatchingLocale watchingLocale;
  final FavoriteLocale favoriteLocale;
  const MyApp(
      {super.key,
      required this.iptv,
      required this.authApi,
      required this.firebaseService,
      required this.watchingLocale,
      required this.favoriteLocale});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    //Enable FullScreen
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: []);
  }

  @override
  Widget build(BuildContext context) {
    return Shortcuts(
      shortcuts: <LogicalKeySet, Intent>{
        LogicalKeySet(LogicalKeyboardKey.select): const ActivateIntent(),
        LogicalKeySet(LogicalKeyboardKey.enter): const ActivateIntent(),
      },
      child: MultiBlocProvider(
        providers: [
          BlocProvider<AuthBloc>(
            create: (BuildContext context) => AuthBloc(widget.authApi),
          ),
          BlocProvider<LiveCatyBloc>(
            create: (BuildContext context) => LiveCatyBloc(widget.iptv),
          ),
          BlocProvider<ChannelsBloc>(
            create: (BuildContext context) => ChannelsBloc(widget.iptv),
          ),
          BlocProvider<MovieCatyBloc>(
            create: (BuildContext context) => MovieCatyBloc(widget.iptv),
          ),
          BlocProvider<SeriesCatyBloc>(
            create: (BuildContext context) => SeriesCatyBloc(widget.iptv),
          ),
          BlocProvider<VideoCubit>(
            create: (BuildContext context) => VideoCubit(),
          ),
          BlocProvider<SettingsCubit>(
            create: (BuildContext context) => SettingsCubit(),
          ),
          BlocProvider<WatchingCubit>(
            create: (BuildContext context) =>
                WatchingCubit(widget.watchingLocale),
          ),
          BlocProvider<FavoritesCubit>(
            create: (BuildContext context) =>
                FavoritesCubit(widget.favoriteLocale),
          ),
        ],
        child: ResponsiveSizer(
          builder: (context, orient, type) {
            return GetMaterialApp(
              title: kAppName,
              theme: MyThemApp.themeData(context),
              debugShowCheckedModeBanner: false,
              initialRoute: "/",
              getPages: [
                GetPage(name: screenSplash, page: () => const SplashScreen()),
                GetPage(name: screenWelcome, page: () => const WelcomeScreen()),
                GetPage(name: screenIntro, page: () => const IntroScreen()),
                GetPage(
                    name: screenLiveCategories,
                    page: () => const LiveCategoriesScreen()),
                GetPage(
                    name: screenRegister, page: () => const RegisterScreen()),
                GetPage(
                    name: screenRegisterTv, page: () => const RegisterUserTv()),
                GetPage(
                    name: screenRegisterTv, page: () => const RegisterUserTv()),
                GetPage(
                    name: screenMovieCategories,
                    page: () => const MovieCategoriesScreen()),
                GetPage(
                    name: screenSeriesCategories,
                    page: () => const SeriesCategoriesScreen()),
                GetPage(
                    name: screenDeviceActivation,
                    page: () => const DeviceActivationScreen()),
                GetPage(
                    name: screenSettings, page: () => const SettingsScreen()),
                GetPage(
                    name: screenFavourite, page: () => const FavouriteScreen()),
                GetPage(name: screenCatchUp, page: () => const CatchUpScreen()),
                GetPage(name: screenUsersList, page: () => const UsersListScreen()),
              ],
            );
          },
        ),
      ),
    );
  }
}
