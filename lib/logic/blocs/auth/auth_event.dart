part of 'auth_bloc.dart';

@immutable
abstract class AuthEvent {}

class AuthRegister extends AuthEvent {
  final String username;
  final String password;
  final String domain;
  final String playlistName;
  final String playlistPin;

  AuthRegister(this.username, this.password, this.domain, {this.playlistName = "", this.playlistPin = ""});
}

class AuthGetUser extends AuthEvent {}

class AuthLogOut extends AuthEvent {}
