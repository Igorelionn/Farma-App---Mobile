import 'package:equatable/equatable.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();
  
  @override
  List<Object?> get props => [];
}

class AuthCheckRequested extends AuthEvent {}

class LoginSubmitted extends AuthEvent {
  final String email;
  final String password;
  final bool rememberMe;
  
  const LoginSubmitted({
    required this.email,
    required this.password,
    this.rememberMe = false,
  });
  
  @override
  List<Object?> get props => [email, password, rememberMe];
}

class LogoutRequested extends AuthEvent {}

