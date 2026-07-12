abstract class AuthState {}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class AuthCodeSaved extends AuthState {}

class Authenticated extends AuthState {}

class Unauthenticated extends AuthState {}

class FirstTimeUser extends AuthState {}

class AuthCheckInProgress extends AuthState {}

class AuthSuccess extends AuthState {
  final String message;
  AuthSuccess({this.message = "Success"});
}

class AuthError extends AuthState {
  final String error;
  AuthError(this.error);
}

// State when OTP is sent successfully
class AuthOtpSent extends AuthState {
  final String email;
  AuthOtpSent(this.email);
}
