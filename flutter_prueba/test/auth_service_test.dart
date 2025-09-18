import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';

import 'package:flutter_prueba/shared/services/auth_service.dart';
import 'package:flutter_prueba/shared/services/api_service.dart';

class MockApi extends Mock implements ApiService {}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('verifyOtp stores tokens and sets authLoggedIn', () async {
    final mock = MockApi();
    when(() => mock.post('/auth/verify-otp', data: any(named: 'data'))).thenAnswer((_) async => Response(
          requestOptions: RequestOptions(path: '/auth/verify-otp'),
          statusCode: 200,
          data: {'access_token': 'atoken', 'refresh_token': 'rtoken'},
        ));

    final svc = AuthService(api: mock);
    final res = await svc.verifyOtp('a@b.c', '1234');
    expect(res, isTrue);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('access_token'), 'atoken');
    expect(prefs.getString('refresh_token'), 'rtoken');
    expect(AuthService.authLoggedIn.value, isTrue);
  });

  test('tryRestoreSession succeeds with refresh token', () async {
    final mock = MockApi();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_email', 'a@b.c');
    await prefs.setString('refresh_token', 'rtoken');

    when(() => mock.post('/auth/refresh', data: any(named: 'data'))).thenAnswer((_) async => Response(
          requestOptions: RequestOptions(path: '/auth/refresh'),
          statusCode: 200,
          data: {'access_token': 'newtoken'},
        ));

    final svc = AuthService(api: mock);
    final res = await svc.tryRestoreSession();
    expect(res, isTrue);
    expect((await SharedPreferences.getInstance()).getString('access_token'), 'newtoken');
    expect(AuthService.authLoggedIn.value, isTrue);
  });

  test('logout clears tokens and sets authLoggedIn false', () async {
    final mock = MockApi();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('access_token', 'atoken');
    await prefs.setString('refresh_token', 'rtoken');
    await prefs.setString('user_email', 'a@b.c');

    final svc = AuthService(api: mock);
    await svc.logout();
    final p2 = await SharedPreferences.getInstance();
    expect(p2.getString('access_token'), isNull);
    expect(p2.getString('refresh_token'), isNull);
    expect(AuthService.authLoggedIn.value, isFalse);
  });
}
