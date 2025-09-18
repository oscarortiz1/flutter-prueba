import 'package:flutter_prueba/features/movements/data/movement_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dio/dio.dart';

void main() {
  test('fetchPage trae 20 items por defecto', () async {
    final repo = MovementRepository(Dio(BaseOptions(baseUrl: 'http://localhost:8080')));
    final items = await repo.fetchPage(page: 1);
    expect(items.length, 20);
  });
}
