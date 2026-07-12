import 'dart:async';
import 'dart:developer';

import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fleexa/core/network/api_constants.dart';
import 'package:fleexa/core/network/api_service.dart';
import 'package:fleexa/core/storage/token_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'auth_state.dart';
import 'package:fleexa/core/services/push_notification_service.dart';

class AuthCubit extends Cubit<AuthState> {
  final APiService apiService;
  final PushNotificationService pushNotificationService;

  String username = "User";
  String email = "";

  String? _resetEmail;
  String? _resetCode;

  StreamSubscription? _logoutSubscription;

  AuthCubit(this.apiService, this.pushNotificationService)
      : super(AuthInitial()) {
    _logoutSubscription = apiService.onLogout.listen((_) {
      username = "User";
      email = "";
      emit(Unauthenticated());
    });
  }

  @override
  Future<void> close() {
    _logoutSubscription?.cancel();
    return super.close();
  }

  Future<void> fetchProfile() async {
    try {
      final response = await apiService.get(ApiConstants.profile);
      if (response.statusCode == 200) {
        log("REAL PROFILE DATA: ${response.data}");
        final rawUsername = response.data['username'];
        username =
            (rawUsername != null && rawUsername.toString().trim().isNotEmpty)
                ? rawUsername.toString()
                : "User";
        email = response.data['email'] ?? "";
        if (state is Authenticated) emit(Authenticated());
      }
    } catch (e) {
      log("Failed to fetch profile: $e");
    }
  }

  // 1. Sign Up
  Future<void> signUp({
    required String username,
    required String email,
    required String password,
    required String confirmPassword,
  }) async {
    emit(AuthLoading());
    try {
      final response = await apiService.post(
        ApiConstants.signUp,
        data: {
          "username": username,
          "email": email,
          "password": password,
          "confirm_password": confirmPassword,
        },
      );

      if (response.statusCode == 201) {
        await signIn(email: email, password: password);
      } else {
        emit(AuthError("Something went wrong"));
      }
    } on DioException catch (e) {
      String errorMsg = e.response?.data['error'] ?? "Failed to sign up";
      emit(AuthError(errorMsg));
    }
  }

  // 2. Sign In
  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    emit(AuthLoading());
    try {
      final response = await apiService.post(
        ApiConstants.signIn,
        data: {
          "email": email,
          "password": password,
        },
      );

      if (response.statusCode == 200) {
        final tokens = response.data;

        // Save tokens securely
        await TokenStorage.saveTokens(
          accessToken: tokens['access_token'],
          refreshToken: tokens['refresh_token'] ?? "",
          idToken: tokens['id_token'],
        );

        await fetchProfile();

        await pushNotificationService.registerDeviceForNotifications();

        emit(AuthSuccess(message: "Logged in successfully"));
      }
    } on DioException catch (e) {
      String errorMsg =
          e.response?.data['error'] ?? "Invalid email or password";
      emit(AuthError(errorMsg));
    }
  }

  // 3. Forgot Password (Request OTP)
  Future<void> forgotPassword(String email) async {
    emit(AuthLoading());
    try {
      _resetEmail = email;
      await apiService.post(
        ApiConstants.forgotPassword,
        data: {"email": email},
      );

      emit(AuthOtpSent(email));
    } on DioException catch (e) {
      String errorMsg = e.response?.data['error'] ?? "Failed to send OTP";
      emit(AuthError(errorMsg));
    }
  }

  // Save OTP code
  void saveOtpCode(String code) {
    _resetCode = code;
    emit(AuthCodeSaved());
  }

  // 4. Reset Password (Verify OTP & Change)
  Future<void> resetPassword({
    required String newPassword,
    required String confirmPassword,
  }) async {
    if (_resetEmail == null || _resetCode == null) {
      emit(AuthError("Missing email or verification code. Please try again."));
      return;
    }
    emit(AuthLoading());
    try {
      await apiService.post(
        ApiConstants.resetPassword,
        data: {
          "email": _resetEmail,
          "code": _resetCode,
          "new_password": newPassword,
          "confirm_new_password": confirmPassword,
        },
      );

      String loginEmail = _resetEmail!;

      _resetEmail = null;
      _resetCode = null;

      await signIn(email: loginEmail, password: newPassword);

      emit(AuthSuccess(message: "Password reset successfully"));
    } on DioException catch (e) {
      String errorMsg = e.response?.data['error'] ?? "Failed to reset password";
      emit(AuthError(errorMsg));
    }
  }

  // 5. Change Password
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    emit(AuthLoading());
    try {
      await apiService.post(
        ApiConstants.changePassword,
        data: {
          "current_password": currentPassword,
          "new_password": newPassword,
          "confirm_new_password": confirmPassword,
        },
      );
      emit(AuthSuccess(message: "Password changed successfully"));
    } on DioException catch (e) {
      String errorMsg =
          e.response?.data['error'] ?? "Failed to change password";
      emit(AuthError(errorMsg));
    }
  }

  // 6. Sign Out
  Future<void> signOut() async {
    emit(AuthLoading());
    try {
      await pushNotificationService.unregisterDevice();
    } catch (e) {
      log("Failed to unregister device from backend, but logging out locally anyway: $e");
    }
    try {
      await TokenStorage.clearTokens();

      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('read_alerts');

      username = "User";
      email = "";
      emit(Unauthenticated());
    } catch (e) {
      emit(AuthError("An unexpected error occurred during local sign out."));
    }
  }

  // 7. Check Authentication Status
  Future<void> checkAppStart() async {
    emit(AuthCheckInProgress());

    // 1. isFirstTimeUser check
    final prefs = await SharedPreferences.getInstance();
    final bool isFirstTime = prefs.getBool('is_first_time') ?? true;

    if (isFirstTime) {
      await prefs.setBool('is_first_time', false);
      emit(FirstTimeUser());
      return;
    }

    // 2. User has opened the app before, check for valid token
    final token = await TokenStorage.getAccessToken();

    if (token != null && token.isNotEmpty) {
      await fetchProfile();

      await pushNotificationService.registerDeviceForNotifications();

      emit(Authenticated()); // Logged in user with valid token -> Home
    } else {
      emit(Unauthenticated()); // User has no valid token -> Sign In
    }
  }

// 8. Delete Account
  Future<bool> deleteAccount(String password) async {
    emit(AuthLoading());
    try {
      // Calls DELETE /api/v1/auth/account on your Go backend
      final response = await apiService.delete(
        '/auth/account',
        data: {
          "password": password,
        },
      );

      if (response.statusCode == 200) {
        // Clear local storage and state just like a Sign Out
        await pushNotificationService.unregisterDevice();
        await TokenStorage.clearTokens();
        username = "User";
        email = "";

        emit(AuthSuccess(message: "Account deleted successfully"));
        emit(
            Unauthenticated()); // This ensures the rest of your app knows the user is gone
        return true;
      }
      return false;
    } on DioException catch (e) {
      // This will catch the 401 "incorrect password" error from your Go handler
      String errorMsg = e.response?.data['error'] ?? "Failed to delete account";
      emit(AuthError(errorMsg));
      return false;
    } catch (e) {
      emit(AuthError("An unexpected error occurred"));
      return false;
    }
  }
}
