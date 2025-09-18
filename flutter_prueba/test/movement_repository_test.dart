import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_prueba/shared/repositories/movement_repository.dart';
import 'package:flutter/services.dart';

class FakeDB {
  Future<List<Map<String, dynamic>>> getMovements() async {
    throw MissingPluginException('sqflite not available in test');
  }
}

void main() {
  test('fetchAll returns a list (in-memory fallback)', () async {
    final repo = MovementRepository(db: FakeDB());
    final items = await repo.fetchAll();
    expect(items, isA<List>());
  });
}
