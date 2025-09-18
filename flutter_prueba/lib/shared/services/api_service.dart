import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Keys (keep in sync with AuthService)
const _tokenKey = 'access_token';
const _refreshTokenKey = 'refresh_token';
const _emailKey = 'user_email';

class ApiService {
  final Dio _dio;

  ApiService._internal(String baseUrl)
      : _dio = Dio(BaseOptions(baseUrl: baseUrl, connectTimeout: const Duration(seconds: 10))) {
    // add interceptor to inject Authorization header and attempt refresh on 401
    _dio.interceptors.add(InterceptorsWrapper(onRequest: (opts, handler) async {
      try {
        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString(_tokenKey);
        if (token != null) {
          opts.headers['Authorization'] = 'Bearer $token';
        }
      } catch (e) {
        print('ApiService interceptor error: $e');
      }
      handler.next(opts);
    }, onError: (err, handler) async {
      // Attempt refresh on 401 Unauthorized
      if (err.response?.statusCode == 401) {
        try {
          final prefs = await SharedPreferences.getInstance();
          final email = prefs.getString(_emailKey);
          final refresh = prefs.getString(_refreshTokenKey);
          if (email != null && refresh != null) {
            final r = await _dio.post('/auth/refresh', data: {'email': email, 'refresh_token': refresh});
            if ((r.statusCode == 200 || r.statusCode == 201) && r.data['access_token'] != null) {
              await prefs.setString(_tokenKey, r.data['access_token'] as String);
              // retry the original request
              final opts = err.requestOptions;
              opts.headers['Authorization'] = 'Bearer ${r.data['access_token'] as String}';
              final cloneReq = await _dio.fetch(opts);
              return handler.resolve(cloneReq);
            }
          }
        } catch (_) {
          // ignore refresh errors
        }
      }
      handler.next(err);
    }));
  }

  static ApiService? _instance;

  static ApiService init({required String baseUrl}) {
    _instance ??= ApiService._internal(baseUrl);
    return _instance!;
  }

  static ApiService get instance {
    if (_instance == null) throw StateError('ApiService not initialized. Call ApiService.init(baseUrl: ...) first.');
    return _instance!;
  }

  Future<Response> postMovimiento(Map<String, dynamic> payload) async {
    return _dio.post('/movimientos', data: payload);
  }

  Future<Response> getMovimientos() async {
    return _dio.get('/movimientos');
  }

  Future<Response> getMovimientosPaged({int page = 0, int limit = 20, String? query}) async {
    final qp = <String, dynamic>{'page': page.toString(), 'limit': limit.toString()};
    if (query != null && query.isNotEmpty) qp['q'] = query;
    return _dio.get('/movimientos', queryParameters: qp);
  }

  Future<Response> deleteMovimiento(String serverId) async {
    return _dio.delete('/movimientos/$serverId');
  }

  // Generic helpers
  Future<Response> post(String path, {Map<String, dynamic>? data}) async {
    return _dio.post(path, data: data);
  }

  Future<Response> get(String path, {Map<String, dynamic>? queryParameters}) async {
    return _dio.get(path, queryParameters: queryParameters);
  }

  Future<Response> patch(String path, {Map<String, dynamic>? data}) async {
    return _dio.patch(path, data: data);
  }
}
