import 'package:flutter/services.dart';
import '../services/api_service.dart';

import '../models/movement.dart';
import '../services/db_provider.dart';
import '../services/sync_service.dart';

/// Simple repository that prefers sqflite but falls back to an in-memory
/// store if the plugin is not available at runtime (e.g. MissingPluginException).
class MovementRepository {
  final dynamic _db;

  /// Allow injecting a DBProvider or test-double for testing; default uses singleton DBProvider().
  MovementRepository({dynamic db}) : _db = db ?? DBProvider();

  // In-memory fallback storage
  final List<Movement> _inMemory = [];
  int _nextId = 1;

  Future<List<Movement>> fetchAll() async {
    try {
      return await _db.getMovements();
    } on MissingPluginException catch (_) {
      // Return in-memory data if sqflite isn't registered on this platform.
      return List.of(_inMemory);
    } on UnsupportedError catch (_) {
      return List.of(_inMemory);
    } catch (e) {
      // Any other error -> rethrow so callers can handle it
      rethrow;
    }
  }

  /// Fetch cached movements; if cache empty, try fetch from server once and
  /// populate the cache. If server returns empty, record that we've checked
  /// so we don't keep querying server until user triggers create/delete/refresh.
  bool _serverCheckDone = false;

  Future<List<Movement>> fetchCachedOrServer() async {
    try {
      final local = await _db.getMovements();
      if (local.isNotEmpty) return local;
      // local empty
      if (_serverCheckDone) return local;
      // attempt to pull from server
      try {
        final resp = await ApiService.instance.getMovimientos();
        if (resp.statusCode == 200) {
          final data = resp.data as List<dynamic>;
          for (final doc in data) {
            await upsertFromServer(doc as Map<String, dynamic>);
          }
          _serverCheckDone = true;
          return await _db.getMovements();
        }
      } catch (_) {
        // network error -> return local empty
      }
      _serverCheckDone = true;
      return local;
    } on MissingPluginException catch (_) {
      return _inMemory;
    }
  }

  /// Reset the internal server-check flag so the next fetch will attempt
  /// to pull from the server again.
  void resetServerCheck() {
    _serverCheckDone = false;
  }

  /// Fetch a page of movements. `page` is zero-based. `limit` default is 20.
  Future<List<Movement>> fetchPage(int page, {int limit = 20, String? query}) async {
    final offset = page * limit;
    try {
      return await _db.getMovementsPage(offset, limit, query: query);
    } on MissingPluginException catch (_) {
      // In-memory fallback: filter and then return slice
      Iterable<Movement> items = _inMemory;
      if (query != null && query.isNotEmpty) {
        final q = query.toLowerCase();
        items = items.where((m) => (m.description ?? '').toLowerCase().contains(q) || m.accountFrom.toLowerCase().contains(q) || m.accountTo.toLowerCase().contains(q) || m.type.toLowerCase().contains(q));
      }
      final list = items.toList();
      final start = offset;
      if (start >= list.length) return [];
      final end = (start + limit) > list.length ? list.length : (start + limit);
      return list.sublist(start, end);
    } on UnsupportedError catch (_) {
      Iterable<Movement> items = _inMemory;
      if (query != null && query.isNotEmpty) {
        final q = query.toLowerCase();
        items = items.where((m) => (m.description ?? '').toLowerCase().contains(q) || m.accountFrom.toLowerCase().contains(q) || m.accountTo.toLowerCase().contains(q) || m.type.toLowerCase().contains(q));
      }
      final list = items.toList();
      final start = offset;
      if (start >= list.length) return [];
      final end = (start + limit) > list.length ? list.length : (start + limit);
      return list.sublist(start, end);
    }
  }

  /// Fetch a page from server and return both list and metadata.
  /// Returns: { 'movements': List<Movement>, 'total': int, 'totalPages': int }
  Future<Map<String, dynamic>> fetchPageWithMeta(int page, {int limit = 20, String? query}) async {
    try {
      final resp = await ApiService.instance.getMovimientosPaged(page: page, limit: limit, query: query);
      if (resp.statusCode == 200) {
        final data = resp.data as Map<String, dynamic>;
        final items = data['data'] as List<dynamic>;
        for (final doc in items) {
          await upsertFromServer(doc as Map<String, dynamic>);
        }
        final local = await fetchPage(page, limit: limit, query: query);
        return {'movements': local, 'total': data['total'] ?? 0, 'totalPages': data['totalPages'] ?? 0};
      }
      return {'movements': <Movement>[], 'total': 0, 'totalPages': 0};
    } catch (_) {
      // network error -> fallback to local paged fetch
      final local = await fetchPage(page, limit: limit, query: query);
      return {'movements': local, 'total': local.length, 'totalPages': 1};
    }
  }

  Future<Movement> add(Movement m) async {
    try {
      final id = await _db.insertMovement(m);
      return Movement(
        id: id,
        serverId: m.serverId,
        type: m.type,
        amount: m.amount,
        description: m.description,
        accountFrom: m.accountFrom,
        accountTo: m.accountTo,
        currency: m.currency,
        status: m.status,
        reference: m.reference,
        valueDate: m.valueDate,
      );
    } on MissingPluginException catch (_) {
      final movement = Movement(
        id: _nextId++,
        type: m.type,
        amount: m.amount,
        description: m.description,
        accountFrom: m.accountFrom,
        accountTo: m.accountTo,
        currency: m.currency,
        status: m.status,
      );
      _inMemory.insert(0, movement);
      return movement;
    } on UnsupportedError catch (_) {
      final movement = Movement(
        id: _nextId++,
        type: m.type,
        amount: m.amount,
        description: m.description,
        accountFrom: m.accountFrom,
        accountTo: m.accountTo,
        currency: m.currency,
        status: m.status,
      );
      _inMemory.insert(0, movement);
      return movement;
    }
  }

  // After any local add we attempt an immediate sync. If there's no
  // connectivity SyncService will queue the work and the local row
  // remains pending for later retry.
  Future<void> _tryImmediateSync() async {
    try {
      await SyncService().manualSyncOnce();
    } catch (_) {
      // ignore — SyncService handles queueing and errors internally
    }
  }

  Future<void> delete(int id) async {
    try {
      // If this movement has a serverId, mark it for deletion so sync will call DELETE on server
      final map = await _db.getMovementById(id);
      if (map != null && (map['server_id'] as String?) != null) {
        await _db.markPendingDelete(id);
      } else {
        await _db.deleteMovement(id);
      }
      // try to sync immediately after marking/deleting
      _tryImmediateSync();
    } on MissingPluginException catch (_) {
      final idx = _inMemory.indexWhere((m) => m.id == id);
      if (idx != -1) {
        final m = _inMemory[idx];
        if (m.serverId != null) {
          // mark as pending_delete by updating syncStatus
          final updated = Movement(
            id: m.id,
            serverId: m.serverId,
            type: m.type,
            amount: m.amount,
            description: m.description,
            accountFrom: m.accountFrom,
            accountTo: m.accountTo,
            currency: m.currency,
            status: m.status,
            syncStatus: 'pending_delete',
          );
          _inMemory[idx] = updated;
        } else {
          _inMemory.removeAt(idx);
        }
      }
      // attempt immediate sync for in-memory fallback as well
      _tryImmediateSync();
    } on UnsupportedError catch (_) {
      final idx = _inMemory.indexWhere((m) => m.id == id);
      if (idx != -1) {
        final m = _inMemory[idx];
        if (m.serverId != null) {
          final updated = Movement(
            id: m.id,
            serverId: m.serverId,
            type: m.type,
            amount: m.amount,
            description: m.description,
            accountFrom: m.accountFrom,
            accountTo: m.accountTo,
            currency: m.currency,
            status: m.status,
            syncStatus: 'pending_delete',
          );
          _inMemory[idx] = updated;
        } else {
          _inMemory.removeAt(idx);
        }
      }
      _tryImmediateSync();
    }
  }

  /// Permanently remove local movement (used after server delete succeeds)
  Future<void> removeLocal(int id) async {
    try {
      await _db.removeLocalMovement(id);
    } on MissingPluginException catch (_) {
      _inMemory.removeWhere((m) => m.id == id);
    } on UnsupportedError catch (_) {
      _inMemory.removeWhere((m) => m.id == id);
    }
  }

  Future<List<Movement>> fetchPending() async {
    try {
      return await _db.getPendingMovements();
    } on MissingPluginException catch (_) {
      return _inMemory.where((m) => m.syncStatus == 'pending').toList();
    } on UnsupportedError catch (_) {
      return _inMemory.where((m) => m.syncStatus == 'pending').toList();
    }
  }

  Future<void> markSyncedLocal(int id, String serverId) async {
    try {
      await _db.markSynced(id, serverId);
    } on MissingPluginException catch (_) {
      final idx = _inMemory.indexWhere((m) => m.id == id);
      if (idx != -1) {
        final m = _inMemory[idx];
        final updated = Movement(
          id: m.id,
          serverId: serverId,
          type: m.type,
          amount: m.amount,
          description: m.description,
          accountFrom: m.accountFrom,
          accountTo: m.accountTo,
          currency: m.currency,
          status: 'pending',
        );
        _inMemory[idx] = updated;
      }
    } on UnsupportedError catch (_) {
      final idx = _inMemory.indexWhere((m) => m.id == id);
      if (idx != -1) {
        final m = _inMemory[idx];
        final updated = Movement(
          id: m.id,
          serverId: serverId,
          type: m.type,
          amount: m.amount,
          description: m.description,
          accountFrom: m.accountFrom,
          accountTo: m.accountTo,
          currency: m.currency,
          status: 'pending',
        );
        _inMemory[idx] = updated;
      }
    }
  }

  Future<Movement?> findByServerId(String serverId) async {
    try {
      final map = await _db.getMovementByServerId(serverId);
      if (map == null) return null;
      return Movement.fromMap(map);
    } on MissingPluginException catch (_) {
      final idx = _inMemory.indexWhere((m) => m.serverId == serverId);
      if (idx == -1) return null;
      return _inMemory[idx];
    } on UnsupportedError catch (_) {
      final idx = _inMemory.indexWhere((m) => m.serverId == serverId);
      if (idx == -1) return null;
      return _inMemory[idx];
    }
  }

  /// Upsert a server-side movement into local storage. Returns the local id.
  Future<int> upsertFromServer(Map<String, dynamic> serverDoc) async {
    try {
      // Map server document to local sqlite column names
      final serverId = serverDoc['_id'] ?? serverDoc['id']?.toString();
      final map = <String, dynamic>{
        'server_id': serverId?.toString(),
        'type': serverDoc['type'] ?? serverDoc['movement_type'] ?? 'transfer',
        'amount': serverDoc['amount'] ?? 0.0,
        'description': serverDoc['description'],
        'account_from': serverDoc['accountFrom'] ?? serverDoc['account_from'] ?? 'default',
        'account_to': serverDoc['accountTo'] ?? serverDoc['account_to'] ?? 'default',
        'currency': serverDoc['currency'] ?? 'PEN',
        'status': serverDoc['status'] ?? 'pending',
        'reference': serverDoc['reference'],
        'value_date': serverDoc['valueDate'] ?? serverDoc['value_date'],
        'created_at': serverDoc['createdAt'] ?? serverDoc['created_at'] ?? DateTime.now().toIso8601String(),
        'updated_at': serverDoc['updatedAt'] ?? serverDoc['updated_at'] ?? DateTime.now().toIso8601String(),
        'sync_status': 'synced',
      };
      return await _db.upsertMovement(map);
    } on MissingPluginException catch (_) {
      // map server doc into Movement and insert/update in-memory
      final serverId = serverDoc['_id'] ?? serverDoc['id']?.toString();
      final existingIdx = _inMemory.indexWhere((m) => m.serverId == serverId);
      final m = Movement(
        id: existingIdx != -1 ? _inMemory[existingIdx].id : _nextId++,
        serverId: serverId?.toString(),
        type: (serverDoc['type'] as String?) ?? 'transfer',
        amount: (serverDoc['amount'] as num?)?.toDouble() ?? 0.0,
        description: serverDoc['description'] as String?,
        accountFrom: (serverDoc['accountFrom'] as String?) ?? (serverDoc['account_from'] as String?) ?? 'default',
        accountTo: (serverDoc['accountTo'] as String?) ?? (serverDoc['account_to'] as String?) ?? 'default',
        currency: (serverDoc['currency'] as String?) ?? 'PEN',
        status: (serverDoc['status'] as String?) ?? 'pending',
      );
      if (existingIdx != -1) {
        _inMemory[existingIdx] = m;
        return m.id!;
      } else {
        _inMemory.insert(0, m);
        return m.id!;
      }
    } on UnsupportedError catch (_) {
      final serverId = serverDoc['_id'] ?? serverDoc['id']?.toString();
      final existingIdx = _inMemory.indexWhere((m) => m.serverId == serverId);
      final m = Movement(
        id: existingIdx != -1 ? _inMemory[existingIdx].id : _nextId++,
        serverId: serverId?.toString(),
        type: (serverDoc['type'] as String?) ?? 'transfer',
        amount: (serverDoc['amount'] as num?)?.toDouble() ?? 0.0,
        description: serverDoc['description'] as String?,
        accountFrom: (serverDoc['accountFrom'] as String?) ?? (serverDoc['account_from'] as String?) ?? 'default',
        accountTo: (serverDoc['accountTo'] as String?) ?? (serverDoc['account_to'] as String?) ?? 'default',
        currency: (serverDoc['currency'] as String?) ?? 'PEN',
        status: (serverDoc['status'] as String?) ?? 'pending',
      );
      if (existingIdx != -1) {
        _inMemory[existingIdx] = m;
        return m.id!;
      } else {
        _inMemory.insert(0, m);
        return m.id!;
      }
    }
  }
}
