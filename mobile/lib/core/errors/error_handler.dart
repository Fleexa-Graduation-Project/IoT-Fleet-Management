import 'package:dio/dio.dart';
import 'package:fleexa/core/utils/constants/app_strings.dart'; // مسار الـ ErrorType

class ErrorHandler {
  static ErrorType getErrorType(dynamic error) {
    if (error is DioException) {
      if (error.type == DioExceptionType.connectionError ||
          error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.receiveTimeout) {
        return ErrorType.network;
      } else if (error.response?.statusCode != null &&
          error.response!.statusCode! >= 500) {
        return ErrorType.server;
      }
    }
    return ErrorType.unknown;
  }
}
