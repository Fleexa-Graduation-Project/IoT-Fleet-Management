import 'dart:async';
import 'dart:developer';

import 'package:dio/dio.dart';
import 'package:fleexa/core/network/api_constants.dart';
import 'package:flutter/foundation.dart';
import 'package:fleexa/core/storage/token_storage.dart';

import 'mock/mock_interceptor.dart';

class APiService {
  late final Dio _dio;
  late final Dio _refreshDio;

  final _logoutController = StreamController<void>.broadcast();
  Stream<void> get onLogout => _logoutController.stream;

  APiService() {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        receiveDataWhenStatusError: true,
        connectTimeout: const Duration(seconds: 45),
        receiveTimeout: const Duration(seconds: 45),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    // Prepare a separate Dio instance for token refresh operations
    _refreshDio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    if (ApiConstants.currentEnv == AppEnvironment.mock) {
      _dio.interceptors.add(MockInterceptor());
    }

    if (kDebugMode) {
      _dio.interceptors.add(
        LogInterceptor(
          request: true,
          requestHeader: true,
          requestBody: true,
          responseHeader: true,
          responseBody: true,
          error: true,
        ),
      );
    }

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // 1. Retrieve the token from secure storage
          String? token = await TokenStorage.getAccessToken();

          final publicRoutes = [
            '/signin',
            '/signup',
            '/register',
            '/forgot-password',
            '/reset-password',
            '/refresh'
          ];

          bool isPublicRoute =
              publicRoutes.any((route) => options.path.contains(route));

          if (token != null && !isPublicRoute) {
            options.headers['Authorization'] = 'Bearer $token';
          }

          return handler.next(options);
        },
        onError: (DioException e, handler) async {
          if (e.response?.statusCode == 401 &&
              !e.requestOptions.path.contains('/auth')) {
            bool isRefreshed = await _refreshToken();

            if (isRefreshed) {
              // Get the new access token after refresh
              String? newAccessToken = await TokenStorage.getAccessToken();

              // Renew the original request with the new token
              e.requestOptions.headers['Authorization'] =
                  'Bearer $newAccessToken';

              try {
                // Resend the original request with the new token
                final response = await _dio.fetch(e.requestOptions);
                return handler.resolve(response);
              } on DioException catch (retryError) {
                return handler.next(retryError);
              }
            } else {
              // If refresh failed, clear tokens and maybe redirect to login
              await TokenStorage.clearTokens();
              _logoutController.add(null);
              return handler.next(e);
            }
          }
          return handler.next(e);
        },
      ),
    );
  }

  // Token Refresh Logic
  Future<bool> _refreshToken() async {
    try {
      String? refreshToken = await TokenStorage.getRefreshToken();

      if (refreshToken == null || refreshToken.isEmpty) {
        return false;
      }

      // use the separate Dio instance to avoid interceptor loops
      final response = await _refreshDio.post(
        '/auth/refresh',
        data: {
          "refresh_token": refreshToken,
        },
      );

      if (response.statusCode == 200) {
        final data = response.data;

        await TokenStorage.saveTokens(
          accessToken: data['access_token'],
          idToken: data['id_token'],
          refreshToken: refreshToken,
        );
        return true;
      }
      return false;
    } catch (e) {
      if (kDebugMode) {
        log("Refresh Token Failed: $e");
      }
      return false;
    }
  }

  // Wrapper Methods

  // GET request with optional query parameters
  Future<Response> get(String endpoint,
      {Map<String, dynamic>? queryParameters}) async {
    try {
      final response =
          await _dio.get(endpoint, queryParameters: queryParameters);
      return response;
    } catch (e) {
      rethrow;
    }
  }

  // POST request with optional body data
  Future<Response> post(String endpoint, {dynamic data}) async {
    try {
      final response = await _dio.post(endpoint, data: data);
      return response;
    } catch (e) {
      rethrow;
    }
  }

  // DELETE request wrapper
  Future<Response> delete(String endpoint, {dynamic data}) async {
    try {
      final response = await _dio.delete(endpoint, data: data);
      return response;
    } catch (e) {
      rethrow;
    }
  }

  // PUT request wrapper
  Future<Response> put(String endpoint, {dynamic data}) async {
    try {
      final response = await _dio.put(endpoint, data: data);
      return response;
    } catch (e) {
      rethrow;
    }
  }
}
