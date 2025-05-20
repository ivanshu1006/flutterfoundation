import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frappe_flutter_app/constants/api_constants.dart';
import 'package:frappe_flutter_app/repositories/frappe_repository.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

class MockHTTPClient extends Mock implements Dio {}

class MockFlutterSecureStorage extends Mock implements FlutterSecureStorage {}

class MockGoRouter extends Mock implements GoRouter {}

void main() {
  late FrappeRepository frappeRepository;
  late MockHTTPClient mockDioClient;
  late MockFlutterSecureStorage mockSecureStorage;
  late MockGoRouter mockGoRouter;

  setUp(() {
    mockDioClient = MockHTTPClient();
    mockSecureStorage = MockFlutterSecureStorage();
    frappeRepository = FrappeRepository(mockDioClient)
      ..secureStorage = mockSecureStorage;

    mockGoRouter = MockGoRouter();

    // LoggerService.I.error('Error');
  });

  group('FrappeRepository - login', () {
    test('returns true when login is successful', () async {
      // Arrange
      const email = 'test@example.com';
      const password = 'password123';
      const fakeCookies = ['sid=some_session_id; Path=/; HttpOnly'];
      const responseData = {
        'full_name': 'Test User',
      };

      // Mocking the Post Request
      when(() => mockDioClient.post(
            ApiConstants.loginEndpoint,
            data: {'usr': email, 'pwd': password},
          )).thenAnswer((_) async => Response(
            data: responseData,
            statusCode: 200,
            headers: Headers.fromMap({'set-cookie': fakeCookies}),
            requestOptions: RequestOptions(path: ApiConstants.loginEndpoint),
          ));

      // Mocking the SecureStorage
      when(() => mockSecureStorage.write(
          key: any(named: 'key'),
          value: any(named: 'value'))).thenAnswer((_) async {});

      // Act
      final result = await frappeRepository.login(email, password);

      // Assert
      // Checking if the login was successful
      expect(result, isTrue);
      // Checking if the secure storage was called only once
      verify(() =>
              mockSecureStorage.write(key: 'sid', value: 'some_session_id'))
          .called(1);
      verify(() => mockSecureStorage.write(key: 'userId', value: email))
          .called(1);
      verify(() => mockSecureStorage.write(
          key: 'fullName', value: responseData['full_name'])).called(1);
    });

    test('returns false when login fails', () async {
      // Arrange
      const email = 'test@example.com';
      const password = 'wrong_password';

      const responseData = {
        'Exception': 'Incorrect User Id/Password',
      };

      when(() => mockGoRouter.go('/login')).thenAnswer((_) async {});

      // Mocking the Post Request
      when(() => mockDioClient.post(
            ApiConstants.loginEndpoint,
            data: {'usr': email, 'pwd': password},
          )).thenAnswer((_) async => Response(
            data: responseData,
            statusCode: 401,
            requestOptions: RequestOptions(path: ApiConstants.loginEndpoint),
          ));

      // Act
      final result = await frappeRepository.login(email, password);

      // Assert
      // Checking if the login failed
      expect(result, isFalse);
      // Checking is the secure storage was not called since login failed
      verifyNever(
        () => mockSecureStorage.write(
            key: any(named: 'key'), value: any(named: 'value')),
      );
    });
  });

  group('FrappeRepository - logout', () {
    test('deletes all user-related keys from secure storage', () async {
      // Arrange
      when(() => mockSecureStorage.delete(key: any(named: 'key')))
          .thenAnswer((_) async {});

      // Act
      await frappeRepository.logout();

      // Assert
      verify(() => mockSecureStorage.delete(key: 'sid')).called(1);
      verify(() => mockSecureStorage.delete(key: 'sidExpiry')).called(1);
      verify(() => mockSecureStorage.delete(key: 'userId')).called(1);
      verify(() => mockSecureStorage.delete(key: 'fullName')).called(1);
      verifyNoMoreInteractions(mockSecureStorage);
    });
  });
  group('FrappeRepository - apiResource', () {
    group('apiResource - List<dynamic>>()', () {
      test('returns data when the API call is successful', () async {
        // Arrange
        const doctype = 'User';
        final fields = ['name', 'email'];
        final filters = [
          {'role': 'Administrator'}
        ];
        const orderBy = 'name asc';

        final responseData = {
          "data": [
            {"name": "Test Admin 1", "email": "test_admin_1@example.com"},
            {"name": "Test Admin 2", "email": "test_admin_2@example.com"}
          ]
        };

        when(() => mockDioClient.get(
              '${ApiConstants.apiResource}$doctype',
              queryParameters: {
                'limit': '[*]',
                'fields': json.encode(fields),
                'filters': json.encode(filters),
                'order_by': orderBy,
              },
            )).thenAnswer(
          (_) async => Response(
            data: responseData,
            statusCode: 200,
            requestOptions:
                RequestOptions(path: '${ApiConstants.apiResource}$doctype'),
          ),
        );

        // Act
        final result = await frappeRepository.apiResource<List<dynamic>>(
          doctype: doctype,
          fields: fields,
          filters: filters,
          orderBy: orderBy,
        );

        // Assert
        expect(result, isA<List<dynamic>>());
        expect(result, equals(responseData['data']));
        verify(() => mockDioClient.get(
              '${ApiConstants.apiResource}$doctype',
              queryParameters: {
                'limit': '[*]',
                'fields': json.encode(fields),
                'filters': json.encode(filters),
                'order_by': orderBy,
              },
            )).called(1);
      });

      test('throws an exception when the API call fails', () async {
        // Arrange
        const doctype = 'User';
        final fields = ['name', 'email'];
        final filters = [
          {'role': 'Administrator'}
        ];
        const orderBy = 'name asc';

        when(() => mockDioClient.get(
              '${ApiConstants.apiResource}$doctype',
              queryParameters: any(named: 'queryParameters'),
            )).thenThrow(DioException(
          requestOptions:
              RequestOptions(path: '${ApiConstants.apiResource}$doctype'),
          error: 'Network error',
        ));

        // Act & Assert
        expect(
          () async => await frappeRepository.apiResource<List<dynamic>>(
            doctype: doctype,
            fields: fields,
            filters: filters,
            orderBy: orderBy,
          ),
          throwsA(isA<Exception>().having((e) => e.toString(), 'description',
              contains('Failed to get resource'))),
        );

        verify(() => mockDioClient.get(
              '${ApiConstants.apiResource}$doctype',
              queryParameters: {
                'limit': '[*]',
                'fields': json.encode(fields),
                'filters': json.encode(filters),
                'order_by': orderBy,
              },
            )).called(1);
      });
    });

    group('apiResource - Map<String, dynamic>()', () {
      test('returns data when the API call is successful', () async {
        // Arrange
        const doctype = 'User/test_admin_1@example.com';
        final List<String> fields = ['name', 'email'];

        final responseData = {
          "data": {
            "name": "Test Admin 1",
            "email": "test_admin_1@example.com",
            "full_name": "Test Admin 1"
          }
        };

        when(() => mockDioClient.get(
              '${ApiConstants.apiResource}$doctype',
              queryParameters: any(named: 'queryParameters'),
            )).thenAnswer(
          (_) async => Response(
            data: responseData,
            statusCode: 200,
            requestOptions:
                RequestOptions(path: '${ApiConstants.apiResource}$doctype'),
          ),
        );

        // Act
        final result = await frappeRepository.apiResource<Map<String, dynamic>>(
          doctype: doctype,
          fields: fields,
        );

        // Assert
        expect(result, isA<Map<String, dynamic>>());
        expect(result, equals(responseData['data']));

        verify(() => mockDioClient.get(
              '${ApiConstants.apiResource}$doctype',
              queryParameters: {
                'limit': '[*]',
                'fields': json.encode(fields),
              },
            )).called(1);
      });

      test('throws an exception when the API call fails', () async {
        // Arrange
        const doctype = 'User/test_admin_1@example.com';
        final fields = ['name', 'email'];

        when(() => mockDioClient.get(
              '${ApiConstants.apiResource}$doctype',
              queryParameters: any(named: 'queryParameters'),
            )).thenThrow(DioException(
          requestOptions:
              RequestOptions(path: '${ApiConstants.apiResource}$doctype'),
          error: 'Network error',
        ));

        // Act & Assert
        expect(
          () async => await frappeRepository.apiResource<Map<String, dynamic>>(
            doctype: doctype,
            fields: fields,
          ),
          throwsA(isA<Exception>().having((e) => e.toString(), 'description',
              contains('Failed to get resource'))),
        );

        verify(() => mockDioClient.get(
              '${ApiConstants.apiResource}$doctype',
              queryParameters: {
                'limit': '[*]',
                'fields': json.encode(fields),
              },
            )).called(1);
      });
    });
  });
}
