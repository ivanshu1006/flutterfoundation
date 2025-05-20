import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../constants/api_constants.dart';
import '../services/logger_service.dart';

class FrappeRepository {
  final Dio _dio;
  FrappeRepository(
    this._dio,
  );
  FlutterSecureStorage secureStorage = const FlutterSecureStorage();
  // final Dio _dio = DioService().client;

  Future<bool> login(String email, String password) async {
    try {
      final response = await _dio.post(ApiConstants.loginEndpoint, data: {
        'usr': email,
        'pwd': password,
      });

      if (response.statusCode == 200) {
        logger.debug(response);
        final cookies = response.headers['set-cookie'];
        if (cookies != null && cookies.isNotEmpty) {
          final fullName = response.data['full_name'];
          final sid = cookies
              .firstWhere((cookie) => cookie.contains('sid='))
              .split(';')[0]
              .split('=')[1];

          final setCookieHeaderList = response.headers['set-cookie']!;
          final setCookieHeader = setCookieHeaderList.join('; ');
          final expiryMatch =
              RegExp(r'Expires=([^;]+)').firstMatch(setCookieHeader);
          final sidExpiry = expiryMatch?.group(1) ?? '';
          await secureStorage.write(key: 'sid', value: sid);
          await secureStorage.write(key: 'sidExpiry', value: sidExpiry);
          await secureStorage.write(key: 'userId', value: email);
          await secureStorage.write(key: 'fullName', value: fullName);

          return true;
        }
      }
    } catch (e) {
      // Handle login error
      logger.error(
        'Login failed: ${e.toString()}',
        error: e,
      );
    }
    return false;
  }

  Future<void> logout() async {
    await secureStorage.delete(key: 'sid');
    await secureStorage.delete(key: 'sidExpiry');
    await secureStorage.delete(key: 'userId');
    await secureStorage.delete(key: 'fullName');
  }

  Future<T> apiResource<T>({
    required String doctype,
    List<String>? fields,
    List<Map<String, String>>? filters,
    String? orderBy,
  }) async {
    try {
      var params = {
        'limit': '[*]',
      };

      if (fields != null) {
        params['fields'] = json.encode(fields);
      }

      if (filters != null) {
        params['filters'] = json.encode(filters);
      }

      if (orderBy != null) {
        params['order_by'] = orderBy;
      }

      var response = await _dio.get(
        "${ApiConstants.apiResource}$doctype",
        queryParameters: params,
      );

      return response.data["data"] as T;
      // If getting the list then use T as <List<dynamic>>
      // await FrappeRepository().apiResource<List<dynamic>>('User', null, null, null);
      // Or else <Map<String, dynamic>>
      // await FrappeRepository().apiResource<Map<String, dynamic>>('User/Administrator', null, null, null);
    } catch (e) {
      throw Exception('Failed to get resource: $e');
    }
  }
}
