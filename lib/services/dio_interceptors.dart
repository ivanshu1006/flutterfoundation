import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../providers/auth_provider.dart';
import '../utils/utils.dart';
import '../widgets/snack_bar.dart';
import 'logger_service.dart';

class DioInterceptors extends InterceptorsWrapper {
  final FlutterSecureStorage secureStorage = const FlutterSecureStorage();
  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final sid = await Utils.getSid();
    if (sid != null) {
      options.headers['Cookie'] = 'sid=$sid';
    }

    logger.info('Request: ${options.method} ${options.headers}');
    super.onRequest(options, handler);
  }

  @override
  void onResponse(
    Response response,
    ResponseInterceptorHandler handler,
  ) {
    // Handle response
    logger.info('Response: ${response.statusCode} ${response.data}');
    super.onResponse(response, handler);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    logger.error(
      'Error: ${err.message}',
      error: err,
      stackTrace: err.stackTrace,
    );
    if (err.response?.statusCode == 401) {
      SnackbarGlobal.show(
        'Incorrect username/password',
        textColor: Colors.white,
        backgroundColor: Colors.red,
      );
    } else if (err.response?.statusCode == 403) {
      try {
        final response = err.response?.data;
        final loginProvider = AuthProvider();
        if (response['session_expired'] == 1) {
          SnackbarGlobal.show(
            'Session Expired. Please login again.',
            textColor: Colors.white,
            backgroundColor: Colors.red,
          );
          loginProvider.logout();
        } else {
          SnackbarGlobal.show(
            'Forbidden',
            textColor: Colors.white,
            backgroundColor: Colors.red,
          );
        }
      } catch (e) {
        throw Exception('Error in Dio Error handler $e');
      }
    } else if (err.response?.statusCode == 404) {
      SnackbarGlobal.show(
        'Page not found',
        textColor: Colors.white,
        backgroundColor: Colors.red,
      );
    } else if (err.type == DioExceptionType.connectionTimeout) {
      SnackbarGlobal.show(
        'Connection timeout',
        textColor: Colors.white,
        backgroundColor: Colors.red,
      );
    } else if (err.type == DioExceptionType.badResponse) {
      SnackbarGlobal.show(
        'Bad Response',
        textColor: Colors.white,
        backgroundColor: Colors.red,
      );
    } else if (err.type == DioExceptionType.cancel) {
      SnackbarGlobal.show(
        'Request Cancelled',
        textColor: Colors.white,
        backgroundColor: Colors.red,
      );
    } else {
      if (err.error.toString().contains('SocketException')) {
        SnackbarGlobal.show(
          'Please check your internet connection.',
          textColor: Colors.white,
          backgroundColor: Colors.red,
        );
      } else {
        SnackbarGlobal.show(
          'Unknown Error Occurred. Error: ${err.error.toString()}',
          textColor: Colors.white,
          backgroundColor: Colors.red,
        );
      }
    }
    super.onError(err, handler);
  }
}
