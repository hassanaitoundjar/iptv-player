import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:player/repository/api/api.dart';
import 'package:player/repository/models/user.dart';
import 'package:player/repository/services/firebase_service.dart';
import 'package:player/repository/services/expiration_service.dart';

part 'auth_event.dart';
part 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthApi authApi;
  final FirebaseService _firebaseService = FirebaseService();
  final ExpirationService _expirationService = ExpirationService();

  AuthBloc(this.authApi) : super(AuthInitial()) {
    on<AuthRegister>((event, emit) async {
      emit(AuthLoading());

      final user = await authApi.registerUser(
        event.username,
        event.password,
        event.domain,
        event.username,
        event.playlistName.isNotEmpty ? event.playlistName : event.username,
        playlistPin: event.playlistPin,
      );

      if (user != null) {
        // Store user data in Firebase
        try {
          await _firebaseService.storeUserData(user);
          print('User data sent to Firebase successfully');
        } catch (e) {
          print('Failed to store user data in Firebase: $e');
          // Continue with the app flow even if Firebase storage fails
        }
        
        changeDeviceOrient();
        await Future.delayed(const Duration(milliseconds: 300));
        emit(AuthSuccess(user));
      } else {
        emit(AuthFailed("could not login!!"));
      }
    });

    on<AuthGetUser>((event, emit) async {
      emit(AuthLoading());

      final localeUser = await LocaleApi.getUser();

      if (localeUser != null) {
        // Update last login time in Firebase
        try {
          if (localeUser.userInfo?.username != null) {
            await _firebaseService.updateLastLogin(localeUser.userInfo!.username!);
          }
        } catch (e) {
          print('Failed to update login time in Firebase: $e');
          // Continue with the app flow even if Firebase update fails
        }
        
        // Check subscription expiration and show notification if needed
        _expirationService.showExpirationNotification(localeUser);
        
        changeDeviceOrient();
        emit(AuthSuccess(localeUser));
      } else {
        emit(AuthFailed("could not login!!"));
      }
    });

    on<AuthLogOut>((event, emit) async {
      await LocaleApi.logOut();
      changeDeviceOrientBack();
      emit(AuthFailed("LogOut"));
    });
  }

  void changeDeviceOrient() {
    //change portrait mobile
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  void changeDeviceOrientBack() {
    //change portrait mobile
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitDown,
      DeviceOrientation.portraitUp,
    ]);
  }
}
